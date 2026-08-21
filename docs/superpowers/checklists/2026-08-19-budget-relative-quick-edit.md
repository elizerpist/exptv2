# Budget relative quick-edit acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BQE-01 | User §4–8, §19–21 | `DashboardBudgetLimitEditController` | Very-long is an optimistic, non-terminal draft clear; the active pointer can create a positive draft afterwards. | Controller RED/GREEN test: start → clear draft → adjust → finish. | DONE |
| BQE-02 | User §7–8, §25 N–Q | Edit-session finalization | Pointer contact performs no write; release/cancel performs exactly one final delete, upsert, or noop. | Repository-count controller tests. | DONE |
| BQE-03 | User §9–18, §25 E–L | `BudgetLimitQuickEditGestureController` | Direction comes from the preceding pointer position; a reversal resets travel, residual accumulator, and auto-repeat; no activation-Y zones remain. | Deterministic scheduler gesture tests, including shifted starting positions. | DONE |
| BQE-04 | User §5–6, §19, §24–25 B–C | Existing edit presentation → avatar consumer | Very-long publishes no-limit synchronously while pressed; same-pointer upward tick remounts the accepted chrome/shadow composition. | Rail widget test with real gesture/edit controller. | DONE |
| BQE-05 | User §3, §13, §17, §23, §28 | Gesture rules/controller | Existing constants, haptics, zero floor, direct RAM updates, and no-I/O move path remain intact. | Focused gesture/controller regressions and source inspection. | DONE |
| BQE-06 | User §31–33 | Delivery | Format, analyze, focused/broader regressions, focused commit/push, successful normal APK, download and SHA-256. | 48 focused tests, 248 fast regressions, `flutter analyze`; `Fluvi Verification` run `32218839780`; downloaded APK SHA-256 `aa17938c63d2987d0ce23987beb6309631d8eaa44dff5d5a7d41efd1e6c7d899`. | DONE |

## Compact architecture card

- Existing owner: `BudgetLimitQuickEditGestureController` owns pointer deltas, epochs, timers and haptic calls; `DashboardBudgetLimitEditController` is the single owner of the optimistic session draft and release/cancel persistence intent.
- Existing shared mechanism: the existing `BudgetLimitQuickEditRules` stays the sole owner of the approved thresholds and interval formula; it is extended from activation-relative to direction-epoch inputs, not copied into a consumer.
- Single write path: `finishEdit` (and existing cancel finish path) queues the one final repository operation. Pointer-move and very-long clear only publish RAM state.
- Focused verification: deterministic gesture scheduler tests, controller persistence-count tests, and the existing rail widget test for pressed/no-limit/positive-limit composition.
