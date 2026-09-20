import '../../query/domain/query_amount_range.dart';
import '../../time_navigation/domain/local_date.dart';
import 'mind_heatmap_amount_range_bucket.dart';
import 'mind_temporal_heatmap_frame.dart';
import 'mind_year_heatmap_projection.dart';

/// Immutable provenance shared by non-Year Mind heatmap projections. It
/// contains only already-admitted prepared membership identity; widgets and
/// Query state never participate in bucket calculation.
final class MindTemporalHeatmapIdentity {
  const MindTemporalHeatmapIdentity({
    required this.upstreamScopeKey,
    required this.indexGeneration,
    required this.coreRevision,
    required this.timeScopeKey,
    this.navigationEpoch = 0,
  });

  final String upstreamScopeKey;
  final int indexGeneration;
  final int coreRevision;
  final String timeScopeKey;
  final int navigationEpoch;

  @override
  bool operator ==(Object other) =>
      other is MindTemporalHeatmapIdentity &&
      other.upstreamScopeKey == upstreamScopeKey &&
      other.indexGeneration == indexGeneration &&
      other.coreRevision == coreRevision &&
      other.timeScopeKey == timeScopeKey &&
      other.navigationEpoch == navigationEpoch;

  @override
  int get hashCode => Object.hash(
    upstreamScopeKey,
    indexGeneration,
    coreRevision,
    timeScopeKey,
    navigationEpoch,
  );
}

/// A compact all-time month-cell frame. Every represented year owns exactly
/// twelve calendar cells; null totals are real empty months, not fake data.
final class MindSumHeatmapFrame implements MindTemporalHeatmapFrame {
  /// The deepest detailed Sum representation uses the already-admitted local
  /// transaction minutes. This is presentation granularity only; it never
  /// opens a repository or query path.
  static const rawDetailWindowMinutes = _rawDetailWindowMinutes;

  MindSumHeatmapFrame._({
    required this.identity,
    required this.range,
    required List<int> years,
    required Map<(int year, int month), MindSumHeatmapMonth> months,
    required Map<int, int> yearTotals,
    required Map<(int year, int month), int> fullMonthTotals,
    required Map<int, List<MindSumHeatmapDailyPoint>> dailyPointsByYear,
    required Map<int, List<_MindSumPreparedDetail>> detailContributionsByYear,
    required this.minimumNonEmptyTotal,
    required this.maximumNonEmptyTotal,
  }) : years = List<int>.unmodifiable(years),
       _months = Map<(int year, int month), MindSumHeatmapMonth>.unmodifiable(
         months,
       ),
       _yearTotals = Map<int, int>.unmodifiable(yearTotals),
       _fullMonthTotals = Map<(int year, int month), int>.unmodifiable(
         fullMonthTotals,
       ),
       _dailyPointsByYear =
           Map<int, List<MindSumHeatmapDailyPoint>>.unmodifiable(
             dailyPointsByYear.map(
               (year, points) => MapEntry(
                 year,
                 List<MindSumHeatmapDailyPoint>.unmodifiable(points),
               ),
             ),
           ),
       _detailContributionsByYear =
           Map<int, List<_MindSumPreparedDetail>>.unmodifiable(
             detailContributionsByYear.map(
               (year, points) => MapEntry(
                 year,
                 List<_MindSumPreparedDetail>.unmodifiable(points),
               ),
             ),
           );

  @override
  final MindTemporalHeatmapIdentity identity;
  @override
  final QueryAmountRangeValues range;
  final List<int> years;
  final Map<(int year, int month), MindSumHeatmapMonth> _months;
  final Map<int, int> _yearTotals;
  final Map<(int year, int month), int> _fullMonthTotals;
  final Map<int, List<MindSumHeatmapDailyPoint>> _dailyPointsByYear;
  final Map<int, List<_MindSumPreparedDetail>> _detailContributionsByYear;
  final int? minimumNonEmptyTotal;
  final int? maximumNonEmptyTotal;

  MindSumHeatmapMonth month({required int year, required int month}) =>
      _months[(year, month)]!;

  int yearTotal(int year) => _yearTotals[year] ?? 0;

  /// Full directional month amount before focus/search membership and live
  /// range refinement. It is a comparison-only read model captured from the
  /// same prepared Sum admission, never a second Query authority.
  int fullMonthTotal({required int year, required int month}) =>
      _fullMonthTotals[(year, month)] ?? 0;

  /// Only real local calendar days with a non-empty current range total are
  /// exposed. The chart may join them visually, but it cannot invent a day.
  List<MindSumHeatmapDailyPoint> dailyPointsForYear(int year) =>
      _dailyPointsByYear[year] ?? const <MindSumHeatmapDailyPoint>[];

