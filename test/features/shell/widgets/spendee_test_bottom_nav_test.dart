import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/shell/app_tab.dart';
import 'package:exptv2/features/shell/widgets/spendee_test_bottom_nav.dart';
import 'package:exptv2/features/settings/theme/expense_surface.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_dashboard_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lays out Dashboard, centered FAB, and Settings only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildApp(
        SpendeeTestBottomNav(
          activeTab: AppTab.home,
          onTabSelected: (_) {},
          onFabPressed: () {},
          onFabLongPress: () {},
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Beállítások'), findsOneWidget);
    expect(find.text('Stats'), findsNothing);
    expect(
      find.byKey(const ValueKey('spendee-test-bottom-nav')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('expt-bottom-nav')), findsOneWidget);

    final dashboardCenter = tester.getCenter(
      find.byKey(const ValueKey('bottom-nav-home')),
    );
    final fabCenter = tester.getCenter(find.byKey(const ValueKey('expt-fab')));
    final settingsCenter = tester.getCenter(
      find.byKey(const ValueKey('bottom-nav-settings')),
    );

    expect(dashboardCenter.dx, lessThan(fabCenter.dx));
    expect(fabCenter.dx, closeTo(206, 0.01));
    expect(fabCenter.dx, lessThan(settingsCenter.dx));
    expect(dashboardCenter.dy, closeTo(settingsCenter.dy, 0.01));

    final fabRect = tester.getRect(find.byKey(const ValueKey('expt-fab')));
    final fabSurface = tester.widget<Container>(
      find.byKey(const ValueKey('expt-fab')),
    );
    final decoration = fabSurface.decoration! as BoxDecoration;
    final radius = decoration.borderRadius! as BorderRadius;
    expect(radius.topLeft.x, closeTo(fabRect.width / 2, 0.01));
  });

  testWidgets('dispatches destinations and existing FAB gestures', (
    tester,
  ) async {
    final selectedTabs = <AppTab>[];
    var fabTaps = 0;
    var fabLongPresses = 0;

    await tester.pumpWidget(
      _buildApp(
        SpendeeTestBottomNav(
          activeTab: AppTab.home,
          dashboardMode: SpendeeDashboardMode.balance,
          onTabSelected: selectedTabs.add,
          onFabPressed: () => fabTaps += 1,
          onFabLongPress: () => fabLongPresses += 1,
        ),
      ),
    );

    Color navSurfaceColor(AppTab tab) {
      final container = tester.widget<Container>(
        find.byKey(ValueKey('bottom-nav-${tab.id}-surface')),
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    expect(navSurfaceColor(AppTab.home), const Color(0x1A06B6D4));
    expect(navSurfaceColor(AppTab.settings), AppColors.white);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
    await tester.pump();
    expect(navSurfaceColor(AppTab.home), AppColors.white);
    expect(navSurfaceColor(AppTab.settings), const Color(0x1A06B6D4));

    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pump();

    expect(selectedTabs, <AppTab>[AppTab.settings, AppTab.home]);
    expect(fabTaps, 1);
    expect(fabLongPresses, 1);
  });

  testWidgets(
    'Balance destinations expose one label without decorative glyph speech',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          SpendeeTestBottomNav(
            activeTab: AppTab.home,
            dashboardMode: SpendeeDashboardMode.balance,
            onTabSelected: (_) {},
            onFabPressed: () {},
          ),
        ),
      );

      final dashboard = tester.getSemantics(
        find.byKey(const ValueKey('bottom-nav-home')),
      );
      final settings = tester.getSemantics(
        find.byKey(const ValueKey('bottom-nav-settings')),
      );

      expect(dashboard.label, 'Dashboard');
      expect(dashboard.flagsCollection.isButton, isTrue);
      expect(dashboard.childrenCount, 0);
      expect(settings.label, 'Beállítások');
      expect(settings.flagsCollection.isButton, isTrue);
      expect(settings.childrenCount, 0);
      expect(find.bySemanticsLabel('Dashboard'), findsOneWidget);
      expect(find.bySemanticsLabel('Beállítások'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('[⌂⚙+]')), findsNothing);
    },
  );

  testWidgets('does not clip the largest configured FAB', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        SpendeeTestBottomNav(
          activeTab: AppTab.home,
          fabSize: 88,
          onTabSelected: (_) {},
          onFabPressed: () {},
        ),
      ),
    );

    final navigationSurface = tester.widget<ExpenseSurfaceContainer>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('expt-bottom-nav')),
            matching: find.byType(ExpenseSurfaceContainer),
          )
          .first,
    );
    expect(navigationSurface.clipContent, isFalse);

    final navigationRect = tester.getRect(
      find.byKey(const ValueKey('expt-bottom-nav')),
    );
    final fabRect = tester.getRect(find.byKey(const ValueKey('expt-fab')));
    expect(fabRect.height, 88);
    expect(fabRect.top, lessThan(navigationRect.top));
    expect(fabRect.bottom, greaterThan(navigationRect.bottom));
  });

  testWidgets('Balance mode paints the exact FAB gradient', (tester) async {
    tester.view.physicalSize = const Size(410, 890);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildApp(
        SpendeeTestBottomNav(
          activeTab: AppTab.home,
          dashboardMode: SpendeeDashboardMode.balance,
          onTabSelected: (_) {},
          onFabPressed: () {},
        ),
      ),
    );

    final gradientSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('expt-fab-gradient')),
    );
    final decoration = gradientSurface.decoration as BoxDecoration;

    expect(decoration.gradient, spendeeBalanceFabGradient);
    expect(
      tester.getRect(find.byKey(const ValueKey('expt-bottom-nav'))),
      const Rect.fromLTWH(0, 810, 410, 80),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('expt-fab'))),
      const Rect.fromLTWH(176, 821.5, 58, 58),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('bottom-nav-home-surface'))),
      const Size(148, 55),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('bottom-nav-settings-surface'))),
      const Size(148, 55),
    );
    expect(find.text('⌂'), findsOneWidget);
    expect(find.text('⚙'), findsOneWidget);
    expect(find.text('+'), findsOneWidget);
    final fabSurface = tester.widget<Container>(
      find.byKey(const ValueKey('expt-fab')),
    );
    final fabDecoration = fabSurface.decoration! as BoxDecoration;
    expect(fabDecoration.boxShadow, hasLength(3));
    expect(fabDecoration.boxShadow!.last.blurStyle, BlurStyle.inner);
    expect(fabDecoration.boxShadow!.last.color, const Color(0x61FFFFFF));
  });

  testWidgets('Budget and Mind modes keep the FAB surface solid', (
    tester,
  ) async {
    for (final mode in <SpendeeDashboardMode>[
      SpendeeDashboardMode.budget,
      SpendeeDashboardMode.mind,
    ]) {
      await tester.pumpWidget(
        _buildApp(
          SpendeeTestBottomNav(
            activeTab: AppTab.home,
            dashboardMode: mode,
            onTabSelected: (_) {},
            onFabPressed: () {},
          ),
        ),
      );

      expect(find.byKey(const ValueKey('expt-fab-gradient')), findsNothing);
      final fabSurface = tester.widget<Container>(
        find.byKey(const ValueKey('expt-fab')),
      );
      final decoration = fabSurface.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.primary);
      expect(decoration.gradient, isNull);
    }
  });
}

Widget _buildApp(Widget bottomNav) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [Positioned(left: 0, right: 0, bottom: 0, child: bottomNav)],
      ),
    ),
  );
}
