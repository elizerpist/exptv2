import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders_ui/flutter_shaders_ui.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../core/diagnostics/fluvi_onscreen_diagnostics.dart';

part 'fluvi_wave_render_probe.dart';

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
  ui.FragmentShader? _surfaceShader;
  ui.Image? _curveTexture;
  FluviTopographicWaveTerrain? _curveTextureTerrain;
  FluviTopographicWaveTerrain? _pendingCurveTextureTerrain;
  int _shaderGeneration = 0;
  final FluviWaveRenderMetrics _metrics = FluviWaveRenderMetrics();
  FluviWaveDebugScope? _debug;
  late final String _diagnosticOwner = 'month-wave-${identityHashCode(this)}';
  late final Map<String, Object?> Function() _diagnosticSnapshot =
      _metrics.snapshot;

  static Future<ui.FragmentProgram>? _surfaceProgram;

  @override
  void initState() {
    super.initState();
    if (kFluviOnscreenDiagnosticsEnabled) {
      FluviDiagnosticLogger.registerUserMarkerContext(
        _diagnosticOwner,
        _diagnosticSnapshot,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _debug = FluviWaveDebugScope.maybeOf(context);
    if (widget.style == FluviTopographicWaveStyle.shaderAtmosphere) {
      if (_metrics.shaderState == 'not-requested') _loadSurfaceShader();
    }
  }

  Future<void> _loadSurfaceShader() async {
    final generation = ++_shaderGeneration;
    _metrics.shaderState = 'loading';
    try {
      final program =
          _debug?.programLoader?.call() ??
          (_surfaceProgram ??= ui.FragmentProgram.fromAsset(
            'shaders/fluvi_wave_surface.frag',
          ));
      final shader = (await program).fragmentShader();
      if (!mounted ||
          generation != _shaderGeneration ||
          widget.style != FluviTopographicWaveStyle.shaderAtmosphere) {
        shader.dispose();
        return;
      }
      final previous = _surfaceShader;
      _metrics.shaderState = 'ready';
      setState(() => _surfaceShader = shader);
      previous?.dispose();
    } catch (error) {
      if (!mounted || generation != _shaderGeneration) return;
      _surfaceProgram = null; // A failed load must not poison a later retry.
      setState(() {
        _metrics.shaderState = 'failed';
        _metrics.shaderError = error.toString();
      });
      // The shader is a material enhancement only. The cached vertex-lit
      // surface below is deliberately equivalent financial geometry and is
      // retained for test software rendering and unsupported GPU backends.
    }
  }

  void _synchronizeCurveTexture(FluviTopographicWaveTerrain terrain) {
    if (terrain.ridgeSamples.isEmpty) {
      _pendingCurveTextureTerrain = null;
      _curveTexture?.dispose();
      if (_curveTexture != null) _metrics.textureDisposals++;
      _curveTexture = null;
      _curveTextureTerrain = null;
      return;
    }
    if (identical(_curveTextureTerrain, terrain) ||
        identical(_pendingCurveTextureTerrain, terrain)) {
      return;
    }
    _pendingCurveTextureTerrain = terrain;
    _metrics.textureRequests++;
    final clock = Stopwatch()..start();
    (_debug?.textureLoader?.call(terrain) ??
            _FluviWaveSurfaceTexture.fromTerrain(
              terrain,
            ).then((texture) => texture.image))
        .then((image) {
          _metrics.textureMicros += clock.elapsedMicroseconds;
          if (!mounted || !identical(_pendingCurveTextureTerrain, terrain)) {
            image.dispose();
            _metrics.textureDisposals++;
            return;
          }
          final previous = _curveTexture;
          setState(() {
            _curveTexture = image;
            _curveTextureTerrain = terrain;
            _metrics.texturePublications++;
            _pendingCurveTextureTerrain = null;
          });
          previous?.dispose();
          if (previous != null) _metrics.textureDisposals++;
        })
        .catchError((Object _) {
          if (identical(_pendingCurveTextureTerrain, terrain)) {
            _pendingCurveTextureTerrain = null;
          }
        });
  }

  int? get _selectedIndex => widget.selectedIndex ?? _tappedIndex;

  @override
  void didUpdateWidget(covariant FluviTopographicWaveChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values)) _tappedIndex = null;
    if (oldWidget.style != FluviTopographicWaveStyle.shaderAtmosphere &&
        widget.style == FluviTopographicWaveStyle.shaderAtmosphere) {
      _loadSurfaceShader();
    }
    if (oldWidget.style == FluviTopographicWaveStyle.shaderAtmosphere &&
        widget.style != FluviTopographicWaveStyle.shaderAtmosphere) {
      _releaseShaderResources();
    }
  }

  void _releaseShaderResources() {
    _shaderGeneration += 1;
    _pendingCurveTextureTerrain = null;
    _surfaceShader?.dispose();
    _surfaceShader = null;
    _curveTexture?.dispose();
    if (_curveTexture != null) _metrics.textureDisposals++;
    _curveTexture = null;
    _curveTextureTerrain = null;
    _metrics.shaderState = 'not-requested';
  }

  @override
  void dispose() {
    _releaseShaderResources();
    _metrics.disposed = true;
    if (kFluviOnscreenDiagnosticsEnabled) {
      FluviDiagnosticLogger.unregisterUserMarkerContext(
        _diagnosticOwner,
        _diagnosticSnapshot,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final before = _geometryCache._terrain;
      final clock = Stopwatch()..start();
      final terrain = _geometryCache.resolve(values: widget.values, size: size);
      if (!identical(before, terrain)) {
        _metrics.geometryBuilds++;
        _metrics.geometryMicros += clock.elapsedMicroseconds;
      }
      if (widget.style == FluviTopographicWaveStyle.shaderAtmosphere) {
        _synchronizeCurveTexture(terrain);
      }
      final boundTexture = identical(_curveTextureTerrain, terrain)
          ? _curveTexture
          : null;
      _metrics.textureTerrain = boundTexture == null ? null : terrain;
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
                if (widget.style ==
                        FluviTopographicWaveStyle.shaderAtmosphere &&
                    !(_debug?.opaqueBody ?? false) &&
                    (_debug?.atmosphere ?? true))
                  const _ShaderAtmosphereLayer(),
                RepaintBoundary(
                  key: ValueKey<String>(
                    'balance-monthly-spending-wave-repaint-${widget.style.name}',
                  ),
                  child: CustomPaint(
                    painter: _FluviTopographicWavePainter(
                      terrain: terrain,
                      metrics: _metrics,
                      debug: _debug,
                      style: widget.style,
                      surfaceShader:
                          widget.style ==
                              FluviTopographicWaveStyle.shaderAtmosphere
                          ? _surfaceShader
                          : null,
                      curveTexture:
                          widget.style ==
                              FluviTopographicWaveStyle.shaderAtmosphere
                          ? boundTexture
                          : null,
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
    required this.surfaceBounds,
    required this.color,
    required this.opacity,
    required this.blurSigma,
  });

  final Path path;
  final Path fillPath;
  final Rect surfaceBounds;
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
    required this.surfaceFootSamples,
    required this.surfacePath,
    required this.surfaceMesh,
    required this.areaPath,
    required this.depthLayers,
    required this.atmospheres,
    required this.dataOffsets,
    required this.highestIndex,
    required this.values,
  });

  final Size size;
  final Rect plot;
  double get financialBaseline => _baselineFor(plot);

  static double _baselineFor(Rect plot) => plot.bottom - plot.height * .25;
  final List<Offset> ridgeSamples;
  final Path ridgePath;

  /// Per-sample local material depth. This is visual volume only; the actual
  /// monetary position remains [ridgeSamples] and is never transformed.
  final List<Offset> surfaceFootSamples;
  final Path surfacePath;
  final ui.Vertices? surfaceMesh;

  /// Retained public compatibility alias for callers that previously inspected
  /// the old gradient body. It now is the local-depth body, not a plot-wide
  /// baseline fill.
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
        surfaceFootSamples: const <Offset>[],
        surfacePath: Path(),
        surfaceMesh: null,
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
        surfaceFootSamples: const <Offset>[],
        surfacePath: Path(),
        surfaceMesh: null,
        areaPath: Path(),
        depthLayers: const <FluviTopographicWaveDepthLayer>[],
        atmospheres: List<FluviTopographicWaveAtmosphericLayer>.unmodifiable(
          _atmospheres(plot: plot, normalizedMean: 0, volatility: 0),
        ),
        dataOffsets: const <Offset>[],
        highestIndex: null,
        values: List<FluviTopographicWaveDatum>.unmodifiable(values),
      );
    }
    // The financial zero is not the clipping boundary. Keep a real foreground
    // below zero, so small and zero days in a nonempty month retain a body.
    final drawableHeight = plot.height * .62;
    final baseline = _baselineFor(plot);
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
    final feet = _surfaceFeet(samples, plot);
    final surfacePath = _closedPath(samples, feet);
    const layerCount = 30;
    final depths = List<FluviTopographicWaveDepthLayer>.generate(layerCount, (
      index,
    ) {
      final depth = index / (layerCount - 1);
      final flattened = List<Offset>.generate(
        samples.length,
        (sampleIndex) => Offset(
          samples[sampleIndex].dx,
          _lerp(samples[sampleIndex].dy, feet[sampleIndex].dy, depth * .82),
        ),
        growable: false,
      );
      return FluviTopographicWaveDepthLayer(
        depth: depth,
        path: _pathFor(flattened),
        opacity: .135 * math.pow(1 - depth, 1.7).toDouble(),
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
      surfaceFootSamples: List<Offset>.unmodifiable(feet),
      surfacePath: surfacePath,
      surfaceMesh: _surfaceMesh(samples, feet, plot),
      areaPath: surfacePath,
      depthLayers: List<FluviTopographicWaveDepthLayer>.unmodifiable(depths),
      atmospheres: List<FluviTopographicWaveAtmosphericLayer>.unmodifiable(
        _atmospheres(
          plot: plot,
          normalizedMean: normalizedMean,
          volatility: volatility,
        ),
      ),
      dataOffsets: List<Offset>.unmodifiable(offsets),
      highestIndex: highestIndex,
      values: List<FluviTopographicWaveDatum>.unmodifiable(values),
    );
  }

  static List<Offset> _surfaceFeet(List<Offset> ridge, Rect plot) =>
      List<Offset>.generate(ridge.length, (index) {
        final point = ridge[index];
        final heightAboveFloor = plot.bottom - point.dy;
        // The shallow foreground remains an authored material thickness, not
        // a financial transform. It lets a low-but-real day receive the same
        // light/shadow grammar as a tall day while preserving ridge Y exactly.
        final thickness = math.max(
          plot.height * .14,
          heightAboveFloor * .60 + plot.height * .02,
        );
        final localSlope = _slopeAt(ridge, index).abs();
        final slopeLift = math.min(plot.height * .045, localSlope * 8);
        return Offset(
          point.dx,
          math.min(plot.bottom - 1.2, point.dy + thickness + slopeLift),
        );
      }, growable: false);

  static double _slopeAt(List<Offset> samples, int index) {
    if (samples.length < 2) return 0;
    final previous = samples[math.max(0, index - 1)];
    final next = samples[math.min(samples.length - 1, index + 1)];
    final dx = next.dx - previous.dx;
    return dx.abs() < .001 ? 0 : (next.dy - previous.dy) / dx;
  }

  static double _lerp(double start, double end, double amount) =>
      start + (end - start) * amount.clamp(0.0, 1.0);

  static Path _closedPath(List<Offset> ridge, List<Offset> feet) {
    final path = _pathFor(ridge);
    for (final point in feet.reversed) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static ui.Vertices? _surfaceMesh(
    List<Offset> ridge,
    List<Offset> feet,
    Rect plot,
  ) {
    if (ridge.length < 2 || ridge.length != feet.length) return null;
    const rows = 12;
    final columns = ridge.length;
    final positions = Float32List(columns * rows * 2);
    final colors = Int32List(columns * rows);
    for (var column = 0; column < columns; column += 1) {
      final slope = _slopeAt(ridge, column);
      for (var row = 0; row < rows; row += 1) {
        final depth = row / (rows - 1);
        final vertex = column * rows + row;
        positions[vertex * 2] = ridge[column].dx;
        positions[vertex * 2 + 1] = _lerp(
          ridge[column].dy,
          feet[column].dy,
          depth,
        );
        colors[vertex] = _surfaceColor(depth, slope).toARGB32();
      }
    }
    final indices = Uint16List((columns - 1) * (rows - 1) * 6);
    var write = 0;
    for (var column = 0; column < columns - 1; column += 1) {
      for (var row = 0; row < rows - 1; row += 1) {
        final topLeft = column * rows + row;
        final topRight = (column + 1) * rows + row;
        final bottomLeft = topLeft + 1;
        final bottomRight = topRight + 1;
        indices[write++] = topLeft;
        indices[write++] = topRight;
        indices[write++] = bottomLeft;
        indices[write++] = topRight;
        indices[write++] = bottomRight;
        indices[write++] = bottomLeft;
      }
    }
    return ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      colors: colors,
      indices: indices,
    );
  }

  static Color _surfaceColor(double depth, double slope) {
    final material = switch (depth) {
      < .045 => Color.lerp(
        const Color(0xfffbfaff),
        const Color(0xffb7abff),
        depth / .045,
      )!,
      < .18 => Color.lerp(
        const Color(0xff9a84f4),
        const Color(0xff725cd4),
        (depth - .045) / .135,
      )!,
      < .56 => Color.lerp(
        const Color(0xff8e78e6),
        const Color(0xffc8c5fa),
        (depth - .18) / .38,
      )!,
      < .86 => Color.lerp(
        const Color(0xffc8c5fa),
        const Color(0xffdcebfa),
        (depth - .56) / .30,
      )!,
      _ => Color.lerp(
        const Color(0xffdcebfa),
        const Color(0xfff5f7ff),
        (depth - .86) / .14,
      )!,
    };
    // A small local normal approximation gives the left/front light a
    // continuous response across the material rather than a global wash.
    final light = (.72 - slope * .32).clamp(.42, .96).toDouble();
    final lit = Color.lerp(const Color(0xffffffff), material, light)!;
    final alpha = (.94 * math.pow(1 - depth, .62)).clamp(.08, .94).toDouble();
    return lit.withValues(alpha: alpha);
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
    // These are actual closed decorative surfaces, not a global baseline
    // fill. Their independent silhouettes make depth readable even beneath a
    // highly spiked real month.
    const opacities = <double>[.14, .115, .09, .064];
    const blurSigmas = <double>[3.5, 3, 2.2, 1.5];
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
        final feet = List<Offset>.generate(sampled.length, (sampleIndex) {
          final point = sampled[sampleIndex];
          final thickness =
              plot.height * (.13 + index * .018) +
              math.sin(sampleIndex * .11 + index) * plot.height * .012;
          return Offset(
            point.dx,
            math.min(plot.bottom - 2, point.dy + thickness),
          );
        }, growable: false);
        final fillPath = _closedPath(sampled, feet);
        return FluviTopographicWaveAtmosphericLayer(
          path: path,
          fillPath: fillPath,
          surfaceBounds: fillPath.getBounds(),
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

/// A compact, cached 1-D ridge/foot/slope lookup for the bounded material
/// shader. It is rebuilt only with [FluviTopographicWaveTerrain], never per
/// animation frame or marker interaction.
final class _FluviWaveSurfaceTexture {
  const _FluviWaveSurfaceTexture._(this.image);

  final ui.Image image;

  static Future<_FluviWaveSurfaceTexture> fromTerrain(
    FluviTopographicWaveTerrain terrain,
  ) {
    const width = 256;
    final bytes = Uint8List(width * 4);
    final samples = terrain.ridgeSamples;
    final feet = terrain.surfaceFootSamples;
    for (var index = 0; index < width; index += 1) {
      final position = index / (width - 1) * (samples.length - 1);
      final lower = position.floor();
      final upper = position.ceil().clamp(0, samples.length - 1);
      final amount = position - lower;
      final ridgeY = FluviTopographicWaveTerrain._lerp(
        samples[lower].dy,
        samples[upper].dy,
        amount,
      );
      final footY = FluviTopographicWaveTerrain._lerp(
        feet[lower].dy,
        feet[upper].dy,
        amount,
      );
      final slope =
          (feet[upper].dx == feet[lower].dx
                  ? 0
                  : (samples[upper].dy - samples[lower].dy) /
                        (feet[upper].dx - feet[lower].dx))
              .clamp(-1.0, 1.0)
              .toDouble();
      final offset = index * 4;
      bytes[offset] = ((ridgeY - terrain.plot.top) / terrain.plot.height * 255)
          .clamp(0, 255)
          .round();
      bytes[offset +
          1] = ((footY - terrain.plot.top) / terrain.plot.height * 255)
          .clamp(0, 255)
          .round();
      bytes[offset + 2] = ((slope + 1) * .5 * 255).clamp(0, 255).round();
      bytes[offset + 3] = 255;
    }
    final result = Completer<_FluviWaveSurfaceTexture>();
    ui.decodeImageFromPixels(
      bytes,
      width,
      1,
      ui.PixelFormat.rgba8888,
      (image) => result.complete(_FluviWaveSurfaceTexture._(image)),
    );
    return result.future;
  }
}

final class _FluviTopographicWavePainter extends CustomPainter {
  const _FluviTopographicWavePainter({
    required this.terrain,
    required this.style,
    required this.surfaceShader,
    required this.curveTexture,
    required this.selectedIndex,
    required this.tooltipForValue,
    required this.metrics,
    required this.debug,
  });

  final FluviTopographicWaveTerrain terrain;
  final FluviTopographicWaveStyle style;
  final ui.FragmentShader? surfaceShader;
  final ui.Image? curveTexture;
  final int? selectedIndex;
  final String Function(int value) tooltipForValue;
  final FluviWaveRenderMetrics metrics;
  final FluviWaveDebugScope? debug;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
    );
    metrics.markerBounds = null;
    metrics.tooltipBounds = null;
    metrics.selectedIndex = null;
    if (!(debug?.opaqueBody ?? false) && (debug?.atmosphere ?? true)) {
      _drawAtmospheres(canvas);
    }
    if (terrain.ridgeSamples.isEmpty) {
      metrics.recordPaint(terrain, 'empty');
      debug?.onPaint?.call(metrics);
      canvas.restore();
      return;
    }
    if (debug?.opaqueBody ?? false) {
      canvas.drawPath(
        terrain.surfacePath,
        Paint()..color = const Color(0xff9682f2),
      );
      metrics.recordPaint(terrain, 'opaque-diagnostic');
    } else {
      _drawGuides(canvas);
      _drawSurface(canvas);
      if (debug?.contours ?? true) _drawContours(canvas);
      _drawRidge(canvas);
      _drawMarkerAndTooltip(canvas, size);
      metrics.recordPaint(
        terrain,
        surfaceShader != null && curveTexture != null ? 'shader' : 'mesh',
      );
    }
    if (debug?.bounds ?? false) {
      canvas.drawRect(
        (Offset.zero & size).deflate(.5),
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke,
      );
      canvas.drawRect(
        terrain.plot,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        Offset(terrain.plot.left, terrain.financialBaseline),
        Offset(terrain.plot.right, terrain.financialBaseline),
        Paint()..color = Colors.orange,
      );
      canvas.drawPath(
        terrain.ridgePath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        FluviTopographicWaveTerrain._pathFor(terrain.surfaceFootSamples),
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke,
      );
    }
    debug?.onPaint?.call(metrics);
    canvas.restore();
  }

  void _drawAtmospheres(Canvas canvas) {
    final reduction = switch (style) {
      FluviTopographicWaveStyle.terrain => .82,
      FluviTopographicWaveStyle.svgReference => 1.0,
      FluviTopographicWaveStyle.shaderAtmosphere => .9,
    };
    for (final wave in terrain.atmospheres) {
      canvas.drawPath(
        wave.fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              wave.color.withValues(alpha: wave.opacity * reduction),
              Color.lerp(
                wave.color,
                FluviTopographicWavePalette.pearl,
                .5,
              )!.withValues(alpha: wave.opacity * .18 * reduction),
              wave.color.withValues(alpha: 0),
            ],
            stops: const <double>[0, .54, 1],
          ).createShader(wave.surfaceBounds)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, wave.blurSigma)
          ..isAntiAlias = true,
      );
      canvas.drawPath(
        wave.path,
        Paint()
          ..color = wave.color.withValues(alpha: wave.opacity * .9 * reduction)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
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

  void _drawSurface(Canvas canvas) {
    final shader = surfaceShader;
    final texture = curveTexture;
    if (shader != null && texture != null) {
      canvas.save();
      canvas.clipPath(terrain.surfacePath);
      shader.setFloat(0, terrain.size.width);
      shader.setFloat(1, terrain.size.height);
      shader.setFloat(2, switch (style) {
        FluviTopographicWaveStyle.terrain => .82,
        FluviTopographicWaveStyle.svgReference => .94,
        FluviTopographicWaveStyle.shaderAtmosphere => 1.0,
      });
      shader.setFloat(3, terrain.plot.left);
      shader.setFloat(4, terrain.plot.top);
      shader.setFloat(5, terrain.plot.width);
      shader.setFloat(6, terrain.plot.height);
      shader.setImageSampler(0, texture, filterQuality: FilterQuality.medium);
      canvas.drawRect(terrain.plot, Paint()..shader = shader);
      canvas.restore();
      return;
    }
    final mesh = terrain.surfaceMesh;
    if (mesh != null) {
      canvas.drawVertices(mesh, BlendMode.srcOver, Paint()..isAntiAlias = true);
    }
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
          ..strokeWidth = .45 + (1 - layer.depth) * .35
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }
  }

  void _drawRidge(Canvas canvas) {
    final glowOpacity = style == FluviTopographicWaveStyle.svgReference
        ? .25
        : .18;
    if (debug?.glow ?? true) {
      canvas.drawPath(
        terrain.ridgePath,
        Paint()
          ..color = FluviTopographicWavePalette.violet.withValues(
            alpha: glowOpacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4)
          ..isAntiAlias = true,
      );
    }
    canvas.drawPath(
      terrain.ridgePath,
      Paint()
        ..color = FluviTopographicWavePalette.pearl.withValues(alpha: .86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
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
        ..strokeWidth = 1.9
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
    metrics.selectedIndex = index;
    metrics.markerBounds = Rect.fromCircle(center: point, radius: 6.25);
    if (debug?.glow ?? true) {
      canvas.drawCircle(
        point,
        10,
        Paint()
          ..color = FluviTopographicWavePalette.violet.withValues(alpha: .22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
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
    metrics.tooltipBounds = bubble.outerRect;
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
      oldDelegate.debug != debug ||
      oldDelegate.style != style ||
      oldDelegate.surfaceShader != surfaceShader ||
      oldDelegate.curveTexture != curveTexture ||
      oldDelegate.selectedIndex != selectedIndex;
}
