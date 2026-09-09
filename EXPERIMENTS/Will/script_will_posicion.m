%% ================================================================
%  MARLUP - Espacio de estados en POSICION DE PISTONES
%  u  = [u1; u2; u3]  posicion comandada de cada piston [m]
%  x  = [q1 q2 q3 qd1 qd2 qd3]'  posicion y velocidad reales
%  y  = [roll; pitch; heave]     lo que miden los sensores
%
%  Arquitectura: feedforward cinematico + LQI + Kalman discreto
%  ================================================================
clear; clc;

%% === 1. Geometria: una sola matriz T para todo ==================
Hp = 0.11;  Rb = 0.13;  Rt = 0.65;
uz = Rb / sqrt(Rb^2 + 4*Hp^2);
phi = deg2rad([-30, 90, 210]);

% [tau_x; tau_y; Fz] = T * [F1; F2; F3]      (la del paper, sin cambios)
T = uz * [ Rt*sin(phi(1))  Rt*sin(phi(2))  Rt*sin(phi(3));
          -Rt*cos(phi(1)) -Rt*cos(phi(2)) -Rt*cos(phi(3));
           1               1               1            ];

W    = T.';        % [q1;q2;q3]      = W    * [alpha; theta; z]
Winv = inv(W);     % [alpha;theta;z] = Winv * [q1; q2; q3]

fprintf('det(T) = %.4f   cond(W) = %.2f\n', det(T), cond(W));
assert(cond(W) < 50, 'W mal condicionada: revisar geometria');

q_lim = 0.5;       % carrera maxima por piston [m]

%% === 2. Dinamica del actuador -> A, B, C, D =====================
% Modelo de segundo orden del lazo de posicion interno del Rexroth:
%   qdd_i = wa^2*(u_i - q_i) - 2*za*wa*qd_i
wa = 20;           % [rad/s] ancho de banda del servo (~3 Hz)
za = 0.9;          % amortiguamiento del servo

A = [ zeros(3)      eye(3);
     -wa^2*eye(3)  -2*za*wa*eye(3) ];

B = [ zeros(3);
      wa^2*eye(3) ];

C = [ Winv  zeros(3) ];    % sensores miden pose, no pistones
D = zeros(3);

sys = ss(A,B,C,D);
assert(rank(ctrb(A,B)) == 6, 'No controlable');
assert(rank(obsv(A,C)) == 6, 'No observable');
fprintf('Polos del actuador: %s\n', mat2str(round(eig(A),2)));

%% === 3. LQI (LQR + accion integral sobre el error de piston) ====
n = 6; p = 3; m = 3;

Aa = [ A              zeros(n,p);
      -eye(3) zeros(3) zeros(p,p) ];    % xi_dot = q_ref - q
Ba = [ B; zeros(p,m) ];

% Bryson: normalizar por los maximos fisicos
q_max  = q_lim;    % error de posicion tolerable [m]
qd_max = 0.5;      % velocidad de piston [m/s]
u_max  = q_lim;    % comando maximo [m]

Q  = diag([ (1/q_max^2)*ones(1,3), (1/qd_max^2)*ones(1,3) ]);
Qi = diag( 8*(1/q_max^2)*ones(1,3) );   % peso integral
R  = diag( (1/u_max^2)*ones(1,3) ) * 0.5;

Ka = lqr(Aa, Ba, blkdiag(Q,Qi), R);
Kx = Ka(:, 1:n);          % sobre [q; qd] estimados
Ki = Ka(:, n+1:end);      % sobre la integral del error

assert(all(real(eig(Aa - Ba*Ka)) < 0), 'Lazo cerrado inestable');

%% === 4. Discretizacion (CRITICO para el Kalman) =================
Ts   = 0.01;
sysd = c2d(sys, Ts, 'zoh');
[Ad, Bd, Cd, Dd] = ssdata(sysd);       % <-- usar ESTAS en el bloque KF

Kxd = Kx;  Kid = Ki * Ts;              % ganancia integral discretizada

%% === 5. Kalman discreto =========================================
Gk = eye(6);                            % nombre propio: no pisa nada
Qk = diag([1e-8 1e-8 1e-8 1e-5 1e-5 1e-5]);          % ruido de proceso
Rk = diag([(0.5*pi/180)^2, (0.5*pi/180)^2, (3e-3)^2]); % AHRS + MB1040
Nk = zeros(6,3);

[Ld, Pd, ~] = dlqe(Ad, Gk, Cd, Qk, Rk, Nk);

fprintf('Desv. est. de q estimada : %.3f mm\n', 1e3*sqrt(Pd(1,1)));
fprintf('Desv. est. de qd estimada: %.3f mm/s\n', 1e3*sqrt(Pd(4,4)));

%% === 6. Ley de control para Simulink ============================
%  q_ref = W * [-alpha_amb; -theta_amb; z_set - z_amb]   (feedforward)
%  q_ref = sat(q_ref, +-0.5)
%  e     = q_ref - xhat(1:3)
%  xi    = Discrete-Time Integrator(e), Ts = 0.01, anti-windup clamping
%  u     = q_ref + Kxd*[e; -xhat(4:6)] + Kid*xi
%  u     = sat(u, +-0.5)
%
%  Bloque Kalman Filter (Discrete): A=Ad, B=Bd, C=Cd, D=0,
%                                   Q=Qk, R=Rk, N=Nk, Ts=0.01
%  Entradas: u (la misma que va al actuador), y_sensado

%% === 7. Validacion ==============================================
Br = [zeros(n,p); eye(p)];
Ca = [eye(3) zeros(3) zeros(3)];
sys_cl = ss(Aa - Ba*Ka, Br, Ca, zeros(p));

figure; step(sys_cl, 2); grid on;
legend('q_1','q_2','q_3');
title('LQI en espacio de pistones - escalon de referencia');

% Rechazo del oleaje: comparar feedforward solo vs feedforward + LQI
f_wave = logspace(-2, 1, 300);
figure; bodemag(sys_cl(1,1), f_wave); grid on;
xline(0.63, 'r--', 'Oleaje T_p=10s');
title('Seguimiento de referencia en la banda del oleaje');

%% === 8. Resumen =================================================
disp('--- Para Simulink ---');
disp('W    ='); disp(W);
disp('Winv ='); disp(Winv);
disp('Kxd  ='); disp(Kxd);
disp('Kid  ='); disp(Kid);
disp('Ld   ='); disp(Ld);