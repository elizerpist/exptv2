import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_static_color_renderer.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

/// Raster evidence for the Header material contract.  The neutral palette is
/// monotonic, so inverse palette lookup recovers the transported U coordinate
/// without making any Cool-colour-specific assumption.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const effects = <DashboardHeaderEffectId>[
    DashboardHeaderEffectId.dualTide,
    DashboardHeaderEffectId.magneticMembrane,
    DashboardHeaderEffectId.breathingLens,
    DashboardHeaderEffectId.cellularField,
    DashboardHeaderEffectId.balanceMembrane,
    DashboardHeaderEffectId.balanceCounterflow,
    DashboardHeaderEffectId.balanceCharges,
    DashboardHeaderEffectId.deepDrift,
  ];

  group('Header seamless material transport distribution', () {
    test('RED source contract rejects scalar palette attraction and shared seam light', () async {
      final shader = await File('shaders/dashboard_header_field.frag').readAsString();
      final commonStart = shader.indexOf('vec3 commonField');
      final commonEnd = shader.indexOf('float portalValue', commonStart);
      final common = shader.substring(commonStart, commonEnd);

      expect(shader, contains('vec2 boundedMaterialSourceUv('));
      expect(shader, contains('float distributionSafePaletteCoordinate('));
      expect(shader, contains('float materialBoundaryEnvelope('));
      expect(common, isNot(contains('(mixture - p.x)')));
      expect(common, isNot(contains('float seam = 4.0 * mixture')));
      expect(common, isNot(contains(') * seam +')));
      expect(common, contains('canonicalGradientCoordinate(sourceUv)'));
      expect(common, contains('distributionSafePaletteCoordinate('));
    });

    test('RED Portal channels move spatial material rather than assigning a mask palette coordinate', () async {
      final shader = await File('shaders/dashboard_header_field.frag').readAsString();
      final composition = shader.substring(
        shader.indexOf('float backgroundMatter'),
        shader.indexOf('float overlayAlpha'),
      );

      expect(composition, contains('portalMaterialCoordinate('));
      expect(
        composition,
        isNot(contains('mix(\n      backgroundLeft, backgroundRight, saturate(backgroundMatter))')),
      );
      expect(composition, isNot(contains('float tint = smooth01(')));
    });

    testWidgets('RED-02 static 112-degree reference distribution is deterministic', (tester) async {
      final raster = await _renderStatic(tester, _neutralFrame);
      final metrics = _DistributionMetrics.fromNeutralRaster(raster);

      expect(metrics.binCount, 64);
      expect(metrics.normalizedEntropy, greaterThan(.90));
      expect(metrics.central70Mass, greaterThan(.55));
      expect(metrics.p05, lessThan(metrics.p25));
      expect(metrics.p25, lessThan(metrics.p50));
      expect(metrics.p50, lessThan(metrics.p75));
      expect(metrics.p75, lessThan(metrics.p95));
    });

    for (final effect in effects) {
      testWidgets('RED distribution baseline: ${effect.name}', (tester) async {
        final staticRaster = await _renderStatic(tester, _neutralFrame);
        final staticMetrics = _DistributionMetrics.fromNeutralRaster(staticRaster);
        final animatedRaster = await _renderEffect(
          tester: tester,
          effect: effect,
          frame: _neutralFrame,
          coordinateOnly: true,
        );
        final metrics = _DistributionMetrics.fromNeutralRaster(animatedRaster);
        final derivative = _DerivativeMetrics.fromNeutralRaster(animatedRaster);
        final middle = _MiddleBandMetrics.fromNeutralRaster(animatedRaster);

        debugPrint('$effect static=$staticMetrics animated=$metrics derivative=$derivative middle=$middle');
        expect(metrics.normalizedEntropy, greaterThanOrEqualTo(staticMetrics.normalizedEntropy - .05));
        expect(metrics.left15Mass, lessThanOrEqualTo(staticMetrics.left15Mass + .06));
        expect(metrics.right15Mass, lessThanOrEqualTo(staticMetrics.right15Mass + .06));
        expect(metrics.central70Mass, greaterThanOrEqualTo(staticMetrics.central70Mass * .90));
        expect(metrics.maxBinMass, lessThanOrEqualTo(staticMetrics.maxBinMass * 1.8));
        expect(metrics.wassersteinFrom(staticMetrics), lessThanOrEqualTo(.10));
        expect(middle.medianLongestRun, greaterThanOrEqualTo(.035));
        expect(derivative.nearZeroRun, lessThanOrEqualTo(18));
        // Eight-bit raster recovery creates isolated ±1-code reversals near
        // flat material. Sustained ribbon stacking is materially above this
        // tolerance; it preserves Deep Drift's current passing evidence.
        expect(derivative.foldCount, lessThanOrEqualTo(8));
      });
    }

    for (final effect in effects) {
      testWidgets('RED constant-colour optics have no narrow seam ridge: ${effect.name}', (tester) async {
        final raster = await _renderEffect(
          tester: tester,
          effect: effect,
          frame: _constantFrame,
        );
        final optics = _OpticalStripeMetrics.fromConstantRaster(raster);
        debugPrint('$effect optical=$optics');

        expect(optics.ridgePeakDelta, lessThanOrEqualTo(.12));
        expect(optics.p95Delta, lessThanOrEqualTo(.07));
        expect(optics.ridgeCoverage, lessThanOrEqualTo(.24));
        expect(optics.narrowRidgeCoverage, lessThanOrEqualTo(.08));
      });
    }

    for (final effect in <DashboardHeaderEffectId>[
      DashboardHeaderEffectId.dualTide,
      DashboardHeaderEffectId.magneticMembrane,
      DashboardHeaderEffectId.breathingLens,
      DashboardHeaderEffectId.cellularField,
    ]) {
      testWidgets('RED real Cool physical scenario P45 W100: ${effect.name}', (tester) async {
        final raster = await _renderEffect(
          tester: tester,
          effect: effect,
          frame: _realCoolWideFrame,
          coordinateOnly: true,
        );
        final metrics = _DistributionMetrics.fromPaletteRaster(
          raster,
          _realCoolWideFrame,
        );
        expect(metrics.occupiedBins, greaterThanOrEqualTo(38));
        expect(metrics.maxBinMass, lessThanOrEqualTo(.095));
        expect(metrics.central70Mass, greaterThanOrEqualTo(.58));
      });
    }

    for (final window in <({String name, DashboardHeaderVisualFrame frame})>[
      (name: 'P45 W43', frame: _realCoolNarrow43Frame),
      (name: 'P50 W28', frame: _realCoolNarrow28Frame),
    ]) {
      testWidgets('RED narrow Cool window stays material-distributed: ${window.name}', (tester) async {
        final staticRaster = await _renderStatic(tester, window.frame);
        final staticMetrics = _DistributionMetrics.fromPaletteRaster(staticRaster, window.frame);
        final raster = await _renderEffect(
          tester: tester,
          effect: DashboardHeaderEffectId.dualTide,
          frame: window.frame,
          coordinateOnly: true,
        );
        final metrics = _DistributionMetrics.fromPaletteRaster(raster, window.frame);
        expect(metrics.wassersteinFrom(staticMetrics), lessThanOrEqualTo(.10));
        expect(metrics.maxBinMass, lessThanOrEqualTo(staticMetrics.maxBinMass * 1.8));
      });
    }

    testWidgets('RED strong transport still avoids binary palette continents', (tester) async {
      final staticRaster = await _renderStatic(tester, _neutralFrame);
      final staticMetrics = _DistributionMetrics.fromNeutralRaster(staticRaster);
      final raster = await _renderEffect(
        tester: tester,
        effect: DashboardHeaderEffectId.dualTide,
        frame: _neutralFrame,
        strength: 1,
        coordinateOnly: true,
      );
      final metrics = _DistributionMetrics.fromNeutralRaster(raster);
      expect(metrics.normalizedEntropy, greaterThanOrEqualTo(staticMetrics.normalizedEntropy - .10));
      expect(metrics.central70Mass, greaterThanOrEqualTo(staticMetrics.central70Mass * .78));
      expect(metrics.maxBinMass, lessThanOrEqualTo(staticMetrics.maxBinMass * 2.1));
    });

    testWidgets('RED Portal background and interior preserve continuous material coordinates', (tester) async {
      for (final channel in <DashboardHeaderPortalChannel>[
        DashboardHeaderPortalChannel.backgroundMorph,
        DashboardHeaderPortalChannel.innerMotion,
      ]) {
        final raster = await _renderEffect(
          tester: tester,
          effect: DashboardHeaderEffectId.magneticMembrane,
          frame: _neutralFrame,
          coordinateOnly: true,
          portal: channel,
        );
        final metrics = _DistributionMetrics.fromNeutralRaster(raster);
        expect(metrics.occupiedBins, greaterThanOrEqualTo(36));
        expect(metrics.maxBinMass, lessThanOrEqualTo(.11));
      }
    });
  });
}

