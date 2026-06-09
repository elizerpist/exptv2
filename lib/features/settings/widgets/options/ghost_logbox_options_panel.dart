import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/app_theme_settings.dart';
import 'settings_option_widgets.dart';

class GhostLogboxOptionsPanel extends StatelessWidget {
  const GhostLogboxOptionsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppThemeSettings settings;
  final ValueChanged<AppThemeSettings> onChanged;

  GhostLogboxSettings get _ghost => settings.ghostLogboxSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        key: const ValueKey('settings-ghost-logbox-scroll'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Felület', 'A ghost logbox saját felületi stílusa:'),
              _surfaceOption('Normál', ExpenseSurfaceInteraction.neutralNeutral),
              _surfaceOption('Neumorph', ExpenseSurfaceInteraction.insetInset),
              _sectionTitle('Szegély', 'A ghost sor körvonala:'),
              _borderOption('Normál', GhostLogboxBorderStyle.normal),
              _borderOption('Szaggatott', GhostLogboxBorderStyle.dashed),
              _switchOption(
                key: const ValueKey('ghost-logbox-background-opacity'),
                title: 'Háttér halványítás',
                value: _ghost.backgroundOpacityEnabled,
                onChanged: (value) => _copyGhost(
                  backgroundOpacityEnabled: value,
                ),
              ),
              _switchOption(
                key: const ValueKey('ghost-logbox-avatar-opacity'),
                title: 'Avatar halványítás',
                value: _ghost.avatarOpacityEnabled,
                onChanged: (value) => _copyGhost(avatarOpacityEnabled: value),
              ),
              _switchOption(
                key: const ValueKey('ghost-logbox-text-opacity'),
                title: 'Szöveg halványítás',
                value: _ghost.textOpacityEnabled,
                onChanged: (value) => _copyGhost(textOpacityEnabled: value),
              ),
              _switchOption(
                key: const ValueKey('ghost-logbox-avatar-badge'),
                title: 'Avatar badge',
                value: _ghost.avatarBadgeEnabled,
                onChanged: (value) => _copyGhost(avatarBadgeEnabled: value),
              ),
              _sectionTitle('Szöveg tónusa', 'A név és összeg tónusa:'),
              _textToneOption('Normál', GhostLogboxTextTone.normal),
              _textToneOption('Szürke', GhostLogboxTextTone.gray),
              _switchOption(
                key: const ValueKey('ghost-logbox-expected-label'),
                title: 'Várható felirat',
                value: _ghost.expectedLabelEnabled,
                onChanged: (value) => _copyGhost(expectedLabelEnabled: value),
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

  Widget _surfaceOption(String title, ExpenseSurfaceInteraction style) {
    final selected = settings.ghostLogboxSurfaceStyle == style;
    return SettingsRadioOption(
      key: ValueKey('ghost-logbox-surface-${style.nativeValue}'),
      title: '$title${selected ? ' (jelenlegi)' : ''}',
      description: style == ExpenseSurfaceInteraction.insetInset
          ? 'Befelé mélyített ghost logbox felület'
          : 'Eredeti sík ghost logbox felület',
      selected: selected,
      onTap: () => onChanged(
        settings.copyWith(ghostLogboxSurfaceStyle: style),
      ),
    );
  }

  Widget _borderOption(String title, GhostLogboxBorderStyle style) {
    final selected = _ghost.borderStyle == style;
    return SettingsRadioOption(
      key: ValueKey('ghost-logbox-border-${style.nativeValue}'),
      title: '$title${selected ? ' (jelenlegi)' : ''}',
      description: style == GhostLogboxBorderStyle.dashed
          ? 'Szaggatott körvonal a várható sorokhoz'
          : 'Normál folytonos körvonal',
      selected: selected,
      onTap: () => _copyGhost(borderStyle: style),
    );
  }

  Widget _textToneOption(String title, GhostLogboxTextTone tone) {
    final selected = _ghost.textTone == tone;
    return SettingsRadioOption(
      key: ValueKey('ghost-logbox-text-${tone.nativeValue}'),
      title: '$title${selected ? ' (jelenlegi)' : ''}',
      description: tone == GhostLogboxTextTone.gray
          ? 'Szürkébb név és összeg'
          : 'A normál tranzakció szövegtónusa',
      selected: selected,
      onTap: () => _copyGhost(textTone: tone),
    );
  }

  Widget _switchOption({
    required ValueKey<String> key,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      key: key,
      title: Text(
        title,
        style: const TextStyle(color: AppColors.gray800),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _copyGhost({
    GhostLogboxBorderStyle? borderStyle,
    bool? backgroundOpacityEnabled,
    bool? avatarOpacityEnabled,
    bool? textOpacityEnabled,
    bool? avatarBadgeEnabled,
    GhostLogboxTextTone? textTone,
    bool? expectedLabelEnabled,
  }) {
    onChanged(
      settings.copyWith(
        ghostLogboxSettings: _ghost.copyWith(
          borderStyle: borderStyle,
          backgroundOpacityEnabled: backgroundOpacityEnabled,
          avatarOpacityEnabled: avatarOpacityEnabled,
          textOpacityEnabled: textOpacityEnabled,
          avatarBadgeEnabled: avatarBadgeEnabled,
          textTone: textTone,
          expectedLabelEnabled: expectedLabelEnabled,
        ),
      ),
    );
  }
}
