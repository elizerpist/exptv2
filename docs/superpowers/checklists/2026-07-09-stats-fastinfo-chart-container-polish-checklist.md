# Stats FastInfo Chart Container Polish Checklist

Source: user request on 2026-07-09 after inspecting the latest stats FastInfo screenshot.

Inspected visual reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260708-225809.png`.

| ID | Source instruction / approved reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| FIP-001 | User: "a naran ssárga vonalaknál nincs élaimítás a bevételben" | `StatsFastInfoGraph`, category secondary line painter | The orange secondary line in category scope is rendered as a smoothed curve, including income mode sparse samples, instead of a jagged polyline. | RED/GREEN layout/style test plus direct code inspection of `_smoothPathForValues`. | DONE |
| FIP-002 | User: "az alsó chart legyen kisebb, a felső nagyobb" | `StatsFastInfoLayout` category chart geometry | Category scope uses a dominant top chart and a compact lower chart. | RED/GREEN widget geometry test on `StatsFastInfoGraph.layoutForTesting`. | DONE |
| FIP-003 | User: "az y tengelyt sk@l@zd be, legalább 1-2 összeggel" | `StatsFastInfoGraph` axis drawing | The category secondary Ft chart draws numeric y-axis scale labels with at least two amount values. The control chart keeps readable 100/50/0 reference labels. | RED/GREEN visual-style contract test plus direct code inspection of `_drawAmountAxisValueLabels` and `_drawControlAxisValueLabels`. | DONE |
| FIP-004 | User: "az y tengely címe ne a screen határ mellett legyen, hanem az y tengely mellett" | `StatsFastInfoLayout`, `_drawAxisLabels` | Category y-axis title and value labels are positioned beside the chart axis inside the shared chart panel, not flush with the screen edge. | RED/GREEN layout geometry test. | DONE |
| FIP-005 | User: "a legendek mi dkét grafikonon legyenek 20% nagyobbak" | `_drawLegend`, chart visual constants | Legends use 20% larger text and marker sizing on both category charts. | RED/GREEN visual-style contract test. | DONE |
| FIP-006 | User: "egy fehér containerbe rakd bele a grafikonokat, egy közös rounded square, valamennyi paddinggal a screen szélétől" | `StatsFastInfoLayout`, `_drawCategoryScope` | Both category-scope charts are drawn inside one shared white rounded rectangle with screen-edge padding. | RED/GREEN layout geometry test plus direct code inspection of `_drawCategoryPanel`. | DONE |
| FIP-007 | Existing stat FastInfo requirements and approved behavior | stats tests, analyzer | Existing heatmap/closing/category metadata and stats page behavior remain intact. | `flutter test test/stats/stats_page_test.dart`; `flutter analyze` in Ubuntu proot. | DONE |
