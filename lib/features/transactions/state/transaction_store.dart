import 'package:flutter/foundation.dart';

import '../../../core/debug/debug_console.dart';
import '../data/limit_manager.dart';
import '../data/transaction_filter.dart';
import '../data/transaction_repository.dart';
import '../models/backheader_budget_item.dart';
import '../models/budget_goal_kind.dart';
import '../models/category_budget_bar_data.dart';
import '../models/overview_budget_data.dart';
import '../models/category_limit.dart';
import '../models/recurring_ghost_record.dart';
import '../models/summary_window.dart';
import '../models/transaction_log_entry.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../models/transaction_summary.dart';

class TransactionStore extends ChangeNotifier {
  TransactionStore(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _periodReferenceDate = _monthStart(_clock());
  }

  final TransactionRepositoryContract _repository;
  final DateTime Function() _clock;
  var _filter = const TransactionFilter();
  var _summaryWindow = SummaryWindow.allTime;
  late DateTime _periodReferenceDate;
  var _loading = false;
  String? _error;
  List<TransactionCategory> _categories = [];
  List<TransactionRecord> _transactions = [];
  List<RecurringGhostRecord> _recurringGhostTransactions = [];
  List<CategoryLimit> _limits = [];

  bool get loading => _loading;
  String? get error => _error;
  TransactionType get activeType => _filter.type;
  SummaryWindow get summaryWindow => _summaryWindow;
  String get searchQuery => _filter.searchQuery;
  String? get merchantFilter => _filter.merchant;
  String? get merchantFilterColorHex => _filter.merchantColorHex;
  TransactionCategory? get activeCategory {
    final id = _filter.categoryId;
    if (id == null) return null;
    for (final category in _categories) {
      if (category.transactionCategoryID == id) return category;
    }
    return null;
  }

