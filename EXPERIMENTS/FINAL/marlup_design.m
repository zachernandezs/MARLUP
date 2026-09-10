function des = marlup_design(ident, opt)
%MARLUP_DESIGN_V2  Corrected control design for the identified MARLUP plant.
%
%   Replaces marlup_design.m, which had a real defect: it bisected a scalar
%   rho multiplying R until the SLOWEST closed-loop pole hit a bandwidth
%   target. For this plant the slowest pole saturates near 1.009 rad/s no
%   matter how small rho gets, because with integral augmentation the slow
%   closed-loop poles converge to transmission zeros fixed by the ratio
%   Qi/Q, which rho does not touch. The bisection therefore ran to its
%   lower bracket and returned rho = 1e-9, giving gains of ~6e8 and a
%   closed-loop pole at 1.56e6 rad/s.
%
%   Symptom to recognise: rho printed as exactly 1.00e-09 (or 1.00e+09),
%   i.e. one of the initial brackets, and a "fastest pole" many orders of
%   magnitude above anything physical.
%
%   This version drops the numerical search. Because the identified W is
%   square and well conditioned (cond ~ 3), it decouples the plant exactly:
%
%       v = W*(F - F_trim)      =>      qddot = v
%
%   so each axis is a unit double integrator and the poles can be placed in
%   closed form. Same control structure, same Simulink wiring, sane gains.
%
%   des = MARLUP_DESIGN_V2(ident)
%   des = MARLUP_DESIGN_V2(ident, opt)
%   des = MARLUP_DESIGN_V2()            loads marlup_ident.mat
%
%   OPTIONS
%     .wn     [1x3] natural frequency per axis [roll pitch heave], rad/s
%             default [3 3 4]. Wave peak is 2*pi/Tp = 0.628 rad/s, so this
%             is ~5x separation. Upper bound is set by the piston dynamics
%             and the solver, not by the algebra.
%     .zeta   [1x3] damping, default [0.9 0.9 0.9]
%     .wi     [1x3] integrator pole, default wn/4
%     .z_ref  heave reference [m], default ident.z0
%     .F_min  saturation lower limit [N], default -3000 (double acting)
%     .F_max  saturation upper limit [N], default  3000
%     .beta_aw anti-windup gain, default 1.0

if nargin < 1 || isempty(ident)
    S = load('marlup_ident.mat'); ident = S.ident;
end
if nargin < 2, opt = struct(); end

def = struct('wn',[3 3 4], 'zeta',[0.9 0.9 0.9], 'wi',[], ...
             'z_ref',ident.z0, 'F_min',-3000, 'F_max',3000, ...
             'beta_aw',1.0, 'verbose',true);
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opt,fn{k}) || isempty(opt.(fn{k})), opt.(fn{k}) = def.(fn{k}); end
end
if isempty(opt.wi), opt.wi = opt.wn/4; end

W = ident.W;
if cond(W) > 20
    warning('marlup:cond', ...
        ['cond(W) = %.1f. Exact decoupling through W^-1 will amplify\n' ...
         'identification error. Consider the LQR-on-B route instead.'], cond(W));
end
Winv   = inv(W);
F_trim = ident.F_trim;

wn = opt.wn(:).'; ze = opt.zeta(:).'; wi = opt.wi(:).';

% --- per-axis gains for a unit double integrator -------------------
%   s^3 + kd s^2 + kp s + ki = (s^2 + 2*ze*wn*s + wn^2)*(s + wi)
kd = 2*ze.*wn + wi;
kp = wn.^2 + 2*ze.*wn.*wi;
ki = wn.^2 .* wi;

G  = zeros(3,6);            % with integrator
Gp = zeros(3,6);            % proportional only, for stage 1
for i = 1:3
    G(i, 2*i-1) = kp(i);   G(i, 2*i) = kd(i);
    Gp(i,2*i-1) = wn(i)^2; Gp(i,2*i) = 2*ze(i)*wn(i);
end

Kx     = Winv * G;
Ki_use = Winv * diag(ki);
KxP    = Winv * Gp;

