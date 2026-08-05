# Dashboard motion/data root-cause audit

Date: 2026-08-05

Audited baseline: `16072f0ef633c27fca8f7aeea0c3d0c7305badc4`

Safety milestone: `bb6c294257b94859a902d445113ab3f739db0783`

Refactor branch: `refactor/dashboard-complete-motion-data-isolation`

## Executive finding

The centered-carousel target calculation is deterministic and data blind. The
observed density-dependent rail distance is caused after that calculation: a
semantic crossing synchronously enters the same Dart UI-isolate notification
graph that owns QueryKey construction, deck lookup, presentation snapshot
construction, amount/count binding, LogBox selection and, on misses or
structural navigation, repository/native preparation. That work competes with
the delivery of subsequent scroll ticks and animation frames. Missing ticks
change which semantic crossings are observed before the ballistic simulation
settles even though the simulation constants and target formula are unchanged.

The existing cache/preview work reduced the probability of the failure but did
not establish an architectural boundary. It left motion, navigation,
preparation, visible presentation and committed query ownership spread across
several mutually listening `ChangeNotifier`s. It also left an N-child SQL
implementation behind a nominally single platform request and performs the
large StandardMessageCodec/Dart materialization on the UI isolate.

This is why changing friction, velocity, thresholds, snap rules or debounce
would only mask the problem. The corrective boundary is a data-independent
Motion Kernel plus immutable, fully projected prepared decks selected through
one display-frame-coalesced visible-frame store. The committed live query is a
separate post-settle owner.

## Current end-to-end event graph

### Gesture to semantic crossing

```text
pointer/drag/fling
  -> ListView / Scrollable creates drag or BallisticScrollActivity
  -> ScrollPosition changes offset
  -> ScrollController listener
     CenteredCarouselController._handleScroll
  -> physical offset / itemExtent
  -> nearest physical index
  -> logical index through CenteredCarouselDataSource
  -> CenteredCarouselController._setSelection
  -> CenteredCarouselController.notifyListeners
     (all visible carousel item ListenableBuilders rebuild)
  -> CenteredCarouselController._emitPreview
  -> TimeRefinementRail._queuePreview
  -> TimeRailDataSourceFactory.valueForLogicalIndex
  -> DashboardTimeNavigationController.previewChildLogicalIndex
  -> DashboardTimeNavigationState.previewChild + pendingInteractionTarget
  -> DashboardTimeNavigationController.notifyListeners
```

Concrete owners:

- `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
  owns the `ScrollController`, observes its `ScrollPosition`, listens to
  `isScrollingNotifier`, calculates selection, emits preview and settle, and
  broadly notifies carousel item builders.
- `lib/shared/motion/centered_carousel/centered_carousel.dart` creates the
  `ListView.builder`, rebuilds a `CenterSnapScrollPhysics` configuration in
  `build`, synchronizes configuration in `didUpdateWidget`, and has post-frame
  recenter logic.
- `lib/features/dashboard/widgets/time_refinement_rail.dart` converts a motion
  callback into a dashboard navigation callback and emits diagnostic work.
- `lib/features/dashboard/time_navigation/application/
  dashboard_time_navigation_controller.dart` owns both structural navigation
  and transient preview state in the same `ChangeNotifier` and owns the
  centered-carousel controller.

### Semantic crossing to visible data

```text
DashboardTimeNavigationController.notifyListeners
  -> DashboardCoreController._handleRailChanged
  -> DashboardCoreController._summaryNavigationNotifier.notifyListeners
  -> DashboardSummaryMetricsController._handleNavigationChanged
  -> DashboardSummaryMetricsController._synchronize
  -> derive displayed parent/child scope
  -> CurrentLedgerQueryScope.copyWith
  -> CurrentLedgerQueryScope.key
     (sort categories, partners and refinements; join canonical string)
  -> DashboardParentBundleRegistry lookup, often through more than one caller
  -> choose child summary / child preview / store snapshot
  -> SummaryMetricsPresentation.fromMetrics
     (amount and count formatting)
  -> DashboardSummaryMetricsController._publish
  -> DashboardSummaryMetricsController._publishToPresentationStore
  -> DashboardPresentationSnapshot construction
     (copy entries, count groups, calculate content digest)
  -> DashboardPresentationStore.setVisibleTarget / publish / promote
  -> DashboardPresentationStore.notifyListeners and/or metadata listeners
  -> DashboardLogPresentationAdapter._reproject
  -> choose prepared LogBox VM or DashboardLogViewModelProjector.presentSnapshot
  -> DashboardLogPresentationAdapter.notifyListeners
  -> amount ListenableBuilder
  -> count/header ListenableBuilder
  -> LogBox viewport ListenableBuilder
  -> widget build/layout/paint
