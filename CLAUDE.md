# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MARLUP is a MATLAB/Simulink control-systems project for a wave-compensated stabilization platform (3 actuators controlling roll, pitch, and heave). There is no build system, package manager, or test suite — everything runs inside MATLAB/Simulink.

## Workflow

The core workflow is two files in `Files/`:

1. **`Files/Script_MARLUP_Final.m`** — run this first in MATLAB. It defines the plant model and computes every gain/matrix the Simulink model needs, leaving them in the base workspace (`Ad`, `Bd`, `Cd`, `Kx`, `Ki`, `Ld`, `T`, `Tinv`, `P_reorder`, etc.).
2. **`Files/MarlupFinal_FINAL.slx`** — the main Simulink model. It reads those workspace variables, so it fails if the script hasn't been run in the same session.

Simulink files (`.slx`), `.mat` data, and media files are binary — they cannot be meaningfully read or edited as text. Changes to the model must be made in Simulink; only the `.m` scripts are editable here.

## Control Architecture (Script_MARLUP_Final.m)

- **State vector**: `x = [roll(α), roll_rate, pitch(θ), pitch_rate, heave(z), heave_rate]`; outputs `y = [roll, pitch, heave]`. Inputs are `[τx, τy, Fz]`, mapped to the 3 physical actuator forces `[F1, F2, F3]` via the geometry matrix `T` / `Tinv`.
- **Plant**: ideal double-integrator dynamics (no damping/stiffness), discretized with ZOH at `Ts = 0.01`. **Every discrete block in the Simulink model must use the same `Ts` as the script** — mismatched sample times are a known failure mode (note the script's comments still mention 0.001 in places; the authoritative value is the `Ts` variable).
- **Estimation**: discrete Kalman filter via `dlqe` (gain `Ld`).
- **Control**: LQI on the augmented system (state feedback `Kx` + error integrator `Ki`), computed both manually via `dlqr` on the augmented matrices and cross-checked with `lqi`. A separate continuous LQR (`K`), observer (`L`), and pre-compensation gain (`Kr`) exist for the non-integrator variant — `Kr` must not be combined with the integrator.
- **Wave disturbance**: modeled as an output disturbance, `y_total = C*x + P_reorder*y_amb`. The wave subsystem outputs `[heave; pitch; roll]` while the model expects `[roll; pitch; heave]`; `P_reorder` fixes the ordering. Do not inject the disturbance through the state equation.
- The comment block "Variables clave para Simulink" at the end of the script documents exactly how each variable wires into the model, including the anti-windup scheme for actuator saturation.

## Repository Layout

- `Files/Figures/` — result plots and simulation videos (binary).
- `Files/Referencia/` — reference material: the final project report (PDF), an earlier scaled-prototype system (`Sistema escalado/`) with its own Simulink models, SolidWorks CAD parts, system-identification data, and `PruebaExtraccionPlanta.m` (plant extraction / PID tuning experiments via `linmod`). This is historical/reference content, not the active model.
- Code comments and documentation are in Spanish; keep new comments consistent with that.
