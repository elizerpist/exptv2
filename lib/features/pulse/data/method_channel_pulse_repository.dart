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
    _map(
      await _channel.invokeMethod<Object?>('getDashboard', {
        'year': year,
        'month': month,
      }),
    ),
  );

  @override
  Future<List<PulseSignalInspection>> signalInspection({
    required int year,
    required int month,
    required String indicatorId,
    int historyLimit = 30,
  }) async {
    final result = _map(
      await _channel.invokeMethod<Object?>('getSignalInspection', {
        'year': year,
        'month': month,
        'indicatorId': indicatorId,
        'historyLimit': historyLimit,
      }),
    );
    return (result['signals'] as List<Object?>? ?? const [])
        .map((item) => PulseSignalInspection.fromMap(_map(item)))
        .toList(growable: false);
  }

  @override
  Future<PulseSituationInspection> triageInspection({
    required int year,
    required int month,
    required String situationKey,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async => PulseSituationInspection.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('getTriageInspection', {
        'year': year,
        'month': month,
        'situationKey': situationKey,
        'historyLimit': historyLimit,
        'historyOffset': historyOffset,
      }),
    ),
  );

  @override
  Future<PulsePriorityInspection> priorityInspection({
    required int year,
    required int month,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async => PulsePriorityInspection.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('getPriorityInspection', {
        'year': year,
        'month': month,
        'historyLimit': historyLimit,
        'historyOffset': historyOffset,
      }),
    ),
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
