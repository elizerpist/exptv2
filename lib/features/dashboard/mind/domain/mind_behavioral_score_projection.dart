import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../query/domain/ledger_direction.dart';
import '../../query/domain/query_amount_range.dart';

/// Immutable provenance of a prepared Mind behavioural-score universe.
///
/// The amount range deliberately is not part of this identity: the existing
/// canonical [QueryAmountRange] may be previewed from the resident daily
/// indexes without rebuilding their source membership.
@immutable
final class MindBehavioralScoreIdentity {
  const MindBehavioralScoreIdentity({
    required this.upstreamScopeKey,
    required this.indexGeneration,
    required this.coreRevision,
    required this.direction,
  });

  final String upstreamScopeKey;
  final int indexGeneration;
  final int coreRevision;
  final LedgerDirection direction;

  @override
  bool operator ==(Object other) =>
      other is MindBehavioralScoreIdentity &&
      other.upstreamScopeKey == upstreamScopeKey &&
      other.indexGeneration == indexGeneration &&
      other.coreRevision == coreRevision &&
      other.direction == direction;

  @override
  int get hashCode =>
      Object.hash(upstreamScopeKey, indexGeneration, coreRevision, direction);
}

/// Compact transaction contribution copied from an already prepared Mind
/// membership. This is semantic transport, never a rendered LogBox row.
@immutable
final class MindBehavioralScoreContribution {
  const MindBehavioralScoreContribution({
    required this.bookedLocalEpochDay,
    required this.amountMinor,
  });

  final int bookedLocalEpochDay;
  final int amountMinor;
}

/// Bounded evidence for the score projection. Production callers can leave
/// timings disabled; tests/profile harnesses can opt into a fixed ring.
final class MindBehavioralScoreSourceWorkCounter {
  MindBehavioralScoreSourceWorkCounter({
    this.measurePreviewDurations = false,
    this.previewDurationCapacity = 64,
  }) : _previewMicros = List<int>.filled(
         previewDurationCapacity,
         0,
         growable: false,
       ) {
    if (previewDurationCapacity <= 0) {
      throw ArgumentError.value(
        previewDurationCapacity,
        'previewDurationCapacity',
      );
    }
  }

  final bool measurePreviewDurations;
  final int previewDurationCapacity;
  final List<int> _previewMicros;
  int _previewCount = 0;
  int _previewNext = 0;

  int sourceRowTouches = 0;
  int preparedContributionTouches = 0;
  int sourceRowTouchesDuringPreview = 0;
  int repositoryAccessesDuringPreview = 0;
  int indexBuildsDuringPreview = 0;
  int maxDayBucketsVisitedPerPreview = 0;

  void recordPreparedContributionTouch() => preparedContributionTouches += 1;

  void finishPreview({required int dayBucketsVisited, int micros = 0}) {
    maxDayBucketsVisitedPerPreview = math.max(
      maxDayBucketsVisitedPerPreview,
      dayBucketsVisited,
    );
    if (!measurePreviewDurations) return;
    _previewMicros[_previewNext] = micros;
    _previewNext = (_previewNext + 1) % previewDurationCapacity;
    if (_previewCount < previewDurationCapacity) _previewCount += 1;
  }

  Map<String, int> previewDurationSummary() {
    if (_previewCount == 0) {
      return const <String, int>{
        'sampleCount': 0,
        'p50Micros': 0,
        'p95Micros': 0,
        'maxMicros': 0,
      };
    }
    final values = List<int>.generate(
      _previewCount,
      (index) => _previewMicros[index],
      growable: false,
    )..sort();
    int percentile(double ratio) =>
        values[((values.length - 1) * ratio)
            .ceil()
            .clamp(0, values.length - 1)
            .toInt()];
    return <String, int>{
      'sampleCount': values.length,
      'p50Micros': percentile(.5),
      'p95Micros': percentile(.95),
      'maxMicros': values.last,
    };
  }
}

@immutable
final class MindBehavioralScoreFrame {
  const MindBehavioralScoreFrame({
    required this.identity,
    required this.range,
    required this.point,
  });

  final MindBehavioralScoreIdentity identity;
  final QueryAmountRangeValues range;
  final MindBehavioralScorePoint point;
}

