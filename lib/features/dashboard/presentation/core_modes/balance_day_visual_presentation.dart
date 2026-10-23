import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

/// A single physical scale for the four existing 30-day cashflow totals.
/// This adapter neither selects transactions nor recalculates momentum.
@immutable
final class BalanceDayComparisonBarScale {
  BalanceDayComparisonBarScale.fromPoint(this.source)
    : amountsMinor = List<int>.unmodifiable([
        source.referenceIncomeMinor,
        source.currentIncomeMinor,
        source.referenceExpenseMinor,
        source.currentExpenseMinor,
      ]) {
    maximumMinor = amountsMinor.fold<int>(0, math.max);
    fractions = List<double>.unmodifiable([
      for (final amount in amountsMinor)
        maximumMinor == 0 || amount <= 0 ? 0.0 : amount / maximumMinor,
    ]);
  }

  final DashboardBalanceDailyMomentumPoint source;
  final List<int> amountsMinor;
  late final int maximumMinor;
  late final List<double> fractions;
}

/// Copy for the existing, overlapping rolling seven-day expense windows.
/// Average rounding and whole-HUF formatting match the current Day panels.
@immutable
final class BalanceDaySevenDayComparisonPresentation {
  BalanceDaySevenDayComparisonPresentation.fromImpact(this.source)
    : previousDailyAverageMinor = (source.previousSevenExpenseMinor / 7)
          .round(),
      currentDailyAverageMinor = (source.currentSevenExpenseMinor / 7).round();

  final DashboardBalanceDailyImpactPresentation source;
  final int previousDailyAverageMinor;
  final int currentDailyAverageMinor;

  String get previousTotalLabel =>
      DashboardPreparedFormatter.amountMinor(source.previousSevenExpenseMinor);
  String get currentTotalLabel =>
      DashboardPreparedFormatter.amountMinor(source.currentSevenExpenseMinor);
  String get previousDailyAverageLabel =>
      DashboardPreparedFormatter.amountMinorPerDay(previousDailyAverageMinor);
  String get currentDailyAverageLabel =>
      DashboardPreparedFormatter.amountMinorPerDay(currentDailyAverageMinor);
}
