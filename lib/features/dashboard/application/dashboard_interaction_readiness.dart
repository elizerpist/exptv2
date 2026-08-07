import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../visible/domain/dashboard_visible_frame.dart';

enum DashboardInteractionReadinessPhase {
  databasePending,
  indexBuilding,
  presentationPreparing,
  renderCriticalWarmup,
  ready,
  failed,
}

typedef DashboardInitialFrameBuilder = Future<DashboardVisibleFrame> Function();
typedef DashboardRenderCriticalResourcePreparer =
    Future<void> Function(double devicePixelRatio);
typedef DashboardReadinessClock = int Function();

/// Sole lifecycle owner for a dashboard that is safe to interact with.
///
/// A valid prepared frame is necessary but not sufficient. Interaction opens
/// only after the canonical render resources are prepared and the one normal
/// visible LogBox surface has submitted its first frame for that exact payload.
final class DashboardInteractionReadiness extends ChangeNotifier {
  DashboardInteractionReadiness({
    required DashboardInitialFrameBuilder buildInitialFrame,
    required DashboardRenderCriticalResourcePreparer
    prepareRenderCriticalResources,
    DashboardReadinessClock? clockMicros,
  }) : _buildInitialFrame = buildInitialFrame,
       _prepareRenderCriticalResources = prepareRenderCriticalResources,
       _clockMicros = clockMicros ?? (() => developer.Timeline.now),
       _phaseStartedMicros = (clockMicros ?? (() => developer.Timeline.now))();

  final DashboardInitialFrameBuilder _buildInitialFrame;
  final DashboardRenderCriticalResourcePreparer _prepareRenderCriticalResources;
  final DashboardReadinessClock _clockMicros;
  final List<int> _phaseDurationsMicros = List<int>.filled(
    DashboardInteractionReadinessPhase.values.length,
    0,
    growable: false,
  );
  int _phaseStartedMicros;

  DashboardInteractionReadinessPhase _phase =
      DashboardInteractionReadinessPhase.databasePending;
  DashboardVisibleFrame? _frame;
  Object? _error;
  Future<void>? _inFlight;
  Completer<void>? _renderSurfacePresented;
  bool _disposed = false;

  DashboardInteractionReadinessPhase get phase => _phase;
  DashboardVisibleFrame? get frame => _frame;
  Object? get error => _error;
  bool get isReady => _phase == DashboardInteractionReadinessPhase.ready;
  bool get isInteractive => isReady;
  bool get mountsDashboard =>
      _phase == DashboardInteractionReadinessPhase.renderCriticalWarmup ||
      _phase == DashboardInteractionReadinessPhase.ready;

  int durationMicrosFor(DashboardInteractionReadinessPhase phase) =>
      _phaseDurationsMicros[phase.index];

  Map<String, Object?> report() => <String, Object?>{
    'phase': _phase.name,
    'isInteractive': isInteractive,
    'viewportId': _frame?.logBox.viewportId,
    'coreRevision': _frame?.coreRevision,
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
    late final Future<void> operation;
    operation = _run(devicePixelRatio).whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
    _inFlight = operation;
    return operation;
  }

  Future<void> _run(double devicePixelRatio) async {
    _error = null;
    _frame = null;
    _renderSurfacePresented = null;
    _setPhase(DashboardInteractionReadinessPhase.indexBuilding);
    try {
      final frame = await _buildInitialFrame();
      _validateFrame(frame);
      if (_disposed) return;

      _frame = frame;
      _setPhase(DashboardInteractionReadinessPhase.presentationPreparing);
      await _prepareRenderCriticalResources(devicePixelRatio);
      if (_disposed) return;

      final presented = Completer<void>();
      _renderSurfacePresented = presented;
      _setPhase(DashboardInteractionReadinessPhase.renderCriticalWarmup);
      await presented.future;
      if (_disposed) return;

      _renderSurfacePresented = null;
      _setPhase(DashboardInteractionReadinessPhase.ready);
    } on Object catch (error) {
      if (_disposed) return;
      _error = error;
      _renderSurfacePresented = null;
      _setPhase(DashboardInteractionReadinessPhase.failed);
    }
  }

  bool markLogBoxFramePresented({required int viewportId}) {
    final frame = _frame;
    final presented = _renderSurfacePresented;
    if (_disposed ||
        _phase != DashboardInteractionReadinessPhase.renderCriticalWarmup ||
        frame == null ||
        frame.logBox.viewportId != viewportId ||
        presented == null ||
        presented.isCompleted) {
      return false;
    }
    presented.complete();
    return true;
  }

  void fail(Object error) {
    if (_disposed) return;
    _error = error;
    final presented = _renderSurfacePresented;
    if (presented != null && !presented.isCompleted) {
      presented.completeError(error);
    }
    _renderSurfacePresented = null;
    _setPhase(DashboardInteractionReadinessPhase.failed);
  }

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
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final presented = _renderSurfacePresented;
    if (presented != null && !presented.isCompleted) {
      presented.complete();
    }
    _renderSurfacePresented = null;
    super.dispose();
  }
}