/// One canonical daily point. A future graph consumes these exact values
/// through [MindBehavioralScoreProjection.preview]; it must not redefine the
/// calculation for Month, Year or Sum presentation.
@immutable
final class MindBehavioralScorePoint {
  const MindBehavioralScorePoint({
    required this.epochDay,
    required this.score,
    required this.noSignal,
    this.expense,
    this.income,
  }) : assert(score >= 0 && score <= 100),
       assert(expense == null || income == null);

  final int epochDay;
  final double score;
  final bool noSignal;
  final MindExpenseScoreComponents? expense;
  final MindIncomeScoreComponents? income;

  int get roundedScore => score.round().clamp(0, 100);

  @override
  bool operator ==(Object other) =>
      other is MindBehavioralScorePoint &&
      other.epochDay == epochDay &&
      other.score == score &&
      other.noSignal == noSignal &&
      other.expense == expense &&
      other.income == income;

  @override
  int get hashCode => Object.hash(epochDay, score, noSignal, expense, income);
}

@immutable
final class MindExpenseScoreComponents {
  const MindExpenseScoreComponents({
    required this.activeDaysInContext,
    required this.dailyAmount,
    required this.amountMaximum,
    required this.isSparse,
    required this.emaPeriod,
    required this.rollingOccurrence,
    required this.rollingAmount,
    required this.smoothedOccurrence,
    required this.smoothedAmount,
    required this.occurrenceIndex,
    required this.amountIndex,
    required this.pressure,
  });

  final int activeDaysInContext;
  final int dailyAmount;
  final int amountMaximum;
  final bool isSparse;
  final int? emaPeriod;
  final int rollingOccurrence;
  final int rollingAmount;
  final double smoothedOccurrence;
  final double smoothedAmount;
  final double occurrenceIndex;
  final double amountIndex;
  final double pressure;

  @override
  bool operator ==(Object other) =>
      other is MindExpenseScoreComponents &&
      other.activeDaysInContext == activeDaysInContext &&
      other.dailyAmount == dailyAmount &&
      other.amountMaximum == amountMaximum &&
      other.isSparse == isSparse &&
      other.emaPeriod == emaPeriod &&
      other.rollingOccurrence == rollingOccurrence &&
      other.rollingAmount == rollingAmount &&
      other.smoothedOccurrence == smoothedOccurrence &&
      other.smoothedAmount == smoothedAmount &&
      other.occurrenceIndex == occurrenceIndex &&
      other.amountIndex == amountIndex &&
      other.pressure == pressure;

  @override
  int get hashCode => Object.hash(
    activeDaysInContext,
    dailyAmount,
    amountMaximum,
    isSparse,
    emaPeriod,
    rollingOccurrence,
    rollingAmount,
    smoothedOccurrence,
    smoothedAmount,
    occurrenceIndex,
    amountIndex,
    pressure,
  );
}

@immutable
final class MindIncomeScoreComponents {
  const MindIncomeScoreComponents({
    required this.currentAmount,
    required this.previousAverage,
    required this.baseline,
    required this.trendDelta,
    required this.trendAdjustment,
  });

  final int currentAmount;
  final double previousAverage;
  final double baseline;
  final double trendDelta;
  final double trendAdjustment;

  @override
  bool operator ==(Object other) =>
      other is MindIncomeScoreComponents &&
      other.currentAmount == currentAmount &&
      other.previousAverage == previousAverage &&
      other.baseline == baseline &&
      other.trendDelta == trendDelta &&
      other.trendAdjustment == trendAdjustment;

  @override
  int get hashCode => Object.hash(
    currentAmount,
    previousAverage,
    baseline,
    trendDelta,
    trendAdjustment,
  );
}

/// Immutable, resident daily range projection for Mind behaviour.
///
/// Every day stores amount-sorted values plus prefix sums. Range preview is
/// therefore a fixed daily-index calculation, never a ledger-row/repository
/// read. Expense evaluates its target from at most 61 daily buckets: 31
/// output samples, each with its own causal 31-day rolling signal.
///
/// Dense Expense normalization is deliberately causal: each smoothed signal
/// divides by the running maximum observed at or before that sample, inside
/// the target's 31-sample causal evaluation strip. This replaces the HTML
/// prototype's whole-visible-series maxima, so a future row or a wider UI
/// TimePlane cannot rewrite an earlier point. It introduces no fixed HUF
/// good/bad threshold.
@immutable
final class MindBehavioralScoreProjection {
  const MindBehavioralScoreProjection._(
    this.identity,
    this._dayRanges,
    this._dayKeys,
    this._sourceWorkCounter,
  );

