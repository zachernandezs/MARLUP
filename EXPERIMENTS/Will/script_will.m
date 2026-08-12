%% ================================================================
%  MARLUP - Control Stage 2
%  Diseno de control LQI (LQR + accion integral) + Filtro de Kalman
%  discreto, con feedforward de gravedad.
%
%  Autores: Alvaro Perez Mora / William Smith Hernandez
%  Instituto Tecnologico de Costa Rica - TECSpace
%
%  ----------------------------------------------------------------
%  INDICE
%    1. Configuracion general
%    2. Parametros fisicos y geometria
%    3. Matriz de asignacion de actuadores (T)
%    4. Modelo en espacio de estados
%    5. Discretizacion
%    6. Estimador: Filtro de Kalman discreto
%    7. ESPECIFICACION DE DESEMPENO  <-- AQUI SE TUNEA
%    8. Sintesis de pesos Q, R, Qi
%    9. Diseno LQI
%   10. Feedforward de gravedad
%   11. Saturaciones y anti-windup
%   12. Verificacion numerica
%   13. Resumen para Simulink
%
%  ----------------------------------------------------------------
%  CAMBIOS RESPECTO A LA VERSION ANTERIOR
%    (a) Se agrego feedforward de gravedad (u_ff = M*g en el canal
%        Fz). Sin esto el LQR debia "inventar" un error enorme para
%        generar los ~664 N que sostienen el plato, y por eso solo
%        se observaban 20-30 N por piston.
%    (b) Q y R ya NO se escogen a mano. Se derivan de la
%        especificacion fisica (wn, zeta, wi) mediante una formula
%        cerrada exacta (ver seccion 8). Los pesos anteriores daban
%        wn ~ 0.65 rad/s, es decir, el mismo ancho de banda que el
%        oleaje (wp ~ 0.63 rad/s): el lazo seguia la perturbacion en
%        vez de rechazarla.
%    (c) Se corrigio la colision de la variable G, que se usaba a la
%        vez para el vector de gravedad y para la matriz de ruido de
%        proceso del Kalman. Ahora son Gg y Gw.
%    (d) Se eliminaron las secciones duplicadas al final del script
%        original ("Control LQR", "Observador", "Kr"), que
%        sobreescribian Q, R y K despues del diseno LQI.
%  ================================================================

clear; clc; close all;

%% ================================================================
%  1. CONFIGURACION GENERAL
%  ================================================================

Ts = 0.01;          % [s] periodo de muestreo GLOBAL.
                    % Debe ser identico en TODOS los bloques discretos
                    % de Simulink (Kalman, integrador, ZOH, controlador).

% Piezas CAD (.SLDPRT) que cargan los bloques File Solid del modelo
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'CAD'));

VERBOSE = true;     % imprimir resumen y graficas de validacion


%% ================================================================
%  2. PARAMETROS FISICOS Y GEOMETRIA
%  ================================================================

% --- Piramide triangular invertida (soporte de actuadores) ---
H  = 0.11;                          % [m] altura de la piramide
Rb = 0.13;                          % [m] radio circunscrito de la base
uz = Rb / sqrt(Rb^2 + 4*H^2);       % componente vertical del vector
                                    % de empuje unitario de cada actuador

% --- Plato superior ---
Rt  = 0.65;                         % [m] radio de aplicacion en el plato
phi = deg2rad([-30, 90, 210]);      % [rad] posicion angular de los 3 puntos

Jx = 6.19446;                       % [kg*m^2] inercia roll
Jy = 6.19446;                       % [kg*m^2] inercia pitch
M_plato = 58.5349;                  % [kg] masa del plato

% Masa total suspendida = plato + partes moviles de los 3 actuadores + herraje
Mass = M_plato + 3*(0.492345 + 1.25618 + 0.667284) + 1.92617;   % [kg]

Mg = Mass*9.81;                           % [m/s^2]

% --- Coherencia geometrica (chequeo, no afecta el diseno) ---
% Para un disco uniforme, J = M*R^2/4. Si Rt y Jx son coherentes,
% el error debe ser pequeno (<5%). Esto valida que Rt = 0.65 m es el
% radio real del plato y no un valor arrastrado.
J_disco = M_plato * Rt^2 / 4;
err_J   = abs(J_disco - Jx)/Jx;
if err_J > 0.05
    warning('MARLUP:geom', ...
        'Rt=%.3f m y Jx=%.4f kg*m^2 no son coherentes (error %.1f%%). Revisar CAD.', ...
        Rt, Jx, 100*err_J);
