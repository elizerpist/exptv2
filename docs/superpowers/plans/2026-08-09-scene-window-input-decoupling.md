# Scene-window input decoupling implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the data-density-dependent dashboard input cooldown without
changing 2025 data, rail physics or vertical stale-session safety.

**Architecture:** `DashboardCoreController` commits rail metadata immediately
and issues only a generation-tagged maintenance request. The prepared-scene
cache retains sole UI-isolate paragraph ownership and executes bounded,
latest-wins work without publishing an interaction gate. Existing hot preview
references serve new vertical input while the cache rotates in the background.

**Tech stack:** Flutter/Dart, `flutter_test`, existing dashboard diagnostics,
Ubuntu/proot Flutter checks, GitHub Actions HUMAN_DIAGNOSTIC profile APK.

## Global constraints

- Base: `e575e6e`; preserve the milestone tag and 2025 generator output.
- Do not modify `CenteredCarousel`, `CenteredCarouselController`,
  `CenterSnapScrollPhysics`, `TimeRefinementRail`, or `DashboardMotionKernel`.
- No golden tests, local APK build, delays/debounces/cooldowns or input gate.

---

### Task 1: Replace the gated lifecycle contract with observable input-first behaviour

**Files:**
- Modify: `test/features/dashboard/application/dashboard_scene_window_rotation_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Modify: `lib/core/diagnostics/fluvi_diagnostic_event.dart`

**Interfaces:** Tests consume the existing scene coordinator and vertical
session callbacks. They produce required ordering assertions: settled metadata
and next-pointer input precede background completion.

- [ ] Write failing tests that hold a scene preparation completer, settle a
  dense target, then assert metadata is committed, `sceneWindowPreparing` is
  not an input gate, a next-frame vertical drag starts exactly one new session,
  and a second rail fling begins before the completer resolves.
- [ ] Add diagnostic fields for preparation generation, elapsed time, pointer
  timestamps, task source and genuine-input rejection count; run the focused
  tests in Ubuntu/proot and observe their expected gated-lifecycle failure.

### Task 2: Decouple navigation metadata and background scene maintenance

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Test: `test/features/dashboard/application/dashboard_scene_window_rotation_test.dart`

**Interfaces:** `DashboardCoreController` preserves `prepare`/`activate` cache
capabilities but publishes `DashboardNavigationState` before invoking
maintenance. `FluviAppShell` consumes only startup readiness for interaction
absorption.

- [ ] Make the new failing metadata/input-order tests red.
- [ ] Replace `_sceneNavigationGated` uses with no-op cache maintenance
  scheduling; commit parent/plane/direction/rail metadata synchronously.
- [ ] Remove `sceneWindowPreparing` from the `AbsorbPointer` condition while
  retaining `!_readiness.isInteractive`.
- [ ] Run focused controller and viewport tests until green.

### Task 3: Make prepared-scene maintenance bounded, reusable and latest-wins

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart`
- Modify: `lib/features/dashboard/presentation/core_dashboard.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_prepared_scene_cache_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_scene_cache_scale_gate_test.dart`

**Interfaces:** The cache accepts a maintenance generation/cancellation check,
keeps immutable matching rows/scenes, and returns a report containing new,
reused, yielded and stale counts. It never activates a stale window.

- [ ] Write failing A→B→A and January→December→…→February cache tests that
  require reused layouts, stale work cancellation and activation of only the
  latest window.
- [ ] Change preparation to bounded batches with an event-loop opportunity
  between batches; check current generation before every batch and preserve
  already reusable immutable entries.
- [ ] Record each contiguous prepare slice, layout/reuse/new counts and
  notifier activity; run cache scale tests and enforce no hot-path layout.

### Task 4: Prove motion and session parity on dense data

**Files:**
- Modify: `test/features/dashboard/presentation/dashboard_rail_density_trace_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Modify: `integration_test/dashboard_interaction_profile_test.dart`

**Interfaces:** Existing rail flight recorder emits pointer-up, ballistic start
and end. Tests compare light and dense fixtures and assert controller/position
identity, target velocity and final delta parity.

- [ ] Write failing tests for 100 immediate post-settle horizontal flings,
  immediate dense vertical drag and a vertical→horizontal→vertical sequence.
- [ ] Run tests red with the baseline gate/await design.
- [ ] Implement only the instrumentation and cache/controller wiring required
  to satisfy those tests; do not touch frozen physics files.
- [ ] Run focused tests and capture report counters with all three critical
  cache/vertical diagnostics at zero.

### Task 5: Verify, document and deliver

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-09-scene-window-input-decoupling.md`
- Modify: `docs/dashboard/dashboard-rail-presentation-isolation-root-cause.md`

- [ ] Re-read the checklist and frozen-file hashes, then run `flutter analyze`
  and the full non-golden suite inside Ubuntu/proot.
- [ ] Run native/core verification in CI; fix the profile expectation so it
  accepts the unchanged 4,304-entry seeded dataset rather than the historical
  700-entry count.
- [ ] Commit tracked source/tests/docs, push the new branch, wait for successful
  Actions, download the normal HUMAN_DIAGNOSTIC APK to
  `/storage/emulated/0/Download/fluvi`, compare SHA-256 and run ZIP integrity.
- [ ] Update each checklist row with observed evidence and report PASS only if
  every row is DONE.
