import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';

const _savingGoal = CategoryLimit(
  id: 91,
  targetType: LimitTargetType.overview,
  targetId: 0,
  transactionType: 'saving',
  window: LimitWindow.monthly,
  periodKey: '2025-09',
  hasLimit: true,
  limitAmount: 100000,
  alertActive: true,
  createdAt: 0,
  updatedAt: 0,
);

const _rentGhost = RecurringGhostRecord(
  id: 91,
  recurringTransactionId: 91,
  periodKey: '2025-09',
  name: 'Rent',
  amount: 100000,
  transactionType: 'expense',
  date: '2025.09.28',
  time: '08:00',
  categoryId: 6,
  categoryName: 'Q',
  categoryColor: '#dc2626',
  categoryIconSlot: 2,
  triggerMillis: 0,
  isActivated: false,
  activatedTransactionId: null,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  test('store loads bootstrap and filters by active type', () async {
    final store = TransactionStore(FakeTransactionRepository());
    await store.start();

    expect(store.visibleTransactions.length, 3);
    store.setActiveType(TransactionType.income);
    expect(store.visibleTransactions.single.displayMerchant, 'Gguu');
    expect(
      store.activeSummary.formattedFor(TransactionType.income),
      '+5 555 Ft',
    );
  });

  test('store exposes cached category index and display log entries', () async {
    final store = TransactionStore(FakeTransactionRepository());
    await store.start();

    expect(store.categoriesById[6]?.name, 'Q');
    expect(store.categoryTransactionCounts[6], 3);

    final entries = store.visibleDisplayLogEntries;
    expect(entries.first.isHeader, isTrue);
    expect(entries.any((entry) => entry.record != null), isTrue);
    expect(
      entries.where((entry) => entry.header != null).length,
      greaterThan(0),
    );
  });

  test(
    'store reuses expensive visible and budget lists until filters change',
    () async {
      final store = TransactionStore(FakeTransactionRepository());
      await store.start();

      final visibleEntries = store.visibleDisplayLogEntries;
      final visibleEntriesAgain = store.visibleDisplayLogEntries;
      final bars = store.categoryBudgetBars;
      final barsAgain = store.categoryBudgetBars;
      final backheaderItems = store.backheaderBudgetItems;
      final backheaderItemsAgain = store.backheaderBudgetItems;

      expect(identical(visibleEntries, visibleEntriesAgain), isTrue);
      expect(identical(bars, barsAgain), isTrue);
      expect(identical(backheaderItems, backheaderItemsAgain), isTrue);

      store.setActiveType(TransactionType.income);

      expect(
        identical(store.visibleDisplayLogEntries, visibleEntries),
        isFalse,
      );
      expect(identical(store.categoryBudgetBars, bars), isFalse);
      expect(identical(store.backheaderBudgetItems, backheaderItems), isFalse);
    },
  );

  test('store reuses public collection snapshots until data changes', () async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(repository);
    await store.start();

    final transactions = store.transactions;
    final categories = store.categories;
    final limits = store.limits;

    expect(identical(store.transactions, transactions), isTrue);
    expect(identical(store.categories, categories), isTrue);
    expect(identical(store.limits, limits), isTrue);

    await store.addTransaction(
      merchant: 'Fresh Shop',
      amount: 42,
      type: TransactionType.expense,
      categoryId: 6,
      date: '2026.06.03',
      time: '10:00',
    );

    expect(identical(store.transactions, transactions), isFalse);
    expect(identical(store.categories, categories), isFalse);
    expect(identical(store.limits, limits), isFalse);
  });

  test(
    'store reuses FastInfo metrics until transaction data changes',
    () async {
      final repository = FakeTransactionRepository();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2025, 9, 25, 12),
      );
      await store.start();

      final metrics = store.fastInfoMetrics;
      final metricsAgain = store.fastInfoMetrics;

      expect(identical(metrics, metricsAgain), isTrue);
      expect(
        metrics.keys,
        containsAll(fastInfoCardCatalog.map((card) => card.id)),
      );
      expect(
        metrics['atlagos_napi_koltes']?.secondaryValues,
        contains(startsWith('Puffer:')),
      );
      expect(metrics['megtakaritas']?.progress, closeTo(0, .001));
      expect(
        metrics['kovetkezo_ismetlo_kiadas']?.primaryValue,
        contains('Rent'),
      );

      await store.addTransaction(
        merchant: 'Fresh Shop',
        amount: 42,
        type: TransactionType.expense,
        categoryId: 6,
        date: '2025.09.25',
        time: '10:00',
      );

      final refreshedMetrics = store.fastInfoMetrics;
      expect(identical(refreshedMetrics, metrics), isFalse);
      expect(refreshedMetrics['legutobbi_tranzakcio']?.primaryValue, '-42 Ft');

      final beforeProjection = store.fastInfoMetrics;
      await store.cycleSummaryWindow();
      expect(identical(store.fastInfoMetrics, beforeProjection), isFalse);
    },
  );

  test('store applies merchant fast filter and search query', () async {
    final store = TransactionStore(FakeTransactionRepository());
    await store.start();

    store.setMerchantFilter('Rrr');
    expect(store.visibleTransactions.length, 2);

    store.clearMerchantFilter();
    store.setSearchQuery('test');
    expect(store.visibleTransactions.single.displayMerchant, 'Test Store');
  });

  test('store saves transaction then reloads bootstrap', () async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(repository);
    await store.start();

    await store.addTransaction(
      merchant: 'New Shop',
      amount: 42,
      type: TransactionType.expense,
      categoryId: 6,
      date: '2025-09-26',
      time: '10:00',
    );

    expect(repository.savedPayloads.single['merchant'], 'New Shop');
    expect(store.visibleTransactions.first.displayMerchant, 'New Shop');
  });

  test('store updates transaction then reloads bootstrap', () async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(repository);
    await store.start();

    final record = store.visibleTransactions.first;
    await store.updateTransaction(
      record,
      merchant: 'Edited Shop',
      amount: 123,
      type: TransactionType.expense,
      categoryId: 6,
      date: '2025-09-27',
      time: '11:20',
      userAssignedName: 'Edited Alias',
    );

    expect(repository.updatedPayloads.single['id'], record.id);
    expect(repository.updatedPayloads.single['merchant'], record.merchant);
    expect(repository.updatedPayloads.single['userAssignedName'], 'Edited Alias');
    expect(store.visibleTransactions.first.displayMerchant, 'Edited Alias');
  });

  test('store keeps original merchant key when edit name becomes alias', () async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(repository);
    await store.start();

    final record = store.visibleTransactions.first;
    await store.updateTransaction(
      record,
      merchant: 'Edited Shop',
      amount: 123,
      type: TransactionType.expense,
      categoryId: 6,
      date: '2025-09-27',
      time: '11:20',
    );

    expect(repository.updatedPayloads.single['merchant'], record.merchant);
    expect(repository.updatedPayloads.single['userAssignedName'], 'Edited Shop');
  });

  test('store deletes transaction then reloads bootstrap', () async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(repository);
    await store.start();

    final record = store.visibleTransactions.first;
    final deleted = await store.deleteTransaction(record);

    expect(deleted, isTrue);
    expect(repository.deletedTransactionIds.single, record.id);
    expect(
      store.transactions.any((transaction) => transaction.id == record.id),
      isFalse,
    );
  });

  test('store filters and manages categories', () async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(repository);
    await store.start();

    final category = store.categories.firstWhere((item) => item.name == 'Q');
    store.setCategoryFilter(category);
    expect(store.visibleTransactions.length, 3);
    expect(store.activeCategory?.name, 'Q');
    expect(store.categoryTransactionCounts[6], 3);

    await store.addCategory(
      name: 'Travel',
      type: TransactionType.expense,
      colorSlot: 8,
      iconSlot: 3,
    );
    expect(repository.savedCategories.single['name'], 'Travel');
    expect(store.activeCategories.any((item) => item.name == 'Travel'), isTrue);

    final created = store.activeCategories.firstWhere(
      (item) => item.name == 'Travel',
    );
    await store.updateCategory(
      created,
      name: 'Travel Edit',
      colorSlot: 9,
      iconSlot: 4,
    );
    expect(
      repository.updatedCategories.single['id'],
      created.transactionCategoryID,
    );
    expect(
      store.activeCategories.any((item) => item.name == 'Travel Edit'),
      isTrue,
    );

    final deleted = await store.deleteCategory(created);
    expect(deleted, isTrue);
    expect(repository.deletedCategoryIds.single, created.transactionCategoryID);
  });

  test('store applies merchant and category filters together', () async {
    final store = TransactionStore(FakeTransactionRepository());
    await store.start();

    final category = store.categories.firstWhere((item) => item.name == 'Q');
    store.setMerchantFilter('Rrr');
    store.setCategoryFilter(category);

    expect(store.merchantFilter, 'Rrr');
    expect(store.activeCategory?.name, 'Q');
    expect(store.visibleTransactions.length, 2);
    expect(
      store.visibleTransactions.every(
        (record) => record.displayMerchant == 'Rrr',
      ),
      isTrue,
    );
  });

  test(
    'store keeps fast filter color while category filter is active',
    () async {
      final store = TransactionStore(FakeTransactionRepository());
      await store.start();

      final category = store.categories.firstWhere((item) => item.name == 'Q');
      store.setMerchantFilter('Rrr', colorHex: category.slotColorHex);
      store.setCategoryFilter(category);

      expect(store.merchantFilter, 'Rrr');
      expect(store.merchantFilterColorHex, category.slotColorHex);
      expect(store.activeCategory?.name, 'Q');
    },
  );

  test('active summary is calculated from visible filtered records', () async {
    final store = TransactionStore(FakeTransactionRepository());
    await store.start();

    store.setMerchantFilter('Rrr');

    expect(store.visibleTransactions.length, 2);
    expect(
      store.activeSummary.formattedFor(TransactionType.expense),
      '-13 135 Ft',
    );
  });

  test('summary title includes interval and active filters', () async {
    final store = TransactionStore(
      FakeTransactionRepository(),
      clock: () => DateTime(2026, 3, 15),
    );
    await store.start();

    expect(store.activeSummaryTitle, contains('Sum'));
    store.cycleSummaryWindow();
    expect(store.activeSummaryTitle, contains('Március 2026'));
    store.cycleSummaryWindow();
    expect(store.activeSummaryTitle, contains('2026'));
  });

  test(
    'store bulk renames and resets by original merchant then reloads',
    () async {
      final repository = FakeTransactionRepository();
      final store = TransactionStore(repository);
      await store.start();

      final record = repository.transactions.firstWhere(
        (transaction) => transaction.merchant == 'Zzz',
      );
      await store.renameTransactionsByMerchant(record, 'Tesco Market');
      await store.resetTransactionNamesByMerchant(record);

      expect(repository.renameArgs, ['Zzz', 'Tesco Market']);
      expect(repository.resetMerchant, 'Zzz');
      expect(repository.loadCount, 3);
    },
  );

  test('reset summary returns to current monthly window', () async {
    final store = TransactionStore(
      FakeTransactionRepository(),
      clock: () => DateTime(2026, 5, 29),
    );
    await store.start();

    await store.cycleSummaryWindow();
    await store.cycleSummaryWindow();
    await store.shiftSummaryPeriod(-2);
    expect(store.summaryWindow, SummaryWindow.yearly);

    await store.resetSummaryToCurrentMonth();

    expect(store.summaryWindow, SummaryWindow.monthly);
    expect(store.activePeriodLabel, 'Május 2026');
  });

  test(
    'display log entries expose the full virtualized list for large datasets',
    () async {
      final repository = FakeTransactionRepository();
      for (var index = 0; index < 260; index += 1) {
        repository.transactions.add(
          TransactionRecord.fromMap({
            'id': 300000 + index,
            'date': '2026.05.${(index % 28 + 1).toString().padLeft(2, '0')}',
            'time': '${(index % 23).toString().padLeft(2, '0')}:10',
            'merchant': 'Future Shop $index',
            'amount': -1000 - index,
            'userAssignedName': null,
            'transactionCategoryID': 6,
          }),
        );
      }
      final store = TransactionStore(repository);
      await store.start();

      final initialEntries = store.visibleDisplayLogEntries;

      expect(store.visibleDisplayLogEntryTotalCount, greaterThan(260));
      expect(initialEntries.length, store.visibleDisplayLogEntryTotalCount);
      expect(store.hasMoreVisibleDisplayLogEntries, isFalse);

      store.loadMoreVisibleDisplayLogEntries();

      final nextEntries = store.visibleDisplayLogEntries;
      expect(identical(nextEntries, initialEntries), isTrue);
    },
  );

  test(
    'summary period can be shifted for monthly and yearly windows',
    () async {
      final store = TransactionStore(
        FakeTransactionRepository(),
        clock: () => DateTime(2026, 3, 15),
      );
      await store.start();

      store.cycleSummaryWindow();
      expect(store.summaryWindow, SummaryWindow.monthly);
      store.shiftSummaryPeriod(1);
      expect(store.activeSummaryTitle, contains('Április 2026'));
      store.shiftSummaryPeriod(-2);
      expect(store.activeSummaryTitle, contains('Február 2026'));

      store.cycleSummaryWindow();
      expect(store.summaryWindow, SummaryWindow.yearly);
      store.shiftSummaryPeriod(1);
      expect(store.activeSummaryTitle, contains('2027'));
    },
  );
}

