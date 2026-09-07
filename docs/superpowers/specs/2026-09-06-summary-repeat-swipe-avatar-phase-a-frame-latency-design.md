# Summary input ownership and Avatar Phase-A authority design

## Authorized source and evidence

This design implements the user's 2026-09-06 execution authorization against
application source `9e8a7b3a0a1f17bbd9433927e1d8a0afcd8413e9`.  The matching
SCIP graph is tooling commit `70aa55a33df55f259196b9a526a687d0823e9b8f` and
indexes that exact application SHA.

The immutable audit base is the three read-only files and manifest in
`docs/superpowers/evidence/2026-09-06-profile-9e8a7b3a-session-fluvi-1788686737010611/`.
They identify session `fluvi-1788686737010611` and build
`profile/9e8a7b3a0a1f`.  The older `fluvi-1788669322121683` session is
historical same-SHA evidence only.

The product work has no new visual design.  The previous Time/LogBox visual
repair is protected.  No HTML mockup is useful for the two source-owned
gesture/resource-authority defects, so no prototype is introduced.

## Existing ownership to preserve

- `CoreDashboard` owns one dashboard widget tree, one
  `DashboardCoreController`, and one `DashboardVisibleFrameStore`.
- `SummaryPillExperiment` and the classic pill are input/presentation
  adapters; they do not own query state or visible-frame authority.
- `SummarySegmentedTrackGeometry` is the neutral owner of segmented selector
  geometry.  The visible selector text must stay where it is.
- `DashboardUpperVerticalGestureCoordinator` remains the owner of genuine
  Summary-background expansion/collapse.
- `CenteredCarouselController` remains the one controller, `ScrollPosition`,
  physics instance, and raw-pointer interruption mechanism for a selector.
- `DashboardLogBoxPreparedSceneCache` remains the sole Phase-A resource and
  scene-bank owner.  `CommittedLogViewportCache` remains a committed adoption
  cache, not a second rail-preview resource authority.
- `DashboardLogBoxViewport`, its vertical controller/position, and its custom
  render surface remain stable and singular.

## Summary input boundary

CURRENT source uses an exact, glyph-sized geometry rect for visual content,
selector hit testing and semantics.  A full `HitTestBehavior.opaque`
background detector behind those selector children forwards vertical drags to
the upper collapse coordinator.  Frozen Time logs establish that a pointer
that reaches the carousel can interrupt `HoldScrollActivity` immediately; they
do not contain its coordinate, hit path or gesture-arena result for failed
swipes.

Therefore the repair first adds bounded pointer-start diagnostics and a
persistent production-parent reproducer.  It must classify every pointer as
selector-owned, background-owned, outside, competing, stale-variant, or
stale-geometry.

If and only if the red test proves that a swipe starts in the visually
attributable selector cell but outside the glyph rectangle, the neutral
geometry owner gains separate, disjoint interaction cells.  Those cells are
derived from existing track/separator midpoints, clipped to the navigation
zone, and do not change visual placement.  Semantics follows the resolved
interaction cell without duplicating nodes.  The unassigned background keeps
collapse ownership.

If the pointer is already inside the current selector rect, the geometry stays
unchanged and the proven stale layer, arena, lifecycle, or coordinator owner is
repaired instead.  No timer, cooldown, forced settle, controller recreation,
or oversized overlapping detector is permissible.

## Terminal motion handoff

The selector controller must also distinguish a physical terminal state from a
notification transition. `HoldScrollActivity` is deliberately non-scrolling,
so a terminal probe that samples a transient Hold cannot depend on a later
`isScrollingNotifier == false` transition when the position becomes idle.

`CenteredCarouselController` keeps the existing command owner and grants that
exact command one additional frame-local terminal probe. It emits the normal
current-command settle only if that probe sees `IdleScrollActivity`. A Hold
which remains active receives no synthetic settle and no repeated probe loop;
new pointer contact, scrolling, command invalidation, disposal, or the
existing idle path remains authoritative. This is lifecycle reconciliation,
not a timeout, cooldown, physics adjustment, or controller replacement.

