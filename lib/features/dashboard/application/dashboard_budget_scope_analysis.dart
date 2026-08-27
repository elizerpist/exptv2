import 'package:flutter/foundation.dart';

import '../../../core/categories/domain/budget_progress_health.dart';
import 'dashboard_budget_month_end_projection.dart';

/// Persistence provenance of one effective monthly denominator. Widgets never
/// implement the base/override fallback rule themselves.
enum DashboardBudgetMonthlyLimitSource { base, override, unavailable }

@immutable
final class DashboardBudgetResolvedMonthlyLimit {
  const DashboardBudgetResolvedMonthlyLimit.available({
    required this.amountScaled100,
    required this.source,
  }) : assert(amountScaled100 != null && amountScaled100 >= 0),
       assert(source != DashboardBudgetMonthlyLimitSource.unavailable);

  const DashboardBudgetResolvedMonthlyLimit.unavailable()
    : amountScaled100 = null,
      source = DashboardBudgetMonthlyLimitSource.unavailable;

  final int? amountScaled100;
  final DashboardBudgetMonthlyLimitSource source;

  bool get isAvailable => amountScaled100 != null;

  @override
  bool operator ==(Object other) =>
      other is DashboardBudgetResolvedMonthlyLimit &&
      other.amountScaled100 == amountScaled100 &&
      other.source == source;

  @override
  int get hashCode => Object.hash(amountScaled100, source);
}

/// The only base/override fallback rule. Native prepared snapshots and the
/// presentation controller both consume this pure contract.
final class DashboardBudgetResolvedMonthlyLimitResolver {
  const DashboardBudgetResolvedMonthlyLimitResolver();

  DashboardBudgetResolvedMonthlyLimit resolve({
    required int? baseMonthlyLimitScaled100,
    required int? overrideScaled100,
  }) {
    if (overrideScaled100 != null) {
      return DashboardBudgetResolvedMonthlyLimit.available(
        amountScaled100: overrideScaled100,
        source: DashboardBudgetMonthlyLimitSource.override,
      );
    }
    if (baseMonthlyLimitScaled100 != null) {
      return DashboardBudgetResolvedMonthlyLimit.available(
        amountScaled100: baseMonthlyLimitScaled100,
        source: DashboardBudgetMonthlyLimitSource.base,
      );
    }
    return const DashboardBudgetResolvedMonthlyLimit.unavailable();
  }
}

/// Distinct semantic scope values prevent forecast, annual aggregation, and
/// typical-month statistics from being treated as one generic actual field.
sealed class DashboardBudgetScopeAnalysis {
  const DashboardBudgetScopeAnalysis({
    required this.displayNumeratorScaled100,
    required this.displayDenominatorScaled100,
    required this.canonicalActualScaled100ForLimitEdit,
    required this.canonicalLimitScaled100ForEdit,
    this.rawRatioOverride,
  });

  final int? displayNumeratorScaled100;
  final int? displayDenominatorScaled100;
  final int? canonicalActualScaled100ForLimitEdit;
  final int? canonicalLimitScaled100ForEdit;

  /// DAY pace retains rational precision here rather than reverse-engineering
  /// a health ratio from rounded, header-ready daily money values.
  final double? rawRatioOverride;

  double get rawRatio =>
      rawRatioOverride ??
      (displayNumeratorScaled100 != null &&
              displayDenominatorScaled100 != null &&
              displayDenominatorScaled100! > 0
          ? displayNumeratorScaled100! / displayDenominatorScaled100!
          : 0);

  BudgetProgressHealth get health => BudgetProgressHealthResolver.resolve(
    isAvailable:
        displayNumeratorScaled100 != null &&
        displayDenominatorScaled100 != null &&
        displayDenominatorScaled100! > 0,
    rawRatio: rawRatio,
  );
}

final class DashboardBudgetMonthAnalysis extends DashboardBudgetScopeAnalysis {
  const DashboardBudgetMonthAnalysis({
    required int monthlyActualScaled100,
    required int? resolvedMonthlyLimitScaled100,
  }) : super(
         displayNumeratorScaled100: monthlyActualScaled100,
         displayDenominatorScaled100: resolvedMonthlyLimitScaled100,
         canonicalActualScaled100ForLimitEdit: monthlyActualScaled100,
         canonicalLimitScaled100ForEdit: resolvedMonthlyLimitScaled100,
       );
}

final class DashboardBudgetDayProjectionAnalysis
    extends DashboardBudgetScopeAnalysis {
  DashboardBudgetDayProjectionAnalysis({
    required this.projection,
    required int canonicalMonthlyActualScaled100,
  }) : super(
         displayNumeratorScaled100: projection.actualDailyAverageScaled100,
         displayDenominatorScaled100: projection.allowedDailyAverageScaled100,
         canonicalActualScaled100ForLimitEdit: canonicalMonthlyActualScaled100,
         canonicalLimitScaled100ForEdit:
             projection.effectiveMonthlyLimitScaled100,
         rawRatioOverride: projection.paceRatio,
       );

  final DashboardBudgetMonthEndProjection projection;
}

