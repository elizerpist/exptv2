import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/navigation/creation_slide_up_route.dart';
import '../../dashboard/application/dashboard_presentation_preferences.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import 'notification_inbox_page.dart';
import 'push_profile_details_page.dart';
import 'push_profile_wizard_page.dart';
import 'review_push_notification_page.dart';
import 'unified_push_profile_pages.dart';

/// Result returned to callers such as the recurring-rule bank-link sheet.
/// A profile alone is intentionally not advertised as a usable automation:
/// callers can distinguish a waiting profile from one with an active rule.
final class PushProfileFlowResult {
  const PushProfileFlowResult({
    required this.profileId,
    this.ruleId,
    this.ruleState,
  });

  final String profileId;
  final String? ruleId;
  final PushRuleState? ruleState;

  bool get usable => ruleState == PushRuleState.active;
}

/// One root router for both push-profile surface families. Each API receives
/// a design snapshot at opening time, preventing a dashboard preference change
/// from replacing an in-progress editor, training draft or review page.
abstract final class PushProfileNavigation {
  static Future<PushProfileFlowResult?> openCreate(
    BuildContext context, {
    required PushProfileUiDesign design,
    required AutomationRepository repository,
    required AutomationPermissionRepository permissions,
  }) => Navigator.of(context).push<PushProfileFlowResult?>(
    creationSlideUpRoute<PushProfileFlowResult?>(
      fullscreenDialog: true,
      builder: (_) => design == PushProfileUiDesign.legacy
          ? _LegacyPushProfileCreateRoute(
              repository: repository,
              permissions: permissions,
            )
          : UnifiedPushProfileEditorPage.create(
              repository: repository,
              permissions: permissions,
            ),
    ),
  );

  static Future<void> openProfile(
    BuildContext context, {
    required PushProfileUiDesign design,
    required AutomationRepository repository,
    required AutomationPermissionRepository permissions,
    required String profileId,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => design == PushProfileUiDesign.legacy
          ? PushProfileDetailsPage(
              repository: repository,
              permissions: permissions,
              profileId: profileId,
            )
          : UnifiedPushProfileDetailPage(
              repository: repository,
              permissions: permissions,
              profileId: profileId,
            ),
    ),
  );

  static Future<void> openInbox(
    BuildContext context, {
    required PushProfileUiDesign design,
    required AutomationRepository repository,
    required AutomationPermissionRepository permissions,
    String? profileId,
    bool onlyReview = false,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => design == PushProfileUiDesign.legacy
          ? NotificationInboxPage(
              repository: repository,
              profileId: profileId,
              onlyReview: onlyReview,
            )
          : UnifiedPushInboxPage(
              repository: repository,
              permissions: permissions,
              profileId: profileId,
              onlyReview: onlyReview,
              onConfigureApplication: () async {
                await PushProfileNavigation.openCreate(
                  context,
                  design: design,
                  repository: repository,
                  permissions: permissions,
                );
              },
            ),
    ),
  );

  static Future<void> openNotification(
    BuildContext context, {
    required PushProfileUiDesign design,
    required AutomationRepository repository,
    required NotificationInboxItem item,
    Future<void> Function(String ledgerEntryId)? onOpenLedgerEntry,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => design == PushProfileUiDesign.legacy
          ? ReviewPushNotificationPage(repository: repository, event: item)
          : UnifiedPushInboxDetailPage(
              repository: repository,
              item: item,
              onOpenLedgerEntry: onOpenLedgerEntry,
            ),
    ),
  );

  /// The compact manager is a root entry point rather than a third profile
  /// flow. Its rows deliberately keep using the selected legacy/unified
  /// detail page, so the two surface families still operate on one dataset.
  static Future<void> openManager(
    BuildContext context, {
    required PushProfileUiDesign design,
    required AutomationRepository repository,
    required AutomationPermissionRepository permissions,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => _PushProfileManagerPage(
        design: design,
        repository: repository,
        permissions: permissions,
      ),
    ),
  );
}

