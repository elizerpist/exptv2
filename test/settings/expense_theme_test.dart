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

  test('resolves colors and ignores legacy surface overrides in normal profile', () {
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
    expect(theme.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
    expect(theme.contentSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
    expect(settings.toMap()['buttonSurfaceStyle'], 'raisedInset');
    expect(settings.toMap()['contentSurfaceStyle'], 'neutralInset');
  });

  test('resolves primary accent from app color and legacy migration', () {
    expect(
      ExpenseTheme.fromSettings(
        AppThemeSettings.defaults().copyWith(appColor: AppColorMode.pink),
      ).accent,
      const Color(0xFFEC4899),
    );
    expect(
      ExpenseTheme.fromSettings(
        AppThemeSettings.fromMap(const <String, Object?>{'theme': 'Pink'}),
      ).accent,
      const Color(0xFFEC4899),
    );
    expect(
      ExpenseTheme.fromSettings(
        AppThemeSettings.fromMap(const <String, Object?>{'theme': 'Sötét'}),
      ).accent,
      const Color(0xFF19BFDC),
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

  test('pink day mode resolves pink accent family', () {
    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(appColor: AppColorMode.pink),
    );

    expect(theme.accent, const Color(0xFFEC4899));
    expect(theme.accentDark, const Color(0xFFBE185D));
    expect(theme.accentLight, const Color(0xFFF9A8D4));
    expect(theme.activeBackground, const Color(0x15EC4899));
  });

  test('night palettes ignore day app color', () {
    final cyan = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        appColor: AppColorMode.pink,
        nightMode: AppNightMode.cyan,
      ),
    );
    final amber = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        appColor: AppColorMode.pink,
        nightMode: AppNightMode.amber,
      ),
    );

    expect(cyan.isNight, isTrue);
    expect(cyan.accent, const Color(0xFF19BFDC));
    expect(cyan.appBackground, const Color(0xFF0B1420));
    expect(cyan.logBox, const Color(0xFF152231));
    expect(amber.accent, const Color(0xFFF0A646));
    expect(amber.appBackground, const Color(0xFF15120F));
    expect(amber.logBox, const Color(0xFF231D17));
  });

  test('profile resolves component surface roles', () {
    final normal = ExpenseTheme.fromSettings(AppThemeSettings.defaults());
    final neu = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        designProfile: AppDesignProfile.neumorphism,
      ),
    );

    expect(normal.contentSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
    expect(normal.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
    expect(
      normal.bottomNavSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(neu.contentSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
    expect(neu.buttonSurfaceStyle, ExpenseSurfaceInteraction.raisedInset);
    expect(neu.bottomNavSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(neu.forcedInsetSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
  });
}
