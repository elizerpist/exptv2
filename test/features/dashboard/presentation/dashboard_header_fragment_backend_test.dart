import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_deep_drift.dart';
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
        }
      },
    );

    test('shader failure cannot select a sparse endpoint mesh plan', () {
      expect(
        DashboardHeaderRenderBackend.values,
        <DashboardHeaderRenderBackend>[
          DashboardHeaderRenderBackend.fragmentShader,
        ],
      );
      expect(
        DashboardHeaderFieldEvaluation.values,
        <DashboardHeaderFieldEvaluation>[
          DashboardHeaderFieldEvaluation.perFragment,
        ],
      );
    });

    test(
      'a fixed-capacity ripple uniform bank cannot grow with rapid input',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.5, .5),
          timestamp: Duration.zero,
          logicalSize: const Size(320, 120),
        );
        for (var index = 1; index <= 30; index += 1) {
          state.pointerMove(
            origin: Offset((.1 + index / 100).clamp(0.0, 1.0), .5),
            logicalDelta: const Offset(3.2, 0),
            logicalSize: const Size(320, 120),
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
      'field displacement, optical overlay and connected water path retain independent '
      'diagnostic inputs',
      () {
        final state = DashboardHeaderTapWaveState();
        state.pointerDown(
          origin: const Offset(.25, .75),
          timestamp: Duration.zero,
          logicalSize: const Size(320, 120),
        );
        state.pointerMove(
          origin: const Offset(.55, .40),
          logicalDelta: const Offset(96, -42),
          logicalSize: const Size(320, 120),
          timestamp: const Duration(milliseconds: 90),
        );

        final ripples = DashboardHeaderTapRippleUniformBank()
          ..update(state: state, elapsed: const Duration(milliseconds: 180));
        final visuals = DashboardHeaderTapWaveVisualUniformBank()
          ..update(state: state, elapsed: const Duration(milliseconds: 180));

        // The same one shared touch state feeds three independently
        // inspectable shader lanes: tap field deformation, radial optics, and
        // the connected water path. None needs a Canvas/offscreen source image.
        expect(ripples.activeCount, greaterThan(0));
        expect(ripples.activeCount, 1);
        // A true drag retracts the large overlay, while the water-path source
        // follows the latest input and retains its original source vertex.
        expect(visuals.overlay.active, 0);
        expect(visuals.overlay.x, closeTo(.55, 1e-12));
        expect(visuals.overlay.y, closeTo(.40, 1e-12));
        expect(visuals.activeTrailCount, greaterThan(0));
        expect(visuals.trails.first.signedVelocity, lessThan(0));
        expect(visuals.trails[1].signedVelocity, greaterThan(0));
        expect(visuals.trails, hasLength(26));
      },
    );

    test('drag trail strength is clamped independently from the tap field', () {
      final state = DashboardHeaderTapWaveState()
        ..configure(
          DashboardHeaderTapWaveTuning.defaults().copyWithValue(
            DashboardHeaderTapWaveCatalog.dynamicTrailStrengthId,
            500,
          ),
        );
      final visuals = DashboardHeaderTapWaveVisualUniformBank()
        ..update(state: state, elapsed: Duration.zero);
      expect(visuals.interactionOpacity, 3);

      state.configure(
        state.tuning.copyWithValue(
          DashboardHeaderTapWaveCatalog.dynamicTrailStrengthId,
          0,
        ),
      );
      visuals.update(state: state, elapsed: Duration.zero);
      expect(visuals.interactionOpacity, 0);
    });

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
      'Portal inner uniforms follow the expanded canonical-gradient bank exactly',
      () {
        final written = <double>[];
        DashboardHeaderFragmentUniformLayout.write(
          size: const Size(320, 120),
          input: _portalAbiInput(interiorEnabled: true),
          setFloat: (index, value) {
            expect(index, written.length);
            written.add(value);
          },
        );

        expect(DashboardHeaderFragmentUniformLayout.version, 4);
        expect(DashboardHeaderFragmentUniformLayout.gradientColorStart, 9);
        expect(DashboardHeaderFragmentUniformLayout.gradientStopStart, 49);
        expect(DashboardHeaderFragmentUniformLayout.commonSettingsStart, 61);
        expect(DashboardHeaderFragmentUniformLayout.backgroundEnabled, 173);
        expect(DashboardHeaderFragmentUniformLayout.interiorEnabled, 192);
        expect(DashboardHeaderFragmentUniformLayout.interiorEffect, 193);
        expect(
          written[DashboardHeaderFragmentUniformLayout.gradientColorStart],
          closeTo(10 / 255, 1e-12),
        );
        expect(
          written[DashboardHeaderFragmentUniformLayout.gradientStopStart + 9],
          1,
        );
        expect(
          written[DashboardHeaderFragmentUniformLayout.backgroundEnabled],
          0,
        );
        expect(
          written[DashboardHeaderFragmentUniformLayout.interiorEnabled],
          1,
        );
        expect(written[DashboardHeaderFragmentUniformLayout.interiorEffect], 2);
        expect(
          written[DashboardHeaderFragmentUniformLayout.interiorSettingsStart],
          36,
        );
        expect(written.length, DashboardHeaderFragmentUniformLayout.floatCount);
      },
    );

    test(
      'the canonical palette ABI preserves active source cardinality for Cool sampling',
      () {
        final written = <double>[];
        DashboardHeaderFragmentUniformLayout.write(
          size: const Size(320, 120),
          input: _portalAbiInput(
            interiorEnabled: false,
            canonicalColors: const <Color>[
              Color(0xffffffff),
              Color(0xff06b6d4),
              Color(0xff00135f),
            ],
            canonicalStops: const <double>[0, .5, 1],
          ),
          setFloat: (index, value) {
            expect(index, written.length);
            written.add(value);
          },
        );

        // The final two stop-bank scalars are reserved capacity.  The first
        // carries the active count so the shader can use its direct 2/3-knot
        // path without replacing the fixed ten-knot ABI or losing continuity.
        expect(
          written[DashboardHeaderFragmentUniformLayout.gradientStopStart +
              DashboardHeaderFragmentUniformLayout
                  .canonicalGradientActiveStopCountOffset],
          3,
        );
      },
    );

    test(
      'the live Cool shader projects its fixed buffer to the exact three-probe palette',
      () {
        final written = <double>[];
        DashboardHeaderFragmentUniformLayout.write(
          size: const Size(320, 120),
          input: _portalAbiInput(interiorEnabled: false),
          setFloat: (index, value) {
            expect(index, written.length);
            written.add(value);
          },
        );

        expect(
          written[DashboardHeaderFragmentUniformLayout.gradientStopStart +
              DashboardHeaderFragmentUniformLayout
                  .canonicalGradientActiveStopCountOffset],
          3,
        );
      },
    );

    test(
      'the shader has direct continuous two and three source-knot palette paths',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();

        expect(shader, contains('float canonicalActiveStopCount()'));
        expect(shader, contains('if (activeStopCount < 2.5)'));
        expect(shader, contains('uGradient2.rgb, uGradientStops0.z'));
        expect(shader, isNot(contains('vec4 gradientColorAt(int index)')));
        expect(shader, isNot(contains('float gradientStopAt(int index)')));
      },
    );

    test(
      'shader uses only Flutter runtime-stage supported scalar types',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();

        expect(shader, isNot(contains('uint ')));
        expect(shader, isNot(contains('bool ')));
        expect(shader, contains('if (index == 0) return vec3(.13, .18, .1);'));
        expect(shader, contains('if (index == 0) return vec3(.16, .18, .7);'));
        final energyHash = shader.substring(
          shader.indexOf('float energyHash'),
          shader.indexOf('float valueNoise'),
        );
        expect(energyHash, contains('fract('));
        expect(shader, contains('float portalHash2'));
        expect(shader, contains('float portalGaussian'));
        expect(
          shader,
          contains('return exp(-.5 * dot(delta / safe, delta / safe));'),
        );
      },
    );

    test(
      'Portal channels retain their own source-over material contributions',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();
        final portalComposition = shader.substring(
          shader.indexOf('float backgroundMatter'),
          shader.indexOf('float overlayAlpha'),
        );

        // Portal blend weights remain material-local. Header opacity belongs
        // once at final source-over composition so a half-opacity Header does
        // not attenuate either Portal channel twice.
        expect(
          portalComposition,
          contains('mix(base, background, backgroundMatter);'),
        );
        expect(
          portalComposition,
          contains('mix(composed, interior, matter * .38);'),
        );
        expect(portalComposition, isNot(contains('saturate(uOpacity)')));
        expect(
          shader,
          contains('fragColor = vec4(composed, saturate(uOpacity));'),
        );
        expect(
          portalComposition,
          isNot(contains('screenBlend(composed, interior)')),
        );
      },
    );

    testWidgets(
      'the pinned runtime-stage compiler loads the production shader',
      (tester) async {
        final program = await FragmentProgram.fromAsset(
          DashboardHeaderFragmentBackend.asset,
        );
        final shader = program.fragmentShader();

        expect(shader, isNotNull);
      },
    );

    testWidgets(
      'the pinned runtime-stage compiler retains every v4 uniform-bank slot',
      (tester) async {
        final program = await FragmentProgram.fromAsset(
          DashboardHeaderFragmentBackend.asset,
        );
        final shader = program.fragmentShader();

        expect(
          () => DashboardHeaderFragmentUniformLayout.write(
            size: const Size(320, 120),
            input: _portalAbiInput(interiorEnabled: true),
            setFloat: shader.setFloat,
          ),
          returnsNormally,
        );
      },
    );

    test(
      'touch overlay and connected water path are native full-surface shader fields, not canvas layers',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();
        final engine = await File(
          'lib/features/dashboard/presentation/core_modes/'
          'dashboard_header_visual_engine.dart',
        ).readAsString();

        expect(shader, contains('vec3 touchOverlay'));
        expect(shader, contains('vec2 displaceWaterTrail'));
        expect(shader, contains('for (int index = 1; index < 25; index++)'));
        expect(shader, contains('if (b.w < 0.0) continue;'));
        expect(
          shader,
          isNot(contains('if (a.w < 0.0 || b.w < 0.0) continue;')),
          reason:
              'The new endpoint owns the connection flag, so the first '
              'piece after a detached sample remains visible.',
        );
        expect(shader, contains('float waterTrailWidthPixels()'));
        expect(shader, contains('signedVelocity'));
        expect(shader, isNot(contains('fwidth(')));
        expect(
          shader,
          contains('farthest * uTouchOverlayScale'),
          reason:
              'The authored .25 gradient endpoint already owns the visible '
              'overlay stop; applying it to geometry as well shrinks the '
              'field fourfold.',
        );
        expect(shader, isNot(contains('farthest * .25 * uTouchOverlayScale')));
        expect(
          shader,
          contains('waterTrailWidthPixels()'),
          reason:
              'The persisted trail-size key maps to a narrow logical-pixel '
              'water-path width inside the shader.',
        );
        expect(shader, isNot(contains('vec3 touchTrail')));
        expect(engine, isNot(contains('DashboardHeaderTapWavePainter')));
        expect(engine, isNot(contains('saveLayer(')));
      },
    );
  });
}

