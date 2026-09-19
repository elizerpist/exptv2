# Mind paging, fixed legend, height parity, and BottomNav style — acceptance checklist

**Status vocabulary:** `NOT DONE`, `PARTIAL`, `BLOCKED`, `DONE`. A row is `DONE` only when its named verification has been run and recorded. This is a new feature/presentation checklist; it does not re-open the completed Day→Month forensic work.

**Sources:** user-approved feature contract dated 2026-09-19; engineering-journal entry “Mind card paging/charts, fixed legend, annual height parity, and contained BottomNav feature contract”; inspected Android screenshots `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260919-122424.png` and `Screenshot_20260919-122418.png`; application source `5893b4568f7061c6e643e7ce767ac76716c7c8d1`; matching SCIP tooling `2433548f311fd23711da28ec957b90f39b34560a`.

## Architecture card

| State / mechanism | Existing single owner | Required invariant / reuse decision | Verification |
| --- | --- | --- | --- |
| Mind palette and legend presentation | `MindYearHeatmapPresentationController` + `MindYearHeatmapPaletteResolver` | Remove obsolete visibility/placement writes; keep scale and one resolver-owned inline legend | settings + mounted all-plane tests |
| Range input/data | `QueryAmountRangeControl` | One existing compact element remains below pager; Mind supplies only inert legend child | element identity + drag test |
| Sum financial series | `MindSumHeatmapProjection` | Extend the resident range-bucket projection with immutable local-day samples; no repository/raw-row/UI scan | domain range-preview and Core counter tests |
| Year full/filtered comparison | `MindYearHeatmapFrame` | background from `monthlyAggregates`; foreground from current `frame.month(month)` days; no second Query | frame/widget math tests |
| Page selection | Mind viewport-local state | `PageController` is presentation-only; it cannot write Query/Time/prepared frames and never covers footer | mounted gesture/no-mutation test |
| BottomNav style | `DashboardShellPresentationController` | One presentation setting selects existing raised geometry or alternate contained physical geometry | controller, bounds and raster tests |

## Final permanent inline legend

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LEGEND-FINAL-01 | §1, §14A | `mind_year_heatmap_presentation_settings.dart` | no `showHeatmapLegend`, placement enum, or setter/write path remains | settings unit test + source search | DONE |
| LEGEND-FINAL-02 | §1 | tuner + Mind surface | no visibility/placement controls and no above-slider lane mount | widget finder test | DONE |
| LEGEND-FINAL-03 | §§1,12 | range/surface | exactly one 10/20 resolver-owned inline legend is always between Min/Max in Sum/Year/Month/Day; the RangeSlider element remains stable | mounted all-plane + identity test | DONE |
| LEGEND-FINAL-04 | §§1,15 | resolver/range | scale/palette changes alter legend samples only through existing resolver and do not change frame, Query or Time | resolver + Core isolation test | PARTIAL — mounted palette/scale and range-identity coverage is green; final Core isolation is deferred to pager units. |

## Annual height parity

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| YEAR-HEIGHT-01 | §§2,8B | settings/Core geometry | 3×4 and 4×3 Mind Year outer/content envelope heights are equal; no four-column +50 extension | production-parent bounds RED→GREEN | DONE |
| YEAR-HEIGHT-02 | §13B | Year viewport | four-column still paints 12 cards in three rows and retains zero-scroll fit | mounted row/scroll test | DONE |
| YEAR-HEIGHT-03 | §§2,13B | Year viewport | reference-width MonthCard and day-cell extents do not decrease to obtain parity; final row stays bounded above footer | before/after rect assertions | PARTIAL — production-parent test locks the 83.5px reference width and its 8.5px width-derived cell authority; device rect comparison remains pending. |

