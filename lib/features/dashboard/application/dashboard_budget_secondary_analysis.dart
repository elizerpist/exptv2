import '../query/domain/ledger_direction.dart';
import '../runtime/domain/prepared_budget_limit_snapshot.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/year_month.dart';

/// Immutable paint-ready Budget analysis identity.
///
/// The projector is deliberately pure and only accepts an exact prepared
/// snapshot. It therefore cannot acquire data while an avatar rail or pager
/// gesture is in flight. A rendering card receives one of these frames and
/// never derives money values from ledger rows.
final class DashboardBudgetSecondaryAnalysisFrame {
  const DashboardBudgetSecondaryAnalysisFrame({
    required this.coreRevision,
    required this.direction,
    required this.targetHandle,
    required this.scope,
    required this.payload,
  });

  final int coreRevision;
  final LedgerDirection direction;
  final int targetHandle;
  final LedgerTimeScope scope;
  final DashboardBudgetSecondaryAnalysisPayload payload;

  bool matches({
    required int coreRevision,
    required LedgerDirection direction,
    required int targetHandle,
    required LedgerTimeScope scope,
  }) =>
      this.coreRevision == coreRevision &&
      this.direction == direction &&
      this.targetHandle == targetHandle &&
      this.scope == scope;
}

enum BudgetAnalysisAvailability { available, unavailable, future }

enum BudgetAnalysisBarDirection { unavailable, up, down }

sealed class DashboardBudgetSecondaryAnalysisPayload {
  const DashboardBudgetSecondaryAnalysisPayload(this.availability);

  final BudgetAnalysisAvailability availability;

  bool get isAvailable => availability == BudgetAnalysisAvailability.available;
}

/// SUM payload. Utilization is intentionally an equal-weight average of
/// eligible months, never total actual / total limit.
final class DashboardBudgetSumAnalysis
    extends DashboardBudgetSecondaryAnalysisPayload {
  const DashboardBudgetSumAnalysis({
    required BudgetAnalysisAvailability availability,
    required this.averageUtilization,
    required this.averageBudgetDeltaScaled100,
    required this.eligibleMonthCount,
    required this.monthsWithinBudget,
    required this.utilizationStandardDeviation,
  }) : super(availability);

  final double? averageUtilization;
  final int? averageBudgetDeltaScaled100;
  final int eligibleMonthCount;
  final int monthsWithinBudget;
  final double? utilizationStandardDeviation;
}

final class DashboardBudgetYearMonthAnalysis {
  const DashboardBudgetYearMonthAnalysis({
    required this.month,
    required this.availability,
    required this.actualScaled100,
    required this.limitScaled100,
    required this.budgetDeltaScaled100,
    required this.barDirection,
    required this.isCompleted,
  });

  final int month;
  final BudgetAnalysisAvailability availability;
  final int? actualScaled100;
  final int? limitScaled100;

  /// `limit - actual`: negative means overspend and is deliberately rendered
  /// upward; positive reserve is deliberately rendered downward.
  final int? budgetDeltaScaled100;
  final BudgetAnalysisBarDirection barDirection;
  final bool isCompleted;
}

final class DashboardBudgetYearAnalysis
    extends DashboardBudgetSecondaryAnalysisPayload {
  DashboardBudgetYearAnalysis({
    required BudgetAnalysisAvailability availability,
    required List<DashboardBudgetYearMonthAnalysis> months,
    required this.completedEligibleMonthCount,
    required this.completedWithinBudgetCount,
    required this.largestOverspendScaled100,
    required this.largestReserveScaled100,
  }) : months = List<DashboardBudgetYearMonthAnalysis>.unmodifiable(months),
       super(availability);

  final List<DashboardBudgetYearMonthAnalysis> months;
  final int completedEligibleMonthCount;
  final int completedWithinBudgetCount;
  final int? largestOverspendScaled100;
  final int? largestReserveScaled100;
}

