import '../domain/ledger_time_scope.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';

enum DashboardTimeNavigationChangeKind { initial, plane, parent, rail, child }

enum DashboardTimeNavigationChangeDirection { none, forward, backward }

class DashboardTimeNavigationChange {
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

class DashboardTimeNavigationState {
  const DashboardTimeNavigationState({
    required this.plane,
    required this.isRailOpen,
    required this.yearCursor,
    required this.monthCursor,
    required this.dayCursor,
    required this.settledChildYear,
    required this.settledChildMonth,
    required this.settledChildDay,
    required this.previewChild,
    this.navigationRevision = 0,
    this.lastChange = const DashboardTimeNavigationChange.initial(),
  });

  final TimePlane plane;
  final bool isRailOpen;
  final int yearCursor;
  final YearMonth monthCursor;
  final int dayCursor;
  final int settledChildYear;
  final int settledChildMonth;
  final int settledChildDay;
  final Object? previewChild;
  final int navigationRevision;
  final DashboardTimeNavigationChange lastChange;

  LedgerTimeScope get parentScope => switch (plane) {
    TimePlane.sum => const AllTimeScope(),
    TimePlane.year => YearScope(yearCursor),
    TimePlane.month => MonthScope(monthCursor),
  };

  LedgerTimeScope get childScope => switch (plane) {
    TimePlane.sum => YearScope(settledChildYear),
    TimePlane.year => MonthScope(
      YearMonth(year: yearCursor, month: settledChildMonth),
    ),
    TimePlane.month => DayScope(monthCursor.clampDay(settledChildDay)),
  };

  LedgerTimeScope get effectiveScope => isRailOpen ? childScope : parentScope;

  DashboardTimeNavigationState copyWith({
    TimePlane? plane,
    bool? isRailOpen,
    int? yearCursor,
    YearMonth? monthCursor,
    int? dayCursor,
    int? settledChildYear,
    int? settledChildMonth,
    int? settledChildDay,
    Object? previewChild = _unset,
    int? navigationRevision,
    DashboardTimeNavigationChange? lastChange,
  }) {
    return DashboardTimeNavigationState(
      plane: plane ?? this.plane,
      isRailOpen: isRailOpen ?? this.isRailOpen,
      yearCursor: yearCursor ?? this.yearCursor,
      monthCursor: monthCursor ?? this.monthCursor,
      dayCursor: dayCursor ?? this.dayCursor,
      settledChildYear: settledChildYear ?? this.settledChildYear,
      settledChildMonth: settledChildMonth ?? this.settledChildMonth,
      settledChildDay: settledChildDay ?? this.settledChildDay,
      previewChild: identical(previewChild, _unset)
          ? this.previewChild
          : previewChild,
      navigationRevision: navigationRevision ?? this.navigationRevision,
      lastChange: lastChange ?? this.lastChange,
    );
  }

  static const _unset = Object();
}
