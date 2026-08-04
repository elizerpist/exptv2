# Dashboard live preview bundle Implementation Plan

> **For agentic workers:** Execute this plan inline in the current feature branch. The work is tightly coupled through one presentation store and one rail callback path, so subagent delegation would add merge risk.

**Goal:** Prepare complete child preview snapshots before interaction and publish them immediately for every distinct rail crossing without changing rail motion behavior.

**Architecture:** Keep `CenteredCarouselController` and `DashboardTimeNavigationController` as motion/selection owners. Add a batch, immutable child-preview read model and bounded cache to the query/presentation lane; resolve exact child keys synchronously into the existing `DashboardPresentationStore`, which remains the only visible state owner.

**Tech Stack:** Dart/Flutter, Kotlin/Room query service, `package:flutter_test`, Ubuntu proot Flutter verification, GitHub Actions APK build.

## Global Constraints

- Start from baseline `561fe92`; milestone commit `c0754f4` is already recorded.
- Do not modify rail physics, ScrollController, ScrollPosition, item extent, velocity mapping, snap, haptics or gesture ownership.
- Do not add crossing-time repository/native/watch/paging I/O.
- Do not add trailing debounce, settle-only preview or a second gesture engine.
- Do not change amount/count calculation semantics or LogBox visual design.
- No golden tests and no local APK build.

---

### Task 1: Audit and RED regressions

**Files:**
- Create: `docs/dashboard/rail-live-preview-root-cause.md`
- Create: `test/features/dashboard/application/dashboard_live_preview_regression_test.dart`
- Modify: `test/boundary/summary_metrics_boundary_test.dart` only if the new shared boundary needs an explicit assertion.

**Interfaces:**
- Consumes the existing `DashboardSummaryMetricsController`, `DashboardPresentationStore`, `DashboardTimeNavigationController` and test repositories.
- Produces failing behavioral tests that require complete child rows during first open and intermediate preview.

- [ ] Step 1: Document the trace from carousel `_handleScroll` to `_emitPreview`, rail `_queuePreview`, navigation preview, summary `_publishToPresentationStore`, store activation and LogBox adapter projection. State that D11 is emitted by `DashboardLogBoxHeader`, while the current snapshot is metric-only because the summary controller copies `existing?.entries` and no child detailed snapshot exists.
- [ ] Step 2: Add a parent fixture whose page contains rows from multiple child days, complete the existing child summary index, then assert the child preview snapshot contains the matching row rather than an empty list.
- [ ] Step 3: Add a sequence fixture for child keys 2, 3, 4, 5 with populated and empty rows and assert the store’s visible key, amount, count and row IDs after each preview notification before settle.
- [ ] Step 4: Add an assertion that the current implementation fails for the expected reason: child metrics are available, but the child snapshot has no detailed entries and the visible LogBox list cannot show the crossed child.
- [ ] Step 5: Run only the new test file through Ubuntu proot and capture the RED output before production edits.

