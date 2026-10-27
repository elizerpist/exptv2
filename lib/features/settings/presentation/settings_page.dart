import 'package:flutter/material.dart';

import '../../automation/domain/automation_models.dart';
import '../../automation/domain/automation_repository.dart';
import '../../dashboard/application/dashboard_presentation_preferences.dart';
import '../../dashboard/presentation/widgets/dashboard_ghost_quick_filter.dart';
import '../../dashboard/query/domain/ghost_filter_mode.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.permissions,
    required this.dashboardPresentationPreferences,
  });

  final AutomationPermissionRepository permissions;
  final DashboardPresentationPreferencesController
  dashboardPresentationPreferences;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  AutomationPermissionStatus? _status;
  bool _loading = true;
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
    try {
      final status = await widget.permissions.getPermissionStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                    final sent = await widget.permissions
                        .sendTestNotification();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sent
                              ? 'Tesztértesítés elküldve.'
                              : 'A Fluvi értesítési engedélye hiányzik.',
                        ),
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
          const SizedBox(height: 22),
          const Text(
            'Megjelenés',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<DashboardPresentationPreferences>(
            valueListenable: widget.dashboardPresentationPreferences,
            builder: (context, preferences, _) => Card(
              child: ExpansionTile(
                key: const ValueKey('settings-ghost-filter-icon-pack'),
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Ghost szűrő ikonjai'),
                subtitle: const Text('A gyorsszűrő megjelenése'),
                children: DashboardGhostQuickFilterIconPack.values
                    .map((pack) {
                      final selected =
                          preferences.ghostQuickFilterIconPack == pack;
                      return ListTile(
                        key: ValueKey(
                          'settings-ghost-filter-icon-${pack.name}',
                        ),
                        leading: Semantics(
                          selected: selected,
                          child: Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                          ),
                        ),
                        onTap: () {
                          widget.dashboardPresentationPreferences
                              .setPreferences(
                                preferences.withGhostQuickFilterIconPack(pack),
                              );
                        },
                        title: Text(
                          pack == DashboardGhostQuickFilterIconPack.current
                              ? 'Jelenlegi'
                              : 'Bizonylat + szellem',
                        ),
                        subtitle: _GhostIconPackPreview(pack: pack),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
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

final class _GhostIconPackPreview extends StatelessWidget {
  const _GhostIconPackPreview({required this.pack});

  final DashboardGhostQuickFilterIconPack pack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final mode in GhostFilterMode.values) ...<Widget>[
          DashboardGhostQuickFilterIcon(mode: mode, iconPack: pack),
          if (mode != GhostFilterMode.values.last) const SizedBox(width: 8),
        ],
      ],
    ),
  );
}
