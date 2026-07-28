# Balance V2 Design

## Goal

Add `Balance V2` as a selectable Balance-shell presentation. It retains the
approved Balance header, action toggle, SummaryPill, SearchPill, time rail,
collapse physics, LogBox, material and page background. The only structural
change is that the five compact FastInfo islands become taller carousel pages.

## Geometry

The current Balance composition has a 72px FastInfo belt at y=241, an 11px
gap, and a 208px detail-card viewport at y=324 (218px including the 4px
pagination gap and the 6px dots). Balance V2 removes the belt and occupies its
entire 83px footprint with the detail carousel:

| Region | Balance | Balance V2 |
| --- | ---: | ---: |
| detail top | 324px | 241px |
| visible card height | 208px | 291px |
| card stage height | 218px | 301px |
| stage bottom | 542px | 542px |

Consequently the action, summary, search, rail and transaction log keep their
existing coordinates. The V2 carousel remains a direct page-background child:
no nested opaque surface or scroll host is introduced, and the existing
unclipped glow layering is retained.

## Carousel content

The same ticking viewport and swipe semantics render nine pages. It prebuilds
the entering neighbour and keeps the current five-slot window behaviour;
moving does not wait for an old page to leave the viewport before creating the
new one.

1. **No-spend napok** — large `X nap` primary fact, explicit `Y megfigyelt
   napból` secondary fact, the existing period cycle, and a compact period
   strip. It must state the selected period rather than implying an all-time
   result.
2. **Legnagyobb kategóriaváltozás** — resolved category icon and colour,
   current delta/percentage, and a current-versus-previous two-period
   comparison from the active Balance frame.
3. **Legutóbbi tranzakció** — resolved category icon, amount, merchant,
   category and time metadata; no inferred merchant frequency.
4. **Költési trend** — direction, absolute/relative active-frame change and
   its explicit comparison basis.
5. **Közelgő ismétlődés** — resolved category, amount, due date and no-data
   state; it remains controlled by the existing ghost inclusion state.
6. **Változó keret** — day/week/month selector, remaining/spent/count facts,
   and a taller live progress region.
7. **Top 5 kategória** — featured leader plus four following resolved
   category rows, with the existing rank-period selector and central category
   icon/colour resolver only.
8. **Top 5 kereskedő** — featured leader plus four following rows, with the
   existing selector and each row's resolver-backed category context.
9. **Átlagos napi költés** — existing period selector, a taller 30-day live
   painter and all existing buffer/peak/outlier facts.

Every result comes from the active `BalanceRenderFrame` and therefore follows
the current transaction type, summary period, category/merchant filters and
ghost state. No sample or duplicated data is allowed.

## Interaction and accessibility

`Balance V2` is a distinct header-dropdown mode and cache identity. The normal
Balance presentation remains untouched. The carousel has nine labelled pages
and nine pagination dots. Existing selectors, ghost controls and No-spend
period cycling remain reachable with semantic labels. Swipe/keyboard input
uses the same ticking viewport rather than a second scrolling implementation.

## Verification

Targeted production-host Flutter widget tests prove mode selection, absence of
the FastInfo belt, exact V2 geometry, page count, rich No-spend copy, five
category/merchant rows, and data changes after period/type changes. Existing
Balance tests remain green. Flutter analyze runs in Ubuntu proot; the debug APK
is built only by GitHub Actions and downloaded to Emulated/0 after success.
