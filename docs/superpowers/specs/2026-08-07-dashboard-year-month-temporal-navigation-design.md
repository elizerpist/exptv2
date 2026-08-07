# Dashboard year/month isolation and temporal navigation design

Date: 2026-08-07

Status: approved by the user's prescriptive milestone-lock specification.

Execution: one agent, inline; no delegation.

## Job to be done

Keep the current prepared-index data runtime and the perfect month/day rail,
remove the residual year/month render-density cost, and make every plane target
derive from one canonical semantic time anchor.

## Architecture card

| Concern | Decision |
|---|---|
| Feature boundary | Existing `features/dashboard/time_navigation`, `runtime`, `visible` and `logbox` modules. No new dashboard runtime/coordinator. |
| Canonical state owner | `DashboardNavigationController` owns one immutable `DashboardTemporalAnchor` as part of its structural snapshot. |
| Write path | Explicit semantic parent/plane/rail/direction commits and epoch-guarded settle retention only. |
| Derived state | `yearCursor`, `monthCursor`, `dayCursor` and retained-child accessors become views of the anchor, not stored competing values. Parent query scope is validated/derived atomically from plane + anchor. |
| Read path | Plane transition: anchor → target plane parent/child → one navigation commit → prepared-index O(1) frame reference → one coalesced visible publish. |
| Presentation split | Each prepared frame exposes one scalar `PreparedSummaryFrame` and one immutable `PreparedLogViewportPayload` reference, both with precomputed IDs. |
| Motion boundary | `TimeRefinementRail` continues to receive only Motion Kernel/catalog/controller/physics inputs. Physics/controller/position sources remain unchanged. |
| Data boundary | Bootstrap/index/revision/paging ownership remains unchanged. Navigation has no repository, SQL, channel or builder capability. |
| Failure semantics | Stale epoch/parent/catalog callbacks are rejected before anchor mutation; invalid parent/anchor combinations fail synchronously. |
| Observability | Existing bounded diagnostics are extended with typed temporal derivation and year/month selection/apply records; disabled mode remains a no-op. |

## Canonical temporal anchor

`DashboardTemporalAnchor` carries:

- visible year, month and day;
- source plane, parent key, child key and child ordinal;
- direction and canonical filter/refinement identity;
- revision and navigation epoch.

The anchor is the sole temporal input to plane transitions. The controller may
retain compatibility getters, but they must read the anchor and cannot store
independent values.

The target rules are fixed:

```text
SUM(anchor Y/M/D)   -> Year parent Y, child M
Year(anchor Y/M/D)  -> Month parent Y-M, child D
Month(anchor Y/M/D) -> Year parent Y, child M
Year(anchor Y/M/D)  -> SUM child Y
```

Month/day clamping occurs once while deriving a new parent month. A transition
never reads the committed frame or a widget-local selected index to recover a
date and never schedules a corrective jump.

## Year/month presentation path

The common hot path remains:

```text
ScrollPosition
  -> semantic logical index
  -> immutable catalog entry
  -> PreparedDashboardIndex O(1) lookup
  -> PreparedSummaryFrame + logViewportId pointer
  -> last target in the display frame
  -> lane-local publish
```

The target change is after lookup. Month frames must not cause row-collection
equality/hash/copy or eager offscreen LogBox construction. The LogBox keeps its
State, vertical controller and lazy sliver; it swaps one prepared bounded
payload reference. Only the viewport rows needed by Flutter may build.

The month/day path uses the same neutral primitives and must produce an exact
regression match. No plane-specific physics or velocity behavior exists.

## Proof order

1. Preserve milestone hashes and baseline tests.
2. Reproduce the real 24-preview-row/94-entry month rather than the old 9-row
   synthetic approximation.
3. Measure selection, notification, build, layout and paint separately.
4. Write failing temporal ownership and year/month render-boundary tests.
5. Implement only the anchor ownership and evidenced post-lookup isolation.
6. Re-run the identical month/day and year/month inputs and exact hash gate.

The release gate is
`docs/superpowers/checklists/2026-08-07-dashboard-year-month-temporal-navigation.md`.
