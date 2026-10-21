import 'financial_limit.dart';

/// Pure effective-dated limit fallback used by editor-facing presentation.
/// Native prepared snapshots apply this same ordering for every dashboard
/// denominator; keeping it named here prevents manual editors from growing a
/// second, ad-hoc historical-base rule.
abstract final class FinancialLimitResolution {
  static FinancialLimit? exactMonthOverride({
    required Iterable<FinancialLimit> limits,
    required FinancialLimitDirection direction,
    required FinancialLimitTarget target,
    required int year,
    required int month,
  }) {
    for (final limit in limits) {
      final period = limit.key.period;
      if (limit.key.direction == direction &&
          limit.key.target == target &&
          period is FinancialLimitMonthOverridePeriod &&
          period.year == year &&
          period.month == month) {
        return limit;
      }
    }
    return null;
  }

  static FinancialLimit? baseRevisionAtOrBefore({
    required Iterable<FinancialLimit> limits,
    required FinancialLimitDirection direction,
    required FinancialLimitTarget target,
    required int year,
    required int month,
  }) {
    FinancialLimit? candidate;
    final requested = _linear(year, month);
    for (final limit in limits) {
      final period = limit.key.period;
      if (limit.key.direction != direction ||
          limit.key.target != target ||
          period is! FinancialLimitBaseMonthlyRevisionPeriod) {
        continue;
      }
      final effective = _linear(
        period.effectiveFromYear,
        period.effectiveFromMonth,
      );
      if (effective <= requested &&
          (candidate == null ||
              effective > _revisionLinear(candidate.key.period))) {
        candidate = limit;
      }
    }
    return candidate;
  }

  /// Exact override > latest base revision effective on/before month > none.
  static FinancialLimit? resolve({
    required Iterable<FinancialLimit> limits,
    required FinancialLimitDirection direction,
    required FinancialLimitTarget target,
    required int year,
    required int month,
  }) =>
      exactMonthOverride(
        limits: limits,
        direction: direction,
        target: target,
        year: year,
        month: month,
      ) ??
      baseRevisionAtOrBefore(
        limits: limits,
        direction: direction,
        target: target,
        year: year,
        month: month,
      );

  static int _revisionLinear(FinancialLimitPeriod period) {
    final revision = period as FinancialLimitBaseMonthlyRevisionPeriod;
    return _linear(revision.effectiveFromYear, revision.effectiveFromMonth);
  }

  static int _linear(int year, int month) => year * 12 + month;
}
