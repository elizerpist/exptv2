enum CaptureMode {
  notificationListener('notification_listener'),
  accessibility('accessibility'),
  both('both');

  const CaptureMode(this.nativeValue);
  final String nativeValue;

  static CaptureMode fromNative(String value) {
    return CaptureMode.values.firstWhere(
      (mode) => mode.nativeValue == value,
      orElse: () => CaptureMode.both,
    );
  }
}

class ServiceStatus {
  const ServiceStatus({
    required this.captureMode,
    required this.notificationListenerEnabled,
    required this.accessibilityEnabled,
    required this.notificationListenerActive,
    required this.accessibilityActive,
    required this.lastNotificationListenerEvent,
    required this.lastAccessibilityEvent,
    required this.totalEvents,
  });

  final CaptureMode captureMode;
  final bool notificationListenerEnabled;
  final bool accessibilityEnabled;
  final bool notificationListenerActive;
  final bool accessibilityActive;
  final DateTime? lastNotificationListenerEvent;
  final DateTime? lastAccessibilityEvent;
  final int totalEvents;

  factory ServiceStatus.fromMap(Map<dynamic, dynamic> map) {
    DateTime? readMillis(String key) {
      final value = map[key];
      if (value is! num || value <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    return ServiceStatus(
      captureMode: CaptureMode.fromNative(
        (map['captureMode'] as String?) ?? 'both',
      ),
      notificationListenerEnabled: map['notificationListenerEnabled'] == true,
      accessibilityEnabled: map['accessibilityEnabled'] == true,
      notificationListenerActive: map['notificationListenerActive'] == true,
      accessibilityActive: map['accessibilityActive'] == true,
      lastNotificationListenerEvent: readMillis(
        'lastNotificationListenerEvent',
      ),
      lastAccessibilityEvent: readMillis('lastAccessibilityEvent'),
      totalEvents: ((map['totalEvents'] as num?) ?? 0).toInt(),
    );
  }
}
