import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import 'dashboard_visible_frame.dart';

/// Lightweight authoritative metadata for one LogBox render binding.
///
/// A preview-to-committed settle may retain the exact same visual payload, so
/// its mode cannot be inferred from the payload lane. This identity is
/// published independently by [DashboardVisibleFrameStore].
@immutable
final class DashboardLogBoxPresentationBinding {
  const DashboardLogBoxPresentationBinding._({
    required this.mode,
    required this.queryKey,
    required this.coreRevision,
    required this.presentationEpoch,
    required this.viewportId,
  });

  factory DashboardLogBoxPresentationBinding.fromFrame(
    DashboardVisibleFrame frame,
  ) => DashboardLogBoxPresentationBinding._(
    mode: frame.mode,
    queryKey: frame.queryKey,
    coreRevision: frame.coreRevision,
    presentationEpoch: frame.presentationEpoch,
    viewportId: frame.logBox.viewportId,
  );

  final DashboardVisibleMode mode;
  final LedgerQueryKey queryKey;
  final int coreRevision;
  final int presentationEpoch;
  final int viewportId;

  @override
  bool operator ==(Object other) =>
      other is DashboardLogBoxPresentationBinding &&
      mode == other.mode &&
      queryKey == other.queryKey &&
      coreRevision == other.coreRevision &&
      presentationEpoch == other.presentationEpoch &&
      viewportId == other.viewportId;

  @override
  int get hashCode =>
      Object.hash(mode, queryKey, coreRevision, presentationEpoch, viewportId);
}
