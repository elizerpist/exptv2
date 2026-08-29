import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_budget_cool_source.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_field_mesh.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_static_color_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Header field fidelity and fallback contract', () {
    test(
      'maximum quality is per-fragment rather than a direct vector mesh',
      () {
        final maxPlan = DashboardHeaderFragmentRenderPlan.resolve(
          logicalSize: const Size(360, 84),
          devicePixelRatio: 3,
          renderScale: 1,
        );
        expect(maxPlan.backend, DashboardHeaderRenderBackend.fragmentShader);
        expect(
          maxPlan.fieldEvaluation,
          DashboardHeaderFieldEvaluation.perFragment,
        );
        // Legacy mesh geometry remains independently testable only; it is not
        // a Header render or shader-failure fallback.
        final geometry = DashboardHeaderFieldSamplingGeometry.resolve(
          logicalSize: const Size(360, 84),
          devicePixelRatio: 3,
          renderScale: 1,
        );

        expect(geometry.logicalSize, const Size(360, 84));
        expect(geometry.physicalWidth, 1080);
        expect(geometry.physicalHeight, 252);
        expect(geometry.hasIntermediateRaster, isFalse);
        expect(
          geometry.interpolation,
          DashboardHeaderFieldInterpolation.triangularLinear,
        );
        expect(geometry.usesDirectCellRectangles, isFalse);
        expect(geometry.columns, 90);
        expect(geometry.rows, 21);
      },
    );

    test('mesh interpolation changes continuously inside a source cell', () {
      expect(
        DashboardHeaderFieldInterpolation.linearSample(
          topLeft: 0,
          topRight: 1,
          bottomLeft: 0,
          bottomRight: 1,
          x: .125,
          y: .5,
        ),
        closeTo(.125, 1e-12),
      );
      expect(
        DashboardHeaderFieldInterpolation.linearSample(
          topLeft: 0,
          topRight: 1,
          bottomLeft: 0,
          bottomRight: 1,
          x: .875,
          y: .5,
        ),
        closeTo(.875, 1e-12),
      );
    });

    test(
      'render identity cannot reuse a physical surface across DPR or quality',
      () {
        const base = DashboardHeaderFieldRenderIdentity(
          logicalWidth: 360,
          logicalHeight: 84,
          devicePixelRatio: 1,
          renderScale: .6,
          effectIdentity: 'dualTide',
          renderStepMs: 42,
          settingsGeneration: 7,
        );
        expect(
          base,
          isNot(
            const DashboardHeaderFieldRenderIdentity(
              logicalWidth: 360,
              logicalHeight: 84,
              devicePixelRatio: 3,
              renderScale: .6,
              effectIdentity: 'dualTide',
              renderStepMs: 42,
              settingsGeneration: 7,
            ),
          ),
        );
        expect(
          base,
          isNot(
            const DashboardHeaderFieldRenderIdentity(
              logicalWidth: 360,
              logicalHeight: 84,
              devicePixelRatio: 1,
              renderScale: 1,
              effectIdentity: 'dualTide',
              renderStepMs: 42,
              settingsGeneration: 7,
            ),
          ),
        );
      },
    );
  });

  group('Color Lab header-effect audit contract', () {
    test(
      'uses explicit stable shader ids instead of enum declaration order',
      () {
        final shaderIds = <DashboardHeaderEffectId, int>{
          for (final effect in DashboardHeaderEffectCatalog.effects)
            effect.id: effect.shaderId,
        };

        expect(shaderIds, const <DashboardHeaderEffectId, int>{
          DashboardHeaderEffectId.staticEffect: 0,
          DashboardHeaderEffectId.dualTide: 1,
          DashboardHeaderEffectId.magneticMembrane: 2,
          DashboardHeaderEffectId.breathingLens: 3,
          DashboardHeaderEffectId.cellularField: 4,
          DashboardHeaderEffectId.balanceMembrane: 5,
          DashboardHeaderEffectId.balanceCounterflow: 6,
          DashboardHeaderEffectId.balanceCharges: 7,
          DashboardHeaderEffectId.deepDrift: 8,
          DashboardHeaderEffectId.freeFlow: 9,
          DashboardHeaderEffectId.chaoticAdvection: 10,
          DashboardHeaderEffectId.elasticSpace: 11,
          DashboardHeaderEffectId.braidedCurrent: 12,
          DashboardHeaderEffectId.volumetricCurrent: 13,
          DashboardHeaderEffectId.metricBloom: 14,
          DashboardHeaderEffectId.gravitationalFabric: 15,
          DashboardHeaderEffectId.breathingMetric: 16,
          DashboardHeaderEffectId.tidalCurvature: 17,
        });
      },
    );

    test(
      'keeps classic IDs in source order then appends full-field flow IDs',
      () {
        expect(
          DashboardHeaderEffectCatalog.effects.map((effect) => effect.id),
          const <DashboardHeaderEffectId>[
            DashboardHeaderEffectId.staticEffect,
            DashboardHeaderEffectId.dualTide,
            DashboardHeaderEffectId.magneticMembrane,
            DashboardHeaderEffectId.breathingLens,
            DashboardHeaderEffectId.cellularField,
            DashboardHeaderEffectId.balanceMembrane,
            DashboardHeaderEffectId.balanceCounterflow,
            DashboardHeaderEffectId.balanceCharges,
            DashboardHeaderEffectId.deepDrift,
            DashboardHeaderEffectId.freeFlow,
            DashboardHeaderEffectId.chaoticAdvection,
            DashboardHeaderEffectId.elasticSpace,
            DashboardHeaderEffectId.braidedCurrent,
            DashboardHeaderEffectId.volumetricCurrent,
            DashboardHeaderEffectId.metricBloom,
            DashboardHeaderEffectId.gravitationalFabric,
            DashboardHeaderEffectId.breathingMetric,
            DashboardHeaderEffectId.tidalCurvature,
          ],
        );
        expect(
          DashboardHeaderEffectCatalog.effects
              .where(
                (effect) => effect.id == DashboardHeaderEffectId.staticEffect,
              )
              .single
              .controls,
          isEmpty,
        );
        expect(
          DashboardHeaderEffectCatalog.effectFor(
            DashboardHeaderEffectId.staticEffect,
          ).label,
          'Statikus színmező',
        );
        expect(
          DashboardHeaderEffectCatalog.effectsForFamily(
            DashboardHeaderAnimationFamily.classicReference,
          ).map((effect) => effect.shaderId),
          containsAll(<int>[0, 1, 2, 3, 4, 5, 6, 7, 8]),
        );
        expect(
          DashboardHeaderEffectCatalog.effectsForFamily(
            DashboardHeaderAnimationFamily.fullFieldFlow,
          ).map((effect) => effect.shaderId),
          <int>[9, 10, 11, 12, 13],
        );
        expect(
          DashboardHeaderEffectCatalog.effectsForFamily(
            DashboardHeaderAnimationFamily.spaceFabricWarp,
          ).map((effect) => effect.shaderId),
          <int>[14, 15, 16, 17],
        );
      },
    );

    test(
      'transcribes source control metadata instead of inventing defaults',
      () {
        final dualTide = DashboardHeaderEffectCatalog.effectFor(
          DashboardHeaderEffectId.dualTide,
        );
        expect(
          dualTide.controlFor('strength'),
          const DashboardHeaderEffectControl(
            id: 'strength',
            label: 'Animáció erő',
            min: 0,
            max: 1,
            step: .01,
            defaultValue: .82,
          ),
        );
        expect(
          dualTide.controlFor('frameMs'),
          const DashboardHeaderEffectControl(
            id: 'frameMs',
            label: 'Render lépés',
            min: 16,
            max: 100,
            step: 1,
            defaultValue: 42,
          ),
        );
        expect(
          dualTide.controlFor('phaseOffset'),
          const DashboardHeaderEffectControl(
            id: 'phaseOffset',
            label: 'Ellenfázis',
            min: 0,
            max: 360,
            step: 1,
            defaultValue: 180,
          ),
        );
        expect(
          DashboardHeaderEffectCatalog.effectFor(
            DashboardHeaderEffectId.balanceCharges,
          ).controlFor('chargeCount'),
          const DashboardHeaderEffectControl(
            id: 'chargeCount',
            label: 'Töltésszám',
            min: 2,
            max: 8,
            step: 1,
            defaultValue: 6,
          ),
        );
      },
    );
  });

  group('Portal inner-motion and background-morph source audit contract', () {
    test('freezes both source selectors exact shared five-mode catalog', () {
      const expected = <(DashboardHeaderPortalMaterialEffectId, String, bool)>[
        (
          DashboardHeaderPortalMaterialEffectId.solidA,
          'Nincs dinamikus effekt',
          false,
        ),
        (
          DashboardHeaderPortalMaterialEffectId.staticMatter,
          'Statikus köd/szigetek',
          false,
        ),
        (
          DashboardHeaderPortalMaterialEffectId.wanderingMist,
          'Vándorló köd',
          true,
        ),
        (
          DashboardHeaderPortalMaterialEffectId.livingArchipelago,
          'Élő szigetvilág',
          true,
        ),
        (
          DashboardHeaderPortalMaterialEffectId.formingClouds,
          'Keletkező energiafelhők',
          true,
        ),
      ];

      expect(
        DashboardHeaderPortalMaterialCatalog.effects.map(
          (effect) => (effect.id, effect.label, effect.isAnimated),
        ),
        expected,
      );
      expect(
        DashboardHeaderPortalMaterialCatalog.defaultEffect,
        DashboardHeaderPortalMaterialEffectId.wanderingMist,
      );

      final mist = DashboardHeaderPortalMaterialCatalog.effectFor(
        DashboardHeaderPortalMaterialEffectId.wanderingMist,
      );
      expect(
        mist.controlFor('coverage'),
        const DashboardHeaderEffectControl(
          id: 'coverage',
          label: 'B-fedettség',
          min: 0,
          max: 80,
          step: 1,
          defaultValue: 36,
          unit: '%',
        ),
      );
      expect(
        mist.controlFor('seed'),
        const DashboardHeaderEffectControl(
          id: 'seed',
          label: 'Véletlenmag',
          min: 0,
          max: 9999,
          step: 1,
          defaultValue: 311,
          unit: '',
        ),
      );
      expect(
        DashboardHeaderPortalMaterialCatalog.effectFor(
          DashboardHeaderPortalMaterialEffectId.formingClouds,
        ).controlFor('lifetime'),
        const DashboardHeaderEffectControl(
          id: 'lifetime',
          label: 'Élettartam',
          min: 2,
          max: 30,
          step: 1,
          defaultValue: 14,
          unit: 's',
        ),
      );

      // This source-derived inventory protects every visible parameter, not
      // merely the currently selected default mode in the tuner.
      const expectedControls =
          <
            DashboardHeaderPortalMaterialEffectId,
            List<(String, String, double, double, double, double, String)>
          >{
            DashboardHeaderPortalMaterialEffectId.staticMatter:
                <(String, String, double, double, double, double, String)>[
                  ('coverage', 'B-fedettség', 0, 80, 1, 34, '%'),
                  ('strength', 'B-erősség', 0, 100, 1, 72, '%'),
                  ('scale', 'Anyagskála', 20, 180, 1, 100, '%'),
                  ('softness', 'Peremlágyság', 0, 100, 1, 76, '%'),
                  ('detail', 'Részletesség', 0, 100, 1, 28, '%'),
                  ('seed', 'Véletlenmag', 0, 9999, 1, 137, ''),
                ],
            DashboardHeaderPortalMaterialEffectId.wanderingMist:
                <(String, String, double, double, double, double, String)>[
                  ('coverage', 'B-fedettség', 0, 80, 1, 36, '%'),
                  ('strength', 'B-erősség', 0, 100, 1, 74, '%'),
                  ('scale', 'Ködskála', 20, 200, 1, 118, '%'),
                  ('softness', 'Peremlágyság', 0, 100, 1, 82, '%'),
                  ('driftSpeed', 'Sodródási sebesség', 0, 100, 1, 22, '%'),
                  ('curl', 'Curl erősség', 0, 100, 1, 44, '%'),
                  ('morphRate', 'Alakváltozás', 0, 100, 1, 28, '%'),
                  ('detail', 'Részletesség', 0, 100, 1, 24, '%'),
                  ('seed', 'Véletlenmag', 0, 9999, 1, 311, ''),
                ],
            DashboardHeaderPortalMaterialEffectId.livingArchipelago:
                <(String, String, double, double, double, double, String)>[
                  ('islandCount', 'Szigetszám', 2, 12, 1, 6, ''),
                  ('size', 'Átlagos méret', 8, 80, 1, 34, '%'),
                  ('sizeVariance', 'Méreteltérés', 0, 100, 1, 42, '%'),
                  ('strength', 'B-erősség', 0, 100, 1, 78, '%'),
                  ('softness', 'Peremlágyság', 0, 100, 1, 66, '%'),
                  ('wanderSpeed', 'Vándorlási sebesség', 0, 100, 1, 30, '%'),
                  (
                    'mergeAttraction',
                    'Összeolvadási vonzás',
                    0,
                    100,
                    1,
                    55,
                    '%',
                  ),
                  ('morphRate', 'Alakváltozás', 0, 100, 1, 36, '%'),
                  ('seed', 'Véletlenmag', 0, 9999, 1, 521, ''),
                ],
            DashboardHeaderPortalMaterialEffectId.formingClouds:
                <(String, String, double, double, double, double, String)>[
                  ('density', 'Aktív felhősűrűség', 1, 10, 1, 4, ''),
                  ('lifetime', 'Élettartam', 2, 30, 1, 14, 's'),
                  ('birthOverlap', 'Születési átfedés', 0, 100, 1, 58, '%'),
                  ('growth', 'Növekedés', 0, 100, 1, 46, '%'),
                  ('strength', 'B-erősség', 0, 100, 1, 76, '%'),
                  ('scale', 'Felhőskála', 10, 120, 1, 46, '%'),
                  ('softness', 'Peremlágyság', 0, 100, 1, 78, '%'),
                  ('driftSpeed', 'Sodródási sebesség', 0, 100, 1, 24, '%'),
                  (
                    'pathIrregularity',
                    'Útvonal-szabálytalanság',
                    0,
                    100,
                    1,
                    52,
                    '%',
                  ),
                  ('seed', 'Véletlenmag', 0, 9999, 1, 887, ''),
                ],
          };
      for (final entry in expectedControls.entries) {
        expect(
          DashboardHeaderPortalMaterialCatalog.effectFor(entry.key).controls
              .map(
                (control) => (
                  control.id,
                  control.label,
                  control.min,
                  control.max,
                  control.step,
                  control.defaultValue,
                  control.unit,
                ),
              )
              .toList(),
          entry.value,
          reason: '${entry.key.name} source control schema',
        );
      }
    });

    test('matches source material values at deterministic source phases', () {
      final staticMatter = DashboardHeaderPortalMaterialCatalog.defaultSettings(
        DashboardHeaderPortalMaterialEffectId.staticMatter,
      );
      expect(
        DashboardHeaderPortalMaterialField.sample(
          effect: DashboardHeaderPortalMaterialEffectId.staticMatter,
          x: .2,
          y: .4,
          phase: 0,
          settings: staticMatter,
        ),
        closeTo(.04237777529173437, 1e-12),
      );
      expect(
        DashboardHeaderPortalMaterialField.sample(
          effect: DashboardHeaderPortalMaterialEffectId.staticMatter,
          x: .2,
          y: .4,
          phase: 1,
          settings: staticMatter,
        ),
        closeTo(.04237777529173437, 1e-12),
      );

      const samples = <DashboardHeaderPortalMaterialEffectId, List<double>>{
        DashboardHeaderPortalMaterialEffectId.wanderingMist: <double>[
          .38599687378155489,
          .36946404731754862,
          .35669051972182936,
          .34670216131777004,
          .33886251653467425,
        ],
        DashboardHeaderPortalMaterialEffectId.livingArchipelago: <double>[
          .61017454352364464,
          .66681521145581957,
          .71627795234340919,
          .75407374973203201,
          .77596778510835562,
        ],
        DashboardHeaderPortalMaterialEffectId.formingClouds: <double>[
          .26841443209810728,
          .29277316955126859,
          .31566248482083747,
          .33616819964471761,
          .35348737005911990,
        ],
      };
      const phases = <double>[0, .25, .5, .75, 1];
      for (final entry in samples.entries) {
        final point =
            entry.key == DashboardHeaderPortalMaterialEffectId.livingArchipelago
            ? const Offset(.13, .81)
            : entry.key == DashboardHeaderPortalMaterialEffectId.formingClouds
            ? const Offset(.92, .17)
            : const Offset(.5, .5);
        final settings = DashboardHeaderPortalMaterialCatalog.defaultSettings(
          entry.key,
        );
        for (var index = 0; index < phases.length; index += 1) {
          expect(
            DashboardHeaderPortalMaterialField.sample(
              effect: entry.key,
              x: point.dx,
              y: point.dy,
              phase: phases[index],
              settings: settings,
            ),
            closeTo(entry.value[index], 1e-12),
            reason: '${entry.key} phase ${phases[index]}',
          );
        }
      }
    });

    test(
      'keeps two source-derived channel states independent on one clock',
      () {
        final controller = DashboardHeaderVisualController(
          vsync: const TestVSync(),
        );
        addTearDown(controller.dispose);

        final tickerIdentity = controller.tickerIdentity;
        expect(
          controller.portalInnerMotion.effect,
          DashboardHeaderPortalMaterialEffectId.wanderingMist,
        );
        expect(
          controller.portalBackgroundMorph.effect,
          DashboardHeaderPortalMaterialEffectId.wanderingMist,
        );
        expect(controller.portalInnerMotion.enabled, isTrue);
        expect(controller.portalBackgroundMorph.enabled, isTrue);

        controller.selectPortalEffect(
          DashboardHeaderPortalChannel.innerMotion,
          DashboardHeaderPortalMaterialEffectId.formingClouds,
        );
        controller.updatePortalControl(
          DashboardHeaderPortalChannel.innerMotion,
          'density',
          7,
        );
        controller.setPortalInnerRotation(enabled: true, speed: 64);

        expect(
          controller.portalBackgroundMorph.effect,
          DashboardHeaderPortalMaterialEffectId.wanderingMist,
        );
        expect(
          controller.portalBackgroundMorph.settingsFor(
            DashboardHeaderPortalMaterialEffectId.wanderingMist,
          )['density'],
          isNull,
        );
        expect(controller.portalInnerMotion.rotationEnabled, isTrue);
        expect(controller.portalInnerMotion.rotationSpeed, 64);

        controller.debugAdvance(const Duration(seconds: 1));
        expect(controller.tickerIdentity, same(tickerIdentity));
        expect(
          controller.portalInnerMotion.phaseFor(
            DashboardHeaderPortalMaterialEffectId.formingClouds,
          ),
          1,
        );
        expect(
          controller.portalBackgroundMorph.phaseFor(
            DashboardHeaderPortalMaterialEffectId.wanderingMist,
          ),
          closeTo(22 / 24, 1e-12),
        );

        controller.resetActivePortalEffect(
          DashboardHeaderPortalChannel.innerMotion,
        );
        expect(
          controller.portalInnerMotion.settingsFor(
            DashboardHeaderPortalMaterialEffectId.formingClouds,
          )['density'],
          4,
        );
        expect(
          controller.portalBackgroundMorph.effect,
          DashboardHeaderPortalMaterialEffectId.wanderingMist,
        );
      },
    );

    test('static/off source combinations let the one shared clock idle', () {
      final controller = DashboardHeaderVisualController(
        vsync: const TestVSync(),
      );
      addTearDown(controller.dispose);

      final tickerIdentity = controller.tickerIdentity;
      controller.selectEffect(DashboardHeaderEffectId.staticEffect);
      controller.selectPortalEffect(
        DashboardHeaderPortalChannel.innerMotion,
        DashboardHeaderPortalMaterialEffectId.staticMatter,
      );
      controller.selectPortalEffect(
        DashboardHeaderPortalChannel.backgroundMorph,
        DashboardHeaderPortalMaterialEffectId.solidA,
      );

      expect(controller.tickerIdentity, same(tickerIdentity));
      expect(controller.tickerIsActive, isFalse);

      controller.selectPortalEffect(
        DashboardHeaderPortalChannel.backgroundMorph,
        DashboardHeaderPortalMaterialEffectId.wanderingMist,
      );
      expect(controller.tickerIdentity, same(tickerIdentity));
      expect(controller.tickerIsActive, isTrue);
    });
  });

  test(
    'one stable shared ticker advances phase and pulse without semantic state',
    () {
      final controller = DashboardHeaderVisualController(
        vsync: const TestVSync(),
      );
      addTearDown(controller.dispose);

      final identity = controller.tickerIdentity;
      controller.selectEffect(DashboardHeaderEffectId.dualTide);
      controller.debugAdvance(const Duration(seconds: 1));
      expect(controller.tickerIdentity, same(identity));
      expect(controller.phase, .42);

      controller.triggerPulse();
      expect(controller.pulseAmount, 1);
      controller.debugAdvance(const Duration(milliseconds: 780));
      expect(controller.pulseAmount, .5);
      controller.debugAdvance(const Duration(milliseconds: 780));
      expect(controller.pulseAmount, 0);
    },
  );

  test(
    'tap waves use the existing shared Header clock without a controller per touch',
    () {
      final controller = DashboardHeaderVisualController(
        vsync: const TestVSync(),
      );
      addTearDown(controller.dispose);

      controller.selectEffect(DashboardHeaderEffectId.staticEffect);
      controller.selectPortalEffect(
        DashboardHeaderPortalChannel.innerMotion,
        DashboardHeaderPortalMaterialEffectId.staticMatter,
      );
      controller.selectPortalEffect(
        DashboardHeaderPortalChannel.backgroundMorph,
        DashboardHeaderPortalMaterialEffectId.solidA,
      );
      final ticker = controller.tickerIdentity;
      expect(controller.tickerIsActive, isFalse);

      controller.beginTapWave(const Offset(.25, .75));
      expect(controller.tickerIdentity, same(ticker));
      expect(controller.tickerIsActive, isTrue);
      expect(controller.tapWave.rippleCount, 1);

      controller.endTapWave();
      controller.debugAdvance(const Duration(milliseconds: 1900));
      expect(controller.tickerIdentity, same(ticker));
      expect(controller.tapWave.requiresFrames, isFalse);
      expect(controller.tickerIsActive, isFalse);
    },
  );

  test('effect field samples match the audited Color Lab source points', () {
    const expectedMix = <DashboardHeaderEffectId, double>{
      DashboardHeaderEffectId.dualTide: .30937178307546137,
      DashboardHeaderEffectId.magneticMembrane: .10604610866937017,
      DashboardHeaderEffectId.breathingLens: .5073245722071098,
      DashboardHeaderEffectId.cellularField: .7831545597048444,
      DashboardHeaderEffectId.balanceMembrane: .40013635486963023,
      DashboardHeaderEffectId.balanceCounterflow: .3172942145858555,
      DashboardHeaderEffectId.balanceCharges: .3623154547134118,
    };
    for (final entry in expectedMix.entries) {
      final settings = DashboardHeaderEffectCatalog.effectFor(
        entry.key,
      ).defaultSettings;
      final sample = DashboardHeaderEffectMath.sample(
        effect: entry.key,
        x: .35,
        y: .67,
        phase: 1.25,
        paletteSplitPercent: 50,
        settings: settings,
      );
      expect(sample.coordinate, closeTo(entry.value, 1e-12));
    }
  });

  test('Budget policy publishes only the global Cool triplet', () {
    FluviDiagnosticLogger.clear();
    final visual = DashboardHeaderVisualController(vsync: const TestVSync());
    final policy = DashboardBudgetHeaderColorPolicy(tuning: visual.tuning);
    addTearDown(() {
      policy.dispose();
      visual.dispose();
    });

    expect(policy.value.colors, const <Color>[
      Color(0xff61e1fb),
      Color(0xff14c5e1),
      Color(0xff0390ca),
    ]);
    expect(policy.value.stops, const <double>[0, .5, 1]);
    expect(policy.value.budgetCoolWindow!.positionPercent, 50);
    expect(policy.value.budgetCoolWindow!.windowWidthPercent, 28);

    visual.setBudgetCoolWindowWidthPercent(100);
    visual.setBudgetCoolPositionPercent(0);
    expect(policy.value.colors, const <Color>[
      Color(0xffffffff),
      Color(0xffffffff),
      Color(0xff14c5e1),
    ]);
    expect(policy.value.stops, const <double>[0, .5, 1]);
    final diagnostics = FluviDiagnosticLogger.entries
        .where((entry) => entry.stage == 'BUDGET_HEADER_COOL_COLOR_BOUND')
        .toList();
    expect(diagnostics, isNotEmpty);
    expect(diagnostics.last.scope, contains('driver=userGlobal'));
    expect(diagnostics.last.scope, contains('positionPct=0'));
    expect(diagnostics.last.scope, contains('windowWidthPct=100'));
  });
  testWidgets('phase ticks repaint only the dedicated Header visual lane', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    var staticContentBuilds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 120,
          child: DashboardHeaderVisualPaintLayer(
            controller: controller,
            frame: _coolFrame(),
            child: Builder(
              builder: (context) {
                staticContentBuilds += 1;
                return const Text('static header content');
              },
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('dashboard-header-visual-paint')),
      findsOneWidget,
    );
    expect(staticContentBuilds, 1);

    await tester.pump(const Duration(milliseconds: 48));
    expect(staticContentBuilds, 1);
    controller.dispose();
  });

  testWidgets(
    'controlled Header resize retains its one ticker and fragment backend',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      final backend = DashboardHeaderFragmentBackend.forTesting();
      final size = ValueNotifier<Size>(const Size(320, 120));
      addTearDown(backend.dispose);
      addTearDown(size.dispose);
      controller.selectEffect(DashboardHeaderEffectId.dualTide);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<Size>(
            valueListenable: size,
            builder: (context, currentSize, _) => SizedBox(
              width: currentSize.width,
              height: currentSize.height,
              child: DashboardHeaderVisualPaintLayer(
                controller: controller,
                frame: _coolFrame(),
                debugFragmentBackend: backend,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final tickerIdentity = controller.tickerIdentity;
      final backendIdentity = backend.backendIdentity;
      for (final currentSize in const <Size>[
        Size(320, 114),
        Size(320, 106),
        Size(320, 96),
        Size(320, 84),
        Size(320, 96),
        Size(320, 120),
      ]) {
        size.value = currentSize;
        await tester.pump();
        expect(controller.tickerIdentity, same(tickerIdentity));
        expect(backend.backendIdentity, same(backendIdentity));
        expect(backend.programCreations, 0);
        expect(backend.shaderCreations, 0);
      }
      controller.dispose();
    },
  );

  testWidgets('an active Header emits physical backend proof configuration', (
    tester,
  ) async {
    FluviDiagnosticLogger.clear();
    final controller = DashboardHeaderVisualController(vsync: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 120,
          child: DashboardHeaderVisualPaintLayer(
            controller: controller,
            frame: DashboardHeaderVisualFrame.staticTone(Colors.blue),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();
    // Let the production FragmentProgram future complete through the same
    // resource listener which emits the physical diagnostic stream.
    await tester.pump(const Duration(seconds: 1));

    final events = FluviDiagnosticLogger.entries;
    final bindings = events
        .where((event) => event.stage == 'HEADER_RENDER_BACKEND_BOUND')
        .toList(growable: false);
    expect(bindings, hasLength(1));
    final readiness = events
        .where(
          (event) =>
              event.stage == 'HEADER_SHADER_READY' ||
              event.stage == 'HEADER_SHADER_FALLBACK',
        )
        .toList(growable: false);
    expect(readiness, hasLength(1));
    expect(
      events.indexOf(bindings.single),
      lessThan(events.indexOf(readiness.single)),
    );
    final configuration = events.firstWhere(
      (event) => event.stage == 'HEADER_RENDER_FIDELITY_CONFIG',
    );
    expect(
      events.indexOf(readiness.single),
      lessThan(events.indexOf(configuration)),
    );
    expect(configuration.scope, contains('fieldEvaluationMode=perFragment'));
    expect(configuration.scope, contains('backend=fragmentShader'));
    controller.dispose();
  });

  testWidgets(
    'a pure static Header binds the Spendee native base without requiring the FragmentProgram',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final controller = DashboardHeaderVisualController(vsync: tester);
      controller.selectEffect(DashboardHeaderEffectId.staticEffect);
      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.innerMotion,
        false,
      );
      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.backgroundMorph,
        false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 120,
            child: DashboardHeaderVisualPaintLayer(
              controller: controller,
              frame: _coolFrame(opacityScalePosition: 100),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final staticBinding = FluviDiagnosticLogger.entries.singleWhere(
        (entry) => entry.stage == 'HEADER_STATIC_COLOR_RENDERER_BOUND',
      );
      expect(
        staticBinding.scope,
        contains('renderer=budget2CssLinearGradient'),
      );
      expect(staticBinding.scope, contains('cssDegrees=112'));
      expect(staticBinding.scope, contains('fieldStopCount=3'));
      expect(staticBinding.scope, contains('fragmentBaseRequired=false'));
      expect(
        FluviDiagnosticLogger.entries.where(
          (entry) => entry.stage == 'HEADER_RENDER_BACKEND_BOUND',
        ),
        isEmpty,
        reason:
            'The isolated static base must not bind the FragmentProgram before '
            'painting its historical native ui.Gradient.linear field.',
      );
      expect(controller.tickerIsActive, isFalse);
      controller.dispose();
    },
  );

  testWidgets(
    'a pure static Header paints the frame finite field without a dense reconstruction',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      controller.selectEffect(DashboardHeaderEffectId.staticEffect);
      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.innerMotion,
        false,
      );
      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.backgroundMorph,
        false,
      );
      const colors = <Color>[
        Color(0xffffffff),
        Color(0xffdff9ff),
        Color(0xff91e7f4),
        Color(0xff2ccdd9),
        Color(0xff20aee4),
        Color(0xff2086ea),
        Color(0xff2164d6),
        Color(0xff4847bd),
        Color(0xff632e9b),
        Color(0xff371157),
      ];
      const stops = <double>[
        0,
        1 / 9,
        2 / 9,
        3 / 9,
        4 / 9,
        5 / 9,
        6 / 9,
        7 / 9,
        8 / 9,
        1,
      ];
      const frame = DashboardHeaderVisualFrame(
        colors: colors,
        stops: stops,
        opacity: 1,
        colorA: Color(0xffffffff),
        colorB: Color(0xff371157),
      );
      final boundary = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 320,
                height: 120,
                child: DashboardHeaderVisualPaintLayer(
                  controller: controller,
                  frame: frame,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final actual = await _headerRgba(tester, boundary);
      final expected = await _nativeStaticFieldRgba(
        tester: tester,
        colors: colors,
        stops: stops,
        size: const Size(320, 120),
      );

      expect(
        actual.buffer.asUint8List(),
        orderedEquals(expected.buffer.asUint8List()),
        reason:
            'The isolated static painter must forward the frame\'s exact '
            'finite colors/stops to the native renderer; an intermediate '
            'PCHIP or dense field changes these pixels.',
      );
      controller.dispose();
    },
  );

  testWidgets(
    'a Portal inner toggle publishes an end-to-end retained render binding',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final controller = DashboardHeaderVisualController(vsync: tester);
      final generation = controller.portalSettingsGeneration.value;
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 120,
            child: DashboardHeaderVisualPaintLayer(
              controller: controller,
              frame: _coolFrame(opacityScalePosition: 100),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      FluviDiagnosticLogger.clear();

      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.innerMotion,
        false,
      );
      await tester.pump();

      expect(controller.portalInnerMotion.enabled, isFalse);
      expect(controller.portalBackgroundMorph.enabled, isTrue);
      expect(controller.portalSettingsGeneration.value, generation + 1);
      final event = FluviDiagnosticLogger.entries.firstWhere(
        (entry) => entry.stage == 'HEADER_PORTAL_INNER_CHANNEL_BOUND',
      );
      expect(event.scope, contains('enabled=false'));
      expect(event.scope, contains('canonicalFieldStopCount='));
      expect(event.scope, contains('phaseOwnerIdentity='));
      expect(event.scope, contains('fragmentBackendIdentity='));
      controller.dispose();
    },
  );

  testWidgets(
    'the retained runtime shader gives a static Cool Header a visible independent inner Portal contribution',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      controller.selectEffect(DashboardHeaderEffectId.staticEffect);
      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.backgroundMorph,
        false,
      );
      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.innerMotion,
        false,
      );
      final boundary = GlobalKey();
      final frame = _coolFrame(
        opacityScalePosition: 100,
        state: const BudgetHeaderGlobalCoolState(
          positionPercent: 50,
          windowWidthPercent: 100,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 320,
                height: 120,
                child: DashboardHeaderVisualPaintLayer(
                  controller: controller,
                  frame: frame,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final off = await _headerRgba(tester, boundary);
      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.innerMotion,
        true,
      );
      await tester.pump();
      final on = await _headerRgba(tester, boundary);

      final difference = _headerPixelDifference(off, on);
      expect(
        difference.changedPixelCount,
        greaterThan(320 * 120 ~/ 10),
        reason:
            'At least ten percent of the output must change for the inner '
            'Portal toggle to be visibly independent rather than a state-only '
            'or imperceptible visual no-op. difference=$difference',
      );
      expect(
        difference.meanRgbDelta,
        greaterThan(2.5),
        reason:
            'The inner layer must retain a materially visible source-over '
            'contribution after sampling the complete canonical palette. '
            'difference=$difference',
      );

      final tickerIdentity = controller.tickerIdentity;
      controller.updatePortalControl(
        DashboardHeaderPortalChannel.innerMotion,
        'coverage',
        0,
      );
      await tester.pump();
      final zeroCoverage = await _headerRgba(tester, boundary);
      final settingDifference = _headerPixelDifference(on, zeroCoverage);
      expect(
        settingDifference.changedPixelCount,
        greaterThan(320 * 120 ~/ 10),
        reason:
            'An inner wandering-mist control must change final pixels, not '
            'only its retained state. difference=$settingDifference',
      );
      expect(controller.tickerIdentity, same(tickerIdentity));
      controller.updatePortalControl(
        DashboardHeaderPortalChannel.innerMotion,
        'coverage',
        36,
      );
      await tester.pump();

      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.innerMotion,
        false,
      );
      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.backgroundMorph,
        true,
      );
      await tester.pump();
      final backgroundOnly = await _headerRgba(tester, boundary);
      final backgroundDifference = _headerPixelDifference(off, backgroundOnly);
      expect(
        backgroundDifference.changedPixelCount,
        greaterThan(320 * 120 ~/ 10),
        reason:
            'The separately enabled background Portal channel must survive '
            'the static base compositing path. difference=$backgroundDifference',
      );

      controller.setPortalEnabled(
        DashboardHeaderPortalChannel.innerMotion,
        true,
      );
      await tester.pump();
      final both = await _headerRgba(tester, boundary);
      final combinedDifference = _headerPixelDifference(backgroundOnly, both);
      expect(
        combinedDifference.changedPixelCount,
        greaterThan(320 * 120 ~/ 10),
        reason:
            'The inner channel must remain independently observable when '
            'background Portal material is already active. '
            'difference=$combinedDifference',
      );
      controller.dispose();
    },
  );

  testWidgets(
    'Header-body pointer waves are passive and a stacked hamburger excludes them',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      var hamburgerTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 240,
            height: 96,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DashboardHeaderTapWaveGestureLayer(
                    controller: controller,
                    child: GestureDetector(
                      key: const ValueKey<String>('tap-wave-header-body'),
                      behavior: HitTestBehavior.translucent,
                      onPanUpdate: (_) {},
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    key: const ValueKey<String>('tap-wave-hamburger'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => hamburgerTaps += 1,
                    child: const SizedBox(width: 40, height: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('tap-wave-header-body')),
      );
      await tester.pump();
      expect(controller.tapWave.rippleCount, 1);

      await tester.tap(
        find.byKey(const ValueKey<String>('tap-wave-hamburger')),
      );
      await tester.pump();
      expect(hamburgerTaps, 1);
      expect(
        controller.tapWave.rippleCount,
        1,
        reason: 'the stacked action retains its independent hit target',
      );
      controller.dispose();
    },
  );

  testWidgets('reduced motion freezes only the shared Header paint clock', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child!,
        ),
        home: DashboardHeaderVisualPaintLayer(
          controller: controller,
          frame: DashboardHeaderVisualFrame.staticTone(Colors.blue),
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(controller.tickerIsActive, isFalse);
    expect(controller.tuning.value.effect, DashboardHeaderEffectId.dualTide);
    controller.dispose();
  });
}

