# Balance carousel detail and flat-navigation clamp design

## Approved direction

The user's written 2026-09-26 prompt is the approved design authority. The
two supplied PNG files are visual direction only. This design intentionally
does not create another settings owner, formatter family, carousel engine, or
category-colour source.

## Architecture

`BalanceCarouselCard` will become a render-only, immutable mini-card model:
each item supplies a title, primary copy, secondary copy and one typed visual
descriptor. The carousel renderer will have one compact-responsive layout
that always retains the same grammar. It will use `BalanceCategoryVisualBadge`
for category/partner-backed items and a finite icon mapping for the remaining
topics. Existing `CenteredCarousel` movement, selection and hit-test ownership
are untouched.

Page two of `BalanceLinkedDetailCard` remains local state below `_RankedDetail`.
It will obtain its category gradient from the existing selected-avatar palette
scope and catalogue; no category identity or financial value is recomputed. A
shared local page-title rhythm token aligns the master title and detail return
row. The detail hero becomes one left identity / right median row, followed by
metric chips and a taller segment presentation.

`DashboardFlatBottomNavStretchLayout` remains the only bridge between shell
and Dashboard scales. It exposes the needed SearchPill-edge gain and the
count-safe maximum gain derived from the same resolved Ledger relationship;
their minimum is the effective value. The 24px raised-FAB artwork offset is
not a substitute for this Dashboard geometry calculation. Consequently the
count row is never pushed past the nav's breathing-gap boundary. Core
continues to feed that one resolved number into existing header/content
expansion inputs for all modes.

## No-go boundaries

No financial calculation, rank order, category handle, Query, repository,
BottomNav placement, slider, Summary, or carousel physics changes. The
pre-existing latest-card setting is retained as user state; the newer
carousel-wide visual grammar takes precedence over its obsolete special layout
while retaining the selected semantic data and no date/time line.

## Validation

Tests first establish canonical card keys/data, category-coloured page-two
geometry at both 320px and the real 210px lower-card envelope, and the
count-safe geometry clamp. A production `FluviAppShell` regression measures
the rendered count/SearchPill rectangles against the BNB physical bar for both
stretch targets. Existing carousel/controller and multi-mode geometry tests
remain regression guards. The final app commit will be tested and analyzed in
Ubuntu proot, pushed, and delivered as the normal online Human APK. Physical
validation remains user-only.
