import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders_ui/flutter_shaders_ui.dart';

/// A render-ready daily value from the established Balance Month projection.
///
/// This type is deliberately presentation-only: the component receives
/// prepared scalar values and has no knowledge of ledger, query or repository
/// types.
@immutable
final class FluviTopographicWaveDatum {
  const FluviTopographicWaveDatum({
    required this.key,
    required this.value,
    required this.label,
  });

  final int key;
  final int value;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is FluviTopographicWaveDatum &&
      other.key == key &&
      other.value == value &&
      other.label == label;

  @override
  int get hashCode => Object.hash(key, value, label);
}

/// Three data-bound terrain material presets over one shared spline/contour
/// geometry engine. The SVG reference is a visual specification, never a
/// static sample-data image in production.
enum FluviTopographicWaveStyle { terrain, svgReference, shaderAtmosphere }

abstract final class FluviTopographicWavePalette {
  static const pearl = Color(0xfff5f3ff);
  static const lavender = Color(0xffdcd8ff);
  static const periwinkle = Color(0xffaaa6ff);
  static const violet = Color(0xff7667f6);
  static const deepViolet = Color(0xff6254da);
  static const icyBlue = Color(0xff8fc9f5);
  static const mint = Color(0xffbfede7);
}

/// The reusable Havi → Költés visual. It owns only the ephemeral tapped
/// marker index; values, formatting and renderer selection remain supplied by
/// the established Balance presentation chain.
final class FluviTopographicWaveChart extends StatefulWidget {
  const FluviTopographicWaveChart({
    super.key,
    required this.values,
    required this.style,
    required this.tooltipForValue,
    this.selectedIndex,
    this.onSelectedIndexChanged,
  });

  final List<FluviTopographicWaveDatum> values;
  final FluviTopographicWaveStyle style;
  final String Function(int value) tooltipForValue;
  final int? selectedIndex;
  final ValueChanged<int>? onSelectedIndexChanged;

  @override
  State<FluviTopographicWaveChart> createState() =>
      _FluviTopographicWaveChartState();
}

