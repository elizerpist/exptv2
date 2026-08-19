import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_partner_distribution_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_partner_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'Partner bank retains one scene per Budget target, not per selection',
    () {
      final bank = DashboardBudgetPartnerDistributionVisualBank.prepare(
        semanticBundle:
            DashboardBudgetPartnerDistributionProjector.projectForScope(
              snapshot: _snapshot(),
              categories: <FluviCategory>[_category()],
              scope: MonthScope(YearMonth(year: 2026, month: 1)),
            ),
      );

      final aggregate = bank.frameFor(LedgerDirection.expense);
      final category = bank.frameFor(LedgerDirection.expense, targetHandle: 1);
      expect(bank.sceneCount, 4, reason: 'two direction-local Budget targets');
      expect(aggregate.scene.slices, hasLength(2));
      expect(category.scene.slices, hasLength(2));
      expect(aggregate.selectedSliceIndexForPartnerId('expense-a'), 0);
      expect(aggregate.selectedSliceIndexForPartnerId('expense-b'), 1);
      expect(aggregate.selectedSliceIndexForPartnerId(null), -1);
    },
  );

  test(
    'Partner focus resolves a retained paint index without rebuilding scene',
    () {
      final bank = DashboardBudgetPartnerDistributionVisualBank.prepare(
        semanticBundle:
            DashboardBudgetPartnerDistributionProjector.projectForScope(
              snapshot: _snapshot(),
              categories: <FluviCategory>[_category()],
              scope: MonthScope(YearMonth(year: 2026, month: 1)),
            ),
      );
      final scene = bank.frameFor(LedgerDirection.expense).scene;

      expect(
        <int>[
          bank
              .frameFor(LedgerDirection.expense)
              .selectedSliceIndexForPartnerId('expense-a'),
          bank
              .frameFor(LedgerDirection.expense)
              .selectedSliceIndexForPartnerId('expense-b'),
          bank
              .frameFor(LedgerDirection.expense)
              .selectedSliceIndexForPartnerId(null),
        ],
        <int>[0, 1, -1],
      );
      expect(scene.geometryBuildCount, 1);
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

PreparedBudgetPartnerDistributionSnapshot _snapshot() {
  const zero = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 0,
    dominantCategoryId: '',
  );
  PreparedBudgetPartnerDistributionDirectionBank bank(String prefix) =>
      PreparedBudgetPartnerDistributionDirectionBank(
        orderedPartnerIds: <String>['$prefix-a', '$prefix-b'],
        orderedPartnerTitles: const <String>['A', 'B'],
        cells: <PreparedBudgetPartnerDistributionCell>[
          for (var index = 0; index < 28; index += 1)
            switch (index) {
              4 => const PreparedBudgetPartnerDistributionCell(
                actualScaled100: 100,
                dominantCategoryId: 'category',
              ),
              5 => const PreparedBudgetPartnerDistributionCell(
                actualScaled100: 50,
                dominantCategoryId: 'category',
              ),
              _ => zero,
            },
        ],
        orderedCategoryIds: const <String>['category'],
        categoryContributionOffsets: <int>[
          0,
          0,
          0,
          2,
          2,
          2,
          2,
          2,
          2,
          2,
          2,
          2,
          2,
          2,
          2,
        ],
        categoryContributions:
            const <PreparedBudgetPartnerCategoryContribution>[
              PreparedBudgetPartnerCategoryContribution(
                partnerHandle: 0,
                actualScaled100: 100,
              ),
              PreparedBudgetPartnerCategoryContribution(
                partnerHandle: 1,
                actualScaled100: 50,
              ),
            ],
      );
  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank('income'),
    expenseBank: bank('expense'),
  );
}
