import 'dart:math' as math;

import 'mind_temporal_heatmap_projection.dart';

/// Immutable two-layer display model for the Mind Day heatmap.
///
/// The background always comes from the resident full-day event frame; the
/// foreground comes from the same frame after the live amount-range preview.
/// This is deliberately a pure projection: it cannot read Query, a repository
/// or the ledger while a range thumb is moving.
final class MindDayHourlyComparisonProjection {
  MindDayHourlyComparisonProjection._({
    required List<MindDayHourlyComparison> hours,
    required this.maximumFullTotal,
  }) : hours = List<MindDayHourlyComparison>.unmodifiable(hours);

  factory MindDayHourlyComparisonProjection.build({
    required Iterable<MindDayTimelineEvent> fullEvents,
    required Iterable<MindDayTimelineEvent> selectedEvents,
  }) {
    final fullByHour = List<int>.filled(24, 0);
    final selectedByHour = List<int>.filled(24, 0);
    for (final event in fullEvents) {
      final hour = _hourFor(event.timeMinutes);
      if (hour != null) fullByHour[hour] += event.total;
    }
    for (final event in selectedEvents) {
      final hour = _hourFor(event.timeMinutes);
      if (hour != null) selectedByHour[hour] += event.total;
    }
    final maximumFullTotal = fullByHour.fold<int>(
      0,
      (maximum, total) => math.max(maximum, total),
    );
    return MindDayHourlyComparisonProjection._(
      maximumFullTotal: maximumFullTotal,
      hours: List<MindDayHourlyComparison>.generate(24, (hour) {
        final fullTotal = fullByHour[hour];
        // Selected events originate from the full resident event population.
        // Keep that containment true at the rendering boundary even if an
        // incomplete frame reaches this purely visual projection.
        final selectedTotal = selectedByHour[hour].clamp(0, fullTotal).toInt();
        return MindDayHourlyComparison(
          hour: hour,
          fullTotal: fullTotal,
          selectedTotal: selectedTotal,
          maximumFullTotal: maximumFullTotal,
        );
      }, growable: false),
    );
  }

  final List<MindDayHourlyComparison> hours;
  final int maximumFullTotal;

  MindDayHourlyComparison hour(int value) => hours[value];
}

/// One hourly cell whose foreground is normalized against the whole-day
/// background maximum, so the selected range never changes the meaning of the
/// pale reference layer.
final class MindDayHourlyComparison {
  const MindDayHourlyComparison({
    required this.hour,
    required this.fullTotal,
    required this.selectedTotal,
    required this.maximumFullTotal,
  });

  final int hour;
  final int fullTotal;
  final int selectedTotal;
  final int maximumFullTotal;

  double get fullFraction => _fraction(fullTotal);
  double get selectedFraction => _fraction(selectedTotal);

  double _fraction(int total) => maximumFullTotal == 0
      ? 0
      : (total / maximumFullTotal).clamp(0, 1).toDouble();
}

int? _hourFor(int minutes) =>
    minutes < 0 || minutes >= 24 * 60 ? null : minutes ~/ 60;
