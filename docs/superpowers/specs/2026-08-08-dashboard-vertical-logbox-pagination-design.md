# Dashboard vertical LogBox pagination design

## Scope and frozen baseline

This is the user-approved `FLUVI DASHBOARD — 3e61da2 MILESTONE LOCK` design. The immutable rail-performance baseline is `3e61da2347bab3f9d9806cd42b272b91235cf9f5`, retained by the local `milestone/dashboard-3e61da2-rail-performance` branch and `dashboard-3e61da2-rail-performance` annotated tag.

`DashboardMotionKernel`, `TimeRefinementRail`, centered-carousel widget/controller/physics, `DashboardPresentationController`, `DashboardVisibleFrameStore`, and `PreparedDashboardIndex` remain byte-for-byte frozen. There is no physics, controller, rail, or index hot-path change and no golden test.

## Source-proven boundary defect

The current exact chain is:

```
committed visible frame (first 24-row preview)
  -> ExplicitCommittedPagingController.loadNextPage
  -> repository read + IsolateDashboardCommittedPageBinaryCodec.decodePage
  -> decoder appends the new page to currentFrame.logBox.groups
  -> a new DashboardVisibleFrame is published
  -> DashboardLogBoxRenderSurface asks DashboardLogBoxPreparedSceneCache
  -> the cache contains only the active rail preview scene window
  -> scene/row lookup misses, records TEXT_LAYOUT_MISS and RAIL_CRITICAL_CACHE_MISS
```

The current page decoder is explicitly the proof: it concatenates every incoming group with `currentFrame.logBox.groups`. Thus each page turns a rail-preview payload into a growing committed list, even though the cache that renders it is intentionally bounded for structural rail scenes. This explains both the post-paging missing-content diagnostic and why total count, currently loaded rows, and scroll extent are conflated. The painter paints no row if its prepared text is absent, so it can never use paint-time layout as a safe recovery route.

## Ownership and canonical state

Two different state domains replace the overloaded cache.

### 1. Prepared rail scene domain

`DashboardLogBoxPreparedSceneCache` is retained as the canonical *rail-only* owner (the implementation may add the clearer `PreparedRailSceneCache` alias only if it does not duplicate ownership). It owns exact-width `PreparedLogBoxScene` resources for the current/adjacent structural rail window. Its scene payload is permanently limited to each frame's preview page (`pageSize`, currently 24). Its only supported lookup is `prepared rail frame -> prepared rail scene -> paint`, and a miss stays `RAIL_CRITICAL_CACHE_MISS`.

### 2. Committed vertical domain

`CommittedLogViewportController` owns one `CommittedLogViewportCache` per exact committed scope/revision. The immutable page unit is `CommittedLogPage`:

```
query key + parent query key + core revision + commit generation
+ page ordinal + start cursor + end/next cursor + content digest
+ complete immutable viewport rows/groups + prebuilt row/header layouts
```

The controller, not `DashboardVisibleFrame`, owns loaded pages, request deduplication, error/stale state, visible logical window, and distance-based/LRU eviction. It retains the current page plus two neighbors in each direction (five pages maximum by default; page size remains 24), with an explicit hard retained-row/layout maximum. Page publication is atomic: decode/project/format/layout/raster identity preparation complete first, then the page cache changes and a repaint is requested. There is no visible partial page and no paint-time preparation.

`DashboardVisibleFrame` remains the rail/summary snapshot and carries only immutable initial-preview and paging metadata: exact query/revision, total entry count, preview payload, initial cursor and presentation identity. A committed page append must not publish a new visible frame and must not mutate its rail scene identity.

## Rendering and virtual geometry

The stable LogBox `CustomPaint` surface remains. The vertical painter receives `CommittedLogViewportSnapshot`, maps scroll offset to a logical row interval, then asks the committed cache for the ready visible/overscan rows. It paints and creates semantics for only that bounded interval. A logical content extent may represent `totalEntryCount`, but neither the full widget tree nor all `TextPainter`s are materialized.

Initial-page rows can be supplied to the vertical controller from the immutable visible-frame preview. A page cache transition preserves the preceding committed page until its replacement window is ready; it never changes the current scroll offset and only increases extent after an append. A normal vertical gap is a `VERTICAL_CACHE_MISS` invariant failure, never a rail miss and never a route to a fallback layout.

```
near-end committed vertical scroll
  -> one queryKey/cursor in-flight request
  -> native keyset page + isolate decode
  -> vertical page row VM/layout preparation
  -> atomic committed-cache commit
  -> extent grows; same offset; O(visible + overscan) paint
```

Structural/plane/direction navigation invalidates the vertical controller generation before the next visible committed frame is selected. In-flight old-generation results are discarded. Rail movement has priority: the paging controller does not issue work while rail motion is active, and bounded lookahead is cancelled/deferred rather than touching a rail callback.

## Rail-settle activation boundary

The first profile gate of this change found a `62.942 ms` UI-isolate task in the year/month rail scenario. Source inspection showed a precise lifecycle violation: every settled committed rail frame called `CommittedLogViewportCache.seed()`, and the cache still held an exact surface width. `seed()` therefore eagerly ran `TextPainter.layout` for the initial 24 committed vertical rows, even though no vertical user scroll had started. That is neither rail preview work nor an allowed rail-settle cost.

The cache now seeds only immutable vertical page metadata when a rail frame commits. The normal rail surface continues to paint the already-ready bounded rail scene. The first actual vertical `ScrollStartNotification` activates the committed vertical cache without duplicating the initial page's layouts: page zero borrows the immutable, already-complete matching rail preview scene. Later keyset pages prepare into the vertical cache transactionally before publication. A preparation failure leaves the rail scene visible and is reported as a vertical failure; no partial page becomes paintable.

Consequently, rail crossing, rail settle, paint, and the first vertical scroll start never lay out a committed vertical page. This preserves the frozen rail path while retaining the vertical domain's no-paint-time-layout and atomic-publication contracts.

## Invariants

1. Rail preview rows per frame never exceed the configured preview page size, independent of total transactions.
2. Normal rail crossing performs no I/O, projection, formatting, `TextPainter.layout`, or committed-cache fill.
3. Normal vertical paint performs no I/O, formatting, decode, asset work, or `TextPainter.layout`.
4. A presented vertical row is atomic: header (where applicable), badge, icon, name, category, amount, and time are all ready together.
5. At most one in-flight read exists per `(queryKey, coreRevision, generation, nextCursor)`.
6. The retained committed-page window and row/layout count have explicit maximums and cannot scale with total entries.
7. An existing viewport row cannot be evicted while it belongs to the visible/overscan retained window.

## Diagnostics and validation

The existing profile onscreen diagnostic policy and console stay enabled. New bounded, structural events are `VERTICAL_PAGE_REQUESTED`, `VERTICAL_PAGE_READY`, `VERTICAL_PAGE_COMMITTED`, `VERTICAL_PAGE_EVICTED`, `VERTICAL_ROW_WINDOW_CHANGED`, `VERTICAL_CACHE_MISS`, `VERTICAL_SCROLL_SUMMARY`, and `VERTICAL_END_REACHED`.

Tests use deterministic 24/94/658/1k/10k/50k/100k fixture datasets. They prove reachability, bounded retention, stale/duplicate handling, atomic publication, no disappearance, offset continuity, and rail isolation. Device smoothness remains a physical profile-APK acceptance and will not be inferred from an emulator.
