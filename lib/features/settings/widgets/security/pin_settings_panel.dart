import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/security_settings.dart';
import '../options/settings_option_widgets.dart';

class PinSettingsPanel extends StatefulWidget {
  const PinSettingsPanel({
    super.key,
    required this.settings,
    required this.onSetPin,
    required this.onChangePin,
    required this.onClearPin,
  });

  final SecuritySettings settings;
  final Future<void> Function(String pin) onSetPin;
  final Future<void> Function(String currentPin, String newPin) onChangePin;
  final Future<void> Function(String currentPin) onClearPin;

  @override
  State<PinSettingsPanel> createState() => _PinSettingsPanelState();
}

class _PinSettingsPanelState extends State<PinSettingsPanel> {
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('pin-settings-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        SettingsSection(
          title: 'PIN beállítása',
          children: [
            SettingsOptionItem(
              title: widget.settings.pinEnabled ? 'PIN aktív' : 'Nincs PIN',
              trailing: Icon(
                widget.settings.pinEnabled ? Icons.lock : Icons.lock_open,
                color: widget.settings.pinEnabled
                    ? AppColors.primary
                    : AppColors.gray400,
              ),
              isLast: true,
            ),
          ],
        ),
        if (widget.settings.pinEnabled)
          _pinField(
            _current,
            'Jelenlegi PIN',
            const ValueKey('pin-current-input'),
          ),
        _pinField(_newPin, 'Új PIN', const ValueKey('pin-new-input')),
        _pinField(
          _confirm,
          'PIN megerősítése',
          const ValueKey('pin-confirm-input'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('pin-save-button'),
          onPressed: _busy ? null : _save,
          child: Text(
            widget.settings.pinEnabled ? 'PIN módosítása' : 'PIN bekapcsolása',
          ),
        ),
        if (widget.settings.pinEnabled) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('pin-clear-button'),
            onPressed: _busy ? null : _clear,
            child: const Text('PIN kikapcsolása'),
          ),
        ],
      ],
    );
  }

  Widget _pinField(TextEditingController controller, String label, Key key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: key,
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final next = _newPin.text;
    final confirm = _confirm.text;
    if (!_validPin(next)) {
      setState(() => _error = 'A PIN 4-6 számjegy legyen.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'A két PIN nem egyezik.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.settings.pinEnabled) {
        await widget.onChangePin(_current.text, next);
      } else {
        await widget.onSetPin(next);
      }
      _current.clear();
      _newPin.clear();
      _confirm.clear();
    } catch (_) {
      setState(() => _error = 'A PIN művelet nem sikerült.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    if (!_validPin(_current.text)) {
      setState(() => _error = 'Add meg a jelenlegi PIN-t.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onClearPin(_current.text);
      _current.clear();
      _newPin.clear();
      _confirm.clear();
    } catch (_) {
      setState(() => _error = 'A PIN kikapcsolása nem sikerült.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validPin(String value) => RegExp(r'^\d{4,6}$').hasMatch(value);
}
