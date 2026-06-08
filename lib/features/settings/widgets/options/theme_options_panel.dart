import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/app_theme_settings.dart';
import '../../../transactions/widgets/header_card/magnet_strip.dart';
import 'settings_option_widgets.dart';

class ThemeOptionsPanel extends StatelessWidget {
  const ThemeOptionsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppThemeSettings settings;
  final ValueChanged<AppThemeSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        key: const ValueKey('settings-theme-scroll'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle(
                'Mágnes típusa',
                'A mágnescsík megjelenési módja a főmenüben:',
              ),
              SettingsRadioOption(
                title:
                    'Átmenetes${settings.magnetType == MagnetType.fade ? ' (jelenlegi)' : ''}',
                description: 'Fokozatos átmenet a két szín között',
                selected: settings.magnetType == MagnetType.fade,
                onTap: () =>
                    onChanged(settings.copyWith(magnetType: MagnetType.fade)),
                preview: const _MagnetPreview(type: MagnetType.fade),
              ),
              SettingsRadioOption(
                title:
                    'Éles átmenet${settings.magnetType == MagnetType.nofade ? ' (jelenlegi)' : ''}',
                description: '100% teli csík -> 0% minimális csík',
                selected: settings.magnetType == MagnetType.nofade,
                onTap: () =>
                    onChanged(settings.copyWith(magnetType: MagnetType.nofade)),
                preview: const _MagnetPreview(type: MagnetType.nofade),
              ),
              SettingsRadioOption(
                title:
                    'Budget vizualizáció${settings.magnetType == MagnetType.budget ? ' (jelenlegi)' : ''}',
                description: 'Bal zöld, jobb piros a költségvetés alapján',
                selected: settings.magnetType == MagnetType.budget,
                onTap: () =>
                    onChanged(settings.copyWith(magnetType: MagnetType.budget)),
                preview: const _MagnetPreview(type: MagnetType.budget),
              ),
              SettingsRadioOption(
                title:
                    'Mágneskártya${settings.magnetType == MagnetType.magnetcard ? ' (jelenlegi)' : ''}',
                description:
                    'Felső és alsó keret, egyenes vonal az egyenleg színével',
                selected: settings.magnetType == MagnetType.magnetcard,
                onTap: () => onChanged(
                  settings.copyWith(magnetType: MagnetType.magnetcard),
                ),
                preview: const _MagnetPreview(type: MagnetType.magnetcard),
              ),
              SettingsRadioOption(
                title:
                    'Adaptív mágnescsík${settings.magnetType == MagnetType.adaptive ? ' (jelenlegi)' : ''}',
                description: 'Íves pill forma, türkiz színnel, dinamikus méret',
                selected: settings.magnetType == MagnetType.adaptive,
                onTap: () => onChanged(
                  settings.copyWith(magnetType: MagnetType.adaptive),
                ),
                preview: const _MagnetPreview(type: MagnetType.adaptive),
              ),
              _sectionTitle('Design profil', 'Az app interakciós stílusa:'),
              _profileOption(
                'Normál',
                'Eredeti app design, gyári tap visszajelzés',
                AppDesignProfile.normal,
              ),
              _profileOption(
                'Neumorphism',
                '3D felületek, shadow-only tap animáció',
                AppDesignProfile.neumorphism,
              ),
              _sectionTitle('App színe', 'Nappali módban használt fő szín:'),
              _appColorOption(
                'Türkiz',
                'Jelenlegi türkiz appszín',
                AppColorMode.turquoise,
                AppColors.primary,
              ),
              _appColorOption(
                'Pink',
                'Pink appszín nappali módhoz',
                AppColorMode.pink,
                const Color(0xFFEC4899),
              ),
              _sectionTitle('Kártya színe', 'A főmenü kártya háttérszíne:'),
              _cardOption(
                'Fehér',
                'Tiszta fehér háttér',
                AppCardColor.white,
                AppColors.white,
              ),
              _cardOption(
                'Világosszürke',
                'Jelenlegi alapértelmezett szín',
                AppCardColor.lightgray,
                AppColors.gray100,
              ),
              _cardOption(
                'Sötétebb szürke',
                'Élénkebb kontrasztú háttér',
                AppCardColor.darkgray,
                AppColors.gray200,
              ),
              _sectionTitle('Háttér színe', 'Az alkalmazás háttérszíne:'),
              _backgroundOption(
                'Fehér',
                'Tiszta fehér alkalmazás háttér',
                AppBackgroundColor.white,
                AppColors.white,
              ),
              _backgroundOption(
                'Szürke',
                'Világosszürke alkalmazás háttér',
                AppBackgroundColor.gray,
                AppColors.gray100,
              ),
              _backgroundOption(
                'Sötétebb szürke háttér',
                'Erősebb szürke alkalmazás háttér',
                AppBackgroundColor.darkgray,
                AppColors.gray200,
              ),
              _sectionTitle(
                'Box színek',
                'Tranzakció logbox, kereső és összesítő pill kitöltőszíne:',
              ),
              _boxOption(
                'Fehér',
                'Fehér logbox háttér',
                AppBoxColor.white,
                AppColors.white,
              ),
              _boxOption(
                'Szürke',
                'Szürke logbox háttér',
                AppBoxColor.gray,
                AppColors.gray100,
              ),
              _boxOption(
                'Sötétebb szürke box',
                'Erősebb szürke logbox háttér',
                AppBoxColor.darkgray,
                AppColors.gray200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }

  Widget _profileOption(
    String title,
    String description,
    AppDesignProfile value,
  ) {
    return SettingsRadioOption(
      title: '$title${settings.designProfile == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.designProfile == value,
      onTap: () => onChanged(_withDesignProfile(value)),
      preview: _SurfacePreview(
        style: value == AppDesignProfile.neumorphism
            ? ExpenseSurfaceInteraction.raisedInset
            : ExpenseSurfaceInteraction.neutralNeutral,
      ),
    );
  }

  Widget _appColorOption(
    String title,
    String description,
    AppColorMode value,
    Color color,
  ) {
    return SettingsRadioOption(
      title: '$title${settings.appColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.appColor == value,
      onTap: () => onChanged(_withAppColor(value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _cardOption(
    String title,
    String description,
    AppCardColor value,
    Color color,
  ) {
    return SettingsRadioOption(
      title: '$title${settings.cardColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.cardColor == value,
      onTap: () => onChanged(settings.copyWith(cardColor: value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _backgroundOption(
    String title,
    String description,
    AppBackgroundColor value,
    Color color,
  ) {
    return SettingsRadioOption(
      title: '$title${settings.backgroundColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.backgroundColor == value,
      onTap: () => onChanged(settings.copyWith(backgroundColor: value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _boxOption(
    String title,
    String description,
    AppBoxColor value,
    Color color,
  ) {
    return SettingsRadioOption(
      title: '$title${settings.boxColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.boxColor == value,
      onTap: () => onChanged(settings.copyWith(boxColor: value)),
      preview: _ColorPreview(color: color),
    );
  }

  AppThemeSettings _withDesignProfile(AppDesignProfile value) {
    final neumorphism = value == AppDesignProfile.neumorphism;
    return settings.copyWith(
      designProfile: value,
      buttonSurfaceStyle: neumorphism
          ? ExpenseSurfaceInteraction.raisedInset
          : ExpenseSurfaceInteraction.neutralNeutral,
      contentSurfaceStyle: neumorphism
          ? ExpenseSurfaceInteraction.insetInset
          : ExpenseSurfaceInteraction.neutralNeutral,
    );
  }

  AppThemeSettings _withAppColor(AppColorMode value) {
    return settings.copyWith(
      appColor: value,
      theme: _legacyThemeForAppColor(value),
    );
  }

  AppTheme _legacyThemeForAppColor(AppColorMode value) {
    return value == AppColorMode.pink ? AppTheme.pink : AppTheme.turquoise;
  }
}

class _ColorPreview extends StatelessWidget {
  const _ColorPreview({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
    );
  }
}

class _MagnetPreview extends StatelessWidget {
  const _MagnetPreview({required this.type});
  final MagnetType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 24,
      child: MagnetStrip(
        type: type,
        totalIncome: 60,
        totalExpense: 40,
        height: 24,
      ),
    );
  }
}

class _SurfacePreview extends StatelessWidget {
  const _SurfacePreview({required this.style});

  final ExpenseSurfaceInteraction style;

  @override
  Widget build(BuildContext context) {
    final pressed =
        style == ExpenseSurfaceInteraction.neutralInset ||
        style == ExpenseSurfaceInteraction.insetInset;
    return ExpensePressable(
      enabled: false,
      forcePressed: pressed,
      builder: (context, isPressed) {
        return ExpenseSurfaceContainer(
          style: style,
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          pressed: isPressed,
          neutralBorder: Border.all(color: AppColors.gray200),
          width: 42,
          height: 30,
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
