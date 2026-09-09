function ident = marlup_identify(mdl, opt)
%MARLUP_IDENTIFY  Numerical identification of the MARLUP Simscape plant.
%
%   ident = MARLUP_IDENTIFY()            uses model 'Model_will'
%   ident = MARLUP_IDENTIFY(mdl)
%   ident = MARLUP_IDENTIFY(mdl, opt)
%
%   WHY THIS EXISTS
%   ---------------
%   The analytic plant used so far (T = uz*[Rt*sin(phi); -Rt*cos(phi); 1])
%   assumes three identical legs at azimuths -30/90/210 deg, perfectly
%   symmetric, thrusting along a common cone. The actual Simscape assembly
%   does NOT have that symmetry: the three Rigid Transform blocks that
%   attach the legs to the "Triangulo" are hand-fitted Euler triples
%
%       Piston1 -> [ 75  60  -4] deg
%       Piston3 -> [-20   0 -90] deg
%       Piston2 -> [249 240 176] deg
%
%   so the real force-to-acceleration map is neither symmetric nor
%   necessarily sign-consistent with T. On top of that, the effective
%   inertia seen at the plate is not simply (Jx, Jy, Mass), because the
%   moving parts of the legs contribute through the mechanism Jacobian.
%
%   Rather than re-deriving the geometry from the CAD, this function
%   measures the plant directly.
%
%   METHOD
%   ------
%   The plate has exactly 3 DOF (3 legs x 5 passive/active joint DOF each
%   -> Gruebler gives 3). Starting from rest at the assembled configuration
%   q0, the generalized accelerations are an AFFINE function of the three
%   piston forces:
%
%       qddot(0) = W * F + c
%
%   where c is the gravity/bias term and W (3x3) is the inverse effective
%   inertia mapped through the mechanism Jacobian. Four short open-loop
%   runs identify W and c exactly:
%
%       F = 0            -> c
%       F = dF * e_i     -> W(:,i) = (a_i - c)/dF        i = 1,2,3
%
%   Acceleration is recovered by least-squares fitting v(t) = a*t over the
%   first few tens of milliseconds, using the plant's OWN velocity outputs
%   (vRoll, vPitch, vZ). No numerical differentiation, no toolbox needed.
%
%   A fifth run with F = dF*[1;1;1] verifies superposition; if it fails,
%   the operating point is not in the linear regime (usually because a
%   joint limit is being hit).
%
%   NOTHING IN THE PLANT IS MODIFIED. Only controller-path parameters
%   (the K gain, the Tinv gain, the two Constants) and solver settings are
%   changed, and everything is restored on exit, including on error.
%
%   OUTPUT (struct)
%     .W        3x3  [alphaddot; thetaddot; zddot] per newton of [F1;F2;F3]  (SI)
%     .c        3x1  bias (gravity) acceleration at q0                        (SI)
%     .F_trim   3x1  piston forces that hold the plate static at q0           (N)
%     .A,.B     6x6 / 6x3 continuous state-space, x = [a; adot; th; thdot; z; zdot] (SI)
%     .C        3x6 output selection [roll; pitch; z]
%     .S_deg2si 6x6 diagonal converting the plant's output vector to SI
%     .z0       assembled plate height (m)  <-- your z reference must be near this
%     .lin_err  superposition check, relative
%
%   Author: written for W. Smith / A. Perez, MARLUP Control Stage 2.

% ------------------------------------------------------------------
% 0. Options
% ------------------------------------------------------------------
if nargin < 1 || isempty(mdl), mdl = 'Model_will'; end
if nargin < 2, opt = struct(); end

def = struct( ...
    'dF',        400, ...      % [N] probe force per piston
    'T_id',      0.06, ...     % [s] length of each identification run
    'T_fit',     0.04, ...     % [s] end of the least-squares window
    't_skip',    0.004, ...    % [s] samples before this are discarded
    'MaxStep',   5e-4, ...     % [s] solver max step during identification
    'RelTol',    1e-6, ...
    'AbsTol',    1e-8, ...
    'verbose',   true);
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opt, fn{k}), opt.(fn{k}) = def.(fn{k}); end
end

load_system(mdl);

% ------------------------------------------------------------------
% 1. Save everything we are about to touch, and guarantee restoration
% ------------------------------------------------------------------
P.mdlParams = {'StopTime','SolverName','RelTol','AbsTol','MaxStep', ...
               'SimulationMode','SignalLogging','SignalLoggingName', ...
               'SignalLoggingSaveFormat','SimscapeLogType'};
P.mdlValues = cellfun(@(p) get_param(mdl,p), P.mdlParams, 'uni', 0);

blk.K     = [mdl '/Gain'];                       % matrix gain, currently K
blk.ref   = [mdl '/Referencias'];                   % 6x1 state reference
blk.ueq   = [mdl '/Fsat'];                  % 3x1 feedforward
blk.Hs    = [mdl '/P-M SPECTRUM/Constant1'];     % significant wave height
P.blkNames  = fieldnames(blk);
P.blkValues = cellfun(@(f) get_param(blk.(f),'Value_or_Gain_placeholder'), ...
                      {}, 'uni', 0); %#ok<NASGU>  (filled below)

