import '../../../models/notification_event.dart';

enum PushNotificationLogStatus {
  all('all', 'Összes'),
  linked('linked', 'Van tranzakció'),
  missing('missing', 'Nincs hozzárendelt log'),
  system('system', 'Rendszer');

  const PushNotificationLogStatus(this.nativeValue, this.label);

  final String nativeValue;
  final String label;

  static PushNotificationLogStatus fromNative(Object? value) {
    final text = value?.toString();
    for (final status in PushNotificationLogStatus.values) {
      if (status.nativeValue == text) return status;
    }
    return PushNotificationLogStatus.missing;
  }
}

class PushNotificationLogQuery {
  const PushNotificationLogQuery({
    this.limit = 60,
    this.offset = 0,
    this.year,
    this.month,
    this.query = '',
    this.status = PushNotificationLogStatus.all,
    this.packageName,
  });

  final int limit;
  final int offset;
  final int? year;
  final int? month;
  final String query;
  final PushNotificationLogStatus status;
  final String? packageName;

  static const Object _noChange = Object();

  Map<String, Object?> toMap() => <String, Object?>{
    'limit': limit,
    'offset': offset,
    'year': year,
    'month': month,
    'query': query,
    'status': status.nativeValue,
    'packageName': packageName,
  };

  PushNotificationLogQuery copyWith({
    int? limit,
    int? offset,
    Object? year = _noChange,
    Object? month = _noChange,
    String? query,
    PushNotificationLogStatus? status,
    Object? packageName = _noChange,
  }) {
    return PushNotificationLogQuery(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      year: identical(year, _noChange) ? this.year : year as int?,
      month: identical(month, _noChange) ? this.month : month as int?,
      query: query ?? this.query,
      status: status ?? this.status,
      packageName: identical(packageName, _noChange)
          ? this.packageName
          : packageName as String?,
    );
  }
}

class PushNotificationLogPage {
  const PushNotificationLogPage({
    required this.events,
    required this.totalCount,
    required this.limit,
    required this.offset,
  });

  final List<PushNotificationLogEvent> events;
  final int totalCount;
  final int limit;
  final int offset;
}

class PushNotificationLogEvent {
  const PushNotificationLogEvent({
    required this.base,
    required this.displayText,
    required this.status,
    required this.statusText,
    required this.linkedTransactionId,
    required this.manualStatus,
  });

  final NotificationEvent base;
  final String displayText;
  final PushNotificationLogStatus status;
  final String statusText;
  final int? linkedTransactionId;
  final String manualStatus;

  int get id => base.id;
  DateTime get timestamp => base.timestamp;
  String get sourceBadge => base.sourceBadge;
  String get displayApp => base.displayApp;
  bool get hasLinkedTransaction => linkedTransactionId != null;
  String get fullText =>
      displayText.trim().isNotEmpty ? displayText : base.bodyText;

  factory PushNotificationLogEvent.fromMap(Map<dynamic, dynamic> map) {
    final status = PushNotificationLogStatus.fromNative(map['status']);
    return PushNotificationLogEvent(
      base: NotificationEvent.fromMap(map),
      displayText: map['displayText']?.toString() ?? '',
      status: status,
      statusText: map['statusText']?.toString() ?? status.label,
      linkedTransactionId: _nullableInt(map['linkedTransactionId']),
      manualStatus: map['manualStatus']?.toString() ?? '',
    );
  }
}

int _readInt(Object? value) =>
    value is int ? value : int.parse(value.toString());
int? _nullableInt(Object? value) => value == null ? null : _readInt(value);
