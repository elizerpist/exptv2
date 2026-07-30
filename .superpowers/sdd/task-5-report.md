# Task 5 report — visual, performance and integration evidence

## Scope and result

This task verified the completed Budget V2 implementation without changing
production or carousel source. The mandatory reference was inspected directly:
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`.

The inspected reference establishes the light blue screen, Fluvi lockup,
blue-gradient budget header, five-avatar belt, large white mother-card, type
pills, total/search/filter controls, transaction log, and bottom navigation.
The existing production/widget contracts cover those structural regions and
the Task 4 geometry locks the belt at `Rect.fromLTWH(17, 241, 378, 80)` and
mother card at `Rect.fromLTWH(17, 332, 378, 210)`. This is not a substitute
for a visual comparison against a freshly installed final APK, so B2P-001 is
honestly `PARTIAL`.

## Performance and architecture review

- `SpendeeBudgetModeHost` constructs `SpendeeBudgetV2Dashboard` for the V2
  variant. Direct source inspection confirmed that the legacy coordinator is
  allocated only for ordinary Budget; the V2 dashboard itself owns its
  `BudgetV2StoreSnapshotCache` and `BudgetV2SelectionController`.
- The direct-frame avatar contract proves retained `Flow`, item, leaf, and
  host identities for within-slot motion. The production contract additionally
  proves direct tick previews remain local rather than delivering a chart
  update.
- The real-size cache contract traverses 4,096 records once per revision,
  returns the same prepared snapshot for a matching revision, and rejects any
  later raw traversal when reading avatar data.
- The production settled-avatar contract records exactly one
  `[BudgetV2Carousel] phase=commit` primary-category publication for the
  gesture. The selection-controller contracts also ensure an obsolete
  generation cannot commit.
- Bounded diagnostics are covered by the selection-controller recent-generation
  window contract and source review; no per-frame diagnostic emission is used.

## Verification (Ubuntu/proot only)

All commands were run through `proot-distro login ubuntu`, using
`/home/flutteruser/flutter/bin/flutter`; no local APK build, download,
installation, GitHub Action, push, or remote dispatch was attempted.

```text
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/budget_v2_snapshot_test.dart test/spendeetest/budget_v2_production_snapshot_test.dart test/spendeetest/budget_v2_selection_controller_core_test.dart test/spendeetest/budget_v2_selection_controller_test.dart test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart'
81 tests passed; All tests passed! (01:34); exit 0

proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter analyze'
No issues found! (ran in 140.2s); exit 0

proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/budget_v2_limit_edit_controller_test.dart test/spendeetest/budget_v2_limit_persistence_coordinator_test.dart test/spendeetest/budget_v2_production_snapshot_test.dart test/spendeetest/budget_v2_selection_controller_core_test.dart test/spendeetest/budget_v2_selection_controller_test.dart test/spendeetest/budget_v2_snapshot_test.dart test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart test/spendeetest/spendee_dashboard_mode_host_test.dart test/spendeetest/spendee_balance_dashboard_test.dart test/spendeetest/spendee_balance_transaction_log_test.dart test/spendeetest/spendee_balance_production_contract_test.dart'
150 tests passed; All tests passed! (03:02); exit 0
```

## Remaining evidence

- B2P-001 requires a fresh screenshot from the final GitHub-built APK after
  installation and a direct comparison to the mandatory reference.
- B2P-011 remains `NOT DONE`: commit/push, workflow dispatch/success, APK
  download to a new Android Downloads folder, and recorded SHA-256 are the
  explicitly deferred remote delivery sequence for the root agent.

The completion rule is not satisfied because those rows remain incomplete.
