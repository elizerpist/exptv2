# Dashboard Interaction Performance Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use executing-plans to implement
> this plan task-by-task. This task is explicitly single-agent inline; do not
> dispatch subagents.

**Goal:** Make child rail and SummaryPill motion independent of repository
reads, native watch churn, bundle projection, broad rebuilds and data density,
while preserving the current parent-child state machine and native Flutter
motion.

**Architecture:** Keep `DashboardPresentationStore` as the sole visible truth,
migrate all reusable parent+child data into one canonical bundle registry, and
route all refresh/prewarm work through one interaction-aware coordinator. A
stable core-revision subscription replaces exact-child watch ownership.

**Tech Stack:** Flutter/Dart, `ChangeNotifier`/immutable snapshots, Kotlin
coroutines, Room, Method/EventChannel, `flutter_test`, Kotlin/JUnit,
`FrameTiming`, `TimelineTask`.

## Global constraints

- Start from and preserve `40f8431` behavior.
- Single agent, inline execution; no subagents.
- No golden tests.
- No rail/SummaryPill physics tuning, manual fling, debounce or settle-only UI.
- Local Flutter test/analyze commands run through Ubuntu proot.
- APK/profile artifacts are built online with GitHub Actions.
- Every production edit follows RED -> GREEN -> REFACTOR.

---

### Task 1: Freeze baseline and add truthful diagnostics

**Files:**
- Modify: `lib/features/dashboard/query/application/dashboard_query_debug.dart`
- Create: `lib/features/dashboard/application/dashboard_performance_counters.dart`
- Test: `test/features/dashboard/application/dashboard_performance_counters_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_amount_execution_test.dart`

**Produces:** bounded numeric counters for bundle lookups, reads, subscriptions,
jobs, rebuilds, projections and actual amount animation starts.

- [ ] Write tests proving counters are allocation-bounded/resettable and amount
  diagnostics describe the executed branch rather than policy intent.
- [ ] Run the tests and observe the expected missing-counter/execution failure.
- [ ] Implement the smallest counter owner and wire actual amount execution.
- [ ] Run focused tests and the frozen amount/preview suite.
- [ ] Commit the diagnostics slice.

### Task 2: Enforce architecture boundaries

**Files:**
- Create: `test/boundary/dashboard_interaction_performance_boundary_test.dart`

**Produces:** fail-closed source contracts preventing concrete repository work
in widgets, query-key viewport keys, a second bundle cache and duplicate motion
engines.

- [ ] Write boundary assertions against the desired owners and forbidden paths.
- [ ] Run and observe failures caused by current split cache/live ownership.
- [ ] Keep the RED suite as the migration guard; satisfy each assertion only in
  the owning implementation task.

### Task 3: Introduce the canonical parent bundle registry

**Files:**
- Create: `lib/features/dashboard/application/dashboard_parent_bundle_registry.dart`
- Modify: `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
- Modify: `lib/features/dashboard/query/application/dashboard_presentation_store.dart`
- Test: `test/features/dashboard/application/dashboard_parent_bundle_registry_test.dart`
- Test: `test/features/dashboard/application/dashboard_summary_amount_controller_test.dart`

**Interfaces:**
- Produces `DashboardParentBundleKey`, `DashboardParentBundleEntry`,
  `DashboardParentBundleRegistry.lookup/put/pinCurrent/markStale`.

- [x] Write RED tests for atomic complete insertion, same-revision reuse,
  explicit-zero hits, pinning, byte-bounded eviction and miss reasons.
- [x] Run focused tests and confirm current split cache cannot satisfy reuse.
- [x] Implement registry models and bounded policy.
- [x] Migrate summary metrics reads/writes to the registry without changing
  visible publication behavior.
- [x] Remove obsolete child-bundle ownership only after all registry tests pass.
- [x] Run open-rail, startup, direction and stress regressions.
- [x] Commit the canonical registry slice.

### Task 4: Make cached navigation and fresh settle side-effect free

**Files:**
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/query/application/current_query_controller.dart`
- Modify: `lib/features/dashboard/query/application/dashboard_live_query_lease_coordinator.dart`
- Test: `test/features/dashboard/application/dashboard_parent_navigation_performance_test.dart`
- Test: `test/features/dashboard/application/dashboard_live_preview_regression_test.dart`
- Test: `test/features/dashboard/query/current_query_controller_test.dart`

**Produces:** semantic commit separate from background freshness ownership.

- [ ] Add RED tests proving fresh child settle, rail open/close and cached
  parent navigation perform zero repository read and zero watch restart.
- [ ] Verify existing code fails specifically through lease activation.
- [ ] Add a committed-scope update path that promotes the registry snapshot
  without activating exact-scope I/O when freshness is valid.
- [ ] Preserve cold/stale refresh behavior behind the background coordinator
  contract introduced next.
- [ ] Run pending-cancellation, active-result and open-rail regression suites.
- [ ] Commit the side-effect-free interaction slice.

### Task 5: Replace per-child watch ownership with stable invalidation

