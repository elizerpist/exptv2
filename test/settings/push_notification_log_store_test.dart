import 'package:exptv2/features/settings/models/notification_parser_rule.dart';
import 'package:exptv2/features/settings/models/push_notification_log_event.dart';
import 'package:exptv2/features/settings/state/push_notification_log_store.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/state/event_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('test/push_log_methods');
  const eventChannel = EventChannel('test/push_log_events');

  final pageQueries = <Map<dynamic, dynamic>>[];
  final createdTransactions = <Map<dynamic, dynamic>>[];
  final savedProfiles = <Map<dynamic, dynamic>>[];
  final systemEventIds = <int>[];

  setUp(() {
    pageQueries.clear();
    createdTransactions.clear();
    savedProfiles.clear();
    systemEventIds.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
          switch (call.method) {
            case 'loadEvents':
              return <Map<String, Object?>>[];
            case 'getStatus':
              return <String, Object?>{
                'captureMode': 'both',
                'notificationListenerEnabled': true,
                'accessibilityEnabled': false,
                'notificationListenerActive': true,
                'accessibilityActive': false,
                'lastNotificationListenerEvent': 0,
                'lastAccessibilityEvent': 0,
                'totalEvents': 1,
              };
            case 'loadNotificationParserProfiles':
              return profilePayload();
            case 'saveNotificationParserProfiles':
              savedProfiles.add(
                Map<dynamic, dynamic>.from(
                  call.arguments as Map<dynamic, dynamic>,
                ),
              );
              return call.arguments;
            case 'loadNotificationEventPage':
              final args = Map<dynamic, dynamic>.from(
                call.arguments as Map<dynamic, dynamic>,
              );
              pageQueries.add(args);
              final offset = args['offset'] as int? ?? 0;
              if (offset >= 1) {
                return <String, Object?>{
                  'events': <Object?>[
                    pushLogEventRow(
                      id: 78,
                      text: 'Kártyás vásárlás: Spar - 4 500 HUF',
                    ),
                  ],
                  'totalCount': 2,
                  'limit': args['limit'],
                  'offset': offset,
                };
              }
              return <String, Object?>{
                'events': <Object?>[
                  pushLogEventRow(
                    id: 77,
                    status: createdTransactions.isEmpty
                        ? 'missing'
                        : 'linked',
                    statusText: createdTransactions.isEmpty
                        ? 'Nincs hozzárendelt log'
                        : 'Van tranzakció',
                    linkedTransactionId: createdTransactions.isEmpty
                        ? null
                        : 26060701,
                  ),
                ],
                'totalCount': 2,
                'limit': args['limit'],
                'offset': offset,
              };
            case 'expenseAddTransaction':
              final payload = Map<dynamic, dynamic>.from(
                call.arguments as Map<dynamic, dynamic>,
              );
              createdTransactions.add(payload);
              return <String, Object?>{
                'id': 26060701,
                'date': payload['date'],
                'time': payload['time'],
                'latitude': null,
                'longitude': null,
                'address': payload['address'],
                'merchant': payload['merchant'],
                'amount': -(payload['amount'] as num).toDouble(),
                'userAssignedName': null,
                'transactionCategoryID': payload['transactionCategoryID'],
                'sourceNotificationEventId':
                    payload['sourceNotificationEventId'],
              };
            case 'markNotificationEventSystem':
              final args = call.arguments as Map<dynamic, dynamic>;
              systemEventIds.add((args['id'] as num).toInt());
              return true;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('loads first page and appends additional push log events', () async {
    final harness = await startHarness();
    final store = harness.logStore;

    await store.loadFirstPage();
    await store.loadMore();

    expect(store.events.map((event) => event.id).toList(), <int>[77, 78]);
    expect(store.totalCount, 2);
    expect(store.hasMore, isFalse);
    expect(pageQueries.map((query) => query['offset']), <int>[0, 1]);
    expect(pageQueries.every((query) => query['limit'] == 60), isTrue);

    harness.dispose();
  });

  test('filters reset paging and reload the first page', () async {
    final harness = await startHarness();
    final store = harness.logStore;

    await store.setFilters(
      year: 2026,
      month: 6,
      query: 'tesco',
      status: PushNotificationLogStatus.missing,
    );

    expect(store.query.year, 2026);
    expect(store.query.month, 6);
    expect(store.query.status, PushNotificationLogStatus.missing);
    expect(pageQueries.single['offset'], 0);
    expect(pageQueries.single['query'], 'tesco');
    expect(pageQueries.single['status'], 'missing');

    harness.dispose();
  });

  test('marks a push log event as system and reloads', () async {
    final harness = await startHarness();
    final store = harness.logStore;

    await store.loadFirstPage();
    await store.markSystem(store.events.single);

    expect(systemEventIds, <int>[77]);
    expect(pageQueries, hasLength(2));

    harness.dispose();
  });

  test(
    'valid training creates uncategorized transaction linked to event',
    () async {
      final harness = await startHarness();
      final store = harness.logStore;

      await store.loadFirstPage();
      final event = store.events.single;
      final trainedProfile = harness
          .parserStore
          .selectedNotificationParserProfile
          .copyWith(sampleText: event.fullText, includeKeyword: '')
          .learnAmountFromSelection('12 345 HUF')
          .learnMerchantFromSelection('Tesco');

      await store.trainAndCreateTransaction(
        event: event,
        trainedProfile: trainedProfile,
      );

      expect(createdTransactions, hasLength(1));
      expect(createdTransactions.single['merchant'], 'Tesco');
      expect(createdTransactions.single['amount'], 12345);
      expect(createdTransactions.single['type'], 'expense');
      expect(createdTransactions.single['transactionCategoryID'], isNull);
      expect(createdTransactions.single['date'], '2026.06.07');
      expect(createdTransactions.single['time'], '21:10');
      expect(createdTransactions.single['sourceNotificationEventId'], 77);
      expect(savedProfiles, hasLength(1));
      expect(store.events.single.status, PushNotificationLogStatus.linked);

      harness.dispose();
    },
  );
}

Future<_Harness> startHarness() async {
  final bridge = NativeBridge(
    methodChannel: const MethodChannel('test/push_log_methods'),
    eventChannel: const EventChannel('test/push_log_events'),
  );
  final parserStore = EventStore(bridge, realtimeEnabled: false);
  await parserStore.start();
  final logStore = PushNotificationLogStore(
    bridge: bridge,
    parserStore: parserStore,
  );
  return _Harness(parserStore: parserStore, logStore: logStore);
}

class _Harness {
  const _Harness({required this.parserStore, required this.logStore});

  final EventStore parserStore;
  final PushNotificationLogStore logStore;

  void dispose() {
    logStore.dispose();
    parserStore.dispose();
  }
}

Map<String, Object?> profilePayload() {
  return <String, Object?>{
    'profiles': <Object?>[
      <String, Object?>{
        'id': 'bank-a',
        'name': 'Bank A',
        'enabled': true,
        'appFilterText': r'^Bank A$',
        'sampleText': 'Kártyás vásárlás: Tesco - 12 345 HUF',
        'includeKeyword': '',
        'amountPattern': r'(?<amount>\d[\d\s]*)\s*HUF',
        'merchantPattern': r'vásárlás:\s*(?<merchant>[^-]+)\s*-',
      },
    ],
  };
}

Map<String, Object?> pushLogEventRow({
  required int id,
  String text = 'Kártyás vásárlás: Tesco - 12 345 HUF',
  String status = 'missing',
  String statusText = 'Nincs hozzárendelt log',
  int? linkedTransactionId,
}) {
  return <String, Object?>{
    'id': id,
    'timestamp': DateTime(2026, 6, 7, 21, 10).millisecondsSinceEpoch,
    'source': 'notification_listener',
    'packageName': 'hu.bank.app',
    'appLabel': 'Bank',
    'title': 'Vásárlás',
    'text': text,
    'bigText': '',
    'subText': '',
    'category': '',
    'notificationKey': 'n-$id',
    'accessibilityEventType': '',
    'hash': 'h-$id',
    'isDuplicate': false,
    'manualStatus': '',
    'displayText': text,
    'status': status,
    'statusText': statusText,
    'linkedTransactionId': linkedTransactionId,
  };
}
