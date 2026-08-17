import 'package:flutter/foundation.dart';

import '../../query/domain/ledger_direction.dart';

/// One typed financial-limit period. It has no string allocation on the hot
/// target/time semantic tick path.
sealed class BudgetLimitPeriod {
  const BudgetLimitPeriod();

  const factory BudgetLimitPeriod.sum() = BudgetLimitSumPeriod;
  const factory BudgetLimitPeriod.year(int year) = BudgetLimitYearPeriod;
  const factory BudgetLimitPeriod.month(int year, int month) =
      BudgetLimitMonthPeriod;
}

final class BudgetLimitSumPeriod extends BudgetLimitPeriod {
  const BudgetLimitSumPeriod();
}

final class BudgetLimitYearPeriod extends BudgetLimitPeriod {
  const BudgetLimitYearPeriod(this.year) : assert(year > 0);

  final int year;
}

final class BudgetLimitMonthPeriod extends BudgetLimitPeriod {
  const BudgetLimitMonthPeriod(this.year, this.month)
    : assert(year > 0),
      assert(month >= 1 && month <= 12);

  final int year;
  final int month;
}

@immutable
final class PreparedBudgetLimitCell {
  const PreparedBudgetLimitCell({
    required this.actualScaled100,
    required this.limitScaled100,
  }) : assert(actualScaled100 >= 0),
       assert(limitScaled100 == null || limitScaled100 >= 0);

  final int actualScaled100;
  final int? limitScaled100;

  bool get hasLimit => limitScaled100 != null;
}

/// Immutable dense limit/actual bank for one exact core revision and prepared
/// dashboard year window. Direction, slice and target-handle resolve one cell
/// by arithmetic only; no category-id search is permitted after publication.
@immutable
final class PreparedBudgetLimitSnapshot {
  PreparedBudgetLimitSnapshot({
    required this.coreRevision,
    required this.yearWindowStart,
    required this.yearWindowEndInclusive,
    required List<String> orderedCategoryIds,
    required List<PreparedBudgetLimitCell> cells,
    this.nativeSqlCallCount = 0,
    this.nativeSqlDurationMicros = 0,
  }) : orderedCategoryIds = List<String>.unmodifiable(orderedCategoryIds),
       cells = List<PreparedBudgetLimitCell>.unmodifiable(cells),
       assert(coreRevision > 0),
       assert(yearWindowStart > 0),
       assert(yearWindowEndInclusive >= yearWindowStart),
       assert(nativeSqlCallCount >= 0),
       assert(nativeSqlDurationMicros >= 0) {
    final expected =
        LedgerDirection.values.length * periodSliceCount * targetCount;
    if (this.cells.length != expected) {
      throw ArgumentError.value(
        cells.length,
        'cells',
        'Expected $expected dense cells for this revision window.',
      );
    }
    if (this.orderedCategoryIds.toSet().length !=
        this.orderedCategoryIds.length) {
      throw ArgumentError.value(
        orderedCategoryIds,
        'orderedCategoryIds',
        'Category IDs must be unique in an exact snapshot.',
      );
    }
  }

  final int coreRevision;
  final int yearWindowStart;
  final int yearWindowEndInclusive;
  final List<String> orderedCategoryIds;
  final List<PreparedBudgetLimitCell> cells;
  final int nativeSqlCallCount;
  final int nativeSqlDurationMicros;

  int get targetCount => orderedCategoryIds.length + 1;
  int get yearCount => yearWindowEndInclusive - yearWindowStart + 1;
  int get periodSliceCount => 1 + yearCount + yearCount * 12;

  int sliceIndexFor(BudgetLimitPeriod period) => switch (period) {
    BudgetLimitSumPeriod() => 0,
    BudgetLimitYearPeriod(:final year) => 1 + _yearOffset(year),
    BudgetLimitMonthPeriod(:final year, :final month) =>
      1 + yearCount + _yearOffset(year) * 12 + (month - 1),
  };

  PreparedBudgetLimitCell cellAt({
    required LedgerDirection direction,
    required BudgetLimitPeriod period,
    required int targetHandle,
  }) {
    if (targetHandle < 0 || targetHandle >= targetCount) {
      throw RangeError.range(targetHandle, 0, targetCount - 1, 'targetHandle');
    }
    final slice = sliceIndexFor(period);
    final directionOffset = direction.index * periodSliceCount * targetCount;
    return cells[directionOffset + slice * targetCount + targetHandle];
  }

  int _yearOffset(int year) {
    if (year < yearWindowStart || year > yearWindowEndInclusive) {
      throw RangeError.range(
        year,
        yearWindowStart,
        yearWindowEndInclusive,
        'year',
      );
    }
    return year - yearWindowStart;
  }
}
