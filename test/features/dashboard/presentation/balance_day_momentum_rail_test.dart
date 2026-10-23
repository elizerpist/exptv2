import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_identity.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_momentum_rail.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_day_rhythm_navigation.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_temporal_component_carousel.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import '../../../support/test_pump.dart';
import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);
  Future<void> frames(WidgetTester tester, [int count = 60]) async {
    for (var i = 0; i < (count > 20 ? 12 : count); i++) {
      await tester.pump(Duration(milliseconds: count > 20 ? 160 : 16));
    }
  }

  Future<_Harness> setup(WidgetTester tester) async {
    final h = _Harness();
    await h.core.bootstrap();
    addTearDown(h.core.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 320,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (_) => h.verticalUpdates++,
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    SizedBox(
                      key: const ValueKey('rail-bounds'),
                      height: 130,
                      child: BalanceDayMomentumRail(
                        presentation: h.presentation,
                        navigation: h.bridge,
                      ),
                    ),
                    const Expanded(child: SizedBox.expand()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await frames(tester, 3);
    return h;
  }

  Future<DashboardCoreController> setupReal(WidgetTester tester) async {
    final core = DashboardCoreController(
      initialCoreRevision: 1,
      initialDate: DateTime(2026, 7, 16),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
    );
    final modes = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(core.dispose);
    addTearDown(modes.dispose);
    await core.bootstrap();
    await pumpDashboardSurface(
      tester,
      CoreDashboard(
        controller: core,
        modeController: modes,
        categoryCollection: emptyTestCategoryCollection,
      ),
    );
    await frames(tester, 4);
    final tuner = tester.widget<DashboardHeaderVisualTuner>(
      find.byType(DashboardHeaderVisualTuner),
    );
    tuner.balancePresentationSettings!.setDayLayoutPresentation(
      BalanceDayLayoutPresentation.focused,
    );
    await frames(tester, 6);
    expect(
      find.byKey(const ValueKey('balance-day-rhythm-carousel')),
      findsOneWidget,
    );
    return core;
  }

  BalanceDayMomentumRailPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.byKey(const ValueKey('balance-day-rhythm-bars')),
              )
              .painter!
          as BalanceDayMomentumRailPainter;

  testWidgets(
    'real CoreDashboard host owns vertical rail drags without day navigation',
    (tester) async {
      final core = await setupReal(tester);
      final rail = find.byKey(const ValueKey('balance-day-rhythm-carousel'));
      expect(rail, findsOneWidget);
      final day = core.navigation.state.dayCursor;
      final before = core.expansion.progress;
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(0, -25));
      await frames(tester, 1);
      await gesture.moveBy(const Offset(0, -70));
      await frames(tester, 2);
      expect(core.navigation.state.dayCursor, day);
      expect(core.expansion.isDragging, isTrue);
      expect(core.expansion.progress, greaterThan(before));
      await gesture.up();
      await frames(tester, 8);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester, 2);
    },
  );
  testWidgets(
    'Core acceptance bridge owns slow horizontal day tick and fractional paint',
    (tester) async {
      final core = await setupReal(tester);
      final rail = find.byKey(const ValueKey('balance-day-rhythm-carousel'));
      final before = core.navigation.state.dayCursor;
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(-25, 0));
      await frames(tester, 1);
      final pitch = tester.getSize(rail).width / 60;
      await gesture.moveBy(Offset(-1.25 * pitch, 0));
      await frames(tester, 2);
      expect(painter(tester).rawOffset, isNot(0));
      expect(painter(tester).rawOffset % 1, isNot(closeTo(0, .001)));
      await gesture.up();
      for (
        var i = 0;
        i < 40 && core.navigation.state.dayCursor == before;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      expect(
        core.navigation.state.dayCursor,
        before + 1,
        reason:
            'A slow 1.25-slot drag must commit exactly one DAY target through the actual LogBox scene',
      );
      await frames(tester, 2);
      final committed = core.navigation.state.dayCursor;
      final summary = tester.widget<DashboardTemporalComponentCarousel>(
        find.byKey(const ValueKey('summary-pill-segmented-day-selector')),
      );
      expect(summary.labelForCandidate(summary.navigation.state), '$committed');
      expect(summary.navigation.state.dayCursor, committed);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('summary-pill-segmented-day-selector')),
          matching: find.text('$committed'),
        ),
        findsOneWidget,
      );
      final visible = core.visibleFrames.value!;
      expect(visible.scope.timeScope, isA<DayScope>());
      expect((visible.scope.timeScope as DayScope).date.day, committed);
      final financialRail = tester.widget<BalanceDayMomentumRail>(
        find.byKey(const ValueKey('balance-day-momentum-rail')),
      );
      expect(financialRail.presentation.timeScope, isA<DayScope>());
      expect(
        (financialRail.presentation.timeScope as DayScope).date.day,
        committed,
      );
      expect(core.expansion.isDragging, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester, 2);
    },
  );
  testWidgets(
    'unmounting a held rhythm rail releases its sole Core motion lane',
    (tester) async {
      final core = await setupReal(tester);
      final rail = find.byKey(const ValueKey('balance-day-rhythm-carousel'));
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(-25, 0));
      await frames(tester, 1);
      await gesture.moveBy(const Offset(-10, 0));
      await frames(tester, 2);
      expect(core.isMotionLaneActive(DashboardMotionLane.summaryShell), isTrue);
      final tuner = tester.widget<DashboardHeaderVisualTuner>(
        find.byType(DashboardHeaderVisualTuner),
      );
      tuner.balancePresentationSettings!.setDayLayoutPresentation(
        BalanceDayLayoutPresentation.current,
      );
      await frames(tester, 3);
      expect(
        find.byKey(const ValueKey('balance-day-rhythm-carousel')),
        findsNothing,
      );
      expect(
        core.isMotionLaneActive(DashboardMotionLane.summaryShell),
        isFalse,
      );
      final day = core.navigation.state.dayCursor;
      await gesture.up();
      await frames(tester, 8);
      expect(core.navigation.state.dayCursor, day);
      expect(
        core.isMotionLaneActive(DashboardMotionLane.summaryShell),
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester, 2);
    },
  );

  testWidgets(
    'fast rail motion interrupted and reversed cannot settle stale flight',
    (tester) async {
      final h = await setup(tester);
      final rail = find.byKey(const ValueKey('rail-bounds'));
      expect(
        painter(tester).points.map((point) => point.epochDay).toSet(),
        hasLength(60),
      );
      for (final point in painter(tester).points) {
        expect(point.currentIncomeMinor, point.epochDay.abs() * 100);
      }
      await tester.fling(rail, const Offset(-100, 0), 1600);
      await frames(tester, 3);
      final g = await tester.startGesture(tester.getCenter(rail));
      await g.moveBy(const Offset(35, 0));
      await frames(tester, 2);
      await g.moveBy(const Offset(12, 0));
      await g.up();
      await frames(tester, 100);
      expect(h.crossings.length, greaterThan(1));
      expect(h.accepted, greaterThan(0));
      expect(h.verticalUpdates, 0);
      final finalDay = h.core.navigation.state.dayCursor;
      await frames(tester, 50);
      expect(h.core.navigation.state.dayCursor, finalDay);
    },
  );
  testWidgets('vertical, diagonal and outside rail obey one gesture owner', (
    tester,
  ) async {
    final h = await setup(tester);
    final rail = find.byKey(const ValueKey('rail-bounds'));
    final day = h.core.navigation.state.dayCursor;
    await tester.drag(rail, const Offset(0, -60));
    await frames(tester, 5);
    await tester.drag(rail, const Offset(0, 60));
    await frames(tester, 5);
    expect(h.verticalUpdates, greaterThan(0));
    expect(h.core.navigation.state.dayCursor, day);
    expect(h.crossings, isEmpty);
    final bounds = tester.getRect(rail);
    await tester.dragFrom(
      Offset(bounds.center.dx, bounds.bottom + 35),
      const Offset(-80, 0),
    );
    await frames(tester, 5);
    expect(h.crossings, isEmpty);
    expect(h.core.navigation.state.dayCursor, day);
    final verticalBefore = h.verticalUpdates;
    await tester.drag(rail, const Offset(-55, -8));
    await frames(tester, 50);
    expect(h.verticalUpdates, verticalBefore);
    expect(h.accepted, greaterThan(0));
  });
}

