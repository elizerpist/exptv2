import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_partner_distribution_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_svg.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_partner_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';

void main() {
  test(
    'prepares one unselected Fluvi clay-donut SVG per partner direction',
    () {
      final semantic = DashboardBudgetPartnerDistributionProjector.project(
        snapshot: _snapshot(),
        categories: <FluviCategory>[_category()],
        period: const BudgetLimitPeriod.month(2026, 1),
      );
      final bank = DashboardBudgetPartnerDistributionVisualBank.prepare(
        semanticBundle: semantic,
        sourceGenerator: _SourceGenerator(),
      );

      expect(bank.variantCount, 2);
      expect(
        bank.frameFor(LedgerDirection.expense).svg,
        contains('viewBox="44 44 424 424"'),
      );
      expect(bank.frameFor(LedgerDirection.expense).svg, contains('100%'));
      expect(bank.frameFor(LedgerDirection.expense).svg, contains('összesen'));
    },
  );

  test(
    'uses the shared production clay-donut geometry without a partner lift',
    () {
      final semantic = DashboardBudgetPartnerDistributionProjector.project(
        snapshot: _snapshot(),
        categories: <FluviCategory>[_category()],
        period: const BudgetLimitPeriod.month(2026, 1),
      );
      final svg = DashboardBudgetPartnerDistributionVisualBank.prepare(
        semanticBundle: semantic,
        sourceGenerator: const FluviBudgetDistributionSvgSourceGenerator(),
      ).frameFor(LedgerDirection.expense).svg;

      expect(svg, contains('viewBox="44 44 424 424"'));
      expect(svg, contains('r="106"'));
      expect(svg, contains('data-fluvi-donut-segment-sides="true"'));
      expect(svg, contains('stroke="#ffffff" stroke-opacity=".58"'));
      expect(svg, contains('>100%</text>'));
      expect(svg, contains('>összesen</text>'));
      expect(svg, isNot(contains('data-fluvi-donut-selected="true"')));
    },
  );

  test(
    'prepares category-target partner variants once before semantic ticks',
    () {
      final semantic = DashboardBudgetPartnerDistributionProjector.project(
        snapshot: _targetSnapshot(),
        categories: <FluviCategory>[_category()],
        period: const BudgetLimitPeriod.month(2026, 1),
      );
      final generator = _CountingSourceGenerator();
      final bank = DashboardBudgetPartnerDistributionVisualBank.prepare(
        semanticBundle: semantic,
        sourceGenerator: generator,
      );

      expect(bank.variantCount, 4);
      expect(generator.calls, 4);
      expect(
        bank
            .frameFor(LedgerDirection.expense, targetHandle: 1)
            .semanticFrame
            .targetHandle,
        1,
      );
      bank.frameFor(LedgerDirection.expense, targetHandle: 0);
      bank.frameFor(LedgerDirection.expense, targetHandle: 1);
      expect(
        generator.calls,
        4,
        reason: 'target ticks only select a ready frame',
      );
    },
  );
}

FluviCategory _category() => FluviCategory(
  id: 'category',
  name: 'Category',
  colorId: 'color_01',
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

final class _SourceGenerator
    implements BudgetCategoryDistributionSvgSourceGenerator {
  @override
  String generate({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  }) => '<svg viewBox="44 44 424 424">100% összesen</svg>';
}

final class _CountingSourceGenerator
    implements BudgetCategoryDistributionSvgSourceGenerator {
  var calls = 0;

  @override
  String generate({
    required List<BudgetCategoryDistributionSvgSlice> slices,
    required int? selectedIndex,
  }) {
    calls += 1;
    return '<svg viewBox="44 44 424 424">100% összesen</svg>';
  }
}

PreparedBudgetPartnerDistributionSnapshot _snapshot() {
  const cell = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 100,
    dominantCategoryId: 'category',
  );
  const zero = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 0,
    dominantCategoryId: '',
  );
  PreparedBudgetPartnerDistributionDirectionBank bank(String id) =>
      PreparedBudgetPartnerDistributionDirectionBank(
        orderedPartnerIds: <String>[id],
        orderedPartnerTitles: <String>[id],
        cells: <PreparedBudgetPartnerDistributionCell>[
          zero,
          zero,
          cell,
          for (var index = 0; index < 11; index += 1) zero,
        ],
      );
  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank('income-partner'),
    expenseBank: bank('expense-partner'),
  );
}

PreparedBudgetPartnerDistributionSnapshot _targetSnapshot() {
  const zero = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 0,
    dominantCategoryId: '',
  );
  const cell = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 100,
    dominantCategoryId: 'category',
  );
  PreparedBudgetPartnerDistributionDirectionBank bank(String id) {
    final cells = <PreparedBudgetPartnerDistributionCell>[
      for (var index = 0; index < 14; index += 1) index == 2 ? cell : zero,
    ];
    return PreparedBudgetPartnerDistributionDirectionBank(
      orderedPartnerIds: <String>[id],
      orderedPartnerTitles: <String>[id],
      cells: cells,
      orderedCategoryIds: const <String>['category'],
      categoryContributionOffsets: <int>[
        0,
        0,
        0,
        1,
        for (var index = 0; index < 11; index += 1) 1,
      ],
      categoryContributions: const <PreparedBudgetPartnerCategoryContribution>[
        PreparedBudgetPartnerCategoryContribution(
          partnerHandle: 0,
          actualScaled100: 100,
        ),
      ],
    );
  }

  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank('income'),
    expenseBank: bank('expense'),
  );
}
