import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/dashboard_header_trend_visual_kernel.dart';

/// Palette roles for the decorative Balance terrain only.
///
/// The history ridge is still derived exclusively from [DashboardHeaderTrendSeries].
/// These colors describe material/light roles, never financial meaning.
abstract final class BalanceHeaderTopographicPalette {
  static const pearl = Color(0xfff5f3ff);
  static const lavender = Color(0xffdcd8ff);
  static const periwinkle = Color(0xffaaa6ff);
  static const violet = Color(0xff7667f6);
  static const deepViolet = Color(0xff6254da);
  static const icyBlue = Color(0xff8fc9f5);
  static const mint = Color(0xffbfede7);
}

abstract final class BalanceHeaderTopographicStyle {
  static const depthLayerCount = 32;
  static const samplesPerSegment = 14;
  static const verticalPadding = 3.5;
  static const contourMaximumOpacity = .22;
  static const chartCornerRadius = 9.0;
  static const ridgeStrokeWidth = 2.8;
  static const ridgeGlowWidth = 7.0;
}

/// One cached contour beneath the truthful spending ridge.
@immutable
final class BalanceHeaderTopographicDepthContour {
  const BalanceHeaderTopographicDepthContour({
    required this.depth,
    required this.opacity,
    required this.path,
  });

  final double depth;
  final double opacity;
  final Path path;
}

/// A deliberately non-financial, very low-frequency atmospheric path.
@immutable
final class BalanceHeaderTopographicAtmosphericWave {
  const BalanceHeaderTopographicAtmosphericWave({
    required this.path,
    required this.fillPath,
    required this.color,
    required this.opacity,
    required this.blurSigma,
  });

  final Path path;
  final Path fillPath;
  final Color color;
  final double opacity;
  final double blurSigma;
}

/// Size-specific immutable geometry for the one topographic Header painter.
///
/// It owns no gesture or financial state. The caller supplies the resident
/// projected trend and uses [pointOffsetForCoordinate] for the existing
/// Header selection marker.
@immutable
final class BalanceHeaderTopographicTerrain {
  const BalanceHeaderTopographicTerrain._({
    required this.size,
    required this.ridgeSamples,
    required this.ridgePath,
    required this.areaPath,
    required this.depthContours,
    required this.atmosphericWaves,
    required this.pointOffsets,
    required this.highestTemporalCoordinate,
  });

  final Size size;
  final List<Offset> ridgeSamples;
  final Path ridgePath;
  final Path areaPath;
  final List<BalanceHeaderTopographicDepthContour> depthContours;
  final List<BalanceHeaderTopographicAtmosphericWave> atmosphericWaves;
  final Map<int, Offset> pointOffsets;
  final int? highestTemporalCoordinate;

  static BalanceHeaderTopographicTerrain resolve({
    required DashboardHeaderTrendSeries series,
    required double minimumValue,
    required double maximumValue,
    required Size size,
  }) {
    assert(maximumValue >= minimumValue);
    return _resolve(
      series: series,
      minimumValue: minimumValue,
      maximumValue: maximumValue,
      size: size,
    );
  }

  Offset? pointOffsetForCoordinate(int temporalCoordinate) =>
      pointOffsets[temporalCoordinate];

