import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'centered_carousel_controller.dart';
import 'centered_carousel_data_source.dart';
import 'centered_carousel_math.dart';
import 'centered_carousel_metrics.dart';
import 'centered_carousel_physics.dart';
import 'centered_carousel_spec.dart';

export 'centered_carousel_controller.dart';
export 'centered_carousel_data_source.dart';
export 'centered_carousel_math.dart';
export 'centered_carousel_metrics.dart';
export 'centered_carousel_physics.dart';
export 'centered_carousel_spec.dart';

class CenteredCarousel<T> extends StatefulWidget {
  const CenteredCarousel({
    super.key,
    this.items,
    this.dataSource,
    required this.controller,
    required this.spec,
    required this.itemBuilder,
    this.onSelectedChanged,
    this.onPreviewChanged,
    this.onSelectionSettled,
    this.height,
    this.semanticsLabelBuilder,
  }) : assert(
         (items == null) != (dataSource == null),
         'Provide exactly one of items or dataSource.',
       );

  final List<T>? items;
  final CenteredCarouselDataSource<T>? dataSource;
  final CenteredCarouselController controller;
  final CenteredCarouselSpec spec;
  final Widget Function(
    BuildContext context,
    T item,
    CenteredCarouselItemMetrics metrics,
  )
  itemBuilder;
  final ValueChanged<int>? onSelectedChanged;
  final ValueChanged<int>? onPreviewChanged;
  final ValueChanged<int>? onSelectionSettled;
  final double? height;
  final String Function(T item)? semanticsLabelBuilder;

  @override
  State<CenteredCarousel<T>> createState() => _CenteredCarouselState<T>();
}

class _CenteredCarouselState<T> extends State<CenteredCarousel<T>> {
  double? _lastViewportWidth;
  int? _pendingCenterLogicalIndex;
  int? _trackedPointer;
  Offset? _pointerDownPosition;
  double? _pointerDownScrollPixels;
  bool _pointerMoved = false;
  bool _pointerWasScrolling = false;

  CenteredCarouselDataSource<T> get _source =>
      widget.dataSource ?? BoundedCarouselDataSource<T>(widget.items!);

  @override
  void initState() {
    super.initState();
    _pendingCenterLogicalIndex = widget.controller.selectedIndex;
    _syncController();
  }

