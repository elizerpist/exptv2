import 'package:flutter/foundation.dart';

import '../../query/domain/ledger_direction.dart';

/// One canonical local-time partition for the prepared DAY Spending Rhythm.
///
/// Ordinals are transport values shared with the native classifier. Keep this
/// order stable: it is deliberately a complete set of contiguous 3-hour
/// buckets, not a display-only grouping.
enum SpendingRhythmDayPart {
  midnight(label: 'Éjfél', displayLabel: '0'),
  dawn(label: 'Hajnal', displayLabel: '3'),
  morning(label: 'Reggel', displayLabel: '6'),
  lateMorning(label: 'Délelőtt', displayLabel: '9'),
  earlyAfternoon(label: 'Kora délután', displayLabel: '12'),
  afternoon(label: 'Délután', displayLabel: '15'),
  evening(label: 'Este', displayLabel: '18'),
  lateEvening(label: 'Késő este', displayLabel: '21');

  const SpendingRhythmDayPart({
    required this.label,
    required this.displayLabel,
  });

  /// Full localized semantic label announced by assistive technologies.
  final String label;

  /// Compact hour-of-day anchor for the narrow fixed-width DAY chart bars.
  /// It identifies the inclusive start of this 3-hour range without clipping
  /// the product's full Hungarian name into an 11dp bar slot.
  final String displayLabel;

  static const int bucketMinutes = 3 * 60;
  static const int bucketCount = 8;
}

/// A lightweight immutable view of one prepared non-zero local day. The
/// values remain in the owning compact bank; the view never allocates an
/// eight-element list during projection or painting.
@immutable
final class PreparedSpendingRhythmDay {
  const PreparedSpendingRhythmDay._({
    required PreparedSpendingRhythmDirectionBank bank,
    required this.index,
  }) : _bank = bank;

  final PreparedSpendingRhythmDirectionBank _bank;
  final int index;

  int get epochDay => _bank.epochDays[index];
  int get actualScaled100 => _bank.dailyActualScaled100[index];

  int actualFor(SpendingRhythmDayPart part) =>
      _bank.dayPartActualScaled100[index * SpendingRhythmDayPart.bucketCount +
          part.index];
}

/// Sparse, target-local prepared Spending Rhythm facts.
///
/// The flattened part vector is `[pointIndex * 8 + dayPart.ordinal]`. It is
/// intentionally compact: target views retain only a pair of indexes and can
/// answer scope projections without copying a target's history or touching a
/// repository.
@immutable
final class PreparedSpendingRhythmDirectionBank {
  PreparedSpendingRhythmDirectionBank({
    required this.targetCount,
    required List<int> targetOffsets,
    required List<int> epochDays,
    required List<int> dailyActualScaled100,
    required List<int> dayPartActualScaled100,
  }) : targetOffsets = List<int>.unmodifiable(targetOffsets),
       epochDays = List<int>.unmodifiable(epochDays),
       dailyActualScaled100 = List<int>.unmodifiable(dailyActualScaled100),
       dayPartActualScaled100 = List<int>.unmodifiable(dayPartActualScaled100) {
    _validate();
    _aggregatesByTarget =
        List<_PreparedSpendingRhythmTargetAggregates>.unmodifiable(
          List<_PreparedSpendingRhythmTargetAggregates>.generate(
            targetCount,
            _buildAggregatesForTarget,
            growable: false,
          ),
        );
  }

  factory PreparedSpendingRhythmDirectionBank.empty({
    required int targetCount,
  }) => PreparedSpendingRhythmDirectionBank(
    targetCount: targetCount,
    targetOffsets: List<int>.filled(targetCount + 1, 0),
    epochDays: const <int>[],
    dailyActualScaled100: const <int>[],
    dayPartActualScaled100: const <int>[],
  );

  final int targetCount;
  final List<int> targetOffsets;
  final List<int> epochDays;
  final List<int> dailyActualScaled100;
  final List<int> dayPartActualScaled100;
  late final List<_PreparedSpendingRhythmTargetAggregates> _aggregatesByTarget;

  int get pointCount => epochDays.length;

  PreparedSpendingRhythmTargetView targetView(int targetHandle) {
    if (targetHandle < 0 || targetHandle >= targetCount) {
      throw RangeError.range(targetHandle, 0, targetCount - 1, 'targetHandle');
    }
    return PreparedSpendingRhythmTargetView._(
      bank: this,
      startIndex: targetOffsets[targetHandle],
      endIndex: targetOffsets[targetHandle + 1],
      aggregates: _aggregatesByTarget[targetHandle],
    );
  }

