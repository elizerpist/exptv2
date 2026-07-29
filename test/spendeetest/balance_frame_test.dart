import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/balance_amount_formatter.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Balance forint format matches browser hu-HU minimum grouping', () {
    expect(formatBalanceForint(9999), '9999 Ft');
    expect(formatBalanceForint(10000), '10 000 Ft');
    expect(formatBalanceForint(-4250), '-4250 Ft');
    expect(formatBalanceSignedForint(14200), '+14 200 Ft');
    expect(formatBalanceCatalogForint(-4250), '-4 250 Ft');
    expect(formatBalanceCatalogForint(650), '650 Ft');
  });

  test('resolves one immutable live-data Balance render frame', () {
    final sourceTransactions = _transactions();
    final input = _input(transactions: sourceTransactions);

    final frame = BalanceFrameResolver.resolve(input);

    expect(
      frame.balance,
      -6900,
      reason:
          'The header follows the selected July expense query, not all data.',
    );
    expect(frame.reserveRatio, 0);
    expect(frame.incomeRatio + frame.expenseRatio, closeTo(1, .000001));
    expect(frame.insights.keys, BalanceInsightKind.values.toSet());
    expect(frame.insights[BalanceInsightKind.latestTransaction]?.ghost?.id, 45);
    expect(frame.insights[BalanceInsightKind.upcomingRecurring]?.ghost?.id, 45);
    expect(frame.variableBudgets.keys, BalanceBudgetPeriod.values.toSet());
    expect(frame.variableBudgets[BalanceBudgetPeriod.month]?.spent, 6500);
    expect(frame.topCategories.keys, BalanceCategoryPeriod.values.toSet());
    expect(
      frame
          .topCategories[BalanceCategoryPeriod.day]
          ?.category
          ?.transactionCategoryID,
      1,
      reason: 'The featured category is resolved from today, not the month.',
    );
    expect(frame.topMerchants.keys, BalanceMerchantPeriod.values.toSet());
    expect(
      frame.topMerchants.values.every((merchants) => merchants.length <= 5),
      isTrue,
    );
    expect(frame.averageDaily.dailySeries, hasLength(30));
    expect(frame.averageDaily.rollingTotal, 6500);
    expect(frame.summary.label, 'Július 2026');
    expect(
      frame.summary.activeAmount,
      7400,
      reason: 'The monthly summary and log share the pending-ghost dataset.',
    );
    expect(
      frame.query.scopeOptions.map((option) => option.key),
      containsAll(<String>['2025-12', '2026-01', '2026-07']),
    );
    expect(frame.query.selectedScope?.key, '2026-07');
    expect(
      frame.logGroups
          .singleWhere((group) => group.date == '2026.07.21')
          .rows
          .where((row) => row.ghost != null)
          .map((row) => row.ghost!.id),
      [45],
    );
    expect(frame.visibleLogRowCount, 5);
    expect(frame.totalLogEntryCount, 8);
    expect(frame.hasMoreLogEntries, isFalse);

    sourceTransactions.add(_transaction(999, '2026.07.22', -1, 'Late'));
    expect(input.transactions, hasLength(10));
    expect(
      () => frame.logGroups.add(frame.logGroups.first),
      throwsUnsupportedError,
    );
    expect(
      () => frame.insights[BalanceInsightKind.noSpend] =
          frame.insights[BalanceInsightKind.noSpend]!,
      throwsUnsupportedError,
    );
  });

  test('lightweight frame preserves V2 query, summary and log output', () {
    final input = _input();

    final full = BalanceFrameResolver.resolve(input);
    final lightweight = BalanceFrameResolver.resolve(
      input,
      includeDetailMetrics: false,
    );

    expect(lightweight.query.activeType, full.query.activeType);
    expect(lightweight.query.summaryWindow, full.query.summaryWindow);
    expect(
      lightweight.query.effectiveReferenceDate,
      full.query.effectiveReferenceDate,
    );
    expect(
      lightweight.query.scopeOptions.map((option) => option.key),
      full.query.scopeOptions.map((option) => option.key),
    );
    expect(lightweight.balance, full.balance);
    expect(lightweight.summary.activeAmount, full.summary.activeAmount);
    expect(lightweight.summary.amountText, full.summary.amountText);
    expect(lightweight.visibleLogRowCount, full.visibleLogRowCount);
    expect(lightweight.totalLogEntryCount, full.totalLogEntryCount);
    expect(lightweight.hasMoreLogEntries, full.hasMoreLogEntries);
    expect(
      lightweight.logGroups
          .expand((group) => group.rows)
          .map((row) => '${row.date}|${row.merchant}|${row.amount}'),
      full.logGroups
          .expand((group) => group.rows)
          .map((row) => '${row.date}|${row.merchant}|${row.amount}'),
    );

    expect(lightweight.fastInfoMetrics, isEmpty);
    expect(lightweight.insights, isEmpty);
    expect(lightweight.variableBudgets, isEmpty);
    expect(lightweight.topCategories, isEmpty);
    expect(lightweight.topMerchants, isEmpty);
    expect(
      lightweight.topCategoriesFor(SpendeeBalanceRankDimension.month),
      isEmpty,
    );
    expect(
      lightweight.topVendorsFor(SpendeeBalanceRankDimension.month),
      isEmpty,
    );
    expect(
      lightweight.averageFor(SpendeeBalanceAverageDimension.month).total,
      0,
    );
    expect(
      lightweight.noSpendFor(SpendeeBalanceNoSpendDimension.month).noSpendDays,
      0,
    );
  });

  test('derives monthly and yearly scopes after non-date filters', () {
    final transactions = <TransactionRecord>[
      _transaction(1, '2026.05.10', -100, 'Focus Market', categoryId: 1),
      _transaction(2, '2026.07.10', -200, 'Focus Market', categoryId: 1),
      _transaction(3, '2026.06.10', -300, 'Other', categoryId: 1),
      _transaction(4, '2026.06.11', -400, 'Focus Market', categoryId: 2),
      _transaction(5, '2023.02.10', -500, 'Focus Market', categoryId: 1),
      _transaction(6, '2025.02.10', -600, 'Focus Market', categoryId: 1),
    ];
    final monthly = BalanceFrameResolver.resolve(
      _input(
        transactions: transactions,
        summaryReferenceDate: DateTime(2026, 6),
        searchQuery: 'focus',
        merchantFilters: const {'Focus Market'},
        categoryIds: const {1},
        visibleLogEntryLimit: 0,
      ),
    );

    expect(monthly.query.scopeOptions.map((option) => option.key), [
      '2023-02',
      '2025-02',
      '2026-05',
      '2026-07',
    ]);
    expect(
      monthly.query.selectedScope?.key,
      '2026-05',
      reason: 'Equal-distance ties deterministically choose the earlier scope.',
    );
    expect(monthly.summary.referenceDate, DateTime(2026, 5));
    expect(monthly.summary.activeAmount, 100);
    expect(
      monthly.logGroups.expand((group) => group.rows),
      hasLength(1),
      reason: 'A stale empty window must not hide the nearest valid scope.',
    );

    final yearly = BalanceFrameResolver.resolve(
      _input(
        transactions: transactions,
        summaryWindow: SummaryWindow.yearly,
        summaryReferenceDate: DateTime(2024),
        searchQuery: 'focus',
        merchantFilters: const {'Focus Market'},
        categoryIds: const {1},
      ),
    );

    expect(yearly.query.scopeOptions.map((option) => option.key), [
      '2023',
      '2025',
      '2026',
    ]);
    expect(yearly.query.selectedScope?.key, '2023');
    expect(yearly.summary.referenceDate, DateTime(2023));
    expect(yearly.summary.activeAmount, 500);
  });

  test('in-flight recurring-only month never falls back before projection', () {
    final frame = BalanceFrameResolver.resolve(
      _input(
        summaryReferenceDate: DateTime(2026, 8),
        ghostProjectionInFlight: true,
      ),
    );

    expect(frame.query.requestedReferenceDate, DateTime(2026, 8));
    expect(frame.query.effectiveReferenceDate, DateTime(2026, 8));
    expect(frame.query.selectedScope, isNull);
    expect(frame.query.hasPendingScopeFallback, isFalse);
  });

  test(
    'query filtering clears every query-derived card outside the result set',
    () {
      final filtered = BalanceFrameResolver.resolve(
        _input(searchQuery: 'grocery'),
        ghostPolicy: BalanceGhostPolicy.all,
      );

      expect(filtered.balance, 0);
      expect(filtered.variableBudgets[BalanceBudgetPeriod.month]!.spent, 0);
      expect(filtered.topMerchants[BalanceMerchantPeriod.month], isEmpty);
      expect(filtered.logGroups.expand((group) => group.rows), isEmpty);
    },
  );

  test(
    'ghost policy recomputes cards without counting generated duplicates',
    () {
      final input = _input();

      final withoutGhosts = BalanceFrameResolver.resolve(
        input,
        ghostPolicy: BalanceGhostPolicy.none,
      );
      final withGhosts = BalanceFrameResolver.resolve(
        input,
        ghostPolicy: BalanceGhostPolicy.all,
      );

      expect(
        withGhosts.variableBudgets[BalanceBudgetPeriod.month]!.spent -
            withoutGhosts.variableBudgets[BalanceBudgetPeriod.month]!.spent,
        500,
      );
      expect(
        withGhosts.averageDaily.rollingTotal -
            withoutGhosts.averageDaily.rollingTotal,
        500,
      );
      expect(
        withoutGhosts.topMerchants[BalanceMerchantPeriod.month]!.map(
          (merchant) => merchant.name,
        ),
        isNot(contains('Netflix')),
      );
      expect(
        withGhosts.topMerchants[BalanceMerchantPeriod.month]!.map(
          (merchant) => merchant.name,
        ),
        contains('Netflix'),
      );
      expect(
        withoutGhosts.insights[BalanceInsightKind.upcomingRecurring]?.ghost,
        isNull,
      );
      expect(
        withGhosts.insights[BalanceInsightKind.upcomingRecurring]?.ghost?.id,
        45,
      );
      expect(
        withGhosts.logGroups
            .expand((group) => group.rows)
            .where((row) => row.ghost != null)
            .map((row) => row.ghost!.id),
        [45],
        reason: 'The card policy never reintroduces a generated ghost.',
      );
    },
  );

  test('future recurring ghost is upcoming, never the latest transaction', () {
    final frame = BalanceFrameResolver.resolve(
      _input(
        transactions: <TransactionRecord>[
          _transaction(810, '2026.07.21', -4250, 'Latest real transaction'),
        ],
        recurringGhosts: const <RecurringGhostRecord>[
          RecurringGhostRecord(
            id: 910,
            recurringTransactionId: 910,
            periodKey: '2026-07',
            name: 'Future recurring transaction',
            amount: 3490,
            transactionType: 'expense',
            date: '2026.07.22',
            time: '08:00',
            categoryId: 1,
            categoryName: 'Food',
            categoryColor: '#24c889',
            categoryIconSlot: 1,
            triggerMillis: 0,
            isActivated: false,
            activatedTransactionId: null,
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      ),
      ghostPolicy: BalanceGhostPolicy.all,
    );

    expect(
      frame.insights[BalanceInsightKind.latestTransaction]!.record?.id,
      810,
    );
    expect(
      frame.insights[BalanceInsightKind.latestTransaction]!.primaryText,
      '-4 250 Ft',
    );
    expect(
      frame.insights[BalanceInsightKind.latestTransaction]!.secondaryText,
      'Latest real transaction · ma, 05:00',
    );
    expect(frame.insights[BalanceInsightKind.latestTransaction]!.ghost, isNull);
    expect(
      frame.insights[BalanceInsightKind.upcomingRecurring]!.ghost?.id,
      910,
    );
    expect(
      frame.insights[BalanceInsightKind.upcomingRecurring]!.primaryText,
      '-3 490 Ft',
    );
  });

  test('upcoming recurring expense ignores an earlier income ghost', () {
    final frame = BalanceFrameResolver.resolve(
      _input(
        recurringGhosts: const <RecurringGhostRecord>[
          RecurringGhostRecord(
            id: 920,
            recurringTransactionId: 920,
            periodKey: '2026-07',
            name: 'Upcoming salary',
            amount: 500000,
            transactionType: 'income',
            date: '2026.07.22',
            time: '08:00',
            categoryId: 3,
            categoryName: 'Salary',
            categoryColor: '#3b82f6',
            categoryIconSlot: 3,
            triggerMillis: 0,
            isActivated: false,
            activatedTransactionId: null,
            createdAt: 0,
            updatedAt: 0,
          ),
          RecurringGhostRecord(
            id: 921,
            recurringTransactionId: 921,
            periodKey: '2026-07',
            name: 'Upcoming rent',
            amount: 120000,
            transactionType: 'expense',
            date: '2026.07.23',
            time: '08:00',
            categoryId: 1,
            categoryName: 'Food',
            categoryColor: '#24c889',
            categoryIconSlot: 1,
            triggerMillis: 0,
            isActivated: false,
            activatedTransactionId: null,
            createdAt: 0,
            updatedAt: 0,
          ),
        ],
      ),
      ghostPolicy: BalanceGhostPolicy.all,
    );

    expect(
      frame.insights[BalanceInsightKind.upcomingRecurring]!.ghost?.id,
      921,
    );
    expect(
      frame.insights[BalanceInsightKind.upcomingRecurring]!.primaryText,
      '-120 000 Ft',
    );
  });

  group('all nine card sections own their pending-ghost policy', () {
    test('no-spend recomputes', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.noSpend}),
      );

      expect(
        withGhost.insights[BalanceInsightKind.noSpend]!.numericValue,
        lessThan(without.insights[BalanceInsightKind.noSpend]!.numericValue!),
      );
    });

    test('category change recomputes', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.categoryChange}),
      );

      expect(
        withGhost
            .insights[BalanceInsightKind.categoryChange]!
            .category
            ?.transactionCategoryID,
        2,
      );
      expect(
        withGhost.insights[BalanceInsightKind.categoryChange]!.numericValue,
        greaterThan(
          without.insights[BalanceInsightKind.categoryChange]!.numericValue!,
        ),
      );
    });

    test('latest transaction recomputes', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.latestTransaction}),
      );

      expect(
        without.insights[BalanceInsightKind.latestTransaction]!.record?.id,
        801,
      );
      expect(
        withGhost.insights[BalanceInsightKind.latestTransaction]!.ghost?.id,
        902,
      );
    });

    test('trend comparison recomputes', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.trendComparison}),
      );

      expect(
        withGhost.insights[BalanceInsightKind.trendComparison]!.numericValue,
        greaterThan(
          without.insights[BalanceInsightKind.trendComparison]!.numericValue!,
        ),
      );
    });

    test('upcoming recurring recomputes', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.upcomingRecurring}),
      );

      expect(
        without.insights[BalanceInsightKind.upcomingRecurring]!.ghost,
        isNull,
      );
      expect(
        withGhost.insights[BalanceInsightKind.upcomingRecurring]!.ghost?.id,
        902,
      );
    });

    test('variable budget recomputes', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.variableBudget}),
      );

      expect(
        withGhost.variableBudgets[BalanceBudgetPeriod.month]!.spent,
        greaterThan(without.variableBudgets[BalanceBudgetPeriod.month]!.spent),
      );
    });

    test('top category recomputes', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.topCategories}),
      );

      expect(
        without
            .topCategories[BalanceCategoryPeriod.month]
            ?.category
            ?.transactionCategoryID,
        1,
      );
      expect(
        withGhost
            .topCategories[BalanceCategoryPeriod.month]
            ?.category
            ?.transactionCategoryID,
        2,
      );
    });

    test('top merchants recompute', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.topMerchants}),
      );

      expect(
        without.topMerchants[BalanceMerchantPeriod.month]!.first.name,
        'Policy Market',
      );
      expect(
        withGhost.topMerchants[BalanceMerchantPeriod.month]!.first.name,
        'Ghost King',
      );
    });

    test('average daily recomputes', () {
      final without = _resolvePolicy(BalanceGhostPolicy.none);
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.only({BalanceGhostSection.averageDaily}),
      );

      expect(
        withGhost.averageDaily.rollingTotal,
        greaterThan(without.averageDaily.rollingTotal),
      );
    });
  });

  test(
    'ghost-aware adapter replaces stale source metrics used by production UI',
    () {
      const staleMetric = FastInfoMetricResult(
        pillValue: 'STALE',
        primaryValue: 'STALE',
        visual: FastInfoVisualDescriptor(
          kind: FastInfoVisualKind.spikeLine,
          value: 99,
          values: <double>[99, 99],
        ),
        chartSeries: <FastInfoChartSeries>[
          FastInfoChartSeries(label: 'stale', values: <double>[99, 99]),
        ],
      );
      final metrics = <String, FastInfoMetricResult>{
        'no_spend_napok_szama': staleMetric,
        'legnagyobb_novekedo_kategoria': staleMetric,
        'legutobbi_tranzakcio': staleMetric,
        'koltesi_trend': staleMetric,
        'atlagos_napi_koltes': staleMetric,
      };
      final without = _resolvePolicy(
        BalanceGhostPolicy.none,
        fastInfoMetrics: metrics,
      );
      final withGhost = _resolvePolicy(
        BalanceGhostPolicy.all,
        fastInfoMetrics: metrics,
      );

      expect(
        without.insights[BalanceInsightKind.noSpend]!.sourceMetric!.pillValue,
        isNot('STALE'),
      );
      expect(
        withGhost.insights[BalanceInsightKind.noSpend]!.sourceMetric!.pillValue,
        isNot(
          without.insights[BalanceInsightKind.noSpend]!.sourceMetric!.pillValue,
        ),
      );
      expect(
        withGhost
                .insights[BalanceInsightKind.categoryChange]!
                .sourceMetric!
                .visual
                .values
                .last -
            withGhost
                .insights[BalanceInsightKind.categoryChange]!
                .sourceMetric!
                .visual
                .values
                .first,
        withGhost.insights[BalanceInsightKind.categoryChange]!.numericValue,
      );
      expect(
        withGhost.insights[BalanceInsightKind.categoryChange]!.secondaryText,
        'előző 30 naphoz képest',
      );
      expect(
        withGhost
            .insights[BalanceInsightKind.latestTransaction]!
            .sourceMetric!
            .primaryValue,
        withGhost.insights[BalanceInsightKind.latestTransaction]!.primaryText,
      );
      expect(
        without
            .insights[BalanceInsightKind.latestTransaction]!
            .sourceMetric!
            .secondaryValues,
        <String>['Policy Market · Food', '2026-07-20 19:00'],
      );
      expect(
        withGhost
            .insights[BalanceInsightKind.latestTransaction]!
            .sourceMetric!
            .secondaryValues,
        <String>['Ghost King · Transport', 'ma 08:00'],
      );
      expect(
        withGhost
            .insights[BalanceInsightKind.trendComparison]!
            .sourceMetric!
            .pillValue,
        isNot('STALE'),
      );
      expect(
        withGhost.fastInfoMetrics['atlagos_napi_koltes']!.series,
        withGhost.averageDaily.dailySeries,
      );
      expect(
        withGhost.fastInfoMetrics['atlagos_napi_koltes']!.series,
        isNot(without.fastInfoMetrics['atlagos_napi_koltes']!.series),
      );
    },
  );

  test('yearly and all-time rails never admit stale monthly ghosts', () {
    const staleGhost = RecurringGhostRecord(
      id: 950,
      recurringTransactionId: 950,
      periodKey: '2030-01',
      name: 'Stale future ghost',
      amount: 50000,
      transactionType: 'expense',
      date: '2030.01.15',
      time: '12:00',
      categoryId: 2,
      categoryName: 'Transport',
      categoryColor: '#fa8a39',
      categoryIconSlot: 2,
      triggerMillis: 0,
      isActivated: false,
      activatedTransactionId: null,
      createdAt: 0,
      updatedAt: 0,
    );
    final transactions = <TransactionRecord>[
      _transaction(951, '2023.02.01', -100, '2023 row'),
      _transaction(952, '2025.02.01', -200, '2025 row'),
    ];

    final yearly = BalanceFrameResolver.resolve(
      _input(
        transactions: transactions,
        recurringGhosts: const [staleGhost],
        summaryWindow: SummaryWindow.yearly,
        summaryReferenceDate: DateTime(2030),
      ),
    );
    expect(yearly.query.scopeOptions.map((option) => option.key), [
      '2023',
      '2025',
    ]);
    expect(yearly.query.effectiveReferenceDate, DateTime(2025));
    expect(yearly.summary.activeAmount, 200);
    expect(
      yearly.logGroups
          .expand((group) => group.rows)
          .where((row) => row.isGhost),
      isEmpty,
    );
    expect(yearly.totalLogEntryCount, 2);

    final allTime = BalanceFrameResolver.resolve(
      _input(
        transactions: transactions,
        recurringGhosts: const [staleGhost],
        summaryWindow: SummaryWindow.allTime,
        summaryReferenceDate: DateTime(2030),
      ),
    );
    expect(allTime.query.scopeOptions.map((option) => option.key), [
      '2023',
      '2025',
    ]);
    expect(allTime.summary.activeAmount, 300);
    expect(
      allTime.logGroups
          .expand((group) => group.rows)
          .where((row) => row.isGhost),
      isEmpty,
    );
    expect(allTime.totalLogEntryCount, 4);
  });

  test('top category and merchant metrics exclude activated fixed rows', () {
    final input = _input(
      transactions: <TransactionRecord>[
        _transaction(960, '2026.07.20', -100, 'Variable', categoryId: 1),
        _transaction(
          961,
          '2026.07.20',
          -100000,
          'Activated fixed',
          categoryId: 2,
          recurringTransactionId: 961,
        ),
      ],
      recurringGhosts: const [],
    );

    final frame = BalanceFrameResolver.resolve(
      input,
      ghostPolicy: BalanceGhostPolicy.none,
    );

    expect(
      frame
          .topCategories[BalanceCategoryPeriod.month]
          ?.category
          ?.transactionCategoryID,
      1,
    );
    expect(
      frame.topMerchants[BalanceMerchantPeriod.month]!.map(
        (merchant) => merchant.name,
      ),
      ['Variable'],
    );
  });

  test('today top category is independent from the monthly leader', () {
    final frame = BalanceFrameResolver.resolve(
      _input(
        transactions: <TransactionRecord>[
          _transaction(970, '2026.07.21', -200, 'Today leader', categoryId: 2),
          _transaction(
            971,
            '2026.07.20',
            -10000,
            'Month leader',
            categoryId: 1,
          ),
        ],
        recurringGhosts: const [],
      ),
      ghostPolicy: BalanceGhostPolicy.none,
    );

    expect(
      frame
          .topCategories[BalanceCategoryPeriod.day]
          ?.category
          ?.transactionCategoryID,
      2,
    );
    expect(
      frame
          .topCategories[BalanceCategoryPeriod.month]
          ?.category
          ?.transactionCategoryID,
      1,
    );
  });
}

