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
estimate_bias = false;      % true: augment with 3 force bias states
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

%% 5. MATRICES PARA EL BLOQUE "KALMAN FILTER" DE SIMULINK ----------------
% El bloque Kalman Filter (Control System Toolbox) hace por dentro lo mismo
% que el subsistema "Estimador" de la seccion 4, pero pide las matrices ya
% preparadas. Con "Model source = Individual A, B, C, D matrices" el modelo
% que asume el bloque es:
%
%   x[k+1] = A*x[k] + B*u[k] + G*w[k]
%   y[k]   = C*x[k] + D*u[k] + H*w[k] + v[k]
%   E{w*w'} = Q,   E{v*v'} = R,   E{w*v'} = N
%
% con u[k] = dF = F - F_trim  [N]  y  y[k] = [roll; pitch; z] en rad y m
% (si el bus de la planta trae los angulos en grados, multiplicar antes por
% Cmeas / S_deg2si, igual que en el subsistema Estimador).
%
% Pestanas del bloque:
%   Model Parameters : A, B, C, D, Sample time, Initial states x[0],
%                      State estimation error covariance P[0]
%   Options          : G, H, Q, R, N  (Noise characteristics)

use_bias_in_kf = estimate_bias;   % true: filtro sobre el modelo aumentado

if use_bias_in_kf
    % Modelo aumentado con los 3 estados de bias de fuerza (9 estados)
    KF_A = Ae;   KF_B = Be;   KF_C = Ce;
    KF_Gf = Ge;                 % ruido fisico: fuerza + deriva del bias
    KF_Qf = Qe;                 % blkdiag(sigma_F^2*I, sigma_d^2*I)
else
    % Modelo simple de 6 estados (roll, pitch, z y sus velocidades)
    KF_A = Ad;   KF_B = Bd;   KF_C = Cd;
    KF_Gf = Bd;                 % el ruido de proceso entra como fuerza
    KF_Qf = Qn;                 % sigma_F^2 * I(3)
end

nx_kf = size(KF_A,1);           % 6 sin bias, 9 con bias
nu_kf = size(KF_B,2);           % 3 fuerzas
ny_kf = size(KF_C,1);           % 3 medidas

% El bloque solo usa el producto G*Q*G', pero exige que la matriz
% [G*Q*G' , G*Q*H'+G*N ; ... , R] sea semidefinida positiva y lo comprueba
% con tolerancia cero. Bd*Qn*Bd' tiene rango 3 sobre 6 estados, es decir es
% singular, y el redondeo deja autovalores del orden de -1e-22 que el
% bloque rechaza aunque en relativo sean cero. Por eso se le entrega el
% ruido ya proyectado sobre los estados (G = I): se simetriza, se recortan
% los autovalores negativos de redondeo y se anade una cresta despreciable
% (1e-12 relativo) que garantiza PSD estricta sin alterar el filtro.
Qw = KF_Gf * KF_Qf * KF_Gf.';
Qw = (Qw + Qw.')/2;
[Vq, Dq] = eig(Qw);
dq = max(real(diag(Dq)), 0);
Qw = Vq*diag(dq)*Vq.';
Qw = (Qw + Qw.')/2 + (max(dq)*1e-12)*eye(nx_kf);

KF_G = eye(nx_kf);              % ruido ya expresado sobre los estados
KF_Q = Qw;                      % = Gf*Qf*Gf' regularizada
nw_kf = size(KF_G,2);           % entradas de ruido de proceso

KF_D = zeros(ny_kf, nu_kf);     % sin transmision directa de la fuerza
KF_H = zeros(ny_kf, nw_kf);     % w no llega directo a la salida
KF_R = Rn;                      % diag([sigma_ang^2 sigma_ang^2 sigma_z^2])
KF_N = zeros(nw_kf, ny_kf);     % w y v independientes

% Condiciones iniciales del bloque
KF_x0 = [0; 0; 0; 0; z0; 0; zeros(nx_kf-6,1)];   % arranca en la pose montada
KF_P0 = diag([(1*pi/180)^2, (5*pi/180)^2, ...    % roll, roll_dot
              (1*pi/180)^2, (5*pi/180)^2, ...    % pitch, pitch_dot
               0.02^2,       0.10^2, ...         % z, z_dot
               repmat((5*sigma_F)^2, 1, nx_kf-6)]);  % bias de fuerza

% Escalado del bus del sensor: la planta entrega los angulos en grados
% (ganancias 180/pi dentro de PLANT - PLATFORM) mientras que Cd trabaja en
% rad. Este bloque va entre la salida Y_sensado y la entrada y del filtro.
S_meas = diag([pi/180, pi/180, 1]);   % [deg; deg; m] -> [rad; rad; m]

% Comprobacion: el bloque debe converger a la misma ganancia que kalman()
assert(rank(obsv(KF_A, KF_C)) == nx_kf, 'El modelo del KF no es observable');
Mpsd = [KF_G*KF_Q*KF_G.',                        KF_G*KF_Q*KF_H.' + KF_G*KF_N;
       (KF_G*KF_Q*KF_H.' + KF_G*KF_N).',         KF_H*KF_Q*KF_H.' + KF_H*KF_N + KF_N.'*KF_H.' + KF_R];
assert(min(eig((Mpsd+Mpsd.')/2)) >= 0, 'La matriz de ruido del bloque no es PSD');
sys_kf_blk = ss(KF_A, [KF_B KF_G], KF_C, [KF_D KF_H], Ts);
[~, L_kf, ~, M_kf] = kalman(sys_kf_blk, KF_Q, KF_R, KF_N);
assert(max(abs(eig(KF_A - L_kf*KF_C))) < 1, 'El KF no es estable');


%% 6. SUMMARY ------------------------------------------------------------
fprintf('\n--- Results ---------------------------------------------\n');
fprintf('Sample time      : %.3f s\n', Ts);
fprintf('F_trim           : [%.1f %.1f %.1f] N\n', F_trim);
fprintf('Assembled z0     : %.4f m\n', z0);
fprintf('max|K|           : %.2f\n', max(abs(K(:))));
fprintf('Estimator        : %s, bias states = %d\n', estimator, nd);
fprintf('max closed loop |z| : %.4f  (must be < 1)\n', max(abs(eig(Ad - Bd*K))));
fprintf('max observer   |z| : %.4f  (must be < 1)\n', max(abs(eig(Ae - L_est*Ce))));
fprintf('KF block states  : %d (bias incluido: %d)\n', nx_kf, use_bias_in_kf);
fprintf('max KF block   |z| : %.4f  (must be < 1)\n', max(abs(eig(KF_A - L_kf*KF_C))));
fprintf('\nNext: run crear_estimador.m (builds MARLUP_conKF.slx). Blocks:\n');
fprintf('  Control gain         ->  K_ctrl\n');
fprintf('  References           ->  r_ref\n');
fprintf('  piston bias constant ->  F_trim\n');
fprintf('  Estimador subsystem  ->  Aest, Best, Cest, x0_hat, Cmeas, Rn, noise_on\n');
fprintf('\nBloque "Kalman Filter" (Model Parameters / Options):\n');
fprintf('  A,B,C,D = KF_A, KF_B, KF_C, KF_D    Sample time = Ts\n');
fprintf('  x[0] = KF_x0    P[0] = KF_P0\n');
fprintf('  G,H = KF_G, KF_H    Q,R,N = KF_Q, KF_R, KF_N\n');
fprintf('---------------------------------------------------------\n');
