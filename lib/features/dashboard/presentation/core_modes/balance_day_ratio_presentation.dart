import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_daily_insights_projection.dart';
import 'balance_day_visual_presentation.dart';
import 'balance_presentation_settings.dart';
import 'budget_clay_semicircle_gauge.dart';

enum BalanceDayRatioAvailability {
  available,
  noFlow,
  noExpense,
  noIncome,
  missingHistory,
}

/// Only adapts the two authoritative V4 periods; never selects ledger rows.
@immutable
final class BalanceDayRatioPeriodPresentation {
  BalanceDayRatioPeriodPresentation({
    required this.totals,
    required this.mode,
    required bool hasComparableHistory,
  }) {
    availability = !hasComparableHistory
        ? BalanceDayRatioAvailability.missingHistory
        : incomeMinor == 0 && expenseMinor == 0
        ? BalanceDayRatioAvailability.noFlow
        : mode == BalanceDayRatioPresentation.coverage && expenseMinor == 0
        ? BalanceDayRatioAvailability.noExpense
        : mode == BalanceDayRatioPresentation.netMargin && incomeMinor == 0
        ? BalanceDayRatioAvailability.noIncome
        : BalanceDayRatioAvailability.available;
    rawPercentage = !isAvailable
        ? null
        : mode == BalanceDayRatioPresentation.coverage
        ? incomeMinor / expenseMinor * 100
        : netMinor / incomeMinor * 100;
    scale = BudgetSemicircleScalePresentation(
      domainMinimum: mode == BalanceDayRatioPresentation.coverage ? 0 : -100,
      domainNeutral: mode == BalanceDayRatioPresentation.coverage ? 100 : 0,
      domainMaximum: mode == BalanceDayRatioPresentation.coverage ? 200 : 100,
      // An unavailable ratio paints an empty track, never a fictitious value.
      rawValue:
          rawPercentage ??
          (mode == BalanceDayRatioPresentation.coverage ? 0 : -100),
    );
  }

  final BalanceDayPeriodTotals totals;
  final BalanceDayRatioPresentation mode;
  late final BalanceDayRatioAvailability availability;
  late final double? rawPercentage;
  late final BudgetSemicircleScalePresentation scale;
  int get incomeMinor => totals.incomeMinor;
  int get expenseMinor => totals.expenseMinor;
  int get netMinor => totals.netMinor;
  bool get isAvailable => availability == BalanceDayRatioAvailability.available;
  bool get isPositive => isAvailable && netMinor > 0;
  bool get isNegative => isAvailable && netMinor < 0;
  bool get isNeutral => isAvailable && netMinor == 0;
  double get visualProgress => scale.visualProgress;
  bool get hasVisualOverflow => isAvailable && scale.hasVisualOverflow;
  String get primaryLabel => switch (availability) {
    BalanceDayRatioAvailability.available =>
      '${_decimal(rawPercentage!, signed: mode == BalanceDayRatioPresentation.netMargin)}%',
    BalanceDayRatioAvailability.noFlow => 'Nincs pénzmozgás',
    BalanceDayRatioAvailability.noExpense => 'Kiadás nélkül',
    BalanceDayRatioAvailability.noIncome => 'Nincs bevétel',
    BalanceDayRatioAvailability.missingHistory => 'Nincs adat',
  };
}

@immutable
final class BalanceDayRatioComparisonPresentation {
  BalanceDayRatioComparisonPresentation.fromMomentum(
    DashboardBalanceDailyMomentumPresentation momentum, {
    required BalanceDayRatioPresentation mode,
  }) : this.fromComparison(
         BalanceDayPeriodComparisonPresentation.fromPoint(momentum.selected),
         mode: mode,
         hasComparableHistory: momentum.available,
       );

  BalanceDayRatioComparisonPresentation.fromComparison(
    this.periods, {
    required this.mode,
    this.hasComparableHistory = true,
  }) : previous = BalanceDayRatioPeriodPresentation(
         totals: periods.previous,
         mode: mode,
         hasComparableHistory: hasComparableHistory,
       ),
       current = BalanceDayRatioPeriodPresentation(
         totals: periods.current,
         mode: mode,
         hasComparableHistory: hasComparableHistory,
       );

  final BalanceDayPeriodComparisonPresentation periods;
  final BalanceDayRatioPresentation mode;
  final bool hasComparableHistory;
  final BalanceDayRatioPeriodPresentation previous, current;
  double? get percentagePointDelta =>
      previous.isAvailable && current.isAvailable
      ? current.rawPercentage! - previous.rawPercentage!
      : null;
  String get deltaLabel => percentagePointDelta == null
      ? 'Nem számítható'
      : '${_decimal(percentagePointDelta!, signed: true)} százalékpont';
  String get deltaTitle => mode == BalanceDayRatioPresentation.coverage
      ? 'Fedezettség változása'
      : 'Nettóarány változása';
  String get formulaLabel => mode == BalanceDayRatioPresentation.coverage
      ? 'Bevétel / kiadás'
      : 'Nettó / bevétel';
}

String _decimal(double value, {required bool signed}) {
  final rounded = value.toStringAsFixed(1);
  final zero = double.parse(rounded) == 0;
  final prefix = zero
      ? ''
      : value < 0
      ? '−'
      : signed && value > 0
      ? '+'
      : '';
  return '$prefix${(zero ? '0.0' : value.abs().toStringAsFixed(1)).replaceAll('.', ',')}';
}
