import 'package:flutter/foundation.dart';

import '../../query/data/dashboard_ledger_entry.dart';
import '../../query/domain/query_amount_range.dart';
import '../../runtime/domain/dashboard_focus_membership_seed.dart';
import '../../time_navigation/domain/local_date.dart';

/// Immutable upstream identity of the one active Mind annual read model.
///
/// The amount range is deliberately absent: a thumb move may only derive a
/// frame from this prepared identity, never rebuild its source membership.
@immutable
final class MindYearHeatmapIdentity {
  const MindYearHeatmapIdentity({
    required this.upstreamScopeKey,
    required this.indexGeneration,
    required this.coreRevision,
    required this.year,
    required this.navigationEpoch,
  });

  final String upstreamScopeKey;
  final int indexGeneration;
  final int coreRevision;
  final int year;
  final int navigationEpoch;

  @override
  bool operator ==(Object other) =>
      other is MindYearHeatmapIdentity &&
      other.upstreamScopeKey == upstreamScopeKey &&
      other.indexGeneration == indexGeneration &&
      other.coreRevision == coreRevision &&
      other.year == year &&
      other.navigationEpoch == navigationEpoch;

  @override
  int get hashCode => Object.hash(
    upstreamScopeKey,
    indexGeneration,
    coreRevision,
    year,
    navigationEpoch,
  );
}

/// Test/profile accounting for the projection's explicitly bounded hot path.
///
/// Production does not need a repository hook because the projection has no
/// repository capability. These values make the no-source-row contract
/// executable rather than an assertion based on callback counts.
final class MindYearHeatmapSourceWorkCounter {
  MindYearHeatmapSourceWorkCounter({
    this.measurePreviewDurations = false,
    this.previewDurationCapacity = 64,
  }) : _previewDurations = List<int>.filled(
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

  /// Disabled in standard builds, so the pointer hot path starts no timer.
  /// Profile builds retain only this fixed-size ring for p50/p95/max evidence.
  final bool measurePreviewDurations;
  final int previewDurationCapacity;
  final List<int> _previewDurations;
  int _previewDurationCount = 0;
  int _previewDurationNext = 0;
  int sourceRowTouches = 0;
  int preparedContributionTouches = 0;
  int sourceRowTouchesDuringPreview = 0;
  int repositoryAccessesDuringPreview = 0;
  int indexBuildsDuringPreview = 0;
  int maxDayBucketsVisitedPerPreview = 0;

  void recordSourceRowTouch() {
    sourceRowTouches += 1;
  }

  void recordPreparedContributionTouch() {
    preparedContributionTouches += 1;
  }

  void recordPreviewDayBucket() {
    sourceRowTouchesDuringPreview += 0;
  }

  void finishPreview({required int dayBucketsVisited}) {
    if (dayBucketsVisited > maxDayBucketsVisitedPerPreview) {
      maxDayBucketsVisitedPerPreview = dayBucketsVisited;
    }
  }

  void recordPreviewDuration(int micros) {
    if (!measurePreviewDurations) return;
    _previewDurations[_previewDurationNext] = micros;
    _previewDurationNext = (_previewDurationNext + 1) % previewDurationCapacity;
    if (_previewDurationCount < previewDurationCapacity) {
      _previewDurationCount += 1;
    }
  }

  /// Snapshot-only measurement; callers invoke it after a drag, never from
  /// the rendering callback itself.
  Map<String, int> previewDurationSummary() {
    if (_previewDurationCount == 0) {
      return const <String, int>{
        'sampleCount': 0,
        'p50Micros': 0,
        'p95Micros': 0,
        'maxMicros': 0,
      };
    }
    final values = List<int>.generate(
      _previewDurationCount,
      (index) => _previewDurations[index],
      growable: false,
    )..sort();
    int percentile(double fraction) =>
        values[((values.length - 1) * fraction)
            .ceil()
            .clamp(0, values.length - 1)
            .toInt()];
    return <String, int>{
      'sampleCount': values.length,
      'p50Micros': percentile(.50),
      'p95Micros': percentile(.95),
      'maxMicros': values.last,
    };
  }
}

/// Immutable, base-lifetime annual contributions for Mind's transient Year
/// publication. The Core owns its bounded retention alongside the prepared
/// base; this domain value owns only the year/ordinal/amount lookup shape.
///
/// Building this value is allowed only while the underlying prepared base is
/// registered. A Summary Time tick reads the selected year's compact
/// contributions and never revisits a [DashboardLedgerEntry].
@immutable
final class MindYearHeatmapPreparedMembership {
  const MindYearHeatmapPreparedMembership._(this._contributionsByYear);

