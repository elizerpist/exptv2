import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
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
  colors: <Color>[Color(0xff000000), Color(0xff808080), Color(0xffffffff)],
  stops: <double>[0, .5, 1],
  opacity: 1,
  colorA: Color(0xff000000),
  colorB: Color(0xffffffff),
  paletteSplitPercent: 50,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Space Fabric temporal material contract', () {
    test(
      'RED makes the shared Header phase the only Space Fabric speed owner',
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
      testWidgets('RED ${effect.name} changes its actual raster at defaults', (
        tester,
      ) async {
        final frames = await _renderTimeline(tester, effect, const <Duration>[
          Duration.zero,
          Duration(seconds: 1),
          Duration(seconds: 3),
        ]);
        final atZero = frames[Duration.zero]!;
        final atOneSecond = frames[const Duration(seconds: 1)]!;
        final atThreeSeconds = frames[const Duration(seconds: 3)]!;

        expect(
          _meanRgbDelta(atZero, atOneSecond),
          greaterThan(.03),
          reason: '${effect.name} must evolve within one real second.',
        );
        expect(
          _meanRgbDelta(atZero, atThreeSeconds),
          greaterThan(.10),
          reason: '${effect.name} must visibly evolve within three seconds.',
        );
      });
    }

    testWidgets('RED keeps the slow breathing metric materially temporal by '
        'eight seconds', (tester) async {
      final frames = await _renderTimeline(
        tester,
        DashboardHeaderEffectId.breathingMetric,
        const <Duration>[Duration.zero, Duration(seconds: 8)],
      );
      final atZero = frames[Duration.zero]!;
      final atEightSeconds = frames[const Duration(seconds: 8)]!;

      expect(_meanRgbDelta(atZero, atEightSeconds), greaterThan(.25));
    });

    for (final effect in _effects) {
      testWidgets('RED ${effect.name} is exactly frozen at speed zero', (
        tester,
      ) async {
        final frames = await _renderTimeline(tester, effect, const <Duration>[
          Duration.zero,
          Duration(seconds: 60),
        ], speed: 0);
        final atZero = frames[Duration.zero]!;
        final atSixtySeconds = frames[const Duration(seconds: 60)]!;

        expect(_meanRgbDelta(atZero, atSixtySeconds), lessThan(.001));
      });
    }

    test(
      'keeps speed as controller-owned phase rate without amplitude state',
      () {
        for (final speed in <double>[.1, .3, .6, 1]) {
          final controller = DashboardHeaderVisualController(
            vsync: const TestVSync(),
          );
          addTearDown(controller.dispose);
          controller.selectEffect(DashboardHeaderEffectId.metricBloom);
          controller.setEffectControl('speed', speed);
          controller.debugAdvance(const Duration(seconds: 1));
          expect(controller.phase, closeTo(speed, 1e-12));
        }
      },
    );
  });
}

Future<Map<Duration, Uint8List>> _renderTimeline(
  WidgetTester tester,
  DashboardHeaderEffectId effect,
  List<Duration> sampleTimes, {
  double? speed,
}) async {
  if (sampleTimes.isEmpty || sampleTimes.first != Duration.zero) {
    throw ArgumentError.value(
      sampleTimes,
      'sampleTimes',
      'Timeline samples must begin at zero.',
    );
  }
  final controller = DashboardHeaderVisualController(vsync: tester);
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
          child: const SizedBox(width: 192, height: 88),
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: boundary,
          child: SizedBox(
            width: 192,
            height: 88,
            child: DashboardHeaderVisualPaintLayer(
              controller: controller,
              frame: _frame,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  // Keep one retained FragmentProgram/session for all samples. Fresh widgets
  // would mix real material movement with asynchronous shader readiness.
  controller.setMotionEnabled(false);
  await tester.pump(const Duration(milliseconds: 200));
  final renderBoundary =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final frames = <Duration, Uint8List>{};
  var previous = Duration.zero;
  try {
    for (final sampleTime in sampleTimes) {
      controller.debugAdvance(sampleTime - previous);
      await tester.pump();
      frames[sampleTime] = await _capture(renderBoundary, tester);
      previous = sampleTime;
    }
    return frames;
  } finally {
    controller.dispose();
  }
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

double _meanRgbDelta(Uint8List left, Uint8List right) {
  if (left.lengthInBytes != right.lengthInBytes) {
    throw StateError('Space Fabric rasters have different dimensions.');
  }
  var total = 0.0;
  var channelCount = 0;
  for (var index = 0; index < left.lengthInBytes; index += 4) {
    total += (left[index] - right[index]).abs();
    total += (left[index + 1] - right[index + 1]).abs();
    total += (left[index + 2] - right[index + 2]).abs();
    channelCount += 3;
  }
  return total / channelCount;
}
