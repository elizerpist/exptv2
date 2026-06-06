import '../../../services/native_bridge.dart';
import '../../transactions/models/transaction_category.dart';
import '../models/app_theme_settings.dart';
import '../models/fast_info_config.dart';

class SettingsBootstrap {
  const SettingsBootstrap({
    required this.themeSettings,
    required this.fastInfoConfig,
    required this.categories,
  });

  final AppThemeSettings themeSettings;
  final FastInfoConfig fastInfoConfig;
  final List<TransactionCategory> categories;
}

class SettingsRepository {
  const SettingsRepository(this._bridge);

  final NativeBridge _bridge;

  Future<SettingsBootstrap> loadBootstrap() async {
    final settings = await _bridge.expenseLoadSettings();
    final categories = await _bridge.expenseListCategories();
    return SettingsBootstrap(
      themeSettings: settings.themeSettings,
      fastInfoConfig: settings.fastInfoConfig,
      categories: categories,
    );
  }

  Future<AppThemeSettings> updateThemeSettings(AppThemeSettings settings) {
    return _bridge.expenseUpdateThemeSettings(settings);
  }

  Future<FastInfoConfig> updateFastInfoConfig(FastInfoConfig config) {
    return _bridge.expenseUpdateFastInfoConfig(config);
  }
}
