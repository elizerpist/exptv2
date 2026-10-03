# Mind Year scope totals and Day dual-layer bars implementation plan

**Goal:** Add live slider-filtered monthly metadata to Mind Year 4×3, move Year layout choice to persisted Settings only, and render Mind Day hourly activity as a truthful two-layer full-versus-filtered comparison.

**Architecture:** `MindYearHeatmapPresentationController` remains the single presentation-state owner. `DashboardPresentationPreferences` persists the two user choices that must survive restart: the existing `yearGridLayout` and new `showYearFourByThreeScopeAmounts`. The Year month-header reads only the already-published `MindYearHeatmapFrame`; Day consumes only its resident full/current timeline events and shares the reference-bar geometry with the established Year-secondary mechanism.

**Constraints:** No Query/repository/index path, financial membership, slider semantics, Balance, Budget, Year secondary-card behavior, or shared interaction owner changes. The 4×3 toggle defaults to ON. Compact month totals omit the repeated `Ft` suffix.

## Architecture card

| Concern | Existing owner | Planned extension | Boundary proof |
| --- | --- | --- | --- |
| Mind presentation state | `MindYearHeatmapPresentationController` | One boolean setter for 4×3 scope-label visibility; reuse existing `yearGridLayout`. | Revision/no-op/equality tests. |
| Persisted visual preferences | `DashboardPresentationPreferences` + method channel + Android `SharedPreferences` | Persist the existing grid enum and new boolean; retire the obsolete body-action visibility preference. | Dart preference, method-channel and native-contract tests. |
| Year 4×3 month amount | `MindYearHeatmapFrame.month(month)` | Sum already preview-filtered day totals in the existing mini-header row. | Range-preview widget test and source boundary review. |
| Compact HUF copy | `formatMindCompactForints` | Add an optional currency-suffix switch, defaulting to existing behavior. | Formatter/widget assertions. |
| Year layout selection | Header tuner settings section | Radio group over the existing `MindYearHeatmapGridLayout` enum. | Settings widget and viewport routing tests. |
| Full/current bar geometry | `MindMonthlyOverlayBarPainter` | Extract its neutral-reference/full-opacity-overlay rectangle policy for Day. | Pure geometry and Year-secondary regression tests. |
| Day hourly aggregation | `MindDayHourlyComparisonProjection` | Preserve its resident full/current sums and shared full maximum; no per-bar data read. | Projection/widget tests. |

## Acceptance checklist

Status values: `NOT DONE`, `PARTIAL`, `DONE`, `BLOCKED`.

| ID | Source requirement | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| PRE-01 | Baseline | branch/worktree | `766710ea` is an ancestor; docs-only descendants retained; known user untracked material untouched. | git preflight | DONE |
| YEAR-01 | 1.1–1.3 | `mind_year_heatmap_viewport.dart` | Each 4×3 month has name left and compact live scope amount right on the same header row, same muted family, no `Ft`. | Widget geometry/text tests | DONE |
| YEAR-02 | 1.2 | Year resident frame | Values use the range-preview `MindYearHeatmapFrame.month` total and update without a query/read. | Preview regression and source boundary test | DONE |
| YEAR-03 | 1.4/3 | settings + preferences | Toggle defaults ON, revisions correctly, persists/restores, and OFF returns name-only 4×3. | Unit/preferences/tuner tests | DONE |
| YEAR-04 | 1.5 | Year viewport | The content card has no 3×4 / 4×3 / 2×6 selector, container or reclaimed dead region. | Widget/layout test | DONE |
| YEAR-05 | 1.6 | tuner + preferences | Settings-only radio selector exposes all three existing layouts, persists and immediately changes the Year viewport. | Tuner/core widget tests | DONE |
| YEAR-06 | 1.7 | Year viewport | 3×4, 4×3, 2×6 heatmap/scroll/palette semantics and Year secondary pages stay intact. | Existing regression suite | DONE |
| DAY-01 | 2.1–2.2 | shared bar geometry + Day card | Day renders exactly neutral full reference plus full-opacity filtered foreground; no translucent full palette layer or capacity track. | Painter/widget inspection | DONE |
| DAY-02 | 2.3–2.5 | Day card | Full-empty hour draws neither bar; full-only hour draws gray only; full-range color covers gray; partial range shrinks only the color. | Widget tests | DONE |
| DAY-03 | 2.6–2.9 | shared bar geometry + hourly projection | Day and Year-secondary share the two-layer geometry; full scale remains authoritative; same-hour event amounts are summed. | Pure and regression tests | DONE |
| ARC-01 | General/Part 3 | changed source | One controller, one preferences store, existing frame/event owners only; no new repository/query/slider state. | Source boundary test/review | DONE |
| VAL-01 | Part 4 | focused tests | Required new and existing Year/Day/settings/persistence tests pass after observed RED. | Ubuntu/proot runs | DONE |
| VAL-02 | Part 5 | quality gates | Format, focused/project analysis, boundary suite, diff check and relevant fast suite pass or are explicitly evidenced. | command outputs | DONE |
| REL-01 | delivery rule | GitHub Actions/APK | One application commit is pushed; normal exact-SHA Human APK is downloaded and SHA-256 verified. | GitHub + local verification | DONE |
| VIS-01 | visual acceptance | Android device | Installed-device visual acceptance of the changed Year/Day states. | User device evidence | BLOCKED — USER ONLY |

## Validation evidence

- RED evidence: the new Year scope-total endpoint, Settings grid option and Day reference-bar assertions each failed before the implementation.
- Focused Green evidence: Year viewport, 4×3/2×6 goldens, Day dual-layer card, hourly aggregation, settings/persistence, Settings tuner, Year host and Year-secondary overlay tests passed in Ubuntu/proot.
- `./scripts/test-fluvi-fast.sh` passed **434** tests.
- Changed-source Dart analysis reported no issues. Project `flutter analyze --no-pub --no-fatal-infos` reported one pre-existing unrelated `unnecessary_import` info in `dashboard_balance_daily_insights_projection_test.dart`.
- The full tuner file has an unrelated existing Balance expectation failure at line 524 (`balance-unified-body-layout`) that is outside this diff; the changed Mind Settings test passes in isolation.

## Ordered execution

1. Add failing settings, persistence, Year viewport and Day two-layer tests; run them against `6ad5fe4d` and retain the expected RED evidence.
2. Implement the smallest presentation-only settings/persistence changes, then the Year header and Settings-only layout selection.
3. Extract the common full/current rectangle geometry from the Year-secondary painter; replace Day's three nested visual layers with it.
4. Run focused GREEN tests, existing Year-secondary/viewport regressions and source-boundary checks; inspect the compact narrow layout.
5. Run formatting, analysis and the repository fast suite; verify every checklist item before the application commit.
6. Push the one application commit, deliver its exact normal Human APK, regenerate exact-SHA SCIP, then record factual journal evidence in a separate docs-only `[skip ci]` commit.
