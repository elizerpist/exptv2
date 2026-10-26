import 'pulse_models.dart';

abstract interface class PulseRepository {
  Future<PulseDashboardSnapshot> dashboard({required int year, required int month});

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
