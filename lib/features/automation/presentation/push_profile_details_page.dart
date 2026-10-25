import 'package:flutter/material.dart';

import '../../dashboard/query/domain/ledger_direction.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'notification_inbox_page.dart';
import 'push_training_editor_page.dart';

class PushProfileDetailsPage extends StatefulWidget {
  const PushProfileDetailsPage({
    super.key,
    required this.repository,
    required this.permissions,
    required this.profileId,
  });
  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  final String profileId;
  @override
  State<PushProfileDetailsPage> createState() => _PushProfileDetailsPageState();
}

class _PushProfileDetailsPageState extends State<PushProfileDetailsPage> {
  PushProfile? _profile;
  List<PushRule> _rules = const [];
  List<NotificationInboxItem> _inbox = const [];
  bool _loading = true;
  Object? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        widget.repository.profile(widget.profileId),
        widget.repository.rules(widget.profileId),
        widget.repository.inbox(profileId: widget.profileId, limit: 8),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = values[0] as PushProfile;
        _rules = values[1] as List<PushRule>;
        _inbox = values[2] as List<NotificationInboxItem>;
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

  Future<void> _togglePause() async {
    final profile = _profile;
    if (profile == null) return;
    await widget.repository.updateProfile(
      profileId: profile.profileId,
      displayName: profile.displayName,
      defaultDirection: profile.defaultDirection,
      state: profile.state == PushProfileState.paused
          ? (_rules.any((rule) => rule.state == PushRuleState.active)
                ? PushProfileState.active
                : PushProfileState.waitingForTraining)
          : PushProfileState.paused,
    );
    _load();
  }

  Future<void> _rename() async {
    final profile = _profile;
    if (profile == null) return;
    final controller = TextEditingController(text: profile.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil átnevezése'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Profil neve'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Mentés'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await widget.repository.updateProfile(
      profileId: profile.profileId,
      displayName: name,
      defaultDirection: profile.defaultDirection,
      state: profile.state,
    );
    _load();
  }

  Future<void> _confirmDelete() async {
    final profile = _profile;
    if (profile == null) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Push profil törlése?'),
        content: const Text(
          'A profilhoz tartozó szabályok és tanítási minták törlődnek. A már könyvelt Ledger-tranzakciók megmaradnak.',
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
    if (approved != true) return;
    await widget.repository.deleteProfile(profile.profileId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openTraining() async {
    final profile = _profile;
    if (profile == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationInboxPage(
          repository: widget.repository,
          profileId: widget.profileId,
          selectionMode: true,
          onSelectForTraining: (event) => PushTrainingEditorPage(
            repository: widget.repository,
            profile: profile,
            event: event,
          ),
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push profil'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'rename') await _rename();
              if (value == 'pause') await _togglePause();
              if (value == 'delete') await _confirmDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'rename',
                child: Text('Profil átnevezése'),
              ),
              PopupMenuItem(
                value: 'pause',
                child: Text(
                  profile?.state == PushProfileState.paused
                      ? 'Megfigyelés folytatása'
                      : 'Megfigyelés szüneteltetése',
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Profil törlése'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('A profil nem tölthető be: $_error'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        child: Text(
                          profile!.appLabel.isEmpty
                              ? '?'
                              : profile.appLabel.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(_profileStateText(profile.state)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _StatusCard(profile: profile, onAction: _actionFor(profile)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Felismerési szabályok',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openTraining,
                        icon: const Icon(Icons.add),
                        label: const Text('Új szabály'),
                      ),
                    ],
                  ),
                  if (_rules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Még nincs felismerési szabály. Egy valódi, elkapott üzenetből taníthatod meg a parsert.',
                      ),
                    )
                  else
                    ..._rules.map(
                      (rule) => _RuleTile(
                        rule: rule,
                        repository: widget.repository,
                        onChanged: _load,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Legutóbbi értesítések',
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
                                  profileId: profile.profileId,
                                ),
                              ),
                            )
                            .then((_) => _load()),
                        child: const Text('Összes'),
                      ),
                    ],
                  ),
                  if (_inbox.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Várakozás az első értesítésre.'),
                    )
                  else
                    ..._inbox.map(
                      (event) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_none),
                        title: Text(
                          event.rawText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(event.receivedAtUtcMs.toString()),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  VoidCallback _actionFor(PushProfile profile) => switch (profile.state) {
    PushProfileState.waitingForPermission =>
      () => widget.permissions.openNotificationAccessSettings(),
    PushProfileState.waitingForTraining ||
    PushProfileState.testing ||
    PushProfileState.reviewRequired ||
    PushProfileState.active => _openTraining,
    PushProfileState.paused => _togglePause,
  };
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.profile, required this.onAction});
  final PushProfile profile;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) {
    final action = switch (profile.state) {
      PushProfileState.waitingForPermission => 'Hozzáférés engedélyezése',
      PushProfileState.waitingForTraining => 'Tanítás elkezdése',
      PushProfileState.testing => 'Tanítás folytatása',
      PushProfileState.active => 'Új felismerési szabály',
      PushProfileState.reviewRequired => 'Értesítések áttekintése',
      PushProfileState.paused => 'Megfigyelés folytatása',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff6f7f9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profileStateText(profile.state),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 6),
          const Text(
            'A megfigyelés és az automatikus könyvelés külön állapot. Csak tesztelt, aktív szabály könyvelhet.',
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

class _RuleTile extends StatefulWidget {
  const _RuleTile({
    required this.rule,
    required this.repository,
    required this.onChanged,
  });
  final PushRule rule;
  final AutomationRepository repository;
  final VoidCallback onChanged;
  @override
  State<_RuleTile> createState() => _RuleTileState();
}

class _RuleTileState extends State<_RuleTile> {
  bool _busy = false;
  PushRuleTestReport? _report;
  Future<void> _test() async {
    setState(() => _busy = true);
    try {
      final report = await widget.repository.backtest(widget.rule.ruleId);
      if (mounted) setState(() => _report = report);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.rule.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(_ruleStateText(widget.rule.state)),
            ],
          ),
          Text(
            widget.rule.direction == LedgerDirection.expense
                ? 'Kiadás'
                : 'Bevétel',
          ),
          if (_report != null)
            Text(
              'Találat: ${_report!.matchedCount}, ellenőrzés: ${_report!.reviewCount}, ütközés: ${_report!.conflictedCount}',
            ),
          Row(
            children: [
              TextButton(
                onPressed: _busy ? null : _test,
                child: const Text('Backtest'),
              ),
              if (_report?.activationReady == true)
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          await widget.repository.activateRule(
                            widget.rule.ruleId,
                          );
                          if (mounted) widget.onChanged();
                        },
                  child: const Text('Szabály aktiválása'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _profileStateText(PushProfileState state) => switch (state) {
  PushProfileState.waitingForPermission => 'Engedélyre vár',
  PushProfileState.waitingForTraining => 'Tanításra vár',
  PushProfileState.testing => 'Tesztelés alatt',
  PushProfileState.active => 'Aktív',
  PushProfileState.reviewRequired => 'Felülvizsgálat szükséges',
  PushProfileState.paused => 'Szüneteltetett',
};
String _ruleStateText(PushRuleState state) => switch (state) {
  PushRuleState.draft => 'Piszkozat',
  PushRuleState.testing => 'Tesztelés',
  PushRuleState.active => 'Aktív',
  PushRuleState.paused => 'Szüneteltetve',
  PushRuleState.failed => 'Javítás szükséges',
};
