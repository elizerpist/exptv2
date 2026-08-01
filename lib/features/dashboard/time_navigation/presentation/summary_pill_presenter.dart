import '../../query/application/current_query_controller.dart';
import '../application/dashboard_time_navigation_state.dart';
import '../domain/local_date.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';
import 'summary_pill_view_model.dart';

abstract final class SummaryPillPresenter {
  static SummaryPillViewModel present({
    required DashboardTimeNavigationState navigation,
    required DashboardQueryState query,
  }) {
    return SummaryPillViewModel(
      plane: navigation.plane,
      periodLabel: _periodLabel(navigation),
      planeLabel: _planeLabel(navigation.plane),
      amountText: _amountText(query),
      isRailOpen: navigation.isRailOpen,
      isLoading: query.isLoading,
      hasError: query.error != null,
    );
  }

  static String _periodLabel(DashboardTimeNavigationState state) {
    switch (state.plane) {
      case TimePlane.sum:
        return state.isRailOpen
            ? state.settledChildYear.toString()
            : 'Összesen';
      case TimePlane.year:
        if (!state.isRailOpen) return state.yearCursor.toString();
        return _formatYearMonth(
          YearMonth(
            year: state.yearCursor,
            month: state.settledChildMonth,
          ),
        );
      case TimePlane.month:
        if (!state.isRailOpen) return _formatYearMonth(state.monthCursor);
        return _formatDate(state.monthCursor.clampDay(state.settledChildDay));
    }
  }

  static String _planeLabel(TimePlane plane) => switch (plane) {
    TimePlane.sum => 'Összesen',
    TimePlane.year => 'Év',
    TimePlane.month => 'Hónap',
  };

  static String _formatYearMonth(YearMonth value) {
    return '${value.year}. ${_monthName(value.month)}';
  }

  static String _formatDate(LocalDate value) {
    return '${value.year}. ${_monthName(value.month)} ${value.day}.';
  }

  static String _monthName(int month) => const <String>[
    '',
    'január',
    'február',
    'március',
    'április',
    'május',
    'június',
    'július',
    'augusztus',
    'szeptember',
    'október',
    'november',
    'december',
  ][month];

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
