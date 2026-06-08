class NotificationSettings {
  const NotificationSettings({
    required this.androidPushEnabled,
    required this.inAppCardsEnabled,
    required this.limitAlertsEnabled,
    required this.recurringAlertsEnabled,
    required this.transactionAlertsEnabled,
  });

  final bool androidPushEnabled;
  final bool inAppCardsEnabled;
  final bool limitAlertsEnabled;
  final bool recurringAlertsEnabled;
  final bool transactionAlertsEnabled;

  factory NotificationSettings.defaults() => const NotificationSettings(
    androidPushEnabled: true,
    inAppCardsEnabled: true,
    limitAlertsEnabled: true,
    recurringAlertsEnabled: true,
    transactionAlertsEnabled: true,
  );

  factory NotificationSettings.fromMap(Map<dynamic, dynamic> map) {
    return NotificationSettings(
      androidPushEnabled: _bool(map['androidPushEnabled'], true),
      inAppCardsEnabled: _bool(map['inAppCardsEnabled'], true),
      limitAlertsEnabled: _bool(map['limitAlertsEnabled'], true),
      recurringAlertsEnabled: _bool(map['recurringAlertsEnabled'], true),
      transactionAlertsEnabled: _bool(map['transactionAlertsEnabled'], true),
    );
  }

  NotificationSettings copyWith({
    bool? androidPushEnabled,
    bool? inAppCardsEnabled,
    bool? limitAlertsEnabled,
    bool? recurringAlertsEnabled,
    bool? transactionAlertsEnabled,
  }) {
    return NotificationSettings(
      androidPushEnabled: androidPushEnabled ?? this.androidPushEnabled,
      inAppCardsEnabled: inAppCardsEnabled ?? this.inAppCardsEnabled,
      limitAlertsEnabled: limitAlertsEnabled ?? this.limitAlertsEnabled,
      recurringAlertsEnabled:
          recurringAlertsEnabled ?? this.recurringAlertsEnabled,
      transactionAlertsEnabled:
          transactionAlertsEnabled ?? this.transactionAlertsEnabled,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'androidPushEnabled': androidPushEnabled,
    'inAppCardsEnabled': inAppCardsEnabled,
    'limitAlertsEnabled': limitAlertsEnabled,
    'recurringAlertsEnabled': recurringAlertsEnabled,
    'transactionAlertsEnabled': transactionAlertsEnabled,
  };
}

bool _bool(Object? value, bool fallback) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return fallback;
}
