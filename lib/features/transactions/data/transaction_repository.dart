import '../../../services/native_bridge.dart';
import '../models/category_limit.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class TransactionBootstrap {
  const TransactionBootstrap({
    required this.categories,
    required this.transactions,
    required this.limits,
    this.recurringGhostTransactions = const [],
  });

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
  final List<CategoryLimit> limits;
  final List<RecurringGhostRecord> recurringGhostTransactions;
}

abstract class TransactionRepositoryContract {
  Future<TransactionBootstrap> loadBootstrap();
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload);
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  );
  Future<bool> deleteTransaction(int id);
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  );
  Future<int> resetTransactionNamesByMerchant(String originalMerchant);
  Future<TransactionCategory> addCategory(Map<String, Object?> payload);
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  );
  Future<bool> deleteCategory(int id);
  Future<Map<int, int>> categoryCounts();
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  });
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload);
}

class TransactionRepository implements TransactionRepositoryContract {
  const TransactionRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    final payload = await _bridge.expenseLoadBootstrap();
    return TransactionBootstrap(
      categories: payload.categories,
      transactions: payload.transactions,
      limits: payload.limits,
      recurringGhostTransactions: payload.recurringGhostTransactions,
    );
  }

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) {
    return _bridge.expenseAddTransaction(payload);
  }

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) {
    return _bridge.expenseUpdateTransaction(id, payload);
  }

  @override
  Future<bool> deleteTransaction(int id) {
    return _bridge.expenseDeleteTransaction(id);
  }

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) {
    return _bridge.expenseRenameTransactionsByMerchant(
      originalMerchant,
      userAssignedName,
    );
  }

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) {
    return _bridge.expenseResetTransactionNamesByMerchant(originalMerchant);
  }

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) {
    return _bridge.expenseAddCategory(payload);
  }

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) {
    return _bridge.expenseUpdateCategory(id, payload);
  }

  @override
  Future<bool> deleteCategory(int id) {
    return _bridge.expenseDeleteCategory(id);
  }

  @override
  Future<Map<int, int>> categoryCounts() {
    return _bridge.expenseCategoryCounts();
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) {
    return _bridge.expenseListCategoryLimits(
      transactionType: transactionType,
      window: window,
      periodKey: periodKey,
    );
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) {
    return _bridge.expenseUpsertCategoryLimit(payload);
  }
}
