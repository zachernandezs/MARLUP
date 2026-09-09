% 1. Define Plant Parameters (Replace with your specific values)
Jx = 6.19446;
Jy = 6.19446;
M  = 58.5349 + 3*(0.492345 + 1.25618 + 0.667284) + 1.92617;
g  = 9.81;

% --- Geometria --------------------------------------------------------
H   = 0.11;                     % altura piramide [m]
Rb  = 0.13;                     % radio circunscrito base [m]
Ra  = 0.65;                     % radio de anclaje de los pistones [m]
hc  = 0.00;                     % altura del CG sobre el plano de anclaje [m]
phi = deg2rad([-30 90 210]);    % azimut de los anclajes
s_t = -1;                       % -1 inclinacion hacia el eje, +1 hacia afuera

den = sqrt(Rb^2 + 4*H^2);
uz  = Rb/den;                   % componente vertical del empuje
uh  = 2*H/den;                  % componente radial del empuje

% --- Asignacion y cinematica -----------------------------------------
Leff = Ra*uz + s_t*hc*uh;                 % brazo efectivo

T = [ Leff*sin(phi);                      % tau_x
     -Leff*cos(phi);                      % tau_y
      uz*ones(1,3) ];                     % Fz
Tinv = inv(T);                            % fuerzas de piston <- esfuerzos
W    = T.';                               % q = W*[alpha; theta; z]
Winv = inv(W);                            % pose <- carrera de pistones

% 2. Construct State-Space Matrices
A = zeros(6,6);
A(1,2) = 1; % alpha derivative
A(3,4) = 1; % theta derivative
A(5,6) = 1; % z (heave) derivative

B = zeros(6,3);
B(2,1) = 1/Jx; % alpha torque input
B(4,2) = 1/Jy; % theta torque input
B(6,3) = 1/M;  % z force input

C = eye(6);
D = zeros(6,3);

% 3. Tune LQR Cost Matrices
% Q penalizes state errors [alpha, alpha_dot, theta, theta_dot, z, z_dot]
% Higher values demand tighter control on that specific state
Q = diag([100, 10, 100, 10, 500, 50]); 

% R penalizes actuator effort [tau_alpha, tau_theta, F_z]
R = diag([1, 1, 0.1]);

% 4. Compute Optimal Feedback Gain
K = lqr(A, B, Q, R);

% 5. Define Equilibrium Input (Gravity Compensation)
U_eq = [0; 0; M*g];