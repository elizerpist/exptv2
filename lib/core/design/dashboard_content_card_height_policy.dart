import 'dashboard_layout_metrics.dart';

/// Resolves the one settled Header/content Mother Card body height shared by
/// every dashboard mode. Balance SUM is the structural baseline: individual
/// scopes and section orders cannot expand this outer presentation contract.
abstract final class DashboardContentCardHeightPolicy {
  static double resolveSettledContentHeight({
    required DashboardLayoutMetrics metrics,
    required bool hasPhysicalRail,
    required double sharedContentStretch,
  }) {
    assert(sharedContentStretch >= 0);
    final reclaimedRailFootprint = hasPhysicalRail
        ? 0.0
        : metrics.railHeight + metrics.railToCollapseHandleGap;
    return metrics.standardGap +
        metrics.subheaderOneHeight +
        metrics.standardGap +
        metrics.zone2CardHeight +
        reclaimedRailFootprint +
        sharedContentStretch;
  }
}
