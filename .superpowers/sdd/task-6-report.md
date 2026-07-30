# Task 6 Report: UI-free Budget V2 query/projection core

## Architecture card

### Scope and sources

- Requirement source: `.superpowers/sdd/task-6-brief.md`
- Existing implementation:
  - `lib/features/transactions/state/transaction_store.dart`
  - `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_snapshot.dart`
  - `lib/features/transactions/models/transaction_log_entry.dart`
- Task boundary: no dashboard/component wiring; no build, push, or download.

### Single source and write path

- Transaction-log sorting, bounded row-windowing, and date-header insertion:
  `models/transaction_log_projection.dart` (single pure mechanism).
- External filter source of truth: `TransactionStore`.
- B2 local vendor/acknowledgement state: `BudgetV2QueryController`.
- B2 prepared read model: immutable `BudgetV2SnapshotSource` /
  `BudgetV2PreparedSnapshot`.
- Store writes: none in Task 6; reconciliation returns instructions for the
  future UI integration.
- Error/retry owner: not applicable; all new projection/reconciliation paths
  are synchronous and pure.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Search/category/merchant filters | `TransactionStore` | Store lifetime | Read into an immutable external scope |
| Selected local vendor | `BudgetV2QueryController` | B2 controller lifetime | Never writes the store directly |
| Acknowledged external scope | `BudgetV2QueryController` | B2 controller lifetime | Reconciliation only |
| Prepared period records/ghosts | `BudgetV2PreparedSnapshot` | Source revision | Immutable |
| Projection memoization | `BudgetV2LogProjectionCache` | Cache lifetime | Keyed by snapshot revision and query |

### Reuse and centralization

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Log ordering/window/headers | Private helpers in `TransactionStore` | Descending normalized date, time, sortId; bounded rows; one header per date | Extract public pure helper and migrate legacy/B2 consumers | Focused helper/B2 tests plus legacy store log tests |
| Vendor selection lookup | `BudgetV2AvatarSnapshot.recordsByVendorKey` | Exact vendor key identity | Reuse `recordsForVendor` | Exact `ACME Shop` / `ACME-Shop` test |

### Layer flow

Future UI (Task 7) → `BudgetV2QueryController` →
`BudgetV2LogProjectionCache` → immutable prepared snapshot →
pure transaction-log projection.

The new core has no widget or `BuildContext` dependency.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| T6-01 | Brief Steps 1-2 | query/projection tests | Genuine RED for missing interfaces/behavior is captured before production code | Ubuntu/proot focused test output | DONE |
| T6-02 | Brief Step 3 | model helper + store | One shared pure sort/window/header mechanism serves legacy and B2 paths | Unit + legacy store tests; code inspection | DONE |
| T6-03 | Brief Step 4 | snapshot source/prepared model | Source carries immutable raw period ghosts and revision includes type/period/normalized query/sorted exact filters | Production snapshot tests | DONE |
| T6-04 | Brief Step 4 | B2 log cache | Projection uses exact vendor index, active scope, ghosts, ordering, pagination, and immutable output | Query projection tests including 97+ rows | DONE |
| T6-05 | Binding constraint | B2 core | No `balanceVisibleDisplay...` getter/prewarm path and no widget/`BuildContext` dependency | `rg` and analyze | DONE |
| T6-06 | Brief Step 5 | query controller | Reconciliation adopts one category, preserves acknowledged selection, clears stale local state, and search does not request writes | Controller unit tests | DONE |
| T6-07 | Brief Step 6 | affected tests | Focused suite and affected legacy log regressions pass in Ubuntu/proot | Fresh test output | DONE |
| T6-08 | Brief Step 7 | Task 6 files | Task 6-only change committed; no UI integration/push/build/download | Git diff/status/log | DONE |

## Evidence log

### Baseline

Before Task 6 tests were added:

```text
flutter test budget_v2_snapshot_test.dart
             budget_v2_production_snapshot_test.dart
             recurring_ghost_log_test.dart
             transaction_store_test.dart
60 tests passed; All tests passed!; exit 0.
```

