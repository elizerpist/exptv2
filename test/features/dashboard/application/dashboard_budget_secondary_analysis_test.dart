import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_secondary_analysis.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_spending_rhythm_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const asOf = LocalDate(year: 2026, month: 3, day: 10);

  group('DashboardBudgetSecondaryAnalysisProjector', () {
    test('SUM uses equal closed-month utilization and keeps zero spend', () {
      final frame = DashboardBudgetSecondaryAnalysisProjector.project(
        snapshot: _snapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 1,
        scope: const AllTimeScope(),
        logicalAsOfDate: asOf,
      );

      final payload = frame.payload as DashboardBudgetSumAnalysis;
      expect(frame.targetHandle, 1);
      expect(payload.isAvailable, isTrue);
      expect(payload.eligibleMonthCount, 3);
      expect(payload.monthsWithinBudget, 2);
      expect(payload.averageUtilization, closeTo(2.5 / 3, 0.000001));
      expect(payload.averageBudgetDeltaScaled100, 16667);
      expect(payload.utilizationStandardDeviation, greaterThan(0));
    });

    test(
      'YEAR preserves 12 slots, product bar orientation and future truth',
      () {
        final frame = DashboardBudgetSecondaryAnalysisProjector.project(
          snapshot: _snapshot(),
          direction: LedgerDirection.expense,
          targetHandle: 1,
          scope: const YearScope(2026),
          logicalAsOfDate: asOf,
        );

        final payload = frame.payload as DashboardBudgetYearAnalysis;
        expect(payload.months, hasLength(12));
        expect(payload.months[0].budgetDeltaScaled100, -100000);
        expect(payload.months[0].barDirection, BudgetAnalysisBarDirection.up);
        expect(payload.months[1].budgetDeltaScaled100, 50000);
        expect(payload.months[1].barDirection, BudgetAnalysisBarDirection.down);
        expect(
          payload.months[3].availability,
          BudgetAnalysisAvailability.future,
        );
        expect(payload.completedEligibleMonthCount, 2);
        expect(payload.completedWithinBudgetCount, 1);
        expect(payload.largestOverspendScaled100, 100000);
        expect(payload.largestReserveScaled100, 50000);
      },
    );

    test('MONTH follows calendar days and projects only the current month', () {
      final current =
          DashboardBudgetSecondaryAnalysisProjector.project(
                snapshot: _snapshot(),
                direction: LedgerDirection.expense,
                targetHandle: 1,
                scope: const MonthScope(YearMonth(year: 2026, month: 3)),
                logicalAsOfDate: asOf,
              ).payload
              as DashboardBudgetMonthSecondaryAnalysis;
      final completed =
          DashboardBudgetSecondaryAnalysisProjector.project(
                snapshot: _snapshot(),
                direction: LedgerDirection.expense,
                targetHandle: 1,
                scope: const MonthScope(YearMonth(year: 2026, month: 2)),
                logicalAsOfDate: asOf,
              ).payload
              as DashboardBudgetMonthSecondaryAnalysis;

      expect(current.elapsedCalendarDays, 10);
      expect(current.daysInMonth, 31);
      expect(current.projectedMonthEndScaled100, 279000);
      expect(current.expectedDeltaScaled100, 179000);
      expect(current.remainingDailyRoomScaled100, 476);
      expect(
        current.paceDifferencePercentagePoints,
        closeTo(90 - 10 / 31 * 100, .000001),
      );
      expect(current.usesForecast, isTrue);
      expect(completed.usesForecast, isFalse);
      expect(completed.projectedMonthEndScaled100, 50000);
      expect(completed.closingBudgetDeltaScaled100, 50000);
    });

    test(
      'DAY calculates category-specific before, after and terminal safety',
      () {
        final day =
            DashboardBudgetSecondaryAnalysisProjector.project(
                  snapshot: _snapshot(),
                  direction: LedgerDirection.expense,
                  targetHandle: 1,
                  scope: const DayScope(
                    LocalDate(year: 2026, month: 3, day: 10),
                  ),
                  logicalAsOfDate: asOf,
                ).payload
                as DashboardBudgetDaySecondaryAnalysis;
        final otherTarget =
            DashboardBudgetSecondaryAnalysisProjector.project(
                  snapshot: _snapshot(),
                  direction: LedgerDirection.expense,
                  targetHandle: 2,
                  scope: const DayScope(
                    LocalDate(year: 2026, month: 3, day: 10),
                  ),
                  logicalAsOfDate: asOf,
                ).payload
                as DashboardBudgetDaySecondaryAnalysis;
        final terminal =
            DashboardBudgetSecondaryAnalysisProjector.project(
                  snapshot: _snapshot(),
                  direction: LedgerDirection.expense,
                  targetHandle: 1,
                  scope: const DayScope(
                    LocalDate(year: 2026, month: 3, day: 31),
                  ),
                  logicalAsOfDate: const LocalDate(
                    year: 2026,
                    month: 3,
                    day: 31,
                  ),
                ).payload
                as DashboardBudgetDaySecondaryAnalysis;

        expect(day.spentBeforeSelectedDayScaled100, 70000);
        expect(day.selectedDayActualScaled100, 20000);
        expect(day.dailyRoomBeforeScaled100, 1364);
        expect(day.dailyRoomAfterScaled100, 476);
        expect(day.dailyRoomChangeScaled100, -888);
        expect(day.remainingSpendableTodayScaled100, 0);
        expect(otherTarget.selectedDayActualScaled100, 7000);
        expect(
          otherTarget.dailyRoomBeforeScaled100,
          isNot(day.dailyRoomBeforeScaled100),
        );
        expect(terminal.isTerminalDay, isTrue);
        expect(terminal.dailyRoomAfterScaled100, isNull);
        expect(terminal.dailyRoomChangeScaled100, isNull);
      },
    );

    test('a missing limit is unavailable rather than a fabricated zero', () {
      final frame = DashboardBudgetSecondaryAnalysisProjector.project(
        snapshot: _snapshot(),
        direction: LedgerDirection.expense,
        targetHandle: 2,
        scope: const MonthScope(YearMonth(year: 2026, month: 4)),
        logicalAsOfDate: asOf,
      );

      final payload = frame.payload as DashboardBudgetMonthSecondaryAnalysis;
      expect(payload.availability, BudgetAnalysisAvailability.future);
      expect(payload.monthlyLimitScaled100, isNull);
      expect(payload.projectedMonthEndScaled100, isNull);
    });

    test('MONTH keeps real 28, 29, 30 and 31-day calendar denominators', () {
      DashboardBudgetMonthSecondaryAnalysis month(int year, int value) =>
          DashboardBudgetSecondaryAnalysisProjector.project(
                snapshot: _snapshot(),
                direction: LedgerDirection.expense,
                targetHandle: 1,
                scope: MonthScope(YearMonth(year: year, month: value)),
                logicalAsOfDate: asOf,
              ).payload
              as DashboardBudgetMonthSecondaryAnalysis;

      expect(month(2025, 2).daysInMonth, 28);
      expect(month(2024, 2).daysInMonth, 29);
      expect(month(2026, 4).daysInMonth, 30);
      expect(month(2026, 3).daysInMonth, 31);
    });
  });
}

