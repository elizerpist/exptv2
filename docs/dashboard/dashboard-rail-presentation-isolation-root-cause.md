# Dashboard rail/presentation isolation root-cause audit

Date: 2026-08-06

Status: causal proof complete; targeted presentation isolation implemented and
verified locally. Profile-mode CI/device evidence is tracked separately in the
acceptance checklist and final report.

## Current ownership graph

```text
DashboardCoreController
  ├── DashboardDataRuntime
  │     ├── GlobalCoreRevisionObserver (one session subscription)
  │     ├── PreparedDashboardIndexBuilder
  │     └── current/pending PreparedDashboardIndex
  ├── DashboardPresentationController
  │     ├── DashboardNavigationController
  │     ├── DashboardMotionKernel
  │     │     └── CenteredCarouselController
  │     │           ├── one ScrollController / framework ScrollPosition
  │     │           └── one mutable-configuration CenterSnapScrollPhysics
  │     ├── DashboardDisplayFrameCoalescer
  │     └── DashboardVisibleFrameStore
  └── ExplicitCommittedPagingController
```

The data architecture is already single-source. Navigation has no repository
capability. The remaining investigation is strictly after the prepared-index
lookup, in the UI-isolate presentation/render path.

## Complete interaction call graph

### SummaryPill, plane and parent navigation

```text
DashboardSummaryPill GestureDetector
  -> _beginGesture / _updateGesture
  -> _finishGesture(DragEndDetails)
  -> _commitWithShellReturn
  -> CoreDashboard callback
  -> DashboardCoreController.navigatePlane or navigateParent
  -> DashboardPresentationController.navigatePlane or navigateParent
  -> DashboardNavigationController metadata commit
  -> DashboardPresentationController._selectStructuralTarget
  -> PreparedDashboardIndex.catalogForKey       O(1), RAM
  -> DashboardMotionKernel.installCatalog
  -> CenteredCarouselController.installSemanticDomain
     (stable controller/position/physics; logical-origin rebinding)
  -> PreparedDashboardIndex.frameForKey         O(1), RAM
  -> DashboardVisibleFrame.fromPrepared         scalar wrapper
  -> DashboardDisplayFrameCoalescer.request
  -> next display frame: DashboardVisibleFrameStore.publish
  -> localized visible-frame listeners
```

Summary shell motion begins synchronously and does not await data. A structural
navigation legitimately rebuilds the structural motion host. It performs no
index build, SQL, channel call or decode.

### Direction change

```text
TransactionDirectionToggle.onSelected
  -> DashboardCoreController.selectDirection
  -> TransactionDirectionController.select (pulse ownership)
  -> DashboardPresentationController.selectDirection
  -> navigation metadata commit
  -> _selectStructuralTarget
  -> prepared catalog/frame lookup
  -> coalesced visible-frame publish
```

The direction pulse controller is independent from `visibleFrames`; a child
crossing must not rebuild or restart it.

### Rail open and close

```text
Summary chevron tap
  -> DashboardCoreController.toggleRail / setRailOpen
  -> DashboardPresentationController.setRailOpen
  -> DashboardNavigationController.setRailOpen
  -> _selectStructuralTarget
  -> existing Motion Kernel catalog/controller
  -> prepared parent or retained child frame
  -> coalesced visible publish
```

The rail is kept in the `Stack`; expansion opacity/ignore-pointer changes are
structural animation state, not QueryKey remounts.

### Drag, semantic crossing and presentation publish

```text
pointer stream
  -> Flutter Scrollable gesture recognizer / velocity tracker
  -> CenteredCarousel ScrollStartNotification
  -> CenteredCarouselController.beginUserMotionCommand
  -> DashboardPresentationController.beginRailMotion
  -> DashboardMotionKernel.beginGesture

ScrollPosition pixel update
  -> CenteredCarouselController._handleScroll
     -> raw centered index from (pixels - minExtent) / fixed itemExtent
     -> DashboardMotionKernel.updateOffset
        -> DashboardMotionKernel.notifyListeners
     -> logical index calculation
     -> _setSelection / _emitPreview
     -> TimeRefinementRail._semanticCrossed
     -> SummaryNavigationMotionController.triggerRailTick
     -> DashboardMotionKernel.semanticCrossed
        -> immutable semantic catalog entry lookup
        -> DashboardPresentationController._onSemanticCrossed
        -> PreparedDashboardIndex.frameForKey       O(1), RAM
        -> DashboardVisibleFrame.fromPrepared       scalar references
        -> DashboardDisplayFrameCoalescer.request
     -> CenteredCarouselController.notifyListeners

next Flutter display frame
  -> DashboardDisplayFrameCoalescer._onDisplayFrame
  -> DashboardPresentationController._publishCoalescedFrame
  -> DashboardVisibleFrameStore.publish
     -> scalar key/revision/digest stale/no-op comparisons
     -> notifyListeners
     -> Summary child-label listener
     -> amount listener
     -> count listener
     -> LogBox viewport listener
     -> DashboardCoreController diagnostic listener
```

