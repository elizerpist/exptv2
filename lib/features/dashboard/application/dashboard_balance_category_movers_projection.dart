import 'package:flutter/foundation.dart';

import '../query/data/dashboard_ledger_entry.dart';
import '../query/domain/ledger_direction.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/year_month.dart';
import 'dashboard_balance_primary_identity.dart';

/// An inclusive calendar comparison range. It is intentionally a value object
/// so Core can publish the exact selected and reference periods alongside the
/// values derived from its resident prepared membership.
@immutable
final class DashboardBalanceCategoryComparisonWindow {
  const DashboardBalanceCategoryComparisonWindow({
    required this.startInclusive,
    required this.endInclusive,
  });

  final LocalDate startInclusive;
  final LocalDate endInclusive;

  bool containsEpochDay(int epochDay) =>
      epochDay >= startInclusive.epochDay && epochDay <= endInclusive.epochDay;

  @override
  bool operator ==(Object other) =>
      other is DashboardBalanceCategoryComparisonWindow &&
      other.startInclusive == startInclusive &&
      other.endInclusive == endInclusive;

  @override
  int get hashCode => Object.hash(startInclusive, endInclusive);
}

/// One period bucket in the in-card category trend. Values are amounts for the
/// real bucket, never interpolated points or a renderer-side ledger scan.
@immutable
final class DashboardBalanceCategoryMoverTrendPoint {
  const DashboardBalanceCategoryMoverTrendPoint({
    required this.bucket,
    required this.currentMinor,
    required this.referenceMinor,
  });

  final int bucket;
  final int currentMinor;
  final int referenceMinor;
}

/// One canonical-category comparison result. Money stays in minor/scaled
/// integer units; percentage is only a deterministic derived display value.
@immutable
final class DashboardBalanceCategoryMover {
  DashboardBalanceCategoryMover({
    required this.id,
    required this.label,
    required this.categoryColorId,
    required this.categoryIconId,
    required this.currentMinor,
    required this.referenceMinor,
    required List<DashboardBalanceCategoryMoverTrendPoint> trend,
  }) : trend = List<DashboardBalanceCategoryMoverTrendPoint>.unmodifiable(
         trend,
       );

  final String id;
  final String label;
  final String categoryColorId;
  final String categoryIconId;
  final int currentMinor;
  final int referenceMinor;
  final List<DashboardBalanceCategoryMoverTrendPoint> trend;

  int get deltaMinor => currentMinor - referenceMinor;
  int get impactMinor => deltaMinor.abs();
  bool get isNew => referenceMinor == 0 && currentMinor > 0;

  /// 10000 means 100.00%. `null` is the explicit finite `New` presentation
  /// state; callers must never turn it into an infinity value.
  int? get percentageBasisPoints =>
      referenceMinor == 0 ? null : (deltaMinor * 10000) ~/ referenceMinor;
}

/// Immutable exact-identity input to both the Balance upper hero and lower
/// Movers renderer. The two widgets never calculate or sort independently.
@immutable
final class DashboardBalanceCategoryMoversPresentation {
  DashboardBalanceCategoryMoversPresentation({
    required this.identity,
    required this.timeScope,
    required this.selectedDirection,
    required this.logicalAsOfDate,
    required this.currentWindow,
    required this.referenceWindow,
    required List<DashboardBalanceCategoryMover> movers,
  }) : movers = List<DashboardBalanceCategoryMover>.unmodifiable(movers),
       presentationId = Object.hashAll(<Object?>[
         identity,
         timeScope.canonicalKey,
         selectedDirection,
         logicalAsOfDate,
         currentWindow,
         referenceWindow,
         for (final mover in movers)
           '${mover.id}:${mover.currentMinor}:${mover.referenceMinor}:'
               '${mover.trend.map((point) => '${point.bucket}:${point.currentMinor}:${point.referenceMinor}').join(',')}',
       ]);

  final DashboardBalancePrimaryIdentity identity;
  final LedgerTimeScope timeScope;
  final LedgerDirection selectedDirection;
  final LocalDate logicalAsOfDate;
  final DashboardBalanceCategoryComparisonWindow currentWindow;
  final DashboardBalanceCategoryComparisonWindow referenceWindow;
  final List<DashboardBalanceCategoryMover> movers;
  final int presentationId;

  bool get isNoChange => movers.isEmpty;
}

