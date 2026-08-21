import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_target.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
