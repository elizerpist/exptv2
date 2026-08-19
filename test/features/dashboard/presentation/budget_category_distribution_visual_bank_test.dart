import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_svg.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';

void main() {
  test(
    'prepared visual bank maps aggregate and zero targets to unselected SVG',
    () {
      final frame = _frame();
      final generator = _CountingGenerator();

      final bank = DashboardBudgetCategoryDistributionVisualBank.prepare(
        semanticBundle: frame,
        sourceGenerator: generator,
      );
      final expense = bank.frameFor(LedgerDirection.expense);

      expect(expense.svgVariants, hasLength(3));
      expect(expense.variantIndexForTargetHandle(0), 0);
      expect(expense.variantIndexForTargetHandle(1), 1);
      expect(expense.variantIndexForTargetHandle(2), 2);
      expect(expense.variantIndexForTargetHandle(3), 0);
      expect(
        generator.calls,
        5,
        reason: 'one aggregate + positive selections per direction',
      );
    },
  );

  test(
    'semantic target lookup causes no SVG generation or cache prewarm',
    () async {
      final bundles = ValueNotifier<DashboardBudgetCategoryDistributionBundle?>(
        _frame(),
      );
      final generator = _CountingGenerator();
      final prewarmer = _CountingPrewarmer();
      final controller =
          DashboardBudgetCategoryDistributionVisualBankController(
            bundles: bundles,
            sourceGenerator: generator,
            prewarmer: prewarmer,
          );
      addTearDown(bundles.dispose);
      addTearDown(controller.dispose);
      await Future<void>.microtask(() {});

      final ready = controller.value!;
      generator.reset();
      prewarmer.reset();
      final visualFrame = ready.frameFor(LedgerDirection.expense);
      for (final handle in <int>[0, 1, 2, 3, 1, 0]) {
        visualFrame.svgForTargetHandle(handle);
      }

      expect(generator.calls, 0);
      expect(prewarmer.calls, 0);
      expect(controller.sourceGenerationCount, greaterThan(0));
      expect(controller.rendererPrewarmCount, greaterThan(0));
    },
  );

  test(
    'the production prewarmer fills flutter_svg public source cache',
    () async {
      const source =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><rect width="1" height="1" fill="#123456"/></svg>';
      const loader = SvgStringLoader(source);
      svg.cache.evict(loader.cacheKey(null));

      await const FlutterSvgBudgetCategoryDistributionPrewarmer().prewarm(
        const <String>[source],
      );

      expect(
        svg.cache.evict(loader.cacheKey(null)),
        isTrue,
        reason: 'prewarm uses flutter_svg 2.3 public SvgStringLoader cache',
      );
    },
  );

  test('visual banks retain at most three revision-period bundles', () async {
    final bundles = ValueNotifier<DashboardBudgetCategoryDistributionBundle?>(
      _frame(),
    );
    final controller = DashboardBudgetCategoryDistributionVisualBankController(
      bundles: bundles,
      sourceGenerator: _CountingGenerator(),
      prewarmer: _SynchronousPrewarmer(),
    );
    addTearDown(bundles.dispose);
    addTearDown(controller.dispose);

    for (final period in const <BudgetLimitPeriod>[
      BudgetLimitPeriod.sum(),
      BudgetLimitPeriod.year(2026),
      BudgetLimitPeriod.month(2026, 2),
    ]) {
      bundles.value = _frame(period: period);
      await Future<void>.microtask(() {});
    }

    expect(controller.retainedBankCount, 3);
    expect(controller.evictionCount, 1);
  });
}

DashboardBudgetCategoryDistributionBundle _frame({
  BudgetLimitPeriod period = const BudgetLimitPeriod.month(2026, 1),
}) => DashboardBudgetCategoryDistributionProjector.project(
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
  period: period,
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

final class _CountingGenerator
    implements BudgetCategoryDistributionSvgSourceGenerator {
  var calls = 0;

  @override
  String generate({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  }) {
    calls += 1;
    return BudgetCategoryDistributionSvg.flutterRenderable(
      BudgetCategoryDistributionSvg.clayDonut(
        slices: slices,
        selectedIndex: selectedIndex,
      ),
    );
  }

  void reset() => calls = 0;
}

final class _CountingPrewarmer
    implements BudgetCategoryDistributionSvgPrewarmer {
  var calls = 0;

  @override
  Future<void> prewarm(Iterable<String> sources) async {
    calls += sources.length;
  }

  void reset() => calls = 0;
}

final class _SynchronousPrewarmer
    implements BudgetCategoryDistributionSvgPrewarmer {
  @override
  Future<void> prewarm(Iterable<String> sources) =>
      SynchronousFuture<void>(null);
}
