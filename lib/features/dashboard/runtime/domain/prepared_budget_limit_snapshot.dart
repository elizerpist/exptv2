import 'package:flutter/foundation.dart';

import '../../query/domain/ledger_direction.dart';
import 'prepared_budget_rhythm_snapshot.dart';

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
/// dashboard direction. Handle zero is aggregate; all other handles are local
/// to this bank and may not be used in the other direction.
@immutable
final class PreparedBudgetLimitDirectionBank {
  PreparedBudgetLimitDirectionBank({
    required List<String> orderedCategoryIds,
    required List<PreparedBudgetLimitCell> cells,
  }) : orderedCategoryIds = List<String>.unmodifiable(orderedCategoryIds),
       cells = List<PreparedBudgetLimitCell>.unmodifiable(cells) {
    if (this.orderedCategoryIds.toSet().length !=
        this.orderedCategoryIds.length) {
      throw ArgumentError.value(
        orderedCategoryIds,
        'orderedCategoryIds',
        'Category IDs must be unique in one direction-local Budget bank.',
      );
    }
  }

  final List<String> orderedCategoryIds;
  final List<PreparedBudgetLimitCell> cells;

  int get targetCount => orderedCategoryIds.length + 1;

  void requireLayout({required int periodSliceCount}) {
    final expected = periodSliceCount * targetCount;
    if (cells.length != expected) {
      throw ArgumentError.value(
        cells.length,
        'cells',
        'Expected $expected dense cells for one direction-local Budget bank.',
      );
    }
  }

  PreparedBudgetLimitCell cellAt({
    required int periodSliceIndex,
    required int targetHandle,
  }) {
    if (targetHandle < 0 || targetHandle >= targetCount) {
      throw RangeError.range(targetHandle, 0, targetCount - 1, 'targetHandle');
    }
    return cells[periodSliceIndex * targetCount + targetHandle];
  }
}

/// Immutable exact-revision Budget snapshot. Each direction owns a separate
/// dense target domain; only period arithmetic remains shared.
@immutable
final class PreparedBudgetLimitSnapshot {
  PreparedBudgetLimitSnapshot({
    required this.coreRevision,
    required this.yearWindowStart,
    required this.yearWindowEndInclusive,
    required this.incomeBank,
    required this.expenseBank,
    this.rhythmSnapshot,
    this.nativeSqlCallCount = 0,
    this.nativeSqlDurationMicros = 0,
  }) : assert(coreRevision > 0),
       assert(yearWindowStart > 0),
       assert(yearWindowEndInclusive >= yearWindowStart),
       assert(nativeSqlCallCount >= 0),
       assert(nativeSqlDurationMicros >= 0) {
    incomeBank.requireLayout(periodSliceCount: periodSliceCount);
    expenseBank.requireLayout(periodSliceCount: periodSliceCount);
    final rhythm = rhythmSnapshot;
    if (rhythm != null &&
        (rhythm.coreRevision != coreRevision ||
            rhythm.incomeBank.targetCount != incomeBank.targetCount ||
            rhythm.expenseBank.targetCount != expenseBank.targetCount)) {
      throw ArgumentError(
        'Prepared Budget rhythm must share the exact revision and target domains.',
      );
    }
  }

  final int coreRevision;
  final int yearWindowStart;
  final int yearWindowEndInclusive;
  final PreparedBudgetLimitDirectionBank incomeBank;
  final PreparedBudgetLimitDirectionBank expenseBank;

  /// Sparse query-independent daily actuals retained from the same native
  /// acquisition as this dense SUM/YEAR/MONTH bank. It is intentionally
  /// optional only while decoding legacy test fixtures; production payloads
  /// are versioned to include it.
  final PreparedBudgetRhythmSnapshot? rhythmSnapshot;
  final int nativeSqlCallCount;
  final int nativeSqlDurationMicros;

  int get yearCount => yearWindowEndInclusive - yearWindowStart + 1;
  int get periodSliceCount => 1 + yearCount + yearCount * 12;

  PreparedBudgetLimitDirectionBank directionBank(LedgerDirection direction) =>
      switch (direction) {
        LedgerDirection.income => incomeBank,
        LedgerDirection.expense => expenseBank,
      };

  int targetCountFor(LedgerDirection direction) =>
      directionBank(direction).targetCount;

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
    final slice = sliceIndexFor(period);
    return directionBank(
      direction,
    ).cellAt(periodSliceIndex: slice, targetHandle: targetHandle);
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
