import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../domain/ledger_time_scope.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';
import 'dashboard_time_navigation_state.dart';

/// Owns structural time navigation only.
///
/// Scroll position, gesture/ballistic state and semantic crossings belong to
/// `DashboardMotionKernel`. Prepared data and visible values belong to their
/// respective immutable stores. Consequently this notifier never fires for a
/// rail tick or settle promotion.
final class DashboardNavigationController extends ChangeNotifier {
  DashboardNavigationController({
    DateTime? initialDate,
    TimePlane initialPlane = TimePlane.month,
    bool initialRailOpen = false,
    LedgerDirection initialDirection = LedgerDirection.income,
    Set<String> categoryIds = const <String>{},
    Set<String> partnerIds = const <String>{},
    Map<String, Object?> refinements = const <String, Object?>{},
  }) {
    final date = initialDate ?? DateTime.now();
    final month = YearMonth(year: date.year, month: date.month);
    final day = date.day.clamp(1, month.daysInMonth);
    final parentScope = _parentScopeFor(
      plane: initialPlane,
      yearCursor: date.year,
      monthCursor: month,
    );
    _state = DashboardNavigationState(
      plane: initialPlane,
      isRailOpen: initialRailOpen,
      parentQueryScope: CurrentLedgerQueryScope(
        direction: initialDirection,
        timeScope: parentScope,
        categoryIds: categoryIds,
        partnerIds: partnerIds,
        refinements: refinements,
      ),
      yearCursor: date.year,
      monthCursor: month,
      dayCursor: day,
      retainedChildYear: date.year,
      retainedChildMonth: date.month,
      retainedChildDay: day,
      navigationEpoch: 0,
    );
  }

  late DashboardNavigationState _state;

  DashboardNavigationState get state => _state;
  bool get isRailOpen => _state.isRailOpen;
  int get selectedChildLogicalIndex => switch (_state.plane) {
    TimePlane.sum => 12,
    TimePlane.year => _state.retainedChildMonth - 1,
    TimePlane.month => _state.retainedChildDay - 1,
  };

