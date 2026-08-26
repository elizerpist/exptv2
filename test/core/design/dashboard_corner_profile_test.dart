import 'package:fluvi/core/design/app_control_metrics.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'corner positions are independent and default to the current baseline',
    () {
      const defaults = DashboardCornerSettings.defaults;
      expect(defaults.positionFor(DashboardCornerSurfaceFamily.header), 0);
      expect(defaults.positionFor(DashboardCornerSurfaceFamily.searchPill), 0);

      final changed = defaults.withPosition(
        DashboardCornerSurfaceFamily.searchPill,
        .75,
      );
      expect(changed.positionFor(DashboardCornerSurfaceFamily.searchPill), .75);
      expect(changed.positionFor(DashboardCornerSurfaceFamily.header), 0);
    },
  );

  test('minimum corner roundness reproduces the current surface radii', () {
    const profile = DashboardCornerProfile(DashboardCornerSettings.defaults);
    const size = Size(320, 80);

    expect(
      profile.radiusFor(DashboardCornerSurfaceFamily.header, size: size),
      AppRadii.control,
    );
    expect(
      profile.radiusFor(DashboardCornerSurfaceFamily.contentCard, size: size),
      AppRadii.control,
    );
    expect(
      profile.radiusFor(
        DashboardCornerSurfaceFamily.directionControl,
        size: size,
      ),
      AppSelectorMetrics.compactTileRadius,
    );
    expect(
      profile.radiusFor(DashboardCornerSurfaceFamily.summaryPill, size: size),
      AppRadii.control,
    );
    expect(
      profile.radiusFor(DashboardCornerSurfaceFamily.searchPill, size: size),
      AppRadii.control,
    );
    expect(
      profile.radiusFor(DashboardCornerSurfaceFamily.logBoxGroup, size: size),
      AppRadii.logGroup,
    );
    expect(
      profile.radiusFor(
        DashboardCornerSurfaceFamily.budgetDistributionCard,
        size: size,
      ),
      AppRadii.control,
    );
  });

  test('corner profile is monotonic and geometry-safe for every family', () {
    const size = Size(44, 32);
    for (final family in DashboardCornerSurfaceFamily.values) {
      var previous = -1.0;
      for (final position in <double>[0, .25, .5, .75, 1]) {
        final radius = DashboardCornerProfile(
          DashboardCornerSettings.defaults.withPosition(family, position),
        ).radiusFor(family, size: size);
        expect(radius, greaterThanOrEqualTo(previous));
        expect(radius, inInclusiveRange(0, size.shortestSide / 2));
        previous = radius;
      }
    }
  });
}
