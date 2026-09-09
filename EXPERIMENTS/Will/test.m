%% MARLUP - Plant identification, discrete LQR and discrete Kalman filter
%
%  Run this script with Model_will.slx on the MATLAB path.
%  It does three things:
%
%    1. Measures the plant (force -> acceleration map) with 4 short
%       open-loop runs of the Simscape model.
%    2. Builds the continuous state space model and discretizes it.
%    3. Designs a discrete LQR gain and a discrete Kalman gain.
%
%  Nothing is written into the model. The results you need in Simulink are
%  left in the workspace:
%
%    Ad, Bd, Cd, Dd  -> discrete matrices (for the Kalman Filter block)
%    K               -> state feedback gain, states in SI (rad, rad/s, m, m/s)
%    K_deg           -> same gain if the states reaching it are in degrees
%    Kr              -> feedforward gain for the reference
%    L               -> discrete Kalman gain
%    F_trim          -> static force per piston [N]
%    z0              -> assembled plate height [m]
%
%  State vector: x = [roll; roll_dot; pitch; pitch_dot; z; z_dot]
%  Input vector: u = [F1; F2; F3]   (piston forces, N)

clear; clc;

mdl  = 'Model_will';   % model name
Ts   = 0.01;           % sample time [s]  (10 ms, same as the PiL)
dF   = 400;            % probe force per piston [N]
T_id = 0.06;           % length of each probe run [s]
T_fit  = 0.04;         % end of the fitting window [s]
t_skip = 0.004;        % samples before this are discarded [s]

load_system(mdl);


%% 1. IDENTIFICATION -----------------------------------------------------
% Starting from rest, the accelerations are an affine function of the
% forces:   qddot = W*F + c
% One run with F = 0 gives c, three runs with one piston at a time give
% the columns of W.

% Save the block values that are going to be changed
K_old   = get_param([mdl '/Gain'],'Gain');
ref_old = get_param([mdl '/Referencias'],'Value');
F_old   = get_param([mdl '/Fsat'],'Value');
Hs_old  = get_param([mdl '/P-M SPECTRUM/Constant1'],'Value');

% Open the loop: no feedback, no reference, flat sea
set_param([mdl '/Gain'],'Gain','zeros(3,6)');
set_param([mdl '/Referencias'],'Value','zeros(6,1)');
set_param([mdl '/P-M SPECTRUM/Constant1'],'Value','0');

% Log the six PLANTA outputs
% Port order: 1 vZ  2 Z  3 vPitch  4 Pitch  5 vRoll  6 Roll
ph = get_param([mdl '/PLANTA'],'PortHandles');
names = {'vZ','Z','vPitch','Pitch','vRoll','Roll'};
for k = 1:6
    set_param(ph.Outport(k), 'DataLogging','on', ...
                             'DataLoggingNameMode','Custom', ...
                             'DataLoggingName', names{k});
end

set_param(mdl, 'SignalLogging','on', 'SignalLoggingName','logsout', ...
               'SignalLoggingSaveFormat','Dataset', ...
               'SolverName','ode23t', 'RelTol','1e-6', 'AbsTol','1e-8', ...
               'MaxStep','5e-4', 'StopTime',num2str(T_id));

Fprobe = [zeros(3,1), dF*eye(3)];   % 4 experiments
acc    = zeros(3,4);

for k = 1:4
    set_param([mdl '/Fsat'],'Value', mat2str(Fprobe(:,k)));
    out = sim(mdl,'ReturnWorkspaceOutputs','on');
    lg  = out.logsout;

    t     = lg.getElement('vRoll').Values.Time;
    vRoll = squeeze(lg.getElement('vRoll').Values.Data)  * pi/180;  % rad/s
    vPtch = squeeze(lg.getElement('vPitch').Values.Data) * pi/180;  % rad/s
    vZ    = squeeze(lg.getElement('vZ').Values.Data);               % m/s
    Z     = squeeze(lg.getElement('Z').Values.Data);                % m

    if k == 1
        z0 = Z(1);          % assembled height
    end

    % Least squares slope of v(t) = a*t through the origin
    m  = (t > t_skip) & (t <= T_fit);
    tt = t(m);
    acc(1,k) = (tt' * vRoll(m)) / (tt' * tt);
    acc(2,k) = (tt' * vPtch(m)) / (tt' * tt);
    acc(3,k) = (tt' * vZ(m))    / (tt' * tt);

    fprintf('F = [%5.0f %5.0f %5.0f] N -> qddot = [%8.4f %8.4f %8.4f]\n', ...
            Fprobe(:,k), acc(:,k));
