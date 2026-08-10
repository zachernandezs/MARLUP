%% ==============================================================
%  MARLUP – Modelo, Kalman (discreto) y Control LQI (x̂ + integrador)
%  Oleaje como disturbio en SALIDA:
%        y_total = C*x + P_reorder * y_amb   (no usar A*(x+x_a))
%  ===============================================================

clear; clc;
gain = 1;

% Piezas CAD (.SLDPRT) que cargan los bloques File Solid del modelo:
% se agregan al path para que los bloques las encuentren por nombre,
% sin rutas absolutas (funciona en cualquier máquina del equipo)
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'CAD'));

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
M_Plato = 58.5349;     % kg
Mass = M_Plato + 3*(0.492345 + 1.25618 + 0.667284) + 1.92617;
g = 9.81;
Mg = Mass*g;

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

G = [0; 0; 0; 0; 0; -g];

% y = [roll  pitch  heave]^T
C = [1 0 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 0 1 0];

D = zeros(3,3);

sys = ss(A,B,C,D);
assert(rank(ctrb(sys))==size(A,1),'Planta no controlable');

%% === Reordenamiento del oleaje (de bloques a salidas del modelo) ===
% Oleaje entrega: y_amb = [heave; pitch; roll]
% Modelo espera:  y     = [ roll;  pitch; heave]
P_reorder = [0 0 1;   % roll   ← 3ª
             0 1 0;   % pitch  ← 2ª
             1 0 0];  % heave  ← 1ª

%% === Discretización ===
Ts  = 0.01;                  % IMPORTANTE: usar este Ts en TODOS los bloques discretos
sysd = c2d(sys, Ts, 'zoh');
[Ad, Bd, Cd, Dd] = ssdata(sysd);

%% === Kalman discreto (dlqe) ===================================
G  = eye(6);   % n×w → w = 6

% Proceso: más incertidumbre en velocidades; lo hacemos más "rápido"
Qx = 30 * diag([1e-6 1e-3 1e-6 1e-3 1e-6 1e-3]);  % ×30 de proceso

% Medición: roll/pitch 0.5°, heave 3 mm
Rn = diag([(0.5*pi/180)^2, (0.5*pi/180)^2, (3e-3)^2]);
N  = zeros(6,3);  % w×p = 6×3

% Chequeo
w = size(G,2); p = size(Cd,1);
assert(all(size(Qx)==[w w]));
assert(all(size(Rn)==[p p]));
assert(all(size(N )==[w p]));

[Ld, ~, ~] = dlqe(Ad, G, Cd, Qx, Rn, N);  % Ld: 6×3

%% ==============================================================
%  LQI: Control Óptimo con Acción Integral
%  Objetivo: eliminar error de estado estacionario ante Mg (y
%  cualquier otra fuerza constante no modelada: fricción, offset
%  de sensores) SIN necesitar conocerla explícitamente.
%  ===============================================================

n = size(A,1);   % 6 estados físicos
p = size(C,1);   % 3 salidas (roll, pitch, heave)
m = size(B,2);   % 3 entradas (tau_x, tau_y, Fz)

% --- Planta aumentada ---
% xi_dot = r - y = r - C*x   (integral del error de salida)
Aa = [A             zeros(n,p);
     -C             zeros(p,p)];
Ba = [B; zeros(p,m)];

assert(rank(ctrb(Aa,Ba)) == n+p, ...
    'Sistema aumentado no controlable: revisar C');

%% === Pesos LQI (validados: ~10s asentamiento, <1% sobreimpulso) ===
% Orden Q: [alpha  alpha_dot  theta  theta_dot  z  z_dot]
Q  = diag([5   8   5   8   50   80]);
R  = diag([0.5 0.5 0.06]);          % [tau_x  tau_y  Fz]

% Orden Qi: [roll_i  pitch_i  heave_i]
% heave_i es el más alto: es el integrador que cancela Mg
Qi = diag([1  1  12]);

Qa = blkdiag(Q, Qi);

% --- Diseño LQR sobre la planta aumentada ---
Ka = lqr(Aa, Ba, Qa, R);

Kx = Ka(:, 1:n);      % ganancia sobre los 6 estados físicos
Ki = Ka(:, n+1:end);  % ganancia sobre los 3 estados integrales

% --- Verificación de estabilidad ---
eig_cl = eig(Aa - Ba*Ka);
assert(all(real(eig_cl) < 0), 'Lazo cerrado LQI inestable');
disp('Polos en lazo cerrado (LQI):'); disp(eig_cl);
