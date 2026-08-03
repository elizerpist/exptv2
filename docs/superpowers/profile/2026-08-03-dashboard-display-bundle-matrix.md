# Dashboard profile measurement matrix

This protocol is deliberately executable only on a physical Android device in
Flutter profile mode. It records no fabricated p50/p90/p99 values in source
control.

## Instrumentation

`DashboardPerformanceTrace` is enabled by `kProfileMode` and records a fixed
numeric ring (512 events):

- `RAIL_FLING_PLAN_CREATED` — target logical index, gesture epoch;
- `RAIL_LOGICAL_INDEX_CROSSED` — crossed logical index, gesture epoch;
- `DISPLAY_SNAPSHOT_SELECTED` — row count, core revision;
- `LOG_PREVIEW_FIRST_PAINT` — visible row count, core revision;
- `PARENT_BUNDLE_READY` — finite child count, core revision;
- `FRAME_TIMING` — UI build and raster durations in microseconds.

The trace is separate from `FluviDiagnosticLogger`; it does not allocate FLOW
strings or rebuild the diagnostic panel.

## Device run

1. Install the GitHub Actions profile/release APK on the test phone.
2. Start the dashboard with an empty finite child and repeat the identical
   month rail fling 100 times; then repeat with a selected child containing
   nine rows.
3. Repeat each input with the debug panel closed and open, and with category
   SVGs cold and already warmed.
4. Export the numeric trace plus Flutter DevTools frame timeline. Calculate UI
   and raster p50/p90/p99/worst outside the application from those artifacts.
5. Record the exact device, Android version, build SHA and matrix cell with
   every result. A missing device run remains `USER VALIDATION PENDING`.

The target is deterministic by construction: the 100-run source regression
uses exact identical gesture inputs and verifies every output target. Device
measurement validates frame costs only; it is not allowed to retune physics.