BalanceFrameInput _input({
  List<TransactionRecord>? transactions,
  List<RecurringGhostRecord>? recurringGhosts,
  SummaryWindow summaryWindow = SummaryWindow.monthly,
  DateTime? summaryReferenceDate,
  String searchQuery = '',
  Set<String> merchantFilters = const <String>{},
  Set<int> categoryIds = const <int>{},
  Map<String, FastInfoMetricResult> fastInfoMetrics =
      const <String, FastInfoMetricResult>{},
  int visibleLogEntryLimit = 5,
  bool ghostProjectionInFlight = false,
}) {
  return BalanceFrameInput(
    now: DateTime(2026, 7, 21, 12),
    activeType: TransactionType.expense,
    summaryWindow: summaryWindow,
    summaryReferenceDate: summaryReferenceDate ?? DateTime(2026, 7),
    searchQuery: searchQuery,
    merchantFilters: merchantFilters,
    categoryIds: categoryIds,
    transactions: transactions ?? _transactions(),
    recurringGhosts: recurringGhosts ?? _ghosts(),
    categories: _categories,
    limits: const <CategoryLimit>[_monthlyExpenseLimit],
    fastInfoMetrics: fastInfoMetrics,
    visibleLogEntryLimit: visibleLogEntryLimit,
    ghostProjectionInFlight: ghostProjectionInFlight,
  );
}

