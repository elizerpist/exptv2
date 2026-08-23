# Header Palette Orientation and Space Fabric Implementation Plan

> **For agentic workers:** Execute inline in this session. The user explicitly prohibits subagents.

**Goal:** Add an opt-in, reversible palette-axis drift over the existing Full
Field Flow and add four independent local-metric Space Fabric source-UV
effects, without changing established flow behavior or the v3 ABI.

**Architecture:** `DashboardHeaderVisualTuning` owns a family-level orientation
value and the existing uniform cache writes it only to reserved `uMain` slots
36–39. The shader keeps the existing fixed 112° helper as the literal OFF
path; a dynamic CSS-angle helper is used only by enabled IDs 9–13. IDs 14–17
select an independent analytical compensated metric-warp source map, then use
the same canonical coordinate, sampler, Portal/touch composition and clock.

**Tech Stack:** Flutter/Dart, runtime fragment shader ABI v3,
`package:flutter_test`, GitHub Actions human `lib/main.dart` profile APK.

## Global Constraints

- Do not change Full Field velocity/backtrace code, defaults or IDs 0–13.
- Never modify `MILESTONE_COMMITS.md` in this task.
- Keep canonical 2/3-stop sampling, Cool P/W semantics and static 112° field.
- Keep one Header controller/ticker/FragmentProgram owner and no hot-path IO.
- All Flutter verification runs inside Ubuntu proot; APK builds run in GitHub Actions.

### Task 1: Freeze the additive contracts

**Files:**
- Create: `test/features/dashboard/presentation/dashboard_header_full_field_orientation_test.dart`
- Create: `test/features/dashboard/presentation/dashboard_header_space_fabric_warp_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_tuner_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_visual_engine_test.dart`

- [ ] Write tests for fixed-112 OFF parity, dynamic coordinate fixtures, v3 slots
  36–39, flow source-UV independence, family metadata/IDs, slider/switch UI,
  metric shader lane, strength-zero parity and Jacobian contracts.
- [ ] Run the two new suites in Ubuntu and confirm they fail because the
  additive types/functions/effects do not exist.
- [ ] Commit: `test(header): freeze palette orientation and metric warp contracts`.

### Task 2: Implement family-level orientation drift

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `shaders/dashboard_header_field.frag`

- [ ] Add `DashboardHeaderPaletteOrientationTuning`, controller intent methods
  and a real `Switch`, keeping it outside effect-local control lists.
- [ ] Pack only slots 36–39 after existing effect control packing. Encode
  integral base/phase degrees in slot 37, with explicit decode tests.
- [ ] Add `canonicalGradientCoordinateAtAngle`, retain the current literal
  112° helper for OFF parity, and apply the oscillatory angle only after
  `fullFieldInverseFlowMap`.
- [ ] Route Portal material coordinate projection through the same active
  palette basis for an enabled Full Field effect; leave classic/static fixed.
- [ ] Run orientation and affected existing tests; commit
  `feat(header): add full-field palette orientation drift`.

### Task 3: Implement Space Fabric metric source maps

**Files:**
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- Modify: `shaders/dashboard_header_field.frag`

- [ ] Add the `spaceFabricWarp` family and catalog entries IDs 14–17 with the
  specified controls/defaults.
- [ ] Add the isolated analytical compensated potential/gradient core,
  soft-boundary source mapping, relief-after-sampling and four parameter
  variants. No call to `fullFieldInverseFlowMap` from this lane.
- [ ] Make Portal compose over metric source UV and retain touch-before-source
  order.
- [ ] Add configuration-only diagnostics and manual/test probe data.
- [ ] Run Space Fabric and regressions; commit
  `feat(header): add space-fabric distortion family`.

### Task 4: Refactor and verify delivery

**Files:**
- Verify only: protected dashboard sources and `MILESTONE_COMMITS.md`

- [ ] Remove temporary duplication, preserve the literal fixed path and
  re-run all focused suites, protected fast suite, analyzer and shader loading.
- [ ] Inspect the CenteredCarousel behavioral diff is empty, ensure milestones
  are untouched, push the three commits and require exact remote match.
- [ ] Monitor required Actions, download only the normal human profile APK to
  `/storage/emulated/0/Download/fluvi`, and calculate SHA-256.
