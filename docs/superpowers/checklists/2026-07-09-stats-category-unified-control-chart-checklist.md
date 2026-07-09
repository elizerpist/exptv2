# Stats Category Unified Control Chart Checklist

Source: user decisions on 2026-07-09:

- Expense keeps the current histogram component math, but the chart should show stronger visual swings.
- Expense orange line should be smoothed, dashed, and represent normalized spike severity, not a concrete HUF value.
- Income needs a separate income-health logic so the chart and magnet strip tell the same story.
- Category-scope FastInfo should become one shared large chart inside the existing white rounded container.

Visual references inspected:

- `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-064807.png`
- `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-070856.png`

| ID | Source instruction / approved reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| UCC-001 | User accepted: current histogram math remains, larger swings | `StatsFastInfoGraph`, category chart painter | Expense histogram keeps raw `0.35/0.35/0.30` control math, but drawing applies a documented visual emphasis around the neutral 50 baseline. | RED/GREEN visual-style test for `60 -> 80` mapping and targeted widget tests. | DONE |
| UCC-002 | User: "a narancs függvény ne szám legyen ... kiugrás mértékét mutassa" | `StatsCategoryScopeSeries` | Expense secondary line returns normalized spike-severity index values from 0 to 100, not HUF amounts or Ft/kiugrás. | RED/GREEN series unit test. | DONE |
| UCC-003 | User: "a narancs függvény szaggatott vonal legyen" | `StatsFastInfoGraph` painter | Category secondary line is drawn as a dashed orange line on the same chart as the histogram. | RED/GREEN visual-style contract test plus code inspection of `_drawDashedPath`. | DONE |
| UCC-004 | User: "a két függvényt rakd egy grafikonba" | `StatsFastInfoLayout`, `StatsFastInfoSpec`, `StatsFastInfoGraph` | Category-scope FastInfo has one large chart inside the shared white rounded container; no separate lower Ft chart is rendered. | RED/GREEN metadata/layout tests. | DONE |
| UCC-005 | User: income screenshot shows magnet near 50 but graph tells something else | `StatsCategoryScopeSeries`, `stats_page.dart` | Income category-scope uses income-health control bars and magnet score from the same income-health series. | RED/GREEN income series unit test. | DONE |
| UCC-006 | User: income orange line should not be raw Ft | `StatsCategoryScopeSeries`, `StatsFastInfoGraph` | Income secondary orange line is a normalized deviation/concentration index, not Ft/active-day. | RED/GREEN income series unit test and metadata test. | DONE |
| UCC-007 | Existing stats behavior | stats tests, analyzer | Heatmap, closing, month cards, scope sheet, header pull, focus navigation remain intact. | `flutter test test/stats/stats_category_scope_series_test.dart test/stats/stats_page_test.dart`; `flutter analyze`. | DONE |
