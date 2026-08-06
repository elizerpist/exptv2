# Dashboard single-data-runtime root-cause audit

Date: 2026-08-06

Audited commit: `1bb0f1d51c30f37065da591391acb18d195111f5`

Branch: `refactor/dashboard-single-data-runtime`

Checkpoint tag: `milestone/dashboard-before-single-data-runtime-20260806`

This audit supersedes the 2026-08-05 completion conclusion. The previous
report measured only the active motion interval. The defect is a post-settle
navigation-triggered acquisition path that starts immediately after that
interval, competes with the next touch/animation, and was explicitly expected
by the old tests.

## Baseline state and evidence

- Tracked working tree: clean before this audit.
- Preserved user-owned untracked files: existing `.tmp-*` logs and
  `test/features/dashboard/presentation/failures/` images.
- Non-golden Flutter baseline: `250/250` passed in Ubuntu proot in 1m13s.
- A–J profile logcat counts from GitHub run `31053294491`:
  - `NATIVE_WATCH_SUBSCRIBED`: 62
  - `ACTIVE_QUERY_SCOPE`: 62
  - `READ_SERVICE_INVOKED`: 62
  - `NATIVE_WATCH_CANCELLED`: 62
- Scenario D (`month/day`, 94 rows) recorded one committed-frame decode after
  the motion window while reporting zero motion-window data calls. This is the
  measurement gap: the exact-scope read happened after settle.
- The old settle tests assert `repository.liveStarts == before + 1`, so the
  faulty acquisition was encoded as desired behavior rather than left
  uncovered.

## Proven root cause

The second refactor created immutable parent-scoped `DashboardPreparedDeck`s,
but did not replace the old committed exact-scope live query. It added a new
preview source beside the old acquisition source:

```text
rail crossing -> parent PreparedDeck frame (RAM)
rail settle   -> DashboardCommittedQueryController.commit
              -> cancel previous exact-scope EventChannel subscription
              -> subscribe to a new exact-scope EventChannel
              -> Room core-revision observer
              -> readSlice(exact child)
              -> SQL + native mapping + binary payload
              -> Dart worker decode/projection
              -> visible presentation publish
```

The rail simulation itself remains data blind. The defect is temporal
coupling: every settle leaves platform, database, serialization and decode work
running immediately before the next interaction and alongside SummaryPill,
amount and SVG tickers. Populated scopes cost more than zero scopes, so equal
gesture input runs in unequal scheduling environments.

## Baseline full call graph

### SummaryPill and structural navigation

```text
DashboardSummaryPill._finishGesture
  -> _commitWithShellReturn
  -> CoreDashboard callback
  -> DashboardCoreController.navigateParent / navigatePlane / selectDirection
  -> DashboardNavigationController.commitParent / commitPlane / selectDirection
  -> navigation.notifyListeners
     -> DashboardMotionHost._onRailChanged or _onDirectionChanged
     -> SummaryPill navigation text listener
     -> structural visual animation starts
  -> DashboardCoreController._yieldToStartedMotion
  -> DashboardCoreController._activateTarget
     -> committed.invalidate (cancels current per-query watch)
     -> DashboardPreparedDeckRequest for the new parent
     -> DashboardPreparedDeckPipeline.resolveRequired
        -> cache hit, or repository.prepareDeck
        -> MethodChannel readDashboardPreparedDeck
        -> FluviLedgerReadService.preparedDeck (six SQL calls)
        -> DashboardBinaryCodec.encodeDeck
        -> IsolateDashboardPreparedDeckDecodeWorker
        -> formatting + LogBox projection in worker
     -> install parent-specific semantic catalog
     -> visible-frame coalescer
     -> DashboardVisibleFrameStore.publish
     -> _publishCoalescedFrame
     -> DashboardCommittedQueryController.commit for committed frame
```

Consequences:

- Parent, plane and direction navigation can create a new parent deck.
- Navigation correctness depends on cache/prewarm state.
- A committed publication immediately activates the exact-scope watch.
- Summary motion begins synchronously, but the same UI isolate later receives
  deck and committed-frame results while its animation is running.

### Rail open and close

```text
DashboardCoreController.setRailOpen
  -> DashboardNavigationController.setRailOpen
  -> navigation.notifyListeners (root structural rail animation)
  -> committed.invalidate (cancel exact-scope watch)
  -> _requestVisibleFromDeck(active parent deck)
  -> display-frame publish parent or retained child
  -> _publishCoalescedFrame
  -> committed.commit
  -> new exact-scope watch
```

