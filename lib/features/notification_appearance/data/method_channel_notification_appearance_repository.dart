import 'package:flutter/services.dart';

import '../domain/notification_appearance_repository.dart';

final class MethodChannelNotificationAppearanceRepository
    implements NotificationAppearanceRepository {
  MethodChannelNotificationAppearanceRepository({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.fluvi/notification_appearance');

  final MethodChannel _channel;

  @override
  Future<NotificationSmallIconStyle> smallIconStyle() =>
      _read('getNotificationSmallIconStyle');

  @override
  Future<NotificationSmallIconStyle> setSmallIconStyle(
    NotificationSmallIconStyle style,
  ) => _read('setNotificationSmallIconStyle', {'style': style.storageValue});

  Future<NotificationSmallIconStyle> _read(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final value = await _channel.invokeMethod<Object?>(method, arguments);
    // A malformed or older native bridge response must not make a missing
    // appearance preference look like a successfully selected filled icon.
    // Native uses the same outline fallback, so both sides stay deterministic.
    if (value is! Map) return NotificationSmallIconStyle.outline;
    final map = Map<Object?, Object?>.from(value);
    return NotificationSmallIconStyle.fromStorage(map['style']);
  }
}
