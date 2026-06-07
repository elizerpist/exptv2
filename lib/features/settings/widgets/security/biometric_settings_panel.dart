import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/security_settings.dart';
import '../options/settings_option_widgets.dart';

class BiometricSettingsPanel extends StatefulWidget {
  const BiometricSettingsPanel({
    super.key,
    required this.settings,
    required this.onRefreshAvailability,
    required this.onAuthenticate,
    required this.onSetEnabled,
    required this.onOpenPinSettings,
  });

  final SecuritySettings settings;
  final Future<void> Function() onRefreshAvailability;
  final Future<bool> Function() onAuthenticate;
  final Future<void> Function(bool enabled) onSetEnabled;
  final VoidCallback onOpenPinSettings;

  @override
  State<BiometricSettingsPanel> createState() => _BiometricSettingsPanelState();
}

class _BiometricSettingsPanelState extends State<BiometricSettingsPanel> {
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRefreshAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settings.pinEnabled) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const SettingsSection(
            title: 'PIN szükséges',
            children: [
              SettingsOptionItem(
                title: 'Biometria csak PIN után kapcsolható be',
                trailing: Icon(Icons.info_outline, color: AppColors.gray400),
                isLast: true,
              ),
            ],
          ),
          FilledButton(
            key: const ValueKey('biometric-open-pin-button'),
            onPressed: widget.onOpenPinSettings,
            child: const Text('PIN beállítása'),
          ),
        ],
      );
    }

    return ListView(
      key: const ValueKey('biometric-settings-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        SettingsSection(
          title: 'Biometrikus azonosítás',
          children: [
            SettingsOptionItem(
              title: widget.settings.biometricLabel,
              trailing: Switch(
                key: const ValueKey('biometric-enable-switch'),
                value: widget.settings.biometricEnabled,
                onChanged: _busy || !widget.settings.biometricAvailable
                    ? null
                    : _toggle,
              ),
              isLast: true,
            ),
          ],
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    );
  }

  Future<void> _toggle(bool enabled) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (enabled) {
        final ok = await widget.onAuthenticate();
        if (!ok) {
          setState(() => _error = 'A biometrikus azonosítás nem sikerült.');
          return;
        }
      }
      await widget.onSetEnabled(enabled);
    } catch (_) {
      setState(() => _error = 'A biometrikus beállítás nem sikerült.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
