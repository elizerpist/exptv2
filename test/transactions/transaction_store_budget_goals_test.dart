import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/backheader_budget_item.dart';
import 'package:exptv2/features/transactions/models/budget_goal_kind.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'expense backheader starts with budget then expense categories',
    () async {
      final store = TransactionStore(
        FakeBudgetGoalRepository(),
        clock: () => DateTime(2026, 5, 17),
      );
      await store.start();
      await store.cycleSummaryWindow();

      expect(store.summaryWindow, SummaryWindow.monthly);
      expect(
        store.backheaderBudgetItems.first.kind,
        BackheaderBudgetItemKind.overview,
      );
      expect(
        store.backheaderBudgetItems.first.overview?.kind,
        BudgetGoalKind.expenseBudget,
      );
      expect(store.backheaderBudgetItems[1].category?.title, 'Food');
    },
  );

  test('income backheader starts with income goal and saving goal', () async {
    final store = TransactionStore(
      FakeBudgetGoalRepository(),
      clock: () => DateTime(2026, 5, 17),
    );
    await store.start();
    await store.cycleSummaryWindow();
    store.setActiveType(TransactionType.income);

    expect(
      store.backheaderBudgetItems[0].overview?.kind,
      BudgetGoalKind.incomeGoal,
    );
    expect(
      store.backheaderBudgetItems[1].overview?.kind,
      BudgetGoalKind.savingGoal,
    );
    expect(store.backheaderBudgetItems[2].category?.title, 'Salary');
  });

  test('saving overview target saves as overview target id zero', () async {
    final repository = FakeBudgetGoalRepository();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await store.start();
    await store.cycleSummaryWindow();

    await store.saveOverviewLimit(
      BudgetGoalKind.savingGoal,
      limitAmount: 100000,
      alertActive: false,
    );

    expect(repository.savedLimits.single['targetType'], 'overview');
    expect(repository.savedLimits.single['targetId'], 0);
    expect(repository.savedLimits.single['transactionType'], 'saving');
    expect(repository.savedLimits.single['window'], 'monthly');
    expect(repository.savedLimits.single['periodKey'], '2026-05');
  });
}

class FakeBudgetGoalRepository extends TransactionRepositoryContract {
  final savedLimits = <Map<String, Object?>>[];
  var limits = <CategoryLimit>[];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: [
      categoryFixture(5, 'Salary', TransactionType.income),
      categoryFixture(6, 'Food', TransactionType.expense),
    ],
    transactions: [
      transactionFixture(1, '2026.05.01', 500000, 5),
      transactionFixture(2, '2026.05.02', -120000, 6),
    ],
    limits: limits,
  );

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    return TransactionPage(
      transactions: const [],
      totalCount: 0,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    savedLimits.add(payload);
    final limit = CategoryLimit.fromMap({
      'id': savedLimits.length,
      ...payload,
      'createdAt': 0,
      'updatedAt': savedLimits.length,
    });
    limits = [
      for (final row in limits)
        if (row.targetType != limit.targetType ||
            row.targetId != limit.targetId ||
            row.transactionType != limit.transactionType ||
            row.window != limit.window ||
            row.periodKey != limit.periodKey)
          row,
      limit,
    ];
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
  ) async => throw UnimplementedError();

  @override
  Future<bool> deleteTransaction(int id) async => throw UnimplementedError();

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async => throw UnimplementedError();

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async =>
      throw UnimplementedError();

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => const [];

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
  Future<Map<int, int>> categoryCounts() async => const {5: 1, 6: 1};
}

TransactionCategory categoryFixture(int id, String name, TransactionType type) {
  return TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': name,
    'type': type.hungarianValue,
    'colorSlot': type == TransactionType.income ? 2 : 7,
    'iconSlot': 2,
    'backgroundColor': type == TransactionType.income ? '#3b82f6' : '#0ea5e9',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  });
}

TransactionRecord transactionFixture(
  int id,
  String date,
  double amount,
  int categoryId,
) {
  return TransactionRecord.fromMap({
    'id': id,
    'date': date,
    'time': '12:00',
    'merchant': 'Merchant',
    'amount': amount,
    'userAssignedName': null,
    'transactionCategoryID': categoryId,
  });
}
