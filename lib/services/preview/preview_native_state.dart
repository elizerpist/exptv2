import 'dart:async';

import 'preview_fixture_data.dart';

class PreviewNativeState {
  PreviewNativeState.seeded({DateTime? now}) : _now = now ?? DateTime.now() {
    reset();
  }

  final DateTime _now;
  late List<Map<String, Object?>> categories;
  late List<Map<String, Object?>> transactions;
  late List<Map<String, Object?>> limits;
  late List<Map<String, Object?>> recurringTransactions;
  late List<Map<String, Object?>> recurringRules;
  late List<Map<String, Object?>> recurringGhosts;
  late List<Map<String, Object?>> notificationCards;
  late List<Map<String, Object?>> notificationEvents;
  late List<Map<String, Object?>> pushLogEvents;
  late List<Map<String, Object?>> statsSnapshots;
  late Map<String, Object?> themeSettings;
  late Map<String, Object?> fastInfoConfig;
  late Map<String, Object?> pushRecurringSettings;
  late Map<String, Object?> notificationSettings;
  late Map<String, Object?> securitySettings;
  late Map<String, Object?> notificationParserConfig;
  bool automaticPushParserEnabled = true;
  String? lastExportFileName;
  String? lastExportMimeType;
  String? lastExportContent;
  int _nextTransactionId = 1;
  int _nextCategoryId = 1;
  int _nextLimitId = 1;
  int _nextRecurringId = 1;
  int _nextRuleId = 1;

  final StreamController<Object?> eventController =
      StreamController<Object?>.broadcast();

  DateTime get now => _now;

  void reset() {
    final fixture = buildPreviewFixtureData(_now);
    categories = previewCopyRows(fixture.categories);
    transactions = previewCopyRows(fixture.transactions);
    limits = previewCopyRows(fixture.limits);
    recurringTransactions = previewCopyRows(fixture.recurringTransactions);
    recurringRules = previewCopyRows(fixture.recurringRules);
    recurringGhosts = previewCopyRows(fixture.recurringGhosts);
    notificationCards = previewCopyRows(fixture.notificationCards);
    notificationEvents = previewCopyRows(fixture.notificationEvents);
    pushLogEvents = previewCopyRows(fixture.pushLogEvents);
    statsSnapshots = previewCopyRows(fixture.statsSnapshots);
    themeSettings = previewDeepCopyMap(fixture.themeSettings);
    fastInfoConfig = previewDeepCopyMap(fixture.fastInfoConfig);
    pushRecurringSettings = previewDeepCopyMap(fixture.pushRecurringSettings);
    notificationSettings = previewDeepCopyMap(fixture.notificationSettings);
    securitySettings = previewDeepCopyMap(fixture.securitySettings);
    notificationParserConfig = previewDeepCopyMap(
      fixture.notificationParserConfig,
    );
    automaticPushParserEnabled = true;
    lastExportFileName = null;
    lastExportMimeType = null;
    lastExportContent = null;
    _nextTransactionId = _nextId(transactions, 'id');
    _nextCategoryId = _nextId(categories, 'transactionCategoryID');
    _nextLimitId = _nextId(limits, 'id');
    _nextRecurringId = _nextId(recurringTransactions, 'id');
    _nextRuleId = _nextId(recurringRules, 'id');
  }

  int takeTransactionId() => _nextTransactionId++;
  int takeCategoryId() => _nextCategoryId++;
  int takeLimitId() => _nextLimitId++;
  int takeRecurringId() => _nextRecurringId++;
  int takeRuleId() => _nextRuleId++;

  Future<void> dispose() => eventController.close();
}

List<Map<String, Object?>> previewCopyRows(
  Iterable<Map<String, Object?>> rows,
) => rows.map(previewDeepCopyMap).toList();

Map<String, Object?> previewDeepCopyMap(Map<dynamic, dynamic> source) =>
    source.map((key, value) => MapEntry(key.toString(), _deepCopy(value)));

Object? _deepCopy(Object? value) {
  if (value is Map) return previewDeepCopyMap(value);
  if (value is List) return value.map(_deepCopy).toList();
  return value;
}

int _nextId(List<Map<String, Object?>> rows, String key) {
  var largest = 0;
  for (final row in rows) {
    final value = row[key];
    final id = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    if (id > largest) largest = id;
  }
  return largest + 1;
}