  @override
  void didUpdateWidget(covariant CenteredCarousel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = oldWidget.controller != widget.controller;
    if (controllerChanged) {
      oldWidget.controller.setOnSelectedChanged(null);
      oldWidget.controller.setCallbacks();
      _pendingCenterLogicalIndex = widget.controller.selectedIndex;
    }
    _syncController();
    // A preview callback can rebuild the parent on every nearest-index
    // change. Re-centering after every ordinary widget update would cancel
    // the active ballistic simulation and reduce a multi-item fling to the
    // first index crossed. Configuration changes recenter inside
    // updateConfiguration; a replacement controller still needs the
    // post-frame initial center.
    if (controllerChanged) _scheduleRecenter();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0.0;
        final maximumVisibleSlots = math.max(
          1,
          ((viewportWidth + widget.spec.viewportTrailingGap) /
                  widget.spec.itemExtent)
              .floor(),
        );
        final visibleSlots = math.max(
          1,
          math.min(
            widget.spec.visibleItemCount,
            maximumVisibleSlots.isOdd
                ? maximumVisibleSlots
                : maximumVisibleSlots - 1,
          ),
        );
        final railWidth = math.min(
          viewportWidth,
          math.max(
            0.0,
            widget.spec.itemExtent * visibleSlots -
                widget.spec.viewportTrailingGap,
          ),
        );
        final sidePadding = math.max(
          0.0,
          (railWidth - widget.spec.itemExtent) / 2,
        );

        if (_lastViewportWidth != viewportWidth) {
          _lastViewportWidth = viewportWidth;
          _pendingCenterLogicalIndex ??= widget.controller.selectedIndex;
          _scheduleRecenter();
        }

        return Center(
          child: SizedBox(
            width: railWidth,
            height: widget.height,
            child: ClipRect(
              clipBehavior: Clip.hardEdge,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false, scrollbars: false),
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerUp: (event) =>
                      _handlePointerUp(event, sidePadding: sidePadding),
                  onPointerCancel: _handlePointerCancel,
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: (notification) {
                      if (notification.dragDetails != null) {
                        widget.controller.beginUserMotionCommand();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      key: const ValueKey('centered-carousel-viewport'),
                      controller: widget.controller.scrollController,
                      scrollDirection: Axis.horizontal,
                      itemExtent: widget.spec.itemExtent,
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      clipBehavior: Clip.hardEdge,
                      physics: CenterSnapScrollPhysics(
                        itemExtent: widget.spec.itemExtent,
                        itemCount: widget.controller.physicalItemCount,
                        frictionDrag: widget.spec.frictionDrag,
                        velocityMultiplier: widget.spec.velocityMultiplier,
                        minimumFlingVelocity: widget.spec.minimumFlingVelocity,
                        maximumFlingVelocity: widget.spec.maximumFlingVelocity,
                        maxItemsPerFling: widget.spec.maxItemsPerFling,
                        forceOneItemOnFling: widget.spec.forceOneItemOnFling,
                        snapSpring: widget.spec.snapSpring,
                        snapTolerance: widget.spec.snapTolerance,
                        parent: const ClampingScrollPhysics(),
                      ),
                      itemCount: widget.controller.physicalItemCount,
                      itemBuilder: (context, physicalIndex) {
                        return ListenableBuilder(
                          listenable: widget.controller,
                          builder: (context, child) {
                            final logicalIndex = widget.controller
                                .logicalIndexForPhysical(physicalIndex);
                            final item = _source.itemAtLogicalIndex(
                              logicalIndex,
                            );
                            final metrics = CenteredCarouselMath.metricsFor(
                              index: physicalIndex,
                              rawCenteredIndex:
                                  widget.controller.rawCenteredIndex,
                              selectedIndex:
                                  widget.controller.selectedPhysicalIndex,
                              logicalIndex: logicalIndex,
                              selectedLogicalIndex:
                                  widget.controller.selectedIndex,
                              spec: widget.spec,
                            );
                            final semanticLabel = widget.semanticsLabelBuilder
                                ?.call(item);

                            return Semantics(
                              label: semanticLabel,
                              selected: metrics.isSelected,
                              button: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: widget.spec.enableTapToCenter
                                    ? () =>
                                          widget.controller.tapToPhysicalIndex(
                                            physicalIndex,
                                            duration: widget
                                                .spec
                                                .programmaticScrollDuration,
                                            curve: widget
                                                .spec
                                                .programmaticScrollCurve,
                                          )
                                    : null,
                                child: RepaintBoundary(
                                  child: Opacity(
                                    opacity: metrics.opacity,
                                    child: Transform.scale(
                                      scale: metrics.scale,
                                      alignment: Alignment.center,
                                      child: Center(
                                        child: widget.itemBuilder(
                                          context,
                                          item,
                                          metrics,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _syncController() {
    widget.controller.setOnSelectedChanged(widget.onSelectedChanged);
    widget.controller.setCallbacks(
      onPreviewChanged: widget.onPreviewChanged,
      onSelectionSettled: widget.onSelectionSettled,
    );
    widget.controller.updateConfiguration(
      itemCount: _source.finiteLength ?? 0,
      itemExtent: widget.spec.itemExtent,
      dataMode: _source.mode,
      finiteLength: _source.finiteLength,
      enableHaptics: widget.spec.enableHaptics,
      hapticThrottle: widget.spec.hapticThrottle,
      programmaticScrollDuration: widget.spec.programmaticScrollDuration,
      programmaticScrollCurve: widget.spec.programmaticScrollCurve,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_trackedPointer != null) return;
    _trackedPointer = event.pointer;
    _pointerDownPosition = event.localPosition;
    _pointerDownScrollPixels = widget.controller.scrollController.hasClients
        ? widget.controller.scrollController.position.pixels
        : null;
    _pointerMoved = false;
    _pointerWasScrolling = widget.controller.hasActiveScrollActivity;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _trackedPointer || _pointerDownPosition == null) {
      return;
    }
    if ((event.localPosition - _pointerDownPosition!).distance > kTouchSlop) {
      _pointerMoved = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event, {required double sidePadding}) {
    if (event.pointer != _trackedPointer) return;

    final shouldRetarget =
        _pointerWasScrolling &&
        !_pointerMoved &&
        widget.spec.enableTapToCenter &&
        widget.controller.physicalItemCount > 0;
    if (shouldRetarget) {
      final position = widget.controller.scrollController.hasClients
          ? widget.controller.scrollController.position
          : null;
      if (position != null &&
          _pointerDownPosition != null &&
          _pointerDownScrollPixels != null) {
        final physicalIndex =
            ((_pointerDownScrollPixels! -
                        position.minScrollExtent +
                        _pointerDownPosition!.dx -
                        sidePadding) /
                    widget.spec.itemExtent)
                .floor();
        if (physicalIndex >= 0 &&
            physicalIndex < widget.controller.physicalItemCount) {
          widget.controller.tapToPhysicalIndex(
            physicalIndex,
            duration: widget.spec.programmaticScrollDuration,
            curve: widget.spec.programmaticScrollCurve,
          );
        }
      }
    }
    _resetPointerTracking();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _trackedPointer) {
      _resetPointerTracking();
    }
  }

  void _resetPointerTracking() {
    _trackedPointer = null;
    _pointerDownPosition = null;
    _pointerDownScrollPixels = null;
    _pointerMoved = false;
    _pointerWasScrolling = false;
  }

  void _scheduleRecenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index =
          _pendingCenterLogicalIndex ?? widget.controller.selectedIndex;
      _pendingCenterLogicalIndex = null;
      widget.controller.jumpToIndex(index);
    });
  }
}
