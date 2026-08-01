import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_collapse_handle.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/fluvi_brand_lockup.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/time_refinement_rail.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/transaction_direction_toggle.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 48);

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

  testWidgets('direction controls use the reference height and rounded box', (
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

    expect(DashboardLayoutMetrics.reference.actionHeight, 52);

    for (final key in const [
      ValueKey('fluvi-income-button'),
      ValueKey('fluvi-expense-button'),
    ]) {
      final decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (decorated.decoration as BoxDecoration).borderRadius,
        const BorderRadius.all(Radius.circular(16)),
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

  testWidgets('time refinement rail exposes five centered rounded boxes', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 23);
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
  });

  testWidgets('active time box uses the shared app highlight gradient', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 23);
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
    expect(decoration.boxShadow, const [FluviVisualTokens.appHighlightShadow]);
    expect(
      decoration.borderRadius,
      const BorderRadius.all(Radius.circular(16)),
    );
  });

  testWidgets('time rail repeats values as an effectively infinite belt', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 23);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(TimeRefinementRail(bounds: _bounds, controller: controller)),
    );
    await tester.pump();

    controller.jumpToIndex(33);
    await tester.pump();

    expect(controller.selectedIndex, 33);
    expect(find.text('2024'), findsOneWidget);
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
