%% ==============================================================
%  MARLUP – Modelo, Kalman (discreto) y Control LQI (x̂ + integrador)
%  Oleaje como disturbio en SALIDA:
%        y_total = C*x + P_reorder * y_amb   (no usar A*(x+x_a))
%  ===============================================================

clear; clc;

%% === Geometría / Asignación de actuadores ===
H  = 0.11;          % [m]
Rb = 0.13;          % [m]
uz = Rb / sqrt(Rb^2 + 4*H^2);

phi = deg2rad([-30, 90, 210]);  % [rad]
Rt  = 0.65;                     % [m]

% [tau_x; tau_y; Fz] = T * [F1; F2; F3]
T = uz * [ Rt*sin(phi(1))  Rt*sin(phi(2))  Rt*sin(phi(3));
          -Rt*cos(phi(1)) -Rt*cos(phi(2)) -Rt*cos(phi(3));
           1               1               1            ];
Tinv = pinv(T);

%% === Inercia del plato ===
Jx   = 6.19446;     % kg*m^2
Jy   = 6.19446;     % kg*m^2
Mass = 58.54 + 1.93 +3*( 1.453 + 0.5 + 1.26 + 0.66);     % [kg]     Contemplando planta final. 

%% === Planta ideal (sin amortiguamiento/rigidez) ===
% x = [alpha  alpha_dot  theta  theta_dot  z  z_dot]^T
A = [0 1 0 0 0 0;
     0 0 0 0 0 0;
     0 0 0 1 0 0;
     0 0 0 0 0 0;
     0 0 0 0 0 1;
     0 0 0 0 0 0];

B = [0     0     0;
     1/Jx  0     0;
     0     0     0;
     0     1/Jy  0;
     0     0     0;
     0     0     1/Mass];

% y = [roll  pitch  heave]^T
C = [1 0 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 0 1 0];

D = zeros(3,3);

sys = ss(A,B,C,D);
assert(rank(ctrb(sys))==size(A,1),'Planta no controlable');

%% === Discretización ===
Ts  = 0.01;                  % IMPORTANTE: usar este Ts en TODOS los bloques discretos
sysd = c2d(sys, Ts, 'zoh');
[Ad, Bd, Cd, Dd] = ssdata(sysd);

%% Control LQR
%            .    .   .
% x =    [ a a  t t z z]
Q = 100*diag([50,1,50,1,25,1]); % Penaliza el error en posiciones, no velocidades
% u =    [Tx   Ty   Fz ]
R = diag([0.05, 0.05, 0.01]); % Penaliza el uso de entrada de control

K = lqr(A,B,Q,R);

%% Ganancia de Pre-compensación (Kr)
% Matriz del sistema en lazo cerrado (sin observador, para análisis de estado estacionario)
A_cl = A - B*K;
% Queremos encontrar Kr tal que y_ss = C*(-inv(A-BK)*B*Kr)*r = r
% Esto implica que C*(-inv(A-BK)*B*Kr) debe ser la matriz identidad.
Kr = pinv(C * (-inv(A_cl)) * B);
