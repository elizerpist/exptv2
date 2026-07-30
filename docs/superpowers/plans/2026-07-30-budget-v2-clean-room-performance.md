# Budget V2 clean-room performance refactor — implementation plan

> **Execution note:** User explicitly approved this plan and all normal
> implementation choices on 2026-07-30; continue without another approval
> gate. Work is isolated on `feature/budget-v2-performance-rewrite`.

**Goal:** Replace Budget V2's Balance-hosted runtime with a standalone,
snapshot-backed screen whose avatar rail has paint-only direct manipulation.

**Architecture:** Add a small `budget_v2` feature boundary: immutable source
snapshot/cache, selection/publication controller, limit-edit controller, and
standalone screen. Reuse only visual leaves, not the Balance screen/frame or
legacy coordinator. Route `budgetV2` directly to it and leave Balance/Budget/
Mind untouched.

**Tech:** Flutter/Dart, existing models/`TransactionStore`, Flow render layout,
`ValueNotifier`/`ChangeNotifier`, Flutter widget/unit tests.

## Task 1 — Lock the boundary with RED tests

**Files:**
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Add: `test/spendeetest/budget_v2_selection_controller_test.dart`
- Add: `test/spendeetest/budget_v2_snapshot_test.dart`

1. Replace the old source-contract expectation that Budget V2 mounts via
   `SpendeeBalanceDashboard` with a clean-room boundary expectation.
2. Write failing tests for the physical/settled/committed state machine,
   cancellation generation and one-commit maximum.
3. Write failing real-size fixture tests proving snapshot preparation is cached
   and avatar selection uses prepared data rather than a raw scan.
4. Run only these tests inside Ubuntu proot and record the expected RED state.

## Task 2 — Build immutable data and interaction cores (TDD)

**Files:**
- Add: `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_snapshot.dart`
- Add: `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_selection_controller.dart`
- Add: `lib/features/transactions/widgets/experimental/budget_v2/budget_v2_limit_edit_controller.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`

1. Implement a source-keyed snapshot cache using the existing store's cached
   period records/bars and prepared per-avatar vendor/log indexes.
2. Implement generation-safe publication state; direct movement can only update
   physical state, and final publication is capped at one per gesture.
3. Implement a standalone long-press limit-edit session with local preview and
   release-only persistence.
4. Make `applyBudgetV2AvatarFilter` a lightweight final acknowledgement by
   removing synchronous active-view prewarming.
5. Run the new unit tests until GREEN, then the affected store tests.

## Task 3 — Replace the avatar rail render hot path (TDD)

**Files:**
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart`
- Modify: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`
- Modify/Add: avatar-rail widget tests

1. Introduce a repaint-listenable Flow delegate with seven retained slot
   children and stable avatar SVG/icon keys.
2. Keep semantic/tap/long-press behaviour and external epoch handling, but
   prevent per-delta `setState`/item-builder recreation.
3. Add instrumentation tests for no host/card/log/store work while dragging,
   incoming-slot retention and immediate pointer pre-emption.
4. Run focused carousel/component tests until GREEN.

## Task 4 — Compose the standalone Budget V2 screen (TDD)

**Files:**
- Add: `lib/features/transactions/widgets/experimental/budget_v2/spendee_budget_v2_dashboard.dart`
- Modify: `lib/features/transactions/widgets/experimental/modes/spendee_budget_mode_host.dart`
- Modify: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`
- Modify: `test/spendeetest/helpers/balance_production_host.dart`
- Modify: `test/spendeetest/spendee_budget_v2_contract_test.dart`

1. Build the equivalent header, belt, mother card, type/period/query controls
   and transaction log from prepared Budget V2 data.
2. Pass only public callbacks/configuration from the parent dashboard; remove
   the B2-specific legacy runtime and conditional legacy coordinator creation.
3. Feed long-press preview and selection notifiers only to the narrow regions
   that require them.
4. Update the production-host helper and assert the new public dashboard is
   mounted instead of `SpendeeBalanceDashboard` for Budget V2.
5. Run the complete Budget V2 contracts, mode-host tests and affected Balance
   tests; resolve regressions before proceeding.

## Task 5 — Verify visual, performance and integration evidence

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-30-budget-v2-clean-room-performance.md`

1. Re-read the screenshot and checklist; capture/inspect a fresh device
   screenshot after installing the GitHub-built APK.
2. Exercise a real data-size avatar swipe sequence and inspect bounded Budget
   V2 diagnostics: zero store/snapshot work during direct frames and at most
   one final commit per gesture.
3. Run targeted tests, then `flutter analyze` and relevant full test suite in
   Ubuntu proot. Update each checklist row honestly.
4. Review the diff independently, commit the implementation, push the feature
   branch, dispatch the GitHub workflow (push does not trigger this workflow),
   wait for success, download the APK to a new Android Downloads folder and
   record its SHA-256.
