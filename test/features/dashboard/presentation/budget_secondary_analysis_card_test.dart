import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/financial_limits/presentation/budget_ring_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_secondary_analysis.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_content_title_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_secondary_analysis_card.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required DashboardBudgetSecondaryAnalysisPayload payload,
    required LedgerTimeScope scope,
    required String scopeLabel,
    double width = 390,
    double textScale = 1,
    bool useCard2OuterClip = false,
    BudgetRingPresentationController? ringPresentation,
  }) {
    final analysis = BudgetSecondaryAnalysisPreparedCard(
      frame: DashboardBudgetSecondaryAnalysisFrame(
        coreRevision: 17,
        direction: LedgerDirection.expense,
        targetHandle: 1,
        scope: scope,
        payload: payload,
      ),
      targetTitle: 'Élelmiszer',
      scopeLabel: scopeLabel,
    );
    final surface = useCard2OuterClip
        ? BudgetDistributionCardShell(child: analysis)
        : DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: analysis,
          );
    return tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 220,
                child: RepaintBoundary(
                  key: const ValueKey<String>(
                    'budget-analysis-golden-boundary',
                  ),
                  child: ringPresentation == null
                      ? surface
                      : BudgetRingPresentationScope(
                          controller: ringPresentation,
                          child: surface,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Rect trackBounds(WidgetTester tester) {
    final materialBounds = tester.getRect(
      find.byType(BudgetSemicircleMaterial),
    );
    final geometry = BudgetSemicircleMaterialGeometry.resolve(
      materialBounds.size,
      layout: BudgetSemicircleMaterialLayout.sumHero,
    );
    return geometry.trackRect.shift(materialBounds.topLeft);
  }

  testWidgets('SUM mounts exactly one direction-aware clay semicircle', (
    tester,
  ) async {
    await pump(
      tester,
      scope: const AllTimeScope(),
      scopeLabel: 'Összesen',
      payload: const DashboardBudgetSumAnalysis(
        availability: BudgetAnalysisAvailability.available,
        averageUtilization: 1.08,
        averageBudgetDeltaScaled100: -84000,
        eligibleMonthCount: 12,
        monthsWithinBudget: 8,
        utilizationStandardDeviation: .12,
      ),
    );

    expect(
      find.byKey(const ValueKey('budget-analysis-sum-semicircle')),
      findsOneWidget,
    );
    expect(find.byType(BudgetSemicircleGauge), findsOneWidget);
    final page = tester.getRect(
      find.byKey(const ValueKey<String>('budget-analysis-golden-boundary')),
    );
    final title = tester.getRect(
      find.byKey(const ValueKey<String>('budget-secondary-analysis-title-row')),
    );
    expect(
      title.top,
      closeTo(page.top + BudgetContentTitleLayout.topInset, .01),
    );
    expect(
      find.byKey(const ValueKey('budget-analysis-year-zero-axis-bars')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('budget-analysis-golden-boundary')),
      matchesGoldenFile('../../../goldens/budget_analysis_sum.png'),
    );
  });

  testWidgets(
    'SUM and MONTH retain canonical track and endpoint geometry when KPI cards hide',
    (tester) async {
      final ringPresentation = BudgetRingPresentationController();
      addTearDown(ringPresentation.dispose);

      Future<void> expectStableViewport({
        required DashboardBudgetSecondaryAnalysisPayload payload,
        required LedgerTimeScope scope,
        required String scopeLabel,
      }) async {
        ringPresentation.setBudgetAnalysisInfoCardsVisible(true);
        await pump(
          tester,
          scope: scope,
          scopeLabel: scopeLabel,
          payload: payload,
          ringPresentation: ringPresentation,
        );
        final on = trackBounds(tester);
        final leftOn = tester.getRect(
          find.byKey(const ValueKey<String>('budget-semicircle-left-endpoint')),
        );
        final rightOn = tester.getRect(
          find.byKey(
            const ValueKey<String>('budget-semicircle-right-endpoint'),
          ),
        );

        ringPresentation.setBudgetAnalysisInfoCardsVisible(false);
        await tester.pump();
        final off = trackBounds(tester);
        final leftOff = tester.getRect(
          find.byKey(const ValueKey<String>('budget-semicircle-left-endpoint')),
        );
        final rightOff = tester.getRect(
          find.byKey(
            const ValueKey<String>('budget-semicircle-right-endpoint'),
          ),
        );

        expect(off.left, closeTo(on.left, .01));
        expect(off.top, closeTo(on.top, .01));
        expect(off.right, closeTo(on.right, .01));
        expect(off.bottom, closeTo(on.bottom, .01));
        // The keyed Positioned origins are the real arc endpoints; the
        // child is paint-translated by half its own width around that origin.
        expect(leftOff.left, closeTo(off.left, .5));
        expect(rightOff.left, closeTo(off.right, .5));
        expect(leftOff.top, greaterThan(off.center.dy));
        expect(rightOff.top, greaterThan(off.center.dy));
        expect(leftOff.left, closeTo(leftOn.left, .01));
        expect(rightOff.left, closeTo(rightOn.left, .01));
        expect(
          tester.widget<Text>(find.text('0%')).style!.fontSize,
          greaterThan(6.5),
        );
        expect(
          find.byKey(const ValueKey<String>('budget-analysis-endpoint-lane')),
          findsOneWidget,
          reason:
              'Hidden cards leave a structural breathing lane, not extra hero height.',
        );
      }

      await expectStableViewport(
        scope: const AllTimeScope(),
        scopeLabel: 'Összesen',
        payload: const DashboardBudgetSumAnalysis(
          availability: BudgetAnalysisAvailability.available,
          averageUtilization: .39,
          averageBudgetDeltaScaled100: -84000,
          eligibleMonthCount: 12,
          monthsWithinBudget: 8,
          utilizationStandardDeviation: .12,
        ),
      );
      await expectStableViewport(
        scope: const MonthScope(YearMonth(year: 2026, month: 3)),
        scopeLabel: '2026. március',
        payload: const DashboardBudgetMonthSecondaryAnalysis(
          availability: BudgetAnalysisAvailability.available,
          daysInMonth: 31,
          elapsedCalendarDays: 18,
          monthActualScaled100: 29000000,
          monthlyLimitScaled100: 39000000,
          elapsedRatio: 18 / 31,
          budgetUsedRatio: 290 / 390,
          paceDifferencePercentagePoints: 16.3,
          projectedMonthEndScaled100: 49944444,
          expectedDeltaScaled100: 10944444,
          closingBudgetDeltaScaled100: null,
          remainingDailyRoomScaled100: 769231,
          historicalDailyAverageScaled100: null,
          usesForecast: true,
        ),
      );
    },
  );

  testWidgets(
    'SUM shared white surface stays continuous at 39, 100 and 225 percent',
    (tester) async {
      for (final sample in <({double ratio, String goldenName})>[
        (ratio: .39, goldenName: '039'),
        (ratio: 1, goldenName: '100'),
        (ratio: 2.25, goldenName: '225'),
      ]) {
        await pump(
          tester,
          scope: const AllTimeScope(),
          scopeLabel: 'Összesen',
          useCard2OuterClip: true,
          payload: DashboardBudgetSumAnalysis(
            availability: BudgetAnalysisAvailability.available,
            averageUtilization: sample.ratio,
            averageBudgetDeltaScaled100: -84000,
            eligibleMonthCount: 12,
            monthsWithinBudget: 8,
            utilizationStandardDeviation: .12,
          ),
        );

        // The golden includes the physical Card2 clip. The shared white
        // interior must remain continuous while the individual KPI cards stay
        // foreground at the bottom of the same surface.
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('budget-analysis-golden-boundary')),
          matchesGoldenFile(
            '../../../goldens/budget_analysis_sum_underlay_${sample.goldenName}.png',
          ),
        );
      }
    },
  );

  testWidgets(
    'SUM uses the shared material and supports every decorative-strip combination',
    (tester) async {
      final ringPresentation = BudgetRingPresentationController();
      addTearDown(ringPresentation.dispose);
      const payload = DashboardBudgetSumAnalysis(
        availability: BudgetAnalysisAvailability.available,
        averageUtilization: .39,
        averageBudgetDeltaScaled100: -84000,
        eligibleMonthCount: 12,
        monthsWithinBudget: 8,
        utilizationStandardDeviation: .12,
      );

      await pump(
        tester,
        scope: const AllTimeScope(),
        scopeLabel: 'Összesen',
        payload: payload,
        useCard2OuterClip: true,
        ringPresentation: ringPresentation,
      );
      for (final setting in <({String name, bool neutral, bool active})>[
        (name: 'neutral_on_active_on', neutral: true, active: true),
        (name: 'neutral_on_active_off', neutral: true, active: false),
        (name: 'neutral_off_active_on', neutral: false, active: true),
        (name: 'neutral_off_active_off', neutral: false, active: false),
      ]) {
        ringPresentation
          ..setBudgetNeutralDecorativeStripVisible(setting.neutral)
          ..setBudgetActiveProgressDecorativeStripVisible(setting.active);
        await tester.pump();

        final material = tester.widget<BudgetSemicircleMaterial>(
          find.byType(BudgetSemicircleMaterial),
        );
        expect(
          find.byType(BudgetSemicircleMaterialPreferences),
          findsOneWidget,
        );
        expect(material.layout, BudgetSemicircleMaterialLayout.sumHero);
        expect(material.showMarker, isTrue);
        expect(material.showNeutralDecorativeStrip, setting.neutral);
        expect(material.showActiveProgressDecorativeStrip, setting.active);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('budget-analysis-golden-boundary')),
          matchesGoldenFile(
            '../../../goldens/budget_analysis_sum_strips_${setting.name}_039.png',
          ),
        );
      }
    },
  );

  testWidgets(
    'SUM and MONTH hide only the neutral track while retaining active geometry',
    (tester) async {
      final ringPresentation = BudgetRingPresentationController();
      addTearDown(ringPresentation.dispose);
      final samples =
          <
            ({
              DashboardBudgetSecondaryAnalysisPayload payload,
              LedgerTimeScope scope,
              String scopeLabel,
              String goldenName,
            })
          >[
            (
              payload: const DashboardBudgetSumAnalysis(
                availability: BudgetAnalysisAvailability.available,
                averageUtilization: .39,
                averageBudgetDeltaScaled100: -84000,
                eligibleMonthCount: 12,
                monthsWithinBudget: 8,
                utilizationStandardDeviation: .12,
              ),
              scope: const AllTimeScope(),
              scopeLabel: 'Összesen',
              goldenName: 'sum',
            ),
            (
              payload: const DashboardBudgetMonthSecondaryAnalysis(
                availability: BudgetAnalysisAvailability.available,
                daysInMonth: 31,
                elapsedCalendarDays: 18,
                monthActualScaled100: 29000000,
                monthlyLimitScaled100: 39000000,
                elapsedRatio: 18 / 31,
                budgetUsedRatio: 290 / 390,
                paceDifferencePercentagePoints: 16.3,
                projectedMonthEndScaled100: 49944444,
                expectedDeltaScaled100: 10944444,
                closingBudgetDeltaScaled100: null,
                remainingDailyRoomScaled100: 769231,
                historicalDailyAverageScaled100: null,
                usesForecast: true,
              ),
              scope: const MonthScope(YearMonth(year: 2026, month: 3)),
              scopeLabel: '2026. március',
              goldenName: 'month',
            ),
          ];

      for (final sample in samples) {
        ringPresentation.setBudgetNeutralTrackVisible(true);
        await pump(
          tester,
          payload: sample.payload,
          scope: sample.scope,
          scopeLabel: sample.scopeLabel,
          useCard2OuterClip: true,
          ringPresentation: ringPresentation,
        );
        final on = tester.widget<BudgetSemicircleMaterial>(
          find.byType(BudgetSemicircleMaterial),
        );
        final onBounds = trackBounds(tester);

        ringPresentation.setBudgetNeutralTrackVisible(false);
        await tester.pump();
        final off = tester.widget<BudgetSemicircleMaterial>(
          find.byType(BudgetSemicircleMaterial),
        );
        final offBounds = trackBounds(tester);
        expect(on.showNeutralTrack, isTrue);
        expect(off.showNeutralTrack, isFalse);
        expect(off.showNeutralDecorativeStrip, on.showNeutralDecorativeStrip);
        expect(
          off.showActiveProgressDecorativeStrip,
          on.showActiveProgressDecorativeStrip,
        );
        expect(off.progress, on.progress);
        expect(offBounds, onBounds);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('budget-analysis-golden-boundary')),
          matchesGoldenFile(
            '../../../goldens/budget_analysis_neutral_track_off_${sample.goldenName}.png',
          ),
        );
      }
    },
  );

  test('YEAR clay material shares Budget semantic families', () {
    final withGloss = BudgetYearClayDeltaMaterial.resolve(
      showNeutralDecorativeStrip: true,
      showActiveProgressDecorativeStrip: true,
    );
    final withoutGloss = BudgetYearClayDeltaMaterial.resolve(
      showNeutralDecorativeStrip: false,
      showActiveProgressDecorativeStrip: false,
    );

    expect(
      withGloss.overspend.colors[1],
      FluviVisualTokens.budgetProgressDanger,
    );
    expect(
      withGloss.reserve.colors[1],
      FluviVisualTokens.budgetProgressHealthy,
    );
    expect(withGloss.overspend.depthColors, hasLength(3));
    expect(withGloss.reserve.depthColors, hasLength(3));
    expect(withGloss.showNeutralDecorativeStrip, isTrue);
    expect(withGloss.showActiveProgressDecorativeStrip, isTrue);
    expect(withoutGloss.showNeutralDecorativeStrip, isFalse);
    expect(withoutGloss.showActiveProgressDecorativeStrip, isFalse);
    expect(withGloss.sameVisualAs(withoutGloss), isFalse);
  });

  test('YEAR preserves red-up, green-down and completed-zero semantics', () {
    expect(
      BudgetYearClayDeltaKindResolver.resolve(_yearMonth(month: 1, delta: -1)),
      BudgetYearClayDeltaKind.overspend,
    );
    expect(
      BudgetYearClayDeltaKindResolver.resolve(_yearMonth(month: 2, delta: 1)),
      BudgetYearClayDeltaKind.reserve,
    );
    expect(
      BudgetYearClayDeltaKindResolver.resolve(_yearMonth(month: 3, delta: 0)),
      BudgetYearClayDeltaKind.exactZero,
    );
    expect(
      BudgetYearClayDeltaKindResolver.resolve(_futureYearMonth(4)),
      BudgetYearClayDeltaKind.future,
    );
  });

  testWidgets(
    'YEAR mounts instant red-up green-down clay capsules with independent rail and bar gloss',
    (tester) async {
      final ringPresentation = BudgetRingPresentationController();
      addTearDown(ringPresentation.dispose);
      final payload = DashboardBudgetYearAnalysis(
        availability: BudgetAnalysisAvailability.available,
        months: <DashboardBudgetYearMonthAnalysis>[
          _yearMonth(month: 1, delta: 32000),
          _yearMonth(month: 2, delta: -18000),
          _yearMonth(month: 3, delta: -46000),
          _yearMonth(month: 4, delta: 24000),
          _yearMonth(month: 5, delta: 12000),
          _yearMonth(month: 6, delta: -28000),
          _yearMonth(month: 7, delta: -9000),
          _yearMonth(month: 8, delta: 39000),
          _yearMonth(month: 9, delta: 0),
          _futureYearMonth(10),
          _futureYearMonth(11),
          _futureYearMonth(12),
        ],
        completedEligibleMonthCount: 9,
        completedWithinBudgetCount: 5,
        largestOverspendScaled100: 46000,
        largestReserveScaled100: 39000,
      );
      await pump(
        tester,
        scope: const YearScope(2026),
        scopeLabel: '2026',
        payload: payload,
        ringPresentation: ringPresentation,
      );

      expect(
        find.byKey(const ValueKey('budget-analysis-year-zero-axis-bars')),
        findsOneWidget,
      );
      expect(find.text('JAN'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('budget-analysis-golden-boundary')),
        matchesGoldenFile(
          '../../../goldens/budget_analysis_year_clay_strips_on.png',
        ),
      );

      ringPresentation.setBudgetNeutralTrackVisible(false);
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey('budget-analysis-golden-boundary')),
        matchesGoldenFile(
          '../../../goldens/budget_analysis_year_clay_strips_on.png',
        ),
        reason:
            'The SUM/MONTH-only neutral-track control cannot hide YEAR rail.',
      );

      ringPresentation
        ..setBudgetNeutralDecorativeStripVisible(false)
        ..setBudgetActiveProgressDecorativeStripVisible(false);
      await tester.pump();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('budget-analysis-golden-boundary')),
        matchesGoldenFile(
          '../../../goldens/budget_analysis_year_clay_strips_off.png',
        ),
      );
    },
  );

  testWidgets(
    'MONTH uses the one SUM-parity shared material hero for every strip combination',
    (tester) async {
      final ringPresentation = BudgetRingPresentationController();
      addTearDown(ringPresentation.dispose);
      await pump(
        tester,
        scope: const MonthScope(YearMonth(year: 2026, month: 3)),
        scopeLabel: '2026. március',
        payload: const DashboardBudgetMonthSecondaryAnalysis(
          availability: BudgetAnalysisAvailability.available,
          daysInMonth: 31,
          elapsedCalendarDays: 18,
          monthActualScaled100: 29000000,
          monthlyLimitScaled100: 39000000,
          elapsedRatio: 18 / 31,
          budgetUsedRatio: 290 / 390,
          paceDifferencePercentagePoints: 16.3,
          projectedMonthEndScaled100: 49944444,
          expectedDeltaScaled100: 10944444,
          closingBudgetDeltaScaled100: null,
          remainingDailyRoomScaled100: 769231,
          historicalDailyAverageScaled100: null,
          usesForecast: true,
        ),
        ringPresentation: ringPresentation,
      );

      expect(
        find.byKey(const ValueKey('budget-analysis-month-semicircle')),
        findsOneWidget,
      );
      for (final setting in <({String name, bool neutral, bool active})>[
        (name: 'neutral_on_active_on', neutral: true, active: true),
        (name: 'neutral_on_active_off', neutral: true, active: false),
        (name: 'neutral_off_active_on', neutral: false, active: true),
        (name: 'neutral_off_active_off', neutral: false, active: false),
      ]) {
        ringPresentation
          ..setBudgetNeutralDecorativeStripVisible(setting.neutral)
          ..setBudgetActiveProgressDecorativeStripVisible(setting.active);
        await tester.pump();

        final materials = tester
            .widgetList<BudgetSemicircleMaterial>(
              find.byType(BudgetSemicircleMaterial),
            )
            .toList(growable: false);
        expect(
          find.byType(BudgetSemicircleMaterialPreferences),
          findsOneWidget,
        );
        expect(materials, hasLength(1));
        for (var index = 0; index < materials.length; index += 1) {
          final material = materials[index];
          expect(material.layout, BudgetSemicircleMaterialLayout.sumHero);
          expect(material.showMarker, isTrue);
          expect(material.showNeutralDecorativeStrip, setting.neutral);
          expect(material.showActiveProgressDecorativeStrip, setting.active);
        }
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('budget-analysis-golden-boundary')),
          matchesGoldenFile(
            '../../../goldens/budget_analysis_month_strips_${setting.name}.png',
          ),
        );
      }
    },
  );

  testWidgets('MONTH budget over target keeps the shared continuous material', (
    tester,
  ) async {
    await pump(
      tester,
      scope: const MonthScope(YearMonth(year: 2026, month: 3)),
      scopeLabel: '2026. március',
      payload: const DashboardBudgetMonthSecondaryAnalysis(
        availability: BudgetAnalysisAvailability.available,
        daysInMonth: 31,
        elapsedCalendarDays: 18,
        monthActualScaled100: 44850000,
        monthlyLimitScaled100: 39000000,
        elapsedRatio: 18 / 31,
        budgetUsedRatio: 1.15,
        paceDifferencePercentagePoints: 57.0,
        projectedMonthEndScaled100: 65000000,
        expectedDeltaScaled100: 26000000,
        closingBudgetDeltaScaled100: null,
        remainingDailyRoomScaled100: -1200000,
        historicalDailyAverageScaled100: null,
        usesForecast: true,
      ),
    );

    final materials = tester
        .widgetList<BudgetSemicircleMaterial>(
          find.byType(BudgetSemicircleMaterial),
        )
        .toList(growable: false);
    expect(materials, hasLength(1));
    final used = materials.single;
    expect(used.showMarker, isTrue);
    expect(used.presentation.health, BudgetClayGaugeHealth.expenseDanger);
    expect(used.presentation.progressStops, hasLength(7));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('budget-analysis-golden-boundary')),
      matchesGoldenFile('../../../goldens/budget_analysis_month_over_115.png'),
    );
  });

  testWidgets(
    'DAY mounts two native clay comparison cards, one arrow and one impact band',
    (tester) async {
      await pump(
        tester,
        scope: const DayScope(LocalDate(year: 2026, month: 3, day: 18)),
        scopeLabel: '2026. március 18.',
        payload: const DashboardBudgetDaySecondaryAnalysis(
          availability: BudgetAnalysisAvailability.available,
          selectedDayActualScaled100: 620000,
          spentBeforeSelectedDayScaled100: 18800000,
          dailyRoomBeforeScaled100: 2363000,
          dailyRoomAfterScaled100: 2499500,
          dailyRoomChangeScaled100: 136500,
          remainingSpendableTodayScaled100: 505000,
          monthlyDeltaScaled100: 2840000,
          usesForecast: true,
          isTerminalDay: false,
        ),
      );

      expect(find.text('Reggel még\nelérhető volt'), findsOneWidget);
      expect(find.text('Mostantól\nelérhető'), findsOneWidget);
      expect(find.text('23630 Ft'), findsOneWidget);
      expect(find.text('24995 Ft'), findsOneWidget);
      expect(find.text('+1365 Ft / nap'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('budget-analysis-day-before-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('budget-analysis-day-after-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('budget-analysis-day-arrow')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(
        find.byKey(const ValueKey('budget-analysis-day-impact-band')),
        findsOneWidget,
      );
      expect(find.byType(BudgetSemicircleGauge), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('budget-analysis-golden-boundary')),
        matchesGoldenFile(
          '../../../goldens/budget_analysis_day_clay_positive.png',
        ),
      );
    },
  );

  testWidgets('DAY terminal state keeps the after clay card mounted', (
    tester,
  ) async {
    await pump(
      tester,
      scope: const DayScope(LocalDate(year: 2026, month: 3, day: 31)),
      scopeLabel: '2026. március 31.',
      payload: const DashboardBudgetDaySecondaryAnalysis(
        availability: BudgetAnalysisAvailability.available,
        selectedDayActualScaled100: 620000,
        spentBeforeSelectedDayScaled100: 18800000,
        dailyRoomBeforeScaled100: 2363000,
        dailyRoomAfterScaled100: null,
        dailyRoomChangeScaled100: null,
        remainingSpendableTodayScaled100: 0,
        monthlyDeltaScaled100: 2840000,
        usesForecast: false,
        isTerminalDay: true,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('budget-analysis-day-before-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('budget-analysis-day-after-card')),
      findsOneWidget,
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Ma zárul a hónap'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('budget-analysis-golden-boundary')),
      matchesGoldenFile(
        '../../../goldens/budget_analysis_day_clay_terminal.png',
      ),
    );
  });

  testWidgets('DAY clay cards retain parent popup tap when info cards hide', (
    tester,
  ) async {
    final ringPresentation = BudgetRingPresentationController();
    addTearDown(ringPresentation.dispose);
    await pump(
      tester,
      scope: const DayScope(LocalDate(year: 2026, month: 3, day: 18)),
      scopeLabel: '2026. március 18.',
      ringPresentation: ringPresentation,
      payload: const DashboardBudgetDaySecondaryAnalysis(
        availability: BudgetAnalysisAvailability.available,
        selectedDayActualScaled100: 620000,
        spentBeforeSelectedDayScaled100: 18800000,
        dailyRoomBeforeScaled100: 2363000,
        dailyRoomAfterScaled100: 2499500,
        dailyRoomChangeScaled100: 136500,
        remainingSpendableTodayScaled100: 505000,
        monthlyDeltaScaled100: 2840000,
        usesForecast: true,
        isTerminalDay: false,
      ),
    );

    final before = tester.getRect(
      find.byKey(const ValueKey<String>('budget-analysis-day-before-card')),
    );
    final after = tester.getRect(
      find.byKey(const ValueKey<String>('budget-analysis-day-after-card')),
    );
    final placement = tester.getRect(
      find.byKey(
        const ValueKey<String>('budget-analysis-day-comparison-placement'),
      ),
    );
    expect(before.width, closeTo(after.width, .01));
    expect(before.height, closeTo(after.height, .01));
    expect(before.height, lessThan(placement.height));
    expect(
      find.byKey(const ValueKey<String>('budget-analysis-kpi-row')),
      findsOneWidget,
    );

    ringPresentation.setBudgetAnalysisInfoCardsVisible(false);
    await tester.pump();

    final hiddenBefore = tester.getRect(
      find.byKey(const ValueKey<String>('budget-analysis-day-before-card')),
    );
    final hiddenAfter = tester.getRect(
      find.byKey(const ValueKey<String>('budget-analysis-day-after-card')),
    );
    expect(hiddenBefore, before);
    expect(hiddenAfter, after);
    expect(
      find.byKey(const ValueKey<String>('budget-analysis-kpi-row')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('budget-analysis-golden-boundary')),
      matchesGoldenFile('../../../goldens/budget_analysis_day_clay_hidden.png'),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('budget-analysis-day-before-card')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('budget-analysis-kpi-popup')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('budget-analysis-day-before-card')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('budget-analysis-kpi-popup')),
      findsNothing,
    );
  });

  testWidgets('DAY clay cards fit a compact width and elevated text scale', (
    tester,
  ) async {
    await pump(
      tester,
      width: 300,
      textScale: 1.25,
      scope: const DayScope(LocalDate(year: 2026, month: 3, day: 18)),
      scopeLabel: '2026. március 18.',
      payload: const DashboardBudgetDaySecondaryAnalysis(
        availability: BudgetAnalysisAvailability.available,
        selectedDayActualScaled100: 620000,
        spentBeforeSelectedDayScaled100: 18800000,
        dailyRoomBeforeScaled100: 2363000,
        dailyRoomAfterScaled100: 2499500,
        dailyRoomChangeScaled100: 136500,
        remainingSpendableTodayScaled100: 505000,
        monthlyDeltaScaled100: 2840000,
        usesForecast: true,
        isTerminalDay: false,
      ),
    );

    final before = tester.getRect(
      find.byKey(const ValueKey<String>('budget-analysis-day-before-card')),
    );
    final after = tester.getRect(
      find.byKey(const ValueKey<String>('budget-analysis-day-after-card')),
    );
    expect(before.width, closeTo(after.width, .01));
    expect(before.height, closeTo(after.height, .01));
    final amount = tester.widget<Text>(find.text('23630 Ft'));
    expect(amount.style?.fontSize, greaterThan(15.5));
    expect(
      find.ancestor(
        of: find.text('23630 Ft'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('budget-analysis-day-before-card'),
        ),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('DAY period publication is direct with no card fade', (
    tester,
  ) async {
    final selectedDay = ValueNotifier(20);
    addTearDown(selectedDay.dispose);
    DashboardBudgetDaySecondaryAnalysis payloadFor(int day) =>
        DashboardBudgetDaySecondaryAnalysis(
          availability: BudgetAnalysisAvailability.available,
          selectedDayActualScaled100: 620000,
          spentBeforeSelectedDayScaled100: 18800000,
          dailyRoomBeforeScaled100: day == 20 ? 2363000 : 2100000,
          dailyRoomAfterScaled100: day == 20 ? 2499500 : 2200000,
          dailyRoomChangeScaled100: day == 20 ? 136500 : 100000,
          remainingSpendableTodayScaled100: 505000,
          monthlyDeltaScaled100: 2840000,
          usesForecast: true,
          isTerminalDay: false,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 220,
          child: ValueListenableBuilder<int>(
            valueListenable: selectedDay,
            builder: (context, day, _) => BudgetSecondaryAnalysisPreparedCard(
              frame: DashboardBudgetSecondaryAnalysisFrame(
                coreRevision: 17,
                direction: LedgerDirection.expense,
                targetHandle: 1,
                scope: DayScope(LocalDate(year: 2026, month: 3, day: day)),
                payload: payloadFor(day),
              ),
              targetTitle: 'Élelmiszer',
              scopeLabel: '2026. március $day.',
            ),
          ),
        ),
      ),
    );
    expect(find.text('23630 Ft'), findsOneWidget);

    selectedDay.value = 21;
    await tester.pump();

    expect(find.text('2026. március 21.'), findsOneWidget);
    expect(find.text('21000 Ft'), findsOneWidget);
    expect(find.text('22000 Ft'), findsOneWidget);
    expect(find.text('23630 Ft'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(BudgetSecondaryAnalysisPreparedCard),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('solid colour mode changes material only, not the SUM geometry', (
    tester,
  ) async {
    final ringPresentation = BudgetRingPresentationController();
    addTearDown(ringPresentation.dispose);
    const payload = DashboardBudgetSumAnalysis(
      availability: BudgetAnalysisAvailability.available,
      averageUtilization: 1.15,
      averageBudgetDeltaScaled100: 1,
      eligibleMonthCount: 1,
      monthsWithinBudget: 0,
      utilizationStandardDeviation: .1,
    );
    await pump(
      tester,
      scope: const AllTimeScope(),
      scopeLabel: 'Összesen',
      payload: payload,
      ringPresentation: ringPresentation,
    );
    final segmented = tester.widget<BudgetSemicircleMaterial>(
      find.byType(BudgetSemicircleMaterial),
    );
    ringPresentation.selectProgressColorPresentation(
      BudgetProgressColorPresentation.solidHealth,
    );
    await tester.pump();
    final solid = tester.widget<BudgetSemicircleMaterial>(
      find.byType(BudgetSemicircleMaterial),
    );

    expect(segmented.progress, solid.progress);
    expect(segmented.layout, solid.layout);
    expect(segmented.showMarker, solid.showMarker);
    expect(segmented.activeMaterial.stops, hasLength(7));
    expect(solid.activeMaterial.stops, const <double>[0, .5, 1]);
    await expectLater(
      find.byKey(const ValueKey('budget-analysis-golden-boundary')),
      matchesGoldenFile(
        '../../../goldens/budget_analysis_sum_solid_danger.png',
      ),
    );
  });

  testWidgets(
    'solid warning is one amber 3D material across the full active strip',
    (tester) async {
      final ringPresentation = BudgetRingPresentationController()
        ..selectProgressColorPresentation(
          BudgetProgressColorPresentation.solidHealth,
        );
      addTearDown(ringPresentation.dispose);
      await pump(
        tester,
        scope: const AllTimeScope(),
        scopeLabel: 'Összesen',
        payload: const DashboardBudgetSumAnalysis(
          availability: BudgetAnalysisAvailability.available,
          averageUtilization: 1.05,
          averageBudgetDeltaScaled100: 1,
          eligibleMonthCount: 1,
          monthsWithinBudget: 0,
          utilizationStandardDeviation: .1,
        ),
        ringPresentation: ringPresentation,
      );
      final material = tester.widget<BudgetSemicircleMaterial>(
        find.byType(BudgetSemicircleMaterial),
      );

      expect(material.activeMaterial.stops, const <double>[0, .5, 1]);
      expect(
        material.activeMaterial.colors[1],
        FluviVisualTokens.budgetProgressWarning,
      );
      await expectLater(
        find.byKey(const ValueKey('budget-analysis-golden-boundary')),
        matchesGoldenFile(
          '../../../goldens/budget_analysis_sum_solid_warning.png',
        ),
      );
    },
  );

  testWidgets(
    'semantic publication is instant while only the sweep and marker move',
    (tester) async {
      final presentation = ValueNotifier<BudgetSemicircleMaterialPresentation>(
        BudgetSemicircleMaterialPresentation.resolve(
          rawRatio: .39,
          direction: LedgerDirection.expense,
          activeGradient: const <Color>[
            Color(0xFF22D3EE),
            Color(0xFF2BC4F3),
            Color(0xFF39B8F4),
          ],
        ),
      );
      addTearDown(presentation.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 390,
            height: 150,
            child: ValueListenableBuilder<BudgetSemicircleMaterialPresentation>(
              valueListenable: presentation,
              builder: (context, value, _) => BudgetSemicircleGauge(
                presentation: value,
                primaryLabel: '${(value.rawRatio * 100).round()}%',
                secondaryLabel: 'havi keretkihasználás',
              ),
            ),
          ),
        ),
      );
      expect(find.text('39%'), findsOneWidget);
      presentation.value = BudgetSemicircleMaterialPresentation.resolve(
        rawRatio: .82,
        direction: LedgerDirection.expense,
        activeGradient: const <Color>[
          Color(0xFF22D3EE),
          Color(0xFF2BC4F3),
          Color(0xFF39B8F4),
        ],
      );
      await tester.pump();

      expect(find.text('82%'), findsOneWidget);
      expect(find.text('39%'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(BudgetSemicircleGauge),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
        reason:
            'Route transitions are unrelated; the gauge subtree has no fade.',
      );
      expect(
        tester
            .widget<BudgetSemicircleMaterial>(
              find.byType(BudgetSemicircleMaterial),
            )
            .progress,
        closeTo(.39 / 1.2, .0001),
        reason: 'The first motion frame starts at the previously painted arc.',
      );
      await tester.pump(const Duration(milliseconds: 160));
      final midway = tester
          .widget<BudgetSemicircleMaterial>(
            find.byType(BudgetSemicircleMaterial),
          )
          .progress;
      expect(midway, greaterThan(.39 / 1.2));
      expect(midway, lessThan(.82 / 1.2));
      await tester.pump(const Duration(milliseconds: 160));
      expect(
        tester
            .widget<BudgetSemicircleMaterial>(
              find.byType(BudgetSemicircleMaterial),
            )
            .progress,
        closeTo(.82 / 1.2, .0001),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rapid semantic retarget starts from the visible sweep', (
    tester,
  ) async {
    final presentation = ValueNotifier<BudgetSemicircleMaterialPresentation>(
      BudgetSemicircleMaterialPresentation.resolve(
        rawRatio: .27,
        direction: LedgerDirection.expense,
        activeGradient: const <Color>[
          Color(0xFF22D3EE),
          Color(0xFF2BC4F3),
          Color(0xFF39B8F4),
        ],
      ),
    );
    addTearDown(presentation.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 150,
          child: ValueListenableBuilder<BudgetSemicircleMaterialPresentation>(
            valueListenable: presentation,
            builder: (context, value, _) => BudgetSemicircleGauge(
              presentation: value,
              primaryLabel: '${(value.rawRatio * 100).round()}%',
              secondaryLabel: 'havi keretkihasználás',
            ),
          ),
        ),
      ),
    );
    presentation.value = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: .91,
      direction: LedgerDirection.expense,
      activeGradient: const <Color>[
        Color(0xFF22D3EE),
        Color(0xFF2BC4F3),
        Color(0xFF39B8F4),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final visibleMidway = tester
        .widget<BudgetSemicircleMaterial>(find.byType(BudgetSemicircleMaterial))
        .progress;

    presentation.value = BudgetSemicircleMaterialPresentation.resolve(
      rawRatio: .43,
      direction: LedgerDirection.expense,
      activeGradient: const <Color>[
        Color(0xFF22D3EE),
        Color(0xFF2BC4F3),
        Color(0xFF39B8F4),
      ],
    );
    await tester.pump();

    expect(find.text('43%'), findsOneWidget);
    expect(
      tester
          .widget<BudgetSemicircleMaterial>(
            find.byType(BudgetSemicircleMaterial),
          )
          .progress,
      closeTo(visibleMidway, .0001),
      reason: 'Latest-wins retargeting must not snap back to 27% or 91%.',
    );
    await tester.pump(const Duration(milliseconds: 320));
    expect(
      tester
          .widget<BudgetSemicircleMaterial>(
            find.byType(BudgetSemicircleMaterial),
          )
          .progress,
      closeTo(.43 / 1.2, .0001),
    );
  });

  testWidgets('hidden info cards toggle the same KPI data in a chart popup', (
    tester,
  ) async {
    final ringPresentation = BudgetRingPresentationController()
      ..setAnalysisInfoCardsVisible(false);
    addTearDown(ringPresentation.dispose);
    await pump(
      tester,
      scope: const AllTimeScope(),
      scopeLabel: 'Összesen',
      payload: const DashboardBudgetSumAnalysis(
        availability: BudgetAnalysisAvailability.available,
        averageUtilization: .39,
        averageBudgetDeltaScaled100: -84000,
        eligibleMonthCount: 12,
        monthsWithinBudget: 8,
        utilizationStandardDeviation: .12,
      ),
      ringPresentation: ringPresentation,
    );

    expect(
      find.byKey(const ValueKey<String>('budget-analysis-kpi-row')),
      findsNothing,
    );
    expect(find.text('Átlagos eltérés'), findsNothing);
    await expectLater(
      find.byKey(const ValueKey('budget-analysis-golden-boundary')),
      matchesGoldenFile(
        '../../../goldens/budget_analysis_sum_info_cards_hidden.png',
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('budget-analysis-sum-semicircle')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('budget-analysis-kpi-popup')),
      findsOneWidget,
    );
    expect(find.text('Átlagos eltérés'), findsOneWidget);
    expect(find.text('−840 Ft'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('budget-analysis-sum-semicircle')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('budget-analysis-kpi-popup')),
      findsNothing,
    );
  });
}

DashboardBudgetYearMonthAnalysis _yearMonth({
  required int month,
  required int delta,
}) => DashboardBudgetYearMonthAnalysis(
  month: month,
  availability: BudgetAnalysisAvailability.available,
  actualScaled100: 100000 - delta,
  limitScaled100: 100000,
  budgetDeltaScaled100: delta,
  barDirection: delta < 0
      ? BudgetAnalysisBarDirection.up
      : BudgetAnalysisBarDirection.down,
  isCompleted: true,
);

DashboardBudgetYearMonthAnalysis _futureYearMonth(int month) =>
    DashboardBudgetYearMonthAnalysis(
      month: month,
      availability: BudgetAnalysisAvailability.future,
      actualScaled100: null,
      limitScaled100: null,
      budgetDeltaScaled100: null,
      barDirection: BudgetAnalysisBarDirection.unavailable,
      isCompleted: false,
    );
