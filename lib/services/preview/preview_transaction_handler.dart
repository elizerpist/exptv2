import 'preview_method_handler.dart';
import 'preview_native_state.dart';

class PreviewTransactionHandler implements PreviewMethodHandler {
  PreviewTransactionHandler(this.state);

  final PreviewNativeState state;

  static const _methods = <String>{
    'expensePickYearMonth',
    'expenseLoadBootstrap',
    'expenseListStatsSnapshots',
    'expenseUpsertStatsSnapshot',
    'expenseListTransactions',
    'expenseListTransactionPage',
    'expenseGetTransaction',
    'expenseNotificationEventIdForTransaction',
    'expenseTransactionsForNotificationEvents',
    'expenseListCategories',
    'expenseAddTransaction',
    'expenseUpdateTransaction',
    'expenseAddCategory',
    'expenseUpdateCategory',
    'expenseDeleteCategory',
    'expenseCategoryCounts',
    'expenseListCategoryLimits',
    'expenseUpsertCategoryLimit',
    'expenseDeleteTransaction',
    'expenseRenameTransactionsByMerchant',
    'expenseResetTransactionNamesByMerchant',
    'expenseListRecurringGhostTransactions',
    'expenseEnsureRecurringGhostTransactions',
  };

  @override
  Set<String> get supportedMethods => _methods;

  @override
  Future<Object?> invoke(String method, Object? arguments) async {
    final payload = _arguments(arguments);
    return switch (method) {
      'expensePickYearMonth' => _pickYearMonth(payload),
      'expenseLoadBootstrap' => _loadBootstrap(),
      'expenseListStatsSnapshots' => previewCopyRows(state.statsSnapshots),
      'expenseUpsertStatsSnapshot' => _upsertStatsSnapshot(payload),
      'expenseListTransactions' => previewCopyRows(
        _filterTransactions(payload),
      ),
      'expenseListTransactionPage' => _listTransactionPage(payload),
      'expenseGetTransaction' => _getTransaction(payload),
      'expenseNotificationEventIdForTransaction' =>
        _notificationEventIdForTransaction(payload),
      'expenseTransactionsForNotificationEvents' =>
        _transactionsForNotificationEvents(payload),
      'expenseListCategories' => _listCategories(payload),
      'expenseAddTransaction' => _addTransaction(payload),
      'expenseUpdateTransaction' => _updateTransaction(payload),
      'expenseAddCategory' => _addCategory(payload),
      'expenseUpdateCategory' => _updateCategory(payload),
      'expenseDeleteCategory' => _deleteCategory(payload),
      'expenseCategoryCounts' => _categoryCounts(),
      'expenseListCategoryLimits' => _listCategoryLimits(payload),
      'expenseUpsertCategoryLimit' => _upsertCategoryLimit(payload),
      'expenseDeleteTransaction' => _deleteTransaction(payload),
      'expenseRenameTransactionsByMerchant' => _renameTransactionsByMerchant(
        payload,
      ),
      'expenseResetTransactionNamesByMerchant' =>
        _resetTransactionNamesByMerchant(payload),
      'expenseListRecurringGhostTransactions' ||
      'expenseEnsureRecurringGhostTransactions' => previewCopyRows(
        state.recurringGhosts,
      ),
      _ => throw UnsupportedError(
        'Unsupported preview transaction method: $method',
      ),
    };
  }

  Map<String, Object?> _pickYearMonth(Map<String, Object?> payload) {
    final year = _int(payload['year'], state.now.year);
    final month = _int(payload['month'], state.now.month).clamp(1, 12);
    return <String, Object?>{'year': year, 'month': month};
  }

  Map<String, Object?> _loadBootstrap() => <String, Object?>{
    'categories': previewCopyRows(state.categories),
    'transactions': previewCopyRows(state.transactions),
    'limits': previewCopyRows(state.limits),
    'recurringGhostTransactions': previewCopyRows(state.recurringGhosts),
  };