final class DashboardBudgetYearAnalysis extends DashboardBudgetScopeAnalysis {
  const DashboardBudgetYearAnalysis({
    required int annualActualScaled100,
    required int? annualResolvedLimitScaled100,
    required this.monthlyActualsScaled100,
    required this.monthlyResolvedLimitsScaled100,
  }) : assert(monthlyActualsScaled100.length == 12),
       assert(monthlyResolvedLimitsScaled100.length == 12),
       super(
         displayNumeratorScaled100: annualActualScaled100,
         displayDenominatorScaled100: annualResolvedLimitScaled100,
         canonicalActualScaled100ForLimitEdit: annualActualScaled100,
         canonicalLimitScaled100ForEdit: annualResolvedLimitScaled100,
       );

  final List<int> monthlyActualsScaled100;
  final List<int?> monthlyResolvedLimitsScaled100;
}

final class DashboardBudgetTypicalMonthAnalysis
    extends DashboardBudgetScopeAnalysis {
  DashboardBudgetTypicalMonthAnalysis({
    required DashboardBudgetTypicalMonthAverage average,
    required int? baseMonthlyLimitScaled100,
  }) : super(
         displayNumeratorScaled100: average.averageMonthlySpendScaled100,
         displayDenominatorScaled100: baseMonthlyLimitScaled100,
         canonicalActualScaled100ForLimitEdit: null,
         canonicalLimitScaled100ForEdit: baseMonthlyLimitScaled100,
       );
}

@immutable
final class DashboardBudgetYearLimitAllocation {
  const DashboardBudgetYearLimitAllocation(this.monthlyLimitsScaled100);

  final List<int> monthlyLimitsScaled100;
}

/// Exact largest-remainder allocation for one semantic annual edit. Production
/// calls use twelve entries, but the pure primitive accepts any nonempty size.
abstract final class DashboardBudgetYearLimitAllocator {
  static DashboardBudgetYearLimitAllocation allocate({
    required List<int> currentMonthlyLimitsScaled100,
    required int requestedAnnualLimitScaled100,
  }) {
    if (currentMonthlyLimitsScaled100.isEmpty ||
        currentMonthlyLimitsScaled100.any((value) => value < 0) ||
        requestedAnnualLimitScaled100 < 0) {
      throw ArgumentError(
        'Monthly limit allocation requires nonnegative values.',
      );
    }
    final currentTotal = currentMonthlyLimitsScaled100.fold<int>(
      0,
      (total, value) => total + value,
    );
    if (currentTotal == 0) {
      return DashboardBudgetYearLimitAllocation(
        _evenlyDistributed(
          count: currentMonthlyLimitsScaled100.length,
          total: requestedAnnualLimitScaled100,
        ),
      );
    }
    final base = List<int>.filled(currentMonthlyLimitsScaled100.length, 0);
    final remainders = <({int index, int remainder})>[];
    var allocated = 0;
    for (
      var index = 0;
      index < currentMonthlyLimitsScaled100.length;
      index += 1
    ) {
      final numerator =
          currentMonthlyLimitsScaled100[index] * requestedAnnualLimitScaled100;
      base[index] = numerator ~/ currentTotal;
      allocated += base[index];
      remainders.add((index: index, remainder: numerator % currentTotal));
    }
    remainders.sort((left, right) {
      final byFraction = right.remainder.compareTo(left.remainder);
      return byFraction == 0 ? left.index.compareTo(right.index) : byFraction;
    });
    for (
      var unit = 0;
      unit < requestedAnnualLimitScaled100 - allocated;
      unit += 1
    ) {
      base[remainders[unit % remainders.length].index] += 1;
    }
    return DashboardBudgetYearLimitAllocation(List<int>.unmodifiable(base));
  }

  static List<int> _evenlyDistributed({
    required int count,
    required int total,
  }) {
    final base = total ~/ count;
    final remainder = total % count;
    return List<int>.unmodifiable([
      for (var index = 0; index < count; index += 1)
        base + (index < remainder ? 1 : 0),
    ]);
  }
}

/// Prepared/cacheable completed-month aggregate used by SUM. The caller owns
/// the calendar count, including zero-spend months; widgets cannot infer it
/// from sparse rhythm points.
@immutable
final class DashboardBudgetTypicalMonthAverage {
  const DashboardBudgetTypicalMonthAverage._({
    required this.averageMonthlySpendScaled100,
    required this.completedMonthCount,
  });

  const DashboardBudgetTypicalMonthAverage.unavailable()
    : averageMonthlySpendScaled100 = null,
      completedMonthCount = 0;

  factory DashboardBudgetTypicalMonthAverage.resolve({
    required int completedMonthSpendScaled100,
    required int completedMonthCount,
  }) {
    if (completedMonthSpendScaled100 < 0 || completedMonthCount < 0) {
      throw ArgumentError('Typical-month inputs must be nonnegative.');
    }
    if (completedMonthCount == 0) {
      return const DashboardBudgetTypicalMonthAverage.unavailable();
    }
    return DashboardBudgetTypicalMonthAverage._(
      averageMonthlySpendScaled100:
          (completedMonthSpendScaled100 + completedMonthCount ~/ 2) ~/
          completedMonthCount,
      completedMonthCount: completedMonthCount,
    );
  }

  final int? averageMonthlySpendScaled100;
  final int completedMonthCount;
  bool get isAvailable => averageMonthlySpendScaled100 != null;
}
