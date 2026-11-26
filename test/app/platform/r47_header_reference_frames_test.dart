import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

// The optional files are synthetic test fixtures, never an owner's palette.
const _directory = String.fromEnvironment('FLUVI_R47_REFERENCE_DIR');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'canonical header frames distinguish two moving styles from a static control',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester)
        ..setPortalEnabled(DashboardHeaderPortalChannel.backgroundMorph, false)
        ..setPortalEnabled(DashboardHeaderPortalChannel.innerMotion, false);
      final renderer = DashboardHeaderMaterialFrameRenderer();
      final examples = <(String, DashboardHeaderEffectId, List<Color>)>[
        (
          'tide',
          DashboardHeaderEffectId.dualTide,
          const [Color(0xffffb37b), Color(0xffff79a8), Color(0xff8f5ee8)],
        ),
        (
          'braided',
          DashboardHeaderEffectId.braidedCurrent,
          const [Color(0xff104f7c), Color(0xff62c7dc), Color(0xff8366dc)],
        ),
        (
          'static',
          DashboardHeaderEffectId.staticEffect,
          const [Color(0xffffb37b), Color(0xffff79a8), Color(0xff8f5ee8)],
        ),
      ];
      final times = <int>[0, 200, 500, 1000, 1900, 6000];
      try {
        for (final (name, effect, colors) in examples) {
          controller.selectEffect(effect);
          if (effect != DashboardHeaderEffectId.staticEffect) {
            controller.setEffectControl('speed', .4);
          }
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
          final profile = snapshot.keyguardMaterialProfile(
            publisherSession: 'r47-test-only',
            publisherRevision: 1,
            referenceGeometry: const Size(412, 188),
            sceneIdentity: 'active-header:balance:0',
          );
          profile.addAll(<String, Object?>{
            'activeMode': 'balance',
            'modeEpoch': 0,
            'motionEnabled': true,
            'sourceAnimated': snapshot.isAnimated,
          });
          if (_directory.isNotEmpty) {
            final dir = Directory(_directory)..createSync(recursive: true);
            File(
              '${dir.path}/$name.json',
            ).writeAsStringSync(jsonEncode(profile));
          }
          Uint8List? first;
          for (final time in times) {
            final image = (await tester.runAsync(
              () => renderer.renderOrbTexture(
                snapshot: snapshot,
                headerSize: const Size(412, 188),
                orbSizePx: 120,
                offset: Duration(milliseconds: time),
              ),
            ))!;
            try {
              final rgba = (await tester.runAsync(
                () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
              ))!.buffer.asUint8List();
              first ??= Uint8List.fromList(rgba);
              var changed = 0;
              for (var y = 0; y < 120; y++) {
                for (var x = 0; x < 120; x++) {
                  if ((x - 60) * (x - 60) + (y - 60) * (y - 60) > 52.8 * 52.8) {
                    continue;
                  }
                  final i = (y * 120 + x) * 4;
                  if ([
                    0,
                    1,
                    2,
                  ].any((c) => (rgba[i + c] - first![i + c]).abs() >= 3)) {
                    changed++;
                  }
                }
              }
              if (time == 1900) {
                if (effect == DashboardHeaderEffectId.staticEffect) {
                  expect(
                    changed,
                    0,
                    reason: 'static negative must stay static',
                  );
                } else {
                  expect(
                    changed,
                    greaterThan(64),
                    reason: 'real interior motion at the selected speed',
                  );
                }
              }
              if (_directory.isNotEmpty) {
                final png = (await tester.runAsync(
                  () => image.toByteData(format: ui.ImageByteFormat.png),
                ))!;
                File(
                  '$_directory/$name-$time.png',
                ).writeAsBytesSync(png.buffer.asUint8List());
              }
            } finally {
              image.dispose();
            }
          }
        }
      } finally {
        renderer.dispose();
        controller.dispose();
      }
    },
  );
}
