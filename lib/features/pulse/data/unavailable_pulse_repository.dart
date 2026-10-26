import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';

final class UnavailablePulseRepository implements PulseRepository {
  const UnavailablePulseRepository();

  Never _unavailable() =>
      throw UnsupportedError('Pulse nem érhető el ezen a platformon.');

  @override
  Future<PulseDashboardSnapshot> dashboard({
    required int year,
    required int month,
  }) async => _unavailable();

  @override
  Future<List<PulseSignalInspection>> signalInspection({
    required int year,
    required int month,
    required String indicatorId,
    int historyLimit = 30,
  }) async => _unavailable();

  @override
  Future<PulseSituationInspection> triageInspection({
    required int year,
    required int month,
    required String situationKey,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async => _unavailable();

  @override
  Future<PulsePriorityInspection> priorityInspection({
    required int year,
    required int month,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async => _unavailable();

  @override
  Future<PulseStoryInspection> selectedStoryPreview({
    required int year,
    required int month,
  }) async => _unavailable();

  @override
  Future<PulseStoryInspection> candidateStoryPreview({
    required int year,
    required int month,
    required String situationKey,
  }) async => _unavailable();

  @override
  Future<PulseStoryInspection> storyInspection({
    required int year,
    required int month,
    required String situationKey,
  }) async => _unavailable();

  @override
  Future<PulseDeliveryDecision> deliveryDecision({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
  }) async => _unavailable();

  @override
  Future<PulseDeliveryInspection> deliveryInspection({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
    int historyLimit = 30,
    int historyOffset = 0,
  }) async => _unavailable();

  @override
  Future<PulseDeliveryPreferences> deliveryPreferences() async =>
      _unavailable();

  @override
  Future<PulseHeaderPresentationReservation?> reserveHeaderPresentation({
    required int year,
    required int month,
    required PulseDeliverySurfaceContext surface,
    required String commandKey,
  }) async => _unavailable();

  @override
  Future<bool> reportPresentationStarted({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async => _unavailable();

  @override
  Future<bool> reportPresented({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async => _unavailable();

  @override
  Future<bool> confirmQualifiedExposure({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
  }) async => _unavailable();

  @override
  Future<bool> finishPresentation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    String reason = 'readable-duration-ended',
  }) async => _unavailable();

  @override
  Future<bool> cancelPresentation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required String reason,
  }) async => _unavailable();

  @override
  Future<bool> dismissStory({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required String commandKey,
  }) async => _unavailable();

  @override
  Future<bool> snoozeSituation({
    required String attemptId,
    required String leaseToken,
    required String hostSessionId,
    required String contentFingerprint,
    required int untilUtcMs,
    required String commandKey,
  }) async => _unavailable();

  @override
  Future<void> muteDeliveryTarget({
    required String targetScope,
    required String commandKey,
  }) async => _unavailable();

  @override
  Future<bool> unmuteDeliveryTarget({
    required String targetScope,
    required String commandKey,
  }) async => _unavailable();

  @override
  Future<bool> clearDeliveryControl({
    required String controlId,
    required String commandKey,
  }) async => _unavailable();

  @override
  Future<PulseDeliveryPreferences> updateDeliveryPreferences({
    required bool automaticEnabled,
    required int normalCooldownMillis,
    required String commandKey,
  }) async => _unavailable();

  @override
  Future<void> setSubscriptionSource({
    required String targetKey,
    required bool selected,
  }) async => _unavailable();

  @override
  Future<void> resetThreshold({
    required String indicatorId,
    required String thresholdKey,
    String targetKey = '',
  }) async => _unavailable();

  @override
  Future<void> setThreshold({
    required String indicatorId,
    required String thresholdKey,
    required double value,
    String targetKey = '',
  }) async => _unavailable();
}
