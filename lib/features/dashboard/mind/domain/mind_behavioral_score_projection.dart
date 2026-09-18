import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../query/domain/ledger_direction.dart';
import '../../query/domain/query_amount_range.dart';
import 'mind_behavioral_score_settings.dart';

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
    this.settings = const MindBehavioralScoreSettings.defaults(),
  });

  final String upstreamScopeKey;
  final int indexGeneration;
  final int coreRevision;
  final LedgerDirection direction;
  final MindBehavioralScoreSettings settings;

  @override
  bool operator ==(Object other) =>
      other is MindBehavioralScoreIdentity &&
      other.upstreamScopeKey == upstreamScopeKey &&
      other.indexGeneration == indexGeneration &&
      other.coreRevision == coreRevision &&
      other.direction == direction &&
      other.settings == settings;

  @override
  int get hashCode => Object.hash(
    upstreamScopeKey,
    indexGeneration,
    coreRevision,
    direction,
    settings,
  );
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
    this.seriesRequest,
  });

  final MindBehavioralScoreIdentity identity;
  final QueryAmountRangeValues range;
  final MindBehavioralScorePoint point;

  /// Header-only visual history prepared with the same immutable score frame.
  /// It remains nullable for lightweight isolated consumers that intentionally
  /// provide just one already-computed point.
  final MindBehavioralScoreChartSeries? chartSeries;

  /// Immutable evaluation provenance shared by the Header text/chart output.
  /// The live publication lane adds its navigation generation separately;
  /// together they reject stale scope/settings completions deterministically.
  final MindBehavioralScoreSeriesRequest? seriesRequest;
}

/// One immutable request for the score series that serves both Header text
/// and its chart. [analyticEndInclusiveEpochDay] may be later than [target]
/// for an HTML mode because its approved whole-scope definition intentionally
/// reads the selected scope's future values. Causal callers pass a target-end
/// scope so past points never receive a future input.
@immutable
final class MindBehavioralScoreSeriesRequest {
  const MindBehavioralScoreSeriesRequest({
    required this.analyticStartInclusiveEpochDay,
    required this.analyticEndInclusiveEpochDay,
    required this.chartStartInclusiveEpochDay,
    required this.targetEpochDay,
    this.pointAnalyticStartInclusiveEpochDay,
  }) : assert(analyticStartInclusiveEpochDay <= analyticEndInclusiveEpochDay),
       assert(chartStartInclusiveEpochDay <= targetEpochDay),
       assert(targetEpochDay >= analyticStartInclusiveEpochDay),
       assert(targetEpochDay <= analyticEndInclusiveEpochDay),
       assert(
         pointAnalyticStartInclusiveEpochDay == null ||
             pointAnalyticStartInclusiveEpochDay <= targetEpochDay,
       );

  final int analyticStartInclusiveEpochDay;
  final int analyticEndInclusiveEpochDay;
  final int chartStartInclusiveEpochDay;
  final int targetEpochDay;

  /// A Day chart may show 31 days while retaining the point semantics that
  /// the canonical single-day request already approved.  Other scopes leave
  /// this null and therefore evaluate their point from [analyticStart].
  final int? pointAnalyticStartInclusiveEpochDay;

  @override
  bool operator ==(Object other) =>
      other is MindBehavioralScoreSeriesRequest &&
      other.analyticStartInclusiveEpochDay == analyticStartInclusiveEpochDay &&
      other.analyticEndInclusiveEpochDay == analyticEndInclusiveEpochDay &&
      other.chartStartInclusiveEpochDay == chartStartInclusiveEpochDay &&
      other.targetEpochDay == targetEpochDay &&
      other.pointAnalyticStartInclusiveEpochDay ==
          pointAnalyticStartInclusiveEpochDay;

  @override
  int get hashCode => Object.hash(
    analyticStartInclusiveEpochDay,
    analyticEndInclusiveEpochDay,
    chartStartInclusiveEpochDay,
    targetEpochDay,
    pointAnalyticStartInclusiveEpochDay,
  );
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
/// therefore a compact resident-day-index calculation, never a ledger-row or
/// repository read. HTML modes intentionally evaluate their selected scope as
/// one series; causal full-history may walk retained daily buckets, but never
/// reconstruct raw source membership on a thumb event.
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

