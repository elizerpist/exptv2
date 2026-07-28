import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../spendee_center_carousel_controller.dart';

typedef SpendeeBalanceTickingItemBuilder =
    Widget Function(
      BuildContext context,
      int index,
      bool selected,
      VoidCallback select,
    );
typedef SpendeeBalanceTickingItemSizeBuilder =
    Size Function(int index, bool selected);
typedef SpendeeBalanceTickingCenterOffsetBuilder =
    double Function(int logicalOffset);
typedef SpendeeBalanceTickingItemScaleBuilder =
    double Function(int index, bool selected, double centeredness);

/// Shared Balance belt driver using the shipping Budget carousel physics.
///
/// The visual owner supplies item sizes and positions; this class exclusively
/// owns boundary ticks, residual motion, wrap, inertia, snap, cancel and
/// selection haptics.
class SpendeeBalanceTickingViewport extends StatefulWidget {
  const SpendeeBalanceTickingViewport({
    super.key,
    required this.width,
    required this.height,
    required this.itemCount,
    required this.slotDistance,
    required this.centerAnchor,
    required this.itemSizeBuilder,
    required this.itemBuilder,
    this.decorativeItemBuilder,
    this.initialIndex = 0,
    this.selectedIndex,
    this.centerOffsetBuilder,
    this.onIndexChanged,
    this.onIndexSettled,
    this.onDragStarted,
    this.onTick,
    this.semanticLabel,
    this.maxVisibleLogicalDistance,
    this.itemScaleBuilder,
    this.prebuildWrappedNeighbour = false,
    this.clipToViewport = false,
    this.backgroundColor,
  }) : assert(itemCount > 0),
       assert(initialIndex >= 0 && initialIndex < itemCount),
       assert(
         selectedIndex == null ||
             (selectedIndex >= 0 && selectedIndex < itemCount),
       );

  final double width;
  final double height;
  final int itemCount;
  final double slotDistance;
  final double centerAnchor;
  final SpendeeBalanceTickingItemSizeBuilder itemSizeBuilder;
  final SpendeeBalanceTickingItemBuilder itemBuilder;
  final SpendeeBalanceTickingItemBuilder? decorativeItemBuilder;
  final int initialIndex;
  final int? selectedIndex;
  final SpendeeBalanceTickingCenterOffsetBuilder? centerOffsetBuilder;
  final ValueChanged<int>? onIndexChanged;
  final ValueChanged<int>? onIndexSettled;
  final VoidCallback? onDragStarted;
  final VoidCallback? onTick;
  final String? semanticLabel;
  final int? maxVisibleLogicalDistance;
  final SpendeeBalanceTickingItemScaleBuilder? itemScaleBuilder;

  /// Keeps a wrapped copy just beyond the entering edge while a finite belt
  /// moves. The copy is decorative, so it cannot duplicate interaction,
  /// focus or semantics before its real slot becomes active.
  final bool prebuildWrappedNeighbour;

  /// B3M-A3 FastInfo/detail surfaces must not paint a virtual neighbour into
  /// the page gutter. Generic callers retain the old shadow-friendly policy.
  final bool clipToViewport;

  /// Optional explicit viewport material. The Balance belts use the exact
  /// page colour so a moving card can never reveal an inherited scroll host.
  final Color? backgroundColor;

  @override
  State<SpendeeBalanceTickingViewport> createState() =>
      _SpendeeBalanceTickingViewportState();
}

