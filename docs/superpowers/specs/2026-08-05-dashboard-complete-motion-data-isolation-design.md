# Dashboard complete motion/data isolation design

Date: 2026-08-05

Status: approved by the user's prescriptive architecture request

Branch: `refactor/dashboard-complete-motion-data-isolation`

This document records the one implementation design. The user explicitly
requested no A/B/C alternatives and supplied the required architecture. The
choices below make those requirements concrete for this repository.

## Dashboard complete motion/data isolation architecture card

### Scope and sources

- User requirement: replace the dashboard interaction/data presentation
  architecture so rail, SummaryPill, SVG pulse and all dashboard animation are
  independent of storage, data density, cache state, native bridge work and
  LogBox rendering.
- Accepted reference paths:
  - `docs/dashboard/dashboard-motion-data-root-cause.md`
  - the 2026-08-05 user specification in this task
  - `docs/superpowers/checklists/
    2026-08-05-dashboard-complete-motion-data-isolation.md`
- Existing implementation paths:
  - `lib/shared/motion/centered_carousel/`
  - `lib/features/dashboard/application/`
  - `lib/features/dashboard/time_navigation/`
  - `lib/features/dashboard/query/`
  - `lib/features/dashboard/logbox/`
  - `lib/features/dashboard/presentation/`
  - `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/`
  - `android/app/src/main/kotlin/com/fluvi/app/`

### Single source and write path

- Source of truth: `DashboardVisibleFrameStore.current` is the only complete
  visible dashboard snapshot. `DashboardPreparedDeckCache` is the only owner
  of reusable prepared data. `DashboardMotionKernel` is the only owner of rail
  motion. `DashboardCommittedQueryController` is the only live-query owner.
- Read model: immutable `DashboardVisibleFrame`, containing the already
  formatted amount/count and already projected `DashboardLogViewportState`.
- Only visible write path:
  `DashboardDisplayFrameCoalescer.request` →
  `DashboardVisibleFrameStore.publishPreparedFrame`. Structural navigation may
  submit one full prepared target through the same coalescer. Live data may
  submit one exact committed prepared frame through the same store after all
  epoch/revision checks. No leaf lane writes independently.
- Error and retry owner: `DashboardPreparedDeckPipeline` owns preparation
  error/retry/generation. `DashboardCommittedQueryController` owns live-stream
  retry/cancellation. UI receives coherent old data or a complete new frame;
  it does not coordinate retry or synthesize partial placeholders.

### State ownership

| State | Owner | Lifetime | Publication rule |
|---|---|---|---|
| Rail offset/velocity/activity/semantic index | `DashboardMotionKernel` | Dashboard controller lifetime | Motion-only numeric `DashboardMotionState`; no data observer. |
| Semantic catalog | current complete `DashboardPreparedDeck`, installed into `DashboardMotionKernel` | Prepared parent/navigation epoch | Replaced atomically only outside an active rail callback; immutable thereafter. |
| Prepared decks/cache/in-flight generations | `DashboardPreparedDeckPipeline` | Dashboard controller lifetime | Cache-only completion unless the exact target is currently awaited. |
| Visible amount/count/LogBox/label | `DashboardVisibleFrameStore` | Dashboard controller lifetime | One immutable frame, maximum one publish per display frame. |
| Committed QueryKey/revision/epoch/lease generation | `DashboardCommittedQueryController` | Dashboard controller lifetime | Updated after settle/structural commit; never from preview. |
| Plane/parent/rail-open/retained child/navigation epoch | `DashboardNavigationController` | Dashboard controller lifetime | Structural intent only; labels and data remain sourced from visible frame. |
| Summary shell/text animation | existing SummaryPill `State` owners | Widget State lifetime | Local tickers; intents only. |
| Direction selection/pulse request | `TransactionDirectionController` plus pulse `State` | Dashboard/widget lifetime | Selection starts pulse immediately; prepared target resolves separately. |
| Collapse/reveal animation | `DashboardMotionHost` | Widget State lifetime | Structural animation only. |
| LogBox scroll offset | `DashboardLogBoxViewportState` | Viewport State lifetime | Local viewport state; VM pointer changes never replace controller/State. |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
|---|---|---|---|---|
| Drag/fling/snap physics | `lib/shared/motion/centered_carousel/` | gesture arbitration, ballistic target, friction, velocity scale, snap, tap retarget | Extend the existing engine with a stable configuration/physics handle; do not copy or alter constants. | Existing centered-carousel physics/math tests plus new identity/repeatability tests. |
| Time labels | `DashboardTimeLabelFormatter` / rail label formatter | Hungarian year/month/day labels | Precompute through the existing formatter when constructing the catalog; widgets do not format. | Label parity tests. |
| Money formatting | `SummaryMetricsPresentation.formatTotalMinor` | exact minor-to-HUF string semantics | Extract/retain one pure formatter usable in a worker isolate; every prepared frame uses it. | Existing formatting expectations plus codec tests. |
| Entity visual identity | existing category color/icon IDs and global resolvers | stable category identity and fallback | Prepared rows retain IDs; widgets continue using the one existing resolver/token source. | Widget/source inspection. |
| Bounded LRU | `DashboardBoundedCache` | O(1) access-order eviction and explicit weight/bytes | Extend the neutral cache or replace its dashboard adapter with one typed `DashboardPreparedDeckCache`; no second cache algorithm. | LRU tests and boundary test. |
| Frame scheduling | Flutter `SchedulerBinding` | one semantic display update per engine frame | One injected `DashboardDisplayFrameScheduler` shared by rail, structural and live target selection. | Fake scheduler coalescing tests. |
| LogBox rendering | existing stable viewport/sliver widgets | stable controller, lazy rows, semantic category visuals | Keep the renderer, remove the raw-snapshot adapter, and feed preprojected immutable VM pointers directly. | Viewport identity and stale-row tests. |

