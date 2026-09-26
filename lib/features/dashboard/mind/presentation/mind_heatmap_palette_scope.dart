import 'package:flutter/material.dart';

import '../../presentation/core_modes/dashboard_header_perceptual_color.dart';
import 'mind_year_heatmap_palette_resolver.dart';

/// Animated, paint-only publication of the one resolved Mind scale. Cells,
/// legend and compact range styling read the same transient stops, while
/// score/data ownership remains outside this widget.
final class MindHeatmapPaletteTransition extends StatefulWidget {
  const MindHeatmapPaletteTransition({
    super.key,
    required this.target,
    required this.animates,
    required this.child,
  });

  final MindHeatmapResolvedScale target;
  final bool animates;
  final Widget child;

  @override
  State<MindHeatmapPaletteTransition> createState() =>
      _MindHeatmapPaletteTransitionState();
}

final class _MindHeatmapPaletteTransitionState
    extends State<MindHeatmapPaletteTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late MindHeatmapResolvedScale _from;
  late MindHeatmapResolvedScale _to;

  @override
  void initState() {
    super.initState();
    _from = widget.target;
    _to = widget.target;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..value = 1;
  }

  @override
  void didUpdateWidget(covariant MindHeatmapPaletteTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameStops(widget.target, _to)) return;
    _from = _resolved;
    _to = widget.target;
    if (widget.animates) {
      _controller.forward(from: 0);
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  MindHeatmapResolvedScale get _resolved {
    final t = Curves.easeInOutCubic.transform(_controller.value);
    if (t == 1) return _to;
    return MindHeatmapResolvedScale(
      List<Color>.unmodifiable(
        List<Color>.generate(_to.stops.length, (index) {
          final fraction = _to.stops.length == 1
              ? 0.0
              : index / (_to.stops.length - 1);
          return DashboardHeaderPerceptualColorMath.mix(
            _from.colorAt(fraction),
            _to.stops[index],
            t,
          );
        }, growable: false),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) =>
        MindHeatmapPaletteScope(scale: _resolved, child: child!),
  );

  static bool _sameStops(
    MindHeatmapResolvedScale left,
    MindHeatmapResolvedScale right,
  ) {
    if (left.stops.length != right.stops.length) return false;
    for (var index = 0; index < left.stops.length; index += 1) {
      if (left.stops[index] != right.stops[index]) return false;
    }
    return true;
  }
}

@immutable
final class MindHeatmapPaletteScope extends InheritedWidget {
  const MindHeatmapPaletteScope({
    super.key,
    required this.scale,
    required super.child,
  });

  final MindHeatmapResolvedScale scale;

  static MindHeatmapResolvedScale? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MindHeatmapPaletteScope>()
      ?.scale;

  @override
  bool updateShouldNotify(MindHeatmapPaletteScope oldWidget) {
    if (scale.stops.length != oldWidget.scale.stops.length) return true;
    for (var index = 0; index < scale.stops.length; index += 1) {
      if (scale.stops[index] != oldWidget.scale.stops[index]) return true;
    }
    return false;
  }
}
