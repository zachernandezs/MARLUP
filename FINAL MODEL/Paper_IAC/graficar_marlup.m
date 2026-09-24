function graficar_marlup(R, M, op)
%GRAFICAR_MARLUP Figuras individuales de la campaña de mediciones MARLUP.
%
%   graficar_marlup()                 usa R_marlup y M_marlup del workspace, o
%                                     resultados_mediciones/resultados_marlup.mat
%   graficar_marlup(R, M)             con las salidas de mediciones_marlup
%   graficar_marlup(R, M, op)         op: ventana, ventanaComp, idioma ('en'|'es'),
%                                     formato, tam, outDir, caso
%
%   Cada figura se exporta por separado (PNG 300 dpi y PDF vectorial) con fondo
%   blanco y texto negro. Se generan:
%     01-03  Respuesta temporal por eje: base (oleaje), placa y referencia.
%     04     Fuerzas de actuador con la fuerza de trim.
%     05-07  Antes y después del control por eje, con la misma escala vertical:
%            placa fija a la base (sin control) frente a placa controlada.
%     08-10  Densidad espectral sin control y con control, con w_p y la
%            predicción base*|S|^2.
%     11     Resumen de atenuación por eje (RMS, en w_p medida y teórica).
%     12-14  Estimador: tasa real (Simscape) frente a la estimada (si hay x_hat).
%     15-18  SiL frente a PiL por eje y residuo (si existen ambos casos).

%% ------------------------------------------------------------ Entradas
if nargin < 2
    if evalin('base','exist(''R_marlup'',''var'') && exist(''M_marlup'',''var'')')
        R = evalin('base','R_marlup'); M = evalin('base','M_marlup');
    else
        d = load(fullfile(pwd,'resultados_mediciones','resultados_marlup.mat'));
        R = d.R; M = d.M;
    end
end
if nargin < 3, op = struct(); end
cfg = M.cfg;
def.ventana     = [0 30];                            % s, figuras temporales
def.ventanaComp = [cfg.Ttrans cfg.Ttrans+30];        % s, antes/después en régimen
def.idioma      = 'en';
def.formato     = {'png','pdf'};
def.tam         = [3.5 2.5];                         % in, una columna IAC
def.outDir      = fullfile(cfg.outDir,'figuras');
def.caso        = M.casoPrincipal;
for f = fieldnames(def)'
    if ~isfield(op,f{1}), op.(f{1}) = def.(f{1}); end
end
op.ventana     = [max(op.ventana(1),0) min(op.ventana(2),cfg.Tend)];
op.ventanaComp = [max(op.ventanaComp(1),0) min(op.ventanaComp(2),cfg.Tend)];
if ~exist(op.outDir,'dir'), mkdir(op.outDir); end
L = textos(op.idioma);
S = R.(op.caso);

C.base  = [0.85 0.33 0.10];                          % naranja: base / sin control
C.placa = [0.00 0.30 0.65];                          % azul: placa controlada
C.ref   = [0 0 0];                                   % negro discontinuo: referencia
C.F     = [0.00 0.30 0.65; 0.80 0.10 0.10; 0.10 0.55 0.20];

ejes = struct( ...
  'id',    {'roll','pitch','heave'}, ...
  'base',  {S.bRoll, S.bPitch, cfg.ref(3)+S.bHeave}, ...
  'placa', {S.roll, S.pitch, S.z}, ...
  'ref',   {cfg.ref(1), cfg.ref(2), cfg.ref(3)}, ...
  'ylab',  {L.yRoll, L.yPitch, L.yHeave}, ...
  'yerr',  {L.eRoll, L.ePitch, L.eHeave}, ...
  'escErr',{1, 1, 100}, ...                          % heave en cm para el error
  'unErr', {'deg','deg','cm'});

%% ------------------------------------------------------------ 01-03 Tiempo
k = S.t >= op.ventana(1) & S.t <= op.ventana(2);
for i = 1:3
    [f,ax] = nuevaFig(op.tam);
    plot(ax,S.t(k),ejes(i).base(k),'-','Color',C.base,'LineWidth',1.0);
    plot(ax,S.t(k),ejes(i).placa(k),'-','Color',C.placa,'LineWidth',1.3);
    plot(ax,S.t(k),ejes(i).ref*ones(nnz(k),1),'--','Color',C.ref,'LineWidth',1.0);
    xlim(ax,op.ventana); etiquetas(ax,L.tiempo,ejes(i).ylab);
    leyenda(ax,{L.base,L.placa,L.ref});
    guardar(f,sprintf('%02d_%s_tiempo',i,ejes(i).id),op);