The crossing itself is synchronous and RAM-only. The potentially expensive
work starts at the following display-frame publication, on the same Flutter UI
isolate that processes later pointer samples and advances the ballistic
simulation.

### Ballistic handoff and settle

```text
Flutter drag end
  -> CenterSnapScrollPhysics.createBallisticSimulation(metrics, velocity)
  -> CenterSnapPhysicsConfiguration.onBallisticStarted
  -> CenteredCarouselController._emitBallisticStarted
  -> DashboardMotionKernel.beginBallistic
  -> pure target calculation and Flutter BallisticScrollActivity
  -> the same _handleScroll/crossing path for each index crossed

ScrollPosition.isScrollingNotifier false
  -> CenteredCarouselController._handleScrollingChanged
  -> optional far-anchor cyclic rebase only when threshold reached
  -> onMotionIdle
  -> _emitSettledForCommand
  -> TimeRefinementRail.onSelectionSettled
  -> DashboardMotionKernel.settled
  -> DashboardPresentationController._onSettled
  -> DashboardNavigationController.retainSettledChild (metadata)
  -> DashboardVisibleFrameStore.promoteCommitted (no notification)
  -> ExplicitCommittedPagingController.commitMetadata (no acquisition)
```

Settle itself is a visual no-op. Explicit vertical near-end scrolling is the
only path to `loadNextPage` and `readCommittedPage`; rail settle never calls it.

## Data/revision call graph

```text
bootstrap / true database revision only
  -> GlobalCoreRevisionObserver.watchCoreRevision (one subscription/session)
  -> DashboardDataRuntime latest-wins generation
  -> PreparedDashboardIndexBuilder
  -> MethodChannel readDashboardPreparedIndex
  -> Dispatchers.IO Room batch (five counted SQL reads)
  -> native aggregation/mapping/binary encoding
  -> worker-isolate Dart decode/projection
  -> complete immutable PreparedDashboardIndex
  -> bootstrap publish, or pending during motion
  -> atomic install on stable idle frame
```

No rail, Summary, plane, parent or direction method has a reference to the
repository contract. Current interaction counters are all zero for SQL,
repository reads, exact-scope subscriptions/cancellations, bridge payloads and
index builds.

## Baseline presentation consumers and rebuild boundaries

### Rail

`TimeRefinementRail` does not listen to `DashboardVisibleFrameStore`. Its
geometry is a fixed `DashboardBounds`, and `CenteredCarousel` uses a fixed
`itemExtent`. Each visible rail item does listen to
`CenteredCarouselController`, so its opacity/scale item widgets rebuild as the
scroll offset changes. This cost is motion-dependent but not data-density
dependent.

### Summary child label and amount

`DashboardSummaryPill` creates a merged navigation/visible-frame listenable for
the text leaf. Each published child frame rebuilds the text-motion leaf to show
the prepared label. `_PreparedAmountSlot` also listens to the complete visible
frame. Preview mode directly replaces prepared text and stops its animation;
it performs no currency formatting, but it still rebuilds/text-layouts.

### Count

`DashboardLogBoxHeader` retains its shell, while its count leaf listens to the
complete visible frame and rebuilds the prepared text.

### LogBox

`DashboardLogBoxViewport` retains one State and vertical ScrollController. It
uses a lazy `CustomScrollView`; there is no QueryKey key, nested shrinkWrap,
build-time sort/group/format or asset decode. However, every visible-frame
notification rebuilds `_DashboardLogScrollArea`, allocates its sliver widget
description, iterates all prepared groups to create delegates, and builds the
new viewport's currently visible row widgets. Empty frames build no rows;
populated frames build text/icon/semantics/paint work. The prior profile
records this density-correlated UI cost, especially for year → month.

### Root and pulse

`DashboardMotionHost` listens only to structural expansion/navigation/
direction motion. Visible child publication does not rebuild the dashboard
root, rail shell, header shell or SVG direction pulse subtree according to the
existing counters. These assertions remain necessary but do not prove pointer
velocity or ballistic continuity.

## Static exclusions

The source audit found no data-dependent value in:

