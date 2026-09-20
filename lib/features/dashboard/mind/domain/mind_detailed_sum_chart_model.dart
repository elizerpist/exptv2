import 'dart:math' as math;

import '../../time_navigation/domain/local_date.dart';
import 'mind_temporal_heatmap_projection.dart';
import 'mind_year_heatmap_presentation_settings.dart';

const _minutesPerDay = 24 * 60;

/// One shared layout calculation for the two Sum annual-band chart renderers.
/// It owns presentation density only: every year stays in the ListView and
/// the current immutable financial frame remains untouched.
final class MindSumChartDensityGeometry {
  const MindSumChartDensityGeometry._({
    required this.bandHeight,
    required this.visibleBandCount,
    required this.interBandGap,
  });

  static const defaultInterBandGap = 8.0;

  final double bandHeight;
  final int visibleBandCount;
  final double interBandGap;

  static MindSumChartDensityGeometry resolve({
    required double availableHeight,
    required int yearCount,
    required MindSumVisibleChartCount preference,
  }) {
    final visibleBandCount = yearCount <= 0
        ? 1
        : math.min(
            yearCount,
            preference == MindSumVisibleChartCount.one ? 1 : 2,
          );
    final safeHeight = math.max(1.0, availableHeight);
    final totalGap = defaultInterBandGap * math.max(0, visibleBandCount - 1);
    return MindSumChartDensityGeometry._(
      bandHeight: math.max(1.0, (safeHeight - totalGap) / visibleBandCount),
      visibleBandCount: visibleBandCount,
      interBandGap: defaultInterBandGap,
    );
  }
}

/// The detailed chart owns a compact annual overview but can use the shared
/// Hungarian full month labels once zoom and real label slots make them
/// readable. This is presentation geometry only; it never changes separators
/// or the temporal viewport.
enum MindDetailedSumAxisLabelDensity {
  initials,
  fullNames;

  static const _minimumFullNameSlotWidth = 44.0;
  static const _maximumFullNameSpanDays = 184;

  static MindDetailedSumAxisLabelDensity forWindow({
    required int year,
    required MindDetailedSumTimeWindow window,
    required double availableWidth,
  }) {
    if (window.visibleDayCount > _maximumFullNameSpanDays ||
        !availableWidth.isFinite ||
        availableWidth <= 0) {
      return MindDetailedSumAxisLabelDensity.initials;
    }
    final visibleMonthStarts = List<int>.generate(12, (index) => index + 1)
        .where((month) {
          final epochDay = LocalDate(year: year, month: month, day: 1).epochDay;
          return epochDay >= window.startEpochDay &&
              epochDay <= window.endEpochDay;
        })
        .length;
    if (visibleMonthStarts <= 1) {
      return MindDetailedSumAxisLabelDensity.fullNames;
    }
    final slotWidth = availableWidth / (visibleMonthStarts - 1);
    return slotWidth >= _minimumFullNameSlotWidth
        ? MindDetailedSumAxisLabelDensity.fullNames
        : MindDetailedSumAxisLabelDensity.initials;
  }
}

/// Paint-only weighted smoothing for detailed Sum curve anchors. It never
/// enters hit testing, filtering, totals or the immutable financial frame.
/// Local extrema are retained verbatim so a spike cannot disappear merely
/// because a user selected a softer presentation.
final class MindDetailedSumVisualSmoothing {
  const MindDetailedSumVisualSmoothing._();

  static List<MindSumHeatmapDetailPoint> apply({
    required List<MindSumHeatmapDetailPoint> points,
    required MindSumSmoothingWindow window,
    required double strength,
  }) {
    final normalizedStrength = strength.clamp(0.0, 1.0).toDouble();
    if (points.length < 3 || normalizedStrength <= 0) return points;
    final ordered = List<MindSumHeatmapDetailPoint>.of(points)
      ..sort(_comparePoint);
    final radiusMinutes = window.dayCount * _minutesPerDay ~/ 2;
    final result = List<MindSumHeatmapDetailPoint>.generate(ordered.length, (
      index,
    ) {
      if (index == 0 || index == ordered.length - 1) return ordered[index];
      final current = ordered[index];
      final before = ordered[index - 1];
      final after = ordered[index + 1];
      final isExtremum =
          (current.total >= before.total && current.total >= after.total) ||
          (current.total <= before.total && current.total <= after.total);
      if (isExtremum) return current;

      var weightedTotal = 0.0;
      var totalWeight = 0.0;
      for (final neighbour in ordered) {
        final distance = (neighbour.epochMinute - current.epochMinute).abs();
        if (distance > radiusMinutes) continue;
        // Triangular temporal weights favour the real anchor under the curve
        // and taper continuously to the configured window edge.
        final weight = 1 - distance / (radiusMinutes + 1);
        weightedTotal += neighbour.total * weight;
        totalWeight += weight;
      }
      if (totalWeight <= 0) return current;
      final weighted = (weightedTotal / totalWeight).round();
      final blended =
          (current.total * (1 - normalizedStrength) +
                  weighted * normalizedStrength)
              .round();
      return MindSumHeatmapDetailPoint(
        epochMinute: current.epochMinute,
        total: blended,
        ordinal: current.ordinal,
      );
    }, growable: false);
    return List<MindSumHeatmapDetailPoint>.unmodifiable(result);
  }

