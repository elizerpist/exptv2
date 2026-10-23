import 'package:flutter/foundation.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../application/dashboard_balance_month_spending_level_projection.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/local_date.dart';

@immutable
final class BalanceMonthTrendPoint {
  const BalanceMonthTrendPoint({
    required this.day,
    required this.incomeMinor,
    required this.expenseMinor,
  });
  final int day;
  final int incomeMinor;
  final int expenseMinor;
  int get netMinor => incomeMinor - expenseMinor;
}

@immutable
final class BalanceMonthSwingPoint {
  const BalanceMonthSwingPoint({
    required this.day,
    required this.incomeMinor,
    required this.expenseMinor,
  });
  final int day;
  final int incomeMinor;
  final int expenseMinor;
  int get netMinor => incomeMinor - expenseMinor;
}

@immutable
final class BalanceMonthFocusedChartPresentation {
  BalanceMonthFocusedChartPresentation._({
    required this.year,
    required this.month,
    required this.sourcePresentationId,
    required List<BalanceMonthTrendPoint> trend,
    required List<BalanceMonthSwingPoint> swings,
    required this.incomeTotalMinor,
    required this.expenseTotalMinor,
    required this.minimumNetMinor,
    required this.maximumNetMinor,
    required this.maxAbsSwingMinor,
    required this.bestDay,
    required this.worstDay,
    required this.spendingLevel,
    this.logicalAsOfDate,
  }) : trend = List.unmodifiable(trend),
       swings = List.unmodifiable(swings);
  factory BalanceMonthFocusedChartPresentation.fromPrimary(
    DashboardBalancePrimaryPresentation primary, {
    DashboardBalanceMonthSpendingLevelPresentation? spendingLevel,
    LocalDate? logicalAsOfDate,
  }) {
    final scope = primary.timeScope;
    if (scope is! MonthScope) {
      throw ArgumentError('Focused month requires MonthScope');
    }
    if (spendingLevel != null && spendingLevel.identity != primary.identity) {
      throw ArgumentError('Month sources must share publication identity');
    }
    final byDay = {for (final point in primary.dailyPoints) point.day: point};
    final days = DateTime.utc(scope.value.year, scope.value.month + 1, 0).day;
    final trend = <BalanceMonthTrendPoint>[
      const BalanceMonthTrendPoint(day: 0, incomeMinor: 0, expenseMinor: 0),
    ];
    final allSwings = <BalanceMonthSwingPoint>[];
    var income = 0, expense = 0, minimum = 0, maximum = 0, maxSwing = 0;
    BalanceMonthSwingPoint? best, worst;
    for (var day = 1; day <= days; day++) {
      final next = byDay[day];
      final nextIncome = next?.incomeMinor ?? income,
          nextExpense = next?.expenseMinor ?? expense;
      final swing = BalanceMonthSwingPoint(
        day: day,
        incomeMinor: nextIncome - income,
        expenseMinor: nextExpense - expense,
      );
      income = nextIncome;
      expense = nextExpense;
      final point = BalanceMonthTrendPoint(
        day: day,
        incomeMinor: income,
        expenseMinor: expense,
      );
      trend.add(point);
      if (point.netMinor < minimum) minimum = point.netMinor;
      if (point.netMinor > maximum) maximum = point.netMinor;
      if (swing.netMinor.abs() > maxSwing) maxSwing = swing.netMinor.abs();
      if (swing.netMinor != 0) {
        allSwings.add(swing);
        if (best == null || swing.netMinor > best.netMinor) best = swing;
        if (worst == null || swing.netMinor < worst.netMinor) worst = swing;
      }
    }
    // Choose seven largest absolute daily nets, breaking ties by earlier day.
    // Display the selected events chronologically on a stable time axis.
    allSwings.sort((a, b) {
      final amount = b.netMinor.abs().compareTo(a.netMinor.abs());
      return amount != 0 ? amount : a.day.compareTo(b.day);
    });
    final swings = allSwings.take(7).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return BalanceMonthFocusedChartPresentation._(
      year: scope.value.year,
      month: scope.value.month,
      sourcePresentationId: primary.presentationId,
      trend: trend,
      swings: swings,
      incomeTotalMinor: primary.incomeTotalMinor,
      expenseTotalMinor: primary.expenseTotalMinor,
      minimumNetMinor: minimum,
      maximumNetMinor: maximum,
      maxAbsSwingMinor: maxSwing,
      bestDay: best,
      worstDay: worst,
      spendingLevel: spendingLevel,
      logicalAsOfDate: logicalAsOfDate,
    );
  }
  final int year, month, sourcePresentationId;
  final List<BalanceMonthTrendPoint> trend;
  List<BalanceMonthTrendPoint> get days => trend;
  final List<BalanceMonthSwingPoint> swings;
  final int incomeTotalMinor,
      expenseTotalMinor,
      minimumNetMinor,
      maximumNetMinor,
      maxAbsSwingMinor;
  int get netTotalMinor => incomeTotalMinor - expenseTotalMinor;
  final BalanceMonthSwingPoint? bestDay, worstDay;
  final DashboardBalanceMonthSpendingLevelPresentation? spendingLevel;
  final LocalDate? logicalAsOfDate;
}
