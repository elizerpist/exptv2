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

## Floating count and aligned outer surface amendment

### Scope and sources

- User requirement: the `N tranzakció listázva` label is fixed directly below
  the collapse handle; LogBox day groups scroll beneath and are occluded by it.
  A LogBox group’s left and right edges exactly match the SummaryPill’s outer
  edges.
- Accepted visual reference:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260803-062705.png`.
- Existing owners: `DashboardGeometryResolver` owns the SummaryPill and
  LogBox shared content bounds; `DashboardLogArea` owns the sole vertical
  scroll host; `DashboardLogAreaState` owns the immutable committed count.

### State and layer boundary

- No state, query, rail or motion owner changes. The count remains derived
  from the committed `DashboardLogAreaState` snapshot.
- `DashboardLogArea` keeps only the scrolling sliver tree and retains a
  header-height spacer so the initial first day begins below the fixed label.
- A presentation-only `DashboardLogBoxFloatingHeader` renders the same count
  in a sibling, non-scrollable stack layer. Its opaque page-surface paint
  occludes scrolling day groups at the header boundary.
- `DashboardGeometryResolver.logBoxHeaderBounds` remains the single geometry
  source for both the LogBox region and the floating header. No manual offset
  or duplicate gesture/hitbox is introduced.

### Reuse and verification

- The existing `DashboardLayoutMetrics.contentGutter` already defines the
  shared SummaryPill/LogBox outer width. Remove the LogBox’s second internal
  outer gutter rather than creating a second width policy.
- Test the scroll separation, fixed-header geometry and exact shared outer
  bounds. Confirm query count, rail preview isolation and LogBox laziness are
  unaffected.

## Preview LogBox performance-recovery amendment

### Scope and sources

- User requirement: while a rail fling crosses child scopes, the floating
  transaction count and LogBox must reflect every displayed child immediately;
  scroll and header collapse/expand must remain smooth.
- Trace evidence: `SUMMARY_METRICS_SELECTED` already emits every preview child,
  but `LOG_QUERY_COMMITTED` and `LOG_FIRST_PAGE_BOUND` only occur after
  `SELECTION_SETTLED_CALLBACK`. Final-target prefetch proves the data cache
  works but is too narrow to cover crossed children.
- Existing owners: `DashboardSummaryMetricsController` owns preview metrics;
  `CurrentQueryController` owns the shared bounded first-page cache and the
  sole committed query write path; `DashboardLogPageCoordinator` owns LogBox
  presentation, cursor-page cache and paging state.

### Single source and publication paths

| State | Owner | Publication rule |
| --- | --- | --- |
| Preview scope/metrics | `DashboardSummaryMetricsController` | Immutable scope/key/revision/amount/count snapshot; never commits a query |
| First-page warm data | `CurrentQueryController` LRU | Data-only prewarm; no watch, native subscription or visible query mutation |
| Preview LogBox state | `DashboardLogPageCoordinator` | O(1) cache selection from exact metrics; scoped loading only on cache miss |
| Committed LogBox state | `DashboardLogPageCoordinator` + `CurrentQueryController` | Settle still selects cache or creates exactly one normal committed read/watch |

No widget tree is cached or rendered offscreen. Only immutable page data and
preprojected presentation states are bounded and reused. The normal committed
query and the preview projection are deliberately separate lanes: the latter
cannot modify rail physics, navigation, watch ownership or persistent state.

### Warming policy

- MONTH and YEAR child rails are finite, so after their compatible child index
  is available the controller warms each child’s first LogBox page through the
  existing bounded LRU. The operation is deduplicated and low priority.
- SUM is unbounded, so it warms a window centred on the settled/target child;
  the radius is derived from the existing maximum fling range and remains
  bounded.
- A non-cached preview has an exact child metrics header and a child-scoped
  skeleton; the previous scope’s rows are never relabelled as the new scope.
- A distinct preview child causes no I/O: it uses only a canonical-key map
  lookup of already warmed data and presentation state.

### Render isolation

`CoreDashboard` retains the same `DashboardLogBoxViewport` widget instance
across `DashboardMotionHost` collapse/expand frames. Motion changes only its
geometry/render constraints; the LogBox’s own listenable rebuilds it when, and
only when, a preview/committed page state changes. The shared rail physics
configuration is not changed.
