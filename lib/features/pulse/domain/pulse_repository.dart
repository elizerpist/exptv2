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
