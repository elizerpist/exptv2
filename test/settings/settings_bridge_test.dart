import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:exptv2/features/settings/models/notification_parser_rule.dart';
import 'package:exptv2/features/settings/models/notification_settings.dart';
import 'package:exptv2/features/settings/models/push_notification_log_event.dart';
import 'package:exptv2/features/settings/models/recurring_transaction.dart';
import 'package:exptv2/features/transactions/models/recurring_rule.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/settings_methods');
  late NativeBridge bridge;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/settings_events'),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'expenseLoadSettings':
              return <String, Object?>{
                'themeSettings': <String, Object?>{
                  'magnetType': 'magnetcard',
                  'cardColor': 'lightgray',
                  'theme': 'Türkiz',
                  'backgroundColor': 'gray',
                  'boxColor': 'white',
                  'buttonSurfaceStyle': 'raisedInset',
                  'contentSurfaceStyle': 'insetInset',
                  'ghostLogboxSurfaceStyle': 'insetInset',
                  'categoryMenuPresentation': 'slideUpSheet',
                  'categoryCardShadowEnabled': false,
                  'logboxShadowEnabled': false,
                  'headerPillShadowEnabled': false,
                  'summaryPillShadowEnabled': false,
                  'searchPillShadowEnabled': false,
                  'ghostLogboxSettings': <String, Object?>{
                    'borderStyle': 'dashed',
                    'backgroundOpacityEnabled': true,
                    'avatarOpacityEnabled': false,
                    'textOpacityEnabled': false,
                    'avatarBadgeEnabled': true,
                    'textTone': 'normal',
                    'expectedLabelEnabled': true,
                  },
                  'backheaderStyle': 'heroToken',
                },
                'fastInfoConfig': <String, Object?>{
                  'pills': <Object?>[
                    <String, Object?>{
                      'id': 'megtakaritas',
                      'label': 'Megtakarítás',
                      'value': '156,780 Ft',
                      'type': 'pill',
                    },
                    <String, Object?>{
                      'id': 'havi_limit_allapot',
                      'label': 'Havi limit állapot',
                      'value': '74%',
                      'type': 'pill',
                    },
                    null,
                  ],
                  'boxes': <Object?>[
                    <String, Object?>{
                      'id': 'mai_nap',
                      'label': 'Mai nap',
                      'value': '2 db',
                      'extra': '-4,500 Ft',
                      'type': 'box',
                    },
                    null,
                    null,
                  ],
                },
                'pushRecurringSettings': <String, Object?>{
                  'conflictPolicy': 'askOnMultipleMatches',
                },
                'securitySettings': <String, Object?>{
                  'pinEnabled': true,
                  'biometricEnabled': false,
                  'biometricAvailable': true,
                  'biometricLabel': 'Ujjlenyomat elerheto',
                },
              };
            case 'expenseUpdateThemeSettings':
              return call.arguments;
            case 'expenseUpdateFastInfoConfig':
              return call.arguments;
            case 'expenseUpdatePushRecurringSettings':
              return <String, Object?>{'pushRecurringSettings': call.arguments};
            case 'expenseUpdateNotificationSettings':
              return <String, Object?>{'notificationSettings': call.arguments};
            case 'expenseSetSecurityPin':
              return <String, Object?>{
                'pinEnabled': true,
                'biometricEnabled': false,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'expenseChangeSecurityPin':
              return <String, Object?>{
                'pinEnabled': true,
                'biometricEnabled': false,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'expenseClearSecurityPin':
              return <String, Object?>{
                'pinEnabled': false,
                'biometricEnabled': false,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'expenseVerifySecurityPin':
              return (call.arguments as Map<dynamic, dynamic>)['pin'] == '1234';
            case 'expenseSetBiometricEnabled':
              return <String, Object?>{
                'pinEnabled': true,
                'biometricEnabled':
                    (call.arguments as Map<dynamic, dynamic>)['enabled'] ==
                    true,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'expenseGetBiometricAvailability':
              return <String, Object?>{
                'pinEnabled': false,
                'biometricEnabled': false,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
            case 'expenseAuthenticateBiometric':
              return true;
            case 'loadNotificationParserProfiles':
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
            case 'saveNotificationParserProfiles':
              return call.arguments;
            case 'loadNotificationParserRule':
              return <String, Object?>{
                'enabled': true,
                'sampleText': 'Paid 999 Ft at Corner Shop',
                'includeKeyword': 'Paid',
                'amountPattern': r'(?<amount>\d+)\s*Ft',
                'merchantPattern': r'at\s+(?<merchant>.+)',
              };
            case 'saveNotificationParserRule':
              return call.arguments;
            case 'loadAutomaticPushParserEnabled':
              return true;
            case 'saveAutomaticPushParserEnabled':
              return call.arguments;
            case 'expenseListRecurringTransactions':
              return <Map<String, Object?>>[
                recurringRow(id: 7, isActive: true),
              ];
            case 'expenseAddRecurringTransaction':
              return recurringRow(id: 8, name: 'Telefon', amount: 7990);
            case 'expenseUpdateRecurringTransaction':
              return recurringRow(id: 7, name: 'Lakbér edit', amount: 180000);
            case 'expenseToggleRecurringTransaction':
              return recurringRow(id: 7, isActive: false);
            case 'expenseDeleteRecurringTransaction':
              return true;
            case 'expenseProcessRecurringTransactions':
              return <Map<String, Object?>>[
                transactionRow(id: 26050101, merchant: 'Lakbér'),
              ];
            case 'loadNotificationEvent':
              return pushLogEventRow(
                id: 77,
                status: 'linked',
                statusText: 'Van tranzakció',
                linkedTransactionId: 26060702,
              );
            case 'loadNotificationEventPage':
              return <String, Object?>{
                'events': <Object?>[
                  pushLogEventRow(
                    id: 77,
                    status: 'missing',
                    statusText: 'Nincs hozzárendelt log',
                  ),
                ],
                'totalCount': 8,
                'limit': 2,
                'offset': 4,
              };
            case 'markNotificationEventSystem':
              return true;
            case 'expenseGetTransaction':
              return <String, Object?>{
                'id': 26060702,
                'date': '2026.06.08',
                'time': '19:36',
                'latitude': null,
                'longitude': null,
                'address': 'Push notification',
                'merchant': 'Hitel',
                'amount': -80000.0,
                'userAssignedName': 'hitel',
                'transactionCategoryID': null,
                'recurringRuleId': 11,
                'recurringInstanceId': 22,
                'sourceNotificationEventId': 77,
              };
            case 'expenseNotificationEventIdForTransaction':
              return 77;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('updates notification settings through native bridge', () async {
    final saved = await bridge.expenseUpdateNotificationSettings(
      NotificationSettings.defaults().copyWith(androidPushEnabled: false),
    );

    expect(saved.androidPushEnabled, isFalse);
    expect(calls.single.method, 'expenseUpdateNotificationSettings');
  });

  test('loads app theme and FastInfo settings', () async {
    final settings = await bridge.expenseLoadSettings();

    expect(settings.themeSettings.magnetType, MagnetType.magnetcard);
    expect(settings.themeSettings.cardColor, AppCardColor.lightgray);
    expect(
      settings.themeSettings.buttonSurfaceStyle,
      ExpenseSurfaceInteraction.raisedInset,
    );
    expect(
      settings.themeSettings.contentSurfaceStyle,
      ExpenseSurfaceInteraction.insetInset,
    );
    expect(
      settings.themeSettings.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.insetInset,
    );
    expect(
      settings.themeSettings.ghostLogboxSettings.borderStyle,
      GhostLogboxBorderStyle.dashed,
    );
    expect(
      settings.themeSettings.ghostLogboxSettings.backgroundOpacityEnabled,
      isTrue,
    );
    expect(
      settings.themeSettings.ghostLogboxSettings.avatarOpacityEnabled,
      isFalse,
    );
    expect(
      settings.themeSettings.ghostLogboxSettings.textOpacityEnabled,
      isFalse,
    );
    expect(
      settings.themeSettings.ghostLogboxSettings.avatarBadgeEnabled,
      isTrue,
    );
    expect(
      settings.themeSettings.ghostLogboxSettings.textTone,
      GhostLogboxTextTone.normal,
    );
    expect(
      settings.themeSettings.ghostLogboxSettings.expectedLabelEnabled,
      isTrue,
    );
    expect(settings.themeSettings.backheaderStyle, BackheaderStyle.classic);
    expect(
      settings.themeSettings.categoryMenuPresentation,
      CategoryMenuPresentation.slideUpSheet,
    );
    expect(settings.themeSettings.categoryCardShadowEnabled, isFalse);
    expect(settings.themeSettings.logboxShadowEnabled, isFalse);
    expect(settings.themeSettings.headerPillShadowEnabled, isFalse);
    expect(settings.themeSettings.summaryPillShadowEnabled, isFalse);
    expect(settings.themeSettings.searchPillShadowEnabled, isFalse);
    expect(settings.fastInfoConfig.pills.first?.label, 'Megtakarítás');
    expect(settings.fastInfoConfig.pills[1]?.id, 'havi_koltes');
    expect(settings.fastInfoConfig.boxes.first, isNull);
    expect(
      settings.pushRecurringSettings.conflictPolicy,
      PushRecurringConflictPolicy.askOnMultipleMatches,
    );
    expect(settings.securitySettings.pinEnabled, isTrue);
    expect(settings.securitySettings.biometricAvailable, isTrue);
  });

  test('updates theme settings through native bridge', () async {
    final updated = await bridge.expenseUpdateThemeSettings(
      AppThemeSettings.fromMap(const <String, Object?>{
        'magnetType': 'adaptive',
        'cardColor': 'darkgray',
        'theme': 'Türkiz',
        'backgroundColor': 'white',
        'boxColor': 'gray',
        'buttonSurfaceStyle': 'raisedInset',
        'contentSurfaceStyle': 'neutralInset',
        'ghostLogboxSurfaceStyle': 'insetInset',
        'ghostLogboxSettings': <String, Object?>{
          'borderStyle': 'normal',
          'backgroundOpacityEnabled': false,
          'avatarOpacityEnabled': true,
          'textOpacityEnabled': true,
          'avatarBadgeEnabled': false,
          'textTone': 'gray',
          'expectedLabelEnabled': false,
        },
        'categoryMenuColor': 'darkgray',
        'categoryMenuSurfaceStyle': 'insetInset',
        'categoryCardColor': 'white',
        'categoryCardSurfaceStyle': 'raisedInset',
        'backheaderStyle': 'centerBadgeBudget',
        'centerBackheaderDesign': 'colored',
        'centerPartitionRingEnabled': true,
        'centerBadgeDiscEnabled': false,
        'centerBadgeBorderMode': 'always',
        'appColor': 'pink',
        'categoryMenuPresentation': 'slideUpSheet',
        'categoryCardShadowEnabled': false,
        'logboxShadowEnabled': false,
        'headerPillShadowEnabled': false,
        'summaryPillShadowEnabled': false,
        'searchPillShadowEnabled': false,
      }),
    );

    expect(updated.magnetType, MagnetType.adaptive);
    expect(
      updated.ghostLogboxSurfaceStyle,
      ExpenseSurfaceInteraction.insetInset,
    );
    expect(
      updated.ghostLogboxSettings.borderStyle,
      GhostLogboxBorderStyle.normal,
    );
    expect(updated.ghostLogboxSettings.textTone, GhostLogboxTextTone.gray);
    expect(updated.ghostLogboxSettings.expectedLabelEnabled, isFalse);
    expect(updated.centerBackheaderDesign, BackheaderCenterDesign.colored);
    expect(updated.toMap()['centerPartitionRingEnabled'], isTrue);
    expect(updated.centerBadgeDiscEnabled, isFalse);
    expect(updated.centerBadgeBorderMode, CenterBadgeBorderMode.always);
    expect(calls.single.method, 'expenseUpdateThemeSettings');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['magnetType'], 'adaptive');
    expect(payload['cardColor'], 'darkgray');
    expect(payload['buttonSurfaceStyle'], 'raisedInset');
    expect(payload['contentSurfaceStyle'], 'neutralInset');
    expect(payload['ghostLogboxSurfaceStyle'], 'insetInset');
    expect(payload['categoryMenuColor'], 'darkgray');
    expect(payload['categoryMenuSurfaceStyle'], 'insetInset');
    expect(payload['categoryCardColor'], 'white');
    expect(payload['categoryCardSurfaceStyle'], 'raisedInset');
    expect(payload['categoryMenuPresentation'], 'slideUpSheet');
    expect(payload['categoryCardShadowEnabled'], isFalse);
    expect(payload['logboxShadowEnabled'], isFalse);
    expect(payload['headerPillShadowEnabled'], isFalse);
    expect(payload['summaryPillShadowEnabled'], isFalse);
    expect(payload['searchPillShadowEnabled'], isFalse);
    expect(payload['ghostLogboxSettings'], isA<Map>());
    final ghostPayload = Map<dynamic, dynamic>.from(
      payload['ghostLogboxSettings'] as Map,
    );
    expect(ghostPayload['textTone'], 'gray');
    expect(ghostPayload['expectedLabelEnabled'], isFalse);
    expect(payload['backheaderStyle'], 'centerBadgeBudget');
    expect(payload['centerBackheaderDesign'], 'colored');
    expect(payload['centerPartitionRingEnabled'], isTrue);
    expect(payload['centerBadgeDiscEnabled'], isFalse);
    expect(payload['centerBadgeBorderMode'], 'always');
    expect(payload.containsKey('designProfile'), isFalse);
    expect(payload.containsKey('nightMode'), isFalse);
    expect(payload['appColor'], 'pink');
  });

  test(
    'backheader style defaults to classic for missing or unknown values',
    () {
      expect(
        AppThemeSettings.fromMap(const <String, Object?>{}).backheaderStyle,
        BackheaderStyle.classic,
      );
      expect(
        AppThemeSettings.fromMap(const <String, Object?>{
          'backheaderStyle': 'not-a-style',
        }).backheaderStyle,
        BackheaderStyle.classic,
      );
      expect(
        AppThemeSettings.fromMap(const <String, Object?>{
          'backheaderStyle': 'mosaicBudget',
        }).backheaderStyle,
        BackheaderStyle.classic,
      );
      expect(
        AppThemeSettings.fromMap(const <String, Object?>{
          'backheaderStyle': 'heroToken',
        }).backheaderStyle,
        BackheaderStyle.classic,
      );
      expect(
        AppThemeSettings.fromMap(const <String, Object?>{
          'backheaderStyle': 'orbitBudget',
        }).backheaderStyle,
        BackheaderStyle.classic,
      );
    },
  );

  test('updates FastInfo config through native bridge', () async {
    final config = FastInfoConfig(
      layoutMode: FastInfoLayoutMode.sixBoxes,
      pills: const [
        FastInfoSlot(
          id: 'megtakaritas',
          label: 'Megtakarítás',
          value: '156,780 Ft',
          type: FastInfoSlotType.pill,
        ),
        null,
        null,
      ],
      boxes: const [null, null, null],
    );

    final updated = await bridge.expenseUpdateFastInfoConfig(config);

    expect(updated.pills.first?.id, 'megtakaritas');
    expect(updated.layoutMode, FastInfoLayoutMode.sixBoxes);
    expect(calls.single.method, 'expenseUpdateFastInfoConfig');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['pills'], isA<List<Object?>>());
    expect(payload['layoutMode'], 'sixBoxes');
    expect(payload['upperRowPresentation'], 'box');
    expect(payload['lowerRowPresentation'], 'box');
  });

  test('updates push recurring settings through native bridge', () async {
    final updated = await bridge.expenseUpdatePushRecurringSettings(
      const PushRecurringSettings(
        conflictPolicy: PushRecurringConflictPolicy.automaticBestMatch,
      ),
    );

    expect(
      updated.conflictPolicy,
      PushRecurringConflictPolicy.automaticBestMatch,
    );
    expect(calls.single.method, 'expenseUpdatePushRecurringSettings');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['conflictPolicy'], 'automaticBestMatch');
  });

  test('updates security pin through native bridge', () async {
    final updated = await bridge.expenseSetSecurityPin('1234');

    expect(updated.pinEnabled, isTrue);
    expect(calls.single.method, 'expenseSetSecurityPin');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['pin'], '1234');
  });

  test('changes security pin through native bridge', () async {
    final updated = await bridge.expenseChangeSecurityPin(
      currentPin: '1234',
      newPin: '4567',
    );

    expect(updated.pinEnabled, isTrue);
    expect(calls.single.method, 'expenseChangeSecurityPin');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['currentPin'], '1234');
    expect(payload['newPin'], '4567');
  });

  test('clears security pin through native bridge', () async {
    final updated = await bridge.expenseClearSecurityPin('1234');

    expect(updated.pinEnabled, isFalse);
    expect(updated.biometricEnabled, isFalse);
    expect(calls.single.method, 'expenseClearSecurityPin');
  });

  test('verifies security pin through native bridge', () async {
    expect(await bridge.expenseVerifySecurityPin('1234'), isTrue);
    expect(await bridge.expenseVerifySecurityPin('0000'), isFalse);
  });

  test('updates biometric setting through native bridge', () async {
    final updated = await bridge.expenseSetBiometricEnabled(true);

    expect(updated.biometricEnabled, isTrue);
    expect(calls.single.method, 'expenseSetBiometricEnabled');
  });

  test(
    'loads biometric availability and authenticates through native bridge',
    () async {
      final availability = await bridge.expenseGetBiometricAvailability();
      final authenticated = await bridge.expenseAuthenticateBiometric();

      expect(availability.biometricAvailable, isTrue);
      expect(authenticated, isTrue);
      expect(calls.map((call) => call.method), <String>[
        'expenseGetBiometricAvailability',
        'expenseAuthenticateBiometric',
      ]);
    },
  );

  test(
    'loads and saves notification parser profiles through native bridge',
    () async {
      final config = await bridge.loadNotificationParserProfiles();

      expect(config.profiles, hasLength(2));
      expect(config.activeProfiles.single.id, 'bank-a');
      expect(config.profiles.last.preview.merchant, 'Tesco');

      final saved = await bridge.saveNotificationParserProfiles(
        config.upsert(config.profiles.last.copyWith(enabled: true)),
      );

      expect(saved.activeProfiles, hasLength(2));
      expect(calls.last.method, 'saveNotificationParserProfiles');
      final payload = calls.last.arguments as Map<dynamic, dynamic>;
      expect(payload['profiles'], isA<List<Object?>>());
    },
  );

  test(
    'loads and saves notification parser rule through native bridge',
    () async {
      final loaded = await bridge.loadNotificationParserRule();

      expect(loaded.sampleText, 'Paid 999 Ft at Corner Shop');
      expect(loaded.preview.amountValue, 999);
      expect(loaded.preview.merchant, 'Corner Shop');

      final saved = await bridge.saveNotificationParserRule(
        NotificationParserRule.defaults().copyWith(
          includeKeyword: 'vásárlás',
          amountPattern: r'(?<amount>\d+)\s*HUF',
          merchantPattern: r'bolt:\s*(?<merchant>.+)',
        ),
      );

      expect(saved.includeKeyword, 'vásárlás');
      expect(calls.last.method, 'saveNotificationParserRule');
      final payload = calls.last.arguments as Map<dynamic, dynamic>;
      expect(payload['amountPattern'], r'(?<amount>\d+)\s*HUF');
      expect(payload['merchantPattern'], r'bolt:\s*(?<merchant>.+)');
    },
  );

  test(
    'loads and saves automatic push parser toggle through native bridge',
    () async {
      final loaded = await bridge.loadAutomaticPushParserEnabled();

      expect(loaded, isTrue);

      final saved = await bridge.saveAutomaticPushParserEnabled(false);

      expect(saved, isFalse);
      expect(
        calls.map((call) => call.method),
        containsAll(<String>[
          'loadAutomaticPushParserEnabled',
          'saveAutomaticPushParserEnabled',
        ]),
      );
    },
  );

  test('opens Android notification settings through native bridge', () async {
    await bridge.openAppNotificationSettings();

    expect(calls.single.method, 'openAppNotificationSettings');
  });

  test('loads paged push notification log events', () async {
    final page = await bridge.loadNotificationEventPage(
      const PushNotificationLogQuery(
        limit: 2,
        offset: 4,
        year: 2026,
        month: 6,
        query: 'tesco',
        status: PushNotificationLogStatus.missing,
      ),
    );

    expect(page.limit, 2);
    expect(page.offset, 4);
    expect(page.totalCount, 8);
    expect(page.events.single.statusText, 'Nincs hozzárendelt log');
    expect(page.events.single.fullText, contains('Tesco'));
    expect(calls.single.method, 'loadNotificationEventPage');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['year'], 2026);
    expect(payload['month'], 6);
    expect(payload['query'], 'tesco');
    expect(payload['status'], 'missing');
  });

  test(
    'marks a push notification event as system through native bridge',
    () async {
      final updated = await bridge.markNotificationEventSystem(77);

      expect(updated, isTrue);
      expect(calls.single.method, 'markNotificationEventSystem');
      final payload = calls.single.arguments as Map<dynamic, dynamic>;
      expect(payload['id'], 77);
    },
  );

  test('loads one push notification event through native bridge', () async {
    final event = await bridge.loadNotificationEvent(77);

    expect(event, isNotNull);
    expect(event!.id, 77);
    expect(event.linkedTransactionId, 26060702);
    expect(calls.single.method, 'loadNotificationEvent');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['id'], 77);
  });

  test(
    'opens transaction and notification links through native bridge',
    () async {
      final transaction = await bridge.expenseGetTransaction(26060702);
      final eventId = await bridge.expenseNotificationEventIdForTransaction(
        26060702,
      );

      expect(transaction, isNotNull);
      expect(transaction!.id, 26060702);
      expect(transaction.sourceNotificationEventId, 77);
      expect(eventId, 77);
      expect(calls.map((call) => call.method), <String>[
        'expenseGetTransaction',
        'expenseNotificationEventIdForTransaction',
      ]);
    },
  );

  test(
    'requests post notifications once on first launch through native bridge',
    () async {
      final requested = await bridge.requestPostNotificationsOnFirstLaunch();

      expect(requested, isFalse);
      expect(calls.single.method, 'requestPostNotificationsOnFirstLaunch');
    },
  );

  test('manages recurring transactions through native bridge', () async {
    final rows = await bridge.expenseListRecurringTransactions();
    expect(rows.single.name, 'Lakbér');
    expect(rows.single.categoryId, 6);

    final created = await bridge.expenseAddRecurringTransaction(
      const RecurringTransactionDraft(
        name: 'Telefon',
        amount: 7990,
        transactionType: TransactionType.expense,
        dayOfMonth: 15,
        categoryId: 6,
      ),
    );
    expect(created.id, 8);

    final updated = await bridge.expenseUpdateRecurringTransaction(
      7,
      const RecurringTransactionDraft(
        name: 'Lakbér edit',
        amount: 180000,
        transactionType: TransactionType.expense,
        dayOfMonth: 1,
        categoryId: 6,
      ),
    );
    expect(updated.name, 'Lakbér edit');

    final toggled = await bridge.expenseToggleRecurringTransaction(7, false);
    expect(toggled.isActive, isFalse);

    final processed = await bridge.expenseProcessRecurringTransactions(
      targetDate: DateTime(2026, 5, 1),
    );
    expect(processed.single.id, 26050101);
    expect(processed.single.merchant, 'Lakbér');

    final deleted = await bridge.expenseDeleteRecurringTransaction(7);
    expect(deleted, isTrue);
  });
}