  Map<String, Object?> _upsertStatsSnapshot(Map<String, Object?> payload) {
    final row = previewDeepCopyMap(payload);
    final id = row['id']?.toString().trim();
    if (id == null || id.isEmpty) {
      throw ArgumentError.value(row['id'], 'id', 'Snapshot ID is required');
    }
    row['id'] = id;
    final index = state.statsSnapshots.indexWhere(
      (existing) => existing['id']?.toString() == id,
    );
    if (index < 0) {
      state.statsSnapshots.add(row);
    } else {
      state.statsSnapshots[index] = row;
    }
    return previewDeepCopyMap(row);
  }

  List<Map<String, Object?>> _filterTransactions(Map<String, Object?> payload) {
    final type = payload['type']?.toString();
    final categoryId = _nullableInt(payload['categoryId']);
    final merchant = payload['merchant']?.toString();
    final search =
        payload['searchQuery']?.toString().trim().toLowerCase() ?? '';
    final yearMonth = payload['yearMonth']?.toString().trim().replaceAll(
      '-',
      '.',
    );

    final rows = state.transactions.where((row) {
      final amount = _double(row['amount']);
      if (type == 'income' && amount <= 0) return false;
      if (type == 'expense' && amount > 0) return false;
      if (categoryId != null &&
          _nullableInt(row['transactionCategoryID']) != categoryId) {
        return false;
      }
      if (merchant != null &&
          merchant.isNotEmpty &&
          row['merchant'] != merchant) {
        return false;
      }
      if (yearMonth != null &&
          yearMonth.isNotEmpty &&
          !row['date'].toString().startsWith(yearMonth)) {
        return false;
      }
      if (search.isNotEmpty) {
        final haystack = <String>[
          row['merchant']?.toString() ?? '',
          row['userAssignedName']?.toString() ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(search)) return false;
      }
      return true;
    }).toList();
    rows.sort(_compareTransactionsDescending);
    return rows;
  }

  Map<String, Object?> _listTransactionPage(Map<String, Object?> payload) {
    final rows = _filterTransactions(payload);
    final offset = _int(payload['offset'], 0).clamp(0, rows.length);
    final limit = _int(payload['limit'], 96).clamp(1, 10000);
    final end = (offset + limit).clamp(offset, rows.length);
    return <String, Object?>{
      'transactions': previewCopyRows(rows.sublist(offset, end)),
      'totalCount': rows.length,
      'limit': limit,
      'offset': offset,
    };
  }

  Map<String, Object?>? _getTransaction(Map<String, Object?> payload) {
    final id = _nullableInt(payload['id']);
    final row = state.transactions.where((row) => row['id'] == id).firstOrNull;
    return row == null ? null : previewDeepCopyMap(row);
  }

  int? _notificationEventIdForTransaction(Map<String, Object?> payload) {
    final id = _nullableInt(payload['id']);
    final row = state.transactions.where((row) => row['id'] == id).firstOrNull;
    return _nullableInt(row?['sourceNotificationEventId']);
  }

  List<Map<String, Object?>> _transactionsForNotificationEvents(
    Map<String, Object?> payload,
  ) {
    final rawIds = payload['eventIds'];
    final ids = rawIds is List
        ? rawIds.map(_nullableInt).whereType<int>().toSet()
        : <int>{};
    return previewCopyRows(
      state.transactions.where(
        (row) => ids.contains(_nullableInt(row['sourceNotificationEventId'])),
      ),
    );
  }

  List<Map<String, Object?>> _listCategories(Map<String, Object?> payload) {
    final rawType = payload['type']?.toString();
    if (rawType == null || rawType.isEmpty) {
      return previewCopyRows(state.categories);
    }
    final type = _hungarianType(rawType);
    return previewCopyRows(
      state.categories.where((row) => row['type'] == type),
    );
  }

  Map<String, Object?> _addTransaction(Map<String, Object?> payload) {
    final row = _transactionFromPayload(payload, id: state.takeTransactionId());
    state.transactions.add(row);
    return previewDeepCopyMap(row);
  }

