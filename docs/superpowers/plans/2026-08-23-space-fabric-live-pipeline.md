# Space Fabric live pipeline implementation plan

> Inline execution only: the user explicitly forbids subagents for this repair.

**Goal:** Prove the real Header ticker-to-GPU phase chain and prevent a numerically non-zero but physically imperceptible Space Fabric animation from passing regression tests.

**Architecture:** Keep `DashboardHeaderVisualController` as the unique phase owner and the retained fragment backend as the unique uniform owner. Add test-only observation to the backend, make real-ticker widget raster capture the production oracle, then calibrate only the first evidenced failed boundary.

**Global constraints:** ABI v3; no second ticker/timer/controller; no Full Field/static/Cool/P/W changes; no `MILESTONE_COMMITS.md` changes; no shader recreation; no production per-frame logging.

### Task 1: Establish live pipeline RED evidence

**Files:**

- Modify: `test/features/dashboard/presentation/dashboard_header_space_fabric_temporal_test.dart`
- Modify: `test/features/dashboard/presentation/dashboard_header_fragment_backend_test.dart`

- [ ] Add real `WidgetTester` ticker samples at 0/500/1000/3000/5000ms without `debugAdvance` or `setMotionEnabled(false)`.
- [ ] Require increasing controller phase, uniform write count/phase, stable program/shader identities, and perceptual raster metrics.
- [ ] Run the focused tests against current production source and record whether the first failure is ticker/repaint, uniform, source map, or perceptual amplitude.

### Task 2: Add the smallest permanent observation seam

**Files:**

- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`

- [ ] Add `@visibleForTesting` retained uniform-write observation without changing ABI or allocation behaviour.
- [ ] Add the bounded, one-time Space Fabric liveness diagnostic after active animation has crossed approximately two seconds.
- [ ] Run the focused RED tests and use the result to identify the primary failure class.

### Task 3: Apply only the evidence-backed fix

**Files:**

- Modify only the first failed boundary and its focused regression test.

- [ ] If ticker or uniform publication fails, repair only that publication boundary.
- [ ] If source-map/perceptual energy fails, calibrate temporal centre/shape evolution while preserving the metric kernel, Jacobian safety and one source map.
- [ ] Re-run source-map, perceptual, speed-zero, identities, Portal/touch, Full Field and static regressions.

### Task 4: Verify and deliver

- [ ] Run focused Header suites, protected suite, analyzer, shader load and profile watchdog.
- [ ] Check protected source diffs and `MILESTONE_COMMITS.md` are empty.
- [ ] Push focused test/fix commits; wait for CI; download and hash the normal `lib/main.dart` profile APK.
- [ ] Leave physical acceptance explicitly pending until user/device evidence exists.
