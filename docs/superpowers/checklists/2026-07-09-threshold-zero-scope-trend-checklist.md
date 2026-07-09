# Unified Sparse Scope Trend Checklist

Sources:
- User report on 2026-07-09 after latest screenshot `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-091845.png`:
- Threshold is `0`.
- Expected: the fast-food scope trend should have a readable curve, starting red/high, moving lower, middle of the year roughly comparable to the first third, and the final third improving.
- Actual: the chart shows a green/max-green plateau, so it does not reveal a trend.
- User correction on 2026-07-09:
  - "nem külön logikát akarok, mert treshold 10k-nál is ugyanez van, pedig akkor már alig van minta. új számítás kell."

Root cause found before coding:
- In `StatsCategoryScopeSeries._expenseControlData`, threshold `0` makes every active scoped day a `hit`.
- The control bars then compare single-day hit/value/impact values against low year averages, so active days saturate and inactive days collapse toward full green.
- The same daily impulse problem appears at sparse positive thresholds such as `10 000`, because only a few days contribute and the chart becomes dominated by spikes/empty-day plateaus.
- The fix must be one unified expense control calculation for every threshold, not a separate `threshold == 0` branch.

| ID | Source Instruction | Code Area | Acceptance Condition | Verification Method | Status |
| --- | --- | --- | --- | --- | --- |
| UST-001 | User: "nem külön logikát akarok" | `lib/features/stats/data/stats_category_scope_series.dart` | Expense category scope uses the same rolling behavior-pressure calculation for threshold `0` and positive thresholds. | RED/GREEN unit tests cover `0` and `10 000`; `rg` verifies the old thresholdless/spike helpers are gone and only one rolling expense control path remains. | DONE |
| UST-002 | User: threshold 0 should show trend, not max-green plateau | `stats_category_scope_series.dart` | Threshold `0` produces a non-flat curve: first third high/red, middle comparable when rarer but pricier, final third lower/green when rarer and cheaper. | `flutter test test/stats/stats_category_scope_series_test.dart --reporter compact` covers third averages and colors. | DONE |
| UST-003 | User: threshold 10k has the same sparse-sample issue | `stats_category_scope_series.dart` | Threshold `10 000` sparse sample produces a smooth middle-year pressure curve instead of isolated spikes/empty plateau, with final third lower than the threshold-hit period. | `sparse positive threshold also uses rolling behavior pressure` regression test in `test/stats/stats_category_scope_series_test.dart`. | DONE |
| UST-004 | User: "új számítás kell" | `stats_category_scope_series.dart` | The orange secondary line is also derived from rolling behavior pressure for all expense thresholds, not raw daily hit severity only. | Unit tests check non-flat values and lower final third for both `0` and `10 000`; old spike-severity helpers removed. | DONE |
| UST-005 | Existing behavior | stats tests, analyzer | Income logic, render mode sheet, chart layout, and non-category stats remain intact. | `flutter test test/stats/stats_category_scope_series_test.dart test/stats/stats_page_test.dart --reporter compact` passed 31/31; `flutter analyze` reported no issues. | DONE |