BalanceRenderFrame _resolvePolicy(
  BalanceGhostPolicy policy, {
  Map<String, FastInfoMetricResult> fastInfoMetrics =
      const <String, FastInfoMetricResult>{},
}) {
  return BalanceFrameResolver.resolve(
    _input(
      transactions: <TransactionRecord>[
        _transaction(800, '2026.06.15', -100, 'Old Market', categoryId: 1),
        _transaction(801, '2026.07.20', -100, 'Policy Market', categoryId: 1),
      ],
      recurringGhosts: const <RecurringGhostRecord>[
        RecurringGhostRecord(
          id: 901,
          recurringTransactionId: 901,
          periodKey: '2026-07',
          name: 'Ghost King',
          amount: 9000,
          transactionType: 'expense',
          date: '2026.07.19',
          time: '12:00',
          categoryId: 2,
          categoryName: 'Transport',
          categoryColor: '#fa8a39',
          categoryIconSlot: 2,
          triggerMillis: 0,
          isActivated: false,
          activatedTransactionId: null,
          createdAt: 0,
          updatedAt: 0,
        ),
        RecurringGhostRecord(
          id: 902,
          recurringTransactionId: 902,
          periodKey: '2026-07',
          name: 'Ghost King',
          amount: 7000,
          transactionType: 'expense',
          date: '2026.07.21',
          time: '08:00',
          categoryId: 2,
          categoryName: 'Transport',
          categoryColor: '#fa8a39',
          categoryIconSlot: 2,
          triggerMillis: 0,
          isActivated: false,
          activatedTransactionId: null,
          createdAt: 0,
          updatedAt: 0,
        ),
      ],
      fastInfoMetrics: fastInfoMetrics,
    ),
    ghostPolicy: policy,
  );
}

