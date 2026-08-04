import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' as flutter;

import 'dashboard_performance_counters.dart';

enum DashboardBackgroundJobType {
  coreRevisionRefresh,
  adjacentParentPrewarm,
  oppositeDirectionPrewarm,
}

enum DashboardBackgroundPriority {
  critical(0),
  normal(50),
  low(100);

  const DashboardBackgroundPriority(this.value);

  final int value;
}

@immutable
class DashboardBackgroundJobKey {
  const DashboardBackgroundJobKey({
    required this.type,
    required this.semanticKey,
  });

  final DashboardBackgroundJobType type;
  final String semanticKey;

  @override
  bool operator ==(Object other) =>
      other is DashboardBackgroundJobKey &&
      other.type == type &&
      other.semanticKey == semanticKey;

  @override
  int get hashCode => Object.hash(type, semanticKey);

  @override
  String toString() => '${type.name}:$semanticKey';
}

typedef DashboardBackgroundDrainScheduler = void Function(VoidCallback drain);
typedef DashboardBackgroundTask =
    Future<bool> Function(DashboardBackgroundWorkToken token);

/// Cooperative cancellation token for one background job generation.
///
/// Native work that already started may finish and populate a lower-level
/// cache, but callers must check [canContinue] before Dart projection or any
/// visible publication.
class DashboardBackgroundWorkToken {
  const DashboardBackgroundWorkToken._({
    required DashboardBackgroundWorkCoordinator owner,
    required this.key,
    required this.generation,
    required int interactionGeneration,
  }) : _owner = owner,
       _interactionGeneration = interactionGeneration;

  final DashboardBackgroundWorkCoordinator _owner;
  final DashboardBackgroundJobKey key;
  final int generation;
  final int _interactionGeneration;

  bool get canContinue => _owner._isCurrent(this);
}

class _DashboardBackgroundJob {
  _DashboardBackgroundJob({
    required this.key,
    required this.priority,
    required this.generation,
    required this.task,
    required this.supersedeGroup,
  });

  final DashboardBackgroundJobKey key;
  final DashboardBackgroundPriority priority;
  final int generation;
  final DashboardBackgroundTask task;
  final String? supersedeGroup;
  final Completer<bool> completer = Completer<bool>();
  bool cancelled = false;
}

/// Single owner for expensive dashboard background work.
///
/// Jobs are semantic-key deduplicated, priority ordered and serialized. A new
/// interaction invalidates the running publication token and prevents queued
/// jobs from starting; presentation itself remains synchronous and independent
/// from this queue.
class DashboardBackgroundWorkCoordinator {
  DashboardBackgroundWorkCoordinator({
    DashboardBackgroundDrainScheduler? scheduleDrain,
    DashboardPerformanceCounters? performanceCounters,
  }) : _scheduleDrain = scheduleDrain ?? _scheduleAtIdlePriority,
       performanceCounters =
           performanceCounters ?? DashboardPerformanceCounters();

  final DashboardBackgroundDrainScheduler _scheduleDrain;
  final DashboardPerformanceCounters performanceCounters;
  final List<_DashboardBackgroundJob> _queue = <_DashboardBackgroundJob>[];
  final Map<DashboardBackgroundJobKey, _DashboardBackgroundJob> _jobsByKey =
      <DashboardBackgroundJobKey, _DashboardBackgroundJob>{};

  _DashboardBackgroundJob? _running;
  int _nextGeneration = 0;
  int _interactionGeneration = 0;
  int? _activeInteractionEpoch;
  bool _drainScheduled = false;
  bool _disposed = false;
  int _runningCount = 0;
  int _maxConcurrentCount = 0;

  bool get isInteractionActive => _activeInteractionEpoch != null;
  int get startedCount => performanceCounters.value(
    DashboardPerformanceMetric.backgroundJobStarted,
  );
  int get completedCount => performanceCounters.value(
    DashboardPerformanceMetric.backgroundJobCompleted,
  );
  int get deduplicatedCount => performanceCounters.value(
    DashboardPerformanceMetric.backgroundJobDeduplicated,
  );
  int get supersededCount => performanceCounters.value(
    DashboardPerformanceMetric.backgroundJobSuperseded,
  );
  int get runningCount => _runningCount;
  int get maxConcurrentCount => _maxConcurrentCount;
  int get queuedCount => _queue.length;

  void beginInteraction(int interactionEpoch) {
    if (_disposed) return;
    _activeInteractionEpoch = interactionEpoch;
    _interactionGeneration += 1;
  }

  void endInteraction(int interactionEpoch) {
    if (_disposed || _activeInteractionEpoch != interactionEpoch) return;
    _activeInteractionEpoch = null;
    _scheduleNext();
  }

