# Bootstrap and preview diagnostics root-cause audit

## Current preview path

The centered carousel emits nearest semantic indices during drag and
ballistic motion. `TimeRefinementRail._queuePreview` forwards the logical index
to `DashboardTimeNavigationController.previewChildLogicalIndex`. The summary
controller then resolves the exact child scope, reads the already prepared
bundle/index in memory and publishes a complete `DashboardPresentationSnapshot`
through `DashboardPresentationStore`. The LogBox adapter listens to that same
store. The rail does not wait for query, repository, native watch or paging.

The existing `D11 LOG_BOX_ENTRY_COUNT_BOUND` line is count-oriented telemetry;
it is not a frame-presented proof. The new typed events must prove the full
snapshot and frame boundary without adding hot-path string work.

## Current semantic gaps

1. `DashboardPresentationSnapshot` exposes `isPreview`, but does not record
   whether the data came from a child bundle, memory cache, fresh query or live
   observer. This makes `preview=false`/`freshQuery` logs ambiguous when a fresh
   result is later displayed as a preview.
2. There is no bounded typed event ring buffer that joins crossing, selected,
   published and frame-presented generations.
3. `FluviAppShell` constructs the controller and immediately builds
   `CoreDashboard`; while the query lane is still loading, the dashboard can
   mount before a valid initial snapshot exists. The shell therefore needs an
   explicit readiness gate and external skeleton.
4. The existing child bundle already caps the projected preview page, but its
   budget is implicit/defaulted and there is no shared stress fixture or cache
   byte/row instrumentation proving the bound at large data volumes.

## Cold parent navigation root cause

Before the parent-display boundary was added, a horizontal parent navigation
changed the navigation target immediately. The summary controller then
resolved the new parent against the active query, which still belonged to the
outgoing parent. Because the target was not yet in the presentation store, it
created a `stalePreviousValue` loading metric with a null amount/count. That
metric was converted to the visible `—` presentation before the target read
and child bundle completed. The subsequent query result was correct; the
placeholder was an invalid intermediate publication, not a data error.

The corrected chain is:

```text
navigation target
  -> parent summary prewarm
  -> complete child preview bundle prewarm
  -> DashboardParentDisplayBundle readiness check
  -> one cached query-scope commit
  -> atomic visible parent snapshot
```

While the target bundle is cold, the outgoing snapshot remains the complete
visible state. No new label is exposed with a null amount/count, and no
`stalePreviousValue` placeholder is published. Adjacent parent prewarming is
scheduled after the active target commit and is not part of the rail preview
hot path.

## Non-causes and frozen surfaces

The current evidence does not indicate a rail physics or settle-only defect:
distinct child preview callbacks occur before settle, and child preview does
not start I/O. No physics, controller, position, simulation, snap, velocity,
item extent or gesture change is part of this slice.

## Hypotheses to test

- H1: typed diagnostics will show full preview publication already occurs; the
  missing proof is telemetry/frame observation rather than motion behavior.
- H2: an explicit shell bootstrap gate removes the initial dash by preventing
  `CoreDashboard` from mounting until a complete same-key snapshot is ready.
- H3: explicit row budgets and deterministic fixtures will prove bounded
  payload behavior without changing exact amount/count calculations.

## Read-layer measurement boundary

The Android Room schema already has the relevant ordering indexes on
`fluvi_ledger_entries`: direction/date/time/id and the category/partner/date
variants. The repository-side batch work must be measured against these
indexes, not inferred from Dart timings alone. The release/profile checklist
uses these SQLite probes on a representative database:

```sql
EXPLAIN QUERY PLAN
SELECT direction, booked_local_epoch_day, SUM(amount_scaled_100), COUNT(*)
FROM fluvi_ledger_entries
WHERE direction = ? AND booked_local_epoch_day >= ?
  AND booked_local_epoch_day < ?
GROUP BY direction, booked_local_epoch_day;

EXPLAIN QUERY PLAN
SELECT id, direction, amount_scaled_100, booked_local_epoch_day,
       booked_local_time_minutes
FROM fluvi_ledger_entries
WHERE direction = ? AND booked_local_epoch_day >= ?
  AND booked_local_epoch_day < ?
ORDER BY booked_local_epoch_day, booked_local_time_minutes, id
LIMIT ?;
```

`DashboardBatchMetrics` is the typed Flutter-side envelope for SQL time,
native projection, bridge payload, Dart decode/projection and cache insertion.
No physical device/profile runner was available in this local pass, so SQL
plans, RSS, GC, raster p95/p99 and bridge payload measurements remain release
verification items rather than invented values.
