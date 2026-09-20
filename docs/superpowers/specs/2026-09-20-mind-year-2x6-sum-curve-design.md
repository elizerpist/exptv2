# Mind Year 2x6 cards and Sum curve presentation

## Intent

Add a third, card-based Year heatmap layout and make the existing MonthCard
surface options consistently available to all card-based Year layouts.  Extend
the detailed Sum chart with presentation-only curve controls while preserving
the admitted financial frame and all existing interaction semantics.

## Ownership

- `MindYearHeatmapPresentationSettings` remains the sole owner for persisted
  presentation choices: MonthCard border/tint controls and Sum curve controls.
- The Year card owns only the local 4x3 / 3x4 / 2x6 display selector.  It does
  not alter query or financial state.
- Existing monthly scope and closing values remain the sole financial source
  for both 3x4 and 2x6 MonthCards.
- A reusable Month heatmap day-number overlay is shared by Month and the new
  2x6 Year card layout, preventing divergent date-label geometry.
- One shared Sum year-band header is used by the detailed-line and monthly
  overlay views, preventing visual/formatting drift.

## Year layouts

| Layout | Month surface | Footer | Day number | Unchanged invariant |
| --- | --- | --- | --- | --- |
| 4x3 | direct cells | none | none | no-scroll direct-grid geometry |
| 3x4 | rounded MonthCard | Scope + Zárás | none | current card geometry/spacing |
| 2x6 | rounded MonthCard | Scope + Zárás | top-left in each day cell | heatmap palette and tap semantics |

MonthCard border and profitability tint apply only to the two card rows.  The
tint uses the established monthly closing result: positive green, negative
red, zero neutral.  Its opacity affects only the card background.

## Sum curve controls

The detailed Sum chart receives immutable presentation inputs from settings:

- interpolation: linear, monotone cubic, Catmull–Rom with tension;
- optional weighted temporal smoothing with a 3/5/7-day-equivalent window;
- optional zoom-adaptive smoothing strength.

Raw chart anchors remain the sole selection/inspection values.  Smoothing is a
paint-only transform.  It preserves local extrema, blends continuously toward
raw anchors with deep zoom, and clamps cubic controls to endpoint ranges so it
does not invent overshoot extrema.

## Non-goals

No changes to Query, range-slider membership, heatmap intensity/palette,
Scope/Zárás meaning, direct 4x3 layout, Month/Day data semantics, or gesture
ownership.
