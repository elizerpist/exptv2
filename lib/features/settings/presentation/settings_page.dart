import 'package:flutter/material.dart';

import '../../automation/domain/automation_models.dart';
import '../../automation/domain/automation_repository.dart';
import '../../runtime_monitoring/domain/runtime_monitoring_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.permissions, this.runtime});

  final AutomationPermissionRepository permissions;
  final RuntimeMonitoringRepository? runtime;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  AutomationPermissionStatus? _status;
  RuntimeMonitoringStatus? _runtimeStatus;
  bool _loading = true;
  bool _runtimeUpdating = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    AutomationPermissionStatus? permissions;
    RuntimeMonitoringStatus? runtime;
    try {
      permissions = await widget.permissions.getPermissionStatus();
    } catch (_) {
      // Keep the settings page useful if the permission bridge is temporarily
      // unavailable; runtime state has a separate native source of truth.
    }
    try {
      runtime = await widget.runtime?.status();
    } catch (_) {
      // The switch state must never be guessed from a failed platform call.
    }
    if (mounted) {
      setState(() {
        _status = permissions ?? _status;
        _runtimeStatus = runtime ?? _runtimeStatus;
        _loading = false;
      });
    }
  }

  Future<void> _changeForeground(bool requested) =>
      _changeRuntime(() => widget.runtime!.setForegroundRequested(requested));

  Future<void> _changeBackground(bool requested) =>
      _changeRuntime(() => widget.runtime!.setBackgroundRequested(requested));

  Future<void> _stopMonitoring() =>
      _changeRuntime(() => widget.runtime!.stopMonitoring());

  Future<void> _changeRuntime(
    Future<RuntimeMonitoringStatus> Function() operation,
  ) async {
    if (_runtimeUpdating || widget.runtime == null) return;
    setState(() => _runtimeUpdating = true);
    try {
      final status = await operation();
      if (mounted) setState(() => _runtimeStatus = status);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A futási mód módosítása nem sikerült. Próbáld újra.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _runtimeUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return SafeArea(
      child: ListView(
        key: const ValueKey('settings-page'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          const Text(
            'Beállítások',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 26),
          const Text(
            'Engedélyek',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _loading
                ? 'Állapot ellenőrzése…'
                : status?.notificationListenerGranted == true
                ? 'Push hozzáférés: engedélyezve'
                : 'Beállítás szükséges',
            style: const TextStyle(color: Color(0xff68727d)),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _PermissionTile(
                  icon: Icons.visibility_outlined,
                  title: 'Banki értesítések olvasása',
                  subtitle: 'A banki alkalmazások értesítéseinek megfigyelése.',
                  status: status?.notificationListenerAvailable == false
                      ? 'Nem elérhető'
                      : status?.notificationListenerGranted == true
                      ? 'Engedélyezve'
                      : 'Nincs engedélyezve',
                  onTap: () async {
                    await widget.permissions.openNotificationAccessSettings();
                  },
                ),
                const Divider(height: 1),
                _PermissionTile(
                  icon: Icons.notifications_outlined,
                  title: 'Fluvi értesítései',
                  subtitle: 'A Fluvi saját értesítéseinek megjelenítése.',
                  status: status?.postNotificationsGranted == true
                      ? 'Engedélyezve'
                      : 'Nincs engedélyezve',
                  onTap: () async {
                    if (status?.postNotificationsGranted == true) {
                      await widget.permissions.openAppNotificationSettings();
                    } else {
                      await widget.permissions.requestPostNotifications();
                    }
                    _refresh();
                  },
                ),
                const Divider(height: 1),
                _PermissionTile(
                  icon: Icons.send_outlined,
                  title: 'Tesztértesítés küldése',
                  subtitle: 'A Fluvi saját rendszerértesítését ellenőrzi.',
                  status: '',
                  onTap: () async {
                    final dispatch = await widget.permissions
                        .sendTestNotification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(dispatch.message),
                        action: dispatch.status == 'channelDisabled'
                            ? SnackBarAction(
                                label: 'Csatorna beállításai',
                                onPressed: () => widget.permissions
                                    .openTestNotificationChannelSettings(),
                              )
                            : null,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _PermissionTile(
                  icon: Icons.info_outline,
                  title: 'Android alkalmazásbeállítások',
                  subtitle: 'A Fluvi rendszerbeállításainak megnyitása.',
                  status: '',
                  onTap: () => widget.permissions.openAppInfoSettings(),
                ),
              ],
            ),
          ),
          if (widget.runtime != null) ...[
            const SizedBox(height: 22),
            const Text(
              'Futás és háttérfigyelés',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    key: const ValueKey('runtime-foreground-switch'),
                    value: _runtimeStatus?.foregroundRequested ?? false,
                    onChanged: _runtimeUpdating ? null : _changeForeground,
                    secondary: const Icon(Icons.visibility_outlined),
                    title: const Text('Előtérszolgáltatás'),
                    subtitle: const Text(
                      'Bekapcsolva az értesítésfigyelés előtérszolgáltatással működik, és állapotértesítést jelenít meg.',
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    key: const ValueKey('runtime-background-switch'),
                    value: _runtimeStatus?.backgroundRequested ?? false,
                    onChanged: _runtimeUpdating ? null : _changeBackground,
                    secondary: const Icon(Icons.hide_source_outlined),
                    title: const Text('Háttérmód'),
                    subtitle: const Text(
                      'Figyelés a Fluvi felületének bezárása után is. A Fluvi kártyája elrejtőzik a legutóbbi alkalmazások közül.',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    onTap: () =>
                        widget.permissions.openAppNotificationSettings(),
                    leading: Icon(
                      _runtimeStatus?.captureAllowed == true
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                    ),
                    title: const Text('Tényleges állapot'),
                    subtitle: Text(
                      _runtimeStatus?.message ?? 'Állapot ellenőrzése…',
                    ),
                    trailing:
                        (_runtimeStatus?.foregroundRequested == true ||
                            _runtimeStatus?.backgroundRequested == true)
                        ? TextButton(
                            key: const ValueKey('runtime-stop-monitoring'),
                            onPressed: _runtimeUpdating
                                ? null
                                : _stopMonitoring,
                            child: const Text('Leállítás'),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            'Adatkezelés',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'A Fluvi kizárólag az általad kiválasztott és megfigyelésre engedélyezett alkalmazások értesítéseit tárolja. Az értesítések helyben maradnak; az alkalmazás nem küldi el őket külső szolgáltatásnak.',
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: status.isEmpty
        ? const Icon(Icons.chevron_right)
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  color: status == 'Engedélyezve'
                      ? const Color(0xff328365)
                      : const Color(0xffa66b25),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
  );
}
