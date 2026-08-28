import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_partner_distribution_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_spending_rhythm_snapshot.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  test(
    'DayScope category distribution reads the exact prepared day, not month',
    () {
      final snapshot = _limitSnapshot();
      final july18 =
          DashboardBudgetCategoryDistributionProjector.projectForScope(
            snapshot: snapshot,
            categories: _categories,
            scope: const DayScope(LocalDate(year: 2026, month: 7, day: 18)),
          );
      final july19 =
          DashboardBudgetCategoryDistributionProjector.projectForScope(
            snapshot: snapshot,
            categories: _categories,
            scope: const DayScope(LocalDate(year: 2026, month: 7, day: 19)),
          );

      expect(july18.analysisScope.canonicalKey, 'day:2026-07-18');
      expect(
        july18
            .frameFor(LedgerDirection.expense)
            .entries
            .map((entry) => entry.categoryId),
        <String>['food'],
      );
      expect(
        july19
            .frameFor(LedgerDirection.expense)
            .entries
            .map((entry) => entry.categoryId),
        <String>['health', 'food'],
      );
      expect(
        july19
            .frameFor(LedgerDirection.expense)
            .entries
            .map((entry) => entry.actualScaled100),
        <int>[80, 20],
      );
      final persistedLimit = july19.persistedLimitPeriod;
      expect(persistedLimit, isA<BudgetLimitMonthPeriod>());
      expect((persistedLimit as BudgetLimitMonthPeriod).year, 2026);
      expect(
        persistedLimit.month,
        7,
        reason:
            'the daily numerator deliberately keeps the containing-month limit identity.',
      );
    },
  );

  test(
    'DayScope partner distribution reads sparse exact daily target contributions',
    () {
      final july18 =
          DashboardBudgetPartnerDistributionProjector.projectForScope(
            snapshot: _partnerSnapshot(),
            categories: _categories,
            scope: const DayScope(LocalDate(year: 2026, month: 7, day: 18)),
          ).frameFor(LedgerDirection.expense, targetHandle: 1);
      final july19 =
          DashboardBudgetPartnerDistributionProjector.projectForScope(
            snapshot: _partnerSnapshot(),
            categories: _categories,
            scope: const DayScope(LocalDate(year: 2026, month: 7, day: 19)),
          ).frameFor(LedgerDirection.expense, targetHandle: 1);

      expect(july18.entries.single.partnerId, 'partner-a');
      expect(july19.entries.single.partnerId, 'partner-b');
      expect(july19.totalPartnerActualScaled100, 100);
    },
  );

  test(
    'prepared Day scenes publish on rail preview without SVG or decode work',
    () async {
      final categories = ValueNotifier<List<FluviCategory>>(_categories);
      final controller = DashboardBudgetDistributionDrawableController(
        categories: categories,
        snapshot: _limitSnapshot(),
        partnerSnapshotForCurrentFrame: _partnerSnapshot,
      );
      addTearDown(categories.dispose);
      addTearDown(controller.dispose);
      const july18 = DayScope(LocalDate(year: 2026, month: 7, day: 18));
      const july19 = DayScope(LocalDate(year: 2026, month: 7, day: 19));

      await controller.prepareForScope(july18);
      await controller.prepareForScope(july19);
      final builds = controller.sceneBuildCount;
      final sourceGeneration = controller.sourceGenerationCount;
      final decode = controller.pictureDecodeCount;

      expect(controller.publishIfReadyForTimeScope(july18), isTrue);
      expect(controller.value!.semanticBundle.analysisScope, july18);
      expect(controller.publishIfReadyForTimeScope(july19), isTrue);
      expect(controller.value!.semanticBundle.analysisScope, july19);
      expect(
        controller.value!.partnerSemanticBundle!.analysisScope,
        july19,
        reason: 'LogBox/header/Category/Partner share one exact preview scope.',
      );
      expect(controller.sceneBuildCount, builds);
      expect(controller.sourceGenerationCount, sourceGeneration);
      expect(controller.pictureDecodeCount, decode);
      expect(controller.rendererPrewarmCount, 0);
    },
  );
}

