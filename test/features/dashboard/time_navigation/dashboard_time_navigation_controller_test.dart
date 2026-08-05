import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('navigation state contains structural identity and no preview lane', () {
    final controller = _controller();
    addTearDown(controller.dispose);

    expect(controller.state.parentQueryKey.value, startsWith('income|'));
    expect(controller.state.parentScope, const AllTimeScope());
    expect(controller.state.retainedSemanticChild, 2026);
    expect(controller.state.navigationEpoch, 0);
  });

  test(
    'rail open is structural but settle retention emits no notification',
    () {
      final controller = _controller();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.setRailOpen(true);
      final epoch = controller.state.navigationEpoch;
      expect(notifications, 1);

      expect(
        controller.retainSettledChild(
          value: 2028,
          expectedNavigationEpoch: epoch,
        ),
        isTrue,
      );
      expect(controller.state.retainedSemanticChild, 2028);
      expect(notifications, 1, reason: 'settle is a visual no-op');
    },
  );

  test('stale settle cannot mutate a replaced navigation target', () {
    final controller = _controller(
      plane: TimePlane.month,
      railOpen: true,
      date: DateTime(2026, 7, 31),
    );
    addTearDown(controller.dispose);
    final staleEpoch = controller.state.navigationEpoch;

    controller.commitParent(DashboardTimeNavigationChangeDirection.backward);

    expect(
      controller.retainSettledChild(
        value: 1,
        expectedNavigationEpoch: staleEpoch,
      ),
      isFalse,
    );
    expect(controller.state.retainedSemanticChild, 30);
  });

  test('July day 31 to June clamps to day 30', () {
    final controller = _controller(
      plane: TimePlane.month,
      railOpen: true,
      date: DateTime(2026, 7, 31),
    );
    addTearDown(controller.dispose);

    controller.commitParent(DashboardTimeNavigationChangeDirection.backward);

    expect(
      controller.state.parentScope,
      const MonthScope(YearMonth(year: 2026, month: 6)),
    );
    expect(
      controller.state.retainedChildScope,
      const DayScope(LocalDate(year: 2026, month: 6, day: 30)),
    );
  });

  test('June day 30 to July preserves day 30', () {
    final controller = _controller(
      plane: TimePlane.month,
      railOpen: true,
      date: DateTime(2026, 6, 30),
    );
    addTearDown(controller.dispose);

    controller.commitParent(DashboardTimeNavigationChangeDirection.forward);

    expect(
      controller.state.parentScope,
      const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    expect(controller.state.retainedSemanticChild, 30);
  });

  test('year parent navigation preserves retained May and December', () {
    final may = _controller(
      plane: TimePlane.year,
      railOpen: true,
      date: DateTime(2025, 5, 14),
    );
    addTearDown(may.dispose);
    may.commitParent(DashboardTimeNavigationChangeDirection.forward);
    expect(may.state.parentScope, const YearScope(2026));
    expect(may.state.retainedChildMonth, 5);

    final december = _controller(
      plane: TimePlane.year,
      railOpen: true,
      date: DateTime(2026, 12, 14),
    );
    addTearDown(december.dispose);
    december.commitParent(DashboardTimeNavigationChangeDirection.backward);
    expect(december.state.parentScope, const YearScope(2025));
    expect(december.state.retainedChildMonth, 12);
  });

  test('parent candidate is read-only and uses the exact future key', () {
    final controller = _controller(
      plane: TimePlane.month,
      railOpen: true,
      date: DateTime(2026, 12, 31),
    );
    addTearDown(controller.dispose);
    final before = controller.state;

    final candidate = controller.parentCandidate(
      DashboardTimeNavigationChangeDirection.forward,
    );

    expect(candidate?.monthCursor, const YearMonth(year: 2027, month: 1));
    expect(candidate?.parentQueryKey.value, contains('month:2027-01'));
    expect(controller.state, same(before));
  });

  test('plane transitions preserve semantic child intent', () {
    final controller = _controller(railOpen: true);
    addTearDown(controller.dispose);
    controller.retainSettledChild(
      value: 2028,
      expectedNavigationEpoch: controller.state.navigationEpoch,
    );

    controller.commitPlane(finer: true);
    expect(controller.state.plane, TimePlane.year);
    expect(controller.state.parentScope, const YearScope(2028));
    expect(controller.state.retainedChildMonth, 5);

    controller.commitPlane(finer: true);
    expect(controller.state.plane, TimePlane.month);
    expect(
      controller.state.parentScope,
      const MonthScope(YearMonth(year: 2028, month: 5)),
    );
  });

  test('direction changes exact key but preserves time navigation', () {
    final controller = _controller(
      plane: TimePlane.month,
      railOpen: true,
      date: DateTime(2026, 7, 31),
    );
    addTearDown(controller.dispose);
    final timeScope = controller.state.parentScope;

    controller.selectDirection(LedgerDirection.expense);

    expect(controller.state.parentScope, timeScope);
    expect(
      controller.state.parentQueryScope.direction,
      LedgerDirection.expense,
    );
    expect(controller.state.parentQueryKey.value, startsWith('expense|'));
  });

  test('seed demo navigation uses the same structural month intent', () {
    final controller = _controller(plane: TimePlane.month);
    addTearDown(controller.dispose);

    controller.navigateToMonth(const YearMonth(year: 2026, month: 7));

    expect(controller.state.isRailOpen, isFalse);
    expect(
      controller.state.parentScope,
      const MonthScope(YearMonth(year: 2026, month: 7)),
    );
  });
}

DashboardNavigationController _controller({
  bool railOpen = false,
  TimePlane plane = TimePlane.sum,
  DateTime? date,
}) => DashboardNavigationController(
  initialDate: date ?? DateTime(2026, 5, 14),
  initialPlane: plane,
  initialRailOpen: railOpen,
);
