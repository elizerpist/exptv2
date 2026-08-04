# Design: SummaryPill parent-navigation performance

## Context

The best-performance baseline is commit `3dd650c`. Child rail preview,
pending-lease invalidation, active-result visual isolation, direct/no-op amount
updates, motion-aware adjacent prewarm and LogBox phase diagnostics already
exist. The remaining suspected cost is the SummaryPill parent-navigation path:
parent scope commits can trigger reads, child-deck work, broad notifications and
prewarm before the visible parent snapshot is selected.

## Ownership map

```text
SummaryPill / centered carousel
  -> existing parent motion/selection owner
  -> DashboardParentNavigationCoordinator (new narrow semantic adapter)
  -> DashboardPresentationStore (single visible UI truth)
  -> in-memory parent presentation index (derived cache, not another owner)

CurrentQueryController / repository
  -> committed parent result and live lease only
  -> may warm cache, never owns preview visibility

DashboardChildPreviewBundle
  -> child deck readiness for the selected parent
  -> never required by parent preview publication

DashboardCoreController
  -> composes coordinators and routes motion lifecycle
  -> does not compute parent metrics or render widgets
```

## Recommended design

Extend the existing centered-carousel semantic callback boundary rather than
creating a second scroll engine. Parent navigation receives a typed motion
epoch. On each distinct parent crossing it resolves the exact parent
`DashboardQueryKey` through a bounded in-memory parent presentation index and
publishes one immutable parent preview snapshot through the existing
`DashboardPresentationStore`. This publish updates label, amount, count and
the narrow parent content metadata together. It does not commit the query,
start a lease, parse a child deck, run adjacent prewarm, or notify the whole
dashboard root.

Settle promotes the already-visible exact snapshot. If query key, revision,
amount, count and content identity match, promotion is visual no-op. Only the
committed query/live-lease lane changes afterward.

Parent and child cursor state stay separate. With the rail closed, the target
parent owns the visible snapshot. With the rail open, the target parent first
normalizes the child cursor against the target parent's child index and then
selects the target parent's child snapshot. An old parent child snapshot is
never valid under a new parent key.

Bootstrap remains gated by the existing startup coordinator: the first
dashboard-dependent frame is withheld until exact parent summary, count and
bounded current child deck are ready. No placeholder or stale cross-scope
publish is introduced.

## Alternatives rejected

1. A second SummaryPill-specific cache/store: rejected because it creates a
   second UI truth source and makes amount/count/content atomicity weaker.
2. Rebuilding the full parent bundle synchronously on every crossing: rejected
   because it places child parsing and projection in the motion hot path.
3. Replacing the SummaryPill physics or using manual `animateTo`: rejected
   because the baseline motion is frozen and the evidence points to data and
   rebuild work, not physics.

## Verification

Red tests cover month/year parent preview sequence, no-I/O motion, stable
controller identities, rail-open parent switching, rail-closed restoration,
equal-snapshot settle no-op, delayed old-result isolation and first-frame
bootstrap. Existing child-rail, lease, amount, prewarm, LogBox and physics
tests remain part of the golden-free suite. Deterministic 5k/20k/100k fixtures
verify bounded aggregation and cache behavior. Device-level UI/raster profile
numbers are reported separately from host/unit evidence.
