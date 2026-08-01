import '../../query/application/current_query_controller.dart';
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
    return SummaryAmountPresentation(
      formattedAmount: _amountText(query),
      scopeKey: query.scope.key.value,
      isLoading: query.isLoading,
      isStale: query.result != null && (query.isLoading || query.error != null),
      hasError: query.error != null,
    );
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
    if (totalMinor == null) return '—';
    final sign = totalMinor < 0 ? '-' : '';
    final absolute = totalMinor.abs();
    final major = absolute ~/ 100;
    final minor = (absolute % 100).toString().padLeft(2, '0');
    return '$sign$major,$minor Ft';
  }
}
