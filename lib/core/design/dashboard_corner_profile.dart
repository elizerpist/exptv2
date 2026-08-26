import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_control_metrics.dart';

/// Semantic outer-surface families controlled by one dashboard roundness
/// preference. Their raw radii intentionally differ because a header, a
/// compact control and a grouped Ledger surface have different proportions.
enum DashboardCornerSurfaceFamily {
  header,
  contentCard,
  directionControl,
  summaryPill,
  searchPill,
  logBoxGroup,
  budgetDistributionCard,
}

/// Normalized, session-level roundness setting.
@immutable
final class DashboardCornerRoundness {
  const DashboardCornerRoundness(double position)
    : position = position < 0
          ? 0
          : position > 1
          ? 1
          : position;

  static const minimum = DashboardCornerRoundness(0);

  final double position;
}

/// Resolves the one normalized preference into geometry-safe family radii.
///
/// The zero endpoint exactly matches the current authored dashboard values;
/// the rounded endpoint is intentionally family-specific and inspired only by
/// the softer external reference's outer-surface proportions.
final class DashboardCornerProfile {
  const DashboardCornerProfile(this.roundness);

  final DashboardCornerRoundness roundness;

  double radiusFor(DashboardCornerSurfaceFamily family, {required Size size}) {
    final endpoints = _endpointsFor(family);
    final interpolated = lerpDouble(
      endpoints.$1,
      endpoints.$2,
      roundness.position,
    )!;
    final safeMaximum = size.shortestSide.isFinite
        ? (size.shortestSide / 2).clamp(0.0, double.infinity).toDouble()
        : interpolated;
    return interpolated.clamp(0.0, safeMaximum).toDouble();
  }

  BorderRadius borderRadiusFor(
    DashboardCornerSurfaceFamily family, {
    required Size size,
  }) => BorderRadius.circular(radiusFor(family, size: size));

  (double, double) _endpointsFor(DashboardCornerSurfaceFamily family) =>
      switch (family) {
        DashboardCornerSurfaceFamily.header => (AppRadii.control, 28),
        DashboardCornerSurfaceFamily.contentCard => (AppRadii.control, 28),
        DashboardCornerSurfaceFamily.directionControl => (
          AppSelectorMetrics.compactTileRadius,
          22,
        ),
        DashboardCornerSurfaceFamily.summaryPill => (AppRadii.control, 25),
        DashboardCornerSurfaceFamily.searchPill => (AppRadii.control, 25),
        DashboardCornerSurfaceFamily.logBoxGroup => (AppRadii.logGroup, 25),
        DashboardCornerSurfaceFamily.budgetDistributionCard => (
          AppRadii.control,
          28,
        ),
      };
}
