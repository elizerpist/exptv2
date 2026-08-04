# Open-rail parent transition root cause

## Baseline

The investigation starts from `104c22f`, with the preserved smooth-rail
milestone at `3dd650c225c24bc4382ceddd208ec35fae2a0e4f`.

## Observed event path

The SummaryPill calls `DashboardCoreController.commitParentNavigation`. That
method previews a cached parent when possible, publishes the parent-motion
idle/settle markers, and then calls `DashboardTimeNavigationController`'s
generic `moveParentNext`/`moveParentPrevious` method.

The generic navigation method changes the parent cursors and recenters the
existing carousel, but it has no explicit parent-deck transition identity.
The core rail listener then sees a generic `parent` change and asynchronously
prepares a parent bundle. Its current commit uses the parent time scope in the
query lane, while an open rail's visible scope is the target child scope.

This leaves a window in which the parent owner, child deck owner, effective
child scope and committed query are derived by different paths. The resulting
child can be treated as a `childSettled` transition and fall back to a live
read. Closing the rail later forces the normal bundle synchronization, which
explains why close/reopen appears to fix the state.

## Callback race

`TimeRefinementRail` forwards selection settlement by logical index only.
There is no captured parent/deck epoch in the callback contract. Therefore a
settle callback delivered after `setRailOpen(false)`, or after a parent deck
replacement, can still call `settleChildLogicalIndex` against the new state.

The existing motion coordinator deduplicates idle and settle events inside its
motion epoch, but it does not validate the navigation parent/deck identity.

## Required correction

The open-rail SummaryPill path must resolve a complete target parent bundle,
retain and clamp the child ordinal, and atomically publish:

* target parent query key;
* target child-deck parent key;
* target child ordinal and child query key;
* direction, filters and revision;
* visible presentation epoch.

The generic parent movement path remains valid for a closed rail. Open-rail
navigation gets one explicit controller transition so it cannot be represented
as only `reason=childSettled`. A captured deck/presentation epoch guards every
delayed settle/preview callback. Cached target bundles publish before any live
lease/read path; cold targets keep the outgoing complete presentation until the
complete target bundle is available.

## Seed gate note

The constructor already defers `startQuery` when `autoStartQuery=false`, but
child preview synchronization can still be reached through later preparation
paths. The correction must make seed readiness an explicit prerequisite for
bundle request, bundle registration/publication, live lease and visible
presentation publication, and must reject any pre-seed revision-0 bundle after
the seed commit.
