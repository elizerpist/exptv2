import 'package:flutter/material.dart';

import '../../../core/design/dashboard_mode_palette.dart';
import '../domain/pulse_models.dart';
import '../domain/pulse_repository.dart';

class PulseDeliverySettingsPage extends StatefulWidget {
  const PulseDeliverySettingsPage({super.key, required this.repository});
  final PulseRepository repository;

  @override
  State<PulseDeliverySettingsPage> createState() =>
      _PulseDeliverySettingsPageState();
}

class _PulseDeliverySettingsPageState extends State<PulseDeliverySettingsPage> {
  PulseDeliveryPreferences? _preferences;
  PulseDeliveryInspection? _inspection;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await widget.repository.deliveryPreferences();
      final now = DateTime.now();
      final inspection = await widget.repository.deliveryInspection(
        year: now.year,
        month: now.month,
        surface: const PulseDeliverySurfaceContext(
          appActive: true,
          ledgerVisible: false,
          headerVisible: false,
          unobstructed: false,
          interactionIdle: true,
          headerLayoutSupported: true,
          hostSessionId: 'delivery-settings',
        ),
      );
      if (mounted) {
        setState(() {
          _preferences = value;
          _inspection = inspection;
        });
      }
    } catch (_) {}
  }

  Future<void> _clearControl(PulseDeliveryControl control) async {
    await widget.repository.clearDeliveryControl(
      controlId: control.controlId,
      commandKey: 'settings-clear-${control.controlId}',
    );
    await _load();
  }

  Future<void> _setAutomatic(bool value) async {
    final preferences = _preferences;
    if (preferences == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.repository.updateDeliveryPreferences(
        automaticEnabled: value,
        normalCooldownMillis: preferences.normalCooldownMillis,
        commandKey:
            'settings-automatic-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (mounted) setState(() => _preferences = updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setCooldown(int minutes) async {
    final preferences = _preferences;
    if (preferences == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.repository.updateDeliveryPreferences(
        automaticEnabled: preferences.automaticEnabled,
        normalCooldownMillis: Duration(minutes: minutes).inMilliseconds,
        commandKey:
            'settings-frequency-$minutes-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (mounted) setState(() => _preferences = updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    return Scaffold(
      backgroundColor: FluviVisualTokens.pageBackground,
      appBar: AppBar(
        title: const Text('Pulse megjelenítés'),
        backgroundColor: FluviVisualTokens.pageBackground,
        elevation: 0,
      ),
      body: preferences == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FluviVisualTokens.border),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Megjelenítés a fejlécben'),
                        subtitle: const Text(
                          'A pénzügyi elemzés és a manuális Pulse nézet kikapcsolva is elérhető marad.',
                        ),
                        value: preferences.automaticEnabled,
                        onChanged: _saving ? null : _setAutomatic,
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Normál megjelenítési gyakoriság'),
                        subtitle: Text(
                          '${preferences.normalCooldownMillis ~/ 60000} perc a minősített megjelenítések között',
                        ),
                        trailing: PopupMenuButton<int>(
                          tooltip: 'Gyakoriság módosítása',
                          enabled: !_saving,
                          onSelected: _setCooldown,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 10, child: Text('10 perc')),
                            PopupMenuItem(value: 30, child: Text('30 perc')),
                            PopupMenuItem(value: 60, child: Text('60 perc')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if ((_inspection?.controls ?? const []).isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FluviVisualTokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aktív halasztások és némítások',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        for (final control in _inspection!.controls)
                          if (control.kind == 'snooze' ||
                              control.kind == 'mute')
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                control.kind == 'mute'
                                    ? 'Némított cél'
                                    : 'Halasztott helyzet',
                              ),
                              subtitle: Text(
                                control.targetScope ??
                                    'Helyzetszintű beállítás',
                              ),
                              trailing: TextButton(
                                onPressed: () => _clearControl(control),
                                child: const Text('Visszavonás'),
                              ),
                            ),
                      ],
                    ),
                  ),
                if ((_inspection?.controls ?? const []).isNotEmpty)
                  const SizedBox(height: 14),
                const Text(
                  'Az aktív halasztások és némítások a Delivery Inspectorban ellenőrizhetők. Ezek nem módosítják a pénzügyi jeleket vagy a Priority sorrendet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}
