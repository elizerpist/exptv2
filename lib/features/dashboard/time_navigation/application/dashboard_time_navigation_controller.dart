import 'package:flutter/foundation.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/ledger_direction.dart';
import '../domain/dashboard_temporal_anchor.dart';
import '../domain/dashboard_temporal_availability.dart';
import '../domain/ledger_time_scope.dart';
import '../domain/local_date.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';
import 'dashboard_time_navigation_state.dart';

typedef DashboardTemporalAnchorChanged =
    void Function(
      DashboardTemporalAnchor oldAnchor,
      DashboardTemporalAnchor newAnchor,
      DashboardTemporalAnchorChangeReason reason,
    );

@immutable
final class DashboardPlaneTargetDerivation {
  const DashboardPlaneTargetDerivation({
    required this.sourcePlane,
    required this.targetPlane,
    required this.temporalAnchor,
    required this.targetParentQueryKey,
    required this.targetChildQueryKey,
    required this.derivationReason,
    required this.navigationEpoch,
  });

  final TimePlane sourcePlane;
  final TimePlane targetPlane;
  final DashboardTemporalAnchor temporalAnchor;
  final LedgerQueryKey targetParentQueryKey;
  final LedgerQueryKey targetChildQueryKey;
  final String derivationReason;
  final int navigationEpoch;
}

typedef DashboardPlaneTargetDerived =
    void Function(DashboardPlaneTargetDerivation derivation);

/// Why the canonical rail child becomes retained.
///
/// A real rail settle and a cross-axis input takeover produce the same
/// temporal anchor, but only the former represents a settle callback.
enum DashboardRetainedChildReason {
  railSettled,
  verticalInputTakeover,
  structuralRailExit,
}

/// Owns structural time navigation and its one canonical temporal anchor.
///
/// Scroll position, gesture/ballistic state and semantic crossings belong to
/// `DashboardMotionKernel`. Prepared data and visible values belong to their
/// immutable stores. This notifier never fires for a rail tick or settle
/// promotion.
final class DashboardNavigationController extends ChangeNotifier {
  DashboardNavigationController({
    DateTime? initialDate,
    TimePlane initialPlane = TimePlane.month,
    bool initialRailOpen = false,
    LedgerDirection initialDirection = LedgerDirection.income,
    Set<String> categoryIds = const <String>{},
    Set<String> partnerIds = const <String>{},
    Map<String, Object?> refinements = const <String, Object?>{},
    int initialCoreRevision = 0,
    this.onTemporalAnchorChanged,
    this.onPlaneTargetDerived,
  }) {
    final date = initialDate ?? DateTime.now();
    final month = YearMonth(year: date.year, month: date.month);
    final day = date.day.clamp(1, month.daysInMonth);
    final queryTemplate = CurrentLedgerQueryScope(
      direction: initialDirection,
      timeScope: const AllTimeScope(),
      categoryIds: categoryIds,
      partnerIds: partnerIds,
      refinements: refinements,
    );
    final parentQueryScope = _parentQueryScope(
      template: queryTemplate,
      plane: initialPlane,
      year: date.year,
      month: month,
    );
    final anchor = _anchorFor(
      parentQueryScope: parentQueryScope,
      plane: initialPlane,
      year: date.year,
      month: month.month,
      day: day,
      revision: initialCoreRevision,
      navigationEpoch: 0,
    );
    _state = DashboardNavigationState(
      plane: initialPlane,
      isRailOpen: initialRailOpen,
      parentQueryScope: parentQueryScope,
      temporalAnchor: anchor,
      navigationEpoch: 0,
    );
  }

  final DashboardTemporalAnchorChanged? onTemporalAnchorChanged;
  final DashboardPlaneTargetDerived? onPlaneTargetDerived;
  late DashboardNavigationState _state;
  DashboardTemporalAvailability _temporalAvailability =
      const DashboardTemporalAvailability.unrestricted();

  DashboardNavigationState get state => _state;
  bool get isRailOpen => _state.isRailOpen;
  DashboardTemporalAnchor get temporalAnchor => _state.temporalAnchor;
  DashboardTemporalAvailability get temporalAvailability =>
      _temporalAvailability;
  int get selectedChildLogicalIndex => switch (_state.plane) {
    TimePlane.sum =>
      _temporalAvailability.allowedYears?.indexOf(_state.retainedChildYear) ??
          12,
    TimePlane.year =>
      _temporalAvailability
              .monthsForYear(_state.retainedChildYear)
              ?.indexOf(_state.retainedChildMonth) ??
          (_state.retainedChildMonth - 1),
    TimePlane.month =>
      _temporalAvailability
              .daysForMonth(_state.retainedChildYear, _state.retainedChildMonth)
              ?.indexOf(_state.retainedChildDay) ??
          (_state.retainedChildDay - 1),
  };

