import 'dart:async';

import '../domain/current_ledger_query_scope.dart';

/// Schedules the expensive, long-lived repository observation separately from
/// the synchronous presentation commit.
///
/// Every request supersedes the previous pending request. The coordinator is
/// deliberately unaware of scroll state and presentation data; it only owns
/// the latest-wins activation boundary for a query lease.
class DashboardLiveQueryLeaseCoordinator {
  DashboardLiveQueryLeaseCoordinator({
    this.quiescence = const Duration(milliseconds: 120),
  });

  final Duration quiescence;
  Timer? _timer;
  int _token = 0;
  CurrentLedgerQueryScope? _pendingScope;
  int? _pendingGeneration;
  int? _lastInvalidatedMotionEpoch;
  int _pendingLeaseCancellationCount = 0;

  bool get hasPendingRequest => _timer != null;
  CurrentLedgerQueryScope? get pendingScope => _pendingScope;
  int? get pendingGeneration => _pendingGeneration;
  int? get lastInvalidatedMotionEpoch => _lastInvalidatedMotionEpoch;
  int get pendingLeaseCancellationCount => _pendingLeaseCancellationCount;

  void request({
    required CurrentLedgerQueryScope scope,
    required int generation,
    required void Function() activate,
  }) {
    _timer?.cancel();
    final token = ++_token;
    _pendingScope = scope;
    _pendingGeneration = generation;
    if (quiescence == Duration.zero) {
      _pendingScope = null;
      _pendingGeneration = null;
      activate();
      return;
    }
    _timer = Timer(quiescence, () {
      if (token != _token) return;
      _timer = null;
      _pendingScope = null;
      _pendingGeneration = null;
      activate();
    });
  }

  void cancel() {
    _token += 1;
    _timer?.cancel();
    _timer = null;
    _pendingScope = null;
    _pendingGeneration = null;
  }

  /// Invalidates only the deferred activation window when a new rail motion
  /// starts. An already active lease is intentionally left alone; its result
  /// can still warm the query cache while the presentation store rejects it
  /// for an unrelated visible preview target.
  void invalidatePendingForMotion({required int motionEpoch}) {
    _lastInvalidatedMotionEpoch = motionEpoch;
    if (_timer != null) {
      _pendingLeaseCancellationCount += 1;
    }
    cancel();
  }
}
