import 'package:exptv2/features/shell/app_tab.dart';
import 'package:exptv2/features/shell/widgets/expt_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('notifications tab shows unread badge count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ExptBottomNav(
            activeTab: AppTab.home,
            unreadNotificationCount: 3,
            onTabSelected: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('bottom-nav-notifications-unread-badge')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('notifications tab hides unread badge when count is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ExptBottomNav(
            activeTab: AppTab.home,
            unreadNotificationCount: 0,
            onTabSelected: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('bottom-nav-notifications-unread-badge')),
      findsNothing,
    );
  });
}
