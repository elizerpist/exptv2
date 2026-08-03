import 'package:flutter/foundation.dart';

import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../domain/time_plane.dart';
import '../domain/ledger_time_scope.dart';
import '../domain/year_month.dart';
import '../presentation/time_rail_data_source_factory.dart';
import 'dashboard_time_navigation_state.dart';
import 'summary_timing_debug.dart';

/// Owns the dashboard's hierarchical time navigation state.
///
/// It coordinates typed parent/child selections and the existing centered
/// carousel, but it does not query storage or know about Flutter layout.
class DashboardTimeNavigationController extends ChangeNotifier {
  DashboardTimeNavigationController({
    DateTime? initialDate,
    TimePlane initialPlane = TimePlane.month,
    bool initialRailOpen = false,
    int? yearAnchor,
  }) : _yearAnchor = yearAnchor ?? (initialDate ?? DateTime.now()).year,
       timeCarousel = CenteredCarouselController(initialIndex: 0) {
    final date = initialDate ?? DateTime.now();
    final month = YearMonth(year: date.year, month: date.month);
    _state = DashboardTimeNavigationState(
      plane: initialPlane,
      isRailOpen: initialRailOpen,
      yearCursor: date.year,
      monthCursor: month,
      dayCursor: date.day.clamp(1, month.daysInMonth),
      settledChildYear: date.year,
      settledChildMonth: date.month,
      settledChildDay: date.day.clamp(1, month.daysInMonth),
      previewChild: null,
    );
    timeCarousel.configureDetachedLogicalIndex(selectedChildLogicalIndex);
  }

  final int _yearAnchor;
  final CenteredCarouselController timeCarousel;
  final ValueNotifier<int> _railSourceRevision = ValueNotifier(0);
  late DashboardTimeNavigationState _state;

  DashboardTimeNavigationState get state => _state;
  bool get isExpanded => _state.isRailOpen;
  bool get isRailOpen => _state.isRailOpen;
  int get yearAnchor => _yearAnchor;
  int get selectedIndex => timeCarousel.selectedIndex;

  /// Emits only committed datasource changes. Drag-preview ticks do not
  /// recreate the rail viewport.
  ValueListenable<int> get railSourceRevision => _railSourceRevision;

  CenteredCarouselDataSource<int> get childDataSource =>
      TimeRailDataSourceFactory.forPlane(
        plane: _state.plane,
        yearAnchor: _yearAnchor,
        monthCursor: _state.monthCursor,
      );

  int get selectedChildLogicalIndex => switch (_state.plane) {
    TimePlane.sum => _state.settledChildYear - _yearAnchor,
    TimePlane.year => _state.settledChildMonth - 1,
    TimePlane.month => _state.settledChildDay - 1,
  };

  int childValueForLogicalIndex(int logicalIndex) =>
      TimeRailDataSourceFactory.valueForLogicalIndex(
        plane: _state.plane,
        logicalIndex: logicalIndex,
        yearAnchor: _yearAnchor,
        monthCursor: _state.monthCursor,
      );

  /// Canonical child scope for an already resolved shared-carousel target.
  ///
  /// This is read-only domain mapping used by data prefetch. It does not
  /// change selected/preview state, rail physics, haptics or query scope.
  LedgerTimeScope childScopeForLogicalIndex(int logicalIndex) {
    final child = childValueForLogicalIndex(logicalIndex);
    return switch (_state.plane) {
      TimePlane.sum => YearScope(child),
      TimePlane.year => MonthScope(
        YearMonth(year: _state.yearCursor, month: child),
      ),
      TimePlane.month => DayScope(_state.monthCursor.clampDay(child)),
    };
  }

  void toggleRail() => setRailOpen(!_state.isRailOpen);

  /// Compatibility alias for the former rail-only controller API.
  void toggle() => toggleRail();

  /// Compatibility intent for the dashboard shell's existing rail API.
  void setExpanded(bool value) => setRailOpen(value);

