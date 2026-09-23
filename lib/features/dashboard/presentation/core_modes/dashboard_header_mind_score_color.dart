import 'package:flutter/material.dart';

import 'dashboard_header_perceptual_color.dart';

/// Mind retains its established score palette and may alternatively use the
/// exact Color Lab Traffic palette. The score remains the window centre for
/// both choices; palette selection never changes behavioral data.
enum MindHeaderScorePalette { current, trafficColorLab }

extension MindHeaderScorePalettePresentation on MindHeaderScorePalette {
  String get label => switch (this) {
    MindHeaderScorePalette.current => 'Current',
    MindHeaderScorePalette.trafficColorLab => 'Traffic (Color Lab)',
  };
}

/// Dashboard-lifetime, user-owned visualization width for Mind's score
/// palette. The score itself remains a domain result and is never stored here.
@immutable
final class MindHeaderScoreWindowState {
  const MindHeaderScoreWindowState({
    required this.windowWidthPercent,
    this.palette = MindHeaderScorePalette.current,
  });

  const MindHeaderScoreWindowState.defaults()
    : windowWidthPercent = defaultWindowWidthPercent,
      palette = MindHeaderScorePalette.current;

  static const double minWindowWidthPercent = 10;
  static const double maxWindowWidthPercent = 100;
  static const double defaultWindowWidthPercent = 28;

  final double windowWidthPercent;
  final MindHeaderScorePalette palette;

  MindHeaderScoreWindowState copyWith({
    double? windowWidthPercent,
    MindHeaderScorePalette? palette,
  }) => MindHeaderScoreWindowState(
    windowWidthPercent: normalizeWindowWidth(
      windowWidthPercent ?? this.windowWidthPercent,
    ),
    palette: palette ?? this.palette,
  );

  static double normalizeWindowWidth(double value) =>
      (value.isFinite ? value : defaultWindowWidthPercent)
          .clamp(minWindowWidthPercent, maxWindowWidthPercent)
          .roundToDouble();

  @override
  bool operator ==(Object other) =>
      other is MindHeaderScoreWindowState &&
      other.windowWidthPercent == windowWidthPercent &&
      other.palette == palette;

  @override
  int get hashCode => Object.hash(windowWidthPercent, palette);
}

/// The approved Mind traffic-light scale. Anchors are product colors; interval
/// sampling uses the shared OKLab path so the red-to-green route stays clean.
/// Alpha remains with the existing Header opacity owner and never becomes
/// score semantics.
abstract final class MindHeaderTrafficLightScale {
  static const List<({double percent, Color color})> _anchors =
      <({double percent, Color color})>[
        (percent: 0, color: Color(0xff991b1b)),
        (percent: 18, color: Color(0xffdc2626)),
        (percent: 35, color: Color(0xfff04a24)),
        (percent: 48, color: Color(0xfff97316)),
        (percent: 58, color: Color(0xfffbbf24)),
        (percent: 70, color: Color(0xff86d957)),
        (percent: 82, color: Color(0xff4ade80)),
        (percent: 100, color: Color(0xff15803d)),
      ];

  static Color sample(double score) {
    final bounded = (score.isFinite ? score : 0).clamp(0.0, 100.0).toDouble();
    for (var index = 1; index < _anchors.length; index += 1) {
      final right = _anchors[index];
      if (bounded > right.percent) continue;
      final left = _anchors[index - 1];
      if (bounded == left.percent) return left.color;
      if (bounded == right.percent) return right.color;
      final span = right.percent - left.percent;
      return DashboardHeaderPerceptualColorMath.mix(
        left.color,
        right.color,
        span == 0 ? 0 : (bounded - left.percent) / span,
      );
    }
    return _anchors.last.color;
  }
}

/// The exact 10-stop Traffic control from the Color Lab palette panel.
/// Sampling shares the existing perceptual interpolation path; only authored
/// stop colours and positions live here.
abstract final class MindHeaderTrafficColorLabScale {
  static const List<double> stops = <double>[
    0,
    11.11,
    22.22,
    33.33,
    44.44,
    55.56,
    66.67,
    77.78,
    88.89,
    100,
  ];

