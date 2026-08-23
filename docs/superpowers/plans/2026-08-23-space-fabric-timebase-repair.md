# Space Fabric Single-Speed Timebase Repair Implementation Plan

> **For agentic workers:** Execute inline in this existing isolated worktree.
> The user explicitly prohibits subagents.

**Goal:** Make all Space Fabric variants visibly temporal by removing their
secondary shader speed scaling while preserving the current metric warp model.

**Architecture:** The existing `DashboardHeaderVisualController` remains the
sole speed/phase owner. `spaceFabricSourceUv` receives the already
speed-scaled `uPhase` and converts it once through a fixed, named calibration
scale before applying its current per-mode frequency ratios. A render-backed
temporal test freezes the contract at 1/3/8-second phase intervals.

**Tech Stack:** Flutter/Dart, runtime fragment shader ABI v3, `flutter_test`,
GitHub Actions normal `lib/main.dart` profile APK.

## Global constraints

- Do not change Full Field Flow, orientation drift, Cool P/W, static output,
  Palette sampling, metric coefficients, IDs 14–17, Portal/touch ownership or
  `MILESTONE_COMMITS.md`.
- Keep one Header ticker and ABI v3.
- Tests/analyzer run in Ubuntu proot; APK builds run in GitHub Actions.

### Task 1: Freeze temporal contracts

**Files:**
- Create: `test/features/dashboard/presentation/dashboard_header_space_fabric_temporal_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_space_fabric_warp_test.dart`

- [ ] Add runtime-shader raster comparisons at 1/3/8 seconds for IDs 14–17.
- [ ] Add speed-zero, monotonic controller phase and source-contract tests.
- [ ] Run the temporal suite against current code and confirm its calibrated
  default-motion assertion fails because of secondary speed scaling.
- [ ] Commit: `test(header): expose frozen space-fabric timebase`.

### Task 2: Repair the single speed owner

**Files:**
- Modify: `shaders/dashboard_header_field.frag`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`

- [ ] Replace the local `phase * f(speed)` with one named fixed conversion of
  the controller-owned phase; remove the shader-local speed read.
- [ ] Extend only configuration/manual diagnostics with the single-speed
  contract metadata.
- [ ] Run the temporal suite plus shader backend test and verify GREEN.
- [ ] Commit: `fix(header): make space-fabric phase single-speed`.

### Task 3: Regression and delivery

**Files:**
- Verify only: protected Dashboard sources and `MILESTONE_COMMITS.md`.

- [ ] Run focused Header suites, analyzer, fast/protected suite, shader
  compile/load and profile watchdog.
- [ ] Check protected diffs, exact remote parity and CI success.
- [ ] Download the exact normal profile APK to
  `/storage/emulated/0/Download/fluvi` and compute SHA-256.