  Map<String, Object?> _updateTransaction(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final index = state.transactions.indexWhere((row) => row['id'] == id);
    if (index < 0) throw StateError('Preview transaction not found: $id');
    final row = _transactionFromPayload(
      payload,
      id: id,
      existing: state.transactions[index],
    );
    state.transactions[index] = row;
    return previewDeepCopyMap(row);
  }

  Map<String, Object?> _transactionFromPayload(
    Map<String, Object?> payload, {
    required int id,
    Map<String, Object?>? existing,
  }) {
    final merged = <String, Object?>{...?existing, ...payload};
    final rawAmount = _double(merged['amount']);
    final rawType =
        merged['type']?.toString() ?? merged['transactionType']?.toString();
    final income = rawType == 'income' || (rawType == null && rawAmount > 0);
    return <String, Object?>{
      'id': id,
      'date': merged['date']?.toString() ?? _formatDate(state.now),
      'time': merged['time']?.toString() ?? '12:00',
      'latitude': merged['latitude'],
      'longitude': merged['longitude'],
      'address': merged['address'],
      'merchant': merged['merchant']?.toString() ?? '',
      'amount': income ? rawAmount.abs() : -rawAmount.abs(),
      'userAssignedName': merged['userAssignedName'],
      'transactionCategoryID': _nullableInt(merged['transactionCategoryID']),
      if (merged['recurringTransactionId'] != null)
        'recurringTransactionId': merged['recurringTransactionId'],
      if (merged['recurringRuleId'] != null)
        'recurringRuleId': merged['recurringRuleId'],
      if (merged['recurringInstanceId'] != null)
        'recurringInstanceId': merged['recurringInstanceId'],
      if (merged['sourceNotificationEventId'] != null)
        'sourceNotificationEventId': merged['sourceNotificationEventId'],
    };
  }

  Map<String, Object?> _addCategory(Map<String, Object?> payload) {
    final row = _categoryFromPayload(payload, id: state.takeCategoryId());
    state.categories.add(row);
    return previewDeepCopyMap(row);
  }

  Map<String, Object?> _updateCategory(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final index = state.categories.indexWhere(
      (row) => row['transactionCategoryID'] == id,
    );
    if (index < 0) throw StateError('Preview category not found: $id');
    final row = _categoryFromPayload(
      payload,
      id: id,
      existing: state.categories[index],
    );
    state.categories[index] = row;
    return previewDeepCopyMap(row);
  }

  Map<String, Object?> _categoryFromPayload(
    Map<String, Object?> payload, {
    required int id,
    Map<String, Object?>? existing,
  }) {
    final merged = <String, Object?>{...?existing, ...payload};
    return <String, Object?>{
      'transactionCategoryID': id,
      'name': merged['name']?.toString() ?? '',
      'type': _hungarianType(merged['type']?.toString() ?? 'expense'),
      'colorSlot': _nullableInt(merged['colorSlot']),
      'iconSlot': _nullableInt(merged['iconSlot']),
      'backgroundColor': merged['backgroundColor']?.toString() ?? '#64748b',
      'icon': merged['icon']?.toString(),
      'notification': merged['notification']?.toString(),
      'hasLimit': _bool(merged['hasLimit']),
      'limitAmount': _double(merged['limitAmount']),
      'alertActive': _bool(merged['alertActive']),
      'isCustomIcon': merged['isCustomIcon'] == null
          ? true
          : _bool(merged['isCustomIcon']),
      'originalIcon': merged['originalIcon']?.toString(),
    };
  }

  bool _deleteCategory(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final referenced = state.transactions.any(
      (row) => _nullableInt(row['transactionCategoryID']) == id,
    );
    if (referenced) return false;
    final before = state.categories.length;
    state.categories.removeWhere((row) => row['transactionCategoryID'] == id);
    return state.categories.length != before;
  }

