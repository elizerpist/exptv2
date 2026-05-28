import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const appTabs = <AppTab>[
  AppTab.home,
  AppTab.stats,
  AppTab.notifications,
  AppTab.settings,
];

enum AppTab {
  home,
  stats,
  notifications,
  settings;

  String get id {
    switch (this) {
      case AppTab.home:
        return 'home';
      case AppTab.stats:
        return 'stats';
      case AppTab.notifications:
        return 'notifications';
      case AppTab.settings:
        return 'settings';
    }
  }

  String get label {
    switch (this) {
      case AppTab.home:
        return 'Főoldal';
      case AppTab.stats:
        return 'Stats';
      case AppTab.notifications:
        return 'Értesítések';
      case AppTab.settings:
        return 'Beállítások';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.home:
        return Icons.home_outlined;
      case AppTab.stats:
        return Icons.query_stats_outlined;
      case AppTab.notifications:
        return Icons.notifications_none;
      case AppTab.settings:
        return Icons.settings_outlined;
    }
  }

  Color get inactiveColor => AppColors.gray500;
}
