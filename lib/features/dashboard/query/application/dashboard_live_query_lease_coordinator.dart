import 'dart:async';

import '../../../../shared/motion/centered_carousel/centered_carousel_motion.dart';
import 'dashboard_query_debug.dart';
import '../domain/current_ledger_query_scope.dart';

/// Separates immediate display commitment from expensive live observation.
///
/// A candidate is latest-wins and only activates after the rail has remained
/// idle for [quiescence]. This timer coordinates repository work only; it
/// never moves a scroll position or participates in rail target calculation.
class DashboardLiveQueryLeaseCoordinator {
  DashboardLiveQueryLeaseCoordinator({
    required this.activateLease,
    this.quiescence = const Duration(milliseconds: 180),
  });

  final void Function(CurrentLedgerQueryScope scope) activateLease;
  final Duration quiescence;

  Timer? _timer;
  CurrentLedgerQueryScope? _candidate;
  int _candidateEpoch = 0;
  int _generation = 0;
  bool _motionActive = false;
  bool _disposed = false;

  void request(CurrentLedgerQueryScope scope, {required int motionEpoch}) {
    if (_disposed) return;
    _candidate = scope;
    _candidateEpoch = motionEpoch;
    if (DashboardQueryDebug.isEnabled) {
      DashboardQueryDebug.mark(
        'LIVE_LEASE_CANDIDATE',
        scope: scope,
        detail: 'motionEpoch=$motionEpoch motionActive=$_motionActive',
      );
    }
    _scheduleIfIdle();
  }

  void onMotion(RailMotionSnapshot motion) {
    if (_disposed) return;
    _motionActive = motion.state != RailMotionState.idle;
    if (_motionActive) {
      _generation += 1;
      _timer?.cancel();
      _timer = null;
      final candidate = _candidate;
      if (candidate != null && DashboardQueryDebug.isEnabled) {
        DashboardQueryDebug.mark(
          'LIVE_LEASE_CANCELLED',
          scope: candidate,
          detail: 'reason=motionActive epoch=${motion.epoch}',
        );
      }
      return;
    }
    _scheduleIfIdle();
  }

  /// Discards a not-yet-active candidate when an external change (for example
  /// a direction switch) supersedes the rail's settled query intent.
  ///
  /// This is deliberately lease-only: it never touches the displayed preview
  /// or a currently active repository subscription.
  void cancelPending() {
    if (_disposed) return;
    final candidate = _candidate;
    _generation += 1;
    _timer?.cancel();
    _timer = null;
    _candidate = null;
    if (candidate != null && DashboardQueryDebug.isEnabled) {
      DashboardQueryDebug.mark(
        'LIVE_LEASE_CANCELLED',
        scope: candidate,
        detail: 'reason=externalScopeChange',
      );
    }
  }

  void _scheduleIfIdle() {
    if (_motionActive || _candidate == null) return;
    _timer?.cancel();
    final generation = ++_generation;
    final scope = _candidate!;
    final epoch = _candidateEpoch;
    _timer = Timer(quiescence, () {
      if (_disposed || _motionActive || generation != _generation) return;
      if (_candidate != scope || _candidateEpoch != epoch) return;
      _timer = null;
      if (DashboardQueryDebug.isEnabled) {
        DashboardQueryDebug.mark(
          'LIVE_LEASE_ACTIVATED',
          scope: scope,
          detail: 'motionEpoch=$epoch generation=$generation',
        );
      }
      activateLease(scope);
    });
  }

  void dispose() {
    _disposed = true;
    _generation += 1;
    _timer?.cancel();
    _timer = null;
    _candidate = null;
  }
}
