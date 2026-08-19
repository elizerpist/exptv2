import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';

void main() {
  test(
    'projects exact positive category distribution from one dense period',
    () {
      final snapshot = _snapshot(
        expenseIds: const <String>['a', 'b', 'c', 'd'],
        expenseMonth: const <int>[1000, 600, 300, 100, 0],
      );

      final bundle = DashboardBudgetCategoryDistributionProjector.project(
        snapshot: snapshot,
        categories: _categories('a', 'b', 'c', 'd'),
        period: const BudgetLimitPeriod.month(2026, 1),
      );
      final frame = bundle.frameFor(LedgerDirection.expense);

      expect(frame.totalCategoryActualScaled100, 1000);
      expect(frame.entries.map((entry) => entry.categoryId), <String>[
        'a',
        'b',
        'c',
      ]);
      expect(frame.entries.map((entry) => entry.actualScaled100), <int>[
        600,
        300,
        100,
      ]);
      expect(frame.entries.map((entry) => entry.roundedPercent), <int>[
        60,
        30,
        10,
      ]);
      expect(frame.sliceIndexForTargetHandle(0), -1);
      expect(frame.sliceIndexForTargetHandle(4), -1);
    },
  );

  test('sorts equal category amounts by authoritative target handle', () {
    final snapshot = _snapshot(
      expenseIds: const <String>['third', 'first', 'second'],
      expenseMonth: const <int>[30, 10, 10, 10],
    );

    final projection = () =>
        DashboardBudgetCategoryDistributionProjector.project(
          snapshot: snapshot,
          categories: _categories('third', 'first', 'second'),
          period: const BudgetLimitPeriod.month(2026, 1),
        ).frameFor(LedgerDirection.expense);

    expect(projection().entries.map((entry) => entry.categoryId), <String>[
      'third',
      'first',
      'second',
    ]);
    expect(
      projection().entries.map((entry) => entry.categoryId),
      projection().entries.map((entry) => entry.categoryId),
    );
  });

  test('one period bundle contains independent income and expense frames', () {
    final snapshot = _snapshot(
      incomeIds: const <String>['salary', 'bonus'],
      expenseIds: const <String>['rent', 'food', 'empty'],
      incomeMonth: const <int>[300, 200, 100],
      expenseMonth: const <int>[700, 500, 200, 0],
    );
    final bundle = DashboardBudgetCategoryDistributionProjector.project(
      snapshot: snapshot,
      categories: _categories('salary', 'bonus', 'rent', 'food', 'empty'),
      period: const BudgetLimitPeriod.month(2026, 1),
    );

    expect(
      bundle
          .frameFor(LedgerDirection.income)
          .entries
          .map((entry) => entry.categoryId),
      <String>['salary', 'bonus'],
    );
    expect(
      bundle
          .frameFor(LedgerDirection.expense)
          .entries
          .map((entry) => entry.categoryId),
      <String>['rent', 'food'],
    );
    expect(bundle.projectionCount, 1);
  });

  test('reads sum, year and month from their exact prepared dense slices', () {
    final snapshot = _snapshot(
      expenseIds: const <String>['a'],
      expenseSum: const <int>[100, 10],
      expenseYear: const <int>[200, 20],
      expenseMonth: const <int>[300, 30],
    );
    final categories = _categories('a');

    int amount(BudgetLimitPeriod period) =>
        DashboardBudgetCategoryDistributionProjector.project(
          snapshot: snapshot,
          categories: categories,
          period: period,
        ).frameFor(LedgerDirection.expense).entries.single.actualScaled100;

    expect(amount(const BudgetLimitPeriod.sum()), 10);
    expect(amount(const BudgetLimitPeriod.year(2026)), 20);
    expect(amount(const BudgetLimitPeriod.month(2026, 1)), 30);
  });

  test(
    'revision-period cache reuses query-independent bundles and bounds retention',
    () {
      final snapshot = _snapshot(
        expenseIds: const <String>['a'],
        expenseMonth: const <int>[10, 10],
      );
      final cache = DashboardBudgetCategoryDistributionBundleCache(
        maximumBundles: 3,
      );
      final categories = _categories('a');

      final january = cache.resolve(
        snapshot: snapshot,
        categories: categories,
        period: const BudgetLimitPeriod.month(2026, 1),
      );
      // A Query-only publication has the same exact prepared revision/period.
      final afterQueryApply = cache.resolve(
        snapshot: snapshot,
        categories: categories,
        period: const BudgetLimitPeriod.month(2026, 1),
      );
      expect(identical(afterQueryApply, january), isTrue);
      expect(cache.projectionCount, 1);

      cache.resolve(
        snapshot: snapshot,
        categories: categories,
        period: const BudgetLimitPeriod.sum(),
      );
      cache.resolve(
        snapshot: snapshot,
        categories: categories,
        period: const BudgetLimitPeriod.year(2026),
      );
      cache.resolve(
        snapshot: snapshot,
        categories: categories,
        period: const BudgetLimitPeriod.month(2026, 2),
      );
      expect(cache.retainedBundleCount, 3);
      expect(cache.projectionCount, 4);
      expect(cache.evictionCount, 1);
    },
  );
}

List<FluviCategory> _categories(
  String first, [
  String? second,
  String? third,
  String? fourth,
  String? fifth,
]) => <String>[first, ?second, ?third, ?fourth, ?fifth].indexed
    .map(
      (item) => FluviCategory(
        id: item.$2,
        name: item.$2.toUpperCase(),
        colorId: 'color_${(item.$1 + 1).toString().padLeft(2, '0')}',
        iconId: 'icon_01',
        isSystemUncategorized: false,
        createdAtUtcMs: 1,
        updatedAtUtcMs: 1,
      ),
    )
    .toList(growable: false);

PreparedBudgetLimitSnapshot _snapshot({
  List<String> incomeIds = const <String>[],
  List<String> expenseIds = const <String>[],
  List<int>? incomeSum,
  List<int>? incomeYear,
  List<int>? incomeMonth,
  List<int>? expenseSum,
  List<int>? expenseYear,
  List<int>? expenseMonth,
}) => PreparedBudgetLimitSnapshot(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  incomeBank: _bank(
    incomeIds,
    sum: incomeSum,
    year: incomeYear,
    month: incomeMonth,
  ),
  expenseBank: _bank(
    expenseIds,
    sum: expenseSum,
    year: expenseYear,
    month: expenseMonth,
  ),
);

PreparedBudgetLimitDirectionBank _bank(
  List<String> ids, {
  List<int>? sum,
  List<int>? year,
  List<int>? month,
}) {
  final targetCount = ids.length + 1;
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * targetCount,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  void install(int slice, List<int>? values) {
    if (values == null) return;
    expect(values.length, targetCount);
    for (var handle = 0; handle < targetCount; handle += 1) {
      cells[slice * targetCount + handle] = PreparedBudgetLimitCell(
        actualScaled100: values[handle],
        limitScaled100: null,
      );
    }
  }

  install(0, sum);
  install(1, year);
  install(2, month);
  return PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: ids,
    cells: cells,
  );
}
