# Budget V2 Final Review Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve every finding in `.superpowers/sdd/task-9-brief.md` without changing Budget V2 visuals, permitted legacy diagnostic behavior, or delivery state.

**Architecture:** The standalone B2 route will be diagnostic-silent except for bounded terminal `BudgetV2InteractionDiagnostics`; the shared legacy carousel keeps its permitted traces through an explicit presentation policy. `BudgetV2LogProjectionCache` will cache one immutable ordered logical result per structural source/filter identity and materialize uncached prefix windows. `TransactionStore` will use immutable structural filter keys, plus a typed filter-and-limit key for legacy Balance paging. Prepared-snapshot revision is an explicit mother-card ticker invalidation input, and cancellation is an explicit selection-controller transition.

**Tech Stack:** Flutter/Dart, `flutter_test`, Ubuntu/proot Flutter SDK.

## Global Constraints

- TDD: every production change follows a witnessed focused RED.
- Preserve ghosts, canonical date headers, exact merchant keys, 96-row cumulative paging, and all approved UI geometry.
- Preserve legacy diagnostics outside the standalone B2 route.
- No push, APK build, artifact download, or other remote mutation.

---

### Task 1: Standalone terminal-only diagnostics

**Files:**
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`
- Modify: `lib/features/transactions/widgets/experimental/budget_v2/spendee_budget_v2_dashboard.dart`

**Interfaces:**
- Consumes: `BudgetV2DiagnosticsScope.allowsLegacyChart(BuildContext)`.
- Produces: an explicit carousel trace policy; standalone B2 emits only final `[BudgetV2Interaction]` records while permitted legacy consumers retain their existing traces.

- [x] Add a real standalone-route assertion that every `[BudgetV2...]` entry is a terminal interaction record and no raw avatar/category/error interpolation is emitted, while retaining the existing legacy trace contracts.
- [x] Run the focused real-route test and verify failure on raw start/settle/schedule/commit entries.
- [x] Pass the diagnostics-scope policy into the shared carousel and remove standalone dashboard lifecycle writes.
- [x] Re-run the focused real-route and legacy contracts.

### Task 2: One logical projection per B2 query

**Files:**
- Modify: `test/spendeetest/budget_v2_query_controller_test.dart`
- Modify: `lib/features/transactions/models/transaction_log_projection.dart`
- Modify: `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_log_projection.dart`

**Interfaces:**
- Consumes: `projectTransactionLogEntries` ordering and canonical header rules.
- Produces: a row-limit-free structural cache key, one immutable ordered logical row list, cheap prefix materialization, and diagnostics for source scans, full projections, materializations, cached queries, and retained logical rows.

- [x] Add a 4,096-row deep 96-row paging regression that asserts one source scan/projection and constant retained cache size across many limits.
- [x] Run the focused unit test and verify the current row-limit-keyed cache fails.
- [x] Add a shared ordered-prefix materializer and refactor the B2 cache to retain no materialized windows.
- [x] Re-run query, ghost, and real production paging contracts.

### Task 3: Collision-free store filter cache identity

**Files:**
- Modify: `test/transactions/transaction_store_test.dart`
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`

**Interfaces:**
- Consumes: normalized transaction type/window/period/search/category/merchant filter semantics.
- Produces: immutable `_TransactionFilterCacheKey` and `_BalanceDisplayLogCacheKey` values used by every relevant store cache and LRU.

- [x] Add sequential `{'ACME,Shop'}` then `{'ACME','Shop'}` store and real-B2 regressions that assert summary, chips, and log remain aligned.
- [x] Run the focused tests and verify stale cached summary/log values reproduce.
- [x] Replace delimiter-joined filter and filter-plus-limit strings with structural keys without rewriting unrelated window caches.
- [x] Re-run store, B2 route, cache-bound, and exact-key contracts.

### Task 4: Same-store ticker revision invalidation

**Files:**
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`
- Modify: `lib/features/transactions/widgets/experimental/budget_v2/spendee_budget_v2_dashboard.dart`

**Interfaces:**
- Consumes: `BudgetV2PreparedSnapshot.sourceRevision` and exact immutable vendor entries.
- Produces: a structural ticker-revision input that cancels/rebases in-flight vendor motion before a stale target callback can publish.

- [x] Add a real same-store rename/delete/data-revision regression during multi-step vendor ticking.
- [x] Run the focused route test and verify the stale vendor publishes or controlled state diverges.
- [x] Thread structural source/vendor revision through mother-card lifecycle cancellation.
- [x] Re-run replacement-store, external-scope, exact-vendor, and same-store ticker contracts.

### Task 5: Lifecycle and legacy projection cost

**Files:**
- Modify: `test/spendeetest/budget_v2_selection_controller_core_test.dart`
- Modify: `test/transactions/transaction_store_test.dart`
- Modify: `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_selection_controller.dart`
- Modify: `lib/features/transactions/widgets/experimental/budget_v2/spendee_budget_v2_dashboard.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`

- [x] Add controller RED tests proving no-drag/cancelled pointers return to committed state and stale generations cannot publish.
- [x] Add legacy display-log evidence proving the canonical ordered rows are not fully sorted a second time.
- [x] Implement the explicit cancellation transition, wire it into the dashboard, and reuse the already ordered legacy rows.
- [x] Re-run selection lifecycle and legacy log suites.

### Task 6: Integrated verification and handoff

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-30-budget-v2-clean-room-performance.md`
- Create: `.superpowers/sdd/task-9-report.md`

- [x] Run the exact Task 7 suite and the broader affected matrix inside Ubuntu/proot.
- [x] Run full `flutter analyze`, `git diff --check`, source inspections, and re-read every remediation acceptance row.
- [x] Reinspect `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`.
- [x] Record fresh RED/GREEN/final evidence in the Task 9 report and mark only proven checklist rows `DONE`.
- [x] Commit as `fix(budget-v2): close clean-room review findings` (`801e8b9`);
  verify clean status; do not push as part of the remediation task.
