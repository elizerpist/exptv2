import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../settings/models/app_theme_settings.dart';
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
    final centerSlotWidth = math.max(widget.fabSize + 16, 74).toDouble();
    return KeyedSubtree(
      key: const ValueKey('spendee-test-bottom-nav'),
      child: ExpenseSurfaceContainer(
        surfaceKey: const ValueKey('expt-bottom-nav'),
        style: widget.surfaceStyle,
        color: widget.surfaceColor,
        borderRadius: BorderRadius.zero,
        animatePress: false,
        clipContent: false,
        height: AppDimensions.bottomNavHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.bottomNavHorizontalPadding,
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
                primaryColor: widget.accentColor,
                surfaceStyle: widget.buttonSurfaceStyle,
                size: widget.fabSize,
                borderRadius: widget.fabSize / 2,
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
    return BottomNavItem(
      tab: tab,
      label: label,
      icon: icon,
      active: _optimisticActiveTab == tab,
      surfaceColor: widget.surfaceColor,
      surfaceStyle: widget.surfaceStyle,
      accentColor: widget.accentColor,
      accentLightColor: widget.accentLightColor,
      activeBackgroundColor: widget.activeBackgroundColor,
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
