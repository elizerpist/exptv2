# Mind three-card charts and cell inspection design

**Status:** approved by the user on 2026-09-19.

**Reference:** `/storage/emulated/0/spendee/reference/mindsumlinechart.png`.

## Product shape

Mind Sum is a three-page visual sequence: multi-year heatmap, exact yearly
aggregate line chart, then the existing daily-anchor multi-line chart. The
second page has one immutable point per represented calendar year; it never
plots transactions or months. The existing daily-anchor chart remains intact
as the tertiary page.

Mind Year is likewise three pages: annual heatmap, existing full-versus-current
filtered bars, then a new twelve-point monthly aggregate line chart. The
existing annual MonthCard inspection is replaced by inspection of a non-empty
represented day cell.

## Ownership card

| Concern | Owner | Rule |
| --- | --- | --- |
| Sum year/month/day aggregates | `MindSumHeatmapProjection` and immutable `MindSumHeatmapFrame` | Build from admitted prepared contributions once; range preview only reads existing amount buckets. |
| Year month aggregates | `MindYearHeatmapFrame` | A month point sums current `frame.month(month)` days; it does not query or scan ledger rows. |
| Sum layout/label choices | `MindYearHeatmapPresentationSettings` and its existing controller | Presentation-only, revisioned, no Query/Time persistence. |
| Page, point, and cell selection | relevant Mind viewport state | Ephemeral local presentation state; clear on immutable frame identity change. |
| Chart geometry and tooltip appearance | one shared Mind aggregate-chart/anchored-infocard primitive | Sum exact-year and Year monthly charts use the same painter, hit rule, palette token and clamped popup placement. |
| Slider | existing `QueryAmountRangeControl` | Physically outside the pager and unchanged as the only range gesture/data owner. |

## Aggregate models

`MindAggregateLinePoint` is an immutable `(domainOrdinal, label, total)` read
model. `MindSumHeatmapFrame` exposes a continuous annual sequence from its
minimum represented year through its maximum, including zero internal years.
Its totals are the current direction/focus/search/range-preview totals. A Year
page builds exactly twelve month points from the current frame's filtered day
totals. Neither chart can manufacture a transaction or interpolate a financial
value.

## Interaction and gesture contract

The outer `PageView` owns normal card swipes. The exact Sum chart creates a
horizontal scrollable plot only when `yearCount * minYearSlotWidth` exceeds
the available plot width; the plot then owns horizontal drags inside its own
bounded hit region. Header, margin and non-plot regions retain outer paging.
The slider remains outside both regions. Vertical boundary handoff continues
through the existing passive `DashboardPagedVerticalBoundaryHandoff`.

One shared passive clean-tap region uses pointer-down/up distance slop and
never claims a pan gesture. It services Sum month cells, Year day cells and
chart anchors. A shared anchored infocard clamps above/below and left/right to
the card's bounds. Each surface has at most one selection and moves rather
than stacks a popup.

## Visual contract

The new exact Sum chart follows the inspected reference: white card language,
purple single line, soft purple downward-fading fill, quiet horizontal grid,
vertical year guides, point emphasis, readable abbreviated Ft ticks and a
bounded selected-year card showing total and YoY delta. Year monthly chart is
the same family at twelve month positions. Heatmap labels use `J F M Á M J J A
S O N D`; `none`, `belowEachRow`, and `insideMonthCells` are presentation
alternatives. The compact Sum row preserves year-left, middle heatmap,
right-side compact total.

## Safety and evidence

No Time/Avatar physics/controller/position, canonical Query ownership,
repository, Room/Kotlin/schema, score calculation, Budget, LogBox or
`MILESTONE_COMMITS.md` change is allowed. Every feature unit begins with a
failing domain/widget/gesture test, then minimal production code. The final
validation includes focused Flutter tests in Ubuntu proot, analyzer, boundary
verification, online Human APK and exact-source SCIP. Runtime Drive-log audit
is intentionally out of scope unless a deterministic unexpected defect forces
one.
