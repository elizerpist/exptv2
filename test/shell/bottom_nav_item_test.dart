import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
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

  testWidgets(
    'bottom nav highlights tapped tab immediately and logs tap path',
    (tester) async {
      DebugConsole.clear();
      var selectedTab = AppTab.home;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ExptBottomNav(
              activeTab: AppTab.home,
              onTabSelected: (tab) => selectedTab = tab,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
      await tester.pump();

      expect(selectedTab, AppTab.settings);
      final settingsLabel = tester.widget<Text>(find.text('Beállítások'));
      expect(settingsLabel.style?.color, AppColors.primary);
      expect(
        DebugConsole.allText,
        contains('[Perf] BottomNav item tap tab=settings'),
      );
      expect(
        DebugConsole.allText,
        contains('[Perf] BottomNav optimistic frame tab=settings'),
      );
    },
  );

  testWidgets('bottom nav dispatches and highlights on pointer down', (
    tester,
  ) async {
    DebugConsole.clear();
    var selectedTab = AppTab.home;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ExptBottomNav(
            activeTab: AppTab.home,
            onTabSelected: (tab) => selectedTab = tab,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('bottom-nav-settings'))),
    );
    await tester.pump();

    expect(selectedTab, AppTab.settings);
    final settingsLabel = tester.widget<Text>(find.text('Beállítások'));
    expect(settingsLabel.style?.color, AppColors.primary);
    expect(
      DebugConsole.allText,
      contains('[Perf] BottomNav pointer dispatch tab=settings'),
    );

    await gesture.up();
    await tester.pump();
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

  testWidgets('active bottom nav item rests normally for raised style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ExptBottomNav(
            activeTab: AppTab.home,
            surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            onTabSelected: (_) {},
          ),
        ),
      ),
    );

    final activeSurface = tester.widget<Container>(
      find.byKey(const ValueKey('bottom-nav-home-surface')),
    );
    final decoration = activeSurface.decoration as BoxDecoration;
    expect(decoration.gradient, isNull);

    await tester.pump(ExpenseSurface.pressDuration);

    final transformYs = tester
        .widgetList<Transform>(
          find.ancestor(
            of: find.byKey(const ValueKey('bottom-nav-home-surface')),
            matching: find.byType(Transform),
          ),
        )
        .map((transform) => transform.transform.getTranslation().y);
    expect(transformYs, isNot(contains(moreOrLessEquals(2, epsilon: 0.01))));
  });
}
