# Header micro-palette, touch-render, and material-field V2 Implementation Plan

> **For agentic workers:** Execute inline task-by-task; this task explicitly prohibits subagents.

**Goal:** Repair the Header’s palette information density, establish and prove the native runtime-shader path, migrate the pixel-prone touch overlay to the retained GPU program, and make Deep Drift one continuous material.

**Architecture:** `CategoryColorCatalog` remains the single semantic color authority. `BudgetHeaderPaletteGenerator` derives a cyclic-neighbor-guided OKLCH micro-palette and `BudgetHeaderColorWindowSampler` keeps continuous sampling. The single `DashboardHeaderFragmentBackend` owns all normal Header pixels—including touch overlay/trails—and the retained Deep Drift skeleton supplies bounded geometry while shader math derives one global continuous material coordinate.

**Tech stack:** Flutter 3.41.4 runtime shaders, Dart/Flutter tests, GitHub human diagnostic APK.

## Global constraints

- Preserve the single Header clock and single retained FragmentProgram.
- No new data/domain work, persistence, bridge, or carousel-physics work on Header/interaction frames.
- No alternate entrypoint, prototype page, WebView, low-resolution intermediate, or normal mesh route.
- RED → GREEN → REFACTOR for each task; run Flutter commands inside Ubuntu proot.

### Task 1: Establish renderer and palette evidence

**Files:**
- Modify: checklist above when audit evidence is complete
- Inspect: `docs/prototypes/color_lab.html`, `dashboard_header_*`, shader, diagnostics logger

- [x] Write tests which expose canonical-slot-6, weak 28/30% separation, absent physical-path event propagation, unsupported GLSL, Canvas touch path, and fixed depth layer color math.
- [x] Run the focused tests and record their expected RED failures.

### Task 2: Palette V2 and tuner evidence

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_budget_palette.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Test: `test/features/dashboard/presentation/dashboard_header_budget_palette_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`

- [x] Replace the monolinear ramp with piecewise OKLCH anchors derived from cyclic neighbor hues; preserve exact canonical slot 7.
- [x] Add a fixture generated from the finalized catalog and perceptual 28/30% metrics across all categories.
- [x] Add numbered visual slots, identity marker, and active window/A-B overlay to the existing collapsed palette section.
- [x] Run focused unit/widget tests green, then refactor duplicated color math.

### Task 3: Native runtime shader and touch composition

**Files:**
- Modify: `shaders/dashboard_header_field.frag`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`
- Modify/remove responsibility: `dashboard_header_tap_wave_painter.dart`
- Test: fragment backend, visual engine and tap wave tests

- [x] Replace unsupported integer hash with tested float-only lattice hash and compile/load the declared shader through the pinned SDK.
- [x] Carry retained tap-overlay/trail state as compact shader uniforms; draw all active touch optics in fragment coordinates.
- [x] Emit low-frequency backend/touch diagnostics from the real Header lifecycle and configuration path—not merely logger string acceptance.
- [x] Preserve source colors, stops, timing, ripple displacement, bounded capacity, rounded clipping, and one program/clock.

### Task 4: Deep Drift continuous material redesign

**Files:**
- Modify: `dashboard_header_deep_drift.dart`
- Modify: `shaders/dashboard_header_field.frag`
- Test: `test/features/dashboard/presentation/dashboard_header_deep_drift_test.dart`

- [x] Add bounded apparent-Z values to retained storage and use each value coherently for optical geometry.
- [x] Accumulate density and depth first, then calculate a single global A/B material coordinate with weak continuous modulation.
- [x] Add deterministic weighted-depth continuity tests; retain the cubic 3×5 blob contract.

### Task 5: Verify and deliver

**Files:** all changed tests, checklist

- [x] Run focused tests, analyzer, fast suite, protected motion checks, and no physics diff. Full suite has an isolated unrelated rail-density trace failure, recorded in the checklist.
- [x] Re-read approved references/checklist and update every status honestly.
- [ ] Commit focused changes, push `separated-core-modes`, wait for all required CI jobs, then download the normal human APK to `/storage/emulated/0/Download/fluvi` and record SHA-256.