  Map<int, int> _categoryCounts() {
    final counts = <int, int>{};
    for (final row in state.transactions) {
      final id = _nullableInt(row['transactionCategoryID']);
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  List<Map<String, Object?>> _listCategoryLimits(Map<String, Object?> payload) {
    bool matches(String key) {
      final filter = payload[key]?.toString();
      return filter == null || filter.isEmpty;
    }

    return previewCopyRows(
      state.limits.where((row) {
        if (!matches('transactionType') &&
            row['transactionType']?.toString() !=
                payload['transactionType']?.toString()) {
          return false;
        }
        if (!matches('window') &&
            row['window']?.toString() != payload['window']?.toString()) {
          return false;
        }
        if (!matches('periodKey') &&
            row['periodKey']?.toString() != payload['periodKey']?.toString()) {
          return false;
        }
        return true;
      }),
    );
  }

  Map<String, Object?> _upsertCategoryLimit(Map<String, Object?> payload) {
    final nowMillis = state.now.millisecondsSinceEpoch;
    final index = state.limits.indexWhere(
      (row) =>
          row['targetType']?.toString() == payload['targetType']?.toString() &&
          _nullableInt(row['targetId']) == _nullableInt(payload['targetId']) &&
          row['transactionType']?.toString() ==
              payload['transactionType']?.toString() &&
          row['window']?.toString() == payload['window']?.toString() &&
          row['periodKey']?.toString() == payload['periodKey']?.toString(),
    );
    final existing = index < 0 ? null : state.limits[index];
    final row = <String, Object?>{
      'id': existing?['id'] ?? state.takeLimitId(),
      'targetType': payload['targetType']?.toString() ?? 'category',
      'targetId': _int(payload['targetId'], 0),
      'transactionType': payload['transactionType']?.toString() ?? 'expense',
      'window': payload['window']?.toString() ?? 'monthly',
      'periodKey': payload['periodKey']?.toString() ?? 'all',
      'hasLimit': _bool(payload['hasLimit']),
      'limitAmount': _double(payload['limitAmount']),
      'alertActive': _bool(payload['alertActive']),
      'createdAt': existing?['createdAt'] ?? nowMillis,
      'updatedAt': nowMillis,
    };
    if (index < 0) {
      state.limits.add(row);
    } else {
      state.limits[index] = row;
    }
    return previewDeepCopyMap(row);
  }

  bool _deleteTransaction(Map<String, Object?> payload) {
    final id = _requiredId(payload);
    final before = state.transactions.length;
    state.transactions.removeWhere((row) => row['id'] == id);
    return state.transactions.length != before;
  }

  int _renameTransactionsByMerchant(Map<String, Object?> payload) {
    final merchant = payload['originalMerchant']?.toString() ?? '';
    final name = payload['userAssignedName']?.toString() ?? '';
    var count = 0;
    for (final row in state.transactions) {
      if (row['merchant'] == merchant) {
        row['userAssignedName'] = name;
        count += 1;
      }
    }
    return count;
  }

  int _resetTransactionNamesByMerchant(Map<String, Object?> payload) {
    final merchant = payload['originalMerchant']?.toString() ?? '';
    var count = 0;
    for (final row in state.transactions) {
      if (row['merchant'] == merchant) {
        row['userAssignedName'] = null;
        count += 1;
      }
    }
    return count;
  }
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

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(Object? value) =>
    value == true || value == 1 || value?.toString() == 'true';

String _hungarianType(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == 'income' || normalized == 'bevétel'
      ? 'bevétel'
      : 'kiadás';
}

String _formatDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

int _compareTransactionsDescending(
  Map<String, Object?> left,
  Map<String, Object?> right,
) {
  final date = right['date'].toString().compareTo(left['date'].toString());
  if (date != 0) return date;
  final time = right['time'].toString().compareTo(left['time'].toString());
  if (time != 0) return time;
  return _int(right['id']).compareTo(_int(left['id']));
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
