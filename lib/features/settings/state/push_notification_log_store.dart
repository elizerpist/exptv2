import 'package:flutter/foundation.dart';

import '../../../services/native_bridge.dart';
import '../../../state/event_store.dart';
import '../../transactions/models/transaction_category.dart';
import '../models/notification_parser_rule.dart';
import '../models/push_notification_log_event.dart';

class PushNotificationLogStore extends ChangeNotifier {
  PushNotificationLogStore({
    required NativeBridge bridge,
    required EventStore parserStore,
  }) : _bridge = bridge,
       _parserStore = parserStore;

  static const pageSize = 60;
  static const Object _noChange = Object();

  final NativeBridge _bridge;
  final EventStore _parserStore;
  final List<PushNotificationLogEvent> _events = <PushNotificationLogEvent>[];

  PushNotificationLogQuery _query = const PushNotificationLogQuery(
    limit: pageSize,
  );
  bool _loading = false;
  bool _loadingMore = false;
  int _totalCount = 0;
  String? _errorText;

  List<PushNotificationLogEvent> get events => List.unmodifiable(_events);
  PushNotificationLogQuery get query => _query;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  int get totalCount => _totalCount;
  String? get errorText => _errorText;
  bool get hasMore => _events.length < _totalCount;

  Future<void> loadFirstPage() async {
    _loading = true;
    _errorText = null;
    notifyListeners();
    try {
      final page = await _bridge.loadNotificationEventPage(
        _query.copyWith(limit: pageSize, offset: 0),
      );
      _events
        ..clear()
        ..addAll(page.events);
      _totalCount = page.totalCount;
      _query = _query.copyWith(limit: pageSize, offset: 0);
    } catch (error) {
      _errorText = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _bridge.loadNotificationEventPage(
        _query.copyWith(limit: pageSize, offset: _events.length),
      );
      _events.addAll(page.events);
      _totalCount = page.totalCount;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setFilters({
    Object? year = _noChange,
    Object? month = _noChange,
    String? query,
    PushNotificationLogStatus? status,
    Object? packageName = _noChange,
  }) async {
    _query = _query.copyWith(
      limit: pageSize,
      offset: 0,
      year: year,
      month: month,
      query: query,
      status: status,
      packageName: packageName,
    );
    await loadFirstPage();
  }

  Future<void> markSystem(PushNotificationLogEvent event) async {
    final updated = await _bridge.markNotificationEventSystem(event.id);
    if (!updated) return;
    await loadFirstPage();
  }

  Future<void> trainAndCreateTransaction({
    required PushNotificationLogEvent event,
    required NotificationParserProfile trainedProfile,
  }) async {
    final preview = trainedProfile.preview;
    if (!preview.isReady ||
        preview.amountValue == null ||
        preview.merchant == null) {
      throw StateError(preview.errorText ?? 'Érvénytelen parser előnézet');
    }
    await _parserStore.saveTrainedNotificationParserProfile(trainedProfile);
    await _bridge.expenseAddTransaction(<String, Object?>{
      'merchant': preview.merchant,
      'amount': preview.amountValue,
      'type': preview.transactionType.nativeValue,
      'transactionCategoryID': null,
      'date': _formatDate(event.timestamp),
      'time': _formatTime(event.timestamp),
      'address': 'Push notification',
      'sourceNotificationEventId': event.id,
    });
    await loadFirstPage();
  }
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.'
      '${value.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
