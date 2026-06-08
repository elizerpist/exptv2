import '../../../services/native_bridge.dart';
import '../../transactions/models/transaction_category.dart';
import '../models/app_theme_settings.dart';
import '../models/fast_info_config.dart';
import '../models/notification_settings.dart';
import '../models/security_settings.dart';

class SettingsBootstrap {
  const SettingsBootstrap({
    required this.themeSettings,
    required this.fastInfoConfig,
    required this.securitySettings,
    required this.notificationSettings,
    required this.categories,
  });

  final AppThemeSettings themeSettings;
  final FastInfoConfig fastInfoConfig;
  final SecuritySettings securitySettings;
  final NotificationSettings notificationSettings;
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
      securitySettings: settings.securitySettings,
      notificationSettings: settings.notificationSettings,
      categories: categories,
    );
  }

  Future<AppThemeSettings> updateThemeSettings(AppThemeSettings settings) {
    return _bridge.expenseUpdateThemeSettings(settings);
  }

  Future<FastInfoConfig> updateFastInfoConfig(FastInfoConfig config) {
    return _bridge.expenseUpdateFastInfoConfig(config);
  }

  Future<NotificationSettings> updateNotificationSettings(
    NotificationSettings settings,
  ) {
    return _bridge.expenseUpdateNotificationSettings(settings);
  }

  Future<SecuritySettings> setSecurityPin(String pin) {
    return _bridge.expenseSetSecurityPin(pin);
  }

  Future<SecuritySettings> changeSecurityPin({
    required String currentPin,
    required String newPin,
  }) {
    return _bridge.expenseChangeSecurityPin(
      currentPin: currentPin,
      newPin: newPin,
    );
  }

  Future<SecuritySettings> clearSecurityPin(String currentPin) {
    return _bridge.expenseClearSecurityPin(currentPin);
  }

  Future<bool> verifySecurityPin(String pin) {
    return _bridge.expenseVerifySecurityPin(pin);
  }

  Future<SecuritySettings> setBiometricEnabled(bool enabled) {
    return _bridge.expenseSetBiometricEnabled(enabled);
  }

  Future<SecuritySettings> loadBiometricAvailability() {
    return _bridge.expenseGetBiometricAvailability();
  }
}
