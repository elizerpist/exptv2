# Balance linked carousel-detail design

## Goal

Make the upper Balance carousel the local topic selector for the existing lower
Balance card. The four implemented topics are Cashflow, Latest transaction,
Top category, and Top partner. The fifth finite carousel item remains the
existing prototype placeholder.

## References and constraints

- Product brief supplied 2026-09-23.
- Visual composition references:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260923-001029.png`
  and
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260923-001026.png`.
- `BalanceHeaderHistoryChart` and its Compound line-chart option remain
  Header-only. They are not lower-card renderers.
- Reuse the existing `CenteredCarousel` controller, position and
  `CenteredCarouselMotionProfiles.timeRefinementRail` unchanged.
- Preserve existing lower-card bounds, cascade, dots, Balance Header, Mind,
  Budget, Summary interaction, Query and repository owners.

## Architecture card

### Single source and write path

`DashboardCoreController` publishes a bounded immutable
`DashboardBalanceLinkedPresentation` from the already resident prepared
directional membership for the current `DashboardVisibleFrame` scope and
direction. It is the only financial aggregation owner. The Balance UI only
renders that value object and sends a local carousel topic intent.

| State | Owner | Lifetime | Write/publication path |
| --- | --- | --- | --- |
| Scoped Cashflow, latest list and rankings | `DashboardCoreController` | exact prepared identity + visible scope/direction | synchronous visible-frame publication from resident membership |
| Selected lower-card topic | Balance surface state | mounted Balance surface | existing `CenteredCarousel.onSelectedChanged` |
| Pair/day inspection | existing Cashflow chart state | mounted Cashflow lower card | local pointer selection only |

No widget, painter or carousel callback may access Room, a repository, Query
construction, an index build, scene preparation or TextPainter readiness.

### Projection data

- **Cashflow:** reuse `DashboardBalancePrimaryPresentation`; it combines both
  directions for the active Summary scope.
- **Latest transaction:** sort the two scoped prepared memberships by the
  existing occurrence/id tie-break and expose the newest five across both
  directions. The small card shows rank one.
- **Top category:** group only the active `DashboardVisibleFrame.direction` by
  category ID and rank by summed absolute minor amount. Display name/color/icon
  come from the admitted entries; ties are deterministic by display name then
  stable ID.
- **Top partner:** group only the active direction by partner ID and rank by
  transaction count. Its visual uses the representative entry's existing
  category visual metadata; ties follow the same deterministic rule.

The Core cache identity contains prepared generation, core revision, exact
scope and active direction. Switching Summary or direction publishes only the
resident matching immutable presentation, with no asynchronous prerequisite.

### UI composition

`BalanceCarouselTopic` has five stable logical values:

1. `cashflow`
2. `latestTransaction`
3. `topCategory`
4. `topPartner`
5. `prototype`

The CenteredCarousel remains its sole gesture, controller and ScrollPosition
owner. Its existing selection callback changes the Balance-local topic state;
the lower card switches content from this state without mutating Summary.

Cashflow keeps the existing SUM/YEAR paired bars and MONTH local cumulative
step lines; DAY remains the existing no-chart lower shell. Latest transaction
uses a bounded five-row list. The two ranking cards use a white content shell,
one featured first row, four ranked rows, entry-derived colorful badge/icon
art, and right-aligned amount or transaction-count values.

## Verification

- Unit/Core: scoped latest, active-direction category amount rank, and
  active-direction partner count rank; identity reuse and zero repository/index
  work on Summary/direction crossing.
- Widget: every center topic selects its matching lower detail, Cashflow
  regressions remain correct, ranking composition contains one featured and
  remaining ranked rows, and the prototype stays a placeholder.
- Boundary: Balance presentation imports only immutable application contracts;
  no presentation source references a repository/Room API.
- Regression: shared carousel identity/motion and existing Balance/Mind tests.

## Explicit non-goals

- No DAY Cashflow chart.
- No new fifth product topic.
- No Header Compound chart reuse in the lower card.
- No changes to Header all-time financial authority.
