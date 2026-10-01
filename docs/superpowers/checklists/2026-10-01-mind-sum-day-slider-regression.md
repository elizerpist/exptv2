# Mind SUM/Day geometry, layering and slider regression checklist

Status values: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

## Mandatory visual sources

- Current broken SUM screenshot:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261001-174319.png`
- SUM-A source of truth:
  `/storage/emulated/0/spendee/source of truth/suma.png`
- SUM-B source of truth:
  `/storage/emulated/0/spendee/source of truth/sumb.png`
- Day source of truth:
  `/storage/emulated/0/spendee/source of truth/napiheatmap.png`

The references are development/verification inputs only. Production widgets may
not display or embed any PNG asset.

## Explicit visual overrides from the user

- Although `suma.png` visibly contains 3×4 / 4×3 / 2×6 controls, the shipped
  SUM-A and SUM-B reference renderers must expose **no** such control and must
  use the fixed four-column, three-row month grid.
- Although `napiheatmap.png` visibly contains a palette-scale legend, the
  shipped Day surface must omit that redundant legend. The retained two-item
  comparison legend is semantically different and remains required.

## Architecture card

| Concern | Single owner / write path | Consumers | Boundary proof |
| --- | --- | --- | --- |
| Canonical range query | existing `CoreDashboard` → `DashboardCoreController` interaction pipeline | Summary pill, transaction list, Mind frames | slider preview/commit regression test proves the same canonical range updates all consumers |
| Mind preview frames | existing live temporal/annual heatmap projection owners | SUM, Year, Month, Day renderers | only resident-frame projections occur during drag; no duplicate query owner |
| SUM visual heat intensity | shared Mind heatmap palette/intensity resolver | SUM-A, SUM-B, Year, Month, Day | range-preview fixtures prove year cards and month cards change from the same frame |
| Temporal content geometry | shared Mind temporal content/body layout contract | SUM, Year, Day | constrained RenderBox tests prove one body bottom/slider/footer seam and no nested false card |
| Day rhythm stacks | immutable Day frame + pure three-layer visual projection | Day heatmap renderer | full/filtered scale behaviour is covered without repository work |

UI only renders immutable frames and forwards range intents. It must not own a
second query/filter, a second slider state, or a parallel timeline data source.

## Acceptance checklist

| ID | Requirement / source | Intended owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| SUMFIX-01 | SUM-A has exactly 12 month cards per year in a fixed four-column by three-row grid; no 3×4/4×3/2×6 chooser | `MindSumReferenceSurface` | constrained widget/RenderBox test: 12 visible cells, fixed 4 columns; chooser absent | DONE |
| SUMFIX-02 | SUM-A and SUM-B remove the duplicated/nested false lower card above the functional slider; body bottom matches Year body/slider seam | shared temporal-body layout | the native source surfaces now return body content only; constrained and production mode-host tests cover the shared footer envelope | DONE |
| SUMFIX-03 | SUM year and month cards use the live canonical slider preview intensity, not static colours | shared heat palette/intensity resolver | both A/B month cells and SUM-B identity/mother-card gradients are range-frame palette consumers in widget tests | DONE |
| DAYFIX-01 | Day removes the redundant heatmap-scale legend above the slider | Day source card | only the required comparison legend/control composition remains | DONE |
| DAYFIX-02 | Day removes the false rounded card bottom below the slider; useful body area and footer seam match Year | shared temporal-body layout | the Day source is body-only within the common seamless shell; constrained and mode-host coverage passes | DONE |
| DAYFIX-03 | Day source-card heatmap uses the current reactive heatmap colour scale | shared palette resolver | scoped dynamic-palette fixture proves displayed selected colour uses the resolver | DONE |
| DAYFIX-04 | Day rhythm has three real layers: equal-height neutral grey capacity bars, full-day current heatmap-colour amount bars at reduced opacity, and selected-range heatmap-colour bars at full opacity | Day frame + pure layer projection + renderer | deterministic projection/widget fixtures assert height, colour, opacity and selected-only shrink behavior | DONE |
| SLIDER-01 | Restore the pre-regression immediate slider filtering: Summary pill, transaction list and every Mind time mode update during range preview | existing `CoreDashboard`/controller preview pipeline | mounted Core regression proves preview updates all existing consumers before release | DONE |
| SLIDER-02 | Do not introduce a second data/query path; preview work stays resident/presentation-only and commit retains existing canonical write path | existing controller/live projections | source/history audit plus resident-frame/domain tests prove no new query/repository/index path | DONE |
| SAFE-01 | Preserve Avatar/time navigation, shared PageView/ScrollPosition identities and Balance/Budget paths | scoped app surfaces | full Core regression (109) and the fast suite (434) pass; diff is constrained to Mind surfaces/tests | DONE |
| VIS-01 | Reinspect SUM-A/SUM-B/Day source PNGs and the final changed screenshot before build | verification | all three sources were reopened and no raster shortcut exists; final installed-APK screenshot remains **PENDING — USER ONLY** because no Android device is attached | PARTIAL |
| REL-01 | One final application commit, online Human Diagnostic APK and separately committed factual journal | delivery | app `0af5e1ff10a883099f62359b007e904450d5f9e7`; Actions `36901121612` correctness/core/Human-APK gates PASS; journal delivery record pushed separately | DONE |

## Delivery evidence

- **Application commit:** `0af5e1ff10a883099f62359b007e904450d5f9e7` — `fix(mind): restore live sum and day range presentation`.
- **Online workflow:** [36901121612](https://github.com/elizerpist/exptv2/actions/runs/36901121612), targeting the exact application SHA. `dashboard-paths`, `test-flutter`, `test-core`, and `build-human-diagnostic-apk` passed. The independent dashboard-profile job was still running when the factual delivery record was prepared; it is not a substitute for the normal correctness or Human APK gates.
- **Human APK:** GitHub release `fluvi-human-diagnostic-0af5e1f`, asset `fluvi_HUMAN_DIAGNOSTIC_0af5e1f.apk`; downloaded to `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_0af5e1f.apk`. Size: `89,112,183` bytes. SHA-256: `a67a38596c6de7753f5e45af087fd6097e33d329d4e15fcdc84e3649375129d8` (matches the release digest). Its ARM64 `libapp.so` contains the exact full `FLUVI_BUILD_COMMIT` `0af5e1ff10a883099f62359b007e904450d5f9e7`.
- **Physical/visual boundary:** the references were inspected and production uses real Flutter rendering, but final installed-APK screenshot comparison and gesture acceptance remain **PENDING — USER ONLY**. `VIS-01` intentionally remains `PARTIAL`.
