import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/debug/debug_console.dart';

void main() {
  const capture = MethodChannel('fluvi/wa_lockscreen_capture');
  const tab = ValueKey('debug-console-lockscreen-tab');
  const toggle = ValueKey('wa-capture-toggle');
  const copy = ValueKey('wa-capture-copy');
  const frozen = 'FLUVI_WA_LOCKSCREEN_CAPTURE_V1\nfixture=ő\nsha256=fixture\n';

  testWidgets(
    'real console freezes running capture and retries exact copy',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var state = 'IDLE';
      var copyFails = true;
      final clipboard = <String>[];
      messenger.setMockMethodCallHandler(capture, (call) async {
        switch (call.method) {
          case 'start':
            state = 'RECORDING';
          case 'getFrozen':
            state = 'FROZEN';
        }
        return <String, Object?>{
          'state': state,
          'id': state == 'IDLE' ? null : 'r51-fixture',
          'elapsedMs': 2345,
          'drops': 2,
          'service': 'DISABLED',
          'hasCapture': state != 'IDLE',
          if (call.method == 'getFrozen') 'text': frozen,
        };
      });
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          if (copyFails) throw PlatformException(code: 'fixture');
          clipboard.add(call.arguments['text'] as String);
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(capture, null);
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(const MaterialApp(home: DebugConsoleDialog()));
      await tester.tap(find.byKey(tab));
      await tester.pumpAndSettle();
      expect(find.text('ORB-szolgáltatás kikapcsolva'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byKey(copy)).onPressed, isNull);
      expect(find.byType(OutlinedButton), findsNWidgets(2));

      await tester.tap(find.byKey(toggle));
      await tester.pumpAndSettle();
      expect(find.text('Leállítás'), findsOneWidget);
      // Remount the same real panel. Its running state belongs to native.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaterialApp(home: DebugConsoleDialog()));
      await tester.tap(find.byKey(tab));
      await tester.pumpAndSettle();
      expect(find.text('Leállítás'), findsOneWidget);

      await tester.tap(find.byKey(copy));
      await tester.pumpAndSettle();
      expect(find.text('Lezárt felvétel'), findsOneWidget);
      expect(
        find.text('A másolás sikertelen. A felvétel megmaradt.'),
        findsOneWidget,
      );
      expect(clipboard, isEmpty);
      copyFails = false;
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(copy));
        await tester.pumpAndSettle();
        expect(find.text('Felvétel a vágólapon.'), findsOneWidget);
      }
      expect(clipboard, [frozen, frozen]);
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'stop disables both actions until the native freeze returns',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final stop = Completer<Map<String, Object?>>();
      final events = <String>[];
      messenger.setMockMethodCallHandler(capture, (call) async {
        events.add(call.method);
        if (call.method == 'stop') return stop.future;
        return <String, Object?>{
          'state': 'RECORDING',
          'id': 'r51-fixture',
          'hasCapture': true,
          'service': 'CONNECTED',
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(capture, null));
      await tester.pumpWidget(const MaterialApp(home: DebugConsoleDialog()));
      await tester.tap(find.byKey(tab));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(toggle));
      await tester.pump();
      expect(tester.widget<OutlinedButton>(find.byKey(copy)).onPressed, isNull);
      expect(
        tester.widget<OutlinedButton>(find.byKey(toggle)).onPressed,
        isNull,
      );
      expect(events, ['status', 'stop']);
      stop.complete({
        'state': 'FROZEN',
        'id': 'r51-fixture',
        'hasCapture': true,
      });
      await tester.pumpAndSettle();
      expect(find.text('Lezárt felvétel'), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byKey(copy)).onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
