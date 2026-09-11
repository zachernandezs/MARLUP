clear;
clc;

scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir), scriptDir = pwd; end
cadDir = fullfile(scriptDir, '..', '..', 'CAD');
assert(isfolder(cadDir), 'No existe la carpeta CAD en: %s', cadDir);
addpath(cadDir);

Ts   = 0.01;           % sample time [s]  (10 ms, same as the PiL)
dF   = 400;            % probe force per piston [N]
T_id = 0.06;           % length of each probe run [s]
T_fit  = 0.04;         % end of the fitting window [s]
t_skip = 0.004;        % samples before this are discarded [s]

%% 1. W and c
% inverse effective inertia
W = [-0.002771924482755   0.005739054496021  -0.002923634654780;
     -0.005027416010180   0.000007232712827   0.004871901244289;
      0.012335716490594   0.012191287899931   0.012053881119175;];

c = [-0.036026972572833;
      0.224216631566696;
     -9.924449576046474;]; % gravity / bias term

F_trim = -W \ c; % forces that hold the plate static

z0 = 1.571637930257020;
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



%% 4. STATE ESTIMATOR ----------------------------------------------------
% Current (filtered) form, executed every Ts inside the "Estimador" block:
%   correction : xhat[k]   = xbar[k] + M_est*(y[k] - Ce*xbar[k])
%   prediction : xbar[k+1] = Ae*xhat[k] + Be*dF[k]
% dF = F - F_trim is the force deviation sent to the pistons and
% y = [roll; pitch; z] in rad and m (the plant reports angles in degrees,
% the conversion is done by Cmeas inside the subsystem).
%
% With estimate_bias = true the model is augmented with a constant force
% bias d (x_e = [x; d], x_e+ = [Ad Bd; 0 I]*x_e + [Bd; 0]*dF). The bias
% absorbs errors in W, c and F_trim, and the control law cancels it:
% dF = K*(r - xhat) - dhat, which removes the steady state error.

estimator     = 'kalman';   % 'kalman' | 'luenberger'
estimate_bias = true;       % true: augment with 3 force bias states
noise_on      = 1;          % 1: add sensor noise in Simulink, 0: clean

sigma_F   = 20;              % N, force / model uncertainty
sigma_d   = 2;               % N per sample, random walk of the force bias
sigma_ang = 0.05 * pi/180;   % rad, AHRS noise
sigma_z   = 0.005;           % m, ultrasonic sensor noise

Qn = eye(3) * sigma_F^2;
Rn = diag([sigma_ang^2, sigma_ang^2, sigma_z^2]);

if estimate_bias
    nd = 3;
    Ae = [Ad, Bd; zeros(nd,6), eye(nd)];
    Be = [Bd; zeros(nd,3)];
    Ce = [Cd, zeros(3,nd)];
    Ge = blkdiag(Bd, eye(nd));           % noise enters as force + bias drift
    Qe = blkdiag(Qn, sigma_d^2*eye(nd));
else
    nd = 0;
    Ae = Ad;  Be = Bd;  Ce = Cd;  Ge = Bd;  Qe = Qn;
end
nxe = 6 + nd;
assert(rank(obsv(Ae, Ce)) == nxe, 'Estimator model is not observable');

switch lower(estimator)
    case 'kalman'
        % Same input matrix for the noise as for the forces (plus bias drift)
        sys_kf = ss(Ae, [Be Ge], Ce, zeros(3, 3 + size(Ge,2)), Ts);
        [~, L_est, P_est, M_est] = kalman(sys_kf, Qe, Rn);   % L_est = Ae*M_est
    case 'luenberger'
        % Pole placement from the same matrices, ~3x faster than the LQR
        wo = [28 30 32];  zo = 0.8;                         % rad/s, damping
        s_obs = [-zo*wo + 1j*wo*sqrt(1-zo^2), -zo*wo - 1j*wo*sqrt(1-zo^2)];
        if estimate_bias, s_obs = [s_obs, -15, -16, -17]; end
        L_est = place(Ae', Ce', exp(s_obs*Ts)).';
        M_est = Ae \ L_est;                                  % current form gain
    otherwise
        error('estimator must be ''kalman'' or ''luenberger''');
end

% Matrices loaded by the "Estimador" subsystem in Simulink
Aest   = Ae - L_est*Ce;                    % Discrete State-Space, input [dF; y]
Best   = [Be, L_est];
Cest   = [eye(nxe) - M_est*Ce, M_est];     % correction gain, input [xbar; y]
x0_hat = [0; 0; 0; 0; z0; 0; zeros(nd,1)]; % start at the assembled pose
Cmeas  = Cd * S_deg2si;                    % plant bus (deg) -> y (rad, m)
Sel_x  = eye(6, nxe);                      % first 6 estimated states (scope)

% Controller acting on the estimate: dF = K_ctrl*(r_ref - xhat)
if estimate_bias
    K_ctrl = [K, eye(nd)];                 % = K*(r - xhat) - dhat
else
    K_ctrl = K;
end
r_ref = [0; 0; 0; 0; 1.8; 0; zeros(nd,1)];


%% 5. SUMMARY ------------------------------------------------------------
fprintf('\n--- Results ---------------------------------------------\n');
fprintf('Sample time      : %.3f s\n', Ts);
fprintf('F_trim           : [%.1f %.1f %.1f] N\n', F_trim);
fprintf('Assembled z0     : %.4f m\n', z0);
fprintf('max|K|           : %.2f\n', max(abs(K(:))));
fprintf('Estimator        : %s, bias states = %d\n', estimator, nd);
fprintf('max closed loop |z| : %.4f  (must be < 1)\n', max(abs(eig(Ad - Bd*K))));
fprintf('max observer   |z| : %.4f  (must be < 1)\n', max(abs(eig(Ae - L_est*Ce))));
fprintf('\nNext: run crear_estimador.m (builds MARLUP_conKF.slx). Blocks:\n');
fprintf('  Control gain         ->  K_ctrl\n');
fprintf('  References           ->  r_ref\n');
fprintf('  piston bias constant ->  F_trim\n');
fprintf('  Estimador subsystem  ->  Aest, Best, Cest, x0_hat, Cmeas, Rn, noise_on\n');
fprintf('---------------------------------------------------------\n');