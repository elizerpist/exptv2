import 'dart:async';

import 'package:flutter/services.dart';

import '../models/installed_app.dart';
import '../models/notification_event.dart';
import '../models/service_status.dart';

class NativeBridge {
  NativeBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel('pushparser/methods'),
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
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>('getStatus');
    return ServiceStatus.fromMap(map ?? <dynamic, dynamic>{});
  }

  Future<List<InstalledApp>> listInstalledApps() async {
    final rows = await _methodChannel.invokeListMethod<dynamic>('listInstalledApps');
    return (rows ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(InstalledApp.fromMap)
        .toList();
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
