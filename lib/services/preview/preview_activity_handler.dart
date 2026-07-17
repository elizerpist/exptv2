import 'preview_method_handler.dart';
import 'preview_native_state.dart';

class PreviewActivityHandler implements PreviewMethodHandler {
  PreviewActivityHandler(this.state);

  final PreviewNativeState state;

  static const _methods = <String>{
    'loadEvents',
    'loadEventsAfterId',
    'loadNotificationEventPage',
    'loadNotificationEvent',
    'markNotificationEventSystem',
    'getStatus',
    'expenseListRecurringTransactions',
    'expenseAddRecurringTransaction',
    'expenseUpdateRecurringTransaction',
    'expenseToggleRecurringTransaction',
    'expenseDeleteRecurringTransaction',
    'expenseProcessRecurringTransactions',
    'expenseListRecurringRules',
    'expenseAddRecurringRule',
    'expenseUpdateRecurringRule',
    'expenseToggleRecurringRule',
    'expenseDeleteRecurringRule',
    'expenseListNotificationCards',
    'expenseMarkNotificationCardRead',
    'expenseDeleteNotificationCard',
    'expenseClearNotificationCards',
    'setCaptureMode',
    'openNotificationAccessSettings',
    'openAccessibilitySettings',
    'openAppInfoSettings',
    'openAppNotificationSettings',
    'requestPostNotifications',
    'requestPostNotificationsOnFirstLaunch',
    'sendTestNotification',
    'clearDatabase',
  };

  static const _nullPlatformMethods = <String>{
    'setCaptureMode',
    'openNotificationAccessSettings',
    'openAccessibilitySettings',
    'openAppInfoSettings',
    'openAppNotificationSettings',
    'requestPostNotifications',
    'sendTestNotification',
  };

  @override
  Set<String> get supportedMethods => _methods;

  @override
  Future<Object?> invoke(String method, Object? arguments) async {
    if (_nullPlatformMethods.contains(method)) return null;
    if (method == 'requestPostNotificationsOnFirstLaunch') return false;
    if (method == 'clearDatabase') {
      state.reset();
      return null;
    }

    final payload = _arguments(arguments);
    return switch (method) {
      'loadEvents' => previewCopyRows(state.notificationEvents),
      'loadEventsAfterId' => _loadEventsAfterId(payload),
      'loadNotificationEventPage' => _loadNotificationEventPage(payload),
      'loadNotificationEvent' => _loadNotificationEvent(payload),
      'markNotificationEventSystem' => _markNotificationEventSystem(payload),
      'getStatus' => _status(),
      'expenseListRecurringTransactions' => previewCopyRows(
        state.recurringTransactions,
      ),
      'expenseAddRecurringTransaction' => _addRecurringTransaction(payload),
      'expenseUpdateRecurringTransaction' => _updateRecurringTransaction(
        payload,
      ),
      'expenseToggleRecurringTransaction' => _toggleRecurringTransaction(
        payload,
      ),
      'expenseDeleteRecurringTransaction' => _deleteRecurringTransaction(
        payload,
      ),
      'expenseProcessRecurringTransactions' => _processRecurring(payload),
      'expenseListRecurringRules' => previewCopyRows(state.recurringRules),
      'expenseAddRecurringRule' => _addRecurringRule(payload),
      'expenseUpdateRecurringRule' => _updateRecurringRule(payload),
      'expenseToggleRecurringRule' => _toggleRecurringRule(payload),
      'expenseDeleteRecurringRule' => _deleteRecurringRule(payload),
      'expenseListNotificationCards' => _listNotificationCards(),
      'expenseMarkNotificationCardRead' => _markNotificationCardRead(payload),
      'expenseDeleteNotificationCard' => _deleteNotificationCard(payload),
      'expenseClearNotificationCards' => _clearNotificationCards(payload),
      _ => throw UnsupportedError(
        'Unsupported preview activity method: $method',
      ),
    };
  }

  List<Map<String, Object?>> _loadEventsAfterId(Map<String, Object?> payload) {
    final afterId = _int(payload['afterId']);
    return previewCopyRows(
      state.notificationEvents.where((row) => _int(row['id']) > afterId),
    );
  }

