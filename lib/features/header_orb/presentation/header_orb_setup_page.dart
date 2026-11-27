import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HeaderOrbSetupPage extends StatefulWidget {
  const HeaderOrbSetupPage({super.key});

  @override
  State<HeaderOrbSetupPage> createState() => _HeaderOrbSetupPageState();
}

class _HeaderOrbSetupPageState extends State<HeaderOrbSetupPage>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('fluvi/header_orb_widget');
  Map<String, Object?>? _status;
  bool _busy = false;
  bool _error = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final status = await _channel.invokeMapMethod<String, Object?>('status');
      if (mounted && request == _request) {
        setState(() {
          _status = status;
          _error = status == null;
        });
      }
    } on PlatformException {
      if (mounted && request == _request) setState(() => _error = true);
    } on MissingPluginException {
      if (mounted && request == _request) setState(() => _error = true);
    }
  }

  Future<void> _change(bool enabled) async {
    setState(() => _busy = true);
    try {
      if (enabled) {
        final granted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fejléc megosztása a zárképernyőn'),
            content: const Text(
              'Az ORB színei tükrözhetik a pénzügyi állapotodat. '
              'A megosztott widget az aktuális fejléc mozgó képét mutatja.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Mégse'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Engedélyezem'),
              ),
            ],
          ),
        );
        if (granted != true || !mounted) return;
      }
      await _channel.invokeMethod<void>('setSharing', enabled);
      await _load();
    } on PlatformException {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openHost() async {
    try {
      await _channel.invokeMethod<void>('openSetup');
    } on PlatformException {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final enabled = status?['sharing'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Zárképernyő')),
      body: ListView(
        children: [
          SwitchListTile(
            key: const ValueKey('header-orb-sharing'),
            title: const Text('Aktuális fejléc megosztása'),
            value: enabled,
            onChanged: status == null || _busy ? null : _change,
          ),
          if (enabled)
            ListTile(
              title: Text(
                status?['ready'] == true
                    ? 'A fejléc képkockái elkészültek'
                    : 'Térj vissza a dashboardra a képkockák elkészítéséhez',
              ),
            ),
          ListTile(
            key: const ValueKey('header-orb-wa-setup'),
            title: const Text('Zárképernyős widget elhelyezése'),
            subtitle: Text(
              status?['accessibilityEnabled'] == true
                  ? 'Widgets Anywhere engedélyezve'
                  : 'Widgets Anywhere beállítása',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: status?['hostAvailable'] == true ? _openHost : null,
          ),
          if (_error)
            ListTile(
              title: const Text('A zárképernyő állapota nem kérdezhető le'),
              trailing: TextButton(onPressed: _load, child: const Text('Újra')),
            ),
        ],
      ),
    );
  }
}