  Future<bool> schedule({
    required DashboardBackgroundJobKey key,
    required DashboardBackgroundPriority priority,
    required DashboardBackgroundTask task,
    String? supersedeGroup,
  }) {
    if (_disposed) return Future<bool>.value(false);
    final duplicate = _jobsByKey[key];
    if (duplicate != null) {
      performanceCounters.increment(
        DashboardPerformanceMetric.backgroundJobDeduplicated,
      );
      return duplicate.completer.future;
    }

    if (supersedeGroup != null) {
      final superseded = _queue
          .where((job) => job.supersedeGroup == supersedeGroup)
          .toList(growable: false);
      for (final job in superseded) {
        _cancelQueued(job);
      }
      final running = _running;
      if (running != null && running.supersedeGroup == supersedeGroup) {
        running.cancelled = true;
      }
    }

    final running = _running;
    if (running != null && priority.value < running.priority.value) {
      // Cooperative preemption: the lower-priority native operation may
      // finish, but its Dart projection/publication token is invalid now.
      running.cancelled = true;
    }

    final job = _DashboardBackgroundJob(
      key: key,
      priority: priority,
      generation: ++_nextGeneration,
      task: task,
      supersedeGroup: supersedeGroup,
    );
    _jobsByKey[key] = job;
    _queue.add(job);
    _scheduleNext();
    return job.completer.future;
  }

  void _cancelQueued(_DashboardBackgroundJob job) {
    if (!_queue.remove(job)) return;
    job.cancelled = true;
    if (identical(_jobsByKey[job.key], job)) {
      _jobsByKey.remove(job.key);
    }
    performanceCounters.increment(
      DashboardPerformanceMetric.backgroundJobSuperseded,
    );
    if (!job.completer.isCompleted) job.completer.complete(false);
  }

  void _scheduleNext() {
    if (_disposed ||
        isInteractionActive ||
        _running != null ||
        _queue.isEmpty ||
        _drainScheduled) {
      return;
    }
    _drainScheduled = true;
    _scheduleDrain(() {
      _drainScheduled = false;
      _startNext();
    });
  }

  void _startNext() {
    if (_disposed || isInteractionActive || _running != null) return;
    _queue.sort((left, right) {
      final priority = left.priority.value.compareTo(right.priority.value);
      return priority != 0
          ? priority
          : left.generation.compareTo(right.generation);
    });
    while (_queue.isNotEmpty && _queue.first.cancelled) {
      final cancelled = _queue.removeAt(0);
      if (identical(_jobsByKey[cancelled.key], cancelled)) {
        _jobsByKey.remove(cancelled.key);
      }
      if (!cancelled.completer.isCompleted) {
        cancelled.completer.complete(false);
      }
    }
    if (_queue.isEmpty) return;

    final job = _queue.removeAt(0);
    _running = job;
    _runningCount += 1;
    if (_runningCount > _maxConcurrentCount) {
      _maxConcurrentCount = _runningCount;
    }
    performanceCounters.increment(
      DashboardPerformanceMetric.backgroundJobStarted,
    );
    final token = DashboardBackgroundWorkToken._(
      owner: this,
      key: job.key,
      generation: job.generation,
      interactionGeneration: _interactionGeneration,
    );
    Future<bool>.sync(() => job.task(token)).then(
      (result) => _finish(job, result && token.canContinue),
      onError: (Object _, StackTrace _) => _finish(job, false),
    );
  }

  void _finish(_DashboardBackgroundJob job, bool result) {
    if (identical(_running, job)) {
      _running = null;
      _runningCount -= 1;
    }
    if (identical(_jobsByKey[job.key], job)) {
      _jobsByKey.remove(job.key);
    }
    performanceCounters.increment(
      DashboardPerformanceMetric.backgroundJobCompleted,
    );
    if (!job.completer.isCompleted) job.completer.complete(result);
    _scheduleNext();
  }

  bool _isCurrent(DashboardBackgroundWorkToken token) {
    if (_disposed || isInteractionActive) return false;
    final running = _running;
    return running != null &&
        identical(_jobsByKey[token.key], running) &&
        running.key == token.key &&
        running.generation == token.generation &&
        !running.cancelled &&
        token._interactionGeneration == _interactionGeneration;
  }

  static void _scheduleAtIdlePriority(VoidCallback drain) {
    try {
      final binding = flutter.SchedulerBinding.instance;

      void drainAfterFrame(Duration _) {
        // An active ticker has already registered the next transient callback
        // by the time post-frame callbacks run. Wait one frame at a time so
        // background work cannot start alongside dashboard motion. Using
        // scheduleTask(Priority.idle) here would repeatedly enqueue zero-delay
        // event-loop timers while an animation is active (and spins FakeAsync
        // widget tests instead of yielding to the next frame).
        if (binding.transientCallbackCount > 0) {
          binding.addPostFrameCallback(drainAfterFrame);
          binding.scheduleFrame();
          return;
        }
        drain();
      }

      binding.addPostFrameCallback(drainAfterFrame);
      binding.scheduleFrame();
    } on FlutterError {
      // Pure unit-test and headless hosts may not install a Flutter binding.
      // Production always takes the frame-aware scheduler path above.
      scheduleMicrotask(drain);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _interactionGeneration += 1;
    _activeInteractionEpoch = null;
    final queued = List<_DashboardBackgroundJob>.of(_queue);
    _queue.clear();
    for (final job in queued) {
      job.cancelled = true;
      if (!job.completer.isCompleted) job.completer.complete(false);
    }
    final running = _running;
    if (running != null) {
      running.cancelled = true;
      if (!running.completer.isCompleted) running.completer.complete(false);
    }
    _jobsByKey.clear();
  }
}
