import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/shell/app_tab.dart';
import 'package:exptv2/features/shell/widgets/spendee_test_bottom_nav.dart';
import 'package:exptv2/features/settings/theme/expense_surface.dart';
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

    expect(navSurfaceColor(AppTab.home), AppColors.primaryActiveBackground);
    expect(navSurfaceColor(AppTab.settings), AppColors.white);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
    await tester.pump();
    expect(navSurfaceColor(AppTab.home), AppColors.white);
    expect(navSurfaceColor(AppTab.settings), AppColors.primaryActiveBackground);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pump();

    expect(selectedTabs, <AppTab>[AppTab.settings, AppTab.home]);
    expect(fabTaps, 1);
    expect(fabLongPresses, 1);
  });

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