  /// Resolves the chart's current visible domain from the same admitted
  /// prepared contribution set as the Sum heatmap. Broad windows use already
  /// range-previewed daily aggregates; once the user has narrowed to a small
  /// calendar window, individual prepared transactions retain their local
  /// minute and ordinal. No repository or raw-ledger read is involved.
  List<MindSumHeatmapDetailPoint> detailPointsForYear({
    required int year,
    required int startEpochMinute,
    required int endEpochMinute,
    bool forceRawTransactions = false,
  }) {
    if (endEpochMinute < startEpochMinute) {
      return const <MindSumHeatmapDetailPoint>[];
    }
    final visibleMinutes = endEpochMinute - startEpochMinute + 1;
    if (forceRawTransactions || visibleMinutes <= _rawDetailWindowMinutes) {
      final prepared = _detailContributionsByYear[year];
      if (prepared == null || prepared.isEmpty) {
        return const <MindSumHeatmapDetailPoint>[];
      }
      final start = _lowerBoundByMinute(prepared, startEpochMinute);
      final points = <MindSumHeatmapDetailPoint>[];
      for (var index = start; index < prepared.length; index += 1) {
        final contribution = prepared[index];
        if (contribution.epochMinute > endEpochMinute) break;
        if (contribution.amountMinor < range.lowerScaled100 ||
            contribution.amountMinor > range.upperScaled100) {
          continue;
        }
        points.add(
          MindSumHeatmapDetailPoint(
            epochMinute: contribution.epochMinute,
            total: contribution.amountMinor,
            ordinal: contribution.ordinal,
          ),
        );
      }
      return List<MindSumHeatmapDetailPoint>.unmodifiable(points);
    }

    final startEpochDay = startEpochMinute ~/ _minutesPerDay;
    final endEpochDay = endEpochMinute ~/ _minutesPerDay;
    return List<MindSumHeatmapDetailPoint>.unmodifiable(
      dailyPointsForYear(year)
          .where(
            (point) =>
                point.date.epochDay >= startEpochDay &&
                point.date.epochDay <= endEpochDay,
          )
          .map(
            (point) => MindSumHeatmapDetailPoint(
              epochMinute: point.date.epochDay * _minutesPerDay + 720,
              total: point.total,
            ),
          ),
    );
  }

  /// Returns at most one truthful range-approved anchor on either side of a
  /// detailed chart viewport. These are painter context only: callers keep
  /// inspection restricted to points inside their actual visible window.
  ///
  /// A sparse year can have its nearest real neighbour farther away than the
  /// current LOD bucket padding. Resolving it from this immutable prepared
  /// frame prevents the clipped line from collapsing at a viewport edge
  /// without inventing a calendar value or reopening a repository/query path.
  List<MindSumHeatmapDetailPoint> detailPaintNeighboursForYear({
    required int year,
    required int startEpochMinute,
    required int endEpochMinute,
    bool forceRawTransactions = false,
  }) {
    if (endEpochMinute < startEpochMinute) {
      return const <MindSumHeatmapDetailPoint>[];
    }
    final visibleMinutes = endEpochMinute - startEpochMinute + 1;
    if (forceRawTransactions || visibleMinutes <= _rawDetailWindowMinutes) {
      final prepared = _detailContributionsByYear[year];
      if (prepared == null || prepared.isEmpty) {
        return const <MindSumHeatmapDetailPoint>[];
      }
      return _rawPaintNeighbours(
        prepared: prepared,
        startEpochMinute: startEpochMinute,
        endEpochMinute: endEpochMinute,
      );
    }

    final daily = dailyPointsForYear(year)
        .map(
          (point) => MindSumHeatmapDetailPoint(
            epochMinute: point.date.epochDay * _minutesPerDay + 720,
            total: point.total,
          ),
        )
        .toList(growable: false);
    return _paintNeighbours(
      points: daily,
      startEpochMinute: startEpochMinute,
      endEpochMinute: endEpochMinute,
    );
  }

