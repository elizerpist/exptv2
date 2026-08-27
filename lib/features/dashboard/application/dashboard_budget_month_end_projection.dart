import 'package:flutter/foundation.dart';

import '../../../core/categories/domain/budget_progress_health.dart';
import '../query/domain/ledger_direction.dart';
import '../time_navigation/domain/local_date.dart';

/// The semantic availability of a containing-month daily-pace calculation.
///
/// A future month intentionally has no fabricated daily pace. Its forecast is
/// represented as an unavailable zero value rather than an infinity or a
/// divided monthly allowance.
enum DashboardBudgetMonthEndProjectionAvailability { available, unavailable }

/// Semantic progress bands are resolved from the unbounded forecast ratio.
/// Renderers map these to the existing Budget accent/warning/danger tokens.
enum DashboardBudgetProjectionHealthBand {
  unavailable,
  targetAccent,
  warning,
  danger,
}

/// Stable identity for derived DAY pace and its secondary month-end forecast.
///
/// Crucially, [selectedDay] is absent. Moving between days in the same visible
/// month must change the Day LogBox and Summary data without changing the
/// Budget forecast itself. The effective monthly limit is present because the
/// complete presentation also contains a limit-dependent ratio and gauge.
@immutable
final class DashboardBudgetMonthEndProjectionKey {
  const DashboardBudgetMonthEndProjectionKey({
    required this.coreRevision,
    required this.direction,
    required this.targetHandle,
    required this.year,
    required this.month,
    required this.logicalAsOfDate,
    required this.effectiveMonthlyLimitScaled100,
  });

  final int coreRevision;
  final LedgerDirection direction;
  final int targetHandle;
  final int year;
  final int month;
  final LocalDate logicalAsOfDate;
  final int? effectiveMonthlyLimitScaled100;

  @override
  bool operator ==(Object other) =>
      other is DashboardBudgetMonthEndProjectionKey &&
      other.coreRevision == coreRevision &&
      other.direction == direction &&
      other.targetHandle == targetHandle &&
      other.year == year &&
      other.month == month &&
      other.logicalAsOfDate == logicalAsOfDate &&
      other.effectiveMonthlyLimitScaled100 == effectiveMonthlyLimitScaled100;

  @override
  int get hashCode => Object.hash(
    coreRevision,
    direction,
    targetHandle,
    year,
    month,
    logicalAsOfDate,
    effectiveMonthlyLimitScaled100,
  );
}

/// Pure, immutable Daily Budget pace input over the existing monthly
/// FinancialLimit model.
///
/// This is not a persisted financial actual. The DAY primary concepts are
/// [actualDailyAverageScaled100], [allowedDailyAverageScaled100], and
/// [paceRatio]. [projectedMonthEndScaled100] remains a secondary mathematical
/// forecast. Limit editing, allocation partitions and canonical accounting
/// still use the containing month's prepared actual separately.
@immutable
final class DashboardBudgetMonthEndProjection {
  const DashboardBudgetMonthEndProjection._({
    required this.key,
    required this.availability,
    required this.monthToDateActualScaled100,
    required this.elapsedCalendarDays,
    required this.daysInMonth,
    required this.actualDailyAverageScaled100,
    required this.allowedDailyAverageScaled100,
    required this.paceRatio,
    required this.projectedMonthEndScaled100,
    required this.effectiveMonthlyLimitScaled100,
    required this.projectionRatio,
    required this.gaugeFillRatio,
    required this.breakEvenGaugeRatio,
    required this.healthBand,
  });