end


%% ================================================================
%  3. MATRIZ DE ASIGNACION DE ACTUADORES
%  ================================================================
%  [tau_x; tau_y; Fz] = T * [F1; F2; F3]

T = uz * [ Rt*sin(phi(1))   Rt*sin(phi(2))   Rt*sin(phi(3));
          -Rt*cos(phi(1))  -Rt*cos(phi(2))  -Rt*cos(phi(3));
           1                1                1              ];

Tinv = pinv(T);     % esfuerzos generalizados -> fuerzas de piston

assert(rank(T) == 3, 'T singular: la geometria no permite control en 3 ejes');

if cond(T) > 20
    warning('MARLUP:Tcond', 'cond(T) = %.1f, geometria mal condicionada', cond(T));
end


%% ================================================================
%  4. MODELO EN ESPACIO DE ESTADOS
%  ================================================================
%  x = [alpha  alpha_dot  theta  theta_dot  z  z_dot]^T
%  u = [tau_x  tau_y  Fz]^T
%  y = [roll   pitch    heave]^T

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

C = [1 0 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 0 1 0];

D = zeros(3,3);

% Vector de gravedad (entra como aceleracion constante en z_dot).
% NO forma parte de A: se compensa explicitamente en la seccion 10.
Gg = [0; 0; 0; 0; 0; -g];

n = size(A,1);      % 6 estados fisicos
p = size(C,1);      % 3 salidas
m = size(B,2);      % 3 entradas

sys = ss(A,B,C,D);
assert(rank(ctrb(A,B)) == n, 'Planta no controlable');
assert(rank(obsv(A,C)) == n, 'Planta no observable');

% --- Reordenamiento del oleaje (bloques -> salidas del modelo) ---
% El subsistema Oleaje entrega y_amb = [heave; pitch; roll]
% El modelo espera                y = [roll;  pitch; heave]
P_reorder = [0 0 1;
             0 1 0;
             1 0 0];


%% ================================================================
%  5. DISCRETIZACION
%  ================================================================

sysd = c2d(sys, Ts, 'zoh');
[Ad, Bd, Cd, Dd] = ssdata(sysd);

% NOTA: el bloque de Kalman en Simulink debe recibir Ad, Bd, Cd, Dd.
% Usar A, B, C, D continuas dentro de un bloque discreto produce
% divergencia del estimador (ese era el bug de la version anterior).


%% ================================================================
%  6. ESTIMADOR: FILTRO DE KALMAN DISCRETO
%  ================================================================
%  El oleaje entra como disturbio de SALIDA, pero fisicamente mueve
%  la planta. Como el modelo no tiene una entrada que genere ese
%  movimiento, el estimador solo puede seguirlo a traves de las
%  mediciones. Por eso el ruido de proceso se modela como una
%  ACELERACION NO MODELADA que actua sobre las velocidades.
%
%  Compromiso:
%    sigma_acc grande -> estimador rapido, sigue el oleaje, pero
%                        inyecta ruido de sensor a las velocidades
%    sigma_acc chico  -> estimador suave, pero xhat se atrasa
%                        respecto al movimiento real

Gw = eye(n);                        % matriz de entrada del ruido de proceso

sigma_acc_ang = 0.1;                % [rad/s^2] aceleracion angular no modelada
sigma_acc_z   = 0.1;                % [m/s^2]   aceleracion vertical no modelada

Qx = diag([1e-8, sigma_acc_ang^2, ...
           1e-8, sigma_acc_ang^2, ...
           1e-8, sigma_acc_z^2  ]);

% Ruido de medicion segun hojas de datos:
%   AHRS 3DM-GX5  : 0.5 deg  en roll y pitch
%   Ultrasonico MB1040 : 3 mm en heave
sigma_ang_sensor = deg2rad(0.5);    % [rad]
sigma_z_sensor   = 3e-3;            % [m]

Rn = diag([sigma_ang_sensor^2, sigma_ang_sensor^2, sigma_z_sensor^2]);

N = zeros(size(Gw,2), p);

assert(isequal(size(Qx), [size(Gw,2) size(Gw,2)]), 'Qx mal dimensionada');
assert(isequal(size(Rn), [p p]),                   'Rn mal dimensionada');

