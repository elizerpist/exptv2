import 'package:flutter/foundation.dart';

import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';
import '../presentation/time_rail_data_source_factory.dart';
import 'dashboard_time_navigation_state.dart';

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
  }

  final int _yearAnchor;
  final CenteredCarouselController timeCarousel;
  late DashboardTimeNavigationState _state;

  DashboardTimeNavigationState get state => _state;
  bool get isExpanded => _state.isRailOpen;
  bool get isRailOpen => _state.isRailOpen;
  int get yearAnchor => _yearAnchor;
  int get selectedIndex => timeCarousel.selectedIndex;

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

  void toggleRail() => setRailOpen(!_state.isRailOpen);

  /// Compatibility alias for the former rail-only controller API.
  void toggle() => toggleRail();

  /// Compatibility intent for the dashboard shell's existing rail API.
  void setExpanded(bool value) => setRailOpen(value);

  void setRailOpen(bool value) {
    if (value == _state.isRailOpen) return;
    _state = _state.copyWith(isRailOpen: value, previewChild: null);
    if (value) _recenterChildSilently();
    notifyListeners();
  }

  void moveToFinerPlane() {
    if (!_state.plane.canMoveFiner) return;

    switch (_state.plane) {
      case TimePlane.sum:
        final promotedYear = _state.isRailOpen
            ? _state.settledChildYear
            : _state.yearCursor;
        final month = YearMonth(
          year: promotedYear,
          month: _state.monthCursor.month,
        );
        _state = _state.copyWith(
          plane: TimePlane.year,
          yearCursor: promotedYear,
          monthCursor: month,
          dayCursor: month.clampDay(_state.dayCursor).day,
          previewChild: null,
        );
      case TimePlane.year:
        final promotedMonth = _state.isRailOpen
            ? _state.settledChildMonth
            : _state.monthCursor.month;
        final month = YearMonth(
          year: _state.yearCursor,
          month: promotedMonth,
        );
        final day = month.clampDay(_state.dayCursor).day;
        _state = _state.copyWith(
          plane: TimePlane.month,
          monthCursor: month,
          dayCursor: day,
          settledChildDay: day,
          previewChild: null,
        );
      case TimePlane.month:
        return;
    }
    _recenterChildSilently();
    notifyListeners();
  }

  void moveToBroaderPlane() {
    if (!_state.plane.canMoveBroader) return;

    switch (_state.plane) {
      case TimePlane.sum:
        return;
      case TimePlane.year:
        _state = _state.copyWith(
          plane: TimePlane.sum,
          settledChildYear: _state.yearCursor,
          previewChild: null,
        );
      case TimePlane.month:
        _state = _state.copyWith(
          plane: TimePlane.year,
          yearCursor: _state.monthCursor.year,
          settledChildMonth: _state.monthCursor.month,
          previewChild: null,
        );
    }
    _recenterChildSilently();
    notifyListeners();
  }

  void moveParentNext() {
    switch (_state.plane) {
      case TimePlane.sum:
        return;
      case TimePlane.year:
        final nextYear = _state.yearCursor + 1;
        final nextMonth = YearMonth(
          year: nextYear,
          month: _state.monthCursor.month,
        );
        _state = _state.copyWith(
          yearCursor: nextYear,
          monthCursor: nextMonth,
          dayCursor: nextMonth.clampDay(_state.dayCursor).day,
          previewChild: null,
        );
      case TimePlane.month:
        final nextMonth = _state.monthCursor.next();
        final nextDay = nextMonth.clampDay(_state.dayCursor).day;
        _state = _state.copyWith(
          monthCursor: nextMonth,
          dayCursor: nextDay,
          settledChildDay: nextDay,
          previewChild: null,
        );
    }
    _recenterChildSilently();
    notifyListeners();
  }

  void moveParentPrevious() {
    switch (_state.plane) {
      case TimePlane.sum:
        return;
      case TimePlane.year:
        final previousYear = _state.yearCursor - 1;
        final previousMonth = YearMonth(
          year: previousYear,
          month: _state.monthCursor.month,
        );
        _state = _state.copyWith(
          yearCursor: previousYear,
          monthCursor: previousMonth,
          dayCursor: previousMonth.clampDay(_state.dayCursor).day,
          previewChild: null,
        );
      case TimePlane.month:
        final previousMonth = _state.monthCursor.previous();
        final previousDay = previousMonth.clampDay(_state.dayCursor).day;
        _state = _state.copyWith(
          monthCursor: previousMonth,
          dayCursor: previousDay,
          settledChildDay: previousDay,
          previewChild: null,
        );
    }
    _recenterChildSilently();
    notifyListeners();
  }

  void previewChildLogicalIndex(int logicalIndex) {
    final next = childValueForLogicalIndex(logicalIndex);
    if (next == _state.previewChild) return;
    _state = _state.copyWith(previewChild: next);
    notifyListeners();
  }

  void settleChildLogicalIndex(int logicalIndex) {
    final child = childValueForLogicalIndex(logicalIndex);
    _state = switch (_state.plane) {
      TimePlane.sum => _state.copyWith(
        settledChildYear: child,
        previewChild: null,
      ),
      TimePlane.year => _state.copyWith(
        settledChildMonth: child,
        previewChild: null,
      ),
      TimePlane.month => _state.copyWith(
        settledChildDay: child,
        dayCursor: child,
        previewChild: null,
      ),
    };
    notifyListeners();
  }

  /// Compatibility entry point for adapters that receive a physical slot.
  void selectChildPhysicalIndex(int physicalIndex) {
    final logicalIndex = timeCarousel.logicalIndexForPhysical(physicalIndex);
    settleChildLogicalIndex(logicalIndex);
  }

  void _recenterChildSilently() {
    timeCarousel.jumpToIndexSilently(selectedChildLogicalIndex);
  }

  @override
  void dispose() {
    timeCarousel.dispose();
    super.dispose();
  }
}