final class DashboardBudgetMonthSecondaryAnalysis
    extends DashboardBudgetSecondaryAnalysisPayload {
  const DashboardBudgetMonthSecondaryAnalysis({
    required BudgetAnalysisAvailability availability,
    required this.daysInMonth,
    required this.elapsedCalendarDays,
    required this.monthActualScaled100,
    required this.monthlyLimitScaled100,
    required this.elapsedRatio,
    required this.budgetUsedRatio,
    required this.paceDifferencePercentagePoints,
    required this.projectedMonthEndScaled100,
    required this.expectedDeltaScaled100,
    required this.closingBudgetDeltaScaled100,
    required this.remainingDailyRoomScaled100,
    required this.historicalDailyAverageScaled100,
    required this.usesForecast,
  }) : super(availability);

  final int daysInMonth;
  final int elapsedCalendarDays;
  final int? monthActualScaled100;
  final int? monthlyLimitScaled100;
  final double? elapsedRatio;
  final double? budgetUsedRatio;
  final double? paceDifferencePercentagePoints;
  final int? projectedMonthEndScaled100;

  /// Current-month signed projected overspend: `projected - limit`.
  final int? expectedDeltaScaled100;

  /// Completed-month signed reserve: `limit - actual`.
  final int? closingBudgetDeltaScaled100;
  final int? remainingDailyRoomScaled100;
  final int? historicalDailyAverageScaled100;
  final bool usesForecast;
}

final class DashboardBudgetDaySecondaryAnalysis
    extends DashboardBudgetSecondaryAnalysisPayload {
  const DashboardBudgetDaySecondaryAnalysis({
    required BudgetAnalysisAvailability availability,
    required this.selectedDayActualScaled100,
    required this.spentBeforeSelectedDayScaled100,
    required this.dailyRoomBeforeScaled100,
    required this.dailyRoomAfterScaled100,
    required this.dailyRoomChangeScaled100,
    required this.remainingSpendableTodayScaled100,
    required this.monthlyDeltaScaled100,
    required this.usesForecast,
    required this.isTerminalDay,
  }) : super(availability);

  final int? selectedDayActualScaled100;
  final int? spentBeforeSelectedDayScaled100;
  final int? dailyRoomBeforeScaled100;
  final int? dailyRoomAfterScaled100;
  final int? dailyRoomChangeScaled100;
  final int? remainingSpendableTodayScaled100;
  final int? monthlyDeltaScaled100;
  final bool usesForecast;
  final bool isTerminalDay;
}

/// Pure calculation owner for the secondary SUM/YEAR/MONTH/DAY visual card.
///
/// All money stays in scaled integers. Ratios are the only floating values and
/// exist solely as renderer-ready dimensions/percentages. This class owns the
/// calendar boundary policy so no widget can silently choose a different
/// denominator.
abstract final class DashboardBudgetSecondaryAnalysisProjector {
  static DashboardBudgetSecondaryAnalysisFrame project({
    required PreparedBudgetLimitSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required LedgerTimeScope scope,
    required LocalDate logicalAsOfDate,
  }) {
    final isKnownTarget =
        targetHandle >= 0 && targetHandle < snapshot.targetCountFor(direction);
    final payload = !isKnownTarget
        ? _unavailableFor(scope)
        : switch (scope) {
            AllTimeScope() => _sum(
              snapshot: snapshot,
              direction: direction,
              targetHandle: targetHandle,
              logicalAsOfDate: logicalAsOfDate,
            ),
            YearScope(:final year) => _year(
              snapshot: snapshot,
              direction: direction,
              targetHandle: targetHandle,
              year: year,
              logicalAsOfDate: logicalAsOfDate,
            ),
            MonthScope(:final value) => _month(
              snapshot: snapshot,
              direction: direction,
              targetHandle: targetHandle,
              year: value.year,
              month: value.month,
              logicalAsOfDate: logicalAsOfDate,
            ),
            DayScope(:final date) => _day(
              snapshot: snapshot,
              direction: direction,
              targetHandle: targetHandle,
              selectedDay: date,
              logicalAsOfDate: logicalAsOfDate,
            ),
          };
    return DashboardBudgetSecondaryAnalysisFrame(
      coreRevision: snapshot.coreRevision,
      direction: direction,
      targetHandle: targetHandle,
      scope: scope,
      payload: payload,
    );
  }

