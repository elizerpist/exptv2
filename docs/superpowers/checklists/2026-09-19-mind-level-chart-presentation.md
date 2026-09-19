# Mind level transition, chart inspection, and presentation controls — acceptance checklist

**Status vocabulary:** `NOT DONE`, `PARTIAL`, `BLOCKED`, `DONE`. A row is `DONE` only with the named evidence. This checklist supersedes no prior completed requirement; it adds the 2026-09-19 level-transition and presentation scope.

**Sources:** user implementation specification §§1–21; Drive `Fluvi mind heatmap` revision 6 (`1R2plbzazBUuuWoi_unktR_Lu7QNYgM9RPIH5J6ioNIM`, SHA-256 `46682010d3a002a7b2eafc9414cc55c5d2bc71e355aef198c8e10990cb8daa95`); screenshot `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260919-073848.png`; source `c1b12ade`; journal `97797ef`.

## Architecture card

| State / mechanism | Existing single owner | Required change / invariant | Verification |
| --- | --- | --- | --- |
| Accepted temporal target | `DashboardCoreController` | Level and component paths use one Core body+Header admission contract; UI never reconstructs a frame | Core RED/GREEN + boundary suite |
| Financial frames and scores | immutable Mind projections + `MindBehavioralScoreProjection` | no second notifier, score owner or financial recomputation | source/diff + counter tests |
| Scale and legend preference | `MindYearHeatmapPresentationController` | one presentation settings write path for resolution, visibility and placement | settings tests |
| Tile/legend colours | `MindYearHeatmapPaletteResolver` | one resolver supplies every plane and legend | resolver/all-plane tests |
| Compact range interaction | `QueryAmountRangeControl` | Mind can supply an inert center accessory; range remains the sole gesture/data owner | widget identity/drag tests |
| Chart selection | `MindHeaderScoreChart` local state | ephemeral, non-persistent selection; one epoch-day X mapping | widget/golden tests |
| Summary startup | existing Summary controllers | defaults are segmented/mirrored and Core tracks actual initial variant | controller/first-frame tests |

## Accepted target and blank-body repair

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LEVEL-01 | §A, Drive 60623–60657 | Core temporal admission | Current-source DayScope → rail-closed MonthScope is observed RED | real Core test | DONE |
| LEVEL-02 | §A | Core + temporal frame | accepted level target publishes `MindMonthHeatmapFrame` without a Month nudge | notifier assertion | DONE |
| LEVEL-03 | §A, screenshot | host + Month viewport | Month grid is mounted with positive bounds; unavailable body and Day grid are absent | widget bounds | DONE |
| LEVEL-04 | §12 | Core score/body contract | body, score, chart endpoint and colour use one accepted Month identity | mounted provenance test | DONE |
| LEVEL-05 | §13 | Core temporal coordinator | Month → Day → Month round trips never revive a stale Day frame | latest-wins Core test | DONE |
| LEVEL-06 | §13 | Core temporal coordinator | rapid child/level/component input paints only latest target | `e19e5a6` latest-wins Core test; final focused suite | DONE |
| LEVEL-07 | §§14–15 | Core prepared data | level publication uses zero repository/index/Query/scene acquisition | work-counter test | DONE |
| LEVEL-08 | §13 | existing Month/Day paths | Month component and Day fast-path positive controls remain green | existing focused tests | DONE |

## Palette resolution

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SCALE-01 | §B, §14C | presentation settings | `ten` default, `twenty` selectable; real change increments revision once and no-op does not | unit test | DONE |
| SCALE-02 | §14D | central resolver | five existing ten-stop palettes are byte-compatible at anchors and off-anchor samples | resolver baseline test | DONE |
| SCALE-03 | §14E | central resolver | each specified 20-stop list resolves exactly at `index / 19` | resolver unit test | DONE |
| SCALE-04 | §14F–G | resolver + viewports | selected resolution drives Sum, Year, Month, Day and legend count | all-plane widget test | DONE |
| SCALE-05 | §B, §15 | presentation controller | 10↔20 changes paint only; financial frame, Query, Time, source/index/projection work remain unchanged | `e19e5a6` production Core identity/counter test; final focused suite | DONE |
| SCALE-06 | §21 | palette contract | exactly five palette identities remain; removed palettes do not reappear | enum/tuner test | DONE |

