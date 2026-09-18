function MARLUP_hidraulico_build(mdl)
%MARLUP_HIDRAULICO_BUILD  Arma el circuito hidraulico de un actuador MARLUP.
%
%   MARLUP_hidraulico_build              -> crea/usa 'PISTON_MODEL'
%   MARLUP_hidraulico_build('MiModelo')  -> lo arma dentro de 'MiModelo'
%
%   Construye, dentro de un subsistema 'ACTUADOR_HIDRAULICO':
%       In1  : Senal P1  (comando de carrete de la valvula, -1..1)
%       Out1 : Posicion  (m)
%       Out2 : Presion_1 (Pa)
%
%   Requiere: Simscape + Simscape Fluids.
%
%   Parametros del actuador Rexroth CDH1 MP3 (paper Perez & Smith):
%       Presion de sistema  p  = 250 bar
%       Area de piston      A  = 12.5 cm^2  -> diametro interior 40 mm
%       Area de anillo      Ar = 6.4  cm^2  -> diametro de vastago 28 mm
%       Carrera                = 1 m
%       Masa acoplada          = 58.19 kg

if nargin < 1 || isempty(mdl), mdl = 'PISTON_MODEL'; end

%% ---------------- parametros del actuador ----------------
% Definidos en MARLUP_hidraulico_params.m (unica fuente de verdad,
% compartida con script_aaron.m).
P = MARLUP_hidraulico_params();
assignin('base','P',P);

%% ---------------- librerias ----------------
libs = {};
for c = {'fluids_lib','fl_lib','nesl_utility'}
    try, load_system(c{1}); libs{end+1} = c{1}; end %#ok<AGROW>
end
if ~any(strcmp(libs,'fluids_lib'))
    error(['No se encontro la libreria de Simscape Fluids (fluids_lib). ' ...
           'Instala el add-on "Simscape Fluids" y vuelve a correr este script.']);
end

%% ---------------- modelo y subsistema ----------------
if ~bdIsLoaded(mdl)
    if exist([mdl '.slx'],'file'), load_system(mdl); else, new_system(mdl); end
end
sub = [mdl '/ACTUADOR_HIDRAULICO'];
if getSimulinkBlockHandle(sub) > 0, delete_block(sub); end
add_block('built-in/Subsystem', sub, 'Position',[120 80 320 220]);
try, delete_line(sub,'In1/1','Out1/1'); end
try, delete_block([sub '/In1']); end
try, delete_block([sub '/Out1']); end

%% ---------------- bloques ----------------
B.act   = place(sub,'Actuador'     ,'Double-Acting Actuator (IL)'            ,libs,[320  60 450 180]);
B.mref  = place(sub,'RefMecanica'  ,'Mechanical Translational Reference'     ,libs,[220 100 250 130]);
B.val   = place(sub,'Valvula4Vias' ,'4-Way Directional Valve (IL)'           ,libs,[300 270 420 390]);
B.src   = place(sub,'FuentePresion','Pressure Source (IL)'                   ,libs,[170 450 220 500]);
B.tank  = place(sub,'Tanque'       ,'Reservoir (IL)'                         ,libs,[350 580 400 630]);
B.prop  = place(sub,'PropFluido'   ,'Isothermal Liquid Properties (IL)'      ,libs,[ 70 580 120 630]);
B.solv  = place(sub,'SolverConfig' ,'Solver Configuration'                   ,libs,[ 70 480 120 530]);
B.sens  = place(sub,'SensorPQ'     ,'Pressure & Volumetric Flow Rate Sensor (IL)',libs,[490 280 560 350]);
B.s2ps  = place(sub,'S2PS'         ,'Simulink-PS Converter'                  ,libs,[170 310 210 345]);
B.pos2s = place(sub,'PS2S_pos'     ,'PS-Simulink Converter'                  ,libs,[510 100 550 135]);
B.pre2s = place(sub,'PS2S_pres'    ,'PS-Simulink Converter'                  ,libs,[620 295 660 330]);
add_block('simulink/Sources/In1' ,[sub '/Senal P1'] ,'Position',[ 80 318 110 336]);
add_block('simulink/Sinks/Out1'  ,[sub '/Posicion'] ,'Position',[600 108 630 126]);
add_block('simulink/Sinks/Out1'  ,[sub '/Presion_1'],'Position',[710 303 740 321]);

%% ---------------- parametros de los bloques ----------------
trySet(B.act, {'bore_diameter','piston_diameter','area_A'}, {'P.bore','P.bore','pi/4*P.bore^2'});
trySet(B.act, {'rod_diameter'}, {'P.rod'});
trySet(B.act, {'stroke','piston_stroke'}, {'P.stroke','P.stroke'});
trySet(B.src, {'pressure','p_ref','pressure_value'}, {'P.p_sys','P.p_sys','P.p_sys'});

%% ---------------- reporte de puertos ----------------
fprintf('\n=== PUERTOS FISICOS ===\n');
bl = find_system(sub,'SearchDepth',1,'Type','Block');
for i = 1:numel(bl)
    ph = get_param(bl{i},'PortHandles');
    cn = [ph.LConn(:); ph.RConn(:)];
    nm = cell(1,numel(cn));
    for j = 1:numel(cn)
        try, nm{j} = get_param(cn(j),'Name'); catch, nm{j} = '?'; end
    end
    fprintf('%-14s  L=%d R=%d  [%s]\n', get_param(bl{i},'Name'), ...
        numel(ph.LConn), numel(ph.RConn), strjoin(nm,' '));
end

try, set_param(mdl,'SolverName','daessc','StopTime','5'); end
open_system(sub);
fprintf('\nBloques colocados en %s. Falta cablear (paso 2).\n', sub);
end

%% ================= helpers =================
function h = place(sub, nm, libname, libs, pos)
src = '';  best = inf;
for k = 1:numel(libs)
    try
        r = find_system(libs{k},'SearchDepth',12,'LookUnderMasks','all', ...
                        'FollowLinks','off','Name',libname);
    catch, r = {};
    end
    for i = 1:numel(r)
        d = numel(strfind(r{i},'/'));
        if d < best, best = d; src = r{i}; end
    end
end
if isempty(src)
    warning('No se encontro el bloque "%s".', libname); h = []; return;
end
h = add_block(src, [sub '/' nm], 'Position', pos, 'MakeNameUnique','on');
end

function trySet(blk, names, vals)
if isempty(blk), return; end
for i = 1:numel(names)
    try
        set_param(blk, names{i}, vals{i});
        fprintf('  set %s.%s = %s\n', get_param(blk,'Name'), names{i}, vals{i});
        return
    catch
    end
end
end
