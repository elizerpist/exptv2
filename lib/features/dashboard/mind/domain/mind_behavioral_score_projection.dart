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
  int chartSeriesBuildCount = 0;
  int maxChartSeriesPointCount = 0;
  int maxDayBucketsVisitedPerChartSeries = 0;

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

  /// Records chart-only prepared-index work separately from the immediate
  /// Header score preview metric. A chart is a semantic publication product,
  /// not a pointer-tick score calculation and must not weaken that bound.
  void finishChartSeries({
    required int pointCount,
    required int dayBucketsVisited,
  }) {
    chartSeriesBuildCount += 1;
    maxChartSeriesPointCount = math.max(maxChartSeriesPointCount, pointCount);
    maxDayBucketsVisitedPerChartSeries = math.max(
      maxDayBucketsVisitedPerChartSeries,
      dayBucketsVisited,
    );
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
    this.chartSeries,
  });

  final MindBehavioralScoreIdentity identity;
  final QueryAmountRangeValues range;
  final MindBehavioralScorePoint point;

  /// Header-only visual history prepared with the same immutable score frame.
  /// It remains nullable for lightweight isolated consumers that intentionally
  /// provide just one already-computed point.
  final MindBehavioralScoreChartSeries? chartSeries;
}

/// A compact, chronological visual sample of canonical daily Mind score
/// points. It deliberately contains points calculated by
/// [MindBehavioralScoreProjection.preview] semantics; the Header chart may
/// down-sample for pixels, but it never introduces chart-only finance math.
@immutable
final class MindBehavioralScoreChartSeries {
  MindBehavioralScoreChartSeries({
    required this.startInclusiveEpochDay,
    required this.endInclusiveEpochDay,
    required List<MindBehavioralScorePoint> points,
  }) : assert(startInclusiveEpochDay <= endInclusiveEpochDay),
       assert(
         points.isEmpty ||
             (points.first.epochDay >= startInclusiveEpochDay &&
                 points.last.epochDay <= endInclusiveEpochDay),
       ),
       points = List<MindBehavioralScorePoint>.unmodifiable(points);

  /// The fixed visual-point budget mirrors the reference's dense-but-minimal
  /// line. Header paint consumes this immutable value and never queries score
  /// history itself.
  static const int maximumVisualPoints = 56;

  final int startInclusiveEpochDay;
  final int endInclusiveEpochDay;
  final List<MindBehavioralScorePoint> points;

  @override
  bool operator ==(Object other) =>
      other is MindBehavioralScoreChartSeries &&
      other.startInclusiveEpochDay == startInclusiveEpochDay &&
      other.endInclusiveEpochDay == endInclusiveEpochDay &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(
    startInclusiveEpochDay,
    endInclusiveEpochDay,
    Object.hashAll(points),
  );
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
    final point = _pointFor(
      range: range,
      targetEpochDay: targetEpochDay,
      onDayBucketVisited: () => visited += 1,
    );
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

  /// Returns a visually bounded chronological history over the requested
  /// already-selected scope. Every emitted sample is an exact canonical daily
  /// score point, including the inclusive amount range; only pixel sampling
  /// is bounded. Header paint never calls this method.
  MindBehavioralScoreChartSeries chartSeries({
    required QueryAmountRangeValues range,
    required int startInclusiveEpochDay,
    required int endInclusiveEpochDay,
    int maximumPoints = MindBehavioralScoreChartSeries.maximumVisualPoints,
  }) {
    if (startInclusiveEpochDay > endInclusiveEpochDay) {
      throw ArgumentError.value(
        endInclusiveEpochDay,
        'endInclusiveEpochDay',
        'must not precede startInclusiveEpochDay',
      );
    }
    if (maximumPoints <= 0) {
      throw ArgumentError.value(
        maximumPoints,
        'maximumPoints',
        'must be positive',
      );
    }
    final sampleDays = _sampleEpochDays(
      startInclusiveEpochDay: startInclusiveEpochDay,
      endInclusiveEpochDay: endInclusiveEpochDay,
      maximumPoints: maximumPoints,
    );
    var visited = 0;
    final points = switch (identity.direction) {
      LedgerDirection.expense => <MindBehavioralScorePoint>[
        for (final epochDay in sampleDays)
          _pointFor(
            range: range,
            targetEpochDay: epochDay,
            onDayBucketVisited: () => visited += 1,
          ),
      ],
      LedgerDirection.income => _incomeChartPoints(
        range: range,
        sampleDays: sampleDays,
        onDayBucketVisited: () => visited += 1,
      ),
    };
    _sourceWorkCounter.finishChartSeries(
      pointCount: points.length,
      dayBucketsVisited: visited,
    );
    return MindBehavioralScoreChartSeries(
      startInclusiveEpochDay: startInclusiveEpochDay,
      endInclusiveEpochDay: endInclusiveEpochDay,
      points: points,
    );
  }

