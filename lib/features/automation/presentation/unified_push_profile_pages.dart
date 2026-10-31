import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/presentation/child_editor_sheet.dart';
import '../../dashboard/application/dashboard_presentation_preferences.dart';
import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import '../data/automation_update_bridge.dart';
import 'push_profile_navigation.dart';

const _pushInk = Color(0xff19264d);
const _pushMuted = Color(0xff718096);
const _pushDivider = Color(0xffe5e9f0);
const _pushNeutral = Color(0xfff1f5f9);
const _pushGround = Color(0xfff5f6fa);
const _pushBrand = Color(0xff7552b8);

/// The unified, one-page push-profile creator/editor. It uses the existing
/// repository and platform permission APIs; no profile can become an active
/// recorder just because this presentation is selected.
final class UnifiedPushProfileEditorPage extends StatefulWidget {
  const UnifiedPushProfileEditorPage.create({
    super.key,
    required this.repository,
    required this.permissions,
  }) : profile = null;

  const UnifiedPushProfileEditorPage.edit({
    super.key,
    required this.repository,
    required this.permissions,
    required PushProfile this.profile,
  });

  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  final PushProfile? profile;

  @override
  State<UnifiedPushProfileEditorPage> createState() =>
      _UnifiedPushProfileEditorPageState();
}

