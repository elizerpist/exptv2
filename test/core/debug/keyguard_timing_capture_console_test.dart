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
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
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
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
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

  testWidgets('explicit sample CTA confirms the selected native route', (
    tester,
  ) async {
    var enabled = false;
    final calls = <MethodCall>[];
    final receipt = <String, Object?>{
      'active': true,
      'captureId': 'capture-test',
      'process': 'process-test',
      'serviceSession': 1,
      'materialDomain': 'fixedSample',
      'profile': 'STANDARD',
      'profileRevision': 9,
      'actualFlags': 0,
      'includeNotImportant': false,
      'printArmed': true,
      'printPurpose': 'fixedSampleOneWake',
      'routeConfirmed': 'WIDGETS_ANYWHERE',
      'routeRequested': 'WIDGETS_ANYWHERE',
      'actionKind': 'ONE_WAKE',
      'sampleShape': 'ORB',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getR448DisplayRoute' => <String, Object?>{
              'available': true,
              'connected': true,
              'configured': 'WIDGETS_ANYWHERE',
              'active': 'NONE',
              'reason': 'PUBLIC_SAMPLE_ONLY',
              'sampleOnly': true,
            },
            'getR44SyntheticTrial' => <String, Object?>{
              'available': true,
              'enabled': enabled,
            },
            'startR449SampleCapture' => () {
              enabled = true;
              receipt['sampleShape'] =
                  (call.arguments as Map)['diagnosticCircle'] == true
                  ? 'CIRCLE'
                  : 'ORB';
              return <String, Object?>{
                ...receipt,
                'snapshot': response('REC', 'LIVE'),
              };
            }(),
            'getR442SampleCaptureStatus' =>
              enabled ? receipt : <String, Object?>{'active': false},
            _ => response('IDLE', ''),
          };
        });
    final bridge = KeyguardTimingCaptureBridge(
      channel: runtime,
      isAndroid: () => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('debug-console-keyguard-tab')));
    await tester.pumpAndSettle();
    final circle = find.byKey(const ValueKey('debug-console-r45-circle'));
    await tester.ensureVisible(circle);
    expect(tester.widget<SwitchListTile>(circle).value, isFalse);
    await tester.tap(circle);
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('debug-console-r449-one-wake'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    final request = calls.singleWhere(
      (call) => call.method == 'startR449SampleCapture',
    );
    expect((request.arguments as Map)['routeRequested'], 'WIDGETS_ANYWHERE');
    expect((request.arguments as Map)['actionKind'], 'ONE_WAKE');
    expect((request.arguments as Map)['diagnosticCircle'], isTrue);
    expect(find.text('Egyszeri rajzpróba előkészítve.'), findsOneWidget);
    expect(find.text('Natív minta: tömör kör'), findsOneWidget);
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
            body: DebugConsoleDialog(
              legacyKeyguardControls: true,
              keyguardTimingCapture: bridge,
            ),
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
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
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

  testWidgets(
    'display route control shows native selection and active backend',
    (tester) async {
      String configured = 'FLUVI_STREAM';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(runtime, (call) async {
            if (call.method == 'getR448DisplayRoute' ||
                call.method == 'setR448DisplayRoute') {
              if (call.method == 'setR448DisplayRoute') {
                configured = (call.arguments as Map)['route'] as String;
              }
              return <String, Object?>{
                'available': true,
                'connected': true,
                'configured': configured,
                'active': 'NONE',
                'sampleOnly': true,
                'reason': configured == 'WIDGETS_ANYWHERE'
                    ? 'PUBLIC_SAMPLE_ONLY'
                    : 'NONE',
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
          home: Scaffold(
            body: DebugConsoleDialog(
              legacyKeyguardControls: true,
              keyguardTimingCapture: bridge,
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('debug-console-keyguard-tab')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Orb megjelenítési útvonala'), findsOneWidget);
      expect(find.textContaining('csak a fix mintaorbot'), findsOneWidget);
      final route = find.byKey(
        const ValueKey('debug-console-route-WIDGETS_ANYWHERE'),
      );
      await tester.ensureVisible(route);
      await tester.tap(route);
      await tester.pumpAndSettle();
      expect(configured, 'WIDGETS_ANYWHERE');
      expect(find.textContaining('Aktív: NONE'), findsOneWidget);
      expect(find.textContaining('PUBLIC_SAMPLE_ONLY'), findsOneWidget);
    },
  );

  testWidgets('copies the two native frozen route summaries together', (
    tester,
  ) async {
    String? clipboard;
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          if (call.method == 'getR448Comparison') {
            return <String, Object?>{
              'report': 'FLUVI_STREAM\ncapture=a\nWIDGETS_ANYWHERE\ncapture=b',
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
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('debug-console-keyguard-tab')));
    await tester.pumpAndSettle();
    final copy = find.byKey(const ValueKey('debug-console-r448-comparison'));
    await tester.ensureVisible(copy);
    await tester.tap(copy);
    await tester.pumpAndSettle();
    expect(clipboard, contains('capture=a'));
    expect(clipboard, contains('capture=b'));
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
              'profile': 'STANDARD',
              'profileRevision': 9,
              'actualFlags': 0,
              'includeNotImportant': false,
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
              'profile': 'STANDARD',
              'profileRevision': 9,
              'actualFlags': 0,
              'includeNotImportant': false,
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
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
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

  testWidgets('one wake print requires its own native acknowledgement', (
    tester,
  ) async {
    var enabled = false;
    final calls = <String>[];
    final receipt = <String, Object?>{
      'active': true,
      'captureId': 'capture-test',
      'process': 'process-test',
      'serviceSession': 1,
      'materialDomain': 'fixedSample',
      'profile': 'STANDARD',
      'profileRevision': 9,
      'actualFlags': 0,
      'includeNotImportant': false,
      'printArmed': true,
      'printPurpose': 'fixedSampleOneWake',
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          calls.add(call.method);
          if (call.method == 'getR44SyntheticTrial') {
            return <String, Object?>{'available': true, 'enabled': enabled};
          }
          if (call.method == 'startR446PrintCapture') {
            enabled = true;
            return <String, Object?>{
              ...receipt,
              'snapshot': response('REC', 'LIVE'),
            };
          }
          if (call.method == 'getR442SampleCaptureStatus') return receipt;
          return response('IDLE', '');
        });
    final bridge = KeyguardTimingCaptureBridge(
      channel: runtime,
      isAndroid: () => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('debug-console-keyguard-tab')));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('debug-console-r446-print'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls, contains('startR446PrintCapture'));
    expect(calls, isNot(contains('startR442SampleCapture')));
    expect(find.text('Egyszeri rajzpróba előkészítve.'), findsOneWidget);
  });

  testWidgets('a separate expanded sample start records its actual profile', (
    tester,
  ) async {
    var enabled = false;
    Object? selected;
    final receipt = <String, Object?>{
      'active': true,
      'captureId': 'capture-test',
      'process': 'process-test',
      'serviceSession': 1,
      'materialDomain': 'fixedSample',
      'profile': 'EXPANDED',
      'profileRevision': 10,
      'actualFlags': 2,
      'includeNotImportant': true,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          if (call.method == 'getR44SyntheticTrial') {
            return <String, Object?>{'available': true, 'enabled': enabled};
          }
          if (call.method == 'startR442SampleCapture') {
            enabled = true;
            selected = (call.arguments as Map)['expanded'];
            return <String, Object?>{
              ...receipt,
              'snapshot': response('REC', 'LIVE'),
            };
          }
          if (call.method == 'getR442SampleCaptureStatus') return receipt;
          return response('IDLE', '');
        });
    final bridge = KeyguardTimingCaptureBridge(
      channel: runtime,
      isAndroid: () => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('debug-console-keyguard-tab')));
    await tester.pumpAndSettle();
    final expanded = find.byKey(const ValueKey('debug-console-r444-expanded'));
    await tester.ensureVisible(expanded);
    await tester.tap(expanded);
    await tester.pumpAndSettle();
    expect(selected, true);
    expect(find.text('Kibővített nézetprofil visszaigazolva.'), findsOneWidget);
  });

  testWidgets('stop remains available for a trial without an open capture', (
    tester,
  ) async {
    var freezeCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(runtime, (call) async {
          if (call.method == 'getR44SyntheticTrial') {
            return <String, Object?>{'available': true, 'enabled': false};
          }
          if (call.method == 'getR442SampleCaptureStatus') {
            return <String, Object?>{'active': false};
          }
          if (call.method == 'freezeKeyguardDiagnosticCapture') freezeCalls++;
          return response('IDLE', '');
        });
    final bridge = KeyguardTimingCaptureBridge(
      channel: runtime,
      isAndroid: () => true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('debug-console-keyguard-tab')));
    await tester.pumpAndSettle();
    final stop = find.byKey(const ValueKey('debug-console-keyguard-freeze'));
    await tester.ensureVisible(stop);
    await tester.tap(stop);
    await tester.pumpAndSettle();
    expect(freezeCalls, 1);
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
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
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
      'profile': 'EXPANDED',
      'profileRevision': 9,
      'actualFlags': 2,
      'includeNotImportant': true,
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
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
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
        home: Scaffold(
          body: DebugConsoleDialog(
            legacyKeyguardControls: true,
            keyguardTimingCapture: bridge,
          ),
        ),
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
