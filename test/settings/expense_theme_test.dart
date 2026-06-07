import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves original card and box colors', () {
    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        cardColor: AppCardColor.darkgray,
        backgroundColor: AppBackgroundColor.white,
        boxColor: AppBoxColor.gray,
      ),
    );

    expect(theme.headerCard, AppColors.gray200);
    expect(theme.appBackground, AppColors.white);
    expect(theme.logBox, AppColors.gray100);
  });

  test('resolves all selectable surface colors and interaction styles', () {
    final settings = AppThemeSettings.defaults().copyWith(
      cardColor: AppCardColor.darkgray,
      backgroundColor: AppBackgroundColor.darkgray,
      boxColor: AppBoxColor.darkgray,
      buttonSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
      contentSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
    );
    final theme = ExpenseTheme.fromSettings(settings);

    expect(theme.headerCard, AppColors.gray200);
    expect(theme.appBackground, AppColors.gray200);
    expect(theme.logBox, AppColors.gray200);
    expect(theme.buttonSurfaceStyle, ExpenseSurfaceInteraction.raisedInset);
    expect(theme.contentSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(settings.toMap()['buttonSurfaceStyle'], 'raisedInset');
    expect(settings.toMap()['contentSurfaceStyle'], 'neutralInset');
  });

  test('resolves primary accent from selected theme', () {
    expect(
      ExpenseTheme.fromSettings(
        AppThemeSettings.defaults().copyWith(theme: AppTheme.pink),
      ).accent,
      const Color(0xFFEC4899),
    );
    expect(
      ExpenseTheme.fromSettings(
        AppThemeSettings.defaults().copyWith(theme: AppTheme.dark),
      ).accent,
      const Color(0xFF1F2937),
    );
  });
}