class _Harness {
  final core = DashboardCoreController(
    initialCoreRevision: 1,
    initialDate: DateTime(2026, 7, 16),
    initialPlane: TimePlane.month,
    initialRailOpen: true,
  );
  int verticalUpdates = 0, accepted = 0;
  final crossings = <DashboardNavigationState>[];
  DashboardDayRhythmNavigation get bridge => DashboardDayRhythmNavigation(
    navigation: core.navigation,
    candidateForOffset: (origin, offset) =>
        core.experimentalTemporalComponentOffsetCandidate(
          plane: origin.plane,
          isRailOpen: origin.isRailOpen,
          component: DashboardTemporalAnchorComponent.day,
          offset: offset,
          base: origin,
        ),
    onCrossed: (candidate) {
      crossings.add(candidate);
      final result = core.navigateExperimentalTemporalComponentCandidate(
        candidate: candidate,
        component: DashboardTemporalAnchorComponent.day,
      );
      if (result.isAcceptedSemanticIntent) accepted++;
      return result;
    },
    paintedTargets: core.segmentedTargetPainted,
    onVisualTargetPainted: (candidate) =>
        core.noteSegmentedSummaryComponentVisualTargetPainted(
          candidate: candidate,
          component: DashboardTemporalAnchorComponent.day,
        ),
    onSettled: (candidate) => core.settleExperimentalTemporalComponentCandidate(
      candidate: candidate,
      component: DashboardTemporalAnchorComponent.day,
    ),
    onMotionActiveChanged: (active) {
      if (active) {
        core.beginSegmentedSummaryMotion();
      } else {
        core.endSegmentedSummaryMotion();
      }
    },
    onDirectInputStarted: core.noteSummaryDirectPointerDown,
    onPointerDownDecision: core.recordSegmentedPointerDown,
  );
  DashboardBalanceDailyInsightsPresentation get presentation {
    final selected = const LocalDate(year: 2026, month: 7, day: 16).epochDay;
    DashboardBalanceDailyMomentumPoint point(int day) =>
        DashboardBalanceDailyMomentumPoint(
          epochDay: day,
          currentIncomeMinor: day.abs() * 100,
          referenceIncomeMinor: 100,
          currentExpenseMinor: 200,
          referenceExpenseMinor: 250,
          isCurrentHalf: day > selected - 30,
          incomeAxis: .2,
          expenseAxis: -.3,
          magnitude: .4,
        );
    return DashboardBalanceDailyInsightsPresentation(
      identity: const DashboardBalancePrimaryIdentity(
        upstreamScopeKey: 'all',
        indexGeneration: 1,
        coreRevision: 1,
      ),
      timeScope: DayScope(const LocalDate(year: 2026, month: 7, day: 16)),
      momentum: DashboardBalanceDailyMomentumPresentation(
        available: true,
        selected: point(selected),
        rhythm: [for (var i = 59; i >= 0; i--) point(selected - i)],
      ),
      impact: DashboardBalanceDailyImpactPresentation.unavailable(
        todayNetMinor: 0,
        referenceAverageNetMinor: 0,
      ),
    );
  }
}
