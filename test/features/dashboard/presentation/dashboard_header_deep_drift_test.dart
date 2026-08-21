import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_deep_drift.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  group('Deep Drift production contract', () {
    test('freezes the Fluvi-native effect catalog and its live controls', () {
      final spec = DashboardHeaderEffectCatalog.effectFor(
        DashboardHeaderEffectId.deepDrift,
      );

      expect(spec.shaderId, 8);
      expect(spec.label, 'Mélységi áramlás');
      expect(spec.controls, const <DashboardHeaderEffectControl>[
        DashboardHeaderEffectControl(
          id: 'strength',
          label: 'Animáció erő',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .82,
        ),
        DashboardHeaderEffectControl(
          id: 'speed',
          label: 'Sebesség',
          min: 0,
          max: 2,
          step: .01,
          defaultValue: .32,
        ),
        DashboardHeaderEffectControl(
          id: 'blobScale',
          label: 'Anyagméret',
          min: .60,
          max: 1.50,
          step: .01,
          defaultValue: 1,
        ),
        DashboardHeaderEffectControl(
          id: 'anisotropy',
          label: 'Nyújtottság',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .55,
        ),
        DashboardHeaderEffectControl(
          id: 'density',
          label: 'Anyagsűrűség',
          min: .35,
          max: 1.40,
          step: .01,
          defaultValue: .82,
        ),
        DashboardHeaderEffectControl(
          id: 'softness',
          label: 'Határ puhaság',
          min: .10,
          max: 1,
          step: .01,
          defaultValue: .68,
        ),
        DashboardHeaderEffectControl(
          id: 'noiseAmount',
          label: 'Anyagvariáció',
          min: 0,
          max: .15,
          step: .005,
          defaultValue: .06,
        ),
        DashboardHeaderEffectControl(
          id: 'noiseScale',
          label: 'Variáció méret',
          min: .15,
          max: 1.20,
          step: .01,
          defaultValue: .45,
        ),
        DashboardHeaderEffectControl(
          id: 'depthSeparation',
          label: 'Mélységi eltérés',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .72,
        ),
        DashboardHeaderEffectControl(
          id: 'depthColorSeparation',
          label: 'A/B mélységi szétválasztás',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .78,
        ),
        DashboardHeaderEffectControl(
          id: 'driftSpread',
          label: 'Áramlási eltérés',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .62,
        ),
        DashboardHeaderEffectControl(
          id: 'lighting',
          label: 'Belső fény',
          min: 0,
          max: .20,
          step: .005,
          defaultValue: .10,
        ),
        DashboardHeaderEffectControl(
          id: 'coreGlow',
          label: 'Magfény',
          min: 0,
          max: .08,
          step: .002,
          defaultValue: .03,
        ),
        DashboardHeaderEffectControl(
          id: 'breathingAmount',
          label: 'Mélységi légzés',
          min: 0,
          max: .10,
          step: .002,
          defaultValue: .06,
        ),
        DashboardHeaderEffectControl(
          id: 'breathingSpeed',
          label: 'Légzés seb.',
          min: 0,
          max: 1,
          step: .01,
          defaultValue: .25,
        ),
        DashboardHeaderEffectControl(
          id: 'nearOpacity',
          label: 'Közeli réteg',
          min: 0,
          max: .35,
          step: .005,
          defaultValue: .19,
        ),
        DashboardHeaderEffectControl(
          id: 'middleOpacity',
          label: 'Középső réteg',
          min: 0,
          max: .30,
          step: .005,
          defaultValue: .14,
        ),
        DashboardHeaderEffectControl(
          id: 'farOpacity',
          label: 'Távoli réteg',
          min: 0,
          max: .25,
          step: .005,
          defaultValue: .10,
        ),
      ]);
    });

    test('uses the compact cubic kernel and its analytic derivative', () {
      expect(DashboardHeaderDeepDriftMath.cubicKernel(0), 1);
      expect(
        DashboardHeaderDeepDriftMath.cubicKernel(.25),
        closeTo(.84375, 1e-12),
      );
      expect(DashboardHeaderDeepDriftMath.cubicKernel(.50), closeTo(.5, 1e-12));
      expect(
        DashboardHeaderDeepDriftMath.cubicKernel(.75),
        closeTo(.15625, 1e-12),
      );
      expect(DashboardHeaderDeepDriftMath.cubicKernel(1), 0);
      expect(DashboardHeaderDeepDriftMath.cubicKernel(1.1), 0);
      expect(DashboardHeaderDeepDriftMath.cubicKernelDerivative(0), 0);
      expect(
        DashboardHeaderDeepDriftMath.cubicKernelDerivative(.25),
        closeTo(-1.125, 1e-12),
      );
      expect(
        DashboardHeaderDeepDriftMath.cubicKernelDerivative(.5),
        closeTo(-1.5, 1e-12),
      );
      expect(
        DashboardHeaderDeepDriftMath.cubicKernelDerivative(.75),
        closeTo(-1.125, 1e-12),
      );
      expect(DashboardHeaderDeepDriftMath.cubicKernelDerivative(1), 0);
      expect(DashboardHeaderDeepDriftMath.cubicKernelDerivative(1.1), 0);
    });

    test('evaluates an anisotropic blob and its analytic gradient', () {
      final sample = DashboardHeaderDeepDriftMath.sampleBlob(
        pointX: .60,
        pointY: .50,
        centerX: .50,
        centerY: .50,
        inverseRadiusX: 2,
        inverseRadiusY: 1,
      );

      expect(sample.r2, closeTo(.04, 1e-12));
      expect(sample.density, closeTo(.995328, 1e-12));
      expect(sample.gradientX, closeTo(-.18432, 1e-12));
      expect(sample.gradientY, 0);
    });

    test('retains exactly three fixed five-blob depth layers across ticks', () {
      final skeleton = DashboardHeaderDeepDriftSkeleton();
      final blobs = skeleton.blobStorage;
      final layers = skeleton.layerStorage;
      final settings = List<double>.filled(18, .5, growable: false)
        ..[0] = .82
        ..[1] = .32
        ..[2] = 1
        ..[3] = .55
        ..[10] = .62
        ..[13] = .06
        ..[14] = .25;

      expect(DashboardHeaderDeepDriftSkeleton.layerCount, 3);
      expect(DashboardHeaderDeepDriftSkeleton.blobsPerLayer, 5);
      expect(DashboardHeaderDeepDriftSkeleton.blobCount, 15);
      for (var tick = 0; tick < 1000; tick += 1) {
        skeleton.advance(
          elapsed: Duration(milliseconds: tick * 16),
          settings: settings,
        );
      }
      expect(skeleton.blobStorage, same(blobs));
      expect(skeleton.layerStorage, same(layers));
      expect(skeleton.blobStorage, hasLength(15 * 4));
      expect(skeleton.layerStorage, hasLength(3 * 4));
    });

    test(
      'depth separation changes retained layer geometry without allocation',
      () {
        final skeleton = DashboardHeaderDeepDriftSkeleton();
        final settings = List<double>.filled(18, .5, growable: false)
          ..[0] = .82
          ..[1] = .32
          ..[2] = 1
          ..[3] = .55
          ..[8] = .72
          ..[10] = .62
          ..[13] = .06
          ..[14] = .25;
        skeleton.advance(
          elapsed: const Duration(milliseconds: 600),
          settings: settings,
        );
        final originalStorage = skeleton.layerStorage;
        final farOffset = 2 * 4 + 3;
        final separatedFarDepth = originalStorage[farOffset];

        settings[8] = 0;
        skeleton.advance(
          elapsed: const Duration(milliseconds: 600),
          settings: settings,
        );

        expect(skeleton.layerStorage, same(originalStorage));
        expect(separatedFarDepth, greaterThan(0));
        expect(skeleton.layerStorage[farOffset], 0);
      },
    );

    test('keeps far A-biased, middle mixed and near B-biased', () {
      final weights = DashboardHeaderDeepDriftMath.depthBWeights(.78);

      expect(weights.far, lessThan(.5));
      expect(weights.middle, closeTo(.5, 1e-12));
      expect(weights.near, greaterThan(.5));
    });

    test(
      'composites near, middle, then far with front-to-back transmittance',
      () {
        final value = DashboardHeaderDeepDriftMath.composeFrontToBack(
          base: 0,
          near: const DashboardHeaderDeepDriftLayerContribution(
            color: 1,
            alpha: .5,
          ),
          middle: const DashboardHeaderDeepDriftLayerContribution(
            color: .6,
            alpha: .5,
          ),
          far: const DashboardHeaderDeepDriftLayerContribution(
            color: .2,
            alpha: .5,
          ),
        );

        expect(value, closeTo(.675, 1e-12));
      },
    );

    test(
      'uses one per-fragment three-by-five cubic field after ripple displacement',
      () async {
        final shader = await File(
          'shaders/dashboard_header_field.frag',
        ).readAsString();
        final start = shader.indexOf('vec3 deepDriftField');
        final end = shader.indexOf('// The dual-tide implementation', start);
        final deepDrift = shader.substring(start, end);

        expect(start, greaterThanOrEqualTo(0));
        expect(end, greaterThan(start));
        expect(deepDrift, contains('for (int layerIndex = 0; layerIndex < 3;'));
        expect(deepDrift, contains('for (int blobIndex = 0; blobIndex < 5;'));
        expect(deepDrift, contains('float h = max(0.0, 1.0 - r2);'));
        expect(deepDrift, contains('float derivative = -6.0 * h * (1.0 - h);'));
        expect(deepDrift, isNot(contains('exp(')));
        expect(deepDrift, isNot(contains('sin(')));
        expect(deepDrift, isNot(contains('cos(')));
        expect(shader, contains('commonField(displaced, rippleLight)'));
      },
    );
  });
}