  static int _comparePoint(
    MindSumHeatmapDetailPoint left,
    MindSumHeatmapDetailPoint right,
  ) {
    final byTime = left.epochMinute.compareTo(right.epochMinute);
    return byTime != 0
        ? byTime
        : (left.ordinal ?? -1).compareTo(right.ordinal ?? -1);
  }
}

/// An immutable visible minute interval inside one calendar year's detailed
/// Sum chart. The home domain is always January through December; pinch zoom
/// narrows real temporal extent rather than scaling a rendered bitmap.
final class MindDetailedSumTimeWindow {
  const MindDetailedSumTimeWindow._({
    required this.homeStartEpochMinute,
    required this.homeEndEpochMinute,
    required this.startEpochMinute,
    required this.endEpochMinute,
  });

  factory MindDetailedSumTimeWindow.fullYear(int year) {
    final firstDay = LocalDate(year: year, month: 1, day: 1).epochDay;
    final lastDay = LocalDate(year: year, month: 12, day: 31).epochDay;
    return MindDetailedSumTimeWindow._(
      homeStartEpochMinute: firstDay * _minutesPerDay,
      homeEndEpochMinute: lastDay * _minutesPerDay + _minutesPerDay - 1,
      startEpochMinute: firstDay * _minutesPerDay,
      endEpochMinute: lastDay * _minutesPerDay + _minutesPerDay - 1,
    );
  }

  final int homeStartEpochMinute;
  final int homeEndEpochMinute;
  final int startEpochMinute;
  final int endEpochMinute;

  int get homeStartEpochDay => homeStartEpochMinute ~/ _minutesPerDay;
  int get homeEndEpochDay => homeEndEpochMinute ~/ _minutesPerDay;
  int get startEpochDay => startEpochMinute ~/ _minutesPerDay;
  int get endEpochDay => endEpochMinute ~/ _minutesPerDay;
  int get visibleMinuteCount => endEpochMinute - startEpochMinute + 1;
  int get homeMinuteCount => homeEndEpochMinute - homeStartEpochMinute + 1;
  int get visibleDayCount => (visibleMinuteCount / _minutesPerDay).ceil();
  int get homeDayCount => (homeMinuteCount / _minutesPerDay).ceil();

  double normalizedPositionOf(int epochDay) => normalizedPositionOfEpochMinute(
    epochDay * _minutesPerDay + _minutesPerDay ~/ 2,
  );

