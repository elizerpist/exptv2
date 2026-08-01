import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_pill_presenter.dart';

DashboardQueryState _query(LedgerTimeScope scope, {int? totalMinor = 12345}) {
  return DashboardQueryState(
    scope: CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: scope,
    ),
    isLoading: false,
    result: totalMinor == null
        ? null
        : DashboardLedgerResult(totalMinor: totalMinor),
    error: null,
  );
}

DashboardTimeNavigationState _state({
  required TimePlane plane,
  required bool railOpen,
  int year = 2026,
  YearMonth month = const YearMonth(year: 2026, month: 5),
  int day = 14,
  int childYear = 2026,
  int childMonth = 5,
  int childDay = 14,
}) {
  return DashboardTimeNavigationState(
    plane: plane,
    isRailOpen: railOpen,
    yearCursor: year,
    monthCursor: month,
    dayCursor: day,
    settledChildYear: childYear,
    settledChildMonth: childMonth,
    settledChildDay: childDay,
    previewChild: null,
  );
}

void main() {
  test('closed SUM projects all-time label and active plane', () {
    final viewModel = SummaryPillPresenter.present(
      navigation: _state(plane: TimePlane.sum, railOpen: false),
      query: _query(const AllTimeScope()),
    );

    expect(viewModel.periodLabel, 'Összesen');
    expect(viewModel.planeLabel, 'Összesen');
    expect(viewModel.amountText, '123,45 Ft');
    expect(viewModel.isRailOpen, isFalse);
  });

  test('open YEAR projects the selected month, not the stale parent label', () {
    final viewModel = SummaryPillPresenter.present(
      navigation: _state(
        plane: TimePlane.year,
        railOpen: true,
        childMonth: 5,
      ),
      query: _query(const MonthScope(YearMonth(year: 2026, month: 5))),
    );

    expect(viewModel.periodLabel, '2026. május');
    expect(viewModel.planeLabel, 'Év');
  });

  test('open MONTH projects the selected day and preserves loading state', () {
    final query = _query(
      const DayScope(LocalDate(year: 2026, month: 5, day: 14)),
      totalMinor: null,
    );
    final viewModel = SummaryPillPresenter.present(
      navigation: _state(
        plane: TimePlane.month,
        railOpen: true,
        childDay: 14,
      ),
      query: DashboardQueryState(
        scope: query.scope,
        isLoading: true,
        result: query.result,
        error: null,
      ),
    );

    expect(viewModel.periodLabel, '2026. május 14.');
    expect(viewModel.planeLabel, 'Hónap');
    expect(viewModel.isLoading, isTrue);
    expect(viewModel.amountText, '—');
  });
}