S         = ident.S_deg2si;
K_model   = Kx  * S;
K_model_P = KxP * S;

x_ref = [0;0;0;0;opt.z_ref;0];

% --- verification -------------------------------------------------
A = ident.A; B = ident.B; C = ident.C;
Acl_P = A - B*KxP;
Acl_I = [A - B*Kx, B*Ki_use; -C, zeros(3)];
eP = eig(Acl_P); eI = eig(Acl_I);
assert(all(real(eP) < 0) && all(real(eI) < 0), 'Closed loop unstable.');

% force excursion over a plausible error envelope
env  = [2*pi/180, 10*pi/180, 2*pi/180, 10*pi/180, 0.08, 0.40].';
dev  = abs(Kx)*env;
Flo  = F_trim - dev;  Fhi = F_trim + dev;

des = struct('Kx',Kx,'Ki_use',Ki_use,'KxP',KxP, ...
             'K_model',K_model,'K_model_P',K_model_P, ...
             'F_trim',F_trim,'x_ref',x_ref,'ref_model',x_ref, ...
             'kp',kp,'kd',kd,'ki',ki,'wn',wn,'zeta',ze,'wi',wi, ...
             'Winv',Winv,'eig_P',eP,'eig_I',eI, ...
             'F_min',opt.F_min,'F_max',opt.F_max,'beta_aw',opt.beta_aw, ...
             'z_ref',opt.z_ref,'z0',ident.z0,'mdl',ident.mdl,'opt',opt);

if opt.verbose
fprintf('\n=========================================================\n');
fprintf(' MARLUP - corrected design (exact decoupling)\n');
fprintf('=========================================================\n\n');
fprintf(' cond(W) = %.2f    max|Kx| = %.1f    max|Ki| = %.1f\n\n', ...
        cond(W), max(abs(Kx(:))), max(abs(Ki_use(:))));

fprintf(' PER-AXIS SPEC\n');
nm = {'roll ','pitch','heave'};
for i = 1:3
fprintf('   %s  wn=%.2f  zeta=%.2f  wi=%.3f  ->  kp=%7.3f  kd=%6.3f  ki=%7.3f\n', ...
        nm{i}, wn(i), ze(i), wi(i), kp(i), kd(i), ki(i));
end
fprintf('   wave peak 0.628 rad/s -> separation %.1fx\n\n', min(wn)/0.628);

fprintf(' Kx (SI):\n');            disp(Kx);
fprintf(' Ki_use (positive-feedback form):\n'); disp(Ki_use);
fprintf(' K_model = Kx*S  (existing Gain block, deg & m):\n'); disp(K_model);
fprintf(' K_model_P  (stage 1, no integrator):\n');            disp(K_model_P);
fprintf(' F_trim = [%.1f %.1f %.1f] N\n\n', F_trim);

fprintf(' CLOSED-LOOP POLES (with integrator)\n');
for k = 1:numel(eI)
fprintf('   %9.4f %+9.4fj\n', real(eI(k)), imag(eI(k)));
end
fprintf('   fastest |p| = %.3f rad/s\n\n', max(abs(eI)));

fprintf(' ACTUATOR CHECK over a 2 deg / 10 deg-s / 8 cm envelope\n');
fprintf('   deviation  [%6.1f %6.1f %6.1f] N\n', dev);
fprintf('   range      [%6.1f %6.1f %6.1f] .. [%6.1f %6.1f %6.1f] N\n', Flo, Fhi);
if any(Flo < opt.F_min) || any(Fhi > opt.F_max)
fprintf('   >> exceeds the saturation band. Either widen it (the CDH1 MP3 is\n');
fprintf('      double acting, so F_min = -3000 is defensible) or slow wn down.\n');
end
fprintf('\n reachable heave: %.3f .. %.3f m   (z_ref = %.4f)\n', ...
        ident.z0-0.13, ident.z0+0.13, opt.z_ref);
if abs(opt.z_ref - ident.z0) > 0.13
fprintf('   >> z_ref is outside the stroke. The legs will sit on their stops.\n');
end
fprintf('=========================================================\n\n');
end

save('marlup_design_v2.mat','des');
end