[Ld, ~, ~] = dlqe(Ad, Gw, Cd, Qx, Rn, N);   % Ld: 6x3


%% ================================================================
%  7. ESPECIFICACION DE DESEMPENO   <-- AQUI SE TUNEA
%  ================================================================
%  No se tocan Q ni R directamente. Se especifica el comportamiento
%  deseado en lazo cerrado y la seccion 8 calcula los pesos exactos
%  que lo producen.
%
%  Polos deseados por eje:
%      (s^2 + 2*zeta*wn*s + wn^2) * (s + wi)
%
%  wn   : ancho de banda. DEBE ser >> wp del oleaje (wp ~ 0.63 rad/s
%         para Tp = 10 s). Con wn >= 5 rad/s hay ~8x de margen.
%         Limite superior: Ts (Nyquist = 314 rad/s) y la dinamica de
%         los pistones. wn <= 10 rad/s es seguro.
%  zeta : amortiguamiento. 0.9 -> practicamente sin sobreimpulso.
%         zeta >= 0.7071 es OBLIGATORIO (ver assert en seccion 8).
%  wi   : polo del integrador. wn/4 es un buen compromiso entre
%         velocidad de rechazo de sesgos y sobreimpulso.

% --- Ejes angulares (roll, pitch) ---
wn_ang   = 5.0;                 % [rad/s]
zeta_ang = 0.9;                 % [-]
wi_ang   = wn_ang/4;            % [rad/s]

% --- Eje vertical (heave) ---
% Ligeramente mas rapido: es el eje con mayor amplitud de perturbacion
% y el que carga con la gravedad.
wn_z   = 6.0;                   % [rad/s]
zeta_z = 0.9;                   % [-]
wi_z   = wn_z/4;                % [rad/s]

% Escala global del costo. Solo importa la razon Q/R, asi que rho no
% cambia las ganancias: sirve unicamente para que Q y R queden en
% rangos numericos comodos de reportar.
rho = 1.0;


%% ================================================================
%  8. SINTESIS DE PESOS Q, R, Qi
%  ================================================================
%  Para cada eje desacoplado (doble integrador con entrada 1/J) mas
%  su integrador, el lugar de las raices simetrico da una relacion
%  EXACTA y cerrada entre los pesos y los polos de lazo cerrado:
%
%      q  = r*J^2 * wn^2 * ( wn^2 + 2*wi^2*(2*zeta^2 - 1) )
%      qd = r*J^2 *        ( 2*wn^2*(2*zeta^2 - 1) + wi^2 )
%      qi = r*J^2 * wn^4 * wi^2
%
%  y las ganancias resultantes son exactamente:
%
%      k_pos = J*(wn^2 + 2*zeta*wn*wi)
%      k_vel = J*(2*zeta*wn + wi)
%      k_int = -J*wn^2*wi
%
%  Eligiendo r_i = rho/J_i^2 los pesos quedan independientes de la
%  inercia, lo que los hace directamente comparables entre ejes.

% Restriccion de validez: qd >= 0 exige zeta >= 1/sqrt(2)
assert(zeta_ang >= 1/sqrt(2), 'zeta_ang < 0.7071: qd resultaria negativo');
assert(zeta_z   >= 1/sqrt(2), 'zeta_z < 0.7071: qd resultaria negativo');

r_tau = rho / Jx^2;             % peso de tau_x y tau_y
r_Fz  = rho / Mass^2;           % peso de Fz

[q_ang, qd_ang, qi_ang] = lqi_weights(Jx,   r_tau, wn_ang, zeta_ang, wi_ang);
[q_z,   qd_z,   qi_z  ] = lqi_weights(Mass, r_Fz,  wn_z,   zeta_z,   wi_z  );

% Orden Q:  [alpha  alpha_dot  theta  theta_dot  z  z_dot]
Q = diag([q_ang, qd_ang, q_ang, qd_ang, q_z, qd_z]);

% Orden R:  [tau_x  tau_y  Fz]
R = diag([r_tau, r_tau, r_Fz]);

% Orden Qi: [roll_i  pitch_i  heave_i]
Qi = diag([qi_ang, qi_ang, qi_z]);


%% ================================================================
%  9. DISENO LQI
%  ================================================================
%  Planta aumentada con los 3 estados integrales:
%      xi_dot = r - y = r - C*x

Aa = [A       zeros(n,p);
     -C       zeros(p,p)];
