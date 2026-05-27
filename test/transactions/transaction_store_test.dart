import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

class FakeTransactionRepository implements TransactionRepositoryContract {
  final savedPayloads = <Map<String, Object?>>[];
  final savedCategories = <Map<String, Object?>>[];
  final updatedCategories = <Map<String, Object?>>[];
  final deletedCategoryIds = <int>[];
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
  Future<TransactionBootstrap> loadBootstrap() async =>
      TransactionBootstrap(categories: categories, transactions: transactions);

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
  Future<Map<int, int>> categoryCounts() async => {5: 1, 6: 3};

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
}
