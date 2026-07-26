import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_log_entry.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detail rankings are filtered, limited to four, and deterministic', () {
    final frame = _frameFor(_recordsAcrossYearsAndMonths());

    expect(
      frame
          .topCategoriesFor(SpendeeBalanceRankDimension.month)
          .map((row) => row.name),
      <String>['Food', 'Transport', 'Health', 'Home'],
    );
    expect(frame.topVendorsFor(SpendeeBalanceRankDimension.all), hasLength(4));
    expect(
      frame
          .topVendorsFor(SpendeeBalanceRankDimension.month)
          .map((row) => row.amount),
      orderedEquals(<double>[360, 180, 120, 100]),
    );
    expect(
      frame.topCategoriesFor(SpendeeBalanceRankDimension.year),
      everyElement(isA<BalanceRankRow>()),
    );
  });

  test('average dimensions use the source calendar windows', () {
    final average = _frameFor(
      _recordsAcrossYearsAndMonths(),
    ).averageFor(SpendeeBalanceAverageDimension.week);

    expect(average.total, 200);
    expect(average.observedDays, 2);
    expect(average.dailyAverage, 100);
    expect(average.trend, 40);
    expect(average.maximum, 120);
    expect(average.outlierCount, 0);
  });

  test(
    'count and scope choices come from the same active filtered records',
    () {
      final frame = _frameFor(
        _recordsAcrossYearsAndMonths(),
        searchQuery: 'food mart',
      );

      expect(frame.transactionCount, 3);
      expect(
        frame.transactionCount,
        frame.logGroups.expand((group) => group.rows).length,
      );
      expect(frame.availableYearScopes, <int>[2026]);
      expect(frame.availableMonthScopes, <String>['2026-07']);
      expect(
        frame.topCategoriesFor(SpendeeBalanceRankDimension.all).single.name,
        'Food',
      );
    },
  );

  test('an empty active query has no scopes or ranked detail rows', () {
    final frame = _frameFor(
      _recordsAcrossYearsAndMonths(),
      searchQuery: 'not present',
    );

    expect(frame.transactionCount, 0);
    expect(frame.availableYearScopes, isEmpty);
    expect(frame.availableMonthScopes, isEmpty);
    expect(frame.topVendorsFor(SpendeeBalanceRankDimension.all), isEmpty);
    expect(frame.averageFor(SpendeeBalanceAverageDimension.month).total, 0);
  });

  test('no-spend metrics expose the four query-derived time dimensions', () {
    final frame = _frameFor(_recordsAcrossYearsAndMonths());

    final week = frame.noSpendFor(SpendeeBalanceNoSpendDimension.week);
    expect(week.observedDays, 2);
    expect(week.noSpendDays, 0);

    final month = frame.noSpendFor(SpendeeBalanceNoSpendDimension.month);
    expect(month.observedDays, 7);
    expect(month.noSpendDays, 0);

    final year = frame.noSpendFor(SpendeeBalanceNoSpendDimension.year);
    expect(year.observedDays, 188);
    expect(year.noSpendDays, 181);

    final all = frame.noSpendFor(SpendeeBalanceNoSpendDimension.all);
    expect(all.observedDays, 7);
    expect(all.noSpendDays, 0);
  });

  test('detail calendar windows follow the selected historical scope', () {
    final frame = _frameFor(<TransactionRecord>[
      _record(1, '2025.12.30', -50, 'December Market', 1),
      _record(2, '2026.07.07', -900, 'July Market', 1),
    ], summaryReferenceDate: DateTime(2025, 12));

    final month = frame.averageFor(SpendeeBalanceAverageDimension.month);
    expect(frame.query.effectiveReferenceDate, DateTime(2025, 12));
    expect(month.total, 50);
    expect(month.observedDays, 31);
    expect(month.dailyValues, hasLength(31));
    expect(
      frame.noSpendFor(SpendeeBalanceNoSpendDimension.month).noSpendDays,
      30,
    );
  });

  test('listed transaction count includes every canonical scoped log row', () {
    final frame = _frameFor(
      <TransactionRecord>[_record(1, '2026.07.01', -100, 'Market', 1)],
      recurringGhosts: <RecurringGhostRecord>[_ghost(101, '2026.07.02', 75)],
    );

    expect(frame.transactionCount, 2);
    expect(
      frame.transactionCount,
      frame.logGroups.expand((group) => group.rows).length,
    );
  });

  test(
    'listed transaction count follows the rendered matching log snapshot',
    () {
      final first = _record(1, '2026.07.07', -100, 'First Market', 1);
      final second = _record(2, '2026.07.06', -200, 'Second Market', 2);
      final frame = BalanceFrameResolver.resolve(
        BalanceFrameInput(
          now: DateTime(2026, 7, 7),
          activeType: TransactionType.expense,
          summaryWindow: SummaryWindow.monthly,
          summaryReferenceDate: DateTime(2026, 7),
          transactions: <TransactionRecord>[first, second],
          recurringGhosts: const <RecurringGhostRecord>[],
          categories: _categories,
          limits: const <CategoryLimit>[],
          displayLogEntries: <TransactionLogEntry>[
            TransactionLogEntry.header('2026.07.07'),
            TransactionLogEntry.record(first),
          ],
          displayLogSummaryWindow: SummaryWindow.monthly,
          displayLogSummaryReferenceDate: DateTime(2026, 7),
          visibleLogEntryLimit: 1,
          totalLogEntryCount: 4,
          hasMoreLogEntries: true,
        ),
      );

      expect(frame.visibleLogRowCount, 1);
      expect(frame.transactionCount, 1);
      expect(frame.totalLogEntryCount, 4);
      expect(frame.hasMoreLogEntries, isTrue);
    },
  );

  test('detail card ghost policy and category query share one row source', () {
    final input = BalanceFrameInput(
      now: DateTime(2026, 7, 7),
      activeType: TransactionType.expense,
      summaryWindow: SummaryWindow.monthly,
      summaryReferenceDate: DateTime(2026, 7),
      categoryIds: const <int>{1},
      transactions: <TransactionRecord>[
        _record(1, '2026.07.07', -10, 'Food Market', 1),
        _record(2, '2026.07.07', -500, 'Transit', 2),
      ],
      recurringGhosts: <RecurringGhostRecord>[_ghost(103, '2026.07.06', 90)],
      categories: _categories,
      limits: const <CategoryLimit>[],
    );

    final withoutGhost = BalanceFrameResolver.resolve(
      input,
      ghostPolicy: BalanceGhostPolicy.none,
    );
    final withCategoryGhost = BalanceFrameResolver.resolve(
      input,
      ghostPolicy: BalanceGhostPolicy.only(<BalanceGhostSection>{
        BalanceGhostSection.topCategories,
      }),
    );

    expect(
      withoutGhost
          .topCategoriesFor(SpendeeBalanceRankDimension.month)
          .single
          .amount,
      10,
    );
    expect(
      withCategoryGhost
          .topCategoriesFor(SpendeeBalanceRankDimension.month)
          .single
          .amount,
      100,
    );
    expect(
      withCategoryGhost
          .topVendorsFor(SpendeeBalanceRankDimension.month)
          .single
          .amount,
      10,
      reason: 'A category-card ghost toggle must not mutate vendor data.',
    );
  });

  test('header balance follows the active type, search, and rail scope', () {
    final frame = _scopedLegacyMetricsFrame();

    expect(frame.query.effectiveReferenceDate, DateTime(2026, 6));
    expect(frame.balance, -100);
  });

  test(
    'FastInfo and variable budget follow the selected active query scope',
    () {
      final frame = _scopedLegacyMetricsFrame();

      expect(frame.variableBudgets[BalanceBudgetPeriod.month]!.spent, 100);
      expect(
        frame.insights[BalanceInsightKind.latestTransaction]!.record?.id,
        101,
      );
      expect(
        frame.topMerchants[BalanceMerchantPeriod.month]!.single.name,
        'Scoped Market',
      );
    },
  );

  test('top rank dimensions never escape the selected rail scope', () {
    final frame = _frameFor(<TransactionRecord>[
      _record(1, '2026.06.20', -900, 'Outside Rail', 2),
      _record(2, '2026.07.07', -100, 'Inside Rail', 1),
    ], summaryReferenceDate: DateTime(2026, 7));

    for (final dimension in SpendeeBalanceRankDimension.values) {
      expect(frame.topCategoriesFor(dimension).map((row) => row.name), <String>[
        'Food',
      ]);
      expect(frame.topVendorsFor(dimension).map((row) => row.name), <String>[
        'Inside Rail',
      ]);
    }
  });

  test('no-spend detail follows its own ghost-toggle policy', () {
    final input = BalanceFrameInput(
      now: DateTime(2026, 7, 7),
      activeType: TransactionType.expense,
      summaryWindow: SummaryWindow.monthly,
      summaryReferenceDate: DateTime(2026, 7),
      transactions: const <TransactionRecord>[],
      recurringGhosts: <RecurringGhostRecord>[_ghost(102, '2026.07.07', 75)],
      categories: _categories,
      limits: const <CategoryLimit>[],
    );

    final withoutGhost = BalanceFrameResolver.resolve(
      input,
      ghostPolicy: BalanceGhostPolicy.none,
    );
    final withGhost = BalanceFrameResolver.resolve(
      input,
      ghostPolicy: BalanceGhostPolicy.only({BalanceGhostSection.noSpend}),
    );

    expect(
      withGhost.noSpendFor(SpendeeBalanceNoSpendDimension.week).noSpendDays,
      1,
    );
    expect(
      withoutGhost.noSpendFor(SpendeeBalanceNoSpendDimension.week).noSpendDays,
      2,
    );
  });
}