Even a pure presentational rail-open/close operation transfers query ownership.

### Rail crossing

```text
ScrollPosition
  -> CenteredCarouselController logical selection
  -> TimeRefinementRail semantic callback
  -> DashboardMotionKernel.semanticCrossed
  -> DashboardCoreController._onSemanticCrossed
  -> activeDeck.frames[entry.queryKey]
  -> DashboardDisplayFrameCoalescer.request
  -> DashboardVisibleFrameStore.publish (maximum once per display frame)
  -> amount/count/LogBox/child-label listeners
```

This segment is already synchronous and memory-only. It is not sufficient,
because its predecessor and successor interactions create data work.

### Rail settle and committed query

```text
ScrollPosition.isScrollingNotifier -> idle
  -> CenteredCarousel settle callback
  -> DashboardMotionKernel.settled
  -> DashboardCoreController._onSettled
  -> DashboardNavigationController.retainSettledChild (metadata, no notify)
  -> DashboardVisibleFrameStore.promoteCommitted (no visual notify)
  -> DashboardCoreController._promoteSettledFrameIfVisible
  -> DashboardCommittedQueryController.commit
     -> update committed metadata and notify controller listeners
     -> cancel previous StreamSubscription
     -> DashboardPreparedLiveRepository.watchCommittedFrame
     -> MethodChannelDashboardPreparedRepository EventChannel
        com.fluvi/dashboard_query_stream
```

This `commit()` call is the direct source of the reported repeating log chain.

### Native exact-scope watch

```text
MainActivity dashboard EventChannel.onListen
  -> NATIVE_WATCH_SUBSCRIBED
  -> DashboardQueryArguments.scopeFrom
  -> ACTIVE_QUERY_SCOPE
  -> DashboardObservationSession.replace
     -> cancel previous Job
     -> NATIVE_WATCH_CANCELLED for previous subscription
  -> scope.launch
  -> READ_SERVICE_INVOKED
  -> FluviLedgerReadService.observeSlice(scope)
     -> Room observeCoreRevision().distinctUntilChanged()
     -> mapLatest { readSlice(scope) }
        -> total(scope)
        -> timeline(scope, pageSize)
        -> categoryRepository.allEntities()
        -> partnerRepository.allEntities()
        -> currentCoreRevision()
        -> native row mapping
     -> DashboardBinaryCodec.encodeFrame on Dispatchers.IO
  -> EventSink.success(binary payload)
  -> Flutter EventChannel delivery
  -> IsolateDashboardPreparedDeckDecodeWorker.decodeFrame
     -> binary decode
     -> amount/time/date formatting
     -> LogBox grouping and row projection
  -> DashboardCommittedQueryController._accept
  -> new DashboardVisibleFrame
  -> DashboardVisibleFrameStore.publish
```

Room work and native encoding are off Android main, and Dart projection uses a
worker isolate. They still consume CPU, memory bandwidth, platform delivery,
allocation and UI publication immediately around interaction. Populated scopes
perform and transfer more row work than empty scopes.

### Global revision observer

There is already a separate, payload-light global observer:

```text
MethodChannelDashboardPreparedRepository.watchCoreRevision
  -> EventChannel com.fluvi/dashboard_core_revision_stream
  -> MainActivity coreRevisionEventChannel
  -> FluviLedgerReadService.observeCoreRevision
  -> Room app_settings core_revision only
```

This is the correct invalidation owner. The exact-scope EventChannel duplicates
revision observation once per committed child and must be removed rather than
delayed.

### Explicit LogBox paging

```text
DashboardLogBoxViewport ScrollUpdateNotification
  -> committed visible frame + nextCursor + extentAfter < 360
  -> DashboardCoreController.loadNextPage
  -> DashboardCommittedQueryController.loadNextPage
  -> MethodChannel readDashboardPreparedFrame
  -> readSlice(scope, after cursor)
  -> worker decodePage + append groups
  -> visible publish guarded by committed generation/revision/key
```

This is legitimate user-requested acquisition but is currently bundled into
the same repository/controller contract as the forbidden live watch. It must
be retained under an explicit paging-only owner.

## Current UI-isolate and notification work

