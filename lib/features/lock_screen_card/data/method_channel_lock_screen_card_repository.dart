import 'package:flutter/services.dart';

import '../domain/lock_screen_card_repository.dart';

final class MethodChannelLockScreenCardRepository
    implements LockScreenCardRepository {
  MethodChannelLockScreenCardRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.fluvi/runtime_monitoring');

  final MethodChannel _channel;

  @override
  Future<LockScreenCardStatus> load() => _read('getLockScreenCard');

  @override
  Future<LockScreenCardStatus> save(
    LockScreenCardConfiguration configuration,
  ) => _read('setLockScreenCard', configuration.toMap());

  @override
  Future<LockScreenCardStatus> saveWidget(
    FinancialSnapshotWidgetConfiguration configuration,
  ) => _read('setFinancialSnapshotWidget', configuration.toMap());

  @override
  Future<LockScreenCardStatus> saveNativeKeyguardCard(
    NativeKeyguardCardConfiguration configuration,
  ) => _read('setNativeKeyguardCard', configuration.toMap());

  @override
  Future<void> openNativeKeyguardSettings() =>
      _channel.invokeMethod<void>('openNativeKeyguardSettings');

  @override
  Future<void> openRuntimeNotificationChannelSettings() =>
      _channel.invokeMethod<void>('openRuntimeNotificationChannelSettings');

  Future<LockScreenCardStatus> _read(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final value = await _channel.invokeMethod<Object?>(method, arguments);
    final map = value is Map<Object?, Object?>
        ? value
        : Map<Object?, Object?>.from(value! as Map);
    return LockScreenCardStatus.fromMap(map);
  }
}
