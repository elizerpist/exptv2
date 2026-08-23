import 'dart:io';

import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('space-fabric Header metric warp contract', () {
    test(
      'RED declares the third family and four append-only stable shader IDs',
      () async {
        final engine = await File(
          'lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart',
        ).readAsString();

        expect(engine, contains('spaceFabricWarp'));
        expect(engine, contains('metricBloom'));
        expect(engine, contains('gravitationalFabric'));
        expect(engine, contains('breathingMetric'));
        expect(engine, contains('tidalCurvature'));
        expect(engine, contains('shaderId: 14'));
        expect(engine, contains('shaderId: 15'));
        expect(engine, contains('shaderId: 16'));
        expect(engine, contains('shaderId: 17'));
        expect(engine, contains("'Térszövet torzítás'"));
      },
    );

    test('RED isolates analytical compensated metric source-UV warp from '
        'the Full Field inverse advection lane', () async {
      final shader = await File(
        'shaders/dashboard_header_field.frag',
      ).readAsString();
      final warpStart = shader.indexOf('vec2 spaceFabricSourceUv(');
      final warpEnd = shader.indexOf('vec3 spaceFabricField(', warpStart);
      expect(warpStart, greaterThanOrEqualTo(0));
      expect(warpEnd, greaterThan(warpStart));
      if (warpStart < 0 || warpEnd <= warpStart) return;
      final warp = shader.substring(warpStart, warpEnd);

      expect(warp, contains('spaceFabricCompensatedKernel('));
      expect(warp, contains('materialBoundaryEnvelope('));
      expect(warp, contains('for (int index = 0; index < 6; index++)'));
      expect(warp, isNot(contains('fullFieldInverseFlowMap(')));
      expect(warp, isNot(contains('sampleCanonicalPalette(')));
      expect(warp, isNot(contains('fract(')));
    });

    test('RED samples the canonical palette only after metric source mapping '
        'and keeps optical relief post-palette', () async {
      final shader = await File(
        'shaders/dashboard_header_field.frag',
      ).readAsString();
      final fieldStart = shader.indexOf('vec3 spaceFabricField(');
      final fieldEnd = shader.indexOf('vec3 commonField(', fieldStart);
      expect(fieldStart, greaterThanOrEqualTo(0));
      expect(fieldEnd, greaterThan(fieldStart));
      if (fieldStart < 0 || fieldEnd <= fieldStart) return;
      final field = shader.substring(fieldStart, fieldEnd);

      expect(
        field,
        contains('vec2 sourceUv = spaceFabricSourceUv(uv, uPhase)'),
      );
      expect(field, contains('canonicalGradientCoordinate(sourceUv)'));
      expect(field, contains('sampleCanonicalPalette(coordinate)'));
      expect(field, contains('applyMaterialOptics('));
      expect(field, isNot(contains('uGradient')));
    });

    testWidgets('RED renders the third family as the sole active selector '
        'with the four Hungarian variants', (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      controller.selectAnimationFamily(
        DashboardHeaderAnimationFamily.spaceFabricWarp,
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

      expect(find.text('Térszövet típusa'), findsNWidgets(2));
      final selector = tester.widget<DropdownButton<DashboardHeaderEffectId>>(
        find.byKey(const ValueKey<String>('dashboard-header-effect-selector')),
      );
      expect(
        selector.items!.map((item) => item.value),
        <DashboardHeaderEffectId>[
          DashboardHeaderEffectId.metricBloom,
          DashboardHeaderEffectId.gravitationalFabric,
          DashboardHeaderEffectId.breathingMetric,
          DashboardHeaderEffectId.tidalCurvature,
        ],
      );
      controller.dispose();
    });

    test(
      'RED exposes configuration-only Space Fabric diagnostic identities',
      () async {
        final engine = await File(
          'lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart',
        ).readAsString();

        expect(engine, contains('HEADER_SPACE_FABRIC_BOUND'));
        expect(engine, contains('HEADER_SPACE_FABRIC_PROBE'));
        expect(engine, contains('metricModel=compensatedLocalWarp'));
        expect(engine, contains('jacobianGuard=true'));
      },
    );
  });
}
