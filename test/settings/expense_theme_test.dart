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

  test(
    'resolves colors and ignores legacy surface overrides in normal profile',
    () {
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
      expect(
        theme.buttonSurfaceStyle,
        ExpenseSurfaceInteraction.neutralNeutral,
      );
      expect(
        theme.contentSurfaceStyle,
        ExpenseSurfaceInteraction.neutralNeutral,
      );
      expect(settings.toMap()['buttonSurfaceStyle'], 'raisedInset');
      expect(settings.toMap()['contentSurfaceStyle'], 'neutralInset');
    },
  );

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
      AppColors.primary,
    );
  });

  test('theme settings default to normal day turquoise profile', () {
    final settings = AppThemeSettings.defaults();

    expect(settings.designProfile, AppDesignProfile.normal);
    expect(settings.appColor, AppColorMode.turquoise);
    expect(settings.toMap()['designProfile'], 'normal');
    expect(settings.toMap().containsKey('nightMode'), isFalse);
    expect(settings.toMap()['appColor'], 'turquoise');
  });

  test('legacy non-neutral surface values migrate to neumorphism profile', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'theme': 'Pink',
      'buttonSurfaceStyle': 'raisedInset',
      'contentSurfaceStyle': 'neutralNeutral',
    });

    expect(settings.designProfile, AppDesignProfile.neumorphism);
    expect(settings.appColor, AppColorMode.pink);
  });

  test('legacy dark theme no longer enables night palette', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'theme': 'Sötét',
      'nightMode': 'amber',
    });
    final theme = ExpenseTheme.fromSettings(settings);

    expect(settings.designProfile, AppDesignProfile.normal);
    expect(settings.theme, AppTheme.turquoise);
    expect(settings.appColor, AppColorMode.turquoise);
    expect(settings.toMap()['theme'], 'Türkiz');
    expect(settings.toMap().containsKey('nightMode'), isFalse);
    expect(theme.accent, AppColors.primary);
    expect(theme.appBackground, AppColors.gray100);
    expect(theme.logBox, AppColors.gray100);
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

  test('unknown legacy night mode values do not affect day palette', () {
    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.fromMap(const <String, Object?>{
        'appColor': 'pink',
        'nightMode': 'amber',
      }),
    );

    expect(theme.accent, const Color(0xFFEC4899));
    expect(theme.appBackground, AppColors.gray100);
    expect(theme.logBox, AppColors.gray100);
  });

  test('profile resolves component surface roles', () {
    final normal = ExpenseTheme.fromSettings(AppThemeSettings.defaults());
    final neu = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        designProfile: AppDesignProfile.neumorphism,
      ),
    );

    expect(
      normal.contentSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
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

  test('accent helpers resolve active background for all palettes', () {
    final turquoise = ExpenseTheme.fromSettings(AppThemeSettings.defaults());
    final pink = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(appColor: AppColorMode.pink),
    );

    expect(turquoise.resolvePrimary(AppColors.primary), AppColors.primary);
    expect(pink.resolvePrimary(AppColors.primary), pink.accent);
    expect(
      pink.resolvePrimary(AppColors.primaryActiveBackground),
      pink.activeBackground,
    );
  });
}
