import 'package:flutter/foundation.dart';

import '../data/limit_manager.dart';
import '../data/transaction_filter.dart';
import '../data/transaction_repository.dart';
import '../models/category_budget_bar_data.dart';
import '../models/category_limit.dart';
import '../models/summary_window.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../models/transaction_summary.dart';

class TransactionStore extends ChangeNotifier {
  TransactionStore(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TransactionRepositoryContract _repository;
  final DateTime Function() _clock;
  var _filter = const TransactionFilter();
  var _summaryWindow = SummaryWindow.allTime;
  var _loading = false;
  String? _error;
  List<TransactionCategory> _categories = [];
  List<TransactionRecord> _transactions = [];
  List<CategoryLimit> _limits = [];

  bool get loading => _loading;
  String? get error => _error;
  TransactionType get activeType => _filter.type;
  SummaryWindow get summaryWindow => _summaryWindow;
  String get searchQuery => _filter.searchQuery;
  String? get merchantFilter => _filter.merchant;
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
      referenceDate: _clock(),
    );
  }

  List<TransactionRecord> get visibleTransactions {
    final query = _filter.searchQuery.trim().toLowerCase();
    final merchant = _filter.merchant?.trim();
    return _transactions.where((record) {
      if (record.type != _filter.type) return false;
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

  String get totalBalanceText =>
      TransactionSummary.fromRecords(_transactions).formattedBalance;

  TransactionSummary get activeSummary {
    final source = LimitManager.recordsForWindow(
      transactions: _transactions,
      activeType: _filter.type,
      summaryWindow: _summaryWindow,
      referenceDate: _clock(),
    );
    return TransactionSummary.fromRecords(source);
  }

  Future<void> start() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = await _repository.loadBootstrap();
      _categories = payload.categories;
      _transactions = _sort(payload.transactions);
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
      clearMerchant: true,
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

  void setMerchantFilter(String merchant) {
    _filter = _filter.copyWith(merchant: merchant, searchQuery: '');
    notifyListeners();
  }

  void clearMerchantFilter() {
    _filter = _filter.copyWith(clearMerchant: true);
    notifyListeners();
  }

  void cycleSummaryWindow() {
    _summaryWindow = switch (_summaryWindow) {
      SummaryWindow.monthly => SummaryWindow.yearly,
      SummaryWindow.yearly => SummaryWindow.allTime,
      SummaryWindow.allTime => SummaryWindow.monthly,
    };
    notifyListeners();
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

  Future<void> _reload() async {
    final payload = await _repository.loadBootstrap();
    _categories = payload.categories;
    _transactions = _sort(payload.transactions);
    _limits = payload.limits;
    notifyListeners();
  }

  List<TransactionRecord> _sort(List<TransactionRecord> records) {
    final rows = [...records];
    rows.sort((left, right) => right.id.compareTo(left.id));
    return rows;
  }
}
