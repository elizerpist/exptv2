import 'dart:math' as math;

import '../../time_navigation/domain/local_date.dart';
import 'mind_temporal_heatmap_projection.dart';

const _minutesPerDay = 24 * 60;

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

/// A source-only LOD sampler. Overview density uses a readable spatial budget
/// instead of one bin per logical pixel. As visible time narrows the budget
/// rises continuously; at a one-day-or-less window every supplied prepared
/// transaction remains individually representable.
final class MindDetailedSumLod {
  const MindDetailedSumLod._();

  static List<MindSumHeatmapDetailPoint> sample({
    required List<MindSumHeatmapDetailPoint> points,
    required MindDetailedSumTimeWindow window,
    required double pixelWidth,
  }) {
    final visible =
        points
            .where(
              (point) =>
                  point.epochMinute >= window.startEpochMinute &&
                  point.epochMinute <= window.endEpochMinute,
            )
            .toList(growable: false)
          ..sort((left, right) {
            final byTime = left.epochMinute.compareTo(right.epochMinute);
            return byTime != 0
                ? byTime
                : (left.ordinal ?? -1).compareTo(right.ordinal ?? -1);
          });
    if (visible.length <= 2 || window.visibleMinuteCount <= _minutesPerDay) {
      return List<MindSumHeatmapDetailPoint>.unmodifiable(visible);
    }

    const minimumAnchorSpacing = 28.0;
    final overviewBins = math.max(
      1,
      (pixelWidth / minimumAnchorSpacing).floor(),
    );
    final zoomProgress =
        (1 - window.visibleMinuteCount / window.homeMinuteCount)
            .clamp(0.0, 1.0)
            .toDouble();
    final binCount = math.max(
      1,
      (overviewBins * (1 + zoomProgress * 3)).round(),
    );
    if (visible.length <= binCount) {
      return List<MindSumHeatmapDetailPoint>.unmodifiable(visible);
    }

    final selectedIndices = <int>{};
    final buckets = <int, List<int>>{};
    final denominator = math.max(1, window.visibleMinuteCount - 1);
    for (var index = 0; index < visible.length; index += 1) {
      final fraction =
          (visible[index].epochMinute - window.startEpochMinute) / denominator;
      final bucket = (fraction * binCount).floor().clamp(0, binCount - 1);
      buckets.putIfAbsent(bucket, () => <int>[]).add(index);
    }
    for (final indices in buckets.values) {
      selectedIndices.add(indices.first);
      selectedIndices.add(indices.last);
      var minimum = indices.first;
      var maximum = indices.first;
      for (final index in indices.skip(1)) {
        if (visible[index].total < visible[minimum].total) minimum = index;
        if (visible[index].total > visible[maximum].total) maximum = index;
      }
      selectedIndices
        ..add(minimum)
        ..add(maximum);
    }
    final ordered = selectedIndices.toList()..sort();
    return List<MindSumHeatmapDetailPoint>.unmodifiable(
      ordered.map((index) => visible[index]),
    );
  }
}
