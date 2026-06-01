import 'dart:async';

import 'package:flutter/services.dart';

import '../features/notifications/models/expense_notification_card.dart';
import '../features/settings/models/app_theme_settings.dart';
import '../features/settings/models/fast_info_config.dart';
import '../features/settings/models/notification_parser_rule.dart';
import '../features/settings/models/recurring_transaction.dart';
import '../features/transactions/models/category_limit.dart';
import '../features/transactions/models/recurring_ghost_record.dart';
import '../features/transactions/models/transaction_category.dart';
import '../features/transactions/models/transaction_record.dart';
import '../models/installed_app.dart';
import '../models/notification_event.dart';
import '../models/service_status.dart';

class ExpenseSettingsPayload {
  const ExpenseSettingsPayload({
    required this.themeSettings,
    required this.fastInfoConfig,
  });

  final AppThemeSettings themeSettings;
  final FastInfoConfig fastInfoConfig;
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
    return ExpenseSettingsPayload(
      themeSettings: theme is Map<dynamic, dynamic>
          ? AppThemeSettings.fromMap(theme)
          : AppThemeSettings.defaults(),
      fastInfoConfig: fastInfo is Map<dynamic, dynamic>
          ? FastInfoConfig.fromMap(fastInfo)
          : FastInfoConfig.defaults(),
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

  Future<void> requestPostNotifications() async {
    await _methodChannel.invokeMethod<void>('requestPostNotifications');
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
