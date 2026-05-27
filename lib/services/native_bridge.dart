import 'dart:async';

import 'package:flutter/services.dart';

import '../features/transactions/models/transaction_category.dart';
import '../features/transactions/models/transaction_record.dart';
import '../models/installed_app.dart';
import '../models/notification_event.dart';
import '../models/service_status.dart';

class ExpenseBootstrapPayload {
  const ExpenseBootstrapPayload({
    required this.categories,
    required this.transactions,
  });

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
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
    return ExpenseBootstrapPayload(
      categories: categories,
      transactions: transactions,
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

  Future<bool> expenseDeleteTransaction(int id) async {
    final deleted = await _methodChannel.invokeMethod<bool>(
      'expenseDeleteTransaction',
      {'id': id},
    );
    return deleted ?? false;
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