P.saved = struct();
P.saved.K    = get_param(blk.K,   'Gain');
P.saved.ref  = get_param(blk.ref, 'Value');
P.saved.ueq  = get_param(blk.ueq, 'Value');
P.saved.Hs   = get_param(blk.Hs,  'Value');

% Port logging state of the PLANTA outputs
ph = get_param([mdl '/PLANTA'],'PortHandles');
assert(numel(ph.Outport) == 6, 'PLANTA should have 6 outputs.');
P.portLog  = arrayfun(@(h) get_param(h,'DataLogging'),         ph.Outport, 'uni', 0);
P.portMode = arrayfun(@(h) get_param(h,'DataLoggingNameMode'), ph.Outport, 'uni', 0);
P.portName = arrayfun(@(h) get_param(h,'DataLoggingName'),     ph.Outport, 'uni', 0);

cleaner = onCleanup(@() local_restore(mdl, blk, ph, P)); %#ok<NASGU>

% ------------------------------------------------------------------
% 2. Configure the model for identification
% ------------------------------------------------------------------
% PLANTA output port order, read straight out of the .slx:
%   1 vZ_marlup  2 Z_marlup  3 vPitch_marlup  4 Pitch_marlup  5 vRoll_marlup  6 Roll_marlup
sigNames = {'id_vZ','id_Z','id_vPitch','id_Pitch','id_vRoll','id_Roll'};
for k = 1:6
    set_param(ph.Outport(k), 'DataLogging','on', ...
                             'DataLoggingNameMode','Custom', ...
                             'DataLoggingName', sigNames{k});
end

set_param(mdl, 'SignalLogging','on', 'SignalLoggingName','logsout', ...
               'SignalLoggingSaveFormat','Dataset', ...
               'SimulationMode','normal', ...
               'SolverName','ode23t', ...
               'RelTol', num2str(opt.RelTol), ...
               'AbsTol', num2str(opt.AbsTol), ...
               'MaxStep',num2str(opt.MaxStep), ...
               'StopTime',num2str(opt.T_id), ...
               'SimscapeLogType','none');     % faster; we use signal logging

% Open the loop: zero feedback, identity actuator map, force = Constant1.
set_param(blk.K,    'Gain', 'zeros(3,6)');
set_param(blk.ref,  'Value','zeros(6,1)');
set_param(blk.Hs,   'Value','0');             % flat sea: fixed base

% ------------------------------------------------------------------
% 3. Run the probe experiments
% ------------------------------------------------------------------
Ftests = [zeros(3,1), opt.dF*eye(3), opt.dF*ones(3,1)];
nT     = size(Ftests,2);
acc    = zeros(3,nT);
z0     = NaN;

if opt.verbose
    fprintf('\n--- MARLUP plant identification -------------------------\n');
    fprintf('Model      : %s\n', mdl);
    fprintf('Probe force: %.0f N   window: %.3f s   solver: ode23t\n\n', opt.dF, opt.T_fit);
end

for k = 1:nT
    set_param(blk.ueq,'Value', mat2str(Ftests(:,k)));
    simOut = sim(mdl, 'ReturnWorkspaceOutputs','on');
    L = simOut.logsout;

    [tv, vRoll ] = local_get(L,'id_vRoll');    % deg/s
    [~ , vPitch] = local_get(L,'id_vPitch');   % deg/s
    [~ , vZ    ] = local_get(L,'id_vZ');       % m/s
    [~ , Z     ] = local_get(L,'id_Z');        % m
    if k == 1, z0 = Z(1); end

    d2r = pi/180;
    acc(1,k) = local_fitslope(tv, vRoll *d2r, opt.t_skip, opt.T_fit);
    acc(2,k) = local_fitslope(tv, vPitch*d2r, opt.t_skip, opt.T_fit);
    acc(3,k) = local_fitslope(tv, vZ,         opt.t_skip, opt.T_fit);

    if opt.verbose
        fprintf('  F = [%6.0f %6.0f %6.0f] N  ->  qddot = [%9.4f %9.4f %9.4f]  (rad/s^2, rad/s^2, m/s^2)\n', ...
                Ftests(:,k), acc(:,k));
    end
end

% ------------------------------------------------------------------
% 4. Assemble the affine model  qddot = W*F + c
% ------------------------------------------------------------------
c = acc(:,1);
W = (acc(:,2:4) - c) / opt.dF;

% superposition check
a_pred = W*Ftests(:,5) + c;
lin_err = norm(a_pred - acc(:,5)) / max(norm(acc(:,5)), eps);

F_trim = -W \ c;

