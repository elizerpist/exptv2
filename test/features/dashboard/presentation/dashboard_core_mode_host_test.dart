import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_transition_motion.dart';

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
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-balance')),
        mode == DashboardModeSpec.balance ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-budget')),
        mode == DashboardModeSpec.budget ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-mind')),
        mode == DashboardModeSpec.mind ? findsOneWidget : findsNothing,
      );
      expect(_mountedModeRootCount(tester), 1);

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
      expect(
        find.byKey(ValueKey('dashboard-core-mode-label-${mode.mode.name}')),
        findsOneWidget,
      );
    }
  });

  test('Mind uses the central unified envelope endpoints', () {
    final split = _presentationFor(DashboardModeSpec.balance).geometry;
    final mind = _presentationFor(DashboardModeSpec.mind).geometry;

    expect(mind.unifiedSubheaderBounds!.top, split.subheaderOneBounds.top);
    expect(mind.unifiedSubheaderBounds!.bottom, split.zone2Bounds.bottom);
  });

  testWidgets('header left and right drags cycle the three-mode ring', (
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
    await _dragHeader(tester, const Offset(-260, 0));
    expect(controller.committedMode, DashboardModeSpec.balance);

    await _dragHeader(tester, const Offset(260, 0));
    expect(controller.committedMode, DashboardModeSpec.mind);
    await _dragHeader(tester, const Offset(260, 0));
    expect(controller.committedMode, DashboardModeSpec.budget);
    await _dragHeader(tester, const Offset(260, 0));
    expect(controller.committedMode, DashboardModeSpec.balance);
  });

  testWidgets('a horizontal header drag mounts only source and one target', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ModeHostHarness(controller: controller));

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
      ),
    );
    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump();

    expect(controller.transition.targetMode, DashboardModeSpec.budget);
    expect(_mountedModeRootCount(tester), 2);
    expect(
      find.byKey(const ValueKey('dashboard-core-mode-balance')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-core-mode-budget')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-core-mode-mind')),
      findsNothing,
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_mountedModeRootCount(tester), 1);
    expect(
      find.byKey(const ValueKey('dashboard-core-mode-budget')),
      findsOneWidget,
    );
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
    expect(controller.transition.phase, DashboardCoreModeTransitionPhase.idle);
  });

  testWidgets(
    'axis stays undecided for ambiguous movement and never switches after commitment',
    (tester) async {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      final expansion = _ExpansionRecorder();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _ModeHostHarness(controller: controller, expansion: expansion),
      );

      final header = find.byKey(
        const ValueKey('dashboard-core-mode-header-gesture-region'),
      );
      final ambiguous = await tester.startGesture(tester.getCenter(header));
      await ambiguous.moveBy(const Offset(-36, -31));
      await tester.pump();
      expect(expansion.starts, 0);
      expect(
        controller.transition.phase,
        DashboardCoreModeTransitionPhase.idle,
      );
      await ambiguous.up();

      final horizontal = await tester.startGesture(tester.getCenter(header));
      await horizontal.moveBy(const Offset(-160, -30));
      await tester.pump();
      await horizontal.moveBy(const Offset(130, 150));
      await tester.pump();
      await horizontal.up();
      await tester.pumpAndSettle();

      expect(expansion.starts, 0);
      expect(
        controller.committedMode,
        DashboardModeSpec.balance,
        reason:
            'A horizontal winner may reduce/cancel its fixed target when the '
            'finger reverses, but it must never reinterpret the same pointer as '
            'the opposite neighbour.',
      );
    },
  );

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
    await tester.pumpAndSettle();
    expect(controller.committedMode, DashboardModeSpec.balance);

    controller.setProgrammaticMode(DashboardModeSpec.mind);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('dashboard-core-mode-mind-body')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();
    expect(controller.committedMode, DashboardModeSpec.mind);
  });

  testWidgets('mode target keeps the same central expansion progress', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _ModeHostHarness(controller: controller, collapseProgress: 90),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
      ),
    );
    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump();

    final sourceHeader = tester.getRect(
      find.byKey(const ValueKey('dashboard-core-mode-balance-header')),
    );
    final targetHeader = tester.getRect(
      find.byKey(const ValueKey('dashboard-core-mode-budget-header')),
    );
    expect(targetHeader.top, sourceHeader.top);
    expect(targetHeader.height, sourceHeader.height);
  });
}

class _ModeHostHarness extends StatefulWidget {
  const _ModeHostHarness({
    required this.controller,
    this.expansion,
    this.collapseProgress = 0,
  });

  final DashboardCoreModeController controller;
  final _ExpansionRecorder? expansion;
  final double collapseProgress;

  @override
  State<_ModeHostHarness> createState() => _ModeHostHarnessState();
}

class _ModeHostHarnessState extends State<_ModeHostHarness>
    with SingleTickerProviderStateMixin {
  late final DashboardCoreModeTransitionMotion _motion;

  @override
  void initState() {
    super.initState();
    _motion = DashboardCoreModeTransitionMotion(vsync: this);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expansion = widget.expansion ?? _ExpansionRecorder();
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: DashboardLayoutMetrics.reference.contentWidth + 34,
            child: DashboardCoreModeHost(
              controller: widget.controller,
              motion: _motion,
              presentationFor: (mode) => _presentationFor(
                mode,
                collapseProgress: widget.collapseProgress,
              ),
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

Future<void> _dragHeader(WidgetTester tester, Offset offset) async {
  await tester.drag(
    find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
    offset,
  );
  await tester.pumpAndSettle();
}

int _mountedModeRootCount(WidgetTester tester) => <Finder>[
  find.byKey(const ValueKey('dashboard-core-mode-balance')),
  find.byKey(const ValueKey('dashboard-core-mode-budget')),
  find.byKey(const ValueKey('dashboard-core-mode-mind')),
].fold(0, (count, finder) => count + finder.evaluate().length);
