% MARLUP
% Written by:
%               Alvaro Perez
%               Aaron Salas
%               William Smith
%

clear;

Ts = 0.01;                      % sample time [s]
z0 = 1.571637930257020;         % assembled heave [m]

% Identified plant
W = [-0.002771924482755   0.005739054496021  -0.002923634654780;
     -0.005027416010180   0.000007232712827   0.004871901244289;
      0.012335716490594   0.012191287899931   0.012053881119175];
c = [-0.036026972572833; 0.224216631566696; -9.924449576046474];

A = zeros(6); A(1,2) = 1; A(3,4) = 1; A(5,6) = 1;
B = zeros(6,3); B([2 4 6],:) = W;
C = [1 0 0 0 0 0; 0 0 1 0 0 0; 0 0 0 0 1 0];
sysd = c2d(ss(A,B,C,zeros(3)), Ts, 'zoh');
Ad = sysd.A; Bd = sysd.B; Cd = sysd.C;

% Constant1 (bias) and Constant (reference)
F_trim = -W \ c;
x_ref  = [0; 0; 0; 0; z0; 0];

% Gain (state feedback): use K if the block sees radians, K_deg if degrees
K     = dlqr(Ad, Bd, diag([2e4 2e3 2e4 2e3 4e3 4e2]), 1e-3*eye(3));
K_deg = K * diag([pi/180 pi/180 pi/180 pi/180 1 1]);

% Saturation, Rate Limiter
F_MIN  = -1000;
F_MAX  =  1000;
F_RATE =  1e5;

% Sensor noise (1 sigma, SI) and Band-Limited White Noise powers (= sigma^2*Ts)
sig_ang  = 0.05*pi/180;   NP_ang  = sig_ang^2  * Ts;   % roll, pitch [rad]
sig_rate = 0.50*pi/180;   NP_rate = sig_rate^2 * Ts;   % rates [rad/s]
sig_z    = 0.005;         NP_z    = sig_z^2    * Ts;   % heave [m]
sig_vz   = 0.010;         NP_vz   = sig_vz^2   * Ts;   % heave rate [m/s]
% (if the noise is added to a signal in degrees, use (sig*180/pi)^2*Ts instead)

% Kalman filter -> Observer (Discrete State-Space block), x0 = x_obs0
Qn = 20^2 * eye(3);
Rn = diag([sig_ang^2, sig_ang^2, sig_z^2]);
Pp = idare(Ad', Cd', Bd*Qn*Bd', Rn, [], []);
L  = Pp*Cd' / (Cd*Pp*Cd' + Rn);

A_obs  = Ad*(eye(6) - L*Cd);
B_obs  = [Bd, Ad*L];
C_obs  = eye(6) - L*Cd;
D_obs  = [zeros(6,3), L];
x_obs0 = x_ref;