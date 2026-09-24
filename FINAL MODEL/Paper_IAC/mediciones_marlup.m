function [R, M] = mediciones_marlup(cfgUsuario)
%MEDICIONES_MARLUP Campaña de mediciones del gemelo digital MARLUP (paper IAC-26).
%
%   [R, M] = mediciones_marlup()            usa la configuración por defecto
%   [R, M] = mediciones_marlup(struct('Tend',60,'runs',{{'PIL'}}))
%
%   Casos que ejecuta (campo cfg.runs):
%     'flat'   : mar en calma (Hs = 0), controlador en Normal. Tiempo de
%                establecimiento desde la condición ensamblada y F_trim medido.
%     'Normal' : oleaje P-M, controlador en Normal (línea base, sec. 9 guía PiL).
%     'SIL'    : oleaje P-M, mismo realizado, código generado en el anfitrión.
%     'PIL'    : oleaje P-M, mismo realizado, código en la STM32F446RE, con
%                perfilado de tiempo de ejecución.
%
%   Señales registradas: salida de la planta (roll, pitch, heave y sus tasas,
%   yaw libre), movimiento de la base (P-M), medición de sensores (y_k), fuerzas
%   de actuador F y, si el bloque del controlador expone un segundo puerto de
%   salida, el estado estimado x_hat = [a da th dth z dz].
%
%   Resultados: Tabla 7 (base vs placa), tiempo de establecimiento, error del
%   estimador (sec. 5.4), atenuación espectral medida en w_p frente a |S(jw_p)|
%   (Tabla 6), residuo SIL-PIL (Fig. 12) y métricas PiL (Tabla 5). Guarda .mat,
%   .csv, figuras PNG a 300 dpi y un archivo .tex con las filas de las tablas.
%
%   El modelo no se modifica de forma permanente: los terminadores y marcas de
%   registro que se agregan se retiran al terminar, también si ocurre un error.
%   No guarde el modelo mientras el script está en ejecución.

%% ------------------------------------------------------------ Configuración
cfg.model       = 'MARLUP_MODEL_F';
cfg.ctrlBlock   = [cfg.model '/Subsystem'];          % bloque Model PiL_MARLUP_IAC26
cfg.plantBlock  = [cfg.model '/ PLATFORM'];           % el nombre inicia con espacio
cfg.waveBlock   = [cfg.model '/P-M Wave Spectrum'];
cfg.sensBlock   = [cfg.model '/Sensors'];
cfg.HsBlock     = [cfg.waveBlock '/Constant1'];      % Hs (m) de entrada al P-M
cfg.Hs          = 0.5;                               % m
cfg.Ts          = 0.01;                              % s, se toma de 'Ts' si existe
cfg.Tend        = 120;                               % s, >= 120 s para la PSD
cfg.Ttrans      = 20;                                % s, transitorio excluido
cfg.ref         = [0 0 1.5];                         % [roll deg, pitch deg, heave m]
cfg.baseAngUnit = 'rad';                             % unidades de roll/pitch de la base
cfg.xhatZoff    = 0;                                 % sumar a x_hat(5) si z se estima en desviación
cfg.bandRel     = 0.02;                              % banda de establecimiento (2 %)
cfg.bandAbs     = [0.05 0.05 1e-3];                  % piso de la banda [deg deg m]
cfg.Fcap        = 3000;                              % N, capacidad del cilindro
cfg.wp          = 2*pi/10;                           % rad/s, pico del espectro
cfg.gains       = [6.15 13.05  6.75;                 % [kd kp ki] roll   (Tabla 4)
                   6.15 13.05  6.75;                 %            pitch
                   8.20 23.20 16.00];                %            heave
cfg.runs        = {'flat','Normal','SIL','PIL'};
cfg.profilePIL  = true;
cfg.gnuBin      = 'C:\ProgramData\MATLAB\R2026a\stm32b\3P.instrset\gnuarm-stm32.instrset\win\bin';
cfg.outDir      = fullfile(pwd,'resultados_mediciones');
cfg.figuras     = struct('ventana',[0 30],'idioma','en');   % ver graficar_marlup

