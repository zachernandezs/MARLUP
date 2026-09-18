function P = MARLUP_hidraulico_params()
%MARLUP_HIDRAULICO_PARAMS  Parametros del actuador hidraulico de MARLUP.
%
%   P = MARLUP_hidraulico_params() devuelve el struct que consumen los
%   bloques de 'PISTON_MODEL/ACTUADOR_HIDRAULICO' (Actuador, Masa,
%   Amortiguador, FuentePresion).
%
%   Unica fuente de verdad: la usan tanto script_aaron.m (que la deja en el
%   workspace base antes de simular) como MARLUP_hidraulico_build.m (que la
%   usa al colocar los bloques). No dupliques estos valores en otro sitio.
%
%   Actuador Rexroth CDH1 MP3 (paper Perez & Smith).

P.p_sys   = 250e5;    % Pa   presion de alimentacion (250 bar)
P.bore    = 0.040;    % m    diametro interior del cilindro  (A  = 12.57 cm^2)
P.rod     = 0.028;    % m    diametro del vastago            (Ar = 6.41  cm^2)
P.stroke  = 1.0;      % m    carrera
P.mass    = 58.19;    % kg   masa acoplada
P.damp    = 1000;     % N*s/m  amortiguamiento viscoso de la carga
                      %        (bloque 'Amortiguador', parametro D).
                      %        tau = P.mass/P.damp = 58 ms; subir si la masa
                      %        libre deriva, bajar para una carga mas suelta.
end