  factory MindBehavioralScoreProjection.build({
    required MindBehavioralScoreIdentity identity,
    required Iterable<MindBehavioralScoreContribution> contributions,
    MindBehavioralScoreSourceWorkCounter? sourceWorkCounter,
  }) {
    final counter = sourceWorkCounter ?? MindBehavioralScoreSourceWorkCounter();
    final mutable = <int, List<int>>{};
    for (final contribution in contributions) {
      counter.recordPreparedContributionTouch();
      mutable
          .putIfAbsent(contribution.bookedLocalEpochDay, () => <int>[])
          .add(contribution.amountMinor);
    }
    final ranges = <int, _MindScoreDayRange>{
      for (final entry in mutable.entries)
        entry.key: _MindScoreDayRange.fromUnsorted(entry.value),
    };
    final keys = ranges.keys.toList(growable: false)..sort();
    return MindBehavioralScoreProjection._(
      identity,
      Map<int, _MindScoreDayRange>.unmodifiable(ranges),
      List<int>.unmodifiable(keys),
      counter,
    );
  }

  static const int _behaviorWindowDays = 31;

  final MindBehavioralScoreIdentity identity;
  final Map<int, _MindScoreDayRange> _dayRanges;
  final List<int> _dayKeys;
  final MindBehavioralScoreSourceWorkCounter _sourceWorkCounter;

  MindBehavioralScoreSourceWorkCounter get sourceWorkCounter =>
      _sourceWorkCounter;

  MindBehavioralScoreFrame preview({
    required QueryAmountRangeValues range,
    required int targetEpochDay,
  }) {
    final watch = _sourceWorkCounter.measurePreviewDurations
        ? (Stopwatch()..start())
        : null;
    var visited = 0;
    int amountAt(int epochDay) {
      visited += 1;
      return _dayRanges[epochDay]?.sumWithin(
            minimum: range.lowerScaled100,
            maximum: range.upperScaled100,
          ) ??
          0;
    }

    final point = switch (identity.direction) {
      LedgerDirection.expense => _expensePoint(
        targetEpochDay: targetEpochDay,
        amountAt: amountAt,
      ),
      LedgerDirection.income => _incomePoint(
        targetEpochDay: targetEpochDay,
        amountAt: amountAt,
        onDayKeyVisited: () => visited += 1,
      ),
    };
    watch?.stop();
    _sourceWorkCounter.finishPreview(
      dayBucketsVisited: visited,
      micros: watch?.elapsedMicroseconds ?? 0,
    );
    return MindBehavioralScoreFrame(
      identity: identity,
      range: range,
      point: point,
    );
  }

  /// Resolves the latest qualifying day inside a UI-selected scope without
  /// changing point mathematics. The caller may use its selected day as the
  /// fallback when a Month/Year/Sum contains no eligible activity.
  int latestEligibleEpochDay({
    required QueryAmountRangeValues range,
    required int startInclusiveEpochDay,
    required int endInclusiveEpochDay,
    required int fallbackEpochDay,
  }) {
    for (
      var index = _upperBound(_dayKeys, endInclusiveEpochDay) - 1;
      index >= 0;
      index -= 1
    ) {
      final day = _dayKeys[index];
      if (day < startInclusiveEpochDay) break;
      if ((_dayRanges[day]?.sumWithin(
                minimum: range.lowerScaled100,
                maximum: range.upperScaled100,
              ) ??
              0) >
          0) {
        return day;
      }
    }
    return fallbackEpochDay;
  }

