# Task 8 Report: independent integration/performance re-review

## Status

APPROVED.

Independent review of `a0703fb..9ce56d7` found no Critical, Important, or
Minor issue. The review changed no production code and performed no push,
build, download, or remote mutation.

The feature checklist intentionally remains incomplete at delivery level:
B2P-001 is still `PARTIAL` pending a final GitHub-built APK screenshot
comparison, and B2P-011 is still `NOT DONE`.

## Required inputs inspected

- `docs/migration-guide.md`
- `docs/superpowers/specs/2026-07-30-budget-v2-clean-room-performance-design.md`
- `docs/superpowers/plans/2026-07-30-budget-v2-clean-room-performance.md`
- `docs/superpowers/plans/2026-07-30-budget-v2-final-clean-room-remediation.md`
- `docs/superpowers/checklists/2026-07-30-budget-v2-clean-room-performance.md`
- `.superpowers/sdd/task-6-report.md`
- `.superpowers/sdd/task-7-report.md`
- `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`

The screenshot was opened directly at original detail. It shows the retained
Budget V2 composition used by the contracts: branded header and budget hero,
five-avatar belt, vendor-distribution mother card, income/expense switch,
summary/search/filter controls, grouped transaction log, and bottom
navigation.

## Independent source findings

Review range:

```text
a0703fb..9ce56d7
20 changed files; 3,502 insertions; 195 deletions.
```

Findings by severity:

- Critical: none.
- Important: none.
- Minor: none.

The source review verified:

1. `BudgetV2LogProjectionCache` is the B2 log projection owner and consumes
   immutable prepared snapshots; the standalone dashboard has no call or token
   for `balanceVisibleDisplayLogEntries`,
   `hasMoreBalanceVisibleDisplayLogEntries`, or
   `loadMoreBalanceVisibleDisplayLogEntries`.
2. `BudgetV2SelectionController` remains the single live primary-avatar
   lifecycle owner. Re-creation occurs only for initialization or store
   replacement; the dashboard maps the final intent to one
   `applyBudgetV2AvatarFilter` acknowledgement.
3. `BudgetV2QueryController` freezes external sets and explicitly orders local
   avatar/vendor acknowledgements against newer external category and merchant
   scopes. Pending-primary abandonment restores the authoritative external
   vendor.
4. Merchant aggregation, prepared indexes, controlled mother-card input,
   donut lookup, legend keys, and store acknowledgement all carry the exact
   vendor key. The lossy `_vendorDistributionKey` helper is absent, so
   `ACME Shop` and `ACME-Shop` remain distinct.
5. Mother-card state retains only page/limit-edit presentation state; selected
   vendor is supplied by the dashboard. External scope changes increment the
   selection epoch and invalidate in-flight ticker work.
6. The vendor ticker emits no per-step `DebugConsole` record. Terminal
   interaction diagnostics are sanitized and retained in a bounded 16-record
   queue; their fields are counts, indexes, revision fingerprint, outcome and
   duration only.
7. Projection/cache and widget paging identities are structural: snapshot
   revision, normalized/sorted scope, avatar key, exact selected vendor key and
   row limit participate without delimiter concatenation.
8. Direct physical frames remain inside the retained rail path. Explicit
   diagnostics measure snapshot resolves/preparations, query resolves/cache
   misses/projections, and the production contract asserts every delta plus
   store notifications is zero before the final commit.
9. `projectTransactionLogEntries` is the one shared ordering/window/header
   mechanism used by B2 and legacy `TransactionStore` paths.

Static evidence:

```text
git diff --check a0703fb..9ce56d7
exit 0; no output.

rg 'balanceVisibleDisplayLogEntries|hasMoreBalanceVisibleDisplayLogEntries|loadMoreBalanceVisibleDisplayLogEntries'
  lib/features/transactions/widgets/experimental/budget_v2/spendee_budget_v2_dashboard.dart
0 matches.

rg '_vendorDistributionKey|vendor_tick'
  lib/features/transactions/widgets/experimental/budget_v2
  lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart
0 matches.
```

## Fresh Ubuntu/proot verification

Every Flutter command used `/home/flutteruser/flutter/bin/flutter` inside the
Ubuntu proot worktree.

### Exact Task 7 command

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_budget_v2_contract_test.dart test/spendeetest/budget_v2_interaction_diagnostics_test.dart'
```

Result:

```text
01:04 +62: All tests passed!
exit 0.
```

### Standalone 4,096-record contract

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "standalone BudgetV2 keeps a 4096-record swipe local until one final commit"'
```

Result:

```text
00:32 +1: All tests passed!
exit 0.
```

This contract proves the same mother-card/log element identities survive the
physical swipe; pre-commit store notifications, snapshot resolves/preparations,
query-cache resolves/misses and log projections are all zero; the final
generation publishes once.

### Query/cache/selection and TransactionStore matrix

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/budget_v2_selection_controller_core_test.dart test/spendeetest/budget_v2_selection_controller_test.dart test/spendeetest/budget_v2_snapshot_test.dart test/spendeetest/budget_v2_production_snapshot_test.dart test/spendeetest/budget_v2_query_controller_test.dart test/transactions/recurring_ghost_log_test.dart test/transactions/transaction_store_test.dart'
```

Result:

```text
00:18 +78: All tests passed!
exit 0.
```

### Full analyzer

```sh
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter analyze'
```

Result:

```text
No issues found! (ran in 46.9s)
exit 0.
```

## Boundary confirmation

Only this report and the evidence text for B2P-006, B2P-007, B2P-009 and
B2P-010 were changed. B2P-001 remains `PARTIAL`; B2P-011 remains `NOT DONE`.
No production file, test, build artifact, remote branch, workflow, or Android
download was modified.
