import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_static_color_renderer.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('continuous Header palette transport contract', () {
    test('fragment ABI v3 removes endpoint RGB authority', () async {
      final shader = await File(
        'shaders/dashboard_header_field.frag',
      ).readAsString();
      final backend = await File(
        'lib/features/dashboard/presentation/core_modes/'
        'dashboard_header_fragment_backend.dart',
      ).readAsString();

      expect(DashboardHeaderFragmentUniformLayout.version, 3);
      expect(shader, isNot(contains('uColorA')));
      expect(shader, isNot(contains('uColorB')));
      expect(shader, isNot(contains('vec3 colorMix')));
      expect(shader, contains('vec3 sampleCanonicalPalette(float coordinate)'));
      expect(
        backend,
        isNot(contains('required this.colorA')),
        reason: 'Endpoint colours must not be fragment paint input.',
      );
      expect(
        backend,
        isNot(contains('required this.colorB')),
        reason: 'Endpoint colours must not be fragment paint input.',
      );
    });

    test(
      'every material lane samples the canonical palette after transport',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();
        final deepStart = shader.indexOf('vec3 deepDriftField');
        final deepEnd = shader.indexOf(
          '// The dual-tide implementation',
          deepStart,
        );
        final portalStart = shader.indexOf('float portalSample');
        final portalEnd = shader.indexOf('vec3 screenBlend', portalStart);
        final deep = shader.substring(deepStart, deepEnd);
        final portal = shader.substring(portalStart, portalEnd);

        expect(shader, contains('float canonicalGradientCoordinate(vec2 uv)'));
        expect(shader, contains('sampleCanonicalPalette('));
        expect(deep, contains('sampleCanonicalPalette('));
        expect(deep, isNot(contains('mix(uColor')));
        expect(portal, isNot(contains('uColor')));
        expect(
          shader.substring(shader.indexOf('void main()')),
          isNot(contains('mix(uColor')),
        );
      },
    );

    for (final effect in DashboardHeaderEffectId.values.where(
      (effect) => effect != DashboardHeaderEffectId.staticEffect,
    )) {
      testWidgets(
        '${effect.name} changes pixels when only the canonical midpoint changes',
        (tester) async {
          final controller = DashboardHeaderVisualController(vsync: tester);
          controller.selectEffect(effect);
          controller.setPortalEnabled(
            DashboardHeaderPortalChannel.backgroundMorph,
            false,
          );
          controller.setPortalEnabled(
            DashboardHeaderPortalChannel.innerMotion,
            false,
          );

          final (first, second) = await _renderHeaderPair(
            tester: tester,
            controller: controller,
            first: _gradientFrame(const Color(0xffff0000)),
            second: _gradientFrame(const Color(0xffffff00)),
          );
          final difference = _pixelDifference(first, second);

          expect(
            difference.changedPixels,
            greaterThan(412 * 188 ~/ 50),
            reason:
                '$effect must sample the complete palette, not only equal red/blue endpoints: $difference',
          );
          expect(difference.meanRgbDelta, greaterThan(1));
          controller.dispose();
        },
      );
    }

    for (final channel in <DashboardHeaderPortalChannel>[
      DashboardHeaderPortalChannel.backgroundMorph,
      DashboardHeaderPortalChannel.innerMotion,
    ]) {
      testWidgets(
        '${channel.name} samples a changed interior canonical colour',
        (tester) async {
          final controller = DashboardHeaderVisualController(vsync: tester);
          controller.selectEffect(DashboardHeaderEffectId.staticEffect);
          controller.setPortalEnabled(
            DashboardHeaderPortalChannel.backgroundMorph,
            channel == DashboardHeaderPortalChannel.backgroundMorph,
          );
          controller.setPortalEnabled(
            DashboardHeaderPortalChannel.innerMotion,
            channel == DashboardHeaderPortalChannel.innerMotion,
          );

          final (first, second) = await _renderHeaderPair(
            tester: tester,
            controller: controller,
            first: _gradientFrame(const Color(0xff00ff00)),
            second: _gradientFrame(const Color(0xffffff00)),
          );
          final difference = _pixelDifference(first, second);
          expect(
            difference.changedPixels,
            greaterThan(412 * 188 ~/ 50),
            reason:
                '$channel must obtain RGB from the complete canonical field: '
                '$difference',
          );
          expect(difference.meanRgbDelta, greaterThan(.5));
          controller.dispose();
        },
      );
    }

    for (final effect in <DashboardHeaderEffectId>[
      DashboardHeaderEffectId.dualTide,
      DashboardHeaderEffectId.deepDrift,
    ]) {
      testWidgets('$effect retains broad Cool palette support', (tester) async {
        final controller = DashboardHeaderVisualController(vsync: tester);
        controller.selectEffect(effect);
        controller.setPortalEnabled(
          DashboardHeaderPortalChannel.backgroundMorph,
          false,
        );
        controller.setPortalEnabled(
          DashboardHeaderPortalChannel.innerMotion,
          false,
        );
        const frame = DashboardHeaderVisualFrame(
          colors: <Color>[
            Color(0xffffffff),
            Color(0xff14c5e1),
            Color(0xff00135f),
          ],
          stops: <double>[0, .5, 1],
          opacity: 1,
          colorA: Color(0xffffffff),
          colorB: Color(0xff00135f),
        );
        final pixels = await _renderHeader(
          tester: tester,
          controller: controller,
          frame: frame,
        );
        final support = _paletteSupport(pixels, frame);
        // Test-only evidence for the bounded palette-support contract.
        debugPrint('$effect paletteSupport=$support');

        expect(
          support.occupiedBins,
          greaterThanOrEqualTo(24),
          reason: '$effect must transport broad palette support: $support',
        );
        expect(support.p95 - support.p05, greaterThanOrEqualTo(.75));
        expect(support.leftEndpointFraction, lessThan(.15));
        expect(support.rightEndpointFraction, lessThan(.15));
        controller.dispose();
      });
    }

    for (final effect in DashboardHeaderEffectId.values.where(
      (effect) => effect != DashboardHeaderEffectId.staticEffect,
    )) {
      testWidgets('$effect at zero strength is the static canonical field', (
        tester,
      ) async {
        final controller = DashboardHeaderVisualController(vsync: tester);
        controller.selectEffect(effect);
        controller.setEffectControl('strength', 0);
        controller.setPortalEnabled(
          DashboardHeaderPortalChannel.backgroundMorph,
          false,
        );
        controller.setPortalEnabled(
          DashboardHeaderPortalChannel.innerMotion,
          false,
        );
        const frame = DashboardHeaderVisualFrame(
          colors: <Color>[
            Color(0xffffffff),
            Color(0xff14c5e1),
            Color(0xff00135f),
          ],
          stops: <double>[0, .5, 1],
          opacity: 1,
          colorA: Color(0xffffffff),
          colorB: Color(0xff00135f),
        );

        final actual = await _renderHeader(
          tester: tester,
          controller: controller,
          frame: frame,
        );
        final expected = await _nativeStatic(tester: tester, frame: frame);
        final difference = _pixelDifference(actual, expected);

        expect(
          difference.meanRgbDelta,
          lessThanOrEqualTo(1),
          reason:
              '$effect strength=0 must be the 112-degree static field: $difference',
        );
        controller.dispose();
      });
    }
  });
}

