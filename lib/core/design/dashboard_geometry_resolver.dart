import '../../features/dashboard/application/dashboard_mode_spec.dart';
import 'dashboard_body_order.dart';
import 'dashboard_layout_frame.dart';
import 'dashboard_layout_metrics.dart';
import 'dashboard_mode_palette.dart';
import 'header_cascade_motion.dart';

/// Resolves every dashboard position from one metric source and one progress.
abstract final class DashboardGeometryResolver {
  static DashboardLayoutFrame resolve({
    required DashboardLayoutMetrics metrics,
    required DashboardModeSpec mode,
    required double collapseProgress,
    required bool isRailExpanded,
    DashboardBodyOrder? bodyOrder,
    bool hasPhysicalRail = true,
  }) {
    final progress = (collapseProgress / metrics.collapseTravel)
        .clamp(0.0, 1.0)
        .toDouble();
    final subheaderOneProgress = _stagedProgress(progress, start: .03);
    final zone2Progress = _stagedProgress(progress, start: .16);
    final isSplitMode =
        mode.subheaderComposition == DashboardSubheaderComposition.split;
    final headerHeight = _lerp(
      metrics.headerExpandedHeight,
      metrics.headerCollapsedHeight,
      progress,
    );
    final collapsedActionTop =
        metrics.headerTop + metrics.headerCollapsedHeight + metrics.standardGap;
    final collapsedSummaryTop =
        collapsedActionTop + metrics.actionHeight + metrics.standardGap;
    final collapsedRailTop =
        collapsedSummaryTop + metrics.summaryHeight + metrics.standardGap;
    final order = bodyOrder ?? DashboardBodyOrder.defaultOrder();
    final reclaimedRailFootprint = hasPhysicalRail
        ? 0.0
        : metrics.railHeight + metrics.railToCollapseHandleGap;
    final modeLowerHeight = metrics.zone2CardHeight + reclaimedRailFootprint;
    // The cursor keeps the accepted Zone2 → dot → next/rail relation, while
    // the named envelope includes the complete painted dot. Those differ by
    // the existing half-padding around the indicator, not a new spacing token.
    final modeContentFlowHeight =
        metrics.subheaderOneHeight +
        metrics.standardGap +
        modeLowerHeight +
        metrics.dotGap +
        metrics.dotHeight;
    final modeContentEnvelopeHeight =
        metrics.subheaderOneHeight +
        metrics.standardGap +
        modeLowerHeight +
        metrics.zone2IndicatorVerticalPadding +
        metrics.dotHeight;
    final expandedBodies = _expandedBodyLayout(
      metrics: metrics,
      order: order,
      modeContentFlowHeight: modeContentFlowHeight,
    );
    final railTop = _lerp(expandedBodies.railTop, collapsedRailTop, progress);
    final collapseHandleTop =
        railTop +
        (hasPhysicalRail && isRailExpanded
            ? metrics.railHeight + metrics.railToCollapseHandleGap
            : 0);

    final left = metrics.contentGutter;
    DashboardBounds bounds(double top, double height) => DashboardBounds(
      left: left,
      top: top,
      width: metrics.contentWidth,
      height: height,
    );
    final subheaderOne = bounds(
      expandedBodies.modeContentTop,
      metrics.subheaderOneHeight,
    );
    final zone2 = bounds(
      subheaderOne.bottom + metrics.standardGap,
      modeLowerHeight,
    );
    final zone2Indicator = bounds(
      zone2.bottom + metrics.zone2IndicatorVerticalPadding,
      metrics.dotHeight,
    );
    final envelope = bounds(
      expandedBodies.modeContentTop,
      metrics.subheaderOneHeight + metrics.standardGap + modeLowerHeight,
    );
    final cascade = HeaderCascadeMotion.calculate(
      masterProgress: 1 - progress,
      geometry: HeaderCascadeGeometry(
        upperCollapsedTop:
            metrics.headerTop +
            metrics.headerCollapsedHeight -
            DashboardMotionTokens.upperHiddenOverlap,
        upperExpandedTop: subheaderOne.top,
        upperHeight: metrics.subheaderOneHeight,
        upperCollapsedInset:
            metrics.contentGutter + DashboardMotionTokens.upperNestedInset,
        upperExpandedInset: metrics.contentGutter,
        upperCollapsedScale: DashboardMotionTokens.subheaderOneCollapseScale,
        upperExpandedScale: DashboardMotionTokens.restingScale,
        lowerExpandedTop: zone2.top,
        lowerExpandedInset: metrics.contentGutter,
        lowerHiddenOverlap: DashboardMotionTokens.lowerHiddenOverlap,
        lowerNestedInset: DashboardMotionTokens.lowerNestedInset,
        lowerCollapsedScale: DashboardMotionTokens.zone2CollapseScale,
        lowerExpandedScale: DashboardMotionTokens.restingScale,
      ),
    );
    final upperCardMotion = isSplitMode ? cascade.upper : null;
    final lowerCardMotion = isSplitMode ? cascade.lower : null;

    return DashboardLayoutFrame(
      mode: mode,
      collapseProgress: collapseProgress
          .clamp(0.0, metrics.collapseTravel)
          .toDouble(),
      headerExpansionProgress: 1 - progress,
      viewportVerticalDragToControllerScale:
          metrics.viewportVerticalDragToControllerScale,
      brandLockupBounds: DashboardBounds(
        left: metrics.brandLockupLeft,
        top: metrics.brandLockupTop,
        width: metrics.brandLockupWidth,
        height: metrics.brandLockupHeight,
      ),
      headerBounds: bounds(metrics.headerTop, headerHeight),
      headerGestureBounds: bounds(metrics.headerTop, headerHeight),
      subheaderOneBounds: subheaderOne,
      zone2Bounds: zone2,
      zone2IndicatorBounds: zone2Indicator,
      subheaderEnvelopeBounds: envelope,
      unifiedSubheaderBounds:
          mode.subheaderComposition == DashboardSubheaderComposition.unified
          ? envelope
          : null,
      actionBounds: bounds(
        _lerp(expandedBodies.actionTop, collapsedActionTop, progress),
        metrics.actionHeight,
      ),
      summaryBounds: bounds(
        _lerp(expandedBodies.summaryTop, collapsedSummaryTop, progress),
        metrics.summaryHeight,
      ),
      railBounds: bounds(railTop, hasPhysicalRail ? metrics.railHeight : 0),
      collapseHandleBounds: bounds(collapseHandleTop, metrics.handleHeight),
      logBoxHeaderBounds: bounds(
        collapseHandleTop + metrics.handleHeight,
        metrics.logBoxHeaderHeight,
      ),
      subheaderOneOpacity: isSplitMode
          ? cascade.upper.opacity
          : 1 - subheaderOneProgress,
      subheaderOneShift: isSplitMode
          ? cascade.upper.top - subheaderOne.top
          : DashboardMotionTokens.subheaderOneCollapseShift *
                subheaderOneProgress,
      subheaderOneScale: isSplitMode
          ? cascade.upper.scale
          : _lerp(
              DashboardMotionTokens.restingScale,
              DashboardMotionTokens.subheaderOneCollapseScale,
              subheaderOneProgress,
            ),
      upperCardMotion: upperCardMotion,
      zone2Opacity: isSplitMode ? cascade.lower.opacity : 1 - zone2Progress,
      zone2Shift: isSplitMode
          ? cascade.lower.top - zone2.top
          : DashboardMotionTokens.zone2CollapseShift * zone2Progress,
      zone2Scale: isSplitMode
          ? cascade.lower.scale
          : _lerp(
              DashboardMotionTokens.restingScale,
              DashboardMotionTokens.zone2CollapseScale,
              zone2Progress,
            ),
      lowerCardMotion: lowerCardMotion,
      isRailExpanded: isRailExpanded,
      hasPhysicalRail: hasPhysicalRail,
      bodyOrder: order,
      modeContentBounds: bounds(
        expandedBodies.modeContentTop,
        modeContentEnvelopeHeight,
      ),
    );
  }

