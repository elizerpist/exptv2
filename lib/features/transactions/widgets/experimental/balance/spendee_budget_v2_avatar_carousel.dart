import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../../../core/debug/debug_console.dart';
import '../spendee_center_carousel_controller.dart';
import 'spendee_budget_v2_avatar_rail_coordinator.dart';

typedef SpendeeBudgetV2AvatarCarouselItemBuilder =
    Widget Function(
      BuildContext context,
      int index,
      bool selected,
      VoidCallback select,
    );
typedef SpendeeBudgetV2AvatarCarouselItemSizeBuilder =
    Size Function(int index, bool selected);
typedef SpendeeBudgetV2AvatarCarouselCenterOffsetBuilder =
    double Function(double logicalOffset);
typedef SpendeeBudgetV2AvatarCarouselVisualScaleBuilder =
    double Function(int index, bool selected, double visualLogicalOffset);
typedef SpendeeBudgetV2AvatarCarouselPreviewCallback =
    void Function(int index, {required bool directDrag});
typedef SpendeeBudgetV2AvatarCarouselSettledCallback =
    void Function(int index, {required bool directDrag});
typedef SpendeeBudgetV2AvatarCarouselInteractionCallback =
    void Function({required bool directDrag});
typedef SpendeeBudgetV2AvatarCarouselInteractionCompletedCallback =
    void Function({
      required int settledIndex,
      required int physicalFrameCount,
      required bool cancelled,
    });

/// Budget V2's dedicated, responsive avatar belt.
///
/// This deliberately mirrors the normal Budget carousel's state boundary:
/// controller ticks and snap motion are local to this widget, while the host
/// receives only a lightweight preview and a final settled item. Keeping this
/// ownership outside the Balance-wide ticker prevents an expensive dashboard
/// or TransactionStore rebuild from competing with a pointer drag.
class SpendeeBudgetV2AvatarCarousel extends StatefulWidget {
  const SpendeeBudgetV2AvatarCarousel({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    this.externalSelectionEpoch = 0,
    required this.height,
    required this.slotDistance,
    required this.itemSizeBuilder,
    required this.itemBuilder,
    this.centerOffsetBuilder,
    this.itemVisualScaleBuilder,
    this.onPreview,
    this.onSettled,
    this.onPointerDown,
    this.onInteractionStarted,
    this.onInteractionCancelled,
    this.onInteractionCompleted,
    this.semanticLabel,
  }) : assert(itemCount > 0),
       assert(selectedIndex >= 0 && selectedIndex < itemCount),
       assert(height > 0),
       assert(slotDistance > 0);

  final int itemCount;
  final int selectedIndex;
  final int externalSelectionEpoch;
  final double height;
  final double slotDistance;
  final SpendeeBudgetV2AvatarCarouselItemSizeBuilder itemSizeBuilder;
  final SpendeeBudgetV2AvatarCarouselItemBuilder itemBuilder;
  final SpendeeBudgetV2AvatarCarouselCenterOffsetBuilder? centerOffsetBuilder;
  final SpendeeBudgetV2AvatarCarouselVisualScaleBuilder? itemVisualScaleBuilder;
  final SpendeeBudgetV2AvatarCarouselPreviewCallback? onPreview;
  final SpendeeBudgetV2AvatarCarouselSettledCallback? onSettled;
  final VoidCallback? onPointerDown;
  final SpendeeBudgetV2AvatarCarouselInteractionCallback? onInteractionStarted;
  final SpendeeBudgetV2AvatarCarouselInteractionCallback?
  onInteractionCancelled;
  final SpendeeBudgetV2AvatarCarouselInteractionCompletedCallback?
  onInteractionCompleted;
  final String? semanticLabel;

  @override
  State<SpendeeBudgetV2AvatarCarousel> createState() =>
      _SpendeeBudgetV2AvatarCarouselState();
}

