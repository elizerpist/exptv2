import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/platform/dashboard_active_header_frame_preparer.dart';
import 'package:fluvi/app/platform/dashboard_orb_material_playback_profile.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  DashboardOrbMaterialPlaybackProfile plan({required bool animated}) =>
      DashboardOrbMaterialPlaybackProfile.resolve(
        isAnimated: animated,
        requiresDenseShaderSampling: true,
        characteristicCycleMs: 1000,
        preferredTextureSizePx: 32,
        maximumFrameCount: 5,
        maximumDecodedBytes: 700 * 1024,
        applyCircularAlphaMask: false,
      );

  ActiveHeaderRenderedFrame sample(int value, {bool outsideOnly = false}) {
    final pixels = Uint8List(32 * 32 * 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final i = (y * 32 + x) * 4;
        final dx = x + .5 - 16;
        final dy = y + .5 - 16;
        final inside = dx * dx + dy * dy < 32 * 32 * .1764;
        pixels[i] = outsideOnly && inside ? 0 : value;
        pixels[i + 1] = outsideOnly && inside ? 0 : value;
        pixels[i + 2] = outsideOnly && inside ? 0 : value;
        pixels[i + 3] = 255;
      }
    }
    return ActiveHeaderRenderedFrame(
      png: Uint8List.fromList(<int>[value + 1]),
      rgba: pixels,
    );
  }

  test('a static source produces exactly its one captured frame', () async {
    var calls = 0;
    final result = await prepareActiveHeaderFrames(
      playback: plan(animated: false),
      animated: false,
      isCurrent: () => true,
      render: (index) async {
        calls++;
        return sample(20);
      },
    );
    expect(result.status, ActiveHeaderPreparationStatus.ready);
    expect(calls, 1);
    expect(result.frames, hasLength(1));
    expect(result.playback!.frameCount, 1);
  });

  test(
    'an animated source requires a moving, verified multi-frame loop',
    () async {
      final result = await prepareActiveHeaderFrames(
        playback: plan(animated: true),
        animated: true,
        isCurrent: () => true,
        render: (index) async => sample(index.isEven ? 0 : 80),
      );
      expect(result.status, ActiveHeaderPreparationStatus.ready);
      expect(result.frames!.length, greaterThanOrEqualTo(3));
      expect(result.frames!.length, result.playback!.frameCount);
      expect(result.playback!.intervalMs, plan(animated: true).intervalMs);
    },
  );

  test(
    'an animated but identical series cannot masquerade as a loop',
    () async {
      final result = await prepareActiveHeaderFrames(
        playback: plan(animated: true),
        animated: true,
        isCurrent: () => true,
        render: (index) async => sample(20),
      );
      expect(
        result.status,
        ActiveHeaderPreparationStatus.animatedButStationary,
      );
      expect(result.frames, isNull);
    },
  );

  test('movement outside the orb interior cannot qualify a loop', () async {
    final result = await prepareActiveHeaderFrames(
      playback: plan(animated: true),
      animated: true,
      isCurrent: () => true,
      render: (index) async => sample(index.isEven ? 0 : 80, outsideOnly: true),
    );
    expect(result.status, ActiveHeaderPreparationStatus.animatedButStationary);
    expect(result.frames, isNull);
  });

  test('a moving sequence with an unverified seam is rejected', () async {
    final result = await prepareActiveHeaderFrames(
      playback: plan(animated: true),
      animated: true,
      isCurrent: () => true,
      render: (index) async => sample(index * 25),
    );
    expect(result.status, ActiveHeaderPreparationStatus.unverifiedLoop);
    expect(result.frames, isNull);
  });

  test('a stale completion cannot publish the preceding generation', () async {
    final first = Completer<ActiveHeaderRenderedFrame>();
    var current = true;
    var calls = 0;
    final pending = prepareActiveHeaderFrames(
      playback: plan(animated: true),
      animated: true,
      isCurrent: () => current,
      render: (index) {
        calls++;
        return first.future;
      },
    );
    await Future<void>.delayed(Duration.zero);
    current = false;
    first.complete(sample(10));
    final result = await pending;
    expect(result.status, ActiveHeaderPreparationStatus.stale);
    expect(result.frames, isNull);
    expect(calls, 1);
  });

  test('frames over the encoded budget are never returned', () async {
    final result = await prepareActiveHeaderFrames(
      playback: plan(animated: false),
      animated: false,
      isCurrent: () => true,
      maximumEncodedBytes: 1,
      render: (index) async =>
          ActiveHeaderRenderedFrame(png: Uint8List(2), rgba: sample(10).rgba),
    );
    expect(result.status, ActiveHeaderPreparationStatus.byteBudgetExceeded);
    expect(result.frames, isNull);
  });

  testWidgets('the prepared static PNG matches the Flutter header reference', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester)
      ..setPortalEnabled(DashboardHeaderPortalChannel.backgroundMorph, false)
      ..setPortalEnabled(DashboardHeaderPortalChannel.innerMotion, false)
      ..selectEffect(DashboardHeaderEffectId.staticEffect);
    try {
      final colors = <Color>[
        const Color(0xffffb37b),
        const Color(0xffff79a8),
        const Color(0xff8f5ee8),
      ];
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: controller,
        frame: DashboardHeaderVisualFrame(
          colors: colors,
          stops: const [0, .5, 1],
          opacity: 1,
          colorA: colors.first,
          colorB: colors.last,
        ),
      );
      await tester.runAsync(() async {
        final prepared = await renderActiveHeaderFrames(
          snapshot: snapshot,
          headerSize: const Size(412, 188),
          devicePixelRatio: 1,
          motionEnabled: true,
          isCurrent: () => true,
        );
        expect(prepared.status, ActiveHeaderPreparationStatus.ready);
        expect(prepared.frames, hasLength(1));
        final expectedBytes = await File(
          'android/app/src/androidTest/assets/r47_reference/static-0.png',
        ).readAsBytes();
        final expectedCodec = await ui.instantiateImageCodec(expectedBytes);
        final actualCodec = await ui.instantiateImageCodec(
          prepared.frames!.single,
        );
        final expected = (await expectedCodec.getNextFrame()).image;
        final actual = (await actualCodec.getNextFrame()).image;
        try {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawImageRect(
            expected,
            Rect.fromLTWH(
              0,
              0,
              expected.width.toDouble(),
              expected.height.toDouble(),
            ),
            Rect.fromLTWH(
              0,
              0,
              actual.width.toDouble(),
              actual.height.toDouble(),
            ),
            Paint()..filterQuality = FilterQuality.high,
          );
          final picture = recorder.endRecording();
          final scaled = await picture.toImage(actual.width, actual.height);
          try {
            final a = (await actual.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List();
            final b = (await scaled.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List();
            var sum = 0;
            var pixels = 0;
            for (var y = 0; y < actual.height; y++) {
              for (var x = 0; x < actual.width; x++) {
                final dx = x + .5 - actual.width / 2;
                final dy = y + .5 - actual.height / 2;
                if (dx * dx + dy * dy >= actual.width * actual.width * .1764) {
                  continue;
                }
                final i = (y * actual.width + x) * 4;
                for (var c = 0; c < 3; c++) {
                  sum += (a[i + c] - b[i + c]).abs();
                }
                pixels++;
              }
            }
            expect(pixels, greaterThan(100));
            expect(sum / (pixels * 3), lessThan(5));
          } finally {
            scaled.dispose();
            picture.dispose();
          }
        } finally {
          actual.dispose();
          expected.dispose();
          actualCodec.dispose();
          expectedCodec.dispose();
        }
      });
    } finally {
      controller.dispose();
    }
  });
}
