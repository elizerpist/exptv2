# Final interaction polish design

## Goal

Eliminate the one-frame sibling LogBox flash caused by a new preview payload
being rendered at an old vertical scroll offset, and make SummaryPill physical
vertical swipes follow the existing `sum → year → month` semantic hierarchy.

## Approved design

`DashboardLogBoxViewport` listens to `logBoxPresentationLane` for every
binding, not only committed bindings. It derives a visible scope identity from
the exact query key, core revision and viewport id. When that identity changes
and the position is not already at its minimum, the stable controller performs
an immediate native `jumpTo(minScrollExtent)`. Flutter's jump interrupts the
current vertical activity without replacing the controller or position.

`DashboardVisibleFrameStore` already stages all lane pointers before notifying
listeners. Its flush order changes so lightweight presentation metadata is
notified before the LogBox payload lane. This makes the top reset occur before
the new sibling payload's render listener can build a frame. Preview→committed
promotion retains the same scope identity and causes no second reset.

`DashboardSummaryPill` retains the existing `TimePlane` order and transition
math. Its vertical gesture commit mapping changes only: a down drag calls
`onMoveFiner`; an up drag calls `onMoveBroader`.

## Error handling and diagnostics

The viewport emits `VERTICAL_VISIBLE_SCOPE_RESET` only when it actually moves
away from a non-top position. The event captures old/new queries, modes,
pixels, presentation epoch, viewport id and activity state. A debug/profile
late-reset invariant records `SIBLING_SCROLL_RESET_LATE` if a newly visible
sibling is observed above its canonical top.

## Evidence

Widget tests capture the first April preview frame after deep May scrolling,
rapid sibling transitions, day/year hierarchy variants, visual no-op settle,
native activity interruption, lane flush order and both Summary swipe cycles.
Existing scene-rebase, paging, cache-boundedness and rail tests remain the
regression boundary. No golden test is added.
