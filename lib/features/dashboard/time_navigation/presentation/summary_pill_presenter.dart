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
      flowId:
          query.result?.flowId ?? DashboardQueryDebug.flowIdFor(query.scope),
    );
    DashboardQueryDebug.mark(
      'D9 amountPresentationEmitted',
      scope: query.scope,
      result: query.result,
      flowId:
          query.result?.flowId ?? DashboardQueryDebug.flowIdFor(query.scope),
      formattedTotal: presentation.formattedAmount,
      detail:
          'formatted=${presentation.formattedAmount} '
          'loading=${presentation.isLoading} '
          'stale=${presentation.isStale} '
          'error=${presentation.hasError}',
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
    // A missing snapshot is not the same thing as an empty query result. The
    // latter has [totalMinor] == 0 and renders `0 Ft`; loading/error state
    // remains visibly provisional until Room has emitted a real slice.
    if (totalMinor == null) return '— Ft';
    return formatTotalMinor(totalMinor);
  }

  /// Shared amount formatter for both a detailed result and its compatible
  /// child-summary index. A valid zero is distinct from no result.
  static String formatTotalMinor(int totalMinor) {
    if (totalMinor == 0) return '0 Ft';
    final sign = totalMinor < 0 ? '-' : '';
    final absolute = totalMinor.abs();
    final major = absolute ~/ 100;
    final minor = (absolute % 100).toString().padLeft(2, '0');
    return '$sign$major,$minor Ft';
  }
}