DashboardHeaderVisualFrame _gradientFrame(Color midpoint) =>
    DashboardHeaderVisualFrame(
      colors: <Color>[
        const Color(0xffff0000),
        midpoint,
        const Color(0xff0000ff),
      ],
      stops: const <double>[0, .5, 1],
      opacity: 1,
      colorA: const Color(0xffff0000),
      colorB: const Color(0xff0000ff),
      paletteSplitPercent: 50,
    );

Future<ByteData> _renderHeader({
  required WidgetTester tester,
  required DashboardHeaderVisualController controller,
  required DashboardHeaderVisualFrame frame,
}) async {
  final boundary = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: 412,
            height: 188,
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
  await tester.pump(const Duration(seconds: 1));
  final renderBoundary =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => renderBoundary.toImage()))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) throw StateError('Header pixels unavailable.');
    return bytes;
  } finally {
    image.dispose();
  }
}

Future<(ByteData, ByteData)> _renderHeaderPair({
  required WidgetTester tester,
  required DashboardHeaderVisualController controller,
  required DashboardHeaderVisualFrame first,
  required DashboardHeaderVisualFrame second,
}) async {
  final firstBoundary = GlobalKey();
  final secondBoundary = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RepaintBoundary(
            key: firstBoundary,
            child: SizedBox(
              width: 412,
              height: 188,
              child: DashboardHeaderVisualPaintLayer(
                controller: controller,
                frame: first,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          RepaintBoundary(
            key: secondBoundary,
            child: SizedBox(
              width: 412,
              height: 188,
              child: DashboardHeaderVisualPaintLayer(
                controller: controller,
                frame: second,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return (
    await _captureHeader(tester, firstBoundary),
    await _captureHeader(tester, secondBoundary),
  );
}

Future<ByteData> _captureHeader(WidgetTester tester, GlobalKey boundary) async {
  final renderBoundary =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => renderBoundary.toImage()))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) throw StateError('Header pixels unavailable.');
    return bytes;
  } finally {
    image.dispose();
  }
}

Future<ByteData> _nativeStatic({
  required WidgetTester tester,
  required DashboardHeaderVisualFrame frame,
}) async {
  final recorder = ui.PictureRecorder();
  DashboardHeaderStaticColorRenderer.paint(
    canvas: Canvas(recorder),
    rect: const Rect.fromLTWH(0, 0, 412, 188),
    colors: frame.colors,
    stops: frame.stops,
    opacity: frame.opacity,
  );
  final image = (await tester.runAsync(
    () => recorder.endRecording().toImage(412, 188),
  ))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) throw StateError('Native static pixels unavailable.');
    return bytes;
  } finally {
    image.dispose();
  }
}

