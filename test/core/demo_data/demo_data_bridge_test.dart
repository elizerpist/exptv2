import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/demo_data/demo_data_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.fluvi/demo_data');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('decodes the deterministic seed report without UI-owned data', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return <String, Object?>{
        'seedVersion': 1,
        'prngSeed': 20260107,
        'createdCategoryCount': 10,
        'createdPartnerCount': 27,
        'createdEntryCount': 700,
        'earliestEntryAtUtcMs': 1767222000000,
        'latestEntryAtUtcMs': 1782777600000,
        'alreadySeeded': false,
        'durationMs': 42,
        'monthlyReports': <Object?>[
          <String, Object?>{
            'year': 2026,
            'month': 7,
            'entryCount': 100,
            'incomeCount': 6,
            'expenseCount': 94,
            'incomeTargetMinor': 70700000,
            'expenseTargetMinor': 68900000,
            'incomeTotalMinor': 70700000,
            'expenseTotalMinor': 68900000,
          },
        ],
      };
    });

    final report = await const MethodChannelDemoDataBridge(
      channel: channel,
    ).seedDemoDataset();

    expect(received?.method, 'seedDemoDataset');
    expect(received?.arguments, <String, Object?>{'forceReset': false});
    expect(report.seedVersion, 1);
    expect(report.createdEntryCount, 700);
    expect(report.monthlyReports.single.expenseTotalMinor, 68900000);
  });
}
