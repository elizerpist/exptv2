import 'package:fluvi/features/automation/data/method_channel_automation_repository.dart';
import 'package:fluvi/features/notification_appearance/domain/notification_appearance_repository.dart';
import 'package:fluvi/features/runtime_monitoring/domain/runtime_monitoring_repository.dart';
import 'package:fluvi/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const permissionsChannel = MethodChannel('test/settings-permissions');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(permissionsChannel, (call) async {
      if (call.method == 'getPermissionStatus') {
        return <String, Object?>{
          'notificationListenerGranted': true,
          'postNotificationsGranted': true,
          'notificationListenerAvailable': true,
          'appNotificationSettingsAvailable': true,
        };
      }
      if (call.method == 'sendTestNotification') {
        return <String, Object?>{
          'status': 'submitted',
          'probeId': 'probe',
          'message': 'Küldési kérés átadva.',
        };
      }
      return true;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(permissionsChannel, null));

  testWidgets('foreground and background mode remain independent switches', (
    tester,
  ) async {
    final runtime = _RuntimeFake();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          permissions: MethodChannelAutomationPermissionRepository(
            channel: permissionsChannel,
          ),
          runtime: runtime,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -520));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('runtime-foreground-switch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('runtime-background-switch')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('runtime-background-switch')));
    await tester.pumpAndSettle();

    expect(runtime.backgroundCalls, [true]);
    expect(runtime.foregroundCalls, isEmpty);
    expect(runtime.value.backgroundRequested, isTrue);
    expect(runtime.value.foregroundRequested, isFalse);
  });

  testWidgets('notification icon choice is independent from runtime modes', (
    tester,
  ) async {
    final appearance = _NotificationAppearanceFake();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          permissions: MethodChannelAutomationPermissionRepository(
            channel: permissionsChannel,
          ),
          notificationAppearance: appearance,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -620));
    await tester.pumpAndSettle();
    final filled = find.byKey(const ValueKey('notification-small-icon-filled'));
    expect(filled, findsOneWidget);
    await tester.ensureVisible(filled);
    await tester.tap(filled);
    await tester.pumpAndSettle();

    expect(appearance.calls, [NotificationSmallIconStyle.filled]);
    expect(appearance.value, NotificationSmallIconStyle.filled);
  });
}

final class _RuntimeFake implements RuntimeMonitoringRepository {
  RuntimeMonitoringStatus value = _status();
  final foregroundCalls = <bool>[];
  final backgroundCalls = <bool>[];

  @override
  Future<RuntimeMonitoringStatus> setBackgroundRequested(bool requested) async {
    backgroundCalls.add(requested);
    return value = _status(
      background: requested,
      foreground: value.foregroundRequested,
    );
  }

  @override
  Future<RuntimeMonitoringStatus> setForegroundRequested(bool requested) async {
    foregroundCalls.add(requested);
    return value = _status(
      foreground: requested,
      background: value.backgroundRequested,
    );
  }

  @override
  Future<RuntimeMonitoringStatus> status() async => value;

  @override
  Future<RuntimeMonitoringStatus> stopMonitoring() async => value = _status();
}

RuntimeMonitoringStatus _status({
  bool foreground = false,
  bool background = false,
}) => RuntimeMonitoringStatus(
  foregroundRequested: foreground,
  backgroundRequested: background,
  foregroundServiceRunning: foreground,
  notificationListenerGranted: true,
  listenerConnected: true,
  postNotificationsGranted: true,
  statusChannelEnabled: true,
  appSurfaceVisible: true,
  stoppedByUser: false,
  captureAllowed: foreground || background,
  state: foreground || background ? 'active' : 'off',
  message: foreground || background ? 'Aktív' : 'Kikapcsolva',
);

final class _NotificationAppearanceFake
    implements NotificationAppearanceRepository {
  NotificationSmallIconStyle value = NotificationSmallIconStyle.outline;
  final calls = <NotificationSmallIconStyle>[];

  @override
  Future<NotificationSmallIconStyle> setSmallIconStyle(
    NotificationSmallIconStyle style,
  ) async {
    calls.add(style);
    return value = style;
  }

  @override
  Future<NotificationSmallIconStyle> smallIconStyle() async => value;
}
