import 'package:flutter/material.dart';

import 'dashboard_header_perceptual_color.dart';

/// Dashboard-lifetime, user-owned visualization width for Mind's score
/// palette. The score itself remains a domain result and is never stored here.
@immutable
final class MindHeaderScoreWindowState {
  const MindHeaderScoreWindowState({required this.windowWidthPercent});

  const MindHeaderScoreWindowState.defaults()
    : windowWidthPercent = defaultWindowWidthPercent;

  static const double minWindowWidthPercent = 10;
  static const double maxWindowWidthPercent = 100;
  static const double defaultWindowWidthPercent = 28;

  final double windowWidthPercent;

  MindHeaderScoreWindowState copyWith({double? windowWidthPercent}) =>
      MindHeaderScoreWindowState(
        windowWidthPercent: normalizeWindowWidth(
          windowWidthPercent ?? this.windowWidthPercent,
        ),
      );

  static double normalizeWindowWidth(double value) =>
      (value.isFinite ? value : defaultWindowWidthPercent)
          .clamp(minWindowWidthPercent, maxWindowWidthPercent)
          .roundToDouble();

  @override
  bool operator ==(Object other) =>
      other is MindHeaderScoreWindowState &&
      other.windowWidthPercent == windowWidthPercent;

  @override
  int get hashCode => windowWidthPercent.hashCode;
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

/// Immutable semantic palette probes passed to the pre-existing Header frame
/// transport. `centerPercent` is always the score; edge clamping never shifts
/// it to make a full window fit.
@immutable
final class MindHeaderScoreWindow {
  const MindHeaderScoreWindow({
    required this.centerPercent,
    required this.windowWidthPercent,
    required this.leftSamplePercent,
    required this.rightSamplePercent,
    required this.colorA,
    required this.colorMid,
    required this.colorB,
  });

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
      other.centerPercent == centerPercent &&
      other.windowWidthPercent == windowWidthPercent &&
      other.leftSamplePercent == leftSamplePercent &&
      other.rightSamplePercent == rightSamplePercent &&
      other.colorA == colorA &&
      other.colorMid == colorMid &&
      other.colorB == colorB;

  @override
  int get hashCode => Object.hash(
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
  }) {
    final center = (score.isFinite ? score : 50).clamp(0.0, 100.0).toDouble();
    final width = MindHeaderScoreWindowState.normalizeWindowWidth(
      windowWidthPercent,
    );
    final half = width / 2;
    final left = (center - half).clamp(0.0, 100.0).toDouble();
    final right = (center + half).clamp(0.0, 100.0).toDouble();
    return MindHeaderScoreWindow(
      centerPercent: center,
      windowWidthPercent: width,
      leftSamplePercent: left,
      rightSamplePercent: right,
      colorA: MindHeaderTrafficLightScale.sample(left),
      colorMid: MindHeaderTrafficLightScale.sample(center),
      colorB: MindHeaderTrafficLightScale.sample(right),
    );
  }
}
