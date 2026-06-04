import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:exptv2/features/settings/models/notification_parser_rule.dart';
import 'package:exptv2/features/settings/models/recurring_transaction.dart';
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
              };
            case 'expenseUpdateThemeSettings':
              return call.arguments;
            case 'expenseUpdateFastInfoConfig':
              return call.arguments;
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
                recurringRow(id: 7, lastProcessedPeriodKey: '2026-05'),
              ];
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads app theme and FastInfo settings', () async {
    final settings = await bridge.expenseLoadSettings();

    expect(settings.themeSettings.magnetType, MagnetType.magnetcard);
    expect(settings.themeSettings.cardColor, AppCardColor.lightgray);
    expect(settings.themeSettings.backheaderStyle, BackheaderStyle.heroToken);
    expect(settings.fastInfoConfig.pills.first?.label, 'Megtakarítás');
    expect(settings.fastInfoConfig.pills[1]?.id, 'havi_koltes');
    expect(settings.fastInfoConfig.boxes.first, isNull);
  });

  test('updates theme settings through native bridge', () async {
    final updated = await bridge.expenseUpdateThemeSettings(
      const AppThemeSettings(
        magnetType: MagnetType.adaptive,
        cardColor: AppCardColor.darkgray,
        theme: AppTheme.turquoise,
        backgroundColor: AppBackgroundColor.white,
        boxColor: AppBoxColor.gray,
        backheaderStyle: BackheaderStyle.orbitBudget,
      ),
    );

    expect(updated.magnetType, MagnetType.adaptive);
    expect(calls.single.method, 'expenseUpdateThemeSettings');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['magnetType'], 'adaptive');
    expect(payload['cardColor'], 'darkgray');
    expect(payload['backheaderStyle'], 'orbitBudget');
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
    },
  );

  test('updates FastInfo config through native bridge', () async {
    final config = FastInfoConfig(
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
    expect(calls.single.method, 'expenseUpdateFastInfoConfig');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['pills'], isA<List<Object?>>());
  });

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

  test('opens Android notification settings through native bridge', () async {
    await bridge.openAppNotificationSettings();

    expect(calls.single.method, 'openAppNotificationSettings');
  });

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
    expect(processed.single.lastProcessedPeriodKey, '2026-05');

    final deleted = await bridge.expenseDeleteRecurringTransaction(7);
    expect(deleted, isTrue);
  });
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