Expected RED command:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && /home/flutteruser/flutter/bin/flutter test test/features/dashboard/application/dashboard_live_preview_regression_test.dart'
```

Expected result: FAIL on the child snapshot row/sequence assertions, not a Dart syntax or test-setup error.

### Task 2: Add the immutable batch preview read model

**Files:**
- Create: `lib/features/dashboard/query/data/dashboard_child_preview_bundle.dart`
- Create: `lib/features/dashboard/query/data/dashboard_child_preview_repository.dart`
- Modify: `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`
- Test: `test/features/dashboard/query/dashboard_child_preview_bundle_test.dart`

**Interfaces:**
- `DashboardChildPreviewBundleRequest(parentScope, childPeriod, previewPageSize)`.
- `DashboardChildPreviewBundle(parentQueryKey, direction, childPeriod, coreRevision, previewPageSize, childrenByQueryKey)`.
- `DashboardChildPreviewRepository.readChildPreviewBundle(request)`.

- [ ] Step 1: Write tests for immutable maps/lists, exact child keys, explicit empty snapshots, and rejection of wrong parent/direction/revision.
- [ ] Step 2: Run the focused tests and observe the expected missing-model RED failure.
- [ ] Step 3: Implement data-only immutable models using existing `DashboardLedgerResult` and `DashboardLedgerEntry`; do not add Widgets, BuildContext, controllers or rendering state.
- [ ] Step 4: Extend the MethodChannel decoder with a single `readDashboardChildPreviewBundle` call and validate every child result’s key, direction and revision.
- [ ] Step 5: Run the model and MethodChannel tests; expected result is PASS.

### Task 3: Implement native batch projection

**Files:**
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviQueryModels.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Test: `android/fluvi-core/src/test/kotlin/com/fluvi/core/query/FluviDashboardObservationTest.kt` or a focused new query test.

**Interfaces:**
- `FluviLedgerReadService.childPreviewBundle(scope, childPeriodKind, previewPageSize)` returns one immutable native batch model containing child slices.
- MainActivity serializes the same row fields and cursor fields already used by `readDashboard`.

- [ ] Step 1: Add a native test fixture asserting MONTH groups rows by day, YEAR by month, caps each child to `previewPageSize`, preserves `nextCursor`, and adds explicit zero buckets for finite month/year domains.
- [ ] Step 2: Run the focused native test and observe RED for the missing bundle method.
- [ ] Step 3: Implement one parent-predicate SQL row read, O(1) category/partner maps, deterministic descending row order, child aggregate totals/counts, and bounded first-page slices. Do not issue one query per child.
- [ ] Step 4: Add SUM bounded-window handling using the existing year-child domain and never materialize hidden widgets.
- [ ] Step 5: Serialize/deserialize the bundle and run the focused native/Flutter repository tests.

### Task 4: Prepare and cache bundles before interaction

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Modify: `lib/features/dashboard/query/data/dashboard_child_summary_repository.dart`
- Test: `test/features/dashboard/application/dashboard_summary_amount_controller_test.dart`

**Interfaces:**
- Summary controller accepts optional `DashboardChildPreviewRepository` alongside the existing aggregate summary repository.
- Bundle preparation is keyed by exact parent query key, child period, preview page size and core revision; it has a bounded LRU of three parent bundles per direction/filter combination.

- [ ] Step 1: Add a failing test that a fresh parent result schedules one bundle prewarm and the bundle’s child snapshots exist before `setRailOpen(true)`.
- [ ] Step 2: Run the focused test and observe RED because the baseline only requests `readChildSummaries`.
- [ ] Step 3: Implement latest-wins, generation/revision/direction guards and store the bundle without activating visible state.
- [ ] Step 4: Convert each bundle child result into a complete `DashboardPresentationSnapshot` with rows and cursor and retain the existing metrics index for compatibility.
- [ ] Step 5: Verify cold first open has cache-hit counters and zero read/watch/native deltas before visible child publish.

### Task 5: Unify immediate preview publication

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Modify: `lib/features/dashboard/query/application/dashboard_presentation_store.dart`
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_presentation_adapter.dart` only if required to preserve preprojected list identity.
- Test: `test/features/dashboard/application/dashboard_live_preview_regression_test.dart`

**Interfaces:**
- Add one controller method, `publishChildPreview(CurrentLedgerQueryScope scope)`, used by preview navigation and existing tap path.
- The method performs only exact-key bundle lookup and one `DashboardPresentationStore.publish` of a complete snapshot.

- [ ] Step 1: Add tests for full atomic amount/count/rows, empty child state, and old-row exclusion.
- [ ] Step 2: Run the tests and observe RED because current `_publishToPresentationStore` only reuses `existing?.entries`.
- [ ] Step 3: Route all preview notifications through the shared method; remove any preview suppression/debounce found in the audit, without touching carousel physics.
- [ ] Step 4: Ensure a same-frame multiple-crossing coalescing policy keeps only the last child for that frame, while separate frames each publish.
- [ ] Step 5: Add numeric counters for semantic crossings, bundle hits/misses, visible preview publishes, log binds and I/O attempts; verify no I/O in crossing callbacks.

### Task 6: Make settle promotion visual no-op and prove identity

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Modify: `lib/features/dashboard/query/application/dashboard_presentation_store.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Test: `test/features/dashboard/application/dashboard_core_controller_test.dart`
- Test: `test/boundary/centered_carousel_boundary_test.dart` if a stronger frozen-physics assertion is needed.

**Interfaces:**
- `DashboardPresentationStore.promote` remains the only committed-promotion API.
- Counters expose `settleVisualRebindCount`, `railControllerRecreationCount`, `railPositionRecreationCount` and `railPhysicsRecreationCount` without changing runtime ownership.

- [ ] Step 1: Add no-settle and settle-no-op tests that stop before the settle callback and then promote an identical snapshot.
- [ ] Step 2: Run RED tests against the current metric-only path.
- [ ] Step 3: Make full preview → committed promotion compare content digest/entries and update metadata without rebinding visual state.
- [ ] Step 4: Assert stable viewport State, ScrollController, ScrollPosition and physics identity across 100 crossings.
- [ ] Step 5: Run focused widget/application/boundary tests.

### Task 7: Full verification, documentation and delivery

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-04-dashboard-live-preview-bundle.md`
- Modify: `docs/dashboard/rail-live-preview-root-cause.md`
- Modify: final implementation files only as needed for verified defects.

- [x] Step 1: Format changed Dart files and run all focused tests.
- [x] Step 2: Run the full non-golden Flutter suite in Ubuntu proot and `flutter analyze --no-fatal-infos`.
- [x] Step 3: Check the logger-off profile benchmark path; report real p50/p90/p99 values or mark physical profiling unavailable.
- [x] Step 4: Re-read the checklist and mark every item honestly; any partial requirement remains explicitly partial.
- [ ] Step 5: Create one final feature commit; do not build locally.
- [ ] Step 6: Push the feature branch once, wait for GitHub Actions, and download the successful APK to `/storage/emulated/0/Download/fluvi_<shortsha>.apk`.
