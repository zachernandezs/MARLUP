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
