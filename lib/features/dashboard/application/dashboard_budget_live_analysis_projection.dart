import 'package:flutter/foundation.dart';

import '../query/domain/ledger_direction.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_live_interaction_coordinator.dart';

/// Typed, immutable Budget-analysis input derived from the canonical live
/// interaction provenance. It is deliberately not a navigation or target
/// store: the temporal candidate belongs to [DashboardLiveInteractionFrame]
/// and the target handle is still owned by Budget presentation.
///
/// A retained [DashboardVisibleFrame] is used only until the first accepted
/// direct interaction (and for revision reconciliation). Once present, the
/// interaction frame is the foreground temporal authority even while a LogBox
/// scene for the same scope is still being prepared.
@immutable
final class DashboardBudgetLiveAnalysisProjection {
  const DashboardBudgetLiveAnalysisProjection._({
    required this.interactionGeneration,
    required this.coreRevision,
    required this.direction,
    required this.scope,
    required this.targetHandle,
    required this.isLiveInteraction,
  });

  const DashboardBudgetLiveAnalysisProjection.unavailable({
    required this.direction,
    required this.targetHandle,
  }) : interactionGeneration = 0,
       coreRevision = null,
       scope = null,
       isLiveInteraction = false;

  final int interactionGeneration;
  final int? coreRevision;
  final LedgerDirection direction;
  final LedgerTimeScope? scope;
  final int targetHandle;
  final bool isLiveInteraction;

  bool get isAvailable => coreRevision != null && scope != null;

  String get provenanceKey =>
      'generation:$interactionGeneration|revision:${coreRevision ?? '-'}|'
      'direction:${direction.name}|scope:${scope?.canonicalKey ?? '-'}|'
      'target:$targetHandle';

  /// Resolves the current immediate analysis input without copying temporal
  /// state. A live frame is intentionally preferred over scene coverage.
  factory DashboardBudgetLiveAnalysisProjection.resolve({
    required DashboardLiveInteractionFrame? liveInteraction,
    required DashboardVisibleFrame? visibleFrame,
    required int? preparedCoreRevision,
    required LedgerDirection selectedDirection,
    required int selectedTargetHandle,
  }) {
    final live = liveInteraction;
    if (live != null &&
        live.coreRevision != null &&
        live.coreRevision == preparedCoreRevision &&
        live.direction == selectedDirection &&
        (live.budgetTargetHandle == null ||
            live.budgetTargetHandle == selectedTargetHandle)) {
      return DashboardBudgetLiveAnalysisProjection._(
        interactionGeneration: live.generation,
        coreRevision: live.coreRevision,
        direction: live.direction,
        scope: live.temporalCandidate.effectiveScope,
        targetHandle: live.budgetTargetHandle ?? selectedTargetHandle,
        isLiveInteraction: true,
      );
    }
    final visible = visibleFrame;
    if (visible != null && visible.coreRevision == preparedCoreRevision) {
      return DashboardBudgetLiveAnalysisProjection._(
        interactionGeneration: 0,
        coreRevision: visible.coreRevision,
        direction: selectedDirection,
        scope: visible.scope.timeScope,
        targetHandle: selectedTargetHandle,
        isLiveInteraction: false,
      );
    }
    return DashboardBudgetLiveAnalysisProjection.unavailable(
      direction: selectedDirection,
      targetHandle: selectedTargetHandle,
    );
  }
}
