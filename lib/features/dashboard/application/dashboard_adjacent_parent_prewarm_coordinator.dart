import 'dart:async';

/// Schedules adjacent parent work outside active rail motion.
///
/// It owns only scheduling and generation state. It does not own query data,
/// presentation snapshots or the rail itself.
class DashboardAdjacentParentPrewarmCoordinator {
  Timer? _timer;
  Future<void> Function(int generation)? _scheduledTask;
  Future<void> Function(int generation)? _deferredTask;
  int _generation = 0;
  int _prewarmStartedCount = 0;
  bool _motionActive = false;
  bool _disposed = false;

  bool get isMotionActive => _motionActive;
  int get prewarmStartedCount => _prewarmStartedCount;

  void beginMotion() {
    if (_disposed) return;
    _motionActive = true;
    _generation += 1;
    if (_timer != null && _scheduledTask != null) {
      _deferredTask = _scheduledTask;
    }
    _timer?.cancel();
    _timer = null;
    _scheduledTask = null;
  }

  void endMotion() {
    if (_disposed || !_motionActive) return;
    _motionActive = false;
    final deferred = _deferredTask;
    _deferredTask = null;
    if (deferred != null) schedule(deferred);
  }

  void schedule(Future<void> Function(int generation) task) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = null;
    _scheduledTask = null;
    final generation = ++_generation;
    if (_motionActive) {
      _deferredTask = task;
      return;
    }
    _scheduledTask = task;
    _timer = Timer(Duration.zero, () {
      _timer = null;
      final scheduled = _scheduledTask;
      _scheduledTask = null;
      if (_disposed || _motionActive || generation != _generation) return;
      if (scheduled == null) return;
      _prewarmStartedCount += 1;
      unawaited(scheduled(generation));
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _scheduledTask = null;
    _deferredTask = null;
  }
}