Ba = [B; zeros(p,m)];
Qa = blkdiag(Q, Qi);

assert(rank(ctrb(Aa,Ba)) == n+p, 'Sistema aumentado no controlable');

Ka = lqr(Aa, Ba, Qa, R);

Kx = Ka(:, 1:n);            % ganancia sobre los 6 estados estimados
Ki = Ka(:, n+1:end);        % ganancia sobre los 3 estados integrales

% ----------------------------------------------------------------
%  ATENCION - SIGNO DE Ki
%  Con la convencion Aa = [A 0; -C 0], la matriz Ki sale NEGATIVA.
%  Es correcto y necesario para la estabilidad. La ley de control es
%
%       u = -Kx*xhat - Ki*xi + u_ff
%
%  NO invertir el signo de Ki en Simulink. Si se invierte, el lazo
%  se vuelve inestable.
% ----------------------------------------------------------------
assert(all(diag(Ki) < 0), 'Ki deberia ser negativa: revisar Aa');

eig_cl = eig(Aa - Ba*Ka);
assert(all(real(eig_cl) < 0), 'Lazo cerrado LQI inestable');


%% ================================================================
% 10. FEEDFORWARD DE GRAVEDAD
%  ================================================================
%  El modelo de diseno no contiene la gravedad, asi que el LQI
%  supone que u = 0 mantiene el plato en su sitio. En Simscape no es
%  asi: hacen falta M*g newtons solo para sostenerlo. Sin este
%  termino, el integrador tarda muchisimo y el lazo se satura
%  mientras tanto (sintoma: fuerzas de piston de 20-30 N y el plato
%  hundiendose).

k_ff = 1.0;                                 % factor de ajuste fino (ver nota)

u_ff = k_ff * [0; 0; Mass*g];               % [tau_x; tau_y; Fz]
F_ff = Tinv * u_ff;                         % fuerza estatica por piston [N]

% NOTA sobre k_ff:
% Mass es la masa que se ESTIMA suspendida. Si Simscape reparte el
% peso de forma distinta (p.ej. parte del cilindro descarga en la
% base), el valor exacto puede diferir. Procedimiento de ajuste:
%   1) Correr con k_ff = 1 y referencia constante.
%   2) Leer el valor de regimen del estado integral de heave.
%   3) Si xi_heave converge a un valor distinto de cero, el
%      integrador esta cubriendo el faltante. Ajustar k_ff hasta que
%      xi_heave -> 0.
% El sistema funciona igual con k_ff aproximado; el integrador
% absorbe el resto. El feedforward solo evita el transitorio largo.


%% ================================================================
% 11. SATURACIONES Y ANTI-WINDUP
%  ================================================================
%  Rexroth CDH1 MP3: A = 12.5 cm^2 a 250 bar -> ~31 kN teoricos.
%  Se usa un limite de diseno mucho menor, con margen sobre la carga
%  estatica, para que la saturacion sea informativa y no decorativa.

F_max = 3000;                       % [N] limite por piston (bloque Saturation)
F_min = 0;                          % [N] cilindro de simple efecto en compresion
                                    % (usar -F_max si es de doble efecto)

margen_ff = F_max / max(F_ff);
if margen_ff < 2
    warning('MARLUP:sat', ...
        'F_max = %.0f N deja solo %.1fx sobre la carga estatica (%.0f N/piston).', ...
        F_max, margen_ff, max(F_ff));
end

beta_aw = 0.5;                      % ganancia de anti-windup (0.1 - 1)
                                    % sumar beta_aw*(u_sat - u) a la
                                    % entrada del integrador


%% ================================================================
% 12. VERIFICACION NUMERICA
%  ================================================================

% --- 12.1 Ganancias analiticas vs numericas ---
kpos_ang_teo = Jx*(wn_ang^2 + 2*zeta_ang*wn_ang*wi_ang);
kpos_z_teo   = Mass*(wn_z^2 + 2*zeta_z*wn_z*wi_z);
err_gain = max(abs([Kx(1,1) - kpos_ang_teo, Kx(3,5) - kpos_z_teo]) ./ ...
               [kpos_ang_teo, kpos_z_teo]);
assert(err_gain < 1e-6, 'La sintesis de pesos no reproduce las ganancias teoricas');