List<TransactionRecord> _transactions() {
  return <TransactionRecord>[
    _transaction(100, '2026.07.21', -1000, 'Lidl', categoryId: 1),
    _transaction(101, '2026.07.20', -2000, 'MOL', categoryId: 2),
    _transaction(102, '2026.07.10', -3000, 'Lidl', categoryId: 1),
    _transaction(103, '2026.06.30', -4000, 'June Market', categoryId: 1),
    _transaction(104, '2026.06.15', -5000, 'Previous', categoryId: 2),
    _transaction(105, '2026.05.30', -6000, 'Previous', categoryId: 1),
    _transaction(106, '2026.01.10', -7000, 'Lidl', categoryId: 1),
    _transaction(107, '2025.12.01', -8000, 'Historic', categoryId: 1),
    _transaction(108, '2026.07.01', 20000, 'Salary', categoryId: 3),
    _transaction(
      109,
      '2026.07.21',
      -900,
      'Duplicate fixed',
      categoryId: 1,
      recurringTransactionId: 44,
    ),
  ];
}

List<RecurringGhostRecord> _ghosts() {
  return const <RecurringGhostRecord>[
    RecurringGhostRecord(
      id: 44,
      recurringTransactionId: 44,
      periodKey: '2026-07',
      name: 'Duplicate fixed',
      amount: 900,
      transactionType: 'expense',
      date: '2026.07.21',
      time: '20:00',
      categoryId: 1,
      categoryName: 'Food',
      categoryColor: '#24c889',
      categoryIconSlot: 1,
      triggerMillis: 0,
      isActivated: false,
      activatedTransactionId: null,
      createdAt: 0,
      updatedAt: 0,
    ),
    RecurringGhostRecord(
      id: 45,
      recurringTransactionId: 45,
      periodKey: '2026-07',
      name: 'Netflix',
      amount: 500,
      transactionType: 'expense',
      date: '2026.07.21',
      time: '23:00',
      categoryId: 1,
      categoryName: 'Food',
      categoryColor: '#24c889',
      categoryIconSlot: 1,
      triggerMillis: 0,
      isActivated: false,
      activatedTransactionId: null,
      createdAt: 0,
      updatedAt: 0,
    ),
    RecurringGhostRecord(
      id: 46,
      recurringTransactionId: 46,
      periodKey: '2026-07',
      name: 'Activated',
      amount: 700,
      transactionType: 'expense',
      date: '2026.07.22',
      time: '08:00',
      categoryId: 2,
      categoryName: 'Transport',
      categoryColor: '#fa8a39',
      categoryIconSlot: 2,
      triggerMillis: 0,
      isActivated: true,
      activatedTransactionId: 777,
      createdAt: 0,
      updatedAt: 0,
    ),
  ];
}