  /// Backwards-compatible one-target convenience for isolated consumers. Core
  /// uses [resolve] so Header text and chart share one scope-series result.
  MindBehavioralScoreFrame preview({
    required QueryAmountRangeValues range,
    required int targetEpochDay,
  }) {
    final first = _dayKeys.isEmpty
        ? targetEpochDay
        : firstEligibleEpochDay(
            range: range,
            startInclusiveEpochDay: _dayKeys.first,
            endInclusiveEpochDay: targetEpochDay,
            fallbackEpochDay: targetEpochDay,
          );
    return resolve(
      range: range,
      request: MindBehavioralScoreSeriesRequest(
        analyticStartInclusiveEpochDay: first,
        analyticEndInclusiveEpochDay: targetEpochDay,
        chartStartInclusiveEpochDay: first,
        targetEpochDay: targetEpochDay,
      ),
    );
  }

  /// Resolves one immutable scope series for both semantic Header score and
  /// visual chart. It is invoked only at semantic/range publication time;
  /// Header paint consumes the returned data without financial work.
  MindBehavioralScoreFrame resolve({
    required QueryAmountRangeValues range,
    required MindBehavioralScoreSeriesRequest request,
    int maximumChartPoints = MindBehavioralScoreChartSeries.maximumVisualPoints,
  }) {
    if (maximumChartPoints <= 0) {
      throw ArgumentError.value(
        maximumChartPoints,
        'maximumChartPoints',
        'must be positive',
      );
    }
    final watch = _sourceWorkCounter.measurePreviewDurations
        ? (Stopwatch()..start())
        : null;
    var visited = 0;
    List<MindBehavioralScorePoint> pointsFor(
      MindBehavioralScoreSeriesRequest seriesRequest,
    ) => switch (identity.direction) {
      LedgerDirection.expense => _expenseSeries(
        range: range,
        request: seriesRequest,
        onDayBucketVisited: () => visited += 1,
      ),
      LedgerDirection.income => _incomeChartPoints(
        range: range,
        sampleDays: _sampleEpochDays(
          startInclusiveEpochDay: seriesRequest.chartStartInclusiveEpochDay,
          endInclusiveEpochDay: seriesRequest.targetEpochDay,
          maximumPoints: maximumChartPoints,
        ),
        onDayBucketVisited: () => visited += 1,
      ),
    };
    final points = pointsFor(request);
    final scopedPoints = points
        .where(
          (point) =>
              point.epochDay >= request.chartStartInclusiveEpochDay &&
              point.epochDay <= request.targetEpochDay,
        )
        .toList(growable: false);
    final pointStart = request.pointAnalyticStartInclusiveEpochDay;
    final point =
        pointStart == null ||
            pointStart == request.analyticStartInclusiveEpochDay
        ? _latestPointAtOrBefore(
            scopedPoints,
            targetEpochDay: request.targetEpochDay,
          )
        : _latestPointAtOrBefore(
            pointsFor(
              MindBehavioralScoreSeriesRequest(
                analyticStartInclusiveEpochDay: pointStart,
                analyticEndInclusiveEpochDay: request.targetEpochDay,
                chartStartInclusiveEpochDay: request.targetEpochDay,
                targetEpochDay: request.targetEpochDay,
              ),
            ),
            targetEpochDay: request.targetEpochDay,
          );
    final chartPoints = _chartPointsFor(
      points,
      chartStartInclusiveEpochDay: request.chartStartInclusiveEpochDay,
      targetEpochDay: request.targetEpochDay,
      maximumPoints: maximumChartPoints,
      fallback: point,
    );
    // Only the Day presentation requests a distinct point analytic origin.
    // Its 31-day chart must end at that canonical Day point. Existing scopes
    // retain their established sparse chart sampling without a synthetic end
    // point (for example an amount-excluded final day).
    final endpointChartPoints = List<MindBehavioralScorePoint>.of(
      chartPoints,
      growable: true,
    );
    if (pointStart != null) {
      if (endpointChartPoints.isEmpty ||
          endpointChartPoints.last.epochDay != request.targetEpochDay) {
        endpointChartPoints.add(point);
      } else {
        endpointChartPoints[endpointChartPoints.length - 1] = point;
      }
    }
    watch?.stop();
    _sourceWorkCounter.finishPreview(
      dayBucketsVisited: visited,
      micros: watch?.elapsedMicroseconds ?? 0,
    );
    _sourceWorkCounter.finishChartSeries(
      pointCount: chartPoints.length,
      dayBucketsVisited: visited,
    );
    return MindBehavioralScoreFrame(
      identity: identity,
      range: range,
      point: point,
      chartSeries: MindBehavioralScoreChartSeries(
        startInclusiveEpochDay: request.chartStartInclusiveEpochDay,
        endInclusiveEpochDay: request.targetEpochDay,
        points: endpointChartPoints,
      ),
      seriesRequest: request,
    );
  }

