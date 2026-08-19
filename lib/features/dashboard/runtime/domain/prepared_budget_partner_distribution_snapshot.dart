import 'package:flutter/foundation.dart';

import '../../query/domain/ledger_direction.dart';
import 'prepared_budget_limit_snapshot.dart';

/// One exact prepared partner amount with its deterministic category-colour
/// authority. An empty [dominantCategoryId] means this dense period cell has
/// no represented amount.
@immutable
final class PreparedBudgetPartnerDistributionCell {
  const PreparedBudgetPartnerDistributionCell({
    required this.actualScaled100,
    required this.dominantCategoryId,
  }) : assert(actualScaled100 >= 0),
       assert(actualScaled100 == 0 || dominantCategoryId != '');

  final int actualScaled100;
  final String dominantCategoryId;
}

/// One sparse positive amount for an exact period/category/partner triple.
/// [partnerHandle] remains local to its direction's partner domain.
@immutable
final class PreparedBudgetPartnerCategoryContribution {
  const PreparedBudgetPartnerCategoryContribution({
    required this.partnerHandle,
    required this.actualScaled100,
  }) : assert(partnerHandle >= 0),
       assert(actualScaled100 > 0);

  final int partnerHandle;
  final int actualScaled100;
}

/// One exact positive partner total for one ledger-local calendar day. The
/// dominant category is the same deterministic partner-colour authority used
/// by the existing Sum/Year/Month dense cells.
@immutable
final class PreparedBudgetPartnerDayCell {
  const PreparedBudgetPartnerDayCell({
    required this.partnerHandle,
    required this.actualScaled100,
    required this.dominantCategoryId,
  }) : assert(partnerHandle >= 0),
       assert(actualScaled100 > 0),
       assert(dominantCategoryId != '');

  final int partnerHandle;
  final int actualScaled100;
  final String dominantCategoryId;
}

