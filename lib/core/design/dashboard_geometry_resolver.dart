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
    bool hasStandaloneCollapseHandle = true,
    bool seamlessHeaderContent = false,
    double modeContentExtraHeight = 0,
    double principalModeContentExtraHeight = 0,
    double expandedHeaderExtraHeight = 0,
  }) {
    assert(modeContentExtraHeight >= 0);
    assert(principalModeContentExtraHeight >= 0);
    assert(expandedHeaderExtraHeight >= 0);
    assert(!seamlessHeaderContent || mode.mode == DashboardMode.mind);
    final progress = (collapseProgress / metrics.collapseTravel)
        .clamp(0.0, 1.0)
        .toDouble();
    final headerExpansionProgress = 1 - progress;
    final subheaderOneProgress = _stagedProgress(progress, start: .03);
    final zone2Progress = _stagedProgress(progress, start: .16);
    final isSplitMode =
        mode.subheaderComposition == DashboardSubheaderComposition.split;
    final headerHeight = _lerp(
      metrics.headerExpandedHeight + expandedHeaderExtraHeight,
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
    final baseModeLowerHeight =
        metrics.zone2CardHeight + reclaimedRailFootprint;
    // A unified mode owns one physical card envelope. Its structural minimum
    // must grow that card itself so its dots and rail remain downstream of the
    // enlarged body. Split modes retain the existing post-content extension
    // behavior used by Budget's optional chart tail.
    final fullUnifiedBodyExtra =
        mode.subheaderComposition == DashboardSubheaderComposition.unified
        ? modeContentExtraHeight
        : 0.0;
    final fullPostContentExtra =
        mode.subheaderComposition == DashboardSubheaderComposition.unified
        ? 0.0
        : modeContentExtraHeight;
    final revealedUnifiedBodyExtra =
        fullUnifiedBodyExtra * headerExpansionProgress;
    final revealedPostContentExtra =
        fullPostContentExtra * headerExpansionProgress;
    final revealedPrincipalModeContentExtraHeight =
        principalModeContentExtraHeight * headerExpansionProgress;
    final fullModeLowerHeight =
        baseModeLowerHeight +
        fullUnifiedBodyExtra +
        principalModeContentExtraHeight;
    final modeLowerHeight =
        baseModeLowerHeight +
        revealedUnifiedBodyExtra +
        revealedPrincipalModeContentExtraHeight;
    // The cursor keeps the accepted Zone2 → dot → next/rail relation, while
    // the named envelope includes the complete painted dot. Those differ by
    // the existing half-padding around the indicator, not a new spacing token.
    final fullModeContentFlowHeight =
        metrics.subheaderOneHeight +
        metrics.standardGap +
        fullModeLowerHeight +
        metrics.dotGap +
        metrics.dotHeight +
        fullPostContentExtra;
    final modeContentEnvelopeHeight =
        metrics.subheaderOneHeight +
        metrics.standardGap +
        modeLowerHeight +
        metrics.zone2IndicatorVerticalPadding +
        metrics.dotHeight +
        revealedPostContentExtra;
    final left = metrics.contentGutter;
    DashboardBounds bounds(double top, double height) => DashboardBounds(
      left: left,
      top: top,
      width: metrics.contentWidth,
      height: height,
    );
    final expandedBodies = _expandedBodyLayout(
      metrics: metrics,
      order: order,
      modeContentFlowHeight: fullModeContentFlowHeight,
      firstBodyTopGap: seamlessHeaderContent ? 0 : metrics.standardGap,
      expandedHeaderExtraHeight: expandedHeaderExtraHeight,
    );
    final headerBounds = bounds(metrics.headerTop, headerHeight);
    final seamlessActionTop =
        headerBounds.bottom +
        fullModeContentFlowHeight * headerExpansionProgress +
        metrics.standardGap;
    final seamlessSummaryTop =
        seamlessActionTop + metrics.actionHeight + metrics.standardGap;
    final seamlessRailTop =
        seamlessSummaryTop + metrics.summaryHeight + metrics.standardGap;
    final actionTop = seamlessHeaderContent
        ? seamlessActionTop
        : _lerp(expandedBodies.actionTop, collapsedActionTop, progress);
    final summaryTop = seamlessHeaderContent
        ? seamlessSummaryTop
        : _lerp(expandedBodies.summaryTop, collapsedSummaryTop, progress);
    final railTop = seamlessHeaderContent
        ? seamlessRailTop
        : _lerp(expandedBodies.railTop, collapsedRailTop, progress);
    final collapseHandleTop =
        railTop +
        (hasPhysicalRail && isRailExpanded
            ? metrics.railHeight + metrics.railToCollapseHandleGap
            : 0);

    final integratedHandleHeight = metrics.handleHeight * 1.4;
    final integratedHandleWidth = metrics.handleHeight * 4.4;
    final headerCollapseHandleBounds = hasStandaloneCollapseHandle
        ? null
        : DashboardBounds(
            left: left + (metrics.contentWidth - integratedHandleWidth) / 2,
            // Its center tracks the actual moving Header edge. The visual
            // treatment owns whether it reads as a notch or translucent pill.
            top: headerBounds.bottom - integratedHandleHeight / 2,
            width: integratedHandleWidth,
            height: integratedHandleHeight,
          );
    final modeContentTop = seamlessHeaderContent
        ? headerBounds.bottom
        : expandedBodies.modeContentTop;
    final subheaderOne = bounds(modeContentTop, metrics.subheaderOneHeight);
    final zone2 = bounds(
      subheaderOne.bottom + metrics.standardGap,
      modeLowerHeight,
    );
    final zone2Indicator = bounds(
      zone2.bottom + metrics.zone2IndicatorVerticalPadding,
      metrics.dotHeight,
    );
    final envelope = bounds(
      modeContentTop,
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
      headerExpansionProgress: headerExpansionProgress,
      expandedHeaderExtraHeight:
          expandedHeaderExtraHeight * headerExpansionProgress,
      principalModeContentExtraHeight: revealedPrincipalModeContentExtraHeight,
      viewportVerticalDragToControllerScale:
          metrics.viewportVerticalDragToControllerScale,
      brandLockupBounds: DashboardBounds(
        left: metrics.brandLockupLeft,
        top: metrics.brandLockupTop,
        width: metrics.brandLockupWidth,
        height: metrics.brandLockupHeight,
      ),
      headerBounds: headerBounds,
      headerGestureBounds: headerBounds,
      subheaderOneBounds: subheaderOne,
      zone2Bounds: zone2,
      zone2IndicatorBounds: zone2Indicator,
      subheaderEnvelopeBounds: envelope,
      unifiedSubheaderBounds:
          mode.subheaderComposition == DashboardSubheaderComposition.unified
          ? envelope
          : null,
      actionBounds: bounds(actionTop, metrics.actionHeight),
      summaryBounds: bounds(summaryTop, metrics.summaryHeight),
      railBounds: bounds(railTop, hasPhysicalRail ? metrics.railHeight : 0),
      collapseHandleBounds: bounds(
        collapseHandleTop,
        hasStandaloneCollapseHandle ? metrics.handleHeight : 0,
      ),
      headerCollapseHandleBounds: headerCollapseHandleBounds,
      logBoxHeaderBounds: bounds(
        collapseHandleTop +
            (hasStandaloneCollapseHandle ? metrics.handleHeight : 0),
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
      hasStandaloneCollapseHandle: hasStandaloneCollapseHandle,
      seamlessHeaderContent: seamlessHeaderContent,
      bodyOrder: order,
      modeContentBounds: bounds(modeContentTop, modeContentEnvelopeHeight),
    );
  }

  static _ExpandedBodyLayout _expandedBodyLayout({
    required DashboardLayoutMetrics metrics,
    required DashboardBodyOrder order,
    required double modeContentFlowHeight,
    required double firstBodyTopGap,
    required double expandedHeaderExtraHeight,
  }) {
    var cursor =
        metrics.headerTop +
        metrics.headerExpandedHeight +
        expandedHeaderExtraHeight +
        firstBodyTopGap;
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
