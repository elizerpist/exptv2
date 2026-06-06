import 'package:exptv2/features/settings/data/settings_repository.dart';
import 'package:exptv2/features/settings/state/settings_store.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/settings_store_methods');
  late SettingsStore store;
  late List<String> methods;

  setUp(() {
    methods = <String>[];
    final bridge = NativeBridge(
      methodChannel: channel,
      eventChannel: const EventChannel('test/settings_store_events'),
    );
    store = SettingsStore(SettingsRepository(bridge));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          methods.add(call.method);
          switch (call.method) {
            case 'expenseLoadSettings':
              return <String, Object?>{
                'themeSettings': <String, Object?>{},
                'fastInfoConfig': <String, Object?>{},
                'pushRecurringSettings': <String, Object?>{},
              };
            case 'expenseListCategories':
              return <Map<String, Object?>>[categoryRow()];
            case 'expenseListRecurringTransactions':
              return <Map<String, Object?>>[];
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads settings without legacy recurring bootstrap', () async {
    await store.start();

    expect(store.error, isNull);
    expect(store.categories.single.name, 'Q');
    expect(store.expenseCategories.single.name, 'Q');
    expect(methods, contains('expenseLoadSettings'));
    expect(methods, contains('expenseListCategories'));
    expect(methods, isNot(contains('expenseListRecurringTransactions')));
  });
}

Map<String, Object?> categoryRow({
  int id = 6,
  String name = 'Q',
  String type = 'kiadás',
}) {
  return <String, Object?>{
    'transactionCategoryID': id,
    'name': name,
    'type': type,
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#dc2626',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  };
}
