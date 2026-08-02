# Dashboard child-summary index and rail latency design

## Decision

The Room → native bridge → Flutter result route is not the one-second delay:
the supplied on-device traces place D8 → D10 at roughly 30–120 ms and the
native read at 15–57 ms.  The delay is therefore before the committed query,
and is longest for a ballistic fling.  A single-tap still waits for the
carousel's visual selection callback, so it can also be slower than a direct
SummaryPill date change.

The dashboard will not make the selected amount depend on the detailed query
for every rail child.  On rail open (and whenever the parent, direction, or
facets change), the dashboard reads one grouped, parent-scoped summary index.
While the rail is open, the amount projection looks up the displayed child in
that index.  The detailed query remains latest-wins and is still changed only
by a committed/settled scope.

```
parent scope + direction + facets
        │
        ├─ native GROUP BY child local period ──> bounded child-summary index
        │                                          (sparse: <= 12/31 rows)
        │
rail preview / tap / fling ──> map lookup ──> SummaryAmountView
        │
settled selection ───────────> existing CurrentQueryController detailed watch
```

## Ownership and reuse

| Concern | Owner | Rule |
| --- | --- | --- |
| Canonical direction/time/facet predicate | `FluviLedgerReadService.where` | The new grouped read reuses it; no Flutter aggregation or duplicate SQL predicate. |
| Child-summary transport | `DashboardLedgerRepository` + `MethodChannelDashboardLedgerRepository` | One typed, one-shot grouped read; not an EventChannel per preview. |
| Parent index cache and latest-wins load | `DashboardSummaryAmountController` | Bounded cache, navigation/query-aware; only it reads the child index. |
| Amount presentation | `DashboardSummaryAmountController` + `SummaryPillPresenter` | The amount subtree listens directly; preview never rebuilds `DashboardMotionHost`. |
| Detailed selected scope | Existing `CurrentQueryController` | Remains settle-only and keeps existing generation/identity rules. |
| Rail physics, target calculation and haptics | `lib/shared/motion/centered_carousel/**` | Untouched. |

## Query compatibility

The index request is constructed from the current direction/facets/refinements
with the navigation parent scope.  Native grouping uses the existing canonical
predicate and stored `booked_local_epoch_day` local-date representation.  Each
returned child includes its canonical child query key, direction and core
revision.  Flutter accepts an index entry only when all match the expected
child scope; missing buckets are represented as a compatible zero summary.

The cache key is parent canonical scope plus child period kind.  The cache is
bounded to 30 entries and is invalidated/reloaded whenever an observed core
revision no longer matches.  It is a summary cache only; it cannot replace the
detailed selected-scope watch.

## Timing instrumentation

The current `D10 summaryAmountViewRendered` is an input/build-adjacent marker,
not proof of paint.  It is replaced with:

- `D10A AMOUNT_STATE_BOUND` when the amount view receives presentation state;
- `D10B AMOUNT_TRANSITION_STARTED` only for a numeric text change;
- `D10C AMOUNT_FIRST_FRAME_PAINTED` in a guarded post-frame callback;
- `D10D AMOUNT_TRANSITION_COMPLETED` only for the active transition.

Each records the requested query key, previous/displayed and target amount in
the detail, current transition duration, loading and stale state.  The amount
crossfade remains a 120 ms, retargetable, latest-wins transition; stale/loading
state alone cannot start it.

Rail timing is emitted at adapter/application boundaries without touching the
shared carousel engine:

- `R1 TARGET_VISUALLY_CENTERED` when the adapter observes the centered item;
- `R2 SCROLL_ACTIVITY_IDLE` from the scroll end notification;
- `R3 SELECTION_SETTLED_CALLBACK` on the dashboard navigation callback;
- `R4 QUERY_SCOPE_COMMITTED` immediately before the existing query scope set.

The shared carousel deliberately encapsulates the exact ballistic target.  No
honest `R0 MOTION_TARGET_RESOLVED` can be produced before settlement without
adding an API to the prohibited shared engine.  The child-summary index removes
the product dependency on that hidden target: each visible preview is enough to
switch the amount in the next frame.  The logs therefore distinguish real
pre-settle latency from amount paint latency without mislabelling an event.

## Explicit non-goals

- No change to centered-carousel physics, friction, velocity bands,
  multipliers, springs, snapping, tap retargeting, cyclic mapping, geometry,
  clipping, or haptics.
- No timer/debounce/cooldown is added to settle detection.
- No per-preview repository read, native subscription, SQL aggregate, or
  detailed list read.
