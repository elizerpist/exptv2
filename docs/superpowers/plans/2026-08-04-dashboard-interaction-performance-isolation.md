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

- [x] Write tests proving counters are allocation-bounded/resettable and amount
  diagnostics describe the executed branch rather than policy intent.
- [x] Run the tests and observe the expected missing-counter/execution failure.
- [x] Implement the smallest counter owner and wire actual amount execution.
- [x] Run focused tests and the frozen amount/preview suite.
- [x] Preserve the completed diagnostics slice for the recovery commit.

### Task 2: Enforce architecture boundaries

**Files:**
- Create: `test/boundary/dashboard_interaction_performance_boundary_test.dart`

**Produces:** fail-closed source contracts preventing concrete repository work
in widgets, query-key viewport keys, a second bundle cache and duplicate motion
engines.

- [x] Write boundary assertions against the desired owners and forbidden paths.
- [x] Run and observe failures caused by current split cache/live ownership.
- [x] Keep the RED suite as the migration guard; satisfy each assertion only in
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

- [x] Add RED tests proving fresh child settle, rail open/close and cached
  parent navigation perform zero repository read and zero watch restart.
- [x] Verify existing code fails specifically through lease activation.
- [x] Add a committed-scope update path that promotes the registry snapshot
  without activating exact-scope I/O when freshness is valid.
- [x] Preserve cold/stale refresh behavior behind the background coordinator
  contract introduced next.
- [x] Run pending-cancellation, active-result and open-rail regression suites.
- [x] Preserve the completed side-effect-free slice for the recovery commit.

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

- [x] Add RED tests showing ten/one-hundred child settles must keep one native
  subscription and schedule no exact-scope initial reads.
- [x] Expose core-revision observation through the repository contract.
- [x] Subscribe once, mark affected registry entries stale, and stop using child
  QueryKey as native observer ownership.
- [x] Keep exact reads available only as coordinator-owned refresh jobs.
- [x] Run Dart watch/result isolation tests; retain Kotlin tests for CI.
- [x] Preserve the completed stable-invalidation slice for the recovery commit.

### Task 6: Centralize background work

**Files:**
- Create: `lib/features/dashboard/application/dashboard_background_work_coordinator.dart`
- Modify: `lib/features/dashboard/application/dashboard_adjacent_parent_prewarm_coordinator.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/application/dashboard_background_work_coordinator_test.dart`
- Test: `test/features/dashboard/application/dashboard_adjacent_parent_prewarm_coordinator_test.dart`

**Produces:** keyed one-at-a-time priority queue with interaction epochs,
cancellation and latest-wins result validation.

- [x] Write RED tests for interaction gating, duplicate coalescing, priority,
  cancellation and stale completion rejection.
- [x] Implement pure coordinator state and injected job runner/clock/scheduler.
- [x] Route stale refresh and adjacent prewarm through it.
- [x] Retire `Timer.zero` starts and prevent background presentation publishes.
- [x] Run rapid-fling and latest-wins navigation regressions.
- [x] Preserve the completed coordinator slice for the recovery commit.

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

- [x] Add instrumented RED widget tests: pulse/amount/query tick must not build
  root, rail, SummaryPill or LogBox; unchanged carousel config must not notify.
- [x] Replace aggregate listening with narrow structural listenables/selectors.
- [x] Move pulse and amount animation builders to leaf subtrees and add only
  measurement-justified repaint isolation.
- [x] Make carousel configuration equality a no-op and retain stable physics.
- [x] Run identity/physics and interaction suites.
- [x] Preserve the completed rebuild-isolation slice for the recovery commit.

### Task 8: Move LogBox projection out of preview

**Files:**
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_view_models.dart`
- Modify: `lib/features/dashboard/logbox/application/dashboard_log_presentation_adapter.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Modify: canonical bundle builder/registry entry files
- Test: `test/features/dashboard/logbox/dashboard_log_view_model_projector_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

- [x] Add RED tests proving preview selection performs no group/sort/format and
  reuses one immutable viewport state for equal semantic content.
- [x] Project bounded viewport models during bundle construction.
- [x] Make adapter selection O(1); preserve stable lazy viewport and controller.
- [x] Keep paging committed-only with one request per cursor.
- [x] Run 0/94/1000-entry row-build and identity tests.
- [x] Preserve the completed LogBox slice for the recovery commit.

### Task 9: Make native bundle construction aggregate and off-main

**Files:**
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/dao/FluviCoreDaos.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/database/dao/FluviQueryRows.kt`
- Modify: `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Test: native DAO/read-service tests located under `android/fluvi-core/src/test`

- [x] Add RED 5k/20k/100k tests asserting aggregate counts/totals, explicit
  zero buckets, bounded preview rows and cancellation.
- [x] Add SQL aggregate/bounded-row queries compatible with supported Android
  SQLite versions.
- [x] Move mapping/serialization to IO/Default dispatcher and hand only the
  completed payload to Main.
- [x] Add query/mapping/serialization timing spans and request generation.
- [x] Run native unit tests in x86 CI; Dart method-channel contract tests pass.
- [x] Preserve the completed native scalability slice for the recovery commit.

### Task 10: Add and run the profile harness

**Files:**
- Create/modify a project-native integration/performance harness under
  `integration_test/` or the existing benchmark location discovered by search.
- Modify: GitHub Actions workflow for profile artifact only if no existing
  profile workflow can be reused.

- [x] Record `FrameTiming`, timeline spans, rebuilds, reads, subscriptions,
  projections, cache hits, memory and GC for every approved scenario.
- [x] Build the profile APK online with verbose FLOW logging disabled.
- [ ] Run the same scripted gestures on one physical device.
- [ ] Compare `40f8431`, `3dd650c` and the feature branch.
- [ ] Record physical p50/p90/p95/p99 results and density delta in the checklist.
- [x] Add the harness/reporting metadata without committing large raw traces.

### Task 11: Final verification and delivery

**Files:**
- Update: `docs/superpowers/checklists/2026-08-04-dashboard-interaction-performance-isolation.md`

- [x] Run focused and full non-golden Flutter tests in Ubuntu proot.
- [x] Run static analysis locally and Kotlin tests in x86 CI.
- [x] Prove no golden additions with repository search.
- [x] Re-read every acceptance row and mark only evidenced rows DONE.
- [x] Run milestone regression comparison and inspect controller/physics diffs.
- [x] Commit remaining documentation, push the feature branch, and use GitHub
  Actions for online build verification.