class FakeTransactionRepository extends TransactionRepositoryContract {
  final savedPayloads = <Map<String, Object?>>[];
  final updatedPayloads = <Map<String, Object?>>[];
  final savedCategories = <Map<String, Object?>>[];
  final updatedCategories = <Map<String, Object?>>[];
  final deletedCategoryIds = <int>[];
  final deletedTransactionIds = <int>[];
  final renameArgs = <String>[];
  String? resetMerchant;
  var loadCount = 0;
  final limits = <CategoryLimit>[_savingGoal];
  final recurringGhostTransactions = <RecurringGhostRecord>[_rentGhost];
  final categories = <TransactionCategory>[
    TransactionCategory.fromMap({
      'transactionCategoryID': 5,
      'name': 'Rr',
      'type': 'bevétel',
      'colorSlot': 2,
      'iconSlot': 0,
      'backgroundColor': '#3b82f6',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
    TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Q',
      'type': 'kiadás',
      'colorSlot': 7,
      'iconSlot': 2,
      'backgroundColor': '#dc2626',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
  ];
  final transactions = <TransactionRecord>[
    TransactionRecord.fromMap({
      'id': 250909,
      'date': '2025.09.25',
      'time': '20:30:00',
      'merchant': 'Test Store',
      'amount': -505,
      'userAssignedName': null,
      'transactionCategoryID': 6,
    }),
    TransactionRecord.fromMap({
      'id': 250908,
      'date': '2025.09.25',
      'time': '5:29',
      'merchant': 'Zzz',
      'amount': -6580,
      'userAssignedName': 'Rrr',
      'transactionCategoryID': 6,
    }),
    TransactionRecord.fromMap({
      'id': 250907,
      'date': '2025.09.25',
      'time': '5:29',
      'merchant': 'Zzz',
      'amount': -6555,
      'userAssignedName': 'Rrr',
      'transactionCategoryID': 6,
    }),
    TransactionRecord.fromMap({
      'id': 250905,
      'date': '2025.09.24',
      'time': '21:56',
      'merchant': 'Rrteeaawwq',
      'amount': 5555,
      'userAssignedName': 'Gguu',
      'transactionCategoryID': 5,
    }),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    loadCount += 1;
    return TransactionBootstrap(
      categories: categories,
      transactions: transactions,
      limits: limits,
      recurringGhostTransactions: recurringGhostTransactions,
    );
  }

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    final rows = transactions.where((transaction) {
      final type = query.type;
      if (type != null && transaction.type != type) return false;
      if (query.categoryId != null &&
          transaction.transactionCategoryID != query.categoryId) {
        return false;
      }
      final merchant = query.merchant;
      if (merchant != null &&
          merchant.isNotEmpty &&
          transaction.displayMerchant != merchant) {
        return false;
      }
      final search = query.searchQuery.trim().toLowerCase();
      if (search.isNotEmpty &&
          !transaction.displayMerchant.toLowerCase().contains(search)) {
        return false;
      }
      final yearMonth = query.yearMonth;
      if (yearMonth != null &&
          yearMonth.isNotEmpty &&
          !transaction.date.replaceAll('.', '-').startsWith(yearMonth)) {
        return false;
      }
      return true;
    }).toList();
    return TransactionPage(
      transactions: rows.skip(query.offset).take(query.limit).toList(),
      totalCount: rows.length,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) async {
    savedCategories.add(payload);
    final category = TransactionCategory.fromMap({
      'transactionCategoryID': 14,
      'name': payload['name'],
      'type': 'kiadás',
      'colorSlot': payload['colorSlot'],
      'iconSlot': payload['iconSlot'],
      'backgroundColor': '#3b82f6',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    });
    categories.add(category);
    return category;
  }

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) async {
    updatedCategories.add({'id': id, ...payload});
    final index = categories.indexWhere(
      (category) => category.transactionCategoryID == id,
    );
    final category = TransactionCategory.fromMap({
      'transactionCategoryID': id,
      'name': payload['name'],
      'type': 'kiadás',
      'colorSlot': payload['colorSlot'],
      'iconSlot': payload['iconSlot'],
      'backgroundColor': '#6366f1',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    });
    categories[index] = category;
    return category;
  }

  @override
  Future<bool> deleteCategory(int id) async {
    deletedCategoryIds.add(id);
    categories.removeWhere((category) => category.transactionCategoryID == id);
    return true;
  }

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => recurringGhostTransactions;

  @override
  Future<Map<int, int>> categoryCounts() async => {5: 1, 6: 3};

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => const [];

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) async {
    savedPayloads.add(payload);
    final record = TransactionRecord.fromMap({
      'id': 250914,
      'date': '2025.09.26',
      'time': '10:00',
      'merchant': payload['merchant'],
      'amount': -42,
      'userAssignedName': null,
      'transactionCategoryID': 6,
    });
    transactions.insert(0, record);
    return record;
  }

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) async {
    updatedPayloads.add({'id': id, ...payload});
    final index = transactions.indexWhere(
      (transaction) => transaction.id == id,
    );
    final record = TransactionRecord.fromMap({
      'id': id,
      'date': '2025.09.27',
      'time': payload['time'],
      'merchant': payload['merchant'],
      'amount': -123,
      'userAssignedName': payload['userAssignedName'],
      'transactionCategoryID': payload['transactionCategoryID'],
    });
    transactions[index] = record;
    return record;
  }

  @override
  Future<bool> deleteTransaction(int id) async {
    deletedTransactionIds.add(id);
    transactions.removeWhere((transaction) => transaction.id == id);
    return true;
  }

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async {
    renameArgs
      ..add(originalMerchant)
      ..add(userAssignedName);
    var count = 0;
    for (var index = 0; index < transactions.length; index += 1) {
      final transaction = transactions[index];
      if (transaction.merchant != originalMerchant) continue;
      final map = transaction.toMap();
      map['userAssignedName'] = userAssignedName;
      transactions[index] = TransactionRecord.fromMap(map);
      count += 1;
    }
    return count;
  }

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async {
    resetMerchant = originalMerchant;
    var count = 0;
    for (var index = 0; index < transactions.length; index += 1) {
      final transaction = transactions[index];
      if (transaction.merchant != originalMerchant) continue;
      final map = transaction.toMap();
      map['userAssignedName'] = null;
      transactions[index] = TransactionRecord.fromMap(map);
      count += 1;
    }
    return count;
  }
}
