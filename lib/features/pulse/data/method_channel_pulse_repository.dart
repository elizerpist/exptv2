import 'package:flutter/services.dart';

import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';

final class MethodChannelPulseRepository implements PulseRepository {
  MethodChannelPulseRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.fluvi/pulse');

  final MethodChannel _channel;

  @override
  Future<PulseDashboardSnapshot> dashboard({
    required int year,
    required int month,
  }) async => PulseDashboardSnapshot.fromMap(
    _map(await _channel.invokeMethod<Object?>('getDashboard', {
      'year': year,
      'month': month,
    })),
  );

  @override
  Future<void> setSubscriptionSource({
    required String targetKey,
    required bool selected,
  }) => _channel.invokeMethod<void>('setSubscriptionSource', {
    'targetKey': targetKey,
    'selected': selected,
  });

  @override
  Future<void> setThreshold({
    required String indicatorId,
    required String thresholdKey,
    required double value,
    String targetKey = '',
  }) => _channel.invokeMethod<void>('setThreshold', {
    'indicatorId': indicatorId,
    'targetKey': targetKey,
    'thresholdKey': thresholdKey,
    'value': value,
  });

  @override
  Future<void> resetThreshold({
    required String indicatorId,
    required String thresholdKey,
    String targetKey = '',
  }) => _channel.invokeMethod<void>('resetThreshold', {
    'indicatorId': indicatorId,
    'targetKey': targetKey,
    'thresholdKey': thresholdKey,
  });
}

Map<Object?, Object?> _map(Object? value) => value is Map<Object?, Object?>
    ? value
    : Map<Object?, Object?>.from(value! as Map);
