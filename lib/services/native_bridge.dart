import 'dart:async';

import 'package:flutter/services.dart';

import '../features/notifications/models/expense_notification_card.dart';
import '../features/settings/models/app_theme_settings.dart';
import '../features/settings/models/fast_info_config.dart';
import '../features/settings/models/notification_parser_rule.dart';
import '../features/settings/models/recurring_transaction.dart';
import '../features/settings/models/security_settings.dart';
import '../features/transactions/models/category_limit.dart';
import '../features/transactions/models/recurring_ghost_record.dart';
import '../features/transactions/models/recurring_rule.dart';
import '../features/transactions/models/transaction_category.dart';
import '../features/transactions/models/transaction_record.dart';
import '../models/installed_app.dart';
import '../models/notification_event.dart';
import '../models/service_status.dart';

class ExpenseSettingsPayload {
  const ExpenseSettingsPayload({
    required this.themeSettings,
    required this.fastInfoConfig,
    required this.pushRecurringSettings,
    required this.securitySettings,
  });

  final AppThemeSettings themeSettings;
  final FastInfoConfig fastInfoConfig;
  final PushRecurringSettings pushRecurringSettings;
  final SecuritySettings securitySettings;
}

class ExpenseBootstrapPayload {
  const ExpenseBootstrapPayload({
    required this.categories,
    required this.transactions,
    required this.limits,
    required this.recurringGhostTransactions,
  });

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
  final List<CategoryLimit> limits;
  final List<RecurringGhostRecord> recurringGhostTransactions;
}

class ExpenseTransactionPagePayload {
  const ExpenseTransactionPagePayload({
    required this.transactions,
    required this.totalCount,
    required this.limit,
    required this.offset,
  });

  final List<TransactionRecord> transactions;
  final int totalCount;
  final int limit;
  final int offset;
}

class NativeBridge {
  NativeBridge({MethodChannel? methodChannel, EventChannel? eventChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel('pushparser/methods'),
      _eventChannel = eventChannel ?? const EventChannel('pushparser/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Future<List<NotificationEvent>> loadEvents() async {
    final rows = await _methodChannel.invokeListMethod<dynamic>('loadEvents');
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(NotificationEvent.fromMap)
        .toList();
  }

  Future<ServiceStatus> getStatus() async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'getStatus',
    );
    return ServiceStatus.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<List<InstalledApp>> listInstalledApps() async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'listInstalledApps',
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(InstalledApp.fromMap)
        .toList();
  }