  /// Resolves the bounded LOD source plus truthful off-screen painter context.
  /// The requested domain may include the current sampler padding, whereas
  /// [visibleStartEpochMinute]/[visibleEndEpochMinute] remain the real chart
  /// viewport. Callers must pass the result to an LOD selector that exposes
  /// only in-viewport anchors to inspection.
  List<MindSumHeatmapDetailPoint> detailPaintSourceForYear({
    required int year,
    required int requestedStartEpochMinute,
    required int requestedEndEpochMinute,
    required int visibleStartEpochMinute,
    required int visibleEndEpochMinute,
    bool forceRawTransactions = false,
  }) {
    final bounded = detailPointsForYear(
      year: year,
      startEpochMinute: requestedStartEpochMinute,
      endEpochMinute: requestedEndEpochMinute,
      forceRawTransactions: forceRawTransactions,
    );
    final neighbours = detailPaintNeighboursForYear(
      year: year,
      startEpochMinute: visibleStartEpochMinute,
      endEpochMinute: visibleEndEpochMinute,
      forceRawTransactions: forceRawTransactions,
    );
    final byIdentity = <(int, int?, int), MindSumHeatmapDetailPoint>{
      for (final point in bounded)
        (point.epochMinute, point.ordinal, point.total): point,
      for (final point in neighbours)
        (point.epochMinute, point.ordinal, point.total): point,
    };
    final points = byIdentity.values.toList(growable: false)
      ..sort((left, right) {
        final byMinute = left.epochMinute.compareTo(right.epochMinute);
        return byMinute != 0
            ? byMinute
            : (left.ordinal ?? -1).compareTo(right.ordinal ?? -1);
      });
    return List<MindSumHeatmapDetailPoint>.unmodifiable(points);
  }

  List<MindSumHeatmapDetailPoint> _rawPaintNeighbours({
    required List<_MindSumPreparedDetail> prepared,
    required int startEpochMinute,
    required int endEpochMinute,
  }) {
    MindSumHeatmapDetailPoint? before;
    var beforeIndex = _lowerBoundByMinute(prepared, startEpochMinute) - 1;
    while (beforeIndex >= 0) {
      final contribution = prepared[beforeIndex];
      if (contribution.amountMinor >= range.lowerScaled100 &&
          contribution.amountMinor <= range.upperScaled100) {
        before = MindSumHeatmapDetailPoint(
          epochMinute: contribution.epochMinute,
          total: contribution.amountMinor,
          ordinal: contribution.ordinal,
        );
        break;
      }
      beforeIndex -= 1;
    }

    MindSumHeatmapDetailPoint? after;
    var afterIndex = _lowerBoundByMinute(prepared, endEpochMinute + 1);
    while (afterIndex < prepared.length) {
      final contribution = prepared[afterIndex];
      if (contribution.amountMinor >= range.lowerScaled100 &&
          contribution.amountMinor <= range.upperScaled100) {
        after = MindSumHeatmapDetailPoint(
          epochMinute: contribution.epochMinute,
          total: contribution.amountMinor,
          ordinal: contribution.ordinal,
        );
        break;
      }
      afterIndex += 1;
    }
    return List<MindSumHeatmapDetailPoint>.unmodifiable(
      <MindSumHeatmapDetailPoint>[?before, ?after],
    );
  }

  static List<MindSumHeatmapDetailPoint> _paintNeighbours({
    required List<MindSumHeatmapDetailPoint> points,
    required int startEpochMinute,
    required int endEpochMinute,
  }) {
    MindSumHeatmapDetailPoint? before;
    MindSumHeatmapDetailPoint? after;
    for (final point in points) {
      if (point.epochMinute < startEpochMinute) {
        before = point;
        continue;
      }
      if (point.epochMinute > endEpochMinute) {
        after = point;
        break;
      }
    }
    return List<MindSumHeatmapDetailPoint>.unmodifiable(
      <MindSumHeatmapDetailPoint>[?before, ?after],
    );
  }

  static int _lowerBoundByMinute(
    List<_MindSumPreparedDetail> points,
    int epochMinute,
  ) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (points[middle].epochMinute < epochMinute) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

const _minutesPerDay = 24 * 60;
const _rawDetailWindowMinutes = 7 * _minutesPerDay;

/// A renderer-facing immutable Sum detail anchor. A null [ordinal] is a
/// range-previewed daily aggregate; a non-null ordinal is one exact prepared
/// transaction at its local minute. The latter is intentionally not a new
/// Query or repository authority.
final class MindSumHeatmapDetailPoint {
  const MindSumHeatmapDetailPoint({
    required this.epochMinute,
    required this.total,
    this.ordinal,
  });

  final int epochMinute;
  final int total;
  final int? ordinal;

  bool get isTransaction => ordinal != null;
}

final class _MindSumPreparedDetail {
  const _MindSumPreparedDetail({
    required this.ordinal,
    required this.epochMinute,
    required this.amountMinor,
  });

  final int ordinal;
  final int epochMinute;
  final int amountMinor;
}

/// One immutable Sum line-chart anchor. Its amount is derived from the same
/// prepared membership and live amount-range preview as the Sum heatmap cell.
final class MindSumHeatmapDailyPoint {
  const MindSumHeatmapDailyPoint({required this.date, required this.total});

