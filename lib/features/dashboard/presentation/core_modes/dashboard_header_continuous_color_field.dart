import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Interpolation choices for a Header source scale.
///
/// [historicalLinear] matches the encoded-sRGB segment interpolation used by
/// Flutter's native gradient. [monotoneCubic] retains every authored anchor,
/// but constructs a bounded C1 function in linear-light RGB between anchors.
enum DashboardHeaderContinuousInterpolation { historicalLinear, monotoneCubic }

/// A linear-light RGB sample used only by the continuous static-field core.
///
/// Values remain unpremultiplied and are constrained to the display gamut by
/// [DashboardHeaderContinuousColorScale] before conversion back to [Color].
@immutable
final class DashboardHeaderLinearRgb {
  const DashboardHeaderLinearRgb({
    required this.red,
    required this.green,
    required this.blue,
  });

  factory DashboardHeaderLinearRgb.fromColor(Color color) =>
      DashboardHeaderLinearRgb(
        red: _toLinear(color.r),
        green: _toLinear(color.g),
        blue: _toLinear(color.b),
      );

  final double red;
  final double green;
  final double blue;

  DashboardHeaderLinearRgb componentwiseMin(DashboardHeaderLinearRgb other) =>
      DashboardHeaderLinearRgb(
        red: math.min(red, other.red),
        green: math.min(green, other.green),
        blue: math.min(blue, other.blue),
      );

  DashboardHeaderLinearRgb componentwiseMax(DashboardHeaderLinearRgb other) =>
      DashboardHeaderLinearRgb(
        red: math.max(red, other.red),
        green: math.max(green, other.green),
        blue: math.max(blue, other.blue),
      );

  DashboardHeaderLinearRgb lerp(DashboardHeaderLinearRgb other, double t) =>
      DashboardHeaderLinearRgb(
        red: red + (other.red - red) * t,
        green: green + (other.green - green) * t,
        blue: blue + (other.blue - blue) * t,
      );

  double distanceTo(DashboardHeaderLinearRgb other) => math.sqrt(
    math.pow(red - other.red, 2) +
        math.pow(green - other.green, 2) +
        math.pow(blue - other.blue, 2),
  );

  bool isWithin(
    DashboardHeaderLinearRgb lower,
    DashboardHeaderLinearRgb upper, {
    double epsilon = 1e-9,
  }) =>
      red >= lower.red - epsilon &&
      red <= upper.red + epsilon &&
      green >= lower.green - epsilon &&
      green <= upper.green + epsilon &&
      blue >= lower.blue - epsilon &&
      blue <= upper.blue + epsilon;

  bool get isInDisplayGamut =>
      red >= -1e-9 &&
      red <= 1 + 1e-9 &&
      green >= -1e-9 &&
      green <= 1 + 1e-9 &&
      blue >= -1e-9 &&
      blue <= 1 + 1e-9;

  Color toColor({double alpha = 1}) => Color.fromARGB(
    (alpha.clamp(0.0, 1.0) * 255).round(),
    (_toSrgb(red.clamp(0.0, 1.0).toDouble()) * 255).round(),
    (_toSrgb(green.clamp(0.0, 1.0).toDouble()) * 255).round(),
    (_toSrgb(blue.clamp(0.0, 1.0).toDouble()) * 255).round(),
  );

  static double _toLinear(double channel) => channel <= .04045
      ? channel / 12.92
      : math.pow((channel + .055) / 1.055, 2.4).toDouble();

  static double _toSrgb(double channel) => channel <= .0031308
      ? channel * 12.92
      : 1.055 * math.pow(channel, 1 / 2.4).toDouble() - .055;
}

/// Immutable source-domain mapping for one finite Header window.
///
/// `sourceForHeaderX(x) = left + x * (right - left)`.  It owns no Budget
/// arithmetic; policy code supplies the already-authoritative clamped bounds.
@immutable
final class DashboardHeaderColorWindowTransform {
  const DashboardHeaderColorWindowTransform({
    required this.left,
    required this.right,
  }) : assert(left >= 0),
       assert(right <= 1),
       assert(right > left);

  final double left;
  final double right;

  double get span => right - left;

  double sourceForHeaderX(double x) {
    final bounded = x.isFinite ? x.clamp(0.0, 1.0).toDouble() : 0.0;
    return left + bounded * span;
  }

  double headerXForSource(double sourcePosition) =>
      ((sourcePosition - left) / span).clamp(0.0, 1.0).toDouble();

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderColorWindowTransform &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => Object.hash(left, right);
}