  static DashboardBudgetSecondaryAnalysisPayload _unavailableFor(
    LedgerTimeScope scope,
  ) => switch (scope) {
    AllTimeScope() => const DashboardBudgetSumAnalysis(
      availability: BudgetAnalysisAvailability.unavailable,
      averageUtilization: null,
      averageBudgetDeltaScaled100: null,
      eligibleMonthCount: 0,
      monthsWithinBudget: 0,
      utilizationStandardDeviation: null,
    ),
    YearScope() => DashboardBudgetYearAnalysis(
      availability: BudgetAnalysisAvailability.unavailable,
      months: List<DashboardBudgetYearMonthAnalysis>.generate(
        12,
        (index) => DashboardBudgetYearMonthAnalysis(
          month: index + 1,
          availability: BudgetAnalysisAvailability.unavailable,
          actualScaled100: null,
          limitScaled100: null,
          budgetDeltaScaled100: null,
          barDirection: BudgetAnalysisBarDirection.unavailable,
          isCompleted: false,
        ),
      ),
      completedEligibleMonthCount: 0,
      completedWithinBudgetCount: 0,
      largestOverspendScaled100: null,
      largestReserveScaled100: null,
    ),
    MonthScope(:final value) => DashboardBudgetMonthSecondaryAnalysis(
      availability: BudgetAnalysisAvailability.unavailable,
      daysInMonth: _daysInMonth(value.year, value.month),
      elapsedCalendarDays: 0,
      monthActualScaled100: null,
      monthlyLimitScaled100: null,
      elapsedRatio: null,
      budgetUsedRatio: null,
      paceDifferencePercentagePoints: null,
      projectedMonthEndScaled100: null,
      expectedDeltaScaled100: null,
      closingBudgetDeltaScaled100: null,
      remainingDailyRoomScaled100: null,
      historicalDailyAverageScaled100: null,
      usesForecast: false,
    ),
    DayScope() => const DashboardBudgetDaySecondaryAnalysis(
      availability: BudgetAnalysisAvailability.unavailable,
      selectedDayActualScaled100: null,
      spentBeforeSelectedDayScaled100: null,
      dailyRoomBeforeScaled100: null,
      dailyRoomAfterScaled100: null,
      dailyRoomChangeScaled100: null,
      remainingSpendableTodayScaled100: null,
      monthlyDeltaScaled100: null,
      usesForecast: false,
      isTerminalDay: false,
    ),
  };

  static DashboardBudgetSumAnalysis _sum({
    required PreparedBudgetLimitSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required LocalDate logicalAsOfDate,
  }) {
    final utilization = <double>[];
    var totalDelta = 0;
    var withinBudget = 0;
    for (
      var year = snapshot.yearWindowStart;
      year <= snapshot.yearWindowEndInclusive;
      year += 1
    ) {
      for (var month = 1; month <= 12; month += 1) {
        if (_compareYearMonth(
              year,
              month,
              logicalAsOfDate.year,
              logicalAsOfDate.month,
            ) >=
            0) {
          continue;
        }
        final cell = snapshot.cellAt(
          direction: direction,
          period: BudgetLimitPeriod.month(year, month),
          targetHandle: targetHandle,
        );
        final limit = _positiveLimit(cell.limitScaled100);
        if (limit == null) continue;
        final delta = limit - cell.actualScaled100;
        utilization.add(cell.actualScaled100 / limit);
        totalDelta += delta;
        if (delta >= 0) withinBudget += 1;
      }
    }
    if (utilization.isEmpty) {
      return const DashboardBudgetSumAnalysis(
        availability: BudgetAnalysisAvailability.unavailable,
        averageUtilization: null,
        averageBudgetDeltaScaled100: null,
        eligibleMonthCount: 0,
        monthsWithinBudget: 0,
        utilizationStandardDeviation: null,
      );
    }
    final mean =
        utilization.reduce((left, right) => left + right) / utilization.length;
    final variance =
        utilization
            .map((value) => (value - mean) * (value - mean))
            .reduce((left, right) => left + right) /
        utilization.length;
    return DashboardBudgetSumAnalysis(
      availability: BudgetAnalysisAvailability.available,
      averageUtilization: mean,
      averageBudgetDeltaScaled100: _roundDivision(
        totalDelta,
        utilization.length,
      ),
      eligibleMonthCount: utilization.length,
      monthsWithinBudget: withinBudget,
      utilizationStandardDeviation: _sqrt(variance),
    );
  }

