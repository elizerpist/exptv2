import 'dart:math' as math;

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
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.setOnSelectedChanged(null);
      oldWidget.controller.setCallbacks();
    }
    _pendingCenterLogicalIndex = widget.controller.selectedIndex;
    _syncController();
    _scheduleRecenter();
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
                        final item = _source.itemAtLogicalIndex(logicalIndex);
                        final metrics = CenteredCarouselMath.metricsFor(
                          index: physicalIndex,
                          rawCenteredIndex: widget.controller.rawCenteredIndex,
                          selectedIndex:
                              widget.controller.selectedPhysicalIndex,
                          logicalIndex: logicalIndex,
                          selectedLogicalIndex: widget.controller.selectedIndex,
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
                                ? () => widget.controller.animateToIndex(
                                    widget.controller.logicalIndexForPhysical(
                                      physicalIndex,
                                    ),
                                    duration:
                                        widget.spec.programmaticScrollDuration,
                                    curve: widget.spec.programmaticScrollCurve,
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