end

c      = acc(:,1);                  % gravity / bias term
W      = (acc(:,2:4) - c) / dF;     % inverse effective inertia
F_trim = -W \ c;                    % forces that hold the plate static

% Put the model back the way it was
set_param([mdl '/Gain'],'Gain',K_old);
set_param([mdl '/Referencias'],'Value',ref_old);
set_param([mdl '/Fsat'],'Value',F_old);
set_param([mdl '/P-M SPECTRUM/Constant1'],'Value',Hs_old);


%% 2. CONTINUOUS AND DISCRETE MODEL --------------------------------------
% Each axis is a double integrator driven by W:
%   roll_ddot, pitch_ddot, z_ddot = W * F

A = zeros(6);  A(1,2) = 1;  A(3,4) = 1;  A(5,6) = 1;
B = zeros(6,3);  B([2 4 6],:) = W;
C = [1 0 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 0 1 0];       % measured outputs: roll, pitch, z
D = zeros(3,3);

sysc = ss(A,B,C,D);
sysd = c2d(sysc, Ts, 'zoh');

Ad = sysd.A;
Bd = sysd.B;
Cd = sysd.C;
Dd = sysd.D;


%% 3. DISCRETE LQR -------------------------------------------------------
% Weights chosen with Bryson's rule: penalty = 1 / (max acceptable value)^2

ang_max = 1.0 * pi/180;    % 1 deg of roll/pitch error
vel_max = 5.0 * pi/180;    % 5 deg/s
z_max   = 0.02;            % 2 cm of heave error
vz_max  = 0.10;            % 0.1 m/s
F_max   = 1000;            % N per piston

Q = diag([2e4, 2e3, 2e4, 2e3, 4e3, 4e2]);
R = 1e-3 * eye(3);

K = dlqr(Ad, Bd, Q, R);

% Feedforward so the heave reference is reached with no steady state error
Kr = pinv(Cd * ((eye(6) - Ad + Bd*K) \ Bd));

% The plant reports angles in degrees. If the states entering the gain
% block are still in degrees, use K_deg instead of K.
S_deg2si = diag([pi/180, pi/180, pi/180, pi/180, 1, 1]);
K_deg    = K * S_deg2si;


%% 4. DISCRETE KALMAN FILTER ---------------------------------------------
% Process noise enters through the force channel, measurement noise on the
% three sensed outputs. Tune Qn and Rn against your real sensor data.

sigma_F     = 20;                % N, force / model uncertainty
sigma_ang   = 0.05 * pi/180;     % rad, AHRS noise
sigma_z     = 0.005;             % m, ultrasonic sensor noise

Qn = eye(3) * sigma_F^2;
Rn = diag([sigma_ang^2, sigma_ang^2, sigma_z^2]);

% Same input matrix for the noise as for the forces
sys_kf   = ss(Ad, [Bd Bd], Cd, [Dd zeros(3)], Ts);
[~, L]   = kalman(sys_kf, Qn, Rn);


%% 5. SUMMARY ------------------------------------------------------------
fprintf('\n--- Results ---------------------------------------------\n');
fprintf('Sample time      : %.3f s\n', Ts);
fprintf('F_trim           : [%.1f %.1f %.1f] N\n', F_trim);
fprintf('Assembled z0     : %.4f m\n', z0);
fprintf('max|K|           : %.2f\n', max(abs(K(:))));
fprintf('max closed loop |z| : %.4f  (must be < 1)\n', max(abs(eig(Ad - Bd*K))));
fprintf('max observer   |z| : %.4f  (must be < 1)\n', max(abs(eig(Ad - L*Cd*Ad))));
fprintf('\nBlocks to fill in Simulink:\n');
fprintf('  state feedback gain  ->  K      (or K_deg)\n');
fprintf('  feedforward gain     ->  Kr\n');
fprintf('  piston bias constant ->  F_trim\n');
fprintf('  Kalman filter block  ->  Ad, Bd, Cd, Dd, Qn, Rn (or gain L)\n');
fprintf('---------------------------------------------------------\n');
