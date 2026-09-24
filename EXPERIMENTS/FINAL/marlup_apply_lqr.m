function marlup_apply_lqr(des, mdl)
%MARLUP_APPLY_LQR  Push the stage-1 controller into the model.
%
%   marlup_apply_lqr(des)          des from marlup_design
%   marlup_apply_lqr(des, mdl)
%
%   This is the "no structural edit" version: it only changes four block
%   parameters plus the solver settings. The PLANTA subsystem is untouched.
%
%     Gain      ->  K_model   (Kx with the deg->rad conversion folded in)
%     Gain1     ->  eye(3)    (Tinv removed; the LQR does the allocation)
%     Constant1 ->  F_trim    (real static load, ~435 N/piston, not 64 N)
%     Constant  ->  [0;0;0;0;z_ref;0]
%
%   Run marlup_identify and marlup_design first.

if nargin < 1 || isempty(des)
    S = load('marlup_design.mat'); des = S.des;
end
if nargin < 2 || isempty(mdl), mdl = 'MARLUP_sinKF'; end

load_system(mdl);

set_param([mdl '/LQR'],      'Gain',  mat2str(des.K_model, 10));
%set_param([mdl '/Gain1'],     'Gain',  'eye(3)');
set_param([mdl '/F_trim'], 'Value', mat2str(des.F_trim, 10));
set_param([mdl '/Referencias'],  'Value', mat2str(des.ref_model, 10));

% Solver: the shipped settings (RelTol = AbsTol = 1e-2) are far too loose
% for signals of order 1e-3 rad.
set_param(mdl, 'SolverName','ode23t', ...
               'RelTol','1e-4', 'AbsTol','1e-6', 'MaxStep','0.01', ...
               'SimulationMode','normal');

fprintf('Applied stage-1 LQR to %s\n', mdl);
fprintf('  z_ref   = %.4f m   (assembled z0 = %.4f m)\n', des.z_ref, des.z0);
fprintf('  F_trim  = [%.1f %.1f %.1f] N\n', des.F_trim);
fprintf('  Solver  = ode23t, RelTol 1e-4, AbsTol 1e-6, MaxStep 0.01\n');
fprintf('\nRun the model. Then check, in this order:\n');
fprintf('  1. Do the three piston strokes stay well inside +-0.28 m?\n');
fprintf('     simlog.PLANTA.Piston1.Prismatic_Joint.Pz.p.series.values\n');
fprintf('  2. Does the yaw of the plate stay near zero?\n');
fprintf('     The Bearing Joint''s Rz is a FREE, undamped, unmeasured DOF.\n');
fprintf('     simlog.PLANTA.Union_4DOF.Rz.q.series.values\n');
fprintf('     If it drifts, that is your 20-second time bomb: the actuator\n');
fprintf('     axes rotate away from the world-frame roll/pitch you measure.\n');
fprintf('  3. Roll/pitch should settle within a couple of tenths of a degree.\n');
fprintf('     Steady heave offset is expected until you add the integrator.\n');
end