The exact profile run for `aca132…` shows that a renderer frame can be delayed
for seconds in the software-EGL job. The bounded Hold probe remains a fallback
for the Hold-specific path, but it cannot be the only terminal delivery
mechanism. Flutter's `ScrollPosition.beginActivity` dispatches
`ScrollEndNotification` while replacing a scrolling activity; that dispatch
precedes installation of the new idle activity. The production repair now
forwards the depth-zero notification from the shared carousel widget, defers
one command-scoped *microtask* (not a timer or frame callback), then settles
only after re-checking current command, raw-pointer ownership and
`IdleScrollActivity`. The direct depth-zero listener is the owner boundary,
because Flutter supplies copied notification metrics rather than the position
identity. This is an event-order handoff, not a delay
or retry loop; the existing single Hold fallback remains bounded.

## Avatar Phase-A resource authority

The active rail-preview painter determines readiness through
`DashboardLogBoxPreparedSceneCache.hasCompleteReadablePhaseAFor(payload)`,
which needs prepared semantic geometry and an exact immutable row/header
resource for each bounded slot.  By contrast,
`DashboardLogBoxViewport._armVisiblePreviewRootIfPossible()` arms the private
committed cache for later canonical adoption.  Those are not the same owner.

The former `DashboardCoreController._activateBudgetAvatarLiveRoot()` staging
path could report a root-stage miss while its caller still published the
derived Avatar Phase-A frame. The current repair replaces that publication
decision with `_bindBudgetAvatarLivePhaseA()`, which consults the actual
rail-preview cache authority before a nonempty visible frame can be accepted.
The frozen Avatar evidence shows why this boundary is necessary: the former
sequence produced a non-empty, 13-pixel rail-preview surface whose painter
could not see readable resources.

The repair belongs at the existing cache/publication boundary:

1. arm the selected bounded payload's compact semantic geometry under the
   existing live resource owner;
2. make its exact resource bank discoverable by the same cache lookup the
   painter uses;
3. only publish a non-empty Avatar target as a live visible owner when that
   exact predicate holds; otherwise retain the already-valid visible target or
   classify the candidate as coalesced before paint;
4. record an honest terminal target outcome with the full immutable identity.

This must not invoke repository/SQL, index construction, rich projection,
TextPainter construction, an eager all-target geometry pass, a cache-size
increase, or another cache/store/controller.  Phase-B remains optional.

## Latency strategy

FrameTiming already proves device-level Avatar budget misses, but does not
prove scroll physics is the source.  Re-measure the existing bounded collector
after correctness repair, correlate residual build/raster work to actual
resource activation and repaint bounds, and alter only a measured source.  The
same rule applies to Mind: its post-publication paint path is fast in frozen
evidence, so it receives a bounded pointer-to-visible-result trace before any
behavior change.

## Protected contracts

- Time semantic projection, exact-empty rendering, render-domain/extent
  authority and final-paint acknowledgement are unchanged.
- Financial query semantics, amount calculations, category/partner meaning,
  paging ownership and stale identity guards are unchanged.
- No rich projection or text shaping is moved into build/paint or a semantic
  tick.
- No second visible-frame store, LogBox, render surface, cache, controller or
  source of truth is introduced.
- Summary visual dimensions, typography, Stack order, and background-collapse
  behavior remain unchanged unless a targeted regression proves otherwise.

## Verification design

The tests use production parents with persistent dashboard/controller/cache/
viewport owners.  They verify actual selector ownership and actual
painter-discoverable resources, rather than callback starts alone.  Existing
Time and Mind tests stay unchanged as protection.  FrameTiming remains a
profile/device measurement rather than a device-specific unit-test threshold.

Physical acceptance remains **PENDING — USER ONLY**.