if evalin('base','exist(''Ts'',''var'')'), cfg.Ts = evalin('base','Ts'); end
if nargin > 0
    for f = fieldnames(cfgUsuario)', cfg.(f{1}) = cfgUsuario.(f{1}); end
end
if cfg.Ttrans > cfg.Tend/2          % corridas cortas: la ventana de estadística es la 2a mitad
    cfg.Ttrans = cfg.Tend/2;
    fprintf('Ttrans ajustado a %.1f s (Tend = %g s).\n',cfg.Ttrans,cfg.Tend);
end

%% ------------------------------------------------------------ Preparación
if ~exist(cfg.outDir,'dir'), mkdir(cfg.outDir); end
load_system(cfg.model);
cfg.pilModel = get_param(cfg.ctrlBlock,'ModelName');
if bdIsLoaded(cfg.pilModel) && strcmp(get_param(cfg.pilModel,'Dirty'),'on')
    save_system(cfg.pilModel);        % guía PiL, tabla 5: referenciado sin cambios
end
st = prepararRegistro(cfg);
limpieza = onCleanup(@() restaurarModelo(st)); %#ok<NASGU>

%% ------------------------------------------------------------ Simulaciones
R = struct();
for k = 1:numel(cfg.runs)
    switch cfg.runs{k}
        case 'flat',   R.flat   = correrCaso(cfg,'Normal',0,false);
        case 'Normal', R.normal = correrCaso(cfg,'Normal',cfg.Hs,false);
        case 'SIL',    R.sil    = correrCaso(cfg,'SIL',cfg.Hs,false);
        case 'PIL',    R.pil    = correrCaso(cfg,'PIL',cfg.Hs,cfg.profilePIL);
    end
end

%% ------------------------------------------------------------ Métricas
M = struct(); M.cfg = cfg;
principal = '';
for c = {'pil','sil','normal'}
    if isfield(R,c{1}), principal = c{1}; break; end
end
M.casoPrincipal = principal;

if ~isempty(principal)
    S = R.(principal);
    [M.tabla7, M.global] = metricasOleaje(S,cfg);
    M.espectro = atenuacionEspectral(S,cfg);
    if S.hasXhat, M.kf = metricasEstimador(S,cfg); end
end
if isfield(R,'flat')
    M.ts    = establecimiento(R.flat,cfg);
    M.Ftrim = mean(R.flat.F(R.flat.t >= R.flat.t(end)-2,:),1);
end
if isfield(R,'sil') && isfield(R,'pil'),    M.silpil  = residuo(R.sil,R.pil); end
if isfield(R,'normal') && isfield(R,'sil'), M.normsil = residuo(R.normal,R.sil); end
if isfield(R,'pil') && isfield(R.pil,'prof'), M.perfil = R.pil.prof; end
if isfield(R,'pil'), M.memoria = memoriaELF(cfg); end
for c = fieldnames(R)'
    M.costo.(c{1}) = R.(c{1}).wall * 10 / cfg.Tend;   % s de cómputo por 10 s simulados
end

%% ------------------------------------------------------------ Figuras
if ~isempty(principal)
    graficar_marlup(R,M,cfg.figuras);
end

%% ------------------------------------------------------------ Exportación
save(fullfile(cfg.outDir,'resultados_marlup.mat'),'R','M','-v7.3');
if isfield(M,'tabla7')
    writetable(M.tabla7,fullfile(cfg.outDir,'tabla7.csv'));
end
escribirLatex(M,fullfile(cfg.outDir,'tablas_paper.tex'));
resumen(M);
assignin('base','R_marlup',R); assignin('base','M_marlup',M);
end

%% =========================================================================
%% Registro de señales
%% =========================================================================
function st = prepararRegistro(cfg)
% {bloque, puerto (número o nombre del Outport interno), nombre de registro, obligatoria}
lista = {cfg.plantBlock,'Roll_marlup','Roll',true;   cfg.plantBlock,'Pitch_marlup','Pitch',true;
         cfg.plantBlock,'Z_marlup','Z',true;         cfg.plantBlock,'vRoll_marlup','vRoll',false;
         cfg.plantBlock,'vPitch_marlup','vPitch',false; cfg.plantBlock,'vZ_marlup','vZ',false;
         [cfg.plantBlock '/Demux'],3,'yaw',false;
         cfg.waveBlock,1,'base',true;  cfg.sensBlock,1,'y_meas',true; cfg.ctrlBlock,1,'F',true};