/// One immutable continuous palette function `C(t)`.
///
/// This core deliberately has no knowledge of category ownership, Budget
/// progress, the tuner, paint bounds, effects or animation. It establishes the
/// only source-colour function used by the static Header field.
@immutable
final class DashboardHeaderContinuousColorScale {
  DashboardHeaderContinuousColorScale.historicalLinear({
    required List<Color> anchors,
    required List<double> anchorPositions,
  }) : this._(
         anchors: anchors,
         anchorPositions: anchorPositions,
         interpolation: DashboardHeaderContinuousInterpolation.historicalLinear,
       );

  DashboardHeaderContinuousColorScale.monotoneCubic({
    required List<Color> anchors,
    required List<double> anchorPositions,
  }) : this._(
         anchors: anchors,
         anchorPositions: anchorPositions,
         interpolation: DashboardHeaderContinuousInterpolation.monotoneCubic,
       );

  DashboardHeaderContinuousColorScale._({
    required List<Color> anchors,
    required List<double> anchorPositions,
    required this.interpolation,
  }) : assert(anchors.length >= 2),
       assert(anchors.length == anchorPositions.length),
       assert(_hasStrictUnitOrder(anchorPositions)),
       anchors = List<Color>.unmodifiable(anchors),
       anchorPositions = List<double>.unmodifiable(anchorPositions),
       _linearAnchors = List<DashboardHeaderLinearRgb>.unmodifiable(
         anchors.map(DashboardHeaderLinearRgb.fromColor),
       ),
       _redSlopes = _slopesFor(
         anchors.map((color) => DashboardHeaderLinearRgb.fromColor(color).red),
         anchorPositions,
         interpolation,
       ),
       _greenSlopes = _slopesFor(
         anchors.map(
           (color) => DashboardHeaderLinearRgb.fromColor(color).green,
         ),
         anchorPositions,
         interpolation,
       ),
       _blueSlopes = _slopesFor(
         anchors.map((color) => DashboardHeaderLinearRgb.fromColor(color).blue),
         anchorPositions,
         interpolation,
       );

  final List<Color> anchors;
  final List<double> anchorPositions;
  final DashboardHeaderContinuousInterpolation interpolation;
  final List<DashboardHeaderLinearRgb> _linearAnchors;
  final List<double> _redSlopes;
  final List<double> _greenSlopes;
  final List<double> _blueSlopes;

  Color sample(double position) {
    final bounded = _bound(position);
    final anchor = _anchorIndexAt(bounded);
    if (anchor != null) return anchors[anchor];
    if (interpolation ==
        DashboardHeaderContinuousInterpolation.historicalLinear) {
      final segment = _segmentFor(bounded);
      final t = _segmentT(segment, bounded);
      return Color.lerp(anchors[segment], anchors[segment + 1], t)!;
    }
    return sampleLinear(bounded).toColor(alpha: _alphaAt(bounded));
  }

  DashboardHeaderLinearRgb sampleLinear(double position) {
    final bounded = _bound(position);
    final anchor = _anchorIndexAt(bounded);
    if (anchor != null) return _linearAnchors[anchor];
    final segment = _segmentFor(bounded);
    final t = _segmentT(segment, bounded);
    if (interpolation ==
        DashboardHeaderContinuousInterpolation.historicalLinear) {
      return _linearAnchors[segment].lerp(_linearAnchors[segment + 1], t);
    }
    final lower = _linearAnchors[segment];
    final upper = _linearAnchors[segment + 1];
    return DashboardHeaderLinearRgb(
      red: _boundedHermite(
        lower.red,
        upper.red,
        _redSlopes[segment],
        _redSlopes[segment + 1],
        _segmentWidth(segment),
        t,
      ),
      green: _boundedHermite(
        lower.green,
        upper.green,
        _greenSlopes[segment],
        _greenSlopes[segment + 1],
        _segmentWidth(segment),
        t,
      ),
      blue: _boundedHermite(
        lower.blue,
        upper.blue,
        _blueSlopes[segment],
        _blueSlopes[segment + 1],
        _segmentWidth(segment),
        t,
      ),
    );
  }

  DashboardHeaderLinearRgb linearDerivative(double position) {
    final bounded = _bound(position);
    final segment = _segmentFor(bounded, preferPreviousAtKnot: false);
    if (interpolation ==
        DashboardHeaderContinuousInterpolation.historicalLinear) {
      final width = _segmentWidth(segment);
      final lower = _linearAnchors[segment];
      final upper = _linearAnchors[segment + 1];
      return DashboardHeaderLinearRgb(
        red: (upper.red - lower.red) / width,
        green: (upper.green - lower.green) / width,
        blue: (upper.blue - lower.blue) / width,
      );
    }
    final t = _segmentT(segment, bounded);
    final lower = _linearAnchors[segment];
    final upper = _linearAnchors[segment + 1];
    final width = _segmentWidth(segment);
    return DashboardHeaderLinearRgb(
      red: _hermiteDerivative(
        lower.red,
        upper.red,
        _redSlopes[segment],
        _redSlopes[segment + 1],
        width,
        t,
      ),
      green: _hermiteDerivative(
        lower.green,
        upper.green,
        _greenSlopes[segment],
        _greenSlopes[segment + 1],
        width,
        t,
      ),
      blue: _hermiteDerivative(
        lower.blue,
        upper.blue,
        _blueSlopes[segment],
        _blueSlopes[segment + 1],
        width,
        t,
      ),
    );
  }

