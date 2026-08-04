import 'package:flutter/foundation.dart';

enum DashboardRailMotionOrigin { userDrag, userFling, programmatic }

@immutable
class DashboardRailMotionEpoch {
  const DashboardRailMotionEpoch({
    required this.id,
    required this.origin,
    required this.startedAt,
  });

  final int id;
  final DashboardRailMotionOrigin origin;
  final DateTime startedAt;
}

/// Semantic dashboard motion state layered over the existing carousel.
///
/// This coordinator never owns pixels, physics, a controller or a scroll
/// activity. It only gives background presentation work a latest-wins epoch
/// and deduplicates semantic idle/settle notifications.
class DashboardRailMotionCoordinator {
  DashboardRailMotionCoordinator({this.onMotionStarted});

  final ValueChanged<DashboardRailMotionEpoch>? onMotionStarted;

  int _nextEpoch = 0;
  DashboardRailMotionEpoch? _current;
  bool _idlePublished = false;
  bool _settlePublished = false;
  int _duplicateIdleDroppedCount = 0;
  int _duplicateSettleDroppedCount = 0;

  DashboardRailMotionEpoch? get currentEpoch => _current;
  bool get isMotionActive => _current != null && !_idlePublished;
  int get duplicateIdleDroppedCount => _duplicateIdleDroppedCount;
  int get duplicateSettleDroppedCount => _duplicateSettleDroppedCount;

  int begin({required DashboardRailMotionOrigin origin}) {
    final epoch = DashboardRailMotionEpoch(
      id: ++_nextEpoch,
      origin: origin,
      startedAt: DateTime.now(),
    );
    _current = epoch;
    _idlePublished = false;
    _settlePublished = false;
    onMotionStarted?.call(epoch);
    return epoch.id;
  }

  bool isCurrent(int epochId) => _current?.id == epochId;

  bool publishIdle({required int epoch, required int logicalIndex}) {
    if (!isCurrent(epoch) || _idlePublished) {
      _duplicateIdleDroppedCount += 1;
      return false;
    }
    _idlePublished = true;
    return true;
  }

  bool publishSettle({required int epoch, required int logicalIndex}) {
    if (!isCurrent(epoch) || _settlePublished) {
      _duplicateSettleDroppedCount += 1;
      return false;
    }
    _settlePublished = true;
    return true;
  }
}