  final LocalDate date;
  final int total;
}

/// A reusable immutable financial aggregate anchor. The ordinal is its only
/// geometry domain; renderers may refine a line between anchors but never
/// create an additional financial observation.
final class MindAggregateLinePoint {
  const MindAggregateLinePoint({
    required this.ordinal,
    required this.label,
    required this.total,
  });

  final int ordinal;
  final String label;
  final int total;
}

final class MindSumHeatmapMonth {
  const MindSumHeatmapMonth({
    required this.year,
    required this.month,
    required this.total,
    required this.kind,
    required this.intensity,
    required this.paletteIntensity,
  });

  final int year;
  final int month;
  final int? total;
  final MindYearHeatmapTileKind kind;
  final double intensity;
  final MindYearHeatmapPaletteIntensity paletteIntensity;

  bool get isEmpty => total == null;
}

/// Compact selected-month daily frame. Its fixed six-row visual envelope is a
/// renderer decision; the frame contains only real local dates.
final class MindMonthHeatmapFrame implements MindTemporalHeatmapFrame {
  MindMonthHeatmapFrame({
    required this.identity,
    required this.range,
    required this.year,
    required this.month,
    required List<MindYearHeatmapDay> days,
    required List<int> fullDailyTotals,
    required this.activeDayCount,
    required this.total,
    required this.minimumNonEmptyTotal,
    required this.maximumNonEmptyTotal,
  }) : days = List<MindYearHeatmapDay>.unmodifiable(days),
       _fullDailyTotals = List<int>.unmodifiable(fullDailyTotals);

  @override
  final MindTemporalHeatmapIdentity identity;
  @override
  final QueryAmountRangeValues range;
  final int year;
  final int month;
  final List<MindYearHeatmapDay> days;
  final List<int> _fullDailyTotals;
  final int activeDayCount;
  final int total;
  final int? minimumNonEmptyTotal;
  final int? maximumNonEmptyTotal;

  MindYearHeatmapDay day(int value) => days[value - 1];

  /// A continuous visual day domain for Month's rhythm page. Empty calendar
  /// days are explicit zero aggregates, not invented transactions; non-empty
  /// values are the same live amount-range totals consumed by the heatmap.
  List<MindAggregateLinePoint> get dailyRhythmPoints =>
      List<MindAggregateLinePoint>.generate(
        days.length,
        (index) => MindAggregateLinePoint(
          ordinal: index + 1,
          label: '${index + 1}',
          total: days[index].total ?? 0,
        ),
        growable: false,
      );

  /// The same admitted membership before only the live amount-range preview.
  /// This gives the rhythm page a truthful gray comparison layer without an
  /// upstream Query mutation or a new financial authority.
  List<MindAggregateLinePoint> get fullDailyRhythmPoints =>
      List<MindAggregateLinePoint>.generate(
        _fullDailyTotals.length,
        (index) => MindAggregateLinePoint(
          ordinal: index + 1,
          label: '${index + 1}',
          total: _fullDailyTotals[index],
        ),
        growable: false,
      );
}

/// Resident month-bucket projection for Sum. Range previews visit only
/// twelve buckets per represented year and use prefix sums inside each bucket.
final class MindSumHeatmapProjection {
  MindSumHeatmapProjection._({
    required this.identity,
    required Map<(int year, int month), MindHeatmapAmountRangeBucket> buckets,
    required Map<int, Map<int, MindHeatmapAmountRangeBucket>> dailyBuckets,
    required Map<int, List<_MindSumPreparedDetail>> detailContributions,
    required Map<(int year, int month), int> fullMonthTotals,
    required List<int> years,
    required this.preparedContributionTouches,
  }) : _buckets =
           Map<
             (int year, int month),
             MindHeatmapAmountRangeBucket
           >.unmodifiable(buckets),
       _dailyBuckets =
           Map<int, Map<int, MindHeatmapAmountRangeBucket>>.unmodifiable(
             dailyBuckets.map(
               (year, buckets) => MapEntry(
                 year,
                 Map<int, MindHeatmapAmountRangeBucket>.unmodifiable(buckets),
               ),
             ),
           ),
       _detailContributions =
           Map<int, List<_MindSumPreparedDetail>>.unmodifiable(
             detailContributions.map(
               (year, values) => MapEntry(
                 year,
                 List<_MindSumPreparedDetail>.unmodifiable(values),
               ),
             ),
           ),
       _fullMonthTotals = Map<(int year, int month), int>.unmodifiable(
         fullMonthTotals,
       ),
       _years = List<int>.unmodifiable(years);