ph = get_param(cfg.ctrlBlock,'PortHandles');
if numel(ph.Outport) >= 2
    lista(end+1,:) = {cfg.ctrlBlock,2,'xhat',false};
else
    warning(['El controlador no expone x_hat (un solo puerto de salida). ' ...
             'Se omiten las métricas del estimador.']);
end
st.cfg = cfg; st.modo = get_param(cfg.ctrlBlock,'SimulationMode');
st.puertos = []; st.previo = {}; st.lineas = []; st.bloques = {};
for i = 1:size(lista,1)
    [p,msg] = resolverPuerto(lista{i,1},lista{i,2});
    if isempty(p)
        if lista{i,4}
            restaurarModelo(st);                       % deshace lo agregado hasta aquí
            error('Señal obligatoria ''%s'': %s',lista{i,3},msg);
        end
        warning('Se omite la señal ''%s'': %s',lista{i,3},msg); continue;
    end
    blk = lista{i,1};
    if get_param(p,'Line') == -1                       % puerto sin conectar
        padre = get_param(blk,'Parent'); pos = get_param(p,'Position');
        tb = add_block('simulink/Sinks/Terminator',[padre '/med_' lista{i,3}], ...
            'MakeNameUnique','on','Position',[pos(1)+30 pos(2)-5 pos(1)+40 pos(2)+5]);
        th = get_param(tb,'PortHandles');
        st.lineas(end+1)  = add_line(padre,p,th.Inport(1));
        st.bloques{end+1} = getfullname(tb);
    end
    st.puertos(end+1) = p;
    st.previo{end+1}  = {get_param(p,'DataLogging'),get_param(p,'DataLoggingNameMode'), ...
                         get_param(p,'DataLoggingName')};
    set_param(p,'DataLogging','on','DataLoggingNameMode','Custom', ...
                'DataLoggingName',lista{i,3});
end
end

function [p,msg] = resolverPuerto(blk,id)
% Devuelve el handle del puerto de salida 'id' (número, o nombre del Outport
% dentro del subsistema). Vacío y un mensaje si no existe.
p = []; msg = '';
if getSimulinkBlockHandle(blk) == -1
    msg = sprintf('no existe el bloque %s',blk); return;
end
ph = get_param(blk,'PortHandles');
if ischar(id)
    ob = find_system(blk,'SearchDepth',1,'LookUnderMasks','all', ...
                     'BlockType','Outport','Name',id);
    if isempty(ob)
        todos = find_system(blk,'SearchDepth',1,'LookUnderMasks','all','BlockType','Outport');
        nom = strjoin(cellfun(@(b) get_param(b,'Name'),todos,'UniformOutput',false),', ');
        msg = sprintf('%s no tiene el Outport ''%s''. Outports disponibles: %s',blk,id,nom);
        return;
    end
    id = str2double(get_param(ob{1},'Port'));
end
if id > numel(ph.Outport)
    msg = sprintf('%s tiene %d salidas; se pidió la %d',blk,numel(ph.Outport),id); return;
end
p = ph.Outport(id);
end

function restaurarModelo(st)
try
    for i = 1:numel(st.puertos)
        v = st.previo{i};
        set_param(st.puertos(i),'DataLogging',v{1},'DataLoggingNameMode',v{2});
        if strcmp(v{2},'Custom'), set_param(st.puertos(i),'DataLoggingName',v{3}); end
    end
    for i = 1:numel(st.lineas),  delete_line(st.lineas(i));   end
    for i = 1:numel(st.bloques), delete_block(st.bloques{i}); end
    set_param(st.cfg.ctrlBlock,'SimulationMode',st.modo);
    fprintf('Modelo restaurado (no es necesario guardarlo).\n');
catch ME
    warning('Restauración incompleta: %s',ME.message);
end
end

%% =========================================================================
%% Ejecución de un caso
%% =========================================================================
function S = correrCaso(cfg,modo,Hs,perfilar)
modos = struct('Normal','Normal','SIL','Software-in-the-loop (SIL)', ...
               'PIL','Processor-in-the-loop (PIL)');