All Flutter commands in this report were run through Ubuntu/proot with
`/home/flutteruser/flutter/bin/flutter`. No Termux-host Flutter/Dart binary was
used.

### TDD RED

The required Step 2 command was run after adding
`budget_v2_query_controller_test.dart` and before either production core file
existed:

```text
flutter test budget_v2_snapshot_test.dart
             budget_v2_production_snapshot_test.dart
             budget_v2_query_controller_test.dart
exit 1.
```

Expected RED reason: the compiler could not read
`budget_v2_log_projection.dart` or `budget_v2_query_controller.dart`, and
reported the missing `BudgetV2LogProjectionCache`, `BudgetV2LogQuery`,
`BudgetV2ExternalQueryScope`, and `BudgetV2QueryController` interfaces.

The shared helper test was also run before its production file existed:

```text
flutter test transaction_store_test.dart
  --plain-name "shared log projection bounds rows and owns canonical headers"
exit 1.
```

Expected RED reason: missing `transaction_log_projection.dart` and
`projectTransactionLogEntries`.

The source revision/ghost test was run before source support existed and failed
with missing `BudgetV2SnapshotSource.periodGhosts`; exit 1.

During review, a stricter controller edge case exposed a real stale-state bug:

```text
flutter test budget_v2_query_controller_test.dart
  --plain-name "BudgetV2 query clears a vendor when an external category changes"
Expected true, Actual false; exit 1.
```

The implementation was then changed so an unrelated external avatar/category
change clears the local vendor even when the old merchant chip remains.

### Focused GREEN

- Shared pure projection helper named test: 1 passed; exit 0.
- Canonical source revision/frozen period ghosts named test: 1 passed; exit 0.
- Query controller/projection file after initial implementation: 7 passed;
  exit 0.
- Stale-vendor external-category regression after correction: 1 passed;
  exit 0.

Final affected suite:

```text
proot-distro login ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite &&
   /home/flutteruser/flutter/bin/flutter test
     test/spendeetest/budget_v2_snapshot_test.dart
     test/spendeetest/budget_v2_production_snapshot_test.dart
     test/spendeetest/budget_v2_query_controller_test.dart
     test/transactions/recurring_ghost_log_test.dart
     test/transactions/transaction_store_test.dart'

70 tests passed; All tests passed! (00:18); exit 0.
```

This includes the legacy complete-log behavior, recurring real/ghost date
grouping, and the existing 10k single-day bounded Balance paging regression.
The new 99-row B2 case proves a 96-row first page has `hasMore`, a cumulative
next page retains the ghost-first date/time/sortId order, and date headers stay
unique.

Static verification:

```text
flutter analyze
No issues found! (ran in 32.8s); exit 0.
```

`rg` over the four B2/core files returned no
`balanceVisibleDisplay`, `BuildContext`, `Widget`, `setState`,
`notifyListeners`, or `prewarm` reference. Direct inspection confirms both
TransactionStore and B2 call `projectTransactionLogEntries`. The unrelated
raw-record fallback inside `transaction_log_list.dart` still creates its own
date headers for callers that do not supply projected entries; Task 6 did not
claim or change ownership of that widget fallback.

## Decisions and signature notes

- Added the explicit store adapter `budgetV2PeriodGhosts`. It publishes only
  eligible, deduplicated, active-type monthly ghosts and does not call any
  Balance display getter or prewarm path.
- `BudgetV2SnapshotRevision` now includes summary window/reference day,
  normalized search, sorted category IDs, sorted exact merchant keys, and raw
  records/ghost/bar/overview identities. `BudgetV2PreparedSnapshot` exposes
  only its immutable `sourceRevision` plus indexed avatar data.
- Prepared avatars received immutable ghost and exact ghost-vendor indexes so
  real and recurring rows share the same query pipeline. Real selected-vendor
  lookup uses the required `recordsForVendor(selectedVendorKey)` path.
