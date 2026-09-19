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
  MindSumHeatmapFrame({
    required this.identity,
    required this.range,
    required List<int> years,
    required Map<(int year, int month), MindSumHeatmapMonth> months,
    required Map<int, int> yearTotals,
    required Map<int, List<MindSumHeatmapDailyPoint>> dailyPointsByYear,
    required this.minimumNonEmptyTotal,
    required this.maximumNonEmptyTotal,
  }) : years = List<int>.unmodifiable(years),
       _months = Map<(int year, int month), MindSumHeatmapMonth>.unmodifiable(
         months,
       ),
       _yearTotals = Map<int, int>.unmodifiable(yearTotals),
       _dailyPointsByYear =
           Map<int, List<MindSumHeatmapDailyPoint>>.unmodifiable(
             dailyPointsByYear.map(
               (year, points) => MapEntry(
                 year,
                 List<MindSumHeatmapDailyPoint>.unmodifiable(points),
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
  final Map<int, List<MindSumHeatmapDailyPoint>> _dailyPointsByYear;
  final int? minimumNonEmptyTotal;
  final int? maximumNonEmptyTotal;

  MindSumHeatmapMonth month({required int year, required int month}) =>
      _months[(year, month)]!;

  int yearTotal(int year) => _yearTotals[year] ?? 0;

  /// One exact annual aggregate per continuous represented calendar year.
  /// Internal years without prepared membership deliberately remain zero so the
  /// aggregate chart preserves a truthful temporal domain without inventing
  /// transactions or a second aggregation authority.
  List<MindAggregateLinePoint> get yearlyPoints {
    if (years.isEmpty) return const <MindAggregateLinePoint>[];
    return List<MindAggregateLinePoint>.generate(years.last - years.first + 1, (
      index,
    ) {
      final year = years.first + index;
      return MindAggregateLinePoint(
        ordinal: year,
        label: '$year',
        total: yearTotal(year),
      );
    }, growable: false);
  }

  /// Only real local calendar days with a non-empty current range total are
  /// exposed. The chart may join them visually, but it cannot invent a day.
  List<MindSumHeatmapDailyPoint> dailyPointsForYear(int year) =>
      _dailyPointsByYear[year] ?? const <MindSumHeatmapDailyPoint>[];
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
       _years = List<int>.unmodifiable(years);

  factory MindSumHeatmapProjection.build({
    required MindTemporalHeatmapIdentity identity,
    required Iterable<MindYearHeatmapPreparedContribution> contributions,
  }) {
    final values = <(int year, int month), List<int>>{};
    final dailyValues = <int, Map<int, List<int>>>{};
    var preparedContributionTouches = 0;
    for (final contribution in contributions) {
      preparedContributionTouches += 1;
      final date = _dateForEpochDay(contribution.bookedLocalEpochDay);
      values
          .putIfAbsent((date.year, date.month), () => <int>[])
          .add(contribution.amountMinor);
      dailyValues
          .putIfAbsent(date.year, () => <int, List<int>>{})
          .putIfAbsent(contribution.bookedLocalEpochDay, () => <int>[])
          .add(contribution.amountMinor);
    }
    final years = values.keys.map((key) => key.$1).toSet().toList()..sort();
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
      years: years,
      preparedContributionTouches: preparedContributionTouches,
    );
  }

  final MindTemporalHeatmapIdentity identity;
  final Map<(int year, int month), MindHeatmapAmountRangeBucket> _buckets;
  final Map<int, Map<int, MindHeatmapAmountRangeBucket>> _dailyBuckets;
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
    return MindSumHeatmapFrame(
      identity: identity,
      range: range,
      years: _years,
      months: months,
      yearTotals: yearTotals,
      dailyPointsByYear: dailyPointsByYear,
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
