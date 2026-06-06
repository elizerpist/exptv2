import '../../../services/native_bridge.dart';
import '../models/category_limit.dart';
import '../models/recurring_ghost_record.dart';
import '../models/recurring_rule.dart';
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

class TransactionPageQuery {
  const TransactionPageQuery({
    this.type,
    this.categoryId,
    this.merchant,
    this.searchQuery = '',
    this.yearMonth,
    this.limit = 96,
    this.offset = 0,
  });

  final TransactionType? type;
  final int? categoryId;
  final String? merchant;
  final String searchQuery;
  final String? yearMonth;
  final int limit;
  final int offset;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type?.nativeValue,
      'categoryId': categoryId,
      'merchant': merchant,
      'searchQuery': searchQuery,
      'yearMonth': yearMonth,
      'limit': limit,
      'offset': offset,
    };
  }
}

class TransactionPage {
  const TransactionPage({
    required this.transactions,
    required this.totalCount,
    required this.limit,
    required this.offset,
  });

  final List<TransactionRecord> transactions;
  final int totalCount;
  final int limit;
  final int offset;
}

abstract class TransactionRepositoryContract {
  Future<TransactionBootstrap> loadBootstrap();
  Future<TransactionPage> listTransactionPage(TransactionPageQuery query);
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
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  });
  Future<List<RecurringRule>> listRecurringRules() async {
    return const <RecurringRule>[];
  }

  Future<RecurringRule> addRecurringRule(RecurringRuleDraft draft) {
    throw UnimplementedError('addRecurringRule');
  }

  Future<RecurringRule> updateRecurringRule(
    int id,
    RecurringRuleDraft draft,
  ) {
    throw UnimplementedError('updateRecurringRule');
  }

  Future<RecurringRule> toggleRecurringRule(
    int id,
    bool isActive,
  ) {
    throw UnimplementedError('toggleRecurringRule');
  }

  Future<bool> deleteRecurringRule(int id) async => false;
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
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    final payload = await _bridge.expenseListTransactionPage(query.toMap());
    return TransactionPage(
      transactions: payload.transactions,
      totalCount: payload.totalCount,
      limit: payload.limit,
      offset: payload.offset,
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
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) {
    return _bridge.expenseEnsureRecurringGhostTransactions(
      targetDate: targetDate,
    );
  }

  @override
  Future<List<RecurringRule>> listRecurringRules() {
    return _bridge.expenseListRecurringRules();
  }

  @override
  Future<RecurringRule> addRecurringRule(RecurringRuleDraft draft) {
    return _bridge.expenseAddRecurringRule(draft);
  }

  @override
  Future<RecurringRule> updateRecurringRule(
    int id,
    RecurringRuleDraft draft,
  ) {
    return _bridge.expenseUpdateRecurringRule(id, draft);
  }

  @override
  Future<RecurringRule> toggleRecurringRule(
    int id,
    bool isActive,
  ) {
    return _bridge.expenseToggleRecurringRule(id, isActive);
  }

  @override
  Future<bool> deleteRecurringRule(int id) {
    return _bridge.expenseDeleteRecurringRule(id);
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
