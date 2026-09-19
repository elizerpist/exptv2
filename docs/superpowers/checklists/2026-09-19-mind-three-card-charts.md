# Mind three-card charts and cell inspection — acceptance checklist

**Reference:** `/storage/emulated/0/spendee/reference/mindsumlinechart.png`.

| ID | Requirement | Owner | Verification | Status |
| --- | --- | --- | --- | --- |
| SUM-STACK-01 | Sum pages are heatmap, yearly exact line, preserved daily multi-line in that order | Sum viewport | mounted pager RED→GREEN | DONE |
| SUM-YEAR-01 | one aggregate point per continuous represented year, including internal zero years | Sum projection | domain test | DONE |
| SUM-YEAR-02 | exact chart uses filter/direction/range preview and no raw transaction plot | projection/chart | domain + widget tests | DONE |
| SUM-YEAR-03 | reference-family line, fill, axes, point tooltip and bounded wide-year scroll | shared chart primitive | widget/golden/gesture tests | PARTIAL |
| SUM-PRESENT-01 | two-row and one-row Sum year styles are selectable without Query mutation | Mind settings/controller | settings + mounted test | DONE |
| SUM-PRESENT-02 | none/below/inside Hungarian month labels are selectable and bounded | Sum heatmap | mounted geometry test | DONE |
| SUM-MONTH-01 | clean month-cell tap opens/moves one bounded month infocard | shared tap/popup + Sum viewport | mounted tap test | DONE |
| YEAR-STACK-01 | Year pages retain heatmap and bars and add monthly line page | Year viewport | mounted pager test | DONE |
| YEAR-LINE-01 | line has twelve current filtered/range-preview month aggregates | Year frame/chart | domain + widget test | DONE |
| YEAR-LINE-02 | chart-point tap selects one bounded month infocard | shared chart primitive | mounted tap test | DONE |
| YEAR-DAY-01 | MonthCard inspection tap is absent; only non-empty day cells select a day infocard | Year heatmap | mounted interaction test | DONE |
| GESTURE-01 | slider, page swipe, chart scroll, heatmap/day/point tap and vertical handoff have one effective owner | pager/tap primitive | parent gesture tests | PARTIAL |
| SAFE-01 | no duplicate Query/data owner; no protected motion/data architecture change | all | source/boundary audit | DONE |
| DELIVERY-01 | focused suites, analyzer, CI/APK and exact-source SCIP are recorded | delivery | command/Actions/manifest evidence | PARTIAL |
| PHYSICAL-01 | exact APK is tested by the user on Android | user | user validation | NOT DONE |