const _neutralFrame = DashboardHeaderVisualFrame(
  colors: <Color>[Color(0xff000000), Color(0xff808080), Color(0xffffffff)],
  stops: <double>[0, .5, 1],
  opacity: 1,
  colorA: Color(0xff000000),
  colorB: Color(0xffffffff),
  paletteSplitPercent: 50,
);

const _constantFrame = DashboardHeaderVisualFrame(
  colors: <Color>[Color(0xff42657c), Color(0xff42657c), Color(0xff42657c)],
  stops: <double>[0, .5, 1],
  opacity: 1,
  colorA: Color(0xff42657c),
  colorB: Color(0xff42657c),
  paletteSplitPercent: 50,
);

// These fixed probes are the current live three-stop Cool projection for the
// user-observed wide/narrow scenarios. They are intentionally non-neutral so
// the inversion exercises the actual palette path as well as U geometry.
const _realCoolWideFrame = DashboardHeaderVisualFrame(
  colors: <Color>[Color(0xfff1fcff), Color(0xff14c5e1), Color(0xff003c93)],
  stops: <double>[0, .5, 1],
  opacity: 1,
  colorA: Color(0xfff1fcff),
  colorB: Color(0xff003c93),
  paletteSplitPercent: 45,
);

const _realCoolNarrow43Frame = DashboardHeaderVisualFrame(
  colors: <Color>[Color(0xffb9f5ff), Color(0xff14c5e1), Color(0xff056bb8)],
  stops: <double>[0, .5, 1],
  opacity: 1,
  colorA: Color(0xffb9f5ff),
  colorB: Color(0xff056bb8),
  paletteSplitPercent: 45,
);

