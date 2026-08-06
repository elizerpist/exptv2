import 'dart:developer' as developer;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../application/dashboard_performance_counters.dart';

/// Fixed-cost render-phase counters used by the reproducible profile harness.
final class DashboardRenderPhaseProbe extends SingleChildRenderObjectWidget {
  const DashboardRenderPhaseProbe({
    super.key,
    required this.counters,
    this.layoutMetric = DashboardPerformanceMetric.dashboardLayout,
    this.paintMetric = DashboardPerformanceMetric.dashboardPaint,
    this.layoutDurationMetric,
    this.paintDurationMetric,
    required super.child,
  });

  final DashboardPerformanceCounters counters;
  final DashboardPerformanceMetric layoutMetric;
  final DashboardPerformanceMetric paintMetric;
  final DashboardPerformanceMetric? layoutDurationMetric;
  final DashboardPerformanceMetric? paintDurationMetric;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      DashboardRenderPhaseProbeRenderObject(
        counters,
        layoutMetric: layoutMetric,
        paintMetric: paintMetric,
        layoutDurationMetric: layoutDurationMetric,
        paintDurationMetric: paintDurationMetric,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant DashboardRenderPhaseProbeRenderObject renderObject,
  ) {
    renderObject
      ..counters = counters
      ..layoutMetric = layoutMetric
      ..paintMetric = paintMetric
      ..layoutDurationMetric = layoutDurationMetric
      ..paintDurationMetric = paintDurationMetric;
  }
}

final class DashboardRenderPhaseProbeRenderObject extends RenderProxyBox {
  DashboardRenderPhaseProbeRenderObject(
    this.counters, {
    required this.layoutMetric,
    required this.paintMetric,
    required this.layoutDurationMetric,
    required this.paintDurationMetric,
  });

  DashboardPerformanceCounters counters;
  DashboardPerformanceMetric layoutMetric;
  DashboardPerformanceMetric paintMetric;
  DashboardPerformanceMetric? layoutDurationMetric;
  DashboardPerformanceMetric? paintDurationMetric;

  @override
  void performLayout() {
    counters.increment(layoutMetric);
    final durationMetric = layoutDurationMetric;
    final started = counters.measuresDurations && durationMetric != null
        ? developer.Timeline.now
        : 0;
    super.performLayout();
    if (started != 0) {
      counters.increment(durationMetric!, by: developer.Timeline.now - started);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    counters.increment(paintMetric);
    final durationMetric = paintDurationMetric;
    final started = counters.measuresDurations && durationMetric != null
        ? developer.Timeline.now
        : 0;
    super.paint(context, offset);
    if (started != 0) {
      counters.increment(durationMetric!, by: developer.Timeline.now - started);
    }
  }
}
