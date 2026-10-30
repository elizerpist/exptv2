import 'package:fluvi/features/manual_transactions/presentation/manual_transaction_budget_impact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normal budget uses the limit as the three-segment scale', () {
    final impact = ManualTransactionBudgetImpactPresentation.calculate(
      limitScaled100: 8000000,
      spentScaled100: 4800000,
      draftScaled100: 850000,
    );

    expect(impact.isOverrun, isFalse);
    expect(impact.remainingScaled100, 2350000);
    expect(impact.spentFraction, closeTo(.6, .000001));
    expect(impact.draftFraction, closeTo(.10625, .000001));
    expect(impact.remainingFraction, closeTo(.29375, .000001));
  });

  test(
    'overrun uses post-save spending as scale and preserves limit marker',
    () {
      final impact = ManualTransactionBudgetImpactPresentation.calculate(
        limitScaled100: 1089464,
        spentScaled100: 0,
        draftScaled100: 3000000,
      );

      expect(impact.isOverrun, isTrue);
      expect(impact.totalScaled100, 3000000);
      expect(impact.overrunScaled100, 1910536);
      expect(impact.spentFraction, 0);
      expect(impact.draftFraction, 1);
      expect(impact.limitFraction, closeTo(.3631546667, .000001));
      expect(impact.remainingFraction, 0);
    },
  );

  test('an exactly exhausted limit has no negative drawable segment', () {
    final impact = ManualTransactionBudgetImpactPresentation.calculate(
      limitScaled100: 1000000,
      spentScaled100: 800000,
      draftScaled100: 200000,
    );

    expect(impact.isOverrun, isFalse);
    expect(impact.isExhausted, isTrue);
    expect(impact.remainingScaled100, 0);
    expect(impact.remainingFraction, 0);
  });

  test('a previously overrun and zero budget remain finite', () {
    final previousOverrun = ManualTransactionBudgetImpactPresentation.calculate(
      limitScaled100: 1000000,
      spentScaled100: 1500000,
      draftScaled100: 200000,
    );
    final zeroBudget = ManualTransactionBudgetImpactPresentation.calculate(
      limitScaled100: 0,
      spentScaled100: 0,
      draftScaled100: 100000,
    );

    expect(previousOverrun.overrunScaled100, 700000);
    expect(previousOverrun.spentFraction, closeTo(1500000 / 1700000, .000001));
    expect(previousOverrun.draftFraction, closeTo(200000 / 1700000, .000001));
    expect(zeroBudget.isOverrun, isTrue);
    expect(zeroBudget.overrunScaled100, 100000);
    expect(zeroBudget.limitFraction, 0);
    expect(zeroBudget.draftFraction, 1);
  });
}