end

%% ------------------------------------------------------------ 04 Fuerzas
[f,ax] = nuevaFig(op.tam);
for j = 1:3, plot(ax,S.t(k),S.F(k,j),'-','Color',C.F(j,:),'LineWidth',1.1); end
nom = {'F_1','F_2','F_3'};
if isfield(M,'Ftrim')
    for j = 1:3
        yline(ax,M.Ftrim(j),':','Color',C.F(j,:),'LineWidth',0.9,'HandleVisibility','off');
    end
end
xlim(ax,op.ventana); etiquetas(ax,L.tiempo,L.yF); leyenda(ax,nom);
guardar(f,'04_fuerzas_actuador',op);

%% ------------------------------------------------------------ 05-07 Antes / después
kc = S.t >= op.ventanaComp(1) & S.t <= op.ventanaComp(2);
for i = 1:3
    eSin = ejes(i).escErr*(ejes(i).base(kc) - ejes(i).ref);
    eCon = ejes(i).escErr*(ejes(i).placa(kc) - ejes(i).ref);
    lim  = 1.1*max(abs([eSin; eCon])); if lim == 0, lim = 1; end
    [f,tl] = nuevaFig(op.tam .* [1 1.55],2);
    datos = {eSin, C.base, L.sinCtrl; eCon, C.placa, L.conCtrl};
    for p = 1:2
        ax = nexttile(tl); estiloEjes(ax);
        plot(ax,S.t(kc),datos{p,1},'-','Color',datos{p,2},'LineWidth',1.1);
        yline(ax,0,'--','Color',C.ref,'LineWidth',0.9);
        xlim(ax,op.ventanaComp); ylim(ax,[-lim lim]);
        ylabel(ax,ejes(i).yerr,'Color','k');
        title(ax,datos{p,3},'Color','k','FontWeight','normal','FontSize',10);
        rmsv = sqrt(mean(datos{p,1}.^2));
        text(ax,0.02,0.90,sprintf('RMS = %.3g %s',rmsv,ejes(i).unErr),'Units','normalized', ...
             'Color','k','FontName','Times New Roman','FontSize',9,'BackgroundColor','w');
    end
    xlabel(ax,L.tiempo,'Color','k');
    guardar(f,sprintf('%02d_%s_antes_despues',4+i,ejes(i).id),op);
end

%% ------------------------------------------------------------ 08-10 Espectro
if isfield(M,'espectro')
    A = M.espectro; ke = A.om > 0 & A.om <= 20;
    for i = 1:3
        [f,ax] = nuevaFig(op.tam);
        set(ax,'XScale','log','YScale','log');
        plot(ax,A.om(ke),A.Pb(ke,i),'-','Color',C.base,'LineWidth',1.0);
        plot(ax,A.om(ke),A.Pp(ke,i),'-','Color',C.placa,'LineWidth',1.3);
        plot(ax,A.om(ke),A.Pb(ke,i).*A.S2(ke,i),'--','Color',C.ref,'LineWidth',0.9);
        xline(ax,cfg.wp,':','Color','k','LineWidth',1.0,'HandleVisibility','off');
        yl = ylim(ax);
        text(ax,cfg.wp*1.08,yl(2),'\omega_p','Color','k', ...
             'FontName','Times New Roman','FontSize',10,'VerticalAlignment','top');
        etiquetas(ax,L.omega,L.psd{i});
        leyenda(ax,{L.sinCtrl,L.conCtrl,L.pred},'southwest');
        text(ax,0.98,0.95,sprintf(L.atenFmt,-A.medido_dB(i),-A.teorico_dB(i)), ...
             'Units','normalized','HorizontalAlignment','right','VerticalAlignment','top', ...
             'Color','k','FontName','Times New Roman','FontSize',9,'BackgroundColor','w');
        guardar(f,sprintf('%02d_%s_espectro',7+i,ejes(i).id),op);
    end
end

