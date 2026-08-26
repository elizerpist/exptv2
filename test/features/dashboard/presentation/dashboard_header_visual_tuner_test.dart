import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/features/dashboard/presentation/budget_content_card_style.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_corner_roundness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Budget Card2 surface switch is session-owned and live', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final cardStyle = BudgetContentCardStyleController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            budgetContentCardStyle: cardStyle,
          ),
        ),
      ),
    );

    final control = find.byKey(
      const ValueKey<String>('dashboard-budget-content-card-surface-switch'),
    );
    await tester.ensureVisible(control);
    expect(control, findsOneWidget);
    expect(cardStyle.showCardSurface, isTrue);

    tester.widget<SwitchListTile>(control).onChanged!(false);
    await tester.pump();
    expect(cardStyle.showCardSurface, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    cardStyle.dispose();
  });

  testWidgets('global corner scale is session-owned and live', (tester) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final roundness = DashboardCornerRoundnessController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            cornerRoundness: roundness,
          ),
        ),
      ),
    );

    final control = find.byKey(
      const ValueKey<String>('dashboard-corner-roundness-slider'),
    );
    await tester.ensureVisible(control);
    expect(roundness.value.position, 0);
    tester
        .widget<Slider>(
          find.descendant(of: control, matching: find.byType(Slider)),
        )
        .onChanged!(1);
    await tester.pump();
    expect(roundness.value.position, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    roundness.dispose();
  });

  test('tuner placement always reserves the live Header plus its gap', () {
    const gap = 12.0;
    for (final headerBottom in <double>[124, 214, 346]) {
      final placement = DashboardHeaderVisualTunerPlacement.resolve(
        headerBottom: headerBottom,
        viewportHeight: 760,
        safeBottom: 24,
        gap: gap,
      );
      expect(placement.top, greaterThanOrEqualTo(headerBottom + gap));
      expect(placement.maxHeight, greaterThanOrEqualTo(0));
    }
  });

  testWidgets('controls apply Header visual settings synchronously', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-cool-position-slider'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-cool-window-width-slider'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dashboard-header-opacity-slider')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dashboard-header-effect-selector')),
      findsOneWidget,
    );
    expect(find.text('Kategória színskálák'), findsNothing);
    expect(controller.tuning.value.budgetCool.positionPercent, 50);
    expect(controller.tuning.value.budgetCool.windowWidthPercent, 28);

    final positionSlider = tester.widget<Slider>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('dashboard-header-cool-position-slider'),
        ),
        matching: find.byType(Slider),
      ),
    );
    positionSlider.onChanged!(80);
    await tester.pump();
    expect(controller.tuning.value.budgetCool.positionPercent, 80);
    expect(controller.tuning.value.budgetCool.windowWidthPercent, 28);

    final widthSlider = tester.widget<Slider>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('dashboard-header-cool-window-width-slider'),
        ),
        matching: find.byType(Slider),
      ),
    );
    widthSlider.onChanged!(100);
    await tester.pump();
    expect(controller.tuning.value.budgetCool.positionPercent, 80);
    expect(controller.tuning.value.budgetCool.windowWidthPercent, 100);
    expect(
      tester
          .widget<Slider>(
            find.descendant(
              of: find.byKey(
                const ValueKey<String>('dashboard-header-cool-position-slider'),
              ),
              matching: find.byType(Slider),
            ),
          )
          .onChanged,
      isNotNull,
      reason: 'Position stays directly controllable at a 100% window.',
    );

    final pulseTrigger = find.byKey(
      const ValueKey<String>('dashboard-header-pulse-trigger'),
    );
    await tester.ensureVisible(pulseTrigger);
    await tester.pump();
    await tester.tap(pulseTrigger);
    await tester.pump();
    expect(controller.pulseAmount, 1);
    controller.dispose();
  });
  testWidgets('Portal channel controls remain separate and reset live', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    controller.selectPortalEffect(
      DashboardHeaderPortalChannel.innerMotion,
      DashboardHeaderPortalMaterialEffectId.staticMatter,
    );
    controller.selectPortalEffect(
      DashboardHeaderPortalChannel.backgroundMorph,
      DashboardHeaderPortalMaterialEffectId.formingClouds,
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

    final innerTitle = find.text('PORTÁL BELSŐ MOZGÁS');
    await tester.ensureVisible(innerTitle);
    await tester.pump();
    expect(innerTitle, findsOneWidget);
    final innerEnabled = find.byKey(
      const ValueKey<String>('dashboard-header-portal-inner-enabled'),
    );
    await tester.ensureVisible(innerEnabled);
    await tester.tap(innerEnabled);
    await tester.pump();
    expect(controller.portalInnerMotion.enabled, isFalse);
    expect(controller.portalBackgroundMorph.enabled, isTrue);
    expect(
      controller.portalBackgroundMorph.effect,
      DashboardHeaderPortalMaterialEffectId.formingClouds,
    );
    await tester.tap(innerEnabled);
    await tester.pump();
    expect(controller.portalInnerMotion.enabled, isTrue);
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-portal-inner-selector'),
      ),
      findsOneWidget,
    );
    final backgroundSelector = find.byKey(
      const ValueKey<String>('dashboard-header-portal-background-selector'),
    );
    await tester.ensureVisible(backgroundSelector);
    await tester.pump();
    expect(backgroundSelector, findsOneWidget);

    final coverageControl = find.byKey(
      const ValueKey<String>('dashboard-header-portal-inner-control-coverage'),
    );
    await tester.ensureVisible(coverageControl);
    await tester.pump();
    final coverageSlider = tester.widget<Slider>(
      find.descendant(of: coverageControl, matching: find.byType(Slider)),
    );
    coverageSlider.onChanged!(70);
    await tester.pump();
    expect(
      controller.portalInnerMotion.settingsFor(
        DashboardHeaderPortalMaterialEffectId.staticMatter,
      )['coverage'],
      70,
    );
    expect(
      controller.portalBackgroundMorph.settingsFor(
        DashboardHeaderPortalMaterialEffectId.formingClouds,
      )['density'],
      4,
    );

    final innerReset = find.byKey(
      const ValueKey<String>('dashboard-header-portal-inner-reset'),
    );
    await tester.ensureVisible(innerReset);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(innerReset);
    await tester.pump();
    expect(
      controller.portalInnerMotion.settingsFor(
        DashboardHeaderPortalMaterialEffectId.staticMatter,
      )['coverage'],
      34,
    );
    expect(
      controller.portalBackgroundMorph.effect,
      DashboardHeaderPortalMaterialEffectId.formingClouds,
    );
    controller.dispose();
  });

  testWidgets(
    'tap-wave controls update the shared visual state without closing the tuner',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 520,
            child: DashboardHeaderVisualTuner(controller: controller),
          ),
        ),
      );
      final control = find.byKey(
        const ValueKey<String>(
          'dashboard-header-tap-wave-control-interactionOpacity',
        ),
      );
      await tester.ensureVisible(control);
      await tester.pump();
      final slider = tester.widget<Slider>(
        find.descendant(of: control, matching: find.byType(Slider)),
      );
      slider.onChanged!(64);
      await tester.pump();
      expect(controller.tapWaveTuning.value.valueFor('interactionOpacity'), 64);
      expect(
        find.byKey(
          const ValueKey<String>('dashboard-header-visual-tuner-list'),
        ),
        findsOneWidget,
      );
      controller.dispose();
    },
  );

  testWidgets('Deep Drift is selectable once and tunes the live shader input', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    controller.selectEffect(DashboardHeaderEffectId.deepDrift);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );

    final selector = tester.widget<DropdownButton<DashboardHeaderEffectId>>(
      find.byKey(const ValueKey<String>('dashboard-header-effect-selector')),
    );
    expect(selector.value, DashboardHeaderEffectId.deepDrift);
    expect(find.text('Mélységi áramlás'), findsOneWidget);

    final materialSize = find.byKey(
      const ValueKey<String>('dashboard-header-effect-control-blobScale'),
    );
    await tester.ensureVisible(materialSize);
    await tester.pump();
    final slider = tester.widget<Slider>(
      find.descendant(of: materialSize, matching: find.byType(Slider)),
    );
    slider.onChanged!(1.24);
    await tester.pump();
    expect(
      controller.tuning.value.settingsFor(
        DashboardHeaderEffectId.deepDrift,
      )['blobScale'],
      1.24,
    );
    expect(
      find.byKey(const ValueKey<String>('dashboard-header-visual-tuner-list')),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('family selector exposes one active classic, full-flow, or '
      'space-fabric list', (tester) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-animation-family-selector'),
      ),
      findsOneWidget,
    );
    expect(find.text('Referencia mozgás · 69d109'), findsOneWidget);
    expect(find.text('Szabad áramlás'), findsNothing);

    controller.selectAnimationFamily(
      DashboardHeaderAnimationFamily.fullFieldFlow,
    );
    await tester.pump();
    expect(controller.tuning.value.effect, DashboardHeaderEffectId.freeFlow);
    expect(find.text('Áramlás típusa'), findsNWidgets(2));
    expect(find.text('Referencia mozgás · 69d109'), findsNothing);
    final selector = tester.widget<DropdownButton<DashboardHeaderEffectId>>(
      find.byKey(const ValueKey<String>('dashboard-header-effect-selector')),
    );
    expect(selector.items!.map((item) => item.value), <DashboardHeaderEffectId>[
      DashboardHeaderEffectId.freeFlow,
      DashboardHeaderEffectId.chaoticAdvection,
      DashboardHeaderEffectId.elasticSpace,
      DashboardHeaderEffectId.braidedCurrent,
      DashboardHeaderEffectId.volumetricCurrent,
    ]);

    controller.selectAnimationFamily(
      DashboardHeaderAnimationFamily.spaceFabricWarp,
    );
    await tester.pump();
    expect(controller.tuning.value.effect, DashboardHeaderEffectId.metricBloom);
    expect(find.text('Térszövet típusa'), findsNWidgets(2));
    final spaceSelector = tester
        .widget<DropdownButton<DashboardHeaderEffectId>>(
          find.byKey(
            const ValueKey<String>('dashboard-header-effect-selector'),
          ),
        );
    expect(
      spaceSelector.items!.map((item) => item.value),
      <DashboardHeaderEffectId>[
        DashboardHeaderEffectId.metricBloom,
        DashboardHeaderEffectId.gravitationalFabric,
        DashboardHeaderEffectId.breathingMetric,
        DashboardHeaderEffectId.tidalCurvature,
      ],
    );
    controller.dispose();
  });
}