/// Pure Balance analytics over one already selected directional prepared
/// membership. It intentionally aggregates canonical `categoryId` values: one
/// entry contributes once to its exact prepared category, so a parent/child
/// hierarchy cannot be double-counted by this projection.
abstract final class DashboardBalanceCategoryMoversProjection {
  static DashboardBalanceCategoryMoversPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required LedgerDirection selectedDirection,
    required LocalDate logicalAsOfDate,
    required Iterable<DashboardLedgerEntry> entries,
  }) {
    final windows = _windowsFor(timeScope, logicalAsOfDate);
    final accumulators = <String, _CategoryAccumulator>{};
    for (final entry in entries) {
      final current = windows.current.containsEpochDay(
        entry.bookedLocalEpochDay,
      );
      final reference = windows.reference.containsEpochDay(
        entry.bookedLocalEpochDay,
      );
      if (!current && !reference) continue;
      final accumulator = accumulators.putIfAbsent(
        entry.categoryId,
        () => _CategoryAccumulator(entry),
      );
      accumulator.observeMetadata(entry);
      final amount = entry.amountMinor.abs();
      if (current) accumulator.currentMinor += amount;
      if (reference) accumulator.referenceMinor += amount;
    }
    // First rank every category by the existing comparison rule. Detailed
    // trends are deliberately built only for the bounded rendered Top 5, so a
    // high-cardinality ledger never triggers a category-count × ledger scan.
    final ranked =
        accumulators.values
            .where((item) => item.currentMinor != item.referenceMinor)
            .toList(growable: false)
          ..sort((left, right) {
            final impact = (right.currentMinor - right.referenceMinor)
                .abs()
                .compareTo((left.currentMinor - left.referenceMinor).abs());
            if (impact != 0) return impact;
            final current = right.currentMinor.compareTo(left.currentMinor);
            return current != 0 ? current : left.id.compareTo(right.id);
          });
    final movers = List<DashboardBalanceCategoryMover>.unmodifiable(
      ranked
          .take(5)
          .map(
            (item) => DashboardBalanceCategoryMover(
              id: item.id,
              label: item.label,
              categoryColorId: item.categoryColorId,
              categoryIconId: item.categoryIconId,
              currentMinor: item.currentMinor,
              referenceMinor: item.referenceMinor,
              trend: _trendFor(
                item.id,
                timeScope,
                windows.current,
                windows.reference,
                entries,
              ),
            ),
          )
          .toList(growable: false),
    );
    return DashboardBalanceCategoryMoversPresentation(
      identity: identity,
      timeScope: timeScope,
      selectedDirection: selectedDirection,
      logicalAsOfDate: logicalAsOfDate,
      currentWindow: windows.current,
      referenceWindow: windows.reference,
      movers: movers,
    );
  }

  static ({
    DashboardBalanceCategoryComparisonWindow current,
    DashboardBalanceCategoryComparisonWindow reference,
  })
  _windowsFor(LedgerTimeScope scope, LocalDate asOf) => switch (scope) {
    AllTimeScope() => _yearToDateWindows(asOf.year, asOf),
    YearScope(:final year) =>
      year == asOf.year
          ? _yearToDateWindows(year, asOf)
          : _completeYearWindows(year),
    MonthScope(:final value) =>
      value.year == asOf.year && value.month == asOf.month
          ? _monthToDateWindows(value, asOf.day)
          : _completeMonthWindows(value),
    DayScope(:final date) => (
      current: DashboardBalanceCategoryComparisonWindow(
        startInclusive: date,
        endInclusive: date,
      ),
      reference: DashboardBalanceCategoryComparisonWindow(
        startInclusive: _dateForEpochDay(date.epochDay - 1),
        endInclusive: _dateForEpochDay(date.epochDay - 1),
      ),
    ),
  };

  static ({
    DashboardBalanceCategoryComparisonWindow current,
    DashboardBalanceCategoryComparisonWindow reference,
  })
  _yearToDateWindows(int year, LocalDate asOf) {
    final currentEnd = LocalDate(
      year: year,
      month: asOf.month,
      day: _daysInMonth(year, asOf.month).clamp(1, asOf.day).toInt(),
    );
    final referenceYear = year - 1;
    return (
      current: DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: year, month: 1, day: 1),
        endInclusive: currentEnd,
      ),
      reference: DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: referenceYear, month: 1, day: 1),
        endInclusive: LocalDate(
          year: referenceYear,
          month: currentEnd.month,
          day: _daysInMonth(
            referenceYear,
            currentEnd.month,
          ).clamp(1, currentEnd.day).toInt(),
        ),
      ),
    );
  }

  static ({
    DashboardBalanceCategoryComparisonWindow current,
    DashboardBalanceCategoryComparisonWindow reference,
  })
  _completeYearWindows(int year) => (
    current: DashboardBalanceCategoryComparisonWindow(
      startInclusive: LocalDate(year: year, month: 1, day: 1),
      endInclusive: LocalDate(year: year, month: 12, day: 31),
    ),
    reference: DashboardBalanceCategoryComparisonWindow(
      startInclusive: LocalDate(year: year - 1, month: 1, day: 1),
      endInclusive: LocalDate(year: year - 1, month: 12, day: 31),
    ),
  );

  static ({
    DashboardBalanceCategoryComparisonWindow current,
    DashboardBalanceCategoryComparisonWindow reference,
  })
  _monthToDateWindows(YearMonth value, int asOfDay) {
    final previous = value.previous();
    final currentEnd = value.clampDay(asOfDay);
    return (
      current: DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: value.year, month: value.month, day: 1),
        endInclusive: currentEnd,
      ),
      reference: DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(
          year: previous.year,
          month: previous.month,
          day: 1,
        ),
        endInclusive: previous.clampDay(currentEnd.day),
      ),
    );
  }

  static ({
    DashboardBalanceCategoryComparisonWindow current,
    DashboardBalanceCategoryComparisonWindow reference,
  })
  _completeMonthWindows(YearMonth value) {
    final previous = value.previous();
    return (
      current: DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: value.year, month: value.month, day: 1),
        endInclusive: value.clampDay(value.daysInMonth),
      ),
      reference: DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(
          year: previous.year,
          month: previous.month,
          day: 1,
        ),
        endInclusive: previous.clampDay(previous.daysInMonth),
      ),
    );
  }

  static List<DashboardBalanceCategoryMoverTrendPoint> _trendFor(
    String categoryId,
    LedgerTimeScope scope,
    DashboardBalanceCategoryComparisonWindow current,
    DashboardBalanceCategoryComparisonWindow reference,
    Iterable<DashboardLedgerEntry> entries,
  ) {
    final currentTotals = _totalsForCategory(entries, categoryId, current);
    final referenceTotals = _totalsForCategory(entries, categoryId, reference);
    final bucketCount = switch (scope) {
      AllTimeScope() || YearScope() => _monthCount(current),
      MonthScope() =>
        current.endInclusive.epochDay - current.startInclusive.epochDay + 1,
      DayScope() => 1,
    };
    return List<DashboardBalanceCategoryMoverTrendPoint>.unmodifiable(
      List<DashboardBalanceCategoryMoverTrendPoint>.generate(
        bucketCount,
        (index) => DashboardBalanceCategoryMoverTrendPoint(
          bucket: index + 1,
          currentMinor: currentTotals[index + 1] ?? 0,
          referenceMinor: referenceTotals[index + 1] ?? 0,
        ),
      ),
    );
  }

  static Map<int, int> _totalsForCategory(
    Iterable<DashboardLedgerEntry> entries,
    String categoryId,
    DashboardBalanceCategoryComparisonWindow window,
  ) {
    final totals = <int, int>{};
    for (final entry in entries) {
      if (entry.categoryId != categoryId ||
          !window.containsEpochDay(entry.bookedLocalEpochDay)) {
        continue;
      }
      final date = _dateForEpochDay(entry.bookedLocalEpochDay);
      final bucket = switch (_monthCount(window)) {
        > 1 => date.month,
        1 when window.startInclusive != window.endInclusive => date.day,
        _ => 1,
      };
      totals.update(
        bucket,
        (value) => value + entry.amountMinor.abs(),
        ifAbsent: () => entry.amountMinor.abs(),
      );
    }
    return totals;
  }

  static int _monthCount(DashboardBalanceCategoryComparisonWindow window) =>
      (window.endInclusive.year - window.startInclusive.year) * 12 +
      window.endInclusive.month -
      window.startInclusive.month +
      1;

  static int _daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  static LocalDate _dateForEpochDay(int epochDay) {
    final date = DateTime.utc(1970).add(Duration(days: epochDay));
    return LocalDate(year: date.year, month: date.month, day: date.day);
  }
}

final class _CategoryAccumulator {
  _CategoryAccumulator(DashboardLedgerEntry entry)
    : id = entry.categoryId,
      representative = entry;

  final String id;
  DashboardLedgerEntry representative;
  int currentMinor = 0;
  int referenceMinor = 0;

  String get label {
    final value = representative.categoryDisplayName?.trim();
    return value == null || value.isEmpty ? 'Kategorizálatlan' : value;
  }

  String get categoryColorId => representative.categoryColorId ?? 'fallback';
  String get categoryIconId => representative.categoryIconId ?? 'fallback';

  void observeMetadata(DashboardLedgerEntry entry) {
    if (entry.id.compareTo(representative.id) < 0) representative = entry;
  }
}