const _realCoolNarrow28Frame = DashboardHeaderVisualFrame(
  colors: <Color>[Color(0xff61e1fb), Color(0xff14c5e1), Color(0xff0390ca)],
  stops: <double>[0, .5, 1],
  opacity: 1,
  colorA: Color(0xff61e1fb),
  colorB: Color(0xff0390ca),
  paletteSplitPercent: 50,
);

Future<_Raster> _renderStatic(
  WidgetTester tester,
  DashboardHeaderVisualFrame frame,
) async {
  final recorder = ui.PictureRecorder();
  DashboardHeaderStaticColorRenderer.paint(
    canvas: Canvas(recorder),
    rect: const Rect.fromLTWH(0, 0, 412, 188),
    colors: frame.colors,
    stops: frame.stops,
    opacity: frame.opacity,
  );
  final image = (await tester.runAsync(
    () => recorder.endRecording().toImage(_Raster.width, _Raster.height),
  ))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) throw StateError('Static Header pixels unavailable.');
    return _Raster(bytes);
  } finally {
    image.dispose();
  }
}

Future<_Raster> _renderEffect({
  required WidgetTester tester,
  required DashboardHeaderEffectId effect,
  required DashboardHeaderVisualFrame frame,
  bool coordinateOnly = false,
  double? strength,
  DashboardHeaderPortalChannel? portal,
}) async {
  final controller = DashboardHeaderVisualController(vsync: tester);
  controller.selectEffect(effect);
  if (strength != null) controller.setEffectControl('strength', strength);
  if (coordinateOnly) {
    final controls = DashboardHeaderEffectCatalog.effectFor(effect).controls
        .map((control) => control.id)
        .toSet();
    if (controls.contains('lightAmount')) {
      controller.setEffectControl('lightAmount', 0);
    }
    if (controls.contains('pulseAmount')) {
      controller.setEffectControl('pulseAmount', 0);
    }
  }
  if (portal != null) controller.setPortalEnabled(portal, true);
  controller.debugAdvance(const Duration(milliseconds: 825));
  final boundary = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: _Raster.width.toDouble(),
            height: _Raster.height.toDouble(),
            child: SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
  // Keep the Header paint layer in a separate replacement so its controller
  // receives the frozen phase after the framework first attaches the ticker.
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: _Raster.width.toDouble(),
            height: _Raster.height.toDouble(),
            child: DashboardHeaderVisualPaintLayer(
              controller: controller,
              frame: frame,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 17));
  final renderBoundary =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => renderBoundary.toImage()))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) throw StateError('Animated Header pixels unavailable.');
    return _Raster(bytes);
  } finally {
    image.dispose();
    controller.dispose();
  }
}

