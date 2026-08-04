/// Fixed diagnostic slots for the dashboard interaction lane.
///
/// The enum is deliberately closed: recording cannot grow a map or retain a
/// query key, scope, row or callback. Profile tooling may take an immutable
/// snapshot outside the hot path when it needs to serialize the values.
enum DashboardPerformanceMetric {
  parentBundleLookup,
  parentBundleHit,
  parentBundleMiss,
  repositoryRead,
  oneShotRead,
  exactWatchStart,
  liveLeaseRequest,
  liveLeaseActivation,
  coreRevisionSubscription,
  backgroundJobStarted,
  backgroundJobCompleted,
  backgroundJobDeduplicated,
  backgroundJobSuperseded,
  dashboardRootBuild,
  summaryPillBuild,
  railBuild,
  logBoxBuild,
  logProjection,
  logRowBuild,
  amountAnimationStarted,
}

/// One allocation-bounded owner for numeric dashboard performance evidence.
class DashboardPerformanceCounters {
  DashboardPerformanceCounters()
    : _values = List<int>.filled(
        DashboardPerformanceMetric.values.length,
        0,
        growable: false,
      );

  final List<int> _values;

  int get slotCount => _values.length;

  int value(DashboardPerformanceMetric metric) => _values[metric.index];

  void increment(DashboardPerformanceMetric metric, {int by = 1}) {
    if (by < 0) {
      throw ArgumentError.value(by, 'by', 'must not be negative');
    }
    _values[metric.index] += by;
  }

  void reset() => _values.fillRange(0, _values.length, 0);

  Map<DashboardPerformanceMetric, int> snapshot() =>
      Map<DashboardPerformanceMetric, int>.unmodifiable({
        for (final metric in DashboardPerformanceMetric.values)
          metric: value(metric),
      });
}
