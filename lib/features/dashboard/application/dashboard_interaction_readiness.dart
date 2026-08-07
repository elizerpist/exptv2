import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_render_readiness_diagnostics.dart';

enum DashboardInteractionReadinessPhase {
  databasePending,
  indexBuilding,
  presentationPreparing,
  renderCriticalWarmup,
  ready,
  failed,
}

/// The deterministic prerequisites of one cold dashboard attempt.
///
/// Engine-side paint, semantics, compositor and raster callbacks are not
/// tasks: they cannot be a terminating startup contract. The last task is the
/// application-owned, exact-width paragraph cache created after normal layout.
enum DashboardReadinessTask {
  viewportPayload,
  renderResources,
  logBoxSurface,
  logBoxLayout,
  textLayoutSlots,
}

enum DashboardReadinessTaskState { pending, running, completed, failed }

typedef DashboardInitialFrameBuilder = Future<DashboardVisibleFrame> Function();
typedef DashboardRenderCriticalResourcePreparer =
    Future<void> Function(double devicePixelRatio);
typedef DashboardReadinessClock = int Function();

/// Sole lifecycle owner for a dashboard that is safe to interact with.
///
/// The render barrier tracks only explicit application-side state. A valid
/// prepared frame, current render resources, surface attachment, normal
/// layout, and the bounded text cache must all be terminal before interaction
/// opens. Every started task has one completed or failed terminal state.
final class DashboardInteractionReadiness extends ChangeNotifier {
  DashboardInteractionReadiness({
    required DashboardInitialFrameBuilder buildInitialFrame,
    required DashboardRenderCriticalResourcePreparer
    prepareRenderCriticalResources,
    DashboardRenderReadinessDiagnostics? diagnostics,
    DashboardReadinessClock? clockMicros,
  }) : _buildInitialFrame = buildInitialFrame,
       _prepareRenderCriticalResources = prepareRenderCriticalResources,
       _diagnostics = diagnostics,
       _clockMicros = clockMicros ?? (() => developer.Timeline.now),
       _phaseStartedMicros = (clockMicros ?? (() => developer.Timeline.now))(),
       _taskStates = <DashboardReadinessTask, DashboardReadinessTaskState>{
         for (final task in DashboardReadinessTask.values)
           task: DashboardReadinessTaskState.pending,
       },
       _taskStartedMicros = <DashboardReadinessTask, int>{
         for (final task in DashboardReadinessTask.values) task: 0,
       };

  final DashboardInitialFrameBuilder _buildInitialFrame;
  final DashboardRenderCriticalResourcePreparer _prepareRenderCriticalResources;
  final DashboardRenderReadinessDiagnostics? _diagnostics;
  final DashboardReadinessClock _clockMicros;
  final List<int> _phaseDurationsMicros = List<int>.filled(
    DashboardInteractionReadinessPhase.values.length,
    0,
    growable: false,
  );
  final Map<DashboardReadinessTask, DashboardReadinessTaskState> _taskStates;
  final Map<DashboardReadinessTask, int> _taskStartedMicros;
  int _phaseStartedMicros;

  DashboardInteractionReadinessPhase _phase =
      DashboardInteractionReadinessPhase.databasePending;
  DashboardVisibleFrame? _frame;
  Object? _error;
  DashboardReadinessTask? _failedTask;
  Future<void>? _inFlight;
  Completer<void>? _renderCriticalTasksCompleted;
  bool _disposed = false;

  DashboardInteractionReadinessPhase get phase => _phase;
  DashboardVisibleFrame? get frame => _frame;
  Object? get error => _error;
  DashboardReadinessTask? get failedTask => _failedTask;
  bool get isReady => _phase == DashboardInteractionReadinessPhase.ready;
  bool get isInteractive => isReady;
  bool get mountsDashboard =>
      _phase == DashboardInteractionReadinessPhase.renderCriticalWarmup ||
      _phase == DashboardInteractionReadinessPhase.ready;

  DashboardReadinessTaskState taskStateFor(DashboardReadinessTask task) =>
      _taskStates[task]!;

  int durationMicrosFor(DashboardInteractionReadinessPhase phase) =>
      _phaseDurationsMicros[phase.index];

  Map<String, Object?> report() => <String, Object?>{
    'phase': _phase.name,
    'isInteractive': isInteractive,
    'viewportId': _frame?.logBox.viewportId,
    'coreRevision': _frame?.coreRevision,
    'failedTask': _failedTask?.name,
    'taskStates': <String, String>{
      for (final task in DashboardReadinessTask.values)
        task.name: _taskStates[task]!.name,
    },
    'phaseDurationsMicros': <String, int>{
      for (final phase in DashboardInteractionReadinessPhase.values)
        phase.name: durationMicrosFor(phase),
    },
  };