  Future<ExpenseBootstrapPayload> expenseLoadBootstrap() async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseLoadBootstrap',
    );
    final payload = map ?? <dynamic, dynamic>{};
    final categories = (payload['categories'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(TransactionCategory.fromMap)
        .toList();
    final transactions =
        (payload['transactions'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<dynamic, dynamic>>()
            .map(TransactionRecord.fromMap)
            .toList();
    final limits = (payload['limits'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(CategoryLimit.fromMap)
        .toList();
    final recurringGhostTransactions =
        (payload['recurringGhostTransactions'] as List<dynamic>? ?? <dynamic>[])
            .cast<Map<dynamic, dynamic>>()
            .map(RecurringGhostRecord.fromMap)
            .toList();
    return ExpenseBootstrapPayload(
      categories: categories,
      transactions: transactions,
      limits: limits,
      recurringGhostTransactions: recurringGhostTransactions,
    );
  }

  Future<List<TransactionRecord>> expenseListTransactions(
    Map<String, Object?> filter,
  ) async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseListTransactions',
      filter,
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(TransactionRecord.fromMap)
        .toList();
  }

  Future<ExpenseTransactionPagePayload> expenseListTransactionPage(
    Map<String, Object?> filter,
  ) async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseListTransactionPage',
      filter,
    );
    final payload = map ?? <dynamic, dynamic>{};
    final rows = (payload['transactions'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(TransactionRecord.fromMap)
        .toList();
    int readInt(String key) {
      final value = payload[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ExpenseTransactionPagePayload(
      transactions: rows,
      totalCount: readInt('totalCount'),
      limit: readInt('limit'),
      offset: readInt('offset'),
    );
  }

  Future<List<TransactionCategory>> expenseListCategories({
    String? type,
  }) async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseListCategories',
      {'type': type},
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(TransactionCategory.fromMap)
        .toList();
  }

  Future<TransactionRecord> expenseAddTransaction(
    Map<String, Object?> payload,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseAddTransaction',
      payload,
    );
    return TransactionRecord.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<TransactionRecord> expenseUpdateTransaction(
    int id,
    Map<String, Object?> payload,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseUpdateTransaction',
      {'id': id, ...payload},
    );
    return TransactionRecord.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<TransactionCategory> expenseAddCategory(
    Map<String, Object?> payload,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseAddCategory',
      payload,
    );
    return TransactionCategory.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<TransactionCategory> expenseUpdateCategory(
    int id,
    Map<String, Object?> payload,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseUpdateCategory',
      {'id': id, ...payload},
    );
    return TransactionCategory.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<bool> expenseDeleteCategory(int id) async {
    final deleted = await _methodChannel.invokeMethod<bool>(
      'expenseDeleteCategory',
      {'id': id},
    );
    return deleted ?? false;
  }

  Future<Map<int, int>> expenseCategoryCounts() async {
    final rows = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseCategoryCounts',
    );
    final counts = <int, int>{};
    for (final entry in (rows ?? <dynamic, dynamic>{}).entries) {
      final key = entry.key is int
          ? entry.key as int
          : int.parse(entry.key.toString());
      final value = entry.value is int
          ? entry.value as int
          : int.parse(entry.value.toString());
      counts[key] = value;
    }
    return counts;
  }

  Future<List<CategoryLimit>> expenseListCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseListCategoryLimits',
      {
        'transactionType': transactionType,
        'window': window,
        'periodKey': periodKey,
      },
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(CategoryLimit.fromMap)
        .toList();
  }

  Future<CategoryLimit> expenseUpsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseUpsertCategoryLimit',
      payload,
    );
    return CategoryLimit.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<bool> expenseDeleteTransaction(int id) async {
    final deleted = await _methodChannel.invokeMethod<bool>(
      'expenseDeleteTransaction',
      {'id': id},
    );
    return deleted ?? false;
  }

  Future<int> expenseRenameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async {
    final count = await _methodChannel.invokeMethod<int>(
      'expenseRenameTransactionsByMerchant',
      {
        'originalMerchant': originalMerchant,
        'userAssignedName': userAssignedName,
      },
    );
    return count ?? 0;
  }

  Future<int> expenseResetTransactionNamesByMerchant(
    String originalMerchant,
  ) async {
    final count = await _methodChannel.invokeMethod<int>(
      'expenseResetTransactionNamesByMerchant',
      {'originalMerchant': originalMerchant},
    );
    return count ?? 0;
  }

  Future<ExpenseSettingsPayload> expenseLoadSettings() async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseLoadSettings',
    );
    final payload = map ?? <dynamic, dynamic>{};
    final theme = payload['themeSettings'];
    final fastInfo = payload['fastInfoConfig'];
    final pushRecurring = payload['pushRecurringSettings'];
    final security = payload['securitySettings'];
    return ExpenseSettingsPayload(
      themeSettings: theme is Map<dynamic, dynamic>
          ? AppThemeSettings.fromMap(theme)
          : AppThemeSettings.defaults(),
      fastInfoConfig: fastInfo is Map<dynamic, dynamic>
          ? FastInfoConfig.fromMap(fastInfo)
          : FastInfoConfig.defaults(),
      pushRecurringSettings: pushRecurring is Map<dynamic, dynamic>
          ? PushRecurringSettings.fromMap(pushRecurring)
          : PushRecurringSettings.defaults(),
      securitySettings: security is Map<dynamic, dynamic>
          ? SecuritySettings.fromMap(security)
          : SecuritySettings.defaults(),
    );
  }

  Future<AppThemeSettings> expenseUpdateThemeSettings(
    AppThemeSettings settings,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseUpdateThemeSettings',
      settings.toMap(),
    );
    return AppThemeSettings.fromMap(row ?? settings.toMap());
  }

  Future<FastInfoConfig> expenseUpdateFastInfoConfig(
    FastInfoConfig config,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseUpdateFastInfoConfig',
      config.toMap(),
    );
    return FastInfoConfig.fromMap(row ?? config.toMap());
  }

  Future<String> expenseSaveTextFile({
    required String fileName,
    required String mimeType,
    required String content,
  }) async {
    final uri = await _methodChannel.invokeMethod<String>(
      'expenseSaveTextFile',
      {'fileName': fileName, 'mimeType': mimeType, 'content': content},
    );
    return uri ?? '';
  }

  Future<void> expenseShareTextFile({
    required String fileName,
    required String mimeType,
    required String content,
    required String chooserTitle,
  }) {
    return _methodChannel.invokeMethod<void>('expenseShareTextFile', {
      'fileName': fileName,
      'mimeType': mimeType,
      'content': content,
      'chooserTitle': chooserTitle,
    });
  }

  Future<PushRecurringSettings> expenseUpdatePushRecurringSettings(
    PushRecurringSettings settings,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseUpdatePushRecurringSettings',
      settings.toMap(),
    );
    final payload = row?['pushRecurringSettings'];
    return payload is Map<dynamic, dynamic>
        ? PushRecurringSettings.fromMap(payload)
        : PushRecurringSettings.fromMap(row ?? settings.toMap());
  }

  Future<SecuritySettings> expenseSetSecurityPin(String pin) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseSetSecurityPin',
      {'pin': pin},
    );
    return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<SecuritySettings> expenseChangeSecurityPin({
    required String currentPin,
    required String newPin,
  }) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseChangeSecurityPin',
      {'currentPin': currentPin, 'newPin': newPin},
    );
    return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<SecuritySettings> expenseClearSecurityPin(String currentPin) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseClearSecurityPin',
      {'currentPin': currentPin},
    );
    return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<bool> expenseVerifySecurityPin(String pin) async {
    final verified = await _methodChannel.invokeMethod<bool>(
      'expenseVerifySecurityPin',
      {'pin': pin},
    );
    return verified ?? false;
  }

  Future<SecuritySettings> expenseSetBiometricEnabled(bool enabled) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseSetBiometricEnabled',
      {'enabled': enabled},
    );
    return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<SecuritySettings> expenseGetBiometricAvailability() async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseGetBiometricAvailability',
    );
    return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<bool> expenseAuthenticateBiometric() async {
    final authenticated = await _methodChannel.invokeMethod<bool>(
      'expenseAuthenticateBiometric',
    );
    return authenticated ?? false;
  }

  Future<List<RecurringTransaction>> expenseListRecurringTransactions() async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseListRecurringTransactions',
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(RecurringTransaction.fromMap)
        .toList();
  }

  Future<RecurringTransaction> expenseAddRecurringTransaction(
    RecurringTransactionDraft draft,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseAddRecurringTransaction',
      draft.toMap(),
    );
    return RecurringTransaction.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<RecurringTransaction> expenseUpdateRecurringTransaction(
    int id,
    RecurringTransactionDraft draft,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseUpdateRecurringTransaction',
      {'id': id, ...draft.toMap()},
    );
    return RecurringTransaction.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<RecurringTransaction> expenseToggleRecurringTransaction(
    int id,
    bool isActive,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseToggleRecurringTransaction',
      {'id': id, 'isActive': isActive},
    );
    return RecurringTransaction.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<bool> expenseDeleteRecurringTransaction(int id) async {
    final deleted = await _methodChannel.invokeMethod<bool>(
      'expenseDeleteRecurringTransaction',
      {'id': id},
    );
    return deleted ?? false;
  }

  Future<List<RecurringTransaction>> expenseProcessRecurringTransactions({
    DateTime? targetDate,
  }) async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseProcessRecurringTransactions',
      {
        if (targetDate != null)
          'targetMillis': targetDate.millisecondsSinceEpoch,
      },
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(RecurringTransaction.fromMap)
        .toList();
  }

  Future<List<RecurringGhostRecord>>
  expenseListRecurringGhostTransactions() async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseListRecurringGhostTransactions',
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(RecurringGhostRecord.fromMap)
        .toList();
  }

  Future<List<RecurringGhostRecord>> expenseEnsureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseEnsureRecurringGhostTransactions',
      {
        if (targetDate != null)
          'targetMillis': targetDate.millisecondsSinceEpoch,
      },
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(RecurringGhostRecord.fromMap)
        .toList();
  }

  Future<List<RecurringRule>> expenseListRecurringRules() async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseListRecurringRules',
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(RecurringRule.fromMap)
        .toList();
  }

  Future<RecurringRule> expenseAddRecurringRule(
    RecurringRuleDraft draft,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseAddRecurringRule',
      draft.toMap(),
    );
    return RecurringRule.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<RecurringRule> expenseUpdateRecurringRule(
    int id,
    RecurringRuleDraft draft,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseUpdateRecurringRule',
      {'id': id, ...draft.toMap()},
    );
    return RecurringRule.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<RecurringRule> expenseToggleRecurringRule(
    int id,
    bool isActive,
  ) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'expenseToggleRecurringRule',
      {'id': id, 'isActive': isActive},
    );
    return RecurringRule.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<bool> expenseDeleteRecurringRule(int id) async {
    final deleted = await _methodChannel.invokeMethod<bool>(
      'expenseDeleteRecurringRule',
      {'id': id},
    );
    return deleted ?? false;
  }

  Future<List<ExpenseNotificationCard>> expenseListNotificationCards() async {
    final rows = await _methodChannel.invokeListMethod<dynamic>(
      'expenseListNotificationCards',
    );
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(ExpenseNotificationCard.fromMap)
        .toList();
  }

  Future<bool> expenseMarkNotificationCardRead(int id) async {
    final updated = await _methodChannel.invokeMethod<bool>(
      'expenseMarkNotificationCardRead',
      {'id': id},
    );
    return updated ?? false;
  }

  Future<bool> expenseDeleteNotificationCard(int id) async {
    final deleted = await _methodChannel.invokeMethod<bool>(
      'expenseDeleteNotificationCard',
      {'id': id},
    );
    return deleted ?? false;
  }

  Future<int> expenseClearNotificationCards({String? monthKey}) async {
    final count = await _methodChannel.invokeMethod<int>(
      'expenseClearNotificationCards',
      {'monthKey': monthKey},
    );
    return count ?? 0;
  }

  Future<NotificationParserConfig> loadNotificationParserProfiles() async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'loadNotificationParserProfiles',
    );
    return NotificationParserConfig.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<NotificationParserConfig> saveNotificationParserProfiles(
    NotificationParserConfig config,
  ) async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'saveNotificationParserProfiles',
      config.toMap(),
    );
    return NotificationParserConfig.fromMap(map ?? config.toMap());
  }

  Future<NotificationParserRule> loadNotificationParserRule() async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'loadNotificationParserRule',
    );
    return NotificationParserRule.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<NotificationParserRule> saveNotificationParserRule(
    NotificationParserRule rule,
  ) async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
      'saveNotificationParserRule',
      rule.toMap(),
    );
    return NotificationParserRule.fromMap(map ?? rule.toMap());
  }

  Future<void> setCaptureMode(CaptureMode mode) async {
    await _methodChannel.invokeMethod<void>('setCaptureMode', mode.nativeValue);
  }

  Future<void> openNotificationAccessSettings() async {
    await _methodChannel.invokeMethod<void>('openNotificationAccessSettings');
  }

  Future<void> openAccessibilitySettings() async {
    await _methodChannel.invokeMethod<void>('openAccessibilitySettings');
  }

  Future<void> openAppInfoSettings() async {
    await _methodChannel.invokeMethod<void>('openAppInfoSettings');
  }

  Future<void> openAppNotificationSettings() async {
    await _methodChannel.invokeMethod<void>('openAppNotificationSettings');
  }

  Future<void> requestPostNotifications() async {
    await _methodChannel.invokeMethod<void>('requestPostNotifications');
  }

  Future<bool> requestPostNotificationsOnFirstLaunch() async {
    final requested = await _methodChannel.invokeMethod<bool>(
      'requestPostNotificationsOnFirstLaunch',
    );
    return requested ?? false;
  }

  Future<void> sendTestNotification() async {
    await _methodChannel.invokeMethod<void>('sendTestNotification');
  }

  Future<void> clearDatabase() async {
    await _methodChannel.invokeMethod<void>('clearDatabase');
  }

  Stream<NotificationEvent> watchEvents() {
    return _eventChannel.receiveBroadcastStream().map((payload) {
      return NotificationEvent.fromMap(payload as Map<dynamic, dynamic>);
    });
  }
}
