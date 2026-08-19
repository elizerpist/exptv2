import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_partner_distribution_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';

void main() {
  test('projects both partner directions from an exact RAM snapshot only', () {
    final bundle = DashboardBudgetPartnerDistributionProjector.project(
      snapshot: _snapshot(),
      categories: <FluviCategory>[
        _category('food', 'color_01'),
        _category('rent', 'color_02'),
        _category('salary', 'color_03'),
      ],
      period: const BudgetLimitPeriod.month(2026, 1),
    );

    expect(bundle.expense.entries.map((entry) => entry.partnerId), <String>[
      'shop',
      'landlord',
    ]);
    expect(bundle.expense.entries.map((entry) => entry.actualScaled100), <int>[
      600,
      400,
    ]);
    expect(bundle.expense.entries.map((entry) => entry.roundedPercent), <int>[
      60,
      40,
    ]);
    expect(bundle.expense.entries.first.colorId, 'color_01');
    expect(bundle.income.entries.single.partnerId, 'employer');
    expect(bundle.income.entries.single.roundedPercent, 100);
  });

  test(
    'omits zero partners and resolves equal amounts by stable source handle',
    () {
      final frame = DashboardBudgetPartnerDistributionProjector.project(
        snapshot: _snapshot(),
        categories: <FluviCategory>[
          _category('food', 'color_01'),
          _category('rent', 'color_02'),
          _category('salary', 'color_03'),
        ],
        period: const BudgetLimitPeriod.year(2026),
      ).frameFor(LedgerDirection.expense);

      expect(frame.entries.map((entry) => entry.partnerId), <String>[
        'shop',
        'landlord',
      ]);
      expect(frame.entries.map((entry) => entry.actualScaled100), <int>[
        500,
        500,
      ]);
      expect(frame.entries.every((entry) => entry.actualScaled100 > 0), isTrue);
    },
  );

  test('reads distinct exact sum, year and month dense cells', () {
    final snapshot = _snapshot();
    final categories = <FluviCategory>[
      _category('food', 'color_01'),
      _category('rent', 'color_02'),
      _category('salary', 'color_03'),
    ];

    DashboardBudgetPartnerDistributionDirectionFrame expenseFor(
      BudgetLimitPeriod period,
    ) => DashboardBudgetPartnerDistributionProjector.project(
      snapshot: snapshot,
      categories: categories,
      period: period,
    ).expense;

    expect(
      expenseFor(const BudgetLimitPeriod.sum()).totalPartnerActualScaled100,
      1_500,
    );
    expect(
      expenseFor(
        const BudgetLimitPeriod.year(2026),
      ).totalPartnerActualScaled100,
      1_000,
    );
    expect(
      expenseFor(
        const BudgetLimitPeriod.month(2026, 1),
      ).totalPartnerActualScaled100,
      1_000,
    );
  });

  test(
    'keeps category-specific partner contributions prepared and RAM-only',
    () {
      final bundle = DashboardBudgetPartnerDistributionProjector.project(
        snapshot: _categoryContributionSnapshot(),
        categories: <FluviCategory>[
          _category('food', 'color_01'),
          _category('rent', 'color_02'),
        ],
        period: const BudgetLimitPeriod.month(2026, 1),
      );

      final aggregate = bundle.frameFor(LedgerDirection.expense);
      final food = bundle.frameFor(LedgerDirection.expense, targetHandle: 1);
      final rent = bundle.frameFor(LedgerDirection.expense, targetHandle: 2);
      expect(aggregate.totalPartnerActualScaled100, 1_000);
      expect(food.entries.map((entry) => entry.partnerId), <String>['shop']);
      expect(food.entries.single.actualScaled100, 600);
      expect(food.entries.single.roundedPercent, 100);
      expect(rent.entries.map((entry) => entry.partnerId), <String>[
        'landlord',
      ]);
      expect(rent.entries.single.actualScaled100, 400);
      // Same prepared bundle, no category-specific native/read path.
      expect(identical(bundle.expenseTargetFrames[0], aggregate), isTrue);
    },
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

PreparedBudgetPartnerDistributionSnapshot _snapshot() {
  PreparedBudgetPartnerDistributionDirectionBank bank(
    List<String> ids,
    List<String> titles,
    List<List<PreparedBudgetPartnerDistributionCell>> slices,
  ) => PreparedBudgetPartnerDistributionDirectionBank(
    orderedPartnerIds: ids,
    orderedPartnerTitles: titles,
    cells: <PreparedBudgetPartnerDistributionCell>[
      for (final slice in slices) ...slice,
    ],
  );
  const zero = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 0,
    dominantCategoryId: '',
  );
  const shop = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 600,
    dominantCategoryId: 'food',
  );
  const landlord = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 400,
    dominantCategoryId: 'rent',
  );
  const employer = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 700,
    dominantCategoryId: 'salary',
  );
  final expenseSlices =
      List<List<PreparedBudgetPartnerDistributionCell>>.generate(
        14,
        (_) => <PreparedBudgetPartnerDistributionCell>[zero, zero, zero],
      );
  expenseSlices[1] = <PreparedBudgetPartnerDistributionCell>[
    const PreparedBudgetPartnerDistributionCell(
      actualScaled100: 500,
      dominantCategoryId: 'food',
    ),
    const PreparedBudgetPartnerDistributionCell(
      actualScaled100: 500,
      dominantCategoryId: 'rent',
    ),
    zero,
  ];
  expenseSlices[2] = <PreparedBudgetPartnerDistributionCell>[
    shop,
    landlord,
    zero,
  ];
  expenseSlices[0] = <PreparedBudgetPartnerDistributionCell>[
    const PreparedBudgetPartnerDistributionCell(
      actualScaled100: 900,
      dominantCategoryId: 'food',
    ),
    const PreparedBudgetPartnerDistributionCell(
      actualScaled100: 600,
      dominantCategoryId: 'rent',
    ),
    zero,
  ];
  final incomeSlices =
      List<List<PreparedBudgetPartnerDistributionCell>>.generate(
        14,
        (_) => <PreparedBudgetPartnerDistributionCell>[zero],
      );
  incomeSlices[1] = <PreparedBudgetPartnerDistributionCell>[employer];
  incomeSlices[2] = <PreparedBudgetPartnerDistributionCell>[employer];
  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(
      const <String>['employer'],
      const <String>['Employer'],
      incomeSlices,
    ),
    expenseBank: bank(
      const <String>['shop', 'landlord', 'zero'],
      const <String>['Bolt', 'Lakbér', 'Nincs'],
      expenseSlices,
    ),
  );
}

