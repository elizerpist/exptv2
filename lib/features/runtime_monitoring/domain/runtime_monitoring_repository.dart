abstract interface class RuntimeMonitoringRepository {
  Future<RuntimeMonitoringStatus> status();
  Future<RuntimeMonitoringStatus> setForegroundRequested(bool requested);
  Future<RuntimeMonitoringStatus> setBackgroundRequested(bool requested);
  Future<RuntimeMonitoringStatus> stopMonitoring();
}

final class RuntimeMonitoringStatus {
  const RuntimeMonitoringStatus({
    required this.foregroundRequested,
    required this.backgroundRequested,
    required this.foregroundServiceRunning,
    required this.notificationListenerGranted,
    required this.listenerConnected,
    required this.postNotificationsGranted,
    required this.statusChannelEnabled,
    required this.appSurfaceVisible,
    required this.stoppedByUser,
    required this.captureAllowed,
    required this.state,
    required this.message,
    this.lastReceivedAtUtcMs,
    this.lastProcessedAtUtcMs,
    this.lastWidgetRefreshAtUtcMs,
  });

  factory RuntimeMonitoringStatus.fromMap(
    Map<Object?, Object?> map,
  ) => RuntimeMonitoringStatus(
    foregroundRequested: map['foregroundRequested'] as bool? ?? false,
    backgroundRequested: map['backgroundRequested'] as bool? ?? false,
    foregroundServiceRunning: map['foregroundServiceRunning'] as bool? ?? false,
    notificationListenerGranted:
        map['notificationListenerGranted'] as bool? ?? false,
    listenerConnected: map['listenerConnected'] as bool? ?? false,
    postNotificationsGranted: map['postNotificationsGranted'] as bool? ?? false,
    statusChannelEnabled: map['statusChannelEnabled'] as bool? ?? true,
    appSurfaceVisible: map['appSurfaceVisible'] as bool? ?? false,
    stoppedByUser: map['stoppedByUser'] as bool? ?? false,
    captureAllowed: map['captureAllowed'] as bool? ?? false,
    state: map['state'] as String? ?? 'unsupported',
    message: map['message'] as String? ?? 'Nem elérhető',
    lastReceivedAtUtcMs: (map['lastReceivedAtUtcMs'] as num?)?.toInt(),
    lastProcessedAtUtcMs: (map['lastProcessedAtUtcMs'] as num?)?.toInt(),
    lastWidgetRefreshAtUtcMs: (map['lastWidgetRefreshAtUtcMs'] as num?)
        ?.toInt(),
  );

  final bool foregroundRequested;
  final bool backgroundRequested;
  final bool foregroundServiceRunning;
  final bool notificationListenerGranted;
  final bool listenerConnected;
  final bool postNotificationsGranted;
  final bool statusChannelEnabled;
  final bool appSurfaceVisible;
  final bool stoppedByUser;
  final bool captureAllowed;
  final String state;
  final String message;
  final int? lastReceivedAtUtcMs;
  final int? lastProcessedAtUtcMs;
  final int? lastWidgetRefreshAtUtcMs;
}
