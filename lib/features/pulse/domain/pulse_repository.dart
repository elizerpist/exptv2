import 'pulse_models.dart';

abstract interface class PulseRepository {
  Future<PulseDashboardSnapshot> dashboard({
    required int year,
    required int month,
  });

  Future<List<PulseSignalInspection>> signalInspection({
    required int year,
    required int month,
    required String indicatorId,
    int historyLimit = 30,
  });

  Future<PulseSituationInspection> triageInspection({
    required int year,
    required int month,
    required String situationKey,
    int historyLimit = 30,
    int historyOffset = 0,
  });

  Future<PulsePriorityInspection> priorityInspection({
    required int year,
    required int month,
    int historyLimit = 30,
    int historyOffset = 0,
  });

  Future<PulseStoryInspection> selectedStoryPreview({
    required int year,
    required int month,
  });

  Future<PulseStoryInspection> candidateStoryPreview({
    required int year,
    required int month,
    required String situationKey,
  });

  Future<PulseStoryInspection> storyInspection({
    required int year,
    required int month,
    required String situationKey,
  });

  Future<PulseDeliveryDecision> deliveryDecision({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
  });

  Future<PulseDeliveryInspection> deliveryInspection({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
    int historyLimit = 30,
    int historyOffset = 0,
  });

  Future<PulseDeliveryPreferences> deliveryPreferences();

  Future<PulseHeaderPresentationReservation?> reserveHeaderPresentation({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
    required String commandKey,
  });

  Future<bool> reportPresentationStarted({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  });

  Future<bool> reportPresented({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  });

  Future<bool> confirmQualifiedExposure({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  });

  Future<bool> finishPresentation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    String reason = 'readable-duration-ended',
  });

  Future<bool> cancelPresentation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required String reason,
  });

  Future<bool> dismissStory({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required String commandKey,
  });

  Future<bool> snoozeSituation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required int untilUtcMs,
    required String commandKey,
  });

  Future<void> muteDeliveryTarget({
    required String targetScope,
    required String commandKey,
  });

  Future<bool> unmuteDeliveryTarget({
    required String targetScope,
    required String commandKey,
  });

  Future<bool> clearDeliveryControl({
    required String controlId,
    required String commandKey,
  });

  Future<PulseDeliveryPreferences> updateDeliveryPreferences({
    required bool automaticEnabled,
    required int normalCooldownMillis,
    required String commandKey,
  });

  Future<void> setSubscriptionSource({
    required String targetKey,
    required bool selected,
  });

  Future<void> setThreshold({
    required String indicatorId,
    required String thresholdKey,
    required double value,
    String targetKey = '',
  });

  Future<void> resetThreshold({
    required String indicatorId,
    required String thresholdKey,
    String targetKey = '',
  });
}
