import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../domain/dashboard_temporal_anchor.dart';
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
  DashboardNavigationState({
    required this.plane,
    required this.isRailOpen,
    required this.parentQueryScope,
    required this.temporalAnchor,
    required this.navigationEpoch,
    this.lastChange = const DashboardTimeNavigationChange.initial(),
  }) : assert(
         parentQueryScope.key == temporalAnchor.sourceParentQueryKey,
         'Parent QueryKey must be derived from the temporal anchor commit.',
       ),
       assert(
         navigationEpoch == temporalAnchor.navigationEpoch,
         'Navigation state and temporal anchor epochs must be atomic.',
       );

  final TimePlane plane;
  final bool isRailOpen;
  final CurrentLedgerQueryScope parentQueryScope;
  final DashboardTemporalAnchor temporalAnchor;
  final int navigationEpoch;
  final DashboardTimeNavigationChange lastChange;

  int get yearCursor => temporalAnchor.visibleYear;
  YearMonth get monthCursor => temporalAnchor.visibleYearMonth;
  int get dayCursor => temporalAnchor.visibleDay;
  int get retainedChildYear => temporalAnchor.visibleYear;
  int get retainedChildMonth => temporalAnchor.visibleMonth;
  int get retainedChildDay => temporalAnchor.visibleDay;

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
    DashboardTemporalAnchor? temporalAnchor,
    int? navigationEpoch,
    DashboardTimeNavigationChange? lastChange,
  }) => DashboardNavigationState(
    plane: plane ?? this.plane,
    isRailOpen: isRailOpen ?? this.isRailOpen,
    parentQueryScope: parentQueryScope ?? this.parentQueryScope,
    temporalAnchor: temporalAnchor ?? this.temporalAnchor,
    navigationEpoch: navigationEpoch ?? this.navigationEpoch,
    lastChange: lastChange ?? this.lastChange,
  );
}
