import '../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import 'dashboard_budget_presentation_controller.dart';
import 'dashboard_core_controller.dart';
import 'dashboard_ephemeral_focus_controller.dart';

/// Composition-only bridge from explicit Budget analysis intents to the one
/// existing Core ephemeral-focus publication path. It owns no Query, focus
/// state, repository, paging or carousel selection.
final class DashboardBudgetLogboxDrilldownCoordinator {
  const DashboardBudgetLogboxDrilldownCoordinator({required this.core});

  final DashboardCoreController core;

  /// Publishes one already-prepared avatar target on the same generation-safe
  /// focus path as settlement. It is invoked only for discrete carousel
  /// crossings; the core publishes its prepared Summary amount immediately
  /// and rejects stale completion before the atomic Ledger scene can rotate.
  Future<bool> previewBudgetTarget({
    required DashboardBudgetPresentationState state,
  }) => commitBudgetTarget(state: state, source: 'avatarPreview');

  Future<bool> commitBudgetTarget({
    required DashboardBudgetPresentationState state,
    required String source,
  }) {
    final target = state.liveSelection.target;
    _record(
      source: source,
      targetHandle: target.handle,
      categoryId: target.category?.id,
    );
    if (target.isAggregate) {
      return core.clearAllEphemeralFocus(deferSceneInstallation: true);
    }
    final category = target.category!;
    return core.requestBudgetCategoryFocus(
      DashboardFocusFacet(
        id: category.id,
        displayName: category.displayName,
        colorId: category.colorId,
        iconId: category.iconId,
      ),
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
