import 'package:flutter/foundation.dart';

import '../../transactions/models/transaction_category.dart';
import '../data/settings_repository.dart';
import '../models/app_theme_settings.dart';
import '../models/fast_info_config.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._repository);

  final SettingsRepository _repository;
  var _loading = false;
  String? _error;
  AppThemeSettings _themeSettings = AppThemeSettings.defaults();
  FastInfoConfig _fastInfoConfig = FastInfoConfig.defaults();
  List<TransactionCategory> _categories = [];

  bool get loading => _loading;
  String? get error => _error;
  AppThemeSettings get themeSettings => _themeSettings;
  FastInfoConfig get fastInfoConfig => _fastInfoConfig;
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
}