  factory MindSumHeatmapProjection.build({
    required MindTemporalHeatmapIdentity identity,
    required Iterable<MindYearHeatmapPreparedContribution> contributions,
    Iterable<MindYearHeatmapPreparedContribution>? fullContributions,
  }) {
    final selectedContributions = contributions.toList(growable: false);
    final fullSource =
        fullContributions?.toList(growable: false) ?? selectedContributions;
    final values = <(int year, int month), List<int>>{};
    final dailyValues = <int, Map<int, List<int>>>{};
    final detailContributions = <int, List<_MindSumPreparedDetail>>{};
    var preparedContributionTouches = 0;
    for (final contribution in selectedContributions) {
      preparedContributionTouches += 1;
      final date = _dateForEpochDay(contribution.bookedLocalEpochDay);
      values
          .putIfAbsent((date.year, date.month), () => <int>[])
          .add(contribution.amountMinor);
      dailyValues
          .putIfAbsent(date.year, () => <int, List<int>>{})
          .putIfAbsent(contribution.bookedLocalEpochDay, () => <int>[])
          .add(contribution.amountMinor);
      final localTime = contribution.bookedLocalTimeMinutes
          .clamp(0, _minutesPerDay - 1)
          .toInt();
      detailContributions
          .putIfAbsent(date.year, () => <_MindSumPreparedDetail>[])
          .add(
            _MindSumPreparedDetail(
              ordinal: contribution.ordinal,
              epochMinute:
                  contribution.bookedLocalEpochDay * _minutesPerDay + localTime,
              amountMinor: contribution.amountMinor,
            ),
          );
    }
    final fullMonthTotals = <(int year, int month), int>{};
    for (final contribution in fullSource) {
      final date = _dateForEpochDay(contribution.bookedLocalEpochDay);
      final key = (date.year, date.month);
      fullMonthTotals[key] =
          (fullMonthTotals[key] ?? 0) + contribution.amountMinor;
    }
    final years = <int>{
      ...values.keys.map((key) => key.$1),
      ...fullMonthTotals.keys.map((key) => key.$1),
    }.toList()..sort();
    return MindSumHeatmapProjection._(
      identity: identity,
      buckets: values.map(
        (key, value) =>
            MapEntry(key, MindHeatmapAmountRangeBucket.fromUnsorted(value)),
      ),
      dailyBuckets: dailyValues.map(
        (year, valuesForYear) => MapEntry(
          year,
          valuesForYear.map(
            (epochDay, valuesForDay) => MapEntry(
              epochDay,
              MindHeatmapAmountRangeBucket.fromUnsorted(valuesForDay),
            ),
          ),
        ),
      ),
      detailContributions: detailContributions.map((year, valuesForYear) {
        valuesForYear.sort((left, right) {
          final byTime = left.epochMinute.compareTo(right.epochMinute);
          return byTime != 0 ? byTime : left.ordinal.compareTo(right.ordinal);
        });
        return MapEntry(year, valuesForYear);
      }),
      fullMonthTotals: fullMonthTotals,
      years: years,
      preparedContributionTouches: preparedContributionTouches,
    );
  }

  final MindTemporalHeatmapIdentity identity;
  final Map<(int year, int month), MindHeatmapAmountRangeBucket> _buckets;
  final Map<int, Map<int, MindHeatmapAmountRangeBucket>> _dailyBuckets;
  final Map<int, List<_MindSumPreparedDetail>> _detailContributions;
  final Map<(int year, int month), int> _fullMonthTotals;
  final List<int> _years;
  final int preparedContributionTouches;

