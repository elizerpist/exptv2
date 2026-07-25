import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../settings/models/app_theme_settings.dart';
import '../../transactions/widgets/experimental/spendee_dashboard_mode.dart';
import '../app_tab.dart';
import 'bottom_nav_item.dart';
import 'expt_fab.dart';

class SpendeeTestBottomNav extends StatefulWidget {
  const SpendeeTestBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onFabPressed,
    this.onFabLongPress,
    this.dashboardMode = SpendeeDashboardMode.budget,
    this.surfaceColor = AppColors.white,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.buttonSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
    this.accentLightColor = AppColors.primaryLight,
    this.activeBackgroundColor = AppColors.primaryActiveBackground,
    this.fabSize = AppDimensions.fabSize,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback onFabPressed;
  final VoidCallback? onFabLongPress;
  final SpendeeDashboardMode dashboardMode;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final Color accentColor;
  final Color accentLightColor;
  final Color activeBackgroundColor;
  final double fabSize;

  @override
  State<SpendeeTestBottomNav> createState() => _SpendeeTestBottomNavState();
}

class _SpendeeTestBottomNavState extends State<SpendeeTestBottomNav> {
  late AppTab _optimisticActiveTab;

  @override
  void initState() {
    super.initState();
    _optimisticActiveTab = widget.activeTab;
  }

  @override
  void didUpdateWidget(covariant SpendeeTestBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTab != _optimisticActiveTab) {
      _optimisticActiveTab = widget.activeTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.dashboardMode == SpendeeDashboardMode.balance;
    final fabSize = balance ? 58.0 : widget.fabSize;
    final centerSlotWidth = math.max(fabSize + 16, 74).toDouble();
    final surfaceColor = balance ? AppColors.white : widget.surfaceColor;
    final surfaceStyle = balance
        ? ExpenseSurfaceInteraction.neutralNeutral
        : widget.surfaceStyle;
    return KeyedSubtree(
      key: const ValueKey('spendee-test-bottom-nav'),
      child: ExpenseSurfaceContainer(
        surfaceKey: const ValueKey('expt-bottom-nav'),
        style: surfaceStyle,
        color: surfaceColor,
        borderRadius: BorderRadius.zero,
        animatePress: false,
        clipContent: false,
        height: AppDimensions.bottomNavHeight,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.bottomNavHorizontalPadding,
          vertical: balance ? AppDimensions.bottomNavVerticalPadding : 0,
        ),
        neutralBorder: const Border(top: BorderSide(color: AppColors.gray200)),
        neutralShadow: const [
          BoxShadow(
            color: AppColors.navShadow,
            offset: Offset(0, -8),
            blurRadius: 16,
          ),
        ],
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                _buildItem(
                  AppTab.home,
                  label: 'Dashboard',
                  icon: Icons.home_outlined,
                ),
                SizedBox(width: centerSlotWidth),
                _buildItem(AppTab.settings),
              ],
            ),
            OverflowBox(
              alignment: Alignment.center,
              minWidth: 0,
              maxWidth: double.infinity,
              minHeight: 0,
              maxHeight: double.infinity,
              child: ExptFab(
                primaryColor: balance ? AppColors.primary : widget.accentColor,
                backgroundGradient: widget.dashboardMode.fabGradient,
                surfaceStyle: balance
                    ? ExpenseSurfaceInteraction.neutralNeutral
                    : widget.buttonSurfaceStyle,
                size: fabSize,
                borderRadius: fabSize / 2,
                onPressed: widget.onFabPressed,
                onLongPress: widget.onFabLongPress,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(AppTab tab, {String? label, IconData? icon}) {
    final balance = widget.dashboardMode == SpendeeDashboardMode.balance;
    return BottomNavItem(
      tab: tab,
      label: label,
      icon: icon,
      iconGlyph: balance ? (tab == AppTab.home ? '⌂' : '⚙') : null,
      active: _optimisticActiveTab == tab,
      surfaceColor: balance ? AppColors.white : widget.surfaceColor,
      surfaceStyle: balance
          ? ExpenseSurfaceInteraction.neutralNeutral
          : widget.surfaceStyle,
      accentColor: balance ? AppColors.primary : widget.accentColor,
      accentLightColor: balance
          ? AppColors.primaryLight
          : widget.accentLightColor,
      activeBackgroundColor: balance
          ? const Color(0x1A06B6D4)
          : widget.activeBackgroundColor,
      horizontalMargin: balance ? 0 : AppDimensions.navItemHorizontalMargin,
      radius: balance ? 18 : AppDimensions.navItemRadius,
      iconSize: balance ? 22 : AppDimensions.navIconSize,
      iconBoxWidth: balance ? 32 : 34,
      iconBoxHeight: balance ? 22 : AppDimensions.navIconSize,
      labelFontSize: balance ? 11 : 12,
      itemHeight: balance ? 55 : null,
      fontFamily: balance ? 'Inter' : null,
      iconFontFamily: balance ? 'B3ma3Symbols' : null,
      onTap: () => _selectTab(tab),
    );
  }

  void _selectTab(AppTab tab) {
    if (_optimisticActiveTab != tab) {
      setState(() => _optimisticActiveTab = tab);
    }
    widget.onTabSelected(tab);
  }
}
