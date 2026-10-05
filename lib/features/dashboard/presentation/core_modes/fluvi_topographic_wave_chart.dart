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
part 'fluvi_wave_surface_lookup.dart';
part 'fluvi_wave_material.dart';

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
  static const pearl = Color(0xfffbfaff);
  static const lavender = Color(0xffb7abff);
  static const periwinkle = Color(0xffc8c5fa);
  static const violet = Color(0xff9682f2);
  static const deepViolet = Color(0xff725cd4);
  static const icyBlue = Color(0xffdcebfa);
  static const mist = Color(0xfff5f7ff);
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
                    !MediaQuery.disableAnimationsOf(context) &&
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
                      fontFamily: Theme.of(
                        context,
                      ).textTheme.bodySmall?.fontFamily,
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
    required this.mesh,
  });

  final Path path;
  final Path fillPath;
  final Rect surfaceBounds;
  final Color color;
  final double opacity;
  final double blurSigma;
  final ui.Vertices? mesh;
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

  static double _baselineFor(Rect plot) => plot.top + plot.height * .65;
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
      math.min(10, size.width / 2),
      math.min(36, size.height * .4),
      math.max(10, size.width - 10),
      math.max(36, size.height - 4),
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
    final baseline = _baselineFor(plot);
    final drawableHeight = baseline - plot.top;
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
    final layerCount = (plot.height / 8).round().clamp(6, 14);
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
        opacity: .07 * math.pow(1 - depth, 1.7).toDouble(),
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
        final x = (point.dx - plot.left) / plot.width;
        // A calm material shore, not a displaced copy of financial peaks.
        // Its highest point is below the genuine zero baseline at every x.
        return Offset(
          point.dx,
          plot.bottom -
              plot.height * (.04 + .025 * math.cos(x * math.pi * 2 - .4)),
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
    Rect plot, {
    double opacity = 1,
    double distance = 0,
  }) {
    if (ridge.length < 2 || ridge.length != feet.length) return null;
    const rows = 24;
    final columns = ridge.length;
    final positions = Float32List(columns * rows * 2);
    final colors = Int32List(columns * rows);
    for (var column = 0; column < columns; column += 1) {
      final slope = _slopeAt(ridge, column);
      final footSlope = _slopeAt(feet, column);
      for (var row = 0; row < rows; row += 1) {
        final depth = row / (rows - 1);
        final vertex = column * rows + row;
        positions[vertex * 2] = ridge[column].dx;
        positions[vertex * 2 + 1] = _lerp(
          ridge[column].dy,
          feet[column].dy,
          depth,
        );
        final color = _FluviWaveMaterial.color(depth, slope, footSlope);
        colors[vertex] = Color.lerp(
          color,
          FluviTopographicWavePalette.periwinkle.withValues(alpha: color.a),
          distance,
        )!.withValues(alpha: color.a * opacity).toARGB32();
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
      [.83, .63, .33, .59, .71, .42, .54, .68, .30, .60, .67, .83],
      [.87, .78, .59, .74, .45, .67, .78, .46, .63, .72, .52, .88],
      [.90, .80, .72, .46, .74, .79, .40, .68, .78, .47, .75, .91],
    ];
    final empty = normalizedMean == 0 && volatility == 0;
    return List<FluviTopographicWaveAtmosphericLayer>.generate(
      profiles.length,
      (index) {
        final controls = <Offset>[
          for (var point = 0; point < profiles[index].length; point += 1)
            Offset(
              plot.left + plot.width * point / (profiles[index].length - 1),
              plot.top +
                  plot.height *
                      (empty
                          ? .82 + profiles[index][point] * .12
                          : profiles[index][point]),
            ),
        ];
        final sampled = _catmullRomSamples(
          controls,
          plot,
          samplesPerSegment: 18,
        );
        final path = _pathFor(sampled);
        final feet = _surfaceFeet(sampled, plot);
        final fillPath = _closedPath(sampled, feet);
        final opacity = empty ? .13 : .48 + index * .10;
        return FluviTopographicWaveAtmosphericLayer(
          path: path,
          fillPath: fillPath,
          surfaceBounds: fillPath.getBounds(),
          color: FluviTopographicWavePalette.periwinkle,
          opacity: opacity,
          blurSigma: 0,
          mesh: _surfaceMesh(
            sampled,
            feet,
            plot,
            opacity: opacity,
            distance: .65 - index * .16,
          ),
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
    final x = _lerp(start.dx, end.dx, t);
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
    required this.surfaceShader,
    required this.curveTexture,
    required this.selectedIndex,
    required this.tooltipForValue,
    required this.metrics,
    required this.debug,
    required this.fontFamily,
  });

  final FluviTopographicWaveTerrain terrain;
  final FluviTopographicWaveStyle style;
  final ui.FragmentShader? surfaceShader;
  final ui.Image? curveTexture;
  final int? selectedIndex;
  final String Function(int value) tooltipForValue;
  final FluviWaveRenderMetrics metrics;
  final FluviWaveDebugScope? debug;
  final String? fontFamily;

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
    if (!(debug?.opaqueBody ?? false) &&
        !(debug?.materialOnly ?? false) &&
        (debug?.atmosphere ?? true)) {
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
      if (!(debug?.materialOnly ?? false)) _drawGuides(canvas);
      _drawSurface(canvas);
      if (!(debug?.materialOnly ?? false)) {
        if (debug?.contours ?? true) _drawContours(canvas);
        _drawRidge(canvas);
        _drawMarkerAndTooltip(canvas, size);
      }
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
    for (final wave in terrain.atmospheres) {
      if (wave.mesh != null) {
        canvas.drawVertices(
          wave.mesh!,
          BlendMode.srcOver,
          Paint()..isAntiAlias = true,
        );
      }
      canvas.drawPath(
        wave.path,
        Paint()
          ..color = FluviTopographicWavePalette.pearl.withValues(
            alpha: wave.opacity * .45,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = .5
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
      shader.setFloat(2, 1);
      shader.setFloat(3, terrain.plot.left);
      shader.setFloat(4, terrain.plot.top);
      shader.setFloat(5, terrain.plot.width);
      shader.setFloat(6, terrain.plot.height);
      _FluviWaveMaterial.bind(shader);
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
        ? .13
        : .08;
    if (debug?.glow ?? true) {
      canvas.drawPath(
        terrain.ridgePath,
        Paint()
          ..color = FluviTopographicWavePalette.violet.withValues(
            alpha: glowOpacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
          ..isAntiAlias = true,
      );
    }
    canvas.drawPath(
      terrain.ridgePath,
      Paint()
        ..color = FluviTopographicWavePalette.pearl.withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9
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
        ..color = FluviTopographicWavePalette.violet
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      point,
      5.1,
      Paint()
        ..color = FluviTopographicWavePalette.pearl
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    final label = tooltipForValue(terrain.values[index].value);
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: fontFamily,
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
      oldDelegate.fontFamily != fontFamily ||
      oldDelegate.style != style ||
      oldDelegate.surfaceShader != surfaceShader ||
      oldDelegate.curveTexture != curveTexture ||
      oldDelegate.selectedIndex != selectedIndex;
}
