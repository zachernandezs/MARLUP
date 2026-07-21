# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MARLUP is a MATLAB/Simulink control-systems project for a wave-compensated stabilization platform (3 actuators controlling roll, pitch, and heave). There is no build system, package manager, or test suite — everything runs inside MATLAB/Simulink.

## Workflow

The core workflow is two files in `MODELS/`:

1. **`MODELS/marlup_init.m`** — run this first in MATLAB. It defines the plant model and computes every gain/matrix the Simulink model needs, leaving them in the base workspace (`Ad`, `Bd`, `Cd`, `Kx`, `Ki`, `Ld`, `T`, `Tinv`, `P_reorder`, etc.). It also calls `addpath` to add `CAD/` to the MATLAB path (resolved relative to the script's own location, so it still works after moves), so the model's File Solid blocks resolve the `.SLDPRT` geometry by name on any machine (no hardcoded absolute paths).
2. **`MODELS/marlup_model.slx`** — the main Simulink model. It reads those workspace variables, so it fails if the script hasn't been run in the same session.

Simulink files (`.slx`), CAD files (`.SLDPRT`/`.SLDASM`), and media files are binary — they cannot be meaningfully read or edited as text. Changes to the model must be made in Simulink; only `MODELS/marlup_init.m` is editable here.

## Control Architecture (MODELS/marlup_init.m)

- **State vector**: `x = [roll(α), roll_rate, pitch(θ), pitch_rate, heave(z), heave_rate]`; outputs `y = [roll, pitch, heave]`. Inputs are `[τx, τy, Fz]`, mapped to the 3 physical actuator forces `[F1, F2, F3]` via the geometry matrix `T` / `Tinv`.
- **Plant**: ideal double-integrator dynamics (no damping/stiffness), discretized with ZOH at `Ts = 0.01`. **Every discrete block in the Simulink model must use the same `Ts` as the script** — mismatched sample times are a known failure mode (the script's "Variables clave" comment block still says `Ts = 0.001` in a couple of places; the authoritative value is the `Ts` variable defined earlier, `0.01`).
- **Estimation**: discrete Kalman filter via `dlqe` (gain `Ld`).
- **Control**: LQI on the augmented system (state feedback `Kx` + error integrator `Ki`), computed both manually via `dlqr` on the augmented matrices and cross-checked with `lqi`. A separate continuous LQR (`K`), observer (`L`), and pre-compensation gain (`Kr`) exist for the non-integrator variant — `Kr` must not be combined with the integrator.
- **Wave disturbance**: modeled as an output disturbance, `y_total = C*x + P_reorder*y_amb`. The wave subsystem outputs `[heave; pitch; roll]` while the model expects `[roll; pitch; heave]`; `P_reorder` fixes the ordering. Do not inject the disturbance through the state equation.
- The comment block "Variables clave para Simulink" at the end of the script documents exactly how each variable wires into the model, including the anti-windup scheme for actuator saturation.

## Repository Layout

- `CAD/` — SolidWorks parts (`.SLDPRT`) and the main assembly (`ably.SLDASM`) used by the Simulink model's File Solid blocks; `MODELS/marlup_init.m` adds this folder to the MATLAB path (see Workflow above).
- `DOCS/` — final project reports (PDF) and `DOCS/FIGS/` with result plots and simulation videos (binary).
- `MODELS/` — the active MATLAB script + Simulink model (see Workflow above). Previously named `IAC/`.
- `EXPERIMENTS/` — placeholder for future experiment scripts/data; currently empty, so it is not tracked by git until it holds a file.
- Code comments and documentation are in Spanish; keep new comments consistent with that.

Note: the repo has been reorganized twice (see git history): first from a `Files/` layout into `CAD`/`DOCS`/`IAC`, then `IAC/` was renamed to `MODELS/` with its script and model renamed to `marlup_init.m`/`marlup_model.slx`. Older reference material (a scaled prototype system, system-identification data, `PruebaExtraccionPlanta.m`) that used to live under `Files/Referencia/` was dropped in the first reorg and no longer exists in this repository.
