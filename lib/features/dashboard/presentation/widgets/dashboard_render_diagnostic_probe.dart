import 'package:flutter/widgets.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../core/diagnostics/fluvi_onscreen_diagnostics.dart';

/// Bounded collapse identity shared by Dashboard render-owner probes.
///
/// The scope deliberately changes only at the caller's semantic progress
/// bucket. It is diagnostic metadata, never a paint, compositing, clipping,
/// hit-test, or state owner.
final class DashboardCollapseDiagnosticScope extends InheritedWidget {
  const DashboardCollapseDiagnosticScope({
    super.key,
    required this.normalizedProgress,
    required this.progressBucket,
    required super.child,
  });

  final double normalizedProgress;
  final int progressBucket;

  static DashboardCollapseDiagnosticScope? maybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<DashboardCollapseDiagnosticScope>();

  /// Keeps diagnostic-only scope elements out of normal production builds.
  static Widget wrap({
    required double normalizedProgress,
    required int progressBucket,
    required Widget child,
  }) => kFluviOnscreenDiagnosticsEnabled
      ? DashboardCollapseDiagnosticScope(
          normalizedProgress: normalizedProgress,
          progressBucket: progressBucket,
          child: child,
        )
      : child;

  @override
  bool updateShouldNotify(DashboardCollapseDiagnosticScope oldWidget) =>
      progressBucket != oldWidget.progressBucket;
}

/// Debug-only, post-frame geometry recorder for one existing render owner.
///
/// In diagnostic-disabled builds this returns [child] directly, adding no
/// render object. In an enabled build it only reads the existing RenderBox
/// after layout at bounded collapse buckets; it never paints a tint, clip, or
/// cover and therefore cannot conceal the pixel owner under investigation.
final class DashboardRenderDiagnosticProbe extends StatefulWidget {
  const DashboardRenderDiagnosticProbe({
    super.key,
    required this.candidate,
    required this.material,
    required this.clip,
    required this.zOrder,
    required this.child,
  });

  final String candidate;
  final String material;
  final String clip;
  final String zOrder;
  final Widget child;

  @override
  State<DashboardRenderDiagnosticProbe> createState() =>
      _DashboardRenderDiagnosticProbeState();
}

final class _DashboardRenderDiagnosticProbeState
    extends State<DashboardRenderDiagnosticProbe> {
  Object? _lastSignature;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleRecord();
  }

  @override
  void didUpdateWidget(covariant DashboardRenderDiagnosticProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleRecord();
  }

  void _scheduleRecord() {
    if (!kFluviOnscreenDiagnosticsEnabled) return;
    final collapse = DashboardCollapseDiagnosticScope.maybeOf(context);
    if (collapse == null) return;
    final signature = Object.hash(
      collapse.progressBucket,
      widget.candidate,
      widget.material,
      widget.clip,
      widget.zOrder,
    );
    if (_lastSignature == signature) return;
    _lastSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final scope = DashboardCollapseDiagnosticScope.maybeOf(context);
      if (scope == null) return;
      final origin = renderObject.localToGlobal(Offset.zero);
      final globalBounds = origin & renderObject.size;
      final paintBounds = renderObject.paintBounds.shift(origin);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'COLLAPSE|LAYER',
          scope:
              'candidate=${widget.candidate} '
              'renderObject=${renderObject.runtimeType} '
              'globalBounds=${_rect(globalBounds)} '
              'paintBounds=${_rect(paintBounds)} '
              'clip=${widget.clip} '
              'material=${widget.material} '
              'zOrder=${widget.zOrder} '
              'collapseProgress=${scope.normalizedProgress.toStringAsFixed(3)} '
              'progressBucket=${scope.progressBucket} '
              'ancestors=${_ancestors(renderObject)}',
        ),
      );
    });
  }

  static String _rect(Rect value) =>
      '${value.left.toStringAsFixed(1)},${value.top.toStringAsFixed(1)} '
      '${value.width.toStringAsFixed(1)}x${value.height.toStringAsFixed(1)}';

  static String _ancestors(RenderObject renderObject) {
    final ancestors = <String>[];
    RenderObject? current = renderObject;
    while (ancestors.length < 8) {
      final parent = current?.parent;
      if (parent is! RenderObject) break;
      ancestors.add(parent.runtimeType.toString());
      current = parent;
    }
    return ancestors.join('>');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