  void setRailOpen(bool value) {
    if (value == _state.isRailOpen) return;
    _publish(
      _state.copyWith(isRailOpen: value),
      DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.rail,
        direction: value
            ? DashboardTimeNavigationChangeDirection.forward
            : DashboardTimeNavigationChangeDirection.backward,
      ),
    );
  }

  DashboardNavigationState? parentCandidate(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    if (direction == DashboardTimeNavigationChangeDirection.none ||
        _state.plane == TimePlane.sum) {
      return null;
    }
    final delta = direction == DashboardTimeNavigationChangeDirection.forward
        ? 1
        : -1;
    final next = switch (_state.plane) {
      TimePlane.sum => _state,
      TimePlane.year => _yearParentCandidate(delta),
      TimePlane.month => _monthParentCandidate(delta),
    };
    return _withParentScope(next);
  }

  DashboardNavigationState? commitParent(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    final candidate = parentCandidate(direction);
    if (candidate == null) return null;
    _publish(
      candidate,
      DashboardTimeNavigationChange(
        kind: _state.isRailOpen
            ? DashboardTimeNavigationChangeKind.parentWhileRailOpen
            : DashboardTimeNavigationChangeKind.parent,
        direction: direction,
      ),
    );
    return _state;
  }

  DashboardNavigationState planeCandidate({required bool finer}) {
    final delta = finer ? 1 : -1;
    final currentIndex = _planeOrder.indexOf(_state.plane);
    final targetPlane =
        _planeOrder[((currentIndex + delta) % _planeOrder.length +
                _planeOrder.length) %
            _planeOrder.length];
    final next = switch ((_state.plane, targetPlane)) {
      (TimePlane.sum, TimePlane.year) => _state.copyWith(
        plane: TimePlane.year,
        yearCursor: _state.isRailOpen
            ? _state.retainedChildYear
            : _state.yearCursor,
      ),
      (TimePlane.year, TimePlane.month) => () {
        final month = YearMonth(
          year: _state.yearCursor,
          month: _state.isRailOpen
              ? _state.retainedChildMonth
              : _state.monthCursor.month,
        );
        final day = month.clampDay(_state.dayCursor).day;
        return _state.copyWith(
          plane: TimePlane.month,
          monthCursor: month,
          dayCursor: day,
          retainedChildDay: day,
        );
      }(),
      (TimePlane.month, TimePlane.sum) => _state.copyWith(plane: TimePlane.sum),
      (TimePlane.sum, TimePlane.month) => () {
        final year = _state.isRailOpen
            ? _state.retainedChildYear
            : _state.yearCursor;
        final month = YearMonth(year: year, month: _state.monthCursor.month);
        final day = month.clampDay(_state.dayCursor).day;
        return _state.copyWith(
          plane: TimePlane.month,
          yearCursor: year,
          monthCursor: month,
          dayCursor: day,
          retainedChildDay: day,
        );
      }(),
      (TimePlane.month, TimePlane.year) => _state.copyWith(
        plane: TimePlane.year,
        yearCursor: _state.monthCursor.year,
        retainedChildMonth: _state.monthCursor.month,
      ),
      (TimePlane.year, TimePlane.sum) => _state.copyWith(
        plane: TimePlane.sum,
        retainedChildYear: _state.yearCursor,
      ),
      _ => _state,
    };
    return _withParentScope(next);
  }

  DashboardNavigationState commitPlane({required bool finer}) {
    final candidate = planeCandidate(finer: finer);
    _publish(
      candidate,
      DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.plane,
        direction: finer
            ? DashboardTimeNavigationChangeDirection.forward
            : DashboardTimeNavigationChangeDirection.backward,
      ),
    );
    return _state;
  }

  /// Retains the semantic child selected by settle without notifying any UI.
  /// The visible frame already displays this exact child, so commit is a
  /// metadata-only promotion.
  bool retainSettledChild({
    required int value,
    required int expectedNavigationEpoch,
  }) {
    if (!_state.isRailOpen ||
        _state.navigationEpoch != expectedNavigationEpoch) {
      return false;
    }
    final next = switch (_state.plane) {
      TimePlane.sum => _state.copyWith(retainedChildYear: value),
      TimePlane.year => _state.copyWith(retainedChildMonth: value),
      TimePlane.month => _state.copyWith(
        retainedChildDay: value,
        dayCursor: value,
      ),
    };
    _state = next;
    return true;
  }

  DashboardNavigationState selectDirection(LedgerDirection direction) {
    if (_state.parentQueryScope.direction == direction) return _state;
    _publish(
      _state.copyWith(
        parentQueryScope: _state.parentQueryScope.copyWith(
          direction: direction,
        ),
      ),
      const DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.direction,
        direction: DashboardTimeNavigationChangeDirection.none,
      ),
    );
    return _state;
  }

  /// Debug seed orchestration uses the same structural parent intent as the
  /// production UI and performs no data work itself.
  void navigateToMonth(YearMonth month) {
    final day = month.clampDay(_state.dayCursor).day;
    _publish(
      _withParentScope(
        _state.copyWith(
          plane: TimePlane.month,
          isRailOpen: false,
          yearCursor: month.year,
          monthCursor: month,
          dayCursor: day,
          retainedChildDay: day,
        ),
      ),
      const DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.parent,
        direction: DashboardTimeNavigationChangeDirection.none,
      ),
    );
  }

  DashboardNavigationState _yearParentCandidate(int delta) {
    final year = _state.yearCursor + delta;
    final month = YearMonth(year: year, month: _state.retainedChildMonth);
    return _state.copyWith(
      yearCursor: year,
      monthCursor: month,
      dayCursor: month.clampDay(_state.dayCursor).day,
    );
  }

  DashboardNavigationState _monthParentCandidate(int delta) {
    final month = delta > 0
        ? _state.monthCursor.next()
        : _state.monthCursor.previous();
    final retainedDay = month.clampDay(_state.retainedChildDay).day;
    return _state.copyWith(
      yearCursor: month.year,
      monthCursor: month,
      dayCursor: retainedDay,
      retainedChildDay: retainedDay,
    );
  }

  DashboardNavigationState _withParentScope(DashboardNavigationState state) =>
      state.copyWith(
        parentQueryScope: state.parentQueryScope.copyWith(
          timeScope: _parentScopeFor(
            plane: state.plane,
            yearCursor: state.yearCursor,
            monthCursor: state.monthCursor,
          ),
        ),
      );

  void _publish(
    DashboardNavigationState candidate,
    DashboardTimeNavigationChange change,
  ) {
    _state = candidate.copyWith(
      navigationEpoch: _state.navigationEpoch + 1,
      lastChange: change,
    );
    notifyListeners();
  }

  static LedgerTimeScope _parentScopeFor({
    required TimePlane plane,
    required int yearCursor,
    required YearMonth monthCursor,
  }) => switch (plane) {
    TimePlane.sum => const AllTimeScope(),
    TimePlane.year => YearScope(yearCursor),
    TimePlane.month => MonthScope(monthCursor),
  };

  static const _planeOrder = <TimePlane>[
    TimePlane.sum,
    TimePlane.year,
    TimePlane.month,
  ];
}
