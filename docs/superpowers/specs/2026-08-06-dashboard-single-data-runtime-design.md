# Dashboard single data runtime design

Date: 2026-08-06

Status: approved by the user's prescriptive architecture request

Branch: `refactor/dashboard-single-data-runtime`

This is the single implementation design. It contains no alternative path and
no compatibility fallback to parent PreparedDecks or per-query live watches.

## Ownership card

### Job to be done

Make every dashboard navigation and motion operation a deterministic,
synchronous RAM lookup while preserving the existing rail mechanics, visual
timings, QueryKey semantics and atomic amount/count/LogBox presentation.

### Canonical owner

`DashboardDataRuntime` is the only acquisition lifecycle owner. It composes:

```text
DashboardDataRuntime
  ├── GlobalCoreRevisionObserver
  ├── PreparedDashboardIndexBuilder
  ├── PreparedDashboardIndex (current + at most one pending replacement)
  └── ExplicitCommittedPagingController

DashboardPresentationController
  ├── DashboardNavigationController
  ├── DashboardMotionKernel
  ├── DashboardDisplayFrameCoalescer
  ├── DashboardVisibleFrameStore
  └── committed metadata (no acquisition)
```

`DashboardCoreController` remains a thin composition façade for the app shell
and widgets. It does not implement cache, repository or live-query policy.

### Public contract

- Data runtime accepts only typed acquisition reasons.
- Presentation installs a complete immutable index and exposes synchronous
  navigation methods.
- Presentation asks the installed index for catalogs and frames.
- Settle commits metadata only.
- LogBox near-end explicitly asks the paging controller for one next page.
- A new index is installed only through the runtime's revision lifecycle.

### Non-goals

- No rail/physics/gesture change.
- No visual redesign.
- No QueryKey, amount/count or LogBox semantic change.
- No storage migration.
- No golden tests.

## Acquisition capability model

```dart
enum DataAcquisitionReason {
  bootstrap,
  databaseRevision,
  explicitCommittedVerticalPaging,
}
```

Index requests accept only `bootstrap` or `databaseRevision`. Page requests
accept only `explicitCommittedVerticalPaging`. There is no API capable of
expressing rail-open, child-settle, parent, plane, direction or SummaryPill as
an acquisition reason. Invalid use throws in all builds and emits
`MOTION_DATA_IO_VIOLATION` in debug/profile diagnostics.

## PreparedDashboardIndex

The index is an immutable process-local snapshot for one core revision and one
filter/refinement identity. One index contains both income and expense data so
direction changes stay RAM-only.

It contains:

- model version, core revision and filter/refinement identity;
- explicit bounded SUM year window;
- page size, generation, build timestamp, digest and estimated bytes;
- O(1) `LedgerQueryKey -> DashboardPreparedFrame` map;
- O(1) parent/catalog map for SUM/year/month parents;
- parent/child semantic relationships and child indices;
- preformatted amount/count/header/empty metadata;
- preprojected bounded LogBox groups and rows;
- stable row and asset identities;
- native/bridge/decode/projection metrics and `dataOrigin`.

`DashboardPreparedFrame` becomes parent-neutral. The same immutable year or
month frame can be displayed as a parent or as a child; the visible wrapper
owns the active parent key. This removes duplicate global frame objects while
preserving the exact visible parent/child invariant.

The index materializes zero frames for its bounded interactive year window.
For a valid scope outside that window, it may create a deterministic immutable
zero frame synchronously from constant empty VM data. That path performs no
I/O, parse, sort, grouping, asset lookup or locale formatting.

## Native global index build

The MethodChannel exposes one build method, `readDashboardPreparedIndex`.
Arguments contain filters/refinements, preview page size, revision/generation
and an explicit year window. Direction and parent scope are deliberately not
arguments because both directions and all temporal levels are built together.

Inside one Room transaction on `Dispatchers.IO`:

1. Read the Partner snapshot and expand canonical Partner filters.
2. Read the Category snapshot.
3. Execute one aggregate query grouped by direction and local day.
4. Execute one direction/date ordered cursor query for bounded preview rows.
5. Read core revision.

Daily aggregates are folded in Kotlin into month, year and all-time summaries.
The ordered cursor is scanned once. Each row is retained only while one of its
day/month/year/all first-page buckets still needs it. A row object is mapped
once even if referenced by four scope previews.

The binary payload uses:

- one deduplicated row table;
- sparse nonzero frame records containing row-table indices;
- aggregate/count/cursor metadata per frame;
- build timings and row/byte counts.

Zero periods are omitted from transport and materialized by the Dart worker.
The number of SQL calls is constant for a filter identity and does not depend
on parent, direction, years, months or days.

## Worker and publish boundary

Android SQL, aggregation, native mapping and binary encoding remain on
`Dispatchers.IO`. The Flutter adapter wraps bytes in
`TransferableTypedData`; `Isolate.run` decodes, validates QueryKeys/revision,
projects each unique row once, groups frame references, formats summaries and
constructs the immutable index. The UI isolate receives only the completed
result of the exiting worker and installs one index reference.

Metrics remain split into SQL, native aggregation, native mapping,
serialization, bridge duration, Dart decode, Dart projection, index publish,
first valid paint, payload/index bytes and memory.

