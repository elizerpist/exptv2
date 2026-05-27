import '../../../services/native_bridge.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class TransactionBootstrap {
  const TransactionBootstrap({
    required this.categories,
    required this.transactions,
  });

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
}

abstract class TransactionRepositoryContract {
  Future<TransactionBootstrap> loadBootstrap();
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload);
  Future<TransactionCategory> addCategory(Map<String, Object?> payload);
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  );
  Future<bool> deleteCategory(int id);
  Future<Map<int, int>> categoryCounts();
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
    );
  }

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) {
    return _bridge.expenseAddTransaction(payload);
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
}
