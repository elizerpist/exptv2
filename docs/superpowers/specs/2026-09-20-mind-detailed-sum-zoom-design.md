# Mind detailed Sum zoom and anchored-card refinement

## Approved input

The user-approved Mind card structure remains intact:

- Sum page 0 is the multi-year heatmap.
- Sum page 1 is the exact one-point-per-year aggregate trend.
- Sum page 2 is the detailed per-year trend and is upgraded in this delivery.
- Year keeps its heatmap, partial bars and twelve-month aggregate line.
- Month and Day keep their approved secondary cards.

The visual references were inspected directly before this design:

- `/storage/emulated/0/spendee/reference/mindsumlinechart.png`
- `/storage/emulated/0/spendee/reference/havi.png`
- `/storage/emulated/0/spendee/reference/napi.png`

No Drive log is an input to this feature delivery.

## Architecture card

### Source and write path

- Financial source of truth: the already-admitted immutable
  `MindSumHeatmapFrame` and its current range-preview daily aggregates.
- Detail model: a pure, immutable Sum detail-series adapter over those frame
  points. It has no repository, Room, Query or Core dependency.
- Zoom/pan/toggle/selected-point state: the page-local detailed Sum widget.
  It is never persisted and never writes navigation or Query state.
- Popup placement: the existing data-free `MindAnchoredInfoCard` remains the
  single shared cell-popup placement primitive. Its bounds calculation is
  strengthened rather than copied into Sum and Year.

### Reuse / centralization decision

| Mechanism | Current owner | Decision |
| --- | --- | --- |
| exact aggregate line chart | `MindAggregateLineChart` | Preserve unchanged for Sum page 1 and Year page 2. |
| detailed annual trend painter | `MindSumYearTrendPainter` | Replace its fixed painter composition with one detailed-chart widget and a pure temporal LOD helper. |
| pager/boundary handoff | `DashboardPagedVerticalBoundaryHandoff` | Reuse; zoom/pan is confined to page 2 and never wraps the slider. |
| popup clamping | `MindAnchoredInfoCard` | Extend one primitive, no feature-local duplicate. |
| chart palette | `MindYearHeatmapPaletteResolver` | Reuse for detailed stroke/fill; do not add raw colours. |

### State ownership

| State | Owner | Lifetime | Write rule |
| --- | --- | --- | --- |
| range-filtered financial points | immutable `MindSumHeatmapFrame` | admitted-frame lifetime | Core projection only |
| LOD window | `MindDetailedSumChart` | mounted detailed-page lifetime | pinch/pan only; reset on frame identity |
| detailed line/heatmap display | `MindDetailedSumChart` | mounted detailed-page lifetime | mini-toggle only |
| popup selection | existing Sum/Year page state | active page/frame | pointer tap only |

### Gesture contract

- The compact range slider remains outside the pager and remains the sole
  range gesture owner.
- The detailed chart owns scale/pan only after a two-pointer scale begins or
  a one-pointer horizontal pan begins inside the detailed plot.
- The outer pager remains available for normal one-pointer horizontal swipes
  outside a zoomed detailed chart; a zoomed chart consumes its own pan.
- Vertical scroll stays with the existing per-year detailed list. For three
  or more years the list scrolls rather than reducing a year band below the
  two-year minimum.

## Design

`MindDetailedSumChart` renders one annual band per represented year. Its home
window is exactly the January-through-December temporal domain. A pinch keeps
the temporal location below the focal point stable, clamps the scale to the
home extent or closer, and regenerates the path from immutable values rather
than bitmap-scaling. A pure LOD helper returns fewer calendar bins at low
pixels-per-day and progressively preserves more true points as the visible
window narrows; source aggregates remain unchanged.

One year receives the available detail plot height; two years split it; three
or more use the same two-year minimum height within the existing vertical
scroll owner. Each band has localized Hungarian month initials and readable
money ticks. The card-top mini control switches between the line and the
existing heatmap representation without mutating Query or time.

The Sum/Year lines retain their existing actual-card constraint sizing. The
new detailed bands reserve axis space once, use the remaining height for the
plot and do not add fixed whitespace above the plot or below X labels.

## Explicit non-goals

- No new Query/controller/store/cache/repository path.
- No raw colour system, score algorithm, Header change, Time/Avatar physics
  change, BottomNav change, or slider replacement.
- No Drive-log audit and no runtime-causality claim.
