import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_day_performance_index_presentation.dart';

import 'balance_day_ratio_presentation_test.dart' show periods;

void main() {
  test('uses authoritative periods and full precision coverage ratios', () {
    final source = periods();
    final result = BalanceDayPerformanceIndexPresentation.fromComparison(
      source,
    );
    expect(result.periods, same(source));
    expect(result.previousIncomeMinor, 72100000);
    expect(result.previousExpenseMinor, 65104500);
    expect(result.currentIncomeMinor, 70700000);
    expect(result.currentExpenseMinor, 75699900);
    expect(result.previousCoverage, closeTo(1.1074503298543112, 1e-12));
    expect(result.currentCoverage, closeTo(.9339510356024249, 1e-12));
    expect(result.performanceIndex, closeTo(84.3334468757, 1e-9));
    expect(result.relativeChangePercent, closeTo(-15.6665531243, 1e-9));
    expect(result.primaryLabel, '84,3%');
    expect(
      result.interpretation,
      '15,7%-kal alacsonyabb fedezettség\naz előző 30 naphoz képest.',
    );
    expect(result.scale.visualProgress, closeTo(.4216672343785, 1e-11));
    expect(result.scale.neutralProgress, .5);
    expect(result.isWorsening, isTrue);
    expect(result.interpretation, isNot(contains('százalékpont')));
  });
  for (final index in [0, 50, 100, 120, 200, 250, 300]) {
    test('index $index preserves real value and clamps only marker', () {
      final result = BalanceDayPerformanceIndexPresentation.fromComparison(
        periods(
          previousIncome: 10000,
          previousExpense: 10000,
          currentIncome: index * 100,
          currentExpense: 10000,
        ),
      );
      expect(result.isAvailable, isTrue);
      expect(result.performanceIndex, closeTo(index.toDouble(), 1e-10));
      expect(
        result.scale.visualProgress,
        closeTo((index / 200).clamp(0, 1), 1e-10),
      );
      expect(result.hasVisualOverflow, index > 200);
      expect(result.isImproving, index > 100);
      expect(result.isWorsening, index < 100);
      if (index == 100) {
        expect(result.interpretation, startsWith('Változatlan'));
      }
    });
  }
  test('undefined denominators and missing history are never a zero index', () {
    for (final source in [
      periods(previousExpense: 0),
      periods(currentExpense: 0),
      periods(previousIncome: 0),
      periods(
        previousIncome: 0,
        previousExpense: 0,
        currentIncome: 0,
        currentExpense: 0,
      ),
    ]) {
      final result = BalanceDayPerformanceIndexPresentation.fromComparison(
        source,
      );
      expect(result.isAvailable, isFalse);
      expect(result.performanceIndex, isNull);
      expect(result.relativeChangePercent, isNull);
      expect(result.primaryLabel, 'Nincs elegendő adat');
      expect(result.scale.visualProgress, 0);
      expect(result.hasVisualOverflow, isFalse);
    }
    final missing = BalanceDayPerformanceIndexPresentation.fromComparison(
      periods(),
      hasComparableHistory: false,
    );
    expect(
      missing.availability,
      BalanceDayPerformanceAvailability.missingHistory,
    );
    expect(missing.previousCoverage, isNull);
    expect(missing.currentCoverage, isNull);
  });
  test('large minor amounts stay finite without integer cross products', () {
    final result = BalanceDayPerformanceIndexPresentation.fromComparison(
      periods(
        previousIncome: 8000000000000000000,
        previousExpense: 4000000000000000000,
        currentIncome: 6000000000000000000,
        currentExpense: 4000000000000000000,
      ),
    );
    expect(result.performanceIndex, 75);
    expect(result.performanceIndex!.isFinite, isTrue);
    expect(result.primaryLabel, '75,0%');
  });
}