  static bool _hasStrictUnitOrder(List<double> positions) {
    if (positions.length < 2 || positions.first != 0 || positions.last != 1) {
      return false;
    }
    for (var index = 1; index < positions.length; index += 1) {
      if (!positions[index].isFinite ||
          positions[index - 1] >= positions[index]) {
        return false;
      }
    }
    return true;
  }

  static List<double> _slopesFor(
    Iterable<double> values,
    List<double> positions,
    DashboardHeaderContinuousInterpolation interpolation,
  ) {
    final samples = values.toList(growable: false);
    if (interpolation ==
        DashboardHeaderContinuousInterpolation.historicalLinear) {
      return List<double>.filled(samples.length, 0, growable: false);
    }
    final deltas = <double>[
      for (var index = 0; index < samples.length - 1; index += 1)
        (samples[index + 1] - samples[index]) /
            (positions[index + 1] - positions[index]),
    ];
    if (samples.length == 2) {
      return List<double>.filled(2, deltas.single, growable: false);
    }
    final result = List<double>.filled(samples.length, 0, growable: false);
    result[0] = _endpointSlope(
      firstWidth: positions[1] - positions[0],
      secondWidth: positions[2] - positions[1],
      firstDelta: deltas[0],
      secondDelta: deltas[1],
    );
    for (var index = 1; index < samples.length - 1; index += 1) {
      final previous = deltas[index - 1];
      final next = deltas[index];
      if (previous == 0 || next == 0 || previous.sign != next.sign) {
        result[index] = 0;
        continue;
      }
      final previousWidth = positions[index] - positions[index - 1];
      final nextWidth = positions[index + 1] - positions[index];
      final firstWeight = 2 * nextWidth + previousWidth;
      final secondWeight = nextWidth + 2 * previousWidth;
      result[index] =
          (firstWeight + secondWeight) /
          (firstWeight / previous + secondWeight / next);
    }
    result[result.length - 1] = _endpointSlope(
      firstWidth: positions.last - positions[positions.length - 2],
      secondWidth:
          positions[positions.length - 2] - positions[positions.length - 3],
      firstDelta: deltas.last,
      secondDelta: deltas[deltas.length - 2],
    );
    return List<double>.unmodifiable(result);
  }

  static double _endpointSlope({
    required double firstWidth,
    required double secondWidth,
    required double firstDelta,
    required double secondDelta,
  }) {
    var slope =
        ((2 * firstWidth + secondWidth) * firstDelta -
            firstWidth * secondDelta) /
        (firstWidth + secondWidth);
    if (slope.sign != firstDelta.sign) return 0;
    if (firstDelta.sign != secondDelta.sign &&
        slope.abs() > firstDelta.abs() * 3) {
      slope = firstDelta * 3;
    }
    return slope;
  }

  static double _boundedHermite(
    double left,
    double right,
    double leftSlope,
    double rightSlope,
    double width,
    double t,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;
    final result =
        (2 * t3 - 3 * t2 + 1) * left +
        (t3 - 2 * t2 + t) * width * leftSlope +
        (-2 * t3 + 3 * t2) * right +
        (t3 - t2) * width * rightSlope;
    return result
        .clamp(math.min(left, right), math.max(left, right))
        .toDouble();
  }

  static double _hermiteDerivative(
    double left,
    double right,
    double leftSlope,
    double rightSlope,
    double width,
    double t,
  ) {
    final t2 = t * t;
    return ((6 * t2 - 6 * t) * left +
            (3 * t2 - 4 * t + 1) * width * leftSlope +
            (-6 * t2 + 6 * t) * right +
            (3 * t2 - 2 * t) * width * rightSlope) /
        width;
  }

  double _bound(double position) =>
      (position.isFinite ? position : 0).clamp(0.0, 1.0).toDouble();

  int? _anchorIndexAt(double position) {
    for (var index = 0; index < anchorPositions.length; index += 1) {
      if ((anchorPositions[index] - position).abs() <= 1e-12) return index;
    }
    return null;
  }

  int _segmentFor(double position, {bool preferPreviousAtKnot = true}) {
    for (var index = 0; index < anchorPositions.length - 1; index += 1) {
      final next = anchorPositions[index + 1];
      if (position < next ||
          (preferPreviousAtKnot && (position - next).abs() <= 1e-12)) {
        return index;
      }
    }
    return anchorPositions.length - 2;
  }

