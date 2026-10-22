import 'package:flutter/foundation.dart';

import '../../time_navigation/domain/local_date.dart';
import 'balance_alternative_scope_presentation.dart';

enum BalanceYearMonthAvailability { recorded, noData, current, future, unknown }

/// A prepared calendar point; financial values never depend on paint frames.
@immutable
final class BalanceYearMonthPoint {
  const BalanceYearMonthPoint({
    required this.month,
    required this.label,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.cumulativeNetMinor,
    required this.availability,
    required this.isClosed,
    required this.isFuture,
    this.transactionCount,
  });

  final int month;
  final String label;
  final int incomeMinor;
  final int expenseMinor;
  final int cumulativeNetMinor;
  final int? transactionCount;
  final BalanceYearMonthAvailability availability;
  final bool isClosed;
  final bool isFuture;
  int get netMinor => incomeMinor - expenseMinor;
  bool get hasRecordedTransactions =>
      (transactionCount ?? 0) > 0 || incomeMinor != 0 || expenseMinor != 0;

  /// Future booked entries are real flows, but not completed monthly closes.
  bool get hasCumulativeClose =>
      !isFuture && availability != BalanceYearMonthAvailability.unknown;
}

@immutable
final class BalanceYearFocusedChartPresentation {
  BalanceYearFocusedChartPresentation._({
    required this.year,
    required this.sourcePresentationId,
    required List<BalanceYearMonthPoint> months,
    required this.annualIncomeMinor,
    required this.annualExpenseMinor,
  }) : months = List<BalanceYearMonthPoint>.unmodifiable(months),
       maxAbsNetMinor = months.fold(
         0,
         (value, month) =>
             value > month.netMinor.abs() ? value : month.netMinor.abs(),
       ),
       maximumFlowMinor = months.fold(
         0,
         (value, month) => [
           value,
           month.incomeMinor,
           month.expenseMinor,
         ].reduce((a, b) => a > b ? a : b),
       ),
       minCumulativeNetMinor = months
           .where((month) => month.hasCumulativeClose)
           .fold(
             0,
             (value, month) => value < month.cumulativeNetMinor
                 ? value
                 : month.cumulativeNetMinor,
           ),
       maxCumulativeNetMinor = months
           .where((month) => month.hasCumulativeClose)
           .fold(
             0,
             (value, month) => value > month.cumulativeNetMinor
                 ? value
                 : month.cumulativeNetMinor,
           );

  factory BalanceYearFocusedChartPresentation.fromIncomeExpense(
    BalanceAlternativeIncomeExpenseBarPresentation source, {
    required int year,
    LocalDate? logicalAsOfDate,
    Map<int, int?> transactionCounts = const {},
  }) {
    assert(source.domain == BalanceAlternativeBarDomain.months);
    final groups = {for (final group in source.groups) group.key: group};
    var cumulative = 0;
    var income = 0;
    var expense = 0;
    final months = <BalanceYearMonthPoint>[];
    for (var month = 1; month <= 12; month++) {
      final group = groups[month];
      final monthlyIncome = group?.incomeMinor ?? 0;
      final monthlyExpense = group?.expenseMinor ?? 0;
      final count = transactionCounts[month];
      final recorded =
          (count ?? 0) > 0 || monthlyIncome != 0 || monthlyExpense != 0;
      final comparison = logicalAsOfDate == null
          ? null
          : (year * 12 + month).compareTo(
              logicalAsOfDate.year * 12 + logicalAsOfDate.month,
            );
      final future = comparison != null && comparison > 0;
      final closed = comparison != null && comparison < 0;
      final availability = recorded
          ? BalanceYearMonthAvailability.recorded
          : future
          ? BalanceYearMonthAvailability.future
          : comparison == 0
          ? BalanceYearMonthAvailability.current
          : count != null
          ? BalanceYearMonthAvailability.noData
          : BalanceYearMonthAvailability.unknown;
      income += monthlyIncome;
      expense += monthlyExpense;
      cumulative += monthlyIncome - monthlyExpense;
      months.add(
        BalanceYearMonthPoint(
          month: month,
          label: group?.label ?? _labels[month - 1],
          incomeMinor: monthlyIncome,
          expenseMinor: monthlyExpense,
          cumulativeNetMinor: cumulative,
          transactionCount: count,
          availability: availability,
          isClosed: closed,
          isFuture: future,
        ),
      );
    }
    return BalanceYearFocusedChartPresentation._(
      year: year,
      sourcePresentationId: source.sourcePresentationId,
      months: months,
      annualIncomeMinor: income,
      annualExpenseMinor: expense,
    );
  }

  final int year;
  final int sourcePresentationId;
  final List<BalanceYearMonthPoint> months;
  final int annualIncomeMinor;
  final int annualExpenseMinor;
  final int maxAbsNetMinor;
  final int maximumFlowMinor;
  final int minCumulativeNetMinor;
  final int maxCumulativeNetMinor;
  BalanceYearMonthPoint? get bestMonth => bestClosedMonth;
  int get annualNetMinor => annualIncomeMinor - annualExpenseMinor;
  int get closedMonthCount => months
      .where(
        (month) =>
            month.isClosed &&
            month.availability != BalanceYearMonthAvailability.unknown,
      )
      .length;
  int get positiveClosedMonthCount =>
      months.where((month) => month.isClosed && month.netMinor > 0).length;
  BalanceYearMonthPoint? get bestClosedMonth {
    BalanceYearMonthPoint? best;
    for (final month in months) {
      if (!month.isClosed || !month.hasRecordedTransactions) continue;
      if (best == null || month.netMinor > best.netMinor) best = month;
    }
    return best;
  }
}

const _labels = [
  'JAN',
  'FEB',
  'MÁR',
  'ÁPR',
  'MÁJ',
  'JÚN',
  'JÚL',
  'AUG',
  'SZE',
  'OKT',
  'NOV',
  'DEC',
];
