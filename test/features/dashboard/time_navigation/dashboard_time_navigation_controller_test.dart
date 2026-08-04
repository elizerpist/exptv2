import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

DashboardTimeNavigationController _controller({
  bool railOpen = false,
  TimePlane plane = TimePlane.sum,
}) {
  return DashboardTimeNavigationController(
    initialDate: DateTime(2026, 5, 14),
    initialPlane: plane,
    initialRailOpen: railOpen,
    yearAnchor: 2026,
  );
}

void main() {
  test('SUM closed uses all-time and open selects a year child', () {
    final controller = _controller();
    addTearDown(controller.dispose);

    expect(controller.state.effectiveScope, const AllTimeScope());
    controller.toggleRail();
    controller.settleChildLogicalIndex(0);

    expect(controller.state.effectiveScope, const YearScope(2026));
    expect(controller.state.previewChild, isNull);
  });

  test('preview does not change the committed effective scope', () {
    final controller = _controller(railOpen: true);
    addTearDown(controller.dispose);
    controller.settleChildLogicalIndex(0);

    controller.previewChildLogicalIndex(1);

    expect(controller.state.previewChild, 2027);
    expect(controller.state.effectiveScope, const YearScope(2026));
  });

  test('settle atomically promotes the displayed preview child', () {
    final controller = _controller(railOpen: true);
    addTearDown(controller.dispose);
    controller.settleChildLogicalIndex(8);
    controller.previewChildLogicalIndex(11);

    expect(controller.state.displayedChild, 2037);
    expect(controller.state.previewChild, 2037);

    var notifications = 0;
    controller.addListener(() => notifications += 1);
    controller.settleChildLogicalIndex(11);

    expect(notifications, 1);
    expect(controller.state.settledChildYear, 2037);
    expect(controller.state.previewChild, isNull);
    expect(controller.state.pendingInteractionTarget, isNull);
    expect(controller.state.displayedChild, 2037);
  });

  test('SUM to YEAR and YEAR to MONTH promote selected children', () {
    final controller = _controller(railOpen: true);
    addTearDown(controller.dispose);
    controller.settleChildLogicalIndex(0);

    controller.moveToFinerPlane();
    expect(controller.state.plane, TimePlane.year);
    expect(controller.state.parentScope, const YearScope(2026));
    expect(
      controller.state.effectiveScope,
      const MonthScope(YearMonth(year: 2026, month: 5)),
    );

    controller.settleChildLogicalIndex(4);
    controller.moveToFinerPlane();
    expect(controller.state.plane, TimePlane.month);
    expect(
      controller.state.parentScope,
      const MonthScope(YearMonth(year: 2026, month: 5)),
    );
    expect(
      controller.state.effectiveScope,
      DayScope(YearMonth(year: 2026, month: 5).clampDay(14)),
    );
  });

  test('broader transitions preserve the parent cursor and rail state', () {
    final controller = _controller(railOpen: true, plane: TimePlane.month);
    addTearDown(controller.dispose);

    controller.settleChildLogicalIndex(13);
    controller.moveToBroaderPlane();

    expect(controller.state.plane, TimePlane.year);
    expect(controller.state.parentScope, const YearScope(2026));
    expect(controller.state.isRailOpen, isTrue);
    expect(
      controller.state.effectiveScope,
      const MonthScope(YearMonth(year: 2026, month: 5)),
    );
  });

  test(
    'YEAR parent navigation changes the year while preserving child month',
    () {
      final controller = _controller(railOpen: false, plane: TimePlane.year);
      addTearDown(controller.dispose);

      final next = controller.parentPreview(
        DashboardTimeNavigationChangeDirection.forward,
      );
      expect(next?.yearCursor, 2027);
      expect(next?.monthCursor, const YearMonth(year: 2027, month: 5));
      expect(next?.parentScope, const YearScope(2027));

      controller.moveParentNext();
      expect(controller.state.yearCursor, 2027);
      expect(controller.state.parentScope, const YearScope(2027));
      expect(
        controller.state.monthCursor,
        const YearMonth(year: 2027, month: 5),
      );
    },
  );

  test('month parent navigation rolls years and clamps the day', () {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2024, 1, 31),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
      yearAnchor: 2024,
    );
    addTearDown(controller.dispose);

    controller.moveParentNext();
    expect(controller.state.monthCursor, const YearMonth(year: 2024, month: 2));
    expect(controller.state.dayCursor, 29);
    expect(controller.selectedChildLogicalIndex, 28);
    expect(
      controller.state.effectiveScope,
      DayScope(YearMonth(year: 2024, month: 2).clampDay(29)),
    );

    controller.moveParentPrevious();
    expect(controller.state.monthCursor, const YearMonth(year: 2024, month: 1));
    expect(controller.state.dayCursor, 29);
  });

  test(
    'parent preview projects the committed transition without mutating state',
    () {
      final controller = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 12, 31),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        yearAnchor: 2026,
      );
      addTearDown(controller.dispose);
      final before = controller.state;
      final selectedBefore = controller.timeCarousel.selectedIndex;

      final candidate = controller.parentPreview(
        DashboardTimeNavigationChangeDirection.forward,
      );

      expect(candidate?.monthCursor, const YearMonth(year: 2027, month: 1));
      expect(candidate?.dayCursor, 31);
      expect(controller.state, same(before));
      expect(controller.timeCarousel.selectedIndex, selectedBefore);
    },
  );

  test('SUM plane has no horizontal parent preview', () {
    final controller = _controller(plane: TimePlane.sum);
    addTearDown(controller.dispose);

    expect(
      controller.parentPreview(DashboardTimeNavigationChangeDirection.forward),
      isNull,
    );
  });

  test('rail close keeps the child cursor and returns to parent scope', () {
    final controller = _controller(railOpen: true, plane: TimePlane.year);
    addTearDown(controller.dispose);
    controller.settleChildLogicalIndex(10);
    expect(
      controller.state.effectiveScope,
      const MonthScope(YearMonth(year: 2026, month: 11)),
    );

    controller.toggleRail();
    expect(controller.state.effectiveScope, const YearScope(2026));
    expect(controller.state.settledChildMonth, 11);
    controller.toggleRail();
    expect(
      controller.state.effectiveScope,
      const MonthScope(YearMonth(year: 2026, month: 11)),
    );
  });

  test(
    'equivalent YEAR plus child and MONTH parent produce the same scope',
    () {
      final viaYear = _controller(railOpen: true, plane: TimePlane.year);
      addTearDown(viaYear.dispose);
      viaYear.settleChildLogicalIndex(4);

      final viaMonth = _controller(railOpen: false, plane: TimePlane.month);
      addTearDown(viaMonth.dispose);
      expect(
        viaYear.state.effectiveScope,
        const MonthScope(YearMonth(year: 2026, month: 5)),
      );
      expect(
        viaMonth.state.effectiveScope,
        const MonthScope(YearMonth(year: 2026, month: 5)),
      );
    },
  );

  test(
    'debug demo navigation can select July 2026 without changing defaults',
    () {
      final controller = _controller(plane: TimePlane.month);
      addTearDown(controller.dispose);

      controller.navigateToMonth(const YearMonth(year: 2026, month: 7));

      expect(controller.state.plane, TimePlane.month);
      expect(controller.state.isRailOpen, isFalse);
      expect(
        controller.state.monthCursor,
        const YearMonth(year: 2026, month: 7),
      );
      expect(
        controller.state.effectiveScope,
        const MonthScope(YearMonth(year: 2026, month: 7)),
      );
    },
  );

  test(
    'open-rail parent transition keeps the target parent and child deck atomic',
    () {
      final controller = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 7, 31),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        yearAnchor: 2026,
      );
      addTearDown(controller.dispose);

      final beforeDeckEpoch = controller.state.deckEpoch;

      controller.commitParentWhileRailOpen(
        DashboardTimeNavigationChangeDirection.backward,
      );

      expect(controller.state.isRailOpen, isTrue);
      expect(
        controller.state.parentScope,
        const MonthScope(YearMonth(year: 2026, month: 6)),
      );
      expect(
        controller.state.childScope,
        const DayScope(LocalDate(year: 2026, month: 6, day: 30)),
      );
      expect(controller.state.displayedChild, 30);
      expect(
        controller.state.lastChange.kind,
        DashboardTimeNavigationChangeKind.parentWhileRailOpen,
      );
      expect(controller.state.deckEpoch, greaterThan(beforeDeckEpoch));
    },
  );

  test('settle callback from a closed rail is rejected by deck identity', () {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2026, 7, 27),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
      yearAnchor: 2026,
    );
    addTearDown(controller.dispose);

    final staleDeckEpoch = controller.state.deckEpoch;
    final staleParentScope = controller.state.parentScope;
    controller.setRailOpen(false);

    expect(
      controller.settleChildLogicalIndexIfCurrent(
        4,
        deckEpoch: staleDeckEpoch,
        parentScope: staleParentScope,
      ),
      isFalse,
    );
    expect(controller.state.isRailOpen, isFalse);
    expect(controller.state.parentScope, staleParentScope);
    expect(
      controller.state.lastChange.kind,
      DashboardTimeNavigationChangeKind.rail,
    );
  });

  test('parent replacement rejects a settle callback from the old deck', () {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2026, 7, 27),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
      yearAnchor: 2026,
    );
    addTearDown(controller.dispose);

    final staleDeckEpoch = controller.state.deckEpoch;
    final staleParentScope = controller.state.parentScope;
    controller.commitParentWhileRailOpen(
      DashboardTimeNavigationChangeDirection.backward,
    );

    expect(
      controller.settleChildLogicalIndexIfCurrent(
        0,
        deckEpoch: staleDeckEpoch,
        parentScope: staleParentScope,
      ),
      isFalse,
    );
    expect(controller.state.parentScope.canonicalKey, 'month:2026-06');
    expect(controller.state.childScope.canonicalKey, 'day:2026-06-27');
  });

  test('open-rail parent transition clamps March 31 to February 28', () {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2026, 3, 31),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
      yearAnchor: 2026,
    );
    addTearDown(controller.dispose);

    controller.commitParentWhileRailOpen(
      DashboardTimeNavigationChangeDirection.backward,
    );

    expect(controller.state.parentScope.canonicalKey, 'month:2026-02');
    expect(controller.state.childScope.canonicalKey, 'day:2026-02-28');
  });

  test(
    'repeated open-rail parent commits are latest-wins and stay on one deck',
    () {
      final controller = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 7, 27),
        initialPlane: TimePlane.month,
        initialRailOpen: true,
        yearAnchor: 2026,
      );
      addTearDown(controller.dispose);

      controller.commitParentWhileRailOpen(
        DashboardTimeNavigationChangeDirection.backward,
      );
      controller.commitParentWhileRailOpen(
        DashboardTimeNavigationChangeDirection.backward,
      );

      expect(controller.state.parentScope.canonicalKey, 'month:2026-05');
      expect(controller.state.childScope.canonicalKey, 'day:2026-05-27');
      expect(controller.state.isRailOpen, isTrue);
      expect(controller.state.deckEpoch, 2);
    },
  );
}