TransactionRecord _transaction(
  int id,
  String date,
  double amount,
  String merchant, {
  int categoryId = 1,
  int? recurringTransactionId,
}) {
  return TransactionRecord(
    id: id,
    date: date,
    time: '${(id % 23).toString().padLeft(2, '0')}:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: merchant,
    amount: amount,
    userAssignedName: null,
    transactionCategoryID: categoryId,
    recurringTransactionId: recurringTransactionId,
  );
}

const _monthlyExpenseLimit = CategoryLimit(
  id: 1,
  targetType: LimitTargetType.overview,
  targetId: 0,
  transactionType: 'expense',
  window: LimitWindow.monthly,
  periodKey: '2026-07',
  hasLimit: true,
  limitAmount: 10000,
  alertActive: true,
  createdAt: 0,
  updatedAt: 0,
);

final _categories = <TransactionCategory>[
  TransactionCategory.fromMap({
    'transactionCategoryID': 1,
    'name': 'Food',
    'type': 'expense',
    'colorSlot': 1,
    'iconSlot': 1,
    'backgroundColor': '#24c889',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  }),
  TransactionCategory.fromMap({
    'transactionCategoryID': 2,
    'name': 'Transport',
    'type': 'expense',
    'colorSlot': 2,
    'iconSlot': 2,
    'backgroundColor': '#fa8a39',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  }),
  TransactionCategory.fromMap({
    'transactionCategoryID': 3,
    'name': 'Salary',
    'type': 'income',
    'colorSlot': 3,
    'iconSlot': 3,
    'backgroundColor': '#3b82f6',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  }),
];
