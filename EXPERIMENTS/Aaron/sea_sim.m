%% ============================================================
%  MARLUP – Video de la superficie del mar (P-M) + triada 3DOF
%  Render headless: no abre ninguna ventana.
%  Salida: MARLUP_oleaje_35s.mp4  (35 s @ 30 fps)
%  ============================================================
clear; clc;

%% --- Parámetros ---
Hs    = 2;         % altura significativa [m]
Tp    = 10;          % periodo pico [s]
Tend  = 35;          % duración del video [s]
fps   = 30;          % cuadros por segundo
Lx    = 5;          % semiancho del dominio en X [m]
Ly    = 5;          % semiancho del dominio en Y [m]
ngrid = 90;          % resolución de la malla
axLen = 2.0;         % longitud de los ejes de la triada [m]
rDisk = 1.2;         % radio del disco de la base [m]
Wpx   = 1280;        % ancho del video [px]
Hpx   = 720;         % alto del video [px]
vidName = 'MARLUP_oleaje_35s.mp4';

%% --- Pre-cálculo del espectro P-M (idéntico a la fcn de Simulink) ---
N = 100; M = 50; g = 9.81;
fp = 1/Tp;  f_max = 4*fp;  df = f_max/N;
f     = df:df:f_max;
omega = 2*pi*f;
d_theta = 2*pi/M;
theta   = d_theta:d_theta:2*pi;

rng(42);                                  % misma semilla que el modelo
fase = 2*pi*rand(N,M);

k_o = omega.^2 / g;
kx  = k_o' * cos(theta);                  % N×M
ky  = k_o' * sin(theta);                  % N×M

A_pm = (5/16)*Hs^2*fp^4;
S    = (A_pm ./ f.^5) .* exp(-1.25*(fp^4 ./ f.^4));

s = 10;
D_theta = (2/pi)*(cos(theta/2)).^(2*s);
D_theta(theta < -pi/2 | theta > pi/2) = 0;

