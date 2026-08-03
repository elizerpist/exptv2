import 'package:flutter/foundation.dart';

import '../../time_navigation/domain/time_plane.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';

/// The semantic identity the dashboard is allowed to render right now.
///
/// The target is separate from repository/request generations. Navigation may
/// change the visible target before the corresponding live lease is active;
/// the target therefore guards presentation selection independently of I/O.
@immutable
class DashboardVisiblePresentationTarget {
  const DashboardVisiblePresentationTarget({
    required this.plane,
    required this.parentQueryKey,
    required this.childQueryKey,
    required this.railOpen,
    required this.direction,
    required this.presentationEpoch,
  }) : assert(!railOpen || childQueryKey != null);

  final TimePlane plane;
  final LedgerQueryKey parentQueryKey;
  final LedgerQueryKey? childQueryKey;
  final bool railOpen;
  final LedgerDirection direction;
  final int presentationEpoch;

  LedgerQueryKey get expectedVisibleQueryKey =>
      railOpen && childQueryKey != null ? childQueryKey! : parentQueryKey;

  @override
  bool operator ==(Object other) =>
      other is DashboardVisiblePresentationTarget &&
      other.plane == plane &&
      other.parentQueryKey == parentQueryKey &&
      other.childQueryKey == childQueryKey &&
      other.railOpen == railOpen &&
      other.direction == direction &&
      other.presentationEpoch == presentationEpoch;

  @override
  int get hashCode => Object.hash(
    plane,
    parentQueryKey,
    childQueryKey,
    railOpen,
    direction,
    presentationEpoch,
  );
}
