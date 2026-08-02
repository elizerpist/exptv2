import '../../query/application/current_query_controller.dart';
import '../../query/application/dashboard_query_debug.dart';
import '../application/dashboard_time_navigation_state.dart';
import 'summary_pill_view_model.dart';
import 'summary_amount_presentation.dart';
import 'summary_navigation_presentation.dart';

abstract final class SummaryPillPresenter {
  static SummaryNavigationPresentation presentNavigation({
    required DashboardTimeNavigationState navigation,
  }) {
    return SummaryNavigationProjector.project(navigation);
  }

  static SummaryAmountPresentation presentAmount({
    required DashboardQueryState query,
  }) {
    final presentation = SummaryAmountPresentation(
      formattedAmount: _amountText(query),
      scopeKey: query.scope.key.value,
      isLoading: query.isLoading,
      isStale: query.result != null && (query.isLoading || query.error != null),
      hasError: query.error != null,
      entryCount: query.result?.entryCount ?? 0,
      coreRevision: query.result?.coreRevision,
      totalMinor: query.result?.totalMinor,
    );
    DashboardQueryDebug.mark(
      'D9 amountPresentationEmitted',
      scope: query.scope,
      result: query.result,
      detail: 'formatted=${presentation.formattedAmount}',
    );
    return presentation;
  }

  static SummaryPillViewModel present({
    required DashboardTimeNavigationState navigation,
    required DashboardQueryState query,
  }) {
    final navigationPresentation = presentNavigation(navigation: navigation);
    final amountPresentation = presentAmount(query: query);
    return SummaryPillViewModel(
      plane: navigation.plane,
      periodLabel: navigationPresentation.subtitle,
      planeLabel: navigationPresentation.planeTitle,
      amountText: amountPresentation.formattedAmount,
      isRailOpen: navigation.isRailOpen,
      isLoading: amountPresentation.isLoading,
      hasError: amountPresentation.hasError,
    );
  }

  static String _amountText(DashboardQueryState query) {
    final totalMinor = query.result?.totalMinor;
    // An empty/loading snapshot still has a meaningful zero amount for the
    // dashboard. Keep the amount region rendered while the real Room result
    // is on its way instead of replacing it with an empty em dash.
    if (totalMinor == null) return '0 Ft';
    final sign = totalMinor < 0 ? '-' : '';
    final absolute = totalMinor.abs();
    final major = absolute ~/ 100;
    final minor = (absolute % 100).toString().padLeft(2, '0');
    return '$sign$major,$minor Ft';
  }
}