  void setRailOpen(bool value) {
    if (value == _state.isRailOpen) return;
    final nextState = _state.copyWith(
      isRailOpen: value,
      previewChild: null,
      pendingInteractionTarget: null,
    );
    _publish(
      nextState,
      DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.rail,
        direction: value
            ? DashboardTimeNavigationChangeDirection.forward
            : DashboardTimeNavigationChangeDirection.backward,
      ),
    );
  }

  void moveToFinerPlane() {
    _movePlaneBy(1, DashboardTimeNavigationChangeDirection.forward);
  }

  void moveToBroaderPlane() {
    _movePlaneBy(-1, DashboardTimeNavigationChangeDirection.backward);
  }

  void moveParentNext() {
    _moveParent(DashboardTimeNavigationChangeDirection.forward);
  }

  void moveParentPrevious() {
    _moveParent(DashboardTimeNavigationChangeDirection.backward);
  }

  /// Read-only projection for the SummaryPill's horizontal drag candidate.
  /// It reuses the same transition calculation as the actual commit and never
  /// changes the carousel, state revision or listener publication.
  DashboardTimeNavigationState? parentPreview(
    DashboardTimeNavigationChangeDirection direction,
  ) => _parentStateFor(direction);

  void _moveParent(DashboardTimeNavigationChangeDirection direction) {
    final nextState = _parentStateFor(direction);
    if (nextState == null) return;
    _publish(
      nextState,
      DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.parent,
        direction: direction,
      ),
    );
  }

  DashboardTimeNavigationState? _parentStateFor(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    if (direction == DashboardTimeNavigationChangeDirection.none) return null;
    final delta = direction == DashboardTimeNavigationChangeDirection.forward
        ? 1
        : -1;
    return switch (_state.plane) {
      TimePlane.sum => null,
      TimePlane.year => () {
        final year = _state.yearCursor + delta;
        final month = YearMonth(year: year, month: _state.monthCursor.month);
        return _state.copyWith(
          yearCursor: year,
          monthCursor: month,
          dayCursor: month.clampDay(_state.dayCursor).day,
          previewChild: null,
          pendingInteractionTarget: null,
        );
      }(),
      TimePlane.month => () {
        final month = delta > 0
            ? _state.monthCursor.next()
            : _state.monthCursor.previous();
        final day = month.clampDay(_state.dayCursor).day;
        return _state.copyWith(
          monthCursor: month,
          dayCursor: day,
          settledChildDay: day,
          previewChild: null,
          pendingInteractionTarget: null,
        );
      }(),
    };
  }

  /// Debug orchestration entry point used after the deterministic demo seed.
  /// Production startup does not call this method, so its default current-date
  /// navigation remains unchanged.
  void navigateToMonth(YearMonth month) {
    final day = month.clampDay(_state.dayCursor).day;
    final nextState = _state.copyWith(
      plane: TimePlane.month,
      isRailOpen: false,
      yearCursor: month.year,
      monthCursor: month,
      dayCursor: day,
      settledChildDay: day,
      previewChild: null,
      pendingInteractionTarget: null,
    );
    _state = nextState;
    _publish(
      _state,
      const DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.parent,
        direction: DashboardTimeNavigationChangeDirection.none,
      ),
    );
  }

  void previewChildLogicalIndex(int logicalIndex) {
    final next = childValueForLogicalIndex(logicalIndex);
    if (next == _state.previewChild &&
        next == _state.pendingInteractionTarget) {
      return;
    }
    DashboardSummaryTimingDebug.mark('P0 previewChanged', value: next);
    _state = _state.copyWith(
      previewChild: next,
      pendingInteractionTarget: next,
    );
    notifyListeners();
    DashboardSummaryTimingDebug.mark('P1 previewStateEmitted', value: next);
  }

  void settleChildLogicalIndex(int logicalIndex) {
    DashboardSummaryTimingDebug.mark('S0 finalSnapObserved');
    DashboardSummaryTimingDebug.mark(
      'R3 SELECTION_SETTLED_CALLBACK',
      value: logicalIndex,
    );
    DashboardSummaryTimingDebug.mark('S1 selectionSettledEntered');
    final child = childValueForLogicalIndex(logicalIndex);
    final nextState = switch (_state.plane) {
      TimePlane.sum => _state.copyWith(
        settledChildYear: child,
        previewChild: null,
        pendingInteractionTarget: null,
      ),
      TimePlane.year => _state.copyWith(
        settledChildMonth: child,
        previewChild: null,
        pendingInteractionTarget: null,
      ),
      TimePlane.month => _state.copyWith(
        settledChildDay: child,
        dayCursor: child,
        previewChild: null,
        pendingInteractionTarget: null,
      ),
    };
    _publish(
      nextState,
      const DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.child,
        direction: DashboardTimeNavigationChangeDirection.none,
      ),
    );
  }

  /// Compatibility entry point for adapters that receive a physical slot.
  void selectChildPhysicalIndex(int physicalIndex) {
    final logicalIndex = timeCarousel.logicalIndexForPhysical(physicalIndex);
    settleChildLogicalIndex(logicalIndex);
  }

  void _movePlaneBy(
    int delta,
    DashboardTimeNavigationChangeDirection direction,
  ) {
    final targetIndex = _positiveModulo(
      _planeOrder.indexOf(_state.plane) + delta,
      _planeOrder.length,
    );
    final targetPlane = _planeOrder[targetIndex];

    final nextState = switch ((_state.plane, targetPlane)) {
      (TimePlane.sum, TimePlane.year) => _promoteSumToYear(),
      (TimePlane.year, TimePlane.month) => _promoteYearToMonth(),
      (TimePlane.month, TimePlane.sum) => _state.copyWith(
        plane: TimePlane.sum,
        previewChild: null,
        pendingInteractionTarget: null,
      ),
      (TimePlane.sum, TimePlane.month) => _promoteSumToMonth(),
      (TimePlane.month, TimePlane.year) => _demoteMonthToYear(),
      (TimePlane.year, TimePlane.sum) => _demoteYearToSum(),
      _ => _state,
    };

    _state = nextState;
    _publish(
      _state,
      DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.plane,
        direction: direction,
      ),
    );
  }

  DashboardTimeNavigationState _promoteSumToYear() {
    final promotedYear = _state.isRailOpen
        ? _state.settledChildYear
        : _state.yearCursor;
    final month = YearMonth(
      year: promotedYear,
      month: _state.monthCursor.month,
    );
    return _state.copyWith(
      plane: TimePlane.year,
      yearCursor: promotedYear,
      monthCursor: month,
      dayCursor: month.clampDay(_state.dayCursor).day,
      previewChild: null,
      pendingInteractionTarget: null,
    );
  }

  DashboardTimeNavigationState _promoteYearToMonth() {
    final promotedMonth = _state.isRailOpen
        ? _state.settledChildMonth
        : _state.monthCursor.month;
    final month = YearMonth(year: _state.yearCursor, month: promotedMonth);
    final day = month.clampDay(_state.dayCursor).day;
    return _state.copyWith(
      plane: TimePlane.month,
      monthCursor: month,
      dayCursor: day,
      settledChildDay: day,
      previewChild: null,
      pendingInteractionTarget: null,
    );
  }

  DashboardTimeNavigationState _promoteSumToMonth() {
    final promotedYear = _state.isRailOpen
        ? _state.settledChildYear
        : _state.yearCursor;
    final month = YearMonth(
      year: promotedYear,
      month: _state.monthCursor.month,
    );
    final day = month.clampDay(_state.dayCursor).day;
    return _state.copyWith(
      plane: TimePlane.month,
      yearCursor: promotedYear,
      monthCursor: month,
      dayCursor: day,
      settledChildDay: day,
      previewChild: null,
      pendingInteractionTarget: null,
    );
  }

  DashboardTimeNavigationState _demoteMonthToYear() {
    return _state.copyWith(
      plane: TimePlane.year,
      yearCursor: _state.monthCursor.year,
      settledChildMonth: _state.monthCursor.month,
      previewChild: null,
      pendingInteractionTarget: null,
    );
  }

  DashboardTimeNavigationState _demoteYearToSum() {
    return _state.copyWith(
      plane: TimePlane.sum,
      settledChildYear: _state.yearCursor,
      previewChild: null,
      pendingInteractionTarget: null,
    );
  }

  void _publish(
    DashboardTimeNavigationState nextState,
    DashboardTimeNavigationChange change,
  ) {
    _state = nextState.copyWith(
      navigationRevision: _state.navigationRevision + 1,
      lastChange: change,
    );
    if (change.kind != DashboardTimeNavigationChangeKind.child) {
      // Navigation owns the semantic target. The shared carousel owns its
      // physical projection and will apply this only on the next viewport
      // lifecycle, not through a public scroll command.
      timeCarousel.prepareDataSourceReconfiguration(selectedChildLogicalIndex);
      _railSourceRevision.value = _state.navigationRevision;
    }
    if (change.kind == DashboardTimeNavigationChangeKind.child) {
      DashboardSummaryTimingDebug.mark(
        'S2 navigationStateCommitted',
        value: _state.displayedChild,
      );
    }
    notifyListeners();
    if (change.kind == DashboardTimeNavigationChangeKind.child) {
      DashboardSummaryTimingDebug.mark(
        'S3 transientChildClearedAtomically',
        value: _state.displayedChild,
      );
    }
  }

  static const _planeOrder = <TimePlane>[
    TimePlane.sum,
    TimePlane.year,
    TimePlane.month,
  ];

  static int _positiveModulo(int value, int modulus) {
    return ((value % modulus) + modulus) % modulus;
  }

  @override
  void dispose() {
    _railSourceRevision.dispose();
    timeCarousel.dispose();
    super.dispose();
  }
}
