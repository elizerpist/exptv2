import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  group('full-field Header material flow', () {
    test(
      'RED registers five explicit full-field variants with stable IDs and Hungarian labels',
      () {
        final byShaderId = <int, DashboardHeaderEffectSpec>{
          for (final effect in DashboardHeaderEffectCatalog.effects)
            effect.shaderId: effect,
        };

        expect(byShaderId.keys, containsAll(<int>[9, 10, 11, 12, 13]));
        expect(byShaderId[9]?.label, 'Szabad áramlás');
        expect(byShaderId[10]?.label, 'Kaotikus keveredés');
        expect(byShaderId[11]?.label, 'Rugalmas tér');
        expect(byShaderId[12]?.label, 'Fonódó áramlás');
        expect(byShaderId[13]?.label, 'Térbeli áramlás');
      },
    );

    test(
      'RED source contract uses a shared bounded inverse flow map before palette lookup',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();
        final flowStart = shader.indexOf('vec2 fullFieldInverseFlowMap(');
        final flowEnd = shader.indexOf('vec3 fullFieldFlowField(', flowStart);
        expect(flowStart, greaterThanOrEqualTo(0));
        if (flowStart < 0) return;
        expect(flowEnd, greaterThan(flowStart));
        if (flowEnd <= flowStart) return;
        final flow = shader.substring(flowStart, flowEnd);
        final fieldStart = flowEnd;
        final fieldEnd = shader.indexOf('float portalValue', fieldStart);
        final field = shader.substring(fieldStart, fieldEnd);

        expect(flow, contains('fullFieldVelocity('));
        expect(flow, contains('fullFieldBoundaryEnvelope('));
        expect(flow, contains('for (int step = 0; step < 2; step++)'));
        expect(flow, isNot(contains('fract(')));
        expect(flow, isNot(contains('mod(')));
        expect(field, contains('canonicalGradientCoordinate(sourceUv)'));
        expect(field, contains('sampleCanonicalPalette(coordinate)'));
        expect(field, contains('applyMaterialOptics('));
        expect(field, isNot(contains('mixture -')));
        expect(field, isNot(contains('paletteSplit')));
      },
    );

    test(
      'RED flow controls preserve direct source-UV semantics and defaults',
      () {
        final byShaderId = <int, DashboardHeaderEffectSpec>{
          for (final effect in DashboardHeaderEffectCatalog.effects)
            effect.shaderId: effect,
        };
        final freeFlow = byShaderId[9];
        expect(freeFlow, isNotNull);
        expect(freeFlow!.controlFor('strength').defaultValue, .72);
        expect(freeFlow.controlFor('speed').defaultValue, .18);
        expect(freeFlow.controlFor('seed').defaultValue, 417);
        expect(freeFlow.controlFor('modeCount').defaultValue, 4);
        expect(freeFlow.controlFor('frameMs').defaultValue, 16);
        for (final id in <int>[10, 11, 12, 13]) {
          expect(byShaderId[id]!.controlFor('seed').min, 0);
          expect(byShaderId[id]!.controlFor('frameMs').defaultValue, 16);
        }
      },
    );

    test(
      'RED tuner renders one family selector and only its active effect selector',
      () async {
        final tuner = await File(
          'lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart',
        ).readAsString();
        final engine = await File(
          'lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart',
        ).readAsString();
        // The tuner renders centralized presentation metadata; labels belong
        // to the animation-family model rather than being copied into UI.
        expect(tuner, contains('Animációs család'));
        expect(engine, contains('Klasszikus effektek · referencia'));
        expect(engine, contains('Teljes mező áramlás'));
        expect(tuner, contains('Referencia mozgás · 69d109'));
        expect(tuner, contains('dashboard-header-animation-family-selector'));
      },
    );

    test(
      'Portal and touch compose on transported material instead of reset',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();
        final main = shader.substring(shader.indexOf('void main()'));

        expect(main, contains('fullFieldInverseFlowMap(displaced, uPhase)'));
        expect(main, contains('fullFieldInverseFlowMap(interiorUv, uPhase)'));
        expect(main, contains('displaceRipples(uv, rippleLight)'));
        expect(main, contains('commonField(displaced, rippleLight)'));
      },
    );
  });
}