  MindBehavioralScorePoint _expensePoint({
    required int targetEpochDay,
    required int Function(int epochDay) amountAt,
  }) {
    final contextStart = targetEpochDay - (_behaviorWindowDays - 1);
    final contextAmounts = List<int>.generate(
      _behaviorWindowDays,
      (index) => amountAt(contextStart + index),
      growable: false,
    );
    final activeDays = contextAmounts.where((amount) => amount > 0).length;
    final dailyAmount = contextAmounts.last;
    final amountMaximum = contextAmounts.fold<int>(
      0,
      (maximum, amount) => math.max(maximum, amount),
    );
    if (activeDays <= 12) {
      final amountIndex = amountMaximum == 0
          ? 0.0
          : _clamp100(dailyAmount / amountMaximum * 100);
      final score = _clamp100(100 - amountIndex);
      return MindBehavioralScorePoint(
        epochDay: targetEpochDay,
        score: score,
        noSignal: false,
        expense: MindExpenseScoreComponents(
          activeDaysInContext: activeDays,
          dailyAmount: dailyAmount,
          amountMaximum: amountMaximum,
          isSparse: true,
          emaPeriod: null,
          rollingOccurrence: activeDays,
          rollingAmount: contextAmounts.fold<int>(
            0,
            (sum, value) => sum + value,
          ),
          smoothedOccurrence: activeDays.toDouble(),
          smoothedAmount: dailyAmount.toDouble(),
          occurrenceIndex: 0,
          amountIndex: amountIndex,
          pressure: amountIndex,
        ),
      );
    }

    // Each sample is a trailing 31-day signal. The sample strip ends at the
    // target and has no future read; its first sample needs the preceding 30
    // daily buckets, keeping the entire dense calculation bounded to 61 days.
    final signalStart = contextStart;
    final sourceStart = signalStart - (_behaviorWindowDays - 1);
    // The tail of this 61-day source strip is exactly [contextAmounts]. Reuse
    // it instead of asking the resident range index for those same 31 days a
    // second time; dense preview therefore touches at most 61 daily buckets.
    final sourceAmounts = List<int>.generate(
      _behaviorWindowDays * 2 - 1,
      (index) => index < _behaviorWindowDays - 1
          ? amountAt(sourceStart + index)
          : contextAmounts[index - (_behaviorWindowDays - 1)],
      growable: false,
    );
    final prefixAmounts = List<int>.filled(sourceAmounts.length + 1, 0);
    final prefixOccurrences = List<int>.filled(sourceAmounts.length + 1, 0);
    for (var index = 0; index < sourceAmounts.length; index += 1) {
      prefixAmounts[index + 1] = prefixAmounts[index] + sourceAmounts[index];
      prefixOccurrences[index + 1] =
          prefixOccurrences[index] + (sourceAmounts[index] > 0 ? 1 : 0);
    }
    final occurrenceSignals = List<int>.generate(_behaviorWindowDays, (index) {
      final end = index + _behaviorWindowDays;
      return prefixOccurrences[end] - prefixOccurrences[index];
    }, growable: false);
    final amountSignals = List<int>.generate(_behaviorWindowDays, (index) {
      final end = index + _behaviorWindowDays;
      return prefixAmounts[end] - prefixAmounts[index];
    }, growable: false);
    final period = dynamicExpenseEmaPeriod(activeDays);
    final alpha = 2 / (period + 1);
    final smoothedOccurrences = _ema(occurrenceSignals, alpha);
    final smoothedAmounts = _ema(amountSignals, alpha);
    var occurrenceReference = 1.0;
    var amountReference = 1.0;
    var occurrenceIndex = 0.0;
    var amountIndex = 0.0;
    for (var index = 0; index < _behaviorWindowDays; index += 1) {
      occurrenceReference = math.max(
        occurrenceReference,
        smoothedOccurrences[index],
      );
      amountReference = math.max(amountReference, smoothedAmounts[index]);
      if (index == _behaviorWindowDays - 1) {
        occurrenceIndex = _clamp100(
          smoothedOccurrences[index] / occurrenceReference * 100,
        );
        amountIndex = _clamp100(smoothedAmounts[index] / amountReference * 100);
      }
    }
    final pressure = _clamp100(.5 * occurrenceIndex + .5 * amountIndex);
    return MindBehavioralScorePoint(
      epochDay: targetEpochDay,
      score: _clamp100(100 - pressure),
      noSignal: false,
      expense: MindExpenseScoreComponents(
        activeDaysInContext: activeDays,
        dailyAmount: dailyAmount,
        amountMaximum: amountMaximum,
        isSparse: false,
        emaPeriod: period,
        rollingOccurrence: occurrenceSignals.last,
        rollingAmount: amountSignals.last,
        smoothedOccurrence: smoothedOccurrences.last,
        smoothedAmount: smoothedAmounts.last,
        occurrenceIndex: occurrenceIndex,
        amountIndex: amountIndex,
        pressure: pressure,
      ),
    );
  }

