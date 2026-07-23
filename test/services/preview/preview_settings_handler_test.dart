import 'package:exptv2/services/preview/preview_native_state.dart';
import 'package:exptv2/services/preview/preview_settings_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PreviewNativeState state;
  late PreviewSettingsHandler handler;

  setUp(() {
    state = PreviewNativeState.seeded(now: DateTime(2026, 7, 18));
    handler = PreviewSettingsHandler(state);
  });

  tearDown(() => state.dispose());

  test('loads and updates all mutable settings maps', () async {
    final loaded =
        await handler.invoke('expenseLoadSettings', null)
            as Map<String, Object?>;
    expect(
      loaded.keys,
      containsAll(<String>[
        'themeSettings',
        'fastInfoConfig',
        'pushRecurringSettings',
        'notificationSettings',
        'securitySettings',
      ]),
    );

    final theme =
        await handler.invoke('expenseUpdateThemeSettings', <String, Object?>{
              'theme': 'Türkiz',
              'dashboardDesignMode': 'classic',
            })
            as Map<String, Object?>;
    expect(theme['theme'], 'Türkiz');
    expect(state.themeSettings['theme'], 'Türkiz');

    await handler.invoke('expenseUpdateFastInfoConfig', <String, Object?>{
      ...state.fastInfoConfig,
      'enabled': false,
    });
    expect(state.fastInfoConfig['enabled'], isFalse);

    await handler.invoke(
      'expenseUpdatePushRecurringSettings',
      <String, Object?>{'conflictPolicy': 'askOnMultipleMatches'},
    );
    expect(
      state.pushRecurringSettings['conflictPolicy'],
      'askOnMultipleMatches',
    );

    await handler.invoke('expenseUpdateNotificationSettings', <String, Object?>{
      'androidPushEnabled': false,
    });
    expect(state.notificationSettings['androidPushEnabled'], isFalse);
  });

  test(
    'parser profiles and flat rule round-trip through shared state',
    () async {
      final config = <String, Object?>{
        'profiles': <Map<String, Object?>>[
          <String, Object?>{
            'id': 'design-bank',
            'name': 'Design Bank',
            'enabled': true,
            'appFilterText': 'Bank',
            'packageName': 'preview.bank',
            'appLabel': 'Bank',
            'sampleText': 'Design Coffee 1 890 Ft',
            'includeKeyword': 'Coffee',
            'amountPattern': r'(?<amount>\d+)',
            'merchantPattern': r'(?<merchant>Design Coffee)',
            'amountSelection': '1 890 Ft',
            'merchantSelection': 'Design Coffee',
            'transactionType': 'expense',
          },
        ],
      };
      final saved =
          await handler.invoke('saveNotificationParserProfiles', config)
              as Map<String, Object?>;
      expect(
        (saved['profiles'] as List).single,
        containsPair('id', 'design-bank'),
      );

      final loaded =
          await handler.invoke('loadNotificationParserProfiles', null)
              as Map<String, Object?>;
      expect(loaded, saved);

      final rule =
          await handler.invoke('saveNotificationParserRule', <String, Object?>{
                'enabled': true,
                'sampleText': 'Updated sample',
                'includeKeyword': 'Updated',
                'amountPattern': '',
                'merchantPattern': '',
                'amountSelection': '',
                'merchantSelection': '',
                'transactionType': 'expense',
              })
              as Map<String, Object?>;
      expect(rule['sampleText'], 'Updated sample');
      expect(
        await handler.invoke('saveAutomaticPushParserEnabled', false),
        isFalse,
      );
      expect(
        await handler.invoke('loadAutomaticPushParserEnabled', null),
        isFalse,
      );
    },
  );

  test('export is memory-backed and installed apps stay unavailable', () async {
    expect(await handler.invoke('listInstalledApps', null), isEmpty);

    final uri = await handler.invoke('expenseSaveTextFile', <String, Object?>{
      'fileName': 'design preview.csv',
      'mimeType': 'text/csv',
      'content': 'amount,merchant\n1890,Design Coffee',
    });
    expect(uri, 'memory://design%20preview.csv');
    expect(state.lastExportFileName, 'design preview.csv');

    expect(
      await handler.invoke('expenseShareTextFile', <String, Object?>{
        'fileName': 'preview.txt',
        'mimeType': 'text/plain',
        'content': 'preview',
      }),
      isNull,
    );
    expect(state.lastExportContent, 'preview');
  });

  test('all security methods remain disabled', () async {
    const disabled = <String, Object?>{
      'pinEnabled': false,
      'biometricEnabled': false,
      'biometricAvailable': false,
      'biometricLabel': 'Nem elerheto',
    };

    for (final method in <String>[
      'expenseSetSecurityPin',
      'expenseChangeSecurityPin',
      'expenseClearSecurityPin',
      'expenseSetBiometricEnabled',
      'expenseGetBiometricAvailability',
    ]) {
      expect(await handler.invoke(method, <String, Object?>{}), disabled);
    }
    expect(
      await handler.invoke('expenseVerifySecurityPin', {'pin': '1234'}),
      isFalse,
    );
    expect(await handler.invoke('expenseAuthenticateBiometric', null), isFalse);
  });
}
