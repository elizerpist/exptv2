import 'package:flutter/foundation.dart';

import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'balance_month_focused_chart_presentation.dart';
import 'budget_clay_semicircle_gauge.dart';

enum BalanceMonthNetMarginAvailability {
  available,
  noIncome,
  noFlow,
  future,
  unavailable,
}

/// Only adapts the accepted month and its prepared cumulative daily points.
/// Does not aggregate ledger entries or consult historical reference months.
@immutable
final class BalanceMonthNetMarginPresentation {
  factory BalanceMonthNetMarginPresentation.fromChart(
    BalanceMonthFocusedChartPresentation chart,
  ) {
    final asOf = chart.logicalAsOfDate;
    if (asOf == null) {
      return BalanceMonthNetMarginPresentation._(
        0,
        0,
        BalanceMonthNetMarginAvailability.unavailable,
      );
    }
    final selected = chart.year * 12 + chart.month;
    final current = asOf.year * 12 + asOf.month;
    if (selected > current) {
      return BalanceMonthNetMarginPresentation._(
        0,
        0,
        BalanceMonthNetMarginAvailability.future,
      );
    }
    var income = chart.incomeTotalMinor, expense = chart.expenseTotalMinor;
    if (selected == current) {
      // Primary totals include scheduled future dates. Read one already-prepared
      // cumulative point at the canonical date; never change trend/swing data.
      final cutoff = chart.trend.where((point) => point.day <= asOf.day).last;
      income = cutoff.incomeMinor;
      expense = cutoff.expenseMinor;
    }
    return BalanceMonthNetMarginPresentation._(
      income,
      expense,
      income > 0
          ? BalanceMonthNetMarginAvailability.available
          : expense > 0
          ? BalanceMonthNetMarginAvailability.noIncome
          : BalanceMonthNetMarginAvailability.noFlow,
    );
  }

  const BalanceMonthNetMarginPresentation._(
    this.incomeMinor,
    this.expenseMinor,
    this.availability,
  ) : netMinor = incomeMinor - expenseMinor,
      netMarginPercent =
          availability == BalanceMonthNetMarginAvailability.available
          ? (incomeMinor - expenseMinor) / incomeMinor * 100
          : null;

  final int incomeMinor, expenseMinor, netMinor;
  final double? netMarginPercent;
  final BalanceMonthNetMarginAvailability availability;
  bool get isAvailable =>
      availability == BalanceMonthNetMarginAvailability.available;
  bool get isPositive => isAvailable && netMinor > 0;
  bool get isNegative => isAvailable && netMinor < 0;
  bool get isNeutral => isAvailable && netMinor == 0;
  BudgetSemicircleScalePresentation get scale =>
      BudgetSemicircleScalePresentation(
        domainMinimum: -100,
        domainNeutral: 0,
        domainMaximum: 100,
        rawValue: netMarginPercent ?? -100,
      );
  bool get hasVisualOverflow => isAvailable && scale.hasVisualOverflow;
  String get primaryLabel {
    if (!isAvailable) {
      return switch (availability) {
        BalanceMonthNetMarginAvailability.noIncome => 'Nincs bevétel',
        BalanceMonthNetMarginAvailability.noFlow => 'Nincs pénzmozgás',
        BalanceMonthNetMarginAvailability.future =>
          'A hónap még nem kezdődött el',
        _ => 'Nincs hiteles havi adat',
      };
    }
    final value = netMarginPercent!;
    final zero = double.parse(value.toStringAsFixed(1)) == 0;
    return '${zero
        ? ''
        : value > 0
        ? '+'
        : '−'}${(zero ? 0.0 : value.abs()).toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  String get interpretation {
    if (!isAvailable) return 'A havi nettóarány nem számítható.';
    if (isNeutral) return 'A havi bevétel és kiadás megegyezik.';
    final amount = netMarginPercent!
        .abs()
        .toStringAsFixed(1)
        .replaceAll(RegExp(r'\.0$'), '')
        .replaceAll('.', ',');
    return isPositive
        ? 'A bevétel $amount%-a megmaradt.'
        : 'A kiadás $amount%-kal meghaladta a bevételt.';
  }

  String get netLabel => switch (availability) {
    BalanceMonthNetMarginAvailability.future ||
    BalanceMonthNetMarginAvailability.unavailable => '',
    _ =>
      'Havi nettó: ${netMinor > 0 ? '+' : ''}${DashboardPreparedFormatter.amountMinor(netMinor)}',
  };
}
