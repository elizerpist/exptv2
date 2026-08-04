import '../../query/application/current_query_controller.dart';
import '../../query/domain/scope_summary_metrics.dart';
import '../application/dashboard_time_navigation_state.dart';
import 'summary_pill_view_model.dart';
import 'summary_metrics_presentation.dart';
import 'summary_navigation_presentation.dart';

abstract final class SummaryPillPresenter {
  static SummaryNavigationPresentation presentNavigation({
    required DashboardTimeNavigationState navigation,
    bool? isPreview,
  }) {
    return SummaryNavigationProjector.project(navigation, isPreview: isPreview);
  }

  static SummaryMetricsPresentation presentMetrics({
    required DashboardQueryState query,
  }) {
    final result = query.result;
    final isExactScope = result?.scopeKey == query.scope.key.value;
    final metrics = ScopeSummaryMetrics(
      scope: query.scope,
      canonicalQueryKey: query.scope.key.value,
      coreRevision: isExactScope ? result?.coreRevision : null,
      totalMinor: isExactScope ? result?.totalMinor : null,
      entryCount: isExactScope ? result?.entryCount : null,
      source: isExactScope
          ? SummaryMetricsSource.freshQuery
          : SummaryMetricsSource.stalePreviousValue,
      isLoading: query.isLoading || !isExactScope,
      isStale: result != null && !isExactScope,
      hasError: query.error != null,
    );
    return SummaryMetricsPresentation.fromMetrics(metrics);
  }

  static SummaryPillViewModel present({
    required DashboardTimeNavigationState navigation,
    required DashboardQueryState query,
  }) {
    final navigationPresentation = presentNavigation(navigation: navigation);
    final metricsPresentation = presentMetrics(query: query);
    return SummaryPillViewModel(
      plane: navigation.plane,
      periodLabel: navigationPresentation.subtitle,
      planeLabel: navigationPresentation.planeTitle,
      amountText: metricsPresentation.formattedAmount,
      isRailOpen: navigation.isRailOpen,
      isLoading: metricsPresentation.isLoading,
      hasError: metricsPresentation.hasError,
    );
  }

  /// Shared amount formatter for detailed and child-index snapshots.
  static String formatTotalMinor(int totalMinor) =>
      SummaryMetricsPresentation.formatTotalMinor(totalMinor);
}
