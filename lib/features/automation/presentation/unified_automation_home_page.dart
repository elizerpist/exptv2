import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/categories/catalog/category_catalog.dart';
import '../../../core/categories/domain/category_repository.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/category_visual_badge.dart';
import '../../dashboard/application/dashboard_presentation_preferences.dart';
import '../../dashboard/query/domain/ledger_direction.dart';
import '../../manual_transactions/application/manual_transaction_editor_preferences.dart';
import '../../manual_transactions/domain/manual_transaction_repository.dart';
import '../domain/automation_models.dart';
import '../domain/automation_repository.dart';
import '../data/automation_update_bridge.dart';
import 'push_profile_navigation.dart';
import 'recurring_navigation.dart';

const _homeInk = Color(0xff19264d);
const _homeMuted = Color(0xff718096);
const _homeLine = Color(0xffe5e9f0);
const _homeNeutral = Color(0xfff1f5f9);

/// Daily, read-only Automation overview. It intentionally starts independent
/// bounded reads for push, permission and recurring data, so an unavailable
/// Android capability never makes scheduled recurrences disappear.
final class UnifiedAutomationHomePage extends StatefulWidget {
  const UnifiedAutomationHomePage({
    super.key,
    required this.repository,
    required this.permissions,
    this.manualRepository,
    this.categories = const <FluviCategory>[],
    this.categoryRepository,
    this.preferencesStore,
    required this.recurringUiDesign,
    required this.pushProfileUiDesign,
    required this.direction,
    this.onOpenLedgerEntry,
  });

  final AutomationRepository repository;
  final AutomationPermissionRepository permissions;
  final ManualTransactionRepository? manualRepository;
  final List<FluviCategory> categories;
  final CategoryRepository? categoryRepository;
  final ManualTransactionEditorPreferencesStore? preferencesStore;
  final RecurringUiDesign recurringUiDesign;
  final PushProfileUiDesign pushProfileUiDesign;
  final LedgerDirection direction;
  final Future<void> Function(String entryId)? onOpenLedgerEntry;

  @override
  State<UnifiedAutomationHomePage> createState() =>
      _UnifiedAutomationHomePageState();
}