### Layer flow

```text
UI intent
  -> DashboardNavigationController / DashboardMotionKernel
  -> DashboardCoreController orchestration façade
  -> DashboardPreparedDeckPipeline or DashboardCommittedQueryController
  -> DashboardPreparedDeckRepository / DashboardLiveFrameRepository
  -> MethodChannel/EventChannel adapter
  -> Fluvi native read service
```

The reverse presentation flow is:

```text
native bounded binary payload
  -> Dart worker-isolate decode + projection
  -> immutable DashboardPreparedDeck / DashboardPreparedFrame
  -> prepared cache
  -> O(1) selected frame
  -> display-frame coalescer
  -> DashboardVisibleFrameStore
  -> narrow amount/count/LogBox/label listenables
```

Presentation imports immutable contracts and controllers, never concrete
repositories, channels or raw query result types. Native/core code has no
Flutter dependency. The dashboard UI owns no query workflow.

### Verification

- Domain/unit: catalog mapping, immutable model invariants, LRU/revision/seed,
  in-flight dedupe, deterministic physics, frame coalescing, committed epoch
  guards and seeded randomized state sequences.
- Widget/integration: stable controller/position/viewport identities,
  localized rebuild counters, long fling, parent navigation open rail,
  direction/plane transitions, settle visual no-op and LogBox content.
- Screenshot/reference: the request does not change appearance and does not
  request a reference match. No new golden test is permitted. One final
  representative device screenshot is inspection evidence only if a connected
  device is available.
- Performance/cancellation: profile scenarios A–J, typed counter assertions,
  timeline/GC/channel/SQL/decode metrics, stale completion rejection and
  physical target/duration comparison.

## Canonical components

### 1. DashboardMotionKernel

`DashboardMotionKernel` is a long-lived object created once by
`DashboardCoreController`. It owns:

- the existing `CenteredCarouselController` and its one `ScrollController`;
- one stable dashboard `CenterSnapScrollPhysics` configuration handle;
- the current immutable `DashboardSemanticCatalog` pointer;
- immutable `DashboardMotionState` snapshots;
- gesture and motion epoch counters;
- semantic-crossing and settle callbacks expressed only in catalog entries.

The existing carousel keeps the exact current geometry, friction (`0.135`),
velocity scale (`0.66`), velocity limits, maximum fling items, spring,
tolerance, haptic threshold and visual timing. The shared carousel gains a
stable physics/configuration object rather than constructing one in every
dashboard build. Its renderer may rebuild visible rail items on scroll ticks
for scale/opacity; those builders receive only numeric motion state and
immutable catalog content.

The kernel callback contract is:

```dart
void Function(
  DashboardSemanticEntry entry,
  DashboardMotionContext context,
) onSemanticCrossed;
```

It contains no repository, query controller, store, loading state or LogBox
type. A semantic entry already holds its exact child scope and canonical
QueryKey, so crossing performs no scope allocation or canonical sorting.

The SUM rail uses a 25-year prepared window: retained year ±12, with exact
four-digit year values and QueryKeys. A committed selection within five years
of either edge schedules a lower-priority re-centered deck. Window identity is
part of the deck cache key. Catalog replacement occurs only after the full new
deck is ready and preserves the long-lived carousel/controller objects.

### 2. DashboardPreparedDeck and DashboardPreparedFrame

`DashboardPreparedDeck` contains:

