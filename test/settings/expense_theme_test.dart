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

  test('resolves colors alongside component surface overrides', () {
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
    expect(theme.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
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
      AppColors.primary,
    );
  });

  test('theme settings default to explicit normal component surfaces', () {
    final settings = AppThemeSettings.defaults();

    expect(
      settings.buttonSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(
      settings.contentSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(
      settings.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(settings.toMap().containsKey('designProfile'), isFalse);
    expect(settings.toMap()['ghostLogboxSurfaceStyle'], 'neutralNeutral');
    expect(
      settings.ghostLogboxSettings.borderStyle,
      GhostLogboxBorderStyle.dashed,
    );
    expect(settings.ghostLogboxSettings.avatarBadgeEnabled, isTrue);
    expect(settings.ghostLogboxSettings.expectedLabelEnabled, isTrue);
  });

  test('legacy neumorphism profile migrates to component surfaces', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'designProfile': 'neumorphism',
    });

    expect(settings.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(
      settings.contentSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(
      settings.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
  });

  test('explicit component surfaces override legacy design profile', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'designProfile': 'neumorphism',
      'buttonSurfaceStyle': 'neutralNeutral',
      'contentSurfaceStyle': 'neutralNeutral',
      'ghostLogboxSurfaceStyle': 'neutralNeutral',
    });

    expect(
      settings.buttonSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(
      settings.contentSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(
      settings.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
  });

  test('ghost logbox settings parse and serialize visual controls', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'ghostLogboxSettings': <String, Object?>{
        'borderStyle': 'normal',
        'backgroundOpacityEnabled': false,
        'avatarOpacityEnabled': true,
        'textOpacityEnabled': true,
        'avatarBadgeEnabled': false,
        'textTone': 'gray',
        'expectedLabelEnabled': false,
      },
    });

    expect(
      settings.ghostLogboxSettings.borderStyle,
      GhostLogboxBorderStyle.normal,
    );
    expect(settings.ghostLogboxSettings.backgroundOpacityEnabled, isFalse);
    expect(settings.ghostLogboxSettings.avatarOpacityEnabled, isTrue);
    expect(settings.ghostLogboxSettings.textOpacityEnabled, isTrue);
    expect(settings.ghostLogboxSettings.avatarBadgeEnabled, isFalse);
    expect(settings.ghostLogboxSettings.textTone, GhostLogboxTextTone.gray);
    expect(settings.ghostLogboxSettings.expectedLabelEnabled, isFalse);
    expect(settings.ghostLogboxSettings.toMap(), <String, Object?>{
      'borderStyle': 'normal',
      'backgroundOpacityEnabled': false,
      'avatarOpacityEnabled': true,
      'textOpacityEnabled': true,
      'avatarBadgeEnabled': false,
      'textTone': 'gray',
      'expectedLabelEnabled': false,
    });
  });

  test('legacy dark theme no longer enables night palette', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'theme': 'Sötét',
      'nightMode': 'amber',
    });
    final theme = ExpenseTheme.fromSettings(settings);

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

  test('component surfaces resolve independently', () {
    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        buttonSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
        contentSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
        ghostLogboxSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
      ),
    );

    expect(theme.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(theme.contentSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
    expect(
      theme.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.neutralNeutral,
    );
    expect(theme.bottomNavSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
  });

  test(
    'legacy design profile getter reflects component surface compatibility only',
    () {
      final neumorph = AppThemeSettings.defaults().copyWith(
        buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
        contentSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
        ghostLogboxSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
      );
      final normal = AppThemeSettings.defaults();

      expect(neumorph.designProfile, AppDesignProfile.neumorphism);
      expect(normal.designProfile, AppDesignProfile.normal);
      expect(neumorph.toMap().containsKey('designProfile'), isFalse);
    },
  );

  test('button neutral inset can be selected independently', () {
    final settings = AppThemeSettings.defaults().copyWith(
      buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
      contentSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
    );
    final theme = ExpenseTheme.fromSettings(settings);

    expect(settings.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(theme.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(theme.bottomNavSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(settings.toMap()['buttonSurfaceStyle'], 'neutralInset');
  });

  test('component surface settings copy independently', () {
    final settings = AppThemeSettings.defaults().copyWith(
      buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
      contentSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
      ghostLogboxSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
      categoryCardSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
      categoryMenuColor: AppBoxColor.darkgray,
      categoryCardColor: AppBoxColor.white,
    );

    expect(settings.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(settings.contentSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
    expect(
      settings.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.neutralInset,
    );
    expect(settings.toMap()['buttonSurfaceStyle'], 'neutralInset');
    expect(settings.toMap()['contentSurfaceStyle'], 'insetInset');
    expect(settings.toMap()['ghostLogboxSurfaceStyle'], 'neutralInset');
    expect(settings.toMap().containsKey('categoryMenuSurfaceStyle'), isFalse);
    expect(settings.toMap()['categoryCardSurfaceStyle'], 'raisedInset');
    expect(settings.toMap()['categoryMenuColor'], 'gray');
    expect(settings.toMap()['categoryCardColor'], 'white');
  });

  test('obsolete category presentation and shadow toggles are ignored', () {
    final defaults = AppThemeSettings.defaults();
    expect(defaults.toMap().containsKey('categoryMenuPresentation'), isFalse);
    expect(defaults.toMap().containsKey('categoryCardShadowEnabled'), isFalse);
    expect(defaults.toMap().containsKey('logboxShadowEnabled'), isFalse);
    expect(defaults.toMap().containsKey('headerPillShadowEnabled'), isFalse);
    expect(defaults.toMap().containsKey('summaryPillShadowEnabled'), isFalse);
    expect(defaults.toMap().containsKey('searchPillShadowEnabled'), isFalse);

    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'categoryMenuPresentation': 'slideUpSheet',
      'categoryCardShadowEnabled': false,
      'logboxShadowEnabled': false,
      'headerPillShadowEnabled': false,
      'summaryPillShadowEnabled': false,
      'searchPillShadowEnabled': false,
    });

    expect(settings.toMap().containsKey('categoryMenuPresentation'), isFalse);
    expect(settings.toMap().containsKey('categoryCardShadowEnabled'), isFalse);
    expect(settings.toMap().containsKey('logboxShadowEnabled'), isFalse);
    expect(settings.toMap().containsKey('headerPillShadowEnabled'), isFalse);
    expect(settings.toMap().containsKey('summaryPillShadowEnabled'), isFalse);
    expect(settings.toMap().containsKey('searchPillShadowEnabled'), isFalse);
  });

  test('shell navigation and fab shape are no longer theme settings', () {
    final defaults = AppThemeSettings.defaults();
    expect(defaults.toMap().containsKey('shellNavigationLayout'), isFalse);
    expect(defaults.toMap().containsKey('fabShape'), isFalse);

    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'shellNavigationLayout': 'current',
      'fabShape': 'roundedSquare',
      'fabSize': 80,
    });

    expect(settings.toMap().containsKey('shellNavigationLayout'), isFalse);
    expect(settings.toMap().containsKey('fabShape'), isFalse);
    expect(settings.fabSize, 80);
  });

  test('fab size parses, serializes, clamps, and copies', () {
    final defaults = AppThemeSettings.defaults();
    expect(defaults.fabSize, 66);
    expect(defaults.toMap()['fabSize'], 66);

    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'fabSize': 80,
    });

    expect(settings.fabSize, 80);
    expect(settings.toMap()['fabSize'], 80);
    expect(
      AppThemeSettings.fromMap(const <String, Object?>{'fabSize': 999}).fabSize,
      88,
    );
    expect(
      AppThemeSettings.fromMap(const <String, Object?>{'fabSize': 1}).fabSize,
      52,
    );
    expect(settings.copyWith(fabSize: 72).fabSize, 72);
  });

  test('stats month card color parses serializes copies and resolves', () {
    final defaults = AppThemeSettings.defaults();
    expect(defaults.statsMonthCardColor, AppBoxColor.white);
    expect(defaults.toMap()['statsMonthCardColor'], 'white');

    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'statsMonthCardColor': 'darkgray',
    });

    expect(settings.statsMonthCardColor, AppBoxColor.darkgray);
    expect(settings.toMap()['statsMonthCardColor'], 'darkgray');
    expect(
      settings
          .copyWith(statsMonthCardColor: AppBoxColor.gray)
          .statsMonthCardColor,
      AppBoxColor.gray,
    );
    expect(
      ExpenseTheme.fromSettings(settings).statsMonthCard,
      AppColors.gray200,
    );
    expect(
      ExpenseTheme.fromSettings(
        settings.copyWith(statsMonthCardColor: AppBoxColor.gray),
      ).statsMonthCard,
      AppColors.gray100,
    );
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