  static BalanceHeaderTopographicTerrain _resolve({
    required DashboardHeaderTrendSeries series,
    required double minimumValue,
    required double maximumValue,
    required Size size,
  }) {
    if (size.isEmpty || series.points.isEmpty) {
      return BalanceHeaderTopographicTerrain._(
        size: size,
        ridgeSamples: const <Offset>[],
        ridgePath: Path(),
        areaPath: Path(),
        depthContours: const <BalanceHeaderTopographicDepthContour>[],
        atmosphericWaves: const <BalanceHeaderTopographicAtmosphericWave>[],
        pointOffsets: const <int, Offset>{},
        highestTemporalCoordinate: null,
      );
    }

    final projection = DashboardHeaderTrendTemporalProjection(
      startInclusiveTemporalCoordinate: series.startInclusiveTemporalCoordinate,
      endInclusiveTemporalCoordinate: series.endInclusiveTemporalCoordinate,
    );
    final drawableHeight = math.max(
      0.0,
      size.height - BalanceHeaderTopographicStyle.verticalPadding * 2,
    );
    final span = maximumValue - minimumValue;
    final sourceOffsets = <Offset>[];
    final pointOffsets = <int, Offset>{};
    var highest = series.points.first;
    for (final point in series.points) {
      final normalized = span == 0
          ? .5
          : ((point.value - minimumValue) / span).clamp(0.0, 1.0).toDouble();
      final offset = Offset(
        projection.plotXForCoordinate(point.temporalCoordinate, size.width),
        BalanceHeaderTopographicStyle.verticalPadding +
            (1 - normalized) * drawableHeight,
      );
      sourceOffsets.add(offset);
      pointOffsets[point.temporalCoordinate] = offset;
      if (point.value > highest.value) highest = point;
    }

    final ridgeSamples = _catmullRomSamples(sourceOffsets, size);
    final ridgePath = _pathFor(ridgeSamples);
    final baseline =
        size.height - BalanceHeaderTopographicStyle.verticalPadding;
    final areaPath = Path.from(ridgePath)
      ..lineTo(size.width, baseline)
      ..lineTo(0, baseline)
      ..close();
    final contours = List<BalanceHeaderTopographicDepthContour>.generate(
      BalanceHeaderTopographicStyle.depthLayerCount,
      (index) {
        final depth =
            index / (BalanceHeaderTopographicStyle.depthLayerCount - 1);
        final contourPoints = ridgeSamples
            .map(
              (point) => Offset(
                point.dx,
                point.dy + (baseline - point.dy) * depth * .82,
              ),
            )
            .toList(growable: false);
        return BalanceHeaderTopographicDepthContour(
          depth: depth,
          opacity:
              BalanceHeaderTopographicStyle.contourMaximumOpacity *
              math.pow(1 - depth, 1.7).toDouble(),
          path: _pathFor(contourPoints),
        );
      },
      growable: false,
    );
    final volatility = _normalizedVolatility(series.points, minimumValue, span);
    final atmospheric = _atmosphericWaves(
      size: size,
      baseline: baseline,
      normalizedMean: _normalizedMean(series.points, minimumValue, span),
      volatility: volatility,
    );

    return BalanceHeaderTopographicTerrain._(
      size: size,
      ridgeSamples: List<Offset>.unmodifiable(ridgeSamples),
      ridgePath: ridgePath,
      areaPath: areaPath,
      depthContours: List<BalanceHeaderTopographicDepthContour>.unmodifiable(
        contours,
      ),
      atmosphericWaves:
          List<BalanceHeaderTopographicAtmosphericWave>.unmodifiable(
            atmospheric,
          ),
      pointOffsets: Map<int, Offset>.unmodifiable(pointOffsets),
      highestTemporalCoordinate: highest.temporalCoordinate,
    );
  }

  static double _normalizedMean(
    List<DashboardHeaderTrendPoint> points,
    double minimumValue,
    double span,
  ) {
    if (points.isEmpty) return .5;
    if (span == 0) return .5;
    final total = points.fold<double>(
      0,
      (sum, point) =>
          sum + ((point.value - minimumValue) / span).clamp(0.0, 1.0),
    );
    return total / points.length;
  }

  static double _normalizedVolatility(
    List<DashboardHeaderTrendPoint> points,
    double minimumValue,
    double span,
  ) {
    if (points.length < 2 || span == 0) return 0;
    var movement = 0.0;
    for (var index = 1; index < points.length; index += 1) {
      movement += ((points[index].value - points[index - 1].value).abs() / span)
          .clamp(0.0, 1.0);
    }
    return (movement / (points.length - 1)).clamp(0.0, 1.0).toDouble();
  }

  static List<BalanceHeaderTopographicAtmosphericWave> _atmosphericWaves({
    required Size size,
    required double baseline,
    required double normalizedMean,
    required double volatility,
  }) {
    const profiles = <List<double>>[
      <double>[-.32, .22, -.12, .38, -.08],
      <double>[.18, -.36, .28, -.16, .12],
      <double>[-.08, .35, -.40, .19, -.21],
      <double>[.28, -.10, .26, -.31, .05],
    ];
    const colors = <Color>[
      BalanceHeaderTopographicPalette.mint,
      BalanceHeaderTopographicPalette.icyBlue,
      BalanceHeaderTopographicPalette.periwinkle,
      BalanceHeaderTopographicPalette.pearl,
    ];
    const opacities = <double>[.028, .042, .058, .046];
    const blurSigmas = <double>[22, 18, 14, 10];
    const amplitudeFractions = <double>[.08, .11, .145, .17];
    const xFractions = <double>[0, .23, .51, .78, 1];
    final influence = .86 + volatility * .28;
    final waves = <BalanceHeaderTopographicAtmosphericWave>[];
    for (var index = 0; index < profiles.length; index += 1) {
      final baseY =
          size.height * (.13 + index * .105) +
          (normalizedMean - .5) * size.height * .08;
      final amplitude = size.height * amplitudeFractions[index] * influence;
      final controls = <Offset>[
        for (var control = 0; control < xFractions.length; control += 1)
          Offset(
            size.width * xFractions[control],
            baseY + profiles[index][control] * amplitude,
          ),
      ];
      final sampled = _catmullRomSamples(controls, size, samplesPerSegment: 18);
      final path = _pathFor(sampled);
      final fillPath = Path.from(path)
        ..lineTo(size.width, baseline)
        ..lineTo(0, baseline)
        ..close();
      waves.add(
        BalanceHeaderTopographicAtmosphericWave(
          path: path,
          fillPath: fillPath,
          color: colors[index],
          opacity: opacities[index],
          blurSigma: blurSigmas[index],
        ),
      );
    }
    return waves;
  }

