import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('test/methods');
  const eventChannel = EventChannel('test/events');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
          if (call.method == 'loadEvents') {
            return <Map<String, Object?>>[
              sampleEvent(
                id: 1,
                appLabel: 'Telegram',
                packageName: 'org.telegram.messenger',
              ),
              sampleEvent(id: 2, appLabel: 'Signal', packageName: 'org.signal'),
            ];
          }
          if (call.method == 'getStatus') {
            return <String, Object?>{
              'captureMode': 'both',
              'notificationListenerEnabled': true,
              'accessibilityEnabled': false,
              'notificationListenerActive': true,
              'accessibilityActive': false,
              'lastNotificationListenerEvent': 1710000000000,
              'lastAccessibilityEvent': 0,
              'totalEvents': 2,
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('filters by app label or package only', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();
    store.setFilterText('telegram');
    store.setFilterEnabled(true);

    expect(store.events, hasLength(1));
    expect(store.events.single.packageName, 'org.telegram.messenger');
  });

  test('invalid regex keeps previous valid filter', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();
    store.setFilterText('Signal');
    store.setFilterEnabled(true);
    store.setFilterText('[');

    expect(store.filterError, isNotNull);
    expect(store.events, hasLength(1));
    expect(store.events.single.appLabel, 'Signal');
  });
}

Map<String, Object?> sampleEvent({
  required int id,
  required String appLabel,
  required String packageName,
}) {
  return <String, Object?>{
    'id': id,
    'timestamp': 1710000000000 + id,
    'source': 'notification_listener',
    'packageName': packageName,
    'appLabel': appLabel,
    'title': 'Title',
    'text': 'Body',
    'bigText': '',
    'subText': '',
    'category': '',
    'notificationKey': '',
    'accessibilityEventType': '',
    'hash': 'hash-$id',
    'isDuplicate': false,
  };
}
