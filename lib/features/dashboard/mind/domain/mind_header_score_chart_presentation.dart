import 'package:flutter/foundation.dart';

/// Presentation-only visibility for the five quiet time labels below Mind's
/// accepted score chart. It intentionally carries no Query, score or Header
/// color state.
enum MindHeaderScoreChartTimeLabels {
  hidden,
  visible;

  String get tunerLabel => switch (this) {
    MindHeaderScoreChartTimeLabels.hidden => 'KI',
    MindHeaderScoreChartTimeLabels.visible => 'BE',
  };
}

@immutable
final class MindHeaderScoreChartPresentationSettings {
  const MindHeaderScoreChartPresentationSettings({
    required this.timeLabels,
    required this.revision,
  });

  const MindHeaderScoreChartPresentationSettings.defaults()
    : timeLabels = MindHeaderScoreChartTimeLabels.hidden,
      revision = 0;

  final MindHeaderScoreChartTimeLabels timeLabels;
  final int revision;

  bool get showsTimeLabels =>
      timeLabels == MindHeaderScoreChartTimeLabels.visible;

  MindHeaderScoreChartPresentationSettings copyWith({
    MindHeaderScoreChartTimeLabels? timeLabels,
    int? revision,
  }) => MindHeaderScoreChartPresentationSettings(
    timeLabels: timeLabels ?? this.timeLabels,
    revision: revision ?? this.revision,
  );

  @override
  bool operator ==(Object other) =>
      other is MindHeaderScoreChartPresentationSettings &&
      other.timeLabels == timeLabels &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(timeLabels, revision);
}

/// The one visual-preference owner for Mind chart labels. This small owner is
/// deliberately separate from behavioral-score mathematics and Header visual
/// effects; it only decides whether an already-prepared chart domain exposes
/// its label projection.
final class MindHeaderScoreChartPresentationController
    extends ValueNotifier<MindHeaderScoreChartPresentationSettings> {
  MindHeaderScoreChartPresentationController({
    MindHeaderScoreChartPresentationSettings? initial,
  }) : super(
         initial ?? const MindHeaderScoreChartPresentationSettings.defaults(),
       );

  void setTimeLabels(MindHeaderScoreChartTimeLabels next) {
    final current = value;
    if (current.timeLabels == next) return;
    value = current.copyWith(timeLabels: next, revision: current.revision + 1);
  }
}
