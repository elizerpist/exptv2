import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/app_theme_settings.dart';
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _sectionTitle('Mágnes típusa', 'A mágnescsík megjelenési módja a főmenüben:'),
        SettingsRadioOption(
          title: 'Átmenetes${settings.magnetType == MagnetType.fade ? ' (jelenlegi)' : ''}',
          description: 'Fokozatos átmenet a két szín között',
          selected: settings.magnetType == MagnetType.fade,
          onTap: () => onChanged(settings.copyWith(magnetType: MagnetType.fade)),
          preview: const _MagnetPreview(type: MagnetType.fade),
        ),
        SettingsRadioOption(
          title: 'Éles átmenet${settings.magnetType == MagnetType.nofade ? ' (jelenlegi)' : ''}',
          description: '100% teli csík -> 0% minimális csík',
          selected: settings.magnetType == MagnetType.nofade,
          onTap: () => onChanged(settings.copyWith(magnetType: MagnetType.nofade)),
          preview: const _MagnetPreview(type: MagnetType.nofade),
        ),
        SettingsRadioOption(
          title: 'Budget vizualizáció${settings.magnetType == MagnetType.budget ? ' (jelenlegi)' : ''}',
          description: 'Bal zöld, jobb piros a költségvetés alapján',
          selected: settings.magnetType == MagnetType.budget,
          onTap: () => onChanged(settings.copyWith(magnetType: MagnetType.budget)),
          preview: const _MagnetPreview(type: MagnetType.budget),
        ),
        SettingsRadioOption(
          title: 'Mágneskártya${settings.magnetType == MagnetType.magnetcard ? ' (jelenlegi)' : ''}',
          description: 'Felső és alsó keret, egyenes vonal az egyenleg színével',
          selected: settings.magnetType == MagnetType.magnetcard,
          onTap: () => onChanged(settings.copyWith(magnetType: MagnetType.magnetcard)),
          preview: const _MagnetPreview(type: MagnetType.magnetcard),
        ),
        SettingsRadioOption(
          title: 'Adaptív mágnescsík${settings.magnetType == MagnetType.adaptive ? ' (jelenlegi)' : ''}',
          description: 'Íves pill forma, türkiz színnel, dinamikus méret',
          selected: settings.magnetType == MagnetType.adaptive,
          onTap: () => onChanged(settings.copyWith(magnetType: MagnetType.adaptive)),
          preview: const _MagnetPreview(type: MagnetType.adaptive),
        ),
        _sectionTitle('Témaszín', 'Az alkalmazás fő színe:'),
        _colorOption('Pink', 'Elegáns rózsaszín színvilág', AppTheme.pink, const Color(0xFFEC4899)),
        _colorOption('Türkiz', 'Jelenlegi alapértelmezett téma', AppTheme.turquoise, AppColors.primary),
        _colorOption('Sötét üzemmód', 'Szemkímélő sötét háttér', AppTheme.dark, const Color(0xFF1F2937)),
        _sectionTitle('Kártya színe', 'A főmenü kártya háttérszíne:'),
        _cardOption('Fehér', 'Tiszta fehér háttér', AppCardColor.white, AppColors.white),
        _cardOption('Világosszürke', 'Jelenlegi alapértelmezett szín', AppCardColor.lightgray, AppColors.gray100),
        _cardOption('Sötétebb szürke', 'Élénkebb kontrasztú háttér', AppCardColor.darkgray, AppColors.gray200),
        _sectionTitle('Háttér színe', 'Az alkalmazás háttérszíne:'),
        _backgroundOption('Fehér', 'Tiszta fehér alkalmazás háttér', AppBackgroundColor.white, AppColors.white),
        _backgroundOption('Szürke', 'Világosszürke alkalmazás háttér', AppBackgroundColor.gray, AppColors.gray100),
        _sectionTitle('Box színek', 'Tranzakció és értesítés logbox-ok kitöltőszíne:'),
        _boxOption('Fehér', 'Fehér logbox háttér', AppBoxColor.white, AppColors.white),
        _boxOption('Szürke', 'Szürke logbox háttér', AppBoxColor.gray, AppColors.gray100),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
        ],
      ),
    );
  }

  Widget _colorOption(String title, String description, AppTheme value, Color color) {
    return SettingsRadioOption(
      title: '$title${settings.theme == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.theme == value,
      onTap: () => onChanged(settings.copyWith(theme: value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _cardOption(String title, String description, AppCardColor value, Color color) {
    return SettingsRadioOption(
      title: '$title${settings.cardColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.cardColor == value,
      onTap: () => onChanged(settings.copyWith(cardColor: value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _backgroundOption(String title, String description, AppBackgroundColor value, Color color) {
    return SettingsRadioOption(
      title: '$title${settings.backgroundColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.backgroundColor == value,
      onTap: () => onChanged(settings.copyWith(backgroundColor: value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _boxOption(String title, String description, AppBoxColor value, Color color) {
    return SettingsRadioOption(
      title: '$title${settings.boxColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.boxColor == value,
      onTap: () => onChanged(settings.copyWith(boxColor: value)),
      preview: _ColorPreview(color: color),
    );
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
    return CustomPaint(
      size: const Size(62, 24),
      painter: _MagnetPreviewPainter(type),
    );
  }
}

class _MagnetPreviewPainter extends CustomPainter {
  _MagnetPreviewPainter(this.type);
  final MagnetType type;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(8));
    if (type == MagnetType.magnetcard) {
      final paint = Paint()
        ..color = AppColors.gray800.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawLine(Offset(4, 7), Offset(size.width - 4, 7), paint);
      canvas.drawLine(Offset(4, size.height - 7), Offset(size.width - 4, size.height - 7), paint);
      canvas.drawLine(Offset(size.width * 0.35, 7), Offset(size.width * 0.35, size.height - 7), paint);
      return;
    }
    final shader = switch (type) {
      MagnetType.budget => const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFFDC2626)]).createShader(rect),
      MagnetType.adaptive => const LinearGradient(colors: [AppColors.white, AppColors.primary]).createShader(rect),
      MagnetType.nofade => const LinearGradient(colors: [Color(0x4D2C2C2C), Color(0x4D2C2C2C), Color(0x0D2C2C2C)]).createShader(rect),
      MagnetType.fade => const LinearGradient(colors: [Color(0x4D2C2C2C), Color(0x0D2C2C2C)]).createShader(rect),
      MagnetType.magnetcard => null,
    };
    canvas.drawRRect(base, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _MagnetPreviewPainter oldDelegate) => oldDelegate.type != type;
}
