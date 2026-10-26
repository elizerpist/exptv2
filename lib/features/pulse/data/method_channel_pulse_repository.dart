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
  Future<PulseStoryInspection> selectedStoryPreview({
    required int year,
    required int month,
  }) async => PulseStoryInspection.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('getSelectedStoryPreview', {
        'year': year,
        'month': month,
      }),
    ),
  );

  @override
  Future<PulseStoryInspection> candidateStoryPreview({
    required int year,
    required int month,
    required String situationKey,
  }) async => PulseStoryInspection.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('getCandidateStoryPreview', {
        'year': year,
        'month': month,
        'situationKey': situationKey,
      }),
    ),
  );

  @override
  Future<PulseStoryInspection> storyInspection({
    required int year,
    required int month,
    required String situationKey,
  }) async => PulseStoryInspection.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('getStoryInspection', {
        'year': year,
        'month': month,
        'situationKey': situationKey,
      }),
    ),
  );

  @override
  Future<PulseDeliveryDecision> deliveryDecision({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
  }) async => PulseDeliveryDecision.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('getDeliveryDecision', {
        'year': year,
        'month': month,
        'surface': surface.toMap(),
      }),
    ),
  );

  @override
  Future<PulseDeliveryInspection> deliveryInspection({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async => PulseDeliveryInspection.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('getDeliveryInspection', {
        'year': year,
        'month': month,
        'surface': surface.toMap(),
        'historyLimit': historyLimit,
        'historyOffset': historyOffset,
      }),
    ),
  );

  @override
  Future<PulseDeliveryPreferences> deliveryPreferences() async =>
      PulseDeliveryPreferences.fromMap(
        _map(await _channel.invokeMethod<Object?>('getDeliveryPreferences')),
      );

  @override
  Future<PulseHeaderPresentationReservation?> reserveHeaderPresentation({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
    required String commandKey,
  }) async {
    final response = await _channel.invokeMethod<Object?>(
      'reserveHeaderPresentation',
      {
        'year': year,
        'month': month,
        'surface': surface.toMap(),
        'commandKey': commandKey,
      },
    );
    return response == null
        ? null
        : PulseHeaderPresentationReservation.fromMap(_map(response));
  }

  @override
  Future<bool> reportPresentationStarted({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async =>
      (await _channel.invokeMethod<bool>('reportPresentationStarted', {
        'attemptId': attemptId,
        'leaseToken': leaseToken,
        'hostSessionId': hostSessionId,
        'contentFingerprint': contentFingerprint,
      })) ??
      false;

  @override
  Future<bool> reportPresented({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async =>
      (await _channel.invokeMethod<bool>('reportPresented', {
        'attemptId': attemptId,
        'leaseToken': leaseToken,
        'hostSessionId': hostSessionId,
        'contentFingerprint': contentFingerprint,
      })) ??
      false;

  @override
  Future<bool> confirmQualifiedExposure({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async =>
      await _channel.invokeMethod<Object?>('confirmQualifiedExposure', {
        'attemptId': attemptId,
        'leaseToken': leaseToken,
        'hostSessionId': hostSessionId,
        'contentFingerprint': contentFingerprint,
      }) !=
      null;

  @override
  Future<bool> finishPresentation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    String reason = 'readable-duration-ended',
  }) async =>
      (await _channel.invokeMethod<bool>('finishPresentation', {
        'attemptId': attemptId,
        'leaseToken': leaseToken,
        'hostSessionId': hostSessionId,
        'contentFingerprint': contentFingerprint,
        'reason': reason,
      })) ??
      false;

  @override
  Future<bool> cancelPresentation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required String reason,
  }) async =>
      (await _channel.invokeMethod<bool>('cancelPresentation', {
        'attemptId': attemptId,
        'leaseToken': leaseToken,
        'hostSessionId': hostSessionId,
        'contentFingerprint': contentFingerprint,
        'reason': reason,
      })) ??
      false;

  @override
  Future<bool> dismissStory({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required String commandKey,
  }) async =>
      (await _channel.invokeMethod<bool>('dismissStory', {
        'attemptId': attemptId,
        'leaseToken': leaseToken,
        'hostSessionId': hostSessionId,
        'contentFingerprint': contentFingerprint,
        'commandKey': commandKey,
      })) ??
      false;

  @override
  Future<bool> snoozeSituation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required int untilUtcMs,
    required String commandKey,
  }) async =>
      (await _channel.invokeMethod<bool>('snoozeSituation', {
        'attemptId': attemptId,
        'leaseToken': leaseToken,
        'hostSessionId': hostSessionId,
        'contentFingerprint': contentFingerprint,
        'untilUtcMs': untilUtcMs,
        'commandKey': commandKey,
      })) ??
      false;

  @override
  Future<void> muteDeliveryTarget({
    required String targetScope,
    required String commandKey,
  }) => _channel.invokeMethod<void>('muteDeliveryTarget', {
    'targetScope': targetScope,
    'commandKey': commandKey,
  });

  @override
  Future<bool> unmuteDeliveryTarget({
    required String targetScope,
    required String commandKey,
  }) async =>
      (await _channel.invokeMethod<bool>('unmuteDeliveryTarget', {
        'targetScope': targetScope,
        'commandKey': commandKey,
      })) ??
      false;

  @override
  Future<bool> clearDeliveryControl({
    required String controlId,
    required String commandKey,
  }) async =>
      (await _channel.invokeMethod<bool>('clearDeliveryControl', {
        'controlId': controlId,
        'commandKey': commandKey,
      })) ??
      false;

  @override
  Future<PulseDeliveryPreferences> updateDeliveryPreferences({
    required bool automaticEnabled,
    required int normalCooldownMillis,
    required String commandKey,
  }) async => PulseDeliveryPreferences.fromMap(
    _map(
      await _channel.invokeMethod<Object?>('updateDeliveryPreferences', {
        'automaticEnabled': automaticEnabled,
        'normalCooldownMillis': normalCooldownMillis,
        'commandKey': commandKey,
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
