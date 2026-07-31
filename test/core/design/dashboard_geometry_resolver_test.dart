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
      expect(frame.summaryBounds.top, 606);
      expect(frame.searchBounds.top, 676);
      expect(frame.collapseHandleBounds.top, 726);
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
        expect(hiddenRail.collapseHandleBounds.top, 726);
        expect(shownRail.collapseHandleBounds.top, 774);
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
        expect(metrics.summaryTop, 606);
        expect(metrics.searchTop, 676);
      },
    );

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
      expect(frame.summaryBounds.top, 272);
      expect(frame.searchBounds.top, 342);
      expect(frame.collapseHandleBounds.top, 440);
      expect(frame.subheaderOneOpacity, 0);
      expect(frame.zone2Opacity, 0);
      expect(frame.isRailExpanded, isTrue);
    });

    test('keeps the rail-to-handle relationship at the collapsed endpoint', () {
      final frame = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.balance,
        collapseProgress: 180,
        isRailExpanded: true,
      );

      expect(frame.railBounds.top, 392);
      expect(frame.collapseHandleBounds.top, 440);
    });
  });
}
