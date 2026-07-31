import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/motion/dashboard_motion_host.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/transaction_direction_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 48);
const _togglePalette = DashboardModePalette(
  incomeGradient: LinearGradient(
    colors: [Color(0xFF001122), Color(0xFF334455)],
  ),
  expenseGradient: LinearGradient(
    colors: [Color(0xFF667788), Color(0xFF99AABB)],
  ),
  upcomingHeaderTone: Color(0xFFCCDDEE),
);

const _countedBalancePalette = DashboardModePalette(
  incomeGradient: LinearGradient(
    colors: [Color(0xFF102030), Color(0xFF405060)],
  ),
  expenseGradient: LinearGradient(
    colors: [Color(0xFF708090), Color(0xFFA0B0C0)],
  ),
  upcomingHeaderTone: Color(0xFFD0E0F0),
);

const _countedBudgetPalette = DashboardModePalette(
  incomeGradient: LinearGradient(
    colors: [Color(0xFF201030), Color(0xFF604050)],
  ),
  expenseGradient: LinearGradient(
    colors: [Color(0xFF907080), Color(0xFFC0A0B0)],
  ),
  upcomingHeaderTone: Color(0xFFF0D0E0),
);

void main() {
  testWidgets('motion host supplies the selected mode palette in its frame', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    DashboardVisualFrame? frame;

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardMotionHost(
          controller: controller,
          mode: DashboardModeSpec.budget,
          builder: (_, value) {
            frame = value;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(
      frame!.palette,
      DashboardModePaletteResolver.resolve(DashboardModeSpec.budget),
    );
    expect(
      frame!.palette.upcomingHeaderTone,
      isNot(
        DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ).upcomingHeaderTone,
      ),
    );
  });

  testWidgets(
    'motion host caches palette resolution through ticker frames and refreshes on mode change',
    (tester) async {
      final controller = DashboardCoreController();
      DashboardVisualFrame? frame;
      var resolutionCount = 0;

      DashboardModePalette countAndResolve(DashboardModeSpec mode) {
        resolutionCount += 1;
        return mode.mode == DashboardMode.budget
            ? _countedBudgetPalette
            : _countedBalancePalette;
      }

      await _pumpHost(
        tester,
        controller,
        (value) => frame = value,
        paletteResolver: countAndResolve,
      );
      expect(resolutionCount, 1);
      expect(frame!.palette, _countedBalancePalette);

      controller.transactionDirection.select(TransactionDirection.expense);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 126));
      await tester.pump(const Duration(milliseconds: 168));
      expect(resolutionCount, 1);

      await _pumpHost(
        tester,
        controller,
        (value) => frame = value,
        mode: DashboardModeSpec.budget,
        paletteResolver: countAndResolve,
      );
      expect(resolutionCount, 2);
      expect(frame!.palette, _countedBudgetPalette);

      await tester.pump(const Duration(milliseconds: 126));
      expect(resolutionCount, 2);

      var replacementResolverCount = 0;
      DashboardModePalette replacementResolver(DashboardModeSpec mode) {
        replacementResolverCount += 1;
        return _togglePalette;
      }

      await _pumpHost(
        tester,
        controller,
        (value) => frame = value,
        mode: DashboardModeSpec.budget,
        paletteResolver: replacementResolver,
      );
      expect(replacementResolverCount, 1);
      expect(frame!.palette, _togglePalette);

      await tester.pump(const Duration(milliseconds: 126));
      expect(replacementResolverCount, 1);
    },
  );

  testWidgets(
    'motion host refreshes its cached palette for a new spec with the same mode enum',
    (tester) async {
      final controller = DashboardCoreController();
      final sameModeReplacement = DashboardModeSpec(
        mode: DashboardMode.balance,
        subheaderComposition: DashboardSubheaderComposition.split,
      );
      DashboardVisualFrame? frame;
      var resolutionCount = 0;

      DashboardModePalette resolveBySpec(DashboardModeSpec mode) {
        resolutionCount += 1;
        return identical(mode, sameModeReplacement)
            ? _togglePalette
            : _countedBalancePalette;
      }

      await _pumpHost(
        tester,
        controller,
        (value) => frame = value,
        paletteResolver: resolveBySpec,
      );
      expect(resolutionCount, 1);
      expect(frame!.palette, _countedBalancePalette);

      await _pumpHost(
        tester,
        controller,
        (value) => frame = value,
        mode: sameModeReplacement,
        paletteResolver: resolveBySpec,
      );

      expect(resolutionCount, 2);
      expect(frame!.palette, _togglePalette);
    },
  );

  testWidgets(
    'direction toggle renders the supplied palette without resolving a mode',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDirectionToggle(
              bounds: _bounds,
              palette: _togglePalette,
              selectedDirection: TransactionDirection.expense,
              incomeIconScale: 1,
              expenseIconScale: 1,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      final selectedDecoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('Kiadás'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(selectedDecoration.gradient, _togglePalette.expenseGradient);
    },
  );

  testWidgets('motion host runs the exact selected-direction pulse policy', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    DashboardVisualFrame? frame;

    await _pumpHost(tester, controller, (value) => frame = value);

    controller.transactionDirection.select(TransactionDirection.expense);
    await tester.pump();
    expect(frame!.expenseIconScale, closeTo(.90, .001));

    await tester.pump(const Duration(milliseconds: 126));
    expect(frame!.expenseIconScale, closeTo(1.12, .001));

    await tester.pump(const Duration(milliseconds: 168));
    expect(frame!.expenseIconScale, closeTo(.98, .001));

    await tester.pump(const Duration(milliseconds: 126));
    expect(frame!.expenseIconScale, closeTo(1, .001));
  });

  testWidgets('motion host reveals the rail after the 180ms policy', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    DashboardVisualFrame? frame;

    await _pumpHost(tester, controller, (value) => frame = value);

    controller.rail.setExpanded(true);
    await tester.pump();
    expect(frame!.railReveal, 0);

    await tester.pump(const Duration(milliseconds: 180));
    expect(frame!.railReveal, 1);
  });

  testWidgets('motion host moves geometry to the collapsed anchor', (
    tester,
  ) async {
    final controller = DashboardCoreController();
    DashboardVisualFrame? frame;

    await _pumpHost(tester, controller, (value) => frame = value);

    controller.expansion.toggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(frame!.geometry.collapseProgress, controller.metrics.collapseTravel);
    expect(frame!.geometry.collapseHandleBounds.top, 392);
  });

  testWidgets(
    'motion host applies static final values when animations are disabled',
    (tester) async {
      final controller = DashboardCoreController();
      DashboardVisualFrame? frame;

      await _pumpHost(
        tester,
        controller,
        (value) => frame = value,
        disableAnimations: true,
      );

      controller
        ..expansion.toggle()
        ..rail.setExpanded(true)
        ..transactionDirection.select(TransactionDirection.expense);
      await tester.pump();

      expect(
        frame!.geometry.collapseProgress,
        controller.metrics.collapseTravel,
      );
      expect(frame!.railReveal, 1);
      expect(frame!.expenseIconScale, 1);
    },
  );

  testWidgets(
    'motion host detaches a replaced controller before listening to the next',
    (tester) async {
      final firstController = DashboardCoreController();
      final secondController = DashboardCoreController();
      DashboardVisualFrame? frame;

      await _pumpHost(tester, firstController, (value) => frame = value);
      await _pumpHost(tester, secondController, (value) => frame = value);

      firstController.transactionDirection.select(TransactionDirection.expense);
      await tester.pump();
      expect(frame!.incomeIconScale, 1);
      expect(frame!.expenseIconScale, 1);

      secondController.transactionDirection.select(
        TransactionDirection.expense,
      );
      await tester.pump();
      expect(frame!.expenseIconScale, closeTo(.90, .001));
    },
  );

  testWidgets(
    'controller replacement atomically adopts static state during active motion and continues listening',
    (tester) async {
      final firstController = DashboardCoreController();
      final replacementController = DashboardCoreController();
      DashboardVisualFrame? frame;

      await _pumpHost(tester, firstController, (value) => frame = value);

      firstController
        ..expansion.toggle()
        ..rail.setExpanded(true)
        ..transactionDirection.select(TransactionDirection.expense);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(
        frame!.geometry.collapseProgress,
        isNot(replacementController.expansion.progress),
      );
      expect(frame!.railReveal, isNot(0));
      expect(frame!.expenseIconScale, isNot(1));

      replacementController
        ..expansion.setProgress(42)
        ..transactionDirection.select(TransactionDirection.expense);
      await _pumpHost(
        tester,
        replacementController,
        (value) => frame = value,
      );

      expect(frame!.geometry.collapseProgress, 42);
      expect(frame!.railReveal, 0);
      expect(frame!.incomeIconScale, 1);
      expect(frame!.expenseIconScale, 1);

      await tester.pump(const Duration(milliseconds: 420));
      expect(frame!.geometry.collapseProgress, 42);
      expect(frame!.railReveal, 0);
      expect(frame!.expenseIconScale, 1);

      firstController
        ..expansion.setProgress(0)
        ..rail.setExpanded(false)
        ..transactionDirection.select(TransactionDirection.income);
      await tester.pump(const Duration(milliseconds: 180));
      expect(frame!.geometry.collapseProgress, 42);
      expect(frame!.railReveal, 0);
      expect(frame!.expenseIconScale, 1);

      replacementController
        ..expansion.setProgress(0)
        ..rail.setExpanded(true)
        ..transactionDirection.select(TransactionDirection.income);
      await tester.pump();
      expect(frame!.incomeIconScale, closeTo(.90, .001));
      await tester.pump(const Duration(milliseconds: 180));
      expect(frame!.geometry.collapseProgress, 0);
      expect(frame!.railReveal, 1);
    },
  );
}

Future<void> _pumpHost(
  WidgetTester tester,
  DashboardCoreController controller,
  ValueChanged<DashboardVisualFrame> onFrame, {
  bool disableAnimations = false,
  DashboardModeSpec mode = DashboardModeSpec.balance,
  DashboardModePaletteLookup? paletteResolver,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: DashboardMotionHost(
          key: const ValueKey('dashboard-motion-host'),
          controller: controller,
          mode: mode,
          paletteResolver: paletteResolver,
          builder: (_, frame) {
            onFrame(frame);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
}