/// The legacy wizard intentionally remains the original three-step flow.
/// It has no structured completion contract, so callers refresh their shared
/// repository state after it closes just as they did before this router.
final class _LegacyPushProfileCreateRoute extends StatelessWidget {
  const _LegacyPushProfileCreateRoute({
    required this.repository,
    required this.permissions,
  });

  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;

  @override
  Widget build(BuildContext context) =>
      PushProfileWizardPage(repository: repository, permissions: permissions);
}

final class _PushProfileManagerPage extends StatefulWidget {
  const _PushProfileManagerPage({
    required this.design,
    required this.repository,
    required this.permissions,
  });

  final PushProfileUiDesign design;
  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;

  @override
  State<_PushProfileManagerPage> createState() =>
      _PushProfileManagerPageState();
}

final class _PushProfileManagerPageState
    extends State<_PushProfileManagerPage> {
  List<PushProfile>? _profiles;
  Map<String, InstalledApplication> _apps = const {};
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Installed application metadata only decorates rows. A capability
      // lookup failure must not hide the user's already persisted profiles.
      final profiles = await widget.repository.listProfiles();
      List<InstalledApplication> apps;
      try {
        apps = await widget.permissions.listInstalledApps();
      } on Object {
        apps = const <InstalledApplication>[];
      }
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _apps = {for (final app in apps) app.packageName: app};
          _error = null;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _create() async {
    await PushProfileNavigation.openCreate(
      context,
      design: widget.design,
      repository: widget.repository,
      permissions: widget.permissions,
    );
    _load();
  }

  Future<void> _open(PushProfile profile) async {
    await PushProfileNavigation.openProfile(
      context,
      design: widget.design,
      repository: widget.repository,
      permissions: widget.permissions,
      profileId: profile.profileId,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = (_profiles ?? const <PushProfile>[])
        .where((profile) {
          final query = _query.trim().toLowerCase();
          return query.isEmpty ||
              profile.displayName.toLowerCase().contains(query) ||
              profile.appLabel.toLowerCase().contains(query);
        })
        .toList(growable: false);
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text('Push profilok'),
        actions: [
          IconButton(
            tooltip: 'Új profil',
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            TextField(
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Profil keresése',
                filled: true,
                fillColor: const Color(0xfff1f5f9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_profiles == null && _error == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ManagerError(onRetry: _load)
            else if (profiles.isEmpty)
              _ManagerEmpty(onCreate: _create)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < profiles.length; index++) ...[
                      if (index > 0)
                        const Divider(
                          height: 1,
                          indent: 65,
                          color: Color(0xffe5e9f0),
                        ),
                      ListTile(
                        minVerticalPadding: 12,
                        leading: _ProfileAppIcon(
                          app: _apps[profiles[index].packageName],
                        ),
                        title: Text(
                          profiles[index].displayName,
                          style: const TextStyle(
                            color: Color(0xff19264d),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          '${profiles[index].appLabel} · ${_profileStatus(profiles[index])}',
                          style: const TextStyle(
                            color: Color(0xff718096),
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _open(profiles[index]),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _ProfileAppIcon extends StatelessWidget {
  const _ProfileAppIcon({this.app});
  final InstalledApplication? app;

  @override
  Widget build(BuildContext context) {
    final encoded = app?.iconPngBase64;
    if (encoded != null && encoded.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(encoded),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        );
      } on FormatException {
        // A malformed historical app icon must not hide its profile row.
      }
    }
    return const SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xfff1f5f9),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Icon(Icons.account_balance_outlined, color: Color(0xff718096)),
      ),
    );
  }
}

String _profileStatus(PushProfile profile) => switch (profile.state) {
  PushProfileState.active => 'Működik',
  PushProfileState.paused => 'Szünetel',
  _ => 'Beállításra vár',
};

final class _ManagerEmpty extends StatelessWidget {
  const _ManagerEmpty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Text('Még nincs push profil.'),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Új profil'),
          ),
        ],
      ),
    ),
  );
}

final class _ManagerError extends StatelessWidget {
  const _ManagerError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: OutlinedButton(
        onPressed: onRetry,
        child: const Text('Újrapróbálás'),
      ),
    ),
  );
}
