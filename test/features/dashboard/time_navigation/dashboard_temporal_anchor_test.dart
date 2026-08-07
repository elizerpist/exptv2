import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_anchor.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('initial temporal anchor is the only canonical Y-M-D snapshot', () {
    final controller = _controller(
      plane: TimePlane.year,
      date: DateTime(2026, 5, 14),
    );
    addTearDown(controller.dispose);

    expect(
      controller.state.temporalAnchor,
      isA<DashboardTemporalAnchor>()
          .having((value) => value.visibleYear, 'year', 2026)
          .having((value) => value.visibleMonth, 'month', 5)
          .having((value) => value.visibleDay, 'day', 14)
          .having((value) => value.sourcePlane, 'source plane', TimePlane.year)
          .having((value) => value.sourceChildOrdinal, 'child', 5),
    );
    expect(controller.state.yearCursor, 2026);
    expect(controller.state.monthCursor, const YearMonth(year: 2026, month: 5));
    expect(controller.state.retainedChildMonth, 5);
  });

  test('Year 2024 then 2026 targets Month 2026 on the first commit', () {
    final controller = _controller(
      plane: TimePlane.year,
      date: DateTime(2026, 5, 14),
    );
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    controller.commitParent(DashboardTimeNavigationChangeDirection.backward);
    controller.commitParent(DashboardTimeNavigationChangeDirection.backward);
    expect(controller.state.temporalAnchor.visibleYear, 2024);
    controller.commitParent(DashboardTimeNavigationChangeDirection.forward);
    controller.commitParent(DashboardTimeNavigationChangeDirection.forward);
    expect(controller.state.temporalAnchor.visibleYear, 2026);
    final beforePlaneCommit = notifications;

    controller.commitPlane(finer: true);

    expect(notifications, beforePlaneCommit + 1);
    expect(controller.state.plane, TimePlane.month);
    expect(
      controller.state.parentScope,
      const MonthScope(YearMonth(year: 2026, month: 5)),
    );
    expect(controller.state.temporalAnchor.visibleYear, 2026);
    expect(controller.state.temporalAnchor.visibleMonth, 5);
    expect(
      controller.state.temporalAnchor.sourceParentQueryKey,
      controller.state.parentQueryKey,
    );
  });

  test('settled May in Year plane becomes Month 2026-05', () {
    final controller = _controller(
      plane: TimePlane.year,
      railOpen: true,
      date: DateTime(2026, 7, 14),
    );
    addTearDown(controller.dispose);

    expect(
      controller.retainSettledChild(
        value: 5,
        expectedNavigationEpoch: controller.state.navigationEpoch,
        coreRevision: 2,
      ),
      isTrue,
    );
    controller.commitPlane(finer: true);

    expect(
      controller.state.parentScope,
      const MonthScope(YearMonth(year: 2026, month: 5)),
    );
    expect(controller.state.temporalAnchor.revision, 2);
  });

  test('Month 2026-07 to Year and back retains July', () {
    final controller = _controller(
      plane: TimePlane.month,
      date: DateTime(2026, 7, 14),
    );
    addTearDown(controller.dispose);

    controller.commitPlane(finer: false);
    expect(controller.state.plane, TimePlane.year);
    expect(controller.state.parentScope, const YearScope(2026));
    expect(controller.state.retainedChildMonth, 7);

    controller.commitPlane(finer: true);
    expect(
      controller.state.parentScope,
      const MonthScope(YearMonth(year: 2026, month: 7)),
    );
  });

  test('Year to SUM and back preserves the canonical selected year', () {
    final controller = _controller(
      plane: TimePlane.year,
      date: DateTime(2026, 5, 14),
    );
    addTearDown(controller.dispose);
    controller.commitParent(DashboardTimeNavigationChangeDirection.backward);
    controller.commitParent(DashboardTimeNavigationChangeDirection.backward);
    expect(controller.state.temporalAnchor.visibleYear, 2024);

    controller.commitPlane(finer: false);
    expect(controller.state.plane, TimePlane.sum);
    expect(controller.state.retainedChildYear, 2024);

    controller.commitPlane(finer: true);
    expect(controller.state.plane, TimePlane.year);
    expect(controller.state.parentScope, const YearScope(2024));
    expect(controller.state.temporalAnchor.visibleYear, 2024);
  });

  test('stale settle cannot overwrite the newest anchor epoch', () {
    final controller = _controller(
      plane: TimePlane.year,
      railOpen: true,
      date: DateTime(2024, 5, 14),
    );
    addTearDown(controller.dispose);
    final staleEpoch = controller.state.navigationEpoch;

    controller.commitParent(DashboardTimeNavigationChangeDirection.forward);
    controller.commitParent(DashboardTimeNavigationChangeDirection.forward);
    final latest = controller.state.temporalAnchor;

    expect(
      controller.retainSettledChild(
        value: 1,
        expectedNavigationEpoch: staleEpoch,
      ),
      isFalse,
    );
    expect(controller.state.temporalAnchor, same(latest));
    expect(controller.state.temporalAnchor.visibleYear, 2026);
  });

  test('direction and rail visibility preserve the temporal anchor target', () {
    for (final railOpen in <bool>[false, true]) {
      final controller = _controller(
        plane: TimePlane.year,
        railOpen: railOpen,
        date: DateTime(2026, 5, 14),
      );
      addTearDown(controller.dispose);
      final filterIdentity =
          controller.state.temporalAnchor.filtersRefinementsIdentity;

      controller.selectDirection(LedgerDirection.expense);
      controller.commitPlane(finer: true);

      expect(
        controller.state.parentScope,
        const MonthScope(YearMonth(year: 2026, month: 5)),
      );
      expect(
        controller.state.temporalAnchor.direction,
        LedgerDirection.expense,
      );
      expect(
        controller.state.temporalAnchor.filtersRefinementsIdentity,
        filterIdentity,
      );
    }
  });
}

DashboardNavigationController _controller({
  required TimePlane plane,
  required DateTime date,
  bool railOpen = false,
}) => DashboardNavigationController(
  initialDate: date,
  initialPlane: plane,
  initialRailOpen: railOpen,
);
