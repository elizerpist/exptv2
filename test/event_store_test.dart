import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exptv2/features/settings/models/notification_parser_rule.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('test/methods');
  const eventChannel = EventChannel('test/events');
  const eventMethodChannel = MethodChannel('test/events');

  final savedParserRules = <Map<dynamic, dynamic>>[];
  final savedParserProfiles = <Map<dynamic, dynamic>>[];
  var firstProfileEnabled = true;
  var installedAppsLoadCount = 0;

  setUp(() {
    savedParserRules.clear();
    savedParserProfiles.clear();
    firstProfileEnabled = true;
    installedAppsLoadCount = 0;
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
                  'enabled': firstProfileEnabled,
                  'appFilterText': r'^Bank A$',
                  'packageName': 'hu.bank.a',
                  'appLabel': 'Bank A',
                  'sampleText': 'Paid 999 Ft at Corner Shop',
                  'includeKeyword': 'Paid',
                  'amountPattern': r'(?<amount>\d+)\s*Ft',
                  'merchantPattern': r'at\s+(?<merchant>.+)',
                },
                <String, Object?>{
                  'id': 'bank-b',
                  'name': 'Bank B',
                  'enabled': !firstProfileEnabled,
                  'appFilterText': r'^Bank B$',
                  'packageName': 'hu.bank.b',
                  'appLabel': 'Bank B',
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
          if (call.method == 'listInstalledApps') {
            installedAppsLoadCount += 1;
            return <Map<String, Object?>>[
              <String, Object?>{
                'packageName': 'hu.bank.a',
                'label': 'Bank A',
                'iconBase64': 'YmFuay1h',
              },
              <String, Object?>{
                'packageName': 'hu.bank.b',
                'label': 'Bank B',
                'iconBase64': 'YmFuay1i',
              },
            ];
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventMethodChannel, null);
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

  test(
    'selects the first enabled notification parser profile on load',
    () async {
      firstProfileEnabled = false;
      final store = EventStore(
        NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
        realtimeEnabled: false,
      );

      await store.start();

      expect(store.selectedNotificationParserProfile.id, 'bank-b');
    },
  );

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

  test('caches installed app list after startup preload', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();
    final first = await store.listInstalledApps();
    final second = await store.listInstalledApps();

    expect(first.map((app) => app.packageName), <String>[
      'hu.bank.a',
      'hu.bank.b',
    ]);
    expect(second, same(first));
    expect(installedAppsLoadCount, 1);
  });

  test('can force refresh the installed app cache', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();
    await store.listInstalledApps();
    await store.listInstalledApps(forceRefresh: true);

    expect(installedAppsLoadCount, 2);
  });

  test('deletes selected notification parser profile and selects fallback', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();
    store.selectNotificationParserProfile('bank-a');
    await store.deleteNotificationParserProfile('bank-a');

    expect(store.notificationParserProfiles.map((profile) => profile.id), [
      'bank-b',
    ]);
    expect(store.selectedNotificationParserProfile.id, 'bank-b');
    expect(savedParserProfiles, hasLength(1));
    final savedRows = savedParserProfiles.single['profiles'] as List<dynamic>;
    expect(savedRows, hasLength(1));
    expect((savedRows.single as Map<dynamic, dynamic>)['id'], 'bank-b');
  });

  test('deletes a non-selected notification parser profile', () async {
    final store = EventStore(
      NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
      realtimeEnabled: false,
    );

    await store.start();
    await store.deleteNotificationParserProfile('bank-b');

    expect(store.notificationParserProfiles.map((profile) => profile.id), [
      'bank-a',
    ]);
    expect(store.selectedNotificationParserProfile.id, 'bank-a');
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

  test('watchEvents routes native debug payloads away from event parsing', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventMethodChannel, (call) async => null);
    final bridge = NativeBridge(
      methodChannel: methodChannel,
      eventChannel: eventChannel,
    );
    final events = <Object>[];
    final debugLogs = <String>[];

    final subscription = bridge
        .watchEvents(onDebugLog: debugLogs.add)
        .listen(events.add);
    await Future<void>.delayed(Duration.zero);

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'test/events',
          const StandardMethodCodec().encodeSuccessEnvelope(<String, Object?>{
            'type': 'debug_log',
            'message':
                '[PushParser] capture skipped package=org.kustom.widget',
          }),
          (_) {},
        );
    await Future<void>.delayed(Duration.zero);

    expect(events, isEmpty);
    expect(debugLogs, <String>[
      '[PushParser] capture skipped package=org.kustom.widget',
    ]);

    await subscription.cancel();
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
