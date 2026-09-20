# Mind Sum three-mode refinement acceptance checklist

## Architecture card

- **Financial/read-model authority:** `MindSumHeatmapProjection` remains the
  only Sum projection over Core-admitted prepared membership. Its immutable
  preview frame is the only filtered/range-preview input for heatmap, detailed
  line and Sum monthly-overlay rendering.
- **Presentation write path:** `_MindSumHeatmapContentState` is the only
  writer of local Sum visualization mode. The top-right control is the only
  UI writer; there is no Sum `PageView` or horizontal-swipe mode writer.
- **Shared mechanisms:** `MindDetailedSumTimeWindow` owns usable temporal
  zoom; `MindDetailedSumLod` owns source-anchor selection; `MindAnchoredInfoCard`
  owns popup clamping. Monthly full-vs-filtered comparison geometry is one
  neutral model/painter shared by Sum and Year adapters, with no copied Query
  logic or raw palette values.
- **No-touch:** Core Query, range-slider ownership, repository/Room/schema,
  Avatar/Time physics, Header score/colour, Year/Month/Day semantics and
  `MILESTONE_COMMITS.md` stay untouched unless a direct regression test proves
  a shared primitive requires a bounded compatibility change.

| ID | Source / reference | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SUM3-01 | 2026-09-20 physical feedback | Sum viewport local state | Exactly heatmap, detailed line and monthly-overlay modes exist; top-right control is the only switch; no Sum `PageView`, swipe affordance, or exact annual page is reachable | Mounted topology test + source review | NOT DONE |
| SUM3-02 | 2026-09-20 physical feedback | `mind_detailed_sum_chart_model.dart` | Full-year home can reach a visible window of <= 184 days; repeated pinch gestures compound; focal time remains stable | RED/GREEN pure-domain + mounted pinch tests | NOT DONE |
| SUM3-03 | 2026-09-20 physical feedback | detailed chart widget | Tap anywhere in a plot resolves the nearest real LOD anchor and shows its real date/day and amount; no interpolated amount | Mounted interaction/popup test | NOT DONE |
| SUM3-04 | 2026-09-20 physical feedback | detailed chart layout/painter | One chart remains expanded; exactly two complete bands including second month axis fit at once; 3+ bands retain min size and inner scrolling | Mounted bounds/scroll tests | NOT DONE |
| SUM3-05 | 2026-09-20 physical feedback | detailed chart painter | Faint dashed vertical boundaries are rendered at visible calendar-month changes | Painter semantics/widget evidence | NOT DONE |
| SUM3-06 | 2026-09-20 physical feedback | neutral monthly comparison model and Sum adapter | Per represented year, gray bars are full selected-direction month totals and palette-resolved foreground bars are current filtered/range totals; zero-safe, slider-reactive | Domain + mounted Sum-bar tests | NOT DONE |
| SUM3-07 | existing protected contract | gestures/range | Three-mode changes, pinch, tap and chart pan leave admitted financial frame and `QueryAmountRangeControl` ownership intact; no horizontal visualization swipe | Mounted regression tests | NOT DONE |
| ARC-04 | `structuring-apps` | all new paths | One range/frame authority; one popup primitive; one monthly overlay core/palette resolver; UI only owns local selection/window | Focused boundary/source review | NOT DONE |
| PERF-02 | 6e96218 milestone / user scope lock | projection/chart | Toggle, pinch, tap and bar paint do no repository, Room, index, Query, Time or score work | Existing projection/widget work-bound tests | NOT DONE |
| DELIV-03 | user workflow | GitHub/SCIP/journal | Application commits each have journal-only children; final exact app SHA has CI, human APK and SCIP | Git/Actions/artifact/graph audit | NOT DONE |
| PHYS-03 | user workflow | Android | Exact produced APK is physically accepted | User-only | BLOCKED |
