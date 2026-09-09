%% =====================================================================
%  MARLUP - Init para Simulink
%  Ejecutar antes de abrir/simular el modelo (o ponerlo en InitFcn).
%  Estado: x = [alpha alpha_dot theta theta_dot z z_dot]'
%  Salida: y = [roll pitch heave]'
%  Entrada generalizada: u = [tau_x tau_y Fz]'
%% =====================================================================
clear; clc;

%% --- Geometria --------------------------------------------------------
H   = 0.11;                     % altura piramide [m]
Rb  = 0.13;                     % radio circunscrito base [m]
Ra  = 0.65;                     % radio de anclaje de los pistones [m]
hc  = 0.00;                     % altura del CG sobre el plano de anclaje [m]
phi = deg2rad([-30 90 210]);    % azimut de los anclajes
s_t = -1;                       % -1 inclinacion hacia el eje, +1 hacia afuera

den = sqrt(Rb^2 + 4*H^2);
uz  = Rb/den;                   % componente vertical del empuje
uh  = 2*H/den;                  % componente radial del empuje

%% --- Asignacion y cinematica -----------------------------------------
Leff = Ra*uz + s_t*hc*uh;                 % brazo efectivo

T = [ Leff*sin(phi);                      % tau_x
     -Leff*cos(phi);                      % tau_y
      uz*ones(1,3) ];                     % Fz
Tinv = inv(T);                            % fuerzas de piston <- esfuerzos
W    = T.';                               % q = W*[alpha; theta; z]
Winv = inv(W);                            % pose <- carrera de pistones

%% --- Inercias ---------------------------------------------------------
Jx = 6.19446;
Jy = 6.19446;
M  = 58.5349 + 3*(0.492345 + 1.25618 + 0.667284) + 1.92617;
g  = 9.81;
Jv = [Jx Jy M];

%% --- Planta -----------------------------------------------------------
A = zeros(6); A(1,2)=1; A(3,4)=1; A(5,6)=1;

Bu = zeros(6,3);
Bu(2,1) = 1/Jx;  Bu(4,2) = 1/Jy;  Bu(6,3) = 1/M;

BF = Bu*T;                                % si prefieres entrada = [F1 F2 F3]

C = [1 0 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 0 1 0];
D = zeros(3,3);

n = 6; p = 3; m = 3;

%% --- Reordenamiento del oleaje ---------------------------------------
% El bloque de oleaje entrega [heave; pitch; roll]; el modelo usa
% [roll; pitch; heave]
P_reorder = [0 0 1;
             0 1 0;
             1 0 0];

%% --- Pesos LQR derivados del ancho de banda --------------------------
wn   = [6 6 6];                 % rad/s [roll pitch heave]
zeta = [0.8 0.8 0.8];
Fmax = 5000;                    % N por piston (para escalar R)

umax = abs(T)*(Fmax*ones(3,1));
R    = diag(1./umax.^2);

qp = zeros(1,3); qv = zeros(1,3);
for k = 1:3
    r     = R(k,k);
    qp(k) = r*Jv(k)^2*wn(k)^4;
    qv(k) = 2*r*Jv(k)^2*wn(k)^2*(2*zeta(k)^2 - 1);
end
Q = diag([qp(1) qv(1) qp(2) qv(2) qp(3) qv(3)]);

K = lqr(A, Bu, Q, R);           % LQR puro (sin integrador)

%% --- LQI --------------------------------------------------------------
Aa = [A zeros(n,p); -C zeros(p,p)];
Ba = [Bu; zeros(p,m)];

wi = wn/4;
Qi = diag(qp .* wi.^2);
Qa = blkdiag(Q, Qi);

Ka = lqr(Aa, Ba, Qa, R);
Kx = Ka(:, 1:n);                % 3x6  sobre xhat
Ki = Ka(:, n+1:end);            % 3x3  sobre el integrador

%% --- Feedforward de gravedad -----------------------------------------
F_grav = T \ [0; 0; M*g];       % [N] por piston  (~435 N c/u)
u_grav = [0; 0; M*g];

%% --- Discretizacion y Kalman -----------------------------------------
Ts = 0.01;                      % MISMO valor en todos los bloques discretos
[Ad, Bd, Cd, Dd] = ssdata(c2d(ss(A,Bu,C,D), Ts, 'zoh'));

Gw = eye(6);
Qw = diag([1e-7 1e-4 1e-7 1e-4 1e-7 1e-4]);            % ruido de proceso
Rv = diag([(0.5*pi/180)^2, (0.5*pi/180)^2, (3e-3)^2]); % 0.5 deg, 3 mm
Nn = zeros(6,3);

Ld = dlqe(Ad, Gw, Cd, Qw, Rv, Nn);

%% --- Limites para saturacion y anti-windup ---------------------------
F_sat  = 8000;                          % N por piston
xi_max = abs(Ki) \ (umax*0.8);          % tope del integrador (clamping)
q_sat  = 0.45;                          % carrera util por piston [m]

%% --- Referencias sugeridas -------------------------------------------
ref_roll  = 0;
ref_pitch = 0;
ref_heave = 0.10;               % m  (mantener por debajo de q_sat/uz)

save('marlup_params.mat');

fprintf('uz=%.4f  Leff=%.4f  M=%.3f kg  F_grav=%.1f N/piston  Ts=%.3f s\n', ...
        uz, Leff, M, F_grav(1), Ts);