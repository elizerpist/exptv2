import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/runtime_monitoring/data/method_channel_runtime_monitoring_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.fluvi/runtime_monitoring');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'reads actual runtime state rather than inferring it from a switch',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getRuntimeStatus');
        return <String, Object?>{
          'foregroundRequested': true,
          'backgroundRequested': false,
          'foregroundServiceRunning': false,
          'notificationListenerGranted': true,
          'listenerConnected': false,
          'postNotificationsGranted': false,
          'statusChannelEnabled': true,
          'appSurfaceVisible': false,
          'stoppedByUser': false,
          'captureAllowed': false,
          'state': 'foregroundStartFailed',
          'message': 'A rendszer nem engedte az előtérszolgáltatás indítását',
        };
      });

      final status = await MethodChannelRuntimeMonitoringRepository(
        channel: channel,
      ).status();

      expect(status.foregroundRequested, isTrue);
      expect(status.foregroundServiceRunning, isFalse);
      expect(status.captureAllowed, isFalse);
      expect(status.state, 'foregroundStartFailed');
    },
  );

  test('writes independent foreground and background requests', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, Object?>{
        'foregroundRequested': call.method == 'setForegroundRequested',
        'backgroundRequested': call.method == 'setBackgroundRequested',
        'foregroundServiceRunning': false,
        'notificationListenerGranted': true,
        'listenerConnected': true,
        'postNotificationsGranted': true,
        'statusChannelEnabled': true,
        'appSurfaceVisible': true,
        'stoppedByUser': false,
        'captureAllowed': true,
        'state': 'active',
        'message': 'Aktív',
      };
    });
    final repository = MethodChannelRuntimeMonitoringRepository(
      channel: channel,
    );

    await repository.setForegroundRequested(true);
    await repository.setBackgroundRequested(true);

    expect(calls.map((call) => call.method), [
      'setForegroundRequested',
      'setBackgroundRequested',
    ]);
    expect(calls.first.arguments, {'requested': true});
    expect(calls.last.arguments, {'requested': true});
  });
}
