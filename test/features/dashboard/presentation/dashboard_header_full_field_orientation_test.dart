import 'dart:io';

import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('full-field palette orientation drift contract', () {
    test('RED retains ABI v3 and reserves four high common slots for the '
        'family-owned palette basis', () async {
      final engine = await File(
        'lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart',
      ).readAsString();
      final shader = await File('shaders/dashboard_header_field.frag')
          .readAsString();

      expect(DashboardHeaderFragmentUniformLayout.version, 3);
      expect(DashboardHeaderFragmentUniformLayout.commonSettingsFloatCount, 40);
      expect(engine, contains('DashboardHeaderPaletteOrientationTuning'));
      expect(engine, contains('orientationEnabledSlot = 36'));
      expect(engine, contains('orientationBaseAndPhaseSlot = 37'));
      expect(engine, contains('orientationSweepSlot = 38'));
      expect(engine, contains('orientationSpeedSlot = 39'));
      expect(shader, contains('float fullFieldOrientationEnabled()'));
    });

    test('RED keeps the fixed 112 degree helper literal and adds a dynamic '
        'CSS-angle projection with a fixed-path OFF return', () async {
      final shader = await File('shaders/dashboard_header_field.frag')
          .readAsString();
      final fixedStart = shader.indexOf('float canonicalGradientCoordinate(vec2 uv)');
      final fixedEnd = shader.indexOf('vec3 sampleCanonicalPalette', fixedStart);
      final fixed = shader.substring(fixedStart, fixedEnd);

      expect(fixed, contains('const vec2 direction = vec2(.9271838546, .3746065934)'));
      expect(shader, contains('float canonicalGradientCoordinateAtAngle('));
      expect(shader, contains('if (abs(degrees - 112.0) < .0001)'));
      expect(shader, contains('return canonicalGradientCoordinate(uv);'));
      expect(shader, contains('vec2(sin(radians), -cos(radians))'));
    });

    test('RED adds an oscillatory family palette basis after source-UV flow '
        'without changing the inverse-flow implementation', () async {
      final shader = await File('shaders/dashboard_header_field.frag')
          .readAsString();
      final inverseStart = shader.indexOf('vec2 fullFieldInverseFlowMap(');
      final inverseEnd = shader.indexOf('vec3 fullFieldFlowField(', inverseStart);
      final inverse = shader.substring(inverseStart, inverseEnd);
      final fieldEnd = shader.indexOf('vec3 commonField(', inverseEnd);
      final field = shader.substring(inverseEnd, fieldEnd);

      expect(inverse, contains('for (int step = 0; step < 2; step++)'));
      expect(field, contains('vec2 sourceUv = fullFieldInverseFlowMap(uv, uPhase)'));
      expect(field, contains('float fullFieldPaletteAngle()'));
      expect(field, contains('canonicalGradientCoordinateAtAngle(sourceUv'));
      expect(field, contains('sin('));
      expect(field, isNot(contains('rotate * sourceUv')));
    });

    testWidgets('RED exposes a real family-level orientation switch and '
        'controls only while full-field flow is selected', (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      controller.selectAnimationFamily(
        DashboardHeaderAnimationFamily.fullFieldFlow,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 520,
            child: DashboardHeaderVisualTuner(controller: controller),
          ),
        ),
      );

      expect(find.text('Színirány mozgás'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('dashboard-header-orientation-enabled')),
        findsOneWidget,
      );
      expect(
        tester.widget<Switch>(
          find.byKey(
            const ValueKey<String>('dashboard-header-orientation-enabled'),
          ),
        ).value,
        isFalse,
      );
      controller.dispose();
    });

    test('RED Portal source projection resolves the same active full-field '
        'palette basis instead of falling back to fixed 112 degrees', () async {
      final shader = await File('shaders/dashboard_header_field.frag')
          .readAsString();
      final portalStart = shader.indexOf('float portalMaterialCoordinate(');
      final portalEnd = shader.indexOf('vec3 screenBlend', portalStart);
      final portal = shader.substring(portalStart, portalEnd);

      expect(portal, contains('activeMaterialPaletteCoordinate(uv)'));
      expect(portal, contains('activeMaterialPaletteCoordinate(sourceUv)'));
    });
  });
}
