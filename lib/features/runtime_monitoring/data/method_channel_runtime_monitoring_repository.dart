import 'package:flutter/services.dart';

import '../domain/runtime_monitoring_repository.dart';

final class MethodChannelRuntimeMonitoringRepository
    implements RuntimeMonitoringRepository {
  MethodChannelRuntimeMonitoringRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.fluvi/runtime_monitoring');

  final MethodChannel _channel;

  @override
  Future<RuntimeMonitoringStatus> status() => _status('getRuntimeStatus');

  @override
  Future<RuntimeMonitoringStatus> setBackgroundRequested(bool requested) =>
      _status('setBackgroundRequested', {'requested': requested});

  @override
  Future<RuntimeMonitoringStatus> setForegroundRequested(bool requested) =>
      _status('setForegroundRequested', {'requested': requested});

  @override
  Future<RuntimeMonitoringStatus> stopMonitoring() => _status('stopMonitoring');

  Future<RuntimeMonitoringStatus> _status(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final raw = await _channel.invokeMethod<Object?>(method, arguments);
    return RuntimeMonitoringStatus.fromMap(
      raw is Map<Object?, Object?>
          ? raw
          : Map<Object?, Object?>.from(raw! as Map),
    );
  }
}