  void _validate() {
    if (targetCount <= 0 ||
        targetOffsets.length != targetCount + 1 ||
        targetOffsets.firstOrNull != 0 ||
        targetOffsets.lastOrNull != epochDays.length ||
        dailyActualScaled100.length != epochDays.length ||
        dayPartActualScaled100.length !=
            epochDays.length * SpendingRhythmDayPart.bucketCount) {
      throw ArgumentError('Invalid prepared Spending Rhythm vector layout.');
    }
    for (var target = 0; target < targetCount; target += 1) {
      final start = targetOffsets[target];
      final end = targetOffsets[target + 1];
      if (start < 0 || start > end || end > epochDays.length) {
        throw ArgumentError('Invalid prepared Spending Rhythm target range.');
      }
      var previousEpochDay = -0x7fffffffffffffff;
      for (var index = start; index < end; index += 1) {
        final total = dailyActualScaled100[index];
        if (epochDays[index] <= previousEpochDay || total <= 0) {
          throw ArgumentError('Prepared Spending Rhythm days must be sorted.');
        }
        var partTotal = 0;
        final partStart = index * SpendingRhythmDayPart.bucketCount;
        for (
          var part = partStart;
          part < partStart + SpendingRhythmDayPart.bucketCount;
          part += 1
        ) {
          final value = dayPartActualScaled100[part];
          if (value < 0) {
            throw ArgumentError(
              'Prepared Spending Rhythm part cannot be negative.',
            );
          }
          partTotal += value;
        }
        if (partTotal != total) {
          throw ArgumentError(
            'Prepared Spending Rhythm day/part totals differ.',
          );
        }
        previousEpochDay = epochDays[index];
      }
    }
  }

  _PreparedSpendingRhythmTargetAggregates _buildAggregatesForTarget(
    int targetHandle,
  ) {
    final monthTotals = <int, int>{};
    final yearTotals = <int, int>{};
    final start = targetOffsets[targetHandle];
    final end = targetOffsets[targetHandle + 1];
    for (var index = start; index < end; index += 1) {
      final date = DateTime.utc(1970).add(Duration(days: epochDays[index]));
      final monthKey = _monthKey(date.year, date.month);
      final actual = dailyActualScaled100[index];
      monthTotals.update(
        monthKey,
        (total) => total + actual,
        ifAbsent: () => actual,
      );
      yearTotals.update(
        date.year,
        (total) => total + actual,
        ifAbsent: () => actual,
      );
    }
    final orderedMonthKeys = monthTotals.keys.toList()..sort();
    final orderedYears = yearTotals.keys.toList()..sort();
    return _PreparedSpendingRhythmTargetAggregates(
      monthKeys: List<int>.unmodifiable(orderedMonthKeys),
      monthActualScaled100: List<int>.unmodifiable(<int>[
        for (final key in orderedMonthKeys) monthTotals[key]!,
      ]),
      years: List<int>.unmodifiable(orderedYears),
      yearActualScaled100: List<int>.unmodifiable(<int>[
        for (final year in orderedYears) yearTotals[year]!,
      ]),
    );
  }
}

/// A no-copy target range in [PreparedSpendingRhythmDirectionBank].
@immutable
final class PreparedSpendingRhythmTargetView {
  const PreparedSpendingRhythmTargetView._({
    required PreparedSpendingRhythmDirectionBank bank,
    required this.startIndex,
    required this.endIndex,
    required _PreparedSpendingRhythmTargetAggregates aggregates,
  }) : _bank = bank,
       _aggregates = aggregates;

  final PreparedSpendingRhythmDirectionBank _bank;
  final int startIndex;
  final int endIndex;
  final _PreparedSpendingRhythmTargetAggregates _aggregates;

  int get length => endIndex - startIndex;
  bool get isEmpty => length == 0;

  PreparedSpendingRhythmDay dayAt(int targetLocalIndex) {
    if (targetLocalIndex < 0 || targetLocalIndex >= length) {
      throw RangeError.range(
        targetLocalIndex,
        0,
        length - 1,
        'targetLocalIndex',
      );
    }
    return PreparedSpendingRhythmDay._(
      bank: _bank,
      index: startIndex + targetLocalIndex,
    );
  }

  PreparedSpendingRhythmDay? dayAtEpochDay(int epochDay) {
    final index = lowerBound(epochDay);
    if (index >= endIndex || _bank.epochDays[index] != epochDay) return null;
    return PreparedSpendingRhythmDay._(bank: _bank, index: index);
  }

  int actualAtEpochDay(int epochDay) =>
      dayAtEpochDay(epochDay)?.actualScaled100 ?? 0;

