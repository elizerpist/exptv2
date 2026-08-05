import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../application/dashboard_performance_counters.dart';

/// Fixed-cost render-phase counters used by the reproducible profile harness.
final class DashboardRenderPhaseProbe extends SingleChildRenderObjectWidget {
  const DashboardRenderPhaseProbe({
    super.key,
    required this.counters,
    required super.child,
  });

  final DashboardPerformanceCounters counters;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      DashboardRenderPhaseProbeRenderObject(counters);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant DashboardRenderPhaseProbeRenderObject renderObject,
  ) {
    renderObject.counters = counters;
  }
}

final class DashboardRenderPhaseProbeRenderObject extends RenderProxyBox {
  DashboardRenderPhaseProbeRenderObject(this.counters);

  DashboardPerformanceCounters counters;

  @override
  void performLayout() {
    counters.increment(DashboardPerformanceMetric.dashboardLayout);
    super.performLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    counters.increment(DashboardPerformanceMetric.dashboardPaint);
    super.paint(context, offset);
  }
}
