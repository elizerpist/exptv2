import 'package:fluvi/features/dashboard/application/dashboard_budget_target.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardBudgetTargetCatalog', () {
    test(
      'puts the typed aggregate at handle zero before repository categories',
      () {
        final catalog = DashboardBudgetTargetCatalog.fromCategories(
          const <DashboardBudgetCategoryVisual>[
            DashboardBudgetCategoryVisual(
              id: 'food',
              displayName: 'Étel',
              colorId: 'green',
              iconId: 'fork',
            ),
            DashboardBudgetCategoryVisual(
              id: 'rent',
              displayName: 'Lakhatás',
              colorId: 'purple',
              iconId: 'home',
            ),
          ],
        );

        expect(catalog.targetCount, 3);
        expect(
          catalog.targetAtHandle(0).identity,
          const DashboardBudgetAggregateTarget(),
        );
        expect(
          catalog.targetAtHandle(1).identity,
          const DashboardBudgetCategoryTarget('food'),
        );
        expect(
          catalog.targetAtHandle(2).identity,
          const DashboardBudgetCategoryTarget('rent'),
        );
      },
    );

    test('keeps exactly the aggregate when inventory is empty', () {
      final catalog = DashboardBudgetTargetCatalog.fromCategories(
        const <DashboardBudgetCategoryVisual>[],
      );

      expect(catalog.targetCount, 1);
      expect(
        catalog.targetAtHandle(0).identity,
        const DashboardBudgetAggregateTarget(),
      );
    });

    test(
      'uses exact direction-specific Spendee aggregate visual contracts',
      () {
        const aggregate = DashboardBudgetAggregateTarget();

        final expense = DashboardBudgetAggregateVisual.forDirection(
          LedgerDirection.expense,
        );
        final income = DashboardBudgetAggregateVisual.forDirection(
          LedgerDirection.income,
        );

        expect(aggregate, isA<DashboardBudgetTargetIdentity>());
        expect(expense.title, 'Budget');
        expect(expense.middleColorArgb, 0xff2bc4f3);
        expect(expense.iconAssetKey, 'dollar-sign');
        expect(income.title, 'Összbevételi cél');
        expect(income.middleColorArgb, 0xff8b45ed);
        expect(income.iconAssetKey, 'banknote');
      },
    );
  });
}