  Map<String, Object?> _loadNotificationEventPage(
    Map<String, Object?> payload,
  ) {
    final query = payload['query']?.toString().trim().toLowerCase() ?? '';
    final status = payload['status']?.toString() ?? 'all';
    final packageName = payload['packageName']?.toString();
    final year = _nullableInt(payload['year']);
    final month = _nullableInt(payload['month']);
    final rows =
        state.pushLogEvents.where((row) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            _int(row['timestamp']),
          );
          if (year != null && timestamp.year != year) return false;
          if (month != null && timestamp.month != month) return false;
          if (status != 'all' && row['status']?.toString() != status)
            return false;
          if (packageName != null &&
              packageName.isNotEmpty &&
              row['packageName']?.toString() != packageName) {
            return false;
          }
          if (query.isNotEmpty) {
            final haystack = <Object?>[
              row['appLabel'],
              row['packageName'],
              row['title'],
              row['text'],
              row['displayText'],
            ].join(' ').toLowerCase();
            if (!haystack.contains(query)) return false;
          }
          return true;
        }).toList()..sort(
          (left, right) => _int(right['id']).compareTo(_int(left['id'])),
        );
    final offset = _int(payload['offset']).clamp(0, rows.length);
    final limit = _int(payload['limit'], 60).clamp(1, 10000);
    final end = (offset + limit).clamp(offset, rows.length);
    return <String, Object?>{
      'events': previewCopyRows(rows.sublist(offset, end)),
      'totalCount': rows.length,
      'limit': limit,
      'offset': offset,
    };
  }

  Map<String, Object?>? _loadNotificationEvent(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final row = state.pushLogEvents.where((row) => row['id'] == id).firstOrNull;
    return row == null ? null : previewDeepCopyMap(row);
  }

  bool _markNotificationEventSystem(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final row = state.pushLogEvents.where((row) => row['id'] == id).firstOrNull;
    if (row == null) return false;
    row
      ..['status'] = 'system'
      ..['statusText'] = 'Rendszer'
      ..['manualStatus'] = 'system'
      ..['linkedTransactionId'] = null;
    return true;
  }

  Map<String, Object?> _status() => <String, Object?>{
    'captureMode': 'both',
    'notificationListenerEnabled': false,
    'accessibilityEnabled': false,
    'notificationListenerActive': false,
    'accessibilityActive': false,
    'lastNotificationListenerEvent': null,
    'lastAccessibilityEvent': null,
    'totalEvents': state.notificationEvents.length,
  };

  Map<String, Object?> _addRecurringTransaction(Map<String, Object?> payload) {
    final row = _recurringTransactionFromPayload(
      payload,
      id: state.takeRecurringId(),
    );
    state.recurringTransactions.add(row);
    return previewDeepCopyMap(row);
  }

  Map<String, Object?> _updateRecurringTransaction(
    Map<String, Object?> payload,
  ) {
    final id = _requiredId(payload);
    final index = state.recurringTransactions.indexWhere(
      (row) => row['id'] == id,
    );
    if (index < 0) {
      throw StateError('Preview recurring transaction not found: $id');
    }
    final row = _recurringTransactionFromPayload(
      payload,
      id: id,
      existing: state.recurringTransactions[index],
    );
    state.recurringTransactions[index] = row;
    return previewDeepCopyMap(row);
  }

  Map<String, Object?> _toggleRecurringTransaction(
    Map<String, Object?> payload,
  ) {
    final id = _requiredId(payload);
    final index = state.recurringTransactions.indexWhere(
      (row) => row['id'] == id,
    );
    if (index < 0) {
      throw StateError('Preview recurring transaction not found: $id');
    }
    state.recurringTransactions[index]
      ..['isActive'] = _bool(payload['isActive'])
      ..['updatedAt'] = state.now.millisecondsSinceEpoch;
    return previewDeepCopyMap(state.recurringTransactions[index]);
  }

  bool _deleteRecurringTransaction(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final before = state.recurringTransactions.length;
    state.recurringTransactions.removeWhere((row) => row['id'] == id);
    state.recurringGhosts.removeWhere(
      (row) => row['recurringTransactionId'] == id,
    );
    return state.recurringTransactions.length != before;
  }

  Map<String, Object?> _recurringTransactionFromPayload(
    Map<String, Object?> payload, {
    required int id,
    Map<String, Object?>? existing,
  }) {
    final merged = <String, Object?>{...?existing, ...payload};
    final category = _category(_int(merged['categoryId']));
    final nowMillis = state.now.millisecondsSinceEpoch;
    return <String, Object?>{
      'id': id,
      'name': merged['name']?.toString() ?? '',
      'amount': _double(merged['amount']).abs(),
      'transactionType': merged['transactionType']?.toString() ?? 'expense',
      'dayOfMonth': _int(merged['dayOfMonth'], 1).clamp(1, 31),
      'categoryId': _int(merged['categoryId']),
      'categoryName': category?['name']?.toString() ?? '',
      'categoryColor': category?['backgroundColor']?.toString() ?? '#64748b',
      'categoryIconSlot': _int(category?['iconSlot']),
      'isActive': merged['isActive'] == null ? true : _bool(merged['isActive']),
      'lastProcessedPeriodKey': merged['lastProcessedPeriodKey'],
      'lastProcessedAt': merged['lastProcessedAt'],
      'createdAt': existing?['createdAt'] ?? nowMillis,
      'updatedAt': nowMillis,
    };
  }

  Map<String, Object?> _addRecurringRule(Map<String, Object?> payload) {
    final row = _recurringRuleFromPayload(payload, id: state.takeRuleId());
    state.recurringRules.add(row);
    return previewDeepCopyMap(row);
  }

  Map<String, Object?> _updateRecurringRule(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final index = state.recurringRules.indexWhere((row) => row['id'] == id);
    if (index < 0) throw StateError('Preview recurring rule not found: $id');
    final row = _recurringRuleFromPayload(
      payload,
      id: id,
      existing: state.recurringRules[index],
    );
    state.recurringRules[index] = row;
    return previewDeepCopyMap(row);
  }

  Map<String, Object?> _toggleRecurringRule(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final index = state.recurringRules.indexWhere((row) => row['id'] == id);
    if (index < 0) throw StateError('Preview recurring rule not found: $id');
    state.recurringRules[index]
      ..['isActive'] = _bool(payload['isActive'])
      ..['updatedAt'] = state.now.millisecondsSinceEpoch;
    return previewDeepCopyMap(state.recurringRules[index]);
  }

  bool _deleteRecurringRule(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final before = state.recurringRules.length;
    state.recurringRules.removeWhere((row) => row['id'] == id);
    return state.recurringRules.length != before;
  }

  Map<String, Object?> _recurringRuleFromPayload(
    Map<String, Object?> payload, {
    required int id,
    Map<String, Object?>? existing,
  }) {
    final merged = <String, Object?>{...?existing, ...payload};
    final category = _category(_int(merged['categoryId']));
    final nowMillis = state.now.millisecondsSinceEpoch;
    return <String, Object?>{
      'id': id,
      'triggerType': merged['triggerType']?.toString() ?? 'date',
      'transactionType': merged['transactionType']?.toString() ?? 'expense',
      'name': merged['name']?.toString() ?? '',
      'estimatedAmount': _double(merged['estimatedAmount']).abs(),
      'expectedDayOfMonth': _int(merged['expectedDayOfMonth'], 1).clamp(1, 31),
      'expectedTime': merged['expectedTime']?.toString() ?? '00:00',
      'categoryId': _int(merged['categoryId']),
      'categoryName': category?['name']?.toString() ?? '',
      'categoryColor': category?['backgroundColor']?.toString() ?? '#64748b',
      'categoryIconSlot': _int(category?['iconSlot']),
      'isActive': merged['isActive'] == null ? true : _bool(merged['isActive']),
      'appFilterText': merged['appFilterText']?.toString() ?? '',
      'packageName': merged['packageName']?.toString() ?? '',
      'appLabel': merged['appLabel']?.toString() ?? '',
      'sampleText': merged['sampleText']?.toString() ?? '',
      'includeKeyword': merged['includeKeyword']?.toString() ?? '',
      'amountPattern': merged['amountPattern']?.toString() ?? '',
      'amountSelection': merged['amountSelection']?.toString() ?? '',
      'merchantPattern': merged['merchantPattern']?.toString() ?? '',
      'merchantSelection': merged['merchantSelection']?.toString() ?? '',
      'dateToleranceDays': _int(merged['dateToleranceDays'], 5),
      'amountTolerancePercent': _double(merged['amountTolerancePercent'], 20),
      'amountToleranceMin': _double(merged['amountToleranceMin'], 5000),
      'createdAt': existing?['createdAt'] ?? nowMillis,
      'updatedAt': nowMillis,
    };
  }

  List<Map<String, Object?>> _processRecurring(Map<String, Object?> payload) {
    final targetMillis = _nullableInt(payload['targetMillis']);
    final target = targetMillis == null
        ? state.now
        : DateTime.fromMillisecondsSinceEpoch(targetMillis);
    final period = _periodKey(target);
    final created = <Map<String, Object?>>[];
    for (final rule in state.recurringRules) {
      final ruleId = _int(rule['id']);
      if (!_bool(rule['isActive']) || rule['triggerType'] != 'date') continue;
      final day = _int(rule['expectedDayOfMonth'], 1);
      if (day > target.day) continue;
      final alreadyExists = state.transactions.any(
        (row) =>
            _nullableInt(row['recurringRuleId']) == ruleId &&
            row['date'].toString().startsWith(period.replaceAll('-', '.')),
      );
      if (alreadyExists) continue;
      final date = DateTime(
        target.year,
        target.month,
        day.clamp(1, DateTime(target.year, target.month + 1, 0).day),
      );
      final income = rule['transactionType'] == 'income';
      final amount = _double(rule['estimatedAmount']).abs();
      final row = <String, Object?>{
        'id': state.takeTransactionId(),
        'date': _formatDate(date),
        'time': rule['expectedTime']?.toString() ?? '00:00',
        'latitude': null,
        'longitude': null,
        'address': null,
        'merchant': rule['name']?.toString() ?? '',
        'amount': income ? amount : -amount,
        'userAssignedName': null,
        'transactionCategoryID': _nullableInt(rule['categoryId']),
        'recurringRuleId': ruleId,
      };
      state.transactions.add(row);
      created.add(row);
    }
    return previewCopyRows(created);
  }

  List<Map<String, Object?>> _listNotificationCards() {
    final rows = List<Map<String, Object?>>.from(state.notificationCards)
      ..sort(
        (left, right) =>
            _int(right['timestamp']).compareTo(_int(left['timestamp'])),
      );
    return previewCopyRows(rows);
  }

  bool _markNotificationCardRead(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final row = state.notificationCards
        .where((row) => row['id'] == id)
        .firstOrNull;
    if (row == null) return false;
    row
      ..['isRead'] = true
      ..['updatedAt'] = state.now.millisecondsSinceEpoch;
    return true;
  }

  bool _deleteNotificationCard(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final before = state.notificationCards.length;
    state.notificationCards.removeWhere((row) => row['id'] == id);
    return state.notificationCards.length != before;
  }

  int _clearNotificationCards(Map<String, Object?> payload) {
    final monthKey = payload['monthKey']?.toString();
    final before = state.notificationCards.length;
    state.notificationCards.removeWhere((row) {
      if (monthKey == null || monthKey.isEmpty) return true;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
        _int(row['timestamp']),
      );
      return _periodKey(timestamp) == monthKey;
    });
    return before - state.notificationCards.length;
  }

  Map<String, Object?>? _category(int id) => state.categories
      .where((row) => row['transactionCategoryID'] == id)
      .firstOrNull;
}

Map<String, Object?> _arguments(Object? arguments) {
  if (arguments == null) return <String, Object?>{};
  if (arguments is! Map) {
    throw ArgumentError.value(arguments, 'arguments', 'Expected a map');
  }
  return arguments.map(
    (key, value) => MapEntry(key.toString(), value as Object?),
  );
}

int _requiredId(Map<String, Object?> payload) {
  final id = _nullableInt(payload['id']);
  if (id == null) throw ArgumentError.value(payload['id'], 'id');
  return id;
}

int _int(Object? value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _double(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Object? value) =>
    value == true || value == 1 || value?.toString() == 'true';

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

String _periodKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
