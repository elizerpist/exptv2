import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'store source reuses its prepared revision and indexes avatar aggregates',
    () async {
      final store = TransactionStore(
        _SnapshotRepository(),
        clock: () => DateTime(2025, 9, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();
      await store.cycleSummaryWindow();

      final firstSource = BudgetV2SnapshotSource.fromStore(store);
      final sameSourceRevision = BudgetV2SnapshotSource.fromStore(store);
      final cache = BudgetV2StoreSnapshotCache();
      final first = cache.resolve(firstSource);
      final same = cache.resolve(sameSourceRevision);

      expect(firstSource.revision, sameSourceRevision.revision);
      expect(identical(first, same), isTrue);

      final foodBar = store.categoryBudgetBars.firstWhere(
        (bar) => bar.targetId == 6,
      );
      final food = first.avatarData(foodBar.key);
      expect(food.records.map((record) => record.id), <int>[3, 1, 0]);
      expect(food.weeklyAmounts, <double>[0, 0, 0, 0, 0, 0, 500]);
      expect(food.vendors, hasLength(1));
      expect(food.vendors.single.name, 'Lidl');
      expect(food.vendors.single.amount, 4500);
      expect(food.recordsForVendor('Lidl').map((record) => record.id), <int>[
        3,
        1,
        0,
      ]);
      expect(food.recordsForVendor('missing'), isEmpty);
      expect(
        () => food.records.add(food.records.first),
        throwsUnsupportedError,
      );

      final overview = first.avatarData(store.overviewBudgetItems.single.key);
      expect(overview.records, hasLength(4));
      expect(overview.vendors.map((vendor) => vendor.name), <String>[
        'Lidl',
        'BKK',
      ]);
      expect(overview.vendors.map((vendor) => vendor.amount), <double>[
        4500,
        2000,
      ]);
    },
  );

  test(
    'active store source changes revision when its cached inputs change',
    () async {
      final store = TransactionStore(
        _SnapshotRepository(),
        clock: () => DateTime(2025, 9, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();
      final cache = BudgetV2StoreSnapshotCache();

      final expense = cache.resolve(BudgetV2SnapshotSource.fromStore(store));
      store.setActiveType(TransactionType.income);
      final income = cache.resolve(BudgetV2SnapshotSource.fromStore(store));

      expect(identical(expense, income), isFalse);
    },
  );

  test(
    'store source revision canonicalizes scope and freezes period ghosts',
    () async {
      final ghost = RecurringGhostRecord(
        id: 801,
        recurringTransactionId: 1801,
        periodKey: '2025-09',
        name: 'ACME-Shop',
        amount: 400,
        transactionType: 'expense',
        date: '2025.09.26',
        time: '08:00',
        categoryId: 6,
        categoryName: 'Food',
        categoryColor: '#000000',
        categoryIconSlot: 1,
        triggerMillis: 0,
        isActivated: false,
        activatedTransactionId: null,
        createdAt: 0,
        updatedAt: 0,
      );
      final store = TransactionStore(
        _SnapshotRepository(projectedGhosts: <RecurringGhostRecord>[ghost]),
        clock: () => DateTime(2025, 9, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();
      await store.setSummaryMonth(2025, 9);
      store.setSearchQuery('  AcMe ');
      store.setCategoryFilters(
        type: TransactionType.expense,
        categoryIds: <int>{6, 5},
      );
      store.setMerchantFilters(<String>{'ACME-Shop', 'ACME Shop'});

      final first = BudgetV2SnapshotSource.fromStore(store);
      store.setSearchQuery('acme');
      store.setCategoryFilters(
        type: TransactionType.expense,
        categoryIds: <int>{5, 6},
      );
      store.setMerchantFilters(<String>{'ACME Shop', 'ACME-Shop'});
      final canonicalEquivalent = BudgetV2SnapshotSource.fromStore(store);

      expect(first.revision, canonicalEquivalent.revision);
      expect(first.periodGhosts, <RecurringGhostRecord>[ghost]);
      expect(() => first.periodGhosts.add(ghost), throwsUnsupportedError);

      store.setMerchantFilters(<String>{'acme-shop', 'ACME Shop'});
      final exactVendorChange = BudgetV2SnapshotSource.fromStore(store);
      expect(exactVendorChange.revision, isNot(first.revision));
    },
  );

  test(
    'historical store source anchors weekly values to its reference date',
    () async {
      final store = TransactionStore(
        _SnapshotRepository(),
        clock: () => DateTime(2025, 9, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();
      await store.setSummaryMonth(2025, 8);

      final snapshot = BudgetV2StoreSnapshotCache().resolve(
        BudgetV2SnapshotSource.fromStore(store),
      );
      final foodBar = store.categoryBudgetBars.firstWhere(
        (bar) => bar.targetId == 6,
      );

      expect(snapshot.avatarData(foodBar.key).weeklyAmounts, <double>[
        0,
        0,
        0,
        0,
        0,
        0,
        700,
      ]);
    },
  );

  test('generic snapshot cache evicts old prepared revisions', () {
    var preparations = 0;
    final cache = BudgetV2SnapshotCache<int, int>(
      maximumCachedRevisions: 2,
      revisionOf: (source) => source,
      prepare: (source) {
        preparations += 1;
        return source;
      },
      avatarDataOf: (prepared, avatarKey) => prepared,
    );

    cache.resolve(1);
    cache.resolve(2);
    cache.resolve(3);
    cache.resolve(2);
    cache.resolve(1);

    expect(preparations, 4);
  });

  test(
    'seven-day buckets include the first civil day across DST fallback',
    () async {
      final store = TransactionStore(
        _SnapshotRepository(
          additionalTransactions: <TransactionRecord>[
            _record(201, '2021.10.26', 'First day', -110, 6),
            _record(202, '2021.11.01', 'Last day', -220, 6),
          ],
        ),
        clock: () => DateTime(2025, 9, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();
      await store.setSummaryMonth(2021, 11);
      await store.setSummaryAllTime();

      final snapshot = BudgetV2StoreSnapshotCache().resolve(
        BudgetV2SnapshotSource.fromStore(store),
      );
      final foodBar = store.categoryBudgetBars.firstWhere(
        (bar) => bar.targetId == 6,
      );

      expect(snapshot.avatarData(foodBar.key).weeklyAmounts, <double>[
        110,
        0,
        0,
        0,
        0,
        0,
        220,
      ]);
    },
  );

  test('exact vendor identities cannot collide in prepared indexes', () async {
    final store = TransactionStore(
      _SnapshotRepository(
        additionalTransactions: <TransactionRecord>[
          _record(301, '2025.09.02', 'ACME Shop', -100, 6),
          _record(302, '2025.09.03', 'ACME-Shop', -200, 6),
        ],
      ),
      clock: () => DateTime(2025, 9, 25, 12),
    );
    addTearDown(store.dispose);
    await store.start();
    await store.setSummaryMonth(2025, 9);

    final snapshot = BudgetV2StoreSnapshotCache().resolve(
      BudgetV2SnapshotSource.fromStore(store),
    );
    final foodBar = store.categoryBudgetBars.firstWhere(
      (bar) => bar.targetId == 6,
    );
    final food = snapshot.avatarData(foodBar.key);
    final acmeVendors = food.vendors
        .where((vendor) => vendor.name.startsWith('ACME'))
        .toList();

    expect(acmeVendors.map((vendor) => vendor.key).toSet(), <String>{
      'ACME Shop',
      'ACME-Shop',
    });
    expect(food.recordsForVendor('ACME Shop').map((record) => record.id), <int>[
      301,
    ]);
    expect(food.recordsForVendor('ACME-Shop').map((record) => record.id), <int>[
      302,
    ]);
  });

  test('public avatar snapshot freezes caller-owned collections', () {
    final records = <TransactionRecord>[
      _record(401, '2025.09.01', 'Lidl', -100, 6),
    ];
    final vendors = <BudgetV2VendorAggregate>[
      const BudgetV2VendorAggregate(
        key: 'Lidl',
        name: 'Lidl',
        amount: 100,
        count: 1,
        leadingCategoryId: 6,
      ),
    ];
    final weekly = <double>[100, 0, 0, 0, 0, 0, 0];
    final recordsByVendor = <String, List<TransactionRecord>>{'Lidl': records};
    final snapshot = BudgetV2AvatarSnapshot(
      avatarKey: 'food',
      records: records,
      vendors: vendors,
      weeklyAmounts: weekly,
      recordsByVendorKey: recordsByVendor,
    );

    records.add(_record(402, '2025.09.02', 'Lidl', -200, 6));
    vendors.clear();
    weekly[0] = 999;
    recordsByVendor.clear();

    expect(snapshot.records, hasLength(1));
    expect(snapshot.vendors, hasLength(1));
    expect(snapshot.weeklyAmounts.first, 100);
    expect(snapshot.recordsForVendor('Lidl'), hasLength(1));
    expect(
      () => snapshot.records.add(snapshot.records.first),
      throwsUnsupportedError,
    );
  });
}

class _SnapshotRepository extends TransactionRepositoryContract {
  _SnapshotRepository({
    this.additionalTransactions = const <TransactionRecord>[],
    this.projectedGhosts = const <RecurringGhostRecord>[],
  });

  final List<TransactionRecord> additionalTransactions;
  final List<RecurringGhostRecord> projectedGhosts;

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: <TransactionCategory>[
      _category(5, 'Travel', TransactionType.expense),
      _category(6, 'Food', TransactionType.expense),
      _category(7, 'Salary', TransactionType.income),
    ],
    transactions: <TransactionRecord>[
      _record(0, '2025.09.01', 'Lidl', -500, 6),
      _record(1, '2025.09.19', 'Lidl', -1000, 6),
      _record(2, '2025.09.22', 'BKK', -2000, 5),
      _record(3, '2025.09.25', 'Lidl', -3000, 6),
      _record(4, '2025.09.25', 'Employer', 500000, 7),
      _record(5, '2025.08.01', 'Lidl', -700, 6),
      ...additionalTransactions,
    ],
    limits: const <CategoryLimit>[],
  );

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async => TransactionPage(
    transactions: const <TransactionRecord>[],
    totalCount: 0,
    limit: query.limit,
    offset: query.offset,
  );

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) =>
      throw UnimplementedError();

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) => throw UnimplementedError();

  @override
  Future<bool> deleteTransaction(int id) => throw UnimplementedError();

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) => throw UnimplementedError();

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) =>
      throw UnimplementedError();

  @override
  Future<Map<int, int>> categoryCounts() => throw UnimplementedError();

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) =>
      throw UnimplementedError();

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) => throw UnimplementedError();

  @override
  Future<bool> deleteCategory(int id) => throw UnimplementedError();

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => const <CategoryLimit>[];

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) =>
      throw UnimplementedError();

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => projectedGhosts;
}

TransactionCategory _category(int id, String name, TransactionType type) =>
    TransactionCategory.fromMap(<String, Object?>{
      'transactionCategoryID': id,
      'name': name,
      'type': type.nativeValue,
      'colorSlot': id,
      'iconSlot': id,
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    });

TransactionRecord _record(
  int id,
  String date,
  String merchant,
  double amount,
  int categoryId,
) => TransactionRecord.fromMap(<String, Object?>{
  'id': id,
  'date': date,
  'time': '12:00',
  'merchant': merchant,
  'amount': amount,
  'transactionCategoryID': categoryId,
});
