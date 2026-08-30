import 'package:flutter/foundation.dart';

import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import 'dashboard_budget_presentation_controller.dart';
import 'dashboard_budget_target.dart';
import 'dashboard_core_controller.dart';
import 'dashboard_ephemeral_focus_controller.dart';

/// Composition-only bridge from explicit Budget analysis intents to the one
/// existing Core ephemeral-focus publication path. It owns no Query, focus
/// state, repository, paging or carousel selection.
final class DashboardBudgetLogboxDrilldownCoordinator {
  const DashboardBudgetLogboxDrilldownCoordinator({
    required this.core,
    this.presentation,
  });

  final DashboardCoreController core;
  final DashboardBudgetPresentationController? presentation;

  ValueListenable<bool> get liveTargetReadiness =>
      core.budgetAvatarLiveRootReady;

  /// Prepares only the rail's fixed local semantic horizon. This adapter owns
  /// target-to-facet translation; the Core remains the sole owner of the
  /// reusable prepared-focus cache and its validity boundary.
  void primeBudgetTargetHotset(Iterable<int> targetHandles) {
    final targets = <DashboardFocusFacet>[];
    for (final handle in targetHandles) {
      final category = presentation?.targetForHandle(handle)?.category;
      if (category == null) continue;
      targets.add(
        DashboardFocusFacet(
          id: category.id,
          displayName: category.displayName,
          colorId: category.colorId,
          iconId: category.iconId,
        ),
      );
    }
    core.primeBudgetAvatarFocusHotset(targets);
  }

  /// Publishes one already-prepared avatar target on the same generation-safe
  /// focus path as settlement. It is invoked only for discrete carousel
  /// crossings; the core publishes its prepared Summary amount immediately
  /// and rejects stale completion before the atomic Ledger scene can rotate.
  Future<bool> previewBudgetTarget({
    int? targetHandle,
    DashboardBudgetPresentationState? state,
  }) {
    final target = targetHandle == null
        ? state?.liveSelection.target
        : presentation?.targetForHandle(targetHandle);
    if (target == null) return Future<bool>.value(false);
    return _commitTarget(
      target: target,
      source: 'avatarPreview',
      publishDuringMotion: true,
    );
  }

  /// Derives the Budget target and its Query facet from one prepared target,
  /// then promotes Budget presentation only in the matching visible Query
  /// publication callback. No caller may independently publish a Header for a
  /// target whose LogBox scene still represents another category.
  Future<bool> commitBudgetTargetHandle({
    required int targetHandle,
    required String source,
    bool publishDuringMotion = false,
  }) {
    final target = presentation?.targetForHandle(targetHandle);
    if (target == null) return Future<bool>.value(false);
    return _commitTarget(
      target: target,
      source: source,
      publishDuringMotion: publishDuringMotion,
    );
  }

  Future<bool> _commitTarget({
    required DashboardBudgetTarget target,
    required String source,
    required bool publishDuringMotion,
  }) {
    _record(
      source: source,
      targetHandle: target.handle,
      categoryId: target.category?.id,
    );
    if (target.isAggregate) {
      return core.clearBudgetCategoryFocus(
        targetHandle: target.handle,
        publishDuringMotion: publishDuringMotion,
        onVisibleSemanticCommit: presentation == null
            ? null
            : () => presentation!.setTargetHandle(target.handle),
      );
    }
    final category = target.category!;
    return core.requestBudgetCategoryFocus(
      DashboardFocusFacet(
        id: category.id,
        displayName: category.displayName,
        colorId: category.colorId,
        iconId: category.iconId,
      ),
      publishDuringMotion: publishDuringMotion,
      targetHandle: target.handle,
      onVisibleSemanticCommit: presentation == null
          ? null
          : () => presentation!.setTargetHandle(target.handle),
    );
  }

  Future<bool> commitPartner({
    required DashboardFocusFacet partner,
    required String source,
    int? targetHandle,
  }) {
    _record(source: source, targetHandle: targetHandle, partnerId: partner.id);
    return core.requestPartnerFocus(partner);
  }

  void _record({
    required String source,
    int? targetHandle,
    String? categoryId,
    String? partnerId,
  }) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_LOGBOX_DRILLDOWN_REQUESTED',
        scope:
            'source=$source targetHandle=${targetHandle ?? '-'} '
            'categoryId=${categoryId ?? '-'} partnerId=${partnerId ?? '-'}',
      ),
    );
  }
}
