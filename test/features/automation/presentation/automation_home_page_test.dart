import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/features/automation/domain/automation_models.dart';
import 'package:fluvi/features/automation/domain/automation_repository.dart';
import 'package:fluvi/features/automation/presentation/automation_dashboard_page.dart';
import 'package:fluvi/features/automation/presentation/unified_automation_home_page.dart';
import 'package:fluvi/features/automation/presentation/unified_push_profile_pages.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  testWidgets(
    'the dashboard Appearance selector swaps an already built Automation tab',
    (tester) async {
      final visual = DashboardHeaderVisualController(vsync: tester);
      final preferences = DashboardPresentationPreferencesController(
        store: InMemoryDashboardPresentationPreferencesStore(),
      );
      addTearDown(preferences.dispose);
      final repository = _HomeRepository.empty();
      const permissions = _PermissionFake();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 360,
                  child: DashboardHeaderVisualTuner(
                    controller: visual,
                    dashboardPresentationPreferences: preferences,
                  ),
                ),
                Expanded(
                  child:
                      ValueListenableBuilder<DashboardPresentationPreferences>(
                        valueListenable: preferences,
                        builder: (context, value, _) => AutomationDashboardPage(
                          repository: repository,
                          permissions: permissions,
                          automationHomeUiDesign: value.automationHomeUiDesign,
                          recurringUiDesign: () => value.recurringUiDesign,
                          pushProfileUiDesign: () => value.pushProfileUiDesign,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey('unified-automation-home-page')),
        findsOneWidget,
      );

      if (!visual.isTunerSectionExpanded(
        DashboardHeaderTunerSection.appearance,
      )) {
        visual.toggleTunerSection(DashboardHeaderTunerSection.appearance);
        await tester.pump();
      }
      final legacy = find.byKey(
        const ValueKey('dashboard-automation-home-legacy'),
      );
      await tester.scrollUntilVisible(
        legacy,
        260,
        scrollable: find
            .descendant(
              of: find.byKey(
                const ValueKey('dashboard-header-visual-tuner-list'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(legacy);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(legacy);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        preferences.value.automationHomeUiDesign,
        AutomationHomeUiDesign.legacy,
      );
      expect(
        find.byKey(const ValueKey('automation-dashboard-page')),
        findsOneWidget,
      );

      final unified = find.byKey(
        const ValueKey('dashboard-automation-home-unified'),
      );
      await tester.ensureVisible(unified);
      await tester.tap(unified);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        preferences.value.automationHomeUiDesign,
        AutomationHomeUiDesign.unified,
      );
      expect(
        find.byKey(const ValueKey('unified-automation-home-page')),
        findsOneWidget,
      );
      visual.dispose();
    },
  );

  testWidgets(
    'one pending review is a direct action and requests the server-side pending page',
    (tester) async {
      final repository = _HomeRepository.pending();
      await tester.pumpWidget(
        MaterialApp(
          home: UnifiedAutomationHomePage(
            repository: repository,
            permissions: const _PermissionFake(),
            recurringUiDesign: RecurringUiDesign.unified,
            pushProfileUiDesign: PushProfileUiDesign.unified,
            direction: LedgerDirection.expense,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.requestedReviewStatus, PushReviewStatus.pending);
      await tester.tap(
        find.byKey(const ValueKey('automation-home-action-pending-review')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UnifiedPushInboxDetailPage), findsOneWidget);
    },
  );

  testWidgets('verified empty data shows the two focused first-use actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UnifiedAutomationHomePage(
          repository: _HomeRepository.empty(),
          permissions: const _PermissionFake(),
          recurringUiDesign: RecurringUiDesign.unified,
          pushProfileUiDesign: PushProfileUiDesign.unified,
          direction: LedgerDirection.expense,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('automation-home-first-recurring')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('automation-home-first-push')),
      findsOneWidget,
    );
  });

  testWidgets('unified Automation home visual: pending review', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('unified-automation-home-visual-boundary'),
        child: MaterialApp(
          home: UnifiedAutomationHomePage(
            repository: _HomeRepository.pending(),
            permissions: const _PermissionFake(),
            recurringUiDesign: RecurringUiDesign.unified,
            pushProfileUiDesign: PushProfileUiDesign.unified,
            direction: LedgerDirection.expense,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('unified-automation-home-visual-boundary')),
      matchesGoldenFile('../../../goldens/unified_automation_home_pending.png'),
    );
  });
}

final class _HomeRepository implements AutomationRepository {
  _HomeRepository({
    required this.home,
    required this.recurrence,
    this.pending = const <NotificationInboxItem>[],
  });

  factory _HomeRepository.empty() => _HomeRepository(
    home: const AutomationDashboardSnapshot(
      profiles: [],
      pendingReviewCount: 0,
      capturedLast30Days: 0,
      recentInbox: [],
    ),
    recurrence: const RecurrenceDashboardSnapshot(
      rules: [],
      pendingCount: 0,
      dueCount: 0,
      realizedCount: 0,
      showPendingGhostsInLedger: true,
    ),
  );

  factory _HomeRepository.pending() {
    const item = NotificationInboxItem(
      notificationId: 'notification-1',
      profileId: 'profile-1',
      sourcePackageName: 'bank.app',
      sourceAppLabel: 'Banki alkalmazás',
      title: 'Kártyás vásárlás',
      rawText: 'Netflix 3 990 Ft',
      receivedAtUtcMs: 1733047200000,
      parseStatus: 'parsed',
      processingStatus: 'review',
      trainingStatus: 'unused',
      reviewStatus: PushReviewStatus.pending,
      confidence: null,
      suggestedPayloadJson: null,
      diagnosticsJson: null,
      ledgerEntryId: null,
    );
    return _HomeRepository(
      home: const AutomationDashboardSnapshot(
        profiles: [],
        pendingReviewCount: 1,
        capturedLast30Days: 0,
        recentInbox: [item],
      ),
      recurrence: const RecurrenceDashboardSnapshot(
        rules: [],
        pendingCount: 0,
        dueCount: 0,
        realizedCount: 0,
        showPendingGhostsInLedger: true,
      ),
      pending: const [item],
    );
  }

  final AutomationDashboardSnapshot home;
  final RecurrenceDashboardSnapshot recurrence;
  final List<NotificationInboxItem> pending;
  PushReviewStatus? requestedReviewStatus;

  @override
  Future<AutomationDashboardSnapshot> homeDashboard() async => home;
  @override
  Future<AutomationDashboardSnapshot> dashboard() async => home;
  @override
  Future<RecurrenceDashboardSnapshot> recurrenceDashboard() async => recurrence;
  @override
  Future<List<RecurrenceOccurrence>> upcomingRecurrenceOccurrences({
    required int fromUtcMs,
    required int toUtcMs,
    int limit = 3,
  }) async => const [];
  @override
  Future<List<NotificationInboxItem>> inbox({
    String? profileId,
    PushReviewStatus? reviewStatus,
    int limit = 50,
    int offset = 0,
  }) async {
    requestedReviewStatus = reviewStatus;
    return reviewStatus == PushReviewStatus.pending ? pending : const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _PermissionFake implements AutomationPermissionRepository {
  const _PermissionFake();
  @override
  Future<AutomationPermissionStatus> getPermissionStatus() async =>
      const AutomationPermissionStatus(
        notificationListenerGranted: true,
        postNotificationsGranted: true,
        notificationListenerAvailable: true,
        appNotificationSettingsAvailable: true,
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
