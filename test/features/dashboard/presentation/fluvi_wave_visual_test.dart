import 'dart:ui' as ui;

import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fluvi_wave_fixture.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('FluviColorLabInter')
      ..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'));
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('WR-18 actual Month material reference and ablation scenes', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
      waveLinked(waveReferenceForints),
    );
    final settings = BalancePresentationController(
      initial: const BalancePresentationSettings.defaults().copyWith(
        usesChildCards: false,
      ),
    );
    addTearDown(linked.dispose);
    addTearDown(settings.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const cases = [
      (
        name: 'reference',
        shader: false,
        body: false,
        glow: true,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'reference',
        shader: false,
        body: true,
        glow: false,
        contours: false,
        width: 412.0,
      ),
      (
        name: 'reference-no-glow',
        shader: false,
        body: false,
        glow: false,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'reference-no-contours',
        shader: false,
        body: false,
        glow: true,
        contours: false,
        width: 412.0,
      ),
      (
        name: 'reference',
        shader: true,
        body: false,
        glow: true,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'reference',
        shader: true,
        body: true,
        glow: false,
        contours: false,
        width: 412.0,
      ),
      (
        name: 'reference-animated',
        shader: true,
        body: false,
        glow: true,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'sparse',
        shader: false,
        body: false,
        glow: true,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'sparse',
        shader: true,
        body: false,
        glow: true,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'sparse',
        shader: false,
        body: true,
        glow: false,
        contours: false,
        width: 412.0,
      ),
      (
        name: 'zero',
        shader: true,
        body: false,
        glow: true,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'first-peak',
        shader: false,
        body: false,
        glow: true,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'last-peak',
        shader: false,
        body: false,
        glow: true,
        contours: true,
        width: 412.0,
      ),
      (
        name: 'reference',
        shader: false,
        body: false,
        glow: true,
        contours: true,
        width: 320.0,
      ),
    ];
    final bodyRasters = <String, List<int>>{};
    for (final scene in cases) {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(
            disableAnimations: scene.name != 'reference-animated',
          );
      final viewport = Size(scene.width, scene.width * 892 / 412);
      await tester.binding.setSurfaceSize(viewport);
      linked.value = waveLinked(
        scene.name.startsWith('reference')
            ? waveReferenceForints
            : scene.name == 'zero'
            ? List.filled(31, 0)
            : waveSparseForints(
                31,
                peak: scene.name == 'first-peak'
                    ? 0
                    : scene.name == 'last-peak'
                    ? 30
                    : 1,
              ),
      );
      settings.setMonthlySpendingChartPresentation(
        scene.shader
            ? BalanceMonthlySpendingChartPresentation.shaderAtmosphere
            : BalanceMonthlySpendingChartPresentation.topographic,
      );
      FluviWaveRenderMetrics? metrics;
      await tester.pumpWidget(
        waveProductionParent(
          linked: linked,
          settings: settings,
          viewport: viewport,
          wrap: (child) => FluviWaveDebugScope(
            materialOnly: scene.body,
            glow: scene.glow,
            contours: scene.contours,
            atmosphere: !scene.body,
            onPaint: (value) => metrics = value,
            child: child,
          ),
        ),
      );
      await tester.pump();
      if (scene.shader && scene.name != 'zero') {
        for (var i = 0; i < 80 && metrics!.route != 'shader'; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        expect(metrics!.route, 'shader');
        expect(identical(metrics!.terrain, metrics!.textureTerrain), isTrue);
      }
      final parent = await waveCapture(
        tester,
        find.byKey(const ValueKey('wave-production-parent')),
      );
      final chartRect = tester.getRect(find.byType(FluviTopographicWaveChart));
      final crop = Rect.fromLTWH(
        chartRect.left * 2,
        chartRect.top * 2,
        chartRect.width * 2,
        chartRect.height * 2,
      );
      final recorder = ui.PictureRecorder();
      Canvas(
        recorder,
      ).drawImageRect(parent, crop, Offset.zero & crop.size, Paint());
      final picture = recorder.endRecording();
      final image = (await tester.runAsync(
        () => picture.toImage(crop.width.ceil(), crop.height.ceil()),
      ))!;
      if (scene.name == 'reference-animated') {
        final pixels = (await tester.runAsync(() => image.toByteData()))!;
        final pixel =
            ((image.height * .32).floor() * image.width +
                (image.width * .7).floor()) *
            4;
        final rgb = List.generate(
          3,
          (channel) => pixels.getUint8(pixel + channel),
        );
        debugPrint('WR-27 optional animated atmosphere background pixel $rgb');
        expect(
          rgb.every((channel) => channel >= 247),
          isTrue,
          reason:
              'The optional animated layer must not wash the reference white background grey.',
        );
      }
      final label =
          '${scene.name}-${scene.shader ? 'shader' : 'mesh'}-${scene.body ? 'body' : 'full'}-${scene.width.toInt()}';
      final metadata = <String, Object?>{
        'dataset': '${scene.name}-synthetic-complete-calendar',
        'viewport': '$viewport',
        'chartGlobalBounds': '$chartRect',
        'transformToRoot': tester
            .renderObject(find.byType(FluviTopographicWaveChart))
            .getTransformTo(null)
            .storage
            .toList(),
        'bodyOnly': scene.body,
        'glow': scene.glow,
        'contours': scene.contours,
        ...metrics!.snapshot(),
      };
      await waveWriteEvidence(tester, image, label, metadata);
      if (!scene.body && ['reference', 'sparse'].contains(scene.name)) {
        await waveWriteEvidence(tester, parent, '$label-parent', metadata);
      }
      if (scene.body) {
        final bytes = (await tester.runAsync(
          () => image.toByteData(),
        ))!.buffer.asUint8List();
        var colored = 0;
        for (var i = 0; i < bytes.length; i += 4) {
          if (bytes[i + 2] - bytes[i] > 18 && bytes[i] < 225) colored++;
        }
        final coverage = colored / (image.width * image.height);
        debugPrint(
          'WR-18 $label substantial violet body coverage=$coverage ${metrics!.snapshot()}',
        );
        expect(
          coverage,
          greaterThan(.13),
          reason: 'body pixels, without ridge/glow/contours/decoration',
        );
        if (scene.name == 'reference') {
          bodyRasters[scene.shader ? 'shader' : 'mesh'] = bytes.toList();
        }
      }
      image.dispose();
      parent.dispose();
      picture.dispose();
      expect(tester.takeException(), isNull);
    }
    final mesh = bodyRasters['mesh']!;
    final shader = bodyRasters['shader']!;
    var difference = 0;
    for (var i = 0; i < mesh.length; i++) {
      difference += (mesh[i] - shader[i]).abs();
    }
    final mean = difference / mesh.length;
    debugPrint(
      'WR-18 same-data shader/mesh mean channel difference=$mean /255',
    );
    expect(
      mean,
      lessThan(7),
      reason: 'two real paint routes must share the material contract',
    );
  });
}
