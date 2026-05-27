import 'package:flutter/foundation.dart';

import '../data/transaction_filter.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../models/transaction_summary.dart';

enum SummaryWindow { monthly, yearly, allTime }

class TransactionStore extends ChangeNotifier {
  TransactionStore(this._repository);

  final TransactionRepositoryContract _repository;
  var _filter = const TransactionFilter();
  var _summaryWindow = SummaryWindow.allTime;
  var _loading = false;
  String? _error;
  List<TransactionCategory> _categories = [];
  List<TransactionRecord> _transactions = [];

  bool get loading => _loading;
  String? get error => _error;
  TransactionType get activeType => _filter.type;
  SummaryWindow get summaryWindow => _summaryWindow;
  String get searchQuery => _filter.searchQuery;
  String? get merchantFilter => _filter.merchant;
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);

  List<TransactionCategory> get activeCategories {
    return _categories
        .where((category) => category.normalizedType == _filter.type)
        .toList();
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

  TransactionSummary get activeSummary {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final source = _transactions.where((record) {
      if (record.type != _filter.type) return false;
      return switch (_summaryWindow) {
        SummaryWindow.monthly => record.yearMonthKey == month,
        SummaryWindow.yearly => record.yearMonthKey.startsWith(year),
        SummaryWindow.allTime => true,
      };
    });
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
      searchQuery: '',
    );
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
    final payload = await _repository.loadBootstrap();
    _categories = payload.categories;
    _transactions = _sort(payload.transactions);
    notifyListeners();
  }

  List<TransactionRecord> _sort(List<TransactionRecord> records) {
    final rows = [...records];
    rows.sort((left, right) => right.id.compareTo(left.id));
    return rows;
  }
}
