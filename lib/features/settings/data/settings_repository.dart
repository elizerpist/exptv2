import '../../../services/native_bridge.dart';
import '../../transactions/models/transaction_category.dart';
import '../models/app_theme_settings.dart';
import '../models/fast_info_config.dart';
import '../models/recurring_transaction.dart';

class SettingsBootstrap {
  const SettingsBootstrap({
    required this.themeSettings,
    required this.fastInfoConfig,
    required this.recurringTransactions,
    required this.categories,
  });

  final AppThemeSettings themeSettings;
  final FastInfoConfig fastInfoConfig;
  final List<RecurringTransaction> recurringTransactions;
  final List<TransactionCategory> categories;
}

class SettingsRepository {
  const SettingsRepository(this._bridge);

  final NativeBridge _bridge;

  Future<SettingsBootstrap> loadBootstrap() async {
    final settings = await _bridge.expenseLoadSettings();
    final recurring = await _bridge.expenseListRecurringTransactions();
    final categories = await _bridge.expenseListCategories();
    return SettingsBootstrap(
      themeSettings: settings.themeSettings,
      fastInfoConfig: settings.fastInfoConfig,
      recurringTransactions: recurring,
      categories: categories,
    );
  }

  Future<AppThemeSettings> updateThemeSettings(AppThemeSettings settings) {
    return _bridge.expenseUpdateThemeSettings(settings);
  }

  Future<FastInfoConfig> updateFastInfoConfig(FastInfoConfig config) {
    return _bridge.expenseUpdateFastInfoConfig(config);
  }

  Future<RecurringTransaction> addRecurringTransaction(
    RecurringTransactionDraft draft,
  ) {
    return _bridge.expenseAddRecurringTransaction(draft);
  }

  Future<RecurringTransaction> updateRecurringTransaction(
    int id,
    RecurringTransactionDraft draft,
  ) {
    return _bridge.expenseUpdateRecurringTransaction(id, draft);
  }

  Future<RecurringTransaction> toggleRecurringTransaction(
    int id,
    bool isActive,
  ) {
    return _bridge.expenseToggleRecurringTransaction(id, isActive);
  }

  Future<bool> deleteRecurringTransaction(int id) {
    return _bridge.expenseDeleteRecurringTransaction(id);
  }

  Future<List<RecurringTransaction>> listRecurringTransactions() {
    return _bridge.expenseListRecurringTransactions();
  }
}
