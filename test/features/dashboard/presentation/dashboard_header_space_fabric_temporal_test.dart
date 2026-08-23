import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _effects = <DashboardHeaderEffectId>[
  DashboardHeaderEffectId.metricBloom,
  DashboardHeaderEffectId.gravitationalFabric,
  DashboardHeaderEffectId.breathingMetric,
  DashboardHeaderEffectId.tidalCurvature,
];

const _frame = DashboardHeaderVisualFrame(
  colors: <Color>[Color(0xff06122c), Color(0xff1ac7df), Color(0xfff4ffff)],
  stops: <double>[0, .5, 1],
  opacity: 1,
  colorA: Color(0xff06122c),
  colorB: Color(0xfff4ffff),
  paletteSplitPercent: 50,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Space Fabric real-ticker perceptual motion contract', () {
    test(
      'keeps the shared Header phase as the only Space Fabric speed owner',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();
        final start = shader.indexOf('vec2 spaceFabricSourceUv(');
        final end = shader.indexOf('vec3 spaceFabricField(', start);
        expect(start, greaterThanOrEqualTo(0));
        expect(end, greaterThan(start));
        if (start < 0 || end <= start) return;
        final sourceMap = shader.substring(start, end);

        expect(sourceMap, contains('SPACE_FABRIC_PHASE_TO_TIME'));
        expect(sourceMap, contains('float localTime = phase *'));
        expect(sourceMap, isNot(contains('float speed = mainValue(1)')));
        expect(sourceMap, isNot(contains('phase * (.065 + speed * .34)')));
      },
    );

    for (final effect in _effects) {
      testWidgets(
        'RED ${effect.name} advances through the real ticker and changes a perceptible raster area',
        (tester) async {
          final timeline = await _renderRealTickerTimeline(tester, effect);
          final baseline = timeline.frameAt(Duration.zero);
          final atOneSecond = timeline.frameAt(const Duration(seconds: 1));
          final atThreeSeconds = timeline.frameAt(const Duration(seconds: 3));
          final atFiveSeconds = timeline.frameAt(const Duration(seconds: 5));

          expect(timeline.tickerWasActive, isTrue);
          expect(
            timeline.phaseAt(const Duration(seconds: 5)),
            greaterThan(timeline.phaseAt(Duration.zero)),
          );
          expect(timeline.fragmentBackend.isReady, isTrue);
          expect(
            timeline.fragmentBackend.debugPhaseUniformWriteCount,
            greaterThanOrEqualTo(5),
            reason:
                '$effect must publish phase repeatedly to the retained shader',
          );
          expect(
            timeline.fragmentBackend.debugLatestPhaseUniformWrite,
            greaterThan(timeline.fragmentBackend.debugFirstPhaseUniformWrite!),
            reason: '$effect must publish increasing ticker-owned phase values',
          );
          expect(
            identical(
              timeline.programIdentityAtStart,
              timeline.fragmentBackend.programIdentity,
            ),
            isTrue,
          );
          expect(
            identical(
              timeline.shaderIdentityAtStart,
              timeline.fragmentBackend.shaderIdentity,
            ),
            isTrue,
          );

          final oneSecond = _perceptualDelta(baseline, atOneSecond);
          final threeSeconds = _perceptualDelta(baseline, atThreeSeconds);
          final fiveSeconds = _perceptualDelta(baseline, atFiveSeconds);

          // Byte-valued RGB output makes the former .03/.10 mean thresholds
          // physically meaningless. These require a real, broad material
          // change rather than a sub-channel numerical difference.
          final minimumFiveSecondArea =
              effect == DashboardHeaderEffectId.breathingMetric ? .30 : .40;
          final isBreathingMetric =
              effect == DashboardHeaderEffectId.breathingMetric;
          final violations = <String>[
            if (!isBreathingMetric && oneSecond.meanPerChannel < .50)
              '1s mean < .50',
            if (!isBreathingMetric && oneSecond.changedPixelFraction < .15)
              '1s changed area < .15',
            if (threeSeconds.meanPerChannel < (isBreathingMetric ? 1.20 : 1.50))
              '3s mean below variant minimum',
            if (threeSeconds.changedPixelFraction <
                (isBreathingMetric ? .25 : .30))
              '3s changed area below variant minimum',
            if (fiveSeconds.changedPixelFraction < minimumFiveSecondArea)
              '5s changed area < $minimumFiveSecondArea',
          ];
          expect(
            violations,
            isEmpty,
            reason:
                '$effect perceptual timeline: '
                '1s=$oneSecond 3s=$threeSeconds 5s=$fiveSeconds',
          );
          await _disposeTimeline(tester, timeline);
        },
      );
    }

    for (final effect in _effects) {
      testWidgets('RED ${effect.name} remains visually frozen at speed zero', (
        tester,
      ) async {
        final timeline = await _renderRealTickerTimeline(
          tester,
          effect,
          speed: 0,
        );
        final delta = _perceptualDelta(
          timeline.frameAt(Duration.zero),
          timeline.frameAt(const Duration(seconds: 5)),
        );

        expect(
          timeline.phaseAt(const Duration(seconds: 5)),
          closeTo(timeline.phaseAt(Duration.zero), 1e-12),
        );
        expect(delta.meanPerChannel, lessThan(.001), reason: '$effect: $delta');
        expect(
          delta.changedPixelFraction,
          lessThan(.001),
          reason: '$effect: $delta',
        );
        await _disposeTimeline(tester, timeline);
      });
    }

    testWidgets('speed changes ticker-owned phase rate without changing the '
        'initial Space Fabric geometry', (tester) async {
      final phases = <double>[];
      for (final speed in <double>[.1, .3, .6, 1]) {
        final timeline = await _renderRealTickerTimeline(
          tester,
          DashboardHeaderEffectId.metricBloom,
          speed: speed,
          sampleTimes: const <Duration>[Duration.zero, Duration(seconds: 1)],
        );
        phases.add(
          timeline.phaseAt(const Duration(seconds: 1)) -
              timeline.phaseAt(Duration.zero),
        );
        await _disposeTimeline(tester, timeline);
      }
      expect(phases[1], greaterThan(phases[0]));
      expect(phases[2], greaterThan(phases[1]));
      expect(phases[3], greaterThan(phases[2]));
    });
  });
}