```

Concrete owners:

- `lib/features/dashboard/application/dashboard_core_controller.dart` is a
  900+ line aggregate notifier that owns and listens to rail, direction,
  expansion, current query, summary metrics, bundle registry, background work,
  LogBox adapter/paging, parent transition and rail-motion coordinators.
- `lib/features/dashboard/application/dashboard_summary_amount_controller.dart`
  is a 1,300+ line notifier that simultaneously owns QueryKey selection,
  metrics-only cache, parent bundles, in-flight preparation, seed handling,
  formatting, visible target selection, store publication and diagnostics.
- `lib/features/dashboard/query/application/dashboard_presentation_store.dart`
  stores raw entries as well as visible presentation. Snapshot construction
  performs group counting and content hashing synchronously.
- `lib/features/dashboard/logbox/application/
  dashboard_log_presentation_adapter.dart` listens to both the store's visual
  and metadata lanes. A settle promotion can therefore re-enter adapter work
  even if the visible values are unchanged.
- `lib/features/dashboard/logbox/application/dashboard_log_view_models.dart`
  groups, sorts and formats transaction rows when no prepared viewport is
  attached.
- `lib/features/dashboard/presentation/core_dashboard.dart` derives a new
  `ScopeSummaryMetrics` and `SummaryMetricsPresentation` inside its metrics
  builder instead of receiving one immutable visible frame.

### Cache miss and parent/plane path

```text
navigation notifier
  -> DashboardCoreController._handleRailChanged
  -> parent-bundle lookup
  -> on cold target: _prepareAndCommitParent / _commitPreparedOrColdTimeScope
  -> DashboardSummaryMetricsController.prepareParentDisplayBundle
  -> CurrentQueryController.prewarm/read
  -> DashboardChildPreviewRepository.readChildPreviewBundle
  -> MethodChannel.invokeMethod
  -> Android MainActivity handleQueryCall (Dispatchers.IO)
  -> FluviLedgerReadService.childPreviewBundle
  -> aggregate SQL
  -> for every child: queryTimelinePage SQL
  -> category and partner lookup
  -> Kotlin row mapping
  -> nested Map/List payload construction
  -> StandardMessageCodec encoding/result delivery
  -> Dart UI-isolate StandardMessageCodec decode
  -> MethodChannelDashboardLedgerRepository._decodeChildPreviewBundle
  -> rebuild scopes and QueryKeys; allocate every child/result/entry
  -> DashboardParentBundleEntry.fromDisplayBundle
  -> for every child: DashboardLogViewModelProjector.presentSnapshot
  -> register every child snapshot in DashboardPresentationStore
  -> bundle-ready/store/navigation notifications
  -> target visible publish
