import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/platform/header_orb_settings_channel.dart';
import '../../../core/diagnostics/copy_last_unlock.dart';

class HeaderOrbSetupPage extends StatefulWidget {
  const HeaderOrbSetupPage({super.key});

  @override
  State<HeaderOrbSetupPage> createState() => _HeaderOrbSetupPageState();
}

class _HeaderOrbSetupPageState extends State<HeaderOrbSetupPage>
    with WidgetsBindingObserver {
  Map<String, Object?>? _status;
  StreamSubscription<Map<String, Object?>>? _changes;
  bool _error = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _changes?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      unawaited(_invoke('settingsResumed'));
    }
  }

  void _update(Map<String, Object?> status) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _error = false;
    });
  }

  Future<void> _invoke(String action, [Map<String, Object?>? args]) async {
    if (_busy) return;
    _busy = true;
    try {
      final status = await HeaderOrbSettingsChannel.methods
          .invokeMapMethod<String, Object?>(action, args);
      if (!mounted || status == null) return;
      _update(status);
      _changes ??= HeaderOrbSettingsChannel.changes.listen(
        _update,
        onError: (Object _) => _setError(),
      );
    } on PlatformException {
      _setError();
    } on MissingPluginException {
      _setError();
    } finally {
      _busy = false;
    }
  }

  void _setError() {
    if (mounted) setState(() => _error = true);
  }

  Widget _styleSelector(int dp) {
    final selected = _status?['style$dp'] as String? ?? 'orb';
    final name = dp == 56 ? '1×1' : '2×2';
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 56, end: 16, bottom: 8),
      child: Wrap(
        spacing: 8,
        children: [
          for (final (style, label) in [
            ('orb', 'ORB'),
            ('fluviMask', 'Fluvi maszk'),
          ])
            Semantics(
              label: '$name · $label',
              excludeSemantics: true,
              button: true,
              selected: selected == style,
              enabled: !_busy,
              onTap: selected == style
                  ? null
                  : () => _invoke('selectStyle', {'dp': dp, 'style': style}),
              child: ChoiceChip(
                key: ValueKey('balance-orb-style-$dp-$style'),
                label: Text(label),
                selected: selected == style,
                onSelected: (value) {
                  if (value) _invoke('selectStyle', {'dp': dp, 'style': style});
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = _status?['sizeDp'] as int? ?? 56;
    final description = _error
        ? 'Az állapot nem kérdezhető le'
        : switch (_status?['state']) {
            'ready' => 'Engedélyezve',
            'dormant' => 'Engedélyezve · válassz méretet az aktiváláshoz',
            'pendingBind' => 'A widget Android-engedélyére vár',
            'needsBind' => 'Válassz méretet a widget engedélyezéséhez',
            'waitingForHeader' => 'Engedélyezve · az ORB képe készül',
            _ => 'Kikapcsolva',
          };
    return Scaffold(
      appBar: AppBar(title: const Text('Zárképernyő')),
      body: ListView(
        children: [
          ListTile(
            key: const ValueKey('balance-orb-accessibility'),
            title: const Text('Android kisegítő lehetőségek'),
            subtitle: Text(description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _invoke('openAccessibility'),
          ),
          for (final dp in [56, 112]) ...[
            ListTile(
              key: ValueKey('balance-orb-size-$dp'),
              title: Text(dp == 56 ? '1×1 (56 dp)' : '2×2 (112 dp)'),
              leading: Icon(
                size == dp
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              selected: size == dp,
              onTap: () => _invoke('selectSize', {'dp': dp}),
            ),
            _styleSelector(dp),
          ],
          SwitchListTile(
            key: const ValueKey('balance-orb-permanent'),
            title: const Text('Permanens ORB'),
            subtitle: const Text(
              'Lezárás után is látható, amíg a telefon Always-On Display módja aktív.',
            ),
            value: _status?['permanentOrb'] == true,
            onChanged: _status == null || _busy
                ? null
                : (enabled) => _invoke('setPermanentOrb', {'enabled': enabled}),
          ),
          if (_status?['permanentOrb'] == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(switch (_status?['ambientState']) {
                'WAIT_MATERIAL' =>
                  'Az AOD-hoz szükséges ORB-kép még nem áll rendelkezésre.',
                'AOD_OBSERVED' =>
                  'A rendszer AOD-állapotot jelzett. Az ORB tényleges láthatósága még nem igazolt.',
                _ => 'A telefon AOD-támogatása még nincs megállapítva.',
              }),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [CopyLastUnlock(), CopyLastUnlock(ambient: true)],
            ),
          ),
        ],
      ),
    );
  }
}