final class _Raster {
  const _Raster(this.bytes);

  static const int width = 412;
  static const int height = 188;
  final ByteData bytes;

  ({double red, double green, double blue}) rgbAt(int x, int y) {
    final index = (y * width + x) * 4;
    return (
      red: bytes.getUint8(index) / 255,
      green: bytes.getUint8(index + 1) / 255,
      blue: bytes.getUint8(index + 2) / 255,
    );
  }

  Iterable<({int x, int y, double r, double g, double b})> get pixels sync* {
    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        final rgb = rgbAt(x, y);
        yield (x: x, y: y, r: rgb.red, g: rgb.green, b: rgb.blue);
      }
    }
  }
}

final class _DistributionMetrics {
  _DistributionMetrics._(this._samples, this.histogram)
      : _sorted = List<double>.of(_samples)..sort();

  factory _DistributionMetrics.fromNeutralRaster(_Raster raster) =>
      _DistributionMetrics._(
        <double>[
          for (final pixel in raster.pixels)
            _clamp01((pixel.r + pixel.g + pixel.b) / 3),
        ],
        _histogram(
          <double>[
            for (final pixel in raster.pixels)
              _clamp01((pixel.r + pixel.g + pixel.b) / 3),
          ],
        ),
      );

  factory _DistributionMetrics.fromPaletteRaster(
    _Raster raster,
    DashboardHeaderVisualFrame frame,
  ) {
    final samples = <double>[
      for (final pixel in raster.pixels)
        _nearestPaletteCoordinate(pixel.r, pixel.g, pixel.b, frame),
    ];
    return _DistributionMetrics._(samples, _histogram(samples));
  }

  final List<double> _samples;
  final List<double> _sorted;
  final List<double> histogram;
  int get binCount => histogram.length;
  int get occupiedBins => histogram.where((mass) => mass > 0).length;
  double get normalizedEntropy {
    final entropy = histogram.fold<double>(0, (sum, mass) =>
        mass == 0 ? sum : sum - mass * math.log(mass));
    return entropy / math.log(binCount);
  }

  double get maxBinMass => histogram.reduce(math.max);
  double get p05 => _percentile(.05);
  double get p25 => _percentile(.25);
  double get p50 => _percentile(.50);
  double get p75 => _percentile(.75);
  double get p95 => _percentile(.95);
  double get left15Mass => _massWhere((u) => u < .15);
  double get right15Mass => _massWhere((u) => u > .85);
  double get central70Mass => _massWhere((u) => u >= .15 && u <= .85);
  double get mid40to60Mass => _massWhere((u) => u >= .40 && u <= .60);