  static const List<Color> colors = <Color>[
    Color(0xffff3b4f),
    Color(0xffff5733),
    Color(0xffff8c1a),
    Color(0xfff7b500),
    Color(0xfff4df24),
    Color(0xffd4f52f),
    Color(0xff7dd943),
    Color(0xff35c76e),
    Color(0xff15bd6f),
    Color(0xff0b8f54),
  ];

  static Color sample(double score) {
    final bounded = (score.isFinite ? score : 0).clamp(0.0, 100.0).toDouble();
    for (var index = 1; index < stops.length; index += 1) {
      final right = stops[index];
      if (bounded > right) continue;
      final left = stops[index - 1];
      if (bounded == left) return colors[index - 1];
      if (bounded == right) return colors[index];
      return DashboardHeaderPerceptualColorMath.mix(
        colors[index - 1],
        colors[index],
        (bounded - left) / (right - left),
      );
    }
    return colors.last;
  }
}

/// Immutable semantic palette probes passed to the pre-existing Header frame
/// transport. `centerPercent` is always the score; edge clamping never shifts
/// it to make a full window fit.
@immutable
final class MindHeaderScoreWindow {
  const MindHeaderScoreWindow({
    required this.palette,
    required this.centerPercent,
    required this.windowWidthPercent,
    required this.leftSamplePercent,
    required this.rightSamplePercent,
    required this.colorA,
    required this.colorMid,
    required this.colorB,
  });

  final MindHeaderScorePalette palette;
  final double centerPercent;
  final double windowWidthPercent;
  final double leftSamplePercent;
  final double rightSamplePercent;
  final Color colorA;
  final Color colorMid;
  final Color colorB;

  List<Color> get colors =>
      List<Color>.unmodifiable(<Color>[colorA, colorMid, colorB]);
  List<double> get stops => const <double>[0, .5, 1];

  @override
  bool operator ==(Object other) =>
      other is MindHeaderScoreWindow &&
      other.palette == palette &&
      other.centerPercent == centerPercent &&
      other.windowWidthPercent == windowWidthPercent &&
      other.leftSamplePercent == leftSamplePercent &&
      other.rightSamplePercent == rightSamplePercent &&
      other.colorA == colorA &&
      other.colorMid == colorMid &&
      other.colorB == colorB;

  @override
  int get hashCode => Object.hash(
    palette,
    centerPercent,
    windowWidthPercent,
    leftSamplePercent,
    rightSamplePercent,
    colorA,
    colorMid,
    colorB,
  );
}

abstract final class MindHeaderScoreWindowSampler {
  static MindHeaderScoreWindow sample({
    required double score,
    required double windowWidthPercent,
    MindHeaderScorePalette palette = MindHeaderScorePalette.current,
  }) {
    final center = (score.isFinite ? score : 50).clamp(0.0, 100.0).toDouble();
    final width = MindHeaderScoreWindowState.normalizeWindowWidth(
      windowWidthPercent,
    );
    final half = width / 2;
    final left = (center - half).clamp(0.0, 100.0).toDouble();
    final right = (center + half).clamp(0.0, 100.0).toDouble();
    return MindHeaderScoreWindow(
      palette: palette,
      centerPercent: center,
      windowWidthPercent: width,
      leftSamplePercent: left,
      rightSamplePercent: right,
      colorA: _sample(palette, left),
      colorMid: _sample(palette, center),
      colorB: _sample(palette, right),
    );
  }

  static Color _sample(MindHeaderScorePalette palette, double score) =>
      switch (palette) {
        MindHeaderScorePalette.current => MindHeaderTrafficLightScale.sample(
          score,
        ),
        MindHeaderScorePalette.trafficColorLab =>
          MindHeaderTrafficColorLabScale.sample(score),
      };
}
