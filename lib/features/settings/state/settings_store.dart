import 'package:flutter/foundation.dart';

import '../../../core/debug/debug_console.dart';
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
  List<RecurringTransaction> get recurringTransactions =>
      List.unmodifiable(_recurringTransactions);
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  List<TransactionCategory> get expenseCategories =>
      categoriesFor(TransactionType.expense);
  List<TransactionCategory> get incomeCategories =>
      categoriesFor(TransactionType.income);

  List<TransactionCategory> categoriesFor(TransactionType type) =>
      _categories.where((category) => category.normalizedType == type).toList();

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
    TransactionType transactionType = TransactionType.expense,
    required int dayOfMonth,
    required int categoryId,
    bool isActive = true,
  }) async {
    final draft = RecurringTransactionDraft(
      name: name,
      amount: amount,
      transactionType: transactionType,
      dayOfMonth: dayOfMonth,
      categoryId: categoryId,
      isActive: isActive,
    );
    DebugConsole.log(
      '[Recurring] save $name type=${transactionType.nativeValue} '
      'day=$dayOfMonth amount=${_debugAmount(amount)}',
    );
    if (id == null) {
      await _repository.addRecurringTransaction(draft);
    } else {
      await _repository.updateRecurringTransaction(id, draft);
    }
    await _reloadRecurring();
  }

  Future<void> toggleRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final nextActive = !transaction.isActive;
    DebugConsole.log('[Recurring] toggle ${transaction.id} active=$nextActive');
    await _repository.toggleRecurringTransaction(transaction.id, nextActive);
    await _reloadRecurring();
  }

  Future<void> deleteRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    DebugConsole.log('[Recurring] delete ${transaction.id}');
    await _repository.deleteRecurringTransaction(transaction.id);
    await _reloadRecurring();
  }

  Future<void> _reloadRecurring() async {
    _recurringTransactions = await _repository.listRecurringTransactions();
    notifyListeners();
  }
}

String _debugAmount(double amount) {
  final rounded = amount.roundToDouble();
  if (amount == rounded) return rounded.toInt().toString();
  return amount.toString();
}
