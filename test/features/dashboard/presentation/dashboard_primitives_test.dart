import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/app_control_metrics.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_collapse_handle.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_placeholder_card.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/fluvi_brand_lockup.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/time_refinement_rail.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/transaction_direction_toggle.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

const _bounds = DashboardBounds(
  left: 0,
  top: 0,
  width: 378,
  height: AppControlMetrics.carouselViewportHeight,
);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('brand lockup renders its semantic brand parts', (tester) async {
    await tester.pumpWidget(_host(const FluviBrandLockup(bounds: _bounds)));

    expect(find.byKey(const ValueKey('fluvi-brand-mark')), findsOneWidget);
    expect(find.byKey(const ValueKey('fluvi-wordmark')), findsOneWidget);
    expect(find.byKey(const ValueKey('fluvi-motto')), findsOneWidget);
  });

  testWidgets('expense direction uses the native action assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TransactionDirectionToggle(
          bounds: _bounds,
          palette: DashboardModePaletteResolver.resolve(
            DashboardModeSpec.balance,
          ),
          selectedDirection: TransactionDirection.expense,
          incomeIconScale: 1,
          expenseIconScale: 1.12,
          onSelected: (_) {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('fluvi-income-wallet')), findsOneWidget);
    expect(find.byKey(const ValueKey('fluvi-expense-bag')), findsOneWidget);
    expect(find.text('Kiadás'), findsOneWidget);
  });

  testWidgets('direction icons apply the shared ten percent size increase', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TransactionDirectionToggle(
          bounds: _bounds,
          palette: DashboardModePaletteResolver.resolve(
            DashboardModeSpec.balance,
          ),
          selectedDirection: TransactionDirection.income,
          incomeIconScale: 1,
          expenseIconScale: 1,
          onSelected: (_) {},
        ),
      ),
    );

    for (final key in const [
      ValueKey('fluvi-income-wallet'),
      ValueKey('fluvi-expense-bag'),
    ]) {
      final transform = tester.widget<Transform>(
        find.ancestor(of: find.byKey(key), matching: find.byType(Transform)),
      );

      expect(transform.transform.storage[0], closeTo(1.10, .001));
      expect(transform.transform.storage[5], closeTo(1.10, .001));
    }
  });

  testWidgets('direction controls use the compact B3M height and radius', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TransactionDirectionToggle(
          bounds: const DashboardBounds(
            left: 0,
            top: 0,
            width: 378,
            height: 52,
          ),
          palette: DashboardModePaletteResolver.resolve(
            DashboardModeSpec.balance,
          ),
          selectedDirection: TransactionDirection.income,
          incomeIconScale: 1,
          expenseIconScale: 1,
          onSelected: (_) {},
        ),
      ),
    );

    expect(AppControlMetrics.selectorHeight, 37);

    for (final key in const [
      ValueKey('fluvi-income-button'),
      ValueKey('fluvi-expense-button'),
    ]) {
      expect(
        tester.getSize(find.byKey(key)).width,
        closeTo((378 - FluviVisualTokens.controlInnerGap) / 2, .01),
      );
      expect(
        tester.getSize(find.byKey(key)).height,
        closeTo(AppSelectorMetrics.directionControlHeight, .01),
      );
      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (decorated.decoration as BoxDecoration).borderRadius,
        const BorderRadius.all(Radius.circular(14)),
      );
      expect(
        (decorated.decoration as BoxDecoration).boxShadow,
        FluviVisualTokens.cardSurfaceShadows,
      );
    }
  });

  testWidgets('inactive direction control uses the white surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TransactionDirectionToggle(
          bounds: const DashboardBounds(
            left: 0,
            top: 0,
            width: 378,
            height: 52,
          ),
          palette: DashboardModePaletteResolver.resolve(
            DashboardModeSpec.balance,
          ),
          selectedDirection: TransactionDirection.income,
          incomeIconScale: 1,
          expenseIconScale: 1,
          onSelected: (_) {},
        ),
      ),
    );

    final inactiveButton = tester.widget<FluviRoundedBox>(
      find.byKey(const ValueKey('fluvi-expense-button')),
    );

    expect(inactiveButton.decoration.color, Colors.white);
    expect(
      inactiveButton.decoration.boxShadow,
      FluviVisualTokens.cardSurfaceShadows,
    );
  });

  testWidgets('active income uses its explicit purple-magenta highlight', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TransactionDirectionToggle(
          bounds: const DashboardBounds(
            left: 0,
            top: 0,
            width: 378,
            height: 52,
          ),
          palette: DashboardModePaletteResolver.resolve(
            DashboardModeSpec.balance,
          ),
          selectedDirection: TransactionDirection.income,
          incomeIconScale: 1,
          expenseIconScale: 1,
          onSelected: (_) {},
        ),
      ),
    );

    final incomeButton = tester.widget<FluviRoundedBox>(
      find.byKey(const ValueKey('fluvi-income-button')),
    );

    expect(
      incomeButton.decoration.gradient,
      const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF715EFB), Color(0xFFB484F3), Color(0xFFE478C3)],
        stops: [0, .5, 1],
      ),
    );
    expect(
      incomeButton.decoration.gradient,
      isNot(
        DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ).incomeGradient,
      ),
    );
  });

  testWidgets('header and summary card surfaces use the shared 3D shadows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            DashboardPlaceholderCard(
              bounds: _bounds,
              semanticKey: const ValueKey('test-header-card'),
            ),
            DashboardSummaryPill(
              bounds: _bounds,
              isRailVisible: false,
              onChevronTap: () {},
            ),
          ],
        ),
      ),
    );

    for (final card in tester.widgetList<FluviRoundedBox>(
      find.byType(FluviRoundedBox),
    )) {
      expect(card.decoration.boxShadow, FluviVisualTokens.cardSurfaceShadows);
    }
  });

  testWidgets('brand lockup uses semantic typography tokens', (tester) async {
    await tester.pumpWidget(_host(const FluviBrandLockup(bounds: _bounds)));

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('fluvi-wordmark'))).style,
      FluviVisualTokens.brandWordmarkTextStyle,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('fluvi-motto'))).style,
      FluviVisualTokens.brandMottoTextStyle,
    );
  });

  testWidgets('collapse handle forwards a tap intent', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(DashboardCollapseHandle(bounds: _bounds, onTap: () => taps += 1)),
    );

    await tester.tap(find.byKey(const ValueKey('dashboard-collapse-handle')));
    expect(taps, 1);
  });

  testWidgets('collapse handle is gray at rest', (tester) async {
    await tester.pumpWidget(
      _host(DashboardCollapseHandle(bounds: _bounds, onTap: () {})),
    );

    final handle = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('dashboard-collapse-handle')),
            matching: find.byType(DecoratedBox),
          )
          .last,
    );
    final decoration = handle.decoration as BoxDecoration;

    expect(decoration.gradient, isNull);
    expect(decoration.color, FluviVisualTokens.collapseHandleIdleColor);
  });

  testWidgets('time refinement rail exposes five centered rounded boxes', (
    tester,
  ) async {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2028, 1, 1),
      initialPlane: TimePlane.sum,
      yearAnchor: 2028,
    );
    controller.timeCarousel.jumpToIndexSilently(23);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(TimeRefinementRail(bounds: _bounds, controller: controller)),
    );
    await tester.pump();

    expect(find.byType(Scrollable), findsOneWidget);
    expect(
      tester.widget<Scrollable>(find.byType(Scrollable)).axisDirection,
      AxisDirection.right,
    );
    final railRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-time-rail')),
    );
    final visibleBoxes = find
        .byKey(const ValueKey('fluvi-time-box'))
        .evaluate()
        .where((element) {
          final renderBox = element.renderObject! as RenderBox;
          final topLeft = renderBox.localToGlobal(Offset.zero);
          return (topLeft & renderBox.size).overlaps(railRect);
        })
        .length;
    expect(visibleBoxes, 5);
    expect(railRect.width, closeTo(378, .01));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dashboard-time-rail')),
        matching: find.byType(ClipRect),
      ),
      findsOneWidget,
    );
  });

  testWidgets('direction controls stay taller than reduced year tiles', (
    tester,
  ) async {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2028, 1, 1),
      initialPlane: TimePlane.sum,
      yearAnchor: 2028,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            TransactionDirectionToggle(
              bounds: const DashboardBounds(
                left: 0,
                top: 0,
                width: 378,
                height: 52,
              ),
              palette: DashboardModePaletteResolver.resolve(
                DashboardModeSpec.balance,
              ),
              selectedDirection: TransactionDirection.income,
              incomeIconScale: 1,
              expenseIconScale: 1,
              onSelected: (_) {},
            ),
            TimeRefinementRail(bounds: _bounds, controller: controller),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const ValueKey('fluvi-income-button'))).height,
      closeTo(AppSelectorMetrics.directionControlHeight, .01),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('fluvi-time-box')).first).height,
      closeTo(AppSelectorMetrics.yearTileHeight, .01),
    );
  });

  testWidgets('time tiles stay shadowless on the dashboard background', (
    tester,
  ) async {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2028, 1, 1),
      initialPlane: TimePlane.sum,
      yearAnchor: 2028,
    );
    controller.timeCarousel.jumpToIndexSilently(23);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(TimeRefinementRail(bounds: _bounds, controller: controller)),
    );
    await tester.pump();

    final selected = tester.widget<FluviRoundedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is FluviRoundedBox &&
            widget.decoration.gradient ==
                FluviVisualTokens.appHighlightGradient,
      ),
    );
    final selectedRect = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is FluviRoundedBox &&
            widget.decoration.gradient ==
                FluviVisualTokens.appHighlightGradient,
      ),
    );

    expect(selected.decoration.boxShadow, isEmpty);
    expect(
      selected.decoration.borderRadius,
      const BorderRadius.all(Radius.circular(14)),
    );
    expect(
      selectedRect.height,
      closeTo(AppSelectorMetrics.yearTileHeight * 1.12, .01),
    );
    expect(selectedRect.width, closeTo(69.2 * 1.12, .01));
    final railRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-time-rail')),
    );
    expect(selectedRect.top, greaterThanOrEqualTo(railRect.top));
    expect(selectedRect.bottom, lessThanOrEqualTo(railRect.bottom));
  });

  testWidgets('active time box uses the shared app highlight gradient', (
    tester,
  ) async {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2028, 1, 1),
      initialPlane: TimePlane.sum,
      yearAnchor: 2028,
    );
    controller.timeCarousel.jumpToIndexSilently(23);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(TimeRefinementRail(bounds: _bounds, controller: controller)),
    );
    await tester.pump();

    final activePill = tester.widget<FluviRoundedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is FluviRoundedBox &&
            widget.decoration.gradient ==
                FluviVisualTokens.appHighlightGradient,
      ),
    );
    final decoration = activePill.decoration;

    expect(decoration.gradient, FluviVisualTokens.appHighlightGradient);
    expect(decoration.boxShadow, isEmpty);
    expect(
      decoration.borderRadius,
      const BorderRadius.all(Radius.circular(14)),
    );
  });

  testWidgets('time rail repeats values as an effectively infinite belt', (
    tester,
  ) async {
    final controller = DashboardTimeNavigationController(
      initialDate: DateTime(2028, 1, 1),
      initialPlane: TimePlane.sum,
      yearAnchor: 2028,
    );
    controller.timeCarousel.jumpToIndexSilently(23);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(TimeRefinementRail(bounds: _bounds, controller: controller)),
    );
    await tester.pump();

    controller.timeCarousel.jumpToIndex(33);
    await tester.pump();

    expect(controller.selectedIndex, 33);
    expect(find.text('2061'), findsOneWidget);
  });

  testWidgets(
    'summary chevron uses the shared highlight while the rail is active',
    (tester) async {
      await tester.pumpWidget(
        _host(
          DashboardSummaryPill(
            bounds: _bounds,
            isRailVisible: true,
            onChevronTap: () {},
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsOneWidget);
    },
  );

  testWidgets('collapse handle uses the pressed highlight while dragging', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        DashboardCollapseHandle(
          bounds: _bounds,
          isDragging: true,
          onTap: () {},
        ),
      ),
    );

    final handle = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('dashboard-collapse-handle')),
            matching: find.byType(DecoratedBox),
          )
          .last,
    );
    final decoration = handle.decoration as BoxDecoration;

    expect(decoration.color, FluviVisualTokens.appHighlightPressedColor);
  });
}
