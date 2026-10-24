import 'package:fluvi/features/dashboard/application/balance_daily_calculation_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_history_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'retained content settings revise without owning outer layout state',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final initial = controller.value;
      controller.setChartMode(BalanceHeaderChartMode.adaptiveSummary);
      expect(
        controller.value,
        initial.copyWith(
          chartMode: BalanceHeaderChartMode.adaptiveSummary,
          revision: 1,
        ),
      );
      controller.setChartMode(BalanceHeaderChartMode.adaptiveSummary);
      expect(notifications, 1);
      controller.setUsesChildCards(false);
      expect(controller.value.usesChildCards, isFalse);
      expect(
        controller.value.sumLayoutPresentation,
        initial.sumLayoutPresentation,
      );
      expect(
        controller.value.yearLayoutPresentation,
        initial.yearLayoutPresentation,
      );
      expect(
        controller.value.monthLayoutPresentation,
        initial.monthLayoutPresentation,
      );
      expect(
        controller.value.dayLayoutPresentation,
        initial.dayLayoutPresentation,
      );
      expect(controller.value.copyWith(), controller.value);
      expect(controller.value.copyWith().hashCode, controller.value.hashCode);
      controller.reset();
      expect(controller.value, initial);
    },
  );

  test('all retained per-scope persisted layout indices remain stable', () {
    expect(BalanceSumLayoutPresentation.current.index, 0);
    expect(BalanceSumLayoutPresentation.focused.index, 1);
    expect(BalanceYearLayoutPresentation.current.index, 0);
    expect(BalanceYearLayoutPresentation.focused.index, 1);
    expect(BalanceMonthLayoutPresentation.current.index, 0);
    expect(BalanceMonthLayoutPresentation.focused.index, 1);
    expect(BalanceDayLayoutPresentation.current.index, 0);
    expect(BalanceDayLayoutPresentation.focused.index, 1);
    expect(BalanceDayFocusedPresentation.monthlyNetMarginImpact.index, 3);
    expect(BalanceDayRatioPresentation.netMargin.index, 1);
    expect(BalanceDayRatioViewPresentation.performanceIndex.index, 1);
    expect(BalanceDayPerformanceVisualPresentation.horizontalMeter.index, 1);
  });

  test(
    'monthly impact perspective retains earlier indices and independent ratio choices',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);
      controller.setDayRatioPresentation(BalanceDayRatioPresentation.netMargin);
      controller.setDayRatioViewPresentation(
        BalanceDayRatioViewPresentation.performanceIndex,
      );
      controller.setDayPerformanceVisualPresentation(
        BalanceDayPerformanceVisualPresentation.horizontalMeter,
      );
      final before = controller.value;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.monthlyNetMarginImpact,
      );
      final expected = before.copyWith(
        dayFocusedPresentation:
            BalanceDayFocusedPresentation.monthlyNetMarginImpact,
        revision: before.revision + 1,
      );
      expect(controller.value, expected);
      expect(controller.value.hashCode, expected.hashCode);
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.monthlyNetMarginImpact,
      );
      expect(notifications, 1);
      for (final earlier in BalanceDayFocusedPresentation.values.take(3)) {
        controller.setDayFocusedPresentation(earlier);
        controller.setDayFocusedPresentation(
          BalanceDayFocusedPresentation.monthlyNetMarginImpact,
        );
        expect(
          controller.value.dayRatioPresentation,
          before.dayRatioPresentation,
        );
        expect(
          controller.value.dayRatioViewPresentation,
          before.dayRatioViewPresentation,
        );
        expect(
          controller.value.dayPerformanceVisualPresentation,
          before.dayPerformanceVisualPresentation,
        );
      }
    },
  );

  test(
    'performance visual revises once and preserves both other ratio choices',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);
      final original = controller.value;
      expect(
        original.dayPerformanceVisualPresentation,
        BalanceDayPerformanceVisualPresentation.semicircle,
      );
      controller.setDayRatioPresentation(BalanceDayRatioPresentation.netMargin);
      controller.setDayRatioViewPresentation(
        BalanceDayRatioViewPresentation.performanceIndex,
      );
      final before = controller.value;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setDayPerformanceVisualPresentation(
        BalanceDayPerformanceVisualPresentation.horizontalMeter,
      );
      final expected = before.copyWith(
        dayPerformanceVisualPresentation:
            BalanceDayPerformanceVisualPresentation.horizontalMeter,
        revision: before.revision + 1,
      );
      expect(controller.value, expected);
      expect(controller.value.hashCode, expected.hashCode);
      controller.setDayPerformanceVisualPresentation(
        BalanceDayPerformanceVisualPresentation.horizontalMeter,
      );
      expect(notifications, 1);
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.financialComparison,
      );
      controller.setDayRatioViewPresentation(
        BalanceDayRatioViewPresentation.dualGauge,
      );
      controller.setDayLayoutPresentation(BalanceDayLayoutPresentation.current);
      expect(
        controller.value.dayPerformanceVisualPresentation,
        BalanceDayPerformanceVisualPresentation.horizontalMeter,
      );
      expect(
        controller.value.dayRatioPresentation,
        BalanceDayRatioPresentation.netMargin,
      );
      controller.setDayPerformanceVisualPresentation(
        BalanceDayPerformanceVisualPresentation.semicircle,
      );
      expect(
        controller.value.dayRatioViewPresentation,
        BalanceDayRatioViewPresentation.dualGauge,
      );
      expect(
        controller.value.sumLayoutPresentation,
        original.sumLayoutPresentation,
      );
      expect(
        controller.value.monthLayoutPresentation,
        original.monthLayoutPresentation,
      );
      expect(
        controller.value.yearLayoutPresentation,
        original.yearLayoutPresentation,
      );
    },
  );

  test(
    'day ratio view revises independently and preserves dual gauge calculation',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);
      final original = controller.value;
      expect(
        original.dayRatioViewPresentation,
        BalanceDayRatioViewPresentation.dualGauge,
      );
      controller.setDayRatioPresentation(BalanceDayRatioPresentation.netMargin);
      final dual = controller.value;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setDayRatioViewPresentation(
        BalanceDayRatioViewPresentation.performanceIndex,
      );
      final expected = dual.copyWith(
        dayRatioViewPresentation:
            BalanceDayRatioViewPresentation.performanceIndex,
        revision: dual.revision + 1,
      );
      expect(controller.value, expected);
      expect(controller.value.hashCode, expected.hashCode);
      controller.setDayRatioViewPresentation(
        BalanceDayRatioViewPresentation.performanceIndex,
      );
      expect(notifications, 1);
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.financialCompass,
      );
      controller.setDayRatioViewPresentation(
        BalanceDayRatioViewPresentation.dualGauge,
      );
      expect(
        controller.value.dayRatioPresentation,
        BalanceDayRatioPresentation.netMargin,
      );
      expect(
        controller.value.dayFocusedPresentation,
        original.dayFocusedPresentation,
      );
      expect(
        controller.value.sumLayoutPresentation,
        original.sumLayoutPresentation,
      );
      expect(
        controller.value.monthLayoutPresentation,
        original.monthLayoutPresentation,
      );
      expect(
        controller.value.yearLayoutPresentation,
        original.yearLayoutPresentation,
      );
    },
  );

  test(
    'day ratio changes only its presentation preference and revises once',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);
      final original = controller.value;
      expect(
        original.dayRatioPresentation,
        BalanceDayRatioPresentation.coverage,
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setDayRatioPresentation(BalanceDayRatioPresentation.netMargin);
      expect(
        controller.value,
        original.copyWith(
          dayRatioPresentation: BalanceDayRatioPresentation.netMargin,
          revision: original.revision + 1,
        ),
      );
      expect(
        controller.value.hashCode,
        original
            .copyWith(
              dayRatioPresentation: BalanceDayRatioPresentation.netMargin,
              revision: original.revision + 1,
            )
            .hashCode,
      );
      controller.setDayRatioPresentation(BalanceDayRatioPresentation.netMargin);
      expect(notifications, 1);
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.dailyImpactFocus,
      );
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.financialCompass,
      );
      expect(
        controller.value.dayRatioPresentation,
        BalanceDayRatioPresentation.netMargin,
      );
      controller.setDayRatioPresentation(BalanceDayRatioPresentation.coverage);
      expect(
        controller.value.dayRatioPresentation,
        original.dayRatioPresentation,
      );
      expect(
        controller.value.showFocusedDayImpact,
        original.showFocusedDayImpact,
      );
    },
  );

  test(
    'SUM alternatives revise independently and retain hidden impact preference',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);
      final original = controller.value;
      expect(
        original.sumLayoutPresentation,
        BalanceSumLayoutPresentation.current,
      );
      expect(
        original.sumFocusedPresentation,
        BalanceSumFocusedPresentation.distribution,
      );
      expect(original.showSumFocusedSupplementaryStats, isTrue);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setSumLayoutPresentation(BalanceSumLayoutPresentation.focused);
      controller.setSumFocusedPresentation(
        BalanceSumFocusedPresentation.positiveRatio,
      );
      controller.setShowSumFocusedSupplementaryStats(false);
      final changed = original.copyWith(
        sumLayoutPresentation: BalanceSumLayoutPresentation.focused,
        sumFocusedPresentation: BalanceSumFocusedPresentation.positiveRatio,
        showSumFocusedSupplementaryStats: false,
        revision: 3,
      );
      expect(controller.value, changed);
      expect(controller.value.hashCode, changed.hashCode);
      controller.setSumLayoutPresentation(BalanceSumLayoutPresentation.focused);
      controller.setSumFocusedPresentation(
        BalanceSumFocusedPresentation.positiveRatio,
      );
      controller.setShowSumFocusedSupplementaryStats(false);
      expect(notifications, 3);
      controller.setSumFocusedPresentation(
        BalanceSumFocusedPresentation.stability,
      );
      controller.setSumLayoutPresentation(BalanceSumLayoutPresentation.current);
      controller.setSumLayoutPresentation(BalanceSumLayoutPresentation.focused);
      expect(controller.value.showSumFocusedSupplementaryStats, isFalse);
      expect(
        controller.value.sumFocusedPresentation,
        BalanceSumFocusedPresentation.stability,
      );
      controller.reset();
      expect(
        controller.value.sumLayoutPresentation,
        BalanceSumLayoutPresentation.current,
      );
      expect(
        controller.value.sumFocusedPresentation,
        BalanceSumFocusedPresentation.distribution,
      );
      expect(controller.value.showSumFocusedSupplementaryStats, isTrue);
    },
  );
  test(
    'day alternatives revise independently and retain hidden impact preference',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);
      final original = controller.value;
      expect(
        original.dayLayoutPresentation,
        BalanceDayLayoutPresentation.current,
      );
      expect(
        original.dayFocusedPresentation,
        BalanceDayFocusedPresentation.financialCompass,
      );
      expect(original.showFocusedDayImpact, isTrue);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setDayLayoutPresentation(BalanceDayLayoutPresentation.focused);
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.financialComparison,
      );
      controller.setShowFocusedDayImpact(false);
      final changed = original.copyWith(
        dayLayoutPresentation: BalanceDayLayoutPresentation.focused,
        dayFocusedPresentation:
            BalanceDayFocusedPresentation.financialComparison,
        showFocusedDayImpact: false,
        revision: 3,
      );
      expect(controller.value, changed);
      expect(controller.value.hashCode, changed.hashCode);
      controller.setDayLayoutPresentation(BalanceDayLayoutPresentation.focused);
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.financialComparison,
      );
      controller.setShowFocusedDayImpact(false);
      expect(notifications, 3);
      controller.setDayFocusedPresentation(
        BalanceDayFocusedPresentation.dailyImpactFocus,
      );
      controller.setDayLayoutPresentation(BalanceDayLayoutPresentation.current);
      controller.setDayLayoutPresentation(BalanceDayLayoutPresentation.focused);
      expect(controller.value.showFocusedDayImpact, isFalse);
      expect(
        controller.value.dayFocusedPresentation,
        BalanceDayFocusedPresentation.dailyImpactFocus,
      );
      controller.reset();
      expect(
        controller.value.dayLayoutPresentation,
        BalanceDayLayoutPresentation.current,
      );
      expect(
        controller.value.dayFocusedPresentation,
        BalanceDayFocusedPresentation.financialCompass,
      );
      expect(controller.value.showFocusedDayImpact, isTrue);
    },
  );

  test('monthly layout switches independently and advances revision once', () {
    final controller = BalancePresentationController();
    addTearDown(controller.dispose);
    final original = controller.value;
    var notifications = 0;
    controller.addListener(() => notifications++);
    expect(
      original.monthLayoutPresentation,
      BalanceMonthLayoutPresentation.current,
    );
    controller.setMonthLayoutPresentation(
      BalanceMonthLayoutPresentation.focused,
    );
    final focused = original.copyWith(
      monthLayoutPresentation: BalanceMonthLayoutPresentation.focused,
      revision: 1,
    );
    expect(controller.value, focused);
    expect(controller.value.hashCode, focused.hashCode);
    controller.setMonthLayoutPresentation(
      BalanceMonthLayoutPresentation.focused,
    );
    expect(notifications, 1);
    controller.setMonthLayoutPresentation(
      BalanceMonthLayoutPresentation.current,
    );
    expect(controller.value, original.copyWith(revision: 2));
    expect(notifications, 2);
  });
  test('annual layout switches independently and advances revision once', () {
    final controller = BalancePresentationController();
    addTearDown(controller.dispose);
    final original = controller.value;
    var notifications = 0;
    controller.addListener(() => notifications++);
    expect(
      original.yearLayoutPresentation,
      BalanceYearLayoutPresentation.current,
    );
    controller.setYearLayoutPresentation(BalanceYearLayoutPresentation.focused);
    final focused = original.copyWith(
      yearLayoutPresentation: BalanceYearLayoutPresentation.focused,
      revision: 1,
    );
    expect(controller.value, focused);
    expect(controller.value.hashCode, focused.hashCode);
    controller.setYearLayoutPresentation(BalanceYearLayoutPresentation.focused);
    expect(notifications, 1);
    controller.setYearLayoutPresentation(BalanceYearLayoutPresentation.current);
    expect(controller.value, original.copyWith(revision: 2));
    expect(notifications, 2);
  });

  test(
    'daily calculation changes only header preference and notifies once',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);
      final original = controller.value;
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(
        original.dailyCalculationMode,
        BalanceDailyCalculationMode.monthToDate,
      );
      controller.setDailyCalculationMode(
        BalanceDailyCalculationMode.allTimeToDate,
      );
      expect(
        controller.value,
        original.copyWith(
          dailyCalculationMode: BalanceDailyCalculationMode.allTimeToDate,
          revision: 1,
        ),
      );
      controller.setDailyCalculationMode(
        BalanceDailyCalculationMode.allTimeToDate,
      );
      expect(notifications, 1);
      controller.setDailyCalculationMode(
        BalanceDailyCalculationMode.monthToDate,
      );
      expect(controller.value, original.copyWith(revision: 2));
      expect(notifications, 2);
    },
  );

  test(
    'BALANCE-REFINEMENT-SETTINGS: header partition and Month rhythm stay revisioned presentation-only choices',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      expect(
        controller.value.headerGraphPresentation,
        BalanceHeaderGraphPresentation.incomeExpensePartition,
      );
      expect(controller.value.headerPartitionHeightPercent, 50);
      expect(
        controller.value.monthCombinedCardPresentation,
        BalanceMonthCombinedCardPresentation.incomeExpense,
      );

      controller
        ..setHeaderGraphPresentation(
          BalanceHeaderGraphPresentation.incomeExpensePartition,
        )
        ..setHeaderPartitionHeightPercent(140)
        ..setMonthCombinedCardPresentation(
          BalanceMonthCombinedCardPresentation.spendingRhythm,
        );

      expect(
        controller.value.headerGraphPresentation,
        BalanceHeaderGraphPresentation.incomeExpensePartition,
      );
      expect(controller.value.headerPartitionHeightPercent, 100);
      expect(
        controller.value.monthCombinedCardPresentation,
        BalanceMonthCombinedCardPresentation.spendingRhythm,
      );
      final copy = controller.value.copyWith();
      expect(copy, controller.value);
      expect(copy.hashCode, controller.value.hashCode);

      controller.setHeaderGraphPresentation(
        BalanceHeaderGraphPresentation.simpleIncomeExpensePartition,
      );
      expect(
        controller.value.headerGraphPresentation,
        BalanceHeaderGraphPresentation.simpleIncomeExpensePartition,
      );
    },
  );

  test(
    'BALANCE-YEAR-BAR-STYLE: default, revision, equality and reset stay presentation-only',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      expect(
        controller.value.yearBarPresentation,
        BalanceYearBarPresentation.current,
      );
      final revision = controller.value.revision;
      controller.setYearBarPresentation(BalanceYearBarPresentation.clay3d);
      expect(
        controller.value.yearBarPresentation,
        BalanceYearBarPresentation.clay3d,
      );
      expect(controller.value.revision, revision + 1);
      controller.setYearBarPresentation(BalanceYearBarPresentation.clay3d);
      expect(controller.value.revision, revision + 1);

      final current = controller.value.copyWith(
        yearBarPresentation: BalanceYearBarPresentation.current,
      );
      expect(current, isNot(controller.value));
      expect(current.hashCode, isNot(controller.value.hashCode));

      controller.reset();
      expect(
        controller.value.yearBarPresentation,
        BalanceYearBarPresentation.current,
      );
    },
  );

  test(
    'MTC-02: the four-way monthly spending renderer is a persisted presentation choice independent from the Header graph kind',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      expect(
        controller.value.monthlySpendingChartPresentation,
        BalanceMonthlySpendingChartPresentation.current,
      );
      expect(
        controller.value.headerGraphPresentation,
        BalanceHeaderGraphPresentation.incomeExpensePartition,
      );

      controller.setMonthlySpendingChartPresentation(
        BalanceMonthlySpendingChartPresentation.shaderAtmosphere,
      );

      expect(
        controller.value.monthlySpendingChartPresentation,
        BalanceMonthlySpendingChartPresentation.shaderAtmosphere,
      );
      expect(
        controller.value.headerGraphPresentation,
        BalanceHeaderGraphPresentation.incomeExpensePartition,
      );
      expect(controller.value.copyWith(), controller.value);
      expect(controller.value.hashCode, controller.value.copyWith().hashCode);
    },
  );

  test(
    'BWD-DEFAULTS RED: Balance starts with the compound header function',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      expect(controller.value.chartMode, BalanceHeaderChartMode.compound);
    },
  );

  test(
    'BALANCE-CHART-MODES RED: views preserve cumulative money and use only immutable Balance history',
    () {
      final history = _history();
      expect(
        DashboardBalanceHistoryViewProjection.project(
          source: history,
          mode: BalanceHeaderChartMode.allTime,
          adaptiveScope: const MonthScope(YearMonth(year: 2026, month: 2)),
        ),
        same(history),
      );

      final adaptive = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.adaptiveSummary,
        adaptiveScope: const MonthScope(YearMonth(year: 2026, month: 2)),
      )!;
      expect(adaptive.points.map((point) => point.balanceMinor), <int>[
        800,
        750,
      ]);
      expect(
        DashboardBalanceHistoryViewProjection.project(
          source: history,
          mode: BalanceHeaderChartMode.adaptiveSummary,
          adaptiveScope: const DayScope(
            LocalDate(year: 2025, month: 1, day: 1),
          ),
        ),
        isNull,
        reason: 'No Summary-period point must not fabricate a Balance trend.',
      );

      final monthEnds = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.monthEndClosingExperimental,
        adaptiveScope: const AllTimeScope(),
      )!;
      expect(monthEnds.points.map((point) => point.balanceMinor), <int>[
        1000,
        750,
        750,
      ]);
      expect(monthEnds.points[1].epochDay, _epochDay(2026, 2, 28));
      expect(monthEnds.points[2].epochDay, _epochDay(2026, 3, 31));
      expect(monthEnds.points[2].entryId, startsWith('month-close:'));
      expect(
        monthEnds.points.last.epochDay,
        _epochDay(2026, 3, 31),
        reason:
            'A partial April ledger must not be presented at April month-end.',
      );
      final onlyPartialMonth = DashboardBalanceHistorySeries(
        startInclusiveEpochMinute: _epochDay(2026, 4, 2) * 1440,
        endInclusiveEpochMinute: _epochDay(2026, 4, 2) * 1440,
        points: <DashboardBalanceHistoryPoint>[
          _point('only-partial', 2026, 4, 2, 900),
        ],
      );
      expect(
        DashboardBalanceHistoryViewProjection.project(
          source: onlyPartialMonth,
          mode: BalanceHeaderChartMode.monthEndClosingExperimental,
          adaptiveScope: const AllTimeScope(),
        ),
        isNull,
        reason: 'A partial first month has no truthful month-end close yet.',
      );
    },
  );

  test(
    'COMPOUND-RED: fourth mode selects closing trend by Summary dimension',
    () {
      final history = DashboardBalanceHistorySeries(
        startInclusiveEpochMinute: _epochDay(2024, 1, 2) * 1440,
        endInclusiveEpochMinute: _epochDay(2026, 4, 2) * 1440,
        points: <DashboardBalanceHistoryPoint>[
          _point('2024-salary', 2024, 1, 2, 1000),
          _point('2024-expense', 2024, 1, 18, 700),
          _point('2024-feb', 2024, 2, 8, 1200),
          _point('2025-salary', 2025, 1, 4, 2200),
          _point('2025-expense', 2025, 1, 22, 1800),
          _point('2026-salary', 2026, 1, 3, 3000),
          _point('2026-feb', 2026, 2, 12, 2700),
          _point('2026-mar', 2026, 3, 6, 3400),
          _point('partial-april', 2026, 4, 2, 3300),
        ],
      );

      expect(BalanceHeaderChartMode.values, hasLength(4));
      expect(BalanceHeaderChartMode.compound.tunerLabel, 'Compound');

      final sum = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.compound,
        adaptiveScope: const AllTimeScope(),
      )!;
      expect(
        sum.points.map((point) => point.entryId),
        everyElement(startsWith('month-close:')),
      );
      expect(sum.points.map((point) => point.epochDay), <int>[
        _epochDay(2024, 1, 31),
        _epochDay(2024, 2, 29),
        _epochDay(2024, 3, 31),
        _epochDay(2024, 4, 30),
        _epochDay(2024, 5, 31),
        _epochDay(2024, 6, 30),
        _epochDay(2024, 7, 31),
        _epochDay(2024, 8, 31),
        _epochDay(2024, 9, 30),
        _epochDay(2024, 10, 31),
        _epochDay(2024, 11, 30),
        _epochDay(2024, 12, 31),
        _epochDay(2025, 1, 31),
        _epochDay(2025, 2, 28),
        _epochDay(2025, 3, 31),
        _epochDay(2025, 4, 30),
        _epochDay(2025, 5, 31),
        _epochDay(2025, 6, 30),
        _epochDay(2025, 7, 31),
        _epochDay(2025, 8, 31),
        _epochDay(2025, 9, 30),
        _epochDay(2025, 10, 31),
        _epochDay(2025, 11, 30),
        _epochDay(2025, 12, 31),
        _epochDay(2026, 1, 31),
        _epochDay(2026, 2, 28),
        _epochDay(2026, 3, 31),
      ]);

      final year = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.compound,
        adaptiveScope: const YearScope(2026),
      )!;
      expect(year.points.map((point) => point.epochDay), <int>[
        _epochDay(2026, 1, 31),
        _epochDay(2026, 2, 28),
        _epochDay(2026, 3, 31),
      ]);
      expect(
        year.points.first.balanceMinor,
        3000,
        reason: 'January must keep absolute Balance, not reset to zero.',
      );

      final month = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.compound,
        adaptiveScope: const MonthScope(YearMonth(year: 2025, month: 1)),
      )!;
      expect(month.points.map((point) => point.entryId), <String>[
        '2025-salary',
        '2025-expense',
      ]);
      expect(month.points.map((point) => point.balanceMinor), <int>[
        2200,
        1800,
      ]);

      final day = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.compound,
        adaptiveScope: const DayScope(LocalDate(year: 2025, month: 1, day: 4)),
      )!;
      expect(day.points.single.entryId, '2025-salary');
    },
  );
  test(
    'BALANCE-CHILD-CARDS-01: child-card chrome defaults on and remains a revisioned presentation-only preference',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      expect(controller.value.usesChildCards, isTrue);
      controller.setUsesChildCards(false);
      expect(controller.value.usesChildCards, isFalse);
      expect(controller.value.revision, 1);
      controller.reset();
      expect(controller.value.usesChildCards, isTrue);
    },
  );
}

DashboardBalanceHistorySeries _history() => DashboardBalanceHistorySeries(
  startInclusiveEpochMinute: _epochDay(2026, 1, 10) * 1440,
  endInclusiveEpochMinute: _epochDay(2026, 4, 2) * 1440,
  points: <DashboardBalanceHistoryPoint>[
    _point('jan', 2026, 1, 10, 1000),
    _point('feb-income', 2026, 2, 4, 800),
    _point('feb-expense', 2026, 2, 21, 750),
    _point('apr', 2026, 4, 2, 900),
  ],
);

DashboardBalanceHistoryPoint _point(
  String id,
  int year,
  int month,
  int day,
  int balance,
) => DashboardBalanceHistoryPoint(
  entryId: id,
  epochDay: _epochDay(year, month, day),
  epochMinute: _epochDay(year, month, day) * 1440,
  incomeTotalMinor: balance,
  expenseTotalMinor: 0,
  balanceMinor: balance,
);

int _epochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970)).inDays;
