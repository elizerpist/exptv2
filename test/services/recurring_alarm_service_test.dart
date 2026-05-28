import 'package:exptv2/services/recurring_alarm_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/recurring_alarm');
  late RecurringAlarmService service;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    service = RecurringAlarmService(methodChannel: channel);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'loadRecurringAlarmDebugState':
              return <String, Object?>{
                'overrideMillis': null,
                'effectiveMillis': DateTime(2026, 6, 1, 0, 1)
                    .millisecondsSinceEpoch,
                'usingOverride': false,
                'logs': <String>['[RecurringAlarm] sync start'],
              };
            case 'setDebugDateOverride':
              final args = call.arguments as Map<dynamic, dynamic>;
              return <String, Object?>{
                'state': <String, Object?>{
                  'overrideMillis': args['targetMillis'] as int,
                  'effectiveMillis': args['targetMillis'] as int,
                  'usingOverride': true,
                  'logs': <String>['[RecurringAlarm] debug override set'],
                },
                'processedCount': 2,
                'processed': <Map<String, Object?>>[
                  <String, Object?>{'recurringId': 9},
                ],
              };
            case 'processRecurringNow':
              return <String, Object?>{
                'state': <String, Object?>{
                  'overrideMillis': null,
                  'effectiveMillis': DateTime(2026, 6, 1, 0, 1)
                      .millisecondsSinceEpoch,
                  'usingOverride': false,
                  'logs': <String>[],
                },
                'processedCount': 1,
              };
            case 'clearDebugDateOverride':
              return <String, Object?>{
                'overrideMillis': null,
                'effectiveMillis': DateTime(2026, 6, 1).millisecondsSinceEpoch,
                'usingOverride': false,
                'logs': <String>[],
              };
            case 'scheduleRecurringDebugTestAlarm':
              return <String, Object?>{
                'overrideMillis': null,
                'effectiveMillis': DateTime(2026, 6, 1).millisecondsSinceEpoch,
                'usingOverride': false,
                'logs': <String>['[RecurringAlarm] debug test alarm scheduled'],
              };
            case 'syncRecurringAlarms':
            case 'clearRecurringAlarmDebugLog':
              return true;
          }
          throw PlatformException(code: 'unexpected', message: call.method);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('loads recurring alarm debug state from the native channel', () async {
    final state = await service.loadDebugState();

    expect(calls.single.method, 'loadRecurringAlarmDebugState');
    expect(state.usingOverride, isFalse);
    expect(state.effectiveDate, DateTime(2026, 6, 1, 0, 1));
    expect(state.logs.single, contains('sync start'));
  });

  test('sets debug date override with normalized day payload', () async {
    final result = await service.setDebugDateOverride(
      DateTime(2026, 6, 1, 18, 30),
    );

    expect(calls.single.method, 'setDebugDateOverride');
    expect(
      (calls.single.arguments as Map<dynamic, dynamic>)['targetMillis'],
      DateTime(2026, 6, 1).millisecondsSinceEpoch,
    );
    expect(result.processedCount, 2);
    expect(result.state.usingOverride, isTrue);
    expect(result.processed.single['recurringId'], 9);
  });

  test('processes recurring transactions on demand', () async {
    final result = await service.processRecurringNow(
      targetDate: DateTime(2026, 6, 2),
    );

    expect(calls.single.method, 'processRecurringNow');
    expect(
      (calls.single.arguments as Map<dynamic, dynamic>)['targetMillis'],
      DateTime(2026, 6, 2).millisecondsSinceEpoch,
    );
    expect(result.processedCount, 1);
  });

  test('clears debug date override', () async {
    final state = await service.clearDebugDateOverride();

    expect(calls.single.method, 'clearDebugDateOverride');
    expect(state.usingOverride, isFalse);
    expect(state.overrideDate, isNull);
    expect(state.effectiveDate, DateTime(2026, 6, 1));
  });

  test('schedules background debug test alarm', () async {
    final state = await service.scheduleDebugTestAlarm(
      delay: const Duration(minutes: 3),
    );

    expect(calls.single.method, 'scheduleRecurringDebugTestAlarm');
    expect(
      (calls.single.arguments as Map<dynamic, dynamic>)['delayMillis'],
      180000,
    );
    expect(state.logs.single, contains('debug test alarm scheduled'));
  });

  test('sync and native log clear return success flags', () async {
    expect(await service.syncRecurringAlarms(), isTrue);
    expect(await service.clearDebugLog(), isTrue);

    expect(calls.map((call) => call.method), <String>[
      'syncRecurringAlarms',
      'clearRecurringAlarmDebugLog',
    ]);
  });
}
