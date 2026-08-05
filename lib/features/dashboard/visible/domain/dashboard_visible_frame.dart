import 'package:flutter/foundation.dart';

import '../../logbox/application/dashboard_log_viewport_state.dart';
import '../../prepared/domain/dashboard_prepared_deck.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../../time_navigation/domain/time_plane.dart';

enum DashboardVisibleMode { preview, committed }

/// The only complete dashboard snapshot consumed by visible presentation.
@immutable
final class DashboardVisibleFrame {
  const DashboardVisibleFrame._({
    required this.preparedFrame,
    required this.scope,
    required this.queryKey,
    required this.parentQueryKey,
    required this.plane,
    required this.railOpen,
    required this.semanticChildIndex,
    required this.childLabel,
    required this.direction,
    required this.coreRevision,
    required this.amount,
    required this.count,
    required this.logBox,
    required this.presentationEpoch,
    required this.frameGeneration,
    required this.navigationEpoch,
    required this.mode,
    required this.visualDigest,
  });

  factory DashboardVisibleFrame.fromPrepared(
    DashboardPreparedFrame frame, {
    required LedgerQueryKey parentQueryKey,
    required TimePlane plane,
    required bool railOpen,
    required int semanticIndex,
    required String childLabel,
    required int navigationEpoch,
    required int presentationEpoch,
    required int frameGeneration,
    required DashboardVisibleMode mode,
  }) {
    if (frame.queryKey != frame.amount.queryKey ||
        frame.queryKey != frame.count.queryKey ||
        frame.queryKey != frame.logBox.queryKey ||
        frame.coreRevision != frame.amount.coreRevision ||
        frame.coreRevision != frame.count.coreRevision ||
        frame.coreRevision != frame.logBox.revision ||
        frame.parentQueryKey != parentQueryKey) {
      throw ArgumentError(
        'Visible amount, count and LogBox must share one key and revision.',
      );
    }
    return DashboardVisibleFrame._(
      preparedFrame: frame,
      scope: frame.scope,
      queryKey: frame.queryKey,
      parentQueryKey: parentQueryKey,
      plane: plane,
      railOpen: railOpen,
      semanticChildIndex: semanticIndex,
      childLabel: childLabel,
      direction: frame.scope.direction,
      coreRevision: frame.coreRevision,
      amount: frame.amount,
      count: frame.count,
      logBox: frame.logBox,
      presentationEpoch: presentationEpoch,
      frameGeneration: frameGeneration,
      navigationEpoch: navigationEpoch,
      mode: mode,
      visualDigest: Object.hash(
        frame.queryKey,
        frame.coreRevision,
        frame.presentationDigest,
        parentQueryKey,
        plane,
        railOpen,
        semanticIndex,
        childLabel,
      ),
    );
  }

  final DashboardPreparedFrame preparedFrame;
  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey queryKey;
  final LedgerQueryKey parentQueryKey;
  final TimePlane plane;
  final bool railOpen;
  final int semanticChildIndex;
  final String childLabel;
  final LedgerDirection direction;
  final int coreRevision;
  final DashboardAmountViewModel amount;
  final DashboardCountViewModel count;
  final DashboardLogViewportState logBox;
  final int presentationEpoch;
  final int frameGeneration;
  final int navigationEpoch;
  final DashboardVisibleMode mode;
  final int visualDigest;

  DashboardVisibleFrame asCommitted() {
    if (mode == DashboardVisibleMode.committed) return this;
    return DashboardVisibleFrame._(
      preparedFrame: preparedFrame,
      scope: scope,
      queryKey: queryKey,
      parentQueryKey: parentQueryKey,
      plane: plane,
      railOpen: railOpen,
      semanticChildIndex: semanticChildIndex,
      childLabel: childLabel,
      direction: direction,
      coreRevision: coreRevision,
      amount: amount,
      count: count,
      logBox: logBox,
      presentationEpoch: presentationEpoch,
      frameGeneration: frameGeneration,
      navigationEpoch: navigationEpoch,
      mode: DashboardVisibleMode.committed,
      visualDigest: visualDigest,
    );
  }
}
