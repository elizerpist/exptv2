# Threshold Zero Scope Trend Checklist

Source: user report on 2026-07-09 after latest screenshot `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-091845.png`:
- Threshold is `0`.
- Expected: the fast-food scope trend should have a readable curve, starting red/high, moving lower, middle of the year roughly comparable to the first third, and the final third improving.
- Actual: the chart shows a green/max-green plateau, so it does not reveal a trend.

Root cause found before coding:
- In `StatsCategoryScopeSeries._expenseControlData`, threshold `0` makes every active scoped day a `hit`.
- The control bars then compare single-day hit/value/impact values against low year averages, so active days saturate and inactive days collapse toward full green.
- This is daily impulse math, not thresholdless behavior trend math.

| ID | Source Instruction | Code Area | Acceptance Condition | Verification Method | Status |
| --- | --- | --- | --- | --- | --- |
| TZS-001 | User: threshold 0 should show trend, not max-green plateau | `lib/features/stats/data/stats_category_scope_series.dart` | For expense category scope with threshold `0`, control bars use rolling activity/amount pressure instead of single-day hit math. | RED/GREEN unit test in `test/stats/stats_category_scope_series_test.dart`. | DONE |
| TZS-002 | User: first third frequent ~5k, middle rarer but pricier, final rarer and cheaper | `stats_category_scope_series.dart` | A synthetic 2025-like sample yields high/red pressure in the first third, comparable pressure in the middle, and lower/green pressure in the final third. | RED/GREEN unit test averages control values by thirds and checks colors. | DONE |
| TZS-003 | User: "szép ív" instead of plateau | `stats_category_scope_series.dart` | Threshold-zero secondary orange line is based on smoothed rolling activity pressure, not daily min/max active amount spikes. | RED/GREEN unit test checks multiple non-flat values and final third lower than first/middle. | DONE |
| TZS-004 | Existing behavior | stats tests, analyzer | Threshold > 0 category spike logic, income logic, render mode sheet, and chart layout stay intact. | `flutter test test/stats/stats_category_scope_series_test.dart test/stats/stats_page_test.dart --reporter compact`; `flutter analyze`. | DONE |
