import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'centered_carousel_controller.dart';
import 'centered_carousel_math.dart';
import 'centered_carousel_metrics.dart';
import 'centered_carousel_physics.dart';
import 'centered_carousel_spec.dart';

export 'centered_carousel_controller.dart';
export 'centered_carousel_math.dart';
export 'centered_carousel_metrics.dart';
export 'centered_carousel_physics.dart';
export 'centered_carousel_spec.dart';

class CenteredCarousel<T> extends StatefulWidget {
  const CenteredCarousel({
    super.key,
    required this.items,
    required this.controller,
    required this.spec,
    required this.itemBuilder,
    this.onSelectedChanged,
    this.height,
    this.semanticsLabelBuilder,
  });

  final List<T> items;
  final CenteredCarouselController controller;
  final CenteredCarouselSpec spec;
  final Widget Function(
    BuildContext context,
    T item,
    CenteredCarouselItemMetrics metrics,
  )
  itemBuilder;
  final ValueChanged<int>? onSelectedChanged;
  final double? height;
  final String Function(T item)? semanticsLabelBuilder;

  @override
  State<CenteredCarousel<T>> createState() => _CenteredCarouselState<T>();
}

class _CenteredCarouselState<T> extends State<CenteredCarousel<T>> {
  double? _lastViewportWidth;
  int? _pendingCenterIndex;

  @override
  void initState() {
    super.initState();
    _pendingCenterIndex = widget.controller.selectedIndex;
    _syncController();
  }

  @override
  void didUpdateWidget(covariant CenteredCarousel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.setOnSelectedChanged(null);
    }
    _pendingCenterIndex = widget.controller.selectedIndex;
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
        final sidePadding = math.max(
          0.0,
          (viewportWidth - widget.spec.itemExtent) / 2,
        );

        if (_lastViewportWidth != viewportWidth) {
          _lastViewportWidth = viewportWidth;
          _pendingCenterIndex ??= widget.controller.selectedIndex;
          _scheduleRecenter();
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: ListView.builder(
            key: const ValueKey('centered-carousel-viewport'),
            controller: widget.controller.scrollController,
            scrollDirection: Axis.horizontal,
            itemExtent: widget.spec.itemExtent,
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            clipBehavior: Clip.none,
            physics: CenterSnapScrollPhysics(
              itemExtent: widget.spec.itemExtent,
              itemCount: widget.items.length,
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
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return ListenableBuilder(
                listenable: widget.controller,
                builder: (context, child) {
                  final metrics = CenteredCarouselMath.metricsFor(
                    index: index,
                    rawCenteredIndex: widget.controller.rawCenteredIndex,
                    selectedIndex: widget.controller.selectedIndex,
                    spec: widget.spec,
                  );
                  final semanticLabel = widget.semanticsLabelBuilder?.call(
                    item,
                  );

                  return Semantics(
                    label: semanticLabel,
                    selected: metrics.isSelected,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.spec.enableTapToCenter
                          ? () => widget.controller.animateToIndex(
                              index,
                              duration: widget.spec.programmaticScrollDuration,
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
                              child: widget.itemBuilder(context, item, metrics),
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
        );
      },
    );
  }

  void _syncController() {
    widget.controller.setOnSelectedChanged(widget.onSelectedChanged);
    widget.controller.updateConfiguration(
      itemCount: widget.items.length,
      itemExtent: widget.spec.itemExtent,
      enableHaptics: widget.spec.enableHaptics,
      programmaticScrollDuration: widget.spec.programmaticScrollDuration,
      programmaticScrollCurve: widget.spec.programmaticScrollCurve,
    );
  }

  void _scheduleRecenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = _pendingCenterIndex ?? widget.controller.selectedIndex;
      _pendingCenterIndex = null;
      widget.controller.jumpToIndex(index);
    });
  }
}
