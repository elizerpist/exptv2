import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../state/event_store.dart';
import '../settings/settings_page.dart';
import 'app_tab.dart';
import 'widgets/blank_tab_page.dart';
import 'widgets/expt_bottom_nav.dart';
import 'widgets/expt_fab.dart';

class ExptShell extends StatefulWidget {
  const ExptShell({super.key, required this.store});

  final EventStore store;

  @override
  State<ExptShell> createState() => _ExptShellState();
}

class _ExptShellState extends State<ExptShell> {
  AppTab _activeTab = AppTab.home;

  void _selectTab(AppTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.bottomNavHeight,
              ),
              child: IndexedStack(
                index: appTabs.indexOf(_activeTab),
                children: [
                  const BlankTabPage(tab: AppTab.home),
                  const BlankTabPage(tab: AppTab.groceries),
                  const BlankTabPage(tab: AppTab.notifications),
                  SettingsPage(store: widget.store),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ExptBottomNav(
              activeTab: _activeTab,
              onTabSelected: _selectTab,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppDimensions.fabBottom,
            child: Center(child: ExptFab(onPressed: () {})),
          ),
        ],
      ),
    );
  }
}