  static DashboardBudgetYearAnalysis _year({
    required PreparedBudgetLimitSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required int year,
    required LocalDate logicalAsOfDate,
  }) {
    if (year < snapshot.yearWindowStart ||
        year > snapshot.yearWindowEndInclusive) {
      return _unavailableFor(YearScope(year)) as DashboardBudgetYearAnalysis;
    }
    final months = <DashboardBudgetYearMonthAnalysis>[];
    var eligible = 0;
    var within = 0;
    int? largestOverspend;
    int? largestReserve;
    for (var month = 1; month <= 12; month += 1) {
      final comparison = _compareYearMonth(
        year,
        month,
        logicalAsOfDate.year,
        logicalAsOfDate.month,
      );
      if (comparison > 0) {
        months.add(
          DashboardBudgetYearMonthAnalysis(
            month: month,
            availability: BudgetAnalysisAvailability.future,
            actualScaled100: null,
            limitScaled100: null,
            budgetDeltaScaled100: null,
            barDirection: BudgetAnalysisBarDirection.unavailable,
            isCompleted: false,
          ),
        );
        continue;
      }
      final cell = snapshot.cellAt(
        direction: direction,
        period: BudgetLimitPeriod.month(year, month),
        targetHandle: targetHandle,
      );
      final limit = _positiveLimit(cell.limitScaled100);
      if (limit == null) {
        months.add(
          DashboardBudgetYearMonthAnalysis(
            month: month,
            availability: BudgetAnalysisAvailability.unavailable,
            actualScaled100: cell.actualScaled100,
            limitScaled100: null,
            budgetDeltaScaled100: null,
            barDirection: BudgetAnalysisBarDirection.unavailable,
            isCompleted: comparison < 0,
          ),
        );
        continue;
      }
      final delta = limit - cell.actualScaled100;
      final completed = comparison < 0;
      if (completed) {
        eligible += 1;
        if (delta >= 0) {
          within += 1;
          largestReserve = _maxNullable(largestReserve, delta);
        } else {
          largestOverspend = _maxNullable(largestOverspend, -delta);
        }
      }
      months.add(
        DashboardBudgetYearMonthAnalysis(
          month: month,
          availability: BudgetAnalysisAvailability.available,
          actualScaled100: cell.actualScaled100,
          limitScaled100: limit,
          budgetDeltaScaled100: delta,
          barDirection: delta < 0
              ? BudgetAnalysisBarDirection.up
              : BudgetAnalysisBarDirection.down,
          isCompleted: completed,
        ),
      );
    }
    return DashboardBudgetYearAnalysis(
      availability: BudgetAnalysisAvailability.available,
      months: months,
      completedEligibleMonthCount: eligible,
      completedWithinBudgetCount: within,
      largestOverspendScaled100: largestOverspend,
      largestReserveScaled100: largestReserve,
    );
  }

