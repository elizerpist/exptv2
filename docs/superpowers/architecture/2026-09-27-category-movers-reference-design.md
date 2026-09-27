# Category movers reference redesign — architecture card

## Scope and authority

The authoritative visual input is
`/storage/emulated/0/spendee/source of truth/change.png`, inspected on
2026-09-27.  It owns the inner design of the two-page Balance category-movers
detail card.  The existing Balance primary-card envelope, carousel ownership,
navigation/query ownership, and bottom-nav/count geometry remain outside this
change.

## Existing owner and read model

`DashboardBalanceCategoryMoversProjection` is the one analytics owner.  It
already derives the exact `currentWindow` and `referenceWindow` from the
selected scope and logical as-of date, and publishes an immutable
`DashboardBalanceCategoryMoversPresentation` to the linked Balance detail
card.  The redesign extends that projection with bounded `topDecreases` and
`topIncreases` lists while retaining the existing global-impact `movers` list
for carousel continuity.  It uses the existing prepared membership input and
does not introduce a repository, query, or widget-side ledger scan.

The card consumes only this presentation.  Its only state is local inspection
state: selected decrease/increase direction and selected category ID.  Neither
may mutate summary scope, carousel selection, data, or query state.

## Rendering boundaries

`balance_category_movers_presentation.dart` owns pure formatting and the
bounded cumulative-series adapter: it formats actual comparison windows and
turns immutable bucket values into cumulative points once before painting.
The widget does not invent dates, rank financial values, or aggregate buckets.
The painter receives prepared cumulative points plus resolved visual labels;
it performs only geometry and paint.

`BalanceCategoryMoversCard` owns the two rendering pages, semantic tap targets,
and page transition.  The existing `DashboardPlaceholderCard` remains the
outer surface, shadow and user-configurable content-border owner.  The Movers
body supplies its internal white surface, upper 4–7% lavender decoration, and
content only; it never alters outer bounds or page dots.

## Shared visual tokens

Create one Movers-specific semantic visual-token source for the reference
palette (`surface`, `ink`, `secondary`, `hairline`, `purple`, `purpleLight`,
`negative`, `positive`, `reference`) rather than duplicating literal colours
between page widgets and the chart painter.  Category avatar/accent colours
continue to resolve through the canonical category catalog.

## Stretched-height contract

The existing host changes the supplied lower-card constraints when its
content-stretch presentation is active. Page 1 distributes that surplus
between bounded inter-row space and the list; Page 2 assigns it primarily to
the chart, capped visually. No outer geometry or count/bottom-nav calculation
changes. The inherited baseline lower envelope is about 210px, while the fixed
reference anatomy needs more space; at that envelope alone the entire local
page scrolls, rather than changing the prohibited outer bounds. Normal and
stretched envelopes retain the complete non-scrolling reference composition.

## Defaults owner map

* `DashboardSummaryPresentationSettings.defaults`: separators off.
* `SummaryPillVariantController`: segmented is already the canonical default;
  retain and test it.
* `DashboardShellPresentationSettings.defaults`: straight + containedFlat.
* `DashboardBodyOrder.defaultOrder`: explicit modeContent → direction →
  summary sequence, independent of enum declaration order.

Each remains a seed/default; its existing controller setter continues to own
user changes and reset-to-default.
