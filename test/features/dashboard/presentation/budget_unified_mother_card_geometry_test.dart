import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_unified_mother_card_geometry.dart';

void main() {
  for (final viewport in [
    const Size(412, 892),
    const Size(320, 640),
    const Size(480, 960),
  ]) {
    for (final physicalRail in [false, true]) {
      for (final stretch in [0.0, 48.0]) {
        for (final roundness in [0.0, 1.0]) {
          test(
            'continuous physical edges $viewport rail=$physicalRail stretch=$stretch roundness=$roundness',
            () {
              final metrics = DashboardLayoutMetrics.reference.fitToViewport(
                viewport,
              );
              final corners = DashboardCornerProfile(
                DashboardCornerSettings(
                  header: roundness,
                  budgetDistributionCard: roundness,
                ),
              );
              BudgetUnifiedMotherCardGeometry resolve(double travel) {
                final f = DashboardGeometryResolver.resolve(
                  metrics: metrics,
                  mode: DashboardModeSpec.budget,
                  collapseProgress: travel,
                  isRailExpanded: physicalRail,
                  hasPhysicalRail: physicalRail,
                  principalModeContentExtraHeight: stretch,
                  canonicalMotherCardContentExtraHeight: stretch,
                  expandedHeaderExtraHeight: stretch / 2,
                );
                return BudgetUnifiedMotherCardGeometry.resolve(
                  frame: f,
                  headerRadius: corners.borderRadiusFor(
                    DashboardCornerSurfaceFamily.header,
                    size: Size(f.headerBounds.width, f.headerBounds.height),
                  ),
                  contentRadius: corners.borderRadiusFor(
                    DashboardCornerSurfaceFamily.budgetDistributionCard,
                    size: Size(
                      f.modeContentBounds.width,
                      f.modeContentBounds.height,
                    ),
                  ),
                );
              }

              final first = resolve(0);
              expect(
                first.bodyBounds.top,
                closeTo(first.headerBounds.bottom, 1e-8),
              );
              expect(
                first.bodyBounds.bottom,
                closeTo(first.joinedBounds.bottom, 1e-8),
              );
              expect(
                first.visibleBodyBounds,
                rectMoreOrLessEquals(first.bodyBounds, epsilon: 1e-8),
              );
              expect(first.shape.headerRadius.bottomLeft, Radius.zero);
              expect(first.shape.contentRadius.topLeft, Radius.zero);
              expect(first.opacity, 1);
              // Explicit first-frame travel probes, not normalized percentages.
              for (final p in [.1, .5, 1.0, 3.0, 9.0]) {
                final next = resolve(p);
                expect(
                  next.bodyBounds.bottom,
                  lessThanOrEqualTo(first.bodyBounds.bottom),
                );
                expect(
                  (next.bodyBounds.bottom - first.bodyBounds.bottom).abs(),
                  lessThan(p * 3),
                );
                expect(
                  (next.visibleBodyBounds.top - first.bodyBounds.top).abs(),
                  lessThan(p * 3),
                );
                expect(next.shape.headerRadius.bottomLeft.x, greaterThan(0));
                expect(next.shape.contentRadius.topLeft.x, greaterThan(0));
              }
              var previous = first;
              // Dense forward/reverse input includes every requested percentage
              // and checks for jumps at the old .001/.999 switching thresholds.
              for (var i = 1; i <= 1000; i++) {
                final next = resolve(metrics.collapseTravel * i / 1000);
                expect(
                  next.bodyBounds.bottom,
                  lessThanOrEqualTo(previous.bodyBounds.bottom + 1e-8),
                );
                expect(
                  (next.bodyBounds.bottom - previous.bodyBounds.bottom).abs(),
                  lessThan(2),
                );
                expect(
                  (next.visibleBodyBounds.top - previous.visibleBodyBounds.top)
                      .abs(),
                  lessThan(2),
                );
                expect(
                  next.bodyBounds.left,
                  greaterThanOrEqualTo(previous.bodyBounds.left - 1e-8),
                );
                expect(
                  next.bodyBounds.right,
                  lessThanOrEqualTo(previous.bodyBounds.right + 1e-8),
                );
                expect(next.visibleBodyBounds.bottom, next.bodyBounds.bottom);
                expect(
                  next.visibleBodyBounds.top,
                  greaterThanOrEqualTo(
                    next.headerBounds.bottom < next.bodyBounds.bottom
                        ? next.headerBounds.bottom
                        : next.bodyBounds.bottom,
                  ),
                );
                previous = next;
              }
              final last = resolve(metrics.collapseTravel);
              expect(
                last.bodyBounds.left,
                closeTo(last.cascadeBounds.left, 1e-8),
              );
              expect(
                last.bodyBounds.top,
                closeTo(last.cascadeBounds.top, 1e-8),
              );
              expect(
                last.bodyBounds.right,
                closeTo(last.cascadeBounds.right, 1e-8),
              );
              expect(
                last.bodyBounds.bottom,
                closeTo(last.cascadeBounds.bottom, 1e-8),
              );
              expect(last.opacity, 0);
              for (final s in [
                0.0,
                .05,
                .2,
                .5,
                .8,
                1.0,
                .8,
                .2,
                .5,
                .05,
                0.0,
              ]) {
                final a = resolve(metrics.collapseTravel * s);
                final b = resolve(metrics.collapseTravel * s);
                expect(a.bodyBounds, b.bodyBounds);
                expect(a.shape.headerRadius, b.shape.headerRadius);
              }
            },
          );
        }
      }
    }
  }
}