% ------------------------------------------------------------------
% 5. Build the state-space model (SI units throughout)
%    x = [alpha; alpha_dot; theta; theta_dot; z; z_dot]
%    u = [F1; F2; F3]  (piston forces, N)
% ------------------------------------------------------------------
A = zeros(6); A(1,2)=1; A(3,4)=1; A(5,6)=1;
B = zeros(6,3); B(2,:) = W(1,:); B(4,:) = W(2,:); B(6,:) = W(3,:);
C = [1 0 0 0 0 0; 0 0 1 0 0 0; 0 0 0 0 1 0];

% The plant reports angles in DEGREES and z in metres. This converts its
% output vector (as assembled by the root Mux) into SI.
S_deg2si = diag([pi/180, pi/180, pi/180, pi/180, 1, 1]);

ident = struct('W',W,'c',c,'F_trim',F_trim,'A',A,'B',B,'C',C, ...
               'S_deg2si',S_deg2si,'z0',z0,'lin_err',lin_err, ...
               'acc',acc,'Ftests',Ftests,'opt',opt,'mdl',mdl, ...
               'date',datetime('now'));

% ------------------------------------------------------------------
% 6. Report
% ------------------------------------------------------------------
if opt.verbose
    fprintf('\n  Bias (gravity) acceleration c   = [%8.4f %8.4f %8.4f]\n', c);
    fprintf('  Superposition error             = %.2e  (want < 1e-2)\n', lin_err);
    fprintf('\n  W  [ (rad/s^2 or m/s^2) per N ]\n');
    disp(W);
    fprintf('  cond(W)       = %.2f\n', cond(W));
    fprintf('  rank(ctrb)    = %d / 6\n', rank(ctrb(A,B)));
    fprintf('\n  F_trim        = [%7.1f %7.1f %7.1f] N per piston\n', F_trim);
    fprintf('  Assembled z0  = %.4f m\n', z0);
    fprintf('  Usable heave  ~ %.3f .. %.3f m  (piston stroke +-0.28 m, uz~0.509)\n', ...
            z0-0.13, z0+0.13);

    % Compare against the analytic T that the old scripts assumed.
    H=0.11; Rb=0.13; Rt=0.65; uz=Rb/sqrt(Rb^2+4*H^2);
    phi=deg2rad([-30 90 210]);
    T_theory = uz*[ Rt*sin(phi); -Rt*cos(phi); ones(1,3)];
    Meff = diag(1./[ W(3,:)*ones(3,1)*0+1 ]); %#ok<NASGU>
    % Effective generalized-force map implied by the identification, using
    % the nominal inertias for scaling so the two are comparable:
    T_ident = diag([6.19446, 6.19446, 67.7085]) * W;
    fprintf('\n  Analytic T assumed so far:\n'); disp(T_theory);
    fprintf('  Equivalent T implied by the model (J*W):\n'); disp(T_ident);
    rel = norm(T_ident - T_theory,'fro')/norm(T_theory,'fro');
    fprintf('  Relative difference = %.1f %%\n', 100*rel);
    if rel > 0.15
        fprintf(['  >> The analytic T does NOT describe this assembly.\n' ...
                 '     Use the identified W. Do not use Tinv in the loop.\n']);
    end
    if any(diag(W) == 0)
        warning('marlup:W','W has a zero on the diagonal - check leg/axis assignment.');
    end
    if lin_err > 1e-2
        warning('marlup:lin', ...
            ['Superposition check failed (%.2e). The probe is leaving the linear\n' ...
             'regime - most likely a joint limit is active. Reduce dF or T_id.'], lin_err);
    end
    fprintf('---------------------------------------------------------\n\n');
end

save('marlup_ident.mat','ident');
end

% ======================================================================
function [t,y] = local_get(L, name)
el = L.getElement(name);
t  = el.Values.Time;
y  = squeeze(el.Values.Data);
end

% ----------------------------------------------------------------------
function a = local_fitslope(t, v, tskip, tfit)
%LOCAL_FITSLOPE  Least-squares slope of v(t)=a*t through the origin.
m = t > tskip & t <= tfit;
if nnz(m) < 5
    error('marlup:fit', ...
        'Only %d samples in the fit window. Reduce MaxStep or increase T_fit.', nnz(m));
end
tt = t(m); vv = v(m);
a  = (tt.'*vv) / (tt.'*tt);
end

% ----------------------------------------------------------------------
function local_restore(mdl, blk, ph, P)
try
    for k = 1:numel(P.mdlParams)
        set_param(mdl, P.mdlParams{k}, P.mdlValues{k});
    end
    set_param(blk.K,   'Gain', P.saved.K);
    set_param(blk.ref, 'Value',P.saved.ref);
    set_param(blk.ueq, 'Value',P.saved.ueq);
    set_param(blk.Hs,  'Value',P.saved.Hs);
    for k = 1:6
        set_param(ph.Outport(k), 'DataLogging',         P.portLog{k}, ...
                                 'DataLoggingNameMode', P.portMode{k}, ...
                                 'DataLoggingName',     P.portName{k});
    end
catch ME
    warning('marlup:restore','Could not fully restore the model: %s', ME.message);
end
end