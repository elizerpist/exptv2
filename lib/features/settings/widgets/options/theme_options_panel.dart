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
                    'Partitioned budget mágnescsík${settings.magnetType == MagnetType.partitionedBudget ? ' (jelenlegi)' : ''}',
                description:
                    'Budget partition szegmensek az eredeti mágnescsík formában',
                selected: settings.magnetType == MagnetType.partitionedBudget,
                onTap: () => onChanged(
                  settings.copyWith(magnetType: MagnetType.partitionedBudget),
                ),
                preview: const _MagnetPreview(
                  type: MagnetType.partitionedBudget,
                ),
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
              _sectionTitle(
                'Gombok felülete',
                'A gombok és ikon gombok nyomási stílusa:',
              ),
              _surfaceOption(
                key: const ValueKey('theme-button-surface-normal'),
                title: 'Normál',
                description: 'Eredeti sík gombfelület',
                selected:
                    settings.buttonSurfaceStyle ==
                    ExpenseSurfaceInteraction.neutralNeutral,
                previewStyle: ExpenseSurfaceInteraction.neutralNeutral,
                onTap: () => onChanged(
                  settings.copyWith(
                    buttonSurfaceStyle:
                        ExpenseSurfaceInteraction.neutralNeutral,
                  ),
                ),
              ),
              _surfaceOption(
                key: const ValueKey('theme-button-surface-neutral-inset'),
                title: 'Neutrális-befelé',
                description: 'Sík gomb, érintéskor benyomott hatással',
                selected:
                    settings.buttonSurfaceStyle ==
                    ExpenseSurfaceInteraction.neutralInset,
                previewStyle: ExpenseSurfaceInteraction.neutralInset,
                onTap: () => onChanged(
                  settings.copyWith(
                    buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
                  ),
                ),
              ),
              _surfaceOption(
                key: const ValueKey('theme-button-surface-neumorph'),
                title: 'Neumorph',
                description:
                    'Kiemelt gombfelület benyomott érintési állapottal',
                selected:
                    settings.buttonSurfaceStyle ==
                    ExpenseSurfaceInteraction.raisedInset,
                previewStyle: ExpenseSurfaceInteraction.raisedInset,
                onTap: () => onChanged(
                  settings.copyWith(
                    buttonSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
                  ),
                ),
              ),
              _sectionTitle(
                'Logboxok felülete',
                'A tartalmi kártyák és tranzakció logboxok stílusa:',
              ),
              _surfaceOption(
                key: const ValueKey('theme-logbox-surface-normal'),
                title: 'Normál',
                description: 'Eredeti sík logbox felület',
                selected:
                    settings.contentSurfaceStyle ==
                    ExpenseSurfaceInteraction.neutralNeutral,
                previewStyle: ExpenseSurfaceInteraction.neutralNeutral,
                onTap: () => onChanged(
                  settings.copyWith(
                    contentSurfaceStyle:
                        ExpenseSurfaceInteraction.neutralNeutral,
                  ),
                ),
              ),
              _surfaceOption(
                key: const ValueKey('theme-logbox-surface-neumorph'),
                title: 'Neumorph',
                description: 'Befelé mélyített logbox felület',
                selected:
                    settings.contentSurfaceStyle ==
                    ExpenseSurfaceInteraction.insetInset,
                previewStyle: ExpenseSurfaceInteraction.insetInset,
                onTap: () => onChanged(
                  settings.copyWith(
                    contentSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
                  ),
                ),
              ),
              _sectionTitle(
                'Kategória menü mód',
                'A kategória választó megnyitási módja:',
              ),
              SettingsRadioOption(
                key: const ValueKey('theme-category-menu-presentation-inline'),
                title:
                    'Inline${settings.categoryMenuPresentation == CategoryMenuPresentation.inline ? ' (jelenlegi)' : ''}',
                description: 'A jelenlegi beúszó overlay a főképernyőn',
                selected:
                    settings.categoryMenuPresentation ==
                    CategoryMenuPresentation.inline,
                onTap: () => onChanged(
                  settings.copyWith(
                    categoryMenuPresentation: CategoryMenuPresentation.inline,
                  ),
                ),
                preview: const Icon(
                  Icons.vertical_align_top_rounded,
                  color: AppColors.gray500,
                ),
              ),
              SettingsRadioOption(
                key: const ValueKey('theme-category-menu-presentation-slide'),
                title:
                    'Slide-up sheet${settings.categoryMenuPresentation == CategoryMenuPresentation.slideUpSheet ? ' (jelenlegi)' : ''}',
                description: 'Fókuszált alsó sheet, mint az új kategória panel',
                selected:
                    settings.categoryMenuPresentation ==
                    CategoryMenuPresentation.slideUpSheet,
                onTap: () => onChanged(
                  settings.copyWith(
                    categoryMenuPresentation:
                        CategoryMenuPresentation.slideUpSheet,
                  ),
                ),
                preview: const Icon(
                  Icons.vertical_align_bottom_rounded,
                  color: AppColors.gray500,
                ),
              ),
              _sectionTitle('Navigáció', 'Bottom nav és FAB elrendezés:'),
              for (final layout in ShellNavigationLayout.values)
                SettingsRadioOption(
                  key: ValueKey(
                    layout == ShellNavigationLayout.current
                        ? 'theme-shell-navigation-current'
                        : 'theme-shell-navigation-right-rounded-fab',
                  ),
                  title:
                      '${layout.displayTitle}${settings.shellNavigationLayout == layout ? ' (jelenlegi)' : ''}',
                  description: layout.description,
                  selected: settings.shellNavigationLayout == layout,
                  onTap: () => onChanged(
                    settings.copyWith(shellNavigationLayout: layout),
                  ),
                  preview: Icon(
                    layout == ShellNavigationLayout.current
                        ? Icons.add_circle_outline
                        : Icons.rounded_corner,
                    color: AppColors.gray500,
                  ),
                ),
              _sectionTitle('FAB forma', 'A plusz gomb alakja:'),
              for (final shape in FabShape.values)
                SettingsRadioOption(
                  key: ValueKey(
                    shape == FabShape.circle
                        ? 'theme-fab-shape-circle'
                        : 'theme-fab-shape-rounded-square',
                  ),
                  title:
                      '${shape.displayTitle}${settings.fabShape == shape ? ' (jelenlegi)' : ''}',
                  description: shape.description,
                  selected: settings.fabShape == shape,
                  onTap: () => onChanged(settings.copyWith(fabShape: shape)),
                  preview: Icon(
                    shape == FabShape.circle
                        ? Icons.add_circle_outline
                        : Icons.rounded_corner,
                    color: AppColors.gray500,
                  ),
                ),
              _FabSizeControl(settings: settings, onChanged: onChanged),
              _sectionTitle(
                'Kategória menü felülete',
                'A kategória overlay háttérfelülete:',
              ),
              _surfaceOption(
                key: const ValueKey('theme-category-menu-surface-normal'),
                title: 'Normál',
                description: 'Sík kategória menü háttér',
                selected:
                    settings.categoryMenuSurfaceStyle ==
                    ExpenseSurfaceInteraction.neutralNeutral,
                previewStyle: ExpenseSurfaceInteraction.neutralNeutral,
                onTap: () => onChanged(
                  settings.copyWith(
                    categoryMenuSurfaceStyle:
                        ExpenseSurfaceInteraction.neutralNeutral,
                  ),
                ),
              ),
              _surfaceOption(
                key: const ValueKey('theme-category-menu-surface-neumorph'),
                title: 'Neumorph',
                description: 'Mélységet kapó kategória menü háttér',
                selected:
                    settings.categoryMenuSurfaceStyle ==
                    ExpenseSurfaceInteraction.insetInset,
                previewStyle: ExpenseSurfaceInteraction.insetInset,
                onTap: () => onChanged(
                  settings.copyWith(
                    categoryMenuSurfaceStyle:
                        ExpenseSurfaceInteraction.insetInset,
                  ),
                ),
              ),
              _categoryMenuColorOption(
                'Fehér',
                'Fehér kategória menü háttér',
                AppBoxColor.white,
                AppColors.white,
              ),
              _categoryMenuColorOption(
                'Szürke',
                'Szürke kategória menü háttér',
                AppBoxColor.gray,
                AppColors.gray100,
              ),
              _categoryMenuColorOption(
                'Sötétebb szürke',
                'Erősebb szürke kategória menü háttér',
                AppBoxColor.darkgray,
                AppColors.gray200,
              ),
              _sectionTitle(
                'Kategória kártyák felülete',
                'A kategória cardok háttérszíne és mélysége:',
              ),
              _surfaceOption(
                key: const ValueKey('theme-category-card-surface-normal'),
                title: 'Normál',
                description: 'Sík kategória kártyák',
                selected:
                    settings.categoryCardSurfaceStyle ==
                    ExpenseSurfaceInteraction.neutralNeutral,
                previewStyle: ExpenseSurfaceInteraction.neutralNeutral,
                onTap: () => onChanged(
                  settings.copyWith(
                    categoryCardSurfaceStyle:
                        ExpenseSurfaceInteraction.neutralNeutral,
                  ),
                ),
              ),
              _surfaceOption(
                key: const ValueKey('theme-category-card-surface-neumorph'),
                title: 'Neumorph',
                description: 'Kiemelt kategória kártyák',
                selected:
                    settings.categoryCardSurfaceStyle ==
                    ExpenseSurfaceInteraction.raisedInset,
                previewStyle: ExpenseSurfaceInteraction.raisedInset,
                onTap: () => onChanged(
                  settings.copyWith(
                    categoryCardSurfaceStyle:
                        ExpenseSurfaceInteraction.raisedInset,
                  ),
                ),
              ),
              _categoryCardColorOption(
                'Fehér',
                'Fehér kategória kártyák',
                AppBoxColor.white,
                AppColors.white,
              ),
              _categoryCardColorOption(
                'Szürke',
                'Szürke kategória kártyák',
                AppBoxColor.gray,
                AppColors.gray100,
              ),
              _categoryCardColorOption(
                'Sötétebb szürke',
                'Erősebb szürke kategória kártyák',
                AppBoxColor.darkgray,
                AppColors.gray200,
              ),
              _sectionTitle(
                'Árnyékok',
                'Normál felületek külső árnyékainak kapcsolása:',
              ),
              _shadowOption(
                keyBase: 'theme-category-card-shadow',
                title: 'Kategória kártyák',
                enabled: settings.categoryCardShadowEnabled,
                onChanged: (enabled) => onChanged(
                  settings.copyWith(categoryCardShadowEnabled: enabled),
                ),
              ),
              _shadowOption(
                keyBase: 'theme-logbox-shadow',
                title: 'Logboxok',
                enabled: settings.logboxShadowEnabled,
                onChanged: (enabled) =>
                    onChanged(settings.copyWith(logboxShadowEnabled: enabled)),
              ),
              _shadowOption(
                keyBase: 'theme-header-pill-shadow',
                title: 'Bevétel/kiadás gombok',
                enabled: settings.headerPillShadowEnabled,
                onChanged: (enabled) => onChanged(
                  settings.copyWith(headerPillShadowEnabled: enabled),
                ),
              ),
              _shadowOption(
                keyBase: 'theme-summary-pill-shadow',
                title: 'Summary pill',
                enabled: settings.summaryPillShadowEnabled,
                onChanged: (enabled) => onChanged(
                  settings.copyWith(summaryPillShadowEnabled: enabled),
                ),
              ),
              _shadowOption(
                keyBase: 'theme-search-pill-shadow',
                title: 'Search pill',
                enabled: settings.searchPillShadowEnabled,
                onChanged: (enabled) => onChanged(
                  settings.copyWith(searchPillShadowEnabled: enabled),
                ),
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

  Widget _surfaceOption({
    required ValueKey<String> key,
    required String title,
    required String description,
    required bool selected,
    required ExpenseSurfaceInteraction previewStyle,
    required VoidCallback onTap,
  }) {
    return SettingsRadioOption(
      key: key,
      title: '$title${selected ? ' (jelenlegi)' : ''}',
      description: description,
      selected: selected,
      onTap: onTap,
      preview: _SurfacePreview(style: previewStyle),
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

  Widget _categoryMenuColorOption(
    String title,
    String description,
    AppBoxColor value,
    Color color,
  ) {
    return SettingsRadioOption(
      key: ValueKey('theme-category-menu-color-${value.nativeValue}'),
      title:
          '$title${settings.categoryMenuColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.categoryMenuColor == value,
      onTap: () => onChanged(settings.copyWith(categoryMenuColor: value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _categoryCardColorOption(
    String title,
    String description,
    AppBoxColor value,
    Color color,
  ) {
    return SettingsRadioOption(
      key: ValueKey('theme-category-card-color-${value.nativeValue}'),
      title:
          '$title${settings.categoryCardColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.categoryCardColor == value,
      onTap: () => onChanged(settings.copyWith(categoryCardColor: value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _shadowOption({
    required String keyBase,
    required String title,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: SettingsRadioOption(
            key: ValueKey('$keyBase-on'),
            title: 'Van árnyék${enabled ? ' (jelenlegi)' : ''}',
            description: title,
            selected: enabled,
            onTap: () => onChanged(true),
            preview: const _SurfacePreview(
              style: ExpenseSurfaceInteraction.neutralNeutral,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SettingsRadioOption(
            key: ValueKey('$keyBase-off'),
            title: 'Nincs árnyék${!enabled ? ' (jelenlegi)' : ''}',
            description: title,
            selected: !enabled,
            onTap: () => onChanged(false),
            preview: const Icon(
              Icons.layers_clear_outlined,
              color: AppColors.gray500,
            ),
          ),
        ),
      ],
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

class _FabSizeControl extends StatefulWidget {
  const _FabSizeControl({required this.settings, required this.onChanged});

  final AppThemeSettings settings;
  final ValueChanged<AppThemeSettings> onChanged;

  @override
  State<_FabSizeControl> createState() => _FabSizeControlState();
}

class _FabSizeControlState extends State<_FabSizeControl> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.settings.fabSize.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _FabSizeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.fabSize != widget.settings.fabSize) {
      _syncText(widget.settings.fabSize);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.settings.fabSize.toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FAB méret',
              style: TextStyle(
                color: AppColors.gray800,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    key: const ValueKey('theme-fab-size-slider'),
                    min: kFabSizeMin.toDouble(),
                    max: kFabSizeMax.toDouble(),
                    divisions: kFabSizeMax - kFabSizeMin,
                    value: value,
                    label: widget.settings.fabSize.toString(),
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.gray200,
                    onChanged: _setSize,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 64,
                  child: TextField(
                    key: const ValueKey('theme-fab-size-input'),
                    controller: _controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      filled: true,
                      fillColor: AppColors.gray100,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: _handleTextChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setSize(double rawValue) {
    final value = rawValue.round().clamp(kFabSizeMin, kFabSizeMax).toInt();
    _syncText(value);
    widget.onChanged(widget.settings.copyWith(fabSize: value));
  }

  void _handleTextChanged(String rawValue) {
    final parsed = int.tryParse(rawValue.trim());
    if (parsed == null) return;
    _setSize(parsed.toDouble());
  }

  void _syncText(int value) {
    final text = value.toString();
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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
