import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const appTabs = <AppTab>[
  AppTab.home,
  AppTab.groceries,
  AppTab.notifications,
  AppTab.settings,
];

enum AppTab {
  home,
  groceries,
  notifications,
  settings;

  String get id {
    switch (this) {
      case AppTab.home:
        return 'home';
      case AppTab.groceries:
        return 'groceries';
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
      case AppTab.groceries:
        return 'Groceries';
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
      case AppTab.groceries:
        return Icons.shopping_cart_outlined;
      case AppTab.notifications:
        return Icons.notifications_none;
      case AppTab.settings:
        return Icons.settings_outlined;
    }
  }

  Color get inactiveColor => AppColors.gray500;
}
