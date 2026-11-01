import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/notification_appearance/data/method_channel_notification_appearance_repository.dart';
import 'package:fluvi/features/notification_appearance/domain/notification_appearance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.fluvi/notification_appearance');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('uses outline for a missing or invalid persisted style', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getNotificationSmallIconStyle');
      return <String, Object?>{'style': 'unknown-old-value'};
    });

    final style = await MethodChannelNotificationAppearanceRepository(
      channel: channel,
    ).smallIconStyle();

    expect(style, NotificationSmallIconStyle.outline);
  });

  test(
    'uses outline when an older bridge returns no appearance payload',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getNotificationSmallIconStyle');
        return null;
      });

      final style = await MethodChannelNotificationAppearanceRepository(
        channel: channel,
      ).smallIconStyle();

      expect(style, NotificationSmallIconStyle.outline);
    },
  );

  test(
    'saves the stable filled name and waits for native confirmation',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'setNotificationSmallIconStyle');
        expect(call.arguments, {'style': 'filled'});
        return <String, Object?>{'style': 'filled'};
      });

      final style = await MethodChannelNotificationAppearanceRepository(
        channel: channel,
      ).setSmallIconStyle(NotificationSmallIconStyle.filled);

      expect(style, NotificationSmallIconStyle.filled);
    },
  );
}