## Global revision lifecycle

`GlobalCoreRevisionObserver` subscribes once when the dashboard runtime starts.
Revision zero is ignored behind the bootstrap barrier. The first positive
revision starts the bootstrap build. Later distinct revisions start
`databaseRevision` builds.

The builder uses monotonically increasing data generations. A newer revision
cancels the older token; an older completion is discarded even if native work
could not be preempted. Exactly one result can become current.

If motion is active when a valid result completes, the runtime stores it as
pending. On settle/end it schedules one display-frame callback. If motion is
still idle and the generation/revision remain current at that callback, the
index replaces the old index atomically and presentation reselects its current
expected target. No motion/controller object is replaced.

Navigation never invalidates or rebuilds the index.

## Presentation hot path

After bootstrap the canonical path is:

```text
navigation or semantic index
  -> PreparedDashboardIndex catalog/frame map lookup
  -> DashboardVisibleFrame wrapping the same prepared frame reference
  -> display-frame-coalesced localized publish
```

The installed index supplies prebuilt semantic catalogs. Rail crossing is:

```text
ScrollPosition
  -> logical index
  -> immutable catalog entry
  -> index.frames[queryKey]
  -> coalescer request
```

It contains no Future, stream, repository, channel, SQL, serialization,
parsing, sorting, grouping, formatting, asset lookup or data notification.

Structural navigation methods are synchronous. They update navigation
metadata, install an already-prepared catalog in the existing Motion Kernel,
select the exact frame and request one publish. Parent navigation while the
rail is open applies the existing deterministic retained-child/clamp rules
before lookup.

## Visible and committed semantics

`DashboardVisibleFrame` remains the sole atomic presentation snapshot. Its
amount, count and LogBox all reference one `DashboardPreparedFrame`, so key and
revision lane mismatches are structurally impossible.

Settle:

1. retains the selected semantic child without a structural notification;
2. promotes the current visible wrapper to committed metadata;
3. records the committed key/revision/epoch for paging;
4. emits no visual notification and performs no acquisition.

If the last crossing is queued for the same display frame, promotion occurs
after that queued target publishes. Same-value settle is a complete no-op for
amount, LogBox, scroll and animation.

## Explicit vertical paging

The stable LogBox viewport continues to trigger at a committed near-end
boundary. `ExplicitCommittedPagingController` snapshots the committed key,
scope, revision, presentation epoch and page generation, then performs one
bounded `readDashboardPreparedPage` call with
`explicitCommittedVerticalPaging`.

The worker appends and validates the page. Publication is accepted only if all
committed metadata and the current index revision still match. Navigation does
not page, and settle does not page. A stale page increments a rejection counter
without changing visible state.

## UI and render boundaries

Existing stable owners are retained:

- one dashboard motion host and its three animation controllers;
- one Motion Kernel/centered-carousel controller/ScrollController/physics;
- one SummaryPill shell and text-motion owner;
- one LogBox State/ScrollController/CustomScrollView;
- localized amount, count/header, LogBox and child-label listeners;
- existing repaint boundaries and lazy slivers.

The core root is notified only by structural motion. Index/frame publication
cannot recreate the direction pulse, rail or SummaryPill controllers.

## Diagnostics

The event vocabulary becomes:

- `GLOBAL_REVISION_WATCH_SUBSCRIBED`
- `GLOBAL_REVISION_CHANGED`
- `INDEX_BUILD_STARTED`
- `INDEX_BUILD_READY`
- `INDEX_PUBLISHED`
- `NAV_PRESENTATION_SELECTED`
- `RAIL_CHILD_CROSSED`
- `SETTLE_METADATA_COMMITTED`
- `VERTICAL_PAGE_REQUESTED`
- `MOTION_DATA_IO_VIOLATION`
- `STALE_CALLBACK_REJECTED`

Every event carries interaction epoch, presentation generation, data
generation, revision, QueryKey, separate `presentationMode` and `dataOrigin`,
motion state and acquisition reason. Profile mode suppresses per-crossing
events. Fixed counters measure all acquisition types over the entire
interaction-to-next-touch interval, not only active ballistic motion.

## Legacy deletion

Once the index path is green, the same change removes:

- `DashboardPreparedDeck`, deck key/cache/pipeline/prewarm and repository API;
- `DashboardCommittedQueryController` and `DashboardPreparedLiveRepository`;
- `com.fluvi/dashboard_query_stream` and `DashboardObservationSession`;
- `observeSlice` use from the dashboard bridge;
- `readDashboardPreparedDeck` and parent/child native deck codec/models;
- live-frame decode paths and live lease diagnostics/tests;
- tests that expect a settle or structural navigation to start a lease/build.

Only the global revision stream and explicit MethodChannel index/page calls
remain.

## Verification strategy

Implementation follows RED/GREEN slices:

1. architecture and acquisition-reason boundary;
2. immutable global index model and lookup invariants;
3. one-subscription/latest-wins runtime;
4. RAM-only presentation and metadata-only settle;
5. explicit paging;
6. native constant-query builder and deduplicated codec;
7. widget identities/rebuilds;
8. full interaction matrix, stress and profile.

No golden test is created. Profile thresholds are reported as PASS or FAIL,
and emulator evidence is never labeled physical-device proof.