  double wassersteinFrom(_DistributionMetrics other) {
    var own = 0.0;
    var reference = 0.0;
    var distance = 0.0;
    for (var index = 0; index < binCount; index += 1) {
      own += histogram[index];
      reference += other.histogram[index];
      distance += (own - reference).abs();
    }
    return distance / binCount;
  }

  double _percentile(double percentile) =>
      _sorted[(percentile * (_sorted.length - 1)).round()];
  double _massWhere(bool Function(double value) predicate) =>
      _samples.where(predicate).length / _samples.length;

  @override
  String toString() =>
      'entropy=${normalizedEntropy.toStringAsFixed(3)} max=${maxBinMass.toStringAsFixed(3)} '
      'p=${p05.toStringAsFixed(3)}/${p25.toStringAsFixed(3)}/${p50.toStringAsFixed(3)}/${p75.toStringAsFixed(3)}/${p95.toStringAsFixed(3)} '
      'outer=${left15Mass.toStringAsFixed(3)}/${right15Mass.toStringAsFixed(3)} '
      'central=${central70Mass.toStringAsFixed(3)} mid=${mid40to60Mass.toStringAsFixed(3)} bins=$occupiedBins';
}

final class _DerivativeMetrics {
  const _DerivativeMetrics({
    required this.p05,
    required this.median,
    required this.p95,
    required this.nearZeroRun,
    required this.foldCount,
  });

  factory _DerivativeMetrics.fromNeutralRaster(_Raster raster) {
    final slopes = <double>[];
    var maxZeroRun = 0;
    var folds = 0;
    // The static 112° direction is predominantly horizontal. These five
    // parallel cross-sections quantify U order without confusing a diagonal
    // material bend with a palette fold.
    for (final y in <int>[18, 52, 94, 136, 170]) {
      var zeroRun = 0;
      var previousSign = 0;
      for (var x = 1; x < _Raster.width; x += 1) {
        final before = raster.rgbAt(x - 1, y);
        final after = raster.rgbAt(x, y);
        final derivative = ((after.red + after.green + after.blue) -
                (before.red + before.green + before.blue)) /
            3 /
            _staticUIncrement;
        slopes.add(derivative);
        if (derivative.abs() < .12) {
          zeroRun += 1;
          maxZeroRun = math.max(maxZeroRun, zeroRun);
          continue;
        }
        zeroRun = 0;
        final sign = derivative.isNegative ? -1 : 1;
        if (previousSign != 0 && sign != previousSign) folds += 1;
        previousSign = sign;
      }
    }
    slopes.sort();
    return _DerivativeMetrics(
      p05: slopes[(slopes.length * .05).floor()],
      median: slopes[slopes.length ~/ 2],
      p95: slopes[(slopes.length * .95).floor()],
      nearZeroRun: maxZeroRun,
      foldCount: folds,
    );
  }

  static const _staticUIncrement = .9271838546 / _Raster.width;
  final double p05;
  final double median;
  final double p95;
  final int nearZeroRun;
  final int foldCount;

  @override
  String toString() =>
      'dU=${p05.toStringAsFixed(3)}/${median.toStringAsFixed(3)}/${p95.toStringAsFixed(3)} '
      'zeroRun=$nearZeroRun folds=$foldCount';
}

final class _MiddleBandMetrics {
  const _MiddleBandMetrics(this.medianLongestRun);

  factory _MiddleBandMetrics.fromNeutralRaster(_Raster raster) {
    final runs = <double>[];
    for (var y = 0; y < _Raster.height; y += 1) {
      var longest = 0;
      var run = 0;
      for (var x = 0; x < _Raster.width; x += 1) {
        final rgb = raster.rgbAt(x, y);
        final u = (rgb.red + rgb.green + rgb.blue) / 3;
        if (u >= .40 && u <= .60) {
          run += 1;
          longest = math.max(longest, run);
        } else {
          run = 0;
        }
      }
      runs.add(longest / _Raster.width);
    }
    runs.sort();
    return _MiddleBandMetrics(runs[runs.length ~/ 2]);
  }

