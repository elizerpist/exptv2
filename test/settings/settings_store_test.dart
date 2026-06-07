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
                'securitySettings': <String, Object?>{
                  'pinEnabled': false,
                  'biometricEnabled': false,
                  'biometricAvailable': true,
                  'biometricLabel': 'Ujjlenyomat elerheto',
                },
              };
            case 'expenseListCategories':
              return <Map<String, Object?>>[categoryRow()];
            case 'expenseListRecurringTransactions':
              return <Map<String, Object?>>[];
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
              return (call.arguments as Map<dynamic, dynamic>)['pin'] ==
                  '1234';
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
                'pinEnabled': store.securitySettings.pinEnabled,
                'biometricEnabled': store.securitySettings.biometricEnabled,
                'biometricAvailable': true,
                'biometricLabel': 'Ujjlenyomat elerheto',
              };
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

  test('loads security settings', () async {
    await store.start();

    expect(store.securitySettings.pinEnabled, isFalse);
    expect(store.securitySettings.biometricAvailable, isTrue);
  });

  test('updates pin and biometric settings', () async {
    await store.start();

    await store.setSecurityPin('1234');
    expect(store.securitySettings.pinEnabled, isTrue);

    expect(await store.verifySecurityPin('1234'), isTrue);
    expect(await store.verifySecurityPin('0000'), isFalse);

    await store.setBiometricEnabled(true);
    expect(store.securitySettings.biometricEnabled, isTrue);

    await store.clearSecurityPin('1234');
    expect(store.securitySettings.pinEnabled, isFalse);
    expect(store.securitySettings.biometricEnabled, isFalse);

    expect(methods, contains('expenseSetSecurityPin'));
    expect(methods, contains('expenseVerifySecurityPin'));
    expect(methods, contains('expenseSetBiometricEnabled'));
    expect(methods, contains('expenseClearSecurityPin'));
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
