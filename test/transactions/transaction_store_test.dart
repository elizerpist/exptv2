import 'dart:async';

import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/slots/category_color_manager.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/state/balance_frame.dart';
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

const _octoberGhost = RecurringGhostRecord(
  id: 101,
  recurringTransactionId: 101,
  periodKey: '2025-10',
  name: 'October pending',
  amount: 2000,
  transactionType: 'expense',
  date: '2025.10.28',
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

const _novemberGhost = RecurringGhostRecord(
  id: 102,
  recurringTransactionId: 102,
  periodKey: '2025-11',
  name: 'November pending',
  amount: 3000,
  transactionType: 'expense',
  date: '2025.11.28',
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

  test(
    'active type switch defers large view resolution until consumers read it',
    () async {
      final store = TransactionStore(HighVolumeTransactionRepository());
      await store.start();
      var notifications = 0;
      store.addListener(() => notifications += 1);
      DebugConsole.clear();

      store.setActiveType(TransactionType.income);

      final logs = DebugConsole.allText;
      expect(logs, contains('[Perf] TypeSwitch request type=income'));
      expect(
        logs,
        isNot(contains('[Perf] Store active view reason=type-switch')),
      );
      expect(logs, contains('[Perf] TypeSwitch notify type=income'));
      expect(logs, contains('[Perf] TypeSwitch complete type=income'));
      expect(logs, contains('elapsed='));
      expect(notifications, 1);
      expect(store.activeType, TransactionType.income);
      expect(store.activeCategoryIds, isEmpty);
      expect(store.activeMerchantFilters, isEmpty);
      expect(store.visibleTransactions, hasLength(3000));
    },
  );

  test(
    'store can defer startup notify and prewarm during native sheet motion',
    () async {
      final repository = _PausedBootstrapRepository();
      final store = TransactionStore(repository);
      addTearDown(store.dispose);
      var notifications = 0;
      store.addListener(() {
        notifications += 1;
      });
      DebugConsole.clear();

      store.suspendUiUpdates();
      final startFuture = store.start();
      await Future<void>.delayed(Duration.zero);

      expect(repository.loadCount, 1);
      expect(notifications, 0);

      repository.release();
      await startFuture;

      expect(notifications, 0);
      expect(
        DebugConsole.allText,
        isNot(contains('[Perf] Store prewarm reason=start')),
      );

      store.resumeUiUpdates();

      expect(notifications, 1);
      expect(
        DebugConsole.allText,
        contains('[Perf] Store prewarm reason=start'),
      );
    },
  );

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
    'filter-derived caches use a bounded LRU and broad invalidation clears it',
    () async {
      final store = TransactionStore(FakeTransactionRepository());
      addTearDown(store.dispose);
      await store.start();

      List<Object> readFilterRevision(String query) {
        store.setSearchQuery(query);
        final revision = <Object>[
          store.visibleTransactions,
          store.visibleGhostTransactions,
          store.visibleLogEntries,
          store.visibleDisplayLogEntries,
          store.balanceVisibleDisplayLogEntries,
          store.activeSummary,
        ];
        store.balanceVisibleDisplayLogEntryTotalCount;
        store.visibleDisplayLogEntryTotalCount;
        return revision;
      }

      final first = readFilterRevision('lru-query-0');
      final second = readFilterRevision('lru-query-1');
      for (
        var index = 2;
        index < TransactionStore.maxFilterCacheEntries;
        index += 1
      ) {
        readFilterRevision('lru-query-$index');
      }

      expect(
        store.filterCacheEntryCount,
        TransactionStore.maxFilterCacheEntries,
      );

      final firstCacheHit = readFilterRevision('lru-query-0');
      for (var index = 0; index < first.length; index += 1) {
        expect(
          identical(firstCacheHit[index], first[index]),
          isTrue,
          reason: 'Reading the oldest revision must promote every cache hit.',
        );
      }

      readFilterRevision('lru-query-${TransactionStore.maxFilterCacheEntries}');
      expect(
        store.filterCacheEntryCount,
        TransactionStore.maxFilterCacheEntries,
      );

      final firstAfterEviction = readFilterRevision('lru-query-0');
      for (var index = 0; index < first.length; index += 1) {
        expect(identical(firstAfterEviction[index], first[index]), isTrue);
      }
      final secondAfterEviction = readFilterRevision('lru-query-1');
      for (var index = 0; index < second.length; index += 1) {
        expect(
          identical(secondAfterEviction[index], second[index]),
          isFalse,
          reason: 'The least-recently-used filter revision must be rebuilt.',
        );
      }

      store.startAddTransactionForm(
        categories: store.categories,
        type: TransactionType.expense,
      );
      expect(store.filterCacheEntryCount, 0);
    },
  );

  test(
    'store merges notification-linked transactions without full reload',
    () async {
      final repository = FakeTransactionRepository();
      final store = TransactionStore(repository);
      await store.start();
      final initialLoadCount = repository.loadCount;

      repository.notificationTransactions[101] = TransactionRecord.fromMap({
        'id': 250915,
        'date': '2025.09.26',
        'time': '11:30',
        'merchant': 'Background Push',
        'amount': -1990,
        'userAssignedName': null,
        'transactionCategoryID': 6,
        'sourceNotificationEventId': 101,
      });

      await store.mergeTransactionsForNotificationEvents([101]);

      expect(repository.loadCount, initialLoadCount);
      expect(
        store.visibleTransactions.any(
          (transaction) => transaction.merchant == 'Background Push',
        ),
        isTrue,
      );

      await store.mergeTransactionsForNotificationEvents([101]);

      expect(repository.loadCount, initialLoadCount);
      expect(
        store.visibleTransactions
            .where((transaction) => transaction.merchant == 'Background Push')
            .length,
        1,
      );
    },
  );

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

  test(
    'date boundary invalidates daily Balance metrics exactly once',
    () async {
      var now = DateTime(2025, 9, 25, 23, 59);
      final store = TransactionStore(
        FakeTransactionRepository(),
        clock: () => now,
      );
      await store.start();
      var notifications = 0;
      store.addListener(() => notifications += 1);
      final metrics = store.fastInfoMetrics;

      expect(store.refreshForDateBoundary(), isFalse);
      expect(notifications, 0);
      expect(identical(store.fastInfoMetrics, metrics), isTrue);

      now = DateTime(2025, 9, 26);
      expect(store.refreshForDateBoundary(), isTrue);
      expect(notifications, 1);
      expect(identical(store.fastInfoMetrics, metrics), isFalse);

      expect(store.refreshForDateBoundary(), isFalse);
      expect(notifications, 1);
    },
  );

  test(
    'month boundary follows the current month and projects its recurring ghosts',
    () async {
      var now = DateTime(2025, 9, 30, 23, 59);
      final repository = _MonthAwareGhostProjectionRepository();
      final store = TransactionStore(repository, clock: () => now);
      addTearDown(store.dispose);
      await store.start();
      await store.setSummaryMonth(2025, 9);
      repository.requestedMonths.clear();

      now = DateTime(2025, 10, 1);
      expect(store.refreshForDateBoundary(), isTrue);
      expect(store.summaryReferenceDate, DateTime(2025, 10));

      for (var attempt = 0; attempt < 10; attempt += 1) {
        if (repository.requestedMonths.isNotEmpty &&
            !store.recurringGhostProjectionInFlight) {
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }

      expect(repository.requestedMonths, [DateTime(2025, 10)]);
      expect(store.recurringGhostTransactions.map((ghost) => ghost.id), const [
        101,
      ]);
      expect(
        store.balanceRecurringGhostTransactions.map((ghost) => ghost.id),
        const [91, 101],
      );
    },
  );

  test(
    'month boundary refreshes Balance card ghosts while a yearly scope stays put',
    () async {
      var now = DateTime(2025, 9, 30, 23, 59);
      final repository = _MonthAwareGhostProjectionRepository();
      final store = TransactionStore(repository, clock: () => now);
      addTearDown(store.dispose);
      await store.start();
      await store.setSummaryYear(2025);
      repository.requestedMonths.clear();

      now = DateTime(2025, 10, 1);
      expect(store.refreshForDateBoundary(), isTrue);

      for (var attempt = 0; attempt < 10; attempt += 1) {
        if (repository.requestedMonths.isNotEmpty &&
            store.balanceRecurringGhostTransactions.any(
              (ghost) => ghost.id == _octoberGhost.id,
            )) {
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }

      expect(store.summaryWindow, SummaryWindow.yearly);
      expect(store.summaryReferenceDate, DateTime(2025));
      expect(repository.requestedMonths, [DateTime(2025, 10)]);
      expect(
        store.balanceRecurringGhostTransactions.map((ghost) => ghost.id),
        const [91, 101],
      );
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
    expect(
      repository.updatedPayloads.single['userAssignedName'],
      'Edited Alias',
    );
    expect(store.visibleTransactions.first.displayMerchant, 'Edited Alias');
  });

  test(
    'store keeps original merchant key when edit name becomes alias',
    () async {
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
      expect(
        repository.updatedPayloads.single['userAssignedName'],
        'Edited Shop',
      );
    },
  );

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
    store.setSearchQuery('rr');
    store.setMerchantFilter('Rrr');
    store.setCategoryFilter(category);

    expect(store.searchQuery, 'rr');
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
    'query category and merchant filters remain independent canonical state',
    () async {
      final store = TransactionStore(FakeTransactionRepository());
      await store.start();
      final category = store.categories.firstWhere((item) => item.name == 'Q');

      store.setSearchQuery('rr');
      store.setMerchantFilters({'Rrr', 'Test Store'});
      store.setCategoryFilters(
        type: TransactionType.expense,
        categoryIds: {category.transactionCategoryID},
      );

      expect(store.searchQuery, 'rr');
      expect(store.activeMerchantFilters, {'Rrr', 'Test Store'});
      expect(store.activeCategoryIds, {category.transactionCategoryID});
      expect(
        store.visibleTransactions.map((record) => record.displayMerchant),
        ['Rrr', 'Rrr'],
      );
    },
  );

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

  test(
    'store applies multiple vendor filters and clears them individually',
    () async {
      final store = TransactionStore(FakeTransactionRepository());
      await store.start();

      store.setMerchantFilters({'Rrr', 'Test Store'});

      expect(store.activeMerchantFilters, {'Rrr', 'Test Store'});
      expect(store.visibleTransactions.length, 3);
      expect(store.activeSummaryTitle, contains('2 vendor'));
      expect(
        store.vendorFilterSummaries.map((summary) => summary.name),
        containsAll(<String>['Rrr', 'Test Store']),
      );

      store.clearMerchantFilter('Rrr');

      expect(store.activeMerchantFilters, {'Test Store'});
      expect(store.visibleTransactions.single.displayMerchant, 'Test Store');
    },
  );

  test(
    'vendor summaries can be requested for a type outside home state',
    () async {
      final store = TransactionStore(FakeTransactionRepository());
      await store.start();

      expect(store.activeType, TransactionType.expense);
      expect(
        store
            .vendorFilterSummariesFor(TransactionType.income)
            .map((summary) => summary.name),
        contains('Gguu'),
      );
      expect(
        store
            .vendorFilterSummariesFor(TransactionType.income)
            .map((summary) => summary.name),
        isNot(contains('Rrr')),
      );
    },
  );

  test(
    'vendor summaries expose deterministic dominant category icon data',
    () async {
      final repository = FakeTransactionRepository();
      repository.categories.add(
        TransactionCategory.fromMap({
          'transactionCategoryID': 7,
          'name': 'Dominant',
          'type': 'kiadás',
          'colorSlot': 3,
          'iconSlot': 4,
          'backgroundColor': '#3b82f6',
          'hasLimit': false,
          'limitAmount': 0,
          'alertActive': false,
          'isCustomIcon': true,
        }),
      );
      repository.transactions.addAll([
        TransactionRecord.fromMap({
          'id': 901,
          'date': '2025.09.25',
          'time': '21:00',
          'merchant': 'Test Store',
          'amount': -999,
          'userAssignedName': null,
          'transactionCategoryID': 7,
        }),
        TransactionRecord.fromMap({
          'id': 902,
          'date': '2025.09.25',
          'time': '21:10',
          'merchant': 'No Category',
          'amount': -100,
          'userAssignedName': null,
          'transactionCategoryID': null,
        }),
      ]);
      final store = TransactionStore(repository);
      await store.start();

      final dominant = store.vendorFilterSummaries.firstWhere(
        (summary) => summary.name == 'Test Store',
      );
      expect(dominant.count, 2);
      expect(dominant.categoryIconSlot, 4);
      expect(dominant.colorHex, CategoryColorManager.hex(3));

      final fallback = store.vendorFilterSummaries.firstWhere(
        (summary) => summary.name == 'No Category',
      );
      expect(fallback.categoryIconSlot, isNull);
      expect(fallback.colorHex, isNull);
    },
  );

  test('vendor summaries and category counts follow summary window', () async {
    final repository = FakeTransactionRepository();
    repository.categories.add(
      TransactionCategory.fromMap({
        'transactionCategoryID': 7,
        'name': 'Scoped',
        'type': 'kiadás',
        'colorSlot': 3,
        'iconSlot': 4,
        'backgroundColor': '#84cc16',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      }),
    );
    repository.transactions.addAll([
      TransactionRecord.fromMap({
        'id': 903,
        'date': '2024.02.10',
        'time': '08:00',
        'merchant': 'Old Shop',
        'amount': -10,
        'userAssignedName': null,
        'transactionCategoryID': 7,
      }),
      TransactionRecord.fromMap({
        'id': 904,
        'date': '2025.02.10',
        'time': '08:00',
        'merchant': 'Year Shop',
        'amount': -20,
        'userAssignedName': null,
        'transactionCategoryID': 7,
      }),
      TransactionRecord.fromMap({
        'id': 905,
        'date': '2025.10.10',
        'time': '08:00',
        'merchant': 'Other Month',
        'amount': -30,
        'userAssignedName': null,
        'transactionCategoryID': 7,
      }),
      TransactionRecord.fromMap({
        'id': 906,
        'date': '2026.01.10',
        'time': '08:00',
        'merchant': 'Future Shop',
        'amount': -40,
        'userAssignedName': null,
        'transactionCategoryID': 7,
      }),
    ]);
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2025, 9, 25, 12),
    );
    await store.start();

    Set<String> vendorNames() =>
        store.vendorFilterSummaries.map((summary) => summary.name).toSet();

    expect(
      vendorNames(),
      containsAll([
        'Test Store',
        'Rrr',
        'Old Shop',
        'Year Shop',
        'Other Month',
        'Future Shop',
      ]),
    );
    expect(store.categoryTransactionCounts[6], 3);
    expect(store.categoryTransactionCounts[7], 4);

    await store.setSummaryYear(2025);

    expect(
      vendorNames(),
      containsAll(['Test Store', 'Rrr', 'Year Shop', 'Other Month']),
    );
    expect(vendorNames(), isNot(contains('Old Shop')));
    expect(vendorNames(), isNot(contains('Future Shop')));
    expect(store.categoryTransactionCounts[6], 3);
    expect(store.categoryTransactionCounts[7], 2);

    await store.setSummaryMonth(2025, 9);

    expect(vendorNames(), containsAll(['Test Store', 'Rrr']));
    expect(vendorNames(), isNot(contains('Year Shop')));
    expect(vendorNames(), isNot(contains('Other Month')));
    expect(store.categoryTransactionCounts[6], 3);
    expect(store.categoryTransactionCounts[7] ?? 0, 0);
  });

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
    'legacy Budget and Mind log remains complete while Balance owns paging',
    () async {
      final repository = FakeTransactionRepository();
      for (var index = 0; index < 550; index += 1) {
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

      final legacyEntries = store.visibleDisplayLogEntries;
      final initialEntries = store.balanceVisibleDisplayLogEntries;

      expect(
        legacyEntries.where((entry) => !entry.isHeader),
        hasLength(store.visibleTransactions.length),
        reason: 'Budget/Mind consume the legacy getter without a load-more UI.',
      );
      expect(legacyEntries, hasLength(store.visibleDisplayLogEntryTotalCount));
      expect(store.hasMoreVisibleDisplayLogEntries, isFalse);
      expect(store.balanceVisibleDisplayLogEntryTotalCount, greaterThan(550));
      expect(
        initialEntries.length,
        lessThan(store.balanceVisibleDisplayLogEntryTotalCount),
      );
      expect(initialEntries.last.isHeader, isFalse);
      expect(store.hasMoreBalanceVisibleDisplayLogEntries, isTrue);
      expect(
        initialEntries.where((entry) => !entry.isHeader).length,
        TransactionStore.visibleDisplayLogPageSize,
      );

      store.loadMoreBalanceVisibleDisplayLogEntries();

      final nextEntries = store.balanceVisibleDisplayLogEntries;
      expect(nextEntries.length, greaterThan(initialEntries.length));
      expect(nextEntries.last.isHeader, isFalse);

      store.setSearchQuery('Future Shop');

      expect(
        store.balanceVisibleDisplayLogEntries
            .where((entry) => !entry.isHeader)
            .length,
        TransactionStore.visibleDisplayLogPageSize,
        reason: 'A filter change must reset only the Balance page window.',
      );
      expect(
        store.visibleDisplayLogEntries.where((entry) => !entry.isHeader),
        hasLength(550),
        reason: 'The full legacy view stays complete after filtering too.',
      );
    },
  );

  test(
    'Balance paging stays bounded for a 10k single-day group and invalidates',
    () async {
      final repository = FakeTransactionRepository();
      repository.transactions
        ..clear()
        ..addAll(
          List<TransactionRecord>.generate(10020, (index) {
            return TransactionRecord.fromMap({
              'id': 400000 + index,
              'date': '2026.05.20',
              'time': '${(index % 23).toString().padLeft(2, '0')}:10',
              'merchant': 'Single Day $index',
              'amount': -1000 - index,
              'userAssignedName': null,
              'transactionCategoryID': 6,
            });
          }),
        );
      final store = TransactionStore(repository);
      await store.start();

      expect(store.balanceVisibleDisplayLogEntries, hasLength(97));
      expect(store.balanceVisibleDisplayLogEntries.first.isHeader, isTrue);
      expect(store.balanceVisibleDisplayLogEntries.last.isHeader, isFalse);
      expect(store.hasMoreBalanceVisibleDisplayLogEntries, isTrue);
      expect(
        store.visibleDisplayLogEntries.where((entry) => !entry.isHeader),
        hasLength(10020),
        reason: 'Legacy completeness is asserted after Balance paging.',
      );

      store.loadMoreBalanceVisibleDisplayLogEntries();
      expect(store.balanceVisibleDisplayLogEntries, hasLength(193));

      store.mergeExternalTransactions([
        TransactionRecord.fromMap({
          'id': 999999,
          'date': '2026.05.21',
          'time': '23:59',
          'merchant': 'Newest mutation',
          'amount': -42,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
      ]);

      final resetRows = store.balanceVisibleDisplayLogEntries;
      expect(
        resetRows.where((entry) => !entry.isHeader),
        hasLength(TransactionStore.visibleDisplayLogPageSize),
      );
      expect(resetRows[1].record?.id, 999999);
      expect(
        store.balanceVisibleDisplayLogEntryTotalCount,
        10023,
        reason: '10 021 records plus two date headers are canonical.',
      );
    },
  );

  test('fromStore nearest fallback metadata can be committed once', () async {
    final store = TransactionStore(
      FakeTransactionRepository(),
      clock: () => DateTime(2026, 7, 25),
    );
    await store.start();
    await store.setSummaryYear(2024);

    final staleFrame = BalanceFrameResolver.resolve(
      BalanceFrameInput.fromStore(store),
    );

    expect(staleFrame.query.effectiveReferenceDate, DateTime(2025));
    expect(staleFrame.query.hasPendingScopeFallback, isTrue);
    expect(staleFrame.visibleLogRowCount, 3);
    expect(staleFrame.totalLogEntryCount, 4);
    expect(staleFrame.hasMoreLogEntries, isFalse);

    expect(
      await BalanceScopeCommitAdapter.commitIfNeeded(store, staleFrame.query),
      isTrue,
    );
    expect(store.summaryWindow, SummaryWindow.yearly);
    expect(store.summaryReferenceDate, DateTime(2025));

    final committedFrame = BalanceFrameResolver.resolve(
      BalanceFrameInput.fromStore(store),
    );
    expect(committedFrame.query.hasPendingScopeFallback, isFalse);
    expect(
      await BalanceScopeCommitAdapter.commitIfNeeded(
        store,
        committedFrame.query,
      ),
      isFalse,
      reason: 'The adapter is idempotent and cannot create a build loop.',
    );
  });

  test(
    'fromStore keeps card ghost inputs independent of summary window',
    () async {
      final store = TransactionStore(
        FakeTransactionRepository(),
        clock: () => DateTime(2025, 9, 25),
      );
      addTearDown(store.dispose);
      await store.start();

      expect(
        BalanceFrameInput.fromStore(store).recurringGhosts.map((row) => row.id),
        [91],
      );
      await store.setSummaryYear(2025);
      expect(store.summaryWindow, SummaryWindow.yearly);
      expect(
        BalanceFrameInput.fromStore(store).recurringGhosts.map((row) => row.id),
        [91],
      );
      await store.setSummaryAllTime();
      expect(store.summaryWindow, SummaryWindow.allTime);
      expect(
        BalanceFrameInput.fromStore(store).recurringGhosts.map((row) => row.id),
        [91],
      );
    },
  );

  test('fromStore snapshots identify an unchanged store revision', () async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2025, 9, 25),
    );
    addTearDown(store.dispose);
    await store.start();

    final first = BalanceFrameInput.fromStore(store);
    final sameRevision = BalanceFrameInput.fromStore(store);
    expect(first.sameRevisionAs(sameRevision), isTrue);

    store.setSearchQuery('rent');
    final changedRevision = BalanceFrameInput.fromStore(store);
    expect(first.sameRevisionAs(changedRevision), isFalse);
  });

  test(
    'monthly summary mutations publish immediately with the stable ghost snapshot',
    () async {
      final repository = _QueuedGhostProjectionRepository();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2025, 9, 25),
      );
      addTearDown(store.dispose);
      await store.start();

      final observations = <(SummaryWindow, DateTime, List<int>)>[];
      void observe() {
        observations.add((
          store.summaryWindow,
          store.summaryReferenceDate,
          store.recurringGhostTransactions.map((ghost) => ghost.id).toList(),
        ));
      }

      store.addListener(observe);
      addTearDown(() => store.removeListener(observe));

      Future<void> expectImmediatePublication({
        required Future<void> Function() mutate,
        required DateTime expectedReference,
        required List<int> expectedStableGhostIds,
        required int requestIndex,
        required List<RecurringGhostRecord> projectedGhosts,
      }) async {
        observations.clear();

        final pending = mutate();

        expect(
          observations,
          hasLength(1),
          reason: 'The new summary scope must publish before async projection.',
        );
        expect(observations.single.$1, SummaryWindow.monthly);
        expect(observations.single.$2, expectedReference);
        expect(observations.single.$3, expectedStableGhostIds);

        await _waitForGhostProjectionRequest(repository, requestIndex + 1);
        expect(repository.requestedMonths[requestIndex], expectedReference);
        repository.release(requestIndex, projectedGhosts);
        await pending;
      }

      await expectImmediatePublication(
        mutate: store.cycleSummaryWindow,
        expectedReference: DateTime(2025, 9),
        expectedStableGhostIds: const [91],
        requestIndex: 0,
        projectedGhosts: const [_rentGhost],
      );
      await expectImmediatePublication(
        mutate: () => store.shiftSummaryPeriod(1),
        expectedReference: DateTime(2025, 10),
        expectedStableGhostIds: const [91],
        requestIndex: 1,
        projectedGhosts: const [_octoberGhost],
      );
      await expectImmediatePublication(
        mutate: store.resetSummaryToCurrentMonth,
        expectedReference: DateTime(2025, 9),
        expectedStableGhostIds: const [101],
        requestIndex: 2,
        projectedGhosts: const [_rentGhost],
      );
      await expectImmediatePublication(
        mutate: () => store.setSummaryMonth(2025, 10),
        expectedReference: DateTime(2025, 10),
        expectedStableGhostIds: const [91],
        requestIndex: 3,
        projectedGhosts: const [_octoberGhost],
      );
    },
  );

  test('latest monthly ghost projection generation wins races', () async {
    final repository = _QueuedGhostProjectionRepository();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2025, 9, 25),
    );
    addTearDown(store.dispose);
    await store.start();

    final observations = <(DateTime, List<int>)>[];
    void observe() {
      observations.add((
        store.summaryReferenceDate,
        store.recurringGhostTransactions.map((ghost) => ghost.id).toList(),
      ));
    }

    store.addListener(observe);
    addTearDown(() => store.removeListener(observe));

    final octoberChange = store.setSummaryMonth(2025, 10);
    expect(observations.single.$1, DateTime(2025, 10));
    expect(observations.single.$2, const [91]);
    await _waitForGhostProjectionRequest(repository, 1);

    final novemberChange = store.setSummaryMonth(2025, 11);
    expect(observations.last.$1, DateTime(2025, 11));
    expect(observations.last.$2, const [91]);
    await _waitForGhostProjectionRequest(repository, 2);

    repository.release(1, const [_novemberGhost]);
    await novemberChange;
    expect(store.summaryReferenceDate, DateTime(2025, 11));
    expect(store.recurringGhostTransactions.map((ghost) => ghost.id), const [
      102,
    ]);

    final notificationCountAfterLatest = observations.length;
    repository.release(0, const [_octoberGhost]);
    await octoberChange;

    expect(store.summaryReferenceDate, DateTime(2025, 11));
    expect(store.recurringGhostTransactions.map((ghost) => ghost.id), const [
      102,
    ]);
    expect(
      observations,
      hasLength(notificationCountAfterLatest),
      reason: 'A stale generation must neither replace state nor republish it.',
    );
  });

  test(
    'Balance keeps its card ghost pool while lower rail projection changes',
    () async {
      final repository = _QueuedGhostProjectionRepository();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2025, 9, 25),
      );
      addTearDown(store.dispose);
      await store.start();

      expect(
        store.balanceRecurringGhostTransactions.map((ghost) => ghost.id),
        const [91],
      );

      final octoberChange = store.setSummaryMonth(2025, 10);
      final inFlight = BalanceFrameResolver.resolve(
        BalanceFrameInput.fromStore(store),
      );
      expect(inFlight.query.effectiveReferenceDate, DateTime(2025, 10));
      expect(inFlight.query.hasPendingScopeFallback, isFalse);

      await _waitForGhostProjectionRequest(repository, 1);
      repository.release(0, const [_octoberGhost]);
      await octoberChange;

      expect(store.recurringGhostTransactions.map((ghost) => ghost.id), const [
        101,
      ]);
      expect(
        store.balanceRecurringGhostTransactions.map((ghost) => ghost.id),
        const [91, 101],
      );
    },
  );

  test(
    'fromStore never labels an in-flight prior-month ghost as current',
    () async {
      final repository = _PausedGhostProjectionRepository();
      repository.transactions.add(
        TransactionRecord.fromMap({
          'id': 260001,
          'date': '2025.10.05',
          'time': '12:00',
          'merchant': 'October real',
          'amount': -4200,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
      );
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2025, 9, 25),
      );
      addTearDown(store.dispose);
      await store.start();

      final pendingChange = store.setSummaryMonth(2025, 10);
      await Future<void>.delayed(Duration.zero);
      expect(repository.requestedMonth, DateTime(2025, 10));

      final inFlight = BalanceFrameResolver.resolve(
        BalanceFrameInput.fromStore(store),
      );
      expect(inFlight.query.effectiveReferenceDate, DateTime(2025, 10));
      expect(inFlight.query.hasPendingScopeFallback, isFalse);
      expect(inFlight.visibleLogRowCount, 1);
      expect(inFlight.totalLogEntryCount, 2);
      expect(
        inFlight.logGroups
            .expand((group) => group.rows)
            .where((row) => row.isGhost),
        isEmpty,
        reason: 'September stable ghosts cannot be labeled as October rows.',
      );

      repository.release(const <RecurringGhostRecord>[_octoberGhost]);
      await pendingChange;

      final settled = BalanceFrameResolver.resolve(
        BalanceFrameInput.fromStore(store),
      );
      expect(settled.visibleLogRowCount, 2);
      expect(settled.totalLogEntryCount, 4);
      expect(
        settled.logGroups
            .expand((group) => group.rows)
            .where((row) => row.isGhost)
            .single
            .ghost
            ?.id,
        101,
      );
    },
  );

  test(
    'pending ghosts share real day groups and generated ghosts are deduped',
    () async {
      final repository = FakeTransactionRepository();
      repository.transactions.add(
        TransactionRecord.fromMap({
          'id': 250990,
          'date': '2025.09.28',
          'time': '08:00',
          'merchant': 'Rent',
          'amount': -100000,
          'userAssignedName': null,
          'transactionCategoryID': 6,
          'recurringTransactionId': 91,
        }),
      );
      repository.recurringGhostTransactions.add(
        const RecurringGhostRecord(
          id: 92,
          recurringTransactionId: 92,
          periodKey: '2025-09',
          name: 'Rrr',
          amount: 3200,
          transactionType: 'expense',
          date: '2025.09.25',
          time: '18:00',
          categoryId: 6,
          categoryName: 'Q',
          categoryColor: '#dc2626',
          categoryIconSlot: 2,
          triggerMillis: 0,
          isActivated: false,
          activatedTransactionId: null,
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2025, 9, 25, 12),
      );
      await store.start();
      await store.resetSummaryToCurrentMonth();

      expect(
        store.visibleLogEntries.where(
          (entry) => entry.ghost?.recurringTransactionId == 91,
        ),
        isEmpty,
        reason: 'A generated real transaction replaces its pending ghost.',
      );
      expect(
        store.visibleLogEntries.where(
          (entry) => entry.ghost?.recurringTransactionId == 92,
        ),
        hasLength(1),
      );
      expect(
        store.visibleDisplayLogEntries
            .where((entry) => entry.isHeader && entry.date == '2025.09.25')
            .length,
        1,
        reason: 'Real and pending rows on one date use one shared day group.',
      );
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
  final notificationTransactions = <int, TransactionRecord>{};
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
  Future<List<TransactionRecord>> transactionsForNotificationEvents(
    Iterable<int> eventIds,
  ) async {
    return [
      for (final id in eventIds)
        if (notificationTransactions[id] != null) notificationTransactions[id]!,
    ];
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

class HighVolumeTransactionRepository extends FakeTransactionRepository {
  HighVolumeTransactionRepository() {
    transactions
      ..clear()
      ..addAll(
        List<TransactionRecord>.generate(6000, (index) {
          final income = index.isEven;
          final day = (index % 28) + 1;
          return TransactionRecord.fromMap({
            'id': 100000 + index,
            'date': '2025.09.${day.toString().padLeft(2, '0')}',
            'time': '10:00',
            'merchant': 'Merchant ${index % 40}',
            'amount': income ? 1000 + index : -(1000 + index),
            'userAssignedName': null,
            'transactionCategoryID': income ? 5 : 6,
          });
        }),
      );
  }
}

class _PausedBootstrapRepository extends FakeTransactionRepository {
  final _releaseCompleter = Completer<void>();

  void release() {
    if (!_releaseCompleter.isCompleted) {
      _releaseCompleter.complete();
    }
  }

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    loadCount += 1;
    await _releaseCompleter.future;
    return TransactionBootstrap(
      categories: categories,
      transactions: transactions,
      limits: limits,
      recurringGhostTransactions: recurringGhostTransactions,
    );
  }
}

class _PausedGhostProjectionRepository extends FakeTransactionRepository {
  final _projection = Completer<List<RecurringGhostRecord>>();
  DateTime? requestedMonth;

  void release(List<RecurringGhostRecord> ghosts) {
    if (!_projection.isCompleted) _projection.complete(ghosts);
  }

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) {
    requestedMonth = targetDate;
    return _projection.future;
  }
}

class _QueuedGhostProjectionRepository extends FakeTransactionRepository {
  final requestedMonths = <DateTime>[];
  final _projections = <Completer<List<RecurringGhostRecord>>>[];

  void release(int index, List<RecurringGhostRecord> ghosts) {
    _projections[index].complete(ghosts);
  }

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) {
    requestedMonths.add(targetDate!);
    final projection = Completer<List<RecurringGhostRecord>>();
    _projections.add(projection);
    return projection.future;
  }
}

class _MonthAwareGhostProjectionRepository extends FakeTransactionRepository {
  final requestedMonths = <DateTime>[];

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async {
    requestedMonths.add(targetDate!);
    return targetDate.year == 2025 && targetDate.month == 10
        ? const [_octoberGhost]
        : const [_rentGhost];
  }
}

Future<void> _waitForGhostProjectionRequest(
  _QueuedGhostProjectionRepository repository,
  int count,
) async {
  for (var attempt = 0; attempt < 10; attempt += 1) {
    if (repository.requestedMonths.length >= count) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Expected $count recurring ghost projection request(s), '
    'got ${repository.requestedMonths.length}.',
  );
}
