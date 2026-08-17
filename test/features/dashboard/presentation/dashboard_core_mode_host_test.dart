import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';

void main() {
  testWidgets('settled host mounts exactly the committed mode root', (
    tester,
  ) async {
    for (final mode in DashboardModeSpec.values) {
      final controller = DashboardCoreModeController(initialMode: mode);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_ModeHostHarness(controller: controller));

      expect(
        find.byKey(ValueKey('dashboard-core-mode-${mode.mode.name}')),
        findsOneWidget,
      );
      expect(_mountedModeRootCount(tester), 1);
      expect(
        find.byKey(ValueKey('dashboard-core-mode-label-${mode.mode.name}')),
        findsOneWidget,
      );

      if (mode == DashboardModeSpec.mind) {
        expect(
          find.byKey(const ValueKey('dashboard-core-mode-mind-body')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dashboard-core-mode-mind-card-1')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('dashboard-core-mode-mind-card-2')),
          findsNothing,
        );
      } else {
        expect(
          find.byKey(ValueKey('dashboard-core-mode-${mode.mode.name}-card-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('dashboard-core-mode-${mode.mode.name}-card-2')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dashboard-core-mode-mind-body')),
          findsNothing,
        );
      }
    }
  });

  test('Mind uses the central unified envelope endpoints', () {
    final split = _presentationFor(DashboardModeSpec.balance).geometry;
    final mind = _presentationFor(DashboardModeSpec.mind).geometry;

    expect(mind.unifiedSubheaderBounds!.top, split.subheaderOneBounds.top);
    expect(mind.unifiedSubheaderBounds!.bottom, split.zone2Bounds.bottom);
  });

  testWidgets('header and cards stay stationary before horizontal acceptance', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ModeHostHarness(controller: controller));

    final header = find.byKey(
      const ValueKey('dashboard-core-mode-balance-header'),
    );
    final card = find.byKey(
      const ValueKey('dashboard-core-mode-balance-card-1'),
    );
    final headerBefore = tester.getRect(header);
    final cardBefore = tester.getRect(card);

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
      ),
    );
    await gesture.moveBy(const Offset(-8, 0));
    await tester.pump();

    expect(controller.committedMode, DashboardModeSpec.balance);
    expect(tester.getRect(header), headerBefore);
    expect(tester.getRect(card), cardBefore);
    expect(_mountedModeRootCount(tester), 1);
    expect(
      find.byKey(const ValueKey('dashboard-core-mode-budget')),
      findsNothing,
    );
    await gesture.up();
  });

  testWidgets(
    'accepted left header intent immediately replaces Balance with Budget',
    (tester) async {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_ModeHostHarness(controller: controller));

      final gesture = await _startHeaderGesture(tester);
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();

      expect(controller.committedMode, DashboardModeSpec.budget);
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-balance')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-budget')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-mind')),
        findsNothing,
      );
      expect(_mountedModeRootCount(tester), 1);
      await gesture.up();
    },
  );

  testWidgets('one long header swipe changes exactly one logical mode', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ModeHostHarness(controller: controller));

    final gesture = await _startHeaderGesture(tester);
    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-600, 0));
    await tester.pump();

    expect(controller.committedMode, DashboardModeSpec.budget);
    expect(_mountedModeRootCount(tester), 1);
    await gesture.up();
  });

  testWidgets('pointer up resets the one-shot latch for the next swipe', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ModeHostHarness(controller: controller));

    await _dragHeader(tester, const Offset(-260, 0));
    expect(controller.committedMode, DashboardModeSpec.budget);
    await _dragHeader(tester, const Offset(-260, 0));
    expect(controller.committedMode, DashboardModeSpec.mind);
  });

  testWidgets('right header swipe immediately cycles Balance to Mind', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ModeHostHarness(controller: controller));

    await _dragHeader(tester, const Offset(260, 0));

    expect(controller.committedMode, DashboardModeSpec.mind);
    expect(
      find.byKey(const ValueKey('dashboard-core-mode-mind')),
      findsOneWidget,
    );
    expect(_mountedModeRootCount(tester), 1);
  });

  testWidgets('vertical header drag uses only expansion callbacks', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    final expansion = _ExpansionRecorder();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _ModeHostHarness(controller: controller, expansion: expansion),
    );

    await _dragHeader(tester, const Offset(0, -180));

    expect(expansion.starts, 1);
    expect(expansion.ends, 1);
    expect(expansion.totalDelta, lessThan(0));
    expect(controller.committedMode, DashboardModeSpec.balance);
    expect(_mountedModeRootCount(tester), 1);
  });

  testWidgets('ambiguous movement stays inert until vertical dominance wins', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    final expansion = _ExpansionRecorder();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _ModeHostHarness(controller: controller, expansion: expansion),
    );

    final gesture = await _startHeaderGesture(tester);
    await gesture.moveBy(const Offset(-36, -31));
    await tester.pump();
    expect(expansion.starts, 0);
    expect(controller.committedMode, DashboardModeSpec.balance);
    expect(_mountedModeRootCount(tester), 1);

    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();

    expect(expansion.starts, 1);
    expect(controller.committedMode, DashboardModeSpec.balance);
  });

  testWidgets('card and Mind-body drags never claim global mode navigation', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ModeHostHarness(controller: controller));

    await tester.drag(
      find.byKey(const ValueKey('dashboard-core-mode-balance-card-1')),
      const Offset(-260, 0),
    );
    await tester.pump();
    expect(controller.committedMode, DashboardModeSpec.balance);

    controller.setProgrammaticMode(DashboardModeSpec.mind);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('dashboard-core-mode-mind-body')),
      const Offset(-260, 0),
    );
    await tester.pump();
    expect(controller.committedMode, DashboardModeSpec.mind);
  });

  testWidgets('atomic replacement preserves the current expansion geometry', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _ModeHostHarness(controller: controller, collapseProgress: 90),
    );

    final balanceHeader = tester.getRect(
      find.byKey(const ValueKey('dashboard-core-mode-balance-header')),
    );
    await _dragHeader(tester, const Offset(-160, 0));
    final budgetHeader = tester.getRect(
      find.byKey(const ValueKey('dashboard-core-mode-budget-header')),
    );

    expect(budgetHeader.top, balanceHeader.top);
    expect(budgetHeader.height, balanceHeader.height);
    expect(_mountedModeRootCount(tester), 1);
  });
}

