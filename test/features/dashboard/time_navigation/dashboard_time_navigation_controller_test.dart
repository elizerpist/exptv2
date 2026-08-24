import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_availability.dart';
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

  test(
    'settled primary targets stay canonical for axis and mother controls',
    () {
      final controller = _controller(
        plane: TimePlane.month,
        date: DateTime(2026, 7, 14),
      );
      addTearDown(controller.dispose);

      final plane = controller.planeTargetCandidate(TimePlane.year);
      expect(plane.plane, TimePlane.year);
      expect(plane.parentScope, const YearScope(2026));
      expect(controller.state.plane, TimePlane.month);

      final mother = controller.parentOffsetCandidate(3);
      expect(mother?.monthCursor, const YearMonth(year: 2026, month: 10));
      expect(
        controller.state.monthCursor,
        const YearMonth(year: 2026, month: 7),
      );

      controller.commitPlaneTargetCandidate(plane, finer: false);
      expect(controller.state.plane, TimePlane.year);
      expect(controller.parentOffsetCandidate(1)?.yearCursor, 2027);
    },
  );

  test('mother offsets fail closed outside the supported calendar range', () {
    final firstMonth = _controller(
      plane: TimePlane.month,
      date: DateTime(1, 1, 1),
    );
    final lastYear = _controller(
      plane: TimePlane.year,
      date: DateTime(9999, 12, 31),
    );
    addTearDown(firstMonth.dispose);
    addTearDown(lastYear.dispose);

    expect(firstMonth.parentOffsetCandidate(-1), isNull);
    expect(lastYear.parentOffsetCandidate(1), isNull);
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

  test('applying a restricted Query reconciles an excluded current child', () {
    final controller = _controller(
      plane: TimePlane.year,
      date: DateTime(2025, 7, 14),
    );
    addTearDown(controller.dispose);
    final filter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
      QueryPeriodSelection.month(2026, 2),
      QueryPeriodSelection.month(2026, 8),
    });

    controller.replaceAppliedQuery(
      CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        temporalFilter: filter,
      ),
      availability: DashboardTemporalAvailability.fromTemporalFilter(filter),
    );

    expect(controller.state.yearCursor, 2026);
    expect(controller.state.retainedChildMonth, 2);
    expect(controller.state.parentScope, const YearScope(2026));
    expect(controller.state.parentQueryScope.temporalFilter, filter);
  });

  test('removing a query restores unrestricted time availability', () {
    final controller = _controller(date: DateTime(2026, 2, 14));
    addTearDown(controller.dispose);

    controller.replaceAppliedQuery(
      CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
      ),
      availability: const DashboardTemporalAvailability.unrestricted(),
    );

    expect(controller.temporalAvailability.isRestrictive, isFalse);
  });

  test('restricted parent navigation wraps excluded years and months', () {
    final controller = _controller(
      plane: TimePlane.year,
      date: DateTime(2026, 2, 14),
    );
    addTearDown(controller.dispose);
    final filter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
      QueryPeriodSelection.month(2024, 11),
      QueryPeriodSelection.month(2026, 2),
      QueryPeriodSelection.month(2026, 8),
    });
    controller.replaceAppliedQuery(
      CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        temporalFilter: filter,
      ),
      availability: DashboardTemporalAvailability.fromTemporalFilter(filter),
    );

    expect(controller.selectedChildLogicalIndex, 0);
    controller.commitParent(DashboardTimeNavigationChangeDirection.backward);
    expect(controller.state.yearCursor, 2024);
    expect(controller.state.retainedChildMonth, 11);
    expect(
      controller.parentCandidate(
        DashboardTimeNavigationChangeDirection.backward,
      ),
      isNotNull,
    );
    expect(
      controller
          .parentCandidate(DashboardTimeNavigationChangeDirection.backward)
          ?.yearCursor,
      2026,
    );

    controller.commitPlane(finer: false);
    expect(controller.state.plane, TimePlane.sum);
    expect(controller.selectedChildLogicalIndex, 0);
  });

  test(
    'restricted month parents wrap through allowed semantic values only',
    () {
      final controller = _controller(
        plane: TimePlane.month,
        date: DateTime(2026, 6, 14),
      );
      addTearDown(controller.dispose);
      final filter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(2026, 1),
        QueryPeriodSelection.month(2026, 3),
        QueryPeriodSelection.month(2026, 8),
      });
      controller.replaceAppliedQuery(
        CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const AllTimeScope(),
          temporalFilter: filter,
        ),
        availability: DashboardTemporalAvailability.fromTemporalFilter(filter),
      );

      expect(
        controller.state.monthCursor,
        const YearMonth(year: 2026, month: 1),
      );
      expect(
        controller
            .parentCandidate(DashboardTimeNavigationChangeDirection.backward)
            ?.monthCursor,
        const YearMonth(year: 2026, month: 8),
      );
      expect(
        controller
            .parentCandidate(DashboardTimeNavigationChangeDirection.forward)
            ?.monthCursor,
        const YearMonth(year: 2026, month: 3),
      );

      controller.commitParent(DashboardTimeNavigationChangeDirection.backward);
      expect(
        controller.state.monthCursor,
        const YearMonth(year: 2026, month: 8),
      );
      controller.commitParent(DashboardTimeNavigationChangeDirection.forward);
      expect(
        controller.state.monthCursor,
        const YearMonth(year: 2026, month: 1),
      );
    },
  );

  test(
    'a single restricted parent does not create a self-navigation target',
    () {
      final controller = _controller(
        plane: TimePlane.month,
        date: DateTime(2026, 6, 14),
      );
      addTearDown(controller.dispose);
      final filter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(2026, 6),
      });
      controller.replaceAppliedQuery(
        CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const AllTimeScope(),
          temporalFilter: filter,
        ),
        availability: DashboardTemporalAvailability.fromTemporalFilter(filter),
      );

      expect(
        controller.parentCandidate(
          DashboardTimeNavigationChangeDirection.backward,
        ),
        isNull,
      );
      expect(
        controller.parentCandidate(
          DashboardTimeNavigationChangeDirection.forward,
        ),
        isNull,
      );
    },
  );

  test('restricted multi-offsets never resolve back to the current parent', () {
    final months = _controller(
      plane: TimePlane.month,
      date: DateTime(2026, 6, 14),
    );
    final years = _controller(
      plane: TimePlane.year,
      date: DateTime(2026, 6, 14),
    );
    addTearDown(months.dispose);
    addTearDown(years.dispose);

    final monthFilter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
      QueryPeriodSelection.month(2026, 1),
      QueryPeriodSelection.month(2026, 3),
      QueryPeriodSelection.month(2026, 8),
    });
    months.replaceAppliedQuery(
      CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        temporalFilter: monthFilter,
      ),
      availability: DashboardTemporalAvailability.fromTemporalFilter(
        monthFilter,
      ),
    );
    expect(
      months.parentOffsetCandidate(2)?.monthCursor,
      const YearMonth(year: 2026, month: 8),
    );
    expect(months.parentOffsetCandidate(3), isNull);
    expect(months.parentOffsetCandidate(-3), isNull);

    final yearFilter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
      QueryPeriodSelection.month(2024, 1),
      QueryPeriodSelection.month(2026, 1),
    });
    years.replaceAppliedQuery(
      CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: const AllTimeScope(),
        temporalFilter: yearFilter,
      ),
      availability: DashboardTemporalAvailability.fromTemporalFilter(
        yearFilter,
      ),
    );
    expect(years.parentOffsetCandidate(1)?.yearCursor, 2024);
    expect(years.parentOffsetCandidate(2), isNull);
    expect(years.parentOffsetCandidate(-2), isNull);
  });

  test('direct hierarchy targets reuse the canonical day child scope', () {
    final controller = _controller(
      plane: TimePlane.month,
      date: DateTime(2026, 1, 31),
    );
    addTearDown(controller.dispose);

    final day = controller.temporalCandidate(
      plane: TimePlane.month,
      isRailOpen: true,
    );
    controller.commitTemporalCandidate(day);
    expect(
      controller.state.effectiveScope,
      const DayScope(LocalDate(year: 2026, month: 1, day: 31)),
    );

    final february = controller.temporalComponentOffsetCandidate(
      plane: TimePlane.month,
      isRailOpen: true,
      component: DashboardTemporalAnchorComponent.month,
      offset: 1,
    );
    expect(february?.monthCursor, const YearMonth(year: 2026, month: 2));
    expect(february?.dayCursor, 28);
  });

  test(
    'one experimental fling stays anchored while each crossing publishes',
    () {
      final controller = _controller(
        plane: TimePlane.month,
        railOpen: true,
        date: DateTime(2026, 7, 14),
      );
      addTearDown(controller.dispose);
      final gestureOrigin = controller.state;

      final first = controller.temporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 1,
        base: gestureOrigin,
      )!;
      controller.commitTemporalCandidate(first);
      expect(controller.state.dayCursor, 15);

      final second = controller.temporalComponentOffsetCandidate(
        plane: TimePlane.month,
        isRailOpen: true,
        component: DashboardTemporalAnchorComponent.day,
        offset: 2,
        base: gestureOrigin,
      )!;
      controller.commitTemporalCandidate(second);
      expect(controller.state.dayCursor, 16);
    },
  );
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
