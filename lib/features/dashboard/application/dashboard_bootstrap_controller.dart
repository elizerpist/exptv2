import 'package:flutter/foundation.dart';

import '../query/application/dashboard_presentation_store.dart';

enum DashboardBootstrapPhase {
  idle,
  resolvingInitialQuery,
  readingCriticalSnapshot,
  preparingChildPreview,
  ready,
  failed,
}

/// Gates the dashboard mount until one complete, same-key snapshot exists.
///
/// This controller coordinates lifecycle only. Query, bundle and visible
/// snapshot ownership remain with their existing controllers/store.
class DashboardBootstrapController extends ChangeNotifier {
  DashboardBootstrapController({
    required DashboardPresentationStore store,
    required Future<DashboardPresentationSnapshot> Function()
    readCriticalSnapshot,
    Future<void> Function()? prepareChildPreview,
  }) : _store = store,
       _readCriticalSnapshot = readCriticalSnapshot,
       _prepareChildPreview = prepareChildPreview;

  final DashboardPresentationStore _store;
  final Future<DashboardPresentationSnapshot> Function() _readCriticalSnapshot;
  final Future<void> Function()? _prepareChildPreview;

  DashboardBootstrapPhase _phase = DashboardBootstrapPhase.idle;
  DashboardPresentationSnapshot? _snapshot;
  Object? _error;
  Future<void>? _inFlight;
  bool _disposed = false;

  DashboardBootstrapPhase get phase => _phase;
  DashboardPresentationSnapshot? get snapshot => _snapshot;
  Object? get error => _error;
  bool get isReady => _phase == DashboardBootstrapPhase.ready;

  Future<void> start() {
    final existing = _inFlight;
    if (existing != null) return existing;
    if (isReady) return Future<void>.value();
    final operation = _run();
    _inFlight = operation;
    return operation.whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    _setPhase(DashboardBootstrapPhase.resolvingInitialQuery);
    try {
      // Keep this phase explicit even when resolving is synchronous. It is a
      // lifecycle boundary for seed/default direction and plane resolution.
      await Future<void>.value();
      _setPhase(DashboardBootstrapPhase.readingCriticalSnapshot);
      final initialSnapshot = await _readCriticalSnapshot();
      _setPhase(DashboardBootstrapPhase.preparingChildPreview);
      await (_prepareChildPreview?.call() ?? Future<void>.value());
      if (!_isValidInitialSnapshot(initialSnapshot)) {
        throw StateError(
          'Dashboard bootstrap requires a complete non-placeholder snapshot.',
        );
      }
      if (_disposed) return;
      _snapshot = initialSnapshot;
      _store.publish(initialSnapshot);
      _setPhase(DashboardBootstrapPhase.ready);
    } on Object catch (error) {
      _error = error;
      _setPhase(DashboardBootstrapPhase.failed);
    }
  }

  static bool _isValidInitialSnapshot(DashboardPresentationSnapshot snapshot) =>
      snapshot.hasValue &&
      !snapshot.isLoading &&
      !snapshot.isStale &&
      !snapshot.hasError &&
      snapshot.scope != null &&
      snapshot.scope!.key == snapshot.queryKey;

  void _setPhase(DashboardBootstrapPhase phase) {
    if (_disposed) return;
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