/// Dense, direction-local partner domain. Unlike Budget target handles this
/// bank has no aggregate row: every handle represents one canonical partner.
@immutable
final class PreparedBudgetPartnerDistributionDirectionBank {
  PreparedBudgetPartnerDistributionDirectionBank({
    required List<String> orderedPartnerIds,
    required List<String> orderedPartnerTitles,
    required List<PreparedBudgetPartnerDistributionCell> cells,
    List<String> orderedCategoryIds = const <String>[],
    List<int>? categoryContributionOffsets,
    List<PreparedBudgetPartnerCategoryContribution> categoryContributions =
        const <PreparedBudgetPartnerCategoryContribution>[],
    List<int> dayEpochDays = const <int>[],
    List<int>? dayAggregateOffsets,
    List<PreparedBudgetPartnerDayCell> dayAggregateCells =
        const <PreparedBudgetPartnerDayCell>[],
    List<int>? dayCategoryContributionOffsets,
    List<PreparedBudgetPartnerCategoryContribution> dayCategoryContributions =
        const <PreparedBudgetPartnerCategoryContribution>[],
  }) : orderedPartnerIds = List<String>.unmodifiable(orderedPartnerIds),
       orderedPartnerTitles = List<String>.unmodifiable(orderedPartnerTitles),
       cells = List<PreparedBudgetPartnerDistributionCell>.unmodifiable(cells),
       orderedCategoryIds = List<String>.unmodifiable(orderedCategoryIds),
       categoryContributionOffsets = List<int>.unmodifiable(
         categoryContributionOffsets ??
             List<int>.filled(orderedCategoryIds.length + 1, 0),
       ),
       categoryContributions =
           List<PreparedBudgetPartnerCategoryContribution>.unmodifiable(
             categoryContributions,
           ),
       dayEpochDays = List<int>.unmodifiable(dayEpochDays),
       dayAggregateOffsets = List<int>.unmodifiable(
         dayAggregateOffsets ?? List<int>.filled(dayEpochDays.length + 1, 0),
       ),
       dayAggregateCells = List<PreparedBudgetPartnerDayCell>.unmodifiable(
         dayAggregateCells,
       ),
       dayCategoryContributionOffsets = List<int>.unmodifiable(
         dayCategoryContributionOffsets ??
             List<int>.filled(
               dayEpochDays.length * orderedCategoryIds.length + 1,
               0,
             ),
       ),
       dayCategoryContributions =
           List<PreparedBudgetPartnerCategoryContribution>.unmodifiable(
             dayCategoryContributions,
           ) {
    if (this.orderedPartnerIds.length != this.orderedPartnerTitles.length ||
        this.orderedPartnerIds.toSet().length !=
            this.orderedPartnerIds.length ||
        this.orderedPartnerIds.any((id) => id.isEmpty) ||
        this.orderedPartnerTitles.any((title) => title.isEmpty) ||
        this.orderedCategoryIds.toSet().length !=
            this.orderedCategoryIds.length) {
      throw ArgumentError('Invalid prepared partner direction domain.');
    }
    if (this.dayAggregateOffsets.length != this.dayEpochDays.length + 1 ||
        this.dayAggregateOffsets.first != 0 ||
        this.dayAggregateOffsets.last != this.dayAggregateCells.length ||
        this.dayCategoryContributionOffsets.length !=
            this.dayEpochDays.length * this.orderedCategoryIds.length + 1 ||
        this.dayCategoryContributionOffsets.first != 0 ||
        this.dayCategoryContributionOffsets.last !=
            this.dayCategoryContributions.length) {
      throw ArgumentError('Invalid prepared partner day distribution layout.');
    }
    var previousDay = -0x7fffffffffffffff;
    for (var dayIndex = 0; dayIndex < this.dayEpochDays.length; dayIndex += 1) {
      final day = this.dayEpochDays[dayIndex];
      if (day <= previousDay) {
        throw ArgumentError('Prepared partner days must be sorted/unique.');
      }
      previousDay = day;
      _requirePartnerRange(
        this.dayAggregateOffsets[dayIndex],
        this.dayAggregateOffsets[dayIndex + 1],
        this.dayAggregateCells.length,
      );
      var previousPartner = -1;
      for (
        var index = this.dayAggregateOffsets[dayIndex];
        index < this.dayAggregateOffsets[dayIndex + 1];
        index += 1
      ) {
        final cell = this.dayAggregateCells[index];
        if (cell.partnerHandle <= previousPartner ||
            cell.partnerHandle >= this.orderedPartnerIds.length) {
          throw ArgumentError(
            'Prepared day partner cells must be handle-sorted.',
          );
        }
        previousPartner = cell.partnerHandle;
      }
    }
    for (
      var index = 0;
      index < this.dayCategoryContributionOffsets.length - 1;
      index += 1
    ) {
      final start = this.dayCategoryContributionOffsets[index];
      final end = this.dayCategoryContributionOffsets[index + 1];
      _requirePartnerRange(start, end, this.dayCategoryContributions.length);
      var previousPartner = -1;
      for (
        var contributionIndex = start;
        contributionIndex < end;
        contributionIndex += 1
      ) {
        final contribution = this.dayCategoryContributions[contributionIndex];
        if (contribution.partnerHandle <= previousPartner ||
            contribution.partnerHandle >= this.orderedPartnerIds.length) {
          throw ArgumentError(
            'Prepared day partner contributions must be handle-sorted.',
          );
        }
        previousPartner = contribution.partnerHandle;
      }
    }
  }

  final List<String> orderedPartnerIds;
  final List<String> orderedPartnerTitles;
  final List<PreparedBudgetPartnerDistributionCell> cells;

  /// Exact direction-local Budget category domain. Target handle zero is the
  /// aggregate and does not have a contribution range; category handles 1+.
  final List<String> orderedCategoryIds;
  final List<int> categoryContributionOffsets;
  final List<PreparedBudgetPartnerCategoryContribution> categoryContributions;

  /// Sparse exact daily aggregate partner totals, keyed by [dayEpochDays].
  final List<int> dayEpochDays;
  final List<int> dayAggregateOffsets;
  final List<PreparedBudgetPartnerDayCell> dayAggregateCells;

