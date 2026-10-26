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