class _ModeHostHarness extends StatelessWidget {
  const _ModeHostHarness({
    required this.controller,
    this.expansion,
    this.collapseProgress = 0,
  });

  final DashboardCoreModeController controller;
  final _ExpansionRecorder? expansion;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final expansion = this.expansion ?? _ExpansionRecorder();
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: DashboardLayoutMetrics.reference.contentWidth + 34,
            child: DashboardCoreModeHost(
              controller: controller,
              presentationFor: (mode) =>
                  _presentationFor(mode, collapseProgress: collapseProgress),
              onVerticalExpansionStart: expansion.begin,
              onVerticalExpansionDragBy: expansion.dragBy,
              onVerticalExpansionEnd: expansion.end,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpansionRecorder {
  int starts = 0;
  int ends = 0;
  double totalDelta = 0;

  void begin() => starts += 1;
  void dragBy(double delta) => totalDelta += delta;
  void end() => ends += 1;
}

DashboardCoreModePresentation _presentationFor(
  DashboardModeSpec mode, {
  double collapseProgress = 0,
}) => DashboardCoreModePresentation(
  geometry: DashboardGeometryResolver.resolve(
    metrics: DashboardLayoutMetrics.reference,
    mode: mode,
    collapseProgress: collapseProgress,
    isRailExpanded: false,
  ),
  palette: DashboardModePaletteResolver.resolve(mode),
);

Future<TestGesture> _startHeaderGesture(WidgetTester tester) =>
    tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
      ),
    );

Future<void> _dragHeader(WidgetTester tester, Offset offset) async {
  await tester.drag(
    find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
    offset,
  );
  await tester.pump();
}

int _mountedModeRootCount(WidgetTester tester) => <Finder>[
  find.byKey(const ValueKey('dashboard-core-mode-balance')),
  find.byKey(const ValueKey('dashboard-core-mode-budget')),
  find.byKey(const ValueKey('dashboard-core-mode-mind')),
].fold(0, (count, finder) => count + finder.evaluate().length);