  MindSumHeatmapFrame preview(QueryAmountRangeValues range) {
    final totals = <(int year, int month), int?>{};
    int? minimum;
    int? maximum;
    for (final year in _years) {
      for (var month = 1; month <= 12; month += 1) {
        final total = _buckets[(year, month)]?.sumWithin(
          minimum: range.lowerScaled100,
          maximum: range.upperScaled100,
        );
        totals[(year, month)] = total;
        if (total != null) {
          minimum = minimum == null || total < minimum ? total : minimum;
          maximum = maximum == null || total > maximum ? total : maximum;
        }
      }
    }
    final months = <(int year, int month), MindSumHeatmapMonth>{};
    final yearTotals = <int, int>{};
    for (final year in _years) {
      var yearTotal = 0;
      for (var month = 1; month <= 12; month += 1) {
        final total = totals[(year, month)];
        if (total != null) yearTotal += total;
        months[(year, month)] = MindSumHeatmapMonth(
          year: year,
          month: month,
          total: total,
          kind: _kindFor(total: total, minimum: minimum, maximum: maximum),
          intensity: _intensityFor(
            total: total,
            minimum: minimum,
            maximum: maximum,
          ),
          paletteIntensity: _paletteIntensityFor(
            total: total,
            minimum: minimum,
            maximum: maximum,
          ),
        );
      }
      yearTotals[year] = yearTotal;
    }
    final dailyPointsByYear = <int, List<MindSumHeatmapDailyPoint>>{};
    for (final year in _years) {
      final buckets = _dailyBuckets[year];
      if (buckets == null || buckets.isEmpty) continue;
      final points = <MindSumHeatmapDailyPoint>[];
      final epochDays = buckets.keys.toList(growable: false)..sort();
      for (final epochDay in epochDays) {
        final total = buckets[epochDay]!.sumWithin(
          minimum: range.lowerScaled100,
          maximum: range.upperScaled100,
        );
        if (total == null) continue;
        points.add(
          MindSumHeatmapDailyPoint(
            date: _dateForEpochDay(epochDay),
            total: total,
          ),
        );
      }
      dailyPointsByYear[year] = points;
    }
    return MindSumHeatmapFrame._(
      identity: identity,
      range: range,
      years: _years,
      months: months,
      yearTotals: yearTotals,
      fullMonthTotals: _fullMonthTotals,
      dailyPointsByYear: dailyPointsByYear,
      detailContributionsByYear: _detailContributions,
      minimumNonEmptyTotal: minimum,
      maximumNonEmptyTotal: maximum,
    );
  }
}

/// Resident day-bucket projection for one selected calendar month. Range
/// previews have a fixed 28–31 bucket ceiling.
final class MindMonthHeatmapProjection {
  MindMonthHeatmapProjection._({
    required this.identity,
    required this.year,
    required this.month,
    required List<MindHeatmapAmountRangeBucket> days,
    required this.preparedContributionTouches,
  }) : _days = List<MindHeatmapAmountRangeBucket>.unmodifiable(days);

  factory MindMonthHeatmapProjection.build({
    required MindTemporalHeatmapIdentity identity,
    required int year,
    required int month,
    required Iterable<MindYearHeatmapPreparedContribution> contributions,
  }) {
    final count = DateTime.utc(year, month + 1, 0).day;
    final values = List<List<int>>.generate(count, (_) => <int>[]);
    var preparedContributionTouches = 0;
    for (final contribution in contributions) {
      preparedContributionTouches += 1;
      final date = _dateForEpochDay(contribution.bookedLocalEpochDay);
      if (date.year == year && date.month == month) {
        values[date.day - 1].add(contribution.amountMinor);
      }
    }
    return MindMonthHeatmapProjection._(
      identity: identity,
      year: year,
      month: month,
      days: values.map(MindHeatmapAmountRangeBucket.fromUnsorted).toList(),
      preparedContributionTouches: preparedContributionTouches,
    );
  }

  final MindTemporalHeatmapIdentity identity;
  final int year;
  final int month;
  final List<MindHeatmapAmountRangeBucket> _days;
  final int preparedContributionTouches;

  MindMonthHeatmapFrame preview(QueryAmountRangeValues range) {
    final totals = _days
        .map(
          (bucket) => bucket.sumWithin(
            minimum: range.lowerScaled100,
            maximum: range.upperScaled100,
          ),
        )
        .toList(growable: false);
    final fullDailyTotals = _days
        .map(
          (bucket) =>
              bucket.sumWithin(
                minimum: range.minimumScaled100,
                maximum: range.maximumScaled100,
              ) ??
              0,
        )
        .toList(growable: false);
    int? minimum;
    int? maximum;
    var total = 0;
    var activeDays = 0;
    for (final value in totals) {
      if (value == null) continue;
      activeDays += 1;
      total += value;
      minimum = minimum == null || value < minimum ? value : minimum;
      maximum = maximum == null || value > maximum ? value : maximum;
    }
    final days = List<MindYearHeatmapDay>.generate(totals.length, (index) {
      final value = totals[index];
      return MindYearHeatmapDay(
        date: LocalDate(year: year, month: month, day: index + 1),
        total: value,
        kind: _kindFor(total: value, minimum: minimum, maximum: maximum),
        intensity: _intensityFor(
          total: value,
          minimum: minimum,
          maximum: maximum,
        ),
        paletteIntensity: _paletteIntensityFor(
          total: value,
          minimum: minimum,
          maximum: maximum,
        ),
      );
    }, growable: false);
    return MindMonthHeatmapFrame(
      identity: identity,
      range: range,
      year: year,
      month: month,
      days: days,
      fullDailyTotals: fullDailyTotals,
      activeDayCount: activeDays,
      total: total,
      minimumNonEmptyTotal: minimum,
      maximumNonEmptyTotal: maximum,
    );
  }
}

/// Compact immutable Day frame.  Its hourly cells are a presentation of the
/// admitted monetary membership; behavioral score ownership remains entirely
/// with [MindBehavioralScoreProjection].
final class MindDayHeatmapFrame implements MindTemporalHeatmapFrame {
  MindDayHeatmapFrame({
    required this.identity,
    required this.range,
    required this.date,
    required List<MindDayHeatmapHour> hours,
    required List<MindDayTimelineEvent> timelineEvents,
    required List<MindDayTimelineEvent> fullTimelineEvents,
    required this.activeHourCount,
    required this.total,
    required this.minimumNonEmptyTotal,
    required this.maximumNonEmptyTotal,
  }) : hours = List<MindDayHeatmapHour>.unmodifiable(hours),
       timelineEvents = List<MindDayTimelineEvent>.unmodifiable(timelineEvents),
       fullTimelineEvents = List<MindDayTimelineEvent>.unmodifiable(
         fullTimelineEvents,
       );

