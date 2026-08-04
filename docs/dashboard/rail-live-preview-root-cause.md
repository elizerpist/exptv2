# Rail live-preview root cause audit

Baseline audited: `561fe92` (`c0754f4` milestone branch tip)

## Event path

The current path is:

`CenteredCarouselController._handleScroll`
→ `_setSelection`
→ `_emitPreview`
→ `CenteredCarousel.onPreviewChanged`
→ `TimeRefinementRail._queuePreview`
→ `DashboardTimeNavigationController.previewChildLogicalIndex`
→ `DashboardSummaryMetricsController._handleNavigationChanged`
→ `_synchronize`
→ `_childMetricsFor`
→ `_publish`
→ `_publishToPresentationStore`
→ `DashboardPresentationStore.publish`
→ `DashboardLogPresentationAdapter._reproject`
→ `DashboardLogBoxViewport`.

The settle path is separate only at the final semantic state transition:

`CenteredCarouselController._handleScrollingChanged`
→ `_emitSettledForCommand`
→ `TimeRefinementRail._settleSelection`
→ `DashboardTimeNavigationController.settleChildLogicalIndex`
→ the same navigation listener and summary publication path.

## Finding 1: D11 is not evidence of a full LogBox snapshot

`DashboardLogBoxHeader` emits `D11 LOG_BOX_ENTRY_COUNT_BOUND` from the
`DashboardPresentationStore`-backed metrics builder. It proves that amount and
count reached the shared store, not that child rows reached the LogBox lane.

The current summary controller creates the preview snapshot in
`_publishToPresentationStore`. That method copies `existing?.entries` for the
child key. On the first child open, and for an uncached intermediate child,
there is no detailed child snapshot under that exact key, so the preview
snapshot contains the correct numeric metrics but an empty entry list. The
LogBox adapter therefore has nothing to render until a committed child query
later publishes its detailed page.

This is the D11 → full visible-presentation break. There is no missing rail
physics event and no need to change the motion engine. The missing input is a
complete child preview payload.

`D12 SUMMARY_METRICS_SELECTED` is additionally guarded by
`DashboardQueryDebug.tracePreviewMetrics`; when preview tracing is disabled,
its absence is a logging configuration detail, not proof that navigation did
not emit a preview.

## Finding 2: first open depends on the committed child read

Before the change, the closed-parent prewarm lane calls only
`DashboardChildSummaryRepository.readChildSummaries`. That produces aggregate
amount/count values and explicit zero buckets, but no rows or cursor. When the
rail opens, `DashboardCoreController._handleRailChanged` changes the current
query scope and `CurrentQueryController` starts the child watch/read path. The
first native/Room result is therefore the first moment at which a complete
child LogBox page can enter the store.

On the second open the detailed child result is already present in the query
cache/store, so the same path appears instant. The difference is cache
warmth, not a race in Money calculation.

## Finding 3: ballistic preview is not suppressed by the carousel

`CenteredCarouselController._handleScroll` does not check
`isBallistic`, `isScrolling`, `IdleScrollActivity`, `isSettled` or a debounce
before `_emitPreview`. The same callback is used for drag and ballistic
nearest-index changes. `TimeRefinementRail._queuePreview` also forwards every
changed logical index and calls `previewChildLogicalIndex` immediately.

The current “only final child is visible” symptom is therefore downstream:
each crossing reaches the summary metrics lane, but the store receives a
metric-only snapshot with no child rows. The final committed child query then
publishes the first detailed result, making the final child appear complete.

## Why single tap works

Tap-to-center uses the same carousel callback, but the tapped child commonly
has already been visited or has a detailed result in the bounded query/store
cache. The summary publication can then reuse non-empty `existing.entries`.
The first-open and ballistic cases expose the uncached-child payload gap.

## Why settle appears to fix it

Settle changes the navigation’s committed child and the core starts the live
child query. The native/Room observer emits a detailed `DashboardLedgerResult`
with rows, and `CurrentQueryController` publishes it to the same store. That
later result is the first full child snapshot for the key; settle itself is
not the correct source of preview data.

## Corrective boundary

The repair belongs between the parent read/prewarm lane and the presentation
store: a single batch child-preview bundle must contain complete first-page
snapshots for every bounded child. Crossing callbacks then perform only an
exact-key O(1) lookup and one atomic visible publish. The live lease/watch can
start after that publish for committed freshness, but it cannot own the first
visible child frame.

The rail physics, centered carousel controller, item extent, simulation,
velocity mapping, snap target and gesture ownership remain frozen. Changing
them would hide a data/presentation ownership problem and would invalidate the
working performance baseline.
