import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';

void main() {
  group('DashboardGeometryResolver', () {
    test('derives the reference expanded lower-stack anchors', () {
      final frame = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.balance,
        collapseProgress: 0,
        isRailExpanded: false,
      );

      expect(frame.actionBounds.top, 553);
      expect(frame.summaryBounds.top, 616);
      expect(frame.railBounds.top, 686);
      expect(frame.collapseHandleBounds.top, 686);
    });

    test(
      'derives brand, indicator, and rail-aware handle bounds centrally',
      () {
        final hiddenRail = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        );
        final shownRail = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: true,
        );

        expect(
          hiddenRail.brandLockupBounds,
          const DashboardBounds(left: 28, top: 52, width: 252, height: 42),
        );
        expect(
          hiddenRail.zone2IndicatorBounds,
          const DashboardBounds(left: 17, top: 536, width: 378, height: 6),
        );
        expect(hiddenRail.collapseHandleBounds.top, 686);
        expect(shownRail.collapseHandleBounds.top, 749);
        expect(
          hiddenRail.headerGestureBounds,
          const DashboardBounds(left: 17, top: 104, width: 378, height: 428),
        );
      },
    );

    test(
      'derives upstream metric positions instead of independent anchors',
      () {
        const metrics = DashboardLayoutMetrics.reference;

        expect(metrics.subheaderOneTop, 241);
        expect(metrics.zone2Top, 324);
        expect(metrics.actionTop, 553);
        expect(metrics.summaryTop, 616);
        expect(metrics.railTop, 686);
      },
    );

    test('maps viewport vertical input back to controller coordinates', () {
      final halfViewportMetrics = DashboardLayoutMetrics.reference
          .fitToViewport(const Size(206, 446));
      final halfViewportFrame = DashboardGeometryResolver.resolve(
        metrics: halfViewportMetrics,
        mode: DashboardModeSpec.balance,
        collapseProgress: 0,
        isRailExpanded: false,
      );

      expect(halfViewportFrame.viewportVerticalDragToControllerScale, 2);
      expect(halfViewportFrame.mapViewportVerticalDragToController(-90), -180);
      expect(halfViewportFrame.mapViewportVerticalDragToController(90), 180);
    });

    test('derives web content-origin metrics without changing spacing', () {
      final metrics = DashboardLayoutMetrics.reference.forWebContentOrigin;

      expect(metrics.brandLockupTop, 0);
      expect(metrics.headerTop, 52);
      expect(metrics.subheaderOneTop, 189);
      expect(metrics.zone2Top, 272);
      expect(metrics.actionTop, 501);
      expect(metrics.summaryTop, 564);
      expect(metrics.railTop, 634);
    });

    test('uses one subheader envelope for split and unified modes', () {
      final balance = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.balance,
        collapseProgress: 0,
        isRailExpanded: false,
      );
      final budget = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.budget,
        collapseProgress: 0,
        isRailExpanded: false,
      );
      final mind = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.mind,
        collapseProgress: 0,
        isRailExpanded: false,
      );

      expect(
        DashboardModeSpec.balance.subheaderComposition,
        DashboardSubheaderComposition.split,
      );
      expect(
        DashboardModeSpec.budget.subheaderComposition,
        DashboardSubheaderComposition.split,
      );
      expect(
        DashboardModeSpec.mind.subheaderComposition,
        DashboardSubheaderComposition.unified,
      );
      expect(mind.subheaderEnvelopeBounds, balance.subheaderEnvelopeBounds);
      expect(mind.subheaderEnvelopeBounds, budget.subheaderEnvelopeBounds);
      expect(mind.unifiedSubheaderBounds, mind.subheaderEnvelopeBounds);
    });

    for (final mode in DashboardModeSpec.values) {
      test('${mode.mode.name} moves the lower stack with Zone2 height', () {
        final frame = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference.copyWith(
            zone2CardHeight: 240,
          ),
          mode: mode,
          collapseProgress: 0,
          isRailExpanded: false,
        );

        expect(frame.actionBounds.top, 585);
      });
    }

    test('interpolates the shared lower stack to the collapsed anchor', () {
      final frame = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.balance,
        collapseProgress: 180,
        isRailExpanded: true,
      );

      expect(frame.headerBounds.height, 104);
      expect(frame.actionBounds.top, 219);
      expect(frame.summaryBounds.top, 282);
      expect(frame.railBounds.top, 352);
      expect(frame.collapseHandleBounds.top, 415);
      expect(frame.subheaderOneOpacity, 0);
      expect(frame.zone2Opacity, 0);
      expect(frame.subheaderOneShift, -81);
      expect(frame.subheaderOneScale, closeTo(.90, .001));
      expect(frame.zone2Shift, -124);
      expect(frame.zone2Scale, closeTo(.96, .001));
      expect(frame.upperCardMotion, isNotNull);
      expect(frame.lowerCardMotion, isNotNull);
      expect(frame.upperCardMotion!.top, closeTo(160, .001));
      expect(frame.upperCardMotion!.left, closeTo(35, .001));
      expect(frame.lowerCardMotion!.top, closeTo(200, .001));
      expect(frame.lowerCardMotion!.left, closeTo(53, .001));
      expect(frame.lowerCardMotion!.opacity, 0);
      expect(frame.isRailExpanded, isTrue);
    });

    test(
      'upper card starts behind the collapsed header with full reveal motion',
      () {
        final collapsed = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: DashboardLayoutMetrics.reference.collapseTravel,
          isRailExpanded: false,
        );
        final midpoint = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: DashboardLayoutMetrics.reference.collapseTravel / 2,
          isRailExpanded: false,
        );

        expect(collapsed.upperCardMotion!.top, closeTo(160, .001));
        expect(collapsed.upperCardMotion!.left, closeTo(35, .001));
        expect(collapsed.upperCardMotion!.opacity, 0);
        expect(midpoint.upperCardMotion!.top, greaterThan(160));
        expect(midpoint.upperCardMotion!.left, lessThan(35));
        expect(midpoint.upperCardMotion!.opacity, greaterThan(0));
        expect(midpoint.upperCardMotion!.opacity, lessThan(1));
      },
    );

    test('publishes cascade motion values for split cards', () {
      final frame = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.balance,
        collapseProgress: 90,
        isRailExpanded: false,
      );

      expect(frame.upperCardMotion, isNotNull);
      expect(frame.lowerCardMotion, isNotNull);
      expect(
        frame.subheaderOneShift,
        closeTo(
          frame.upperCardMotion!.top - frame.subheaderOneBounds.top,
          .001,
        ),
      );
      expect(frame.subheaderOneScale, frame.upperCardMotion!.scale);
      expect(
        frame.zone2Shift,
        closeTo(frame.lowerCardMotion!.top - frame.zone2Bounds.top, .001),
      );
      expect(frame.zone2Scale, frame.lowerCardMotion!.scale);
      expect(frame.subheaderOneOpacity, frame.upperCardMotion!.opacity);
      expect(frame.zone2Opacity, frame.lowerCardMotion!.opacity);
      expect(frame.lowerCardMotion, isNotNull);
      expect(frame.lowerCardMotion!.top, greaterThan(263));
      expect(frame.lowerCardMotion!.top, lessThan(324));
      expect(frame.lowerCardMotion!.left, greaterThan(17));
      expect(frame.lowerCardMotion!.left, lessThan(35));
      expect(frame.lowerCardMotion!.opacity, greaterThan(0));
    });

    test('keeps the rail-to-handle relationship at the collapsed endpoint', () {
      final frame = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.balance,
        collapseProgress: 180,
        isRailExpanded: true,
      );

      expect(frame.railBounds.top, 352);
      expect(frame.collapseHandleBounds.top, 415);
    });
  });
}
