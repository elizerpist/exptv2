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
                },
                'fastInfoConfig': <String, Object?>{
                  'pills': <Object?>[
                    <String, Object?>{
                      'id': 'megtakaritas',
                      'label': 'Megtakarítás',
                      'value': '156,780 Ft',
                      'type': 'pill',
                    },
                    null,
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
    expect(settings.fastInfoConfig.pills.first?.label, 'Megtakarítás');
    expect(settings.fastInfoConfig.boxes.first?.extra, '-4,500 Ft');
  });

  test('updates theme settings through native bridge', () async {
    final updated = await bridge.expenseUpdateThemeSettings(
      const AppThemeSettings(
        magnetType: MagnetType.adaptive,
        cardColor: AppCardColor.darkgray,
        theme: AppTheme.turquoise,
        backgroundColor: AppBackgroundColor.white,
        boxColor: AppBoxColor.gray,
      ),
    );

    expect(updated.magnetType, MagnetType.adaptive);
    expect(calls.single.method, 'expenseUpdateThemeSettings');
    final payload = calls.single.arguments as Map<dynamic, dynamic>;
    expect(payload['magnetType'], 'adaptive');
    expect(payload['cardColor'], 'darkgray');
  });

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