set_param(cfg.ctrlBlock,'SimulationMode',modos.(modo));
in = Simulink.SimulationInput(cfg.model);
in = in.setBlockParameter(cfg.HsBlock,'Value',num2str(Hs,'%.6g'));
in = in.setModelParameter('StopTime',num2str(cfg.Tend),'SignalLogging','on', ...
                          'SignalLoggingName','logsout','ReturnWorkspaceOutputs','on');
if perfilar
    in = in.setModelParameter('CodeExecutionProfiling','on', ...
        'CodeProfilingInstrumentation','coarse', ...
        'CodeExecutionProfileVariable','executionProfile', ...
        'CodeProfilingSaveOptions','AllData');
end
fprintf('>> %s | Hs = %.2f m | %g s simulados\n',modo,Hs,cfg.Tend);
tic;
try
    out = sim(in);
catch ME
    if perfilar && contains(ME.message,'CodeProfilingInstrumentation')
        in  = in.setModelParameter('CodeProfilingInstrumentation','on');
        out = sim(in);
    else
        rethrow(ME);
    end
end
S.wall = toc; S.modo = modo; S.Hs = Hs;
fprintf('   %.1f s de cómputo\n',S.wall);
S = extraerSenales(S,out.logsout,cfg);
if perfilar, S.prof = leerPerfil(out,cfg); end
end

function S = extraerSenales(S,logs,cfg)
tg = (0:cfg.Ts:cfg.Tend)'; S.t = tg;
g = @(n,m) remuestrear(logs,n,tg,m);
S.roll  = g('Roll','linear');   S.pitch  = g('Pitch','linear');  S.z  = g('Z','linear');
S.vroll = g('vRoll','linear');  S.vpitch = g('vPitch','linear'); S.vz = g('vZ','linear');
S.yaw   = g('yaw','linear');
B = g('base','linear');                               % Mux del P-M: [pitch roll heave]
k = 1; if strcmp(cfg.baseAngUnit,'rad'), k = 180/pi; end
S.bRoll = k*B(:,2); S.bPitch = k*B(:,1); S.bHeave = B(:,3);
S.F = g('F','previous');                              % discreto: retención
Y = g('y_meas','previous');                           % [rad rad m]
S.yRoll = Y(:,1)*180/pi; S.yPitch = Y(:,2)*180/pi; S.yZ = Y(:,3);
el = logs.getElement('F'); if isa(el,'Simulink.SimulationData.Dataset'), el = el{1}; end
S.dtype = class(el.Values.Data);
S.hasXhat = any(strcmp(logs.getElementNames,'xhat'));
if S.hasXhat
    X = g('xhat','previous');                         % [a da th dth z dz] en rad, m
    S.xhat = [X(:,1:4)*180/pi, X(:,5)+cfg.xhatZoff, X(:,6)];
end
end

function y = remuestrear(logs,nombre,tg,metodo)
if ~any(strcmp(logs.getElementNames,nombre))      % señal opcional no registrada
    y = nan(numel(tg),1); return;
end
el = logs.getElement(nombre);
if isa(el,'Simulink.SimulationData.Dataset'), el = el{1}; end
t = el.Values.Time; d = el.Values.Data;
if ndims(d) == 3
    d = permute(d,[3 1 2]); d = reshape(d,size(d,1),[]);
elseif size(d,1) ~= numel(t)
    d = d.';
end
[t,iu] = unique(t,'last');
y = interp1(t,double(d(iu,:)),tg,metodo,'extrap');
end

