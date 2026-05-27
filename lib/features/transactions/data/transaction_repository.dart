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
}