final class _UnifiedPushProfileEditorPageState
    extends State<UnifiedPushProfileEditorPage>
    with WidgetsBindingObserver {
  final _name = TextEditingController();
  InstalledApplication? _app;
  AutomationPermissionStatus? _permission;
  PushTransactionDirection _direction = PushTransactionDirection.automatic;
  bool _monitor = true;
  bool _nameTouched = false;
  bool _saving = false;
  String? _appError;
  String? _error;

  bool get _editing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final profile = widget.profile;
    if (profile != null) {
      _app = InstalledApplication(
        packageName: profile.packageName,
        label: profile.appLabel,
      );
      _name.text = profile.displayName;
      _nameTouched = true;
      _direction = profile.defaultDirection;
      _monitor = profile.state != PushProfileState.paused;
    }
    _refreshPermission();
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

  Future<void> _refreshPermission() async {
    try {
      final permission = await widget.permissions.getPermissionStatus();
      if (mounted) setState(() => _permission = permission);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _chooseApp() async {
    if (_editing) return;
    final app = await showFluviChildEditorSheet<InstalledApplication>(
      context,
      builder: (_) => _UnifiedPushApplicationPicker(
        repository: widget.repository,
        permissions: widget.permissions,
        selectedPackage: _app?.packageName,
      ),
    );
    if (app == null || !mounted) return;
    setState(() {
      final previousPackage = _app?.packageName;
      _app = app;
      _appError = null;
      if (!_nameTouched || previousPackage != app.packageName) {
        _name.text = app.label;
        _nameTouched = false;
      }
    });
  }

  Future<void> _save() async {
    final app = _app;
    if (app == null) {
      setState(() => _appError = 'Válassz ki egy alkalmazást.');
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Adj meg profilnevet.');
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = _editing
          ? await widget.repository.updateProfile(
              profileId: widget.profile!.profileId,
              displayName: name,
              defaultDirection: _direction,
              state: _monitor
                  ? _resumeState(widget.profile!)
                  : PushProfileState.paused,
            )
          : await widget.repository.createProfile(
              packageName: app.packageName,
              appLabel: app.label,
              displayName: name,
              defaultDirection: _direction,
              monitoringRequested: _monitor,
              notificationAccessGranted:
                  _permission?.notificationListenerGranted ?? false,
            );
      if (!mounted) return;
      if (_editing) {
        Navigator.of(
          context,
        ).pop(PushProfileFlowResult(profileId: profile.profileId));
      } else {
        await Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => UnifiedPushProfileDetailPage(
              repository: widget.repository,
              permissions: widget.permissions,
              profileId: profile.profileId,
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  PushProfileState _resumeState(PushProfile profile) {
    if (profile.ruleCount > 0) return PushProfileState.active;
    return (_permission?.notificationListenerGranted ?? false)
        ? PushProfileState.waitingForTraining
        : PushProfileState.waitingForPermission;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          _PushHero(
            title: _editing ? 'Push profil szerkesztése' : 'Új push profil',
            label: 'Profil',
            value: _app?.label ?? 'Válassz alkalmazást',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _PushFieldRow(
                  icon: Icons.apps_outlined,
                  label: 'Alkalmazás',
                  value: _app?.label ?? 'Alkalmazás kiválasztása',
                  onTap: _editing ? null : _chooseApp,
                  trailing: _editing
                      ? null
                      : const Icon(Icons.chevron_right_rounded),
                  avatar: _app == null ? null : _PushAppAvatar(app: _app!),
                ),
                if (_appError != null) _FieldError(message: _appError!),
                const Divider(height: 1, color: _pushDivider),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: TextField(
                    controller: _name,
                    autofocus: false,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _nameTouched = true,
                    style: const TextStyle(
                      color: _pushInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Profil neve',
                      labelStyle: TextStyle(color: _pushMuted, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const Divider(height: 1, color: _pushDivider),
                _permissionRow(),
                const Divider(height: 1, color: _pushDivider),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _monitor,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _monitor = value),
                  title: const Text(
                    'Értesítések gyűjtése',
                    style: TextStyle(
                      color: _pushInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Az automatikus rögzítéshez előbb felismerési szabályt kell beállítani.',
                    style: TextStyle(color: _pushMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xfff2f4f8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: _pushMuted,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A profil létrehozása után egy beérkezett értesítésből megtaníthatod a felismerést.',
                            style: TextStyle(
                              color: _pushMuted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) _FieldError(message: _error!),
              ],
            ),
          ),
          _PushFooter(
            primaryLabel: _editing ? 'Mentés' : 'Létrehozás',
            busy: _saving,
            onCancel: () => Navigator.of(context).maybePop(),
            onPrimary: _save,
          ),
        ],
      ),
    ),
  );

  Widget _permissionRow() {
    final status = _permission;
    final available = status?.notificationListenerAvailable ?? false;
    final granted = status?.notificationListenerGranted ?? false;
    final label = !available
        ? 'Ezen az eszközön nem elérhető'
        : granted
        ? 'Engedélyezve'
        : 'Engedélyezés szükséges';
    return _PushFieldRow(
      icon: Icons.notifications_outlined,
      label: 'Értesítés-hozzáférés',
      value: label,
      helper:
          'A Fluvi csak a kiválasztott alkalmazás értesítéseit dolgozza fel.',
      trailing: !available || granted
          ? null
          : TextButton(
              onPressed: () async {
                await widget.permissions.openNotificationAccessSettings();
                _refreshPermission();
              },
              child: const Text('Engedélyezés'),
            ),
    );
  }
}

final class _UnifiedPushApplicationPicker extends StatefulWidget {
  const _UnifiedPushApplicationPicker({
    required this.repository,
    required this.permissions,
    this.selectedPackage,
  });
  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  final String? selectedPackage;

  @override
  State<_UnifiedPushApplicationPicker> createState() =>
      _UnifiedPushApplicationPickerState();
}

final class _UnifiedPushApplicationPickerState
    extends State<_UnifiedPushApplicationPicker> {
  List<InstalledApplication>? _apps;
  Set<String> _usedPackages = const {};
  String _query = '';
  bool _showSystemApps = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _apps = null;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        widget.permissions.listInstalledApps(),
        widget.repository.listProfiles(),
      ]);
      if (!mounted) return;
      setState(() {
        _apps = values[0] as List<InstalledApplication>;
        _usedPackages = (values[1] as List<PushProfile>)
            .map((profile) => profile.packageName)
            .toSet();
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    return ChildEditorSheetScaffold(
      title: 'Alkalmazás kiválasztása',
      applying: false,
      onCancel: () => Navigator.of(context).pop(),
      onApply: null,
      body: SizedBox(
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Alkalmazás keresése',
                filled: true,
                fillColor: _pushNeutral,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('push-app-picker-system-toggle'),
                onPressed: () =>
                    setState(() => _showSystemApps = !_showSystemApps),
                icon: Icon(
                  _showSystemApps
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  size: 18,
                ),
                label: const Text('Rendszeralkalmazások mutatása'),
              ),
            ),
            Expanded(
              child: apps == null
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: TextButton(
                        onPressed: _load,
                        child: const Text(
                          'Az alkalmazáslista nem tölthető be. Újrapróbálás',
                        ),
                      ),
                    )
                  : _appList(apps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appList(List<InstalledApplication> source) {
    final query = _query.trim().toLowerCase();
    final apps = source
        .where(
          (app) =>
              (_showSystemApps || !app.isSystemApp) &&
              (query.isEmpty ||
                  app.label.toLowerCase().contains(query) ||
                  app.packageName.toLowerCase().contains(query)),
        )
        .toList(growable: false);
    if (apps.isEmpty) return const Center(child: Text('Nincs találat.'));
    return ListView.separated(
      itemCount: apps.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: _pushDivider),
      itemBuilder: (context, index) {
        final app = apps[index];
        final used =
            _usedPackages.contains(app.packageName) &&
            app.packageName != widget.selectedPackage;
        return ListTile(
          leading: _LazyPushAppAvatar(
            app: app,
            permissions: widget.permissions,
          ),
          title: Text(
            app.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: used
              ? const Text('Már beállítva')
              : Text(
                  app.enabled
                      ? app.packageName
                      : '${app.packageName} · letiltva',
                ),
          trailing: used
              ? const Icon(Icons.check_circle_outline, color: _pushMuted)
              : null,
          onTap: () => Navigator.of(context).pop(app),
        );
      },
    );
  }
}

/// New push-profile overview. Its state cards are derived from persisted
/// profile/rule/inbox values plus the live platform permission, rather than
/// inventing a second profile state machine for the new surface.
final class UnifiedPushProfileDetailPage extends StatefulWidget {
  const UnifiedPushProfileDetailPage({
    super.key,
    required this.repository,
    required this.permissions,
    required this.profileId,
  });

  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  final String profileId;

  @override
  State<UnifiedPushProfileDetailPage> createState() =>
      _UnifiedPushProfileDetailPageState();
}

final class _UnifiedPushProfileDetailPageState
    extends State<UnifiedPushProfileDetailPage>
    with WidgetsBindingObserver {
  PushProfile? _profile;
  List<PushRule> _rules = const [];
  List<NotificationInboxItem> _inbox = const [];
  AutomationPermissionStatus? _permission;
  Object? _error;
  bool _loading = true;

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
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final values = await Future.wait<Object>([
        widget.repository.profile(widget.profileId),
        widget.repository.rules(widget.profileId),
        widget.repository.inbox(profileId: widget.profileId, limit: 8),
        widget.permissions.getPermissionStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = values[0] as PushProfile;
        _rules = values[1] as List<PushRule>;
        _inbox = values[2] as List<NotificationInboxItem>;
        _permission = values[3] as AutomationPermissionStatus;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  Future<void> _edit() async {
    final profile = _profile;
    if (profile == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UnifiedPushProfileEditorPage.edit(
          repository: widget.repository,
          permissions: widget.permissions,
          profile: profile,
        ),
      ),
    );
    _load();
  }

  Future<void> _setMonitoring(bool monitoring) async {
    final profile = _profile;
    if (profile == null) return;
    final state = monitoring
        ? (_rules.any((rule) => rule.state == PushRuleState.active)
              ? PushProfileState.active
              : (_permission?.notificationListenerGranted ?? false)
              ? PushProfileState.waitingForTraining
              : PushProfileState.waitingForPermission)
        : PushProfileState.paused;
    await widget.repository.updateProfile(
      profileId: profile.profileId,
      displayName: profile.displayName,
      defaultDirection: profile.defaultDirection,
      state: state,
    );
    _load();
  }

  Future<void> _delete() async {
    final profile = _profile;
    if (profile == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Push profil törlése?'),
        content: const Text(
          'A profil szabályai és tanítási mintái törlődnek. A már rögzített Ledger-tranzakciók megmaradnak; a kapcsolódó ismétlődések Beállításra vár állapotban maradnak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Profil törlése'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await widget.repository.deleteProfile(profile.profileId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openTraining() async {
    final profile = _profile;
    if (profile == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UnifiedPushTrainingPickerPage(
          repository: widget.repository,
          permissions: widget.permissions,
          profile: profile,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || profile == null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: _load,
            child: const Text('A profil nem tölthető be. Újrapróbálás'),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _PushHero(
              title: 'Push profil',
              label: 'Profil neve',
              value: profile.displayName,
              onBack: () => Navigator.of(context).maybePop(),
              menu: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _edit();
                  if (action == 'monitor') {
                    _setMonitoring(profile.state == PushProfileState.paused);
                  }
                  if (action == 'delete') _delete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Profil szerkesztése'),
                  ),
                  PopupMenuItem(
                    value: 'monitor',
                    child: Text(
                      profile.state == PushProfileState.paused
                          ? 'Gyűjtés folytatása'
                          : 'Gyűjtés szüneteltetése',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Profil törlése'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    _stateRow(
                      Icons.notifications_outlined,
                      'Értesítések gyűjtése',
                      profile.state == PushProfileState.paused
                          ? 'Szünetel'
                          : 'Bekapcsolva',
                    ),
                    const Divider(height: 1, color: _pushDivider),
                    _stateRow(
                      Icons.auto_awesome_outlined,
                      'Automatikus rögzítés',
                      _rules.any((rule) => rule.state == PushRuleState.active)
                          ? 'Van aktív szabály'
                          : 'Még nincs aktív szabály',
                    ),
                    const SizedBox(height: 24),
                    _nextStep(profile),
                    const SizedBox(height: 26),
                    _sectionHeader(
                      'Felismerési szabályok',
                      action: 'Új szabály',
                      onTap: _openTraining,
                    ),
                    if (_rules.isEmpty)
                      const _EmptyCopy(
                        'Még nincs felismerési szabály. Egy valódi, elkapott üzenetből taníthatod meg a felismerést.',
                      )
                    else
                      ..._rules.map(
                        (rule) => _PushRuleRow(
                          rule: rule,
                          onTap: () => _openRule(rule),
                        ),
                      ),
                    const SizedBox(height: 26),
                    _sectionHeader(
                      'Legutóbbi értesítések',
                      action: 'Összes',
                      onTap: () => PushProfileNavigation.openInbox(
                        context,
                        design: PushProfileUiDesign.unified,
                        repository: widget.repository,
                        permissions: widget.permissions,
                        profileId: profile.profileId,
                      ),
                    ),
                    if (_inbox.isEmpty)
                      const _EmptyCopy(
                        'Várjuk az első értesítést. Ez természetes várakozó állapot.',
                      )
                    else
                      ..._inbox.map(
                        (item) => _PushInboxRow(
                          item: item,
                          onTap: () => _openInboxItem(item),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stateRow(IconData icon, String label, String value) =>
      _PushFieldRow(icon: icon, label: label, value: value);

  Widget _nextStep(PushProfile profile) {
    final permission = _permission;
    final hasPermission = permission?.notificationListenerGranted ?? false;
    final pending = _inbox
        .where((item) => item.reviewStatus == PushReviewStatus.pending)
        .length;
    String title;
    String copy;
    String? action;
    VoidCallback? onTap;
    if (!(permission?.notificationListenerAvailable ?? false) ||
        !hasPermission) {
      title = 'Értesítés-hozzáférés szükséges';
      copy =
          'Engedélyezd az értesítés-hozzáférést, hogy a Fluvi a kiválasztott alkalmazás üzeneteit gyűjthesse.';
      action = 'Engedélyezés';
      onTap = () async {
        await widget.permissions.openNotificationAccessSettings();
        _load();
      };
    } else if (profile.state == PushProfileState.paused) {
      title = 'A gyűjtés szünetel';
      copy = 'A profil megtartja szabályait, de új értesítést nem dolgoz fel.';
      action = 'Gyűjtés folytatása';
      onTap = () => _setMonitoring(true);
    } else if (pending > 0) {
      title = '$pending értesítés ellenőrzésre vár';
      copy = 'A kétes találatok nem kerülnek automatikusan a Ledgerbe.';
      action = 'Áttekintés';
      onTap = () => PushProfileNavigation.openInbox(
        context,
        design: PushProfileUiDesign.unified,
        repository: widget.repository,
        permissions: widget.permissions,
        profileId: profile.profileId,
        onlyReview: true,
      );
    } else if (_inbox.isEmpty) {
      title = 'Várjuk az első értesítést.';
      copy =
          'Amint a kiválasztott alkalmazás értesítést küld, ebből taníthatod meg a felismerést.';
    } else if (_rules.isEmpty) {
      title = 'Van tanítható értesítés';
      copy =
          'Válassz egy eredeti üzenetet, jelöld ki az összeget és a partnert, majd próbáld ki a szabályt.';
      action = 'Tanítás elkezdése';
      onTap = _openTraining;
    } else {
      title = 'A profil használatra kész';
      copy =
          'Az aktív szabályok csak az új, megfelelő értesítéseket dolgozzák fel.';
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _pushNeutral,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Következő lépés',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _pushMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: _pushInk,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              copy,
              style: const TextStyle(
                color: _pushMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            if (action != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onTap, child: Text(action)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRule(PushRule rule) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UnifiedPushRuleDetailPage(
          repository: widget.repository,
          permissions: widget.permissions,
          profileId: widget.profileId,
          rule: rule,
        ),
      ),
    );
    _load();
  }

  Future<void> _openInboxItem(NotificationInboxItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UnifiedPushInboxDetailPage(
          repository: widget.repository,
          item: item,
        ),
      ),
    );
    _load();
  }
}

/// A paged selection list: unlike the legacy first-100 list it keeps loading
/// historical notifications as the user reaches the end.
final class UnifiedPushTrainingPickerPage extends StatefulWidget {
  const UnifiedPushTrainingPickerPage({
    super.key,
    required this.repository,
    required this.permissions,
    required this.profile,
  });
  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  final PushProfile profile;

  @override
  State<UnifiedPushTrainingPickerPage> createState() =>
      _UnifiedPushTrainingPickerPageState();
}

final class _UnifiedPushTrainingPickerPageState
    extends State<UnifiedPushTrainingPickerPage> {
  final _scroll = ScrollController();
  final List<NotificationInboxItem> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;
  StreamSubscription<void>? _automationUpdates;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 240) _loadMore();
    });
    _loadMore();
    _automationUpdates = AutomationUpdateBridge.changes.listen(
      (_) => _loadMore(reset: true),
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _automationUpdates?.cancel();
    super.dispose();
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _hasMore = true;
      }
    });
    try {
      final page = await widget.repository.inbox(
        profileId: widget.profile.profileId,
        offset: _items.length,
        limit: 40,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == 40;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _pushGround,
    appBar: AppBar(title: const Text('Válassz egy értesítést')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Text(
            '${widget.profile.displayName} · egy eredeti üzenetből taníthatsz szabályt',
            style: const TextStyle(color: _pushMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: _items.isEmpty && _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? _EmptyTrainingInbox(
                  error: _error,
                  onRetry: () => _loadMore(reset: true),
                )
              : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 1),
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = _items[index];
                    return DecoratedBox(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: _PushInboxRow(
                        item: item,
                        onTap: () => Navigator.of(context)
                            .push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => UnifiedPushTrainingEditorPage(
                                  repository: widget.repository,
                                  profile: widget.profile,
                                  item: item,
                                ),
                              ),
                            )
                            .then((_) => _loadMore(reset: true)),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

final class _EmptyTrainingInbox extends StatelessWidget {
  const _EmptyTrainingInbox({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_paused_outlined,
            size: 36,
            color: _pushMuted,
          ),
          const SizedBox(height: 12),
          Text(
            error == null
                ? 'Még nem érkezett értesítés ehhez a profilhoz.'
                : 'Az értesítések nem tölthetők be.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ellenőrizd az értesítés-hozzáférést és hogy a gyűjtés be van kapcsolva.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _pushMuted, fontSize: 12),
          ),
          if (error != null)
            TextButton(onPressed: onRetry, child: const Text('Újrapróbálás')),
        ],
      ),
    ),
  );
}

/// Guided, but reversible, field selection on the exact raw notification
/// text. Flutter selections use UTF-16 offsets, the same unit passed to Core.
final class UnifiedPushTrainingEditorPage extends StatefulWidget {
  const UnifiedPushTrainingEditorPage({
    super.key,
    required this.repository,
    required this.profile,
    required this.item,
  });
  final AutomationRepository repository;
  final PushProfile profile;
  final NotificationInboxItem item;

  @override
  State<UnifiedPushTrainingEditorPage> createState() =>
      _UnifiedPushTrainingEditorPageState();
}

final class _UnifiedPushTrainingEditorPageState
    extends State<UnifiedPushTrainingEditorPage> {
  final _name = TextEditingController(text: 'Új felismerési szabály');
  final List<PushFieldSpan> _spans = [];
  PushSampleKind _kind = PushSampleKind.transaction;
  LedgerDirection _direction = LedgerDirection.expense;
  TextSelection _selection = const TextSelection.collapsed(offset: -1);
  String? _message;
  bool _testing = false;
  PushRule? _trialRule;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addRole(PushFieldRole role) {
    final selection = _selection;
    if (!selection.isValid || selection.isCollapsed || selection.start < 0) {
      setState(() => _message = 'Előbb jelölj ki egy szövegrészt.');
      return;
    }
    final overlaps = _spans.any(
      (span) =>
          !(selection.end <= span.start ||
              selection.start >= span.endExclusive),
    );
    final duplicate =
        role != PushFieldRole.ignore && _spans.any((span) => span.role == role);
    if (overlaps || duplicate) {
      setState(
        () => _message = overlaps
            ? 'A kijelölések nem fedhetik egymást.'
            : 'Ehhez a szerephez már van kijelölés.',
      );
      return;
    }
    setState(() {
      _spans.add(
        PushFieldSpan(
          start: selection.start,
          endExclusive: selection.end,
          role: role,
        ),
      );
      _spans.sort((a, b) => a.start.compareTo(b.start));
      _message = null;
    });
  }

  bool get _complete =>
      _kind != PushSampleKind.transaction ||
      _spans.any((span) => span.role == PushFieldRole.amount) &&
          _spans.any((span) => span.role == PushFieldRole.merchant);

  Future<void> _test() async {
    if (!_complete) {
      setState(() => _message = 'Az Összeg és a Partner kijelölése kötelező.');
      return;
    }
    if (_testing) return;
    setState(() {
      _testing = true;
      _message = null;
    });
    try {
      if (_kind != PushSampleKind.transaction) {
        await widget.repository.addTrainingSample(
          profileId: widget.profile.profileId,
          notificationId: widget.item.notificationId,
          kind: _kind,
          spansJson: jsonEncode(_spans.map((span) => span.toMap()).toList()),
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final name = _name.text.trim().isEmpty
          ? 'Új felismerési szabály'
          : _name.text.trim();
      final existing = _trialRule;
      final rule = existing == null
          ? await widget.repository.createRule(
              profileId: widget.profile.profileId,
              notificationId: widget.item.notificationId,
              name: name,
              direction: _direction,
              spans: _spans,
            )
          : await widget.repository.updateRule(
              ruleId: existing.ruleId,
              expectedVersion: existing.version,
              notificationId: widget.item.notificationId,
              name: name,
              direction: _direction,
              spans: _spans,
            );
      _trialRule = rule;
      final report = await widget.repository.backtest(rule.ruleId);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UnifiedPushTestResultPage(
            repository: widget.repository,
            profile: widget.profile,
            item: widget.item,
            ruleId: rule.ruleId,
            report: report,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Felismerés tanítása')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${widget.profile.appLabel} · ${_humanDate(widget.item.receivedAtUtcMs)}',
              style: const TextStyle(color: _pushMuted, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _kindSelector(),
              const SizedBox(height: 18),
              const Text(
                'Eredeti értesítés',
                style: TextStyle(
                  color: _pushInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _pushNeutral,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    widget.item.rawText,
                    style: const TextStyle(
                      color: _pushInk,
                      fontSize: 16,
                      height: 1.45,
                    ),
                    onSelectionChanged: (selection, _) =>
                        setState(() => _selection = selection),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _nextPrompt,
                style: const TextStyle(
                  color: _pushInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _roleButton('Összeg', PushFieldRole.amount),
                  _roleButton('Partner', PushFieldRole.merchant),
                  _roleButton('Egyenleg', PushFieldRole.balance),
                  _roleButton('Számla / kártya', PushFieldRole.account),
                  _roleButton('Pénznem', PushFieldRole.currency),
                  _roleButton('Más változó rész', PushFieldRole.ignore),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Kijelölt adatok',
                style: TextStyle(
                  color: _pushInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              _selectionSummary(),
              if (_kind == PushSampleKind.transaction) ...[
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  autofocus: false,
                  decoration: const InputDecoration(labelText: 'Szabály neve'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<LedgerDirection>(
                  segments: const [
                    ButtonSegment(
                      value: LedgerDirection.expense,
                      label: Text('Kiadás'),
                    ),
                    ButtonSegment(
                      value: LedgerDirection.income,
                      label: Text('Bevétel'),
                    ),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (value) =>
                      setState(() => _direction = value.first),
                ),
              ],
              if (_message != null) _FieldError(message: _message!),
            ],
          ),
        ),
        _PushFooter(
          primaryLabel: _kind == PushSampleKind.transaction
              ? 'Kipróbálás'
              : 'Mentés',
          busy: _testing,
          onCancel: () => Navigator.of(context).maybePop(),
          onPrimary: _test,
        ),
      ],
    ),
  );

  String get _nextPrompt {
    if (_kind != PushSampleKind.transaction) {
      return 'A minta besorolása rögzíthető.';
    }
    if (!_spans.any((span) => span.role == PushFieldRole.amount)) {
      return 'Jelöld ki a tranzakció összegét.';
    }
    if (!_spans.any((span) => span.role == PushFieldRole.merchant)) {
      return 'Jelöld ki a partner nevét.';
    }
    return 'Jelöld meg a további változó adatokat, ha vannak.';
  }

  Widget _kindSelector() => SegmentedButton<PushSampleKind>(
    segments: const [
      ButtonSegment(
        value: PushSampleKind.transaction,
        label: Text('Tranzakció'),
      ),
      ButtonSegment(
        value: PushSampleKind.nonTransaction,
        label: Text('Nem tranzakció'),
      ),
      ButtonSegment(
        value: PushSampleKind.failedTransaction,
        label: Text('Sikertelen tranzakció'),
      ),
    ],
    selected: {_kind},
    showSelectedIcon: false,
    onSelectionChanged: (value) {
      if (_trialRule != null && value.first != PushSampleKind.transaction) {
        setState(
          () => _message =
              'A próbaszabály már létezik. Módosítsd a kijelöléseket, vagy lépj vissza a próba elvetéséhez.',
        );
        return;
      }
      setState(() => _kind = value.first);
    },
  );

  Widget _roleButton(String label, PushFieldRole role) =>
      OutlinedButton(onPressed: () => _addRole(role), child: Text(label));

  Widget _selectionSummary() => Column(
    children: [
      for (final role in [
        PushFieldRole.amount,
        PushFieldRole.merchant,
        PushFieldRole.balance,
        PushFieldRole.account,
        PushFieldRole.currency,
        PushFieldRole.ignore,
      ])
        ..._spans.where((span) => span.role == role).isEmpty
            ? [
                _SummarySpan(
                  label: _roleLabel(role),
                  value:
                      role == PushFieldRole.amount ||
                          role == PushFieldRole.merchant
                      ? 'Nincs kijelölve'
                      : '—',
                ),
              ]
            : _spans
                  .where((span) => span.role == role)
                  .map(
                    (span) => _SummarySpan(
                      label: _roleLabel(role),
                      value: widget.item.rawText.substring(
                        span.start,
                        span.endExclusive,
                      ),
                      onDelete: () => setState(() => _spans.remove(span)),
                    ),
                  ),
    ],
  );
}

final class UnifiedPushTestResultPage extends StatefulWidget {
  const UnifiedPushTestResultPage({
    super.key,
    required this.repository,
    required this.profile,
    this.item,
    required this.ruleId,
    required this.report,
  });
  final AutomationRepository repository;
  final PushProfile profile;
  final NotificationInboxItem? item;
  final String ruleId;
  final PushRuleTestReport report;

  @override
  State<UnifiedPushTestResultPage> createState() =>
      _UnifiedPushTestResultPageState();
}

final class _UnifiedPushTestResultPageState
    extends State<UnifiedPushTestResultPage> {
  bool _activating = false;
  String? _error;

  Future<void> _activate() async {
    if (!widget.report.activationReady || _activating) return;
    setState(() {
      _activating = true;
      _error = null;
    });
    try {
      final rule = await widget.repository.activateRule(widget.ruleId);
      if (!mounted) return;
      Navigator.of(context).pop(
        PushProfileFlowResult(
          profileId: widget.profile.profileId,
          ruleId: rule.ruleId,
          ruleState: rule.state,
        ),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Próba eredménye')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                const Text(
                  'Ezt a tranzakciót vizsgálta a szabály',
                  style: TextStyle(
                    color: _pushInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _pushNeutral,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile.displayName,
                          style: const TextStyle(
                            color: _pushInk,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item == null
                              ? 'A tárolt mintaértesítés ebben a Core-verzióban nem kérhető le közvetlenül.'
                              : 'Forrásértesítés: ${_humanDate(widget.item!.receivedAtUtcMs)}',
                          style: const TextStyle(
                            color: _pushMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.item != null)
                          Text(
                            widget.item!.rawText,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _pushInk),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Ellenőrzés korábbi értesítéseken',
                  style: TextStyle(
                    color: _pushInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'A riport a Core parser aktuális szabályverziójának eredménye; nem jelent validált pontossági százalékot.',
                  style: TextStyle(
                    color: _pushMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                _ReportLine(
                  'Felismerve',
                  report.matchedCount,
                  Icons.check_circle_outline,
                  const Color(0xff328365),
                ),
                _ReportLine(
                  'Javítást igényel',
                  report.reviewCount,
                  Icons.fact_check_outlined,
                  const Color(0xffb7791f),
                ),
                _ReportLine(
                  'Nem illeszkedik',
                  report.rejectedCount,
                  Icons.remove_circle_outline,
                  _pushMuted,
                ),
                _ReportLine(
                  'Másik szabállyal ütközik',
                  report.conflictedCount,
                  Icons.warning_amber_rounded,
                  const Color(0xffb4233c),
                ),
                if (!report.activationReady)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'A jelenlegi próba alapján a szabály még nem aktiválható. Javítsd a kijelöléseket, majd futtasd újra a próbát.',
                      style: TextStyle(color: Color(0xffb4233c), fontSize: 12),
                    ),
                  ),
                if (_error != null) _FieldError(message: _error!),
              ],
            ),
          ),
          _PushFooter(
            primaryLabel: 'Aktiválás',
            busy: _activating,
            primaryEnabled: report.activationReady,
            onCancel: () => Navigator.of(context).maybePop(),
            onPrimary: _activate,
            cancelLabel: 'Javítás',
          ),
        ],
      ),
    );
  }
}

final class _ReportLine extends StatelessWidget {
  const _ReportLine(this.label, this.count, this.icon, this.color);
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _pushInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(color: _pushInk, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

final class UnifiedPushRuleDetailPage extends StatefulWidget {
  const UnifiedPushRuleDetailPage({
    super.key,
    required this.repository,
    required this.permissions,
    required this.profileId,
    required this.rule,
  });
  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  final String profileId;
  final PushRule rule;
  @override
  State<UnifiedPushRuleDetailPage> createState() =>
      _UnifiedPushRuleDetailPageState();
}

final class _UnifiedPushRuleDetailPageState
    extends State<UnifiedPushRuleDetailPage> {
  bool _busy = false;
  String? _message;
  Future<void> _test() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final report = await widget.repository.backtest(widget.rule.ruleId);
      if (!mounted) return;
      final profile = await widget.repository.profile(widget.profileId);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UnifiedPushTestResultPage(
            repository: widget.repository,
            profile: profile,
            ruleId: widget.rule.ruleId,
            report: report,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (widget.rule.state == PushRuleState.active) {
        // The current public Core API exposes activation but not an explicit
        // rule pause command; preserve that truth in the UI instead of a fake
        // state-changing control.
        setState(
          () => _message =
              'A szabály szüneteltetése ebben a Core-verzióban még nem érhető el.',
        );
      } else {
        await widget.repository.activateRule(widget.rule.ruleId);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Felismerési szabály')),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.rule.name,
                style: const TextStyle(
                  color: _pushInk,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.rule.direction == LedgerDirection.expense ? 'Kiadás' : 'Bevétel'} · ${_ruleStateLabel(widget.rule.state)} · v${widget.rule.version}',
                style: const TextStyle(color: _pushMuted),
              ),
              const SizedBox(height: 24),
              _PushFieldRow(
                icon: Icons.account_tree_outlined,
                label: 'Profil',
                value: widget.profileId,
              ),
              const Divider(height: 1, color: _pushDivider),
              _PushFieldRow(
                icon: Icons.verified_outlined,
                label: 'Állapot',
                value: _ruleStateLabel(widget.rule.state),
              ),
              const Divider(height: 1, color: _pushDivider),
              _PushFieldRow(
                icon: Icons.speed_outlined,
                label: 'Legutóbbi próba',
                value: 'Próba újrafuttatható',
              ),
              if (_message != null) _FieldError(message: _message!),
            ],
          ),
        ),
        _PushFooter(
          primaryLabel: widget.rule.state == PushRuleState.active
              ? 'Aktív'
              : 'Aktiválás',
          busy: _busy,
          primaryEnabled: widget.rule.state != PushRuleState.active,
          onCancel: _test,
          cancelLabel: 'Próba újra',
          onPrimary: _toggle,
        ),
      ],
    ),
  );
}

/// New notification manager. It requests successive pages from the repository
/// instead of narrowing an arbitrary in-memory first page.
final class UnifiedPushInboxPage extends StatefulWidget {
  const UnifiedPushInboxPage({
    super.key,
    required this.repository,
    required this.permissions,
    this.profileId,
    this.onlyReview = false,
    this.onConfigureApplication,
  });
  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  final String? profileId;
  final bool onlyReview;
  final Future<void> Function()? onConfigureApplication;

  @override
  State<UnifiedPushInboxPage> createState() => _UnifiedPushInboxPageState();
}

final class _UnifiedPushInboxPageState extends State<UnifiedPushInboxPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final List<NotificationInboxItem> _items = [];
  PushReviewStatus? _filter;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;
  StreamSubscription<void>? _automationUpdates;

  @override
  void initState() {
    super.initState();
    _filter = widget.onlyReview ? PushReviewStatus.pending : null;
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 240) _loadMore();
    });
    _loadMore();
    _automationUpdates = AutomationUpdateBridge.changes.listen(
      (_) => _loadMore(reset: true),
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _automationUpdates?.cancel();
    super.dispose();
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _hasMore = true;
      }
    });
    try {
      final page = await widget.repository.inbox(
        profileId: widget.profileId,
        reviewStatus: _filter,
        offset: _items.length,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == 50;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final shown = _items
        .where((item) {
          final matchesSearch =
              query.isEmpty ||
              item.rawText.toLowerCase().contains(query) ||
              (item.title?.toLowerCase().contains(query) ?? false) ||
              (item.sourceAppLabel?.toLowerCase().contains(query) ?? false);
          return matchesSearch;
        })
        .toList(growable: false);
    return Scaffold(
      backgroundColor: _pushGround,
      appBar: AppBar(title: const Text('Értesítések')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _search,
              autofocus: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Értesítés keresése',
                filled: true,
                fillColor: _pushNeutral,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                for (final status in <PushReviewStatus?>[
                  null,
                  PushReviewStatus.pending,
                  PushReviewStatus.approved,
                  PushReviewStatus.ignored,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_reviewLabel(status)),
                      selected: _filter == status,
                      onSelected: widget.onlyReview
                          ? null
                          : (_) {
                              if (_filter == status) return;
                              setState(() => _filter = status);
                              _loadMore(reset: true);
                            },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : shown.isEmpty
                ? _InboxEmptyState(
                    error: _error,
                    canConfigure:
                        widget.profileId == null && !widget.onlyReview,
                    onConfigureApplication: widget.onConfigureApplication,
                    onRetry: () => _loadMore(reset: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadMore(reset: true),
                    child: ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: shown.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 1),
                      itemBuilder: (context, index) {
                        if (index == shown.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = shown[index];
                        return DecoratedBox(
                          decoration: const BoxDecoration(color: Colors.white),
                          child: _PushInboxRow(
                            item: item,
                            onTap: () => Navigator.of(context)
                                .push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => UnifiedPushInboxDetailPage(
                                      repository: widget.repository,
                                      item: item,
                                    ),
                                  ),
                                )
                                .then((_) => _loadMore(reset: true)),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

final class _InboxEmptyState extends StatelessWidget {
  const _InboxEmptyState({
    required this.error,
    required this.canConfigure,
    required this.onConfigureApplication,
    required this.onRetry,
  });

  final Object? error;
  final bool canConfigure;
  final Future<void> Function()? onConfigureApplication;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            error == null ? Icons.inbox_outlined : Icons.error_outline,
            color: _pushMuted,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            error == null
                ? 'Még nincs banki értesítés.'
                : 'Az értesítések nem tölthetők be.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _pushInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error == null
                ? 'Az első üzenethez válassz alkalmazást, majd kapcsold be a gyűjtést.'
                : 'Próbáld újra, az eddigi adatok változatlanok maradnak.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _pushMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          if (error != null)
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Újrapróbálás'),
            )
          else if (canConfigure && onConfigureApplication != null)
            FilledButton.icon(
              onPressed: () => onConfigureApplication!(),
              icon: const Icon(Icons.add),
              label: const Text('Alkalmazás beállítása'),
            ),
        ],
      ),
    ),
  );
}

final class UnifiedPushInboxDetailPage extends StatefulWidget {
  const UnifiedPushInboxDetailPage({
    super.key,
    required this.repository,
    required this.item,
    this.onOpenLedgerEntry,
  });
  final AutomationRepository repository;
  final NotificationInboxItem item;
  final Future<void> Function(String ledgerEntryId)? onOpenLedgerEntry;
  @override
  State<UnifiedPushInboxDetailPage> createState() =>
      _UnifiedPushInboxDetailPageState();
}

final class _UnifiedPushInboxDetailPageState
    extends State<UnifiedPushInboxDetailPage> {
  late final TextEditingController _partner;
  final _amount = TextEditingController();
  LedgerDirection _direction = LedgerDirection.expense;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _partner = TextEditingController();
    final raw = widget.item.suggestedPayloadJson;
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<Object?, Object?>;
        final amount = (map['amountScaled100'] as num?)?.toInt();
        if (amount != null && amount > 0) _amount.text = _money(amount);
        _partner.text = map['merchant'] as String? ?? '';
        _direction = switch (map['direction']) {
          'income' => LedgerDirection.income,
          _ => LedgerDirection.expense,
        };
      } on Object {
        // A malformed historical diagnostic never blocks a manual review.
      }
    }
  }

  @override
  void dispose() {
    _partner.dispose();
    _amount.dispose();
    super.dispose();
  }

  int? get _minor => _parseMinor(_amount.text);
  Future<void> _trainFromNotification() async {
    final profileId = widget.item.profileId;
    if (profileId == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await widget.repository.profile(profileId);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UnifiedPushTrainingEditorPage(
            repository: widget.repository,
            profile: profile,
            item: widget.item,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _approve() async {
    final amount = _minor;
    if (amount == null || _partner.text.trim().isEmpty || _saving) {
      setState(() => _error = 'Adj meg pozitív összeget és partnert.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final local = DateTime.fromMillisecondsSinceEpoch(
        widget.item.receivedAtUtcMs,
      );
      await widget.repository.approveReview(
        notificationId: widget.item.notificationId,
        merchantName: _partner.text.trim(),
        direction: _direction,
        amountScaled100: amount,
        bookedLocalEpochDay: DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).difference(DateTime.utc(1970)).inDays,
        bookedLocalTimeMinutes: local.hour * 60 + local.minute,
        occurredAtUtcMs: widget.item.receivedAtUtcMs,
      );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final recorded = item.ledgerEntryId != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(recorded ? 'Rögzített értesítés' : 'Értesítés részletei'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                Text(
                  item.sourceAppLabel ?? 'Forrásalkalmazás',
                  style: const TextStyle(
                    color: _pushInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _humanDate(item.receivedAtUtcMs),
                  style: const TextStyle(color: _pushMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _pushNeutral,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      item.rawText,
                      style: const TextStyle(
                        color: _pushInk,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _PushFieldRow(
                  icon: Icons.fact_check_outlined,
                  label: 'Feldolgozási állapot',
                  value: _reviewLabel(item.reviewStatus),
                ),
                if (!recorded &&
                    item.reviewStatus == PushReviewStatus.pending) ...[
                  const Divider(height: 1, color: _pushDivider),
                  TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Összeg (Ft)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _partner,
                    decoration: const InputDecoration(labelText: 'Partner'),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<LedgerDirection>(
                    segments: const [
                      ButtonSegment(
                        value: LedgerDirection.expense,
                        label: Text('Kiadás'),
                      ),
                      ButtonSegment(
                        value: LedgerDirection.income,
                        label: Text('Bevétel'),
                      ),
                    ],
                    selected: {_direction},
                    onSelectionChanged: (value) =>
                        setState(() => _direction = value.first),
                  ),
                ],
                if (_error != null) _FieldError(message: _error!),
              ],
            ),
          ),
          if (!recorded && item.reviewStatus == PushReviewStatus.pending)
            _PushFooter(
              primaryLabel: 'Jóváhagyás',
              busy: _saving,
              onCancel: () async {
                await widget.repository.ignoreReview(item.notificationId);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              cancelLabel: 'Kihagyás',
              onPrimary: _approve,
            )
          else if (!recorded &&
              item.reviewStatus == PushReviewStatus.none &&
              item.profileId != null)
            _PushFooter(
              primaryLabel: 'Felismerés tanítása ebből',
              busy: _saving,
              onCancel: () => Navigator.of(context).pop(),
              cancelLabel: 'Vissza',
              onPrimary: _trainFromNotification,
            )
          else if (recorded && widget.onOpenLedgerEntry != null)
            _PushFooter(
              primaryLabel: 'Kapcsolódó tranzakció megnyitása',
              busy: false,
              onCancel: () => Navigator.of(context).pop(),
              cancelLabel: 'Vissza',
              onPrimary: () async {
                final entryId = item.ledgerEntryId;
                if (entryId == null) return;
                await widget.onOpenLedgerEntry!(entryId);
              },
            ),
        ],
      ),
    );
  }
}

final class _PushHero extends StatelessWidget {
  const _PushHero({
    required this.title,
    required this.label,
    required this.value,
    required this.onBack,
    this.menu,
  });
  final String title;
  final String label;
  final String value;
  final VoidCallback onBack;
  final Widget? menu;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xfffff2fa), Color(0xfff2edff), Color(0xffeef4ff)],
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        20,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 2,
            bottom: -2,
            child: ExcludeSemantics(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: _pushBrand,
                  size: 34,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: _pushInk,
                      tooltip: 'Vissza',
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _pushInk,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                    ),
                  ),
                  ?menu,
                ],
              ),
              const SizedBox(height: 18),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _pushMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              SizedBox(
                width: 245,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: _pushInk,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                    height: 1.08,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _PushFieldRow extends StatelessWidget {
  const _PushFieldRow({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
    this.trailing,
    this.onTap,
    this.avatar,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? helper;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? avatar;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child:
                avatar ??
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _pushNeutral,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _pushMuted, size: 22),
                ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _pushMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _pushInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (helper != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      helper!,
                      style: const TextStyle(
                        color: _pushMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: trailing!,
            ),
        ],
      ),
    ),
  );
}

final class _PushFooter extends StatelessWidget {
  const _PushFooter({
    required this.primaryLabel,
    required this.busy,
    required this.onCancel,
    required this.onPrimary,
    this.cancelLabel = 'Mégse',
    this.primaryEnabled = true,
  });
  final String primaryLabel;
  final String cancelLabel;
  final bool busy;
  final bool primaryEnabled;
  final VoidCallback onCancel;
  final VoidCallback onPrimary;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(color: Colors.white),
    child: SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cancel = _pushButtonWidth(context, cancelLabel, 104);
            final primary = _pushButtonWidth(
              context,
              busy ? '$primaryLabel…' : primaryLabel,
              120,
            );
            final total = cancel + primary + 12;
            final available = constraints.maxWidth;
            final cancelWidth = total <= available
                ? cancel
                : (available - 12) * .43;
            final primaryWidth = total <= available
                ? primary
                : available - 12 - cancelWidth;
            return Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: cancelWidth,
                    child: _PushActionButton(
                      key: const ValueKey<String>('unified-push-cta-secondary'),
                      label: cancelLabel,
                      onPressed: busy ? null : onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: primaryWidth,
                    child: _PushActionButton(
                      key: const ValueKey<String>('unified-push-cta-primary'),
                      label: busy ? '$primaryLabel…' : primaryLabel,
                      primary: true,
                      enabled: primaryEnabled,
                      onPressed: busy || !primaryEnabled ? null : onPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

double _pushButtonWidth(BuildContext context, String label, double minimum) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  return (painter.width + 28).clamp(minimum, double.infinity).toDouble();
}

final class _PushActionButton extends StatelessWidget {
  const _PushActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.enabled = true,
  });
  final String label;
  final bool primary;
  final bool enabled;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2619264d),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          color: primary
              ? (enabled ? _pushBrand : _pushBrand.withValues(alpha: .42))
              : Colors.white,
          border: primary ? null : Border.all(color: const Color(0xffdde2ec)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: primary ? Colors.white : _pushInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _PushAppAvatar extends StatelessWidget {
  const _PushAppAvatar({required this.app});
  final InstalledApplication app;
  @override
  Widget build(BuildContext context) {
    final raw = app.iconPngBase64;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _pushNeutral,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: raw == null
            ? Center(
                child: Text(
                  app.label.isEmpty
                      ? '?'
                      : app.label.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: _pushInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : Image.memory(base64Decode(raw), fit: BoxFit.cover),
      ),
    );
  }
}

/// The package directory intentionally omits icons. Fetching an icon only for
/// a visible picker row keeps a large installed-app list responsive and lets a
/// single broken package icon fall back to the neutral avatar.
final class _LazyPushAppAvatar extends StatefulWidget {
  const _LazyPushAppAvatar({required this.app, required this.permissions});
  final InstalledApplication app;
  final AutomationPermissionRepository permissions;

  @override
  State<_LazyPushAppAvatar> createState() => _LazyPushAppAvatarState();
}

final class _LazyPushAppAvatarState extends State<_LazyPushAppAvatar> {
  String? _icon;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _LazyPushAppAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.app.packageName != widget.app.packageName) {
      _icon = null;
      _load();
    }
  }

  Future<void> _load() async {
    final icon =
        widget.app.iconPngBase64 ??
        await widget.permissions.installedApplicationIcon(
          widget.app.packageName,
        );
    if (mounted) setState(() => _icon = icon);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: _PushAppAvatar(
      app: InstalledApplication(
        packageName: widget.app.packageName,
        label: widget.app.label,
        iconPngBase64: _icon,
        isSystemApp: widget.app.isSystemApp,
        enabled: widget.app.enabled,
      ),
    ),
  );
}

final class _PushRuleRow extends StatelessWidget {
  const _PushRuleRow({required this.rule, required this.onTap});
  final PushRule rule;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _pushNeutral,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Icon(Icons.rule_outlined, color: _pushMuted),
      ),
    ),
    title: Text(
      rule.name,
      style: const TextStyle(color: _pushInk, fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      '${rule.direction == LedgerDirection.expense ? 'Kiadás' : 'Bevétel'} · ${_ruleStateLabel(rule.state)}',
      style: const TextStyle(color: _pushMuted, fontSize: 12),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

final class _PushInboxRow extends StatelessWidget {
  const _PushInboxRow({required this.item, required this.onTap});
  final NotificationInboxItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    leading: const SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _pushNeutral,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Icon(Icons.notifications_outlined, color: _pushMuted),
      ),
    ),
    title: Text(
      item.title?.isNotEmpty == true
          ? item.title!
          : item.sourceAppLabel ?? 'Értesítés',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: _pushInk, fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      '${_humanDate(item.receivedAtUtcMs)} · ${item.rawText}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: _pushMuted, fontSize: 12),
    ),
    trailing: Text(
      _reviewLabel(item.reviewStatus),
      style: const TextStyle(color: _pushMuted, fontSize: 11),
      textAlign: TextAlign.right,
    ),
    onTap: onTap,
  );
}

final class _SummarySpan extends StatelessWidget {
  const _SummarySpan({required this.label, required this.value, this.onDelete});
  final String label;
  final String value;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 118,
          child: Text(
            label,
            style: const TextStyle(color: _pushMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: value == 'Nincs kijelölve' ? _pushMuted : _pushInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onDelete,
            tooltip: 'Kijelölés eltávolítása',
          ),
      ],
    ),
  );
}

final class _EmptyCopy extends StatelessWidget {
  const _EmptyCopy(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(value, style: const TextStyle(color: _pushMuted, height: 1.4)),
  );
}

final class _FieldError extends StatelessWidget {
  const _FieldError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      message,
      style: const TextStyle(color: Color(0xffb4233c), fontSize: 12),
    ),
  );
}

Widget _sectionHeader(
  String title, {
  required String action,
  required VoidCallback onTap,
}) => Row(
  children: [
    Expanded(
      child: Text(
        title,
        style: const TextStyle(
          color: _pushInk,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    TextButton(onPressed: onTap, child: Text(action)),
  ],
);

String _reviewLabel(PushReviewStatus? status) => switch (status) {
  null => 'Összes',
  PushReviewStatus.none => 'Még nincs felismerés',
  PushReviewStatus.pending => 'Ellenőrzésre vár',
  PushReviewStatus.approved => 'Rögzítve',
  PushReviewStatus.ignored => 'Kihagyva',
  PushReviewStatus.rejected => 'Elutasítva',
};

String _ruleStateLabel(PushRuleState state) => switch (state) {
  PushRuleState.draft => 'Piszkozat',
  PushRuleState.testing => 'Próba alatt',
  PushRuleState.active => 'Aktív',
  PushRuleState.paused => 'Szünetel',
  PushRuleState.failed => 'Javítást igényel',
};

String _roleLabel(PushFieldRole role) => switch (role) {
  PushFieldRole.amount => 'Összeg',
  PushFieldRole.merchant => 'Partner',
  PushFieldRole.balance => 'Egyenleg',
  PushFieldRole.account => 'Számla / kártya',
  PushFieldRole.currency => 'Pénznem',
  PushFieldRole.ignore => 'Más változó rész',
};

String _humanDate(int utcMs) {
  final value = DateTime.fromMillisecondsSinceEpoch(utcMs);
  final now = DateTime.now();
  if (value.year == now.year &&
      value.month == now.month &&
      value.day == now.day) {
    return 'Ma ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
  return '${value.year}. ${value.month.toString().padLeft(2, '0')}. ${value.day.toString().padLeft(2, '0')}. ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String _money(int minor) => minor % 100 == 0
    ? '${minor ~/ 100}'
    : '${minor ~/ 100},${(minor % 100).toString().padLeft(2, '0')}';

int? _parseMinor(String source) {
  final normalized = source
      .replaceAll(RegExp(r'[\s\u00A0.]'), '')
      .replaceAll(',', '.');
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(normalized);
  if (match == null) return null;
  final whole = int.tryParse(match.group(1)!);
  final cents = int.tryParse((match.group(2) ?? '').padRight(2, '0'));
  if (whole == null || cents == null || whole < 0) return null;
  return whole * 100 + cents > 0 ? whole * 100 + cents : null;
}
