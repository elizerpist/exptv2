import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'push_profile_details_page.dart';

class PushProfileWizardPage extends StatefulWidget {
  const PushProfileWizardPage({
    super.key,
    required this.repository,
    required this.permissions,
  });
  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  @override
  State<PushProfileWizardPage> createState() => _PushProfileWizardPageState();
}

class _PushProfileWizardPageState extends State<PushProfileWizardPage>
    with WidgetsBindingObserver {
  final _name = TextEditingController();
  int _step = 0;
  List<InstalledApplication> _apps = const [];
  InstalledApplication? _selected;
  String _search = '';
  bool _showSystemApps = false;
  PushTransactionDirection _direction = PushTransactionDirection.automatic;
  bool _monitor = true;
  bool _loadingApps = true;
  bool _saving = false;
  AutomationPermissionStatus? _status;
  Object? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        widget.permissions.listInstalledApps(),
        widget.permissions.getPermissionStatus(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _apps = values[0] as List<InstalledApplication>;
        _status = values[1] as AutomationPermissionStatus;
        _loadingApps = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loadingApps = false;
        });
      }
    }
  }

  Future<void> _refreshPermission() async {
    final status = await widget.permissions.getPermissionStatus();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _next() async {
    if (_step == 0) {
      if (_selected == null) return;
      setState(() {
        _name.text = _selected!.label;
        _step = 1;
      });
      return;
    }
    if (_step == 1) {
      if (_name.text.trim().isEmpty) return;
      setState(() => _step = 2);
      return;
    }
    await _create();
  }

  Future<void> _create() async {
    final app = _selected;
    if (app == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // A package name is the stable source identity.  Check before the
      // write so the user can deliberately continue with the existing
      // profile rather than encountering a late, opaque validation error.
      PushProfile? duplicate;
      for (final profile in await widget.repository.listProfiles()) {
        if (profile.packageName == app.packageName) {
          duplicate = profile;
          break;
        }
      }
      if (duplicate != null) {
        final existingProfile = duplicate;
        if (!mounted) return;
        final openExisting = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Már létezik push profil'),
            content: Text('${app.label} alkalmazáshoz már van profil.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Maradok'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Profil megnyitása'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (openExisting == true) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => PushProfileDetailsPage(
                repository: widget.repository,
                permissions: widget.permissions,
                profileId: existingProfile.profileId,
              ),
            ),
          );
          return;
        }
        setState(() => _saving = false);
        return;
      }
      final profile = await widget.repository.createProfile(
        packageName: app.packageName,
        appLabel: app.label,
        displayName: _name.text.trim(),
        defaultDirection: _direction,
        monitoringRequested: _monitor,
        notificationAccessGranted:
            _status?.notificationListenerGranted ?? false,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PushProfileDetailsPage(
            repository: widget.repository,
            permissions: widget.permissions,
            profileId: profile.profileId,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('push-profile-wizard-page'),
      appBar: AppBar(
        title: const Text('Új push profil'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close),
        ),
        actions: [
          Center(child: Text('${_step + 1} / 3')),
          const SizedBox(width: 18),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: _body(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_step > 0)
                TextButton(
                  onPressed: _saving ? null : () => setState(() => _step--),
                  child: const Text('Előző'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _next,
                child: Text(
                  _saving
                      ? 'Mentés…'
                      : _step == 2
                      ? 'Profil létrehozása'
                      : 'Következő',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() => switch (_step) {
    0 => _appStep(),
    1 => _setupStep(),
    _ => _summaryStep(),
  };
  Widget _appStep() {
    if (_loadingApps) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Az alkalmazáslista nem tölthető be.'),
            TextButton(onPressed: _load, child: const Text('Újrapróbálás')),
          ],
        ),
      );
    }
    final query = _search.trim().toLowerCase();
    final shown = _apps
        .where(
          (app) =>
              (_showSystemApps || !app.isSystemApp) &&
              (query.isEmpty ||
                  app.label.toLowerCase().contains(query) ||
                  app.packageName.toLowerCase().contains(query)),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Melyik alkalmazás értesítéseit figyeljük?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Csak a kiválasztott alkalmazásból érkező értesítések kerülhetnek a Fluvi Inboxba.',
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (value) => setState(() => _search = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Alkalmazás keresése',
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => _showSystemApps = !_showSystemApps),
          icon: Icon(
            _showSystemApps
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank,
            size: 18,
          ),
          label: const Text('Rendszeralkalmazások mutatása'),
        ),
        Expanded(
          child: shown.isEmpty
              ? const Center(child: Text('Nincs találat.'))
              : ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (_, index) {
                    final app = shown[index];
                    final selected = app.packageName == _selected?.packageName;
                    return ListTile(
                      onTap: () => setState(() => _selected = app),
                      leading: _AppIcon(app: app),
                      title: Text(app.label),
                      subtitle: Text(app.packageName),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xff328365),
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _setupStep() => ListView(
    children: [
      const Text(
        'Profil beállítása',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _AppIcon(app: _selected!),
        title: Text(_selected!.label),
        subtitle: Text(_selected!.packageName),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _name,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Profil neve'),
      ),
      const SizedBox(height: 20),
      const Text(
        'Feldolgozási irány',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      RadioGroup<PushTransactionDirection>(
        groupValue: _direction,
        onChanged: (value) => setState(() => _direction = value!),
        child: Column(
          children: PushTransactionDirection.values
              .map(
                (direction) => RadioListTile<PushTransactionDirection>(
                  contentPadding: EdgeInsets.zero,
                  value: direction,
                  title: Text(_directionLabel(direction)),
                  subtitle: direction == PushTransactionDirection.automatic
                      ? const Text('A felismerési szabály dönti el az irányt.')
                      : null,
                ),
              )
              .toList(growable: false),
        ),
      ),
      const Divider(),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _monitor,
        onChanged: (value) => setState(() => _monitor = value),
        title: const Text('Megfigyelés'),
        subtitle: const Text(
          'A profil létrejön, de tanítás nélkül nem könyvel automatikusan.',
        ),
      ),
    ],
  );
  Widget _summaryStep() {
    final granted = _status?.notificationListenerGranted == true;
    return ListView(
      children: [
        const Text(
          'Kezdődhet a megfigyelés',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        _summaryRow('Banki alkalmazás', _selected!.label),
        _summaryRow('Profil neve', _name.text.trim()),
        _summaryRow('Feldolgozási irány', _directionLabel(_direction)),
        _summaryRow(
          'Értesítés-hozzáférés',
          granted ? 'Engedélyezve' : 'Nincs engedélyezve',
        ),
        if (!granted) ...[
          const SizedBox(height: 14),
          const Text(
            'Az Android széles értesítés-hozzáférést kér. A Fluvi csak az itt kiválasztott, engedélyezett alkalmazások üzeneteit tárolja.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.permissions.openNotificationAccessSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Hozzáférés engedélyezése'),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Hiba: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _summaryRow(String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(color: Color(0xff68727d))),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.app});
  final InstalledApplication app;
  @override
  Widget build(BuildContext context) {
    final raw = app.iconPngBase64;
    return CircleAvatar(
      backgroundColor: const Color(0xffeef1f4),
      foregroundImage: raw == null ? null : MemoryImage(base64Decode(raw)),
      child: raw == null
          ? Text(
              app.label.isEmpty ? '?' : app.label.substring(0, 1).toUpperCase(),
            )
          : null,
    );
  }
}

String _directionLabel(PushTransactionDirection value) => switch (value) {
  PushTransactionDirection.automatic => 'Automatikus',
  PushTransactionDirection.expenseOnly => 'Csak kiadás',
  PushTransactionDirection.incomeOnly => 'Csak bevétel',
};