%% ------------------------------------------------------------ 11 Resumen
if isfield(M,'tabla7')
    val = M.tabla7.Red_dB(:);
    if isfield(M,'espectro'), val = [val, -M.espectro.medido_dB(:), -M.espectro.teorico_dB(:)]; end
    [f,ax] = nuevaFig(op.tam);
    b = bar(ax,val,'grouped','EdgeColor','k','LineWidth',0.6);
    paleta = [C.placa; C.base; 0.6 0.6 0.6];
    for j = 1:numel(b)
        b(j).FaceColor = paleta(j,:);
        xt = b(j).XEndPoints; yt = b(j).YEndPoints;
        text(ax,xt,yt,compose('%.1f',yt),'HorizontalAlignment','center', ...
             'VerticalAlignment','bottom','Color','k','FontName','Times New Roman','FontSize',8);
    end
    set(ax,'XTick',1:3,'XTickLabel',{'Roll','Pitch','Heave'});
    etiquetas(ax,'',L.aten); ylim(ax,[0 1.15*max(val(:))]);
    leyenda(ax,L.barras(1:size(val,2)),'northwest');
    guardar(f,'11_resumen_atenuacion',op);
end

%% ------------------------------------------------------------ 12-14 Estimador
if isfield(S,'hasXhat') && S.hasXhat
    tasas = {S.vroll, S.xhat(:,2), L.yVRoll; S.vpitch, S.xhat(:,4), L.yVPitch; S.vz, S.xhat(:,6), L.yVZ};
    for i = 1:3
        [f,ax] = nuevaFig(op.tam);
        plot(ax,S.t(k),tasas{i,1}(k),'-','Color','k','LineWidth',1.1);
        plot(ax,S.t(k),tasas{i,2}(k),'--','Color',C.placa,'LineWidth',1.1);
        xlim(ax,op.ventana); etiquetas(ax,L.tiempo,tasas{i,3});
        leyenda(ax,{L.real,L.kf});
        guardar(f,sprintf('%02d_%s_estimador',11+i,ejes(i).id),op);
    end
end

%% ------------------------------------------------------------ 15-18 SiL / PiL
if isfield(R,'sil') && isfield(R,'pil')
    A = R.sil; B = R.pil;
    v = {A.roll,B.roll; A.pitch,B.pitch; A.z,B.z};
    for i = 1:3
        [f,ax] = nuevaFig(op.tam);
        plot(ax,A.t(k),v{i,1}(k),'-','Color',C.placa,'LineWidth',1.3);
        plot(ax,B.t(k),v{i,2}(k),'--','Color',C.F(2,:),'LineWidth',1.1);
        xlim(ax,op.ventana); etiquetas(ax,L.tiempo,ejes(i).ylab);
        leyenda(ax,{'SiL','PiL'});
        guardar(f,sprintf('%02d_%s_sil_pil',14+i,ejes(i).id),op);
    end
    if isfield(M,'silpil')
        [f,ax] = nuevaFig(op.tam); set(ax,'YScale','log');
        E = abs(M.silpil.E(:,4:6)) + eps;
        for i = 1:3, plot(ax,M.silpil.t,E(:,i),'-','Color',C.F(i,:),'LineWidth',0.9); end
        xlim(ax,[0 cfg.Tend]); etiquetas(ax,L.tiempo,L.resid);
        leyenda(ax,{'Roll (deg)','Pitch (deg)','Heave (m)'});
        guardar(f,'18_residuo_sil_pil',op);
    end
end
fprintf('Figuras guardadas en %s\n',op.outDir);
end

%% =========================================================================
function [f,h] = nuevaFig(tam,nFilas)
f = figure('Units','inches','Position',[1 1 tam],'Color','w','InvertHardcopy','off');
try, theme(f,'light'); catch, end                      % evita el tema oscuro de R2025+
if nargin < 2
    h = axes(f); estiloEjes(h);
else
    h = tiledlayout(f,nFilas,1,'TileSpacing','compact','Padding','compact');
end
end

function estiloEjes(ax)
set(ax,'Color','w','XColor','k','YColor','k','ZColor','k', ...
    'GridColor',[0.80 0.80 0.80],'GridAlpha',1,'MinorGridColor',[0.90 0.90 0.90], ...
    'FontName','Times New Roman','FontSize',10,'LineWidth',0.75, ...
    'Box','on','TickDir','in','Layer','top');
