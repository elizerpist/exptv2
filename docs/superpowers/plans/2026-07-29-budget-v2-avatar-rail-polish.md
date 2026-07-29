# Budget V2 Avatar Rail Polish Implementation Plan

> **For agentic workers:** Execute inline: make each regression test fail before its matching production change, then re-run the focused Flutter test in Ubuntu proot.

**Goal:** Centre and enlarge the selected Budget V2 avatar progress orb, remove the rail dots without moving content, make the rail tick atomically with the selected orb, keep exactly five visible avatars, and keep category/vendor pie state in step with an animated remote selection.

**Architecture:** `SpendeeBalanceTickingViewport` retains the one-slot physics but gains Budget-V2-specific selection/visibility options. The dashboard separates the belt's requested target from its committed filter selection and shares a lightweight preview value with the mother-card charts. The existing resolver remains the only source of pie colours.

**Tech Stack:** Flutter/Dart, flutter_test, flutter_svg, existing `DebugConsole` diagnostics; targeted test/analyse commands run in Ubuntu proot; APK build via GitHub Actions.

## Acceptance mapping

- [x] BUDGETV2-029 — selected orb centre and extra ring breathing room.
- [x] BUDGETV2-030 — dot-free fixed-height avatar area with slightly larger avatars.
- [x] BUDGETV2-031 — exactly five painted slots and synchronized selected-orb/tick transition.
- [x] BUDGETV2-032 — full resolver colours for all category/vendor slices and legends.
- [x] BUDGETV2-033 — category and vendor pies preview every avatar tick; Store filter remains settle-only.

### Task 1: Lock down rail geometry and tick selection

**Files:**
- Modify tests: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Modify tests: `test/spendeetest/spendee_balance_ticking_carousel_test.dart`
- Modify implementation: `lib/features/transactions/widgets/experimental/balance/spendee_balance_ticking_carousel.dart`
- Modify implementation: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`

1. Add failing tests for no avatar dots, stable 80px belt, 72px avatar allocation, a down-centred 40px orb core, strict entering-neighbour offstage state, and an orb that becomes selected only on the same controller boundary that emits its tick.
2. Run the focused test files and confirm these assertions fail against the present implementation.
3. Add opt-in `selectionFollowsActiveIndex` and `hideEnteringLogicalNeighbour` flags to the generic ticker; enable both only on the Budget V2 belt.
4. Preserve the 80px belt, remove dot widgets, allocate the ticker 72px at the top, increase orb allocation/core and translate only the inner avatar down into mathematical centre.
5. Re-run the focused tests until green.

### Task 2: Keep remote chart requests animated without jumping charts or filters

**Files:**
- Modify tests: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Modify implementation: `lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart`
- Modify implementation: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`

1. Add a failing production-host contract that records the category and vendor distribution diagnostics while a remote legend/category request crosses multiple avatars; it must contain intermediate selected keys and one settled dashboard filter publication.
2. Run the targeted contract test and confirm the current direct parent selection jumps its chart state.
3. Keep a requested belt index separate from the committed avatar key. Publish inexpensive preview keys on each tick via a `ValueNotifier`, and commit/filter only from `onIndexSettled`.
4. Rebuild the compact/category/vendor chart projections from the preview bar while retaining vendor-selection clearing and existing final filter semantics.
5. Re-run the targeted contract test until it observes the stepped chart states and one final settlement.

### Task 3: Restore full pie colours and verify the package

**Files:**
- Modify tests: `test/spendeetest/spendee_budget_v2_contract_test.dart`
- Modify implementation: `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`
- Modify checklist: `docs/superpowers/checklists/2026-07-29-budget-v2-income-distribution.md`

1. Replace the old fading expectation with a failing test requiring both active and inactive outputs to equal the central resolver colour.
2. Make `BudgetV2DonutSliceVisuals` return the full resolver colour for each state; retain selection offset/highlight geometry without using colour dimming.
3. Run the full Budget V2 contract and ticker suites, then scoped Flutter analyse in Ubuntu proot.
4. Inspect the checklist against the tests/source/screenshot, mark verified requirements `DONE`, commit only task files, push `spendeetest`, trigger/observe GitHub Actions, and download the built debug APK into `/storage/emulated/0/Download`.