  Map<int, int> get categoryTransactionCounts {
    final counts = <int, int>{};
    for (final transaction in _transactions) {
      counts.update(
        transaction.transactionCategoryID,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);
  List<RecurringGhostRecord> get recurringGhostTransactions =>
      List.unmodifiable(_recurringGhostTransactions);
  List<CategoryLimit> get limits => List.unmodifiable(_limits);

  List<TransactionCategory> get activeCategories {
    return _categories
        .where((category) => category.normalizedType == _filter.type)
        .toList();
  }

  List<CategoryBudgetBarData> get categoryBudgetBars {
    return LimitManager.buildBars(
      categories: _categories,
      transactions: _transactions,
      limits: _limits,
      activeType: _filter.type,
      summaryWindow: _summaryWindow,
      referenceDate: _periodReferenceDate,
    );
  }

  List<OverviewBudgetData> get overviewBudgetItems {
    final window = LimitManager.windowForSummary(_summaryWindow);
    final periodKey = LimitManager.periodKeyFor(
      _summaryWindow,
      _periodReferenceDate,
    );
    final income = _periodTotal(TransactionType.income);
    final expense = _periodTotal(TransactionType.expense);
    final kinds = _filter.type == TransactionType.expense
        ? const [BudgetGoalKind.expenseBudget]
        : const [BudgetGoalKind.incomeGoal, BudgetGoalKind.savingGoal];

    return kinds.map((kind) {
      final sourceLimit = LimitManager.findLimit(
        limits: _limits,
        targetType: LimitTargetType.overview,
        targetId: 0,
        transactionType: kind.transactionType,
        window: window,
        periodKey: periodKey,
      );
      final amount = switch (kind) {
        BudgetGoalKind.expenseBudget => expense,
        BudgetGoalKind.incomeGoal => income,
        BudgetGoalKind.savingGoal => (income - expense)
            .clamp(0.0, double.infinity)
            .toDouble(),
      };
      final hasLimit = sourceLimit?.hasLimit ?? false;
      final limitAmount = hasLimit ? sourceLimit!.limitAmount : 0.0;
      return OverviewBudgetData(
        kind: kind,
        window: window,
        periodKey: periodKey,
        amount: amount,
        hasLimit: hasLimit,
        limitAmount: limitAmount,
        alertActive: sourceLimit?.alertActive ?? false,
        sourceLimit: sourceLimit,
      );
    }).toList();
  }

  List<BackheaderBudgetItem> get backheaderBudgetItems {
    return [
      for (final overview in overviewBudgetItems)
        BackheaderBudgetItem.overview(overview),
      for (final bar in categoryBudgetBars) BackheaderBudgetItem.category(bar),
    ];
  }

  double get activePeriodIncomeTotal => _periodTotal(TransactionType.income);

  double _periodTotal(TransactionType type) {
    return LimitManager.recordsForWindow(
      transactions: _transactions,
      activeType: type,
      summaryWindow: _summaryWindow,
      referenceDate: _periodReferenceDate,
    ).fold<double>(0, (sum, record) => sum + record.amount.abs());
  }

  List<TransactionRecord> get windowedTransactions {
    return LimitManager.recordsForWindow(
      transactions: _transactions,
      activeType: _filter.type,
      summaryWindow: _summaryWindow,
      referenceDate: _periodReferenceDate,
    ).toList();
  }

  List<TransactionRecord> get visibleTransactions {
    final query = _filter.searchQuery.trim().toLowerCase();
    final merchant = _filter.merchant?.trim();
    return windowedTransactions.where((record) {
      if (_filter.categoryId != null &&
          record.transactionCategoryID != _filter.categoryId) {
        return false;
      }
      if (merchant != null && record.displayMerchant != merchant) return false;
      if (query.isNotEmpty &&
          !record.displayMerchant.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<RecurringGhostRecord> get visibleGhostTransactions {
    final query = _filter.searchQuery.trim().toLowerCase();
    final merchant = _filter.merchant?.trim();
    return _recurringGhostTransactions.where((ghost) {
      if (ghost.isActivated) return false;
      if (_ghostIsBeforeCurrentMonth(ghost)) return false;
      if (ghost.type != _filter.type) return false;
      if (!_ghostInActiveWindow(ghost)) return false;
      if (_filter.categoryId != null &&
          ghost.categoryId != _filter.categoryId) {
        return false;
      }
      if (merchant != null && ghost.name != merchant) return false;
      if (query.isNotEmpty && !ghost.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<TransactionLogEntry> get visibleLogEntries {
    final entries = <TransactionLogEntry>[
      for (final record in visibleTransactions)
        TransactionLogEntry.record(record),
      for (final ghost in visibleGhostTransactions)
        TransactionLogEntry.ghost(ghost),
    ];
    entries.sort((left, right) {
      final date = right.date.compareTo(left.date);
      if (date != 0) return date;
      final time = right.time.compareTo(left.time);
      if (time != 0) return time;
      return right.sortId.compareTo(left.sortId);
    });
    return entries;
  }

  String get totalBalanceText =>
      TransactionSummary.fromRecords(_transactions).formattedBalance;

  TransactionSummary get activeSummary =>
      TransactionSummary.fromRecords(visibleTransactions);

  String get activePeriodLabel {
    final reference = _periodReferenceDate;
    return switch (_summaryWindow) {
      SummaryWindow.allTime => 'Sum',
      SummaryWindow.yearly => reference.year.toString(),
      SummaryWindow.monthly =>
        '${_hungarianMonth(reference.month)} ${reference.year}',
    };
  }

  String get activeSummaryTitle {
    final reference = _periodReferenceDate;
    final base = switch (_summaryWindow) {
      SummaryWindow.allTime => 'Sum',
      SummaryWindow.yearly => reference.year.toString(),
      SummaryWindow.monthly =>
        '${_hungarianMonth(reference.month)} ${reference.year}',
    };
    final parts = <String>[base];
    final merchant = _filter.merchant;
    if (merchant != null) parts.add(merchant);
    final category = activeCategory;
    if (category != null) parts.add(category.name);
    return parts.join(' · ');
  }

  Future<void> start() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = await _repository.loadBootstrap();
      _categories = payload.categories;
      _transactions = _sort(payload.transactions);
      _recurringGhostTransactions = _sortGhosts(
        payload.recurringGhostTransactions,
      );
      DebugConsole.log(
        '[Recurring] loaded ${_recurringGhostTransactions.length} pending ghosts',
      );
      _limits = payload.limits;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setActiveType(TransactionType type) {
    _filter = _filter.copyWith(
      type: type,
      clearMerchant: true,
      clearCategory: true,
      searchQuery: '',
    );
    notifyListeners();
  }

  void setCategoryFilter(TransactionCategory category) {
    _filter = _filter.copyWith(
      type: category.normalizedType,
      categoryId: category.transactionCategoryID,
      searchQuery: '',
    );
    notifyListeners();
  }

  void clearCategoryFilter() {
    _filter = _filter.copyWith(clearCategory: true);
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _filter = _filter.copyWith(searchQuery: value);
    notifyListeners();
  }

  void setMerchantFilter(String merchant, {String? colorHex}) {
    _filter = _filter.copyWith(
      merchant: merchant,
      merchantColorHex: colorHex,
      searchQuery: '',
    );
    notifyListeners();
  }

  void clearMerchantFilter() {
    _filter = _filter.copyWith(clearMerchant: true);
    notifyListeners();
  }

  Future<void> cycleSummaryWindow() async {
    _summaryWindow = switch (_summaryWindow) {
      SummaryWindow.monthly => SummaryWindow.yearly,
      SummaryWindow.yearly => SummaryWindow.allTime,
      SummaryWindow.allTime => SummaryWindow.monthly,
    };
    notifyListeners();
    await _projectRecurringGhostsForActiveWindow();
  }

  Future<void> shiftSummaryPeriod(int direction) async {
    if (direction == 0 || _summaryWindow == SummaryWindow.allTime) return;
    _periodReferenceDate = switch (_summaryWindow) {
      SummaryWindow.monthly => DateTime(
        _periodReferenceDate.year,
        _periodReferenceDate.month + direction,
      ),
      SummaryWindow.yearly => DateTime(_periodReferenceDate.year + direction),
      SummaryWindow.allTime => _periodReferenceDate,
    };
    notifyListeners();
    await _projectRecurringGhostsForActiveWindow();
  }

  Future<void> resetSummaryToCurrentMonth() async {
    _summaryWindow = SummaryWindow.monthly;
    _periodReferenceDate = _monthStart(_clock());
    notifyListeners();
    await _projectRecurringGhostsForActiveWindow();
  }

  Future<void> addTransaction({
    required String merchant,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required String date,
    required String time,
  }) async {
    await _repository.addTransaction({
      'merchant': merchant,
      'amount': amount,
      'type': type.nativeValue,
      'transactionCategoryID': categoryId,
      'date': date,
      'time': time,
    });
    await _reload();
  }

  Future<void> updateTransaction(
    TransactionRecord transaction, {
    required String merchant,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required String date,
    required String time,
    String? userAssignedName,
  }) async {
    await _repository.updateTransaction(transaction.id, {
      'merchant': merchant,
      'amount': amount,
      'type': type.nativeValue,
      'transactionCategoryID': categoryId,
      'date': date,
      'time': time,
      'userAssignedName': userAssignedName,
    });
    await _reload();
  }

  Future<bool> deleteTransaction(TransactionRecord transaction) async {
    final deleted = await _repository.deleteTransaction(transaction.id);
    if (deleted) {
      await _reload();
    }
    return deleted;
  }

  Future<void> refreshAfterRecurringProcessing() async {
    await _reload();
    DebugConsole.log('[RecurringAlarm] store refreshed after processing');
  }

  Future<int> renameTransactionsByMerchant(
    TransactionRecord transaction,
    String userAssignedName,
  ) async {
    DebugConsole.log(
      '[Transactions] rename ${transaction.merchant} -> $userAssignedName',
    );
    final count = await _repository.renameTransactionsByMerchant(
      transaction.merchant,
      userAssignedName,
    );
    await _reload();
    DebugConsole.log(
      '[Transactions] renamed $count rows for ${transaction.merchant}',
    );
    return count;
  }

  Future<int> resetTransactionNamesByMerchant(
    TransactionRecord transaction,
  ) async {
    DebugConsole.log('[Transactions] reset name ${transaction.merchant}');
    final count = await _repository.resetTransactionNamesByMerchant(
      transaction.merchant,
    );
    await _reload();
    DebugConsole.log(
      '[Transactions] reset $count rows for ${transaction.merchant}',
    );
    return count;
  }

  Future<void> addCategory({
    required String name,
    required TransactionType type,
    required int colorSlot,
    required int iconSlot,
  }) async {
    await _repository.addCategory({
      'name': name,
      'type': type.nativeValue,
      'colorSlot': colorSlot,
      'iconSlot': iconSlot,
    });
    await _reload();
  }

  Future<void> updateCategory(
    TransactionCategory category, {
    required String name,
    required int colorSlot,
    required int iconSlot,
  }) async {
    await _repository.updateCategory(category.transactionCategoryID, {
      'name': name,
      'type': category.normalizedType.nativeValue,
      'colorSlot': colorSlot,
      'iconSlot': iconSlot,
    });
    await _reload();
  }

  Future<bool> deleteCategory(TransactionCategory category) async {
    final deleted = await _repository.deleteCategory(
      category.transactionCategoryID,
    );
    if (deleted) {
      if (_filter.categoryId == category.transactionCategoryID) {
        _filter = _filter.copyWith(clearCategory: true);
      }
      await _reload();
    }
    return deleted;
  }

  Future<void> saveCategoryLimitForBar(
    CategoryBudgetBarData bar, {
    required double limitAmount,
    required bool alertActive,
  }) async {
    final amount = limitAmount < 0 ? 0.0 : limitAmount;
    final hasLimit = amount > 0;
    await _repository.upsertCategoryLimit({
      'targetType': bar.targetType.nativeValue,
      'targetId': bar.targetId,
      'transactionType': bar.transactionType.nativeValue,
      'window': bar.window.nativeValue,
      'periodKey': bar.periodKey,
      'hasLimit': hasLimit,
      'limitAmount': hasLimit ? amount : 0.0,
      'alertActive': hasLimit && alertActive,
    });
    await _reload();
  }

  Future<void> saveOverviewLimit(
    BudgetGoalKind kind, {
    required double limitAmount,
    required bool alertActive,
  }) async {
    final amount = limitAmount < 0 ? 0.0 : limitAmount;
    final hasLimit = amount > 0;
    await _repository.upsertCategoryLimit({
      'targetType': LimitTargetType.overview.nativeValue,
      'targetId': 0,
      'transactionType': kind.transactionType,
      'window': LimitManager.windowForSummary(_summaryWindow).nativeValue,
      'periodKey': LimitManager.periodKeyFor(
        _summaryWindow,
        _periodReferenceDate,
      ),
      'hasLimit': hasLimit,
      'limitAmount': hasLimit ? amount : 0.0,
      'alertActive': hasLimit && alertActive,
    });
    await _reload();
  }

  Future<void> _projectRecurringGhostsForActiveWindow() async {
    if (_summaryWindow == SummaryWindow.allTime) return;
    final targetDate = DateTime(
      _periodReferenceDate.year,
      _periodReferenceDate.month,
    );
    final periodKey =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}';
    DebugConsole.log('[Recurring] ensuring ghosts for $periodKey');
    final ghosts = await _repository.ensureRecurringGhostTransactions(
      targetDate: targetDate,
    );
    _recurringGhostTransactions = _sortGhosts(ghosts);
    DebugConsole.log(
      '[Recurring] projected ${visibleGhostTransactions.length} ghosts for $periodKey',
    );
    notifyListeners();
  }

  Future<void> _reload() async {
    final payload = await _repository.loadBootstrap();
    _categories = payload.categories;
    _transactions = _sort(payload.transactions);
    _recurringGhostTransactions = _sortGhosts(
      payload.recurringGhostTransactions,
    );
    _limits = payload.limits;
    notifyListeners();
  }

  bool _ghostIsBeforeCurrentMonth(RecurringGhostRecord ghost) {
    final ghostDate = DateTime.tryParse(ghost.normalizedDate);
    if (ghostDate == null) return false;
    return DateTime(ghostDate.year, ghostDate.month).isBefore(
      _monthStart(_clock()),
    );
  }

  bool _ghostInActiveWindow(RecurringGhostRecord ghost) {
    return switch (_summaryWindow) {
      SummaryWindow.allTime => false,
      SummaryWindow.monthly =>
        ghost.yearMonthKey ==
            '${_periodReferenceDate.year.toString().padLeft(4, '0')}-${_periodReferenceDate.month.toString().padLeft(2, '0')}',
      SummaryWindow.yearly => ghost.normalizedDate.startsWith(
        _periodReferenceDate.year.toString(),
      ),
    };
  }

  List<RecurringGhostRecord> _sortGhosts(List<RecurringGhostRecord> records) {
    final rows = [...records];
    rows.sort((left, right) {
      final date = right.date.compareTo(left.date);
      if (date != 0) return date;
      final time = right.time.compareTo(left.time);
      if (time != 0) return time;
      return right.id.compareTo(left.id);
    });
    return rows;
  }

  List<TransactionRecord> _sort(List<TransactionRecord> records) {
    final rows = [...records];
    rows.sort((left, right) => right.id.compareTo(left.id));
    return rows;
  }
}

DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);

String _hungarianMonth(int month) {
  const months = <int, String>{
    1: 'Január',
    2: 'Február',
    3: 'Március',
    4: 'Április',
    5: 'Május',
    6: 'Június',
    7: 'Július',
    8: 'Augusztus',
    9: 'Szeptember',
    10: 'Október',
    11: 'November',
    12: 'December',
  };
  return months[month] ?? month.toString();
}
