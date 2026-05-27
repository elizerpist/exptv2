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
}

class FakeTransactionRepository implements TransactionRepositoryContract {
  final savedPayloads = <Map<String, Object?>>[];
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
