import 'package:fluvi/features/automation/domain/automation_models.dart';
import 'package:fluvi/features/automation/domain/automation_repository.dart';
import 'package:fluvi/features/automation/presentation/push_profile_navigation.dart';
import 'package:fluvi/features/automation/presentation/push_profile_wizard_page.dart';
import 'package:fluvi/features/automation/presentation/unified_push_profile_pages.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => PreparedVectorAssetAtlas.instance.prepare());

  testWidgets(
    'the dashboard presentation selector drives the next legacy or unified push flow',
    (tester) async {
      final visual = DashboardHeaderVisualController(vsync: tester);
      final preferences = DashboardPresentationPreferencesController(
        store: InMemoryDashboardPresentationPreferencesStore(),
      );
      addTearDown(preferences.dispose);
      final repository = _PushAutomationFake();
      final permissions = _PushPermissionFake();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 520,
                  child: DashboardHeaderVisualTuner(
                    controller: visual,
                    dashboardPresentationPreferences: preferences,
                  ),
                ),
                Builder(
                  builder: (context) => FilledButton(
                    onPressed: () => PushProfileNavigation.openCreate(
                      context,
                      design: preferences.value.pushProfileUiDesign,
                      repository: repository,
                      permissions: permissions,
                    ),
                    child: const Text('Új push profil'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (!visual.isTunerSectionExpanded(
        DashboardHeaderTunerSection.appearance,
      )) {
        visual.toggleTunerSection(DashboardHeaderTunerSection.appearance);
        await tester.pump();
      }

      final legacy = find.byKey(
        const ValueKey('dashboard-push-profile-ui-legacy'),
      );
      // The tuner is a lazily-built scroll view.  Drive the real dashboard
      // settings panel to the choice instead of injecting the enum directly
      // into the navigation entry point.
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
      expect(preferences.value.pushProfileUiDesign, PushProfileUiDesign.legacy);

      await tester.tap(find.text('Új push profil'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byType(PushProfileWizardPage, skipOffstage: false),
        findsOneWidget,
      );
      Navigator.of(
        tester.element(find.byType(PushProfileWizardPage, skipOffstage: false)),
      ).pop();
      await tester.pump(const Duration(milliseconds: 500));

      final unified = find.byKey(
        const ValueKey('dashboard-push-profile-ui-unified'),
      );
      await tester.scrollUntilVisible(
        unified,
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
      await tester.ensureVisible(unified);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(unified);
      await tester.pump();
      expect(
        preferences.value.pushProfileUiDesign,
        PushProfileUiDesign.unified,
      );
      await tester.tap(find.text('Új push profil'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byType(UnifiedPushProfileEditorPage, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Alkalmazás kiválasztása', skipOffstage: false),
        findsOneWidget,
      );
      visual.dispose();
    },
  );

  testWidgets('unified push editor keeps compact right-aligned CTA actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('unified-push-editor-visual-boundary'),
        child: MaterialApp(
          home: UnifiedPushProfileEditorPage.create(
            repository: _PushAutomationFake(),
            permissions: _PushPermissionFake(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Válassz alkalmazást'), findsOneWidget);
    final cancel = tester.getRect(
      find.byKey(const ValueKey('unified-push-cta-secondary')),
    );
    final create = tester.getRect(
      find.byKey(const ValueKey('unified-push-cta-primary')),
    );
    expect(cancel.top, closeTo(create.top, 0.1));
    expect(cancel.right, lessThan(create.left));
    expect(create.right, closeTo(370, 0.5));

    await expectLater(
      find.byKey(const ValueKey('unified-push-editor-visual-boundary')),
      matchesGoldenFile(
        '../../../goldens/unified_push_profile_editor_empty.png',
      ),
    );
  });
}

final class _PushAutomationFake implements AutomationRepository {
  @override
  Future<List<PushProfile>> listProfiles() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _PushPermissionFake implements AutomationPermissionRepository {
  @override
  Future<AutomationPermissionStatus> getPermissionStatus() async =>
      const AutomationPermissionStatus(
        notificationListenerGranted: false,
        postNotificationsGranted: false,
        notificationListenerAvailable: true,
        appNotificationSettingsAvailable: true,
      );

  @override
  Future<List<InstalledApplication>> listInstalledApps() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