  /// Returns a visually bounded chronological history over the requested
  /// scope. It preserves the public convenience API while using the same
  /// scope-series algorithm as [resolve].
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
    return resolve(
      range: range,
      request: MindBehavioralScoreSeriesRequest(
        analyticStartInclusiveEpochDay: startInclusiveEpochDay,
        analyticEndInclusiveEpochDay: endInclusiveEpochDay,
        chartStartInclusiveEpochDay: startInclusiveEpochDay,
        targetEpochDay: endInclusiveEpochDay,
      ),
      maximumChartPoints: maximumPoints,
    ).chartSeries!;
  }

  MindBehavioralScorePoint _latestPointAtOrBefore(
    List<MindBehavioralScorePoint> points, {
    required int targetEpochDay,
  }) {
    for (var index = points.length - 1; index >= 0; index -= 1) {
      final point = points[index];
      if (point.epochDay <= targetEpochDay) return point;
    }
    return switch (identity.direction) {
      LedgerDirection.expense => _noPressureExpensePoint(targetEpochDay),
      LedgerDirection.income => _incomePointFromHistory(
        targetEpochDay: targetEpochDay,
        current: 0,
        priorCount: 0,
        previousAverage: 0,
        medianWithCurrent: 0,
      ),
    };
  }

  static List<MindBehavioralScorePoint> _chartPointsFor(
    List<MindBehavioralScorePoint> points, {
    required int chartStartInclusiveEpochDay,
    required int targetEpochDay,
    required int maximumPoints,
    required MindBehavioralScorePoint fallback,
  }) {
    final scoped = points
        .where(
          (point) =>
              point.epochDay >= chartStartInclusiveEpochDay &&
              point.epochDay <= targetEpochDay,
        )
        .toList(growable: false);
    final source = scoped.isEmpty
        ? <MindBehavioralScorePoint>[fallback]
        : scoped;
    if (source.length <= maximumPoints) return source;
    return List<MindBehavioralScorePoint>.generate(
      maximumPoints,
      (index) => source[(source.length - 1) * index ~/ (maximumPoints - 1)],
      growable: false,
    );
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

  /// Builds one Expense series for the requested analytic scope. Every amount
  /// lookup is against the resident per-day range index; there is no ledger
  /// row, repository, renderer, or animation dependency here.
  List<MindBehavioralScorePoint> _expenseSeries({
    required QueryAmountRangeValues range,
    required MindBehavioralScoreSeriesRequest request,
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

    final amounts = List<int>.generate(
      request.analyticEndInclusiveEpochDay -
          request.analyticStartInclusiveEpochDay +
          1,
      (index) => amountAt(request.analyticStartInclusiveEpochDay + index),
      growable: false,
    );
    return switch (identity.settings.expenseAlgorithm) {
      MindExpenseScoreAlgorithm.htmlCentered => _htmlExpenseSeries(
        amounts: amounts,
        seriesStartEpochDay: request.analyticStartInclusiveEpochDay,
        centered: true,
      ),
      MindExpenseScoreAlgorithm.htmlTrailing => _htmlExpenseSeries(
        amounts: amounts,
        seriesStartEpochDay: request.analyticStartInclusiveEpochDay,
        centered: false,
      ),
      MindExpenseScoreAlgorithm.causalTrailing => _causalExpenseSeries(
        amounts: amounts,
        seriesStartEpochDay: request.analyticStartInclusiveEpochDay,
      ),
    };
  }

  /// Exact scope-series form of the approved HTML Expense calculation. Sparse
  /// versus dense is intentionally decided once across the whole active
  /// evaluation series, never separately at each target date.
  List<MindBehavioralScorePoint> _htmlExpenseSeries({
    required List<int> amounts,
    required int seriesStartEpochDay,
    required bool centered,
  }) {
    final firstActive = amounts.indexWhere((amount) => amount > 0);
    if (firstActive < 0) return const <MindBehavioralScorePoint>[];
    var lastActive = amounts.length - 1;
    while (amounts[lastActive] <= 0) {
      lastActive -= 1;
    }
    final graph = amounts.sublist(firstActive, lastActive + 1);
    final graphStart = seriesStartEpochDay + firstActive;
    final activeDays = graph.where((amount) => amount > 0).length;
    final amountMaximum = graph.fold<int>(
      0,
      (maximum, amount) => math.max(maximum, amount),
    );
    final graphAmountTotal = graph.fold<int>(0, (sum, amount) => sum + amount);
    if (activeDays <= 12) {
      return <MindBehavioralScorePoint>[
        for (var index = 0; index < graph.length; index += 1)
          if (graph[index] > 0)
            _sparseExpensePoint(
              epochDay: graphStart + index,
              dailyAmount: graph[index],
              amountMaximum: amountMaximum,
              activeDaysInContext: activeDays,
              rollingOccurrence: activeDays,
              rollingAmount: graphAmountTotal,
            ),
      ];
    }

    final prefixAmounts = _prefixSums(graph);
    final prefixOccurrences = _prefixOccurrences(graph);
    final occurrences = List<int>.filled(graph.length, 0, growable: false);
    final rollingAmounts = List<int>.filled(graph.length, 0, growable: false);
    for (var index = 0; index < graph.length; index += 1) {
      final start = centered
          ? math.max(0, index - 15)
          : math.max(0, index - (_behaviorWindowDays - 1));
      final endExclusive = centered
          ? math.min(graph.length, index + 16)
          : index + 1;
      occurrences[index] =
          prefixOccurrences[endExclusive] - prefixOccurrences[start];
      rollingAmounts[index] =
          prefixAmounts[endExclusive] - prefixAmounts[start];
    }
    final period = dynamicExpenseEmaPeriod(activeDays);
    final alpha = 2 / (period + 1);
    final smoothedOccurrences = _ema(occurrences, alpha);
    final smoothedAmounts = _ema(rollingAmounts, alpha);
    final occurrenceMaximum = smoothedOccurrences.fold<double>(0, math.max);
    final amountMaximumSmoothed = smoothedAmounts.fold<double>(0, math.max);
    return List<MindBehavioralScorePoint>.generate(graph.length, (index) {
      final occurrenceIndex = occurrenceMaximum <= 0
          ? 0.0
          : _clamp100(smoothedOccurrences[index] / occurrenceMaximum * 100);
      final amountIndex = amountMaximumSmoothed <= 0
          ? 0.0
          : _clamp100(smoothedAmounts[index] / amountMaximumSmoothed * 100);
      final pressure = _clamp100(.5 * occurrenceIndex + .5 * amountIndex);
      return MindBehavioralScorePoint(
        epochDay: graphStart + index,
        score: _clamp100(100 - pressure),
        noSignal: false,
        expense: MindExpenseScoreComponents(
          activeDaysInContext: activeDays,
          dailyAmount: graph[index],
          amountMaximum: amountMaximum,
          isSparse: false,
          emaPeriod: period,
          rollingOccurrence: occurrences[index],
          rollingAmount: rollingAmounts[index],
          smoothedOccurrence: smoothedOccurrences[index],
          smoothedAmount: smoothedAmounts[index],
          occurrenceIndex: occurrenceIndex,
          amountIndex: amountIndex,
          pressure: pressure,
        ),
      );
    }, growable: false);
  }

  /// Forward-only robust Expense model. State begins at the caller-selected
  /// analytic origin. Once the thirteenth qualifying active day arrives, the
  /// model stays dense even if a later 31-day window becomes quiet.
  List<MindBehavioralScorePoint> _causalExpenseSeries({
    required List<int> amounts,
    required int seriesStartEpochDay,
  }) {
    final prefixAmounts = _prefixSums(amounts);
    final prefixOccurrences = _prefixOccurrences(amounts);
    final points = <MindBehavioralScorePoint>[];
    var cumulativeActiveDays = 0;
    var smoothedOccurrence = 0.0;
    var smoothedAmount = 0.0;
    var occurrenceReference = 1.0;
    var amountReference = 1.0;

    for (var index = 0; index < amounts.length; index += 1) {
      final dailyAmount = amounts[index];
      if (dailyAmount > 0) cumulativeActiveDays += 1;
      final start = math.max(0, index - (_behaviorWindowDays - 1));
      final endExclusive = index + 1;
      final rollingOccurrence =
          prefixOccurrences[endExclusive] - prefixOccurrences[start];
      final rollingAmount = prefixAmounts[endExclusive] - prefixAmounts[start];
      final period = dynamicExpenseEmaPeriod(cumulativeActiveDays);
      final alpha = 2 / (period + 1);
      if (index == 0) {
        smoothedOccurrence = rollingOccurrence.toDouble();
        smoothedAmount = rollingAmount.toDouble();
      } else {
        smoothedOccurrence += alpha * (rollingOccurrence - smoothedOccurrence);
        smoothedAmount += alpha * (rollingAmount - smoothedAmount);
      }
      occurrenceReference = math.max(occurrenceReference, smoothedOccurrence);
      amountReference = math.max(amountReference, smoothedAmount);
      final epochDay = seriesStartEpochDay + index;

      if (cumulativeActiveDays <= 12) {
        if (dailyAmount <= 0) continue;
        var sparseMaximum = 0;
        for (
          var sparseIndex = start;
          sparseIndex < endExclusive;
          sparseIndex += 1
        ) {
          sparseMaximum = math.max(sparseMaximum, amounts[sparseIndex]);
        }
        points.add(
          _sparseExpensePoint(
            epochDay: epochDay,
            dailyAmount: dailyAmount,
            amountMaximum: sparseMaximum,
            activeDaysInContext: rollingOccurrence,
            rollingOccurrence: rollingOccurrence,
            rollingAmount: rollingAmount,
          ),
        );
        continue;
      }

      final occurrenceIndex = _clamp100(
        smoothedOccurrence / occurrenceReference * 100,
      );
      final amountIndex = _clamp100(smoothedAmount / amountReference * 100);
      final pressure = _clamp100(.5 * occurrenceIndex + .5 * amountIndex);
      var amountMaximum = 0;
      for (
        var maximumIndex = start;
        maximumIndex < endExclusive;
        maximumIndex += 1
      ) {
        amountMaximum = math.max(amountMaximum, amounts[maximumIndex]);
      }
      points.add(
        MindBehavioralScorePoint(
          epochDay: epochDay,
          score: _clamp100(100 - pressure),
          noSignal: false,
          expense: MindExpenseScoreComponents(
            activeDaysInContext: rollingOccurrence,
            dailyAmount: dailyAmount,
            amountMaximum: amountMaximum,
            isSparse: false,
            emaPeriod: period,
            rollingOccurrence: rollingOccurrence,
            rollingAmount: rollingAmount,
            smoothedOccurrence: smoothedOccurrence,
            smoothedAmount: smoothedAmount,
            occurrenceIndex: occurrenceIndex,
            amountIndex: amountIndex,
            pressure: pressure,
          ),
        ),
      );
    }
    return points;
  }

  MindBehavioralScorePoint _sparseExpensePoint({
    required int epochDay,
    required int dailyAmount,
    required int amountMaximum,
    required int activeDaysInContext,
    required int rollingOccurrence,
    required int rollingAmount,
  }) {
    final amountIndex = amountMaximum == 0
        ? 0.0
        : _clamp100(dailyAmount / amountMaximum * 100);
    return MindBehavioralScorePoint(
      epochDay: epochDay,
      score: _clamp100(100 - amountIndex),
      noSignal: false,
      expense: MindExpenseScoreComponents(
        activeDaysInContext: activeDaysInContext,
        dailyAmount: dailyAmount,
        amountMaximum: amountMaximum,
        isSparse: true,
        emaPeriod: null,
        rollingOccurrence: rollingOccurrence,
        rollingAmount: rollingAmount,
        smoothedOccurrence: rollingOccurrence.toDouble(),
        smoothedAmount: dailyAmount.toDouble(),
        occurrenceIndex: 0,
        amountIndex: amountIndex,
        pressure: amountIndex,
      ),
    );
  }

  MindBehavioralScorePoint _noPressureExpensePoint(int epochDay) =>
      _sparseExpensePoint(
        epochDay: epochDay,
        dailyAmount: 0,
        amountMaximum: 0,
        activeDaysInContext: 0,
        rollingOccurrence: 0,
        rollingAmount: 0,
      );

  static List<int> _prefixSums(List<int> values) {
    final result = List<int>.filled(values.length + 1, 0, growable: false);
    for (var index = 0; index < values.length; index += 1) {
      result[index + 1] = result[index] + values[index];
    }
    return result;
  }

  static List<int> _prefixOccurrences(List<int> values) {
    final result = List<int>.filled(values.length + 1, 0, growable: false);
    for (var index = 0; index < values.length; index += 1) {
      result[index + 1] = result[index] + (values[index] > 0 ? 1 : 0);
    }
    return result;
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
