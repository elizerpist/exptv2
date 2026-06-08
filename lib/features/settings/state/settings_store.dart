import 'package:flutter/foundation.dart';

import '../../../core/debug/debug_console.dart';
import '../../transactions/models/transaction_category.dart';
import '../data/settings_repository.dart';
import '../models/app_theme_settings.dart';
import '../models/fast_info_config.dart';
import '../models/notification_settings.dart';
import '../models/security_settings.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._repository);

  final SettingsRepository _repository;
  var _loading = false;
  String? _error;
  AppThemeSettings _themeSettings = AppThemeSettings.defaults();
  FastInfoConfig _fastInfoConfig = FastInfoConfig.defaults();
  SecuritySettings _securitySettings = SecuritySettings.defaults();
  NotificationSettings _notificationSettings = NotificationSettings.defaults();
  List<TransactionCategory> _categories = [];

  bool get loading => _loading;
  String? get error => _error;
  AppThemeSettings get themeSettings => _themeSettings;
  FastInfoConfig get fastInfoConfig => _fastInfoConfig;
  SecuritySettings get securitySettings => _securitySettings;
  NotificationSettings get notificationSettings => _notificationSettings;
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
      _securitySettings = payload.securitySettings;
      _notificationSettings = payload.notificationSettings;
      _categories = payload.categories;
      DebugConsole.log('[ThemeSurface] settings load ${_themeSignature()}');
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateThemeSettings(AppThemeSettings settings) async {
    _themeSettings = await _repository.updateThemeSettings(settings);
    DebugConsole.log('[ThemeSurface] settings update ${_themeSignature()}');
    notifyListeners();
  }

  Future<void> updateFastInfoConfig(FastInfoConfig config) async {
    _fastInfoConfig = await _repository.updateFastInfoConfig(config);
    notifyListeners();
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    _notificationSettings = await _repository.updateNotificationSettings(settings);
    notifyListeners();
  }

  Future<void> setSecurityPin(String pin) async {
    _securitySettings = await _repository.setSecurityPin(pin);
    notifyListeners();
  }

  Future<void> changeSecurityPin({
    required String currentPin,
    required String newPin,
  }) async {
    _securitySettings = await _repository.changeSecurityPin(
      currentPin: currentPin,
      newPin: newPin,
    );
    notifyListeners();
  }

  Future<void> clearSecurityPin(String currentPin) async {
    _securitySettings = await _repository.clearSecurityPin(currentPin);
    notifyListeners();
  }

  Future<bool> verifySecurityPin(String pin) {
    return _repository.verifySecurityPin(pin);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _securitySettings = await _repository.setBiometricEnabled(enabled);
    notifyListeners();
  }

  Future<void> refreshBiometricAvailability() async {
    _securitySettings = await _repository.loadBiometricAvailability();
    notifyListeners();
  }

  String _themeSignature() {
    return 'button=${_themeSettings.buttonSurfaceStyle.nativeValue} '
        'content=${_themeSettings.contentSurfaceStyle.nativeValue} '
        'bg=${_themeSettings.backgroundColor.nativeValue} '
        'card=${_themeSettings.cardColor.nativeValue} '
        'box=${_themeSettings.boxColor.nativeValue} '
        'magnet=${_themeSettings.magnetType.nativeValue} '
        'backheader=${_themeSettings.backheaderStyle.nativeValue}';
  }
}
