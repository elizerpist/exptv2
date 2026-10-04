import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/dashboard_header_trend_visual_kernel.dart';

/// The common physical token set for compact header partition lanes.
///
/// Budget owns the original allocation partition; Balance reuses its radius
/// and baseline thickness rather than independently sampling a lookalike.
abstract final class DashboardPartitionLaneGeometry {
  static const cornerRadius = Radius.circular(4);
  static const baselineThickness = 7.0;
  static const balanceHeaderMaximumThickness = 42.0;
  static const budgetHeaderMinimumHeightPercent = -50.0;
  static const budgetHeaderMaximumHeightPercent = 100.0;

  /// Budget's previously fixed 7px lane remains the zero reference point;
  /// the tuner can now also contract down to 3.5px for a genuinely lower
  /// minimum thickness without adding a second geometry policy.
  static double budgetHeaderThicknessFor(double percent) =>
      baselineThickness *
      (1 +
          percent.clamp(
                budgetHeaderMinimumHeightPercent,
                budgetHeaderMaximumHeightPercent,
              ) /
              100);

  /// A label-bearing Balance lane expands from the exact Budget baseline.
  /// The user-controlled percent is visual-only and never alters either
  /// income or expense membership.
  static double balanceHeaderThicknessFor(double percent) =>
      baselineThickness +
      (balanceHeaderMaximumThickness - baselineThickness) *
          percent.clamp(0.0, 100.0) /
          100.0;

  /// Resolves the one vertical lane shared by both Balance header bar
  /// presentations. At zero the lane ends exactly at the expanded Header's
  /// safe plot bottom (the Budget partition baseline); at one it sits directly
  /// beneath the primary Balance value. The range re-solves with lane height.
  static double balanceHeaderTopFor({
    required double plotTop,
    required double plotHeight,
    required double valueTop,
    required double height,
    required double verticalPosition,
  }) {
    final metrics = DashboardHeaderTrendChartStyle.primaryValueTextMetrics;
    final valueBottom = valueTop + metrics.fontSize! * metrics.height!;
    final topLimit = valueBottom + 7;
    final bottomLimit = math.max(topLimit, plotTop + plotHeight - height);
    return bottomLimit -
        (bottomLimit - topLimit) * verticalPosition.clamp(0.0, 1.0);
  }
}
