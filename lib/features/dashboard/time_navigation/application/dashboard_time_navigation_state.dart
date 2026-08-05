import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../domain/ledger_time_scope.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';

enum DashboardTimeNavigationChangeKind {
  initial,
  plane,
  parent,
  parentWhileRailOpen,
  rail,
  retainedChild,
  direction,
}

enum DashboardTimeNavigationChangeDirection { none, forward, backward }

@immutable
final class DashboardTimeNavigationChange {
  const DashboardTimeNavigationChange({
    required this.kind,
    required this.direction,
  });

  const DashboardTimeNavigationChange.initial()
    : kind = DashboardTimeNavigationChangeKind.initial,
      direction = DashboardTimeNavigationChangeDirection.none;

  final DashboardTimeNavigationChangeKind kind;
  final DashboardTimeNavigationChangeDirection direction;
}

/// Immutable structural dashboard navigation snapshot.
///
/// This object deliberately has no transient preview, scroll activity,
/// carousel/controller or loading fields. Its parent query identity changes
/// only through explicit structural navigation intents; display data is owned
/// by `DashboardVisibleFrame`.
@immutable
final class DashboardNavigationState {
  const DashboardNavigationState({
    required this.plane,
    required this.isRailOpen,
    required this.parentQueryScope,
    required this.yearCursor,
    required this.monthCursor,
    required this.dayCursor,
    required this.retainedChildYear,
    required this.retainedChildMonth,
    required this.retainedChildDay,
    required this.navigationEpoch,
    this.lastChange = const DashboardTimeNavigationChange.initial(),
  });

  final TimePlane plane;
  final bool isRailOpen;
  final CurrentLedgerQueryScope parentQueryScope;
  final int yearCursor;
  final YearMonth monthCursor;
  final int dayCursor;
  final int retainedChildYear;
  final int retainedChildMonth;
  final int retainedChildDay;
  final int navigationEpoch;
  final DashboardTimeNavigationChange lastChange;

  LedgerQueryKey get parentQueryKey => parentQueryScope.key;
  LedgerTimeScope get parentScope => parentQueryScope.timeScope;

  int get retainedSemanticChild => switch (plane) {
    TimePlane.sum => retainedChildYear,
    TimePlane.year => retainedChildMonth,
    TimePlane.month => retainedChildDay,
  };

  LedgerTimeScope get retainedChildScope => switch (plane) {
    TimePlane.sum => YearScope(retainedChildYear),
    TimePlane.year => MonthScope(
      YearMonth(year: yearCursor, month: retainedChildMonth),
    ),
    TimePlane.month => DayScope(monthCursor.clampDay(retainedChildDay)),
  };

  LedgerTimeScope get effectiveScope =>
      isRailOpen ? retainedChildScope : parentScope;

  DashboardNavigationState copyWith({
    TimePlane? plane,
    bool? isRailOpen,
    CurrentLedgerQueryScope? parentQueryScope,
    int? yearCursor,
    YearMonth? monthCursor,
    int? dayCursor,
    int? retainedChildYear,
    int? retainedChildMonth,
    int? retainedChildDay,
    int? navigationEpoch,
    DashboardTimeNavigationChange? lastChange,
  }) => DashboardNavigationState(
    plane: plane ?? this.plane,
    isRailOpen: isRailOpen ?? this.isRailOpen,
    parentQueryScope: parentQueryScope ?? this.parentQueryScope,
    yearCursor: yearCursor ?? this.yearCursor,
    monthCursor: monthCursor ?? this.monthCursor,
    dayCursor: dayCursor ?? this.dayCursor,
    retainedChildYear: retainedChildYear ?? this.retainedChildYear,
    retainedChildMonth: retainedChildMonth ?? this.retainedChildMonth,
    retainedChildDay: retainedChildDay ?? this.retainedChildDay,
    navigationEpoch: navigationEpoch ?? this.navigationEpoch,
    lastChange: lastChange ?? this.lastChange,
  );
}