  static DashboardBudgetMonthSecondaryAnalysis _month({
    required PreparedBudgetLimitSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required int year,
    required int month,
    required LocalDate logicalAsOfDate,
  }) {
    final days = _daysInMonth(year, month);
    if (year < snapshot.yearWindowStart ||
        year > snapshot.yearWindowEndInclusive) {
      return _unavailableFor(MonthScope(_yearMonth(year, month)))
          as DashboardBudgetMonthSecondaryAnalysis;
    }
    final comparison = _compareYearMonth(
      year,
      month,
      logicalAsOfDate.year,
      logicalAsOfDate.month,
    );
    if (comparison > 0) {
      return DashboardBudgetMonthSecondaryAnalysis(
        availability: BudgetAnalysisAvailability.future,
        daysInMonth: days,
        elapsedCalendarDays: 0,
        monthActualScaled100: null,
        monthlyLimitScaled100: null,
        elapsedRatio: null,
        budgetUsedRatio: null,
        paceDifferencePercentagePoints: null,
        projectedMonthEndScaled100: null,
        expectedDeltaScaled100: null,
        closingBudgetDeltaScaled100: null,
        remainingDailyRoomScaled100: null,
        historicalDailyAverageScaled100: null,
        usesForecast: false,
      );
    }
    final cell = snapshot.cellAt(
      direction: direction,
      period: BudgetLimitPeriod.month(year, month),
      targetHandle: targetHandle,
    );
    final limit = _positiveLimit(cell.limitScaled100);
    if (limit == null) {
      return DashboardBudgetMonthSecondaryAnalysis(
        availability: BudgetAnalysisAvailability.unavailable,
        daysInMonth: days,
        elapsedCalendarDays: comparison < 0 ? days : logicalAsOfDate.day,
        monthActualScaled100: cell.actualScaled100,
        monthlyLimitScaled100: null,
        elapsedRatio: null,
        budgetUsedRatio: null,
        paceDifferencePercentagePoints: null,
        projectedMonthEndScaled100: null,
        expectedDeltaScaled100: null,
        closingBudgetDeltaScaled100: null,
        remainingDailyRoomScaled100: null,
        historicalDailyAverageScaled100: null,
        usesForecast: false,
      );
    }
    final elapsed = comparison < 0
        ? days
        : logicalAsOfDate.day.clamp(1, days).toInt();
    final actual = cell.actualScaled100;
    final current = comparison == 0;
    final projected = current ? _roundDivision(actual * days, elapsed) : actual;
    final usedRatio = actual / limit;
    final elapsedRatio = elapsed / days;
    final remainingDaysAfterCurrentDay = current ? days - elapsed : 0;
    return DashboardBudgetMonthSecondaryAnalysis(
      availability: BudgetAnalysisAvailability.available,
      daysInMonth: days,
      elapsedCalendarDays: elapsed,
      monthActualScaled100: actual,
      monthlyLimitScaled100: limit,
      elapsedRatio: elapsedRatio,
      budgetUsedRatio: usedRatio,
      paceDifferencePercentagePoints: (usedRatio - elapsedRatio) * 100,
      projectedMonthEndScaled100: projected,
      expectedDeltaScaled100: current ? projected - limit : null,
      closingBudgetDeltaScaled100: current ? null : limit - actual,
      remainingDailyRoomScaled100: current && remainingDaysAfterCurrentDay > 0
          ? _roundDivision(
              (limit - actual).clamp(0, limit).toInt(),
              remainingDaysAfterCurrentDay,
            )
          : null,
      historicalDailyAverageScaled100: current
          ? null
          : _roundDivision(actual, days),
      usesForecast: current,
    );
  }

