import 'package:flutter/material.dart';

import '../../../core/debug/debug_console.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../app_tab.dart';
import 'bottom_nav_item.dart';

class ExptBottomNav extends StatefulWidget {
  const ExptBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.unreadNotificationCount = 0,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onTabSelected;
  final int unreadNotificationCount;

  @override
  State<ExptBottomNav> createState() => _ExptBottomNavState();
}

class _ExptBottomNavState extends State<ExptBottomNav> {
  late AppTab _optimisticActiveTab;
  String? _lastLoggedBuildKey;

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
        'to=${widget.activeTab.id} unread=${widget.unreadNotificationCount}',
      );
      _optimisticActiveTab = widget.activeTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildKey =
        '${_optimisticActiveTab.id}|${widget.activeTab.id}|${widget.unreadNotificationCount}';
    if (_lastLoggedBuildKey != buildKey) {
      _lastLoggedBuildKey = buildKey;
      DebugConsole.log(
        '[Perf] BottomNav build active=${_optimisticActiveTab.id} '
        'parent=${widget.activeTab.id} unread=${widget.unreadNotificationCount}',
      );
    }

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
          _buildItem(AppTab.home),
          _buildItem(AppTab.stats),
          const Expanded(child: SizedBox.shrink()),
          _buildItem(
            AppTab.notifications,
            badgeCount: widget.unreadNotificationCount,
          ),
          _buildItem(AppTab.settings),
        ],
      ),
    );
  }

  Widget _buildItem(AppTab tab, {int badgeCount = 0}) {
    return BottomNavItem(
      tab: tab,
      active: _optimisticActiveTab == tab,
      badgeCount: badgeCount,
      onPointerDown: () => _logPointerDown(tab),
      onTap: () => _handleTap(tab),
    );
  }

  void _logPointerDown(AppTab tab) {
    DebugConsole.log(
      '[Perf] BottomNav pointer tab=${tab.id} active=${_optimisticActiveTab.id} '
      'parent=${widget.activeTab.id}',
    );
  }

  void _handleTap(AppTab tab) {
    final requestedAt = DateTime.now();
    DebugConsole.log(
      '[Perf] BottomNav item tap tab=${tab.id} '
      'active=${_optimisticActiveTab.id} parent=${widget.activeTab.id}',
    );
    if (_optimisticActiveTab != tab) {
      setState(() => _optimisticActiveTab = tab);
      DebugConsole.log('[Perf] BottomNav optimistic active tab=${tab.id}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _optimisticActiveTab != tab) return;
        DebugConsole.log(
          '[Perf] BottomNav optimistic frame tab=${tab.id} '
          'elapsed=${DateTime.now().difference(requestedAt).inMilliseconds}ms',
        );
      });
    }
    widget.onTabSelected(tab);
  }
}
