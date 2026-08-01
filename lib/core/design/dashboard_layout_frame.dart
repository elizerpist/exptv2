import 'package:flutter/foundation.dart';

import '../../features/dashboard/application/dashboard_mode_spec.dart';

@immutable
class DashboardBounds {
  const DashboardBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  @override
  bool operator ==(Object other) {
    return other is DashboardBounds &&
        other.left == left &&
        other.top == top &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

/// The complete, immutable layout result consumed by dashboard presentation.
@immutable
class DashboardLayoutFrame {
  const DashboardLayoutFrame({
    required this.mode,
    required this.collapseProgress,
    required this.viewportVerticalDragToControllerScale,
    required this.brandLockupBounds,
    required this.headerBounds,
    required this.headerGestureBounds,
    required this.subheaderOneBounds,
    required this.zone2Bounds,
    required this.zone2IndicatorBounds,
    required this.subheaderEnvelopeBounds,
    required this.unifiedSubheaderBounds,
    required this.actionBounds,
    required this.summaryBounds,
    required this.searchBounds,
    required this.railBounds,
    required this.collapseHandleBounds,
    required this.subheaderOneOpacity,
    required this.subheaderOneShift,
    required this.subheaderOneScale,
    required this.zone2Opacity,
    required this.zone2Shift,
    required this.zone2Scale,
    required this.isRailExpanded,
  });

  final DashboardModeSpec mode;
  final double collapseProgress;

  /// Translates physical vertical input into the headless controller's metric
  /// coordinate system. Presentation leaves only apply this mapping.
  final double viewportVerticalDragToControllerScale;

  double mapViewportVerticalDragToController(double viewportDelta) {
    return viewportDelta * viewportVerticalDragToControllerScale;
  }

  final DashboardBounds brandLockupBounds;
  final DashboardBounds headerBounds;
  final DashboardBounds headerGestureBounds;
  final DashboardBounds subheaderOneBounds;
  final DashboardBounds zone2Bounds;
  final DashboardBounds zone2IndicatorBounds;
  final DashboardBounds subheaderEnvelopeBounds;
  final DashboardBounds? unifiedSubheaderBounds;
  final DashboardBounds actionBounds;
  final DashboardBounds summaryBounds;
  final DashboardBounds searchBounds;
  final DashboardBounds railBounds;
  final DashboardBounds collapseHandleBounds;
  final double subheaderOneOpacity;
  final double subheaderOneShift;
  final double subheaderOneScale;
  final double zone2Opacity;
  final double zone2Shift;
  final double zone2Scale;
  final bool isRailExpanded;
}
