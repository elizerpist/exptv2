import 'package:flutter/material.dart';

/// The common physical token set for compact header partition lanes.
///
/// Budget owns the original allocation partition; Balance reuses its radius
/// and baseline thickness rather than independently sampling a lookalike.
abstract final class DashboardPartitionLaneGeometry {
  static const cornerRadius = Radius.circular(4);
  static const baselineThickness = 7.0;
  static const balanceHeaderMaximumThickness = 42.0;

  /// A label-bearing Balance lane expands from the exact Budget baseline.
  /// The user-controlled percent is visual-only and never alters either
  /// income or expense membership.
  static double balanceHeaderThicknessFor(double percent) =>
      baselineThickness +
      (balanceHeaderMaximumThickness - baselineThickness) *
          percent.clamp(0.0, 100.0) /
          100.0;
}