  /// Sparse exact daily category-target amounts. The offsets are flattened as
  /// `dayIndex * orderedCategoryIds.length + (targetHandle - 1)`.
  final List<int> dayCategoryContributionOffsets;
  final List<PreparedBudgetPartnerCategoryContribution>
  dayCategoryContributions;

  int get partnerCount => orderedPartnerIds.length;
  int get categoryTargetCount => orderedCategoryIds.length + 1;

  void requireLayout({required int periodSliceCount}) {
    final expected = periodSliceCount * partnerCount;
    if (cells.length != expected) {
      throw ArgumentError.value(
        cells.length,
        'cells',
        'Expected $expected dense cells for one direction-local partner bank.',
      );
    }
    final contributionTargets = periodSliceCount * orderedCategoryIds.length;
    if (categoryContributionOffsets.length != contributionTargets + 1 ||
        categoryContributionOffsets.first != 0 ||
        categoryContributionOffsets.last != categoryContributions.length) {
      throw ArgumentError(
        'Invalid sparse partner category contribution layout.',
      );
    }
    for (var index = 0; index < contributionTargets; index += 1) {
      final start = categoryContributionOffsets[index];
      final end = categoryContributionOffsets[index + 1];
      if (start > end || start < 0 || end > categoryContributions.length) {
        throw ArgumentError('Invalid partner contribution range.');
      }
      var previousPartner = -1;
      for (
        var contributionIndex = start;
        contributionIndex < end;
        contributionIndex += 1
      ) {
        final contribution = categoryContributions[contributionIndex];
        if (contribution.partnerHandle <= previousPartner ||
            contribution.partnerHandle >= partnerCount) {
          throw ArgumentError('Partner contributions must be handle-sorted.');
        }
        previousPartner = contribution.partnerHandle;
      }
    }
  }

  PreparedBudgetPartnerDistributionCell cellAt({
    required int periodSliceIndex,
    required int partnerHandle,
  }) {
    if (partnerHandle < 0 || partnerHandle >= partnerCount) {
      throw RangeError.range(
        partnerHandle,
        0,
        partnerCount - 1,
        'partnerHandle',
      );
    }
    return cells[periodSliceIndex * partnerCount + partnerHandle];
  }

  List<PreparedBudgetPartnerCategoryContribution> contributionsFor({
    required int periodSliceIndex,
    required int targetHandle,
  }) {
    if (targetHandle == 0) {
      return const <PreparedBudgetPartnerCategoryContribution>[];
    }
    if (targetHandle < 0 || targetHandle >= categoryTargetCount) {
      throw RangeError.range(
        targetHandle,
        0,
        categoryTargetCount - 1,
        'targetHandle',
      );
    }
    final index =
        periodSliceIndex * orderedCategoryIds.length + targetHandle - 1;
    return categoryContributions.sublist(
      categoryContributionOffsets[index],
      categoryContributionOffsets[index + 1],
    );
  }

  List<PreparedBudgetPartnerDayCell> dayAggregateFor(int epochDay) {
    final dayIndex = _dayIndex(epochDay);
    if (dayIndex < 0) return const <PreparedBudgetPartnerDayCell>[];
    return dayAggregateCells.sublist(
      dayAggregateOffsets[dayIndex],
      dayAggregateOffsets[dayIndex + 1],
    );
  }

  List<PreparedBudgetPartnerCategoryContribution> dayContributionsFor({
    required int epochDay,
    required int targetHandle,
  }) {
    if (targetHandle == 0) {
      return <PreparedBudgetPartnerCategoryContribution>[
        for (final cell in dayAggregateFor(epochDay))
          PreparedBudgetPartnerCategoryContribution(
            partnerHandle: cell.partnerHandle,
            actualScaled100: cell.actualScaled100,
          ),
      ];
    }
    if (targetHandle < 0 || targetHandle >= categoryTargetCount) {
      throw RangeError.range(
        targetHandle,
        0,
        categoryTargetCount - 1,
        'targetHandle',
      );
    }
    final dayIndex = _dayIndex(epochDay);
    if (dayIndex < 0) {
      return const <PreparedBudgetPartnerCategoryContribution>[];
    }
    final index = dayIndex * orderedCategoryIds.length + targetHandle - 1;
    return dayCategoryContributions.sublist(
      dayCategoryContributionOffsets[index],
      dayCategoryContributionOffsets[index + 1],
    );
  }