- `DashboardPreparedDeckKey` with model version, direction, exact parent key,
  canonical filters/refinements digest, child kind, core revision, page size
  and semantic-window identity;
- exact parent scope and one prepared parent frame;
- immutable semantic catalog;
- immutable `Map<LedgerQueryKey, DashboardPreparedFrame>`;
- child/page counts, completeness, digest, generation and preparation time.

`DashboardPreparedFrame` contains the exact scope/key/parent/revision,
preformatted amount/count, error/empty/header model, immutable grouped LogBox
viewport model, bounded first page, next cursor, stable row/asset identities
and a presentation digest. A complete cacheable frame always has
`loading=false`, `stale=false` and revision greater than zero.

The visible model wraps a prepared frame without reprojecting it:

```dart
DashboardVisibleFrame.fromPrepared(
  frame,
  plane: navigation.plane,
  railOpen: navigation.railOpen,
  semanticIndex: entry.logicalIndex,
  navigationEpoch: navigation.epoch,
  presentationEpoch: nextEpoch,
  frameGeneration: generation,
  mode: DashboardVisibleMode.preview,
)
```

Constructor assertions enforce identical amount/count/LogBox key and
revision. These submodels are pointer-stable members of the frame.

### 3. Native constant-query parent batch and binary transport

`FluviLedgerReadService.readPreparedDeck` runs on `Dispatchers.IO` and uses a
constant query shape:

1. one grouped aggregate query using the unchanged scope predicate;
2. one ordered cursor query for bounded child first pages, retaining at most
   `pageSize + 1` rows per requested child and the parent first page;
3. constant metadata/revision/category/partner lookups (or joins), independent
   of child count.

There is no `queryTimelinePage` inside a child loop. The ordered cursor is
streamed and only bounded output rows are materialized. Month and year decks
therefore do not issue 31 or 12 page queries. The SUM cursor is constrained by
the explicit year window for children while the parent aggregate remains
all-time exact.

The Android app encodes the complete deck into one versioned `ByteArray` while
still on `Dispatchers.IO`. StandardMessageCodec then transports only a byte
array, not a nested object graph. The wire format has magic/version/request
identity, exact keys/revision/metrics, frame records, cursor records and
bounded row records. Lengths and counts are validated before allocation.

Flutter receives `Uint8List` and uses `Isolate.run` to decode, validate,
format, group and construct the immutable deck. `Isolate.run` returns the
finished graph through its exit transfer. The UI isolate only validates the
request generation/key/revision and inserts the finished object into the
cache. Exact live slices and paging use the same versioned binary row/frame
codec and worker projector; no nested live payload is decoded on the UI
isolate.

### 4. DashboardPreparedDeckPipeline and cache

The pipeline is the only preparation owner. It holds:

- one typed bounded access-order LRU;
- `Map<DashboardPreparedDeckKey, Future<DashboardPreparedDeck>>` for keyed
  in-flight joining;
- current core revision and seed gate;
- preparation/navigation generations;
- cancel/discard tokens and numeric diagnostics.

`prepareRequired` joins an existing in-flight request, validates request
generation after every async boundary, rejects revision zero and stores only a
complete exact-key deck. `prewarm` uses the same function with a low-priority
token, never publishes visible state and does not start while interaction is
active. Already-running native work may finish off-thread; a cancelled token
prevents cache/publication.

Revision change evicts every key from the old revision and invalidates its
in-flight generations. The active/previous/next and required
opposite-direction keys are pinned through the typed residency policy; all
other entries are ordinary LRU candidates. Lookup is done once per target
intent and passed down as a result object, not repeated by callers.

### 5. DashboardDisplayFrameCoalescer and visible frame store

The coalescer stores only one pending target. The first request in an engine
frame schedules one frame callback; later requests before that callback replace
the pending target. At callback time it publishes the last target, clears the
slot and has no queue. A request after that callback schedules the next frame,
so crossings occurring in distinct display frames remain visible.

There is no duration, timer, debounce, throttle, idle rule or trailing replay.
The coalescer never calls the carousel and cannot alter physics.

`DashboardVisibleFrameStore` has one visual listener channel. It publishes a
frame only if exact key/revision/epoch checks pass and its visual digest differs
from the current frame. `promoteCommitted` updates internal provenance and the
separate committed owner without notifying visual consumers. Thus settle can
change preview/committed metadata while amount/count/LogBox pixels and
identities remain untouched.

### 6. DashboardCommittedQueryController

Settle receives the already selected semantic entry and current visible frame:

1. reject stale motion/navigation epoch;
2. call `visibleStore.promoteCommitted` without a visual notification;
3. update immutable `DashboardCommittedState`;
4. cancel the previous lease;
5. start exactly one repository watch immediately, with a new lease
   generation (no quiescence timer).

