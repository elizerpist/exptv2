import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/app_theme_settings.dart';

class ExpenseTheme {
  const ExpenseTheme({
    required this.settings,
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.activeBackground,
    required this.headerCard,
    required this.appBackground,
    required this.logBox,
    required this.fieldSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.buttonSurfaceStyle,
    required this.contentSurfaceStyle,
    required this.bottomNavSurfaceStyle,
    required this.forcedInsetSurfaceStyle,
    required this.ghostLogboxSurfaceStyle,
    required this.categoryMenu,
    required this.categoryCard,
    required this.statsMonthCard,
    required this.categoryMenuSurfaceStyle,
    required this.categoryCardSurfaceStyle,
  });

  final AppThemeSettings settings;
  final Color accent;
  final Color accentDark;
  final Color accentLight;
  final Color activeBackground;
  final Color headerCard;
  final Color appBackground;
  final Color logBox;
  final Color fieldSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ExpenseSurfaceInteraction contentSurfaceStyle;
  final ExpenseSurfaceInteraction bottomNavSurfaceStyle;
  final ExpenseSurfaceInteraction forcedInsetSurfaceStyle;
  final ExpenseSurfaceInteraction ghostLogboxSurfaceStyle;
  final Color categoryMenu;
  final Color categoryCard;
  final Color statsMonthCard;
  final ExpenseSurfaceInteraction categoryMenuSurfaceStyle;
  final ExpenseSurfaceInteraction categoryCardSurfaceStyle;

  Color resolvePrimary(Color color) {
    if (color == AppColors.primary) return accent;
    if (color == AppColors.primaryDark) return accentDark;
    if (color == AppColors.primaryLight) return accentLight;
    if (color == AppColors.primaryActiveBackground) return activeBackground;
    return color;
  }

  factory ExpenseTheme.fromSettings(AppThemeSettings settings) {
    final accentFamily = _dayAccentFamily(settings);
    return ExpenseTheme(
      settings: settings,
      accent: accentFamily.accent,
      accentDark: accentFamily.dark,
      accentLight: accentFamily.light,
      activeBackground: accentFamily.activeBackground,
      headerCard: switch (settings.cardColor) {
        AppCardColor.white => AppColors.white,
        AppCardColor.lightgray => AppColors.gray100,
        AppCardColor.darkgray => AppColors.gray200,
      },
      appBackground: switch (settings.backgroundColor) {
        AppBackgroundColor.white => AppColors.white,
        AppBackgroundColor.gray => AppColors.gray100,
        AppBackgroundColor.darkgray => AppColors.gray200,
      },
      logBox: switch (settings.boxColor) {
        AppBoxColor.white => AppColors.white,
        AppBoxColor.gray => AppColors.gray100,
        AppBoxColor.darkgray => AppColors.gray200,
      },
      fieldSurface: switch (settings.boxColor) {
        AppBoxColor.white => AppColors.white,
        AppBoxColor.gray => AppColors.gray100,
        AppBoxColor.darkgray => AppColors.gray200,
      },
      textPrimary: AppColors.gray900,
      textSecondary: AppColors.gray600,
      textMuted: AppColors.gray500,
      border: AppColors.gray200,
      buttonSurfaceStyle: settings.buttonSurfaceStyle,
      contentSurfaceStyle: settings.contentSurfaceStyle,
      bottomNavSurfaceStyle: settings.buttonSurfaceStyle,
      forcedInsetSurfaceStyle:
          settings.contentSurfaceStyle ==
              ExpenseSurfaceInteraction.neutralNeutral
          ? ExpenseSurfaceInteraction.neutralNeutral
          : ExpenseSurfaceInteraction.insetInset,
      ghostLogboxSurfaceStyle: settings.ghostLogboxSurfaceStyle,
      categoryMenu: _boxColor(settings.categoryMenuColor),
      categoryCard: _boxColor(settings.categoryCardColor),
      statsMonthCard: _boxColor(settings.statsMonthCardColor),
      categoryMenuSurfaceStyle: settings.categoryMenuSurfaceStyle,
      categoryCardSurfaceStyle: settings.categoryCardSurfaceStyle,
    );
  }

  static Color _boxColor(AppBoxColor color) {
    return switch (color) {
      AppBoxColor.white => AppColors.white,
      AppBoxColor.gray => AppColors.gray100,
      AppBoxColor.darkgray => AppColors.gray200,
    };
  }

  static _AccentFamily _dayAccentFamily(AppThemeSettings settings) {
    if (settings.appColor == AppColorMode.pink) {
      return const _AccentFamily(
        accent: Color(0xFFEC4899),
        dark: Color(0xFFBE185D),
        light: Color(0xFFF9A8D4),
        activeBackground: Color(0x15EC4899),
      );
    }
    return const _AccentFamily(
      accent: AppColors.primary,
      dark: AppColors.primaryDark,
      light: AppColors.primaryLight,
      activeBackground: AppColors.primaryActiveBackground,
    );
  }
}

class _AccentFamily {
  const _AccentFamily({
    required this.accent,
    required this.dark,
    required this.light,
    required this.activeBackground,
  });

  final Color accent;
  final Color dark;
  final Color light;
  final Color activeBackground;
}