class _SpendeeBalanceTickingViewportState
    extends State<SpendeeBalanceTickingViewport>
    with SingleTickerProviderStateMixin {
  late SpendeeCenterCarouselController _controller;
  late final AnimationController _motionController;
  var _motionSerial = 0;
  var _liveTicked = false;

  /// Direction of the in-flight visual travel. The active belt owns five
  /// stable slots; this lets it prepare exactly one entering neighbour before
  /// an existing slot leaves the viewport.
  var _motionDirection = 0;

  int get _requestedIndex => widget.selectedIndex ?? widget.initialIndex;
  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _controller = _newController(_requestedIndex);
    _motionController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant SpendeeBalanceTickingViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.slotDistance != widget.slotDistance) {
      _stopMotion();
      _controller = _newController(
        _requestedIndex.clamp(0, widget.itemCount - 1),
      );
      _motionDirection = 0;
      return;
    }
    final selectedIndex = widget.selectedIndex;
    if (selectedIndex != null && selectedIndex != _controller.index) {
      _stopMotion();
      _controller.reset(index: selectedIndex);
      _motionDirection = 0;
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  SpendeeCenterCarouselController _newController(int index) {
    return SpendeeCenterCarouselController(
      itemCount: widget.itemCount,
      initialIndex: index,
      slotDistance: widget.slotDistance,
      switchThreshold: widget.slotDistance * .6875,
    );
  }

  void _stopMotion() {
    _motionSerial += 1;
    _motionController.stop();
  }

  void _beginDrag(DragStartDetails details) {
    _stopMotion();
    _controller.beginDragFromCurrentMotion();
    _liveTicked = false;
    if (_motionDirection != 0) {
      setState(() => _motionDirection = 0);
    }
    widget.onDragStarted?.call();
  }

  void _updateDrag(DragUpdateDetails details) {
    _applyMotionDelta(details.delta.dx);
  }

  void _endDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    unawaited(_release(velocity));
  }

  void _cancelDrag() {
    final serial = ++_motionSerial;
    unawaited(_cancelDragAndReset(serial));
  }

  Future<void> _cancelDragAndReset(int serial) async {
    await _animateTravel(
      _controller.cancelTravel(),
      const Duration(milliseconds: 120),
      Curves.easeOutCubic,
      serial,
    );
    if (mounted && serial == _motionSerial && _motionDirection != 0) {
      setState(() => _motionDirection = 0);
    }
  }

  Future<void> _release(double velocityDx) async {
    final serial = ++_motionSerial;
    final motion = _controller.releaseMotion(
      velocityDx: velocityDx,
      liveTicked: _liveTicked,
    );
    await _animateTravel(
      motion.initialTravel,
      motion.initialDuration,
      motion.inertial ? Curves.easeOutCubic : Curves.easeOut,
      serial,
    );
    if (!mounted || serial != _motionSerial) return;
    final settle = _controller.settleTravel(
      preferredDxDirection: motion.preferredDxDirection,
      allowDirectionalSnap: motion.directionalSnapAllowed,
    );
    await _animateTravel(
      settle,
      const Duration(milliseconds: 120),
      Curves.easeOutCubic,
      serial,
    );
    if (mounted && serial == _motionSerial) {
      if (_motionDirection != 0) {
        setState(() => _motionDirection = 0);
      }
      widget.onIndexSettled?.call(_controller.index);
    }
  }

  void _select(int targetIndex) {
    if (targetIndex == _controller.index &&
        _controller.residualDx.abs() < .01) {
      return;
    }
    _stopMotion();
    _controller.beginDragFromCurrentMotion();
    _liveTicked = false;
    _motionDirection = 0;
    final serial = ++_motionSerial;
    final travel = _controller.travelToIndex(targetIndex);
    unawaited(
      _animateTravel(
        travel,
        const Duration(milliseconds: 220),
        Curves.easeOutCubic,
        serial,
      ).then((_) {
        if (mounted && serial == _motionSerial) {
          if (_motionDirection != 0) {
            setState(() => _motionDirection = 0);
          }
          widget.onIndexSettled?.call(_controller.index);
        }
      }),
    );
  }

  void _selectPrevious() {
    _select((_controller.index - 1) % widget.itemCount);
  }

  void _selectNext() {
    _select((_controller.index + 1) % widget.itemCount);
  }

  Future<void> _animateTravel(
    double travel,
    Duration duration,
    Curve curve,
    int serial,
  ) async {
    if (travel.abs() < .001 || !mounted || serial != _motionSerial) return;
    if (_reducedMotion) {
      _motionController.stop();
      _applyMotionDelta(travel);
      return;
    }
    _motionController.duration = duration;
    var lastValue = 0.0;
    final animation = Tween<double>(
      begin: 0,
      end: travel,
    ).animate(CurvedAnimation(parent: _motionController, curve: curve));
    void applyFrame() {
      if (!mounted || serial != _motionSerial) return;
      final delta = animation.value - lastValue;
      lastValue = animation.value;
      if (delta != 0) _applyMotionDelta(delta);
    }

    animation.addListener(applyFrame);
    var completed = false;
    try {
      await _motionController.forward(from: 0).orCancel;
      completed = true;
    } on TickerCanceled {
      // A new drag/tap owns the current residual from this point.
    } finally {
      animation.removeListener(applyFrame);
    }
    if (!completed || !mounted || serial != _motionSerial) return;
    final remainder = travel - lastValue;
    if (remainder.abs() >= .001) _applyMotionDelta(remainder);
  }

  void _applyMotionDelta(double deltaDx) {
    if (!mounted || deltaDx == 0) return;
    _motionDirection = deltaDx.isNegative ? -1 : 1;
    final update = _controller.applyDragDelta(deltaDx);
    if (update.tickedIndexes.isNotEmpty) {
      _liveTicked = true;
      for (final index in update.tickedIndexes) {
        (widget.onTick ?? HapticFeedback.selectionClick).call();
        widget.onIndexChanged?.call(index);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _controller.index;
    final slots = _renderSlots(activeIndex);
    final centerSlot = _centerSlot(slots);
    final stack = Stack(
      key: const ValueKey('spendee-balance-ticking-stack'),
      clipBehavior: widget.clipToViewport ? Clip.hardEdge : Clip.none,
      children: [
        for (final slot in slots)
          _positionedItem(
            context,
            index: slot.index,
            activeIndex: activeIndex,
            logicalOffset: slot.logicalOffset,
            decorativeClone: slot.decorativeClone,
            visuallySelected:
                slot.index == centerSlot.index &&
                slot.logicalOffset == centerSlot.logicalOffset &&
                slot.decorativeClone == centerSlot.decorativeClone,
          ),
      ],
    );
    final viewport = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _beginDrag,
      onHorizontalDragUpdate: _updateDrag,
      onHorizontalDragEnd: _endDrag,
      onHorizontalDragCancel: _cancelDrag,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: switch (widget.backgroundColor) {
          final color? => ColoredBox(color: color, child: stack),
          null => stack,
        },
      ),
    );
    final label = widget.semanticLabel;
    return label == null
        ? viewport
        : CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.arrowLeft):
                  _selectPrevious,
              const SingleActivator(LogicalKeyboardKey.arrowRight): _selectNext,
            },
            child: Focus(
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: label,
                onDecrease: _selectPrevious,
                onIncrease: _selectNext,
                child: viewport,
              ),
            ),
          );
  }

  List<({int index, int logicalOffset, bool decorativeClone})> _renderSlots(
    int activeIndex,
  ) {
    if (widget.itemCount == 2) {
      final otherIndex = (activeIndex + 1) % 2;
      return [
        (index: otherIndex, logicalOffset: -1, decorativeClone: true),
        (index: otherIndex, logicalOffset: 1, decorativeClone: false),
        (index: activeIndex, logicalOffset: 0, decorativeClone: false),
      ];
    }
    final maxDistance = widget.maxVisibleLogicalDistance;
    if (maxDistance != null && widget.itemCount > maxDistance * 2 + 1) {
      final logicalOffsets = <int>[
        for (
          var logicalOffset = -maxDistance;
          logicalOffset <= maxDistance;
          logicalOffset += 1
        )
          logicalOffset,
        if (_motionDirection < 0) maxDistance + 1,
        if (_motionDirection > 0) -maxDistance - 1,
      ];
      return [
        for (final logicalOffset in logicalOffsets)
          (
            index:
                (activeIndex + logicalOffset + widget.itemCount) %
                widget.itemCount,
            logicalOffset: logicalOffset,
            decorativeClone: false,
          ),
      ]..sort((left, right) {
        final leftDistance = left.logicalOffset.abs();
        final rightDistance = right.logicalOffset.abs();
        return rightDistance.compareTo(leftDistance);
      });
    }
    final indexes = List<int>.generate(widget.itemCount, (index) => index)
      ..sort((left, right) {
        final leftDistance = _logicalOffset(left, activeIndex).abs();
        final rightDistance = _logicalOffset(right, activeIndex).abs();
        return rightDistance.compareTo(leftDistance);
      });
    final slots = [
      for (final index in indexes)
        (
          index: index,
          logicalOffset: _logicalOffset(index, activeIndex),
          decorativeClone: false,
        ),
    ];
    if (widget.prebuildWrappedNeighbour && _motionDirection != 0) {
      final nearestOffsets = slots
          .map((slot) => slot.logicalOffset)
          .toList(growable: false);
      final logicalOffset = _motionDirection < 0
          ? nearestOffsets.reduce(
                  (left, right) => left > right ? left : right,
                ) +
                1
          : nearestOffsets.reduce(
                  (left, right) => left < right ? left : right,
                ) -
                1;
      slots.add((
        index:
            (activeIndex + logicalOffset + widget.itemCount) % widget.itemCount,
        logicalOffset: logicalOffset,
        decorativeClone: true,
      ));
    }
    return slots..sort((left, right) {
      final leftDistance = left.logicalOffset.abs();
      final rightDistance = right.logicalOffset.abs();
      return rightDistance.compareTo(leftDistance);
    });
  }

  Widget _positionedItem(
    BuildContext context, {
    required int index,
    required int activeIndex,
    required int logicalOffset,
    required bool decorativeClone,
    required bool visuallySelected,
  }) {
    final layoutSelected = index == activeIndex && logicalOffset == 0;
    final size = widget.itemSizeBuilder(index, layoutSelected);
    final authoredOffset =
        widget.centerOffsetBuilder?.call(logicalOffset) ??
        logicalOffset * widget.slotDistance;
    final center =
        widget.centerAnchor + authoredOffset + _controller.residualDx;
    final centeredness =
        (1 -
                (authoredOffset + _controller.residualDx).abs() /
                    widget.slotDistance)
            .clamp(0.0, 1.0)
            .toDouble();
    final scale =
        widget.itemScaleBuilder?.call(index, visuallySelected, centeredness) ??
        1.0;
    final itemRect = Rect.fromLTWH(
      center - size.width / 2,
      (widget.height - size.height) / 2,
      size.width,
      size.height,
    );
    final visible = itemRect.overlaps(
      Rect.fromLTWH(0, 0, widget.width, widget.height),
    );
    return Positioned(
      key: ValueKey('spendee-balance-ticking-slot-$index-$logicalOffset'),
      left: itemRect.left,
      top: itemRect.top,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        ignoring: decorativeClone || !visible,
        child: ExcludeFocus(
          excluding: decorativeClone || !visible,
          child: ExcludeSemantics(
            excluding: decorativeClone || !visible,
            child: Transform.scale(
              key: decorativeClone
                  ? null
                  : ValueKey(
                      'spendee-balance-ticking-scale-$index-$logicalOffset',
                    ),
              alignment: Alignment.center,
              scale: scale,
              child:
                  (decorativeClone
                  ? widget.decorativeItemBuilder ?? widget.itemBuilder
                  : widget.itemBuilder)(
                    context,
                    index,
                    visuallySelected,
                    () => _select(index),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  ({int index, int logicalOffset, bool decorativeClone}) _centerSlot(
    List<({int index, int logicalOffset, bool decorativeClone})> slots,
  ) {
    return slots.reduce((nearest, candidate) {
      final nearestDistance = _distanceFromCenter(nearest.logicalOffset);
      final candidateDistance = _distanceFromCenter(candidate.logicalOffset);
      if (candidateDistance < nearestDistance) return candidate;
      if (candidateDistance > nearestDistance) return nearest;
      if (nearest.decorativeClone && !candidate.decorativeClone) {
        return candidate;
      }
      return nearest;
    });
  }

  double _distanceFromCenter(int logicalOffset) {
    final authoredOffset =
        widget.centerOffsetBuilder?.call(logicalOffset) ??
        logicalOffset * widget.slotDistance;
    return (authoredOffset + _controller.residualDx).abs();
  }

  int _logicalOffset(int index, int activeIndex) {
    var forward = (index - activeIndex) % widget.itemCount;
    if (forward < 0) forward += widget.itemCount;
    final backward = forward - widget.itemCount;
    return forward.abs() <= backward.abs() ? forward : backward;
  }
}
