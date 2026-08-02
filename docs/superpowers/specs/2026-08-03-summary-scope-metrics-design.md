# Summary scope metrics design

## Goal

Ensure that the amount in the SummaryPill and the transaction count in the
LogBox always describe the exact same canonical ledger scope, including every
open-rail preview child, without adding a count-specific query or affecting
rail physics, haptics, query commit timing, or SummaryPill motion.

## Root-cause findings

The Android grouped child-summary query already returns `SUM(amount_scaled_100)`
and `COUNT(*)` together. Its Dart transport and
`DashboardTimeChildSummary` already retain both values. The existing indexed
path also reads both from the same bucket.

The unsafe path is the cache-miss fallback in
`DashboardSummaryAmountController`: it publishes
`SummaryPillPresenter.presentAmount(query: _query.state)`. A
`CurrentQueryController` scope change intentionally retains the prior
`DashboardLedgerResult` while the next watch is loading. The presenter assigns
the current scope key while using the retained result's amount and count. That
permits a previous parent result to be described by a new child scope.

The current `SummaryAmountPresentation` name obscures its dual metric role and
does not make scope identity a first-class invariant.

## Selected architecture

### Canonical metrics value

`ScopeSummaryMetrics` is an immutable domain/read-model value with:

- complete `CurrentLedgerQueryScope`;
- canonical query key and core revision;
- `totalMinor` and `entryCount` from the same record;
- `SummaryMetricsSource`;
- loading, stale, and error flags.

`SummaryMetricsPresentation` is the only formatted view model consumed by
SummaryPill amount and LogBox count. It is derived from exactly one
`ScopeSummaryMetrics` value.

### One state owner

`DashboardSummaryMetricsController` replaces the amount-named presentation
owner. It remains a presentation/application projection over two existing
inputs only:

1. `CurrentQueryController` for committed parent or settled detailed results;
2. `DashboardTimeNavigationController` plus the bounded
   `DashboardTimeChildSummaryIndex` cache for an open rail's displayed child.

The controller is the sole write path for the metrics presentation. Widgets
only render it through targeted listenables. Neither widget performs scope
resolution, database access, or fallback selection.

### Scope selection

`displayedMetricsScope` follows the navigation state:

- rail closed: `parentScope`;
- rail open: `childToScope(parentScope, displayedChild)`;
- `displayedChild` priority: preview, pending target, then settled child.

`committedEffectiveScope` remains owned by the navigation/query controllers and
continues to change only on existing commits. Preview performs one compatible
map lookup and never starts a watch, native subscription, or detailed query.

### Parent, child, zero, and loading values

- A compatible complete child index maps a child key to one bucket containing
  both amount and count.
- A missing bucket in a complete index becomes an explicit zero metrics value
  for its canonical child scope.
- An incompatible or unavailable index produces one loading/stale metrics
  value for the displayed scope. It must never borrow the parent count or page
  length.
- A parent result is usable only when its result query key equals its declared
  current query scope. Otherwise the controller publishes loading/stale
  metrics, never relabels retained parent values as child metrics.

### Boundary rules

- Android Room remains the only SQL owner. The existing grouped query remains
  the one source of `SUM` plus `COUNT(*)`; it gains explicit index-completeness
  metadata and tests rather than a new count query.
- Query state remains in `CurrentQueryController` and navigation state remains
  in `DashboardTimeNavigationController`.
- Motion controllers, haptics, carousel physics, and the detailed LogBox list
  do not consume or mutate metrics state.
- The metrics controller publishes a dedicated
  `D12 SUMMARY_METRICS_SELECTED` diagnostic only when a selected metrics value
  changes; it never logs animation frames.

## Alternatives rejected

1. A separate child count query would add I/O and latency to the rail preview
   hot path.
2. A small parent-count fallback patch would retain the unsafe split between
   retained detailed results and child-summary values.
3. Making detailed queries own all displayed metrics would remove immediate
   preview feedback and regress the already accepted rail performance.

## Verification

- Dart unit tests cover SUM/YEAR/MONTH open and closed scope mapping, exact
  child regression fixtures, zero buckets, preview priority, settle stability,
  direction/facet compatibility, and no-fallback loading behavior.
- Widget tests prove SummaryPill and LogBox receive the same metrics
  presentation.
- Room integration proves a real grouped predicate returns the parent and
  child amount/count pairs from one SQL read-model.
- A 100-preview-tick test records zero detailed queries, watches, native
  subscriptions, and index reads after preload.
- Existing centered-carousel physics snapshots and rail/query regressions stay
  green without changes to their preset files.