% --- 12.2 Estabilidad del lazo DISCRETO con ganancias continuas ---
% El diseno es continuo pero se implementa a Ts = 0.01 s.
Aad = [Ad            zeros(n,p);
      -Ts*Cd         eye(p)    ];
Bad = [Bd; zeros(p,m)];
rho_d = max(abs(eig(Aad - Bad*Ka)));
assert(rho_d < 1, 'Lazo cerrado DISCRETO inestable: reducir wn o Ts');

% --- 12.3 Separacion estimador / controlador ---
% Regla practica: el estimador debe ser 3-10x mas rapido que el lazo.
rate_obs  = -log(abs(eig(Ad - Ad*Ld*Cd)))/Ts;
rate_ctrl = abs(real(eig_cl));
sep = min(rate_obs) / max(rate_ctrl);
if sep < 3
    warning('MARLUP:sep', 'Estimador solo %.1fx mas rapido que el control', sep);
elseif sep > 15
    warning('MARLUP:sep', ...
        'Estimador %.1fx mas rapido: puede inyectar ruido. Bajar sigma_acc_*', sep);
end

% --- 12.4 Respuesta a escalon en lazo cerrado ideal ---
Br     = [zeros(n,p); eye(p)];
Ca     = [C, zeros(p,p)];
sys_cl = ss(Aa - Ba*Ka, Br, Ca, zeros(p,p));

% --- 12.5 Rechazo de gravedad (prueba clave) ---
% Con el feedforward activo, la gravedad ya no deberia aparecer.
% Esta simulacion la aplica SIN feedforward para comprobar que el
% integrador por si solo tambien la cancela (mas lento, pero lo hace).
Bg          = [Gg; zeros(p,1)];
sys_cl_dist = ss(Aa - Ba*Ka, [Br, Bg], Ca, zeros(p,p+1));

t_sim = (0:Ts:20)';
r_in  = [zeros(length(t_sim),2), 1.75*ones(length(t_sim),1)];   % altura objetivo
g_in  = ones(length(t_sim),1);
y_g   = lsim(sys_cl_dist, [r_in, g_in], t_sim);

err_final = abs(y_g(end,3) - 1.75);
assert(err_final < 1e-3, ...
    'El integrador no cancela la gravedad: error final %.4f m', err_final);

if VERBOSE
    figure('Name','Validacion LQI','Position',[100 100 1000 400]);

    subplot(1,2,1);
    step(sys_cl, 8); grid on;
    legend('Roll','Pitch','Heave','Location','southeast');
    title('Respuesta a escalon (referencia unitaria)');

    subplot(1,2,2);
    plot(t_sim, y_g(:,3), 'LineWidth', 1.4); hold on;
    yline(1.75, '--', 'Referencia');
    grid on; xlabel('Tiempo (s)'); ylabel('z (m)');
    title('Heave con gravedad activa (sin feedforward)');
end


%% ================================================================
% 13. RESUMEN PARA SIMULINK
%  ================================================================
if VERBOSE
fprintf('\n');
fprintf('================================================================\n');
fprintf(' MARLUP - Resumen del diseno\n');
fprintf('================================================================\n\n');

fprintf(' PLANTA\n');
fprintf('   Masa suspendida        %8.3f kg\n',     Mass);
fprintf('   Jx = Jy                %8.4f kg*m^2\n', Jx);
fprintf('   uz                     %8.4f\n',        uz);
fprintf('   cond(T)                %8.2f\n\n',      cond(T));

fprintf(' ESPECIFICACION\n');
fprintf('   Angular   wn=%.2f rad/s  zeta=%.2f  wi=%.2f rad/s\n', ...
        wn_ang, zeta_ang, wi_ang);
fprintf('   Heave     wn=%.2f rad/s  zeta=%.2f  wi=%.2f rad/s\n', ...
        wn_z, zeta_z, wi_z);
fprintf('   Margen sobre el oleaje (wp~0.63 rad/s): %.1fx\n\n', wn_ang/0.63);

fprintf(' PESOS SINTETIZADOS\n');
fprintf('   Q  = diag([%.2f %.2f %.2f %.2f %.2f %.2f])\n', diag(Q));
fprintf('   Qi = diag([%.2f %.2f %.2f])\n',                diag(Qi));
fprintf('   R  = diag([%.4e %.4e %.4e])\n\n',              diag(R));