  MindBehavioralScorePoint _incomePoint({
    required int targetEpochDay,
    required int Function(int epochDay) amountAt,
    required VoidCallback onDayKeyVisited,
  }) {
    final current = amountAt(targetEpochDay);
    final previous = <int>[];
    for (
      var index = 0;
      index < _lowerBound(_dayKeys, targetEpochDay);
      index += 1
    ) {
      onDayKeyVisited();
      final amount = amountAt(_dayKeys[index]);
      if (amount > 0) previous.add(amount);
    }
    if (current <= 0 || previous.isEmpty) {
      return MindBehavioralScorePoint(
        epochDay: targetEpochDay,
        score: 50,
        noSignal: true,
        income: MindIncomeScoreComponents(
          currentAmount: current,
          previousAverage: 0,
          baseline: 0,
          trendDelta: 0,
          trendAdjustment: 0,
        ),
      );
    }
    final start = math.max(0, previous.length - 3);
    final recentPrevious = previous.sublist(start);
    final average =
        recentPrevious.fold<int>(0, (sum, value) => sum + value) /
        recentPrevious.length;
    final medianSource = <int>[...previous, current]..sort();
    final median = medianSource.length.isOdd
        ? medianSource[medianSource.length ~/ 2].toDouble()
        : (medianSource[medianSource.length ~/ 2 - 1] +
                  medianSource[medianSource.length ~/ 2]) /
              2;
    final baseline = math.max(1, math.max(average, median)).toDouble();
    final trendDelta = (current - average) / baseline;
    final adjustment = (trendDelta * 35).clamp(-30.0, 30.0).toDouble();
    return MindBehavioralScorePoint(
      epochDay: targetEpochDay,
      score: _clamp100(50 + adjustment),
      noSignal: false,
      income: MindIncomeScoreComponents(
        currentAmount: current,
        previousAverage: average,
        baseline: baseline,
        trendDelta: trendDelta,
        trendAdjustment: adjustment,
      ),
    );
  }

  static int dynamicExpenseEmaPeriod(int activeScopeDays) =>
      (22 - .45 * activeScopeDays).round().clamp(7, 18).toInt();

  static List<double> _ema(List<int> values, double alpha) {
    if (values.isEmpty) return const <double>[];
    final result = List<double>.filled(values.length, 0, growable: false);
    result[0] = values.first.toDouble();
    for (var index = 1; index < values.length; index += 1) {
      result[index] =
          result[index - 1] + alpha * (values[index] - result[index - 1]);
    }
    return result;
  }

  static double _clamp100(num value) => value.clamp(0.0, 100.0).toDouble();

  static int _lowerBound(List<int> values, int value) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (values[middle] < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  static int _upperBound(List<int> values, int value) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (values[middle] <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

@immutable
final class _MindScoreDayRange {
  const _MindScoreDayRange._(this._values, this._prefixSums);

  factory _MindScoreDayRange.fromUnsorted(List<int> values) {
    final sorted = List<int>.of(values)..sort();
    final prefix = List<int>.filled(sorted.length + 1, 0, growable: false);
    for (var index = 0; index < sorted.length; index += 1) {
      prefix[index + 1] = prefix[index] + sorted[index];
    }
    return _MindScoreDayRange._(
      List<int>.unmodifiable(sorted),
      List<int>.unmodifiable(prefix),
    );
  }

  final List<int> _values;
  final List<int> _prefixSums;

  int? sumWithin({required int minimum, required int maximum}) {
    if (_values.isEmpty || minimum > maximum) return null;
    final start = MindBehavioralScoreProjection._lowerBound(_values, minimum);
    final end = MindBehavioralScoreProjection._upperBound(_values, maximum);
    return start == end ? null : _prefixSums[end] - _prefixSums[start];
  }
}
