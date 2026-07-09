import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../settings/models/app_theme_settings.dart';
import '../app_tab.dart';
import 'bottom_nav_item.dart';

class ExptBottomNav extends StatefulWidget {
  const ExptBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.surfaceColor = AppColors.white,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
    this.accentLightColor = AppColors.primaryLight,
    this.activeBackgroundColor = AppColors.primaryActiveBackground,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final Color accentColor;
  final Color accentLightColor;
  final Color activeBackgroundColor;

  @override
  State<ExptBottomNav> createState() => _ExptBottomNavState();
}

class _ExptBottomNavState extends State<ExptBottomNav> {
  late AppTab _optimisticActiveTab;
  String? _lastLoggedBuildKey;
  AppTab? _pointerDispatchedTab;

  @override
  void initState() {
    super.initState();
    _optimisticActiveTab = widget.activeTab;
  }

  @override
  void didUpdateWidget(ExptBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTab != _optimisticActiveTab) {
      DebugConsole.log(
        '[Perf] BottomNav parent sync from=${_optimisticActiveTab.id} '
        'to=${widget.activeTab.id}',
      );
      _optimisticActiveTab = widget.activeTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildKey = '${_optimisticActiveTab.id}|${widget.activeTab.id}';
    if (_lastLoggedBuildKey != buildKey) {
      _lastLoggedBuildKey = buildKey;
      DebugConsole.log(
        '[Perf] BottomNav build active=${_optimisticActiveTab.id} '
        'parent=${widget.activeTab.id}',
      );
    }

    final children = <Widget>[
      _buildItem(AppTab.home),
      _buildItem(AppTab.stats),
      _buildItem(AppTab.settings),
    ];

    return ExpenseSurfaceContainer(
      surfaceKey: const ValueKey('expt-bottom-nav'),
      style: widget.surfaceStyle,
      color: AppColors.white,
      borderRadius: BorderRadius.zero,
      animatePress: false,
      height: AppDimensions.bottomNavHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.bottomNavHorizontalPadding,
        vertical: AppDimensions.bottomNavVerticalPadding,
      ),
      neutralBorder: const Border(top: BorderSide(color: AppColors.gray200)),
      neutralShadow: const [
        BoxShadow(
          color: AppColors.navShadow,
          offset: Offset(0, -8),
          blurRadius: 16,
        ),
      ],
      child: Row(children: children),
    );
  }

  Widget _buildItem(AppTab tab, {int badgeCount = 0}) {
    return BottomNavItem(
      tab: tab,
      active: _optimisticActiveTab == tab,
      surfaceColor: AppColors.white,
      surfaceStyle: widget.surfaceStyle,
      accentColor: widget.accentColor,
      accentLightColor: widget.accentLightColor,
      activeBackgroundColor: widget.activeBackgroundColor,
      badgeCount: badgeCount,
      onPointerDown: () => _handlePointerDown(tab),
      onTap: () => _handleTap(tab),
    );
  }

  void _handlePointerDown(AppTab tab) {
    final requestedAt = DateTime.now();
    DebugConsole.log(
      '[Perf] BottomNav pointer tab=${tab.id} active=${_optimisticActiveTab.id} '
      'parent=${widget.activeTab.id}',
    );
    _activateOptimistic(tab, requestedAt, source: 'pointer');
    if (widget.activeTab == tab) return;
    _pointerDispatchedTab = tab;
    DebugConsole.log(
      '[Perf] BottomNav pointer dispatch tab=${tab.id} '
      'elapsed=${DateTime.now().difference(requestedAt).inMilliseconds}ms',
    );
    widget.onTabSelected(tab);
  }

  void _handleTap(AppTab tab) {
    final requestedAt = DateTime.now();
    DebugConsole.log(
      '[Perf] BottomNav item tap tab=${tab.id} '
      'active=${_optimisticActiveTab.id} parent=${widget.activeTab.id}',
    );
    if (_pointerDispatchedTab == tab) {
      _pointerDispatchedTab = null;
      DebugConsole.log(
        '[Perf] BottomNav item tap dispatch skipped tab=${tab.id}',
      );
      return;
    }
    _activateOptimistic(tab, requestedAt, source: 'tap');
    widget.onTabSelected(tab);
  }

  void _activateOptimistic(
    AppTab tab,
    DateTime requestedAt, {
    required String source,
  }) {
    if (_optimisticActiveTab == tab) return;
    setState(() => _optimisticActiveTab = tab);
    DebugConsole.log(
      '[Perf] BottomNav optimistic active tab=${tab.id} source=$source',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _optimisticActiveTab != tab) return;
      DebugConsole.log(
        '[Perf] BottomNav optimistic frame tab=${tab.id} source=$source '
        'elapsed=${DateTime.now().difference(requestedAt).inMilliseconds}ms',
      );
    });
  }
}
