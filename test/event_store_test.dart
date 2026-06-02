import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exptv2/features/settings/models/notification_parser_rule.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('test/methods');
  const eventChannel = EventChannel('test/events');

  final savedParserRules = <Map<dynamic, dynamic>>[];
  final savedParserProfiles = <Map<dynamic, dynamic>>[];

  setUp(() {
    savedParserRules.clear();
    savedParserProfiles.clear();
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
          if (call.method == 'loadNotificationParserProfiles') {
            return <String, Object?>{
              'profiles': <Object?>[
                <String, Object?>{
                  'id': 'bank-a',
                  'name': 'Bank A',
                  'enabled': true,
                  'appFilterText': r'^Bank A$',
                  'sampleText': 'Paid 999 Ft at Corner Shop',
                  'includeKeyword': 'Paid',
                  'amountPattern': r'(?<amount>\d+)\s*Ft',
                  'merchantPattern': r'at\s+(?<merchant>.+)',
                },
                <String, Object?>{
                  'id': 'bank-b',
                  'name': 'Bank B',
                  'enabled': false,
                  'appFilterText': r'^Bank B$',
                  'sampleText': 'Kártyás vásárlás: Tesco - 12 345 HUF',
                  'includeKeyword': '',
                  'amountPattern': r'(?<amount>\d[\d\s]*)\s*HUF',
                  'merchantPattern': r'vásárlás:\s*(?<merchant>[^-]+)\s*-',
                },
              ],
            };
          }
          if (call.method == 'saveNotificationParserProfiles') {
            savedParserProfiles.add(
              Map<dynamic, dynamic>.from(
                call.arguments as Map<dynamic, dynamic>,
              ),
            );
            return call.arguments;
          }
          if (call.method == 'loadNotificationParserRule') {
            return <String, Object?>{
              'enabled': true,
              'sampleText': 'Paid 999 Ft at Corner Shop',
              'includeKeyword': 'Paid',
              'amountPattern': r'(?<amount>\d+)\s*Ft',
              'merchantPattern': r'at\s+(?<merchant>.+)',
            };
          }
          if (call.method == 'saveNotificationParserRule') {
            savedParserRules.add(
              Map<dynamic, dynamic>.from(
                call.arguments as Map<dynamic, dynamic>,
              ),
            );
            return call.arguments;
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

  test('loads, selects and toggles notification parser profiles', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();

    expect(store.notificationParserProfiles, hasLength(2));
    expect(store.selectedNotificationParserProfile.id, 'bank-a');
    expect(store.notificationParserPreview.merchant, 'Corner Shop');

    store.selectNotificationParserProfile('bank-b');
    expect(store.selectedNotificationParserProfile.id, 'bank-b');
    expect(store.notificationParserPreview.merchant, 'Tesco');

    await store.setNotificationParserProfileEnabled('bank-b', true);

    expect(store.notificationParserConfig.activeProfiles, hasLength(2));
    expect(savedParserProfiles, hasLength(1));
  });

  test('adds a new notification parser profile', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();
    await store.addNotificationParserProfile();

    expect(store.notificationParserProfiles, hasLength(3));
    expect(store.selectedNotificationParserProfile.name, 'Profil 3');
    expect(savedParserProfiles, hasLength(1));
  });

  test('loads and saves notification parser rules', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();

    expect(store.notificationParserRule.includeKeyword, 'Paid');
    expect(store.notificationParserPreview.amountValue, 999);
    expect(store.notificationParserPreview.merchant, 'Corner Shop');

    await store.setNotificationParserRule(
      NotificationParserRule.defaults().copyWith(
        sampleText: 'Kártyás vásárlás: Tesco - 12 345 HUF',
        includeKeyword: '',
        amountPattern: r'(?<amount>\d[\d\s]*)\s*HUF',
        merchantPattern: r'vásárlás:\s*(?<merchant>[^-]+)\s*-',
      ),
    );

    expect(store.notificationParserPreview.amountValue, 12345);
    expect(savedParserProfiles, hasLength(1));
    final profiles = savedParserProfiles.single['profiles'] as List<dynamic>;
    final first = profiles.first as Map<dynamic, dynamic>;
    expect(first['merchantPattern'], r'vásárlás:\s*(?<merchant>[^-]+)\s*-');
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
