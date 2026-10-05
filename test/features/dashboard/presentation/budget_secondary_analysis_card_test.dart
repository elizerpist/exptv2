import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_secondary_analysis.dart';
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
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            height: 220,
            child: RepaintBoundary(
              key: const ValueKey<String>('budget-analysis-golden-boundary'),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: BudgetSecondaryAnalysisPreparedCard(
                  frame: DashboardBudgetSecondaryAnalysisFrame(
                    coreRevision: 17,
                    direction: LedgerDirection.expense,
                    targetHandle: 1,
                    scope: scope,
                    payload: payload,
                  ),
                  targetTitle: 'Élelmiszer',
                  scopeLabel: scopeLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('SUM mounts exactly one overspend-capable semicircle', (
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
    'MONTH mounts exactly two side-by-side semicircles and pp insight',
    (tester) async {
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
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('budget-analysis-golden-boundary')),
        matchesGoldenFile('../../../goldens/budget_analysis_month.png'),
      );
    },
  );

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
