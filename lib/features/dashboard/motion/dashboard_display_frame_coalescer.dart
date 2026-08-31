import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

abstract interface class DashboardDisplayFrameScheduler {
  int get currentFrameNumber;

  void scheduleFrame(VoidCallback callback);
}

/// Schedules one callback on the next Flutter engine display frame.
final class FlutterDashboardDisplayFrameScheduler
    implements DashboardDisplayFrameScheduler {
  int _currentFrameNumber = 0;

  @override
  int get currentFrameNumber => _currentFrameNumber;

  @override
  void scheduleFrame(VoidCallback callback) {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _currentFrameNumber += 1;
      callback();
    });
  }
}

/// Retains only the latest semantic target until the next display boundary.
///
/// This is deliberately a one-slot frame scheduler: it has no timer, time
/// window, replay queue or idle/settle dependency.
final class DashboardDisplayFrameCoalescer<T extends Object> {
  DashboardDisplayFrameCoalescer({
    required DashboardDisplayFrameScheduler scheduler,
    required ValueChanged<T> publish,
  }) : _scheduler = scheduler,
       _publish = publish;

  final DashboardDisplayFrameScheduler _scheduler;
  final ValueChanged<T> _publish;

  T? _pending;
  bool _scheduled = false;
  int? _lastPublishFrame;
  int _publishesInCurrentFrame = 0;

  int requestCount = 0;
  int publishCount = 0;
  int coalescedTargetCount = 0;
  int maximumPublishesInOneDisplayFrame = 0;

  bool get hasPendingTarget => _pending != null;
  int get currentFrameNumber => _scheduler.currentFrameNumber;

  void request(T target) {
    requestCount += 1;
    if (_pending != null) coalescedTargetCount += 1;
    _pending = target;
    if (_scheduled) return;
    _scheduled = true;
    _scheduler.scheduleFrame(_onDisplayFrame);
  }

  /// Immediately publishes the newest target and leaves an already requested
  /// engine callback harmless. Physical pointer-up uses this to ensure the
  /// final value is visible before its asynchronous canonical handoff starts.
  void flush() => _onDisplayFrame();

  /// Invalidates a queued target without trying to cancel the engine callback.
  /// Flutter can still invoke that callback, but it observes an empty slot and
  /// therefore cannot publish after the owning widget/controller has gone.
  void discardPendingTarget() {
    _pending = null;
    _scheduled = false;
  }

  void _onDisplayFrame() {
    _scheduled = false;
    final target = _pending;
    _pending = null;
    if (target == null) return;

    final frameNumber = _scheduler.currentFrameNumber;
    if (_lastPublishFrame == frameNumber) {
      _publishesInCurrentFrame += 1;
    } else {
      _lastPublishFrame = frameNumber;
      _publishesInCurrentFrame = 1;
    }
    if (_publishesInCurrentFrame > maximumPublishesInOneDisplayFrame) {
      maximumPublishesInOneDisplayFrame = _publishesInCurrentFrame;
    }
    publishCount += 1;
    _publish(target);
  }
}
