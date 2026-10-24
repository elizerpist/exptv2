import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/mind_unified_mother_card_geometry.dart';

void main() {
  for (final viewport in [
    const Size(412, 892),
    const Size(320, 640),
    const Size(480, 960),
  ]) {
    for (final rail in [false, true]) {
      for (final stretch in [0.0, 48.0]) {
        for (final radius in [0.0, 28.0]) {
          test(
            'Mind unified continuity $viewport rail=$rail stretch=$stretch radius=$radius',
            () {
              final metrics = DashboardLayoutMetrics.reference.fitToViewport(
                viewport,
              );
              MindUnifiedMotherCardGeometry resolve(double travel) {
                final frame = DashboardGeometryResolver.resolve(
                  metrics: metrics,
                  mode: DashboardModeSpec.mind,
                  collapseProgress: travel,
                  isRailExpanded: rail,
                  hasPhysicalRail: rail,
                  seamlessHeaderContent: true,
                  principalModeContentExtraHeight: stretch,
                  canonicalMotherCardContentExtraHeight: stretch,
                  expandedHeaderExtraHeight: stretch / 2,
                );
                expect(frame.lowerCardMotion, isNull);
                return MindUnifiedMotherCardGeometry.resolve(
                  frame: frame,
                  headerRadius: BorderRadius.circular(radius),
                  contentRadius: BorderRadius.circular(radius),
                );
              }

              final initial = resolve(0);
              expect(initial.bodyBounds.top, initial.headerBounds.bottom);
              expect(
                initial.bodyBounds.bottom,
                closeTo(initial.joinedBounds.bottom, 1e-8),
              );
              expect(initial.visibleBodyBounds, initial.bodyBounds);
              expect(initial.shape.headerRadius.bottomLeft, Radius.zero);
              expect(initial.shape.contentRadius.topLeft, Radius.zero);
              var previous = initial;
              for (var i = 1; i <= 1000; i++) {
                final next = resolve(metrics.collapseTravel * i / 1000);
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
                  (next.bodyBounds.width - previous.bodyBounds.width).abs(),
                  lessThan(1),
                );
                expect(
                  next.bodyBounds.bottom,
                  lessThanOrEqualTo(previous.bodyBounds.bottom + 1e-8),
                );
                expect(
                  next.visibleBodyBounds.top,
                  greaterThanOrEqualTo(next.headerBounds.bottom),
                );
                expect(next.visibleBodyBounds.height, greaterThanOrEqualTo(0));
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
                final t = resolve(travel * metrics.collapseTravel / 180);
                expect(t.separation, closeTo(travel / 180, 1e-8));
                expect(
                  t.shape.headerRadius.bottomLeft.x,
                  closeTo(radius * t.separation, 1e-8),
                );
                expect(
                  t.shape.contentRadius.topLeft.x,
                  closeTo(radius * t.separation, 1e-8),
                );
              }
              final half = resolve(metrics.collapseTravel * .5);
              expect(
                half.contentBounds.top - half.visibleBodyBounds.top,
                isNot(
                  closeTo(
                    initial.contentBounds.top - initial.visibleBodyBounds.top,
                    .01,
                  ),
                ),
              );
              for (final s in [.35, .1, .7, 0.0]) {
                final a = resolve(metrics.collapseTravel * s);
                final b = resolve(metrics.collapseTravel * s);
                expect(a.bodyBounds, b.bodyBounds);
                expect(a.contentBounds, b.contentBounds);
                expect(a.contentScale, b.contentScale);
              }
              expect(
                resolve(metrics.collapseTravel).visibleBodyBounds.height,
                0,
              );
              expect(resolve(metrics.collapseTravel).opacity, 0);
            },
          );
        }
      }
    }
  }
}
