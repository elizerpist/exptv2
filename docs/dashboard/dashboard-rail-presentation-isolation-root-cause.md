# Dashboard rail/presentation isolation root-cause audit

Date: 2026-08-06

Status: static call graph complete; dynamic divergence proof pending.

No production behavior change may be made until the dynamic instrumentation
described below identifies the first empty/populated divergence.

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

## Presentation consumers and current rebuild boundaries

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

## Unproven causal chain and measurement gate

The established correlation is:

```text
prepared populated frame
  -> visible-frame notification
  -> more LogBox row/sliver build/layout/paint
  -> longer UI frame
```

What remains unknown is the first physical divergence:

1. pointer events may be delivered with larger gaps, changing Flutter's
   release velocity estimate;
2. release velocity may match while the physics receives a different value;
3. both velocities may match while an activity/metrics correction interrupts
   the simulation;
4. the physical endpoint may match and only build/raster jank changes the
   perceived distance.

The implementation phase must first add a disabled-by-default bounded flight
recorder and run at least 30 identical traces for each required density pair.
Only the first statistically repeatable divergence may define the fix. This
prevents another data-architecture rewrite or physics compensation based on a
subjective symptom.
