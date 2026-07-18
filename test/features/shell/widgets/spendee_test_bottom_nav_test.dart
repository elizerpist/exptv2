import 'package:exptv2/features/shell/app_tab.dart';
import 'package:exptv2/features/shell/widgets/spendee_test_bottom_nav.dart';
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

    await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
    await tester.tap(find.byKey(const ValueKey('bottom-nav-home')));
    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.longPress(find.byKey(const ValueKey('expt-fab')));
    await tester.pump();

    expect(selectedTabs, <AppTab>[AppTab.settings, AppTab.home]);
    expect(fabTaps, 1);
    expect(fabLongPresses, 1);
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