Map<String, Object?> pushLogEventRow({
  required int id,
  required String status,
  required String statusText,
  int? linkedTransactionId,
}) {
  return <String, Object?>{
    'id': id,
    'timestamp': DateTime(2026, 6, 7, 21, 10).millisecondsSinceEpoch,
    'source': 'notification_listener',
    'packageName': 'hu.bank.app',
    'appLabel': 'Bank',
    'title': 'Vásárlás',
    'text': 'Kártyás vásárlás: Tesco - 12 345 HUF',
    'bigText': '',
    'subText': '',
    'category': '',
    'notificationKey': 'n-$id',
    'accessibilityEventType': '',
    'hash': 'h-$id',
    'isDuplicate': false,
    'manualStatus': '',
    'displayText': 'Kártyás vásárlás: Tesco - 12 345 HUF',
    'status': status,
    'statusText': statusText,
    'linkedTransactionId': linkedTransactionId,
  };
}

Map<String, Object?> recurringRow({
  required int id,
  String name = 'Lakbér',
  double amount = 165000,
  bool isActive = true,
  String? lastProcessedPeriodKey,
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'amount': amount,
    'transactionType': 'expense',
    'dayOfMonth': 1,
    'categoryId': 6,
    'categoryName': 'Q',
    'categoryColor': '#dc2626',
    'categoryIconSlot': 2,
    'isActive': isActive,
    'lastProcessedPeriodKey': lastProcessedPeriodKey,
    'lastProcessedAt': lastProcessedPeriodKey == null ? null : 1777593600000,
    'createdAt': 1777593600000,
    'updatedAt': 1777593600000,
  };
}

Map<String, Object?> transactionRow({
  required int id,
  String merchant = 'Hitel',
  double amount = -80000.0,
}) {
  return <String, Object?>{
    'id': id,
    'date': '2026.05.01',
    'time': '08:00',
    'latitude': null,
    'longitude': null,
    'address': 'Recurring rule transaction',
    'merchant': merchant,
    'amount': amount,
    'userAssignedName': merchant,
    'transactionCategoryID': 6,
    'recurringRuleId': 7,
    'recurringInstanceId': 70,
    'sourceNotificationEventId': null,
  };
}
