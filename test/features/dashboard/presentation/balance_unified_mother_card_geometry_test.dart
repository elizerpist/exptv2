import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_unified_mother_card_geometry.dart';

void main() {
  for (final viewport in [
    const Size(412, 892),
    const Size(280, 620),
    const Size(480, 960),
  ]) {
    for (final physicalRail in [false, true]) {
      for (final stretch in [0.0, 48.0]) {
        for (final roundness in [0.0, 1.0]) {
          test(
            'Balance continuous physical and independent content geometry $viewport rail=$physicalRail stretch=$stretch roundness=$roundness',
            () {
              final metrics = DashboardLayoutMetrics.reference.fitToViewport(
                viewport,
              );
              BalanceUnifiedMotherCardGeometry resolve(double travel) {
                final frame = DashboardGeometryResolver.resolve(
                  metrics: metrics,
                  mode: DashboardModeSpec.balance,
                  collapseProgress: travel,
                  isRailExpanded: physicalRail,
                  hasPhysicalRail: physicalRail,
                  principalModeContentExtraHeight: stretch,
                  canonicalMotherCardContentExtraHeight: stretch,
                );
                final corners = DashboardCornerProfile(
                  DashboardCornerSettings(
                    header: roundness,
                    contentCard: roundness,
                  ),
                );
                return BalanceUnifiedMotherCardGeometry.resolve(
                  frame: frame,
                  headerRadius: corners.borderRadiusFor(
                    DashboardCornerSurfaceFamily.header,
                    size: Size(
                      frame.headerBounds.width,
                      frame.headerBounds.height,
                    ),
                  ),
                  contentRadius: corners.borderRadiusFor(
                    DashboardCornerSurfaceFamily.contentCard,
                    size: Size(
                      frame.modeContentBounds.width,
                      frame.modeContentBounds.height,
                    ),
                  ),
                );
              }

              final expanded = resolve(0);
              expect(expanded.bodyBounds.top, expanded.headerBounds.bottom);
              expect(expanded.bodyBounds.bottom, expanded.joinedBounds.bottom);
              expect(expanded.shape.headerRadius.bottomLeft, Radius.zero);
              expect(expanded.shape.contentRadius.topLeft, Radius.zero);
              expect(expanded.contentOpacity, 1);
              for (final travel in [.1, .5, 1.0, 3.0, 9.0]) {
                final next = resolve(travel);
                expect(
                  next.bodyBounds.bottom,
                  lessThanOrEqualTo(expanded.bodyBounds.bottom),
                );
                expect(
                  (next.bodyBounds.bottom - expanded.bodyBounds.bottom).abs(),
                  lessThan(3 * travel),
                );
                expect(
                  (next.visibleBodyBounds.top - expanded.bodyBounds.top).abs(),
                  lessThan(3 * travel),
                );
                expect(
                  (next.bodyBounds.width - expanded.bodyBounds.width).abs(),
                  lessThan(3 * travel),
                );
              }
              var previous = expanded;
              // Dense samples catch the old settled-state epsilon boundary and the
              // independent lower-edge snap. These are physical rectangles, not PNGs.
              for (var i = 1; i <= 1000; i++) {
                final next = resolve(metrics.collapseTravel * i / 1000);
                for (final delta in [
                  next.bodyBounds.top - previous.bodyBounds.top,
                  next.bodyBounds.bottom - previous.bodyBounds.bottom,
                  next.bodyBounds.width - previous.bodyBounds.width,
                  next.visibleBodyBounds.top - previous.visibleBodyBounds.top,
                ]) {
                  expect(
                    delta.abs(),
                    lessThan(3),
                    reason: 'No discontinuity at sample $i',
                  );
                }
                expect(
                  next.bodyBounds.bottom,
                  lessThanOrEqualTo(previous.bodyBounds.bottom + 1e-8),
                );
                expect(
                  next.shape.headerRadius.bottomLeft.x,
                  greaterThanOrEqualTo(
                    previous.shape.headerRadius.bottomLeft.x,
                  ),
                );
                expect(
                  next.shape.contentRadius.topLeft.x,
                  greaterThanOrEqualTo(previous.shape.contentRadius.topLeft.x),
                );
                expect(next.visibleBodyBounds.bottom, next.bodyBounds.bottom);
                expect(
                  next.visibleBodyBounds.top,
                  greaterThanOrEqualTo(next.headerBounds.bottom),
                );
                previous = next;
              }
              for (final travel in [
                0.0,
                .1,
                .5,
                1.0,
                3.0,
                9.0,
                18.0,
                36.0,
                90.0,
                144.0,
                171.0,
                180.0,
              ]) {
                final g = resolve(
                  travel.clamp(0, metrics.collapseTravel).toDouble(),
                );
                expect(g.bodyBounds.isFinite, isTrue);
                expect(g.contentOpacity, inInclusiveRange(0, 1));
              }
              final partial = resolve(metrics.collapseTravel * .35);
              expect(
                partial.contentScale != expanded.contentScale ||
                    partial.contentShift != expanded.contentShift,
                isTrue,
                reason:
                    'The analytical content has independent motion inside the material.',
              );
              for (final fraction in [.35, .1, .7, 0.0]) {
                final first = resolve(metrics.collapseTravel * fraction);
                final repeated = resolve(metrics.collapseTravel * fraction);
                expect(first.bodyBounds, repeated.bodyBounds);
                expect(first.contentScale, repeated.contentScale);
                expect(first.contentShift, repeated.contentShift);
              }
              expect(resolve(0).bodyBounds, expanded.bodyBounds);
            },
          );
        }
      }
    }
  }
}