DashboardHeaderFragmentPaintInput _portalAbiInput({
  required bool interiorEnabled,
  List<Color>? canonicalColors,
  List<double>? canonicalStops,
}) {
  final colors =
      canonicalColors ??
      List<Color>.generate(
        DashboardHeaderFragmentBackend.canonicalGradientStopCapacity,
        (index) => Color.fromARGB(255, (index + 1) * 10, 80, 180),
        growable: false,
      );
  return DashboardHeaderFragmentPaintInput(
    phase: .25,
    elapsed: const Duration(milliseconds: 750),
    effectShaderId: 0,
    paletteSplitPercent: 50,
    opacity: 1,
    pulse: 0,
    shaderQuality: 1,
    canonicalColors: colors,
    canonicalStops:
        canonicalStops ??
        List<double>.generate(
          DashboardHeaderFragmentBackend.canonicalGradientStopCapacity,
          (index) => index / 9,
          growable: false,
        ),
    commonSettings: List<double>.filled(40, 0, growable: false),
    deepDrift: DashboardHeaderDeepDriftSkeleton(),
    background: DashboardHeaderFragmentPortalInput(
      enabled: false,
      effectIndex: 2,
      phase: .75,
      paletteCenterPercent: 50,
      paletteWindowPercent: 68,
      rotationEnabled: false,
      rotationSpeed: 28,
      settings: List<double>.filled(12, 0, growable: false),
    ),
    interior: DashboardHeaderFragmentPortalInput(
      enabled: interiorEnabled,
      effectIndex: 2,
      phase: .75,
      paletteCenterPercent: 50,
      paletteWindowPercent: 68,
      rotationEnabled: false,
      rotationSpeed: 28,
      settings: const <double>[36, 74, 118, 82, 22, 44, 28, 24, 311],
    ),
    ripples: DashboardHeaderTapRippleUniformBank(),
    tapRippleRadiusTravel: .42,
    tapRippleIntensity: 1,
    tapPulseLight: .025,
    tapVisuals: DashboardHeaderTapWaveVisualUniformBank(),
  );
}
