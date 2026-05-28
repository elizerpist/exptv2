import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../services/native_bridge.dart';
import '../../state/event_store.dart';
import 'data/settings_repository.dart';
import 'state/settings_store.dart';
import 'widgets/app_filter_control.dart';
import 'widgets/options/fast_info_options_panel.dart';
import 'widgets/options/recurring_options_panel.dart';
import 'widgets/options/settings_option_widgets.dart';
import 'widgets/options/simple_options_panel.dart';
import 'widgets/options/theme_options_panel.dart';

enum _SettingsMenu {
  root,
  parsedApp,
  fastInfo,
  statistics,
  recurring,
  currency,
  language,
  theme,
  exportData,
  importData,
  backup,
  about,
  help,
  contact,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.store,
    required this.nativeBridge,
  });

  final EventStore store;
  final NativeBridge nativeBridge;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsStore _settingsStore;
  var _activeMenu = _SettingsMenu.root;
  var _hapticFeedback = true;
  var _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    _settingsStore = SettingsStore(SettingsRepository(widget.nativeBridge));
    _settingsStore.addListener(_onStoreChanged);
    _settingsStore.start();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_onStoreChanged);
      widget.store.addListener(_onStoreChanged);
    }
    if (oldWidget.nativeBridge != widget.nativeBridge) {
      _settingsStore.removeListener(_onStoreChanged);
      _settingsStore = SettingsStore(SettingsRepository(widget.nativeBridge));
      _settingsStore.addListener(_onStoreChanged);
      _settingsStore.start();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    _settingsStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray100,
      child: ColoredBox(
        key: const ValueKey('settings-page'),
        color: AppColors.gray100,
        child: SafeArea(
          bottom: false,
          child: _buildActiveMenu(),
        ),
      ),
    );
  }

  Widget _buildActiveMenu() {
    if (_activeMenu == _SettingsMenu.root) return _buildRootMenu();
    return SettingsSubmenuShell(
      title: _menuTitle(_activeMenu),
      onBack: () => setState(() => _activeMenu = _SettingsMenu.root),
      child: _submenuBody(_activeMenu),
    );
  }

  Widget _buildRootMenu() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          AppDimensions.bottomNavHeight + AppDimensions.fabSize,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              'Beállítások',
              style: TextStyle(
                color: AppColors.gray800,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SettingsSection(
          title: 'Alkalmazás beállítások',
          children: [
            SettingsOptionItem(title: 'Megfigyelni kívánt alkalmazás', onTap: () => _open(_SettingsMenu.parsedApp)),
            SettingsOptionItem(title: 'FastInfo', onTap: () => _open(_SettingsMenu.fastInfo)),
            SettingsOptionItem(title: 'Statisztikák', onTap: () => _open(_SettingsMenu.statistics)),
            SettingsOptionItem(title: 'Ismétlődő tranzakciók', onTap: () => _open(_SettingsMenu.recurring), isLast: true),
          ],
        ),
        SettingsSection(
          title: 'Megjelenítési beállítások',
          children: [
            SettingsOptionItem(title: 'Pénznem', onTap: () => _open(_SettingsMenu.currency)),
            SettingsOptionItem(title: 'Nyelv', onTap: () => _open(_SettingsMenu.language)),
            SettingsOptionItem(title: 'Téma', onTap: () => _open(_SettingsMenu.theme), isLast: true),
          ],
        ),
        SettingsSection(
          title: 'Adatkezelés',
          children: [
            SettingsOptionItem(title: 'Export adatok', onTap: () => _open(_SettingsMenu.exportData)),
            SettingsOptionItem(title: 'Import adatok', onTap: () => _open(_SettingsMenu.importData)),
            SettingsOptionItem(title: 'Biztonsági mentés', onTap: () => _open(_SettingsMenu.backup)),
            const SettingsOptionItem(title: 'Adatok törlése', isLast: true),
          ],
        ),
        const SettingsSection(
          title: 'Értesítési beállítások',
          children: [
            SettingsOptionItem(title: 'Napi emlékeztetők'),
            SettingsOptionItem(title: 'Költségvetési riasztások'),
            SettingsOptionItem(title: 'Havi összefoglalók', isLast: true),
          ],
        ),
        const SettingsSection(
          title: 'Adatvédelem és biztonság',
          children: [
            SettingsOptionItem(title: 'PIN kód beállítása'),
            SettingsOptionItem(title: 'Biometrikus azonosítás'),
            SettingsOptionItem(title: 'Adatvédelmi szabályzat', isLast: true),
          ],
        ),
        SettingsSection(
          title: 'Visszajelzések',
          children: [
            SettingsOptionItem(
              title: 'Haptikus visszajelzés',
              trailing: Switch(value: _hapticFeedback, onChanged: (value) => setState(() => _hapticFeedback = value)),
            ),
            SettingsOptionItem(
              title: 'Hang',
              trailing: Switch(value: _soundEnabled, onChanged: (value) => setState(() => _soundEnabled = value)),
              isLast: true,
            ),
          ],
        ),
        SettingsSection(
          title: 'Információ és támogatás',
          children: [
            SettingsOptionItem(title: 'Alkalmazásról', onTap: () => _open(_SettingsMenu.about)),
            SettingsOptionItem(title: 'Súgó', onTap: () => _open(_SettingsMenu.help)),
            SettingsOptionItem(title: 'Kapcsolat', onTap: () => _open(_SettingsMenu.contact)),
            const SettingsOptionItem(title: 'Verzió: 1.0.0', trailing: SizedBox.shrink(), isLast: true),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _submenuBody(_SettingsMenu menu) {
    return switch (menu) {
      _SettingsMenu.parsedApp => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            const Text(
              'Válaszd ki azt az alkalmazást, amelynek push üzeneteit szeretnéd érzékelni és automatikusan rögzíteni a tranzakciókat:',
              style: TextStyle(color: AppColors.gray600),
            ),
            const SizedBox(height: 16),
            AppFilterControl(
              value: widget.store.filterText,
              errorText: widget.store.filterError,
              onTextChanged: widget.store.setFilterText,
              onLoadInstalledApps: widget.store.listInstalledApps,
              onAppSelected: widget.store.selectInstalledApp,
            ),
          ],
        ),
      _SettingsMenu.fastInfo => FastInfoOptionsPanel(config: _settingsStore.fastInfoConfig),
      _SettingsMenu.theme => ThemeOptionsPanel(
          settings: _settingsStore.themeSettings,
          onChanged: _settingsStore.updateThemeSettings,
        ),
      _SettingsMenu.recurring => RecurringOptionsPanel(store: _settingsStore),
      _SettingsMenu.currency => const SimpleOptionsPanel(
          title: 'Pénznem kiválasztása',
          children: ['EUR - Euro', 'HUF - Magyar Forint', 'USD - US Dollar'],
        ),
      _SettingsMenu.language => const SimpleOptionsPanel(
          title: 'Nyelv kiválasztása',
          children: ['English', 'Magyar'],
        ),
      _SettingsMenu.exportData => const SimpleOptionsPanel(
          title: 'Export formátum kiválasztása',
          children: ['CSV', 'JSON', 'Excel'],
        ),
      _SettingsMenu.importData => const SimpleOptionsPanel(
          title: 'Import formátum kiválasztása',
          children: ['CSV', 'JSON', 'Excel'],
        ),
      _SettingsMenu.backup => const SimpleOptionsPanel(
          title: 'Biztonsági mentés',
          children: ['Új biztonsági mentés', 'Korábbi mentések'],
        ),
      _SettingsMenu.statistics => const SimpleOptionsPanel(
          title: 'Statisztikák',
          children: ['Havi áttekintés', 'Kategória bontás', 'Trend'],
        ),
      _SettingsMenu.about => const SimpleOptionsPanel(
          title: 'Expense Tracker',
          children: ['Verzió: 1.0.0', '© 2024 - Minden jog fenntartva'],
        ),
      _SettingsMenu.help => const SimpleOptionsPanel(
          title: 'Súgó',
          children: ['Push feldolgozás', 'Tranzakciók', 'Beállítások'],
        ),
      _SettingsMenu.contact => const SimpleOptionsPanel(
          title: 'Kapcsolat',
          children: ['Email támogatás', 'Visszajelzés', 'Hibajelentés'],
        ),
      _SettingsMenu.root => _buildRootMenu(),
    };
  }

  String _menuTitle(_SettingsMenu menu) {
    return switch (menu) {
      _SettingsMenu.parsedApp => 'Megfigyelni kívánt alkalmazás',
      _SettingsMenu.fastInfo => 'FastInfo',
      _SettingsMenu.statistics => 'Statisztikák',
      _SettingsMenu.recurring => 'Ismétlődő tranzakciók',
      _SettingsMenu.currency => 'Pénznem Beállítások',
      _SettingsMenu.language => 'Nyelv Beállítások',
      _SettingsMenu.theme => 'Téma Beállítások',
      _SettingsMenu.exportData => 'Adatok Exportálása',
      _SettingsMenu.importData => 'Adatok Importálása',
      _SettingsMenu.backup => 'Biztonsági mentés',
      _SettingsMenu.about => 'Az Alkalmazásról',
      _SettingsMenu.help => 'Súgó',
      _SettingsMenu.contact => 'Kapcsolat',
      _SettingsMenu.root => 'Beállítások',
    };
  }

  void _open(_SettingsMenu menu) {
    setState(() => _activeMenu = menu);
  }
}
