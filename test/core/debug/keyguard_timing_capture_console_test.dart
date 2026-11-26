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
    expect((startArguments as Map)['r43Evidence'], isFalse);
    expect(find.textContaining('REC'), findsOneWidget);
  });

  testWidgets('Android 17 evidence is explicitly armed', (tester) async {
    Object? startArguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          if (call.method == 'startKeyguardDiagnosticCapture') {
            startArguments = call.arguments;
          }
          return response('REC', 'LIVE');
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
    await tester.ensureVisible(
      find.byKey(const ValueKey('debug-console-r43-start')),
    );
    await tester.tap(find.byKey(const ValueKey('debug-console-r43-start')));
    await tester.pump();
    expect((startArguments as Map)['r43Evidence'], isTrue);
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
      await tester.ensureVisible(
        find.byKey(const ValueKey('debug-console-keyguard-copy')),
      );
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

  testWidgets('renderer choice acknowledges the next hidden boundary', (
    tester,
  ) async {
    String? sent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          if (call.method == 'getKeyguardOrbRenderMode') {
            return <String, Object?>{
              'available': true,
              'configured': 'SURFACE_LIVE',
              'effective': 'SURFACE_LIVE',
              'pendingBoundary': false,
            };
          }
          if (call.method == 'setKeyguardOrbRenderMode') {
            sent = (call.arguments as Map)['mode'] as String?;
            return <String, Object?>{
              'available': true,
              'configured': sent,
              'effective': 'SURFACE_LIVE',
              'pendingBoundary': true,
            };
          }
          return response('IDLE', '');
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
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('debug-console-orb-surface-static')),
    );
    await tester.pumpAndSettle();
    expect(sent, 'SURFACE_STATIC');
    expect(find.textContaining('következő elrejtés'), findsOneWidget);
  });

  testWidgets('one action requests an acknowledged sample capture', (
    tester,
  ) async {
    final calls = <String>[];
    var sampleEnabled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          calls.add(call.method);
          if (call.method == 'getR44SyntheticTrial') {
            return <String, Object?>{
              'available': true,
              'enabled': sampleEnabled,
            };
          }
          if (call.method == 'startR442SampleCapture') {
            sampleEnabled = true;
            return <String, Object?>{
              'active': true,
              'captureId': 'capture-test',
              'process': 'process-test',
              'serviceSession': 1,
              'materialDomain': 'fixedSample',
              'snapshot': response('REC', 'LIVE'),
            };
          }
          if (call.method == 'getR442SampleCaptureStatus') {
            return <String, Object?>{
              'active': true,
              'captureId': 'capture-test',
              'process': 'process-test',
              'serviceSession': 1,
              'materialDomain': 'fixedSample',
            };
          }
          return response('IDLE', '');
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
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('debug-console-r442-start'));
    expect(start, findsOneWidget);
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(calls, contains('startR442SampleCapture'));
    expect(calls, isNot(contains('setR44SyntheticTrial')));
    expect(find.text('Mintaorb-próba aktív'), findsOneWidget);
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('debug-console-keyguard-start')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Próba leállítása és riport megtartása'), findsOneWidget);
  });

  testWidgets('a rejected start reports its reason and never claims active', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          if (call.method == 'getR44SyntheticTrial') {
            return <String, Object?>{'available': true, 'enabled': false};
          }
          if (call.method == 'startR442SampleCapture') {
            return <String, Object?>{'active': false, 'reason': 'phoneLocked'};
          }
          if (call.method == 'getR442SampleCaptureStatus') {
            return <String, Object?>{'active': false, 'reason': 'notStarted'};
          }
          return response('IDLE', '');
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
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('debug-console-r442-start'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('Mintaorb-próba aktív'), findsNothing);
    expect(find.textContaining('telefon zárolva'), findsOneWidget);
  });

  testWidgets('a replaced native receipt cannot leave a trial active', (
    tester,
  ) async {
    var sampleEnabled = false;
    const receipt = <String, Object?>{
      'active': true,
      'captureId': 'capture-test',
      'process': 'process-test',
      'serviceSession': 1,
      'materialDomain': 'fixedSample',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          if (call.method == 'getR44SyntheticTrial') {
            return <String, Object?>{
              'available': true,
              'enabled': sampleEnabled,
            };
          }
          if (call.method == 'startR442SampleCapture') {
            sampleEnabled = true;
            return <String, Object?>{
              ...receipt,
              'snapshot': response('REC', 'LIVE'),
            };
          }
          if (call.method == 'getR442SampleCaptureStatus') {
            return <String, Object?>{...receipt, 'serviceSession': 2};
          }
          return response('IDLE', '');
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
    await tester.pumpAndSettle();
    final start = find.byKey(const ValueKey('debug-console-r442-start'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('Mintaorb-próba aktív'), findsNothing);
    expect(
      find.byKey(const ValueKey('debug-console-keyguard-error')),
      findsOneWidget,
    );
  });

  testWidgets('R44 synthetic data requires an explicit switch', (tester) async {
    final changes = <bool>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          if (call.method == 'getR44SyntheticTrial') {
            return <String, Object?>{'available': true, 'enabled': false};
          }
          if (call.method == 'setR44SyntheticTrial') {
            final enabled = (call.arguments as Map)['enabled'] as bool;
            changes.add(enabled);
            return <String, Object?>{'available': true, 'enabled': enabled};
          }
          return response('IDLE', '');
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
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    final toggle = find.byKey(const ValueKey('debug-console-r44-synthetic'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(find.textContaining('csak mintaadat'), findsOneWidget);
  });
}