  int actualForDayPartAtEpochDay({
    required int epochDay,
    required SpendingRhythmDayPart part,
  }) => dayAtEpochDay(epochDay)?.actualFor(part) ?? 0;

  /// Compact month aggregate built once with the prepared snapshot, never in
  /// a widget or painter.
  int actualForMonth({required int year, required int month}) =>
      _aggregates.monthActualFor(_monthKey(year, month));

  /// Exact prepared month-to-date actual for an existing DAY pace consumer.
  ///
  /// This preserves the former rhythm-bank contract while retaining the new
  /// time-of-day facts. It bounds the walk to this target's sparse points in
  /// one concrete calendar month after two binary searches; no controller,
  /// widget, or painter needs to calculate date windows from transactions.
  int actualForMonthThroughEpochDay({
    required int year,
    required int month,
    required int throughEpochDay,
  }) {
    final firstDay = DateTime.utc(
      year,
      month,
      1,
    ).difference(DateTime.utc(1970)).inDays;
    final lastDay = DateTime.utc(
      year,
      month + 1,
      0,
    ).difference(DateTime.utc(1970)).inDays;
    if (throughEpochDay < firstDay) return 0;
    final finalDay = throughEpochDay < lastDay ? throughEpochDay : lastDay;
    var total = 0;
    final endExclusive = lowerBound(finalDay + 1);
    for (var index = lowerBound(firstDay); index < endExclusive; index += 1) {
      total += _bank.dailyActualScaled100[index];
    }
    return total;
  }

  /// Compact year aggregate built once with the prepared snapshot, so SUM is
  /// O(year count) rather than a walk over every prepared local day.
  int actualForYear(int year) => _aggregates.yearActualFor(year);

  int? get firstYear => _aggregates.years.firstOrNull;
  int? get lastYear => _aggregates.years.lastOrNull;

  /// First bank index at or after [epochDay], constrained to this target.
  int lowerBound(int epochDay) {
    var lower = startIndex;
    var upper = endIndex;
    while (lower < upper) {
      final middle = (lower + upper) ~/ 2;
      if (_bank.epochDays[middle] < epochDay) {
        lower = middle + 1;
      } else {
        upper = middle;
      }
    }
    return lower;
  }

  Iterable<PreparedSpendingRhythmDay> daysInEpochRange({
    required int inclusiveStart,
    required int inclusiveEnd,
  }) sync* {
    if (inclusiveEnd < inclusiveStart) return;
    final endExclusive = lowerBound(inclusiveEnd + 1);
    for (
      var index = lowerBound(inclusiveStart);
      index < endExclusive;
      index += 1
    ) {
      yield PreparedSpendingRhythmDay._(bank: _bank, index: index);
    }
  }
}

int _monthKey(int year, int month) => year * 12 + month - 1;

@immutable
final class _PreparedSpendingRhythmTargetAggregates {
  const _PreparedSpendingRhythmTargetAggregates({
    required this.monthKeys,
    required this.monthActualScaled100,
    required this.years,
    required this.yearActualScaled100,
  });

  final List<int> monthKeys;
  final List<int> monthActualScaled100;
  final List<int> years;
  final List<int> yearActualScaled100;

  int monthActualFor(int monthKey) {
    final index = _lowerBound(monthKeys, monthKey);
    return index < monthKeys.length && monthKeys[index] == monthKey
        ? monthActualScaled100[index]
        : 0;
  }

  int yearActualFor(int year) {
    final index = _lowerBound(years, year);
    return index < years.length && years[index] == year
        ? yearActualScaled100[index]
        : 0;
  }
}

int _lowerBound(List<int> values, int value) {
  var lower = 0;
  var upper = values.length;
  while (lower < upper) {
    final middle = (lower + upper) ~/ 2;
    if (values[middle] < value) {
      lower = middle + 1;
    } else {
      upper = middle;
    }
  }
  return lower;
}

/// Prepared all-history facts for one exact dashboard core revision.
@immutable
final class PreparedSpendingRhythmSnapshot {
  const PreparedSpendingRhythmSnapshot({
    required this.coreRevision,
    required this.incomeBank,
    required this.expenseBank,
  }) : assert(coreRevision > 0);

  final int coreRevision;
  final PreparedSpendingRhythmDirectionBank incomeBank;
  final PreparedSpendingRhythmDirectionBank expenseBank;

  PreparedSpendingRhythmDirectionBank directionBank(
    LedgerDirection direction,
  ) => switch (direction) {
    LedgerDirection.income => incomeBank,
    LedgerDirection.expense => expenseBank,
  };
}
