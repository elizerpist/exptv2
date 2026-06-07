import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/app_theme_settings.dart';

class ExpenseTheme {
  const ExpenseTheme({
    required this.settings,
    required this.accent,
    required this.headerCard,
    required this.appBackground,
    required this.logBox,
    required this.buttonSurfaceStyle,
    required this.contentSurfaceStyle,
  });

  final AppThemeSettings settings;
  final Color accent;
  final Color headerCard;
  final Color appBackground;
  final Color logBox;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ExpenseSurfaceInteraction contentSurfaceStyle;

  factory ExpenseTheme.fromSettings(AppThemeSettings settings) {
    return ExpenseTheme(
      settings: settings,
      accent: switch (settings.theme) {
        AppTheme.pink => const Color(0xFFEC4899),
        AppTheme.turquoise => AppColors.primary,
        AppTheme.dark => const Color(0xFF1F2937),
      },
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
      buttonSurfaceStyle: settings.buttonSurfaceStyle,
      contentSurfaceStyle: settings.contentSurfaceStyle,
    );
  }
}