_PixelDifference _pixelDifference(ByteData first, ByteData second) {
  var changedPixels = 0;
  var totalRgbDelta = 0;
  for (var index = 0; index < first.lengthInBytes; index += 4) {
    final delta =
        (first.getUint8(index) - second.getUint8(index)).abs() +
        (first.getUint8(index + 1) - second.getUint8(index + 1)).abs() +
        (first.getUint8(index + 2) - second.getUint8(index + 2)).abs();
    if (delta == 0) continue;
    changedPixels += 1;
    totalRgbDelta += delta;
  }
  return _PixelDifference(
    changedPixels: changedPixels,
    meanRgbDelta: totalRgbDelta / (first.lengthInBytes / 4),
  );
}

final class _PixelDifference {
  const _PixelDifference({
    required this.changedPixels,
    required this.meanRgbDelta,
  });

  final int changedPixels;
  final double meanRgbDelta;

  @override
  String toString() =>
      'changed=$changedPixels mean=${meanRgbDelta.toStringAsFixed(3)}';
}

_PaletteSupport _paletteSupport(
  ByteData pixels,
  DashboardHeaderVisualFrame frame,
) {
  final samples = <double>[];
  final occupied = <int>{};
  var leftEndpoints = 0;
  var rightEndpoints = 0;
  for (var index = 0; index < pixels.lengthInBytes; index += 16) {
    final coordinate = _nearestPaletteCoordinate(
      red: pixels.getUint8(index) / 255,
      green: pixels.getUint8(index + 1) / 255,
      blue: pixels.getUint8(index + 2) / 255,
      frame: frame,
    );
    samples.add(coordinate);
    occupied.add((coordinate * 32).floor().clamp(0, 31));
    if (coordinate <= .02) leftEndpoints += 1;
    if (coordinate >= .98) rightEndpoints += 1;
  }
  samples.sort();
  final count = samples.length;
  return _PaletteSupport(
    occupiedBins: occupied.length,
    p05: samples[(count * .05).floor()],
    p95: samples[(count * .95).floor()],
    leftEndpointFraction: leftEndpoints / count,
    rightEndpointFraction: rightEndpoints / count,
  );
}

double _nearestPaletteCoordinate({
  required double red,
  required double green,
  required double blue,
  required DashboardHeaderVisualFrame frame,
}) {
  var bestCoordinate = 0.0;
  var bestDistance = double.infinity;
  for (var index = 0; index <= 256; index += 1) {
    final coordinate = index / 256;
    final expected = _sampleFrame(frame, coordinate);
    final dr = red - expected.r;
    final dg = green - expected.g;
    final db = blue - expected.b;
    final distance = dr * dr + dg * dg + db * db;
    if (distance < bestDistance) {
      bestDistance = distance;
      bestCoordinate = coordinate;
    }
  }
  return bestCoordinate;
}

Color _sampleFrame(DashboardHeaderVisualFrame frame, double coordinate) {
  final safe = coordinate.clamp(0.0, 1.0);
  var segment = frame.stops.length - 2;
  for (var index = 0; index < frame.stops.length - 1; index += 1) {
    if (safe <= frame.stops[index + 1]) {
      segment = index;
      break;
    }
  }
  final amount =
      ((safe - frame.stops[segment]) /
              (frame.stops[segment + 1] - frame.stops[segment]))
          .clamp(0.0, 1.0);
  return Color.lerp(frame.colors[segment], frame.colors[segment + 1], amount)!;
}

final class _PaletteSupport {
  const _PaletteSupport({
    required this.occupiedBins,
    required this.p05,
    required this.p95,
    required this.leftEndpointFraction,
    required this.rightEndpointFraction,
  });

  final int occupiedBins;
  final double p05;
  final double p95;
  final double leftEndpointFraction;
  final double rightEndpointFraction;

  @override
  String toString() =>
      'bins=$occupiedBins p05=${p05.toStringAsFixed(3)} '
      'p95=${p95.toStringAsFixed(3)} '
      'left=${leftEndpointFraction.toStringAsFixed(3)} '
      'right=${rightEndpointFraction.toStringAsFixed(3)}';
}