- physics constants or target calculation;
- `itemExtent`, `min/max velocity`, friction or snap spring;
- semantic catalog lookup;
- `DashboardVisibleFrame.fromPrepared` list handling;
- `DashboardVisibleFrameStore` equality (scalar/digest only);
- crossing-time repository, channel, SQL, parse, format, group or projection;
- QueryKey-based rail or LogBox remount.

`DashboardLogViewportState.hasSameVisualValue` performs deep group/row checks,
but the current crossing path does not call it. It is not accepted as a cause
without a dynamic call/CPU trace.

## Dynamic causal proof

The proof-first flight recorder was added before the presentation change. It
captures Flutter's raw drag release velocity and the exact velocity received by
`createBallisticSimulation`, plus controller/position/physics/activity identity,
scroll geometry, metric notifications, presentation timing, frame timing and
the final endpoint. The recorder is a bounded typed ring, disabled by default,
and does not emit per-pixel strings.

Each deterministic fixture used the same start pixel, item extent, pointer
positions, sample cadence, drag duration and distance. Each pair ran 30 times.
The complete month/day matrix ran 150 flings and the year/month matrix ran 120.

The first physical divergence did **not** occur in gesture or motion:

| Measurement | Empty | Populated | Result |
|---|---:|---:|---|
| drag release velocity, forward | -2032.8611936301181 | -2032.8611936301181 | identical |
| ballistic input velocity, forward | 2199.9966122376204 | 2199.9966122376204 | identical |
| final logical delta, forward | 10 | 10 | identical |
| final pixel distance, forward | 524.5201793722808 | 524.5201793722808 | identical |
| ballistic interruption count | 0 | 0 | identical |
| scroll metric-change count | 0 | 0 | identical |
| controller/position/physics recreation | 0 | 0 | identical |

Reverse year/month runs produced the exact sign-reversed motion: release
`2032.8611936299187`, ballistic input `-2199.996612237566`, logical delta `-10`
and pixel distance `-524.5201793722808`.

The first density-dependent difference was therefore after prepared-frame
selection, in rendering:

```text
prepared populated frame
  -> visible-frame notification
  -> per-group LogBox sliver/delegate tree recreation
  -> more visible LogBox row build/layout/paint
  -> longer UI frame
```

This explains why the populated rail felt shorter despite reaching the same
physical target: intermediate child presentation was less continuously visible.
The larger month LogBox presentation made year -> month perceptually worse.
There was no evidence for physics tuning, velocity compensation, activity
interruption or metric correction, so none was introduced.

## Targeted final path

The data runtime, immutable prepared index, bootstrap barrier, coalescer and
carousel physics remain intact. Only the evidenced post-lookup path changed:

```text
semantic crossing
  -> O(1) PreparedPresentationFrame reference lookup
  -> one display-frame-coalesced visible frame
  -> atomic staging of navigation/amount/count/LogBox lane pointers
  -> lane-local notification
  -> one stable LogBox viewport and one lazy SliverList
  -> only visible preprojected rows build
```

`DashboardPreparedFrame` now precomputes constant-time frame, amount, count and
LogBox viewport identities. `DashboardLogViewportState` preflattens bounded
headers/rows/gaps and group paint geometry during prepared-data projection.
Crossing performs neither collection equality/hash nor list/map copies,
formatting, grouping, sorting, projection or asynchronous work.

The LogBox outer State and vertical controller remain stable. Its content lane
swaps the prepared viewport reference; a custom painter preserves the grouped
card backgrounds while a single lazy sliver creates only visible rows. The
rail listens to no content lane. Settle still promotes metadata without a
visual publish, LogBox rebind or amount animation.

## Local deterministic result after isolation

All density fixtures retained identical motion and zero activity/metric
changes. Representative local widget-harness presentation measurements were:

| Pair | Apply p50 (us) | Apply p95 (us) | Apply p99 (us) | Log bind p95 (us) | Row builds p95 |
|---|---:|---:|---:|---:|---:|
| month/day empty | 495 | 758 | 1787 | 130 | 0 |
| month/day 2 rows | 460 | 929 | 1079 | 441 | 16 |
| month/day 9 rows | 418 | 792 | 2219 | 276 | 56 |
| month/day large amount, 2 rows | 390 | 955 | 1658 | 148 | 16 |
| year/month empty | 503 | 1004 | 1393 | 396 | 0 |
| year/month 94-row child / 658-row parent | 510 | 879 | 921 | 291 | 40 |

These are deterministic debug widget-harness timings, not AOT physical-device
smoothness claims. The profile workflow records AOT UI/raster percentiles,
allocation/GC, metrics, activities and rebuild counters for the final evidence.