final class _UnifiedAutomationHomePageState
    extends State<UnifiedAutomationHomePage>
    with WidgetsBindingObserver {
  AutomationDashboardSnapshot? _push;
  AutomationPermissionStatus? _permission;
  RecurrenceDashboardSnapshot? _recurrence;
  List<RecurrenceOccurrence>? _upcoming;
  List<NotificationInboxItem> _pendingReview = const [];
  Object? _pushError;
  Object? _recurrenceError;
  bool _loading = true;
  int _request = 0;
  StreamSubscription<void>? _automationUpdates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _automationUpdates = AutomationUpdateBridge.changes.listen(
      (_) => unawaited(_refresh()),
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _automationUpdates?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  (int, int) _weekBounds() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    // Constructing the end from local calendar fields avoids treating an
    // hour-short/hour-long DST week as a fixed 168-hour interval.
    final end = DateTime(now.year, now.month, now.day + 7);
    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch - 1);
  }

  Future<_HomeLoad<T>> _capture<T>(Future<T> future) async {
    try {
      return _HomeLoad<T>.value(await future);
    } on Object catch (error) {
      return _HomeLoad<T>.error(error);
    }
  }

  Future<void> _refresh() async {
    final request = ++_request;
    final bounds = _weekBounds();
    if (mounted) {
      setState(() {
        _loading = _push == null && _recurrence == null;
      });
    }
    final homeFuture = _capture(widget.repository.homeDashboard());
    final permissionFuture = _capture(widget.permissions.getPermissionStatus());
    final recurrenceFuture = _capture(widget.repository.recurrenceDashboard());
    final upcomingFuture = _capture(
      widget.repository.upcomingRecurrenceOccurrences(
        fromUtcMs: bounds.$1,
        toUtcMs: bounds.$2,
        limit: 3,
      ),
    );
    final pendingFuture = _capture(
      widget.repository.inbox(reviewStatus: PushReviewStatus.pending, limit: 1),
    );
    final home = await homeFuture;
    final permission = await permissionFuture;
    final recurrence = await recurrenceFuture;
    final upcoming = await upcomingFuture;
    final pending = await pendingFuture;
    if (!mounted || request != _request) return;
    setState(() {
      if (home.data != null) {
        _push = home.data;
        _pushError = null;
      } else {
        _pushError = home.error;
      }
      if (permission.data != null) _permission = permission.data;
      if (recurrence.data != null) {
        _recurrence = recurrence.data;
        _recurrenceError = null;
      } else {
        _recurrenceError = recurrence.error;
      }
      if (upcoming.data != null) _upcoming = upcoming.data;
      if (pending.data != null) _pendingReview = pending.data!;
      _loading = false;
    });
  }

  Future<void> _newRecurring() async {
    final manual = widget.manualRepository;
    if (manual == null) return;
    await RecurringNavigation.openCreate(
      context,
      design: widget.recurringUiDesign,
      repository: widget.repository,
      manualRepository: manual,
      categories: widget.categories,
      categoryRepository: widget.categoryRepository,
      preferencesStore: widget.preferencesStore,
      permissions: widget.permissions,
      direction: widget.direction,
      pushProfileUiDesign: widget.pushProfileUiDesign,
    );
    if (mounted) _refresh();
  }

  Future<void> _openRecurring({bool occurrences = false}) async {
    final manual = widget.manualRepository;
    if (manual == null) return;
    final bounds = _weekBounds();
    await RecurringNavigation.openManager(
      context,
      design: widget.recurringUiDesign,
      repository: widget.repository,
      manualRepository: manual,
      categories: widget.categories,
      categoryRepository: widget.categoryRepository,
      preferencesStore: widget.preferencesStore,
      permissions: widget.permissions,
      direction: widget.direction,
      onOpenLedgerEntry: widget.onOpenLedgerEntry,
      initialRulesTab: !occurrences,
      initialOccurrenceFilter: RecurrenceOccurrenceStatus.pending,
      initialOccurrenceFromUtcMs: occurrences ? bounds.$1 : null,
      initialOccurrenceToUtcMs: occurrences ? bounds.$2 : null,
    );
    if (mounted) _refresh();
  }

  Future<void> _openOccurrence(RecurrenceOccurrence occurrence) async {
    final manual = widget.manualRepository;
    if (manual == null) return;
    await RecurringNavigation.openOccurrence(
      context,
      design: widget.recurringUiDesign,
      repository: widget.repository,
      manualRepository: manual,
      categories: widget.categories,
      occurrenceId: occurrence.occurrenceId,
      onOpenLedgerEntry: widget.onOpenLedgerEntry,
    );
    if (mounted) _refresh();
  }

  Future<void> _newProfile() async {
    await PushProfileNavigation.openCreate(
      context,
      design: widget.pushProfileUiDesign,
      repository: widget.repository,
      permissions: widget.permissions,
    );
    if (mounted) _refresh();
  }

  Future<void> _openPushManager() async {
    await PushProfileNavigation.openManager(
      context,
      design: widget.pushProfileUiDesign,
      repository: widget.repository,
      permissions: widget.permissions,
    );
    if (mounted) _refresh();
  }

  Future<void> _openProfile(String profileId) async {
    await PushProfileNavigation.openProfile(
      context,
      design: widget.pushProfileUiDesign,
      repository: widget.repository,
      permissions: widget.permissions,
      profileId: profileId,
    );
    if (mounted) _refresh();
  }

  Future<void> _openInbox({bool onlyReview = false}) async {
    await PushProfileNavigation.openInbox(
      context,
      design: widget.pushProfileUiDesign,
      repository: widget.repository,
      permissions: widget.permissions,
      onlyReview: onlyReview,
    );
    if (mounted) _refresh();
  }

  Future<void> _openNotification(NotificationInboxItem item) async {
    await PushProfileNavigation.openNotification(
      context,
      design: widget.pushProfileUiDesign,
      repository: widget.repository,
      item: item,
      onOpenLedgerEntry: widget.onOpenLedgerEntry,
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final push = _push;
    final recurrence = _recurrence;
    final isVerifiedEmpty =
        !_loading &&
        _pushError == null &&
        _recurrenceError == null &&
        push != null &&
        recurrence != null &&
        push.profiles.isEmpty &&
        recurrence.rules.isEmpty &&
        (_upcoming?.isEmpty ?? false) &&
        push.recentInbox.isEmpty;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          key: const ValueKey('unified-automation-home-page'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
          children: [
            _header(),
            if (_loading && push == null && recurrence == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isVerifiedEmpty)
              _firstUse()
            else ...[
              if (_action() case final action?) ...[
                const SizedBox(height: 20),
                action,
              ],
              const SizedBox(height: 24),
              _management(push: push, recurrence: recurrence),
              const SizedBox(height: 24),
              _upcomingSection(),
              const SizedBox(height: 24),
              _recentNotifications(push),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      const Expanded(
        child: Text(
          'Automatizálás',
          style: TextStyle(
            color: _homeInk,
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
      ),
      SizedBox(
        width: 46,
        height: 46,
        child: PopupMenuButton<String>(
          tooltip: 'Működési információk és engedélyek',
          onSelected: (value) {
            if (value == 'permissions') {
              widget.permissions.openNotificationAccessSettings();
            } else {
              showDialog<void>(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text('Automatizáció működése'),
                  content: Text(
                    'A Fluvi csak az általad kiválasztott, engedélyezett alkalmazások értesítéseit dolgozza fel. A várható ismétlődések önmagukban nem kerülnek a Ledgerbe.',
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
          icon: const Icon(Icons.more_horiz_rounded, color: _homeInk),
        ),
      ),
    ],
  );

  Widget? _action() {
    final push = _push;
    if (push == null) return null;
    if (push.pendingReviewCount > 0) {
      final one = _pendingReview.firstOrNull;
      return _ActionCard(
        key: const ValueKey('automation-home-action-pending-review'),
        icon: Icons.fact_check_outlined,
        title: push.pendingReviewCount == 1
            ? 'Egy értesítés ellenőrzésre vár'
            : '${push.pendingReviewCount} értesítés ellenőrzésre vár',
        subtitle: 'A kétes találatok még nem kerültek a Ledgerbe.',
        onTap: one == null
            ? () => _openInbox(onlyReview: true)
            : () => _openNotification(one),
      );
    }
    final permission = _permission;
    final needsPermission =
        permission?.notificationListenerAvailable == true &&
        permission?.notificationListenerGranted != true &&
        push.profiles.any(
          (profile) => profile.state == PushProfileState.waitingForPermission,
        );
    if (needsPermission) {
      return _ActionCard(
        key: const ValueKey('automation-home-action-permission'),
        icon: Icons.notifications_off_outlined,
        title: 'A banki értesítésekhez hozzáférés szükséges',
        subtitle:
            'Az engedély után a profil megtarthatja a már megadott beállításait.',
        onTap: () => widget.permissions.openNotificationAccessSettings(),
        lavender: true,
      );
    }
    final ready = push.profiles.where(
      (profile) =>
          profile.state == PushProfileState.waitingForTraining &&
          profile.inboxCount > 0,
    );
    if (ready.isNotEmpty) {
      return _ActionCard(
        key: const ValueKey('automation-home-action-training'),
        icon: Icons.school_outlined,
        title: 'A banki profil tanításra kész',
        subtitle: 'Válassz egy beérkezett értesítést a felismerési szabályhoz.',
        onTap: () => _openProfile(ready.first.profileId),
        lavender: true,
      );
    }
    return null;
  }

  Widget _management({
    required AutomationDashboardSnapshot? push,
    required RecurrenceDashboardSnapshot? recurrence,
  }) {
    final profiles = push?.profiles ?? const <PushProfile>[];
    final rules = recurrence?.rules ?? const <RecurrenceRule>[];
    final active = rules
        .where((rule) => rule.isActive && !_ruleNeedsSetup(rule, profiles))
        .length;
    final waiting = rules
        .where((rule) => _ruleNeedsSetup(rule, profiles))
        .length;
    final paused = rules.where((rule) => !rule.isActive).length;
    final profilesWaiting = profiles
        .where(
          (profile) =>
              profile.state != PushProfileState.active &&
              profile.state != PushProfileState.paused,
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Kezelés'),
        const SizedBox(height: 8),
        _HomeGroup(
          children: [
            _HomeRow(
              key: const ValueKey('automation-home-manage-recurring'),
              icon: Icons.repeat_rounded,
              title: 'Ismétlődések',
              subtitle: _recurrenceError != null
                  ? 'Az ismétlődések most nem tölthetők be · Újrapróbálás'
                  : recurrence == null
                  ? 'Betöltés…'
                  : rules.isEmpty
                  ? 'Még nincs ismétlődő tranzakció'
                  : _ruleSummary(
                      active: active,
                      waiting: waiting,
                      paused: paused,
                    ),
              onTap: _recurrenceError == null ? _openRecurring : _refresh,
            ),
            _HomeRow(
              key: const ValueKey('automation-home-manage-push'),
              icon: Icons.account_balance_outlined,
              title: 'Push profilok',
              subtitle: _pushError != null
                  ? 'A push profilok most nem tölthetők be · Újrapróbálás'
                  : _permission?.notificationListenerAvailable == false
                  ? 'Ezen az eszközön az értesítésfigyelés nem elérhető'
                  : push == null
                  ? 'Betöltés…'
                  : profiles.isEmpty
                  ? 'Még nincs profil'
                  : '${profiles.length} profil${profilesWaiting == 0 ? '' : ' · $profilesWaiting beállításra vár'}',
              onTap: _pushError == null ? _openPushManager : _refresh,
            ),
            _HomeRow(
              key: const ValueKey('automation-home-manage-inbox'),
              icon: Icons.inbox_outlined,
              title: 'Banki értesítések',
              subtitle: _inboxSummary(push, profiles),
              onTap: _openInbox,
            ),
          ],
        ),
      ],
    );
  }

  String _inboxSummary(
    AutomationDashboardSnapshot? push,
    List<PushProfile> profiles,
  ) {
    if (profiles.isEmpty) {
      return 'Válassz alkalmazást az első értesítés fogadásához.';
    }
    final permission = _permission;
    if (permission?.notificationListenerAvailable == true &&
        permission?.notificationListenerGranted != true) {
      return 'Értesítés-hozzáférés szükséges.';
    }
    final inbox = push?.recentInbox ?? const <NotificationInboxItem>[];
    if (inbox.isEmpty) return 'Az első értesítésre vár.';
    final pending = push?.pendingReviewCount ?? 0;
    final latest = _humanDate(inbox.first.receivedAtUtcMs);
    return 'Legutóbbi $latest${pending == 0 ? '' : ' · $pending ellenőrzésre vár'}';
  }

  Widget _upcomingSection() {
    final upcoming = _upcoming;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Következő 7 nap',
          action: 'Összes',
          onTap: () => _openRecurring(occurrences: true),
        ),
        const SizedBox(height: 8),
        if (_recurrenceError != null)
          _InlineState(
            message: 'Az alkalmak most nem tölthetők be.',
            onRetry: _refresh,
          )
        else if (upcoming == null)
          const _InlineLoading()
        else if (upcoming.isEmpty)
          const _InlineState(
            message: 'A következő 7 napban nincs várható alkalom.',
          )
        else
          _HomeGroup(
            children: [
              for (final occurrence in upcoming)
                _HomeRow(
                  key: ValueKey(
                    'automation-home-occurrence-${occurrence.occurrenceId}',
                  ),
                  leading: _categoryAvatar(occurrence.categoryId),
                  title: _ruleName(occurrence.ruleId),
                  subtitle:
                      '${_relativeOccurrenceDate(occurrence)} · ${_clock(occurrence.expectedLocalTimeMinutes)}',
                  trailing: _occurrenceAmount(occurrence),
                  onTap: () => _openOccurrence(occurrence),
                  ghost: true,
                ),
            ],
          ),
      ],
    );
  }

  Widget _recentNotifications(AutomationDashboardSnapshot? push) {
    final inbox = push?.recentInbox ?? const <NotificationInboxItem>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Legutóbbi értesítések',
          action: 'Összes',
          onTap: _openInbox,
        ),
        const SizedBox(height: 8),
        if (_pushError != null)
          _InlineState(
            message: 'Az értesítések most nem tölthetők be.',
            onRetry: _refresh,
          )
        else if (push == null)
          const _InlineLoading()
        else if (inbox.isEmpty)
          const _InlineState(
            message:
                'Még nincs elkapott, engedélyezett forrásból származó értesítés.',
          )
        else
          _HomeGroup(
            children: [
              for (final item in inbox)
                _HomeRow(
                  key: ValueKey(
                    'automation-home-notification-${item.notificationId}',
                  ),
                  icon: Icons.notifications_outlined,
                  title: item.title?.isNotEmpty == true
                      ? item.title!
                      : item.sourceAppLabel ?? 'Értesítés',
                  subtitle:
                      '${item.sourceAppLabel ?? 'Forrás'} · ${_humanDate(item.receivedAtUtcMs)}',
                  trailing: _reviewLabel(item.reviewStatus),
                  onTap: () => _openNotification(item),
                ),
            ],
          ),
      ],
    );
  }

  Widget _firstUse() => Column(
    children: [
      const SizedBox(height: 16),
      _HomeGroup(
        children: [
          _HomeRow(
            key: const ValueKey('automation-home-first-recurring'),
            icon: Icons.repeat_rounded,
            title: 'Rendszeres tranzakció beállítása',
            subtitle:
                'Állíts be például havi előfizetést, lakbért vagy fizetést.',
            onTap: _newRecurring,
            tall: true,
          ),
          _HomeRow(
            key: const ValueKey('automation-home-first-push'),
            icon: Icons.account_balance_outlined,
            title: 'Banki értesítések felismerése',
            subtitle:
                'Válassz banki alkalmazást, majd tanítsd meg a Fluvi számára az értesítések felismerését.',
            onTap: _newProfile,
            tall: true,
          ),
        ],
      ),
    ],
  );

  bool _ruleNeedsSetup(RecurrenceRule rule, List<PushProfile> profiles) {
    if (rule.triggerKind != RecurrenceTriggerKind.push ||
        rule.pushProfileId == null ||
        rule.pushRuleId == null) {
      return rule.triggerKind == RecurrenceTriggerKind.push &&
          (rule.pushProfileId == null || rule.pushRuleId == null);
    }
    final profile = profiles
        .where((item) => item.profileId == rule.pushProfileId)
        .firstOrNull;
    return profile == null ||
        profile.state == PushProfileState.waitingForPermission ||
        profile.state == PushProfileState.waitingForTraining ||
        profile.state == PushProfileState.paused;
  }

  String _ruleSummary({
    required int active,
    required int waiting,
    required int paused,
  }) {
    final parts = <String>[];
    if (active > 0) parts.add('$active aktív szabály');
    if (waiting > 0) parts.add('$waiting beállításra vár');
    if (paused > 0) parts.add('$paused szünetel');
    return parts.join(' · ');
  }

  String _ruleName(String ruleId) =>
      (_recurrence?.rules ?? const <RecurrenceRule>[])
          .where((rule) => rule.ruleId == ruleId)
          .map((rule) => rule.name)
          .firstOrNull ??
      'Ismétlődő tranzakció';

  Widget _categoryAvatar(String categoryId) {
    final category = widget.categories
        .where((item) => item.id == categoryId)
        .firstOrNull;
    if (category == null) {
      return const _HomeIcon(icon: Icons.category_outlined);
    }
    return CategoryVisualBadge(
      colorHandle: CategoryColorCatalog.handleOf(category.colorId),
      iconHandle: CategoryIconCatalog.handleOf(category.iconId),
      size: 40,
      iconSize: 18,
    );
  }
}

final class _HomeLoad<T> {
  const _HomeLoad.value(this.data) : error = null;
  const _HomeLoad.error(this.error) : data = null;
  final T? data;
  final Object? error;
}

final class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: _homeInk,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ],
  );
}

