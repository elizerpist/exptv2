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

  test('theme settings default to normal day turquoise profile', () {
    final settings = AppThemeSettings.defaults();

    expect(settings.designProfile, AppDesignProfile.normal);
    expect(settings.nightMode, AppNightMode.off);
    expect(settings.appColor, AppColorMode.turquoise);
    expect(settings.toMap()['designProfile'], 'normal');
    expect(settings.toMap()['nightMode'], 'off');
    expect(settings.toMap()['appColor'], 'turquoise');
  });

  test('legacy non-neutral surface values migrate to neumorphism profile', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'theme': 'Pink',
      'buttonSurfaceStyle': 'raisedInset',
      'contentSurfaceStyle': 'neutralNeutral',
    });

    expect(settings.designProfile, AppDesignProfile.neumorphism);
    expect(settings.nightMode, AppNightMode.off);
    expect(settings.appColor, AppColorMode.pink);
  });

  test('legacy dark theme migrates to night cyan', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'theme': 'Sötét',
    });

    expect(settings.designProfile, AppDesignProfile.normal);
    expect(settings.nightMode, AppNightMode.cyan);
    expect(settings.appColor, AppColorMode.turquoise);
  });
}