  static _ExpandedBodyLayout _expandedBodyLayout({
    required DashboardLayoutMetrics metrics,
    required DashboardBodyOrder order,
    required double modeContentFlowHeight,
  }) {
    var cursor =
        metrics.headerTop + metrics.headerExpandedHeight + metrics.standardGap;
    double? actionTop;
    double? summaryTop;
    double? modeContentTop;
    for (var index = 0; index < order.components.length; index += 1) {
      switch (order.components[index]) {
        case DashboardBodyComponent.direction:
          actionTop = cursor;
          cursor += metrics.actionHeight;
        case DashboardBodyComponent.summary:
          summaryTop = cursor;
          cursor += metrics.summaryHeight;
        case DashboardBodyComponent.modeContent:
          modeContentTop = cursor;
          cursor += modeContentFlowHeight;
      }
      if (index != order.components.length - 1) cursor += metrics.standardGap;
    }
    return _ExpandedBodyLayout(
      actionTop: actionTop!,
      summaryTop: summaryTop!,
      modeContentTop: modeContentTop!,
      railTop: cursor + metrics.standardGap,
    );
  }

  static double _lerp(double from, double to, double progress) =>
      from + (to - from) * progress;

  static double _stagedProgress(double progress, {required double start}) =>
      ((progress - start) / .62).clamp(0.0, 1.0).toDouble();
}

final class _ExpandedBodyLayout {
  const _ExpandedBodyLayout({
    required this.actionTop,
    required this.summaryTop,
    required this.modeContentTop,
    required this.railTop,
  });

  final double actionTop;
  final double summaryTop;
  final double modeContentTop;
  final double railTop;
}
