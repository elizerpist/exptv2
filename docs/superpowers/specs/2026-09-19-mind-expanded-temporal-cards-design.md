# Mind expanded temporal cards — approved design

## Scope

This design records the user's already-approved Sum, Year, Month, and Day Mind
feature contract. It is feature work: no Drive/runtime-log audit is part of the
normal path. The visual references are:

- `/storage/emulated/0/spendee/reference/mindsumlinechart.png`
- `/storage/emulated/0/spendee/reference/havi.png`
- `/storage/emulated/0/spendee/reference/napi.png`

## Architecture card

### Sources and existing owners

- Immutable Mind frames and resident amount-range buckets remain the sole data
  source: `mind_temporal_heatmap_projection.dart`.
- `MindAggregateLineChart` remains the one shared aggregate-line renderer and
  receives bounded immutable points. Its selection state is presentation-local.
- `MindSumHeatmapViewport`, `MindMonthHeatmapViewport`, and
  `MindDayHeatmapViewport` own their visual pager and local cell selection.
- Year keeps `MindYearHeatmapViewport` as the owner of its primary/secondary/
  tertiary page composition and local selected-day state.
- `MindYearHeatmapPresentationSettings` remains the only write path for Sum
  heatmap layout and label placement. Query, repository, and score owners are
  unchanged.

### State and data flow

`prepared contribution -> immutable resident temporal projection -> immutable
frame -> viewport/chart renderer -> local selected-cell/point popup`.

The only new data exposed by frames is bounded presentation read data: monthly
daily totals and selected-day time-stamped event markers. No widget reads Room,
queries a repository, rescans ledger rows, mutates Query, or derives financial
membership.

### Shared mechanisms

- Extend `MindAggregateLineChart` for Sum yearly and Year monthly aggregate
  charts rather than duplicating line/popup/axis/selection behavior.
- Extract one card-local anchored-infocard primitive when the Sum month and Year
  day interactions need the same bounds-clamped actual-cell anchoring.
- Keep `PageView` scoped to the visualization area. The fixed range footer is
  outside it and remains the sole horizontal range-drag owner.
- Use the existing palette resolver and compact-money formatter; no local color
  scale or financial formatter is introduced.

### Gesture policy

- Page swipe owns bare visualization-space horizontal drags.
- The scrollable Sum annual chart owns drags that begin on its scroll surface.
- The Year twelve-month aggregate chart is width-fit and never scrolls
  horizontally.
- RangeSlider remains outside the pager and owns its entire thumb sequence.
- Heatmap/chart clean taps only change presentation-local selection and are
  rejected after movement slop.

### Verification

- Domain tests prove bounded projection data and aggregate semantics.
- Widget tests prove page ordering, settings, actual-cell anchors, selection,
  chart width policy, Month rhythm and Day timeline composition.
- Existing boundary suite plus targeted source inspection prove no presentation
  dependency reaches repository/Room/Query ownership.
- Reference screenshots are re-inspected at the final visual milestone.

