import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/debug/debug_console.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../services/native_bridge.dart';
import '../../state/event_store.dart';
import 'data/settings_repository.dart';
import 'models/app_theme_settings.dart';
import 'models/fast_info_config.dart';
import 'theme/expense_theme.dart';
import 'state/settings_store.dart';
import 'widgets/notification_parser_rule_editor.dart';
import 'widgets/options/backheader_style_options_panel.dart';
import 'widgets/options/fast_info_options_panel.dart';
import 'widgets/options/permissions_options_panel.dart';
import 'widgets/options/settings_option_widgets.dart';
import 'widgets/options/simple_options_panel.dart';
import 'widgets/options/theme_options_panel.dart';
import 'widgets/push_log/push_notification_log_page.dart';
import 'widgets/security/biometric_settings_panel.dart';
import 'widgets/security/pin_settings_panel.dart';

enum _SettingsMenu {
  root,
  parsedApp,
  pushLog,
  permissions,
  fastInfo,
  statistics,
  currency,
  language,
  backheader,
  theme,
  exportData,
  importData,
  backup,
  pinSecurity,
  biometricSecurity,
  about,
  help,
  contact,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.store,
    required this.nativeBridge,
    this.expenseTheme,
    this.onThemeSettingsChanged,
    this.onFastInfoConfigChanged,
  });

  final EventStore store;
  final NativeBridge nativeBridge;
  final ExpenseTheme? expenseTheme;
  final ValueChanged<AppThemeSettings>? onThemeSettingsChanged;
  final ValueChanged<FastInfoConfig>? onFastInfoConfigChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsStore _settingsStore;
  late _SettingsMenu _activeMenu;
  var _hapticFeedback = true;
  var _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _activeMenu = _menuFromKey(widget.store.settingsActiveMenuKey);
    DebugConsole.log(
      '[Settings] active menu restore key=${widget.store.settingsActiveMenuKey}',
    );
    widget.store.addListener(_onStoreChanged);
    unawaited(widget.store.loadNotificationParserRule());
    unawaited(widget.store.preloadInstalledApps());
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
      unawaited(widget.store.loadNotificationParserRule());
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
    if (!mounted) return;
    final storeMenu = _menuFromKey(widget.store.settingsActiveMenuKey);
    setState(() {
      _activeMenu = storeMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseTheme =
        widget.expenseTheme ??
        ExpenseTheme.fromSettings(_settingsStore.themeSettings);
    return Material(
      color: expenseTheme.appBackground,
      child: ColoredBox(
        key: const ValueKey('settings-page'),
        color: expenseTheme.appBackground,
        child: SafeArea(bottom: false, child: _buildActiveMenu()),
      ),
    );
  }

  Widget _buildActiveMenu() {
    if (_activeMenu == _SettingsMenu.root) return _buildRootMenu();
    return SettingsSubmenuShell(
      title: _menuTitle(_activeMenu),
      onBack: _backFromActiveMenu,
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
                SettingsOptionItem(
                  title: 'Push import',
                  onTap: () => _open(_SettingsMenu.parsedApp),
                ),
                SettingsOptionItem(
                  title: 'Engedélyek',
                  onTap: () => _open(_SettingsMenu.permissions),
                ),
                SettingsOptionItem(
                  title: 'FastInfo',
                  onTap: () => _open(_SettingsMenu.fastInfo),
                ),
                SettingsOptionItem(
                  title: 'Statisztikák',
                  onTap: () => _open(_SettingsMenu.statistics),
                  isLast: true,
                ),
              ],
            ),
            SettingsSection(
              title: 'Megjelenítési beállítások',
              children: [
                SettingsOptionItem(
                  title: 'Pénznem',
                  onTap: () => _open(_SettingsMenu.currency),
                ),
                SettingsOptionItem(
                  title: 'Nyelv',
                  onTap: () => _open(_SettingsMenu.language),
                ),
                SettingsOptionItem(
                  title: 'Backheader',
                  onTap: () => _open(_SettingsMenu.backheader),
                ),
                SettingsOptionItem(
                  title: 'Téma',
                  onTap: () => _open(_SettingsMenu.theme),
                  isLast: true,
                ),
              ],
            ),
            SettingsSection(
              title: 'Adatkezelés',
              children: [
                SettingsOptionItem(
                  title: 'Export adatok',
                  onTap: () => _open(_SettingsMenu.exportData),
                ),
                SettingsOptionItem(
                  title: 'Import adatok',
                  onTap: () => _open(_SettingsMenu.importData),
                ),
                SettingsOptionItem(
                  title: 'Biztonsági mentés',
                  onTap: () => _open(_SettingsMenu.backup),
                ),
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
            SettingsSection(
              title: 'Adatvédelem és biztonság',
              children: [
                SettingsOptionItem(
                  title: 'PIN kód beállítása',
                  onTap: () => _open(_SettingsMenu.pinSecurity),
                ),
                SettingsOptionItem(
                  title: 'Biometrikus azonosítás',
                  onTap: () => _open(_SettingsMenu.biometricSecurity),
                ),
                const SettingsOptionItem(
                  title: 'Adatvédelmi szabályzat',
                  isLast: true,
                ),
              ],
            ),
            SettingsSection(
              title: 'Visszajelzések',
              children: [
                SettingsOptionItem(
                  title: 'Haptikus visszajelzés',
                  trailing: Switch(
                    value: _hapticFeedback,
                    onChanged: (value) =>
                        setState(() => _hapticFeedback = value),
                  ),
                ),
                SettingsOptionItem(
                  title: 'Hang',
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: (value) => setState(() => _soundEnabled = value),
                  ),
                  isLast: true,
                ),
              ],
            ),
            SettingsSection(
              title: 'Információ és támogatás',
              children: [
                SettingsOptionItem(
                  title: 'Alkalmazásról',
                  onTap: () => _open(_SettingsMenu.about),
                ),
                SettingsOptionItem(
                  title: 'Súgó',
                  onTap: () => _open(_SettingsMenu.help),
                ),
                SettingsOptionItem(
                  title: 'Kapcsolat',
                  onTap: () => _open(_SettingsMenu.contact),
                ),
                const SettingsOptionItem(
                  title: 'Verzió: 1.0.0',
                  trailing: SizedBox.shrink(),
                  isLast: true,
                ),
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
        key: const ValueKey('settings-parsed-app-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const Text(
            'Válaszd ki azt az alkalmazást, amelynek push üzeneteit szeretnéd érzékelni és automatikusan rögzíteni a tranzakciókat:',
            style: TextStyle(color: AppColors.gray600),
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'PushParser napló',
            children: [
              SettingsOptionItem(
                title: 'Elkapott push üzenetek',
                subtitle:
                    'Év, hónap, app, szöveg és log kapcsolat szerint szűrhető',
                onTap: () => _open(_SettingsMenu.pushLog),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          NotificationParserProfilesPanel(
            profiles: widget.store.notificationParserProfiles,
            selectedProfile: widget.store.selectedNotificationParserProfile,
            preview: widget.store.notificationParserPreview,
            installedApps: widget.store.installedApps,
            onProfileSelected: widget.store.selectNotificationParserProfile,
            onAddProfile: () {
              unawaited(widget.store.addNotificationParserProfile());
            },
            onDeleteProfile: (id) {
              unawaited(widget.store.deleteNotificationParserProfile(id));
            },
            onProfileEnabledChanged: (id, enabled) {
              unawaited(
                widget.store.setNotificationParserProfileEnabled(id, enabled),
              );
            },
            onProfileChanged: (profile) {
              unawaited(
                widget.store.updateSelectedNotificationParserProfile(profile),
              );
            },
            onSaveProfile: () {
              unawaited(widget.store.saveSelectedNotificationParserProfile());
            },
            onLoadInstalledApps: widget.store.listInstalledApps,
          ),
        ],
      ),
      _SettingsMenu.pushLog => PushNotificationLogPage(
        nativeBridge: widget.nativeBridge,
        parserStore: widget.store,
      ),
      _SettingsMenu.permissions => PermissionsOptionsPanel(
        nativeBridge: widget.nativeBridge,
      ),
      _SettingsMenu.fastInfo => FastInfoOptionsPanel(
        config: _settingsStore.fastInfoConfig,
        onChanged: _updateFastInfoConfig,
      ),
      _SettingsMenu.theme => ThemeOptionsPanel(
        settings: _settingsStore.themeSettings,
        onChanged: _updateThemeSettings,
      ),
      _SettingsMenu.backheader => BackheaderStyleOptionsPanel(
        settings: _settingsStore.themeSettings,
        onChanged: _updateThemeSettings,
      ),
      _SettingsMenu.pinSecurity => PinSettingsPanel(
        settings: _settingsStore.securitySettings,
        onSetPin: _settingsStore.setSecurityPin,
        onChangePin: (currentPin, newPin) => _settingsStore.changeSecurityPin(
          currentPin: currentPin,
          newPin: newPin,
        ),
        onClearPin: _settingsStore.clearSecurityPin,
      ),
      _SettingsMenu.biometricSecurity => BiometricSettingsPanel(
        settings: _settingsStore.securitySettings,
        onRefreshAvailability: _settingsStore.refreshBiometricAvailability,
        onAuthenticate: widget.nativeBridge.expenseAuthenticateBiometric,
        onSetEnabled: _settingsStore.setBiometricEnabled,
        onOpenPinSettings: () => _open(_SettingsMenu.pinSecurity),
      ),
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
      _SettingsMenu.parsedApp => 'Push import',
      _SettingsMenu.pushLog => 'Elkapott push üzenetek',
      _SettingsMenu.permissions => 'Engedélyek',
      _SettingsMenu.fastInfo => 'FastInfo',
      _SettingsMenu.statistics => 'Statisztikák',
      _SettingsMenu.currency => 'Pénznem Beállítások',
      _SettingsMenu.language => 'Nyelv Beállítások',
      _SettingsMenu.backheader => 'Backheader',
      _SettingsMenu.theme => 'Téma Beállítások',
      _SettingsMenu.exportData => 'Adatok Exportálása',
      _SettingsMenu.importData => 'Adatok Importálása',
      _SettingsMenu.backup => 'Biztonsági mentés',
      _SettingsMenu.pinSecurity => 'PIN kód beállítása',
      _SettingsMenu.biometricSecurity => 'Biometrikus azonosítás',
      _SettingsMenu.about => 'Az Alkalmazásról',
      _SettingsMenu.help => 'Súgó',
      _SettingsMenu.contact => 'Kapcsolat',
      _SettingsMenu.root => 'Beállítások',
    };
  }

  Future<void> _updateFastInfoConfig(FastInfoConfig config) async {
    await _settingsStore.updateFastInfoConfig(config);
    if (!mounted) return;
    widget.onFastInfoConfigChanged?.call(_settingsStore.fastInfoConfig);
  }

  void _updateThemeSettings(AppThemeSettings settings) {
    _settingsStore.updateThemeSettings(settings).then((_) {
      if (!mounted) return;
      widget.onThemeSettingsChanged?.call(_settingsStore.themeSettings);
    });
  }

  void _open(_SettingsMenu menu) {
    widget.store.setSettingsActiveMenuKey(_menuKey(menu));
    setState(() => _activeMenu = menu);
  }

  void _backFromActiveMenu() {
    final next = _activeMenu == _SettingsMenu.pushLog
        ? _SettingsMenu.parsedApp
        : _SettingsMenu.root;
    widget.store.setSettingsActiveMenuKey(_menuKey(next));
    setState(() {
      _activeMenu = next;
    });
  }

  String _menuKey(_SettingsMenu menu) => menu.name;

  _SettingsMenu _menuFromKey(String key) {
    for (final menu in _SettingsMenu.values) {
      if (menu.name == key) return menu;
    }
    return _SettingsMenu.root;
  }
}
