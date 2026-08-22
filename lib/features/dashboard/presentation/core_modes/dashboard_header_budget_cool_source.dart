import 'package:flutter/material.dart';

/// Dashboard-lifetime, user-owned Budget Header colour settings.
///
/// This deliberately has no Budget, category, progress, or time input. Its
/// defaults and integer ranges are transcribed from the Cool scale controls in
/// `docs/prototypes/color_lab.html`.
@immutable
final class BudgetHeaderGlobalCoolState {
  const BudgetHeaderGlobalCoolState({
    required this.positionPercent,
    required this.windowWidthPercent,
  });

  const BudgetHeaderGlobalCoolState.defaults()
    : positionPercent = defaultPositionPercent,
      windowWidthPercent = defaultWindowWidthPercent;

  static const double minPositionPercent = 0;
  static const double maxPositionPercent = 100;
  static const double minWindowWidthPercent = 10;
  static const double maxWindowWidthPercent = 100;
  static const double defaultPositionPercent = 50;
  static const double defaultWindowWidthPercent = 28;

  final double positionPercent;
  final double windowWidthPercent;

  BudgetHeaderGlobalCoolState copyWith({
    double? positionPercent,
    double? windowWidthPercent,
  }) => BudgetHeaderGlobalCoolState(
    positionPercent: _integerPercent(
      positionPercent ?? this.positionPercent,
      min: minPositionPercent,
      max: maxPositionPercent,
      fallback: defaultPositionPercent,
    ),
    windowWidthPercent: _integerPercent(
      windowWidthPercent ?? this.windowWidthPercent,
      min: minWindowWidthPercent,
      max: maxWindowWidthPercent,
      fallback: defaultWindowWidthPercent,
    ),
  );

  static double normalizePosition(double value) => _integerPercent(
    value,
    min: minPositionPercent,
    max: maxPositionPercent,
    fallback: defaultPositionPercent,
  );

  static double normalizeWindowWidth(double value) => _integerPercent(
    value,
    min: minWindowWidthPercent,
    max: maxWindowWidthPercent,
    fallback: defaultWindowWidthPercent,
  );

  static double _integerPercent(
    double value, {
    required double min,
    required double max,
    required double fallback,
  }) {
    final finite = value.isFinite ? value : fallback;
    return finite.clamp(min, max).roundToDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is BudgetHeaderGlobalCoolState &&
      positionPercent == other.positionPercent &&
      windowWidthPercent == other.windowWidthPercent;

  @override
  int get hashCode => Object.hash(positionPercent, windowWidthPercent);
}

/// Exact, fixed Color Lab Cool source. The authored stops are intentionally
/// not category colours or a generated semantic palette.
abstract final class BudgetHeaderCoolColorSource {
  static const List<Color> stops = <Color>[
    Color(0xffffffff),
    Color(0xffe6fbff),
    Color(0xffbdf5ff),
    Color(0xff75e6ff),
    Color(0xff22d3ee),
    Color(0xff06b6d4),
    Color(0xff0284c7),
    Color(0xff0057d9),
    Color(0xff0030a8),
    Color(0xff00135f),
  ];

  /// Port of `sampleScaleColor(coolScaleStops, position)` from Color Lab.
  /// The JavaScript source mixes encoded RGB channels and applies
  /// `Math.round`; all channels are positive, so Dart [round] has the same
  /// tie behaviour here.
  static Color sample(double positionPercent) {
    final bounded = clampPercent(positionPercent);
    final scaled = bounded / 100 * (stops.length - 1);
    final index = scaled.floor().clamp(0, stops.length - 1);
    final nextIndex = (index + 1).clamp(0, stops.length - 1);
    final amount = scaled - index;
    return _mix(stops[index], stops[nextIndex], amount);
  }

  static double clampPercent(double value) =>
      (value.isFinite ? value : 0).clamp(0.0, 100.0).toDouble();

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

/// Immutable three-probe snapshot consumed by the Budget Header.
@immutable
final class BudgetHeaderCoolWindow {
  const BudgetHeaderCoolWindow({
    required this.positionPercent,
    required this.windowWidthPercent,
    required this.leftRawPercent,
    required this.centerRawPercent,
    required this.rightRawPercent,
    required this.leftSamplePercent,
    required this.centerSamplePercent,
    required this.rightSamplePercent,
    required this.colorA,
    required this.colorMid,
    required this.colorB,
  });

  final double positionPercent;
  final double windowWidthPercent;
  final double leftRawPercent;
  final double centerRawPercent;
  final double rightRawPercent;
  final double leftSamplePercent;
  final double centerSamplePercent;
  final double rightSamplePercent;
  final Color colorA;
  final Color colorMid;
  final Color colorB;

  List<Color> get colors =>
      List<Color>.unmodifiable(<Color>[colorA, colorMid, colorB]);
  List<double> get stops => const <double>[0, .5, 1];

  @override
  bool operator ==(Object other) =>
      other is BudgetHeaderCoolWindow &&
      positionPercent == other.positionPercent &&
      windowWidthPercent == other.windowWidthPercent &&
      leftRawPercent == other.leftRawPercent &&
      centerRawPercent == other.centerRawPercent &&
      rightRawPercent == other.rightRawPercent &&
      leftSamplePercent == other.leftSamplePercent &&
      centerSamplePercent == other.centerSamplePercent &&
      rightSamplePercent == other.rightSamplePercent &&
      colorA == other.colorA &&
      colorMid == other.colorMid &&
      colorB == other.colorB;

  @override
  int get hashCode => Object.hash(
    positionPercent,
    windowWidthPercent,
    leftRawPercent,
    centerRawPercent,
    rightRawPercent,
    leftSamplePercent,
    centerSamplePercent,
    rightSamplePercent,
    colorA,
    colorMid,
    colorB,
  );
}

/// Port of the Color Lab's Cool test-header probes.  The source clamps each
/// probe independently; it never moves the user-selected position to fit the
/// complete window inside the scale.
abstract final class BudgetHeaderCoolWindowSampler {
  static BudgetHeaderCoolWindow sample(BudgetHeaderGlobalCoolState state) {
    final position = BudgetHeaderGlobalCoolState.normalizePosition(
      state.positionPercent,
    );
    final width = BudgetHeaderGlobalCoolState.normalizeWindowWidth(
      state.windowWidthPercent,
    );
    final half = width / 2;
    final leftRaw = position - half;
    final centerRaw = position;
    final rightRaw = position + half;
    final leftSample = BudgetHeaderCoolColorSource.clampPercent(leftRaw);
    final centerSample = BudgetHeaderCoolColorSource.clampPercent(centerRaw);
    final rightSample = BudgetHeaderCoolColorSource.clampPercent(rightRaw);
    return BudgetHeaderCoolWindow(
      positionPercent: position,
      windowWidthPercent: width,
      leftRawPercent: leftRaw,
      centerRawPercent: centerRaw,
      rightRawPercent: rightRaw,
      leftSamplePercent: leftSample,
      centerSamplePercent: centerSample,
      rightSamplePercent: rightSample,
      colorA: BudgetHeaderCoolColorSource.sample(leftSample),
      colorMid: BudgetHeaderCoolColorSource.sample(centerSample),
      colorB: BudgetHeaderCoolColorSource.sample(rightSample),
    );
  }
}