  @override
  final MindTemporalHeatmapIdentity identity;
  @override
  final QueryAmountRangeValues range;
  final LocalDate date;
  final List<MindDayHeatmapHour> hours;

  /// Exact current-range event markers for the Day timeline. These markers are
  /// captured from the admitted prepared contribution set at projection build;
  /// they never cause a ledger or repository read from presentation.
  final List<MindDayTimelineEvent> timelineEvents;

  /// Exact selected-day markers before the live amount-range refinement.
  final List<MindDayTimelineEvent> fullTimelineEvents;
  int get fullTimelineTotal =>
      fullTimelineEvents.fold<int>(0, (total, event) => total + event.total);
  final int activeHourCount;
  final int total;
  final int? minimumNonEmptyTotal;
  final int? maximumNonEmptyTotal;

  MindDayHeatmapHour hour(int value) => hours[value];
}

/// One exact resident transaction marker for the Day timeline. [ordinal]
/// retains stable prepared ordering when two transactions share a minute.
final class MindDayTimelineEvent {
  const MindDayTimelineEvent({
    required this.ordinal,
    required this.timeMinutes,
    required this.total,
  });

  final int ordinal;
  final int timeMinutes;
  final int total;
}

final class MindDayHeatmapHour {
  const MindDayHeatmapHour({
    required this.hour,
    required this.total,
    required this.kind,
    required this.intensity,
    required this.paletteIntensity,
  });

  final int hour;
  final int? total;
  final MindYearHeatmapTileKind kind;
  final double intensity;
  final MindYearHeatmapPaletteIntensity paletteIntensity;

  bool get isEmpty => total == null;
}

/// Resident 24-bucket projection for the existing Month-plane [DayScope].
/// Target construction reads prepared contributions only; a held amount range
/// preview visits exactly these buckets and never consults ledger rows.
final class MindDayHeatmapProjection {
  MindDayHeatmapProjection._({
    required this.identity,
    required this.date,
    required List<MindHeatmapAmountRangeBucket> hours,
    required List<_MindDayTimelinePreparedEvent> timelineEvents,
    required this.preparedContributionTouches,
  }) : _hours = List<MindHeatmapAmountRangeBucket>.unmodifiable(hours),
       _timelineEvents = List<_MindDayTimelinePreparedEvent>.unmodifiable(
         timelineEvents,
       );

  factory MindDayHeatmapProjection.build({
    required MindTemporalHeatmapIdentity identity,
    required LocalDate date,
    required Iterable<MindYearHeatmapPreparedContribution> contributions,
  }) {
    final values = List<List<int>>.generate(24, (_) => <int>[]);
    final timelineEvents = <_MindDayTimelinePreparedEvent>[];
    var preparedContributionTouches = 0;
    for (final contribution in contributions) {
      preparedContributionTouches += 1;
      if (contribution.bookedLocalEpochDay != date.epochDay) continue;
      final minutes = contribution.bookedLocalTimeMinutes;
      if (minutes < 0 || minutes >= 24 * 60) continue;
      values[minutes ~/ 60].add(contribution.amountMinor);
      timelineEvents.add(
        _MindDayTimelinePreparedEvent(
          ordinal: contribution.ordinal,
          timeMinutes: minutes,
          total: contribution.amountMinor,
        ),
      );
    }
    return MindDayHeatmapProjection._(
      identity: identity,
      date: date,
      hours: values.map(MindHeatmapAmountRangeBucket.fromUnsorted).toList(),
      timelineEvents: timelineEvents,
      preparedContributionTouches: preparedContributionTouches,
    );
  }