final class _FluviTopographicWaveChartState
    extends State<FluviTopographicWaveChart> {
  final _FluviTopographicWaveGeometryCache _geometryCache =
      _FluviTopographicWaveGeometryCache();
  int? _tappedIndex;

  int? get _selectedIndex => widget.selectedIndex ?? _tappedIndex;

  @override
  void didUpdateWidget(covariant FluviTopographicWaveChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values)) _tappedIndex = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final terrain = _geometryCache.resolve(values: widget.values, size: size);
      return Semantics(
        label: 'Költés napi topografikus idősor',
        hint: 'Érintse meg a napi összeg kiválasztásához',
        child: GestureDetector(
          key: ValueKey<String>(
            'balance-monthly-spending-wave-${widget.style.name}',
          ),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final index = terrain.nearestIndexForX(details.localPosition.dx);
            if (index == null) return;
            widget.onSelectedIndexChanged?.call(index);
            if (widget.selectedIndex == null) {
              setState(() => _tappedIndex = index);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (widget.style == FluviTopographicWaveStyle.shaderAtmosphere)
                  const _ShaderAtmosphereLayer(),
                RepaintBoundary(
                  key: ValueKey<String>(
                    'balance-monthly-spending-wave-repaint-${widget.style.name}',
                  ),
                  child: CustomPaint(
                    painter: _FluviTopographicWavePainter(
                      terrain: terrain,
                      style: widget.style,
                      selectedIndex: _selectedIndex,
                      tooltipForValue: widget.tooltipForValue,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// This runs only in the shader-specific monthly preset. The terrain itself
/// stays in the static Canvas painter, so the animated atmospheric repaint
/// never recomputes financial geometry. The package freezes automatically for
/// the platform reduced-motion setting.
final class _ShaderAtmosphereLayer extends StatelessWidget {
  const _ShaderAtmosphereLayer();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    key: const ValueKey<String>(
      'balance-monthly-spending-wave-shader-atmosphere',
    ),
    child: ShaderPerformance(
      settings: const ShaderPerformanceSettings(
        maxFramesPerSecond: 12,
        respectReducedMotion: true,
      ),
      child: AuroraEffect(
        color1: FluviTopographicWavePalette.mint,
        color2: FluviTopographicWavePalette.lavender,
        intensity: .055,
        speed: .12,
        child: const SizedBox.expand(),
      ),
    ),
  );
}

@immutable
final class FluviTopographicWaveDepthLayer {
  const FluviTopographicWaveDepthLayer({
    required this.depth,
    required this.path,
    required this.opacity,
  });

  final double depth;
  final Path path;
  final double opacity;
}

@immutable
final class FluviTopographicWaveAtmosphericLayer {
  const FluviTopographicWaveAtmosphericLayer({
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

/// Size- and data-specific cached drawing geometry. It is immutable after
/// resolution so a static terrain painter does no spline or path work on
/// ordinary parent rebuilds.
@immutable
final class FluviTopographicWaveTerrain {
  const FluviTopographicWaveTerrain._({
    required this.size,
    required this.plot,
    required this.ridgeSamples,
    required this.ridgePath,
    required this.areaPath,
    required this.depthLayers,
    required this.atmospheres,
    required this.dataOffsets,
    required this.highestIndex,
    required this.values,
  });

  final Size size;
  final Rect plot;
  final List<Offset> ridgeSamples;
  final Path ridgePath;
  final Path areaPath;
  final List<FluviTopographicWaveDepthLayer> depthLayers;
  final List<FluviTopographicWaveAtmosphericLayer> atmospheres;
  final List<Offset> dataOffsets;
  final int? highestIndex;
  final List<FluviTopographicWaveDatum> values;

  int? nearestIndexForX(double x) {
    if (dataOffsets.isEmpty) return null;
    var nearest = 0;
    var distance = (dataOffsets.first.dx - x).abs();
    for (var index = 1; index < dataOffsets.length; index += 1) {
      final nextDistance = (dataOffsets[index].dx - x).abs();
      if (nextDistance < distance) {
        nearest = index;
        distance = nextDistance;
      }
    }
    return nearest;
  }

  static FluviTopographicWaveTerrain resolve({
    required List<FluviTopographicWaveDatum> values,
    required Size size,
  }) {
    final plot = Rect.fromLTRB(
      2,
      4,
      math.max(2, size.width - 2),
      math.max(4, size.height - 4),
    );
    if (size.isEmpty || values.isEmpty || plot.width <= 0 || plot.height <= 0) {
      return FluviTopographicWaveTerrain._(
        size: size,
        plot: plot,
        ridgeSamples: const <Offset>[],
        ridgePath: Path(),
        areaPath: Path(),
        depthLayers: const <FluviTopographicWaveDepthLayer>[],
        atmospheres: const <FluviTopographicWaveAtmosphericLayer>[],
        dataOffsets: const <Offset>[],
        highestIndex: null,
        values: List<FluviTopographicWaveDatum>.unmodifiable(values),
      );
    }
    final maximum = values.fold<int>(
      0,
      (max, datum) => math.max(max, datum.value),
    );
    // A zero-only month has no financial ridge. Rendering a nominal ridge at
    // an arbitrary normalized height would manufacture activity that did not
    // occur, so retain only the deliberately non-data atmospheric empty state.
    if (maximum == 0) {
      return FluviTopographicWaveTerrain._(
        size: size,
        plot: plot,
        ridgeSamples: const <Offset>[],
        ridgePath: Path(),
        areaPath: Path(),
        depthLayers: const <FluviTopographicWaveDepthLayer>[],
        atmospheres: List<FluviTopographicWaveAtmosphericLayer>.unmodifiable(
          _atmospheres(
            plot: plot,
            baseline: plot.bottom,
            normalizedMean: 0,
            volatility: 0,
          ),
        ),
        dataOffsets: const <Offset>[],
        highestIndex: null,
        values: List<FluviTopographicWaveDatum>.unmodifiable(values),
      );
    }
    final drawableHeight = plot.height * .84;
    final baseline = plot.bottom;
    final offsets = <Offset>[];
    var highestIndex = 0;
    for (var index = 0; index < values.length; index += 1) {
      final datum = values[index];
      if (datum.value > values[highestIndex].value) highestIndex = index;
      final x = values.length == 1
          ? plot.center.dx
          : plot.left + plot.width * index / (values.length - 1);
      final normalized = (datum.value / maximum).clamp(0.0, 1.0).toDouble();
      offsets.add(Offset(x, baseline - normalized * drawableHeight));
    }
    final controls = offsets.length == 1
        ? <Offset>[
            Offset(plot.left, offsets.first.dy),
            Offset(plot.right, offsets.first.dy),
          ]
        : offsets;
    final samples = _catmullRomSamples(controls, plot);
    final ridgePath = _pathFor(samples);
    final areaPath = Path.from(ridgePath)
      ..lineTo(plot.right, baseline)
      ..lineTo(plot.left, baseline)
      ..close();
    const layerCount = 30;
    final depths = List<FluviTopographicWaveDepthLayer>.generate(layerCount, (
      index,
    ) {
      final depth = index / (layerCount - 1);
      final flattened = samples
          .map(
            (point) => Offset(
              point.dx,
              point.dy + (baseline - point.dy) * depth * .82,
            ),
          )
          .toList(growable: false);
      return FluviTopographicWaveDepthLayer(
        depth: depth,
        path: _pathFor(flattened),
        // The SVG's contours remain visible as one fused ribbon at the
        // compact child-card scale. This is still non-linear fading, but the
        // shallow layers have enough presence to read as terrain rather than
        // disappearing behind the dominant ridge glow.
        opacity: .19 * math.pow(1 - depth, 1.45).toDouble(),
      );
    }, growable: false);
    final normalizedMean =
        values.fold<double>(0, (sum, datum) => sum + datum.value / maximum) /
        values.length;
    final volatility = _volatility(values, maximum);
    return FluviTopographicWaveTerrain._(
      size: size,
      plot: plot,
      ridgeSamples: List<Offset>.unmodifiable(samples),
      ridgePath: ridgePath,
      areaPath: areaPath,
      depthLayers: List<FluviTopographicWaveDepthLayer>.unmodifiable(depths),
      atmospheres: List<FluviTopographicWaveAtmosphericLayer>.unmodifiable(
        _atmospheres(
          plot: plot,
          baseline: baseline,
          normalizedMean: normalizedMean,
          volatility: volatility,
        ),
      ),
      dataOffsets: List<Offset>.unmodifiable(offsets),
      highestIndex: highestIndex,
      values: List<FluviTopographicWaveDatum>.unmodifiable(values),
    );
  }

  static double _volatility(
    List<FluviTopographicWaveDatum> values,
    int maximum,
  ) {
    if (maximum <= 0 || values.length < 2) return 0;
    var movement = 0.0;
    for (var index = 1; index < values.length; index += 1) {
      movement +=
          (values[index].value - values[index - 1].value).abs() / maximum;
    }
    return (movement / (values.length - 1)).clamp(0.0, 1.0).toDouble();
  }

  static List<FluviTopographicWaveAtmosphericLayer> _atmospheres({
    required Rect plot,
    required double baseline,
    required double normalizedMean,
    required double volatility,
  }) {
    const profiles = <List<double>>[
      <double>[-.30, .20, -.12, .35, -.08],
      <double>[.16, -.34, .26, -.14, .10],
      <double>[-.07, .32, -.38, .18, -.20],
      <double>[.24, -.08, .24, -.28, .04],
    ];
    const colors = <Color>[
      FluviTopographicWavePalette.mint,
      FluviTopographicWavePalette.icyBlue,
      FluviTopographicWavePalette.lavender,
      FluviTopographicWavePalette.pearl,
    ];
    // The reference uses a visible but deliberately non-data atmospheric
    // wash. These stay below the terrain contour maximum (.135) and are
    // further reduced in the shader preset, where Aurora supplies diffusion.
    const opacities = <double>[.082, .068, .052, .035];
    const blurSigmas = <double>[16, 13, 10, 8];
    const amplitudes = <double>[.16, .13, .11, .08];
    const xFractions = <double>[0, .23, .52, .78, 1];
    final influence = .86 + volatility * .24;
    return List<FluviTopographicWaveAtmosphericLayer>.generate(
      profiles.length,
      (index) {
        final baseY =
            plot.top +
            plot.height * (.18 + index * .105) +
            (normalizedMean - .5) * plot.height * .07;
        final amplitude = plot.height * amplitudes[index] * influence;
        final controls = <Offset>[
          for (var point = 0; point < xFractions.length; point += 1)
            Offset(
              plot.left + plot.width * xFractions[point],
              baseY + profiles[index][point] * amplitude,
            ),
        ];
        final sampled = _catmullRomSamples(
          controls,
          plot,
          samplesPerSegment: 18,
        );
        final path = _pathFor(sampled);
        final fillPath = Path.from(path)
          ..lineTo(plot.right, baseline)
          ..lineTo(plot.left, baseline)
          ..close();
        return FluviTopographicWaveAtmosphericLayer(
          path: path,
          fillPath: fillPath,
          color: colors[index],
          opacity: opacities[index],
          blurSigma: blurSigmas[index],
        );
      },
      growable: false,
    );
  }

  static List<Offset> _catmullRomSamples(
    List<Offset> controls,
    Rect plot, {
    int samplesPerSegment = 14,
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
        samples.add(_catmullRom(previous, start, end, next, t, plot));
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
    Rect plot,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;
    double interpolate(double p0, double p1, double p2, double p3) =>
        .5 *
        ((2 * p1) +
            (-p0 + p2) * t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
            (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
    final x = interpolate(
      previous.dx,
      start.dx,
      end.dx,
      next.dx,
    ).clamp(plot.left, plot.right).toDouble();
    // Catmull–Rom continuity, bounded by this segment's two genuine daily
    // values, prevents an invented spend spike or dip between measurements.
    final lowerY = math.min(start.dy, end.dy);
    final upperY = math.max(start.dy, end.dy);
    final y = interpolate(
      previous.dy,
      start.dy,
      end.dy,
      next.dy,
    ).clamp(lowerY, upperY).clamp(plot.top, plot.bottom).toDouble();
    return Offset(x, y);
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

final class _FluviTopographicWaveGeometryCache {
  _FluviTopographicWaveCacheKey? _key;
  FluviTopographicWaveTerrain? _terrain;

  FluviTopographicWaveTerrain resolve({
    required List<FluviTopographicWaveDatum> values,
    required Size size,
  }) {
    final key = _FluviTopographicWaveCacheKey(values: values, size: size);
    if (key == _key && _terrain != null) return _terrain!;
    _key = key;
    return _terrain = FluviTopographicWaveTerrain.resolve(
      values: values,
      size: size,
    );
  }
}

@immutable
final class _FluviTopographicWaveCacheKey {
  _FluviTopographicWaveCacheKey({
    required List<FluviTopographicWaveDatum> values,
    required this.size,
  }) : values = List<FluviTopographicWaveDatum>.unmodifiable(values);

  final List<FluviTopographicWaveDatum> values;
  final Size size;

  @override
  bool operator ==(Object other) =>
      other is _FluviTopographicWaveCacheKey &&
      other.size == size &&
      listEquals(other.values, values);

  @override
  int get hashCode => Object.hash(size, Object.hashAll(values));
}

final class _FluviTopographicWavePainter extends CustomPainter {
  const _FluviTopographicWavePainter({
    required this.terrain,
    required this.style,
    required this.selectedIndex,
    required this.tooltipForValue,
  });

  final FluviTopographicWaveTerrain terrain;
  final FluviTopographicWaveStyle style;
  final int? selectedIndex;
  final String Function(int value) tooltipForValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
    );
    _drawAtmospheres(canvas);
    if (terrain.ridgeSamples.isEmpty) {
      canvas.restore();
      return;
    }
    _drawGuides(canvas);
    _drawArea(canvas);
    _drawContours(canvas);
    _drawRidge(canvas);
    _drawMarkerAndTooltip(canvas, size);
    canvas.restore();
  }

  void _drawAtmospheres(Canvas canvas) {
    // The source-SVG choice keeps its reference's more present atmospheric
    // hierarchy. The shader choice delegates most atmosphere to Aurora, so
    // its Canvas echoes deliberately recede. All three keep identical real
    // financial ridge geometry.
    final reduction = switch (style) {
      FluviTopographicWaveStyle.terrain => .74,
      FluviTopographicWaveStyle.svgReference => 1.0,
      // Aurora is intentionally only an additional diffusion pass. Keep the
      // source-SVG-like Canvas waves materially visible underneath it so the
      // shader route still reads as mint/aqua/lilac on every supported
      // backend, including a platform shader fallback.
      FluviTopographicWaveStyle.shaderAtmosphere => .70,
    };
    final referenceWash = switch (style) {
      FluviTopographicWaveStyle.svgReference => const <Color>[
        Color(0x30bfede7),
        Color(0x2cdcd8ff),
        Color(0x00f5f3ff),
      ],
      // Preserve a pastel atmospheric cue under Aurora even when a platform
      // supplies only the package's neutral shader fallback.
      FluviTopographicWaveStyle.shaderAtmosphere => const <Color>[
        Color(0x1fbfede7),
        Color(0x1a8fc9f5),
        Color(0x00f5f3ff),
      ],
      FluviTopographicWaveStyle.terrain => null,
    };
    if (referenceWash != null) {
      canvas.drawRect(
        terrain.plot,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: referenceWash,
            stops: <double>[0, .52, 1],
          ).createShader(terrain.plot)
          ..isAntiAlias = true,
      );
    }
    for (final wave in terrain.atmospheres) {
      canvas.drawPath(
        wave.fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              wave.color.withValues(alpha: wave.opacity * reduction),
              wave.color.withValues(alpha: 0),
            ],
          ).createShader(terrain.plot)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, wave.blurSigma)
          ..isAntiAlias = true,
      );
    }
  }

  void _drawGuides(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xffdce5f5).withValues(alpha: .56)
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    const guideCount = 7;
    for (var index = 0; index < guideCount; index += 1) {
      final x =
          terrain.plot.left + terrain.plot.width * index / (guideCount - 1);
      for (var y = terrain.plot.top; y < terrain.plot.bottom; y += 7) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 3, terrain.plot.bottom)),
          paint,
        );
      }
    }
  }

  void _drawArea(Canvas canvas) {
    final opacity = switch (style) {
      FluviTopographicWaveStyle.terrain => .76,
      FluviTopographicWaveStyle.svgReference => 1.0,
      FluviTopographicWaveStyle.shaderAtmosphere => .68,
    };
    canvas.drawPath(
      terrain.areaPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0x43aaa6ff),
            Color(0x2e8fc9f5),
            Color(0x00f5f3ff),
          ],
          stops: <double>[0, .46, 1],
        ).createShader(terrain.plot)
        ..color = Colors.white.withValues(alpha: opacity)
        ..isAntiAlias = true,
    );
  }

  void _drawContours(Canvas canvas) {
    final intensity = switch (style) {
      FluviTopographicWaveStyle.terrain => .94,
      FluviTopographicWaveStyle.svgReference => 1.08,
      FluviTopographicWaveStyle.shaderAtmosphere => .88,
    };
    for (final layer in terrain.depthLayers.reversed) {
      final tint = Color.lerp(
        FluviTopographicWavePalette.icyBlue,
        FluviTopographicWavePalette.violet,
        1 - layer.depth,
      )!;
      canvas.drawPath(
        layer.path,
        Paint()
          ..color = tint.withValues(alpha: layer.opacity * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .70 + (1 - layer.depth) * .46
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }
  }

  void _drawRidge(Canvas canvas) {
    final glowOpacity = style == FluviTopographicWaveStyle.svgReference
        ? .36
        : .29;
    canvas.drawPath(
      terrain.ridgePath,
      Paint()
        ..color = FluviTopographicWavePalette.violet.withValues(
          alpha: glowOpacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      terrain.ridgePath,
      Paint()
        ..color = FluviTopographicWavePalette.pearl.withValues(alpha: .86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.drawPath(
      terrain.ridgePath,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[
            FluviTopographicWavePalette.periwinkle,
            Color(0xff8d7df8),
            FluviTopographicWavePalette.violet,
            FluviTopographicWavePalette.deepViolet,
          ],
        ).createShader(terrain.plot)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  void _drawMarkerAndTooltip(Canvas canvas, Size size) {
    final index =
        (selectedIndex != null &&
            selectedIndex! >= 0 &&
            selectedIndex! < terrain.dataOffsets.length)
        ? selectedIndex
        : terrain.highestIndex;
    if (index == null) return;
    final point = terrain.dataOffsets[index];
    canvas.drawCircle(
      point,
      10,
      Paint()
        ..color = FluviTopographicWavePalette.violet.withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      point,
      5.1,
      Paint()
        ..color = FluviTopographicWavePalette.pearl
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      point,
      5.1,
      Paint()
        ..color = const Color(0xff8c7bfa)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3,
    );
    final label = tooltipForValue(terrain.values[index].value);
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xff6874f1),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: math.max(28, size.width - 16));
    final bubbleWidth = math.max(42.0, text.width + 16);
    const bubbleHeight = 24.0;
    final left = (point.dx - bubbleWidth / 2)
        .clamp(2.0, math.max(2.0, size.width - bubbleWidth))
        .toDouble();
    final top = (point.dy - bubbleHeight - 13)
        .clamp(2.0, math.max(2.0, size.height - bubbleHeight))
        .toDouble();
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, bubbleWidth, bubbleHeight),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = Colors.white.withValues(alpha: .96)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .3),
    );
    text.paint(
      canvas,
      Offset(
        left + (bubbleWidth - text.width) / 2,
        top + (bubbleHeight - text.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _FluviTopographicWavePainter oldDelegate) =>
      oldDelegate.terrain != terrain ||
      oldDelegate.style != style ||
      oldDelegate.selectedIndex != selectedIndex;
}