  factory MindYearHeatmapPreparedMembership.fromEntries(
    List<DashboardLedgerEntry> entries,
  ) {
    final mutable = <int, List<MindYearHeatmapPreparedContribution>>{};
    for (var ordinal = 0; ordinal < entries.length; ordinal += 1) {
      final entry = entries[ordinal];
      final date = DateTime.utc(
        1970,
      ).add(Duration(days: entry.bookedLocalEpochDay));
      mutable
          .putIfAbsent(date.year, () => <MindYearHeatmapPreparedContribution>[])
          .add(
            MindYearHeatmapPreparedContribution(
              ordinal: ordinal,
              bookedLocalEpochDay: entry.bookedLocalEpochDay,
              amountMinor: entry.amountMinor,
            ),
          );
    }
    return MindYearHeatmapPreparedMembership._(
      Map<int, List<MindYearHeatmapPreparedContribution>>.unmodifiable(
        mutable.map(
          (year, values) =>
              MapEntry<int, List<MindYearHeatmapPreparedContribution>>(
                year,
                List<MindYearHeatmapPreparedContribution>.unmodifiable(values),
              ),
        ),
      ),
    );
  }

  final Map<int, List<MindYearHeatmapPreparedContribution>>
  _contributionsByYear;

  int get contributionCount => _contributionsByYear.values.fold<int>(
    0,
    (sum, values) => sum + values.length,
  );

  Iterable<MindYearHeatmapPreparedContribution> contributionsForYear({
    required int year,
    required DashboardFocusOrdinalSet membership,
  }) sync* {
    for (final contribution
        in _contributionsByYear[year] ??
            const <MindYearHeatmapPreparedContribution>[]) {
      if (membership.containsOrdinal(contribution.ordinal)) {
        yield contribution;
      }
    }
  }

  /// Reuses the exact admitted prepared membership for another Mind consumer.
  /// The caller still owns its own projection/score semantics; this method
  /// does not create a second filter authority or revisit ledger rows.
  Iterable<MindYearHeatmapPreparedContribution> contributionsForMembership({
    required DashboardFocusOrdinalSet membership,
  }) sync* {
    for (final contributions in _contributionsByYear.values) {
      for (final contribution in contributions) {
        if (membership.containsOrdinal(contribution.ordinal)) {
          yield contribution;
        }
      }
    }
  }
}

@immutable
final class MindYearHeatmapPreparedContribution {
  const MindYearHeatmapPreparedContribution({
    required this.ordinal,
    required this.bookedLocalEpochDay,
    required this.amountMinor,
  });

  final int ordinal;
  final int bookedLocalEpochDay;
  final int amountMinor;
}

/// Rendering categories are named so a zero-normalized non-empty tile cannot
/// accidentally share the empty-day color.
enum MindYearHeatmapTileKind {
  empty,
  minimum,
  interpolated,
  maximum,
  equalRange,
}

/// Palette decisions passed to the Mind renderer; no heuristic intensity is
/// inferred for an equal-valued annual data set.
enum MindYearHeatmapPaletteIntensity {
  empty,
  minimum,
  interpolated,
  maximum,
  equalRange,
}

@immutable
final class MindYearHeatmapDay {
  const MindYearHeatmapDay({
    required this.date,
    required this.total,
    required this.kind,
    required this.intensity,
    required this.paletteIntensity,
  });

  final LocalDate date;
  final int? total;
  final MindYearHeatmapTileKind kind;

  /// Numeric global normalization for deterministic paint interpolation.
  final double intensity;
  final MindYearHeatmapPaletteIntensity paletteIntensity;

  bool get isEmpty => total == null;
}

@immutable
final class MindYearHeatmapFrame {
  factory MindYearHeatmapFrame({
    required MindYearHeatmapIdentity identity,
    required QueryAmountRangeValues range,
    required List<MindYearHeatmapDay> days,
    required List<List<MindYearHeatmapDay>> months,
    required int? minimumNonEmptyTotal,
    required int? maximumNonEmptyTotal,
  }) => MindYearHeatmapFrame._(
    identity: identity,
    range: range,
    days: List<MindYearHeatmapDay>.unmodifiable(days),
    months: List<List<MindYearHeatmapDay>>.unmodifiable(
      months.map(List<MindYearHeatmapDay>.unmodifiable),
    ),
    minimumNonEmptyTotal: minimumNonEmptyTotal,
    maximumNonEmptyTotal: maximumNonEmptyTotal,
  );

