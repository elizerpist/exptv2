# SummaryPill parent-navigation performance audit

Audit baseline: `3dd650c225c24bc4382ceddd208ec35fae2a0e4f`
Branch: `feature/dashboard-summary-navigation-performance`
Backup tag: `milestone/dashboard-rail-smoothness-3dd650c`

## Executive finding

The existing child rail has a semantic preview lane. The SummaryPill parent
lane does not. Its horizontal gesture is a shell gesture that chooses one
direction and invokes `moveParentNext`/`moveParentPrevious` on release. There
is no parent preview callback, parent motion epoch, or parent snapshot lookup
between the gesture and the committed navigation state.

Consequently, parent navigation currently follows this path:

```text
SummaryPill GestureDetector
  -> threshold/velocity decision on pan end
  -> DashboardTimeNavigationController._moveParent
  -> navigation state publish
  -> DashboardCoreController._handleRailChanged
  -> DashboardSummaryMetricsController synchronization
  -> CurrentQueryController/prewarm and child-bundle preparation
  -> committed scope/watch path
```

The visual label is read from `DashboardTimeNavigationController`, while the
amount/count are read from `DashboardPresentationStore.activeSnapshot`. A
target parent is therefore not represented by one preview snapshot during the
gesture. The previous task's store protection correctly prevents an invalid
placeholder or cross-key result from becoming visible, but it cannot make a
parent preview instant when no parent preview publish is attempted.

## Ownership map

| Concern | Current owner | Finding |
|---|---|---|
| Child rail pixels/physics | `CenteredCarouselController` + `TimeRefinementRail` | Frozen and already has semantic preview/idle/settle callbacks. |
| Parent SummaryPill gesture | `DashboardSummaryPill` | Gesture shell only; commits one parent on release. |
| Parent navigation state | `DashboardTimeNavigationController` | `parentPreview()` is read-only, but `_moveParent()` is the only state publish. |
| Parent metrics | `DashboardSummaryMetricsController` + `CurrentQueryController` | Resolves parent metrics after navigation state changes; no parent preview API. |
| Visible metrics truth | `DashboardPresentationStore` | Correct single store, but parent preview snapshots are not selected by a motion lane. |
| Child bundle preparation | `DashboardSummaryMetricsController` | Correctly cache/prewarm oriented, but it is currently part of parent commit readiness. |
| Live lease | `CurrentQueryController` / `DashboardLiveQueryLeaseCoordinator` | Previous milestone protects pending leases for child rail motion only. |
| Adjacent parent prewarm | `DashboardAdjacentParentPrewarmCoordinator` | Motion-aware for the child rail; parent motion has no corresponding lifecycle signal. |
| Summary text painting | `SummaryNavigationMotionRegion` | Paint-only and narrow, but it consumes navigation state rather than a parent preview presentation. |

## Proven cause of the parent hot-path work

`DashboardCoreController._handleRailChanged` treats a committed parent state
change as a request to run `_prepareAndCommitParent`. That method waits for a
parent `query.prewarm()` result and then for the child preview bundle before
calling `query.setTimeScope`. This is a valid committed-data path, but it is
not a preview path. It means parent navigation work can include repository
read, bundle preparation, and a broad query notification before the target
parent becomes the canonical displayed scope.

The existing `DashboardParentDisplayBundle` is a useful data contract for
bootstrap and prewarm readiness. It is not an independent UI truth source and
must remain so. The missing piece is an O(1) parent snapshot selection from
the central presentation store before the committed query transition.

## Parent/child cursor finding

`DashboardTimeNavigationController._parentStateFor` correctly changes the
parent cursor and clamps the child cursor for a new month/year. However, it
also prepares the full committed navigation state only at `_moveParent()`.
When the rail is open, the current child scope remains committed until the
parent transition completes. A future parent preview must therefore derive an
exact child key from the target parent and cursor, and may not relabel the old
child snapshot under the new parent label.

## Bootstrap finding

`DashboardBootstrapController` already gates the dashboard-dependent route on
an exact, non-loading, non-stale parent snapshot and, when available, a
complete current-parent child bundle. This is the correct lifecycle boundary.
The new work must preserve that gate and add regression coverage; it should
not create a second startup loader or render a temporary SummaryPill dash.

## Rebuild finding

`CoreDashboard` currently supplies `controller.rail` as the navigation
listenable and `controller.presentationStore` as the metrics listenable. The
SummaryPill has narrow text/amount slots, but the parent target is not present
in the store until the commit path. Parent preview work must publish through
that existing store and avoid notifying the aggregate dashboard listener.
The SummaryPill and rail controller instances are created above the preview
state and can remain stable.

## Root-cause conclusion

The lag is not caused by rail physics. It is caused by a missing parent
presentation lane and by making committed parent readiness (query result plus
child bundle) the first place where the target parent is selected. The
minimal fix is to add a parent semantic preview boundary that uses exact
same-key cached snapshots from `DashboardPresentationStore`, then leave query
commit, child bundle preparation, live lease activation and adjacent prewarm
behind the final settle. Parent motion must also participate in the existing
motion/prewarm/lease invalidation boundary, without introducing another scroll
engine or UI truth source.

## Verification gaps to close with red tests

1. Month and year parent preview sequences currently have no presentation test.
2. Parent preview has no no-I/O assertion.
3. Parent motion has no epoch-level idle/settle deduplication test.
4. Rail-open parent switching has no exact target-child presentation test.
5. Parent preview has no delayed old-result isolation test.
6. SummaryPill controller/header/root rebuild counters are not asserted for
   parent preview.
