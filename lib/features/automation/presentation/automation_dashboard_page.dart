import 'package:flutter/material.dart';

import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'notification_inbox_page.dart';
import 'push_profile_details_page.dart';
import 'push_profile_wizard_page.dart';

class AutomationDashboardPage extends StatefulWidget {
  const AutomationDashboardPage({
    super.key,
    required this.repository,
    required this.permissions,
  });
  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  @override
  State<AutomationDashboardPage> createState() =>
      _AutomationDashboardPageState();
}

class _AutomationDashboardPageState extends State<AutomationDashboardPage>
    with WidgetsBindingObserver {
  AutomationDashboardSnapshot? _snapshot;
  AutomationPermissionStatus? _permissions;
  Object? _error;
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
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        widget.repository.dashboard(),
        widget.permissions.getPermissionStatus(),
      ]);
      if (!mounted) {
        return;
      }
      var snapshot = values[0] as AutomationDashboardSnapshot;
      final permissions = values[1] as AutomationPermissionStatus;
      if (permissions.notificationListenerGranted) {
        final awaitingPermission = snapshot.profiles.where(
          (profile) => profile.state == PushProfileState.waitingForPermission,
        );
        for (final profile in awaitingPermission) {
          await widget.repository.updateProfile(
            profileId: profile.profileId,
            displayName: profile.displayName,
            defaultDirection: profile.defaultDirection,
            state: PushProfileState.waitingForTraining,
          );
        }
        if (awaitingPermission.isNotEmpty) {
          snapshot = await widget.repository.dashboard();
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _permissions = permissions;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _newProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PushProfileWizardPage(
          repository: widget.repository,
          permissions: widget.permissions,
        ),
      ),
    );
    if (mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          key: const ValueKey('automation-dashboard-page'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Automatizáció',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'permissions') {
                      widget.permissions.openNotificationAccessSettings();
                    }
                    if (value == 'information') {
                      showDialog<void>(
                        context: context,
                        builder: (context) => const AlertDialog(
                          title: Text('Automatizáció működése'),
                          content: Text(
                            'A Fluvi csak az általad kiválasztott, megfigyelésre engedélyezett alkalmazások értesítéseit tárolja. A szabályok kizárólag sikeres teszt után könyvelhetnek automatikusan.',
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'information',
                      child: Text('Működési információk'),
                    ),
                    PopupMenuItem(
                      value: 'permissions',
                      child: Text('Engedélyek megnyitása'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MonitoringStatus(
              status: _permissions,
              profiles: snapshot?.profiles ?? const [],
              onOpenPermissions: () =>
                  widget.permissions.openNotificationAccessSettings(),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorPanel(error: _error!, onRetry: _refresh)
            else if (snapshot != null) ...[
              if (snapshot.pendingReviewCount > 0) ...[
                const SizedBox(height: 22),
                const Text(
                  'Beavatkozást igényel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.fact_check_outlined,
                  title:
                      '${snapshot.pendingReviewCount} értesítés felülvizsgálatra vár',
                  subtitle:
                      'A kétes találatok nem kerültek automatikusan a Ledgerbe.',
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (_) => NotificationInboxPage(
                            repository: widget.repository,
                            profileId: null,
                            onlyReview: true,
                          ),
                        ),
                      )
                      .then((_) => _refresh()),
                ),
              ],
              const SizedBox(height: 22),
              _Statistics(snapshot: snapshot),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Push profilok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _newProfile,
                    icon: const Icon(Icons.add),
                    label: const Text('Új profil'),
                  ),
                ],
              ),
              if (snapshot.profiles.isEmpty)
                _EmptyProfiles(onAdd: _newProfile)
              else
                ...snapshot.profiles.map(
                  (profile) => _ProfileTile(
                    profile: profile,
                    onTap: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute<void>(
                            builder: (_) => PushProfileDetailsPage(
                              repository: widget.repository,
                              permissions: widget.permissions,
                              profileId: profile.profileId,
                            ),
                          ),
                        )
                        .then((_) => _refresh()),
                  ),
                ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Elkapott értesítések',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute<void>(
                            builder: (_) => NotificationInboxPage(
                              repository: widget.repository,
                              profileId: null,
                            ),
                          ),
                        )
                        .then((_) => _refresh()),
                    child: const Text('Összes'),
                  ),
                ],
              ),
              if (snapshot.recentInbox.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'Még nincs elkapott, engedélyezett forrásból származó értesítés.',
                    style: TextStyle(color: Color(0xff68727d)),
                  ),
                )
              else
                ...snapshot.recentInbox.map(
                  (event) => _InboxPreview(event: event),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonitoringStatus extends StatelessWidget {
  const _MonitoringStatus({
    required this.status,
    required this.profiles,
    required this.onOpenPermissions,
  });
  final AutomationPermissionStatus? status;
  final List<PushProfile> profiles;
  final VoidCallback onOpenPermissions;
  @override
  Widget build(BuildContext context) {
    final monitored = profiles.where(
      (profile) =>
          profile.state != PushProfileState.paused &&
          profile.state != PushProfileState.waitingForPermission,
    );
    final enabled =
        status?.notificationListenerGranted == true && monitored.isNotEmpty;
    final label = enabled
        ? 'Értesítésfigyelés aktív'
        : profiles.isEmpty
        ? 'Nincs még figyelt profil'
        : status?.notificationListenerGranted == true
        ? 'A megfigyelés szüneteltetve'
        : 'Értesítés-hozzáférés szükséges';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpenPermissions,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                enabled
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: enabled
                    ? const Color(0xff328365)
                    : const Color(0xffa66b25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'Engedélyek',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.snapshot});
  final AutomationDashboardSnapshot snapshot;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xfff7f8fa),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat(
          '${snapshot.profiles.where((p) => p.state == PushProfileState.active).length}',
          'aktív profil',
        ),
        _stat('${snapshot.capturedLast30Days}', '30 napos esemény'),
        _stat('${snapshot.pendingReviewCount}', 'ellenőrzendő'),
      ],
    ),
  );
  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xff68727d)),
      ),
    ],
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile, required this.onTap});
  final PushProfile profile;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(
          profile.appLabel.isEmpty
              ? '?'
              : profile.appLabel.substring(0, 1).toUpperCase(),
        ),
      ),
      title: Text(profile.displayName),
      subtitle: Text(
        '${_state(profile.state)} · ${profile.ruleCount} felismerési szabály',
      ),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _InboxPreview extends StatelessWidget {
  const _InboxPreview({required this.event});
  final NotificationInboxItem event;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(
      radius: 18,
      child: Icon(Icons.notifications_none, size: 19),
    ),
    title: Text(
      event.title?.isNotEmpty == true
          ? event.title!
          : event.sourceAppLabel ?? 'Értesítés',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(event.rawText, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Text(
      _review(event.reviewStatus),
      style: const TextStyle(fontSize: 11),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xfffffaf3),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xffa66b25)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _EmptyProfiles extends StatelessWidget {
  const _EmptyProfiles({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Column(
      children: [
        const Text(
          'Még nincs push profil. Csak az általad kiválasztott banki alkalmazások értesítéseit tároljuk.',
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onAdd,
          child: const Text('Első profil létrehozása'),
        ),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      children: [
        const Text('Az automatizáció adatai most nem tölthetők be.'),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onRetry, child: const Text('Újrapróbálás')),
      ],
    ),
  );
}

String _state(PushProfileState state) => switch (state) {
  PushProfileState.waitingForPermission => 'Engedélyre vár',
  PushProfileState.waitingForTraining => 'Tanításra vár',
  PushProfileState.testing => 'Tesztelés alatt',
  PushProfileState.active => 'Aktív',
  PushProfileState.reviewRequired => 'Felülvizsgálat szükséges',
  PushProfileState.paused => 'Szüneteltetett',
};
String _review(PushReviewStatus status) => switch (status) {
  PushReviewStatus.none => 'Új',
  PushReviewStatus.pending => 'Ellenőrzés',
  PushReviewStatus.approved => 'Könyvelve',
  PushReviewStatus.ignored => 'Kihagyva',
  PushReviewStatus.rejected => 'Elutasítva',
};
