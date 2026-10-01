import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_ranking.dart';

void main() {
  test(
    'transaction-count ranking breaks ties by amount then stable handle',
    () {
      expect(
        BudgetDistributionRankingOrder.compare(
          ranking: BudgetDistributionRanking.transactionCount,
          leftTransactionCount: 18,
          rightTransactionCount: 18,
          leftActualScaled100: 1200,
          rightActualScaled100: 1000,
          leftStableHandle: 8,
          rightStableHandle: 1,
        ),
        lessThan(0),
      );
      expect(
        BudgetDistributionRankingOrder.compare(
          ranking: BudgetDistributionRanking.transactionCount,
          leftTransactionCount: 18,
          rightTransactionCount: 18,
          leftActualScaled100: 1200,
          rightActualScaled100: 1200,
          leftStableHandle: 1,
          rightStableHandle: 8,
        ),
        lessThan(0),
      );
    },
  );

  test('share ranking ignores count and remains monetary-order based', () {
    expect(
      BudgetDistributionRankingOrder.compare(
        ranking: BudgetDistributionRanking.share,
        leftTransactionCount: 1,
        rightTransactionCount: 99,
        leftActualScaled100: 1200,
        rightActualScaled100: 1000,
        leftStableHandle: 8,
        rightStableHandle: 1,
      ),
      lessThan(0),
    );
  });
}