final class _HomeGroup extends StatelessWidget {
  const _HomeGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10334155),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0)
            const Divider(
              height: 1,
              indent: 65,
              endIndent: 12,
              color: _homeLine,
            ),
          children[index],
        ],
      ],
    ),
  );
}

final class _HomeRow extends StatelessWidget {
  const _HomeRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.ghost = false,
    this.tall = false,
  });
  final IconData? icon;
  final Widget? leading;
  final String title, subtitle;
  final String? trailing;
  final VoidCallback? onTap;
  final bool ghost, tall;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: tall ? 16 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ?? _HomeIcon(icon: icon!),
            const SizedBox(width: 13),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _homeInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (ghost) ...[
                          const Icon(
                            Icons.auto_awesome_outlined,
                            size: 14,
                            color: _homeMuted,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              color: _homeMuted,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  trailing!,
                  style: const TextStyle(
                    color: _homeMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.right,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.chevron_right_rounded, color: _homeMuted),
              ),
          ],
        ),
      ),
    ),
  );
}

final class _HomeIcon extends StatelessWidget {
  const _HomeIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        color: _homeNeutral,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Icon(icon, size: 22, color: _homeMuted),
    ),
  );
}

final class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.lavender = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool lavender;
  @override
  Widget build(BuildContext context) => Material(
    color: lavender ? const Color(0xfff2effb) : const Color(0xfffff6df),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _HomeIcon(icon: icon),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _homeInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _homeMuted,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _homeMuted),
          ],
        ),
      ),
    ),
  );
}

