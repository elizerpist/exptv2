# Task 7 Report: controlled Budget V2 query, vendor, and local log integration

## Status

DONE

Task 7 is complete. No Task 7 acceptance item is partial or blocked. The
feature-level checklist still correctly leaves B2P-001 PARTIAL until a
GitHub-built APK can be visually compared and B2P-011 NOT DONE because this
task explicitly forbade build, push, and download.

## Architecture card

### Sources and boundary

- Requirement source: `.superpowers/sdd/task-7-brief.md`
- Upstream core report: `.superpowers/sdd/task-6-report.md`
- Acceptance matrix:
  `docs/superpowers/checklists/2026-07-30-budget-v2-clean-room-performance.md`
- Mandatory visual reference:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`
- Task boundary: production dashboard integration and affected compatibility
  adapters/tests only; no APK build, push, download, or remote mutation.

### State ownership

| State | Owner | Publication rule |
| --- | --- | --- |
| Physical, settled, and committed primary avatar | `BudgetV2SelectionController` | Direct frames stay local; one settled generation may commit once |
| External search/category/merchant scope and exact local vendor | `BudgetV2QueryController` | Reconciles store notifications without writing the store |
| Prepared records, ghosts, and exact vendor indexes | `BudgetV2PreparedSnapshot` | Immutable per source revision |
| B2 log rows and paging | `BudgetV2LogProjectionCache` + dashboard row limit | 96-row cumulative local windows |
| Vendor highlight | Dashboard-controlled `selectedVendorKey` | Mother card owns no persistent vendor selection |
| Vendor ticker step/page/limit-edit presentation | Mother-card widget state | Transient UI state only |
| Store acknowledgement | `SpendeeBudgetV2Dashboard` | Existing lightweight adapters; one notification per final primary intent |

### Query flow

Store scope → immutable prepared snapshot → controller reconciliation →
effective local primary/vendor scope → `BudgetV2LogProjectionCache` →
`SpendeeBalanceTransactionLog.fromEntries`.

Pending primary selection overrides stale external category/merchant filters
locally while preserving normalized search. The previous vendor is cleared at
primary settle. A newer local vendor remains local until the primary's single
atomic acknowledgement; a newer external vendor is preserved. If the pending
primary is abandoned, the controlled vendor is restored from the committed
external scope.

### Exact identity and paging

- Vendor distribution factories now use exact immutable keys (`vendor.key` or
  the exact rollup name); the lossy slug helper was deleted.
- Log paging identity is structural (`BudgetV2SnapshotRevision`, avatar key,
  selected exact vendor), so merchant keys containing delimiters cannot
  collide.
- The standalone dashboard no longer references
  `balanceVisibleDisplayLogEntries`,
  `hasMoreBalanceVisibleDisplayLogEntries`, or
  `loadMoreBalanceVisibleDisplayLogEntries`.
- The real production route proves 96 rows expand cumulatively to 120 without
  notifying the store.

## Acceptance results

| ID | Result | Evidence |
| --- | --- | --- |
| T7-01 | DONE | Existing Food entry selects the Food avatar/card/log before and after acknowledgement; real category chip returns to Overview |
| T7-02 | DONE | Exact vendor selection and real merchant-chip removal keep controller, legend, and log aligned; external scope cancels stale ticker work |
| T7-03 | DONE | `ACME Shop` and `ACME-Shop` have distinct keys and independent production log selections |
| T7-04 | DONE | Production route pages 96→120 locally; ghost-aware core paging passes; legacy visible-log tokens are absent |
| T7-05 | DONE | Live ticker traverses multiple vendors without raw or normalized merchant diagnostics |
| T7-06 | DONE | 4,096-record direct drag reports zero query resolves, misses, projections, snapshot work, and pre-commit store notifications |
| T7-07 | DONE | Exact and 178-test affected suites pass; analyzer is clean; mandatory screenshot was reinspected after implementation; geometry was not edited |

## TDD evidence

### Baseline

Before Task 7 edits, the exact required two-file command passed 54 tests in
01:36.

### Initial RED

The four required production-route contracts and source contracts were added
before implementation. The exact Task 7 command exited 1 with five expected
failures:

- the dashboard did not own `BudgetV2LogProjectionCache`;
- existing Food scope still selected Overview;
- exact `Lidl` legend identity was absent;
- `ACME Shop` and `ACME-Shop` collided;
- the ticker logged a merchant-derived `vendor_tick` value.

The selection-controller adoption contract separately failed to compile until
`adoptCommittedAvatar` was implemented.

### Review-driven RED → GREEN cases

Independent review exposed and tests reproduced these real integration edges:

- explicit query-cache counters were missing from the direct-frame proof;
- settled local primary initially updated neither card nor log before store
  acknowledgement;
- committed Food/Lidl → pending Travel intersected the new avatar with stale
  external filters;
- same-store external merchant changes did not cancel a running vendor ticker;
- delimiter-joined log query keys could collide;
- a newer local or external vendor could be erased by an older pending-primary
  timer;
- a vendor acknowledgement could linger after its pending primary was
  abandoned;
- production paging lacked a route-level 96→next-page contract.

Each case received a failing contract before or alongside its remediation.
The final implementation uses structural identities, query-scope epochs,
controller-held acknowledgements, atomic category/vendor store publication,
and explicit abandoned-primary restoration.

## Final verification

All Flutter commands ran inside Ubuntu/proot with
`/home/flutteruser/flutter/bin/flutter`.

Exact Task 7 command:

```text
flutter test
  test/spendeetest/spendee_budget_v2_contract_test.dart
  test/spendeetest/budget_v2_interaction_diagnostics_test.dart

