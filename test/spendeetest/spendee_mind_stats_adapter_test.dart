import 'dart:io';

import 'package:exptv2/features/stats/data/stats_year_data.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/recurring_rule.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_mind_stats_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mind host owns frame, rail, and year-carousel runtime', () {
    final facade = File(
      'lib/features/transactions/widgets/experimental/'
      'spendee_test_dashboard.dart',
    ).readAsStringSync();
    final mindHost = File(
      'lib/features/transactions/widgets/experimental/modes/'
      'spendee_mind_mode_host.dart',
    ).readAsStringSync();
    final budgetHost = File(
      'lib/features/transactions/widgets/experimental/modes/'
      'spendee_budget_mode_host.dart',
    ).readAsStringSync();

    for (final facadeRuntimeField in const <String>[
      '_MindStatsFrameCacheKey? _mindStatsFrameCacheKey;',
      'SpendeeMindStatsFrame? _mindStatsFrameCache;',
      '_MindSumVolumeFrameCacheKey? _mindSumVolumeFrameCacheKey;',
      'StatsRenderFrame? _mindSumVolumeFrameCache;',
      'final _mindSumYearFrameCache =',
      '_MindSumStage2WidgetCacheKey? _mindSumStage2WidgetCacheKey;',
      'Widget? _mindSumStage2WidgetCache;',
      'int? _selectedMindSumYear;',
      'int? _publishedMindSumYear;',
      'SpendeeCenterCarouselController? _mindSumYearCarouselController;',
      'late final AnimationController _mindSumYearCarouselReleaseController;',
      'late final ValueNotifier<_MindGlobalRailPresentation>',
      'late Widget _homeContent;',
      'late final ValueNotifier<SpendeeHeaderStage> _stageNotifier;',
    ]) {
      expect(
        facade,
        isNot(contains(facadeRuntimeField)),
        reason: '$facadeRuntimeField must not remain in the dashboard facade',
      );
    }

    for (final hostRuntimeField in const <String>[
      'late TransactionStore _mindStore;',
      'SpendeeMindStatsFrame? _mindStatsFrameCache;',
      'SpendeeCenterCarouselController? _mindSumYearCarouselController;',
      'late final AnimationController _mindSumYearCarouselReleaseController;',
      'late final ValueNotifier<_MindGlobalRailPresentation>',
      'late final ValueNotifier<SpendeeHeaderStage> _stageNotifier;',
      'Widget? _mindHomeContent;',
      'void _invalidateMindRuntimeForStoreReplacement()',
      'homeContent: _mindHomeContent!',
    ]) {
      expect(
        mindHost,
        contains(hostRuntimeField),
        reason: '$hostRuntimeField must be owned by the Mind host',
      );
    }

    expect(
      facade,
      isNot(contains('with TickerProviderStateMixin')),
      reason: 'the dashboard facade must not own Mind animation vsync',
    );
    expect(
      budgetHost,
      isNot(contains('mindGlobalRailPresentationListenable:')),
      reason: 'the Budget legacy home must not receive a Mind rail',
    );
    expect(
      budgetHost,
      isNot(contains('_MindGlobalRailPresentation')),
      reason: 'the Budget host must not own Mind rail presentation state',
    );
    expect(
      budgetHost,
      contains('Widget? _legacyHomeContent;'),
      reason:
          'the Budget host must retain its home content across animation frames',
    );
    expect(
      budgetHost,
      contains('homeContent: _legacyHomeContent!'),
      reason: 'the Budget host must reuse the cached home content in build',
    );
  });

  test('mind stats frame maps summary windows to stats scopes', () async {
    final store = TransactionStore(
      _MindStatsRepository(),
      clock: () => DateTime(2026, 7, 18),
    );
    await store.start();

    expect(
      SpendeeMindStatsFrame.fromStore(store).summaryScope,
      StatsSummaryScope.allTime,
    );

    await store.setSummaryYear(2026);
    expect(
      SpendeeMindStatsFrame.fromStore(store).summaryScope,
      StatsSummaryScope.yearly,
    );

    await store.setSummaryMonth(2026, 7);
    expect(
      SpendeeMindStatsFrame.fromStore(store).summaryScope,
      StatsSummaryScope.monthly,
    );
  });

  test(
    'mind stats frame exposes live expense and income chart series',
    () async {
      final store = TransactionStore(
        _MindStatsRepository(),
        clock: () => DateTime(2026, 7, 18),
      );
      await store.start();
      await store.setSummaryYear(2026);

      final frame = SpendeeMindStatsFrame.fromStore(store);

      expect(frame.expenseFrame.categoryScopeSeries.scoreLine, isNotEmpty);
      expect(frame.expenseFrame.categoryScopeSeries.helperBars, isNotEmpty);
      expect(frame.incomeFrame.categoryScopeSeries.scoreLine, isNotEmpty);
      expect(
        frame.incomeFrame.categoryScopeSeries.incomeComparisonBars,
        isNotEmpty,
      );
    },
  );

  test('mind stats frame follows active type and vendor filters', () async {
    final store = TransactionStore(
      _MindStatsRepository(),
      clock: () => DateTime(2026, 7, 18),
    );
    await store.start();
    await store.setSummaryYear(2026);

    final unfiltered = SpendeeMindStatsFrame.fromStore(store);
    expect(unfiltered.activeFrame.yearData.metricRecordCount, greaterThan(2));

    store.setMerchantFilter('Piac');
    final filtered = SpendeeMindStatsFrame.fromStore(store);

    expect(filtered.modeKey, 'yearly');
    expect(filtered.activeFrame.yearData.metricRecordCount, 2);
    expect(filtered.activeFrame.yearData.largestVisibleVendor, 'Piac');
  });

  test(
    'mind stats frame exposes active volume and pattern chart inputs',
    () async {
      final store = TransactionStore(
        _MindStatsRepository(),
        clock: () => DateTime(2026, 7, 18),
      );
      await store.start();
      await store.setSummaryYear(2026);

      final expense = SpendeeMindStatsFrame.fromStore(store);
      expect(expense.activeFrame.yearData.activeType, TransactionType.expense);
      expect(
        expense.activeVolumePoints,
        same(expense.expenseFrame.categoryScopeSeries.valueIndex),
      );
      expect(
        expense.activePatternBars,
        same(expense.expenseFrame.categoryScopeSeries.helperBars),
      );

      store.setActiveType(TransactionType.income);
      final income = SpendeeMindStatsFrame.fromStore(store);
      expect(income.activeFrame.yearData.activeType, TransactionType.income);
      expect(
        income.activeVolumePoints,
        same(income.incomeFrame.categoryScopeSeries.valueIndex),
      );
      expect(
        income.activePatternBars,
        same(income.incomeFrame.categoryScopeSeries.helperBars),
      );
      expect(
        income.activeVolumePoints,
        isNot(same(expense.activeVolumePoints)),
      );
      expect(income.activePatternBars, isNot(same(expense.activePatternBars)));
    },
  );

  test(
    'mind stats frame active score follows summary scope and filters',
    () async {
      final store = TransactionStore(
        _MindStatsRepository(),
        clock: () => DateTime(2026, 7, 18),
      );
      await store.start();
      await store.setSummaryYear(2026);

      store.setActiveType(TransactionType.income);
      final yearlyIncome = SpendeeMindStatsFrame.fromStore(store);
      expect(
        yearlyIncome.activeScoreLine,
        same(yearlyIncome.incomeFrame.categoryScopeSeries.scoreLine),
      );

      await store.setSummaryMonth(2026, 1);
      final monthlyIncome = SpendeeMindStatsFrame.fromStore(store);
      expect(monthlyIncome.activeScore, isNot(yearlyIncome.activeScore));
      expect(
        monthlyIncome.activeScoreLine,
        same(monthlyIncome.incomeFrame.categoryScopeSeries.scoreLine),
      );

      await store.setSummaryYear(2026);
      store.setActiveType(TransactionType.expense);
      final unfilteredExpense = SpendeeMindStatsFrame.fromStore(store);
      store.setMerchantFilter('Piac');
      final filteredExpense = SpendeeMindStatsFrame.fromStore(store);
      expect(filteredExpense.activeScore, isNot(unfilteredExpense.activeScore));
      expect(
        filteredExpense.activeScoreLine,
        same(filteredExpense.expenseFrame.categoryScopeSeries.scoreLine),
      );
    },
  );

  test(
    'mind SUM selected-year frame keeps active query, type, and monthly volume data',
    () async {
      final store = TransactionStore(
        _MindStatsRepository(),
        clock: () => DateTime(2026, 7, 18),
      );
      await store.start();

      final allTime = SpendeeMindStatsFrame.fromStore(store);
      final expenseYearSummary = allTime.activeFrame.yearData.sumYearSummaries
          .firstWhere((summary) => summary.year == 2026);
      expect(expenseYearSummary.monthTotals.keys.toList()..sort(), [1, 2, 3]);

      final rawVolume = SpendeeMindStatsFrame.sumYearVolumeFrameFromStore(
        store,
        activeType: TransactionType.expense,
      );
      final rawVolumeSummary = rawVolume.yearData.sumYearSummaries.firstWhere(
        (summary) => summary.year == 2026,
      );
      expect(rawVolumeSummary.monthTotals.keys.toList()..sort(), [1, 2, 3, 4]);
      expect(rawVolumeSummary.monthTotals[4], 1000);

      final expense = SpendeeMindStatsFrame.sumYearFrameFromStore(
        store,
        year: 2026,
        activeType: TransactionType.expense,
      );
      expect(expense.yearData.summaryScope, StatsSummaryScope.yearly);
      expect(
        [
          for (final month in expense.yearData.months)
            if (month.transactionCount > 0) month.month,
        ],
        [1, 2, 3],
      );
      expect(expense.yearData.summaryTotal, 58800);

      store.setCategoryFilter(_MindStatsRepository().categories.first);
      final food = SpendeeMindStatsFrame.sumYearFrameFromStore(
        store,
        year: 2026,
        activeType: TransactionType.expense,
      );
      expect(food.yearData.selectedCategoryIds, {1});
      final foodAllTime = SpendeeMindStatsFrame.fromStore(store);
      final foodYearSummary = foodAllTime.activeFrame.yearData.sumYearSummaries
          .firstWhere((summary) => summary.year == 2026);
      expect(foodYearSummary.monthTotals.keys.toList()..sort(), [1, 2]);
      expect(
        [
          for (final month in food.yearData.months)
            if (month.transactionCount > 0) month.month,
        ],
        [1, 2],
      );
      expect(food.yearData.summaryTotal, 42000);

      store.clearCategoryFilter();
      store.setMerchantFilter('Piac');
      final vendor = SpendeeMindStatsFrame.sumYearFrameFromStore(
        store,
        year: 2026,
        activeType: TransactionType.expense,
      );
      expect(vendor.yearData.summaryTotal, 42000);
      expect(
        [
          for (final month in vendor.yearData.months)
            if (month.transactionCount > 0) month.month,
        ],
        [1, 2],
      );

      store.setActiveType(TransactionType.income);
      store.clearCategoryFilter();
      store.setMerchantFilters(const <String>{});
      final income = SpendeeMindStatsFrame.sumYearFrameFromStore(
        store,
        year: 2026,
        activeType: TransactionType.income,
      );
      expect(income.yearData.summaryTotal, 1090000);
      expect(
        [
          for (final month in income.yearData.months)
            if (month.transactionCount > 0) month.month,
        ],
        [1, 2, 3],
      );
    },
  );
}

