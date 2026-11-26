import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/debug/debug_console.dart';
import 'package:fluvi/core/diagnostics/keyguard_timing_capture_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.fluvi/runtime_monitoring');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget panel() => MaterialApp(
    home: Scaffold(
      body: DebugConsoleDialog(
        initialKeyguard: true,
        keyguardTimingCapture: KeyguardTimingCaptureBridge(
          channel: channel,
          isAndroid: () => true,
        ),
      ),
    ),
  );

  testWidgets('two rapid taps cannot start a second native run', (
    tester,
  ) async {
    final ready = Completer<Map<String, Object?>>();
    var starts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getR46Recording') return {'state': 'READY'};
      if (call.method == 'getR448DisplayRoute')
        return {
          'available': true,
          'connected': true,
          'configured': 'FLUVI_STREAM',
        };
      if (call.method == 'startR46Recording') {
        starts++;
        return ready.future;
      }
      return <String, Object?>{};
    });
    await tester.pumpWidget(panel());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Felvétel indítása'));
    await tester.pump();
    expect(find.text('Indítás…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('r46-recording-action')),
          )
          .onPressed,
      isNull,
    );
    ready.complete({
      'active': true,
      'captureId': 'one',
      'printArmed': true,
      'routeConfirmed': 'FLUVI_STREAM',
      'sampleShape': 'ORB',
      'actionKind': 'SESSION',
      'policy': 'R46_ALL',
    });
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(find.text('Leállítás és másolás'), findsOneWidget);
  });

  testWidgets('interrupted run is finalized and its original id is copied', (
    tester,
  ) async {
    const id = 'interrupted';
    const text =
        'FLUVI_R46_RECORDING_V1\ncaptureId=$id route=FLUVI_STREAM end=INTERRUPTED\nEND_FLUVI_R46_RECORDING_V1\n';
    String? clipboard;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => switch (call.method) {
        'getR46Recording' => {'state': 'INTERRUPTED', 'captureId': id},
        'getR448DisplayRoute' => {
          'available': true,
          'connected': false,
          'configured': 'FLUVI_STREAM',
        },
        'stopR46Recording' => {'captureId': id, 'report': text},
        'markR46Copied' => {'captureId': id, 'state': 'COPIED'},
        _ => <String, Object?>{},
      },
    );
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData')
        clipboard = (call.arguments as Map)['text'] as String;
      return null;
    });
    await tester.pumpWidget(panel());
    await tester.pumpAndSettle();
    expect(find.textContaining('szolgáltatás megszakadt'), findsOneWidget);
    await tester.tap(find.text('Leállítás és másolás'));
    await tester.pumpAndSettle();
    expect(clipboard, text);
    expect(find.text('Riport a vágólapon.'), findsOneWidget);
  });

  testWidgets('a mismatched native route never becomes active', (tester) async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => switch (call.method) {
        'getR46Recording' => {'state': 'READY'},
        'getR448DisplayRoute' => {
          'available': true,
          'connected': true,
          'configured': 'FLUVI_STREAM',
        },
        'startR46Recording' => {
          'active': true,
          'captureId': 'wrong',
          'printArmed': true,
          'routeConfirmed': 'WIDGETS_ANYWHERE',
          'sampleShape': 'ORB',
          'actionKind': 'SESSION',
          'policy': 'R46_ALL',
        },
        _ => <String, Object?>{},
      },
    );
    await tester.pumpWidget(panel());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Felvétel indítása'));
    await tester.pumpAndSettle();
    expect(find.text('Leállítás és másolás'), findsNothing);
    expect(find.textContaining('A felvétel nem indult el'), findsOneWidget);
  });
}