**Files:**
- Modify: `lib/features/dashboard/query/data/dashboard_ledger_repository.dart`
- Modify: `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`
- Modify: `lib/features/dashboard/query/application/current_query_controller.dart`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`
- Test: `test/features/dashboard/query/current_query_controller_test.dart`
- Test: `android/app/src/test/kotlin/com/fluvi/app/MainActivityDashboardQueryArgumentsTest.kt`

**Produces:** one stable core-revision stream whose identity is independent of
child selection.

- [ ] Add RED tests showing ten/one-hundred child settles must keep one native
  subscription and schedule no exact-scope initial reads.
- [ ] Expose core-revision observation through the repository contract.
- [ ] Subscribe once, mark affected registry entries stale, and stop using child
  QueryKey as native observer ownership.
- [ ] Keep exact reads available only as coordinator-owned refresh jobs.
- [ ] Run Dart and Kotlin watch/result isolation tests.
- [ ] Commit the stable invalidation slice.

### Task 6: Centralize background work

**Files:**
- Create: `lib/features/dashboard/application/dashboard_background_work_coordinator.dart`
- Modify: `lib/features/dashboard/application/dashboard_adjacent_parent_prewarm_coordinator.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/application/dashboard_background_work_coordinator_test.dart`
- Test: `test/features/dashboard/application/dashboard_adjacent_parent_prewarm_coordinator_test.dart`

**Produces:** keyed one-at-a-time priority queue with interaction epochs,
cancellation and latest-wins result validation.

- [ ] Write RED tests for interaction gating, duplicate coalescing, priority,
  cancellation and stale completion rejection.
- [ ] Implement pure coordinator state and injected job runner/clock/scheduler.
- [ ] Route stale refresh and adjacent prewarm through it.
- [ ] Retire `Timer.zero` starts and prevent background presentation publishes.
- [ ] Run rapid-fling and latest-wins navigation regressions.
- [ ] Commit the coordinator slice.

### Task 7: Isolate dashboard rebuilds and animations

**Files:**
- Modify: `lib/core/motion/dashboard_motion_host.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
- Modify: direction-toggle/pulse widget located by repository search
- Modify: `lib/shared/motion/centered_carousel/centered_carousel.dart`
- Modify: `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
- Test: `test/features/dashboard/presentation/dashboard_rebuild_isolation_test.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_controller_test.dart`
- Test: `test/shared/motion/centered_carousel/centered_carousel_widget_test.dart`

- [ ] Add instrumented RED widget tests: pulse/amount/query tick must not build
  root, rail, SummaryPill or LogBox; unchanged carousel config must not notify.
- [ ] Replace aggregate listening with narrow structural listenables/selectors.
- [ ] Move pulse and amount animation builders to leaf subtrees and add only
  measurement-justified repaint isolation.
- [ ] Make carousel configuration equality a no-op and retain stable physics.
- [ ] Run identity/physics and interaction suites.
- [ ] Commit the rebuild-isolation slice.

### Task 8: Move LogBox projection out of preview

**Files:**
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_view_models.dart`
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_presentation_adapter.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: canonical bundle builder/registry entry files
- Test: `test/features/dashboard/logbox/dashboard_log_view_model_projector_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

- [ ] Add RED tests proving preview selection performs no group/sort/format and
  reuses one immutable viewport state for equal semantic content.
- [ ] Project bounded viewport models during bundle construction.
- [ ] Make adapter selection O(1); preserve stable lazy viewport and controller.
- [ ] Keep paging committed-only with one request per cursor.
- [ ] Run 0/94/1000-entry row-build and identity tests.
- [ ] Commit the LogBox slice.

### Task 9: Make native bundle construction aggregate and off-main

**Files:**
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/dao/FluviCoreDaos.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/dao/FluviQueryRows.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Test: native DAO/read-service tests located under `android/fluvi-core/src/test`

- [ ] Add RED 5k/20k/100k tests asserting aggregate counts/totals, explicit
  zero buckets, bounded preview rows and cancellation.
- [ ] Add SQL aggregate/bounded-row queries compatible with supported Android
  SQLite versions.
- [ ] Move mapping/serialization to IO/Default dispatcher and hand only the
  completed payload to Main.
- [ ] Add query/mapping/serialization timing spans and request generation.
- [ ] Run native unit tests and Dart method-channel contract tests.
- [ ] Commit the native scalability slice.

### Task 10: Add and run the profile harness

**Files:**
- Create/modify a project-native integration/performance harness under
  `integration_test/` or the existing benchmark location discovered by search.
- Modify: GitHub Actions workflow for profile artifact only if no existing
  profile workflow can be reused.

- [ ] Record `FrameTiming`, timeline spans, rebuilds, reads, subscriptions,
  projections, cache hits, memory and GC for every approved scenario.
- [ ] Build the profile APK online and run the same scripted gestures on one
  physical device with verbose FLOW logging disabled.
- [ ] Compare `40f8431`, `3dd650c` and the feature branch.
- [ ] Record honest p50/p90/p95/p99 results and density delta in the checklist.
- [ ] Commit the harness/results metadata without committing large raw traces.

### Task 11: Final verification and delivery

**Files:**
- Update: `docs/superpowers/checklists/2026-08-04-dashboard-interaction-performance-isolation.md`

- [ ] Run focused and full non-golden Flutter tests in Ubuntu proot.
- [ ] Run Dart MCP/static analysis and Kotlin tests.
- [ ] Prove no golden additions with repository search.
- [ ] Re-read every acceptance row and mark only evidenced rows DONE.
- [ ] Run milestone regression comparison and inspect controller/physics diffs.
- [ ] Commit remaining documentation, push the feature branch, and use GitHub
  Actions for online build verification.