Live output is decoded/projected off the UI isolate. Acceptance requires exact
committed QueryKey, direction, filter/refinement identity, core revision,
committed epoch, presentation epoch and lease generation. A newer core revision
invalidates prepared cache and starts one current-parent preparation. An
accepted same-value live frame is a no-op. No live callback can invoke or
modify `DashboardMotionKernel`.

### 7. Navigation, parent changes and plane changes

`DashboardNavigationController` contains only structural target state. Visible
labels come from `DashboardVisibleFrame`, so a cold target cannot relabel old
amount/count/LogBox data.

For an open-rail parent intent:

1. increment navigation epoch and calculate the retained semantic value;
2. derive the exact target deck key once;
3. if warm, install its catalog and select the retained/clamped entry, then
   submit one visible frame in the current display frame;
4. if cold, leave the current catalog and complete visible frame untouched,
   start/await background preparation, and keep all local animations running;
5. when the exact generation completes, atomically install the deck and submit
   the exact mapped frame;
6. only after visibility is coherent, promote committed ownership/start lease.

Month child mapping preserves day when valid and clamps to the new month's last
day. Year child mapping preserves month. SUM year mapping preserves the year if
inside the new 25-year window and otherwise re-centers a window around it.
Rapid A→B→C navigation increments navigation epoch; A/B completions are
discarded.

Plane and direction intents begin their local SummaryPill/reveal/pulse motion
immediately. A warm deck swaps atomically; a cold deck retains the outgoing
coherent frame until ready. The animation callback does not perform repository
work or projection. SummaryPill starts shell return before invoking the
structural intent callback.

### 8. UI subtree boundaries

`CoreDashboard` composes stable stateful children once under structural layout
motion:

- SummaryPill shell/navigation motion subtree;
- rail motion subtree fed by kernel/catalog only;
- amount text subtree selecting `visibleFrame.amount`;
- count text leaf selecting `visibleFrame.count`;
- LogBox stable viewport selecting `visibleFrame.logBox`;
- direction SVG/pulse subtree fed only by direction animation;
- static header shell.

The root listens only to collapse/reveal/layout and structural navigation, not
semantic visible frames. Each visible consumer uses a small typed selector that
compares identity/digest before notifying. The header shell and viewport shell
do not rebuild per child; only count text and LogBox sliver content do. The
rail never imports visible/prepared/query types. Repaint boundaries remain on
the independently animated/scrolling regions.

### 9. LogBox and paging

The current `DashboardLogPresentationAdapter` is removed. The viewport receives
the preprojected `DashboardLogViewportState` from the visible frame. Its State,
`ScrollController`, `CustomScrollView`, sliver structure and stable row/group
keys remain mounted. VM changes replace one immutable pointer; `SliverList` and
`SliverFixedExtentList` build only visible rows.

Grouping, ordering, date/time/money/semantic string formatting and asset IDs are
prepared in the worker deck pipeline. Paging is reachable only from committed
LogBox state; the binary page is projected off-isolate and merged into a new
immutable committed frame. Paging never reports anything to motion.

### 10. Diagnostics and benchmark

One bounded typed ring records the required event enum and numeric/context
fields. Semantic-cross events are optional under a profile switch; pixel events
are never recorded. One fixed-slot counter array records every requested
rebuild, publish, I/O, projection, stale and identity metric.

The integration profile harness runs scenarios A–J without prewarming as a
correctness condition. It records first and tenth gestures separately, uses
the same programmatic velocities/positions, captures Flutter frame/timeline/GC
data and joins native SQL/channel/decode metrics with target/settle indices.
Profile success requires zero data I/O between gesture start and motion settle.

## Removed production constructions

The migration removes production use of and then deletes or collapses the
following old owners:

- metrics-only child summary preview cache/index lane;
- `DashboardSummaryMetricsController` as query/cache/store coordinator;
- raw-entry `DashboardPresentationStore` and its metadata listener lane;
- `DashboardLogPresentationAdapter` and build-time fallback projection;
- `DashboardParentBundleRegistry`/display-bundle parallel representation;
- `DashboardAdjacentParentPrewarmCoordinator` and global-ticker polling
  background coordinator;
- timer-based `DashboardLiveQueryLeaseCoordinator`;
- rail-motion presentation guards and settle-time visual publication;
- query-scope-based LogBox rebinding and repeated canonical QueryKey creation;
- nested child-preview bridge payload and N-child SQL loop.

Compatibility names may remain only as zero-state type aliases or thin intent
facades during the same commit if an external public import requires them;
they may not retain caches, notifiers, query ownership or a second write path.
The final production dependency graph has one canonical path.