class _MindStatsRepository implements TransactionRepositoryContract {
  final categories = <TransactionCategory>[
    _category(1, 'Élelmiszer', 'kiadás'),
    _category(2, 'Közlekedés', 'kiadás'),
    _category(101, 'Fizetés', 'bevétel'),
  ];

  late final transactions = <TransactionRecord>[
    _record(1, '2026.01.03', 1, -11000, 'Piac'),
    _record(2, '2026.01.11', 2, -7200, 'Busz'),
    _record(3, '2026.02.04', 1, -31000, 'Piac'),
    _record(4, '2026.03.12', 2, -9600, 'Metro'),
    _record(8, '2026.04.05', 1, -1000, 'Piac'),
    _record(5, '2026.01.01', 101, 280000, 'Munkahely'),
    _record(6, '2026.02.01', 101, 310000, 'Munkahely'),
    _record(7, '2026.03.01', 101, 500000, 'Munkahely'),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    return TransactionBootstrap(
      categories: categories,
      transactions: transactions,
      limits: const <CategoryLimit>[],
    );
  }

  @override
  Future<List<TransactionRecord>> transactionsForNotificationEvents(
    Iterable<int> eventIds,
  ) async {
    return const <TransactionRecord>[];
  }

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    final rows = transactions
        .where((record) {
          if (query.type != null && record.type != query.type) return false;
          if (query.categoryId != null &&
              record.transactionCategoryID != query.categoryId) {
            return false;
          }
          if (query.merchant != null &&
              record.displayMerchant != query.merchant) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    return TransactionPage(
      transactions: rows,
      totalCount: rows.length,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTransaction(int id) {
    throw UnimplementedError();
  }

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) {
    throw UnimplementedError();
  }

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async {
    return const <RecurringGhostRecord>[];
  }

  @override
  Future<List<RecurringRule>> listRecurringRules() async {
    return const <RecurringRule>[];
  }

  @override
  Future<RecurringRule> addRecurringRule(RecurringRuleDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> updateRecurringRule(int id, RecurringRuleDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> toggleRecurringRule(int id, bool isActive) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteRecurringRule(int id) async {
    return false;
  }

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteCategory(int id) {
    throw UnimplementedError();
  }

  @override
  Future<Map<int, int>> categoryCounts() async {
    return <int, int>{
      for (final category in categories) category.transactionCategoryID: 1,
    };
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async {
    return const <CategoryLimit>[];
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) {
    throw UnimplementedError();
  }
}

TransactionCategory _category(int id, String name, String type) {
  return TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': name,
    'type': type,
    'colorSlot': id % 20,
    'iconSlot': id % 8,
    'backgroundColor': null,
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  });
}

TransactionRecord _record(
  int id,
  String date,
  int categoryId,
  double amount,
  String merchant,
) {
  return TransactionRecord.fromMap({
    'id': id,
    'date': date,
    'time': '10:00',
    'merchant': merchant,
    'amount': amount,
    'userAssignedName': null,
    'transactionCategoryID': categoryId,
  });
}