  void setRailOpen(bool value, {int? coreRevision}) {
    final candidate = railVisibilityCandidate(
      value,
      coreRevision: coreRevision,
    );
    if (candidate == _state) return;
    commitRailVisibilityCandidate(candidate);
  }

  /// Pure rail-visibility projection used by the dashboard scene coordinator.
  /// Opening the rail changes the immediately visible LogBox payload, so its
  /// child scene must be active before this state may publish.
  DashboardNavigationState railVisibilityCandidate(
    bool value, {
    int? coreRevision,
  }) {
    if (value == _state.isRailOpen) return _state;
    return _candidateFor(
      plane: _state.plane,
      coreRevision: coreRevision,
    ).copyWith(isRailOpen: value);
  }

  DashboardNavigationState commitRailVisibilityCandidate(
    DashboardNavigationState candidate,
  ) {
    if (candidate.isRailOpen == _state.isRailOpen) return _state;
    _publish(
      candidate,
      DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.rail,
        direction: candidate.isRailOpen
            ? DashboardTimeNavigationChangeDirection.forward
            : DashboardTimeNavigationChangeDirection.backward,
      ),
      DashboardTemporalAnchorChangeReason.railVisibilityCommitted,
    );
    return _state;
  }

  /// Atomically replaces the applied filter template and its derived temporal
  /// rail domain. The existing time-navigation controller remains the only
  /// owner of structural selection and performs deterministic reconciliation.
  DashboardNavigationState replaceAppliedQuery(
    CurrentLedgerQueryScope template, {
    required DashboardTemporalAvailability availability,
    int? coreRevision,
  }) {
    final candidate = appliedQueryCandidate(
      template,
      availability: availability,
      coreRevision: coreRevision,
    );
    _temporalAvailability = availability;
    _publish(
      candidate,
      const DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.query,
        direction: DashboardTimeNavigationChangeDirection.none,
      ),
      DashboardTemporalAnchorChangeReason.queryApplied,
    );
    return _state;
  }

  /// Pure target projection used to prepare the exact scenes needed before a
  /// Query publication changes visible navigation metadata.
  DashboardNavigationState appliedQueryCandidate(
    CurrentLedgerQueryScope template, {
    required DashboardTemporalAvailability availability,
    int? coreRevision,
  }) {
    final old = _state;
    final reconciled = _reconcileToAvailability(
      old.temporalAnchor,
      availability,
    );
    final month = YearMonth(year: reconciled.year, month: reconciled.month);
    final parentQueryScope = _parentQueryScope(
      template: template,
      plane: old.plane,
      year: reconciled.year,
      month: month,
    );
    final candidate = old.copyWith(
      parentQueryScope: parentQueryScope,
      temporalAnchor: _anchorFor(
        parentQueryScope: parentQueryScope,
        plane: old.plane,
        year: reconciled.year,
        month: reconciled.month,
        day: reconciled.day,
        revision: coreRevision ?? old.temporalAnchor.revision,
        navigationEpoch: old.navigationEpoch,
      ),
    );
    return candidate;
  }

  DashboardNavigationState? parentCandidate(
    DashboardTimeNavigationChangeDirection direction, {
    int? coreRevision,
  }) => parentCursorCandidate(direction, coreRevision: coreRevision);

  DashboardNavigationState? parentCursorCandidate(
    DashboardTimeNavigationChangeDirection direction, {
    int? coreRevision,
  }) {
    if (direction == DashboardTimeNavigationChangeDirection.none ||
        _state.plane == TimePlane.sum) {
      return null;
    }
    final delta = direction == DashboardTimeNavigationChangeDirection.forward
        ? 1
        : -1;
    return parentOffsetCandidate(delta, coreRevision: coreRevision);
  }

  /// Pure target projection for the primary mother selector. The offset is
  /// relative to the currently committed parent and never publishes a query.
  /// A zero offset describes the current parent; SUM deliberately has none.
  DashboardNavigationState? parentOffsetCandidate(
    int offset, {
    int? coreRevision,
  }) {
    if (_state.plane == TimePlane.sum) return null;
    if (offset == 0) return _state;
    return switch (_state.plane) {
      TimePlane.sum => null,
      TimePlane.year => _yearParentCandidate(offset, coreRevision),
      TimePlane.month => _monthParentCandidate(offset, coreRevision),
    };
  }

  DashboardNavigationState? commitParent(
    DashboardTimeNavigationChangeDirection direction, {
    int? coreRevision,
  }) {
    final candidate = parentCandidate(direction, coreRevision: coreRevision);
    if (candidate == null) return null;
    return commitParentCandidate(candidate, direction);
  }

  DashboardNavigationState commitParentCandidate(
    DashboardNavigationState candidate,
    DashboardTimeNavigationChangeDirection direction,
  ) {
    _publish(
      candidate,
      DashboardTimeNavigationChange(
        kind: _state.isRailOpen
            ? DashboardTimeNavigationChangeKind.parentWhileRailOpen
            : DashboardTimeNavigationChangeKind.parent,
        direction: direction,
      ),
      DashboardTemporalAnchorChangeReason.parentCommitted,
    );
    return _state;
  }

  DashboardNavigationState planeCandidate({
    required bool finer,
    int? coreRevision,
  }) => planeCursorCandidate(finer: finer, coreRevision: coreRevision);

  /// Pure target projection for the primary axis selector. It keeps the
  /// existing three-plane model and returns no preview/committed side effect.
  DashboardNavigationState planeTargetCandidate(
    TimePlane target, {
    int? coreRevision,
  }) => _candidateFor(plane: target, coreRevision: coreRevision);

  DashboardNavigationState planeCursorCandidate({
    required bool finer,
    int? coreRevision,
  }) {
    final delta = finer ? 1 : -1;
    final currentIndex = _planeOrder.indexOf(_state.plane);
    final targetPlane =
        _planeOrder[((currentIndex + delta) % _planeOrder.length +
                _planeOrder.length) %
            _planeOrder.length];
    return _candidateFor(plane: targetPlane, coreRevision: coreRevision);
  }

  DashboardNavigationState commitPlane({
    required bool finer,
    int? coreRevision,
  }) {
    final candidate = planeCandidate(finer: finer, coreRevision: coreRevision);
    return commitPlaneCandidate(candidate, finer: finer);
  }

  DashboardNavigationState commitPlaneCandidate(
    DashboardNavigationState candidate, {
    required bool finer,
  }) => commitPlaneTargetCandidate(candidate, finer: finer);

  /// Commits a previously prepared primary-axis target through the existing
  /// canonical plane publication path.
  DashboardNavigationState commitPlaneTargetCandidate(
    DashboardNavigationState candidate, {
    required bool finer,
  }) {
    final nextEpoch = _state.navigationEpoch + 1;
    onPlaneTargetDerived?.call(
      DashboardPlaneTargetDerivation(
        sourcePlane: _state.plane,
        targetPlane: candidate.plane,
        temporalAnchor: candidate.temporalAnchor.copyWith(
          navigationEpoch: nextEpoch,
        ),
        targetParentQueryKey: candidate.parentQueryKey,
        targetChildQueryKey: candidate.temporalAnchor.sourceChildQueryKey,
        derivationReason: finer ? 'finer' : 'broader',
        navigationEpoch: nextEpoch,
      ),
    );
    _publish(
      candidate,
      DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.plane,
        direction: finer
            ? DashboardTimeNavigationChangeDirection.forward
            : DashboardTimeNavigationChangeDirection.backward,
      ),
      DashboardTemporalAnchorChangeReason.planeCommitted,
    );
    return _state;
  }

  /// Retains the semantic child selected by settle without notifying any UI.
  /// The visible frame already displays this exact child, so commit is a
  /// metadata-only anchor promotion.
  bool retainSettledChild({
    required int value,
    required int expectedNavigationEpoch,
    LedgerQueryKey? childQueryKey,
    int? coreRevision,
  }) => retainChild(
    value: value,
    expectedNavigationEpoch: expectedNavigationEpoch,
    childQueryKey: childQueryKey,
    coreRevision: coreRevision,
    reason: DashboardRetainedChildReason.railSettled,
  );

  /// Retains an exact currently visible child without manufacturing a rail
  /// settle. This remains metadata-only: the visible prepared payload is
  /// owned by the presentation layer.
  bool retainChild({
    required int value,
    required int expectedNavigationEpoch,
    LedgerQueryKey? childQueryKey,
    int? coreRevision,
    required DashboardRetainedChildReason reason,
  }) {
    if (!_state.isRailOpen ||
        _state.navigationEpoch != expectedNavigationEpoch) {
      return false;
    }
    final oldAnchor = _state.temporalAnchor;
    final nextValues = switch (_state.plane) {
      TimePlane.sum => (
        year: value,
        month: oldAnchor.visibleMonth,
        day: oldAnchor.visibleDay,
      ),
      TimePlane.year => (
        year: oldAnchor.visibleYear,
        month: value,
        day: oldAnchor.visibleDay,
      ),
      TimePlane.month => (
        year: oldAnchor.visibleYear,
        month: oldAnchor.visibleMonth,
        day: value,
      ),
    };
    final month = YearMonth(year: nextValues.year, month: nextValues.month);
    final day = month.clampDay(nextValues.day).day;
    final childScope = _childScopeFor(
      plane: _state.plane,
      year: nextValues.year,
      month: month,
      day: day,
    );
    final nextAnchor = DashboardTemporalAnchor(
      visibleYear: nextValues.year,
      visibleMonth: nextValues.month,
      visibleDay: day,
      sourcePlane: _state.plane,
      sourceParentQueryKey: _state.parentQueryKey,
      sourceChildQueryKey:
          childQueryKey ??
          _state.parentQueryScope.copyWith(timeScope: childScope).key,
      sourceChildOrdinal: value,
      direction: _state.parentQueryScope.direction,
      filtersRefinementsIdentity: oldAnchor.filtersRefinementsIdentity,
      revision: coreRevision ?? oldAnchor.revision,
      navigationEpoch: _state.navigationEpoch,
    );
    _state = _state.copyWith(temporalAnchor: nextAnchor);
    onTemporalAnchorChanged?.call(oldAnchor, nextAnchor, switch (reason) {
      DashboardRetainedChildReason.railSettled =>
        DashboardTemporalAnchorChangeReason.railRetainedChild,
      DashboardRetainedChildReason.verticalInputTakeover =>
        DashboardTemporalAnchorChangeReason.verticalInputTakeover,
      DashboardRetainedChildReason.structuralRailExit =>
        DashboardTemporalAnchorChangeReason.structuralRailExit,
    });
    return true;
  }

  DashboardNavigationState directionCandidate(
    LedgerDirection direction, {
    CurrentLedgerQueryScope? template,
    DashboardTemporalAvailability? availability,
    int? coreRevision,
  }) {
    final directionalTemplate = template;
    if (directionalTemplate != null) {
      if (directionalTemplate.direction != direction) {
        throw ArgumentError.value(
          directionalTemplate,
          'template',
          'A direction candidate requires its own directional template.',
        );
      }
      // A direction is a selection, never a mutation/copy of the currently
      // visible Query.  Reconcile the existing temporal anchor against the
      // target direction's availability before deriving its parent identity.
      return appliedQueryCandidate(
        directionalTemplate,
        availability: availability ?? _temporalAvailability,
        coreRevision: coreRevision,
      );
    }
    if (_state.parentQueryScope.direction == direction) return _state;
    return _candidateFor(
      plane: _state.plane,
      direction: direction,
      coreRevision: coreRevision,
    );
  }

  DashboardNavigationState selectDirection(
    LedgerDirection direction, {
    CurrentLedgerQueryScope? template,
    DashboardTemporalAvailability? availability,
    int? coreRevision,
  }) => commitDirectionCandidate(
    directionCandidate(
      direction,
      template: template,
      availability: availability,
      coreRevision: coreRevision,
    ),
    availability: availability,
  );

  DashboardNavigationState commitDirectionCandidate(
    DashboardNavigationState candidate, {
    DashboardTemporalAvailability? availability,
  }) {
    if (candidate.parentQueryScope == _state.parentQueryScope &&
        (availability == null || availability == _temporalAvailability)) {
      return _state;
    }
    if (availability != null) _temporalAvailability = availability;
    _publish(
      candidate,
      const DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.direction,
        direction: DashboardTimeNavigationChangeDirection.none,
      ),
      DashboardTemporalAnchorChangeReason.directionCommitted,
    );
    return _state;
  }

  /// Debug seed orchestration uses the same structural month intent as the
  /// production UI and performs no data work itself.
  void navigateToMonth(YearMonth month, {int? coreRevision}) {
    final day = month.clampDay(_state.temporalAnchor.visibleDay).day;
    final candidate = _candidateFor(
      plane: TimePlane.month,
      year: month.year,
      month: month.month,
      day: day,
      coreRevision: coreRevision,
    ).copyWith(isRailOpen: false);
    _publish(
      candidate,
      const DashboardTimeNavigationChange(
        kind: DashboardTimeNavigationChangeKind.parent,
        direction: DashboardTimeNavigationChangeDirection.none,
      ),
      DashboardTemporalAnchorChangeReason.debugMonthCommitted,
    );
  }

  DashboardNavigationState? _yearParentCandidate(int delta, int? coreRevision) {
    final anchor = _state.temporalAnchor;
    final restrictedYears = _temporalAvailability.allowedYears;
    final unrestrictedYear = anchor.visibleYear + delta;
    final year = restrictedYears == null
        ? (unrestrictedYear >= 1 && unrestrictedYear <= 9999
              ? unrestrictedYear
              : null)
        : _cyclicParentAdjacent(restrictedYears, anchor.visibleYear, delta);
    if (year == null) return null;
    final allowedMonths = _temporalAvailability.monthsForYear(year);
    final monthValue =
        allowedMonths == null || allowedMonths.contains(anchor.visibleMonth)
        ? anchor.visibleMonth
        : allowedMonths.first;
    final month = YearMonth(year: year, month: monthValue);
    final allowedDays = _temporalAvailability.daysForMonth(year, month.month);
    final day = allowedDays == null || allowedDays.isEmpty
        ? anchor.visibleDay
        : (allowedDays.contains(anchor.visibleDay)
              ? anchor.visibleDay
              : allowedDays.first);
    return _candidateFor(
      plane: TimePlane.year,
      year: year,
      month: month.month,
      day: month.clampDay(day).day,
      coreRevision: coreRevision,
    );
  }

  ({int year, int month, int day}) _reconcileToAvailability(
    DashboardTemporalAnchor anchor,
    DashboardTemporalAvailability availability,
  ) {
    if (!availability.isRestrictive) {
      return (
        year: anchor.visibleYear,
        month: anchor.visibleMonth,
        day: anchor.visibleDay,
      );
    }
    final allowedYears = availability.allowedYears!;
    if (allowedYears.isEmpty) {
      throw StateError('A restrictive Query needs at least one allowed year.');
    }
    final year = availability.allowsYear(anchor.visibleYear)
        ? anchor.visibleYear
        : allowedYears.first;
    final months = availability.monthsForYear(year)!;
    if (months.isEmpty) {
      throw StateError('A restrictive Query needs an allowed month for $year.');
    }
    final month = months.contains(anchor.visibleMonth)
        ? anchor.visibleMonth
        : months.first;
    final yearMonth = YearMonth(year: year, month: month);
    final allowedDays = availability.daysForMonth(year, month);
    final unclampedDay = allowedDays == null || allowedDays.isEmpty
        ? anchor.visibleDay
        : (allowedDays.contains(anchor.visibleDay)
              ? anchor.visibleDay
              : allowedDays.first);
    return (
      year: year,
      month: month,
      day: yearMonth.clampDay(unclampedDay).day,
    );
  }

  DashboardNavigationState? _monthParentCandidate(
    int delta,
    int? coreRevision,
  ) {
    final anchor = _state.temporalAnchor;
    final current = anchor.visibleYearMonth;
    final restrictedMonths = _temporalAvailability.allowedYearMonths;
    final month = restrictedMonths == null
        ? _offsetYearMonth(current, delta)
        : _cyclicParentAdjacent(restrictedMonths, current, delta);
    if (month == null) return null;
    return _candidateFor(
      plane: TimePlane.month,
      year: month.year,
      month: month.month,
      day: month.clampDay(anchor.visibleDay).day,
      coreRevision: coreRevision,
    );
  }

  /// Summary parent navigation follows the same cyclic semantic universe as
  /// the rail. It is intentionally scoped to parent navigation so finite
  /// boundary semantics can remain explicit in future non-parent paths.
  static T? _cyclicParentAdjacent<T>(List<T> values, T current, int delta) {
    if (values.length <= 1) return null;
    final index = values.indexOf(current);
    if (index < 0) return null;
    final offset = delta % values.length;
    // A ballistic mother fling may span the entire restricted sibling ring.
    // Returning the current parent would publish an unnecessary query epoch;
    // treat that full-cycle result as the same safe no-op as a one-item ring.
    if (offset == 0) return null;
    final next = (index + offset + values.length) % values.length;
    return values[next];
  }

  static YearMonth? _offsetYearMonth(YearMonth current, int offset) {
    final zeroBasedMonth = (current.year - 1) * 12 + current.month - 1;
    final target = zeroBasedMonth + offset;
    if (target < 0 || target >= 9999 * 12) return null;
    return YearMonth(year: target ~/ 12 + 1, month: target % 12 + 1);
  }

  DashboardNavigationState _candidateFor({
    required TimePlane plane,
    int? year,
    int? month,
    int? day,
    LedgerDirection? direction,
    int? coreRevision,
  }) {
    final current = _state.temporalAnchor;
    final nextYear = year ?? current.visibleYear;
    final nextMonthValue = month ?? current.visibleMonth;
    final nextMonth = YearMonth(year: nextYear, month: nextMonthValue);
    final nextDay = nextMonth.clampDay(day ?? current.visibleDay).day;
    final template = _state.parentQueryScope.copyWith(
      direction: direction ?? _state.parentQueryScope.direction,
    );
    final parentQueryScope = _parentQueryScope(
      template: template,
      plane: plane,
      year: nextYear,
      month: nextMonth,
    );
    final anchor = _anchorFor(
      parentQueryScope: parentQueryScope,
      plane: plane,
      year: nextYear,
      month: nextMonthValue,
      day: nextDay,
      revision: coreRevision ?? current.revision,
      navigationEpoch: _state.navigationEpoch,
      filtersRefinementsIdentity: current.filtersRefinementsIdentity,
    );
    return _state.copyWith(
      plane: plane,
      parentQueryScope: parentQueryScope,
      temporalAnchor: anchor,
    );
  }

  void _publish(
    DashboardNavigationState candidate,
    DashboardTimeNavigationChange change,
    DashboardTemporalAnchorChangeReason anchorReason,
  ) {
    final oldAnchor = _state.temporalAnchor;
    final nextEpoch = _state.navigationEpoch + 1;
    final nextAnchor = candidate.temporalAnchor.copyWith(
      navigationEpoch: nextEpoch,
    );
    _state = candidate.copyWith(
      temporalAnchor: nextAnchor,
      navigationEpoch: nextEpoch,
      lastChange: change,
    );
    onTemporalAnchorChanged?.call(oldAnchor, nextAnchor, anchorReason);
    notifyListeners();
  }

  static DashboardTemporalAnchor _anchorFor({
    required CurrentLedgerQueryScope parentQueryScope,
    required TimePlane plane,
    required int year,
    required int month,
    required int day,
    required int revision,
    required int navigationEpoch,
    String? filtersRefinementsIdentity,
  }) {
    final yearMonth = YearMonth(year: year, month: month);
    final clampedDay = yearMonth.clampDay(day).day;
    final childScope = _childScopeFor(
      plane: plane,
      year: year,
      month: yearMonth,
      day: clampedDay,
    );
    return DashboardTemporalAnchor(
      visibleYear: year,
      visibleMonth: month,
      visibleDay: clampedDay,
      sourcePlane: plane,
      sourceParentQueryKey: parentQueryScope.key,
      sourceChildQueryKey: parentQueryScope.copyWith(timeScope: childScope).key,
      sourceChildOrdinal: switch (plane) {
        TimePlane.sum => year,
        TimePlane.year => month,
        TimePlane.month => clampedDay,
      },
      direction: parentQueryScope.direction,
      filtersRefinementsIdentity:
          filtersRefinementsIdentity ??
          DashboardTemporalAnchor.filtersRefinementsIdentityOf(
            parentQueryScope,
          ),
      revision: revision,
      navigationEpoch: navigationEpoch,
    );
  }

  static CurrentLedgerQueryScope _parentQueryScope({
    required CurrentLedgerQueryScope template,
    required TimePlane plane,
    required int year,
    required YearMonth month,
  }) => template.copyWith(
    timeScope: switch (plane) {
      TimePlane.sum => const AllTimeScope(),
      TimePlane.year => YearScope(year),
      TimePlane.month => MonthScope(month),
    },
  );

  static LedgerTimeScope _childScopeFor({
    required TimePlane plane,
    required int year,
    required YearMonth month,
    required int day,
  }) => switch (plane) {
    TimePlane.sum => YearScope(year),
    TimePlane.year => MonthScope(month),
    TimePlane.month => DayScope(
      LocalDate(year: year, month: month.month, day: day),
    ),
  };

  static const _planeOrder = <TimePlane>[
    TimePlane.sum,
    TimePlane.year,
    TimePlane.month,
  ];
}