  Future<void> start({required double devicePixelRatio}) {
    if (devicePixelRatio <= 0 || !devicePixelRatio.isFinite) {
      throw ArgumentError.value(
        devicePixelRatio,
        'devicePixelRatio',
        'must be finite and greater than zero',
      );
    }
    final existing = _inFlight;
    if (existing != null) return existing;
    if (isReady) return Future<void>.value();
    _resetAttempt();
    _recordPhaseEntered(_phase);
    late final Future<void> operation;
    operation = _run(devicePixelRatio).whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
    _inFlight = operation;
    return operation;
  }

  Future<void> _run(double devicePixelRatio) async {
    _setPhase(DashboardInteractionReadinessPhase.indexBuilding);
    _startTask(DashboardReadinessTask.viewportPayload);
    try {
      final frame = await _buildInitialFrame();
      _validateFrame(frame);
      if (_disposed) return;

      _frame = frame;
      _completeTask(DashboardReadinessTask.viewportPayload);
      _setPhase(DashboardInteractionReadinessPhase.presentationPreparing);
      _startTask(DashboardReadinessTask.renderResources);
      await _prepareRenderCriticalResources(devicePixelRatio);
      if (_disposed) return;

      _completeTask(DashboardReadinessTask.renderResources);
      _renderCriticalTasksCompleted = Completer<void>();
      _setPhase(DashboardInteractionReadinessPhase.renderCriticalWarmup);
      _startTask(DashboardReadinessTask.logBoxSurface);
      await _renderCriticalTasksCompleted!.future;
      if (_disposed) return;

      _renderCriticalTasksCompleted = null;
      _setPhase(DashboardInteractionReadinessPhase.ready);
      _diagnostics?.recordReadinessReady(
        phase: _phase.name,
        startMicros: _phaseStartedMicros,
        durationMicros: 0,
        queryKey: _queryKey,
        coreRevision: _coreRevision,
        generation: _generation,
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'READINESS_READY',
          queryKey: _queryKey,
          coreRevision: _coreRevision,
        ),
      );
    } on Object catch (error) {
      if (_disposed) return;
      _failActiveTask(error);
      _transitionToFailed(error);
    }
  }

  bool markLogBoxSurfaceAttached({required int viewportId}) {
    if (!_isCurrentWarmupViewport(viewportId) ||
        taskStateFor(DashboardReadinessTask.logBoxSurface) !=
            DashboardReadinessTaskState.running) {
      return false;
    }
    _completeTask(DashboardReadinessTask.logBoxSurface);
    _startTask(DashboardReadinessTask.logBoxLayout);
    return true;
  }

  bool markLogBoxSurfaceLaidOut({required int viewportId}) {
    if (!_isCurrentWarmupViewport(viewportId) ||
        taskStateFor(DashboardReadinessTask.logBoxLayout) !=
            DashboardReadinessTaskState.running) {
      return false;
    }
    _completeTask(DashboardReadinessTask.logBoxLayout);
    _startTask(DashboardReadinessTask.textLayoutSlots);
    return true;
  }

  bool markLogBoxTextLayoutsPrepared({required int viewportId}) {
    if (!_isCurrentWarmupViewport(viewportId) ||
        taskStateFor(DashboardReadinessTask.textLayoutSlots) !=
            DashboardReadinessTaskState.running) {
      return false;
    }
    _completeTask(DashboardReadinessTask.textLayoutSlots);
    final terminal = _renderCriticalTasksCompleted;
    if (terminal == null || terminal.isCompleted) return false;
    terminal.complete();
    return true;
  }

  void failRenderCriticalTask({
    required DashboardReadinessTask task,
    required Object error,
  }) {
    if (_disposed ||
        _phase != DashboardInteractionReadinessPhase.renderCriticalWarmup) {
      return;
    }
    _failTask(task, error);
    final terminal = _renderCriticalTasksCompleted;
    if (terminal != null && !terminal.isCompleted) {
      terminal.completeError(error);
    }
    _transitionToFailed(error);
  }

  /// For failures which happen before a surface task exists (for example demo
  /// seeding or initial data preparation). A running task is terminally failed
  /// when one exists; otherwise the phase itself still terminates explicitly.
  void fail(Object error) {
    if (_disposed) return;
    _failActiveTask(error);
    final terminal = _renderCriticalTasksCompleted;
    if (terminal != null && !terminal.isCompleted) {
      terminal.completeError(error);
    }
    _transitionToFailed(error);
  }

  bool _isCurrentWarmupViewport(int viewportId) {
    final frame = _frame;
    return !_disposed &&
        _phase == DashboardInteractionReadinessPhase.renderCriticalWarmup &&
        frame != null &&
        frame.logBox.viewportId == viewportId;
  }

  void _resetAttempt() {
    _error = null;
    _frame = null;
    _failedTask = null;
    _renderCriticalTasksCompleted = null;
    for (final task in DashboardReadinessTask.values) {
      _taskStates[task] = DashboardReadinessTaskState.pending;
      _taskStartedMicros[task] = 0;
    }
  }

  void _startTask(DashboardReadinessTask task) {
    final state = taskStateFor(task);
    if (_disposed || state != DashboardReadinessTaskState.pending) {
      throw StateError('Cannot start readiness task ${task.name} from $state.');
    }
    final now = _clockMicros();
    _taskStartedMicros[task] = now;
    _taskStates[task] = DashboardReadinessTaskState.running;
    _diagnostics?.recordReadinessTaskStarted(
      phase: _phase.name,
      task: task.name,
      startMicros: now,
      queryKey: _queryKey,
      coreRevision: _coreRevision,
      generation: _generation,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'READINESS_TASK_STARTED',
        message: task.name,
        queryKey: _queryKey,
        coreRevision: _coreRevision,
      ),
    );
  }

  void _completeTask(DashboardReadinessTask task) {
    if (_disposed ||
        taskStateFor(task) != DashboardReadinessTaskState.running) {
      return;
    }
    final now = _clockMicros();
    final started = _taskStartedMicros[task]!;
    _taskStates[task] = DashboardReadinessTaskState.completed;
    _diagnostics?.recordReadinessTaskCompleted(
      phase: _phase.name,
      task: task.name,
      startMicros: started,
      durationMicros: now - started,
      queryKey: _queryKey,
      coreRevision: _coreRevision,
      generation: _generation,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'READINESS_TASK_COMPLETED',
        message: task.name,
        queryKey: _queryKey,
        coreRevision: _coreRevision,
        durationMs: (now - started) ~/ 1000,
      ),
    );
  }

  void _failActiveTask(Object error) {
    for (final task in DashboardReadinessTask.values) {
      if (taskStateFor(task) == DashboardReadinessTaskState.running) {
        _failTask(task, error);
        return;
      }
    }
  }

  void _failTask(DashboardReadinessTask task, Object error) {
    final state = taskStateFor(task);
    if (_disposed ||
        state == DashboardReadinessTaskState.completed ||
        state == DashboardReadinessTaskState.failed) {
      return;
    }
    final now = _clockMicros();
    final started = _taskStartedMicros[task] ?? now;
    _taskStates[task] = DashboardReadinessTaskState.failed;
    _failedTask = task;
    _diagnostics?.recordReadinessTaskFailed(
      phase: _phase.name,
      task: task.name,
      startMicros: started,
      durationMicros: now - started,
      queryKey: _queryKey,
      coreRevision: _coreRevision,
      generation: _generation,
      error: error,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'READINESS_TASK_FAILED',
        message: task.name,
        queryKey: _queryKey,
        coreRevision: _coreRevision,
        error: '$error',
        durationMs: (now - started) ~/ 1000,
      ),
    );
  }

  void _transitionToFailed(Object error) {
    if (_disposed) return;
    _error = error;
    _renderCriticalTasksCompleted = null;
    _setPhase(DashboardInteractionReadinessPhase.failed);
  }

  String get _queryKey => _frame?.queryKey.value ?? 'bootstrap';
  int get _coreRevision => _frame?.coreRevision ?? 0;
  int get _generation => _frame?.frameGeneration ?? 0;

  static void _validateFrame(DashboardVisibleFrame frame) {
    if (frame.coreRevision <= 0 ||
        frame.queryKey != frame.scope.key ||
        frame.amount.queryKey != frame.count.queryKey ||
        frame.amount.queryKey != frame.logBox.queryKey ||
        frame.amount.coreRevision != frame.coreRevision ||
        frame.count.coreRevision != frame.coreRevision ||
        frame.logBox.revision != frame.coreRevision) {
      throw StateError(
        'Dashboard readiness requires one complete atomic prepared frame.',
      );
    }
  }

  void _setPhase(DashboardInteractionReadinessPhase next) {
    if (_disposed || next == _phase) return;
    final now = _clockMicros();
    _phaseDurationsMicros[_phase.index] += now - _phaseStartedMicros;
    _phaseStartedMicros = now;
    _phase = next;
    _recordPhaseEntered(next);
    notifyListeners();
  }

  void _recordPhaseEntered(DashboardInteractionReadinessPhase phase) {
    _diagnostics?.recordReadinessPhaseEntered(
      phase: phase.name,
      startMicros: _phaseStartedMicros,
      queryKey: _queryKey,
      coreRevision: _coreRevision,
      generation: _generation,
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'READINESS_PHASE_ENTERED',
        message: phase.name,
        queryKey: _queryKey,
        coreRevision: _coreRevision,
      ),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final terminal = _renderCriticalTasksCompleted;
    if (terminal != null && !terminal.isCompleted) terminal.complete();
    _renderCriticalTasksCompleted = null;
    super.dispose();
  }
}
