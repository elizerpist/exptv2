import '../../features/dashboard/application/dashboard_mode_spec.dart';
import 'dashboard_layout_frame.dart';
import 'dashboard_layout_metrics.dart';
import 'dashboard_mode_palette.dart';

/// Resolves every dashboard position from one metric source and one progress.
abstract final class DashboardGeometryResolver {
  static DashboardLayoutFrame resolve({
    required DashboardLayoutMetrics metrics,
    required DashboardModeSpec mode,
    required double collapseProgress,
    required bool isRailExpanded,
  }) {
    final progress = (collapseProgress / metrics.collapseTravel)
        .clamp(0.0, 1.0)
        .toDouble();
    final subheaderOneProgress = _stagedProgress(progress, start: .03);
    final zone2Progress = _stagedProgress(progress, start: .16);
    final headerHeight = _lerp(
      metrics.headerExpandedHeight,
      metrics.headerCollapsedHeight,
      progress,
    );
    final collapsedActionTop =
        metrics.headerTop + metrics.headerCollapsedHeight + metrics.standardGap;
    final collapsedSummaryTop =
        collapsedActionTop + metrics.actionHeight + metrics.standardGap;
    final collapsedSearchTop =
        collapsedSummaryTop + metrics.summaryHeight + metrics.standardGap;
    final collapsedRailTop =
        collapsedSearchTop + metrics.searchHeight + metrics.standardGap;

    final left = metrics.contentGutter;
    DashboardBounds bounds(double top, double height) => DashboardBounds(
      left: left,
      top: top,
      width: metrics.contentWidth,
      height: height,
    );
    final subheaderOne = bounds(
      metrics.subheaderOneTop,
      metrics.subheaderOneHeight,
    );
    final zone2 = bounds(metrics.zone2Top, metrics.zone2CardHeight);
    final zone2Indicator = bounds(metrics.zone2IndicatorTop, metrics.dotHeight);
    final envelope = bounds(
      metrics.subheaderOneTop,
      metrics.subheaderOneHeight +
          metrics.standardGap +
          metrics.zone2CardHeight,
    );

    return DashboardLayoutFrame(
      mode: mode,
      collapseProgress: collapseProgress
          .clamp(0.0, metrics.collapseTravel)
          .toDouble(),
      viewportVerticalDragToControllerScale:
          metrics.viewportVerticalDragToControllerScale,
      brandLockupBounds: DashboardBounds(
        left: metrics.brandLockupLeft,
        top: metrics.brandLockupTop,
        width: metrics.brandLockupWidth,
        height: metrics.brandLockupHeight,
      ),
      headerBounds: bounds(metrics.headerTop, headerHeight),
      headerGestureBounds: bounds(
        metrics.headerTop,
        envelope.bottom - metrics.headerTop,
      ),
      subheaderOneBounds: subheaderOne,
      zone2Bounds: zone2,
      zone2IndicatorBounds: zone2Indicator,
      subheaderEnvelopeBounds: envelope,
      unifiedSubheaderBounds:
          mode.subheaderComposition == DashboardSubheaderComposition.unified
          ? envelope
          : null,
      actionBounds: bounds(
        _lerp(metrics.actionTop, collapsedActionTop, progress),
        metrics.actionHeight,
      ),
      summaryBounds: bounds(
        _lerp(metrics.summaryTop, collapsedSummaryTop, progress),
        metrics.summaryHeight,
      ),
      searchBounds: bounds(
        _lerp(metrics.searchTop, collapsedSearchTop, progress),
        metrics.searchHeight,
      ),
      railBounds: bounds(
        _lerp(metrics.railTop, collapsedRailTop, progress),
        metrics.railHeight,
      ),
      collapseHandleBounds: bounds(
        _lerp(metrics.railTop, collapsedRailTop, progress) +
            (isRailExpanded ? metrics.railHeight + metrics.standardGap : 0),
        metrics.handleHeight,
      ),
      subheaderOneOpacity: 1 - subheaderOneProgress,
      subheaderOneShift:
          DashboardMotionTokens.subheaderOneCollapseShift *
          subheaderOneProgress,
      subheaderOneScale: _lerp(
        DashboardMotionTokens.restingScale,
        DashboardMotionTokens.subheaderOneCollapseScale,
        subheaderOneProgress,
      ),
      zone2Opacity: 1 - zone2Progress,
      zone2Shift: DashboardMotionTokens.zone2CollapseShift * zone2Progress,
      zone2Scale: _lerp(
        DashboardMotionTokens.restingScale,
        DashboardMotionTokens.zone2CollapseScale,
        zone2Progress,
      ),
      isRailExpanded: isRailExpanded,
    );
  }

  static double _lerp(double from, double to, double progress) =>
      from + (to - from) * progress;

  static double _stagedProgress(double progress, {required double start}) =>
      ((progress - start) / .62).clamp(0.0, 1.0).toDouble();
}