%% =========================================================================
%% Métricas
%% =========================================================================
function [T,G] = metricasOleaje(S,cfg)
w = S.t >= cfg.Ttrans;
base  = [S.bRoll S.bPitch S.bHeave];
placa = [S.roll S.pitch S.z] - cfg.ref;
Eje   = {'Roll (deg)';'Pitch (deg)';'Heave (m)'};
RMS_base  = sqrt(mean(base(w,:).^2,1))';  Pico_base  = max(abs(base(w,:)),[],1)';
RMS_placa = sqrt(mean(placa(w,:).^2,1))'; Pico_placa = max(abs(placa(w,:)),[],1)';
Red_RMS = RMS_base./RMS_placa; Red_dB = 20*log10(Red_RMS); Red_pico = Pico_base./Pico_placa;
T = table(Eje,RMS_base,RMS_placa,Red_RMS,Red_dB,Pico_base,Pico_placa,Red_pico);
G.Fmin = min(S.F(:)); G.Fmax = max(S.F(:));
G.FminEst = min(min(S.F(w,:))); G.FmaxEst = max(max(S.F(w,:)));
G.usoFuerza = max(abs(S.F(:)))/cfg.Fcap;
G.yawDeriva = S.yaw(end) - S.yaw(1);
G.yawMax    = max(abs(S.yaw - S.yaw(1)));
G.errMedio  = mean(placa(w,:),1);              % offset estacionario por eje
end

function ts = establecimiento(S,cfg)
e = [S.roll S.pitch S.z] - cfg.ref; ts = zeros(1,3);
for i = 1:3
    banda = max(cfg.bandRel*abs(e(1,i)), cfg.bandAbs(i));
    fuera = find(abs(e(:,i)) > banda,1,'last');
    if isempty(fuera),           ts(i) = 0;
    elseif fuera == numel(S.t),  ts(i) = NaN;   % no se establece en la ventana
    else,                        ts(i) = S.t(fuera+1);
    end
end
end

function K = metricasEstimador(S,cfg)
w = S.t >= cfg.Ttrans;
verd = [S.roll S.vroll S.pitch S.vpitch S.z S.vz];
err  = S.xhat - verd;
K.nombres = {'alpha','dalpha','theta','dtheta','z','dz'};
K.unid    = {'deg','deg/s','deg','deg/s','m','m/s'};
K.rms  = sqrt(mean(err(w,:).^2,1));
K.pico = max(abs(err(w,:)),[],1);
eMed = [S.yRoll S.yPitch S.yZ] - [S.roll S.pitch S.z];   % ruido + cuantización + ZOH
K.rmsMedicion = sqrt(mean(eMed(w,:).^2,1));
K.factorRuido = K.rmsMedicion ./ K.rms([1 3 5]);        % > 1: el KF filtra la medición
end

function A = atenuacionEspectral(S,cfg)
w = S.t >= cfg.Ttrans; n = nnz(w);
L = 2^floor(log2(n/2));                               % al menos 3 segmentos con 50 %
base  = [S.bRoll S.bPitch S.bHeave];
placa = [S.roll S.pitch S.z] - cfg.ref;
for i = 1:3
    [om,Pb] = psdWelch(base(w,i),cfg.Ts,L);
    [~, Pp] = psdWelch(placa(w,i),cfg.Ts,L);
    A.om = om; A.Pb(:,i) = Pb; A.Pp(:,i) = Pp;
    banda = om >= 0.8*cfg.wp & om <= 1.2*cfg.wp;
    if ~any(banda), [~,j] = min(abs(om-cfg.wp)); banda(j) = true; end
    A.medido_dB(i) = 10*log10(sum(Pp(banda))/sum(Pb(banda)));
    gk = cfg.gains(i,:); s = 1j*om;
    A.S2(:,i) = abs(s.^3 ./ (s.^3 + gk(1)*s.^2 + gk(2)*s + gk(3))).^2;
    sp = 1j*cfg.wp;
    A.teorico_dB(i) = 20*log10(abs(sp^3/(sp^3 + gk(1)*sp^2 + gk(2)*sp + gk(3))));
end
A.resolucion = om(2);                                 % rad/s
end

