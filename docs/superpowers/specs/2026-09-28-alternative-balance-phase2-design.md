# Alternative Balance dashboard phase 2 design

## Authority

The user confirmed that the Card 3 source reference is
`/storage/emulated/0/spendee/source of truth/barchart.png` (1186×1326).
Only its `Bevétel / Kiadás` Card 3 region is source-locked.  The written scope
rules are authoritative for the rest of the alternative body.

## Ownership / architecture card

| Concern | Owner | Write path | Excluded responsibility |
| --- | --- | --- | --- |
| Financial pairs | existing `DashboardBalancePrimaryPresentation` | existing prepared Balance projection | repository, raw-ledger scan, Query changes |
| Alternative scope model | new sealed render adapter | pure conversion from immutable primary presentation | financial aggregation |
| SUM/YEAR Card 3 | one reusable income/expense bar renderer | immutable bar model plus a domain policy | Month/Day charts or interaction popups |
| SUM/YEAR slots | new `BalanceFiveSectionLayout` | pure `Rect` resolution | Month/Day geometry |
| Month/Day slots | existing `BalanceFourSectionLayout` | unchanged | SUM/YEAR five-slot behavior |
| SUM scrolling | Card-3-local stateful renderer | stable `ScrollController` | global dashboard gesture ownership |

## Scope routing

The settled unified alternative body selects one sealed render model from the
canonical `LedgerTimeScope`: `AllTimeScope` → Sum, `YearScope` → Year,
`MonthScope` → Month, `DayScope` → Day.  SUM and YEAR share the five-slot
geometry and Card 3 renderer.  MONTH and DAY retain the existing four-slot
placeholder scaffold unchanged.

## Card 3 source-locked composition

The reference shows a white rounded Card 3 with soft depth, 14-ish logical
inner padding at the production scale, a bold `Bevétel / Kiadás` title,
income/expense total/legend row, right-aligned net total, and a grouped
upright-bar chart.  It uses mint income and coral-pink expense bars, a shared
linear Y scale, three restrained horizontal value guides, compact labels, and
small rounded bar caps.  The chart preserves the reference order: income then
expense for every group.

YEAR presents exactly twelve fixed slots labelled `JAN` through `DEC`; its
plot is not scrollable.  SUM uses the same chrome and bar dimensions, but only
its plot lane becomes horizontally scrollable when real-year groups exceed the
reference group width.  The local controller initializes to the newest end
once when Card 3 enters an overflowing SUM binding; harmless primary/Header
refreshes keep the user's position intact.

## Geometry

`BalanceFiveSectionLayout` preserves the 60/40 vertical body partition and
the 70/30 top / 50/50 bottom width partition.  Its right top 30% is split into
Card 4 and Card 5, each 30% of full body height.  Surface gutters remain visual
insets inside exact allocation slots.  `BalanceFourSectionLayout` remains the
sole Month/Day geometry owner.

## Verification

Tests precede production work for: sealed scope routing, adapter fidelity,
five-slot math, fixed 12-month YEAR fit, SUM overflow and scroll retention,
Month/Day four-slot regression, and no added financial boundary work.  Visual
goldens cover SUM and YEAR Card 3 at production body bounds.
