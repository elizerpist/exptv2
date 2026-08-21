import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_tap_wave.dart';

void main() {
  group('maximum-fidelity Header fragment backend contract', () {
    test(
      'maximum quality resolves to per-fragment evaluation, never /4 mesh',
      () {
        final plan = DashboardHeaderFragmentRenderPlan.resolve(
          logicalSize: const Size(412, 188),
          devicePixelRatio: 3,
          renderScale: 1,
        );

        expect(plan.backend, DashboardHeaderRenderBackend.fragmentShader);
        expect(
          plan.fieldEvaluation,
          DashboardHeaderFieldEvaluation.perFragment,
        );
        expect(plan.legacyMeshColumns, isNull);
        expect(plan.legacyMeshRows, isNull);
        expect(plan.dartSurfaceFieldSamplesPerTick, 0);
        expect(plan.physicalSize, const Size(1236, 564));
      },
    );

    test(
      'DPR changes output resolution without reintroducing a source mesh',
      () {
        final dprOne = DashboardHeaderFragmentRenderPlan.resolve(
          logicalSize: const Size(412, 188),
          devicePixelRatio: 1,
          renderScale: 1,
        );
        final dprThree = DashboardHeaderFragmentRenderPlan.resolve(
          logicalSize: const Size(412, 188),
          devicePixelRatio: 3,
          renderScale: 1,
        );

        expect(dprOne.backend, DashboardHeaderRenderBackend.fragmentShader);
        expect(dprThree.backend, DashboardHeaderRenderBackend.fragmentShader);
        expect(
          dprOne.fieldEvaluation,
          DashboardHeaderFieldEvaluation.perFragment,
        );
        expect(
          dprThree.fieldEvaluation,
          DashboardHeaderFieldEvaluation.perFragment,
        );
        expect(dprOne.physicalSize, const Size(412, 188));
        expect(dprThree.physicalSize, const Size(1236, 564));
      },
    );

    test(
      'every normal visual quality keeps the production field per fragment',
      () {
        for (final renderScale in <double>[.35, .60, .95, 1]) {
          final plan = DashboardHeaderFragmentRenderPlan.resolve(
            logicalSize: const Size(412, 188),
            devicePixelRatio: 3,
            renderScale: renderScale,
          );

          expect(
            plan.backend,
            DashboardHeaderRenderBackend.fragmentShader,
            reason: 'renderScale=$renderScale must not select legacy mesh',
          );
          expect(
            plan.fieldEvaluation,
            DashboardHeaderFieldEvaluation.perFragment,
          );
          expect(plan.legacyMeshColumns, isNull);
          expect(plan.legacyMeshRows, isNull);
        }
      },
    );

    test('legacy mesh requires an explicit shader-failure fallback plan', () {
      final fallback = DashboardHeaderFragmentRenderPlan.shaderFailureFallback(
        logicalSize: const Size(412, 188),
        devicePixelRatio: 3,
        renderScale: .35,
      );

      expect(fallback.backend, DashboardHeaderRenderBackend.legacyMesh);
      expect(
        fallback.fieldEvaluation,
        DashboardHeaderFieldEvaluation.sparseVertices,
      );
      expect(fallback.legacyMeshColumns, isNotNull);
      expect(fallback.legacyMeshRows, isNotNull);
    });

    test(
      'a fixed-capacity ripple uniform bank cannot grow with rapid input',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.5, .5),
          timestamp: Duration.zero,
        );
        for (var index = 1; index <= 30; index += 1) {
          state.pointerMove(
            origin: Offset((.1 + index / 100).clamp(0.0, 1.0), .5),
            timestamp: Duration(milliseconds: 60 * index),
          );
        }

        final uniforms = DashboardHeaderTapRippleUniformBank.fromState(
          state: state,
          elapsed: const Duration(milliseconds: 1800),
        );
        expect(uniforms.activeCount, lessThanOrEqualTo(10));
        expect(uniforms.slots, hasLength(10));
        expect(uniforms.dartSurfaceFieldSamplesPerTick, 0);
      },
    );

    test(
      'Portal source profiles do not add a second mesh decimation at max',
      () {
        // `.55` and `.48` are Color Lab source-complexity profiles. On the
        // high-fidelity route they remain shader parameters, not input to the
        // historic `logicalSize * scale / 4` node calculation.
        final plan = DashboardHeaderFragmentRenderPlan.resolve(
          logicalSize: const Size(412, 188),
          devicePixelRatio: 3,
          renderScale: 1,
        );

        expect(plan.backend, DashboardHeaderRenderBackend.fragmentShader);
        expect(plan.legacyMeshColumns, isNull);
        expect(plan.legacyMeshRows, isNull);
        expect(plan.dartSurfaceFieldSamplesPerTick, 0);
      },
    );

    test(
      'configuration changes preserve the retained shader backend identity',
      () {
        final backend = DashboardHeaderFragmentBackend.forTesting();
        final first = backend.backendIdentity;
        backend.markConfigurationChanged();
        backend.markPhaseTick();
        backend.markPhaseTick();

        expect(backend.backendIdentity, same(first));
        expect(backend.programCreations, 0);
        expect(backend.shaderCreations, 0);
        expect(backend.dartSurfaceFieldSamplesPerTick, 0);
      },
    );

    test(
      'shader keeps the audited source lattice and fixed source seeds',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();

        expect(shader, contains('uint hashed = x * 374761393u'));
        expect(
          shader,
          contains('hashed = (hashed ^ (hashed >> 13u)) * 1274126177u'),
        );
        expect(shader, contains('if (index == 0) return vec3(.13, .18, .1);'));
        expect(shader, contains('if (index == 0) return vec3(.16, .18, .7);'));
        final energyHash = shader.substring(
          shader.indexOf('float energyHash'),
          shader.indexOf('float valueNoise'),
        );
        expect(energyHash.contains('sin('), isFalse);
        expect(shader, contains('float portalHash2'));
        expect(shader, contains('float portalGaussian'));
        expect(
          shader,
          contains('return exp(-.5 * dot(delta / safe, delta / safe));'),
        );
      },
    );
  });
}
