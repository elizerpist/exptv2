# Budget Header palette domain and continuous material implementation plan

> **For agentic workers:** Execute inline because the user explicitly disallowed subagents. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the positive-limit Budget Header's white-endpoint scale with a live canonical 21×10 palette domain, expose it safely in the existing tuner, and make Deep Drift a continuous field-led material without disturbing Dashboard motion or data ownership.

**Architecture:** Add a pure `BudgetHeaderPaletteCatalog` and `BudgetHeaderColorWindowSampler` beside the shared Header visual engine.  The existing Budget colour policy resolves one immutable palette-window frame from retained presentation state.  The retained shader stays the only normal renderer; its existing Deep Drift branch gains directional carrier/advection blending while retaining the one shared clock, program and bounded input skeleton.

**Tech Stack:** Dart/Flutter, existing category visual catalog, retained Flutter runtime shader, existing FLOW diagnostics, GitHub Actions human APK.

## Global constraints

- Work only on `separated-core-modes`; no centered-carousel, TimeRail or expansion physics changes.
- TDD: every production behavior below first has a focused test that fails for the current implementation.
- No extra palette/token colour authority, renderer, ticker, controller, app route, I/O, or frame-level logging.
- Run Flutter tooling only in Ubuntu proot.  Build normal Android APK only in GitHub Actions.

### Task 1: Pure palette/window domain and boundary contract

**Files:**
- Create `lib/features/dashboard/presentation/core_modes/dashboard_header_budget_palette.dart`
- Modify `dashboard_header_visual_engine.dart`
- Create `test/features/dashboard/presentation/dashboard_header_budget_palette_test.dart`
- Modify `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`

- [ ] **Step 1: Write RED tests** for 21 palettes × 10 slots, identity-slot placement, non-white endpoint mode, continuous sampler A/B and exact width clamping.
- [ ] **Step 2: Run** `flutter test test/features/dashboard/presentation/dashboard_header_budget_palette_test.dart test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`; record expected failures because `BudgetHeaderColorScale` still samples white.
- [ ] **Step 3: Implement** immutable palette, OKLab conversion/interpolation, deterministic catalog cache and sampler.
- [ ] **Step 4: Replace** positive-limit policy projection with sampler result; preserve no-limit canonical gradients and aggregate source gradient.
- [ ] **Step 5: Re-run focused tests** and commit the isolated palette binding.

### Task 2: Semantic diagnostics and collapsible tuner UI

**Files:**
- Modify `dashboard_header_visual_engine.dart`
- Modify `dashboard_header_visual_tuner.dart`
- Modify `lib/core/diagnostics/fluvi_diagnostic_logger.dart`
- Modify `dashboard_header_visual_tuner_test.dart`
- Modify `fluvi_diagnostic_logger_test.dart`

- [ ] **Step 1: Write RED tests** for separate section state, live slider mutation, 21 preview rows × 10 swatches, and bounded palette FLOW payloads.
- [ ] **Step 2: Run** the tuner/logger focused test command; record current non-collapsible/missing-palette failures.
- [ ] **Step 3: Implement** controller-owned collapsed-section state and reusable `_CollapsibleTunerSection`; keep card placement and ListView ownership unchanged.
- [ ] **Step 4: Implement** palette-preview rows from the centralized catalog and diagnostics from the policy/render boundary only.
- [ ] **Step 5: Re-run focused tests** and commit tuner/diagnostics separately.

### Task 3: Deep Drift continuous material correction

**Files:**
- Modify `dashboard_header_deep_drift.dart`
- Modify `shaders/dashboard_header_field.frag`
- Modify `dashboard_header_deep_drift_test.dart`

- [ ] **Step 1: Write RED tests** that freeze directional carrier/advection, rotation-secondary transform sizing, continuous density blending and retained storage identity.
- [ ] **Step 2: Run** Deep Drift tests and record source-contract failures.
- [ ] **Step 3: Implement** retained directional layer flow in the skeleton and a per-fragment smooth carrier/density composition before alpha/tone; retain 3×5 cubic blobs and analytic lighting.
- [ ] **Step 4: Verify** shader source contains no new CPU field/multi-program route, no blob-loop trig/exp/sqrt, and all focused tests pass.
- [ ] **Step 5: Commit** the material correction separately.

### Task 4: Regression, delivery and physical status

- [ ] **Step 1: Run** targeted Header/diagnostics/Budget tests and the project-required protected suites in Ubuntu proot; run `flutter analyze`.
- [ ] **Step 2: Inspect** `git diff -- lib/shared/motion/centered_carousel/centered_carousel_physics.dart` and confirm it is empty.
- [ ] **Step 3: Re-read** this plan, the design, the acceptance checklist and Color Lab reference; update every requirement status honestly.
- [ ] **Step 4: Commit/push** focused source changes, wait for exact-SHA GitHub Actions and download the normal human APK to `/storage/emulated/0/Download/fluvi`.
- [ ] **Step 5: Report** automated evidence and leave device-only appearance acceptance explicitly pending until the user tests the delivered APK.
