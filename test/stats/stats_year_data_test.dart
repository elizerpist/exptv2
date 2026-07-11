import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stats render mode exposes only the common mode', () {
    expect(StatsRenderMode.values, [StatsRenderMode.common]);
  });

  test('month cards expose Hungarian weekday headings', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: const [],
      categories: const [],
      selectedCategoryIds: const {},
    );

    expect(data.months.first.weekdayLabels, [
      'H',
      'K',
      'Sze',
      'Cs',
      'P',
      'Szo',
      'V',
    ]);
  });

  test('day heat uses the filtered scope maximum even at threshold zero', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: -1000, categoryId: 1),
        record(id: 2, date: '2026-01-02', amount: -10000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
    );

    final january = data.months.first;
    expect(january.days[0].meetsThreshold, isTrue);
    expect(january.days[0].heatmapIntensity, closeTo(0.1, 0.0001));
    expect(january.days[1].heatmapIntensity, 1);
  });

  test(
    'single category heat uses its color while multi scope uses common heat',
    () {
      final categories = [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
        category(id: 2, name: 'Taxi', type: TransactionType.expense),
      ];
      final transactions = [
        record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
        record(id: 2, date: '2026-01-01', amount: -9000, categoryId: 2),
      ];

      final single = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: StatsRenderMode.common,
        thresholdValue: 0,
        transactions: transactions,
        categories: categories,
        selectedCategoryIds: const {1},
      );
      final all = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: StatsRenderMode.common,
        thresholdValue: 0,
        transactions: transactions,
        categories: categories,
        selectedCategoryIds: const {},
      );

      expect(
        single.months.first.days.first.dominantCategoryColor,
        categories[0].slotColor,
      );
      expect(
        all.months.first.days.first.dominantCategoryColor,
        const Color(0xFF06B6D4),
      );
    },
  );

  test('expense score input aggregates raw scoped records by day', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: -3000, categoryId: 1),
        record(id: 2, date: '2026-01-01', amount: -3000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
    );

    final day = data.months.first.days.first;
    expect(day.scopeAmount, 0, reason: 'visible stats remain record-filtered');
    expect(day.scoreScopeAmount, 6000);
  });

  test('income data keeps category-independent matching expense load', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.income,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: [
        record(id: 1, date: '2026-01-01', amount: 6000, categoryId: 1),
        record(id: 2, date: '2026-01-01', amount: -7000, categoryId: 2),
        record(id: 3, date: '2026-01-01', amount: -9000, categoryId: 3),
      ],
      categories: [
        category(id: 1, name: 'Fizetés', type: TransactionType.income),
        category(id: 2, name: 'Bolt', type: TransactionType.expense),
        category(id: 3, name: 'Taxi', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {1},
    );

    expect(data.months.first.matchingExpenseTotal, 16000);
    expect(data.matchingExpensePeriodAmounts.first, 16000);
  });

  test(
    'monthly closing is canonical income minus expense before threshold',
    () {
      final data = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: StatsRenderMode.common,
        thresholdValue: 5000,
        transactions: [
          record(id: 1, date: '2026-01-01', amount: 10000, categoryId: 2),
          record(id: 2, date: '2026-01-02', amount: -3000, categoryId: 1),
          record(id: 3, date: '2026-01-03', amount: -2000, categoryId: 1),
        ],
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
          category(id: 2, name: 'Fizetés', type: TransactionType.income),
        ],
        selectedCategoryIds: const {},
      );

      expect(data.months.first.scopeTotal, 0);
      expect(data.months.first.closingAmount, 5000);
    },
  );

  test('sum scope exposes canonical income-expense balance for every year', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.income,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: [
        record(id: 1, date: '2024-01-01', amount: 10000, categoryId: 2),
        record(id: 2, date: '2024-01-02', amount: -4000, categoryId: 1),
        record(id: 3, date: '2025-01-01', amount: 5000, categoryId: 2),
        record(id: 4, date: '2025-01-02', amount: -7000, categoryId: 1),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
        category(id: 2, name: 'Fizetés', type: TransactionType.income),
      ],
      selectedCategoryIds: const {},
      summaryScope: StatsSummaryScope.allTime,
    );

    expect(data.periodLabels, ['2024', '2025']);
    expect(data.periodClosingAmounts, [6000, -2000]);
  });

  test(
    'stats year data measures threshold by active type and selected scope',
    () {
      final data = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: StatsRenderMode.common,
        thresholdValue: 5000,
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
          record(id: 2, date: '2026-01-01', amount: -30000, categoryId: 2),
          record(id: 3, date: '2026-01-02', amount: -4000, categoryId: 1),
          record(id: 4, date: '2026-01-03', amount: 9000, categoryId: 3),
        ],
        categories: [
          category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
          category(id: 2, name: 'Ruha', type: TransactionType.expense),
          category(id: 3, name: 'Fizetés', type: TransactionType.income),
        ],
        selectedCategoryIds: {1},
      );

      final january = data.months.first;
      expect(january.days[0].scopeAmount, 6000);
      expect(january.days[0].meetsThreshold, isTrue);
      expect(january.days[1].scopeAmount, 0);
      expect(january.days[1].meetsThreshold, isFalse);
      expect(january.days[2].scopeAmount, 0);
      expect(january.thresholdHitDays, 1);
      expect(data.summaryValue, '6 000 Ft');
      expect(data.headerLabel, 'SZŰRÉS PONTSZÁM');
      expect(data.headerValue, contains('Gyorskaja'));
    },
  );

  test(
    'graph domain uses active side first through last transaction month',
    () {
      final expenseData = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.expense,
        mode: StatsRenderMode.common,
        thresholdValue: 5000,
        transactions: [
          record(id: 1, date: '2026-03-01', amount: -4000, categoryId: 1),
          record(id: 2, date: '2026-07-01', amount: -7000, categoryId: 1),
          record(id: 3, date: '2026-12-01', amount: 9000, categoryId: 2),
        ],
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
          category(id: 2, name: 'Fizetés', type: TransactionType.income),
        ],
        selectedCategoryIds: const {},
      );

      expect(expenseData.graphMonths.map((month) => month.month), [
        3,
        4,
        5,
        6,
        7,
      ]);

      final incomeData = StatsYearData.build(
        year: 2026,
        activeType: TransactionType.income,
        mode: StatsRenderMode.common,
        thresholdValue: 5000,
        transactions: [
          record(id: 1, date: '2026-01-01', amount: -4000, categoryId: 1),
          record(id: 2, date: '2026-04-01', amount: 7000, categoryId: 2),
          record(id: 3, date: '2026-06-01', amount: 9000, categoryId: 2),
        ],
        categories: [
          category(id: 1, name: 'Bolt', type: TransactionType.expense),
          category(id: 2, name: 'Fizetés', type: TransactionType.income),
        ],
        selectedCategoryIds: const {},
      );

      expect(incomeData.graphMonths.map((month) => month.month), [4, 5, 6]);
    },
  );

  test('summary scope filters all-time yearly and monthly totals', () {
    final transactions = [
      record(id: 1, date: '2025-12-01', amount: -3000, categoryId: 1),
      record(id: 2, date: '2026-05-01', amount: -7000, categoryId: 1),
      record(id: 3, date: '2026-06-01', amount: -11000, categoryId: 1),
      record(id: 4, date: '2026-06-02', amount: 50000, categoryId: 2),
    ];
    final categories = [
      category(id: 1, name: 'Bolt', type: TransactionType.expense),
      category(id: 2, name: 'Fizetés', type: TransactionType.income),
    ];

    final allTime = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: transactions,
      categories: categories,
      selectedCategoryIds: const {},
      summaryScope: StatsSummaryScope.allTime,
    );
    final yearly = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: transactions,
      categories: categories,
      selectedCategoryIds: const {},
    );
    final monthly = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 5000,
      transactions: transactions,
      categories: categories,
      selectedCategoryIds: const {},
      summaryScope: StatsSummaryScope.monthly,
      month: 6,
    );

    expect(allTime.summaryTotal, 18000);
    expect(yearly.summaryTotal, 18000);
    expect(monthly.summaryTotal, 11000);
    expect(monthly.months[4].activeTotal, 0);
    expect(monthly.months[5].activeTotal, 11000);
  });

  test('stats year data filters by selected vendor names', () {
    final data = StatsYearData.build(
      year: 2026,
      activeType: TransactionType.expense,
      mode: StatsRenderMode.common,
      thresholdValue: 0,
      transactions: [
        record(
          id: 1,
          date: '2026-01-01',
          amount: -6000,
          categoryId: 1,
          merchant: 'BKK',
        ),
        record(
          id: 2,
          date: '2026-01-01',
          amount: -9000,
          categoryId: 1,
          merchant: 'Spar',
        ),
      ],
      categories: [
        category(id: 1, name: 'Bolt', type: TransactionType.expense),
      ],
      selectedCategoryIds: const {},
      vendorFilters: const {'BKK'},
    );

    expect(data.summaryTotal, 6000);
    expect(data.months.first.days.first.activeAmount, 6000);
  });
}

TransactionRecord record({
  required int id,
  required String date,
  required double amount,
  required int categoryId,
  String merchant = 'Teszt',
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: '10:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: merchant,
    amount: amount,
    userAssignedName: null,
    transactionCategoryID: categoryId,
  );
}

TransactionCategory category({
  required int id,
  required String name,
  required TransactionType type,
}) {
  return TransactionCategory(
    transactionCategoryID: id,
    name: name,
    type: type.hungarianValue,
    colorSlot: id,
    iconSlot: null,
    backgroundColor: null,
    icon: null,
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  );
}
