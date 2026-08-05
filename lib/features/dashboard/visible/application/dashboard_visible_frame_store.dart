import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../domain/dashboard_visible_frame.dart';

/// Sole notifier for the complete visible dashboard presentation snapshot.
///
/// Every notified value already contains amount, count and LogBox data for one
/// exact QueryKey/revision. Commit promotion changes ownership metadata only
/// and intentionally emits no visual notification.
final class DashboardVisibleFrameStore extends ChangeNotifier
    implements ValueListenable<DashboardVisibleFrame?> {
  DashboardVisibleFrame? _value;
  int _generationCursor = 0;

  @override
  DashboardVisibleFrame? get value => _value;

  int visiblePublishCount = 0;
  int staleFrameRejectCount = 0;
  int visualNoOpCount = 0;
  int committedPromotionCount = 0;

  /// These remain explicit proof counters: neither operation belongs here.
  int logRebindCount = 0;
  int amountRestartCount = 0;

  /// Issues the one process-local ordering token shared by prepared previews
  /// and committed-live frames.
  ///
  /// Keeping allocation beside the sole visible-frame store prevents two
  /// publishers from independently producing the same generation and making
  /// a newer semantic target look stale.
  int nextFrameGeneration() {
    final visibleGeneration = _value?.frameGeneration ?? 0;
    if (_generationCursor < visibleGeneration) {
      _generationCursor = visibleGeneration;
    }
    _generationCursor += 1;
    return _generationCursor;
  }

  bool publish(DashboardVisibleFrame frame) {
    final current = _value;
    if (current != null && _isStale(frame, current)) {
      staleFrameRejectCount += 1;
      return false;
    }

    if (current != null &&
        frame.queryKey == current.queryKey &&
        frame.coreRevision == current.coreRevision &&
        frame.visualDigest == current.visualDigest) {
      if (frame.presentationEpoch > current.presentationEpoch ||
          frame.navigationEpoch > current.navigationEpoch ||
          frame.frameGeneration > current.frameGeneration) {
        _value = frame;
      }
      visualNoOpCount += 1;
      return false;
    }

    _value = frame;
    visiblePublishCount += 1;
    notifyListeners();
    return true;
  }

  bool promoteCommitted({
    required LedgerQueryKey expectedKey,
    required int epoch,
  }) {
    final current = _value;
    if (current == null ||
        current.queryKey != expectedKey ||
        current.presentationEpoch != epoch ||
        current.mode == DashboardVisibleMode.committed) {
      return false;
    }
    _value = current.asCommitted();
    committedPromotionCount += 1;
    return true;
  }

  static bool _isStale(
    DashboardVisibleFrame candidate,
    DashboardVisibleFrame current,
  ) {
    if (candidate.presentationEpoch < current.presentationEpoch ||
        candidate.navigationEpoch < current.navigationEpoch ||
        candidate.coreRevision < current.coreRevision) {
      return true;
    }
    if (candidate.presentationEpoch != current.presentationEpoch ||
        candidate.navigationEpoch != current.navigationEpoch) {
      return false;
    }
    if (candidate.frameGeneration < current.frameGeneration) return true;
    return candidate.frameGeneration == current.frameGeneration &&
        (candidate.queryKey != current.queryKey ||
            candidate.coreRevision != current.coreRevision ||
            candidate.visualDigest != current.visualDigest ||
            candidate.mode != current.mode);
  }
}
