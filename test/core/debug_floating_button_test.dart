import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/debug/debug_floating_button.dart';
import 'package:exptv2/core/theme/app_dimensions.dart';
import 'package:exptv2/services/native_ime_sheet_bridge.dart';
import 'package:exptv2/services/recurring_alarm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(DebugConsole.clear);

  testWidgets('floating button opens debug console dialog', (tester) async {
    DebugConsole.log('bootstrap finished');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
      ),
    );

    final buttonRect = tester.getRect(
      find.byKey(const ValueKey('debug-floating-button')),
    );
    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    final positioned = tester.widget<Positioned>(
      find.byKey(const ValueKey('debug-floating-button-position')),
    );
    expect(positioned.left, 16);
    expect(positioned.right, isNull);
    expect(buttonRect.left, moreOrLessEquals(16));
    expect(
      buttonRect.bottom,
      moreOrLessEquals(screenSize.height - AppDimensions.bottomNavHeight - 12),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    expect(find.text('Debug Console'), findsOneWidget);
    expect(find.textContaining('bootstrap finished'), findsOneWidget);
  });

  testWidgets('debug console can advance recurring debug date', (tester) async {
    const channel = MethodChannel('test/recurring_alarm_debug_console');
    final calls = <MethodCall>[];
    var changedCount = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'loadRecurringAlarmDebugState':
              return <String, Object?>{
                'overrideMillis': null,
                'effectiveMillis': DateTime(
                  2026,
                  5,
                  31,
                  0,
                  1,
                ).millisecondsSinceEpoch,
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
              };
            case 'scheduleRecurringDebugTestAlarm':
              return <String, Object?>{
                'overrideMillis': null,
                'effectiveMillis': DateTime(
                  2026,
                  5,
                  31,
                  0,
                  1,
                ).millisecondsSinceEpoch,
                'usingOverride': false,
                'logs': <String>['[RecurringAlarm] debug test alarm scheduled'],
              };
          }
          throw PlatformException(code: 'unexpected', message: call.method);
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DebugFloatingButton(
                recurringAlarmService: RecurringAlarmService(
                  methodChannel: channel,
                ),
                onRecurringChanged: () => changedCount += 1,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('debug-console-recurring-section')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('recurring-debug-next-day')));
    await tester.pumpAndSettle();

    expect(calls.map((call) => call.method), contains('setDebugDateOverride'));
    expect(changedCount, 1);
    expect(
      DebugConsole.entries.any((entry) => entry.contains('processed 2')),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('recurring-debug-test-alarm')));
    await tester.pumpAndSettle();

    expect(
      calls.map((call) => call.method),
      contains('scheduleRecurringDebugTestAlarm'),
    );
    expect(
      DebugConsole.entries.any(
        (entry) => entry.contains('debug test alarm scheduled'),
      ),
      isTrue,
    );
  });

  testWidgets('debug console can open native IME sheet probe', (tester) async {
    const channel = MethodChannel('test/native_ime_sheet_probe');
    final calls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DebugFloatingButton(
                nativeImeSheetBridge: NativeImeSheetBridge(
                  methodChannel: channel,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('native-ime-sheet-probe-open')));
    await tester.pumpAndSettle();

    expect(calls.map((call) => call.method), contains('openProbe'));
    expect(
      DebugConsole.entries.any(
        (entry) => entry.contains('Native IME probe open requested'),
      ),
      isTrue,
    );
  });

  testWidgets('native IME bridge handles transaction commit callback', (
    tester,
  ) async {
    const channel = MethodChannel('test/native_ime_sheet_commit');
    var commits = 0;
    final bridge = NativeImeSheetBridge(
      methodChannel: channel,
      onTransactionCommitted: () async {
        commits += 1;
      },
    );
    addTearDown(bridge.dispose);

    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'test/native_ime_sheet_commit',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('transactionCommitted'),
          ),
          (_) {},
        );
    await tester.pump();

    expect(commits, 1);
  });
}