- The shared `TransactionLogProjection` also exposes immutable sorted `rows`
  and `totalDisplayEntryCount`; these are the minimal additions needed to
  preserve the two legacy TransactionStore public getter contracts without a
  second sort/header implementation. Complete lists use one `sort`; bounded
  page queries retain the previous bounded insertion behavior.
- The controller constructor takes `unfilteredAvatarKey` and an immutable
  category-to-avatar map because the brief leaves category/avatar resolution
  injection unspecified. `BudgetV2QueryReconciliation` is the explicit,
  UI-free return instruction: adopt/clear avatar, clear vendor, and never
  request a store write. The public `BudgetV2ExternalQueryScope` constructor is
  now a freezing factory rather than the brief's illustrative `const`
  constructor. This intentional deviation is required to prevent mutable
  caller-owned sets from changing an already-created query or cache key.
- No dashboard or `spendee_budget_v2_components.dart` wiring was added. No
  push, build, download, or remote action was performed.

## Review remediation evidence

The Task 6 review findings were verified against the committed implementation
and addressed in a follow-up TDD pass.

### Merchant-scope expansion RED -> GREEN

The controller previously cleared a local vendor only when the new merchant
scope no longer contained that vendor. Therefore the actual external change
`{'ACME-Shop'} -> {'ACME-Shop', 'Other'}` incorrectly retained the local exact
vendor index and kept the B2 projection narrowed to ACME.

```text
flutter test test/spendeetest/budget_v2_query_controller_test.dart
  --plain-name "BudgetV2 query clears vendor narrowing when external merchants expand"

RED: Expected clearSelectedVendor true, Actual false; exit 1.
GREEN: 1 test passed; All tests passed!; exit 0.
```

`BudgetV2QueryController` now compares the new merchant scope with the
previous external merchant scope. Any actual unacknowledged change clears the
local vendor. The GREEN contract also resolves the resulting B2 query and
proves both exact external merchants appear in descending log order, so the
projection cannot remain silently narrowed to ACME.

### Scope immutability RED -> GREEN

The original public `const` constructor retained caller-owned set references.
Mutating those sets after query construction changed later normalization and
cache semantics.

```text
flutter test test/spendeetest/budget_v2_query_controller_test.dart
  --plain-name "BudgetV2 external scope freezes caller sets for query and cache semantics"

RED: expected categoryIds {6}, actual {6, 5}; exit 1.
GREEN: 1 test passed; All tests passed!; exit 0.
```

The public constructor is now a factory that freezes both sets through a
private immutable constructor; `copyWith` routes through the same factory.
The GREEN test mutates all original sets and proves the scope stays unchanged,
the same query resolves to the identical cached projection, the row set does
not widen, and the exposed sets reject mutation.

### Strengthened pagination evidence

The 99-row contract now includes two out-of-scope real records and two
out-of-scope ghosts (wrong merchant and wrong category). It asserts:

- the exact first-page row sequence is ghost `900`, then records `1000..1094`;
- the cumulative next page is ghost `900`, then records `1000..1097`;
- the exact continuation after the 96-row boundary is `1095, 1096, 1097`;
- first-page headers are days `25..13` and full-page headers are `25..12`;
- none of the four distractors enter either scoped result.

The strengthened named test passed; exit 0.

### Fresh final verification after review remediation

```text
proot-distro login ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite &&
   /home/flutteruser/flutter/bin/flutter test
     test/spendeetest/budget_v2_snapshot_test.dart
     test/spendeetest/budget_v2_production_snapshot_test.dart
     test/spendeetest/budget_v2_query_controller_test.dart
     test/transactions/recurring_ghost_log_test.dart
     test/transactions/transaction_store_test.dart'

72 tests passed; All tests passed! (00:20); exit 0.

flutter analyze
No issues found! (ran in 33.9s); exit 0.
```

## Concern status

No open Task 6 concerns. Task 7 still owns UI integration and therefore must
translate `BudgetV2QueryReconciliation` instructions into the existing
selection/store callbacks without moving store writes into this core.
