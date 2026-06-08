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

  bool get isNeumorphism =>
      settings.designProfile == AppDesignProfile.neumorphism;
  bool get isNight => settings.nightMode != AppNightMode.off;

  Color resolvePrimary(Color color) {
    if (color == AppColors.primary) return accent;
    if (color == AppColors.primaryDark) return accentDark;
    if (color == AppColors.primaryLight) return accentLight;
    if (color == AppColors.primaryActiveBackground) return activeBackground;
    return color;
  }

  factory ExpenseTheme.fromSettings(AppThemeSettings settings) {
    const nightCyanAccent = Color(0xFF19BFDC);
    const nightCyanBackground = Color(0xFF0B1420);
    const nightCyanCard = Color(0xFF162333);
    const nightCyanSurface = Color(0xFF152231);
    const nightAmberAccent = Color(0xFFF0A646);
    const nightAmberBackground = Color(0xFF15120F);
    const nightAmberCard = Color(0xFF292118);
    const nightAmberSurface = Color(0xFF231D17);

    final neumorphism = settings.designProfile == AppDesignProfile.neumorphism;
    final surfaceStyles = _surfaceStyles(neumorphism);

    if (settings.nightMode == AppNightMode.cyan) {
      return ExpenseTheme(
        settings: settings,
        accent: nightCyanAccent,
        accentDark: const Color(0xFF0E7490),
        accentLight: const Color(0xFF67E8F9),
        activeBackground: const Color(0x2219BFDC),
        headerCard: nightCyanCard,
        appBackground: nightCyanBackground,
        logBox: nightCyanSurface,
        fieldSurface: nightCyanSurface,
        textPrimary: const Color(0xFFE5F0F8),
        textSecondary: const Color(0xFFB7C8D8),
        textMuted: const Color(0xFF7F95A8),
        border: const Color(0xFF2A3D50),
        buttonSurfaceStyle: surfaceStyles.button,
        contentSurfaceStyle: surfaceStyles.content,
        bottomNavSurfaceStyle: surfaceStyles.bottomNav,
        forcedInsetSurfaceStyle: surfaceStyles.forcedInset,
      );
    }

    if (settings.nightMode == AppNightMode.amber) {
      return ExpenseTheme(
        settings: settings,
        accent: nightAmberAccent,
        accentDark: const Color(0xFFC27803),
        accentLight: const Color(0xFFFCD34D),
        activeBackground: const Color(0x22F0A646),
        headerCard: nightAmberCard,
        appBackground: nightAmberBackground,
        logBox: nightAmberSurface,
        fieldSurface: nightAmberSurface,
        textPrimary: const Color(0xFFF4EDE3),
        textSecondary: const Color(0xFFD7C5AF),
        textMuted: const Color(0xFFA78E75),
        border: const Color(0xFF3C3025),
        buttonSurfaceStyle: surfaceStyles.button,
        contentSurfaceStyle: surfaceStyles.content,
        bottomNavSurfaceStyle: surfaceStyles.bottomNav,
        forcedInsetSurfaceStyle: surfaceStyles.forcedInset,
      );
    }

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
      buttonSurfaceStyle: surfaceStyles.button,
      contentSurfaceStyle: surfaceStyles.content,
      bottomNavSurfaceStyle: surfaceStyles.bottomNav,
      forcedInsetSurfaceStyle: surfaceStyles.forcedInset,
    );
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

  static _SurfaceStyles _surfaceStyles(bool neumorphism) {
    return neumorphism
        ? const _SurfaceStyles(
            button: ExpenseSurfaceInteraction.raisedInset,
            content: ExpenseSurfaceInteraction.insetInset,
            bottomNav: ExpenseSurfaceInteraction.neutralInset,
            forcedInset: ExpenseSurfaceInteraction.insetInset,
          )
        : const _SurfaceStyles(
            button: ExpenseSurfaceInteraction.neutralNeutral,
            content: ExpenseSurfaceInteraction.neutralNeutral,
            bottomNav: ExpenseSurfaceInteraction.neutralNeutral,
            forcedInset: ExpenseSurfaceInteraction.neutralNeutral,
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

class _SurfaceStyles {
  const _SurfaceStyles({
    required this.button,
    required this.content,
    required this.bottomNav,
    required this.forcedInset,
  });

  final ExpenseSurfaceInteraction button;
  final ExpenseSurfaceInteraction content;
  final ExpenseSurfaceInteraction bottomNav;
  final ExpenseSurfaceInteraction forcedInset;
}
