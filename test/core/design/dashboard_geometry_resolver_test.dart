import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';

void main() {
  group('DashboardGeometryResolver', () {
    test(
      'derives the reference expanded structural order and lower anchors',
      () {
        final frame = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        );

        expect(frame.actionBounds.top, 241);
        expect(frame.summaryBounds.top, 304);
        expect(frame.subheaderOneBounds.top, 374);
        expect(frame.zone2Bounds.top, 457);
        expect(frame.railBounds.top, 695);
        expect(frame.collapseHandleBounds.top, 695);
        expect(frame.headerBounds.bottom, lessThan(frame.actionBounds.top));
        expect(frame.actionBounds.bottom, lessThan(frame.summaryBounds.top));
        expect(
          frame.summaryBounds.bottom,
          lessThan(frame.subheaderOneBounds.top),
        );
        expect(
          frame.subheaderOneBounds.bottom,
          lessThan(frame.zone2Bounds.top),
        );
        expect(
          frame.zone2Bounds.bottom,
          lessThan(frame.zone2IndicatorBounds.top),
        );
        expect(
          frame.zone2IndicatorBounds.bottom,
          lessThan(frame.railBounds.top),
        );
        expect(
          frame.logBoxHeaderBounds,
          const DashboardBounds(left: 17, top: 715, width: 378, height: 122),
        );
      },
    );

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
          const DashboardBounds(left: 17, top: 681.5, width: 378, height: 6),
        );
        expect(hiddenRail.collapseHandleBounds.top, 695);
        expect(shownRail.collapseHandleBounds.top, 753);
        expect(hiddenRail.logBoxHeaderBounds.top, 715);
        expect(shownRail.logBoxHeaderBounds.top, 773);
        expect(
          hiddenRail.headerGestureBounds,
          const DashboardBounds(left: 17, top: 104, width: 378, height: 126),
        );
      },
    );

    test('centers indicator padding between Zone2 and the rail', () {
      const metrics = DashboardLayoutMetrics.reference;
      final frame = DashboardGeometryResolver.resolve(
        metrics: metrics,
        mode: DashboardModeSpec.balance,
        collapseProgress: 0,
        isRailExpanded: false,
      );

      final upperPadding =
          frame.zone2IndicatorBounds.top - frame.zone2Bounds.bottom;
      final lowerPadding =
          frame.railBounds.top - frame.zone2IndicatorBounds.bottom;

      expect(upperPadding, closeTo(lowerPadding, .001));
      expect(
        frame.zone2Bounds.bottom,
        lessThan(frame.zone2IndicatorBounds.top),
      );
      expect(frame.zone2IndicatorBounds.bottom, lessThan(frame.railBounds.top));
      expect(frame.actionBounds.top, metrics.actionTop);
    });

    test(
      'derives upstream metric positions instead of independent anchors',
      () {
        const metrics = DashboardLayoutMetrics.reference;

        expect(metrics.actionTop, 241);
        expect(metrics.summaryTop, 304);
        expect(metrics.subheaderOneTop, 374);
        expect(metrics.zone2Top, 457);
        expect(metrics.railTop, 695);
      },
    );

    test(
      'reclaims open-rail lower-stack space centrally while preserving the Ledger origin',
      () {
        const metrics = DashboardLayoutMetrics.reference;
        final openRail = DashboardGeometryResolver.resolve(
          metrics: metrics,
          mode: DashboardModeSpec.budget,
          collapseProgress: 0,
          isRailExpanded: true,
        );
        final balance = DashboardGeometryResolver.resolve(
          metrics: metrics,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: true,
        );
        final mind = DashboardGeometryResolver.resolve(
          metrics: metrics,
          mode: DashboardModeSpec.mind,
          collapseProgress: 0,
          isRailExpanded: true,
        );

        // 5 px comes from the dedicated open-rail handle gap and 4 px from
        // the historical count lane; the 9 px is transferred only through
        // Zone2. The Ledger chrome can grow without changing this core-card
        // dependency.
        expect(metrics.standardGap, 11);
        expect(DashboardLayoutMetrics.reclaimedCoreVerticalSpace, 9);
        expect(metrics.zone2CardHeight, 217);
        expect(
          openRail.collapseHandleBounds.top - openRail.railBounds.bottom,
          6,
        );
        expect(openRail.logBoxHeaderBounds.height, 122);
        expect(
          DashboardLogBoxTokens.summaryHeaderHeight,
          metrics.logBoxHeaderHeight,
        );
        expect(
          DashboardLogBoxTokens.ledgerResultTopInset +
              DashboardLogBoxTokens.ledgerResultAmountHeight +
              DashboardLogBoxTokens.ledgerResultCountHeight +
              DashboardLogBoxTokens.ledgerResultToSearchGap +
              DashboardLogBoxTokens.ledgerSearchPillHeight +
              DashboardLogBoxTokens.ledgerSearchToListGap,
          DashboardLogBoxTokens.summaryHeaderHeight,
        );
        // The resolver keeps the Ledger origin at 773; the expanded fixed
        // chrome occupies its own viewport height before date groups begin.
        expect(openRail.logBoxHeaderBounds.top, 773);
        expect(openRail.logBoxHeaderBounds.bottom, 895);

        expect(balance.zone2Bounds.height, metrics.zone2CardHeight);
        expect(openRail.zone2Bounds.height, metrics.zone2CardHeight);
        expect(
          mind.unifiedSubheaderBounds!.bottom,
          openRail.zone2Bounds.bottom,
        );
        expect(
          openRail.railBounds.bottom,
          lessThan(openRail.collapseHandleBounds.top),
        );
        expect(
          openRail.collapseHandleBounds.bottom,
          lessThanOrEqualTo(openRail.logBoxHeaderBounds.top),
        );
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
      expect(halfViewportFrame.actionBounds.top, 120.5);
      expect(halfViewportFrame.summaryBounds.top, 152);
      expect(halfViewportFrame.subheaderOneBounds.top, 187);
      expect(halfViewportFrame.zone2Bounds.top, 228.5);
      expect(halfViewportFrame.railBounds.top, 347.5);
      expect(halfViewportFrame.logBoxHeaderBounds.height, 61);
    });

    test('derives web content-origin metrics without changing spacing', () {
      final metrics = DashboardLayoutMetrics.reference.forWebContentOrigin;

      expect(metrics.brandLockupTop, 0);
      expect(metrics.headerTop, 52);
      expect(metrics.actionTop, 189);
      expect(metrics.summaryTop, 252);
      expect(metrics.subheaderOneTop, 322);
      expect(metrics.zone2Top, 405);
      expect(metrics.railTop, 643);
      expect(metrics.logBoxHeaderHeight, 122);
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
      expect(balance.actionBounds, budget.actionBounds);
      expect(balance.actionBounds, mind.actionBounds);
      expect(balance.summaryBounds, budget.summaryBounds);
      expect(balance.summaryBounds, mind.summaryBounds);
      expect(balance.railBounds, budget.railBounds);
      expect(balance.railBounds, mind.railBounds);

      for (final mode in DashboardModeSpec.values) {
        final collapsed = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: mode,
          collapseProgress: DashboardLayoutMetrics.reference.collapseTravel,
          isRailExpanded: false,
        );
        expect(collapsed.headerBounds.height, 104);
        expect(collapsed.actionBounds.top, 219);
        expect(collapsed.summaryBounds.top, 282);
        expect(collapsed.railBounds.top, 352);
      }
    });

    for (final mode in DashboardModeSpec.values) {
      test('${mode.mode.name} keeps action and summary upstream of Zone2', () {
        final baseline = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: mode,
          collapseProgress: 0,
          isRailExpanded: false,
        );
        final taller = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference.copyWith(
            zone2CardHeight: 240,
          ),
          mode: mode,
          collapseProgress: 0,
          isRailExpanded: false,
        );

        expect(taller.actionBounds.top, baseline.actionBounds.top);
        expect(taller.summaryBounds.top, baseline.summaryBounds.top);
        expect(taller.subheaderOneBounds.top, baseline.subheaderOneBounds.top);
        expect(taller.zone2Bounds.top, baseline.zone2Bounds.top);
        expect(taller.railBounds.top, baseline.railBounds.top + 23);
        expect(
          taller.collapseHandleBounds.top,
          baseline.collapseHandleBounds.top + 23,
        );
        expect(
          taller.logBoxHeaderBounds.top,
          baseline.logBoxHeaderBounds.top + 23,
        );
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
      expect(frame.collapseHandleBounds.top, 410);
      expect(frame.subheaderOneOpacity, 0);
      expect(frame.zone2Opacity, 0);
      expect(frame.subheaderOneShift, -214);
      expect(frame.subheaderOneScale, closeTo(.90, .001));
      expect(frame.zone2Shift, -257);
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
      expect(frame.lowerCardMotion!.top, greaterThan(324));
      expect(frame.lowerCardMotion!.top, lessThan(457));
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
      expect(frame.collapseHandleBounds.top, 410);
    });

    test(
      'derives one header expansion reveal from the existing collapse owner',
      () {
        final dynamic expanded = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.budget,
          collapseProgress: 0,
          isRailExpanded: false,
        );
        final dynamic collapsed = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.budget,
          collapseProgress: DashboardLayoutMetrics.reference.collapseTravel,
          isRailExpanded: false,
        );

        expect(expanded.headerExpansionProgress, 1);
        expect(collapsed.headerExpansionProgress, 0);
      },
    );
  });
}
