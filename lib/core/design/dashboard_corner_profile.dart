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

/// Independent normalized positions for the semantic dashboard surface
/// families. Every zero endpoint is the exact current authored baseline.
@immutable
final class DashboardCornerSettings {
  const DashboardCornerSettings({
    this.header = 0,
    this.contentCard = 0,
    this.directionControl = 0,
    this.summaryPill = 0,
    this.searchPill = 0,
    this.logBoxGroup = 0,
    this.budgetDistributionCard = 0,
  }) : assert(header >= 0 && header <= 1),
       assert(contentCard >= 0 && contentCard <= 1),
       assert(directionControl >= 0 && directionControl <= 1),
       assert(summaryPill >= 0 && summaryPill <= 1),
       assert(searchPill >= 0 && searchPill <= 1),
       assert(logBoxGroup >= 0 && logBoxGroup <= 1),
       assert(budgetDistributionCard >= 0 && budgetDistributionCard <= 1);

  static const defaults = DashboardCornerSettings();

  final double header;
  final double contentCard;
  final double directionControl;
  final double summaryPill;
  final double searchPill;
  final double logBoxGroup;
  final double budgetDistributionCard;

  double positionFor(DashboardCornerSurfaceFamily family) => switch (family) {
    DashboardCornerSurfaceFamily.header => header,
    DashboardCornerSurfaceFamily.contentCard => contentCard,
    DashboardCornerSurfaceFamily.directionControl => directionControl,
    DashboardCornerSurfaceFamily.summaryPill => summaryPill,
    DashboardCornerSurfaceFamily.searchPill => searchPill,
    DashboardCornerSurfaceFamily.logBoxGroup => logBoxGroup,
    DashboardCornerSurfaceFamily.budgetDistributionCard =>
      budgetDistributionCard,
  };

  DashboardCornerSettings withPosition(
    DashboardCornerSurfaceFamily family,
    double position,
  ) {
    final next = position.clamp(0.0, 1.0).toDouble();
    return switch (family) {
      DashboardCornerSurfaceFamily.header => DashboardCornerSettings(
        header: next,
        contentCard: contentCard,
        directionControl: directionControl,
        summaryPill: summaryPill,
        searchPill: searchPill,
        logBoxGroup: logBoxGroup,
        budgetDistributionCard: budgetDistributionCard,
      ),
      DashboardCornerSurfaceFamily.contentCard => DashboardCornerSettings(
        header: header,
        contentCard: next,
        directionControl: directionControl,
        summaryPill: summaryPill,
        searchPill: searchPill,
        logBoxGroup: logBoxGroup,
        budgetDistributionCard: budgetDistributionCard,
      ),
      DashboardCornerSurfaceFamily.directionControl => DashboardCornerSettings(
        header: header,
        contentCard: contentCard,
        directionControl: next,
        summaryPill: summaryPill,
        searchPill: searchPill,
        logBoxGroup: logBoxGroup,
        budgetDistributionCard: budgetDistributionCard,
      ),
      DashboardCornerSurfaceFamily.summaryPill => DashboardCornerSettings(
        header: header,
        contentCard: contentCard,
        directionControl: directionControl,
        summaryPill: next,
        searchPill: searchPill,
        logBoxGroup: logBoxGroup,
        budgetDistributionCard: budgetDistributionCard,
      ),
      DashboardCornerSurfaceFamily.searchPill => DashboardCornerSettings(
        header: header,
        contentCard: contentCard,
        directionControl: directionControl,
        summaryPill: summaryPill,
        searchPill: next,
        logBoxGroup: logBoxGroup,
        budgetDistributionCard: budgetDistributionCard,
      ),
      DashboardCornerSurfaceFamily.logBoxGroup => DashboardCornerSettings(
        header: header,
        contentCard: contentCard,
        directionControl: directionControl,
        summaryPill: summaryPill,
        searchPill: searchPill,
        logBoxGroup: next,
        budgetDistributionCard: budgetDistributionCard,
      ),
      DashboardCornerSurfaceFamily.budgetDistributionCard =>
        DashboardCornerSettings(
          header: header,
          contentCard: contentCard,
          directionControl: directionControl,
          summaryPill: summaryPill,
          searchPill: searchPill,
          logBoxGroup: logBoxGroup,
          budgetDistributionCard: next,
        ),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardCornerSettings &&
      other.header == header &&
      other.contentCard == contentCard &&
      other.directionControl == directionControl &&
      other.summaryPill == summaryPill &&
      other.searchPill == searchPill &&
      other.logBoxGroup == logBoxGroup &&
      other.budgetDistributionCard == budgetDistributionCard;

  @override
  int get hashCode => Object.hash(
    header,
    contentCard,
    directionControl,
    summaryPill,
    searchPill,
    logBoxGroup,
    budgetDistributionCard,
  );
}

/// Resolves the one normalized preference into geometry-safe family radii.
///
/// The zero endpoint exactly matches the current authored dashboard values;
/// the rounded endpoint is intentionally family-specific and inspired only by
/// the softer external reference's outer-surface proportions.
final class DashboardCornerProfile {
  const DashboardCornerProfile(this.settings);

  final DashboardCornerSettings settings;

  double radiusFor(DashboardCornerSurfaceFamily family, {required Size size}) {
    final endpoints = _endpointsFor(family);
    final interpolated = lerpDouble(
      endpoints.$1,
      endpoints.$2,
      settings.positionFor(family),
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