  static List<Offset> _catmullRomSamples(
    List<Offset> controls,
    Size bounds, {
    int samplesPerSegment = BalanceHeaderTopographicStyle.samplesPerSegment,
  }) {
    if (controls.isEmpty) return const <Offset>[];
    if (controls.length == 1) return List<Offset>.of(controls);
    final samples = <Offset>[];
    for (var segment = 0; segment < controls.length - 1; segment += 1) {
      final previous = controls[math.max(0, segment - 1)];
      final start = controls[segment];
      final end = controls[segment + 1];
      final next = controls[math.min(controls.length - 1, segment + 2)];
      for (var sample = 0; sample < samplesPerSegment; sample += 1) {
        final t = sample / samplesPerSegment;
        samples.add(_catmullRom(previous, start, end, next, t, bounds));
      }
    }
    samples.add(controls.last);
    return samples;
  }

  static Offset _catmullRom(
    Offset previous,
    Offset start,
    Offset end,
    Offset next,
    double t,
    Size bounds,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;
    double component(double p0, double p1, double p2, double p3) =>
        .5 *
        ((2 * p1) +
            (-p0 + p2) * t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
            (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
    return Offset(
      component(
        previous.dx,
        start.dx,
        end.dx,
        next.dx,
      ).clamp(0.0, bounds.width).toDouble(),
      component(previous.dy, start.dy, end.dy, next.dy)
          .clamp(
            BalanceHeaderTopographicStyle.verticalPadding,
            math.max(
              BalanceHeaderTopographicStyle.verticalPadding,
              bounds.height - BalanceHeaderTopographicStyle.verticalPadding,
            ),
          )
          .toDouble(),
    );
  }

  static Path _pathFor(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }
}

/// State-owned cache. It avoids rebuilding sampled spline paths on ordinary
/// Header rebuilds and invalidates only when series values or paint bounds do.
final class BalanceHeaderTopographicGeometryCache {
  _BalanceHeaderTopographicCacheKey? _key;
  BalanceHeaderTopographicTerrain? _terrain;

  BalanceHeaderTopographicTerrain resolve({
    required DashboardHeaderTrendSeries series,
    required double minimumValue,
    required double maximumValue,
    required Size size,
  }) {
    final key = _BalanceHeaderTopographicCacheKey(
      series: series,
      minimumValue: minimumValue,
      maximumValue: maximumValue,
      size: size,
    );
    if (key == _key && _terrain != null) return _terrain!;
    _key = key;
    return _terrain = BalanceHeaderTopographicTerrain.resolve(
      series: series,
      minimumValue: minimumValue,
      maximumValue: maximumValue,
      size: size,
    );
  }
}

@immutable
final class _BalanceHeaderTopographicCacheKey {
  _BalanceHeaderTopographicCacheKey({
    required DashboardHeaderTrendSeries series,
    required this.minimumValue,
    required this.maximumValue,
    required this.size,
  }) : start = series.startInclusiveTemporalCoordinate,
       end = series.endInclusiveTemporalCoordinate,
       points = List<_BalanceHeaderTopographicPointKey>.unmodifiable(
         series.points
             .map(
               (point) => _BalanceHeaderTopographicPointKey(
                 temporalCoordinate: point.temporalCoordinate,
                 value: point.value,
               ),
             )
             .toList(growable: false),
       );

  final int start;
  final int end;
  final double minimumValue;
  final double maximumValue;
  final Size size;
  final List<_BalanceHeaderTopographicPointKey> points;

  @override
  bool operator ==(Object other) =>
      other is _BalanceHeaderTopographicCacheKey &&
      other.start == start &&
      other.end == end &&
      other.minimumValue == minimumValue &&
      other.maximumValue == maximumValue &&
      other.size == size &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(
    start,
    end,
    minimumValue,
    maximumValue,
    size,
    Object.hashAll(points),
  );
}

@immutable
final class _BalanceHeaderTopographicPointKey {
  const _BalanceHeaderTopographicPointKey({
    required this.temporalCoordinate,
    required this.value,
  });

  final int temporalCoordinate;
  final double value;

  @override
  bool operator ==(Object other) =>
      other is _BalanceHeaderTopographicPointKey &&
      other.temporalCoordinate == temporalCoordinate &&
      other.value == value;

  @override
  int get hashCode => Object.hash(temporalCoordinate, value);
}

/// One bounded painter for all terrain layers. It deliberately uses Canvas
/// paint effects rather than a widget tree of filters/layers.
final class BalanceHeaderTopographicPainter extends CustomPainter {
  const BalanceHeaderTopographicPainter({
    required this.terrain,
    this.selectedTemporalCoordinate,
    this.showsAreaFade = true,
  });

  final BalanceHeaderTopographicTerrain terrain;
  final int? selectedTemporalCoordinate;
  final bool showsAreaFade;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || terrain.ridgeSamples.isEmpty) return;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(BalanceHeaderTopographicStyle.chartCornerRadius),
      ),
    );
    _drawAtmosphere(canvas, size);
    _drawGuide(canvas, size);
    if (showsAreaFade) _drawArea(canvas, size);
    _drawContours(canvas);
    _drawRidge(canvas, size);
    _drawMarker(canvas);
    canvas.restore();
  }

  void _drawAtmosphere(Canvas canvas, Size size) {
    for (final wave in terrain.atmosphericWaves) {
      final bounds = Offset.zero & size;
      canvas.drawPath(
        wave.fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              wave.color.withValues(alpha: wave.opacity),
              wave.color.withValues(alpha: 0),
            ],
          ).createShader(bounds)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, wave.blurSigma)
          ..isAntiAlias = true,
      );
      canvas.drawPath(
        wave.path,
        Paint()
          ..color = wave.color.withValues(alpha: wave.opacity * .72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, wave.blurSigma)
          ..isAntiAlias = true,
      );
    }
  }

  void _drawGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BalanceHeaderTopographicPalette.pearl.withValues(alpha: .15)
      ..strokeWidth = .55
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final y = size.height * DashboardHeaderTrendChartStyle.guideRelativeY;
    for (var start = 0.0; start < size.width; start += 5.0) {
      canvas.drawLine(
        Offset(start, y),
        Offset((start + 2.0).clamp(0.0, size.width), y),
        paint,
      );
    }
  }

  void _drawArea(Canvas canvas, Size size) {
    canvas.drawPath(
      terrain.areaPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x70aaa6ff), Color(0x00dcd8ff)],
        ).createShader(Offset.zero & size)
        ..isAntiAlias = true,
    );
  }

  void _drawContours(Canvas canvas) {
    for (final contour in terrain.depthContours.reversed) {
      if (contour.opacity <= 0) continue;
      canvas.drawPath(
        contour.path,
        Paint()
          ..color = Color.lerp(
            BalanceHeaderTopographicPalette.icyBlue,
            BalanceHeaderTopographicPalette.violet,
            1 - contour.depth,
          )!.withValues(alpha: contour.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .5 + (1 - contour.depth) * .4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }
  }

  void _drawRidge(Canvas canvas, Size size) {
    canvas.drawPath(
      terrain.ridgePath,
      Paint()
        ..color = BalanceHeaderTopographicPalette.violet.withValues(alpha: .36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = BalanceHeaderTopographicStyle.ridgeGlowWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      terrain.ridgePath,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            BalanceHeaderTopographicPalette.icyBlue,
            BalanceHeaderTopographicPalette.violet,
            BalanceHeaderTopographicPalette.deepViolet,
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = BalanceHeaderTopographicStyle.ridgeStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      terrain.ridgePath,
      Paint()
        ..color = BalanceHeaderTopographicPalette.pearl.withValues(alpha: .58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  void _drawMarker(Canvas canvas) {
    final coordinate =
        selectedTemporalCoordinate ?? terrain.highestTemporalCoordinate;
    if (coordinate == null) return;
    final offset = terrain.pointOffsetForCoordinate(coordinate);
    if (offset == null) return;
    canvas.drawCircle(
      offset,
      8,
      Paint()
        ..color = BalanceHeaderTopographicPalette.violet.withValues(alpha: .30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      offset,
      4.4,
      Paint()
        ..color = BalanceHeaderTopographicPalette.violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      offset,
      2,
      Paint()
        ..color = BalanceHeaderTopographicPalette.pearl
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant BalanceHeaderTopographicPainter oldDelegate) =>
      oldDelegate.terrain != terrain ||
      oldDelegate.selectedTemporalCoordinate != selectedTemporalCoordinate ||
      oldDelegate.showsAreaFade != showsAreaFade;
}
