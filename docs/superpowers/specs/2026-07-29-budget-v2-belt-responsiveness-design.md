# Budget V2 avatar belt responsiveness design

## Context

The tested `fd26ba9` V2 rail is centred from its real viewport, but its
interaction model still differs from a continuous belt.  The supplied
22:10 trace proves two separate failures:

1. `SpendeeBudgetV2AvatarCarousel` mounts only logical offsets `-2…2`.
   The next source avatar is therefore first built while a swipe is already
   underway.  Its `CategorySlotIcon` first-render diagnostics occur during
   direct dragging.
2. The V2 dashboard cancels the final filter only from
   `onHorizontalDragStart`.  Flutter can recognise that gesture after the
   360ms idle timer, so the timer may synchronously publish the store filter
   immediately before the next swipe.  The trace shows a commit at 22:10:13.31
   followed by the rail drag starting at 22:10:13.34.

The standard Budget controller remains the physics reference.  Its category
filtering is already performant; this repair applies the same state boundary
to V2 rather than changing the shared filter implementation.

## Options considered

### A. Keep five slots and only cancel on drag recognition

This is the current architecture.  It cannot prevent a first render at the
visible edge or stop an idle publish between pointer-down and gesture-arena
resolution.  Rejected.

### B. Persistent seven-slot V2 belt with raw pointer cancellation

Render five visible slots plus an invisible, retained entry slot at each edge
(`-3…3`).  Slot widgets use the category index as their identity, so an entry
avatar keeps its decoded SVG/icon subtree as it moves from `±3` to `±2`.
Its opacity interpolates from zero outside the belt to fully visible by the
outer visible slot.  A `Listener.onPointerDown` cancels the pending idle
filter before the horizontal gesture recogniser runs.

Direct-drag settlement remains local through the idle period: it does not
change the chart/mother-card preview key or rebuild the dashboard.  The final
timer publishes the selected key once.  Remote chart/legend/tap steps keep
their existing per-step chart previews.

Recommended.  It preserves the working standard-Budget data/filter path while
giving V2 the physical continuity its richer avatar widgets require.

### C. Replace the rail with `PageView` or a scrollable list

This would introduce a second physics/selection state, make wrapped category
ordering and long-press handling more complex, and would not solve the
dashboard publication race by itself.  Rejected.

## Approved implementation boundary

The user explicitly requested a responsive belt carousel.  This design treats
that instruction as approval for option B.

### Carousel ownership

`spendee_budget_v2_avatar_carousel.dart` remains the sole owner of drag,
release and snap motion.  It gains:

- stable index-keyed slot identity;
- seven unique logical positions (`-3…3`) when there are enough categories;
- edge opacity and ignored pointer input for fully invisible buffer slots;
- a raw pointer-down callback that does not start drag physics;
- a settled callback that reports whether the interaction was a direct drag.

The five normal positions remain the only visible avatars at rest.  The two
edge entries are already mounted, non-painting and non-interactive until they
cross the outer edge.  Small belts retain one unique widget per category.

### Dashboard ownership

`spendee_balance_dashboard.dart` owns only final selection publication:

- raw pointer down cancels the pending `Timer` immediately;
- direct-drag settlement records/schedules the final bar without changing
  `_budgetV2RequestedBarKey` or `_budgetV2PreviewBarKey`;
- forced remote selections carry an epoch so they can reclaim the local belt
  even if the published index is unchanged; a nullable default-overview key
  compares by its resolved logical index, preventing a return to overview
  from publishing or scheduling an unnecessary filter;
- the 360ms idle deadline still batches the expensive filter, but it is no
  longer an input cooldown because a new touch preempts it before gesture
  recognition;
- remote chart/legend/tap selection remains on the existing stepped-preview
  path.

### Diagnostics

No per-frame or per-tick logging is added.  Existing start/settle/cancel logs
remain bounded.  At most one existing `filter_cancel` entry records a
pointer-down pre-emption when a pending filter actually existed.

## Acceptance

- BUDGETV2-042: entering avatars are already mounted and fade into the belt;
  no third visible neighbour appears at rest.
- BUDGETV2-043: pointer-down cancels a pending publish before drag
  recognition; tap and long-press contracts remain intact.
- BUDGETV2-044: direct swipe settlement does not rebuild chart data before the
  idle publication; remote stepped charts still do.
- BUDGETV2-045: diagnostics remain interaction-scoped.

## Verification

Widget regressions will cover retained entry slots, entry opacity during a
drag, pointer-down timer cancellation, direct-settle chart deferral, remote
chart-step preservation, and bounded diagnostics.  The focused V2 carousel,
V2 production contract and normal Budget reference tests will run in Ubuntu
proot, followed by scoped analysis.  A fresh GitHub Actions debug APK will be
installed/downloaded for device verification.
