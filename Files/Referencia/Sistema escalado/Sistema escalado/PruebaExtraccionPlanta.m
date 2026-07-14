% Nombre del modelo (sin la extensión .slx)
nombre_modelo = 'Marlup3ControlesPruebasinMotor';




[num,den]=linmod(nombre_modelo);

num=1;
sys_tf2 = tf(num, den);
% Mostrar
disp('Función de transferencia:');
sys_tf2


figure;
step(sys_tf2);
title('Respuesta al Escalón de sys\_tf2');
grid on;

pidTuner(sys_tf2, 'PID')


% Crear sistema en lazo cerrado: PID en serie con planta, y realimentación unitaria
T2 = feedback(sys_tf2, 1);

% Graficar la respuesta
figure;
step(T2);
title('Respuesta al Escalón del Sistema T2');
grid on;



order(T2)

sys_clean = minreal(sys_tf2)


orden_deseado=10;
[sys_red, info] = balred(sys_clean, orden_deseado);



sys_red



% Ajusta modelo de orden 4
sys_identificado = tfest(sys_red, 4);
sys_identificado



pidTuner(sys_simplificado, 'PID')