function [om,P] = psdWelch(x,dt,L)
x = x(:) - mean(x); N = numel(x); L = min(L,N); L = L - mod(L,2);
h = 0.5 - 0.5*cos(2*pi*(0:L-1)'/(L-1));
paso = L/2; nseg = floor((N-L)/paso) + 1; P = zeros(L/2+1,1);
for k = 0:nseg-1
    seg = x(k*paso + (1:L)); seg = seg - mean(seg);
    X = fft(seg.*h); P = P + abs(X(1:L/2+1)).^2;
end
P = P*dt/(nseg*sum(h.^2)); P(2:end-1) = 2*P(2:end-1);
om = 2*pi*(0:L/2)'/(L*dt);
end

function D = residuo(A,B)
D.nombres = {'F1 (N)','F2 (N)','F3 (N)','roll (deg)','pitch (deg)','z (m)'};
XA = [A.F A.roll A.pitch A.z]; XB = [B.F B.roll B.pitch B.z];
E = XB - XA; n = size(E,1); h = floor(n/2);
D.max = max(abs(E)); D.rms = sqrt(mean(E.^2));
D.rel = D.rms ./ sqrt(mean((XA - mean(XA)).^2));      % respecto a la variación de la señal
D.crecimiento = sqrt(mean(E(h+1:end,:).^2)) ./ max(sqrt(mean(E(1:h,:).^2)),eps);
D.t = A.t; D.E = E;
end

function P = leerPerfil(out,cfg)
P = struct('ok',false);
try
    ep = out.executionProfile;
catch
    try, ep = getCoderExecutionProfile(cfg.pilModel);
    catch, warning('No se encontró el perfil de ejecución.'); return; end
end
try
    tps = double(ep.TimerTicksPerSecond); secs = {};
    for k = 1:50
        try, secs{end+1} = ep.Sections(k); catch, break; end %#ok<AGROW>
    end
    nombres = cellfun(@(s) s.Name,secs,'UniformOutput',false);
    i = find(contains(lower(nombres),'step'),1); if isempty(i), i = 1; end
    tt = double(secs{i}.ExecutionTimeInTicks)/tps;
    P.seccion = nombres{i}; P.media_us = 1e6*mean(tt); P.max_us = 1e6*max(tt);
    P.carga = max(tt)/cfg.Ts; P.ciclosMax = max(double(secs{i}.ExecutionTimeInTicks));
    P.ep = ep; P.ok = true;
catch ME
    warning('Perfil no interpretado (%s). Use report(M.perfil.ep).',ME.message);
    P.ep = ep;
end
end

function Mem = memoriaELF(cfg)
Mem = struct('ok',false);
cg  = Simulink.fileGenControl('get','CodeGenFolder');
elf = fullfile(cg,'slprj','ert',cfg.pilModel,'pil',[cfg.pilModel '.elf']);
exe = fullfile(cfg.gnuBin,'arm-none-eabi-size.exe');
if ~isfile(elf) || ~isfile(exe)
    warning('No se encontró %s o arm-none-eabi-size; se omite Flash/RAM.',elf); return;
end
[s,txt] = system(sprintf('"%s" "%s"',exe,elf));
if s ~= 0, return; end
lin = strtrim(splitlines(strtrim(txt))); v = sscanf(lin{2},'%d %d %d');
Mem.text = v(1); Mem.data = v(2); Mem.bss = v(3);
Mem.flash_kB = (v(1)+v(2))/1024; Mem.ram_kB = (v(2)+v(3))/1024; Mem.ok = true;
end

%% =========================================================================
%% Salida en texto
%% =========================================================================
function escribirLatex(M,archivo)
fid = fopen(archivo,'w'); cierre = onCleanup(@() fclose(fid)); %#ok<NASGU>
if isfield(M,'tabla7')
    T = M.tabla7; et = {'Roll','Pitch','Heave'};
    fprintf(fid,'%% Tabla 7 (caso %s): base & placa & reducción\n',upper(M.casoPrincipal));
    for i = 1:3
        fprintf(fid,'%s RMS & %.4g & %.4g & %.1f (%.1f dB) \\\\\n',et{i}, ...
            T.RMS_base(i),T.RMS_placa(i),T.Red_RMS(i),T.Red_dB(i));
    end
    for i = 1:3
        fprintf(fid,'%s peak & %.4g & %.4g & %.1f \\\\\n',et{i}, ...
            T.Pico_base(i),T.Pico_placa(i),T.Red_pico(i));
    end
    fprintf(fid,'Force range [min, max]: [%.0f, %.0f] N (%.1f %% de la capacidad)\n', ...
        M.global.Fmin,M.global.Fmax,100*M.global.usoFuerza);
    fprintf(fid,'Yaw drift: %.3f deg (max %.3f deg)\n\n',M.global.yawDeriva,M.global.yawMax);
end
if isfield(M,'espectro')
    fprintf(fid,'%% Atenuación en w_p medida vs |S(jw_p)| (Tabla 6)\n');
    fprintf(fid,'medido [roll pitch heave] = [%.1f %.1f %.1f] dB; teórico = [%.1f %.1f %.1f] dB\n\n', ...
        M.espectro.medido_dB,M.espectro.teorico_dB);
end
if isfield(M,'ts')
    fprintf(fid,'%% Establecimiento (mar en calma): [%.2f %.2f %.2f] s; F_trim = [%.1f %.1f %.1f] N\n\n', ...
        M.ts,M.Ftrim);
end
if isfield(M,'kf')
    fprintf(fid,'%% Error del estimador (RMS / pico)\n');
    for i = 1:6
        fprintf(fid,'%s & %.3g & %.3g & %s \\\\\n',M.kf.nombres{i},M.kf.rms(i),M.kf.pico(i),M.kf.unid{i});
    end
    fprintf(fid,'Factor de reducción de ruido en posiciones: [%.1f %.1f %.1f]\n\n',M.kf.factorRuido);
end
if isfield(M,'silpil')
    fprintf(fid,'%% Residuo PiL - SiL: max / RMS / crecimiento 2a mitad vs 1a\n');
    for i = 1:6
        fprintf(fid,'%s & %.3g & %.3g & %.2f \\\\\n',M.silpil.nombres{i}, ...
            M.silpil.max(i),M.silpil.rms(i),M.silpil.crecimiento(i));
    end
    fprintf(fid,'\n');
end
if isfield(M,'perfil') && M.perfil.ok
    p = M.perfil;
    fprintf(fid,'%% Tabla 5\nAverage execution time per step & %.1f $\\mu$s \\\\\n',p.media_us);
    fprintf(fid,'Worst-case execution time per step & %.1f $\\mu$s \\\\\n',p.max_us);
    fprintf(fid,'CPU load at $T_s$ & %.2f \\%% \\\\\n',100*p.carga);
end
if isfield(M,'memoria') && M.memoria.ok
    fprintf(fid,'Flash / RAM usage & %.1f kB / %.1f kB \\\\\n',M.memoria.flash_kB,M.memoria.ram_kB);
end
if isfield(M,'silpil')
    fprintf(fid,'Max. SiL--PiL output difference & %.2g N (F), %.2g deg, %.2g m \\\\\n', ...
        max(M.silpil.max(1:3)),max(M.silpil.max(4:5)),M.silpil.max(6));
end
if isfield(M,'costo')
    fprintf(fid,'\n%% Costo de cómputo por 10 s simulados (Tabla 8)\n');
    for c = fieldnames(M.costo)', fprintf(fid,'%s: %.1f s\n',c{1},M.costo.(c{1})); end
end
end

function resumen(M)
fprintf('\n================ RESUMEN MARLUP ================\n');
if isfield(M,'tabla7'), fprintf('Caso principal: %s\n',upper(M.casoPrincipal)); disp(M.tabla7); end
if isfield(M,'espectro')
    fprintf('Atenuación en w_p  medida: [%.1f %.1f %.1f] dB | teórica: [%.1f %.1f %.1f] dB (resolución %.3f rad/s)\n', ...
        M.espectro.medido_dB,M.espectro.teorico_dB,M.espectro.resolucion);
end
if isfield(M,'ts'),  fprintf('t_s (calma): [%.2f %.2f %.2f] s | F_trim: [%.1f %.1f %.1f] N\n',M.ts,M.Ftrim); end
if isfield(M,'kf'),  fprintf('KF RMS tasas: [%.3g deg/s %.3g deg/s %.3g m/s]\n',M.kf.rms([2 4 6])); end
if isfield(M,'silpil'), fprintf('Max |PiL-SiL|: F %.2g N | ángulos %.2g deg | z %.2g m\n', ...
        max(M.silpil.max(1:3)),max(M.silpil.max(4:5)),M.silpil.max(6)); end
if isfield(M,'perfil') && M.perfil.ok
    fprintf('PiL: media %.1f us, máx %.1f us, carga %.2f %% de Ts\n',M.perfil.media_us,M.perfil.max_us,100*M.perfil.carga);
end
fprintf('Resultados en: %s\n',M.cfg.outDir);
end
