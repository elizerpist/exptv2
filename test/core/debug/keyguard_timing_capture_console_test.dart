import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/debug/debug_console.dart';
import 'package:fluvi/core/diagnostics/keyguard_timing_capture_bridge.dart';

void main() {
  const runtime = MethodChannel('com.fluvi/runtime_monitoring');

  Map<String, Object?> response(String state, String report) =>
      <String, Object?>{
        'available': true,
        'captureState': state,
        'captureId': 'capture-test',
        'attemptCount': 3,
        'eventsRecorded': 12,
        'eventsRetained': 12,
        'eventsEvicted': 0,
        'eventsCoalesced': 0,
        'report': report,
      };

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, null);
  });

  testWidgets('keyguard tab controls only the native timing capture', (
    tester,
  ) async {
    final calls = <String>[];
    Object? startArguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          calls.add(call.method);
          if (call.method == 'startKeyguardDiagnosticCapture') {
            startArguments = call.arguments;
          }
          return switch (call.method) {
            'startKeyguardDiagnosticCapture' => response('REC', 'LIVE'),
            'freezeKeyguardDiagnosticCapture' => response(
              'FROZEN',
              'FLUVI_KEYGUARD_TIMING_CAPTURE_V1\nEND_FLUVI_KEYGUARD_TIMING_CAPTURE_V1',
            ),
            _ => response('FROZEN', 'FROZEN REPORT'),
          };
        });
    final bridge = KeyguardTimingCaptureBridge(
      channel: runtime,
      isAndroid: () => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DebugConsoleDialog(keyguardTimingCapture: bridge)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-console-keyguard-tab')));
    await tester.pump();
    expect(calls, contains('getKeyguardDiagnosticCapture'));
    expect(
      find.byKey(const ValueKey('debug-console-keyguard-help')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('debug-console-keyguard-start')),
    );
    await tester.pump();
    expect(calls, contains('startKeyguardDiagnosticCapture'));
    expect((startArguments as Map)['captureMode'], 'LIGHT');
    expect(find.textContaining('REC'), findsOneWidget);
  });

  testWidgets(
    'copy freezes a running capture before placing native report on clipboard',
    (tester) async {
      final calls = <String>[];
      String? clipboard;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(runtime, (call) async {
            calls.add(call.method);
            return switch (call.method) {
              'getKeyguardDiagnosticCapture' => response('REC', 'LIVE'),
              'freezeKeyguardDiagnosticCapture' => response(
                'FROZEN',
                'FLUVI_KEYGUARD_TIMING_CAPTURE_V1\nEND_FLUVI_KEYGUARD_TIMING_CAPTURE_V1',
              ),
              _ => response('FROZEN', 'REPORT'),
            };
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard =
                  (call.arguments as Map<Object?, Object?>)['text'] as String?;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final bridge = KeyguardTimingCaptureBridge(
        channel: runtime,
        isAndroid: () => true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleDialog(keyguardTimingCapture: bridge),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('debug-console-keyguard-tab')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('debug-console-keyguard-copy')),
      );
      await tester.pump();

      expect(
        calls,
        containsAllInOrder(<String>[
          'getKeyguardDiagnosticCapture',
          'freezeKeyguardDiagnosticCapture',
        ]),
      );
      expect(clipboard, startsWith('FLUVI_KEYGUARD_TIMING_CAPTURE_V1'));
    },
  );
}