| Work | Concrete source | Interaction relation |
|---|---|---|
| Parent `DashboardPreparedDeckRequest` and canonical keys | `DashboardCoreController._requestFor`, `CurrentLedgerQueryScope.key` | Every cold structural target. |
| Cache/in-flight/prewarm orchestration | `DashboardPreparedDeckPipeline`, `_activateTarget`, `_runPrewarm` | Parent/plane/direction navigation. |
| Platform result delivery and completed-index publication | method/event channel adapters and core callbacks | Runs alongside active tickers. |
| Visible frame construction/hash | `_visibleFromDeck`, `DashboardVisibleFrame.fromPrepared` | Structural targets and crossings. |
| Store notification | `DashboardVisibleFrameStore.publish` | Rebuilds amount/count/LogBox/label leaves. |
| Committed controller notification | `DashboardCommittedQueryController.commit` | Every transferred exact-scope owner. |
| LogBox sliver list creation | `DashboardLogBoxViewport._DashboardLogScrollArea.build` | Localized but proportional to prepared groups. |

The expensive binary decode, formatting and grouping are already moved into an
`Isolate.run` worker. The remaining architectural failure is acquisition and
publication ownership, not merely the location of formatting.

## Widget and identity audit

- `DashboardMotionHost` owns stable collapse, rail-reveal and direction-pulse
  `AnimationController`s. It listens only to structural expansion/navigation/
  direction state.
- `DashboardMotionKernel` and its centered-carousel controller own a stable
  rail `ScrollController` and physics object for the core-controller lifetime.
- `DashboardLogBoxViewport` owns one stable `ScrollController`, uses
  `CustomScrollView` and lazy slivers, and has no QueryKey root key.
- Summary amount, child text, LogBox and header consume localized listenables.
- Repaint boundaries already isolate SummaryPill and LogBox lanes.

These parts do not require physics or visual-mechanism replacement. Their
tickers stall because post-settle and structural data work shares device and UI
resources. The runtime/data ownership must change while these identities stay
stable.

## Why each symptom occurs

### Populated scopes are slower than empty scopes

Every settle invokes exact-scope `readSlice`. Empty scopes return no rows;
populated scopes execute and map a page, encode row strings, transfer a larger
payload, decode/project rows and publish another visible frame. The CPU and
allocation difference overlaps the next input and unrelated tickers.

### Equal gestures produce one step or a long fling

The pure physics target is deterministic. Gesture velocity sampling and
delivery of scroll/ticker frames occur while previous settle work may still be
running. Equal human gestures therefore do not always reach the physics engine
with equal scheduling conditions. Tuning physics would mask rather than remove
the source.

### First fling differs from warm flings

Bootstrap prepares only one parent deck. Adjacent parent/direction/plane decks
depend on asynchronous prewarm. The first structural path can build a cold
deck, while later paths hit cache. In both cases settle still starts a live
watch. Thus cache warmth remains part of interaction behavior.

### Year/month is worse than month/day

Year navigation can activate/build another 12-child parent deck, transfer
more populated preview rows, then start another exact-month live read. Month/
day often has fewer populated day previews. The physical rail engine is the
same; the surrounding data work differs.

### SummaryPill, SVG pulse and amount also drop frames

Their controller identities are independent, but they share Flutter's UI
isolate, Android process CPU, allocator and renderer with platform result
delivery and presentation publication. The old data tasks are triggered by the
same structural actions that start those animations.

## Required replacement boundary

The fix is not another cache, delay or guard. The final call graph must be:

```text
seed ready
  -> one global revision subscription
  -> one background global index build
  -> one immutable index publication
  -> bootstrap barrier opens

any dashboard navigation
  -> semantic/navigation target
  -> PreparedDashboardIndex O(1) lookup
  -> immutable visible-frame pointer selection
  -> optional display-frame coalesced publish
  -> metadata-only commit

database revision only
  -> latest-wins background index rebuild
  -> pending during motion
  -> atomic idle-frame index swap

committed vertical near-end only
  -> explicit bounded page read
```

No navigation action may enter repository, platform, Room, bridge decode or
index-build code, and the per-query EventChannel must cease to exist.

## Implemented final call graph

### Bootstrap and real database changes

```text
FluviDatabase ready (core_revision >= 1)
  -> one GlobalCoreRevisionObserver subscription for the dashboard session
  -> DashboardDataRuntime
  -> PreparedDashboardIndexBuilder (latest generation wins)
  -> MethodChannel readDashboardPreparedIndex
  -> MainActivity Dispatchers.IO
  -> one Room transaction / five counted SQL reads
  -> native day aggregate fold + bounded preview-row retention
  -> FLDI v3 binary payload with one deduplicated row table
  -> IsolateDashboardPreparedIndexDecodeWorker
  -> zero-universe + formatting/grouping/projection in worker isolate
  -> immutable PreparedDashboardIndex
  -> atomic PreparedDashboardIndex + DashboardVisibleFrame publication
  -> bootstrap barrier opens and CoreDashboard mounts
```

