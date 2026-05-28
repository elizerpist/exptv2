import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/settings/data/settings_repository.dart';
import 'package:exptv2/features/settings/state/settings_store.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/settings_store_methods');
  late SettingsStore store;

  setUp(() {
    DebugConsole.clear();
    final bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/settings_store_events'),
    );
    store = SettingsStore(SettingsRepository(bridge));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'expenseLoadSettings':
              return <String, Object?>{};
            case 'expenseListRecurringTransactions':
              return <Map<String, Object?>>[recurringRow(isActive: true)];
            case 'expenseListCategories':
              return <Map<String, Object?>>[categoryRow()];
            case 'expenseAddRecurringTransaction':
              return recurringRow(id: 8, name: 'Telefon');
            case 'expenseUpdateRecurringTransaction':
              return recurringRow(id: 7, name: 'Lakbér edit');
            case 'expenseToggleRecurringTransaction':
              return recurringRow(isActive: false);
            case 'expenseDeleteRecurringTransaction':
              return true;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('logs recurring transaction lifecycle actions', () async {
    await store.start();
    await store.saveRecurringTransaction(
      name: 'Telefon',
      amount: 7990,
      dayOfMonth: 15,
      categoryId: 6,
    );
    await store.toggleRecurringTransaction(store.recurringTransactions.single);
    await store.deleteRecurringTransaction(store.recurringTransactions.single);

    expect(
      DebugConsole.entries.any(
        (entry) =>
            entry.contains('[Recurring] save Telefon day=15 amount=7990'),
      ),
      isTrue,
    );
    expect(
      DebugConsole.entries.any(
        (entry) => entry.contains('[Recurring] toggle 7 active=false'),
      ),
      isTrue,
    );
    expect(
      DebugConsole.entries.any(
        (entry) => entry.contains('[Recurring] delete 7'),
      ),
      isTrue,
    );
  });
}

Map<String, Object?> recurringRow({
  int id = 7,
  String name = 'Lakbér',
  bool isActive = true,
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'amount': 165000,
    'transactionType': 'expense',
    'dayOfMonth': 1,
    'categoryId': 6,
    'categoryName': 'Q',
    'categoryColor': '#dc2626',
    'categoryIconSlot': 2,
    'isActive': isActive,
    'lastProcessedPeriodKey': null,
    'lastProcessedAt': null,
    'createdAt': 1777593600000,
    'updatedAt': 1777593600000,
  };
}

Map<String, Object?> categoryRow() {
  return <String, Object?>{
    'transactionCategoryID': 6,
    'name': 'Q',
    'type': 'kiadás',
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#dc2626',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  };
}
