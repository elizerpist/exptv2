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
  });

  final String upstreamScopeKey;
  final int indexGeneration;
  final int coreRevision;
  final String timeScopeKey;

  @override
  bool operator ==(Object other) =>
      other is MindTemporalHeatmapIdentity &&
      other.upstreamScopeKey == upstreamScopeKey &&
      other.indexGeneration == indexGeneration &&
      other.coreRevision == coreRevision &&
      other.timeScopeKey == timeScopeKey;

  @override
  int get hashCode => Object.hash(
    upstreamScopeKey,
    indexGeneration,
    coreRevision,
    timeScopeKey,
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
    required this.minimumNonEmptyTotal,
    required this.maximumNonEmptyTotal,
  }) : years = List<int>.unmodifiable(years),
       _months = Map<(int year, int month), MindSumHeatmapMonth>.unmodifiable(
         months,
       ),
       _yearTotals = Map<int, int>.unmodifiable(yearTotals);

  @override
  final MindTemporalHeatmapIdentity identity;
  @override
  final QueryAmountRangeValues range;
  final List<int> years;
  final Map<(int year, int month), MindSumHeatmapMonth> _months;
  final Map<int, int> _yearTotals;
  final int? minimumNonEmptyTotal;
  final int? maximumNonEmptyTotal;

  MindSumHeatmapMonth month({required int year, required int month}) =>
      _months[(year, month)]!;

  int yearTotal(int year) => _yearTotals[year] ?? 0;
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
    required this.activeDayCount,
    required this.total,
    required this.minimumNonEmptyTotal,
    required this.maximumNonEmptyTotal,
  }) : days = List<MindYearHeatmapDay>.unmodifiable(days);

  @override
  final MindTemporalHeatmapIdentity identity;
  @override
  final QueryAmountRangeValues range;
  final int year;
  final int month;
  final List<MindYearHeatmapDay> days;
  final int activeDayCount;
  final int total;
  final int? minimumNonEmptyTotal;
  final int? maximumNonEmptyTotal;

  MindYearHeatmapDay day(int value) => days[value - 1];
}

/// Resident month-bucket projection for Sum. Range previews visit only
/// twelve buckets per represented year and use prefix sums inside each bucket.
final class MindSumHeatmapProjection {
  MindSumHeatmapProjection._({
    required this.identity,
    required Map<(int year, int month), MindHeatmapAmountRangeBucket> buckets,
    required List<int> years,
  }) : _buckets =
           Map<
             (int year, int month),
             MindHeatmapAmountRangeBucket
           >.unmodifiable(buckets),
       _years = List<int>.unmodifiable(years);

  factory MindSumHeatmapProjection.build({
    required MindTemporalHeatmapIdentity identity,
    required Iterable<MindYearHeatmapPreparedContribution> contributions,
  }) {
    final values = <(int year, int month), List<int>>{};
    for (final contribution in contributions) {
      final date = _dateForEpochDay(contribution.bookedLocalEpochDay);
      values
          .putIfAbsent((date.year, date.month), () => <int>[])
          .add(contribution.amountMinor);
    }
    final years = values.keys.map((key) => key.$1).toSet().toList()..sort();
    return MindSumHeatmapProjection._(
      identity: identity,
      buckets: values.map(
        (key, value) =>
            MapEntry(key, MindHeatmapAmountRangeBucket.fromUnsorted(value)),
      ),
      years: years,
    );
  }

  final MindTemporalHeatmapIdentity identity;
  final Map<(int year, int month), MindHeatmapAmountRangeBucket> _buckets;
  final List<int> _years;

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
    return MindSumHeatmapFrame(
      identity: identity,
      range: range,
      years: _years,
      months: months,
      yearTotals: yearTotals,
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
  }) : _days = List<MindHeatmapAmountRangeBucket>.unmodifiable(days);

  factory MindMonthHeatmapProjection.build({
    required MindTemporalHeatmapIdentity identity,
    required int year,
    required int month,
    required Iterable<MindYearHeatmapPreparedContribution> contributions,
  }) {
    final count = DateTime.utc(year, month + 1, 0).day;
    final values = List<List<int>>.generate(count, (_) => <int>[]);
    for (final contribution in contributions) {
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
    );
  }

  final MindTemporalHeatmapIdentity identity;
  final int year;
  final int month;
  final List<MindHeatmapAmountRangeBucket> _days;

  MindMonthHeatmapFrame preview(QueryAmountRangeValues range) {
    final totals = _days
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
      activeDayCount: activeDays,
      total: total,
      minimumNonEmptyTotal: minimum,
      maximumNonEmptyTotal: maximum,
    );
  }
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