62 tests passed; All tests passed! (01:18); exit 0.
```

Affected regression matrix:

```text
budget_v2_selection_controller_core_test.dart
budget_v2_selection_controller_test.dart
budget_v2_limit_edit_controller_test.dart
budget_v2_limit_persistence_coordinator_test.dart
budget_v2_snapshot_test.dart
budget_v2_production_snapshot_test.dart
budget_v2_query_controller_test.dart
spendee_budget_v2_avatar_carousel_test.dart
spendee_balance_ticking_carousel_test.dart
spendee_balance_transaction_log_test.dart
spendee_balance_performance_test.dart
spendee_balance_dashboard_test.dart
spendee_dashboard_mode_host_test.dart
recurring_ghost_log_test.dart
recurring_ghost_log_box_test.dart
transaction_store_test.dart

178 tests passed; All tests passed! (01:09); exit 0.
```

Static verification:

```text
flutter analyze
No issues found! (ran in 52.7s); exit 0.
```

`git diff --check` is clean. Direct source search finds none of the three
legacy Balance visible-log APIs, the lossy vendor-key helper, or the removed
per-step vendor ticker trace in the Task 7 production path.

Independent final code review reported no Critical, Important, or Minor
findings and assessed Task 7 as approved and ready to merge.

## Interface extensions required by integration review

Task 7 consumed the Task 6 core and added small integration-safe extensions:

- `BudgetV2SelectionController.adoptCommittedAvatar` cancels stale work when
  an external primary becomes authoritative.
- `BudgetV2LogProjectionCacheDiagnostics` exposes resolve, miss, and
  projection counters used by bounded terminal interaction evidence.
- `BudgetV2InteractionDiagnostic` records only sanitized counter deltas.
- `BudgetV2QueryController` adopts exact one-merchant external scopes and can
  hold a newer acknowledged local vendor across an unchanged stale scope.
- `TransactionStore.applyBudgetV2AvatarFilter` accepts an optional exact
  selected vendor so a final primary acknowledgement can apply both dimensions
  atomically with one notification.
- The legacy `SpendeeBalanceDashboard` compatibility consumer now also passes
  controlled `selectedVendorKey`; no mother-card consumer retains hidden
  vendor authority.

## Visual and delivery status

The mandatory screenshot was inspected before implementation and reinspected
twice during final integration/review. Task 7 changed data flow, ownership,
diagnostics, and exact identities only; no approved layout, color, spacing,
or geometry token was changed.

No build, push, artifact download, or remote action was performed.
