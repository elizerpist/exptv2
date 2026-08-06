import 'package:flutter/foundation.dart';

import '../visible/domain/dashboard_visible_frame.dart';

enum DashboardBootstrapPhase {
  idle,
  waitingForSeed,
  resolvingCoreRevision,
  preparingInitialIndex,
  ready,
  failed,
}

/// Lifecycle gate for the first complete prepared index and visible frame.
///
/// The core owns preparation and publication. This controller only prevents
/// the dashboard widget tree from mounting before a nonzero-revision atomic
/// frame exists.
final class DashboardBootstrapController extends ChangeNotifier {
  DashboardBootstrapController({
    required Future<DashboardVisibleFrame> Function() bootstrap,
  }) : _bootstrap = bootstrap;

  final Future<DashboardVisibleFrame> Function() _bootstrap;

  DashboardBootstrapPhase _phase = DashboardBootstrapPhase.idle;
  DashboardVisibleFrame? _frame;
  Object? _error;
  Future<void>? _inFlight;
  bool _disposed = false;

  DashboardBootstrapPhase get phase => _phase;
  DashboardVisibleFrame? get frame => _frame;
  Object? get error => _error;
  bool get isReady => _phase == DashboardBootstrapPhase.ready;

  void fail(Object error) {
    if (_disposed) return;
    _error = error;
    _setPhase(DashboardBootstrapPhase.failed);
  }

  Future<void> start() {
    final existing = _inFlight;
    if (existing != null) return existing;
    if (isReady) return Future<void>.value();
    late final Future<void> operation;
    operation = _run().whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
    _inFlight = operation;
    return operation;
  }

  Future<void> _run() async {
    _error = null;
    _setPhase(DashboardBootstrapPhase.resolvingCoreRevision);
    try {
      // Revision resolution and index preparation are one fail-closed core
      // operation. The explicit phase here exists for diagnostics/UI only.
      _setPhase(DashboardBootstrapPhase.preparingInitialIndex);
      final frame = await _bootstrap();
      if (frame.coreRevision <= 0 ||
          frame.queryKey != frame.scope.key ||
          frame.amount.queryKey != frame.count.queryKey ||
          frame.amount.queryKey != frame.logBox.queryKey) {
        throw StateError(
          'Dashboard bootstrap requires one complete atomic frame.',
        );
      }
      if (_disposed) return;
      _frame = frame;
      _setPhase(DashboardBootstrapPhase.ready);
    } on Object catch (error) {
      fail(error);
    }
  }

  void _setPhase(DashboardBootstrapPhase phase) {
    if (_disposed || phase == _phase) return;
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
