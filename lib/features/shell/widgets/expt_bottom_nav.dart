import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../app_tab.dart';
import 'bottom_nav_item.dart';

class ExptBottomNav extends StatelessWidget {
  const ExptBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('expt-bottom-nav'),
      height: AppDimensions.bottomNavHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.bottomNavHorizontalPadding,
        vertical: AppDimensions.bottomNavVerticalPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navShadow,
            offset: Offset(0, -8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          BottomNavItem(
            tab: AppTab.home,
            active: activeTab == AppTab.home,
            onTap: () => onTabSelected(AppTab.home),
          ),
          BottomNavItem(
            tab: AppTab.groceries,
            active: activeTab == AppTab.groceries,
            onTap: () => onTabSelected(AppTab.groceries),
          ),
          const Expanded(child: SizedBox.shrink()),
          BottomNavItem(
            tab: AppTab.notifications,
            active: activeTab == AppTab.notifications,
            onTap: () => onTabSelected(AppTab.notifications),
          ),
          BottomNavItem(
            tab: AppTab.settings,
            active: activeTab == AppTab.settings,
            onTap: () => onTabSelected(AppTab.settings),
          ),
        ],
      ),
    );
  }
}
