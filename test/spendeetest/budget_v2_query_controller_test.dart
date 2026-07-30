import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_log_projection.dart';
import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_query_controller.dart';
import 'package:exptv2/features/transactions/widgets/experimental/budget_v2/budget_v2_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'BudgetV2 projection uses exact selected-vendor index and active scope',
    () async {
      final store = TransactionStore(
        _QueryRepository(
          transactions: <TransactionRecord>[
            _record(301, '2025.09.02', 'ACME Shop', -100, 6),
            _record(302, '2025.09.03', 'ACME-Shop', -200, 6),
            _record(303, '2025.09.04', 'ACME-Shop', -300, 5),
          ],
        ),
        clock: () => DateTime(2025, 9, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();
      await store.setSummaryMonth(2025, 9);
      final prepared = BudgetV2StoreSnapshotCache().resolve(
        BudgetV2SnapshotSource.fromStore(store),
      );
      final foodKey = store.categoryBudgetBars
          .firstWhere((bar) => bar.targetId == 6)
          .key;
      final cache = BudgetV2LogProjectionCache();

      final projection = cache.resolve(
        snapshot: prepared,
        query: BudgetV2LogQuery(
          avatarKey: foodKey,
          selectedVendorKey: 'ACME-Shop',
          scope: const BudgetV2ExternalQueryScope(
            searchQuery: 'acme',
            categoryIds: <int>{6},
            merchantKeys: <String>{'ACME-Shop'},
          ),
        ),
      );

      expect(
        projection.entries
            .where((entry) => !entry.isHeader)
            .map((entry) => entry.record?.id),
        <int>[302],
      );
      expect(projection.visibleRowCount, 1);
      expect(projection.totalRowCount, 1);
      expect(projection.hasMore, isFalse);
      expect(
        () => projection.entries.add(projection.entries.last),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'BudgetV2 projection preserves ghosts and cumulative page ordering',
    () async {
      final realRecords = List<TransactionRecord>.generate(98, (index) {
        final day = 24 - (index ~/ 8);
        return _record(
          1000 + index,
          '2025.09.${day.toString().padLeft(2, '0')}',
          'Paged Vendor',
          -100 - index.toDouble(),
          6,
          time: '${(23 - index % 8).toString().padLeft(2, '0')}:30',
        );
      });
      final store = TransactionStore(
        _QueryRepository(
          transactions: realRecords,
          projectedGhosts: <RecurringGhostRecord>[
            _ghost(
              id: 900,
              date: '2025.09.25',
              time: '23:59',
              name: 'Paged Vendor',
              categoryId: 6,
            ),
          ],
        ),
        clock: () => DateTime(2025, 9, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();
      await store.cycleSummaryWindow();
      final prepared = BudgetV2StoreSnapshotCache().resolve(
        BudgetV2SnapshotSource.fromStore(store),
      );
      final foodKey = store.categoryBudgetBars
          .firstWhere((bar) => bar.targetId == 6)
          .key;
      final cache = BudgetV2LogProjectionCache();
      const scope = BudgetV2ExternalQueryScope(
        searchQuery: '',
        categoryIds: <int>{6},
        merchantKeys: <String>{'Paged Vendor'},
      );

      final firstPage = cache.resolve(
        snapshot: prepared,
        query: BudgetV2LogQuery(
          avatarKey: foodKey,
          scope: scope,
          rowLimit: TransactionStore.visibleDisplayLogPageSize,
        ),
      );
      final nextPage = cache.resolve(
        snapshot: prepared,
        query: BudgetV2LogQuery(
          avatarKey: foodKey,
          scope: scope,
          rowLimit: TransactionStore.visibleDisplayLogPageSize * 2,
        ),
      );

      expect(firstPage.visibleRowCount, 96);
      expect(firstPage.totalRowCount, 99);
      expect(firstPage.hasMore, isTrue);
      expect(firstPage.entries.first.isHeader, isTrue);
      expect(firstPage.entries[1].ghost?.id, 900);
      expect(firstPage.entries.last.isHeader, isFalse);
      expect(nextPage.visibleRowCount, 99);
      expect(nextPage.totalRowCount, 99);
      expect(nextPage.hasMore, isFalse);
      expect(nextPage.entries.first.isHeader, isTrue);
      expect(nextPage.entries[1].ghost?.id, 900);
      expect(nextPage.entries.last.isHeader, isFalse);
      expect(
        nextPage.entries
            .where((entry) => entry.isHeader)
            .map((entry) => entry.header)
            .toSet()
            .length,
        nextPage.entries.where((entry) => entry.isHeader).length,
      );
    },
  );

  test(
    'BudgetV2 projection cache keys immutable results by revision and query',
    () async {
      final store = TransactionStore(
        _QueryRepository(
          transactions: <TransactionRecord>[
            _record(1, '2025.09.02', 'ACME-Shop', -100, 6),
          ],
        ),
        clock: () => DateTime(2025, 9, 25, 12),
      );
      addTearDown(store.dispose);
      await store.start();
      await store.setSummaryMonth(2025, 9);
      final prepared = BudgetV2StoreSnapshotCache().resolve(
        BudgetV2SnapshotSource.fromStore(store),
      );
      final foodKey = store.categoryBudgetBars
          .firstWhere((bar) => bar.targetId == 6)
          .key;
      final query = BudgetV2LogQuery(
        avatarKey: foodKey,
        scope: const BudgetV2ExternalQueryScope(
          searchQuery: '',
          categoryIds: <int>{6},
          merchantKeys: <String>{},
        ),
      );
      final cache = BudgetV2LogProjectionCache();

      final first = cache.resolve(snapshot: prepared, query: query);
      final same = cache.resolve(snapshot: prepared, query: query);

      expect(identical(first, same), isTrue);
    },
  );

  test(
    'BudgetV2 query reconciliation adopts an external category and clears a removed vendor',
    () {
      final controller = BudgetV2QueryController(
        unfilteredAvatarKey: 'overview',
        avatarKeyByCategoryId: const <int, String>{5: 'travel', 6: 'food'},
      );
      const foodScope = BudgetV2ExternalQueryScope(
        searchQuery: '',
        categoryIds: <int>{6},
        merchantKeys: <String>{'ACME-Shop'},
      );

      final adopted = controller.reconcileExternalScope(foodScope);
      expect(adopted.avatarKeyToAdopt, 'food');
      expect(controller.externalAvatarKey, 'food');

      controller.selectVendor('ACME-Shop');
      controller.acknowledgeVendor(<String>{'ACME-Shop'});
      final acknowledged = controller.reconcileExternalScope(foodScope);
      expect(acknowledged.clearSelectedVendor, isFalse);
      expect(controller.selectedVendorKey, 'ACME-Shop');

      final removed = controller.reconcileExternalScope(
        foodScope.copyWith(merchantKeys: const <String>{}),
      );
      expect(removed.clearSelectedVendor, isTrue);
      expect(controller.selectedVendorKey, isNull);
    },
  );

  test('BudgetV2 query search reconciliation never requests a store write', () {
    final controller = BudgetV2QueryController(
      unfilteredAvatarKey: 'overview',
      avatarKeyByCategoryId: const <int, String>{6: 'food'},
    );
    controller.reconcileExternalScope(
      const BudgetV2ExternalQueryScope(
        searchQuery: '',
        categoryIds: <int>{6},
        merchantKeys: <String>{},
      ),
    );

    final result = controller.reconcileExternalScope(
      const BudgetV2ExternalQueryScope(
        searchQuery: 'lidl',
        categoryIds: <int>{6},
        merchantKeys: <String>{},
      ),
    );

    expect(result.avatarKeyToAdopt, isNull);
    expect(result.clearSelectedVendor, isFalse);
    expect(result.requiresStoreWrite, isFalse);
    expect(controller.externalScope.searchQuery, 'lidl');
  });

  test('BudgetV2 query preserves an acknowledged avatar callback', () {
    final controller = BudgetV2QueryController(
      unfilteredAvatarKey: 'overview',
      avatarKeyByCategoryId: const <int, String>{5: 'travel', 6: 'food'},
    );
    controller.reconcileExternalScope(
      const BudgetV2ExternalQueryScope(
        searchQuery: '',
        categoryIds: <int>{5},
        merchantKeys: <String>{},
      ),
    );

    controller.acknowledgeAvatar(
      avatarKey: 'food',
      categoryIds: const <int>{6},
    );
    final localCallback = controller.reconcileExternalScope(
      const BudgetV2ExternalQueryScope(
        searchQuery: '',
        categoryIds: <int>{6},
        merchantKeys: <String>{},
      ),
    );

    expect(localCallback.avatarKeyToAdopt, isNull);
    expect(controller.externalAvatarKey, 'food');

    final externalChip = controller.reconcileExternalScope(
      const BudgetV2ExternalQueryScope(
        searchQuery: '',
        categoryIds: <int>{5},
        merchantKeys: <String>{},
      ),
    );
    expect(externalChip.avatarKeyToAdopt, 'travel');
    expect(controller.externalAvatarKey, 'travel');
  });

  test(
    'BudgetV2 query clears a stale avatar for an unrelated multi-chip scope',
    () {
      final controller = BudgetV2QueryController(
        unfilteredAvatarKey: 'overview',
        avatarKeyByCategoryId: const <int, String>{5: 'travel', 6: 'food'},
      );
      controller.reconcileExternalScope(
        const BudgetV2ExternalQueryScope(
          searchQuery: '',
          categoryIds: <int>{6},
          merchantKeys: <String>{},
        ),
      );

      final result = controller.reconcileExternalScope(
        const BudgetV2ExternalQueryScope(
          searchQuery: '',
          categoryIds: <int>{5, 6},
          merchantKeys: <String>{},
        ),
      );

      expect(result.clearExternalAvatar, isTrue);
      expect(controller.externalAvatarKey, isNull);
    },
  );

  test('BudgetV2 query clears a vendor when an external category changes', () {
    final controller = BudgetV2QueryController(
      unfilteredAvatarKey: 'overview',
      avatarKeyByCategoryId: const <int, String>{5: 'travel', 6: 'food'},
    );
    const foodScope = BudgetV2ExternalQueryScope(
      searchQuery: '',
      categoryIds: <int>{6},
      merchantKeys: <String>{'ACME-Shop'},
    );
    controller.reconcileExternalScope(foodScope);
    controller.selectVendor('ACME-Shop');
    controller.acknowledgeVendor(foodScope.merchantKeys);
    controller.reconcileExternalScope(foodScope);

    final result = controller.reconcileExternalScope(
      foodScope.copyWith(categoryIds: const <int>{5}),
    );

    expect(result.avatarKeyToAdopt, 'travel');
    expect(result.clearSelectedVendor, isTrue);
    expect(controller.selectedVendorKey, isNull);
  });
}

class _QueryRepository extends TransactionRepositoryContract {
  _QueryRepository({
    required this.transactions,
    this.projectedGhosts = const <RecurringGhostRecord>[],
  });

  final List<TransactionRecord> transactions;
  final List<RecurringGhostRecord> projectedGhosts;

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: <TransactionCategory>[
      _category(5, 'Travel'),
      _category(6, 'Food'),
    ],
    transactions: transactions,
    limits: const <CategoryLimit>[],
  );

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => projectedGhosts;

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
}

TransactionCategory _category(int id, String name) =>
    TransactionCategory.fromMap(<String, Object?>{
      'transactionCategoryID': id,
      'name': name,
      'type': 'expense',
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
  int categoryId, {
  String time = '12:00',
}) => TransactionRecord.fromMap(<String, Object?>{
  'id': id,
  'date': date,
  'time': time,
  'merchant': merchant,
  'amount': amount,
  'transactionCategoryID': categoryId,
});

RecurringGhostRecord _ghost({
  required int id,
  required String date,
  required String time,
  required String name,
  required int categoryId,
}) => RecurringGhostRecord(
  id: id,
  recurringTransactionId: id + 10000,
  periodKey: '2025-09',
  name: name,
  amount: 250,
  transactionType: 'expense',
  date: date,
  time: time,
  categoryId: categoryId,
  categoryName: 'Food',
  categoryColor: '#000000',
  categoryIconSlot: 1,
  triggerMillis: 0,
  isActivated: false,
  activatedTransactionId: null,
  createdAt: 0,
  updatedAt: 0,
);