PreparedBudgetPartnerDistributionSnapshot _categoryContributionSnapshot() {
  const zero = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 0,
    dominantCategoryId: '',
  );
  const shop = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 600,
    dominantCategoryId: 'food',
  );
  const landlord = PreparedBudgetPartnerDistributionCell(
    actualScaled100: 400,
    dominantCategoryId: 'rent',
  );
  final cells = <PreparedBudgetPartnerDistributionCell>[
    for (var slice = 0; slice < 14; slice += 1)
      for (final cell in <PreparedBudgetPartnerDistributionCell>[
        slice == 2 ? shop : zero,
        slice == 2 ? landlord : zero,
      ])
        cell,
  ];
  final offsets = <int>[0];
  final contributions = <PreparedBudgetPartnerCategoryContribution>[];
  for (var slice = 0; slice < 14; slice += 1) {
    for (var category = 0; category < 2; category += 1) {
      if (slice == 2) {
        contributions.add(
          PreparedBudgetPartnerCategoryContribution(
            partnerHandle: category,
            actualScaled100: category == 0 ? 600 : 400,
          ),
        );
      }
      offsets.add(contributions.length);
    }
  }
  PreparedBudgetPartnerDistributionDirectionBank bank() =>
      PreparedBudgetPartnerDistributionDirectionBank(
        orderedPartnerIds: const <String>['shop', 'landlord'],
        orderedPartnerTitles: const <String>['Bolt', 'Lakbér'],
        cells: cells,
        orderedCategoryIds: const <String>['food', 'rent'],
        categoryContributionOffsets: offsets,
        categoryContributions: contributions,
      );
  PreparedBudgetPartnerDistributionDirectionBank empty() =>
      PreparedBudgetPartnerDistributionDirectionBank(
        orderedPartnerIds: const <String>[],
        orderedPartnerTitles: const <String>[],
        cells: const <PreparedBudgetPartnerDistributionCell>[],
      );
  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: empty(),
    expenseBank: bank(),
  );
}