  static DashboardBudgetDaySecondaryAnalysis _day({
    required PreparedBudgetLimitSnapshot snapshot,
    required LedgerDirection direction,
    required int targetHandle,
    required LocalDate selectedDay,
    required LocalDate logicalAsOfDate,
  }) {
    final dayComparison = _compareDate(selectedDay, logicalAsOfDate);
    if (dayComparison > 0) {
      return const DashboardBudgetDaySecondaryAnalysis(
        availability: BudgetAnalysisAvailability.future,
        selectedDayActualScaled100: null,
        spentBeforeSelectedDayScaled100: null,
        dailyRoomBeforeScaled100: null,
        dailyRoomAfterScaled100: null,
        dailyRoomChangeScaled100: null,
        remainingSpendableTodayScaled100: null,
        monthlyDeltaScaled100: null,
        usesForecast: false,
        isTerminalDay: false,
      );
    }
    if (selectedDay.year < snapshot.yearWindowStart ||
        selectedDay.year > snapshot.yearWindowEndInclusive) {
      return _unavailableFor(DayScope(selectedDay))
          as DashboardBudgetDaySecondaryAnalysis;
    }
    final cell = snapshot.cellAt(
      direction: direction,
      period: BudgetLimitPeriod.month(selectedDay.year, selectedDay.month),
      targetHandle: targetHandle,
    );
    final limit = _positiveLimit(cell.limitScaled100);
    final rhythm = snapshot.spendingRhythmSnapshot;
    if (limit == null ||
        rhythm == null ||
        rhythm.coreRevision != snapshot.coreRevision) {
      return _unavailableFor(DayScope(selectedDay))
          as DashboardBudgetDaySecondaryAnalysis;
    }
    final bank = rhythm.directionBank(direction);
    if (targetHandle >= bank.targetCount) {
      return _unavailableFor(DayScope(selectedDay))
          as DashboardBudgetDaySecondaryAnalysis;
    }
    final target = bank.targetView(targetHandle);
    final selectedActual = target.actualAtEpochDay(selectedDay.epochDay);
    final spentBefore = target.actualForMonthThroughEpochDay(
      year: selectedDay.year,
      month: selectedDay.month,
      throughEpochDay: selectedDay.epochDay - 1,
    );
    final days = _daysInMonth(selectedDay.year, selectedDay.month);
    final remainingInclusive = days - selectedDay.day + 1;
    final remainingAfter = days - selectedDay.day;
    final before = _roundDivision(
      (limit - spentBefore).clamp(0, limit).toInt(),
      remainingInclusive,
    );
    final after = remainingAfter == 0
        ? null
        : _roundDivision(
            (limit - spentBefore - selectedActual).clamp(0, limit).toInt(),
            remainingAfter,
          );
    final isCurrentDay = dayComparison == 0;
    final monthComparison = _compareYearMonth(
      selectedDay.year,
      selectedDay.month,
      logicalAsOfDate.year,
      logicalAsOfDate.month,
    );
    final throughSelected = spentBefore + selectedActual;
    final monthlyDelta = monthComparison < 0
        ? cell.actualScaled100 - limit
        : isCurrentDay
        ? _roundDivision(throughSelected * days, selectedDay.day) - limit
        : null;
    return DashboardBudgetDaySecondaryAnalysis(
      availability: BudgetAnalysisAvailability.available,
      selectedDayActualScaled100: selectedActual,
      spentBeforeSelectedDayScaled100: spentBefore,
      dailyRoomBeforeScaled100: before,
      dailyRoomAfterScaled100: after,
      dailyRoomChangeScaled100: after == null ? null : after - before,
      remainingSpendableTodayScaled100: (before - selectedActual)
          .clamp(0, before)
          .toInt(),
      monthlyDeltaScaled100: monthlyDelta,
      usesForecast: isCurrentDay && monthComparison == 0,
      isTerminalDay: remainingAfter == 0,
    );
  }

  static int? _positiveLimit(int? value) =>
      value != null && value > 0 ? value : null;

  static int _daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  static int _compareYearMonth(
    int leftYear,
    int leftMonth,
    int rightYear,
    int rightMonth,
  ) {
    final byYear = leftYear.compareTo(rightYear);
    return byYear == 0 ? leftMonth.compareTo(rightMonth) : byYear;
  }

  static int _compareDate(LocalDate left, LocalDate right) {
    final month = _compareYearMonth(
      left.year,
      left.month,
      right.year,
      right.month,
    );
    return month == 0 ? left.day.compareTo(right.day) : month;
  }

  static int _roundDivision(int numerator, int denominator) {
    if (denominator <= 0) return 0;
    if (numerator >= 0) return (numerator + denominator ~/ 2) ~/ denominator;
    return -((-numerator + denominator ~/ 2) ~/ denominator);
  }

  static int? _maxNullable(int? current, int candidate) =>
      current == null || candidate > current ? candidate : current;

  static double _sqrt(double value) {
    if (value <= 0) return 0;
    var estimate = value;
    for (var iteration = 0; iteration < 12; iteration += 1) {
      estimate = (estimate + value / estimate) / 2;
    }
    return estimate;
  }

  static YearMonth _yearMonth(int year, int month) =>
      YearMonth(year: year, month: month);
}
