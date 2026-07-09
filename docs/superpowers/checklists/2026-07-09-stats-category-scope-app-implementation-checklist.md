# Stats Category Scope App Implementation Checklist

Source: user request on 2026-07-09: "a kiadási és bevételi category scopeot implementáld exact 100%. explicit módon. az appban azt akarom látni mint a megbeszélt 2 html ben".

Mandatory visual/math references:
- Expense/category-scope reference: `docs/prototypes/stats_fastfood_2025_sim.html`
- Expense/category-scope prototype checklist: `docs/superpowers/checklists/2026-07-09-stats-fastfood-html-simulation-checklist.md`
- Income/category-scope reference: `docs/prototypes/stats_income_2025_sim.html`
- Income/category-scope prototype checklist: `docs/superpowers/checklists/2026-07-09-stats-income-html-simulation-checklist.md`

Implementation target files:
- Model/math: `lib/features/stats/data/stats_category_scope_series.dart`
- Year data threshold/month support: `lib/features/stats/data/stats_year_data.dart`
- FastInfo painter/layout: `lib/features/stats/widgets/stats_fast_info_graph.dart`
- Header score/magnet binding: `lib/features/stats/stats_page.dart`
- Tests: `test/stats/stats_category_scope_series_test.dart`, `test/stats/stats_page_test.dart`, `test/stats/stats_year_data_test.dart`

| ID | Source Instruction / Reference | Intended Code Area | Acceptance Condition | Verification Method | Status |
| --- | --- | --- | --- | --- | --- |
| CSA-001 | "appban azt akarom látni mint a ... stats_fastfood_2025_sim.html" | `StatsCategoryScopeSeries` expense branch | Expense category scope crops from first threshold-hit day to last threshold-hit day; no empty year tail is drawn. Dense mode uses centered 31-day rolling occurrence + amount, EMA, normalized 0..100, pressure `0.5 occurrence + 0.5 amount`, score `100-pressure`. Sparse mode (`<=12` hits) uses only real hit days and real date positions. | Failing-then-passing unit tests cover dense crop, sparse two-hit mode, and endpoint score. | DONE |
| CSA-002 | Fastfood checklist FHS-023/FHS-024 | `StatsCategoryScopeSeries` expense helper bars + painter | Expense lower helper chart uses only real threshold-hit sample bars. `threshold > 0`: `max(0, amount-threshold)` normalized to visible max excess. `threshold <= 0`: min-baseline fallback. No synthetic filler bars. | Unit tests inspect helper bar raw values/deltas/count; painter metadata/layout tests inspect helper chart. | DONE |
| CSA-003 | Fastfood checklist FHS-030/FHS-044 | `StatsFastInfoGraph` layout/painter | Expense FastInfo panel matches HTML at 412px: panel `{14,42,384,268}`, title at `(47,64)`, legend `y=81`, main chart `{47,104,337,126}`, helper `{47,264,337,26}`, month label font `7.4`. | Widget/layout tests with `Size(412,328)` assert exact geometry and metadata. | DONE |
| CSA-004 | Fastfood checklist FHS-043 | `StatsPage` header | Expense category scope header label is `SCOPE SCORE`, value is score-only like `85/100`, and magnet marker follows the same latest score endpoint. | Widget/unit tests inspect rendered header text and marker position. | DONE |
| CSA-005 | "appban azt akarom látni mint ... stats_income_2025_sim.html" | `StatsCategoryScopeSeries` income branch | Income category scope graph months are dynamic by transaction threshold: threshold `0` includes months with income; threshold `>0` includes only months with at least one threshold-hit day. Main score uses app-current income health formula from the HTML and exposes endpoint score as header/magnet value. | Failing-then-passing unit tests cover month filtering, income score values, and endpoint score. | DONE |
| CSA-006 | Income checklist IHS-011 | `StatsCategoryScopeSeries` income helper bars + painter | Income lower chart uses average-deviation bars from visible threshold-filtered monthly totals. Center `0` is visible sample average; above-average bars are green, below-average bars are red; height/opacity follow normalized absolute deviation. | Unit tests inspect helper deltas/colors/count and painter metadata. | DONE |
| CSA-007 | Income checklist IHS-013/IHS-014 | `StatsFastInfoGraph` layout/painter | Income FastInfo panel matches accepted HTML: upper title draw y uses `titleDrawY = titleY + 5`, `upperLift = 12`, lower chart remains fixed, and upper chart/legend do not overlap lower title. | Layout tests assert the income category-scope geometry at `Size(412,328)`. | DONE |
| CSA-008 | Income checklist IHS-010 | `StatsPage` header | Income category scope header label is `INCOME SCORE`, value is score-only like `77/100`, and magnet marker follows the visible score endpoint, not the old aggregate income score. | Widget/unit tests inspect header text and marker position. | DONE |
| CSA-009 | Existing app behavior | `StatsYearData`, `StatsYearCalendar`, `StatsPage` | Existing all-scope semantics remain: empty selected category set means ALL categories, selected set means multi-category scope. Monthcards keep threshold circles consistent with the active type and threshold. Focus/heatmap/closing are not changed by this category-scope implementation. | Existing stats tests plus targeted category-scope tests pass. | DONE |

## Verification Evidence

- `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_category_scope_series_test.dart test/stats/stats_page_test.dart && /home/flutteruser/flutter/bin/flutter analyze'`
  - Result: 32 tests passed; `No issues found!`
- `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats'`
  - Result: 48 tests passed.