  String? dayDominantCategoryIdFor({
    required int epochDay,
    required int partnerHandle,
  }) {
    final dayIndex = _dayIndex(epochDay);
    if (dayIndex < 0) return null;
    var low = dayAggregateOffsets[dayIndex];
    var high = dayAggregateOffsets[dayIndex + 1];
    while (low < high) {
      final middle = (low + high) ~/ 2;
      final handle = dayAggregateCells[middle].partnerHandle;
      if (handle < partnerHandle) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final end = dayAggregateOffsets[dayIndex + 1];
    return low < end && dayAggregateCells[low].partnerHandle == partnerHandle
        ? dayAggregateCells[low].dominantCategoryId
        : null;
  }

  int _dayIndex(int epochDay) {
    var low = 0;
    var high = dayEpochDays.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (dayEpochDays[middle] < epochDay) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low < dayEpochDays.length && dayEpochDays[low] == epochDay
        ? low
        : -1;
  }

  void _requirePartnerRange(int start, int end, int length) {
    if (start > end || start < 0 || end > length) {
      throw ArgumentError('Invalid prepared partner day range.');
    }
  }
}

/// Query-independent exact-revision partner distribution source. It shares
/// [BudgetLimitPeriod] arithmetic with the existing prepared Budget bank so
/// TimeRefinement cannot drift into a second period interpretation.
@immutable
final class PreparedBudgetPartnerDistributionSnapshot {
  PreparedBudgetPartnerDistributionSnapshot({
    required this.coreRevision,
    required this.yearWindowStart,
    required this.yearWindowEndInclusive,
    required this.incomeBank,
    required this.expenseBank,
    this.nativeSqlCallCount = 0,
    this.nativeSqlDurationMicros = 0,
  }) : assert(coreRevision > 0),
       assert(yearWindowStart > 0),
       assert(yearWindowEndInclusive >= yearWindowStart),
       assert(nativeSqlCallCount >= 0),
       assert(nativeSqlDurationMicros >= 0) {
    incomeBank.requireLayout(periodSliceCount: periodSliceCount);
    expenseBank.requireLayout(periodSliceCount: periodSliceCount);
  }

  final int coreRevision;
  final int yearWindowStart;
  final int yearWindowEndInclusive;
  final PreparedBudgetPartnerDistributionDirectionBank incomeBank;
  final PreparedBudgetPartnerDistributionDirectionBank expenseBank;
  final int nativeSqlCallCount;
  final int nativeSqlDurationMicros;

  int get yearCount => yearWindowEndInclusive - yearWindowStart + 1;
  int get periodSliceCount => 1 + yearCount + yearCount * 12;

  PreparedBudgetPartnerDistributionDirectionBank directionBank(
    LedgerDirection direction,
  ) => switch (direction) {
    LedgerDirection.income => incomeBank,
    LedgerDirection.expense => expenseBank,
  };

  int sliceIndexFor(BudgetLimitPeriod period) => switch (period) {
    BudgetLimitSumPeriod() => 0,
    BudgetLimitYearPeriod(:final year) => 1 + _yearOffset(year),
    BudgetLimitMonthPeriod(:final year, :final month) =>
      1 + yearCount + _yearOffset(year) * 12 + month - 1,
  };

  PreparedBudgetPartnerDistributionCell cellAt({
    required LedgerDirection direction,
    required BudgetLimitPeriod period,
    required int partnerHandle,
  }) => directionBank(direction).cellAt(
    periodSliceIndex: sliceIndexFor(period),
    partnerHandle: partnerHandle,
  );

  List<PreparedBudgetPartnerCategoryContribution> contributionsFor({
    required LedgerDirection direction,
    required BudgetLimitPeriod period,
    required int targetHandle,
  }) => directionBank(direction).contributionsFor(
    periodSliceIndex: sliceIndexFor(period),
    targetHandle: targetHandle,
  );

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