```

The native entry point runs SQL and Kotlin mapping on `Dispatchers.IO`, but
this does not isolate the whole operation. `MainActivity.dashboardChildPreviewBundleMap`
creates a nested transport graph, StandardMessageCodec delivers it, and
`MethodChannelDashboardLedgerRepository._decodeChildPreviewBundle` parses and
materializes it on the Dart UI isolate. The log's 7 ms Dart parse for only six
rows is direct evidence of this boundary cost.

The method name says “bundle”, but
`android/fluvi-core/src/main/kotlin/com/fluvi/core/query/
FluviLedgerReadService.kt::childPreviewBundle` executes
`queryTimelinePage(...)` inside `childValues.forEach`. A month deck therefore
uses up to 31 child page SQL calls and a year deck up to 12, in addition to the
aggregate and lookup queries. It is a single platform round-trip, not a
constant-query parent batch.

### Settle to committed live query

```text
ScrollPosition.isScrollingNotifier -> idle
  -> CenteredCarouselController._handleScrollingChanged
  -> _emitSettledForCommand / onSelectionSettled
  -> TimeRefinementRail._settleSelection
  -> DashboardCoreController.publishRailMotionSettle
  -> DashboardRailMotionCoordinator settle/idle bookkeeping
  -> DashboardTimeNavigationController.settleChildLogicalIndexIfCurrent
  -> DashboardTimeNavigationController._publish(child)
  -> the same summary/store publication graph
  -> CurrentQueryController.setTimeScope / commitPreparedResult
  -> DashboardLiveQueryLeaseCoordinator.request
  -> 120 ms Timer-based quiescence in the application shell configuration
  -> repository read or watch activation
  -> MethodChannel/EventChannel result
  -> CurrentQueryController._applyResult
  -> presentation store publish
  -> query and summary notifications