fprintf(' GANANCIAS\n');
fprintf('   Kx (roll)   pos=%8.2f  vel=%8.2f  [N*m/rad, N*m*s/rad]\n', Kx(1,1), Kx(1,2));
fprintf('   Kx (pitch)  pos=%8.2f  vel=%8.2f\n',                       Kx(2,3), Kx(2,4));
fprintf('   Kx (heave)  pos=%8.2f  vel=%8.2f  [N/m, N*s/m]\n',         Kx(3,5), Kx(3,6));
fprintf('   Ki (diag)      %8.2f %8.2f %8.2f   (NEGATIVA: es correcto)\n\n', diag(Ki));

fprintf(' FEEDFORWARD DE GRAVEDAD\n');
fprintf('   u_ff (Fz)              %8.2f N\n',   u_ff(3));
fprintf('   F_ff por piston        %8.2f N\n\n', F_ff(1));

fprintf(' VERIFICACION\n');
fprintf('   Polos continuos  Re max     %8.3f  (estable)\n', max(real(eig_cl)));
fprintf('   Polos discretos  |z| max    %8.4f  (estable)\n', rho_d);
fprintf('   Estimador / controlador     %8.1fx\n',           sep);
fprintf('   Error final con gravedad    %8.2e m\n\n',        err_final);

fprintf('----------------------------------------------------------------\n');
fprintf(' BLOQUES DE SIMULINK\n');
fprintf('----------------------------------------------------------------\n');
fprintf(' Todos los bloques discretos con Ts = %.3f s\n\n', Ts);
fprintf('  1) Oleaje:      y_amb -> Gain(P_reorder) -> Sum\n');
fprintf('     y_total = C*x + P_reorder*y_amb\n\n');
fprintf('  2) Kalman (Discrete Kalman Filter):\n');
fprintf('     A=Ad  B=Bd  C=Cd  D=Dd  Q=Qx  R=Rn  N=zeros(6,3)\n');
fprintf('     Entradas: u (la MISMA que entra a la planta, en\n');
fprintf('               esfuerzos generalizados, NO F1..F3)\n');
fprintf('               y_total\n');
fprintf('     Salida:   xhat (6x1)\n\n');
fprintf('  3) Integrador:  e  = r - y_total\n');
fprintf('                  xi = Discrete-Time Integrator(e), Ts\n\n');
fprintf('  4) Ley de control:\n');
fprintf('     u = -Kx*xhat - Ki*xi + u_ff\n');
fprintf('     (no usar Kr: el integrador ya elimina el error)\n\n');
fprintf('  5) Actuadores:\n');
fprintf('     u -> Gain(Tinv) -> Saturation [%.0f, %.0f] -> pistones\n', F_min, F_max);
fprintf('     Anti-windup: sumar beta_aw*(u_sat - u) a la entrada\n');
fprintf('                  del integrador, beta_aw = %.2f\n\n', beta_aw);
fprintf('  6) NO debe haber ningun bloque de ganancia extra entre\n');
fprintf('     Tinv y los pistones. Si existe un Gain de 500 heredado\n');
fprintf('     del modelo anterior, ELIMINARLO: se habia agregado\n');
fprintf('     para compensar la falta de feedforward.\n');
fprintf('================================================================\n\n');
end


%% ================================================================
%  FUNCIONES LOCALES
%  ================================================================

function [q, qd, qi] = lqi_weights(J, r, wn, zeta, wi)
%LQI_WEIGHTS Pesos LQI exactos para un eje doble-integrador.
%
%   [q, qd, qi] = LQI_WEIGHTS(J, r, wn, zeta, wi) devuelve los pesos
%   de posicion, velocidad e integral que, con peso de entrada r,
%   colocan los polos de lazo cerrado exactamente en las raices de
%
%       (s^2 + 2*zeta*wn*s + wn^2) * (s + wi)
%
%   para la planta J*x_ddot = u con accion integral sobre x.
%
%   Derivacion: lugar de las raices simetrico. Igualando
%   phi(s)*phi(-s) con el polinomio optimo se obtiene un sistema en
%   los coeficientes que se resuelve en forma cerrada.
%
%   Requiere zeta >= 1/sqrt(2) para que qd >= 0.

    q  = r * J^2 * wn^2 * ( wn^2 + 2*wi^2*(2*zeta^2 - 1) );
    qd = r * J^2 *        ( 2*wn^2*(2*zeta^2 - 1) + wi^2 );
    qi = r * J^2 * wn^4 * wi^2;
end