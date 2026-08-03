# Dashboard LogBox design

## Architecture card

### Scope and sources

- User requirement: scope-correct, Spendee Balance-shaped, day-grouped and
  paged Fluvi LogBox with rail-safe prefetch.
- Accepted visual references: `docs/dashboard/logbox-spendee-balance-mapping.md`
  and its audited Spendee source paths.
- Existing Fluvi owners: `CurrentQueryController`,
  `DashboardSummaryMetricsController`, `DashboardTimeNavigationController`,
  `FluviLedgerReadService`, `CategoryVisualResolver` and `AppRadii`.

### Single source and write path

- Canonical committed scope: `CurrentQueryController.state.scope`.
- Canonical committed data: exact-key/revision `DashboardLedgerResult` first
  page plus `DashboardLogPageCoordinator` pages for that scope.
- Summary preview: `DashboardSummaryMetricsController`; it is presentation
  only and cannot mutate or rebind LogBox data.
- Only write path: rail settle/parent/plane/direction intent →
  `DashboardCoreController` → `CurrentQueryController`.
- Error/retry owner: `DashboardLogPageCoordinator`.

### State ownership

| State | Owner | Publication rule |
| --- | --- | --- |
| Rail preview metrics | `DashboardSummaryMetricsController` | SummaryPill only; never list query/rebind |
| Committed query scope | `CurrentQueryController` | exact query key; latest-wins watch/cache selection |
| First LogBox page | current query result / prefetch cache | bound only when key and revision match committed scope |
| Subsequent pages and LRU | `DashboardLogPageCoordinator` | page cursor, key and revision must match active state |
| Motion-target prefetch intent | shared centered-carousel callback → coordinator | data-only, latest-wins, no visible scope mutation |
| UI scroll and row rendering | `DashboardLogArea` | pure rendering and user intents only |

### Layer flow

`DashboardLogArea` → `DashboardLogPageCoordinator` →
`DashboardLedgerRepository` → method channel → `FluviLedgerReadService` →
Room. The coordinator never owns navigation and UI never owns SQL/cache I/O.

### Reuse and centralization

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Scope/key/revision | `CurrentQueryController` and `CurrentLedgerQueryScope` | Extend; no LogBox query owner |
| Rail final target | `CenteredCarousel` physics/controller | Add an optional shared target callback; do not duplicate fling math |
| Category visual | `CategoryVisualResolver` / `CategoryVisualBadge` | Reuse directly |
| Radius/token/typography | `AppRadii` / `FluviVisualTokens` | Extend semantic LogBox tokens only |
| Query page cache | current query’s first-page LRU | coordinator owns additional cursor pages under one bounded LRU policy |

## Design decisions

1. The native core returns a page measured in complete local-day groups. It
   obtains the next N dates and then batch-loads all rows for those dates,
   using the exact same predicate/timezone rule as summary reads. This avoids
   N+1 and never splits a day.
2. `DashboardLedgerResult` carries the first day-group page and the aggregate
   from the same committed scope. Its summary fields therefore remain the
   canonical committed metrics for the LogBox snapshot.
3. `DashboardCommittedQuerySnapshot` is derived only from an exact
   query-key/revision result. It pairs committed metrics with LogBox state;
   preview metrics never enter it.
4. The LogBox is the dashboard's only vertical scroll host beneath the fixed
   controls; it is not nested in another vertical list. It uses
   `SliverMainAxisGroup` + `SliverFixedExtentList.builder`, group/row
   `ValueKey`s, a 360px cache extent, sliver-level rounded clipping and
   immutable preformatted view models. A dense day therefore stays joined
   visually while its rows remain lazy.
5. First pages are prefetched from the shared rail engine’s already computed
   target; the prefetch is cancellable/latest-wins and only fills data cache.
   Settle chooses cache or begins the normal committed read without waiting on
   motion.
