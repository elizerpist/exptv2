# Mind expanded temporal cards — acceptance checklist

| ID | Source / reference | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-01 | approved expanded prompt | projections + viewports | Frames remain the single resident read source; no Query/repository write path | domain/boundary test + inspection | NOT DONE |
| ARC-02 | all three PNG references | shared chart / card primitives | Existing chart, palette, formatter, and anchored-popup mechanism are reused centrally | widget tests + inspection | NOT DONE |
| SUM-01 | prompt §5 | Sum viewport | Pages are heatmap, exact yearly line, preserved multi-line in that order | widget pager test | PARTIAL |
| SUM-02 | `mindsumlinechart.png` | aggregate chart | One annual aggregate point/year, min slot width + scroll, selected bounded popup and compact axis | domain/widget/reference check | PARTIAL |
| SUM-03 | prompt §5B–C | Sum viewport/settings | 2-row / year-left-strip-amount-right layout, aligned label locations, cell-anchored month popup | widget geometry/tap test | PARTIAL |
| YEAR-01 | prompt §6A | Year viewport | Height parity; month-card interaction absent; colored day popup follows actual cell | widget geometry/tap test | PARTIAL |
| YEAR-02 | prompt §6B–C | Year viewport/chart | Partial overlay bars remain; new 12-point aggregate line fits no-scroll and selects bounded popup | widget/domain test | PARTIAL |
| MONTH-01 | `havi.png` | Month frame/viewport | Secondary daily rhythm page has bounded daily bars, average reference, summary tiles and range response | domain/widget/reference check | NOT DONE |
| DAY-01 | `napi.png` | Day frame/viewport | Secondary timeline uses actual resident timestamps/amounts, time axis, markers, legend and summary tiles | domain/widget/reference check | NOT DONE |
| GEST-01 | prompt §11 | pager/chart/footer | Page, inner chart scroll, RangeSlider and clean tap each have one owner | widget gesture tests | NOT DONE |
| LEGEND-01 | approved prior contract | Mind surface/footer | Single always-visible inline legend; no user setting/top lane regression | existing focused test | DONE |
| BNB-01 | approved prior contract | shell/navigation | Raised and contained-flat nav choices remain selectable | existing focused test | DONE |
| SAFE-01 | milestone 6e96218 | protected systems | No Time/Avatar/Query/Room/score/schema changes | diff + boundary verification | NOT DONE |
| DELIVERY-01 | AGENTS.md/prompt | commits/journal/CI | Journal after each app commit; tests, analyzer, online APK and exact SCIP evidence | command/output audit | NOT DONE |