## Legend placement and body geometry

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| LEGEND-01 | §D–E | Mind settings + surface | visibility and placement are independent presentation-only settings | settings test | DONE |
| LEGEND-02 | §D, §14I–K | Mind body + compact range | above mode: 16px lane, 68px footer, no clipping/overflow and +18px body under equal outer bounds | mounted rect test | DONE |
| LEGEND-03 | §E, §14J | compact range accessory | inline mode has zero external lane; 10×6px / 20×4px 1px-gap swatches fit between Min/Max and +34px body | mounted rect test | DONE |
| LEGEND-04 | §E | compact range accessory | hidden legend reserves no external or inline space regardless of placement | widget test | DONE |
| LEGEND-05 | §D, §15 | shared range control | RangeSlider bounds, thumb input, preview and commit are unchanged at 68px; standard Query layout is byte-compatible | widget/interaction test | DONE |

## Header chart inspection

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CHART-01 | §C, §8.14 | chart projection | sparse-point RED proves index X differs from epoch X; one pure temporal mapping then owns anchors/labels/hit test/crosshair | unit/widget test | DONE |
| CHART-02 | §12.6–12.9 | chart-local state | no initial selection; clean tap selects nearest immutable point; repeated same-point tap clears; another tap moves | widget test | DONE |
| CHART-03 | §C | chart painter | white vertical crosshair and selected real-point marker/`NN/100` top value are rendered | focused golden | DONE |
| CHART-04 | §C, §14O–P | chart presentation context | exact Year/Sum/Month/Day bottom labels reuse the Hungarian formatter | widget test | DONE |
| CHART-05 | §C, §12.6 | chart-local lifecycle | immutable series/domain change clears selected state synchronously; same series survives Header collapse | widget test | DONE |
| CHART-06 | §C, §12.7 | Header gesture coexistence | labels hidden/visible are independent; vertical chart drag selects nothing and still drives Header gesture | widget test | DONE |
| CHART-07 | §15 | chart-local state | repeated taps cause zero score/Core/Query/Time/repository/index work | `e19e5a6` production Core counter test; final focused suite | DONE |
| CHART-08 | §C | chart layout | edge labels stay in Header bounds without altering real crosshair X | widget bounds test | DONE |

## Summary startup defaults

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUMMARY-01 | §F, §14R | variant controller | fresh default is segmented, `transitionEpoch == 0`, and explicit initial variants remain testable | unit test | DONE |
| SUMMARY-02 | §F, §14S | summary presentation | default and reset orientation are mirrored | controller test | DONE |
| SUMMARY-03 | §F, §14T | CoreDashboard | first mounted frame is segmented/mirrored and Core bookkeeping starts from controller value | widget/integration test | DONE |
| SUMMARY-04 | §F | existing tuner | Legacy/Segmented and Normal/Mirrored remain reversible product choices | tuner widget test | DONE |
| SUMMARY-05 | §F | startup diagnostics | no synthetic Legacy→Segmented event or epoch at launch | event/transition test | DONE |

## No-touch, validation, and delivery

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SAFE-01 | §11, §15 | protected systems | no diffs in Time/Avatar physics/controller/position, Query semantics, score/color maths, Room/Kotlin/schema, LogBox, Budget, Day aggregation, Year inspection or milestone file | c1b12..5893 diff and boundary review | DONE |
| VAL-01 | §§10,13,17 | all changed features | every production behavior has observed current-source RED before GREEN | committed RED/GREEN tests, including post-default narrow-layout RED | DONE |
| VAL-02 | §17 | Flutter suites | focused tests, analyzer, fast suite, boundary verifier and diff check pass | Ubuntu/proot output | DONE |
| VAL-03 | §§18–19 | commits/journal | application commits have factual separate journal-only evidence, final app tip triggers build | `git show` audit; exact `5893b456` first pushed for workflow 35436924400 | DONE |
| VAL-04 | §19 | CI/APK/SCIP | each CI job is reported independently; normal APK embeds exact app SHA and final SCIP indexes it | workflow/artifact/manifest | NOT DONE |
| VAL-05 | §21 | user validation | Android physical acceptance remains user-only | user report | NOT DONE |