The five counted reads are Partner metadata, the daily aggregate batch, the
single ordered preview cursor, Category metadata and the core revision. Their
count does not depend on parent, direction, year, month, day or navigation.

A later revision follows the same builder path. A superseded generation is
discarded. If any dashboard motion lane is active, the completed index stays
pending; the last lane becoming idle schedules one stable-frame callback that
installs the index and complete visible frame under the same revision in one
atomic publication.

### Navigation and motion

```text
SummaryPill / plane / parent / direction / rail-open intent
  -> DashboardPresentationController synchronous navigation metadata
  -> PreparedDashboardIndex prebuilt catalog lookup
  -> PreparedDashboardIndex frame map lookup
  -> display-frame-coalesced DashboardVisibleFrame pointer publication

ScrollPosition
  -> DashboardMotionKernel logical index
  -> immutable DashboardSemanticCatalog[index]
  -> PreparedDashboardIndex.frames[queryKey]
  -> at most one last-target visible publication per display frame

settle
  -> retain semantic child metadata
  -> promote the already-visible prepared frame to committed metadata
  -> no visible notification and no acquisition
```

There is no Future, repository, MethodChannel, EventChannel, Room read,
decode, projection, formatting, grouping, asset parsing or list copy in the
navigation/crossing path. Direction and category icons use build-time compiled
`.svg.vec` assets; source SVG parsing is absent from dashboard widget builds.

### Explicit vertical paging

```text
stable committed LogBox viewport near end
  -> ExplicitCommittedPagingController
  -> readDashboardCommittedPage
  -> exact committed key/revision/navigation/presentation generations
  -> bounded keyset page on Dispatchers.IO
  -> worker-isolate page decode/projection
  -> accept only if every committed identity is still current
```

This is the only remaining exact-scope acquisition. It cannot be expressed by
rail settle, parent, direction, plane or SummaryPill navigation.

## Removed dual-pipeline owners

- Dart PreparedDeck model, binary codec, repository, bounded cache, pipeline,
  prewarm and empty-repository adapters.
- `DashboardCommittedQueryController`, committed live repository contract and
  exact-scope EventChannel adapter.
- Native `com.fluvi/dashboard_query_stream`,
  `DashboardObservationSession`, `observeSlice` and PreparedDeck models/codec.
- Settle-time visual publication and tests that required a live acquisition.

The production dashboard now has one data runtime, one global revision stream,
one current immutable index, at most one pending replacement, one presentation
controller and one explicit paging owner.

## Identity and rail-mechanics evidence

The following baseline and final SHA-256 values are identical:

| File | Baseline/final SHA-256 |
|---|---|
| `lib/features/dashboard/widgets/time_refinement_rail.dart` | `e669d118a2dd6607d295543ddc848f1683d538486b1270b02b8e981b1fbf684a` |
| `lib/shared/motion/centered_carousel/centered_carousel_physics.dart` | `1b3539cea8ac2870f7fae2c64e78f657187df0046b01d77e21c295c8c2c8a5ec` |
| `lib/shared/motion/centered_carousel/centered_carousel_controller.dart` | `2ce33c8a88a52585049d6cb95304e0487097a3e00bbf52b5e694ecb3d1350bbb` |
| `lib/shared/motion/centered_carousel/centered_carousel.dart` | `d454fc2608fbf4532745fe39e0c4b9c6aaefdc511e3f946b6788899f8bf8fcc6` |
| `lib/features/dashboard/motion/dashboard_motion_kernel.dart` | `dc4858703d344adad3bf89bbf75e03711a6a3a101052aa1f509666ef6002a376` |

`git diff` against the baseline is empty for all five files. Widget tests also
keep the rail State, controller, physics, ScrollPosition and LogBox viewport
identities through 100 structural/data changes.

## Local verification recorded before CI

- Full non-golden Flutter suite: `233/233 PASS` in Ubuntu proot.
- Flutter static analysis: `No issues found`.
- Native main and test Kotlin compilation: PASS.
- Native Room execution in local ARM64/proot: host-blocked by the desktop
  SQLite JNI `UnsatisfiedLinkError`; the x86_64 GitHub runner is the required
  execution environment and remains a release gate.
- No golden test or golden reference was added or regenerated. Existing
  user-owned failure images remain untracked and untouched.