  double normalizedPositionOfEpochMinute(int epochMinute) {
    if (visibleMinuteCount <= 1) return .5;
    return ((epochMinute - startEpochMinute) / (visibleMinuteCount - 1))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// Compatibility entry point for calendar-day tests and callers. The chart
  /// itself uses [zoomAtMinute] so a pinch focal point preserves time within a
  /// day as detail becomes available.
  MindDetailedSumTimeWindow zoom({
    required double scaleDelta,
    required int focalEpochDay,
  }) => zoomAtMinute(
    scaleDelta: scaleDelta,
    focalEpochMinute: focalEpochDay * _minutesPerDay + _minutesPerDay ~/ 2,
  );

  MindDetailedSumTimeWindow zoomAtMinute({
    required double scaleDelta,
    required int focalEpochMinute,
  }) {
    if (!scaleDelta.isFinite || scaleDelta <= 0) return this;
    final requested = (visibleMinuteCount / scaleDelta).round();
    final nextCount = requested.clamp(1, homeMinuteCount);
    if (nextCount == visibleMinuteCount) return this;
    final focalFraction = normalizedPositionOfEpochMinute(focalEpochMinute);
    final proposedStart = (focalEpochMinute - focalFraction * (nextCount - 1))
        .round();
    final latestStart = homeEndEpochMinute - nextCount + 1;
    final nextStart = proposedStart
        .clamp(homeStartEpochMinute, latestStart)
        .toInt();
    return MindDetailedSumTimeWindow._(
      homeStartEpochMinute: homeStartEpochMinute,
      homeEndEpochMinute: homeEndEpochMinute,
      startEpochMinute: nextStart,
      endEpochMinute: nextStart + nextCount - 1,
    );
  }

  /// Converts Flutter's relatively conservative cumulative pinch scale into
  /// the chart's temporal zoom response. The exponent preserves analog input
  /// and focal-time math, while making a normal physical pinch materially
  /// narrow the full-year domain instead of merely changing it by a few days.
  MindDetailedSumTimeWindow zoomForGesture({
    required double scaleDelta,
    required int focalEpochMinute,
  }) {
    if (!scaleDelta.isFinite || scaleDelta <= 0) return this;
    const gestureZoomExponent = 3.2;
    return zoomAtMinute(
      scaleDelta: math.pow(scaleDelta, gestureZoomExponent).toDouble(),
      focalEpochMinute: focalEpochMinute,
    );
  }

  MindDetailedSumTimeWindow panByDays(int days) =>
      panByMinutes(days * _minutesPerDay);

  MindDetailedSumTimeWindow panByMinutes(int minutes) {
    if (minutes == 0 || visibleMinuteCount >= homeMinuteCount) return this;
    final latestStart = homeEndEpochMinute - visibleMinuteCount + 1;
    final nextStart = (startEpochMinute + minutes)
        .clamp(homeStartEpochMinute, latestStart)
        .toInt();
    if (nextStart == startEpochMinute) return this;
    return MindDetailedSumTimeWindow._(
      homeStartEpochMinute: homeStartEpochMinute,
      homeEndEpochMinute: homeEndEpochMinute,
      startEpochMinute: nextStart,
      endEpochMinute: nextStart + visibleMinuteCount - 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MindDetailedSumTimeWindow &&
      other.homeStartEpochMinute == homeStartEpochMinute &&
      other.homeEndEpochMinute == homeEndEpochMinute &&
      other.startEpochMinute == startEpochMinute &&
      other.endEpochMinute == endEpochMinute;

  @override
  int get hashCode => Object.hash(
    homeStartEpochMinute,
    homeEndEpochMinute,
    startEpochMinute,
    endEpochMinute,
  );
}

/// One normalized viewport for every annual band in the detailed Sum chart.
///
/// It deliberately stores a fraction of a calendar year rather than an epoch
/// interval. Each band can therefore project the exact same visible temporal
/// portion onto its own leap/non-leap year without creating one gesture state
/// machine per band.
final class MindDetailedSumNormalizedViewport {
  const MindDetailedSumNormalizedViewport._({
    required this.startFraction,
    required this.visibleFraction,
  });

  const MindDetailedSumNormalizedViewport.fullYear()
    : startFraction = 0,
      visibleFraction = 1;

  final double startFraction;
  final double visibleFraction;

  bool get isZoomed => visibleFraction < 1;

  MindDetailedSumTimeWindow windowForYear(int year) {
    final home = MindDetailedSumTimeWindow.fullYear(year);
    final visibleCount = (home.homeMinuteCount * visibleFraction)
        .round()
        .clamp(1, home.homeMinuteCount)
        .toInt();
    final remaining = home.homeMinuteCount - visibleCount;
    // [startFraction] is measured against the whole year, matching the
    // focal-point zoom calculation below; it is not a fraction of the
    // remaining post-zoom travel.  Using the latter shifts the date under a
    // centred pinch toward the start of the year.
    final start =
        home.homeStartEpochMinute +
        (home.homeMinuteCount * startFraction)
            .round()
            .clamp(0, remaining)
            .toInt();
    return MindDetailedSumTimeWindow._(
      homeStartEpochMinute: home.homeStartEpochMinute,
      homeEndEpochMinute: home.homeEndEpochMinute,
      startEpochMinute: start,
      endEpochMinute: start + visibleCount - 1,
    );
  }

  /// Applies a continuous physical scale around [focalFraction] while keeping
  /// the same normalized calendar location under the user's fingers.
  MindDetailedSumNormalizedViewport zoomForGesture({
    required double scaleDelta,
    required double focalFraction,
  }) {
    if (!scaleDelta.isFinite || scaleDelta <= 0) return this;
    const gestureZoomExponent = 3.2;
    final effectiveScale = math.pow(scaleDelta, gestureZoomExponent).toDouble();
    final nextVisible = (visibleFraction / effectiveScale)
        .clamp(1 / (366 * _minutesPerDay), 1.0)
        .toDouble();
    if ((nextVisible - visibleFraction).abs() < 1e-9) return this;
    final focal =
        startFraction + focalFraction.clamp(0.0, 1.0) * visibleFraction;
    final requestedStart = focal - focalFraction.clamp(0.0, 1.0) * nextVisible;
    final nextStart = requestedStart
        .clamp(0.0, math.max(0.0, 1.0 - nextVisible))
        .toDouble();
    return MindDetailedSumNormalizedViewport._(
      startFraction: nextStart,
      visibleFraction: nextVisible,
    );
  }

  MindDetailedSumNormalizedViewport panByFraction(double delta) {
    if (!isZoomed || delta == 0) return this;
    final nextStart = (startFraction + delta)
        .clamp(0.0, math.max(0.0, 1.0 - visibleFraction))
        .toDouble();
    if (nextStart == startFraction) return this;
    return MindDetailedSumNormalizedViewport._(
      startFraction: nextStart,
      visibleFraction: visibleFraction,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MindDetailedSumNormalizedViewport &&
      other.startFraction == startFraction &&
      other.visibleFraction == visibleFraction;

  @override
  int get hashCode => Object.hash(startFraction, visibleFraction);
}

/// A source-only LOD sampler. Overview density uses a readable spatial budget
/// instead of one bin per logical pixel. As visible time narrows the budget
/// rises continuously; at a one-day-or-less window every supplied prepared
/// transaction remains individually representable.
final class MindDetailedSumLodSelection {
  const MindDetailedSumLodSelection({
    required this.inspectablePoints,
    required this.paintPoints,
    required this.bucketSpanMinutes,
    required this.hasLeftPaintContinuation,
    required this.hasRightPaintContinuation,
  });

  /// Real selected anchors inside the visible domain. These are the only
  /// anchors that tap inspection may choose.
  final List<MindSumHeatmapDetailPoint> inspectablePoints;

  /// [inspectablePoints] plus at most one real source neighbour on each side
  /// when a visible path needs clipping continuity at the plot boundary.
  final List<MindSumHeatmapDetailPoint> paintPoints;
  final int bucketSpanMinutes;
  final bool hasLeftPaintContinuation;
  final bool hasRightPaintContinuation;
}

final class MindDetailedSumLod {
  const MindDetailedSumLod._();

  /// The caller supplies the current domain plus one bucket on either side.
  /// That bounded overlap lets a pan keep an interior bucket's extrema stable
  /// without rebuilding a whole financial history for every pointer update.
  static int sourcePaddingMinutes({
    required MindDetailedSumTimeWindow window,
    required double pixelWidth,
  }) => _bucketSpanMinutes(window: window, pixelWidth: pixelWidth);

  static List<MindSumHeatmapDetailPoint> sample({
    required List<MindSumHeatmapDetailPoint> points,
    required MindDetailedSumTimeWindow window,
    required double pixelWidth,
  }) => select(
    points: points,
    window: window,
    pixelWidth: pixelWidth,
  ).inspectablePoints;

  /// Resolves the truthful selectable LOD anchors and the separate clipped
  /// paint context. The latter prevents a real segment just outside the
  /// viewport from disappearing at a crop edge while keeping that outside
  /// source observation unavailable to tap inspection.
  static MindDetailedSumLodSelection select({
    required List<MindSumHeatmapDetailPoint> points,
    required MindDetailedSumTimeWindow window,
    required double pixelWidth,
  }) {
    final ordered = _ordered(points);
    final visible = ordered
        .where(
          (point) =>
              point.epochMinute >= window.startEpochMinute &&
              point.epochMinute <= window.endEpochMinute,
        )
        .toList(growable: false);
    final bucketSpan = _bucketSpanMinutes(
      window: window,
      pixelWidth: pixelWidth,
    );
    final inspectable = <MindSumHeatmapDetailPoint>[];
    if (visible.length <= 2 || window.visibleMinuteCount <= _minutesPerDay) {
      inspectable.addAll(visible);
    } else {
      final binCount = _visibleBinCount(window: window, pixelWidth: pixelWidth);
      if (visible.length <= binCount) {
        inspectable.addAll(visible);
      } else {
        final selectedIndices = <int>{};
        final buckets = <int, List<int>>{};
        // Deliberately anchor the grid at the calendar-year home domain,
        // never at the current viewport edge. At fixed zoom an overlapping
        // interval is therefore sampled by the same immutable buckets after a
        // horizontal pan.
        final paddedStart = window.startEpochMinute - bucketSpan;
        final paddedEnd = window.endEpochMinute + bucketSpan;
        for (var index = 0; index < ordered.length; index += 1) {
          final point = ordered[index];
          if (point.epochMinute < paddedStart ||
              point.epochMinute > paddedEnd) {
            continue;
          }
          final bucket =
              ((point.epochMinute - window.homeStartEpochMinute) / bucketSpan)
                  .floor();
          buckets.putIfAbsent(bucket, () => <int>[]).add(index);
        }
        for (final indices in buckets.values) {
          selectedIndices.add(indices.first);
          selectedIndices.add(indices.last);
          var minimum = indices.first;
          var maximum = indices.first;
          for (final index in indices.skip(1)) {
            if (ordered[index].total < ordered[minimum].total) minimum = index;
            if (ordered[index].total > ordered[maximum].total) maximum = index;
          }
          selectedIndices
            ..add(minimum)
            ..add(maximum);
        }
        inspectable.addAll(
          selectedIndices
              .map((index) => ordered[index])
              .where(
                (point) =>
                    point.epochMinute >= window.startEpochMinute &&
                    point.epochMinute <= window.endEpochMinute,
              ),
        );
        inspectable.sort(_comparePoints);
      }
    }

    final before = inspectable.isEmpty
        ? null
        : _nearestBefore(ordered, window.startEpochMinute);
    final after = inspectable.isEmpty
        ? null
        : _nearestAfter(ordered, window.endEpochMinute);
    final paint = <MindSumHeatmapDetailPoint>[?before, ...inspectable, ?after];
    return MindDetailedSumLodSelection(
      inspectablePoints: List<MindSumHeatmapDetailPoint>.unmodifiable(
        inspectable,
      ),
      paintPoints: List<MindSumHeatmapDetailPoint>.unmodifiable(paint),
      bucketSpanMinutes: bucketSpan,
      hasLeftPaintContinuation: before != null,
      hasRightPaintContinuation: after != null,
    );
  }

  static List<MindSumHeatmapDetailPoint> _ordered(
    List<MindSumHeatmapDetailPoint> points,
  ) => List<MindSumHeatmapDetailPoint>.of(points)..sort(_comparePoints);

  static int _comparePoints(
    MindSumHeatmapDetailPoint left,
    MindSumHeatmapDetailPoint right,
  ) {
    final byTime = left.epochMinute.compareTo(right.epochMinute);
    return byTime != 0
        ? byTime
        : (left.ordinal ?? -1).compareTo(right.ordinal ?? -1);
  }

  static MindSumHeatmapDetailPoint? _nearestBefore(
    List<MindSumHeatmapDetailPoint> ordered,
    int exclusiveMinute,
  ) {
    for (var index = ordered.length - 1; index >= 0; index -= 1) {
      final point = ordered[index];
      if (point.epochMinute < exclusiveMinute) return point;
    }
    return null;
  }

  static MindSumHeatmapDetailPoint? _nearestAfter(
    List<MindSumHeatmapDetailPoint> ordered,
    int exclusiveMinute,
  ) {
    for (final point in ordered) {
      if (point.epochMinute > exclusiveMinute) return point;
    }
    return null;
  }

  static int _visibleBinCount({
    required MindDetailedSumTimeWindow window,
    required double pixelWidth,
  }) {
    const minimumAnchorSpacing = 28.0;
    final overviewBins = math.max(
      1,
      (pixelWidth / minimumAnchorSpacing).floor(),
    );
    final zoomProgress =
        (1 - window.visibleMinuteCount / window.homeMinuteCount)
            .clamp(0.0, 1.0)
            .toDouble();
    return math.max(1, (overviewBins * (1 + zoomProgress * 3)).round());
  }

  static int _bucketSpanMinutes({
    required MindDetailedSumTimeWindow window,
    required double pixelWidth,
  }) => math.max(
    1,
    (window.visibleMinuteCount /
            _visibleBinCount(window: window, pixelWidth: pixelWidth))
        .ceil(),
  );
}