## Sum pager and multi-year views

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUM-PAGER-01 | §§3,12 | Sum viewport/surface | page 0 starts heatmap, horizontal visual-region swipe reaches page 1 and reverse retains page-0 scroll state | mounted pager test | DONE |
| SUM-PAGER-02 | §§3,12,15 | pager/range | slider horizontal drag cannot page; visual page changes preserve Query, Time and prepared-frame identity and create no duplicate owner | production-parent gesture/counter test | PARTIAL — slider/page gestures, range-element identity and admitted-frame identity are green; direct Core Query/Time mutation counters remain final-package evidence. |
| SUM-HEATMAP-01 | §§3,13C | Sum viewport | title is `Többéves aktivitás`, subtitle is exact represented period/month count, no `Éves aktivitás` remains | widget text test | DONE |
| SUM-HEATMAP-02 | §13C | Sum viewport/formatter | each year is header row (year left, rounded compact amount right) plus one full-width twelve-cell row; examples format 7,728,364 as `7,73 M Ft` and 645,560 as `646 k Ft` | widget + formatter test | DONE |
| SUM-LINE-01 | §§4,14D | temporal projection | per-year immutable real local-day series derives from prepared membership and range bucket preview; it contains no fabricated transaction | domain RED→GREEN | DONE |
| SUM-LINE-02 | §§4,13E | Sum chart painter | page 1 paints monthly dashed separators, month-centre markers, continuous real anchors and clipped downward transparent area fade | mounted geometry/golden test | PARTIAL — mounted painter/anchor tests are green; focused raster/golden evidence remains pending. |
| SUM-LINE-03 | §§4,15 | Sum projection/Core | range/focus/direction updates follow current frame identity with no repository/index/raw-ledger scan | projection counter/Core test | PARTIAL — immutable range-bucket counter proves preview avoids a second contribution scan; final Core counter evidence remains pending. |

## Year overlay-bar page

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| YEAR-BAR-01 | §§4,13E | Year viewport/read model | page 1 has exactly 12 aligned background/foreground bars; gray background uses selected-direction full `monthlyAggregates` | mounted income/expense test | DONE |
| YEAR-BAR-02 | §§4,14E | Year viewport | foreground is current `frame.month(month)` sum, including focus/search and amount preview; no filter fully covers background | filter/range math test | DONE |
| YEAR-BAR-03 | §13F | chart scale | zero totals are safe; monthly initials, zero baseline, readable nice full-total scale and horizontal grid lines render | pure scale + widget test | PARTIAL — pure zero-based nice scale and mounted month initials/grid paint are green; focused raster/golden review remains pending. |
| YEAR-BAR-04 | §§4,15 | ownership | preview is read-only bounded frame derivation; no second Query/repository/raw-row scan | counter/source audit | PARTIAL — page-two range-preview test consumes only a replacement immutable frame; final Core/repository counter evidence remains package-level work. |

## Additive BottomNav style

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BOTTOMNAV-01 | §§5,14F | shell settings/controller/tuner | `raisedFab` remains default/selectable and `containedFlat` is selectable | controller + tuner test | DONE |
| BOTTOMNAV-02 | §§5,13G | BNB-03 | raised variant keeps 75px bar, 24px overflow, 84px ring and current contour/raster behavior | existing regression/raster test | DONE |
| BOTTOMNAV-03 | §§5,12 | BNB-03 | contained variant has horizontal central top edge, zero FAB overflow and a smaller visible circle wholly in bar | bounds/contour and focused raster tests | DONE |
| BOTTOMNAV-04 | §§5,13G | BNB-03 | contained FAB hit/semantics target is at least 48px; item actions, edge-shape/top-border and safe area remain correct | semantics/interaction/SafeArea widget test | DONE |

## No-touch, delivery and evidence

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SAFE-PAGE-01 | §§11,15 | protected owners | no Time/Avatar physics/controller/position, Query semantics, score, Budget, LogBox, Room/Kotlin/schema or milestone diff | diff/boundary audit | NOT DONE |
| SAFE-PAGE-02 | §§12,15 | gesture/data boundaries | one effective pointer owner; pager visual-only; no second slider, Query controller or data store | parent widget tests + source review | PARTIAL — Sum parent tests cover slider/page/vertical ownership; all-unit audit remains pending. |
| VAL-PAGE-01 | §§13,16 | all units | every production unit has an observed RED then GREEN test and its app commit has a separate file-only journal evidence commit | test/commit audit | PARTIAL — Units 1–3 are committed and separately journaled; Unit 4 has observed RED→GREEN and awaits its application/journal commits. |
| VAL-PAGE-02 | §§17,19 | delivery | required focused suites, analyzer, fast/boundary checks, exact final CI/APK and exact-source SCIP are truthfully recorded | command/Actions/manifest evidence | NOT DONE |
| VAL-PAGE-03 | §§4,20 | physical | device visual/touch acceptance is not self-approved | user validation | NOT DONE |
