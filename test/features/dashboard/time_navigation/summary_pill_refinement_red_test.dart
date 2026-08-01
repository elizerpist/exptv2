import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_pill_presenter.dart';

class _DelayedQueryRepository implements DashboardLedgerRepository {
  final pending = <String, Completer<DashboardLedgerResult>>{};

  @override
  Future<DashboardLedgerResult> read(CurrentLedgerQueryScope scope) {
    final completer = Completer<DashboardLedgerResult>();
    pending[scope.key.value] = completer;
    return completer.future;
  }
}

DashboardTimeNavigationController _navigation({
  required TimePlane plane,
  required bool railOpen,
}) {
  return DashboardTimeNavigationController(
    initialDate: DateTime(2026, 5, 14),
    initialPlane: plane,
    initialRailOpen: railOpen,
    yearAnchor: 2026,
  );
}

void main() {
  test('plane ring wraps upward and preserves the month cursor', () {
    final controller = _navigation(plane: TimePlane.month, railOpen: false);
    addTearDown(controller.dispose);

    final planes = <TimePlane>[];
    for (var index = 0; index < 4; index += 1) {
      controller.moveToFinerPlane();
      planes.add(controller.state.plane);
    }

    expect(planes, <TimePlane>[
      TimePlane.sum,
      TimePlane.year,
      TimePlane.month,
      TimePlane.sum,
    ]);
    expect(controller.state.monthCursor, const YearMonth(year: 2026, month: 5));
  });

  test('plane ring wraps downward and preserves the year cursor', () {
    final controller = _navigation(plane: TimePlane.sum, railOpen: false);
    addTearDown(controller.dispose);

    final planes = <TimePlane>[];
    for (var index = 0; index < 4; index += 1) {
      controller.moveToBroaderPlane();
      planes.add(controller.state.plane);
    }

    expect(planes, <TimePlane>[
      TimePlane.month,
      TimePlane.year,
      TimePlane.sum,
      TimePlane.month,
    ]);
    expect(controller.state.yearCursor, 2026);
  });

  test('navigation presenter uses plane title and child-only subtitle', () {
    final controller = _navigation(plane: TimePlane.year, railOpen: true);
    addTearDown(controller.dispose);
    controller.settleChildLogicalIndex(4);

    final viewModel = SummaryPillPresenter.present(
      navigation: controller.state,
      query: DashboardQueryState(
        scope: CurrentLedgerQueryScope(
          direction: LedgerDirection.expense,
          timeScope: controller.state.effectiveScope,
        ),
        isLoading: false,
        result: const DashboardLedgerResult(totalMinor: 12345),
        error: null,
      ),
    );

    expect(viewModel.planeLabel, 'Éves');
    expect(viewModel.periodLabel, '2026. május');
  });

  test(
    'amount projection keeps the previous amount visible while loading',
    () async {
      final repository = _DelayedQueryRepository();
      final controller = CurrentQueryController(
        repository: repository,
        initialScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const AllTimeScope(),
        ),
      );
      addTearDown(controller.dispose);

      controller.setTimeScope(const YearScope(2026));
      final firstKey = repository.pending.keys.single;
      repository.pending[firstKey]!.complete(
        const DashboardLedgerResult(totalMinor: 12345),
      );
      await Future<void>.value();

      controller.setTimeScope(
        const MonthScope(YearMonth(year: 2026, month: 5)),
      );

      expect(controller.state.isLoading, isTrue);
      expect(controller.state.result?.totalMinor, 12345);
    },
  );
}
