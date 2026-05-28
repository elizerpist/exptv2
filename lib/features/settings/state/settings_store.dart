import 'package:flutter/foundation.dart';

import '../../transactions/models/transaction_category.dart';
import '../data/settings_repository.dart';
import '../models/app_theme_settings.dart';
import '../models/fast_info_config.dart';
import '../models/recurring_transaction.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._repository);

  final SettingsRepository _repository;
  var _loading = false;
  String? _error;
  AppThemeSettings _themeSettings = AppThemeSettings.defaults();
  FastInfoConfig _fastInfoConfig = FastInfoConfig.defaults();
  List<RecurringTransaction> _recurringTransactions = [];
  List<TransactionCategory> _categories = [];

  bool get loading => _loading;
  String? get error => _error;
  AppThemeSettings get themeSettings => _themeSettings;
  FastInfoConfig get fastInfoConfig => _fastInfoConfig;
  List<RecurringTransaction> get recurringTransactions => List.unmodifiable(_recurringTransactions);
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  List<TransactionCategory> get expenseCategories => _categories
      .where((category) => category.normalizedType == TransactionType.expense)
      .toList();

  Future<void> start() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = await _repository.loadBootstrap();
      _themeSettings = payload.themeSettings;
      _fastInfoConfig = payload.fastInfoConfig;
      _recurringTransactions = payload.recurringTransactions;
      _categories = payload.categories;
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateThemeSettings(AppThemeSettings settings) async {
    _themeSettings = await _repository.updateThemeSettings(settings);
    notifyListeners();
  }

  Future<void> updateFastInfoConfig(FastInfoConfig config) async {
    _fastInfoConfig = await _repository.updateFastInfoConfig(config);
    notifyListeners();
  }

  Future<void> saveRecurringTransaction({
    int? id,
    required String name,
    required double amount,
    required int dayOfMonth,
    required int categoryId,
    bool isActive = true,
  }) async {
    final draft = RecurringTransactionDraft(
      name: name,
      amount: amount,
      transactionType: TransactionType.expense,
      dayOfMonth: dayOfMonth,
      categoryId: categoryId,
      isActive: isActive,
    );
    if (id == null) {
      await _repository.addRecurringTransaction(draft);
    } else {
      await _repository.updateRecurringTransaction(id, draft);
    }
    await _reloadRecurring();
  }

  Future<void> toggleRecurringTransaction(RecurringTransaction transaction) async {
    await _repository.toggleRecurringTransaction(transaction.id, !transaction.isActive);
    await _reloadRecurring();
  }

  Future<void> deleteRecurringTransaction(RecurringTransaction transaction) async {
    await _repository.deleteRecurringTransaction(transaction.id);
    await _reloadRecurring();
  }

  Future<void> _reloadRecurring() async {
    _recurringTransactions = await _repository.listRecurringTransactions();
    notifyListeners();
  }
}