final class _TickerTimeline {
  _TickerTimeline({
    required this.controller,
    required this.fragmentBackend,
    required this.frames,
    required this.phases,
    required this.tickerWasActive,
    required this.programIdentityAtStart,
    required this.shaderIdentityAtStart,
  });

  final DashboardHeaderVisualController controller;
  final DashboardHeaderFragmentBackend fragmentBackend;
  final Map<Duration, Uint8List> frames;
  final Map<Duration, double> phases;
  final bool tickerWasActive;
  final Object programIdentityAtStart;
  final Object shaderIdentityAtStart;

  Uint8List frameAt(Duration time) => frames[time]!;
  double phaseAt(Duration time) => phases[time]!;
  void dispose() {
    controller.dispose();
    fragmentBackend.dispose();
  }
}

Future<_TickerTimeline> _renderRealTickerTimeline(
  WidgetTester tester,
  DashboardHeaderEffectId effect, {
  List<Duration> sampleTimes = const <Duration>[
    Duration.zero,
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 5),
  ],
  double? speed,
}) async {
  if (sampleTimes.isEmpty || sampleTimes.first != Duration.zero) {
    throw ArgumentError.value(
      sampleTimes,
      'sampleTimes',
      'Ticker samples must begin at zero.',
    );
  }
  final controller = DashboardHeaderVisualController(vsync: tester);
  final fragmentBackend = DashboardHeaderFragmentBackend();
  controller.selectEffect(effect);
  controller.setPortalEnabled(DashboardHeaderPortalChannel.innerMotion, false);
  controller.setPortalEnabled(
    DashboardHeaderPortalChannel.backgroundMorph,
    false,
  );
  if (speed != null) controller.setEffectControl('speed', speed);
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
              frame: _frame,
              debugFragmentBackend: fragmentBackend,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
  // Runtime shader loading is asynchronous. Keep the production ticker alive
  // while the retained program becomes ready; the first captured sample is
  // only taken after this warm-up, never after manual phase injection.
  for (var attempt = 0; attempt < 30 && !fragmentBackend.isReady; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (!fragmentBackend.isReady) {
    controller.dispose();
    fragmentBackend.dispose();
    throw StateError(
      'Retained Space Fabric FragmentShader did not become ready.',
    );
  }
  final tickerWasActive = controller.tickerIsActive;
  final programIdentityAtStart = fragmentBackend.programIdentity;
  final shaderIdentityAtStart = fragmentBackend.shaderIdentity;
  final renderBoundary =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final frames = <Duration, Uint8List>{};
  final phases = <Duration, double>{};
  var previous = Duration.zero;
  for (final sampleTime in sampleTimes) {
    final delta = sampleTime - previous;
    if (delta > Duration.zero) await tester.pump(delta);
    frames[sampleTime] = await _capture(renderBoundary, tester);
    phases[sampleTime] = controller.phase;
    previous = sampleTime;
  }
  return _TickerTimeline(
    controller: controller,
    fragmentBackend: fragmentBackend,
    frames: frames,
    phases: phases,
    tickerWasActive: tickerWasActive,
    programIdentityAtStart: programIdentityAtStart,
    shaderIdentityAtStart: shaderIdentityAtStart,
  );
}

Future<Uint8List> _capture(
  RenderRepaintBoundary boundary,
  WidgetTester tester,
) async {
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) throw StateError('Space Fabric raster unavailable.');
    return Uint8List.fromList(bytes.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

Future<void> _disposeTimeline(
  WidgetTester tester,
  _TickerTimeline timeline,
) async {
  timeline.controller.setMotionEnabled(false);
  await tester.pumpWidget(const SizedBox.shrink());
  timeline.dispose();
}

final class _PerceptualDelta {
  const _PerceptualDelta({
    required this.meanPerChannel,
    required this.changedPixelFraction,
  });

  final double meanPerChannel;
  final double changedPixelFraction;

  @override
  String toString() =>
      'meanPerChannel=$meanPerChannel '
      'changedPixelFraction=$changedPixelFraction';
}

_PerceptualDelta _perceptualDelta(Uint8List left, Uint8List right) {
  if (left.lengthInBytes != right.lengthInBytes) {
    throw StateError('Space Fabric rasters have different dimensions.');
  }
  var channelTotal = 0.0;
  var changedPixels = 0;
  var pixelCount = 0;
  for (var index = 0; index < left.lengthInBytes; index += 4) {
    final red = (left[index] - right[index]).abs();
    final green = (left[index + 1] - right[index + 1]).abs();
    final blue = (left[index + 2] - right[index + 2]).abs();
    channelTotal += red + green + blue;
    if (red * red + green * green + blue * blue >= 16) changedPixels += 1;
    pixelCount += 1;
  }
  return _PerceptualDelta(
    meanPerChannel: channelTotal / (pixelCount * 3),
    changedPixelFraction: changedPixels / pixelCount,
  );
}
