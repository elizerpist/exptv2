# Continuous swipe and lazy focus — acceptance checklist

## Architecture card

The existing `PreparedDashboardIndex` remains the source of truth for the
committed base query, its temporal topology, prepared rows and compact focus
membership. `DashboardEphemeralFocusDeriver` owns a lightweight, anchored
focus overlay rather than a second materialized dashboard universe.
`DashboardLogBoxPartnerSwipeController` owns one interaction's structural
segment lease and its translation; the static LogBox renderer omits that lease
and an isolated canonical-segment layer paints it exactly once. Translation is
presentation-only and never writes query, paging, or scroll state.

## Requirements

| ID | Source | Intended owner/code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SWP-01 | User: no dead-zone jump | Partner swipe recognizer/controller | Acquisition consumes/slides through arbitration continuously: no replayed 8px jump, while vertical/right intent remains rejected. | RED/GREEN gesture continuity test; physical slow-drag check. | NOT DONE |
| SWP-02 | User: x=0 is a waypoint | Swipe kinematics | Visual travel continues past `-globalLeft`, is bounded only by actual offscreen row travel, and commit threshold is independent. | RED/GREEN kinematics tests. | NOT DONE |
| SWP-03 | User: isolated canonical segment | Render surface + viewport presentation layer | Static surface excludes active entry once; active canonical segment is the only painted body and changes dx through retained transform rather than full-surface repaint. | Structural paint-count/repaint-boundary test; code inspection; physical check. | NOT DONE |
| SWP-04 | User: retain morphology | Prepared block geometry + active segment painter | Top/middle/bottom/singleton radii and bottom-shadow ownership remain exact during track/snap-back. | Existing and extended morphology tests. | NOT DONE |
| FOC-01 | User: lazy current root | Focus deriver/index contract | Prepared focus critical path does not call `zeroUniverse`, build 2014–2038 topology, or eagerly materialize all temporal frames. | RED/GREEN deriver instrumentation tests. | NOT DONE |
| FOC-02 | User: prepared hit means direct ready | Focus deriver/index | Membership hit has no worker, SQL, base scan or copied rows; current root only is materialized synchronously and later frames are lazy/memoized. | Fast-path and lazy-navigation tests. | NOT DONE |
| FOC-03 | User: no same-focus republish | Focus controller | Identical valid category+partner request is a semantic no-op with no new focus/index/navigation/scene publication. | Controller no-op regression and diagnostic assertion. | NOT DONE |
| RET-01 | User: retain base ready-ahead through focus | `CommittedLogViewportCache` + focus/base publication | Unchanged base identity/revision reactivates retained bounded pages 0–3 without Room; stale base invalidates safely. | Cache/publication regression and bounds test. | NOT DONE |
| DIA-01 | User: compact retention diagnostics | Focus scene retention owner | Retention identity/log uses compact fields/digest/counts, never serializes whole scene-window payload list. | Focus diagnostics structural test. | NOT DONE |
| REG-01 | User: preserve approved interaction contracts | Existing rail/vertical/query-sheet owners | Controllers/positions/physics, virtual geometry, cache misses and route-sensitive speculative gate retain their contracts. | Existing milestone/query-sheet/rail/vertical test suites. | NOT DONE |
| APK-01 | Global delivery + user | Standard `lib/main.dart` APK | Final pushed production SHA has successful GitHub human APK, downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256; physical validation explicitly remains human-owned. | GitHub Actions + local SHA check. | NOT DONE |

## Explicit non-goals

- No rail or vertical physics, paging-policy, page-size, lookahead, cache-limit,
  controller/position identity, or Query sheet lifecycle change.
- No duplicate swipe row, `Dismissible`, whole-row raster snapshot, per-move
  text/layout/data work, golden test, integration harness or automated input.
- No persistent-query mutation to emulate focus and no global focus cache.
