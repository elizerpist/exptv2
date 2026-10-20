import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              height: 220,
              child: RepaintBoundary(
                key: const ValueKey<String>('budget-analysis-golden-boundary'),
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
    );
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
    expect(find.byType(BudgetSumSemicircleGauge), findsOneWidget);
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
      final preparedSumMaterial = tester
          .widget<BudgetSemicircleMaterial>(
            find.byType(BudgetSemicircleMaterial),
          )
          .presentation;
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
        expect(identical(material.presentation, preparedSumMaterial), isTrue);
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
    'YEAR mounts a centered zero-axis chart with prepared signed bars',
    (tester) async {
      await pump(
        tester,
        scope: const YearScope(2026),
        scopeLabel: '2026',
        payload: DashboardBudgetYearAnalysis(
          availability: BudgetAnalysisAvailability.available,
          months: List<DashboardBudgetYearMonthAnalysis>.generate(
            12,
            (index) => DashboardBudgetYearMonthAnalysis(
              month: index + 1,
              availability: index < 3
                  ? BudgetAnalysisAvailability.available
                  : BudgetAnalysisAvailability.future,
              actualScaled100: index < 3 ? 100000 : null,
              limitScaled100: index < 3 ? 90000 : null,
              budgetDeltaScaled100: index == 1
                  ? 20000
                  : index < 3
                  ? -10000
                  : null,
              barDirection: index == 1
                  ? BudgetAnalysisBarDirection.down
                  : index < 3
                  ? BudgetAnalysisBarDirection.up
                  : BudgetAnalysisBarDirection.unavailable,
              isCompleted: index < 2,
            ),
          ),
          completedEligibleMonthCount: 2,
          completedWithinBudgetCount: 1,
          largestOverspendScaled100: 10000,
          largestReserveScaled100: 20000,
        ),
      );

      expect(
        find.byKey(const ValueKey('budget-analysis-year-zero-axis-bars')),
        findsOneWidget,
      );
      expect(find.text('JAN'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('budget-analysis-golden-boundary')),
        matchesGoldenFile('../../../goldens/budget_analysis_year.png'),
      );
    },
  );

  testWidgets(
    'MONTH uses two shared material semicircles for every strip combination',
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
        find.byKey(const ValueKey('budget-analysis-month-elapsed-semicircle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-analysis-month-used-semicircle')),
        findsOneWidget,
      );
      expect(find.textContaining('pp'), findsOneWidget);
      final preparedMonthMaterials = tester
          .widgetList<BudgetSemicircleMaterial>(
            find.byType(BudgetSemicircleMaterial),
          )
          .map((material) => material.presentation)
          .toList(growable: false);
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
          findsNWidgets(2),
        );
        expect(materials, hasLength(2));
        for (var index = 0; index < materials.length; index += 1) {
          final material = materials[index];
          expect(material.layout, BudgetSemicircleMaterialLayout.monthMetric);
          expect(material.showMarker, isFalse);
          expect(material.showNeutralDecorativeStrip, setting.neutral);
          expect(material.showActiveProgressDecorativeStrip, setting.active);
          expect(
            identical(material.presentation, preparedMonthMaterials[index]),
            isTrue,
          );
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
    expect(materials, hasLength(2));
    final used = materials.last;
    expect(used.showMarker, isFalse);
    expect(used.presentation.health, BudgetClayGaugeHealth.expenseDanger);
    expect(used.presentation.progressStops, hasLength(7));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('budget-analysis-golden-boundary')),
      matchesGoldenFile('../../../goldens/budget_analysis_month_over_115.png'),
    );
  });

  testWidgets('DAY mounts Before After blocks, one arrow and one impact band', (
    tester,
  ) async {
    await pump(
      tester,
      scope: const DayScope(LocalDate(year: 2026, month: 3, day: 18)),
      scopeLabel: '2026. március 18.',
      payload: const DashboardBudgetDaySecondaryAnalysis(
        availability: BudgetAnalysisAvailability.available,
        selectedDayActualScaled100: 620000,
        spentBeforeSelectedDayScaled100: 18800000,
        dailyRoomBeforeScaled100: 1125000,
        dailyRoomAfterScaled100: 830000,
        dailyRoomChangeScaled100: -295000,
        remainingSpendableTodayScaled100: 505000,
        monthlyDeltaScaled100: 2840000,
        usesForecast: true,
        isTerminalDay: false,
      ),
    );

    expect(find.text('Reggel még\nelérhető volt'), findsOneWidget);
    expect(find.text('Mostantól\nelérhető'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(
      find.byKey(const ValueKey('budget-analysis-day-impact-band')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('budget-analysis-golden-boundary')),
      matchesGoldenFile('../../../goldens/budget_analysis_day.png'),
    );
  });
}