  MindBehavioralScorePoint _pointFor({
    required QueryAmountRangeValues range,
    required int targetEpochDay,
    required VoidCallback onDayBucketVisited,
  }) {
    int amountAt(int epochDay) {
      onDayBucketVisited();
      return _dayRanges[epochDay]?.sumWithin(
            minimum: range.lowerScaled100,
            maximum: range.upperScaled100,
          ) ??
          0;
    }

    return switch (identity.direction) {
      LedgerDirection.expense => _expensePoint(
        targetEpochDay: targetEpochDay,
        amountAt: amountAt,
      ),
      LedgerDirection.income => _incomePoint(
        targetEpochDay: targetEpochDay,
        amountAt: amountAt,
        onDayKeyVisited: onDayBucketVisited,
      ),
    };
  }

  /// Resolves all sampled Income points in chronological order. The generic
  /// point resolver intentionally calculates a single point and therefore
  /// walks its prior meaningful days. A chart must not repeat that history
  /// walk for every pixel sample: this one resident-index pass carries the
  /// last-three and running-median context forward while preserving the
  /// precise single-point formula.
  List<MindBehavioralScorePoint> _incomeChartPoints({
    required QueryAmountRangeValues range,
    required List<int> sampleDays,
    required VoidCallback onDayBucketVisited,
  }) {
    final points = <MindBehavioralScorePoint>[];
    final median = _MindScoreRunningMedian();
    final recentPrevious = <int>[];
    var recentPreviousSum = 0;
    var dayKeyIndex = 0;

    int eligibleAmountAtKey(int epochDay) {
      onDayBucketVisited();
      return _dayRanges[epochDay]?.sumWithin(
            minimum: range.lowerScaled100,
            maximum: range.upperScaled100,
          ) ??
          0;
    }

    void appendRecentPrevious(int amount) {
      recentPrevious.add(amount);
      recentPreviousSum += amount;
      if (recentPrevious.length > 3) {
        recentPreviousSum -= recentPrevious.removeAt(0);
      }
    }

    void appendMeaningfulPrevious(int amount) {
      median.add(amount);
      appendRecentPrevious(amount);
    }

    for (final targetEpochDay in sampleDays) {
      while (dayKeyIndex < _dayKeys.length &&
          _dayKeys[dayKeyIndex] < targetEpochDay) {
        final amount = eligibleAmountAtKey(_dayKeys[dayKeyIndex]);
        if (amount > 0) appendMeaningfulPrevious(amount);
        dayKeyIndex += 1;
      }

      var current = 0;
      if (dayKeyIndex < _dayKeys.length &&
          _dayKeys[dayKeyIndex] == targetEpochDay) {
        current = eligibleAmountAtKey(_dayKeys[dayKeyIndex]);
        dayKeyIndex += 1;
      }

      final priorCount = median.count;
      final priorAverage = recentPrevious.isEmpty
          ? 0.0
          : recentPreviousSum / recentPrevious.length;
      if (current > 0) median.add(current);
      final medianWithCurrent = current > 0 ? median.median : 0.0;
      points.add(
        _incomePointFromHistory(
          targetEpochDay: targetEpochDay,
          current: current,
          priorCount: priorCount,
          previousAverage: priorAverage,
          medianWithCurrent: medianWithCurrent,
        ),
      );
      if (current > 0) appendRecentPrevious(current);
    }
    return points;
  }

