import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

enum BalanceDayComparisonPeriod { previous, current }

enum BalanceDayComparisonFlow { income, expense }

@immutable
final class BalanceDayPeriodTotals {
  const BalanceDayPeriodTotals({
    required this.period,
    required this.incomeMinor,
    required this.expenseMinor,
  });
  final BalanceDayComparisonPeriod period;
  final int incomeMinor, expenseMinor;
  int get netMinor => incomeMinor - expenseMinor;
}

/// Adapts the authoritative, non-overlapping D-59..D-30 and D-29..D windows.
/// No transaction processing or navigation state lives here.
@immutable
final class BalanceDayPeriodComparisonPresentation {
  BalanceDayPeriodComparisonPresentation.fromPoint(this.source)
    : previous = BalanceDayPeriodTotals(
        period: BalanceDayComparisonPeriod.previous,
        incomeMinor: source.referenceIncomeMinor,
        expenseMinor: source.referenceExpenseMinor,
      ),
      current = BalanceDayPeriodTotals(
        period: BalanceDayComparisonPeriod.current,
        incomeMinor: source.currentIncomeMinor,
        expenseMinor: source.currentExpenseMinor,
      );
  final DashboardBalanceDailyMomentumPoint source;
  final BalanceDayPeriodTotals previous, current;
  int get netDeltaMinor => current.netMinor - previous.netMinor;
  static String signedAmountLabel(int value) =>
      '${value > 0 ? '+' : ''}${DashboardPreparedFormatter.amountMinor(value)}';
}

@immutable
final class BalanceDayComparisonBar {
  const BalanceDayComparisonBar(this.period, this.flow, this.amountMinor);
  final BalanceDayComparisonPeriod period;
  final BalanceDayComparisonFlow flow;
  final int amountMinor;
}

/// One common physical scale, explicitly ordered by period then flow.
@immutable
final class BalanceDayComparisonBarScale {
  BalanceDayComparisonBarScale.fromPoint(
    DashboardBalanceDailyMomentumPoint source,
  ) : this.fromComparison(
        BalanceDayPeriodComparisonPresentation.fromPoint(source),
      );
  BalanceDayComparisonBarScale.fromComparison(this.comparison) {
    bars = List<BalanceDayComparisonBar>.unmodifiable([
      for (final period in [comparison.previous, comparison.current]) ...[
        BalanceDayComparisonBar(
          period.period,
          BalanceDayComparisonFlow.income,
          period.incomeMinor,
        ),
        BalanceDayComparisonBar(
          period.period,
          BalanceDayComparisonFlow.expense,
          period.expenseMinor,
        ),
      ],
    ]);
    amountsMinor = List<int>.unmodifiable(bars.map((bar) => bar.amountMinor));
    maximumMinor = amountsMinor.fold<int>(0, math.max);
    fractions = List<double>.unmodifiable([
      for (final amount in amountsMinor)
        maximumMinor == 0 || amount <= 0 ? 0.0 : amount / maximumMinor,
    ]);
  }
  final BalanceDayPeriodComparisonPresentation comparison;
  DashboardBalanceDailyMomentumPoint get source => comparison.source;
  late final List<BalanceDayComparisonBar> bars;
  late final List<int> amountsMinor;
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