final class _InlineLoading extends StatelessWidget {
  const _InlineLoading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(20),
    child: Center(child: CircularProgressIndicator()),
  );
}

final class _InlineState extends StatelessWidget {
  const _InlineState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _homeMuted, fontSize: 13),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Újrapróbálás')),
        ],
      ),
    ),
  );
}

String _relativeOccurrenceDate(RecurrenceOccurrence occurrence) {
  final date = DateTime(
    1970,
  ).add(Duration(days: occurrence.expectedLocalEpochDay));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  if (target == today) {
    return 'Ma';
  }
  if (target == DateTime(today.year, today.month, today.day + 1)) {
    return 'Holnap';
  }
  const months = [
    'JAN.',
    'FEBR.',
    'MÁRC.',
    'ÁPR.',
    'MÁJ.',
    'JÚN.',
    'JÚL.',
    'AUG.',
    'SZEPT.',
    'OKT.',
    'NOV.',
    'DEC.',
  ];
  return '${months[target.month - 1]} ${target.day}.';
}

String _clock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String _occurrenceAmount(RecurrenceOccurrence occurrence) =>
    occurrence.expectedAmountScaled100 == null
    ? 'Értesítésből'
    : '${occurrence.amountPolicy == RecurrenceAmountPolicy.estimated ? 'kb. ' : ''}${_money(occurrence.expectedAmountScaled100!)} Ft';

String _money(int amount) {
  final value = amount / 100;
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
}

String _reviewLabel(PushReviewStatus status) => switch (status) {
  PushReviewStatus.pending => 'Ellenőrzésre vár',
  PushReviewStatus.approved => 'Rögzítve',
  PushReviewStatus.ignored => 'Kihagyva',
  PushReviewStatus.rejected => 'Elutasítva',
  PushReviewStatus.none => 'Beérkezett',
};

String _humanDate(int utcMs) {
  final value = DateTime.fromMillisecondsSinceEpoch(utcMs);
  final now = DateTime.now();
  if (value.year == now.year &&
      value.month == now.month &&
      value.day == now.day) {
    return 'Ma ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (value.year == yesterday.year &&
      value.month == yesterday.month &&
      value.day == yesterday.day) {
    return 'Tegnap ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
  return '${value.year}. ${value.month.toString().padLeft(2, '0')}. ${value.day.toString().padLeft(2, '0')}. ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