  static List<int> _sampleEpochDays({
    required int startInclusiveEpochDay,
    required int endInclusiveEpochDay,
    required int maximumPoints,
  }) {
    final span = endInclusiveEpochDay - startInclusiveEpochDay;
    final availableDayCount = span + 1;
    final pointCount = math.min(availableDayCount, maximumPoints);
    if (pointCount == 1) return <int>[endInclusiveEpochDay];
    return List<int>.generate(
      pointCount,
      (index) => startInclusiveEpochDay + (span * index ~/ (pointCount - 1)),
      growable: false,
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

  /// The earliest range-eligible daily contribution in an already-resolved
  /// visual scope. All-Time chart bounds use this resident lookup rather than
  /// inventing an arbitrary calendar origin.
  int firstEligibleEpochDay({
    required QueryAmountRangeValues range,
    required int startInclusiveEpochDay,
    required int endInclusiveEpochDay,
    required int fallbackEpochDay,
  }) {
    final startIndex = _lowerBound(_dayKeys, startInclusiveEpochDay);
    final endIndex = _upperBound(_dayKeys, endInclusiveEpochDay);
    for (var index = startIndex; index < endIndex; index += 1) {
      final day = _dayKeys[index];
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
      return _incomePointFromHistory(
        targetEpochDay: targetEpochDay,
        current: current,
        priorCount: previous.length,
        previousAverage: 0,
        medianWithCurrent: 0,
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
    return _incomePointFromHistory(
      targetEpochDay: targetEpochDay,
      current: current,
      priorCount: previous.length,
      previousAverage: average,
      medianWithCurrent: median,
    );
  }

  MindBehavioralScorePoint _incomePointFromHistory({
    required int targetEpochDay,
    required int current,
    required int priorCount,
    required double previousAverage,
    required double medianWithCurrent,
  }) {
    if (current <= 0 || priorCount == 0) {
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
    final baseline = math
        .max(1, math.max(previousAverage, medianWithCurrent))
        .toDouble();
    final trendDelta = (current - previousAverage) / baseline;
    final adjustment = (trendDelta * 35).clamp(-30.0, 30.0).toDouble();
    return MindBehavioralScorePoint(
      epochDay: targetEpochDay,
      score: _clamp100(50 + adjustment),
      noSignal: false,
      income: MindIncomeScoreComponents(
        currentAmount: current,
        previousAverage: previousAverage,
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

/// Incremental exact median for the already range-filtered Income daily
/// amounts. It is intentionally tiny and local to the resident score index:
/// no collection package, source-row access, or chart rendering state leaks
/// into the score model.
final class _MindScoreRunningMedian {
  final List<int> _lowerMaxHeap = <int>[];
  final List<int> _upperMinHeap = <int>[];

  int get count => _lowerMaxHeap.length + _upperMinHeap.length;

  void add(int value) {
    if (_lowerMaxHeap.isEmpty || value <= _lowerMaxHeap.first) {
      _pushMax(value);
    } else {
      _pushMin(value);
    }
    if (_lowerMaxHeap.length > _upperMinHeap.length + 1) {
      _pushMin(_popMax());
    } else if (_upperMinHeap.length > _lowerMaxHeap.length) {
      _pushMax(_popMin());
    }
  }

  double get median {
    assert(count > 0);
    if (_lowerMaxHeap.length == _upperMinHeap.length) {
      return (_lowerMaxHeap.first + _upperMinHeap.first) / 2;
    }
    return _lowerMaxHeap.first.toDouble();
  }

  void _pushMax(int value) {
    _lowerMaxHeap.add(value);
    var index = _lowerMaxHeap.length - 1;
    while (index > 0) {
      final parent = (index - 1) >> 1;
      if (_lowerMaxHeap[parent] >= _lowerMaxHeap[index]) break;
      _swap(_lowerMaxHeap, parent, index);
      index = parent;
    }
  }

  int _popMax() {
    final value = _lowerMaxHeap.first;
    _removeMaxAt(0);
    return value;
  }

  void _removeMaxAt(int index) {
    final last = _lowerMaxHeap.removeLast();
    if (index == _lowerMaxHeap.length) return;
    _lowerMaxHeap[index] = last;
    _siftMax(index);
  }

  void _siftMax(int index) {
    while (true) {
      final left = index * 2 + 1;
      final right = left + 1;
      var candidate = index;
      if (left < _lowerMaxHeap.length &&
          _lowerMaxHeap[left] > _lowerMaxHeap[candidate]) {
        candidate = left;
      }
      if (right < _lowerMaxHeap.length &&
          _lowerMaxHeap[right] > _lowerMaxHeap[candidate]) {
        candidate = right;
      }
      if (candidate == index) return;
      _swap(_lowerMaxHeap, candidate, index);
      index = candidate;
    }
  }

  void _pushMin(int value) {
    _upperMinHeap.add(value);
    var index = _upperMinHeap.length - 1;
    while (index > 0) {
      final parent = (index - 1) >> 1;
      if (_upperMinHeap[parent] <= _upperMinHeap[index]) break;
      _swap(_upperMinHeap, parent, index);
      index = parent;
    }
  }

  int _popMin() {
    final value = _upperMinHeap.first;
    _removeMinAt(0);
    return value;
  }

  void _removeMinAt(int index) {
    final last = _upperMinHeap.removeLast();
    if (index == _upperMinHeap.length) return;
    _upperMinHeap[index] = last;
    _siftMin(index);
  }

  void _siftMin(int index) {
    while (true) {
      final left = index * 2 + 1;
      final right = left + 1;
      var candidate = index;
      if (left < _upperMinHeap.length &&
          _upperMinHeap[left] < _upperMinHeap[candidate]) {
        candidate = left;
      }
      if (right < _upperMinHeap.length &&
          _upperMinHeap[right] < _upperMinHeap[candidate]) {
        candidate = right;
      }
      if (candidate == index) return;
      _swap(_upperMinHeap, candidate, index);
      index = candidate;
    }
  }

  static void _swap(List<int> values, int left, int right) {
    final value = values[left];
    values[left] = values[right];
    values[right] = value;
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
