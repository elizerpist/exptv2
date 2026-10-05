import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_secondary_analysis.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

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

  test(
    'analysis bank retains target-specific exact-scope frames for O(1) selection',
    () {
      final snapshot = _snapshotForAnalysis();
      const scope = MonthScope(YearMonth(year: 2026, month: 1));
      final bank = DashboardBudgetSecondaryAnalysisBank.prepare(
        snapshot: snapshot,
        scope: scope,
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );

      final aggregate = bank.frameFor(
        direction: LedgerDirection.expense,
        targetHandle: 0,
      );
      final category = bank.frameFor(
        direction: LedgerDirection.expense,
        targetHandle: 1,
      );

      expect(bank.frameCount, 6);
      expect(aggregate, isNotNull);
      expect(category, isNotNull);
      expect(aggregate!.coreRevision, snapshot.coreRevision);
      expect(category!.scope, scope);
      expect(aggregate.targetHandle, 0);
      expect(category.targetHandle, 1);
      expect(category.payload, isA<DashboardBudgetMonthSecondaryAnalysis>());
      expect(
        identical(
          bank.frameFor(direction: LedgerDirection.expense, targetHandle: 1),
          category,
        ),
        isTrue,
        reason: 'Avatar selection is a retained bank lookup, not a new build.',
      );
    },
  );

  test('analysis frames are retained on an exact scope cache hit', () async {
    final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
      _category('a', 'color_02'),
      _category('b', 'color_03'),
      _category('salary', 'color_01'),
      _category('other', 'color_04'),
    ]);
    final snapshot = _snapshotForAnalysis();
    final controller = DashboardBudgetDistributionDrawableController(
      categories: categories,
      snapshot: snapshot,
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
    );
    addTearDown(categories.dispose);
    addTearDown(controller.dispose);
    const scope = MonthScope(YearMonth(year: 2026, month: 1));

    await controller.prepareForScope(scope);
    final firstBuildCount = controller.analysisFrameBuildCount;
    await controller.prepareForScope(scope);

    expect(firstBuildCount, greaterThan(0));
    expect(controller.analysisFrameBuildCount, firstBuildCount);
    expect(controller.analysisFrameCacheHitCount, 1);
    expect(snapshot.nativeSqlCallCount, 0);
    expect(controller.pictureDecodeCount, 0);
  });
}

PreparedBudgetLimitSnapshot _snapshotForAnalysis() =>
    PreparedBudgetLimitSnapshot(
      coreRevision: 7,
      yearWindowStart: 2026,
      yearWindowEndInclusive: 2026,
      incomeBank: _bank(
        const <String>['salary', 'other'],
        const <int>[0, 0, 0],
      ),
      expenseBank: _bank(const <String>['a', 'b'], const <int>[100, 60, 40]),
    );

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