  double _segmentT(int segment, double position) =>
      (position - anchorPositions[segment]) / _segmentWidth(segment);

  double _segmentWidth(int segment) =>
      anchorPositions[segment + 1] - anchorPositions[segment];

  double _alphaAt(double position) {
    final segment = _segmentFor(position);
    final t = _segmentT(segment, position);
    return anchors[segment].a +
        (anchors[segment + 1].a - anchors[segment].a) * t;
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderContinuousColorScale &&
      listEquals(anchors, other.anchors) &&
      listEquals(anchorPositions, other.anchorPositions) &&
      interpolation == other.interpolation;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(anchors),
    Object.hashAll(anchorPositions),
    interpolation,
  );
}

/// One immutable sample prepared for the native static Header renderer.
@immutable
final class DashboardHeaderContinuousFieldStop {
  const DashboardHeaderContinuousFieldStop({
    required this.sourcePosition,
    required this.headerStop,
    required this.color,
  });

  final double sourcePosition;
  final double headerStop;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderContinuousFieldStop &&
      sourcePosition == other.sourcePosition &&
      headerStop == other.headerStop &&
      color == other.color;

  @override
  int get hashCode => Object.hash(sourcePosition, headerStop, color);
}

/// Prepared static Header field.
///
/// Its samples are resolved when a semantic colour input changes, never from
/// the painter or the shared Header clock. The native renderer still owns the
/// final `ui.Gradient.linear` call; this type only supplies its immutable,
/// continuous source-function approximation.
@immutable
final class DashboardHeaderContinuousField {
  factory DashboardHeaderContinuousField({
    required String paletteId,
    required DashboardHeaderContinuousColorScale sourceScale,
    required DashboardHeaderColorWindowTransform windowTransform,
    required double rawProgress,
    required double windowWidth,
    required double opacity,
    int minimumRenderStopCount = 128,
  }) {
    assert(minimumRenderStopCount >= 2);
    final samplePositions = <double>{
      for (var index = 0; index < minimumRenderStopCount; index += 1)
        index / (minimumRenderStopCount - 1),
      for (final sourcePosition in sourceScale.anchorPositions)
        if (sourcePosition > windowTransform.left &&
            sourcePosition < windowTransform.right)
          windowTransform.headerXForSource(sourcePosition),
    }.toList(growable: false)..sort();
    final stops = List<DashboardHeaderContinuousFieldStop>.unmodifiable(
      <DashboardHeaderContinuousFieldStop>[
        for (final headerStop in samplePositions)
          DashboardHeaderContinuousFieldStop(
            sourcePosition: windowTransform.sourceForHeaderX(headerStop),
            headerStop: headerStop,
            color: sourceScale.sample(
              windowTransform.sourceForHeaderX(headerStop),
            ),
          ),
      ],
    );
    return DashboardHeaderContinuousField._(
      paletteId: paletteId,
      sourceScale: sourceScale,
      windowTransform: windowTransform,
      rawProgress: rawProgress,
      windowWidth: windowWidth,
      opacity: opacity.clamp(0.0, 1.0).toDouble(),
      renderStops: stops,
      colors: List<Color>.unmodifiable(<Color>[
        for (final stop in stops) stop.color,
      ]),
      stops: List<double>.unmodifiable(<double>[
        for (final stop in stops) stop.headerStop,
      ]),
    );
  }

  const DashboardHeaderContinuousField._({
    required this.paletteId,
    required this.sourceScale,
    required this.windowTransform,
    required this.rawProgress,
    required this.windowWidth,
    required this.opacity,
    required this.renderStops,
    required this.colors,
    required this.stops,
  });

  final String paletteId;
  final DashboardHeaderContinuousColorScale sourceScale;
  final DashboardHeaderColorWindowTransform windowTransform;
  final double rawProgress;
  final double windowWidth;
  final double opacity;
  final List<DashboardHeaderContinuousFieldStop> renderStops;
  final List<Color> colors;
  final List<double> stops;

  String get fieldHash {
    var hash = 0x811c9dc5;
    void mix(int value) {
      hash = ((hash ^ value) * 0x01000193).toUnsigned(32);
    }

    for (final color in colors) {
      mix(color.toARGB32());
    }
    for (final stop in stops) {
      mix((stop * 1000000).round());
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  @override
  bool operator ==(Object other) =>
      other is DashboardHeaderContinuousField &&
      paletteId == other.paletteId &&
      sourceScale == other.sourceScale &&
      windowTransform == other.windowTransform &&
      rawProgress == other.rawProgress &&
      windowWidth == other.windowWidth &&
      opacity == other.opacity &&
      listEquals(renderStops, other.renderStops);

  @override
  int get hashCode => Object.hash(
    paletteId,
    sourceScale,
    windowTransform,
    rawProgress,
    windowWidth,
    opacity,
    Object.hashAll(renderStops),
  );
}