BalanceRenderFrame _frameFor(
  List<TransactionRecord> records, {
  String searchQuery = '',
  DateTime? summaryReferenceDate,
  List<RecurringGhostRecord> recurringGhosts = const <RecurringGhostRecord>[],
}) {
  final now = DateTime(2026, 7, 7);
  return BalanceFrameResolver.resolve(
    BalanceFrameInput(
      now: now,
      activeType: TransactionType.expense,
      summaryWindow: SummaryWindow.monthly,
      summaryReferenceDate: summaryReferenceDate ?? now,
      searchQuery: searchQuery,
      transactions: records,
      recurringGhosts: recurringGhosts,
      categories: _categories,
      limits: const <CategoryLimit>[],
    ),
  );
}

BalanceRenderFrame _scopedLegacyMetricsFrame() {
  return BalanceFrameResolver.resolve(
    BalanceFrameInput(
      now: DateTime(2026, 7, 7),
      activeType: TransactionType.expense,
      summaryWindow: SummaryWindow.monthly,
      summaryReferenceDate: DateTime(2026, 6),
      searchQuery: 'scoped',
      transactions: <TransactionRecord>[
        _record(101, '2026.06.20', -100, 'Scoped Market', 1),
        _record(102, '2026.07.07', -700, 'July Market', 1),
        _record(103, '2026.06.20', 1000, 'Salary', null),
      ],
      recurringGhosts: const <RecurringGhostRecord>[],
      categories: _categories,
      limits: const <CategoryLimit>[],
    ),
  );
}