class _SpendeeBudgetV2AvatarCarouselState
    extends State<SpendeeBudgetV2AvatarCarousel>
    with SingleTickerProviderStateMixin {
  // Five avatars are fully visible at rest. The two extra edge entries are
  // retained at zero opacity, so an incoming item already owns its SVG/icon
  // subtree before it crosses into the visible belt.
  static const _slotOffsets = <int>[-3, -2, -1, 0, 1, 2, 3];

  late SpendeeCenterCarouselController _controller;
  late SpendeeBudgetV2AvatarRailCoordinator _railCoordinator;
  late final AnimationController _motionController;
  late final _AvatarRailMotionSignal _motionSignal;
  final Map<int, _AvatarRailCachedItem> _cachedItems =
      <int, _AvatarRailCachedItem>{};
  var _liveTicked = false;
  var _physicalFrameCount = 0;
  var _viewportWidth = 0.0;

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = _newController(widget.selectedIndex);
    _railCoordinator = SpendeeBudgetV2AvatarRailCoordinator(
      externalSelectionEpoch: widget.externalSelectionEpoch,
    );
    _motionController = AnimationController(vsync: this);
    _motionSignal = _AvatarRailMotionSignal();
  }

  @override
  void didUpdateWidget(covariant SpendeeBudgetV2AvatarCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A parent update is a real configuration boundary even when it reuses
    // the same builder tear-off. Recreate the retained presentation once so
    // captured callbacks and inherited values cannot go stale.
    _cachedItems.clear();
    final itemCountChanged = oldWidget.itemCount != widget.itemCount;
    final slotDistanceChanged = oldWidget.slotDistance != widget.slotDistance;
    if (itemCountChanged || slotDistanceChanged) {
      _stopCurrentMotion();
      _controller = _newController(
        widget.selectedIndex.clamp(0, widget.itemCount - 1).toInt(),
      );
      _railCoordinator.reset(
        externalSelectionEpoch: widget.externalSelectionEpoch,
      );
      return;
    }

    // A local settlement updates the parent selected index as an
    // acknowledgement. It is not a new command. Only an explicit epoch can
    // take physical ownership away from the belt.
    if (_railCoordinator.consumeExternalSelectionEpoch(
      widget.externalSelectionEpoch,
    )) {
      _startExternalSelection(widget.selectedIndex, force: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The item builder may have read Theme, MediaQuery, or another inherited
    // value from this carousel context. Dependency updates are presentation
    // boundaries; repaint-listenable motion never enters this lifecycle.
    _cachedItems.clear();
  }

  @override
  void dispose() {
    _motionController.dispose();
    _motionSignal.dispose();
    super.dispose();
  }

  SpendeeCenterCarouselController _newController(int index) =>
      SpendeeCenterCarouselController(
        itemCount: widget.itemCount,
        initialIndex: index,
        slotDistance: widget.slotDistance,
        switchThreshold: widget.slotDistance * .6875,
      );

  void _stopCurrentMotion() {
    _motionController.stop();
  }

  void _beginDirectDrag(DragStartDetails details) {
    _startInteraction(directDrag: true, source: 'drag');
  }

  void _startInteraction({
    required bool directDrag,
    required String source,
    int? externalTargetIndex,
  }) {
    _stopCurrentMotion();
    final serial = directDrag
        ? _railCoordinator.beginDirectMotion()
        : _railCoordinator.beginExternalMotion(
            targetIndex: externalTargetIndex!,
          );
    _controller.beginDragFromCurrentMotion();
    _liveTicked = false;
    _physicalFrameCount = 0;
    widget.onInteractionStarted?.call(directDrag: directDrag);
    DebugConsole.log(
      '[BudgetV2AvatarRail] phase=start id=$serial source=$source '
      'index=${_controller.index} viewport_width='
      '${_viewportWidth.toStringAsFixed(1)} center_x='
      '${(_viewportWidth / 2).toStringAsFixed(1)}',
    );
  }

  void _updateDirectDrag(DragUpdateDetails details) {
    _physicalFrameCount += 1;
    _applyMotionDelta(details.delta.dx, directDrag: true);
  }

  void _endDirectDrag(DragEndDetails details) {
    final serial = _railCoordinator.activeSerial;
    final velocity = details.primaryVelocity ?? 0;
    unawaited(_release(serial: serial, velocityDx: velocity));
  }

  void _cancelDirectDrag() {
    final serial = _railCoordinator.activeSerial;
    widget.onInteractionCancelled?.call(directDrag: true);
    unawaited(_cancel(serial: serial));
  }

  Future<void> _cancel({required int serial}) async {
    await _animateTravel(
      travel: _controller.cancelTravel(),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      serial: serial,
      directDrag: true,
    );
    if (!mounted || !_railCoordinator.isCurrent(serial)) return;
    _railCoordinator.finishWithoutSettlement(serial);
    DebugConsole.log(
      '[BudgetV2AvatarRail] phase=cancel id=$serial source=drag '
      'index=${_controller.index}',
    );
    widget.onInteractionCompleted?.call(
      settledIndex: _controller.index,
      physicalFrameCount: _physicalFrameCount,
      cancelled: true,
    );
  }

  Future<void> _release({
    required int serial,
    required double velocityDx,
  }) async {
    final motion = _controller.releaseMotion(
      velocityDx: velocityDx,
      liveTicked: _liveTicked,
    );
    await _animateTravel(
      travel: motion.initialTravel,
      duration: motion.initialDuration,
      curve: motion.inertial ? Curves.easeOutQuad : Curves.easeOutCubic,
      serial: serial,
      directDrag: true,
    );
    if (!mounted || !_railCoordinator.isCurrent(serial)) return;
    final settleTravel = _controller.settleTravel(
      preferredDxDirection: motion.preferredDxDirection,
      allowDirectionalSnap: motion.directionalSnapAllowed,
    );
    await _animateTravel(
      travel: settleTravel,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      serial: serial,
      directDrag: true,
    );
    if (!mounted || !_railCoordinator.isCurrent(serial)) return;
    _settle(serial: serial, source: 'drag', directDrag: true);
  }

  void _startExternalSelection(int index, {bool force = false}) {
    if (!force &&
        index == _controller.index &&
        _controller.residualDx.abs() < .01) {
      return;
    }
    _startInteraction(
      directDrag: false,
      source: 'step',
      externalTargetIndex: index,
    );
    final serial = _railCoordinator.activeSerial;
    unawaited(_animateExternalSelection(targetIndex: index, serial: serial));
  }

  Future<void> _animateExternalSelection({
    required int targetIndex,
    required int serial,
  }) async {
    while (mounted &&
        _railCoordinator.isCurrent(serial) &&
        (_controller.index != targetIndex ||
            _controller.residualDx.abs() > .01)) {
      final remaining = _controller.travelToIndex(targetIndex);
      if (remaining.abs() < .01) break;
      final step = remaining
          .clamp(-widget.slotDistance, widget.slotDistance)
          .toDouble();
      await _animateTravel(
        travel: step,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        serial: serial,
        directDrag: false,
      );
    }
    if (!mounted || !_railCoordinator.isCurrent(serial)) return;
    _settle(serial: serial, source: 'step', directDrag: false);
  }

  Future<void> _animateTravel({
    required double travel,
    required Duration duration,
    required Curve curve,
    required int serial,
    required bool directDrag,
  }) async {
    if (travel.abs() < .001 ||
        !mounted ||
        !_railCoordinator.isCurrent(serial)) {
      return;
    }
    if (_reducedMotion) {
      _applyMotionDelta(travel, directDrag: directDrag);
      return;
    }
    _motionController
      ..stop()
      ..duration = duration;
    var lastValue = 0.0;
    final animation = Tween<double>(
      begin: 0,
      end: travel,
    ).animate(CurvedAnimation(parent: _motionController, curve: curve));
    void applyFrame() {
      if (!mounted || !_railCoordinator.isCurrent(serial)) return;
      final delta = animation.value - lastValue;
      lastValue = animation.value;
      if (delta != 0) _applyMotionDelta(delta, directDrag: directDrag);
    }

    animation.addListener(applyFrame);
    var completed = false;
    try {
      await _motionController.forward(from: 0).orCancel;
      completed = true;
    } on TickerCanceled {
      // The next gesture owns the controller's current residual position.
    } finally {
      animation.removeListener(applyFrame);
    }
    if (!completed || !mounted || !_railCoordinator.isCurrent(serial)) return;
    final remainder = travel - lastValue;
    if (remainder.abs() >= .001) {
      _applyMotionDelta(remainder, directDrag: directDrag);
    }
  }

  void _applyMotionDelta(double deltaDx, {required bool directDrag}) {
    if (!mounted || deltaDx == 0) return;
    final update = _controller.applyDragDelta(deltaDx);
    if (update.tickedIndexes.isNotEmpty) {
      _liveTicked = true;
      setState(() {});
      for (final index in update.tickedIndexes) {
        HapticFeedback.selectionClick();
        widget.onPreview?.call(index, directDrag: directDrag);
      }
    }
    _motionSignal.markNeedsPaint();
  }

  void _settle({
    required int serial,
    required String source,
    required bool directDrag,
  }) {
    if (!_railCoordinator.settle(serial)) return;
    DebugConsole.log(
      '[BudgetV2AvatarRail] phase=settle id=$serial source=$source '
      'index=${_controller.index} residual='
      '${_controller.residualDx.toStringAsFixed(2)}',
    );
    widget.onSettled?.call(_controller.index, directDrag: directDrag);
    if (directDrag) {
      widget.onInteractionCompleted?.call(
        settledIndex: _controller.index,
        physicalFrameCount: _physicalFrameCount,
        cancelled: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('spendee-budget-v2-avatar-carousel-viewport'),
      width: double.infinity,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : 0;
          if (_viewportWidth <= 0) return const SizedBox.shrink();
          final activeIndex = _controller.index;
          final slots = _slotsFor(activeIndex);
          final items = _itemsFor(slots);
          return Listener(
            behavior: HitTestBehavior.translucent,
            // Cancelling an idle dashboard commit must happen on raw pointer
            // contact, not when Flutter later resolves the horizontal-drag
            // arena. That keeps the next swipe responsive even if the prior
            // belt selection was waiting on its debounce timer.
            onPointerDown: _handlePointerDown,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onHorizontalDragStart: _beginDirectDrag,
              onHorizontalDragUpdate: _updateDirectDrag,
              onHorizontalDragEnd: _endDirectDrag,
              onHorizontalDragCancel: _cancelDirectDrag,
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: widget.semanticLabel,
                child: Flow(
                  key: const ValueKey(
                    'spendee-budget-v2-avatar-carousel-stack',
                  ),
                  clipBehavior: Clip.none,
                  delegate: _AvatarRailFlowDelegate(
                    repaint: _motionSignal,
                    controller: _controller,
                    slots: slots,
                    height: widget.height,
                    slotDistance: widget.slotDistance,
                    centerOffsetBuilder: widget.centerOffsetBuilder,
                    itemVisualScaleBuilder: widget.itemVisualScaleBuilder,
                  ),
                  children: items,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<_AvatarRailSlot> _slotsFor(int activeIndex) {
    // Keep the five visible slots and one retained entry on each edge live,
    // but never render the same category twice. A small belt wraps quickly
    // (for example, a three-item belt maps multiple logical positions to the
    // same category), so the closest logical position wins and every avatar
    // has one unambiguous interaction target.
    final closestOffsetByIndex = <int, int>{};
    for (final logicalOffset in _slotOffsets) {
      final index =
          (activeIndex + logicalOffset + widget.itemCount) % widget.itemCount;
      final existing = closestOffsetByIndex[index];
      if (existing == null || logicalOffset.abs() < existing.abs()) {
        closestOffsetByIndex[index] = logicalOffset;
      }
    }
    final slots = <_AvatarRailSlot>[
      for (final logicalOffset in _slotOffsets)
        _AvatarRailSlot(
          index:
              (activeIndex + logicalOffset + widget.itemCount) %
              widget.itemCount,
          logicalOffset: logicalOffset,
          size: widget.itemSizeBuilder(
            (activeIndex + logicalOffset + widget.itemCount) % widget.itemCount,
            logicalOffset == 0,
          ),
          enabled:
              closestOffsetByIndex[(activeIndex +
                      logicalOffset +
                      widget.itemCount) %
                  widget.itemCount] ==
              logicalOffset,
        ),
    ];
    slots.sort((left, right) {
      final leftDistance = left.logicalOffset.abs();
      final rightDistance = right.logicalOffset.abs();
      return rightDistance.compareTo(leftDistance);
    });
    return slots;
  }

  List<Widget> _itemsFor(List<_AvatarRailSlot> slots) {
    final retainedIndexes = <int>{};
    final items = <Widget>[];
    for (final slot in slots) {
      if (!slot.enabled) {
        items.add(
          SizedBox.shrink(
            key: ValueKey(
              'spendee-budget-v2-avatar-carousel-empty-'
              '${slot.logicalOffset}',
            ),
          ),
        );
        continue;
      }
      retainedIndexes.add(slot.index);
      final selected =
          slot.index == _controller.index && slot.logicalOffset == 0;
      final cached = _cachedItems[slot.index];
      final item = cached != null && cached.selected == selected
          ? cached.child
          : widget.itemBuilder(
              context,
              slot.index,
              selected,
              () => _selectFromTap(slot.index),
            );
      _cachedItems[slot.index] = _AvatarRailCachedItem(
        selected: selected,
        child: item,
      );
      items.add(
        _AvatarRailInteractionGate(
          key: ValueKey('spendee-budget-v2-avatar-carousel-item-${slot.index}'),
          controller: _controller,
          logicalOffset: slot.logicalOffset,
          slotDistance: widget.slotDistance,
          motionSignal: _motionSignal,
          child: RepaintBoundary(
            key: ValueKey(
              'spendee-budget-v2-avatar-carousel-boundary-${slot.index}',
            ),
            child: KeyedSubtree(
              key: ValueKey(
                'spendee-budget-v2-avatar-carousel-scale-${slot.index}',
              ),
              child: item,
            ),
          ),
        ),
      );
    }
    _cachedItems.removeWhere((index, _) => !retainedIndexes.contains(index));
    return items;
  }

  void _handlePointerDown(PointerDownEvent _) {
    widget.onPointerDown?.call();
    if (!_railCoordinator.ownsExternalMotion) return;

    // Stop the old external tween and synchronously centre its target before
    // Flutter's drag arena waits for a horizontal threshold. This gives the
    // very next swipe a clean physical origin instead of a cooldown. Do not
    // take direct ownership yet: a tap/hold that never becomes a horizontal
    // drag still needs the original external request to settle and clear its
    // host-side requested target.
    final externalTargetIndex =
        _railCoordinator.externalTargetIndex ?? _controller.index;
    _stopCurrentMotion();
    _controller.reset(index: externalTargetIndex);
    _liveTicked = false;
    DebugConsole.log(
      '[BudgetV2AvatarRail] phase=interrupt id=${_railCoordinator.activeSerial} '
      'source=pointer '
      'index=${_controller.index}',
    );
    _motionSignal.markNeedsPaint();
    if (mounted) setState(() {});
  }

  void _selectFromTap(int index) {
    if (index == _controller.index && _controller.residualDx.abs() < .01) {
      return;
    }
    _startInteraction(
      directDrag: false,
      source: 'tap',
      externalTargetIndex: index,
    );
    final serial = _railCoordinator.activeSerial;
    unawaited(_animateExternalSelection(targetIndex: index, serial: serial));
  }
}

class _AvatarRailMotionSignal extends ChangeNotifier {
  void markNeedsPaint() => notifyListeners();
}

class _AvatarRailSlot {
  const _AvatarRailSlot({
    required this.index,
    required this.logicalOffset,
    required this.size,
    required this.enabled,
  });

  final int index;
  final int logicalOffset;
  final Size size;
  final bool enabled;
}

class _AvatarRailCachedItem {
  const _AvatarRailCachedItem({required this.selected, required this.child});

  final bool selected;
  final Widget child;
}

class _AvatarRailInteractionGate extends SingleChildRenderObjectWidget {
  const _AvatarRailInteractionGate({
    super.key,
    required this.controller,
    required this.logicalOffset,
    required this.slotDistance,
    required this.motionSignal,
    required super.child,
  });

  final SpendeeCenterCarouselController controller;
  final int logicalOffset;
  final double slotDistance;
  final _AvatarRailMotionSignal motionSignal;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAvatarRailInteractionGate(
      controller: controller,
      logicalOffset: logicalOffset,
      slotDistance: slotDistance,
      motionSignal: motionSignal,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAvatarRailInteractionGate renderObject,
  ) {
    renderObject
      ..controller = controller
      ..logicalOffset = logicalOffset
      ..slotDistance = slotDistance
      ..motionSignal = motionSignal;
  }
}

class _RenderAvatarRailInteractionGate extends RenderProxyBox {
  _RenderAvatarRailInteractionGate({
    required SpendeeCenterCarouselController controller,
    required int logicalOffset,
    required double slotDistance,
    required _AvatarRailMotionSignal motionSignal,
  }) : _controller = controller,
       _logicalOffset = logicalOffset,
       _slotDistance = slotDistance,
       _motionSignal = motionSignal;

  SpendeeCenterCarouselController _controller;
  int _logicalOffset;
  double _slotDistance;
  _AvatarRailMotionSignal _motionSignal;

  SpendeeCenterCarouselController get controller => _controller;
  set controller(SpendeeCenterCarouselController value) {
    if (identical(value, _controller)) return;
    _updateConfiguration(() => _controller = value);
  }

  int get logicalOffset => _logicalOffset;
  set logicalOffset(int value) {
    if (value == _logicalOffset) return;
    _updateConfiguration(() => _logicalOffset = value);
  }

  double get slotDistance => _slotDistance;
  set slotDistance(double value) {
    if (value == _slotDistance) return;
    _updateConfiguration(() => _slotDistance = value);
  }

  _AvatarRailMotionSignal get motionSignal => _motionSignal;
  set motionSignal(_AvatarRailMotionSignal value) {
    if (identical(value, _motionSignal)) return;
    if (attached) _motionSignal.removeListener(_handleMotion);
    _motionSignal = value;
    if (attached) _motionSignal.addListener(_handleMotion);
    _syncSemanticsVisibility();
  }

  bool get _isVisible =>
      (_logicalOffset + _controller.residualDx / _slotDistance).abs() < 3;

  void _updateConfiguration(VoidCallback update) {
    update();
    _syncSemanticsVisibility();
  }

  void _handleMotion() {
    // Flow owns the paint invalidation. When accessibility is active, rebuild
    // only semantics geometry so its transform follows the same live residual.
    // With no semantics owner this path remains paint-only.
    if (owner?.semanticsOwner != null) markNeedsSemanticsUpdate();
  }

  void _syncSemanticsVisibility() {
    if (owner?.semanticsOwner != null) markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _motionSignal.addListener(_handleMotion);
    _syncSemanticsVisibility();
  }

  @override
  void detach() {
    _motionSignal.removeListener(_handleMotion);
    super.detach();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_isVisible) return false;
    return super.hitTest(result, position: position);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_isVisible) super.visitChildrenForSemantics(visitor);
  }
}

class _AvatarRailFlowDelegate extends FlowDelegate {
  _AvatarRailFlowDelegate({
    required Listenable repaint,
    required this.controller,
    required this.slots,
    required this.height,
    required this.slotDistance,
    required this.centerOffsetBuilder,
    required this.itemVisualScaleBuilder,
  }) : super(repaint: repaint);

  final SpendeeCenterCarouselController controller;
  final List<_AvatarRailSlot> slots;
  final double height;
  final double slotDistance;
  final SpendeeBudgetV2AvatarCarouselCenterOffsetBuilder? centerOffsetBuilder;
  final SpendeeBudgetV2AvatarCarouselVisualScaleBuilder? itemVisualScaleBuilder;

  @override
  BoxConstraints getConstraintsForChild(int index, BoxConstraints constraints) {
    final slot = slots[index];
    if (!slot.enabled) return const BoxConstraints.tightFor();
    return BoxConstraints.tight(slot.size);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    for (var childIndex = 0; childIndex < context.childCount; childIndex += 1) {
      final slot = slots[childIndex];
      if (!slot.enabled) continue;
      final childSize = context.getChildSize(childIndex);
      if (childSize == null) continue;
      final selected =
          slot.index == controller.index && slot.logicalOffset == 0;
      final authoredOffset =
          centerOffsetBuilder?.call(slot.logicalOffset.toDouble()) ??
          slot.logicalOffset * slotDistance;
      final visualLogicalOffset =
          slot.logicalOffset + controller.residualDx / slotDistance;
      final opacity = _entryOpacity(visualLogicalOffset);
      final scale =
          itemVisualScaleBuilder?.call(
            slot.index,
            selected,
            visualLogicalOffset,
          ) ??
          1.0;
      final centerX =
          context.size.width / 2 + authoredOffset + controller.residualDx;
      final transform = Matrix4.identity()
        ..translateByDouble(centerX, height / 2, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1)
        ..translateByDouble(-childSize.width / 2, -childSize.height / 2, 0, 1);
      context.paintChild(childIndex, transform: transform, opacity: opacity);
    }
  }

  double _entryOpacity(double visualLogicalOffset) {
    final distance = visualLogicalOffset.abs();
    if (distance <= 2) return 1;
    if (distance >= 3) return 0;
    return 3 - distance;
  }

  @override
  bool shouldRelayout(covariant _AvatarRailFlowDelegate oldDelegate) {
    if (slots.length != oldDelegate.slots.length) return true;
    for (var index = 0; index < slots.length; index += 1) {
      final slot = slots[index];
      final oldSlot = oldDelegate.slots[index];
      if (slot.enabled != oldSlot.enabled || slot.size != oldSlot.size) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _AvatarRailFlowDelegate oldDelegate) => true;
}
