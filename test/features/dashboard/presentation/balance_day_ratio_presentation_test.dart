import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_ratio_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_visual_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';

BalanceDayPeriodComparisonPresentation periods({
  int previousIncome = 72100000,
  int previousExpense = 65104500,
  int currentIncome = 70700000,
  int currentExpense = 75699900,
}) => BalanceDayPeriodComparisonPresentation.fromPoint(
  DashboardBalanceDailyMomentumPoint(
    epochDay: 1,
    referenceIncomeMinor: previousIncome,
    referenceExpenseMinor: previousExpense,
    currentIncomeMinor: currentIncome,
    currentExpenseMinor: currentExpense,
    isCurrentHalf: true,
    incomeAxis: 0,
    expenseAxis: 0,
    magnitude: 0,
  ),
);

void main() {
  test(
    'coverage uses exact ratios and unrounded percentage point difference',
    () {
      final source = periods();
      final result = BalanceDayRatioComparisonPresentation.fromComparison(
        source,
        mode: BalanceDayRatioPresentation.coverage,
      );
      expect(result.periods, same(source));
      expect(result.previous.incomeMinor, 72100000);
      expect(result.current.expenseMinor, 75699900);
      expect(result.previous.rawPercentage, closeTo(110.74503298543112, 1e-10));
      expect(result.current.rawPercentage, closeTo(93.39510356024249, 1e-10));
      expect(result.previous.primaryLabel, '110,7%');
      expect(result.current.primaryLabel, '93,4%');
      expect(result.percentagePointDelta, closeTo(-17.349929425188634, 1e-10));
      expect(result.deltaLabel, '−17,3 százalékpont');
      expect(
        result.previous.visualProgress,
        closeTo(result.previous.rawPercentage! / 200, 1e-12),
      );
      expect(result.previous.scale.neutralProgress, .5);
      expect(result.previous.isPositive, isTrue);
      expect(result.current.isNegative, isTrue);
    },
  );
  test(
    'net margin preserves negative percentage and changes semantic mapping',
    () {
      final result = BalanceDayRatioComparisonPresentation.fromComparison(
        periods(),
        mode: BalanceDayRatioPresentation.netMargin,
      );
      expect(result.previous.netMinor, 6995500);
      expect(result.current.netMinor, -4999900);
      expect(result.previous.rawPercentage, closeTo(9.70249653259362, 1e-10));
      expect(result.current.rawPercentage, closeTo(-7.071994342291372, 1e-10));
      expect(result.previous.primaryLabel, '+9,7%');
      expect(result.current.primaryLabel, '−7,1%');
      expect(result.deltaLabel, '−16,8 százalékpont');
      expect(result.percentagePointDelta, closeTo(-16.774490874884993, 1e-10));
      expect(result.previous.visualProgress, greaterThan(.5));
      expect(result.current.visualProgress, lessThan(.5));
      expect(result.current.scale.neutralProgress, .5);
    },
  );
  for (final percentage in [0, 50, 100, 110, 200, 250]) {
    test(
      'coverage $percentage preserves real value and clamps only geometry',
      () {
        final result = BalanceDayRatioComparisonPresentation.fromComparison(
          periods(previousIncome: percentage * 100, previousExpense: 10000),
          mode: BalanceDayRatioPresentation.coverage,
        ).previous;
        expect(result.rawPercentage, closeTo(percentage.toDouble(), 1e-10));
        expect(
          result.visualProgress,
          closeTo((percentage / 200).clamp(0, 1), 1e-12),
        );
        expect(result.hasVisualOverflow, percentage > 200);
        expect(result.isNeutral, percentage == 100);
      },
    );
  }
  for (final percentage in [-150, -100, -50, 0, 50, 100]) {
    test('net margin $percentage keeps sign, neutral and overflow', () {
      final result = BalanceDayRatioComparisonPresentation.fromComparison(
        periods(
          previousIncome: 10000,
          previousExpense: (100 - percentage) * 100,
        ),
        mode: BalanceDayRatioPresentation.netMargin,
      ).previous;
      expect(result.rawPercentage, closeTo(percentage.toDouble(), 1e-10));
      expect(
        result.visualProgress,
        closeTo(((percentage + 100) / 200).clamp(0, 1), 1e-12),
      );
      expect(result.hasVisualOverflow, percentage < -100);
      expect(result.isNeutral, percentage == 0);
      expect(result.rawPercentage!.isFinite, isTrue);
    });
  }
  test(
    'zero denominators, no flow and one-sided availability stay explicit',
    () {
      for (final mode in BalanceDayRatioPresentation.values) {
        final none = BalanceDayRatioComparisonPresentation.fromComparison(
          periods(previousIncome: 0, previousExpense: 0),
          mode: mode,
        );
        expect(none.previous.isAvailable, isFalse);
        expect(none.previous.primaryLabel, 'Nincs pénzmozgás');
        expect(none.previous.rawPercentage, isNull);
        expect(none.previous.visualProgress, 0);
        expect(none.current.isAvailable, isTrue);
        expect(none.percentagePointDelta, isNull);
        expect(none.deltaLabel, 'Nem számítható');
      }
      final noExpense = BalanceDayRatioComparisonPresentation.fromComparison(
        periods(previousExpense: 0),
        mode: BalanceDayRatioPresentation.coverage,
      );
      expect(noExpense.previous.primaryLabel, 'Kiadás nélkül');
      final noIncome = BalanceDayRatioComparisonPresentation.fromComparison(
        periods(currentIncome: 0),
        mode: BalanceDayRatioPresentation.netMargin,
      );
      expect(noIncome.current.primaryLabel, 'Nincs bevétel');
      expect(noIncome.current.netMinor, -75699900);
      expect(noIncome.current.rawPercentage, isNull);
      final missing = BalanceDayRatioComparisonPresentation.fromMomentum(
        DashboardBalanceDailyMomentumPresentation.unavailable(
          selectedEpochDay: 4,
        ),
        mode: BalanceDayRatioPresentation.coverage,
      );
      expect(missing.hasComparableHistory, isFalse);
      expect(
        missing.previous.availability,
        BalanceDayRatioAvailability.missingHistory,
      );
      expect(missing.current.rawPercentage, isNull);
    },
  );
}
