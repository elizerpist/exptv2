import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_target.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_field_mesh.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_fragment_backend.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_painter.dart';

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
        expect(maxPlan.legacyMeshColumns, isNull);
        expect(maxPlan.legacyMeshRows, isNull);

        // This geometry remains the deliberate low-quality/failure fallback.
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
    test('contains every non-Portal MindPortalEnergy mode in source order', () {
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
    });

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

    test('a live A/B palette change recolours an existing Portal field only', () {
      final lane = DashboardHeaderPortalMaterialPaintLane();
      final state = DashboardHeaderPortalChannelState.backgroundMorphDefaults();
      void paint(Color colorA, Color colorB) {
        final recorder = ui.PictureRecorder();
        lane.paintBackground(
          Canvas(recorder),
          const Size(360, 84),
          state: state,
          colorA: colorA,
          colorB: colorB,
          opacity: 1,
          elapsedMicros: 0,
          devicePixelRatio: 3,
        );
        recorder.endRecording().dispose();
      }

      paint(const Color(0xff0044ff), const Color(0xff00ddff));
      expect(lane.backgroundFieldRebuildCount, 1);

      paint(const Color(0xffff0044), const Color(0xffffcc00));
      expect(
        lane.backgroundFieldRebuildCount,
        1,
        reason:
            'Target change may recolour live Header A/B immediately but must not regenerate the source field.',
      );
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

    test(
      'projects source palette window and rotated interior sample point',
      () {
        final palette =
            DashboardHeaderPortalMaterialProjection.backgroundPalette(
              colorA: const Color(0xff000000),
              colorB: const Color(0xffffffff),
              centerPercent: 50,
              windowPercent: 68,
            );
        expect(palette.colorA, const Color(0xff292929));
        expect(palette.colorB, const Color(0xffd6d6d6));

        final point =
            DashboardHeaderPortalMaterialProjection.interiorSamplePoint(
              x: .5,
              y: 0,
              width: 160,
              height: 40,
              phase: .25,
              rotationEnabled: false,
              rotationSpeed: 100,
            );
        expect(point.x, .5);
        expect(point.y, .375);
        expect(point.angle, 0);
        expect(point.spanPx, 160);

        final rotated =
            DashboardHeaderPortalMaterialProjection.interiorSamplePoint(
              x: 0,
              y: .5,
              width: 160,
              height: 40,
              phase: .25,
              rotationEnabled: true,
              rotationSpeed: 100,
            );
        expect(rotated.x, .5);
        expect(rotated.y, 0);
        expect(rotated.angle, closeTo(3.141592653589793 / 2, 1e-12));
        expect(rotated.spanPx, 160);
      },
    );
  });

  group('Budget Color Lab scale projection', () {
    test('uses the source opacity scale interpolation', () {
      expect(DashboardHeaderOpacityScale.valueAt(0), .16);
      expect(DashboardHeaderOpacityScale.valueAt(50), .57);
      expect(DashboardHeaderOpacityScale.valueAt(100), 1);
    });

    test('samples a clamped finite window, not a static alpha overlay', () {
      final category = CategoryColorCatalog.resolve('color_13');

      final zero = BudgetHeaderColorScale.project(
        canonicalGradient: category,
        rawProgress: 0,
        windowWidthPercent: 28,
        opacityScalePosition: 50,
      );
      expect(zero.windowLeftPercent, 0);
      expect(zero.windowRightPercent, 28);
      expect(zero.colorA, const Color(0xffffffff));
      expect(zero.colorB, const Color(0xffc8e6fc));
      expect(zero.opacity, .57);

      final quarter = BudgetHeaderColorScale.project(
        canonicalGradient: category,
        rawProgress: .25,
        windowWidthPercent: 28,
        opacityScalePosition: 50,
      );
      expect(quarter.windowLeftPercent, 11);
      expect(quarter.windowRightPercent, 39);
      expect(quarter.colorA, const Color(0xffe9f6fe));
      expect(quarter.colorB, const Color(0xffb2dafb));

      final middle = BudgetHeaderColorScale.project(
        canonicalGradient: category,
        rawProgress: .5,
        windowWidthPercent: 28,
        opacityScalePosition: 50,
      );
      expect(middle.windowLeftPercent, 36);
      expect(middle.windowRightPercent, 64);
      expect(middle.colorA, const Color(0xffb8defc));
      expect(middle.colorB, const Color(0xff83bef8));

      final terminal = BudgetHeaderColorScale.project(
        canonicalGradient: category,
        rawProgress: 1.25,
        windowWidthPercent: 28,
        opacityScalePosition: 50,
      );
      expect(terminal.windowLeftPercent, 72);
      expect(terminal.windowRightPercent, 100);
      expect(terminal.colorA, const Color(0xff74b3f6));
      expect(terminal.colorB, const Color(0xff418cf0));

      final exactCapacity = BudgetHeaderColorScale.project(
        canonicalGradient: category,
        rawProgress: 1,
        windowWidthPercent: 28,
        opacityScalePosition: 50,
      );
      expect(exactCapacity.windowLeftPercent, 72);
      expect(exactCapacity.windowRightPercent, 100);
      expect(exactCapacity.colorA, terminal.colorA);
      expect(exactCapacity.colorB, terminal.colorB);
    });

    test('keeps the target canonical gradient intact for no-limit state', () {
      final category = CategoryColorCatalog.resolve('color_13');
      final frame = BudgetHeaderColorScale.noLimit(
        canonicalGradient: category,
        opacityScalePosition: 50,
      );

      expect(frame.colors, <Color>[
        category.colorA,
        category.middleColor,
        category.colorB,
      ]);
      expect(frame.stops, const <double>[0, .52, 1]);
      expect(frame.opacity, .57);
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

  test(
    'Budget policy follows the one live selection and never owns edit state',
    () {
      final targetCatalog = DashboardBudgetTargetCatalog.fromCategories(
        const <DashboardBudgetCategoryVisual>[
          DashboardBudgetCategoryVisual(
            id: 'food',
            displayName: 'Food',
            colorId: 'color_13',
            iconId: 'icon_01',
          ),
          DashboardBudgetCategoryVisual(
            id: 'travel',
            displayName: 'Travel',
            colorId: 'color_14',
            iconId: 'icon_01',
          ),
        ],
      );
      final visual = DashboardHeaderVisualController(vsync: const TestVSync());
      final liveState = ValueNotifier<DashboardBudgetPresentationState>(
        _budgetPresentationState(
          target: targetCatalog.targetAtHandle(1),
          title: 'Food',
          actualScaled100: 2500,
          limitScaled100: 10000,
        ),
      );
      final policy = DashboardBudgetHeaderColorPolicy(
        presentation: liveState,
        tuning: visual.tuning,
      );
      addTearDown(() {
        policy.dispose();
        liveState.dispose();
        visual.dispose();
      });

      final food = CategoryColorCatalog.resolve('color_13');
      expect(
        policy.value,
        equals(
          BudgetHeaderColorScale.project(
            canonicalGradient: food,
            rawProgress: .25,
            windowWidthPercent: 28,
            opacityScalePosition: 50,
          ),
        ),
      );

      // This simulates the existing optimistic live selection publication: no
      // persistence/repository activity belongs to this policy.
      liveState.value = _budgetPresentationState(
        target: targetCatalog.targetAtHandle(1),
        title: 'Food',
        actualScaled100: 2500,
        limitScaled100: 20000,
      );
      expect(
        policy.value.windowLeftPercent,
        BudgetHeaderColorScale.project(
          canonicalGradient: food,
          rawProgress: .125,
          windowWidthPercent: 28,
          opacityScalePosition: 50,
        ).windowLeftPercent,
      );

      // A target handoff preserves the one shared ticker/policy owner but must
      // replace the palette source immediately; no stale category A/B frame is
      // allowed to survive the semantic publication.
      final beforeTargetHandoff = policy.value;
      liveState.value = _budgetPresentationState(
        target: targetCatalog.targetAtHandle(2),
        title: 'Travel',
        actualScaled100: 2500,
        limitScaled100: 20000,
      );
      expect(policy.value, isNot(beforeTargetHandoff));
      expect(
        policy.value.colorB,
        isNot(CategoryColorCatalog.resolve('color_13').colorB),
      );

      liveState.value = _budgetPresentationState(
        target: targetCatalog.targetAtHandle(0),
        title: 'Budget',
        actualScaled100: 2500,
        limitScaled100: null,
      );
      expect(policy.value.colors, const <Color>[
        Color(0xff22d3ee),
        Color(0xff2bc4f3),
        Color(0xff39b8f4),
      ]);
    },
  );

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
            frame: BudgetHeaderColorScale.project(
              canonicalGradient: CategoryColorCatalog.resolve('color_13'),
              rawProgress: .5,
              windowWidthPercent: 28,
              opacityScalePosition: 50,
            ),
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

DashboardBudgetPresentationState _budgetPresentationState({
  required DashboardBudgetTarget target,
  required String title,
  required int actualScaled100,
  required int? limitScaled100,
}) {
  const period = FinancialLimitMonthPeriod(2026, 1);
  final key = FinancialLimitKey(
    direction: FinancialLimitDirection.expense,
    target: target.isAggregate
        ? const FinancialLimitAggregateTarget()
        : FinancialLimitCategoryTarget(target.category!.id),
    period: period,
  );
  final selection = DashboardBudgetLiveSelectionState.available(
    direction: LedgerDirection.expense,
    target: target,
    title: title,
    actualScaled100: actualScaled100,
    limitScaled100: limitScaled100,
    limitKey: key,
    coreRevision: 7,
    analysisScopeLabel: '2026. január',
  );
  return DashboardBudgetPresentationState(
    items: const <DashboardBudgetTargetPresentationItem>[],
    selectedHandle: target.handle,
    liveSelection: selection,
    partition: const DashboardBudgetPartitionPresentation.unavailable(
      direction: LedgerDirection.expense,
    ),
  );
}
