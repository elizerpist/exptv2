import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_daily_insights_projection.dart';
import 'balance_day_visual_presentation.dart';
import 'budget_clay_semicircle_gauge.dart';

/// Undefined ratios remain distinct from a valid zero performance index.
enum BalanceDayPerformanceAvailability {
  available,
  missingHistory,
  noPreviousExpense,
  noCurrentExpense,
  noPreviousCoverage,
}

/// Relative coverage of the authoritative D-29..D and D-59..D-30 windows.
/// Coverage fields are ratios (1 means 100%); the index is in percentage units.
@immutable
final class BalanceDayPerformanceIndexPresentation {
  BalanceDayPerformanceIndexPresentation.fromMomentum(
    DashboardBalanceDailyMomentumPresentation momentum,
  ) : this.fromComparison(
        BalanceDayPeriodComparisonPresentation.fromPoint(momentum.selected),
        hasComparableHistory: momentum.available,
      );

  BalanceDayPerformanceIndexPresentation.fromComparison(
    this.periods, {
    bool hasComparableHistory = true,
  }) {
    availability = !hasComparableHistory
        ? BalanceDayPerformanceAvailability.missingHistory
        : previousExpenseMinor == 0
        ? BalanceDayPerformanceAvailability.noPreviousExpense
        : currentExpenseMinor == 0
        ? BalanceDayPerformanceAvailability.noCurrentExpense
        : previousIncomeMinor == 0
        ? BalanceDayPerformanceAvailability.noPreviousCoverage
        : BalanceDayPerformanceAvailability.available;
    previousCoverage = !hasComparableHistory || previousExpenseMinor == 0
        ? null
        : previousIncomeMinor / previousExpenseMinor;
    currentCoverage = !hasComparableHistory || currentExpenseMinor == 0
        ? null
        : currentIncomeMinor / currentExpenseMinor;
    performanceIndex = isAvailable
        ? currentCoverage! / previousCoverage! * 100
        : null;
    scale = BudgetSemicircleScalePresentation(
      domainMinimum: 0,
      domainNeutral: 100,
      domainMaximum: 200,
      rawValue: performanceIndex ?? 0,
    );
  }

  final BalanceDayPeriodComparisonPresentation periods;
  late final BalanceDayPerformanceAvailability availability;
  late final double? previousCoverage, currentCoverage, performanceIndex;
  late final BudgetSemicircleScalePresentation scale;
  int get previousIncomeMinor => periods.previous.incomeMinor;
  int get previousExpenseMinor => periods.previous.expenseMinor;
  int get currentIncomeMinor => periods.current.incomeMinor;
  int get currentExpenseMinor => periods.current.expenseMinor;
  bool get isAvailable =>
      availability == BalanceDayPerformanceAvailability.available;
  double? get relativeChangePercent =>
      isAvailable ? performanceIndex! - 100 : null;
  bool get hasVisualOverflow => isAvailable && scale.hasVisualOverflow;
  bool get isImproving => isAvailable && relativeChangePercent! > 1e-10;
  bool get isWorsening => isAvailable && relativeChangePercent! < -1e-10;
  String get primaryLabel =>
      isAvailable ? '${_decimal(performanceIndex!)}%' : 'Nincs elegendő adat';
  String get interpretation {
    if (!isAvailable) {
      return switch (availability) {
        BalanceDayPerformanceAvailability.noPreviousExpense =>
          'Az előző időszak kiadása nélkül nem számítható.',
        BalanceDayPerformanceAvailability.noCurrentExpense =>
          'Az aktuális időszak kiadása nélkül nem számítható.',
        BalanceDayPerformanceAvailability.noPreviousCoverage =>
          'Az előző időszak fedezettsége nulla; nincs viszonyítási alap.',
        _ => 'Az összehasonlításhoz további előzmények szükségesek.',
      };
    }
    final change = relativeChangePercent!;
    // Rounded zero is described as unchanged, never as a signed zero change.
    if (double.parse(change.toStringAsFixed(1)) == 0) {
      return 'Változatlan fedezettség az előző 30 naphoz képest.';
    }
    return '${_decimal(change.abs())}%-kal ${change > 0 ? 'magasabb' : 'alacsonyabb'} fedezettség\naz előző 30 naphoz képest.';
  }
}

String _decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