PreparedBudgetLimitSnapshot _snapshot() {
  const startYear = 2025;
  const endYear = 2026;
  final expense = _bank(startYear: startYear, endYear: endYear);
  final income = _emptyBank(startYear: startYear, endYear: endYear);
  return PreparedBudgetLimitSnapshot(
    coreRevision: 71,
    yearWindowStart: startYear,
    yearWindowEndInclusive: endYear,
    incomeBank: income,
    expenseBank: expense,
    spendingRhythmSnapshot: PreparedSpendingRhythmSnapshot(
      coreRevision: 71,
      incomeBank: PreparedSpendingRhythmDirectionBank.empty(targetCount: 3),
      expenseBank: _rhythmBank(),
    ),
  );
}

PreparedBudgetLimitDirectionBank _bank({
  required int startYear,
  required int endYear,
}) {
  const targetCount = 3;
  final cells = List<PreparedBudgetLimitCell>.filled(
    (1 + (endYear - startYear + 1) + (endYear - startYear + 1) * 12) *
        targetCount,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  int sliceForMonth(int year, int month) =>
      1 + (endYear - startYear + 1) + (year - startYear) * 12 + month - 1;
  void month(int year, int month, int handle, int actual, int? limit) {
    cells[sliceForMonth(year, month) * targetCount + handle] =
        PreparedBudgetLimitCell(actualScaled100: actual, limitScaled100: limit);
  }

  month(2025, 12, 1, 0, 100000);
  month(2026, 1, 1, 200000, 100000);
  month(2026, 2, 1, 50000, 100000);
  month(2026, 3, 1, 90000, 100000);
  month(2026, 3, 2, 7000, 200000);
  return PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['rent', 'food'],
    cells: cells,
  );
}

PreparedBudgetLimitDirectionBank _emptyBank({
  required int startYear,
  required int endYear,
}) => PreparedBudgetLimitDirectionBank(
  orderedCategoryIds: const <String>['salary', 'other'],
  cells: List<PreparedBudgetLimitCell>.filled(
    (1 + (endYear - startYear + 1) + (endYear - startYear + 1) * 12) * 3,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  ),
);

PreparedSpendingRhythmDirectionBank _rhythmBank() {
  final day5 = const LocalDate(year: 2026, month: 3, day: 5).epochDay;
  final day10 = const LocalDate(year: 2026, month: 3, day: 10).epochDay;
  final day31 = const LocalDate(year: 2026, month: 3, day: 31).epochDay;
  List<int> buckets(int amount) => <int>[amount, 0, 0, 0, 0, 0, 0, 0];
  return PreparedSpendingRhythmDirectionBank(
    targetCount: 3,
    targetOffsets: const <int>[0, 0, 2, 3],
    epochDays: <int>[day5, day10, day10],
    dailyActualScaled100: const <int>[70000, 20000, 7000],
    dayPartActualScaled100: <int>[
      ...buckets(70000),
      ...buckets(20000),
      ...buckets(7000),
    ],
  );
}