  /// Derives one daily pace and a secondary month-end forecast from already
  /// prepared scalar values.
  ///
  /// Positive scaled-money division rounds half up, matching the project's
  /// existing integer percentage convention: `(numerator + divisor ~/ 2) ~/
  /// divisor`. No double money conversion occurs before the final visual ratio.
  factory DashboardBudgetMonthEndProjection.derive({
    required int coreRevision,
    required LedgerDirection direction,
    required int targetHandle,
    required int year,
    required int month,
    required LocalDate logicalAsOfDate,
    required int monthToDateActualScaled100,
    required int finalMonthActualScaled100,
    required int? effectiveMonthlyLimitScaled100,
  }) {
    if (monthToDateActualScaled100 < 0 || finalMonthActualScaled100 < 0) {
      throw ArgumentError('Budget actuals cannot be negative.');
    }
    final key = DashboardBudgetMonthEndProjectionKey(
      coreRevision: coreRevision,
      direction: direction,
      targetHandle: targetHandle,
      year: year,
      month: month,
      logicalAsOfDate: logicalAsOfDate,
      effectiveMonthlyLimitScaled100: effectiveMonthlyLimitScaled100,
    );
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;
    final comparison = _compareYearMonth(
      year,
      month,
      logicalAsOfDate.year,
      logicalAsOfDate.month,
    );
    final availability = comparison > 0
        ? DashboardBudgetMonthEndProjectionAvailability.unavailable
        : DashboardBudgetMonthEndProjectionAvailability.available;
    final elapsed = switch (comparison) {
      < 0 => daysInMonth,
      0 => logicalAsOfDate.day.clamp(1, daysInMonth),
      _ => 0,
    };
    final sourceActual = comparison < 0
        ? finalMonthActualScaled100
        : comparison == 0
        ? monthToDateActualScaled100
        : 0;
    final actualDailyAverage =
        availability ==
            DashboardBudgetMonthEndProjectionAvailability.unavailable
        ? null
        : _roundPositiveDivision(sourceActual, elapsed);
    final hasLimit =
        effectiveMonthlyLimitScaled100 != null &&
        effectiveMonthlyLimitScaled100 > 0;
    final allowedDailyAverage =
        availability ==
                DashboardBudgetMonthEndProjectionAvailability.unavailable ||
            !hasLimit
        ? null
        : _roundPositiveDivision(effectiveMonthlyLimitScaled100, daysInMonth);
    final projected = switch (availability) {
      DashboardBudgetMonthEndProjectionAvailability.unavailable => 0,
      DashboardBudgetMonthEndProjectionAvailability.available
          when comparison < 0 =>
        finalMonthActualScaled100,
      DashboardBudgetMonthEndProjectionAvailability.available =>
        _roundPositiveDivision(sourceActual * daysInMonth, elapsed),
    };
    // Keep pace semantics rational until the final ratio. Dividing rounded
    // daily header amounts here would silently change health at fractional
    // cent boundaries. The equivalent projected-month ratio stays available
    // as a secondary forecast identity, not as the primary DAY terminology.
    final paceRatio =
        availability ==
                DashboardBudgetMonthEndProjectionAvailability.unavailable ||
            !hasLimit
        ? 0.0
        : sourceActual *
              daysInMonth /
              (elapsed * effectiveMonthlyLimitScaled100);
    final fill = _boundedGaugeFill(paceRatio);
    return DashboardBudgetMonthEndProjection._(
      key: key,
      availability: availability,
      monthToDateActualScaled100: sourceActual,
      elapsedCalendarDays: elapsed,
      daysInMonth: daysInMonth,
      actualDailyAverageScaled100: actualDailyAverage,
      allowedDailyAverageScaled100: allowedDailyAverage,
      paceRatio: paceRatio,
      projectedMonthEndScaled100: projected,
      effectiveMonthlyLimitScaled100: effectiveMonthlyLimitScaled100,
      projectionRatio: paceRatio,
      gaugeFillRatio: fill,
      breakEvenGaugeRatio: .75,
      healthBand: _healthFor(availability: availability, rawRatio: paceRatio),
    );
  }

  final DashboardBudgetMonthEndProjectionKey key;
  final DashboardBudgetMonthEndProjectionAvailability availability;
  final int monthToDateActualScaled100;
  final int elapsedCalendarDays;
  final int daysInMonth;

  /// Rounded, localized-header-ready actual spend per elapsed calendar day.
  /// Null means a future month, for which pace is intentionally undefined.
  final int? actualDailyAverageScaled100;

  /// Rounded, localized-header-ready sustainable spend per calendar day from
  /// the same containing-month limit. Null also covers a missing/zero limit.
  final int? allowedDailyAverageScaled100;

  /// Exact unbounded daily pace ratio. This intentionally retains the
  /// rational month-spend × days / (elapsed × monthly-limit) value instead of
  /// dividing rounded header amounts.
  final double paceRatio;

  /// Secondary forecast only; never the DAY Header's primary value.
  final int projectedMonthEndScaled100;
  final int? effectiveMonthlyLimitScaled100;
  final double projectionRatio;
  final double gaugeFillRatio;
  final double breakEvenGaugeRatio;
  final DashboardBudgetProjectionHealthBand healthBand;

  bool get isAvailable =>
      availability == DashboardBudgetMonthEndProjectionAvailability.available;

  static int _roundPositiveDivision(int numerator, int divisor) {
    if (divisor <= 0) return 0;
    return (numerator + divisor ~/ 2) ~/ divisor;
  }

  static int _compareYearMonth(
    int leftYear,
    int leftMonth,
    int rightYear,
    int rightMonth,
  ) {
    final byYear = leftYear.compareTo(rightYear);
    return byYear == 0 ? leftMonth.compareTo(rightMonth) : byYear;
  }

  static double _boundedGaugeFill(double rawRatio) =>
      !rawRatio.isFinite ? 0 : (rawRatio * .75).clamp(0.0, 1.0).toDouble();

  static DashboardBudgetProjectionHealthBand _healthFor({
    required DashboardBudgetMonthEndProjectionAvailability availability,
    required double rawRatio,
  }) => switch (BudgetProgressHealthResolver.resolve(
    isAvailable:
        availability == DashboardBudgetMonthEndProjectionAvailability.available,
    rawRatio: rawRatio,
  )) {
    BudgetProgressHealth.unavailable =>
      DashboardBudgetProjectionHealthBand.unavailable,
    BudgetProgressHealth.targetAccent =>
      DashboardBudgetProjectionHealthBand.targetAccent,
    BudgetProgressHealth.warning => DashboardBudgetProjectionHealthBand.warning,
    BudgetProgressHealth.danger => DashboardBudgetProjectionHealthBand.danger,
  };
}
