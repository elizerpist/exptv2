import 'package:flutter/foundation.dart';

import '../query/application/dashboard_parent_display_bundle.dart';
import '../query/application/dashboard_query_debug.dart';
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
    Future<DashboardPresentationSnapshot> Function()? readCriticalSnapshot,
    Future<DashboardParentDisplayBundle> Function()? readInitialBundle,
    Future<void> Function()? prepareChildPreview,
  }) : assert(readCriticalSnapshot != null || readInitialBundle != null),
       _store = store,
       _readCriticalSnapshot = readCriticalSnapshot,
       _readInitialBundle = readInitialBundle,
       _prepareChildPreview = prepareChildPreview;

  final DashboardPresentationStore _store;
  final Future<DashboardPresentationSnapshot> Function()? _readCriticalSnapshot;
  final Future<DashboardParentDisplayBundle> Function()? _readInitialBundle;
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
      final initialBundle = await _readInitialBundle?.call();
      final initialSnapshot =
          initialBundle?.parentSnapshot ?? await _readCriticalSnapshot!.call();
      if (initialBundle == null) {
        _setPhase(DashboardBootstrapPhase.preparingChildPreview);
        await (_prepareChildPreview?.call() ?? Future<void>.value());
      }
      if (!_isValidInitialSnapshot(initialSnapshot)) {
        throw StateError(
          'Dashboard bootstrap requires a complete non-placeholder snapshot.',
        );
      }
      if (initialBundle != null && !initialBundle.isComplete) {
        throw StateError(
          'Dashboard bootstrap requires a complete parent display bundle.',
        );
      }
      if (_disposed) return;
      _snapshot = initialSnapshot;
      _store.publish(initialSnapshot);
      DashboardQueryDebug.mark(
        'DASHBOARD_FIRST_VALID_PAINT',
        scope: initialSnapshot.scope,
        totalMinor: initialSnapshot.totalMinor,
        entryCount: initialSnapshot.entryCount,
        coreRevision: initialSnapshot.coreRevision,
        detail: 'showedPlaceholder=false',
      );
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
