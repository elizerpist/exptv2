import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_ranking.dart';

void main() {
  group('BudgetDistributionRankingOrder', () {
    test('share ranks exact monetary amount before stable handle', () {
      final rows = <_Row>[
        const _Row(handle: 9, actual: 110, count: 1),
        const _Row(handle: 3, actual: 200, count: 1),
        const _Row(handle: 1, actual: 110, count: 9),
      ]..sort(_compare(BudgetDistributionRanking.share));

      expect(rows.map((row) => row.handle), <int>[3, 1, 9]);
    });

    test('transaction count ranks count, then money, then stable handle', () {
      final rows = <_Row>[
        const _Row(handle: 9, actual: 110, count: 4),
        const _Row(handle: 3, actual: 200, count: 4),
        const _Row(handle: 1, actual: 110, count: 7),
        const _Row(handle: 2, actual: 110, count: 4),
      ]..sort(_compare(BudgetDistributionRanking.transactionCount));

      expect(rows.map((row) => row.handle), <int>[1, 3, 2, 9]);
    });
  });

  test('category and partner ranking selections remain independent', () {
    final controller = BudgetDistributionRankingController();
    addTearDown(controller.dispose);

    controller.setCategory(BudgetDistributionRanking.transactionCount);

    expect(
      controller.category.value,
      BudgetDistributionRanking.transactionCount,
    );
    expect(controller.partner.value, BudgetDistributionRanking.share);
  });
}

Comparator<_Row> _compare(BudgetDistributionRanking ranking) =>
    (left, right) => BudgetDistributionRankingOrder.compare(
      ranking: ranking,
      leftTransactionCount: left.count,
      rightTransactionCount: right.count,
      leftActualScaled100: left.actual,
      rightActualScaled100: right.actual,
      leftStableHandle: left.handle,
      rightStableHandle: right.handle,
    );

class _Row {
  const _Row({required this.handle, required this.actual, required this.count});

  final int handle;
  final int actual;
  final int count;
}