  final double medianLongestRun;

  @override
  String toString() => 'middleRun=${medianLongestRun.toStringAsFixed(3)}';
}

final class _OpticalStripeMetrics {
  const _OpticalStripeMetrics({
    required this.ridgePeakDelta,
    required this.p95Delta,
    required this.ridgeCoverage,
    required this.narrowRidgeCoverage,
  });

  factory _OpticalStripeMetrics.fromConstantRaster(_Raster raster) {
    final luminance = <double>[
      for (final pixel in raster.pixels)
        pixel.r * .213 + pixel.g * .715 + pixel.b * .072,
    ]..sort();
    final baseline = luminance[luminance.length ~/ 2];
    final deltas = <double>[for (final value in luminance) (value - baseline).abs()]..sort();
    final ridge = deltas.where((delta) => delta > .055).length / deltas.length;
    final narrow = _narrowHorizontalRidgeCoverage(raster, baseline);
    return _OpticalStripeMetrics(
      ridgePeakDelta: deltas.last,
      p95Delta: deltas[(deltas.length * .95).floor()],
      ridgeCoverage: ridge,
      narrowRidgeCoverage: narrow,
    );
  }

  final double ridgePeakDelta;
  final double p95Delta;
  final double ridgeCoverage;
  final double narrowRidgeCoverage;

  @override
  String toString() =>
      'peak=${ridgePeakDelta.toStringAsFixed(3)} p95=${p95Delta.toStringAsFixed(3)} '
      'coverage=${ridgeCoverage.toStringAsFixed(3)} narrow=${narrowRidgeCoverage.toStringAsFixed(3)}';
}

List<double> _histogram(List<double> values) {
  final counts = List<int>.filled(64, 0);
  for (final value in values) {
    counts[(value * 64).floor().clamp(0, 63)] += 1;
  }
  return <double>[for (final count in counts) count / values.length];
}

double _nearestPaletteCoordinate(
  double red,
  double green,
  double blue,
  DashboardHeaderVisualFrame frame,
) {
  var best = 0.0;
  var bestDistance = double.infinity;
  for (var index = 0; index <= 512; index += 1) {
    final coordinate = index / 512;
    final expected = _sample(frame, coordinate);
    final distance =
        math.pow(red - expected.r, 2) + math.pow(green - expected.g, 2) + math.pow(blue - expected.b, 2);
    if (distance < bestDistance) {
      bestDistance = distance.toDouble();
      best = coordinate;
    }
  }
  return best;
}

Color _sample(DashboardHeaderVisualFrame frame, double coordinate) {
  final u = _clamp01(coordinate);
  final segment = u <= frame.stops[1] ? 0 : 1;
  final amount = ((u - frame.stops[segment]) /
          (frame.stops[segment + 1] - frame.stops[segment]))
      .clamp(0.0, 1.0);
  return Color.lerp(frame.colors[segment], frame.colors[segment + 1], amount)!;
}

double _narrowHorizontalRidgeCoverage(_Raster raster, double baseline) {
  var covered = 0;
  for (var y = 0; y < _Raster.height; y += 1) {
    var longest = 0;
    var run = 0;
    for (var x = 0; x < _Raster.width; x += 1) {
      final rgb = raster.rgbAt(x, y);
      final delta = (rgb.red * .213 + rgb.green * .715 + rgb.blue * .072 - baseline).abs();
      if (delta > .055) {
        run += 1;
        longest = math.max(longest, run);
      } else {
        run = 0;
      }
    }
    if (longest > 0 && longest < _Raster.width * .15) covered += 1;
  }
  return covered / _Raster.height;
}

double _clamp01(double value) => math.max(0, math.min(1, value));