const _categories = <FluviCategory>[
  FluviCategory(
    id: 'food',
    name: 'Food',
    colorId: 'color_01',
    iconId: 'icon_01',
    isSystemUncategorized: false,
    createdAtUtcMs: 1,
    updatedAtUtcMs: 1,
  ),
  FluviCategory(
    id: 'health',
    name: 'Health',
    colorId: 'color_02',
    iconId: 'icon_02',
    isSystemUncategorized: false,
    createdAtUtcMs: 1,
    updatedAtUtcMs: 1,
  ),
];

PreparedBudgetLimitSnapshot _limitSnapshot() {
  const targetCount = 3;
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * targetCount,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  // Month July is slice 8 in a 2026-only window. It intentionally differs
  // from both individual days so an accidental Day -> Month collapse fails.
  for (var handle = 0; handle < targetCount; handle += 1) {
    cells[8 * targetCount + handle] = PreparedBudgetLimitCell(
      actualScaled100: const <int>[200, 120, 80][handle],
      limitScaled100: null,
    );
  }
  final expense = PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food', 'health'],
    cells: cells,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 17,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: PreparedBudgetLimitDirectionBank(
      orderedCategoryIds: const <String>[],
      cells: List<PreparedBudgetLimitCell>.filled(
        14,
        const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
      ),
    ),
    expenseBank: expense,
    spendingRhythmSnapshot: PreparedSpendingRhythmSnapshot(
      coreRevision: 17,
      incomeBank: PreparedSpendingRhythmDirectionBank.empty(targetCount: 1),
      expenseBank: PreparedSpendingRhythmDirectionBank(
        targetCount: 3,
        targetOffsets: const <int>[0, 2, 4, 5],
        epochDays: const <int>[20652, 20653, 20652, 20653, 20653],
        dailyActualScaled100: const <int>[100, 100, 100, 20, 80],
        dayPartActualScaled100: const <int>[
          100,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          100,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          100,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          20,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          80,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
    ),
  );
}

PreparedBudgetPartnerDistributionSnapshot _partnerSnapshot() {
  const zero = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 0,
    dominantCategoryId: '',
  );
  final empty = PreparedBudgetPartnerDistributionDirectionBank(
    orderedPartnerIds: const <String>[],
    orderedPartnerTitles: const <String>[],
    cells: const <PreparedBudgetPartnerDistributionCell>[],
  );
  final expense = PreparedBudgetPartnerDistributionDirectionBank(
    orderedPartnerIds: const <String>['partner-a', 'partner-b'],
    orderedPartnerTitles: const <String>['A', 'B'],
    cells: <PreparedBudgetPartnerDistributionCell>[
      for (var index = 0; index < 28; index += 1) zero,
    ],
    orderedCategoryIds: const <String>['food', 'health'],
    categoryContributionOffsets: List<int>.filled(29, 0),
    dayEpochDays: const <int>[20652, 20653],
    dayAggregateOffsets: const <int>[0, 1, 2],
    dayAggregateCells: const <PreparedBudgetPartnerDayCell>[
      PreparedBudgetPartnerDayCell(
        partnerHandle: 0,
        actualScaled100: 100,
        dominantCategoryId: 'food',
      ),
      PreparedBudgetPartnerDayCell(
        partnerHandle: 1,
        actualScaled100: 100,
        dominantCategoryId: 'food',
      ),
    ],
    dayCategoryContributionOffsets: const <int>[0, 1, 1, 2, 2],
    dayCategoryContributions: const <PreparedBudgetPartnerCategoryContribution>[
      PreparedBudgetPartnerCategoryContribution(
        partnerHandle: 0,
        actualScaled100: 100,
      ),
      PreparedBudgetPartnerCategoryContribution(
        partnerHandle: 1,
        actualScaled100: 100,
      ),
    ],
  );
  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 17,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: empty,
    expenseBank: expense,
  );
}