grid(ax,'on'); hold(ax,'on');
end

function etiquetas(ax,xl,yl)
if ~isempty(xl), xlabel(ax,xl,'Color','k','FontName','Times New Roman','FontSize',10); end
ylabel(ax,yl,'Color','k','FontName','Times New Roman','FontSize',10);
end

function leyenda(ax,nombres,ubic)
if nargin < 3, ubic = 'best'; end
legend(ax,nombres,'Location',ubic,'TextColor','k','Color','w','EdgeColor','k', ...
       'FontName','Times New Roman','FontSize',9,'AutoUpdate','off');
end

function guardar(f,nombre,op)
for j = 1:numel(op.formato)
    arch = fullfile(op.outDir,[nombre '.' op.formato{j}]);
    if strcmp(op.formato{j},'pdf')
        exportgraphics(f,arch,'ContentType','vector','BackgroundColor','white');
    else
        exportgraphics(f,arch,'Resolution',300,'BackgroundColor','white');
    end
end
end

function L = textos(idioma)
if strcmp(idioma,'es')
    L.tiempo = 'Tiempo (s)';  L.omega = 'Frecuencia angular \omega (rad/s)';
    L.yRoll = 'Ángulo de roll \alpha (deg)'; L.yPitch = 'Ángulo de pitch \theta (deg)';
    L.yHeave = 'Altura z (m)';  L.yF = 'Fuerza de actuador F_i (N)';
    L.eRoll = 'Error \alpha - \alpha_{ref} (deg)'; L.ePitch = 'Error \theta - \theta_{ref} (deg)';
    L.eHeave = 'Error z - z_{ref} (cm)';
    L.yVRoll = 'Tasa de roll d\alpha/dt (deg/s)'; L.yVPitch = 'Tasa de pitch d\theta/dt (deg/s)';
    L.yVZ = 'Velocidad vertical dz/dt (m/s)';
    L.base = 'Base (oleaje)'; L.placa = 'Placa (controlada)'; L.ref = 'Referencia';
    L.sinCtrl = 'Sin control (placa fija a la base)'; L.conCtrl = 'Con control';
    L.pred = 'Predicción base\cdot|S|^2'; L.real = 'Real (Simscape)'; L.kf = 'Estimada (KF)';
    L.psd = {'DEP de \alpha (deg^2 s/rad)','DEP de \theta (deg^2 s/rad)','DEP de z (m^2 s/rad)'};
    L.aten = 'Atenuación (dB)'; L.resid = '|PiL - SiL|';
    L.barras = {'Reducción RMS','Medida en \omega_p','Teórica |S(j\omega_p)|'};
    L.atenFmt = 'En \\omega_p: %.1f dB (teórica %.1f dB)';
else
    L.tiempo = 'Time (s)';  L.omega = 'Angular frequency \omega (rad/s)';
    L.yRoll = 'Roll angle \alpha (deg)'; L.yPitch = 'Pitch angle \theta (deg)';
    L.yHeave = 'Heave z (m)';  L.yF = 'Actuator force F_i (N)';
    L.eRoll = 'Error \alpha - \alpha_{ref} (deg)'; L.ePitch = 'Error \theta - \theta_{ref} (deg)';
    L.eHeave = 'Error z - z_{ref} (cm)';
    L.yVRoll = 'Roll rate d\alpha/dt (deg/s)'; L.yVPitch = 'Pitch rate d\theta/dt (deg/s)';
    L.yVZ = 'Heave rate dz/dt (m/s)';
    L.base = 'Base (wave input)'; L.placa = 'Plate (controlled)'; L.ref = 'Reference';
    L.sinCtrl = 'Without control (plate locked to base)'; L.conCtrl = 'With control';
    L.pred = 'Prediction base\cdot|S|^2'; L.real = 'True (Simscape)'; L.kf = 'Estimated (KF)';
    L.psd = {'PSD of \alpha (deg^2 s/rad)','PSD of \theta (deg^2 s/rad)','PSD of z (m^2 s/rad)'};
    L.aten = 'Attenuation (dB)'; L.resid = '|PiL - SiL|';
    L.barras = {'RMS reduction','Measured at \omega_p','Predicted |S(j\omega_p)|'};
    L.atenFmt = 'At \\omega_p: %.1f dB (predicted %.1f dB)';
end
end
