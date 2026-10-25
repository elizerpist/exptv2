import 'package:fluvi/features/automation/data/method_channel_automation_repository.dart';
import 'package:fluvi/features/automation/presentation/push_profile_wizard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const automation = MethodChannel('com.fluvi/automation');
  const permissions = MethodChannel('com.fluvi/automation_permissions');
  final profile = <String, Object>{
    'profileId': 'profile-1',
    'packageName': 'com.bank.example',
    'appLabel': 'Teszt Bank',
    'displayName': 'Teszt Bank',
    'defaultDirection': 'automatic',
    'state': 'waitingForTraining',
    'ruleCount': 0,
    'inboxCount': 0,
    'revision': 1,
  };

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(permissions, (call) async {
      switch (call.method) {
        case 'listInstalledApps':
          return [
            <String, Object>{
              'packageName': 'com.bank.example',
              'label': 'Teszt Bank',
            },
          ];
        case 'getPermissionStatus':
          return <String, Object>{
            'notificationListenerGranted': true,
            'postNotificationsGranted': true,
            'notificationListenerAvailable': true,
            'appNotificationSettingsAvailable': true,
          };
      }
      return true;
    });
    messenger.setMockMethodCallHandler(automation, (call) async {
      switch (call.method) {
        case 'listProfiles':
          return const <Object>[];
        case 'createProfile':
        case 'getProfile':
          return profile;
        case 'listRules':
        case 'listInbox':
          return const <Object>[];
      }
      throw PlatformException(code: 'unexpected', message: call.method);
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(automation, null);
    messenger.setMockMethodCallHandler(permissions, null);
  });

  testWidgets('creates an explicitly selected push profile and opens details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PushProfileWizardPage(
          repository: MethodChannelAutomationRepository(channel: automation),
          permissions: MethodChannelAutomationPermissionRepository(
            channel: permissions,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teszt Bank'));
    await tester.tap(find.text('Következő'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Következő'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil létrehozása'));
    await tester.pumpAndSettle();

    expect(find.text('Push profil'), findsOneWidget);
    expect(find.text('Tanításra vár'), findsAtLeastNWidgets(1));
  });
}
