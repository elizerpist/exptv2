import 'dart:math' as math;

import '../../time_navigation/domain/local_date.dart';
import 'mind_temporal_heatmap_projection.dart';

/// An immutable visible interval inside one calendar year's detailed Sum
/// chart. The home domain stays available on every derived window so a local
/// pinch may narrow time but can never expose days outside January–December.
final class MindDetailedSumTimeWindow {
  const MindDetailedSumTimeWindow._({
    required this.homeStartEpochDay,
    required this.homeEndEpochDay,
    required this.startEpochDay,
    required this.endEpochDay,
  });

  factory MindDetailedSumTimeWindow.fullYear(int year) =>
      MindDetailedSumTimeWindow._(
        homeStartEpochDay: LocalDate(year: year, month: 1, day: 1).epochDay,
        homeEndEpochDay: LocalDate(year: year, month: 12, day: 31).epochDay,
        startEpochDay: LocalDate(year: year, month: 1, day: 1).epochDay,
        endEpochDay: LocalDate(year: year, month: 12, day: 31).epochDay,
      );

  final int homeStartEpochDay;
  final int homeEndEpochDay;
  final int startEpochDay;
  final int endEpochDay;

  int get visibleDayCount => endEpochDay - startEpochDay + 1;
  int get homeDayCount => homeEndEpochDay - homeStartEpochDay + 1;

  double normalizedPositionOf(int epochDay) {
    if (visibleDayCount <= 1) return .5;
    return ((epochDay - startEpochDay) / (visibleDayCount - 1))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// Narrows/widens the actual visible calendar domain around [focalEpochDay].
  /// The current focal fraction is retained when it fits; edge clamping is the
  /// only reason it can move, and a factor below one never exceeds home.
  MindDetailedSumTimeWindow zoom({
    required double scaleDelta,
    required int focalEpochDay,
  }) {
    if (!scaleDelta.isFinite || scaleDelta <= 0) return this;
    final requested = (visibleDayCount / scaleDelta).round();
    final nextCount = requested.clamp(1, homeDayCount);
    if (nextCount == visibleDayCount) return this;
    final focalFraction = normalizedPositionOf(focalEpochDay);
    final proposedStart = (focalEpochDay - focalFraction * (nextCount - 1))
        .round();
    final latestStart = homeEndEpochDay - nextCount + 1;
    final nextStart = proposedStart
        .clamp(homeStartEpochDay, latestStart)
        .toInt();
    return MindDetailedSumTimeWindow._(
      homeStartEpochDay: homeStartEpochDay,
      homeEndEpochDay: homeEndEpochDay,
      startEpochDay: nextStart,
      endEpochDay: nextStart + nextCount - 1,
    );
  }

  MindDetailedSumTimeWindow panByDays(int days) {
    if (days == 0 || visibleDayCount >= homeDayCount) return this;
    final latestStart = homeEndEpochDay - visibleDayCount + 1;
    final nextStart = (startEpochDay + days)
        .clamp(homeStartEpochDay, latestStart)
        .toInt();
    if (nextStart == startEpochDay) return this;
    return MindDetailedSumTimeWindow._(
      homeStartEpochDay: homeStartEpochDay,
      homeEndEpochDay: homeEndEpochDay,
      startEpochDay: nextStart,
      endEpochDay: nextStart + visibleDayCount - 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MindDetailedSumTimeWindow &&
      other.homeStartEpochDay == homeStartEpochDay &&
      other.homeEndEpochDay == homeEndEpochDay &&
      other.startEpochDay == startEpochDay &&
      other.endEpochDay == endEpochDay;

  @override
  int get hashCode => Object.hash(
    homeStartEpochDay,
    homeEndEpochDay,
    startEpochDay,
    endEpochDay,
  );
}

/// A pure bounded downsampler for the detailed Sum line. It never invents a
/// financial point: every returned anchor is one of [points]. At low density
/// it keeps each bucket's chronological endpoints plus extrema, preserving
/// visible spikes; at higher pixels-per-day it naturally returns more source
/// anchors until every in-window day is available.
final class MindDetailedSumLod {
  const MindDetailedSumLod._();

  static List<MindSumHeatmapDailyPoint> sample({
    required List<MindSumHeatmapDailyPoint> points,
    required MindDetailedSumTimeWindow window,
    required double pixelWidth,
  }) {
    final visible =
        points
            .where(
              (point) =>
                  point.date.epochDay >= window.startEpochDay &&
                  point.date.epochDay <= window.endEpochDay,
            )
            .toList(growable: false)
          ..sort(
            (left, right) => left.date.epochDay.compareTo(right.date.epochDay),
          );
    if (visible.length <= 2) return visible;
    final binCount = math.max(1, pixelWidth.floor());
    if (visible.length <= binCount) return visible;

    final selectedIndices = <int>{};
    final buckets = <int, List<int>>{};
    final denominator = math.max(1, window.visibleDayCount - 1);
    for (var index = 0; index < visible.length; index += 1) {
      final fraction =
          (visible[index].date.epochDay - window.startEpochDay) / denominator;
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
    return List<MindSumHeatmapDailyPoint>.unmodifiable(
      ordered.map((index) => visible[index]),
    );
  }
}