  const MindYearHeatmapFrame._({
    required this.identity,
    required this.range,
    required this.days,
    required List<List<MindYearHeatmapDay>> months,
    required this.minimumNonEmptyTotal,
    required this.maximumNonEmptyTotal,
  }) : _months = months;

  final MindYearHeatmapIdentity identity;
  final QueryAmountRangeValues range;
  final List<MindYearHeatmapDay> days;
  final List<List<MindYearHeatmapDay>> _months;
  final int? minimumNonEmptyTotal;
  final int? maximumNonEmptyTotal;

  List<MindYearHeatmapDay> month(int month) {
    if (month < 1 || month > 12) throw RangeError.range(month, 1, 12);
    return _months[month - 1];
  }

  MindYearHeatmapDay dayFor(LocalDate date) {
    if (date.year != identity.year) throw ArgumentError.value(date, 'date');
    final offset =
        date.epochDay -
        LocalDate(year: identity.year, month: 1, day: 1).epochDay;
    if (offset < 0 || offset >= days.length) {
      throw ArgumentError.value(date, 'date');
    }
    final day = days[offset];
    if (day.date != date) throw ArgumentError.value(date, 'date');
    return day;
  }
}

/// Active-year, source-row-free range projection.
///
/// Construction visits resident prepared source rows exactly once. Each local
/// day then retains sorted amount contributions and prefix sums. A slider tick
/// therefore touches only the fixed 365/366 day domain and binary-searches
/// each day-local immutable range index; it never walks a ledger row.
@immutable
final class MindYearHeatmapProjection {
  const MindYearHeatmapProjection._(
    this.identity,
    this._days,
    this._startEpochDay,
    this._workCounter,
  );

  factory MindYearHeatmapProjection.build({
    required MindYearHeatmapIdentity identity,
    required Iterable<DashboardLedgerEntry> entries,
    MindYearHeatmapSourceWorkCounter? sourceWorkCounter,
  }) {
    final counter = sourceWorkCounter ?? MindYearHeatmapSourceWorkCounter();
    return _buildFromContributions(
      identity: identity,
      sourceWorkCounter: counter,
      contributions: entries.map((entry) {
        counter.recordSourceRowTouch();
        return MindYearHeatmapPreparedContribution(
          ordinal: -1,
          bookedLocalEpochDay: entry.bookedLocalEpochDay,
          amountMinor: entry.amountMinor,
        );
      }),
    );
  }

  factory MindYearHeatmapProjection.buildFromPreparedContributions({
    required MindYearHeatmapIdentity identity,
    required Iterable<MindYearHeatmapPreparedContribution> contributions,
    MindYearHeatmapSourceWorkCounter? sourceWorkCounter,
  }) {
    final counter = sourceWorkCounter ?? MindYearHeatmapSourceWorkCounter();
    return _buildFromContributions(
      identity: identity,
      sourceWorkCounter: counter,
      contributions: contributions.map((contribution) {
        counter.recordPreparedContributionTouch();
        return contribution;
      }),
    );
  }

  static MindYearHeatmapProjection _buildFromContributions({
    required MindYearHeatmapIdentity identity,
    required Iterable<MindYearHeatmapPreparedContribution> contributions,
    required MindYearHeatmapSourceWorkCounter sourceWorkCounter,
  }) {
    final start = LocalDate(year: identity.year, month: 1, day: 1).epochDay;
    final end = LocalDate(year: identity.year + 1, month: 1, day: 1).epochDay;
    final perDay = List<List<int>>.generate(
      end - start,
      (_) => <int>[],
      growable: false,
    );
    for (final contribution in contributions) {
      final offset = contribution.bookedLocalEpochDay - start;
      if (offset < 0 || contribution.bookedLocalEpochDay >= end) continue;
      // QueryAmountRange and the resident membership index compare this exact
      // stored amount field. Keep the same signed/absolute semantics here.
      perDay[offset].add(contribution.amountMinor);
    }
    return MindYearHeatmapProjection._(
      identity,
      List<_MindYearHeatmapDayRange>.unmodifiable(
        perDay.map(_MindYearHeatmapDayRange.fromUnsorted),
      ),
      start,
      sourceWorkCounter,
    );
  }

  final MindYearHeatmapIdentity identity;
  final List<_MindYearHeatmapDayRange> _days;
  final int _startEpochDay;
  final MindYearHeatmapSourceWorkCounter _workCounter;

  int get dayCount => _days.length;
  MindYearHeatmapSourceWorkCounter get sourceWorkCounter => _workCounter;

