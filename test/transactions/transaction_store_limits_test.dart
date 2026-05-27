import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'store saves category limit for the active summary window period',
    () async {
      final repository = FakeLimitRepository();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );
      await store.start();

      store.cycleSummaryWindow();
      expect(store.summaryWindow, SummaryWindow.monthly);

      await store.saveCategoryLimitForBar(
        store.categoryBudgetBars.single,
        limitAmount: 75000,
        alertActive: true,
      );

      expect(repository.savedLimits.single['targetType'], 'category');
      expect(repository.savedLimits.single['targetId'], 6);
      expect(repository.savedLimits.single['transactionType'], 'expense');
      expect(repository.savedLimits.single['window'], 'monthly');
      expect(repository.savedLimits.single['periodKey'], '2026-05');
      expect(repository.savedLimits.single['limitAmount'], 75000);
      expect(store.categoryBudgetBars.single.limitAmount, 75000);
    },
  );
}

class FakeLimitRepository implements TransactionRepositoryContract {
  final savedLimits = <Map<String, Object?>>[];
  var limits = <CategoryLimit>[];

  final categories = <TransactionCategory>[
    TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Food',
      'type': 'kiadás',
      'colorSlot': 7,
      'iconSlot': 2,
      'backgroundColor': '#0ea5e9',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
  ];

  final transactions = <TransactionRecord>[
    TransactionRecord.fromMap({
      'id': 1,
      'date': '2026.05.04',
      'time': '12:00',
      'merchant': 'Shop',
      'amount': -100,
      'userAssignedName': null,
      'transactionCategoryID': 6,
    }),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: categories,
    transactions: transactions,
    limits: limits,
  );

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    savedLimits.add(payload);
    final limit = CategoryLimit.fromMap({
      'id': 1,
      ...payload,
      'hasLimit': true,
      'createdAt': 0,
      'updatedAt': 1,
    });
    limits = [limit];
    return limit;
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => limits;

  @override
  Future<TransactionRecord> addTransaction(
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();


  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTransaction(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) async =>
      throw UnimplementedError();

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

  @override
  Future<bool> deleteCategory(int id) async => throw UnimplementedError();

  @override
  Future<Map<int, int>> categoryCounts() async => const {6: 1};
}
