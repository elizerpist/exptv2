# Task 5 report — visual, performance and integration evidence

## Scope and result

This task inspected the mandatory reference and then corrected the standalone
Budget V2 diagnostic boundary. The reference was inspected directly:
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
- The original dashboard had three long-press per-update traces
  (`move`, `budget_limit_tick`, and `tick`) and legacy chart diagnostic paths
  could emit raw build-path values. The red diagnostics and rail tests first
  failed because the final-summary mechanism and terminal callback did not
  exist; after the implementation they pass.
- `BudgetV2InteractionDiagnostics` is a UI-free core owning a bounded queue of
  sanitized terminal records. Each record contains only source revision,
  record/bar counts, physical-frame count, settled index, commit count and
  final commit duration (plus cache-work counts); it deliberately has no
  amount, merchant, vendor, category or avatar value.
- The rail counts direct physical frames locally and sends one terminal
  callback. The dashboard owns the interaction session, records cache deltas,
  and completes it only at cancellation or the final primary-filter commit.
  `BudgetV2DiagnosticsScope`, in its own presentation file, disables legacy
  raw chart build diagnostics only under the standalone B2 route; the legacy
  default remains enabled. Store replacement cancels the active session.
- The real standalone `SpendeeBudgetV2Dashboard` 4,096-record swipe contract
  proves direct moves retain the mother-card/log widgets, publish no store
  notification, perform zero direct cache resolve/preparation calls, emit no
  chart/raw sensitive trace, and make exactly one final primary commit after
  the idle boundary. Multiple long-press moves likewise emit no per-frame
  trace and one terminal summary only.

## Verification (Ubuntu/proot only)

All commands were run through `proot-distro login ubuntu`, using
`/home/flutteruser/flutter/bin/flutter`; no local APK build, download,
installation, GitHub Action, push, or remote dispatch was attempted.

```text
TDD red evidence:
budget_v2_interaction_diagnostics_test.dart before its core existed: expected
missing-library/undefined-symbol compilation failure; exit 1.
spendee_budget_v2_avatar_carousel_test.dart before its terminal callback
existed: expected `onInteractionCompleted` named-parameter failure; exit 1.

TDD green evidence:
budget_v2_interaction_diagnostics_test.dart: 1 test passed; exit 0.
spendee_budget_v2_avatar_carousel_test.dart: 18 tests passed; exit 0.
new 4,096-record standalone contract: 1 test passed; exit 0.

proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/budget_v2_snapshot_test.dart test/spendeetest/budget_v2_production_snapshot_test.dart test/spendeetest/budget_v2_selection_controller_core_test.dart test/spendeetest/budget_v2_selection_controller_test.dart test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart'
81 tests passed; All tests passed! (01:34); exit 0

proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter analyze'
No issues found! (ran in 140.2s); exit 0

proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/.config/superpowers/worktrees/exptv2/budget-v2-performance-rewrite && /home/flutteruser/flutter/bin/flutter test test/spendeetest/budget_v2_limit_edit_controller_test.dart test/spendeetest/budget_v2_limit_persistence_coordinator_test.dart test/spendeetest/budget_v2_production_snapshot_test.dart test/spendeetest/budget_v2_selection_controller_core_test.dart test/spendeetest/budget_v2_selection_controller_test.dart test/spendeetest/budget_v2_snapshot_test.dart test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart test/spendeetest/spendee_dashboard_mode_host_test.dart test/spendeetest/spendee_balance_dashboard_test.dart test/spendeetest/spendee_balance_transaction_log_test.dart test/spendeetest/spendee_balance_production_contract_test.dart'
150 tests passed; All tests passed! (03:02); exit 0

Fresh post-remediation focused suite (diagnostics, snapshot/cache, avatar rail,
and Budget V2 contract): 80 tests passed; All tests passed! (02:18); exit 0.

Fresh post-format relevant suite (diagnostics, limit edit/persistence,
snapshot/cache, selection, carousel, Budget V2 contract and Balance host/log
regressions): 153 tests passed; All tests passed! (03:47); exit 0.

Final-tree full analysis:
`flutter analyze` — No issues found! (ran in 81.1s); exit 0.
```

## Remaining evidence

- B2P-001 requires a fresh screenshot from the final GitHub-built APK after
  installation and a direct comparison to the mandatory reference.
- B2P-011 remains `NOT DONE`: commit/push, workflow dispatch/success, APK
  download to a new Android Downloads folder, and recorded SHA-256 are the
  explicitly deferred remote delivery sequence for the root agent.

The completion rule is not satisfied because those rows remain incomplete.
