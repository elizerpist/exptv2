import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_host.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_placeholder_card.dart';

import '../../../support/dashboard_render_resources.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets(
    'BALANCE-HEADER-ROUTE/BUTTON RED: production Header relay inspects Balance points and the tuner sits in the brand lane',
    (tester) async {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      final headerVisual = DashboardHeaderVisualController(vsync: tester);
      final balanceHeaderFrame = DashboardBalanceHeaderColorPolicy(
        tuning: headerVisual.tuning,
      );
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        DashboardBalancePresentation(
          scopeKey: 'all',
          coreRevision: 1,
          incomeTotalMinor: 1000,
          expenseTotalMinor: 100,
          netTotalMinor: 900,
          formattedNetTotal: '9 Ft',
          presentationId: 1,
          history: DashboardBalanceHistorySeries(
            startInclusiveEpochMinute: 20000 * 1440,
            endInclusiveEpochMinute: 20100 * 1440,
            points: const <DashboardBalanceHistoryPoint>[
              DashboardBalanceHistoryPoint(
                entryId: 'first',
                epochDay: 20000,
                epochMinute: 20000 * 1440,
                incomeTotalMinor: 1000,
                expenseTotalMinor: 0,
                balanceMinor: 1000,
              ),
              DashboardBalanceHistoryPoint(
                entryId: 'last',
                epochDay: 20100,
                epochMinute: 20100 * 1440,
                incomeTotalMinor: 1000,
                expenseTotalMinor: 100,
                balanceMinor: 900,
              ),
            ],
          ),
        ),
      );
      final settings = BalancePresentationController();
      final expansion = _ExpansionRecorder();
      addTearDown(controller.dispose);
      addTearDown(balanceHeaderFrame.dispose);
      addTearDown(balance.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: DashboardLayoutMetrics.reference.canvasWidth,
            height: DashboardLayoutMetrics.reference.canvasHeight,
            child: DashboardCoreModeHost(
              controller: controller,
              presentationFor: (mode) => _presentationFor(mode),
              balancePresentation: balance,
              balancePresentationSettings: settings,
              balanceHeaderVisualFrame: balanceHeaderFrame,
              headerVisualController: headerVisual,
              onVerticalExpansionStart: expansion.begin,
              onVerticalExpansionDragBy: expansion.dragBy,
              onVerticalExpansionEnd: expansion.end,
            ),
          ),
        ),
      );
      await tester.pump();

      final button = tester.getRect(
        find.byKey(
          const ValueKey<String>('dashboard-header-visual-tuner-button'),
        ),
      );
      final header = tester.getRect(
        find.byKey(
          const ValueKey<String>('dashboard-core-mode-balance-header'),
        ),
      );
      final modeIcon = tester.getRect(
        find.byKey(
          const ValueKey<String>('dashboard-header-mode-icon-balance'),
        ),
      );
      expect(button.bottom, lessThanOrEqualTo(header.top));
      expect(button.right, closeTo(header.right - 8, .01));
      expect(
        modeIcon.right,
        closeTo(header.right - 14, .01),
        reason: 'The mode action remains in the Header right corner.',
      );
      final balanceModeLabel = find.byKey(
        const ValueKey<String>('dashboard-core-mode-label-balance'),
      );
      expect(balanceModeLabel, findsNothing);
      final balanceModeIcon = find.byKey(
        const ValueKey<String>('dashboard-header-mode-icon-balance'),
      );
      expect(balanceModeIcon, findsOneWidget);
      headerVisual.setBalanceHeaderIconColor(
        DashboardHeaderForegroundColor.black,
      );
      await tester.pump();
      expect(
        tester
            .widget<PreparedVectorPictureView>(
              find.descendant(
                of: balanceModeIcon,
                matching: find.byType(PreparedVectorPictureView),
              ),
            )
            .color,
        Colors.black,
        reason: 'The Header action consumes the mode-local icon channel.',
      );
      headerVisual.setHeaderTypography(
        DashboardHeaderTypographyProfile.colorLab,
      );
      await tester.pump();
      expect(balanceModeIcon, findsOneWidget);
      headerVisual.setHeaderTypography(DashboardHeaderTypographyProfile.app);
      await tester.pump();
      expect(balanceModeIcon, findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey<String>('dashboard-header-visual-tuner-button'),
        ),
      );
      await tester.pump();
      expect(headerVisual.tunerOpen.value, isTrue);

      final plot = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-header-history-chart-paint'),
        ),
      );
      await tester.tapAt(Offset(plot.left + 3, plot.center.dy));
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-header-history-chart-selected-amount',
          ),
        ),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(
          const ValueKey<String>('dashboard-core-mode-header-gesture-region'),
        ),
        const Offset(0, -100),
      );
      await tester.pump();
      expect(expansion.starts, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      headerVisual.dispose();
    },
  );

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
        find.byKey(ValueKey('dashboard-header-mode-icon-${mode.mode.name}')),
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

  testWidgets(
    'HEADER-MODE-ACTION-RED: local white mode icons replace labels and are the only Header mode switch affordance',
    (tester) async {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_ModeHostHarness(controller: controller));

      expect(
        find.byKey(const ValueKey<String>('dashboard-core-mode-label-balance')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('dashboard-header-mode-icon-balance'),
        ),
        findsOneWidget,
      );
      expect(
        DashboardHeaderModeIconButton.assetFor(DashboardMode.balance),
        'assets/fluvi/header_mode_icons/balance-scale.svg',
      );
      final balanceAsset = tester.widget<PreparedVectorPictureView>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('dashboard-header-mode-icon-balance'),
          ),
          matching: find.byType(PreparedVectorPictureView),
        ),
      );
      expect(balanceAsset.color, Colors.white);
      final headerGesture = find.byKey(
        const ValueKey<String>('dashboard-core-mode-header-gesture-region'),
      );
      await tester.drag(headerGesture, const Offset(-260, 0));
      await tester.pump();
      expect(
        controller.committedMode,
        DashboardModeSpec.balance,
        reason: 'Horizontal Header swipes no longer own mode selection.',
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('dashboard-header-mode-icon-balance'),
        ),
      );
      await tester.pump();
      expect(controller.committedMode, DashboardModeSpec.budget);
      expect(
        find.byKey(const ValueKey<String>('dashboard-header-mode-icon-budget')),
        findsOneWidget,
      );
      expect(
        DashboardHeaderModeIconButton.assetFor(DashboardMode.budget),
        'assets/fluvi/header_mode_icons/budget-sliders-vertical.svg',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('dashboard-header-mode-icon-budget')),
      );
      await tester.pump();
      expect(controller.committedMode, DashboardModeSpec.mind);
      expect(
        find.byKey(const ValueKey<String>('dashboard-header-mode-icon-mind')),
        findsOneWidget,
      );
      expect(
        DashboardHeaderModeIconButton.assetFor(DashboardMode.mind),
        'assets/fluvi/header_mode_icons/mind-brain.svg',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('dashboard-header-mode-icon-mind')),
      );
      await tester.pump();
      expect(controller.committedMode, DashboardModeSpec.balance);
    },
  );

  testWidgets(
    'HEADER-MODE-ICON-SIZE/WAVE RED: the icon scales from its base without owning Header tap waves',
    (tester) async {
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      final visual = DashboardHeaderVisualController(vsync: tester);
      final balanceFrame = DashboardBalanceHeaderColorPolicy(
        tuning: visual.tuning,
      );
      addTearDown(mode.dispose);
      addTearDown(balanceFrame.dispose);
      await tester.pumpWidget(
        _ModeHostHarness(
          controller: mode,
          headerVisual: visual,
          balanceHeaderVisualFrame: balanceFrame,
        ),
      );

      final icon = find.byKey(
        const ValueKey<String>('dashboard-header-mode-icon-balance'),
      );
      final semantics = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('Balance mód, következő mód'),
        findsOneWidget,
      );
      expect(
        tester.widget(icon),
        isNot(isA<InkResponse>()),
        reason: 'A mode action must not own a second local ink splash.',
      );
      final initial = tester.getRect(icon);
      expect(initial.width, DashboardHeaderModeIconButton.buttonExtentFor(0));
      visual.setHeaderModeIconSizePercent(100);
      await tester.pump();
      final enlarged = tester.getRect(icon);
      expect(
        enlarged.width,
        DashboardHeaderModeIconButton.buttonExtentFor(100),
      );
      expect(
        tester
            .widget<PreparedVectorPictureView>(
              find.descendant(
                of: icon,
                matching: find.byType(PreparedVectorPictureView),
              ),
            )
            .width,
        DashboardHeaderModeIconButton.glyphExtentFor(100),
      );

      await tester.tapAt(Offset(enlarged.right - 2, enlarged.center.dy));
      await tester.pump();
      expect(mode.committedMode, DashboardModeSpec.budget);
      expect(
        visual.tapWave.rippleCount,
        0,
        reason: 'The mode action must not seed the Header splash.',
      );
      await tester.tap(
        find.byKey(const ValueKey('dashboard-core-mode-header-gesture-region')),
      );
      await tester.pump();
      expect(visual.tapWave.rippleCount, 1);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      visual.dispose();
    },
  );

  test('Mind uses the central unified envelope endpoints', () {
    final split = _presentationFor(DashboardModeSpec.balance).geometry;
    final mind = _presentationFor(DashboardModeSpec.mind).geometry;

    expect(mind.unifiedSubheaderBounds!.top, split.subheaderOneBounds.top);
    expect(mind.unifiedSubheaderBounds!.bottom, split.zone2Bounds.bottom);
  });

  testWidgets(
    'Budget replaces only card1 content with a rail in the existing card1 envelope',
    (tester) async {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.budget,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_ModeHostHarness(controller: controller));

      final cardOne = find.byKey(
        const ValueKey('dashboard-core-mode-budget-card-1'),
      );
      final rail = find.byKey(
        const ValueKey<String>('budget-target-avatar-rail'),
      );

      expect(rail, findsOneWidget);
      expect(
        find.ancestor(
          of: cardOne,
          matching: find.byType(DashboardPlaceholderCard),
        ),
        findsNothing,
      );
      expect(tester.getRect(rail).center, tester.getRect(cardOne).center);
      expect(tester.getRect(rail).height, 112);
      expect(
        tester.getRect(cardOne).height,
        DashboardLayoutMetrics.reference.subheaderOneHeight,
      );
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey('dashboard-core-mode-budget-card-2')),
            )
            .top,
        DashboardLayoutMetrics.reference.zone2Top,
      );
    },
  );

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

    expect(controller.committedMode.mode, DashboardMode.balance);
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
    'long left header swipe remains inert after mode navigation moved to the icon',
    (tester) async {
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(_ModeHostHarness(controller: controller));

      final gesture = await _startHeaderGesture(tester);
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();

      expect(controller.committedMode, DashboardModeSpec.balance);
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-balance')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-core-mode-budget')),
        findsNothing,
      );
      expect(_mountedModeRootCount(tester), 1);
      await gesture.up();
    },
  );

  testWidgets(
    'repeated horizontal header movement never changes a logical mode',
    (tester) async {
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

      expect(controller.committedMode, DashboardModeSpec.balance);
      expect(_mountedModeRootCount(tester), 1);
      await gesture.up();
    },
  );

  testWidgets('pointer up leaves the inert Header horizontal contract intact', (
    tester,
  ) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ModeHostHarness(controller: controller));

    await _dragHeader(tester, const Offset(-260, 0));
    expect(controller.committedMode, DashboardModeSpec.balance);
    await _dragHeader(tester, const Offset(-260, 0));
    expect(controller.committedMode, DashboardModeSpec.balance);
  });

  testWidgets('right header swipe remains inert', (tester) async {
    final controller = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ModeHostHarness(controller: controller));

    await _dragHeader(tester, const Offset(260, 0));

    expect(controller.committedMode, DashboardModeSpec.balance);
    expect(
      find.byKey(const ValueKey('dashboard-core-mode-balance')),
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
    expect(controller.committedMode.mode, DashboardMode.balance);
    expect(_mountedModeRootCount(tester), 1);
  });

  testWidgets('diagonal Header movement only claims vertical expansion', (
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
    expect(expansion.starts, 1);
    expect(controller.committedMode.mode, DashboardMode.balance);
    expect(_mountedModeRootCount(tester), 1);

    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();

    expect(expansion.starts, 1);
    expect(controller.committedMode.mode, DashboardMode.balance);
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
    expect(controller.committedMode.mode, DashboardMode.balance);

    controller.setProgrammaticMode(DashboardModeSpec.mind);
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('dashboard-core-mode-mind-body')),
      const Offset(-260, 0),
    );
    await tester.pump();
    expect(controller.committedMode.mode, DashboardMode.mind);
  });

  testWidgets(
    'a physical vertical drag on the Budget content-card background uses the Header expansion owner',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = DashboardCoreModeController(
        initialMode: DashboardModeSpec.budget,
      );
      final expansion = _ExpansionRecorder();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _ModeHostHarness(controller: controller, expansion: expansion),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('dashboard-core-mode-budget-card-1')),
        ),
      );
      await gesture.moveBy(const Offset(0, -120));
      await gesture.up();
      await tester.pump();

      expect(expansion.starts, 1);
      expect(expansion.ends, 1);
      expect(expansion.totalDelta, lessThan(0));
      expect(controller.committedMode.mode, DashboardMode.budget);
    },
  );

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
    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard-header-mode-icon-balance')),
    );
    await tester.pump();
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
    this.headerVisual,
    this.balanceHeaderVisualFrame,
    this.collapseProgress = 0,
  });

  final DashboardCoreModeController controller;
  final _ExpansionRecorder? expansion;
  final DashboardHeaderVisualController? headerVisual;
  final ValueListenable<DashboardHeaderVisualFrame>? balanceHeaderVisualFrame;
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
            height: DashboardLayoutMetrics.reference.canvasHeight,
            child: DashboardCoreModeHost(
              controller: controller,
              presentationFor: (mode) =>
                  _presentationFor(mode, collapseProgress: collapseProgress),
              onVerticalExpansionStart: expansion.begin,
              onVerticalExpansionDragBy: expansion.dragBy,
              onVerticalExpansionEnd: expansion.end,
              headerVisualController: headerVisual,
              balanceHeaderVisualFrame: balanceHeaderVisualFrame,
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
