import 'package:flutter/material.dart';

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

/// The approved Stats Common traffic-light scale. Sampling is deterministic
/// encoded-RGB interpolation; alpha stays with the existing Header opacity
/// owner and never becomes score semantics.
abstract final class MindHeaderTrafficLightScale {
  static const List<({double percent, Color color})> _anchors =
      <({double percent, Color color})>[
        (percent: 0, color: Color(0xffdc2626)),
        (percent: 18, color: Color(0xffef4444)),
        (percent: 40, color: Color(0xfff87171)),
        // The approved amber interval spans approximately 51–57%. Its
        // central anchor is exactly 54% so there is one stable sample.
        (percent: 54, color: Color(0xfffbbf24)),
        (percent: 66, color: Color(0xff4ade80)),
        (percent: 84, color: Color(0xff22c55e)),
        (percent: 100, color: Color(0xff16a34a)),
      ];

  static Color sample(double score) {
    final bounded = (score.isFinite ? score : 0).clamp(0.0, 100.0).toDouble();
    for (var index = 1; index < _anchors.length; index += 1) {
      final right = _anchors[index];
      if (bounded > right.percent) continue;
      final left = _anchors[index - 1];
      final span = right.percent - left.percent;
      return _mix(
        left.color,
        right.color,
        span == 0 ? 0 : (bounded - left.percent) / span,
      );
    }
    return _anchors.last.color;
  }

  static Color _mix(Color left, Color right, double amount) => Color.fromARGB(
    _mixChannel(_channel(left, 24), _channel(right, 24), amount),
    _mixChannel(_channel(left, 16), _channel(right, 16), amount),
    _mixChannel(_channel(left, 8), _channel(right, 8), amount),
    _mixChannel(_channel(left, 0), _channel(right, 0), amount),
  );

  static int _channel(Color color, int shift) =>
      (color.toARGB32() >> shift) & 0xff;

  static int _mixChannel(int left, int right, double amount) =>
      (left + (right - left) * amount).round().clamp(0, 255);
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