  MindYearHeatmapFrame preview(QueryAmountRangeValues range) {
    final stopwatch = _workCounter.measurePreviewDurations
        ? (Stopwatch()..start())
        : null;
    final totals = List<int?>.filled(_days.length, null, growable: false);
    int? minimum;
    int? maximum;
    var visited = 0;
    for (var index = 0; index < _days.length; index += 1) {
      visited += 1;
      _workCounter.recordPreviewDayBucket();
      final total = _days[index].sumWithin(
        minimum: range.lowerScaled100,
        maximum: range.upperScaled100,
      );
      totals[index] = total;
      if (total == null) continue;
      minimum = minimum == null || total < minimum ? total : minimum;
      maximum = maximum == null || total > maximum ? total : maximum;
    }
    _workCounter.finishPreview(dayBucketsVisited: visited);

    final result = List<MindYearHeatmapDay>.generate(_days.length, (index) {
      final total = totals[index];
      final date = _localDateAt(index);
      if (total == null) {
        return MindYearHeatmapDay(
          date: date,
          total: null,
          kind: MindYearHeatmapTileKind.empty,
          intensity: 0,
          paletteIntensity: MindYearHeatmapPaletteIntensity.empty,
        );
      }
      if (minimum == maximum) {
        return MindYearHeatmapDay(
          date: date,
          total: total,
          kind: MindYearHeatmapTileKind.equalRange,
          intensity: .72,
          paletteIntensity: MindYearHeatmapPaletteIntensity.equalRange,
        );
      }
      final normalized = (total - minimum!) / (maximum! - minimum);
      if (normalized <= 0) {
        return MindYearHeatmapDay(
          date: date,
          total: total,
          kind: MindYearHeatmapTileKind.minimum,
          intensity: 0,
          paletteIntensity: MindYearHeatmapPaletteIntensity.minimum,
        );
      }
      if (normalized >= 1) {
        return MindYearHeatmapDay(
          date: date,
          total: total,
          kind: MindYearHeatmapTileKind.maximum,
          intensity: 1,
          paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        );
      }
      return MindYearHeatmapDay(
        date: date,
        total: total,
        kind: MindYearHeatmapTileKind.interpolated,
        intensity: normalized,
        paletteIntensity: MindYearHeatmapPaletteIntensity.interpolated,
      );
    }, growable: false);
    final months = List<List<MindYearHeatmapDay>>.generate(
      12,
      (_) => <MindYearHeatmapDay>[],
      growable: false,
    );
    for (final day in result) {
      months[day.date.month - 1].add(day);
    }
    final frame = MindYearHeatmapFrame(
      identity: identity,
      range: range,
      days: List<MindYearHeatmapDay>.unmodifiable(result),
      months: months,
      minimumNonEmptyTotal: minimum,
      maximumNonEmptyTotal: maximum,
    );
    if (stopwatch != null) {
      stopwatch.stop();
      _workCounter.recordPreviewDuration(stopwatch.elapsedMicroseconds);
    }
    return frame;
  }

  LocalDate _localDateAt(int offset) {
    final value = DateTime.utc(
      1970,
    ).add(Duration(days: _startEpochDay + offset));
    return LocalDate(year: value.year, month: value.month, day: value.day);
  }
}

@immutable
final class _MindYearHeatmapDayRange {
  const _MindYearHeatmapDayRange._(this._values, this._prefixSums);

  factory _MindYearHeatmapDayRange.fromUnsorted(List<int> values) {
    if (values.isEmpty) return _MindYearHeatmapDayRange._empty;
    final sorted = List<int>.of(values)..sort();
    final prefix = List<int>.filled(sorted.length + 1, 0, growable: false);
    for (var index = 0; index < sorted.length; index += 1) {
      prefix[index + 1] = prefix[index] + sorted[index];
    }
    return _MindYearHeatmapDayRange._(
      List<int>.unmodifiable(sorted),
      List<int>.unmodifiable(prefix),
    );
  }

  static final _MindYearHeatmapDayRange _empty = _MindYearHeatmapDayRange._(
    const <int>[],
    const <int>[0],
  );

  final List<int> _values;
  final List<int> _prefixSums;

  int? sumWithin({required int minimum, required int maximum}) {
    if (_values.isEmpty || minimum > maximum) return null;
    final start = _lowerBound(minimum);
    final end = _upperBound(maximum);
    if (start == end) return null;
    return _prefixSums[end] - _prefixSums[start];
  }

  int _lowerBound(int value) {
    var low = 0;
    var high = _values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (_values[middle] < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  int _upperBound(int value) {
    var low = 0;
    var high = _values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (_values[middle] <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}
