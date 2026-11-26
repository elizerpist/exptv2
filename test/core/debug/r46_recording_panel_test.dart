import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/debug/debug_console.dart';
import 'package:fluvi/core/diagnostics/keyguard_timing_capture_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const runtime = MethodChannel('com.fluvi/runtime_monitoring');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(runtime, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('owner entry has only the two routes and one recording action', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(runtime, (call) async {
      if (call.method == 'getR448DisplayRoute') {
        return {
          'available': true,
          'connected': true,
          'configured': 'FLUVI_STREAM',
          'active': 'NONE',
        };
      }
      return {
        'available': true,
        'captureState': 'IDLE',
        'captureId': '',
        'active': false,
      };
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebugConsoleDialog(
            keyguardTimingCapture: KeyguardTimingCaptureBridge(
              channel: runtime,
              isAndroid: () => true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('debug-console-keyguard-tab')));
    await tester.pumpAndSettle();

    expect(find.text('Zárképernyő mérése'), findsOneWidget);
    expect(find.text('Fluvi'), findsOneWidget);
    expect(find.text('Widgets Anywhere'), findsOneWidget);
    expect(find.text('Felvétel indítása'), findsOneWidget);
    expect(find.byKey(const ValueKey('debug-console-mark-bug')), findsNothing);
    expect(find.byKey(const ValueKey('debug-console-logs-tab')), findsNothing);
    expect(find.text('LIGHT'), findsNothing);
    expect(find.text('FULL'), findsNothing);
  });

  for (final route in KeyguardDisplayRoute.values) {
    testWidgets(
      'one start and one stop copy the selected ${route.wireValue} report',
      (tester) async {
        var configured = 'FLUVI_STREAM';
        var state = 'READY';
        String? clipboard;
        final calls = <MethodCall>[];
        const id = 'r46-capture-test';
        final report =
            'FLUVI_R46_RECORDING_V1\ncaptureId=$id route=${route.wireValue}\n'
            '${List.filled(18000, 'ár').join()}\nEND_FLUVI_R46_RECORDING_V1\n';
        messenger.setMockMethodCallHandler(runtime, (call) async {
          calls.add(call);
          final args = call.arguments as Map<Object?, Object?>?;
          switch (call.method) {
            case 'getR46Recording':
              return {
                'state': state,
                'captureId': state == 'READY' ? null : id,
              };
            case 'getR448DisplayRoute':
            case 'setR448DisplayRoute':
              configured = args?['route'] as String? ?? configured;
              return {
                'available': true,
                'connected': true,
                'configured': configured,
                'active': 'NONE',
              };
            case 'startR46Recording':
              expect(args?['route'], route.wireValue);
              state = 'RECORDING';
              return {
                'active': true,
                'captureId': id,
                'printArmed': true,
                'routeConfirmed': configured,
                'sampleShape': 'ORB',
                'actionKind': 'SESSION',
                'policy': 'R46_ALL',
              };
            case 'stopR46Recording':
              expect(args?['captureId'], id);
              state = 'SEALED';
              return {'captureId': id, 'report': report};
            case 'markR46Copied':
              state = 'COPIED';
              return {'captureId': id, 'state': state};
            default:
              return <String, Object?>{};
          }
        });
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          return null;
        });
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DebugConsoleDialog(
                initialKeyguard: true,
                keyguardTimingCapture: KeyguardTimingCaptureBridge(
                  channel: runtime,
                  isAndroid: () => true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('r46-route-${route.wireValue}')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Felvétel indítása'));
        await tester.pumpAndSettle();
        expect(find.text('Leállítás és másolás'), findsOneWidget);
        await tester.tap(find.text('Leállítás és másolás'));
        await tester.pumpAndSettle();
        expect(find.text('Riport a vágólapon.'), findsOneWidget);
        expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, report);
        expect(report.length, greaterThan(32768));
        expect(
          calls.where((call) => call.method == 'startR46Recording'),
          hasLength(1),
        );
        expect(
          calls.where((call) => call.method == 'stopR46Recording'),
          hasLength(1),
        );
        expect(
          calls.where(
            (call) => call.method == 'startKeyguardDiagnosticCapture',
          ),
          isEmpty,
        );
      },
    );
  }

  testWidgets(
    'failed clipboard write retries the same sealed report without stopping twice',
    (tester) async {
      const id = 'retry-id';
      const report =
          'FLUVI_R46_RECORDING_V1\ncaptureId=$id route=FLUVI_STREAM\nEND_FLUVI_R46_RECORDING_V1\n';
      var stopCalls = 0;
      var writes = 0;
      final sent = <String>[];
      messenger.setMockMethodCallHandler(
        runtime,
        (call) async => switch (call.method) {
          'getR46Recording' => {'state': 'RECORDING', 'captureId': id},
          'getR448DisplayRoute' => {
            'available': true,
            'connected': true,
            'configured': 'FLUVI_STREAM',
          },
          'stopR46Recording' => () {
            stopCalls++;
            return {'captureId': id, 'report': report};
          }(),
          'markR46Copied' => {'captureId': id, 'state': 'COPIED'},
          _ => <String, Object?>{},
        },
      );
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          sent.add((call.arguments as Map)['text'] as String);
          if (++writes == 1) throw PlatformException(code: 'CLIPBOARD_FAILED');
        }
        return null;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleDialog(
              initialKeyguard: true,
              keyguardTimingCapture: KeyguardTimingCaptureBridge(
                channel: runtime,
                isAndroid: () => true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leállítás és másolás'));
      await tester.pumpAndSettle();
      expect(find.text('Másolás újra'), findsOneWidget);
      await tester.tap(find.text('Másolás újra'));
      await tester.pumpAndSettle();
      expect(sent, [report, report]);
      expect(stopCalls, 1);
      expect(find.text('Riport a vágólapon.'), findsOneWidget);
    },
  );

  testWidgets('both choices and the action remain visible with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    messenger.setMockMethodCallHandler(
      runtime,
      (call) async => switch (call.method) {
        'getR46Recording' => {'state': 'READY'},
        'getR448DisplayRoute' => {
          'available': true,
          'connected': true,
          'configured': 'FLUVI_STREAM',
        },
        _ => <String, Object?>{},
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(1.6),
          ),
          child: Scaffold(
            body: DebugConsoleDialog(
              initialKeyguard: true,
              keyguardTimingCapture: KeyguardTimingCaptureBridge(
                channel: runtime,
                isAndroid: () => true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final key in [
      'r46-route-FLUVI_STREAM',
      'r46-route-WIDGETS_ANYWHERE',
      'r46-recording-action',
    ]) {
      final rect = tester.getRect(find.byKey(ValueKey(key)));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      expect(rect.bottom, lessThanOrEqualTo(720));
    }
    expect(tester.takeException(), isNull);
  });
}