List<TransactionRecord> _recordsAcrossYearsAndMonths() => <TransactionRecord>[
  _record(1, '2024.01.04', -10, 'Archive Food', 1),
  _record(2, '2025.12.01', -100, 'Food Mart', 1),
  _record(3, '2026.01.02', -50, 'Food Mart', 1),
  _record(4, '2026.07.01', -120, 'Food Mart', 1),
  _record(5, '2026.07.02', -120, 'Food Mart', 1),
  _record(6, '2026.07.03', -180, 'Transit', 2),
  _record(7, '2026.07.04', -120, 'Clinic', 3),
  _record(8, '2026.07.05', -100, 'Home Store', 4),
  _record(9, '2026.07.06', -80, 'Tech Shop', 5),
  _record(10, '2026.07.07', 500, 'Salary', null),
  _record(11, '2026.07.07', -120, 'Food Mart', 1),
];

TransactionRecord _record(
  int id,
  String date,
  double amount,
  String merchant,
  int? categoryId,
) => TransactionRecord(
  id: id,
  date: date,
  time: '12:00',
  latitude: null,
  longitude: null,
  address: null,
  merchant: merchant,
  amount: amount,
  userAssignedName: null,
  transactionCategoryID: categoryId,
);

RecurringGhostRecord _ghost(int id, String date, double amount) =>
    RecurringGhostRecord(
      id: id,
      recurringTransactionId: id,
      periodKey: date.substring(0, 7),
      name: 'Ghost Market',
      amount: amount,
      transactionType: 'expense',
      date: date,
      time: '12:00',
      categoryId: 1,
      categoryName: 'Food',
      categoryColor: '#000000',
      categoryIconSlot: 0,
      triggerMillis: 0,
      isActivated: false,
      activatedTransactionId: null,
      createdAt: 0,
      updatedAt: 0,
    );

final List<TransactionCategory> _categories = <TransactionCategory>[
  _category(1, 'Food'),
  _category(2, 'Transport'),
  _category(3, 'Health'),
  _category(4, 'Home'),
  _category(5, 'Technology'),
];

TransactionCategory _category(int id, String name) => TransactionCategory(
  transactionCategoryID: id,
  name: name,
  type: 'expense',
  colorSlot: null,
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
