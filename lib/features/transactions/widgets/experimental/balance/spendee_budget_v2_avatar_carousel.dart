import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  var _liveTicked = false;
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
  }

  @override
  void didUpdateWidget(covariant SpendeeBudgetV2AvatarCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  void dispose() {
    _motionController.dispose();
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
    widget.onInteractionStarted?.call(directDrag: directDrag);
    DebugConsole.log(
      '[BudgetV2AvatarRail] phase=start id=$serial source=$source '
      'index=${_controller.index} viewport_width='
      '${_viewportWidth.toStringAsFixed(1)} center_x='
      '${(_viewportWidth / 2).toStringAsFixed(1)}',
    );
    if (mounted) setState(() {});
  }

  void _updateDirectDrag(DragUpdateDetails details) {
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
    setState(() {});
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
    setState(() {});
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
    setState(() {});
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
      for (final index in update.tickedIndexes) {
        HapticFeedback.selectionClick();
        widget.onPreview?.call(index, directDrag: directDrag);
      }
    }
    setState(() {});
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
                child: Stack(
                  key: const ValueKey(
                    'spendee-budget-v2-avatar-carousel-stack',
                  ),
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    for (final slot in slots)
                      _positionedItem(
                        context,
                        index: slot.index,
                        logicalOffset: slot.logicalOffset,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<({int index, int logicalOffset})> _slotsFor(int activeIndex) {
    // Keep the five visible slots and one retained entry on each edge live,
    // but never render the same category twice. A small belt wraps quickly
    // (for example, a three-item belt maps multiple logical positions to the
    // same category), so the closest logical position wins and every avatar
    // has one unambiguous interaction target.
    final slotsByIndex = <int, ({int index, int logicalOffset})>{};
    for (final logicalOffset in _slotOffsets) {
      final index =
          (activeIndex + logicalOffset + widget.itemCount) % widget.itemCount;
      final candidate = (index: index, logicalOffset: logicalOffset);
      final existing = slotsByIndex[index];
      if (existing == null ||
          candidate.logicalOffset.abs() < existing.logicalOffset.abs()) {
        slotsByIndex[index] = candidate;
      }
    }
    final slots = slotsByIndex.values.toList();
    slots.sort((left, right) {
      final leftDistance = left.logicalOffset.abs();
      final rightDistance = right.logicalOffset.abs();
      return rightDistance.compareTo(leftDistance);
    });
    return slots;
  }

  Widget _positionedItem(
    BuildContext context, {
    required int index,
    required int logicalOffset,
  }) {
    final selected = index == _controller.index && logicalOffset == 0;
    final size = widget.itemSizeBuilder(index, selected);
    final authoredOffset =
        widget.centerOffsetBuilder?.call(logicalOffset.toDouble()) ??
        logicalOffset * widget.slotDistance;
    final physicalOffset = authoredOffset + _controller.residualDx;
    // Authored inner/outer spacing may deliberately stretch the physical
    // positions of a band. Visual band state must remain logical, otherwise
    // widening the outer gap would fade or shrink a still-visible ±2 avatar.
    final visualLogicalOffset =
        logicalOffset + _controller.residualDx / widget.slotDistance;
    final opacity = _entryOpacity(visualLogicalOffset);
    final scale =
        widget.itemVisualScaleBuilder?.call(
          index,
          selected,
          visualLogicalOffset,
        ) ??
        1.0;
    final centerX = _viewportWidth / 2 + physicalOffset;
    return Positioned(
      // The category owns its subtree while it travels across the belt. In
      // particular, an already-built +3 entry must retain its decoded icon
      // when it becomes the visible +2 item after the controller tick.
      key: ValueKey('spendee-budget-v2-avatar-carousel-item-$index'),
      left: centerX - size.width / 2,
      top: (widget.height - size.height) / 2,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        ignoring: opacity <= 0,
        child: Opacity(
          opacity: opacity,
          child: RepaintBoundary(
            child: Transform.scale(
              key: ValueKey('spendee-budget-v2-avatar-carousel-scale-$index'),
              alignment: Alignment.center,
              scale: scale,
              child: widget.itemBuilder(
                context,
                index,
                selected,
                () => _selectFromTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _entryOpacity(double visualLogicalOffset) {
    final distance = visualLogicalOffset.abs();
    if (distance <= 2) return 1;
    if (distance >= 3) return 0;
    return 3 - distance;
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