  final MindTemporalHeatmapIdentity identity;
  final LocalDate date;
  final List<MindHeatmapAmountRangeBucket> _hours;
  final List<_MindDayTimelinePreparedEvent> _timelineEvents;
  final int preparedContributionTouches;

  MindDayHeatmapFrame preview(QueryAmountRangeValues range) {
    final totals = _hours
        .map(
          (bucket) => bucket.sumWithin(
            minimum: range.lowerScaled100,
            maximum: range.upperScaled100,
          ),
        )
        .toList(growable: false);
    int? minimum;
    int? maximum;
    var total = 0;
    var activeHours = 0;
    for (final value in totals) {
      if (value == null) continue;
      activeHours += 1;
      total += value;
      minimum = minimum == null || value < minimum ? value : minimum;
      maximum = maximum == null || value > maximum ? value : maximum;
    }
    final timelineEvents =
        _timelineEvents
            .where(
              (event) =>
                  event.total >= range.lowerScaled100 &&
                  event.total <= range.upperScaled100,
            )
            .map(
              (event) => MindDayTimelineEvent(
                ordinal: event.ordinal,
                timeMinutes: event.timeMinutes,
                total: event.total,
              ),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final byTime = left.timeMinutes.compareTo(right.timeMinutes);
            return byTime != 0 ? byTime : left.ordinal.compareTo(right.ordinal);
          });
    final fullTimelineEvents =
        _timelineEvents
            .map(
              (event) => MindDayTimelineEvent(
                ordinal: event.ordinal,
                timeMinutes: event.timeMinutes,
                total: event.total,
              ),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final byTime = left.timeMinutes.compareTo(right.timeMinutes);
            return byTime != 0 ? byTime : left.ordinal.compareTo(right.ordinal);
          });
    return MindDayHeatmapFrame(
      identity: identity,
      range: range,
      date: date,
      hours: List<MindDayHeatmapHour>.generate(24, (hour) {
        final value = totals[hour];
        return MindDayHeatmapHour(
          hour: hour,
          total: value,
          kind: _kindFor(total: value, minimum: minimum, maximum: maximum),
          intensity: _intensityFor(
            total: value,
            minimum: minimum,
            maximum: maximum,
          ),
          paletteIntensity: _paletteIntensityFor(
            total: value,
            minimum: minimum,
            maximum: maximum,
          ),
        );
      }, growable: false),
      timelineEvents: timelineEvents,
      fullTimelineEvents: fullTimelineEvents,
      activeHourCount: activeHours,
      total: total,
      minimumNonEmptyTotal: minimum,
      maximumNonEmptyTotal: maximum,
    );
  }
}

final class _MindDayTimelinePreparedEvent {
  const _MindDayTimelinePreparedEvent({
    required this.ordinal,
    required this.timeMinutes,
    required this.total,
  });

  final int ordinal;
  final int timeMinutes;
  final int total;
}

MindYearHeatmapTileKind _kindFor({
  required int? total,
  required int? minimum,
  required int? maximum,
}) {
  if (total == null) return MindYearHeatmapTileKind.empty;
  if (minimum == maximum) return MindYearHeatmapTileKind.equalRange;
  if (total == minimum) return MindYearHeatmapTileKind.minimum;
  if (total == maximum) return MindYearHeatmapTileKind.maximum;
  return MindYearHeatmapTileKind.interpolated;
}

double _intensityFor({
  required int? total,
  required int? minimum,
  required int? maximum,
}) {
  if (total == null) return 0;
  if (minimum == maximum) return .72;
  return (total - minimum!) / (maximum! - minimum);
}

MindYearHeatmapPaletteIntensity _paletteIntensityFor({
  required int? total,
  required int? minimum,
  required int? maximum,
}) {
  if (total == null) return MindYearHeatmapPaletteIntensity.empty;
  if (minimum == maximum) return MindYearHeatmapPaletteIntensity.equalRange;
  if (total == minimum) return MindYearHeatmapPaletteIntensity.minimum;
  if (total == maximum) return MindYearHeatmapPaletteIntensity.maximum;
  return MindYearHeatmapPaletteIntensity.interpolated;
}

LocalDate _dateForEpochDay(int epochDay) {
  final value = DateTime.utc(1970).add(Duration(days: epochDay));
  return LocalDate(year: value.year, month: value.month, day: value.day);
}