Anm = sqrt(2 * S' .* D_theta * df * d_theta);   % N×M

%% --- Malla espacial y vectorización ---
xv = linspace(-Lx, Lx, ngrid);
yv = linspace(-Ly, Ly, ngrid);
[X, Y] = meshgrid(xv, yv);

Xf = X(:).';  Yf = Y(:).';                      % 1×P
KX = kx(:);   KY = ky(:);                       % Q×1
AA = Anm(:);  PH = fase(:);
OM = reshape(repmat(omega.', 1, M), [], 1);     % Q×1, consistente con Anm(:)

PHASE_SPACE = KX*Xf + KY*Yf;                    % Q×P (fase espacial fija)

%% --- Figura invisible, tamaño de impresión fijado ---
fig = figure('Visible','off','Color','k','Units','pixels', ...
             'Position',[0 0 Wpx Hpx],'Renderer','opengl', ...
             'MenuBar','none','ToolBar','none','InvertHardcopy','off', ...
             'PaperUnits','inches','PaperPosition',[0 0 Wpx/96 Hpx/96], ...
             'PaperPositionMode','manual');

ax = axes('Parent',fig,'Color','k','Units','normalized', ...
          'Position',[0.08 0.10 0.76 0.80]);
hold(ax,'on'); grid(ax,'on'); box(ax,'on');
ax.GridColor = [0.35 0.35 0.35];
ax.XColor = 'w'; ax.YColor = 'w'; ax.ZColor = 'w';

hSurf = surf(ax, X, Y, zeros(size(X)), 'EdgeColor','none', ...
             'FaceAlpha',0.92, 'FaceLighting','gouraud');
colormap(ax, turbo);
clim(ax, [-0.3, 0.3]);                    % usar caxis() si R<2022a
cb = colorbar(ax); cb.Color = 'w';
cb.Label.String = 'Elevación \eta (m)'; cb.Label.Color = 'w';

light(ax,'Position',[-20 -20 30],'Style','infinite');
material(ax,'dull');

% Triada 3DOF en el origen (base de MARLUP)
hX = plot3(ax,[0 0],[0 0],[0 0],'r-','LineWidth',3);
hY = plot3(ax,[0 0],[0 0],[0 0],'g-','LineWidth',3);
hZ = plot3(ax,[0 0],[0 0],[0 0],'c-','LineWidth',3);
hO = plot3(ax,0,0,0,'wo','MarkerFaceColor','w','MarkerSize',7);

tDisk = linspace(0,2*pi,60);
hDisk = patch(ax,'XData',rDisk*cos(tDisk),'YData',rDisk*sin(tDisk), ...
              'ZData',zeros(size(tDisk)),'FaceColor',[0.85 0.2 0.2], ...
              'FaceAlpha',0.55,'EdgeColor','w','LineWidth',1.2);

xlabel(ax,'X (m)'); ylabel(ax,'Y (m)'); zlabel(ax,'Elevación (m)');
axis(ax,[-Lx Lx -Ly Ly -0.5 0.5]);
daspect(ax,[1 1 0.15]);                         % [1 1 1] para escala real
view(ax, -37.5, 28);
hTitle = title(ax,'','Color','w','FontSize',13,'FontName','FixedWidth');

%% --- Video writer ---
v = VideoWriter(vidName,'MPEG-4');
v.FrameRate = fps;
v.Quality   = 95;
open(v);

tvec = 0:1/fps:Tend;
hPix = 0; wPix = 0;
fprintf('Renderizando %d cuadros (sin ventana)...\n', numel(tvec));

for i = 1:numel(tvec)
    t = tvec(i);

    % ---- Superficie: eta(x,y,t) = sum Anm*cos(kx*x + ky*y - w*t + fase)
    ARG  = PHASE_SPACE - OM*t + PH;             % Q×P
    eta  = reshape(AA.' * cos(ARG), size(X));
    set(hSurf,'ZData',eta,'CData',eta);

    % ---- Estado en el origen (igual a la fcn de Simulink)
    arg0   = -omega.'*t + fase;                 % N×M
    heave  = sum(Anm .* cos(arg0), 'all');
    detadx = sum(Anm .* kx .* sin(arg0), 'all');
    detady = sum(Anm .* ky .* sin(arg0), 'all');
    pitch  = atan(detadx);
    roll   = atan(detady);

    % ---- Rotación de la triada: R = Rx(roll)*Ry(pitch)
    cr = cos(roll);  sr = sin(roll);
    cp = cos(pitch); sp = sin(pitch);
    R  = [1 0 0; 0 cr -sr; 0 sr cr] * [cp 0 sp; 0 1 0; -sp 0 cp];

    o  = [0; 0; heave+0.03];
    ex = o + R*[axLen;0;0];
    ey = o + R*[0;axLen;0];
    ez = o + R*[0;0;axLen * 0.15];

    set(hX,'XData',[o(1) ex(1)],'YData',[o(2) ex(2)],'ZData',[o(3) ex(3)]);
    set(hY,'XData',[o(1) ey(1)],'YData',[o(2) ey(2)],'ZData',[o(3) ey(3)]);
    set(hZ,'XData',[o(1) ez(1)],'YData',[o(2) ez(2)],'ZData',[o(3) ez(3)]);
    set(hO,'XData',o(1),'YData',o(2),'ZData',o(3));

    Pd = R * [rDisk*cos(tDisk); rDisk*sin(tDisk); zeros(1,numel(tDisk))];
    set(hDisk,'XData',Pd(1,:),'YData',Pd(2,:),'ZData',Pd(3,:)+heave+0.03);

    hTitle.String = sprintf(['t = %5.2f s   |   heave = %+6.3f m   ' ...
        'pitch = %+6.2f deg   roll = %+6.2f deg'], t, heave, ...
        rad2deg(pitch), rad2deg(roll));

    % ---- Captura sin mostrar ventana
    F = print(fig,'-RGBImage','-r96');

    if i == 1
        hPix = size(F,1) - mod(size(F,1),2);    % dimensiones pares (MPEG-4)
        wPix = size(F,2) - mod(size(F,2),2);
    end

    % Normalizar a tamaño constante sin Image Processing Toolbox:
    % recorte si sobra, relleno negro si falta.
    if size(F,1) ~= hPix || size(F,2) ~= wPix
        G = zeros(hPix, wPix, 3, 'uint8');
        r = min(hPix, size(F,1));
        c = min(wPix, size(F,2));
        G(1:r, 1:c, :) = F(1:r, 1:c, :);
        F = G;
    else
        F = F(1:hPix, 1:wPix, :);
    end

    writeVideo(v, F);

    if mod(i,fps)==0, fprintf('  %5.1f s / %d s\n', t, Tend); end
end

close(v);
close(fig);
fprintf('Listo: %s  (%d cuadros, %d×%d px, %.0f s)\n', ...
        vidName, numel(tvec), wPix, hPix, Tend);