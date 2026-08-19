import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';

void main() {
  test(
    'one Category scene maps aggregate and absent targets to no selection',
    () {
      final bank = DashboardBudgetCategoryDistributionVisualBank.prepare(
        semanticBundle: _bundle(),
      );
      final expense = bank.frameFor(LedgerDirection.expense);

      expect(bank.sceneCount, 2);
      expect(expense.scene.slices, hasLength(2));
      expect(expense.sliceIndexForTargetHandle(0), -1);
      expect(expense.sliceIndexForTargetHandle(1), 0);
      expect(expense.sliceIndexForTargetHandle(2), 1);
      expect(expense.sliceIndexForTargetHandle(3), -1);
    },
  );

  test('Category target selection changes only a scene paint index', () {
    final bank = DashboardBudgetCategoryDistributionVisualBank.prepare(
      semanticBundle: _bundle(),
    );
    final expense = bank.frameFor(LedgerDirection.expense);
    final scene = expense.scene;

    final selections = <int>[
      expense.sliceIndexForTargetHandle(0),
      expense.sliceIndexForTargetHandle(1),
      expense.sliceIndexForTargetHandle(2),
      expense.sliceIndexForTargetHandle(3),
      expense.sliceIndexForTargetHandle(1),
    ];

    expect(selections, <int>[-1, 0, 1, -1, 0]);
    expect(identical(scene, expense.scene), isTrue);
    expect(scene.geometryBuildCount, 1);
  });
}

DashboardBudgetCategoryDistributionBundle _bundle() =>
    DashboardBudgetCategoryDistributionProjector.project(
      snapshot: PreparedBudgetLimitSnapshot(
        coreRevision: 7,
        yearWindowStart: 2026,
        yearWindowEndInclusive: 2026,
        incomeBank: _bank(const <String>['salary'], const <int>[10, 10]),
        expenseBank: _bank(
          const <String>['a', 'b', 'zero'],
          const <int>[100, 60, 40, 0],
        ),
      ),
      categories: <FluviCategory>[
        _category('salary', 'color_01'),
        _category('a', 'color_02'),
        _category('b', 'color_03'),
        _category('zero', 'color_04'),
      ],
      period: const BudgetLimitPeriod.month(2026, 1),
    );

PreparedBudgetLimitDirectionBank _bank(List<String> ids, List<int> values) {
  final count = ids.length + 1;
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * count,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  for (var handle = 0; handle < count; handle += 1) {
    cells[2 * count + handle] = PreparedBudgetLimitCell(
      actualScaled100: values[handle],
      limitScaled100: null,
    );
  }
  return PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: ids,
    cells: cells,
  );
}

FluviCategory _category(String id, String colorId) => FluviCategory(
  id: id,
  name: id,
  colorId: colorId,
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);
