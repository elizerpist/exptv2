import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../query/data/dashboard_ledger_entry.dart';
import '../query/domain/ledger_direction.dart';
import '../time_navigation/domain/ledger_time_scope.dart';

const _minutesPerDay = 24 * 60;
const _categoryDayOccurrenceLimit = 12;
const _partnerRecentOccurrenceLimit = 5;
const _partnerCadenceOccurrenceLimit = 8;
const _minorPerForint = 100;

/// Compact rank metadata supplied by the existing rank owner.  It is an
/// internal projection input, not a second rank algorithm.
@immutable
final class DashboardBalanceEntityInsightSeed {
  const DashboardBalanceEntityInsightSeed({
    required this.id,
    required this.label,
    required this.direction,
  });

  final String id;
  final String label;
  final LedgerDirection direction;
}

/// A bounded temporal value for an entity detail.  Category values are money;
/// partner values are occurrence counts, as declared by the owning insight.
@immutable
final class DashboardBalanceEntityTemporalBucket {
  const DashboardBalanceEntityTemporalBucket({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final int value;
}

/// Render-safe occurrence data. It carries no partner or category display
/// string, so a detail cannot accidentally leak the sibling analytics domain.
@immutable
final class DashboardBalanceEntityOccurrence {
  const DashboardBalanceEntityOccurrence({
    required this.id,
    required this.epochDay,
    required this.localTimeMinutes,
    required this.amountMinor,
    required this.occurredOrder,
  });

  final String id;
  final int epochDay;
  final int localTimeMinutes;
  final int amountMinor;
  final int occurredOrder;
}

@immutable
final class DashboardBalanceTransactionSizeDistribution {
  const DashboardBalanceTransactionSizeDistribution({
    required this.zeroToFiveKCount,
    required this.fiveToTenKCount,
    required this.tenToTwentyKCount,
    required this.twentyKPlusCount,
  });

  final int zeroToFiveKCount;
  final int fiveToTenKCount;
  final int tenToTwentyKCount;
  final int twentyKPlusCount;

  List<int> get counts => List<int>.unmodifiable(<int>[
    zeroToFiveKCount,
    fiveToTenKCount,
    tenToTwentyKCount,
    twentyKPlusCount,
  ]);

  int get totalCount =>
      zeroToFiveKCount + fiveToTenKCount + tenToTwentyKCount + twentyKPlusCount;

  /// A lowest-value tie wins by using the first maximum index.
  int get dominantBucketIndex {
    var winner = 0;
    for (var index = 1; index < counts.length; index += 1) {
      if (counts[index] > counts[winner]) winner = index;
    }
    return winner;
  }
}

@immutable
final class DashboardBalanceCategoryInsight {
  DashboardBalanceCategoryInsight({
    required this.id,
    required this.label,
    required this.direction,
    required this.amountMinor,
    required this.activeDirectionScopeAmountMinor,
    required this.transactionCount,
    required this.activeDayCount,
    required this.medianAmountTimesTwo,
    required List<DashboardBalanceEntityTemporalBucket> temporalBuckets,
    required this.distribution,
    required this.minimumAmountMinor,
    required this.maximumAmountMinor,
    required List<DashboardBalanceEntityOccurrence> dayOccurrences,
    required this.hiddenDayOccurrenceCount,
  }) : temporalBuckets =
           List<DashboardBalanceEntityTemporalBucket>.unmodifiable(
             temporalBuckets,
           ),
       dayOccurrences = List<DashboardBalanceEntityOccurrence>.unmodifiable(
         dayOccurrences,
       );

  final String id;
  final String label;
  final LedgerDirection direction;
  final int amountMinor;
  final int activeDirectionScopeAmountMinor;
  final int transactionCount;
  final int activeDayCount;
  final int medianAmountTimesTwo;
  final List<DashboardBalanceEntityTemporalBucket> temporalBuckets;
  final DashboardBalanceTransactionSizeDistribution distribution;
  final int minimumAmountMinor;
  final int maximumAmountMinor;
  final List<DashboardBalanceEntityOccurrence> dayOccurrences;
  final int hiddenDayOccurrenceCount;

  int get shareBasisPoints => activeDirectionScopeAmountMinor == 0
      ? 0
      : (amountMinor * 10000 ~/ activeDirectionScopeAmountMinor);

  int get roundedMedianAmountMinor => _roundHalfUp(medianAmountTimesTwo);
  bool get usesDayLowSampleFallback => transactionCount < 4;
}

@immutable
final class DashboardBalancePartnerRelationship {
  DashboardBalancePartnerRelationship({
    required this.allHistoryTransactionCount,
    required this.firstOccurrence,
    required this.latestOccurrence,
    required this.medianAmountTimesTwo,
    required this.firstQuartileAmountMinor,
    required this.thirdQuartileAmountMinor,
    required this.typicalCadenceMinutesTimesTwo,
    required List<DashboardBalanceEntityOccurrence> cadenceOccurrences,
  }) : cadenceOccurrences = List<DashboardBalanceEntityOccurrence>.unmodifiable(
         cadenceOccurrences,
       );

  final int allHistoryTransactionCount;
  final DashboardBalanceEntityOccurrence firstOccurrence;
  final DashboardBalanceEntityOccurrence latestOccurrence;
  final int medianAmountTimesTwo;
  final int firstQuartileAmountMinor;
  final int thirdQuartileAmountMinor;

  /// Null means fewer than three truthful transactions / two intervals.
  final int? typicalCadenceMinutesTimesTwo;
  final List<DashboardBalanceEntityOccurrence> cadenceOccurrences;

  int get roundedMedianAmountMinor => _roundHalfUp(medianAmountTimesTwo);
  int? get roundedTypicalCadenceMinutes => typicalCadenceMinutesTimesTwo == null
      ? null
      : _roundHalfUp(typicalCadenceMinutesTimesTwo!);
}

@immutable
final class DashboardBalancePartnerInsight {
  DashboardBalancePartnerInsight({
    required this.id,
    required this.label,
    required this.direction,
    required this.amountMinor,
    required this.transactionCount,
    required this.activeDayCount,
    required this.latestScopeOccurrence,
    required List<DashboardBalanceEntityTemporalBucket> temporalBuckets,
    required List<DashboardBalanceEntityOccurrence> recentScopeOccurrences,
    required this.relationship,
  }) : temporalBuckets =
           List<DashboardBalanceEntityTemporalBucket>.unmodifiable(
             temporalBuckets,
           ),
       recentScopeOccurrences =
           List<DashboardBalanceEntityOccurrence>.unmodifiable(
             recentScopeOccurrences,
           );

  final String id;
  final String label;
  final LedgerDirection direction;
  final int amountMinor;
  final int transactionCount;
  final int activeDayCount;
  final DashboardBalanceEntityOccurrence latestScopeOccurrence;
  final List<DashboardBalanceEntityTemporalBucket> temporalBuckets;
  final List<DashboardBalanceEntityOccurrence> recentScopeOccurrences;
  final DashboardBalancePartnerRelationship relationship;
}

@immutable
final class DashboardBalanceEntityInsights {
  DashboardBalanceEntityInsights({
    required Map<String, DashboardBalanceCategoryInsight> categories,
    required Map<String, DashboardBalancePartnerInsight> partners,
  }) : categories = Map<String, DashboardBalanceCategoryInsight>.unmodifiable(
         categories,
       ),
       partners = Map<String, DashboardBalancePartnerInsight>.unmodifiable(
         partners,
       );

  final Map<String, DashboardBalanceCategoryInsight> categories;
  final Map<String, DashboardBalancePartnerInsight> partners;
}

/// Builds bounded detail payloads after the pre-existing Top-5 rank selection.
/// It has no repository, Query, scene, or widget capability.
abstract final class DashboardBalanceEntityInsightsProjection {
  static DashboardBalanceEntityInsights build({
    required LedgerTimeScope timeScope,
    required Iterable<DashboardLedgerEntry> scopedDirectionalEntries,
    required Iterable<DashboardLedgerEntry> fullDirectionalEntries,
    required List<DashboardBalanceEntityInsightSeed> categorySeeds,
    required List<DashboardBalanceEntityInsightSeed> partnerSeeds,
  }) {
    final scoped = List<DashboardLedgerEntry>.unmodifiable(
      scopedDirectionalEntries,
    );
    final categories = <String, _CategoryAccumulator>{
      for (final seed in categorySeeds) seed.id: _CategoryAccumulator(seed),
    };
    final partners = <String, _PartnerScopeAccumulator>{
      for (final seed in partnerSeeds) seed.id: _PartnerScopeAccumulator(seed),
    };
    final scopeAmount = scoped.fold<int>(
      0,
      (total, entry) => total + entry.amountMinor.abs(),
    );

    // Exactly one extra current-scope pass serves both Top-5 detail families.
    for (final entry in scoped) {
      categories[entry.categoryId]?.add(entry);
      partners[entry.partnerId]?.add(entry);
    }

    final relationships = <String, _PartnerRelationshipAccumulator>{
      for (final seed in partnerSeeds)
        seed.id: _PartnerRelationshipAccumulator(seed),
    };
    // The second, all-history pass is limited to the selected partner Top-5.
    for (final entry in fullDirectionalEntries) {
      relationships[entry.partnerId]?.add(entry);
    }

    return DashboardBalanceEntityInsights(
      categories: <String, DashboardBalanceCategoryInsight>{
        for (final entry in categories.entries)
          entry.key: entry.value.finish(
            timeScope: timeScope,
            scopeAmountMinor: scopeAmount,
            domainEntries: scoped,
          ),
      },
      partners: <String, DashboardBalancePartnerInsight>{
        for (final entry in partners.entries)
          entry.key: entry.value.finish(
            timeScope: timeScope,
            domainEntries: scoped,
            relationship: relationships[entry.key]!.finish(),
          ),
      },
    );
  }
}

final class _CategoryAccumulator {
  _CategoryAccumulator(this.seed);

  final DashboardBalanceEntityInsightSeed seed;
  var amountMinor = 0;
  final Set<int> activeDays = <int>{};
  final List<int> amounts = <int>[];
  final Map<int, int> temporalAmounts = <int, int>{};
  final _BoundedNewestOccurrences dayOccurrences = _BoundedNewestOccurrences(
    _categoryDayOccurrenceLimit,
  );
  var dayOccurrenceCount = 0;

  void add(DashboardLedgerEntry entry) {
    final amount = entry.amountMinor.abs();
    amountMinor += amount;
    activeDays.add(entry.bookedLocalEpochDay);
    amounts.add(amount);
    final date = _dateForEpochDay(entry.bookedLocalEpochDay);
    temporalAmounts.update(
      date.year * 10000 + date.month * 100 + date.day,
      (value) => value + amount,
      ifAbsent: () => amount,
    );
    dayOccurrenceCount += 1;
    dayOccurrences.add(_occurrenceFor(entry));
  }

  DashboardBalanceCategoryInsight finish({
    required LedgerTimeScope timeScope,
    required int scopeAmountMinor,
    required List<DashboardLedgerEntry> domainEntries,
  }) {
    final sorted = amounts..sort();
    final distribution = _distributionFor(sorted);
    final orderedDayOccurrences = dayOccurrences.oldestFirst();
    return DashboardBalanceCategoryInsight(
      id: seed.id,
      label: seed.label,
      direction: seed.direction,
      amountMinor: amountMinor,
      activeDirectionScopeAmountMinor: scopeAmountMinor,
      transactionCount: sorted.length,
      activeDayCount: activeDays.length,
      medianAmountTimesTwo: _medianTimesTwo(sorted),
      temporalBuckets: _temporalBuckets(
        timeScope: timeScope,
        domainEntries: domainEntries,
        values: temporalAmounts,
      ),
      distribution: distribution,
      minimumAmountMinor: sorted.first,
      maximumAmountMinor: sorted.last,
      dayOccurrences: orderedDayOccurrences,
      hiddenDayOccurrenceCount:
          dayOccurrenceCount - orderedDayOccurrences.length,
    );
  }
}

final class _PartnerScopeAccumulator {
  _PartnerScopeAccumulator(this.seed);

  final DashboardBalanceEntityInsightSeed seed;
  var amountMinor = 0;
  final Set<int> activeDays = <int>{};
  final Map<int, int> temporalCounts = <int, int>{};
  final _BoundedNewestOccurrences newest = _BoundedNewestOccurrences(
    _partnerRecentOccurrenceLimit,
  );

  void add(DashboardLedgerEntry entry) {
    amountMinor += entry.amountMinor.abs();
    activeDays.add(entry.bookedLocalEpochDay);
    final date = _dateForEpochDay(entry.bookedLocalEpochDay);
    final temporalKey = date.year * 10000 + date.month * 100 + date.day;
    temporalCounts.update(temporalKey, (value) => value + 1, ifAbsent: () => 1);
    newest.add(_occurrenceFor(entry));
  }

  DashboardBalancePartnerInsight finish({
    required LedgerTimeScope timeScope,
    required List<DashboardLedgerEntry> domainEntries,
    required DashboardBalancePartnerRelationship relationship,
  }) {
    final recent = newest.newestFirst();
    return DashboardBalancePartnerInsight(
      id: seed.id,
      label: seed.label,
      direction: seed.direction,
      amountMinor: amountMinor,
      transactionCount: recent.isEmpty
          ? 0
          : temporalCounts.values.fold(0, (a, b) => a + b),
      activeDayCount: activeDays.length,
      latestScopeOccurrence: recent.first,
      temporalBuckets: _temporalBuckets(
        timeScope: timeScope,
        domainEntries: domainEntries,
        values: temporalCounts,
      ),
      recentScopeOccurrences: recent,
      relationship: relationship,
    );
  }
}

final class _PartnerRelationshipAccumulator {
  _PartnerRelationshipAccumulator(this.seed);

  final DashboardBalanceEntityInsightSeed seed;
  final List<DashboardBalanceEntityOccurrence> occurrences =
      <DashboardBalanceEntityOccurrence>[];
  final List<int> amounts = <int>[];

  void add(DashboardLedgerEntry entry) {
    occurrences.add(_occurrenceFor(entry));
    amounts.add(entry.amountMinor.abs());
  }

  DashboardBalancePartnerRelationship finish() {
    occurrences.sort(_oldestFirst);
    amounts.sort();
    final cadenceMarkers = occurrences.length <= _partnerCadenceOccurrenceLimit
        ? occurrences
        : occurrences.sublist(
            occurrences.length - _partnerCadenceOccurrenceLimit,
          );
    int? cadenceTimesTwo;
    if (occurrences.length >= 3) {
      final gaps = <int>[
        for (var index = 1; index < occurrences.length; index += 1)
          _localMinute(occurrences[index]) -
              _localMinute(occurrences[index - 1]),
      ]..sort();
      cadenceTimesTwo = _medianTimesTwo(gaps);
    }
    return DashboardBalancePartnerRelationship(
      allHistoryTransactionCount: occurrences.length,
      firstOccurrence: occurrences.first,
      latestOccurrence: occurrences.last,
      medianAmountTimesTwo: _medianTimesTwo(amounts),
      firstQuartileAmountMinor: _nearestRank(amounts, .25),
      thirdQuartileAmountMinor: _nearestRank(amounts, .75),
      typicalCadenceMinutesTimesTwo: cadenceTimesTwo,
      cadenceOccurrences: cadenceMarkers,
    );
  }
}

final class _BoundedNewestOccurrences {
  _BoundedNewestOccurrences(this.limit);

  final int limit;
  final List<DashboardBalanceEntityOccurrence> _values =
      <DashboardBalanceEntityOccurrence>[];

  void add(DashboardBalanceEntityOccurrence occurrence) {
    _values.add(occurrence);
    _values.sort(_newestFirst);
    if (_values.length > limit) _values.removeLast();
  }

  List<DashboardBalanceEntityOccurrence> newestFirst() =>
      List<DashboardBalanceEntityOccurrence>.unmodifiable(_values);

  List<DashboardBalanceEntityOccurrence> oldestFirst() =>
      List<DashboardBalanceEntityOccurrence>.unmodifiable(
        _values.toList()..sort(_oldestFirst),
      );
}

List<DashboardBalanceEntityTemporalBucket> _temporalBuckets({
  required LedgerTimeScope timeScope,
  required List<DashboardLedgerEntry> domainEntries,
  required Map<int, int> values,
}) {
  switch (timeScope) {
    case AllTimeScope():
      if (domainEntries.isEmpty) {
        return const <DashboardBalanceEntityTemporalBucket>[];
      }
      final years = domainEntries
          .map((entry) => _dateForEpochDay(entry.bookedLocalEpochDay).year)
          .toList();
      final first = years.reduce(math.min);
      final last = years.reduce(math.max);
      return List<DashboardBalanceEntityTemporalBucket>.unmodifiable(
        <DashboardBalanceEntityTemporalBucket>[
          for (var year = first; year <= last; year += 1)
            DashboardBalanceEntityTemporalBucket(
              id: '$year',
              label: '$year',
              value: _valueForYear(values, year),
            ),
        ],
      );
    case YearScope(:final year):
      return List<DashboardBalanceEntityTemporalBucket>.unmodifiable(
        <DashboardBalanceEntityTemporalBucket>[
          for (var month = 1; month <= 12; month += 1)
            DashboardBalanceEntityTemporalBucket(
              id: '$year-$month',
              label: '$month.',
              value: _valueForMonth(values, year, month),
            ),
        ],
      );
    case MonthScope(:final value):
      final days = DateTime.utc(value.year, value.month + 1, 0).day;
      return List<DashboardBalanceEntityTemporalBucket>.unmodifiable(
        <DashboardBalanceEntityTemporalBucket>[
          for (var day = 1; day <= days; day += 1)
            DashboardBalanceEntityTemporalBucket(
              id: '${value.year}-${value.month}-$day',
              label: '$day.',
              value: values[value.year * 10000 + value.month * 100 + day] ?? 0,
            ),
        ],
      );
    case DayScope():
      return const <DashboardBalanceEntityTemporalBucket>[];
  }
}

int _valueForYear(Map<int, int> values, int year) => values.entries
    .where((entry) => entry.key ~/ 10000 == year)
    .fold(0, (sum, entry) => sum + entry.value);

int _valueForMonth(Map<int, int> values, int year, int month) => values.entries
    .where((entry) => entry.key ~/ 100 == year * 100 + month)
    .fold(0, (sum, entry) => sum + entry.value);

DashboardBalanceTransactionSizeDistribution _distributionFor(List<int> sorted) {
  var zeroToFive = 0;
  var fiveToTen = 0;
  var tenToTwenty = 0;
  var twentyPlus = 0;
  for (final amount in sorted) {
    if (amount < 5000 * _minorPerForint) {
      zeroToFive += 1;
    } else if (amount < 10000 * _minorPerForint) {
      fiveToTen += 1;
    } else if (amount < 20000 * _minorPerForint) {
      tenToTwenty += 1;
    } else {
      twentyPlus += 1;
    }
  }
  return DashboardBalanceTransactionSizeDistribution(
    zeroToFiveKCount: zeroToFive,
    fiveToTenKCount: fiveToTen,
    tenToTwentyKCount: tenToTwenty,
    twentyKPlusCount: twentyPlus,
  );
}

int _medianTimesTwo(List<int> sorted) {
  assert(sorted.isNotEmpty);
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle] * 2
      : sorted[middle - 1] + sorted[middle];
}

int _nearestRank(List<int> sorted, double percentile) {
  assert(sorted.isNotEmpty);
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

int _roundHalfUp(int timesTwo) => (timesTwo + 1) ~/ 2;

DashboardBalanceEntityOccurrence _occurrenceFor(DashboardLedgerEntry entry) =>
    DashboardBalanceEntityOccurrence(
      id: entry.id,
      epochDay: entry.bookedLocalEpochDay,
      localTimeMinutes: entry.bookedLocalTimeMinutes,
      amountMinor: entry.amountMinor.abs(),
      occurredOrder:
          entry.occurredAtUtcMs ??
          entry.bookedLocalEpochDay * _minutesPerDay +
              entry.bookedLocalTimeMinutes,
    );

int _localMinute(DashboardBalanceEntityOccurrence value) =>
    value.epochDay * _minutesPerDay + value.localTimeMinutes;

int _oldestFirst(
  DashboardBalanceEntityOccurrence left,
  DashboardBalanceEntityOccurrence right,
) {
  final local = _localMinute(left).compareTo(_localMinute(right));
  if (local != 0) return local;
  final occurrence = left.occurredOrder.compareTo(right.occurredOrder);
  return occurrence != 0 ? occurrence : left.id.compareTo(right.id);
}

int _newestFirst(
  DashboardBalanceEntityOccurrence left,
  DashboardBalanceEntityOccurrence right,
) => _oldestFirst(right, left);

DateTime _dateForEpochDay(int epochDay) =>
    DateTime.utc(1970).add(Duration(days: epochDay));
