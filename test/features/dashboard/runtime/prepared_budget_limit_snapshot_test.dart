import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreparedBudgetLimitSnapshot', () {
    test('uses dense arithmetic slices and preserves missing versus zero', () {
      final snapshot = PreparedBudgetLimitSnapshot(
        coreRevision: 41,
        yearWindowStart: 2025,
        yearWindowEndInclusive: 2026,
        orderedCategoryIds: const <String>['food'],
        cells: List<PreparedBudgetLimitCell>.generate(
          108,
          (index) => PreparedBudgetLimitCell(
            actualScaled100: index == 0 ? 100 : index * 100,
            limitScaled100: index == 0
                ? null
                : index == 1
                ? 0
                : index * 100 + 100,
          ),
        ),
      );

      expect(snapshot.targetCount, 2);
      expect(snapshot.sliceIndexFor(const BudgetLimitPeriod.sum()), 0);
      expect(snapshot.sliceIndexFor(const BudgetLimitPeriod.year(2025)), 1);
      expect(
        snapshot.sliceIndexFor(const BudgetLimitPeriod.month(2026, 12)),
        1 + 2 + 12 + 11,
      );
      expect(
        snapshot
            .cellAt(
              direction: LedgerDirection.income,
              period: const BudgetLimitPeriod.sum(),
              targetHandle: 0,
            )
            .hasLimit,
        isFalse,
      );
      expect(
        snapshot
            .cellAt(
              direction: LedgerDirection.income,
              period: const BudgetLimitPeriod.sum(),
              targetHandle: 1,
            )
            .limitScaled100,
        0,
      );
    });
  });
}
