# Deferred committed-page presentation readiness implementation plan

> **For agentic workers:** Execute inline in this session. The user explicitly prohibits subagents.

**Goal:** Prevent a current exact virtual page from remaining blank through ballistic scroll when its repository response was already admitted and decoded before raw pointer contact.

**Architecture:** Extend the one existing `ExplicitCommittedPagingController` with a presentation-only deferred-page opportunity. It must use `CommittedLogViewportCache.prepareAndCommit` and its existing cooperative yields, while the normal cursor drain retains the stricter acquisition gate. The viewport/cache diagnostic change reports the immutable virtual world separately from the contiguous resource-ready frontier; it does not change geometry or scheduling.

**Tech Stack:** Flutter/Dart, existing keyset repository, `ChangeNotifier`, Flutter scroll notifications, existing cooperative `TextPainter` preparation.

## Global constraints

- Preserve `026f027` publication reservation/binding and `99ebb88` same-target hotset promotion.
- Do not alter physics, controller/position identity, page size, cache capacity, virtual extent, or renderer fail-closed behavior.
- Never start a new repository page read during raw pointer, drag, or ballistic interaction.
- Do not use timers, post-frame delays, polling, a new cache, or a second paging scheduler.
- Commit only the correctness change first, then diagnostics-only behavior in a second commit.

### Task 1: Reproduce and isolate deferred presentation

**Files:**
- Modify: `test/features/dashboard/runtime/explicit_committed_paging_controller_test.dart`
- Modify: `test/features/dashboard/application/dashboard_core_query_application_test.dart` only if a lifecycle integration assertion needs it

- [x] Add a 67-row/three-page controllable test: admit ordinal 1, enter pointer plus formal interaction, complete page 1, assert one request and deferred data, release only raw pointer, then expect ordinal 1 drawable while interaction remains active and ordinal 2 still unread.
- [x] Run the focused runtime test on `99ebb88`; it failed at RED because `resumeDeferredPagePresentation` did not exist.
- [x] Add motion-gate, new-pointer cooperative-preemption and structural-supersede regressions; re-run the existing terminal/zero-move, Query-sheet and protected Query scheduler coverage.

### Task 2: Commit 1 — presentation-only deferred resume

**Files:**
- Modify: `lib/features/dashboard/runtime/application/explicit_committed_paging_controller.dart`
- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Test: `test/features/dashboard/runtime/explicit_committed_paging_controller_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_stable_render_surface_test.dart`

- [x] Split the existing private gate into strict acquisition permission and narrower exact-deferred presentation permission.
- [x] Add one public presentation-only resume method that can commit exactly `_deferredPage`, never enters the cursor/read loop, and logs one low-volume resume event.
- [x] Wire raw pointer end and structural-motion idle to invoke only that method while a formal interaction remains active.
- [x] Keep `canPublish` identity checks on every cache preparation slice; a new pointer leaves data deferred and no partial page drawable.
- [x] GREEN focused tests, refactor names/comments, run geometry/identity/painter regressions, then commit `fix: resume deferred committed page before virtual exposure`.

### Task 3: Commit 2 — truthful resource-readiness diagnostics

**Files:**
- Modify: `lib/features/dashboard/logbox/application/committed_log_viewport_cache.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart`
- Test: `test/features/dashboard/logbox/application/committed_log_viewport_cache_test.dart`
- Test: `test/features/dashboard/presentation/dashboard_logbox_viewport_test.dart`

- [ ] Add RED tests for `readyDrawableExtent`, ready-ahead pixels, currently missing visible ordinals, and truthful logical/resource window diagnostics.
- [ ] Derive all frontier values from the immutable manifest plus `highestReadyPageOrdinal`; retain miss event deduplication.
- [ ] Add bounded visible-range current-state fields to interaction and cache summaries; do not invoke scheduling, modify cache retention, or emit per-frame logs.
- [ ] GREEN focused diagnostics tests, prove the paging scheduler has no behavior change, then commit `chore: report drawable committed ready-ahead accurately`.

### Task 4: Final verification and delivery

- [ ] Run the required runtime, viewport, stable-renderer, Query, scene-window, cache/geometry, partner-swipe, fast, boundary, and analyzer checks in Ubuntu proot.
- [ ] Re-read the acceptance checklist and mark only evidence-backed items DONE.
- [ ] Push each production commit, monitor the exact-SHA human diagnostic APK workflow, download it to `/storage/emulated/0/Download/fluvi`, and record SHA-256.
- [ ] Report the late boundary telemetry and retained-key diagnostic only; do not include either in these commits.