Future<ByteData> _headerRgba(WidgetTester tester, GlobalKey boundary) async {
  final renderBoundary =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(
    () => renderBoundary.toImage(pixelRatio: 1),
  ))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) {
      throw StateError('Could not inspect the Header render pixels.');
    }
    return bytes;
  } finally {
    image.dispose();
  }
}

Future<ByteData> _nativeStaticFieldRgba({
  required WidgetTester tester,
  required List<Color> colors,
  required List<double> stops,
  required Size size,
}) async {
  final recorder = ui.PictureRecorder();
  DashboardHeaderStaticColorRenderer.paint(
    canvas: Canvas(recorder),
    rect: Offset.zero & size,
    colors: colors,
    stops: stops,
    opacity: 1,
  );
  final image = (await tester.runAsync(
    () => recorder.endRecording().toImage(
      size.width.round(),
      size.height.round(),
    ),
  ))!;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) {
      throw StateError('Could not inspect the expected static Header pixels.');
    }
    return bytes;
  } finally {
    image.dispose();
  }
}

_HeaderPixelDifference _headerPixelDifference(ByteData first, ByteData second) {
  if (first.lengthInBytes != second.lengthInBytes) {
    throw StateError('Header images differ in dimensions.');
  }
  var changed = 0;
  var totalRgbDelta = 0;
  var maximumRgbDelta = 0;
  for (var offset = 0; offset < first.lengthInBytes; offset += 4) {
    final delta =
        (first.getUint8(offset) - second.getUint8(offset)).abs() +
        (first.getUint8(offset + 1) - second.getUint8(offset + 1)).abs() +
        (first.getUint8(offset + 2) - second.getUint8(offset + 2)).abs();
    if (delta == 0) continue;
    changed += 1;
    totalRgbDelta += delta;
    if (delta > maximumRgbDelta) maximumRgbDelta = delta;
  }
  return _HeaderPixelDifference(
    changedPixelCount: changed,
    meanRgbDelta: totalRgbDelta / (first.lengthInBytes / 4),
    maximumRgbDelta: maximumRgbDelta,
  );
}

final class _HeaderPixelDifference {
  const _HeaderPixelDifference({
    required this.changedPixelCount,
    required this.meanRgbDelta,
    required this.maximumRgbDelta,
  });

  final int changedPixelCount;
  final double meanRgbDelta;
  final int maximumRgbDelta;

  @override
  String toString() =>
      'changed=$changedPixelCount meanRgbDelta=${meanRgbDelta.toStringAsFixed(3)} '
      'maximumRgbDelta=$maximumRgbDelta';
}

DashboardHeaderVisualFrame _coolFrame({
  double opacityScalePosition = 50,
  BudgetHeaderGlobalCoolState state =
      const BudgetHeaderGlobalCoolState.defaults(),
}) => BudgetHeaderCoolColorScale.fromWindow(
  window: BudgetHeaderCoolWindowSampler.sample(state),
  opacityScalePosition: opacityScalePosition,
  staticSettingsGeneration: 0,
);