```

Although generations reject some stale results, there is no single committed
snapshot containing QueryKey, direction, filters, refinements, revision and
presentation epoch. Query, store and navigation each own part of acceptance.
The settle promotion also updates presentation metadata and can rebind the
LogBox or restart amount policy even when the pixels should not change.

## UI-isolate heavy work inventory

| Work | Concrete location | Why it is on the critical isolate |
|---|---|---|
| Canonical QueryKey sorting/string creation | `CurrentLedgerQueryScope._canonicalValue` | `key` recomputes rather than retaining an immutable canonical key; preview selection asks for it repeatedly. |
| Child scope and data-source allocation | `DashboardTimeNavigationController.childDataSource`, `TimeRailDataSourceFactory.forPlane` | New generated/cyclic source and lists are created from widget/controller reads. |
| Snapshot copying, group counting and hashing | `DashboardPresentationSnapshot` constructor | Runs synchronously before every store publication. |
| Amount/count formatting | `SummaryMetricsPresentation.fromMetrics` and `CoreDashboard._presentationFromStore` | Runs from store/listener builders and preview publication. |
| Log grouping and date sort | `DashboardLogViewModelProjector.presentSnapshot` | Called by bundle registration or adapter fallback on the UI isolate. |
| Row sort and row formatting | `DashboardLogViewModelProjector.presentSnapshot/presentRow` | Builds strings and view-model objects for all preview rows. |
| Whole-bundle LogBox projection | `DashboardParentBundleEntry.fromDisplayBundle` | Loops over all 12/28–31 children synchronously after bridge decode. |
| Whole-bundle store registration | `DashboardSummaryMetricsController._registerBundleSnapshots` | Constructs/publishes one snapshot per child and touches central store state. |
| Method-channel payload decode | Flutter StandardMessageCodec plus `MethodChannelDashboardLedgerRepository._decodeChildPreviewBundle` | Nested maps/lists and every entry are materialized on the UI isolate. |
| Store/adapter deep visual comparisons | `DashboardPresentationSnapshot.hasSameVisualValue`, `DashboardLogViewportState.hasSameVisualValue` | Walks groups and rows during publication/adapter selection. |
| Verbose diagnostic interpolation | FLOW call sites and `DashboardQueryDebug` callers | Some detail strings are constructed at call sites even when profile output is disabled. |
| Broad widget build/layout | root/summary/header/LogBox listeners | Multiple notifier lanes observe one logical transition. |

The Kotlin SQL, aggregate mapping and row mapping are on `Dispatchers.IO`.
They still contend indirectly through main-thread platform codec work and the
Dart result materialization, and the N-child query shape makes their latency
large enough to overlap motion and other animations.

## Notifications that can run during rail or SummaryPill motion

1. `CenteredCarouselController.notifyListeners` for selection and controller
   state. Every visible item uses this listable to derive selected styling.
2. `DashboardTimeNavigationController.notifyListeners` for every distinct
   preview child, despite the notifier also carrying parent, plane, rail-open
   and committed cursor state.
3. `DashboardCoreController._summaryNavigationNotifier.notifyListeners` from
   rail and parent paths.
4. `DashboardSummaryMetricsController.notifyListeners` after preview/store
   synchronization.
5. `DashboardPresentationStore.notifyListeners` on visible target and active
   snapshot changes.
6. `DashboardPresentationStore` metadata listeners on same-value promotion.
7. `DashboardLogPresentationAdapter.notifyListeners` after reproject/select.
8. `CurrentQueryController.notifyListeners` for loading, cache, read, live and
   error state.
9. `DashboardCoreController.notifyListeners` for structural child notifier
   forwarding and committed navigation.
10. Bootstrap/background completion notifications can arrive while an
    unrelated ticker is active. The background coordinator waits for
    `transientCallbackCount == 0`, but already-running native work and result
    decoding cannot be preempted, and the scheduler's repeated post-frame
    checks are themselves coupled to global ticker state.

`DashboardPresentationDiagnostics` has a scheduler-based coalescer, but only
for the `previewFramePresented` diagnostic record. Actual store publications
occur before it and are not coalesced.

## Widget rebuild and paint boundaries today

| Subtree | Current dependency | Consequence |
|---|---|---|
| Dashboard root | `DashboardMotionHost` structural animations plus `DashboardCoreController` forwarded notifications | Rail/plane/parent/collapse transitions rebuild the large positioned stack. |
| Rail | parent `CoreDashboard` build, navigation state, and carousel controller | Semantic preview does not always rebuild the root, but each scroll tick rebuilds visible item selector builders; physics/spec/data-source objects are recreated by builds. |
| SummaryPill navigation text | summary navigation notifier and staged transition state | Narrower than root, but parent preview still enters the data/store lane synchronously. |
| SummaryPill amount | presentation-store-derived formatted metrics | Every visible publication can update amount policy; preview and settle can target the same value twice. |
| Header/count | presentation store inside the outer LogBox adapter builder and another inner store builder | A single frame can rebuild the viewport parent and header through separate listener lanes. |
| LogBox viewport | `DashboardLogPresentationAdapter` | State/controller are stable while mounted, but VM selection/projection and whole viewport build are coupled to central store publications. |
| Direction SVG pulse | a leaf `AnimationController` and cached SVG child during its own ticks | Its controller is reasonably isolated, but any synchronous UI-isolate parse/projection elsewhere blocks its frames. |
| SummaryPill shell/text animation | local animation controllers | Local identity is stable, but `_commitWithShellReturn` currently invokes the commit callback before starting shell return; data work can therefore delay animation start. |

Dynamic `Opacity` layers in the rail reveal, amount crossfade and summary text
transition can add raster saveLayer cost. They are not the data-dependent root
cause, but profile measurements must include them and preserve their visual
timing while the ownership boundary is changed.

## Controller, position, physics and viewport identity lifecycle

- `DashboardTimeNavigationController` constructs one
  `CenteredCarouselController`, and that controller constructs one
  `ScrollController`. Those identities are stable for the controller lifetime.
- `CenteredCarousel` supplies a newly constructed `CenterSnapScrollPhysics` to
  `ListView.builder` on every widget build. Flutter may make a new applied
  physics chain/position relationship when configuration changes.
- `CenteredCarousel.didUpdateWidget` reconfigures the controller and can
  recenter when source/spec/config changes. `TimeRailDataSourceFactory` creates
  new source/list identities, so parent/plane builds create avoidable config
  churn.
- `CenteredCarousel._scheduleRecenter` uses a post-frame callback on viewport
  changes. Navigation methods also call `jumpToIndexSilently` before publishing
  structural changes.
- `DashboardLogBoxViewportState` constructs one `ScrollController`; constant
  widget keys preserve it while the subtree remains mounted. There is no root
  QueryKey key today, which is correct. The adapter/store metadata lanes still
  make it rebuild and compare/project content.
- Summary shell, summary text, collapse, rail reveal and direction pulse
  animation controllers are stable in their respective `State` owners. They
  stall because all Dart UI work shares the isolate, not because each pulse
  tick recreates its controller.

## Symptom-by-symptom causal explanation

### Populated data shortens or destabilizes fling

More populated child frames create more bridge objects, projection work, row
comparisons, widget builds, layout and paint. Semantic crossings synchronously
enter those lanes. The UI isolate misses scroll/animation scheduling windows;
therefore fewer `ScrollPosition` changes and nearest-index transitions are
processed before idle. Empty children avoid most row work. The physical
simulation constants are identical, but the event delivery environment is not.

### First rail use has no intermediate complete content

Before a full child bundle is warm, the metrics-only child index contains
amount/count but not LogBox rows. Preview publication can therefore select
numeric values while the detailed frame is absent. The committed settle later
starts/readies the exact child query and supplies the first rows. A warm bundle
already contains per-child snapshots, so subsequent crossings appear complete.

### Warm state behaves better

Warm parent bundles skip SQL, platform codec, Dart parse and full bundle
projection. Lookup becomes closer to the intended O(1) path, although snapshot
construction, formatting, store fan-out and widget work still remain. Cache
warmth changes performance because it is compensating for a missing boundary.

### Identical fling travels different distances

`CenterSnapScrollPhysics` deterministically maps the same initial position and
velocity to the same target. The gesture-to-physics input can nevertheless be
sampled differently when the UI isolate is blocked, and semantic preview work
can delay subsequent scroll activity/idle notifications. Multiple idle/settle
events arise from recenter/configuration and the separate pointer/scroll
lifecycle. Thus observed distance varies while the pure target function passes
repeatability tests.

### Year to month is worse than month to day

The year parent path constructs a 12-child deck whose populated months can each
carry a full first page; mapping and LogBox projection can therefore touch far
more rows than a six-nonempty-day month example. It also combines year-parent
navigation, month catalog replacement and bundle/store notifications. The
current native code performs one page SQL per non-empty month. The cost is tied
to row distribution, not merely to the number of visible rail labels.

### SUM/plane transitions stall the SVG pulse

Plane and direction transitions enter `DashboardCoreController`, query
preparation, bundle parsing and root structural notifications while the pulse
and SummaryPill tick on the same Dart UI isolate. The SVG leaf is locally
isolated from data notifier rebuilds, but no Flutter subtree can animate while
the isolate is executing a long synchronous decode/projection/build task.

### Open-rail parent publication waits for a bundle

`DashboardCoreController` deliberately keeps the outgoing coherent snapshot
while `_prepareAndCommitParent` resolves a cold target. This avoids a mixed or
placeholder frame, but it couples navigation completion to data readiness.
The navigation controller also recenters and publishes structural state around
that asynchronous handoff. A warm registry entry hides the delay; a cold miss
does not. The correct design keeps the motion/navigation epoch independent,
maps the retained semantic child immediately, and atomically swaps only a full
prepared frame when the deck completes.

### Seed revision zero can leak into preparation

Bootstrap/query start is gated in the shell, and later patches clear several
caches after seed. The deck key itself does not make `coreRevision > 0` a
construction invariant, and preparation/store types can represent revision
zero. A request that began before the seed can complete later unless every
registration/publication boundary rejects it. Generation checks spread across
controllers are not a substitute for a seed-closed prepared-state owner.

## Root cause, stated precisely

The root cause is not simply “main isolate load”. It is the absence of a
one-way ownership boundary:

1. transient motion mutates the same navigation notifier as committed state;
2. that notifier synchronously derives QueryKeys and enters summary/cache/store
   logic;
3. visible amount, count and LogBox are separate publications/listeners instead
   of one immutable frame;
4. the cache stores several representations (metrics index, child bundle,
   presentation snapshots) and a miss can begin preparation from navigation;
5. native “batch” preparation performs N child SQL reads;
6. nested codec payload and Dart projection are materialized on the UI isolate;
7. settle re-enters visual publication before/while committed live ownership is
   changed;
8. the widget tree has multiple overlapping notification lanes, so one semantic
   transition fans out into formatting, comparisons, builds, layouts and paint.

The refactor must remove every arrow from motion to repository/preparation and
replace the visible fan-out with:

```text
ScrollPosition
  -> logical index
  -> immutable semantic catalog O(1)
  -> immutable prepared frame O(1)
  -> one latest-target publication per display frame
  -> localized amount/count/LogBox/label listeners
```

Settle then promotes the already visible identity without a visual
notification and hands ownership to one generation/epoch-guarded committed
live lease.
