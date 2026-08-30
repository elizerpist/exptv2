import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:fluvi/core/debug/debug_floating_button.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_event.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';

void main() {
  setUp(FluviDiagnosticLogger.clear);

  testWidgets('matches the Spendee floating debug entry point', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
      ),
    );

    expect(find.byKey(const ValueKey('debug-floating-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('debug-floating-button-position')),
      findsOneWidget,
    );
    final topLeft = tester.getTopLeft(
      find.byKey(const ValueKey('debug-floating-button-position')),
    );
    expect(topLeft.dx, 16);
  });

  testWidgets('opens the bounded signal-path console without layout shift', (
    tester,
  ) async {
    FluviDiagnosticLogger.log(
      const FluviDiagnosticEvent(stage: 'D10', message: '689 000 Ft'),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('debug-console-dialog')), findsOneWidget);
    expect(find.text('Debug Console'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    expect(FluviDiagnosticLogger.allText, contains('[FLOW][D10]'));
  });

  testWidgets('virtualizes the latest 1000 retained entries in the panel', (
    tester,
  ) async {
    for (var index = 0; index <= 1000; index += 1) {
      FluviDiagnosticLogger.log(FluviDiagnosticEvent(stage: 'D$index'));
    }
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1000 retained'), findsOneWidget);
    expect(find.byKey(const ValueKey('debug-console-logs')), findsOneWidget);
    expect(find.textContaining('[FLOW][D1000]'), findsOneWidget);
    expect(find.textContaining('[FLOW][D0]'), findsNothing);
    expect(find.byType(SelectableText).evaluate().length, lessThan(1000));
  });

  testWidgets('manual review pauses follow and jump-to-live clears unseen', (
    tester,
  ) async {
    for (var index = 0; index < 120; index += 1) {
      FluviDiagnosticLogger.log(FluviDiagnosticEvent(stage: 'D$index'));
    }
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('debug-console-logs')),
      const Offset(0, 320),
    );
    await tester.pump();
    expect(find.textContaining('REVIEWING'), findsOneWidget);

    for (var index = 120; index < 127; index += 1) {
      FluviDiagnosticLogger.log(FluviDiagnosticEvent(stage: 'D$index'));
    }
    await tester.pump();
    await tester.pump();
    expect(find.text('+7 new'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('debug-console-jump-live')));
    await tester.pump();
    expect(find.textContaining('LIVE'), findsOneWidget);
    expect(find.byKey(const ValueKey('debug-console-jump-live')), findsNothing);
  });

  testWidgets('quick bug marker appends structured current context', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DebugFloatingButton(
                diagnosticStatusProvider: () => const <String, Object?>{
                  'mode': 'mind',
                  'direction': 'expense',
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('debug-console-mark-bug')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mind slider'));
    await tester.pump();

    final marker = FluviDiagnosticLogger.entries.last;
    expect(marker.stage, 'USER_MARK');
    expect(marker.scope, contains('issue=mind_slider'));
    expect(marker.scope, contains('mode=mind'));
  });

  testWidgets('controls an explicit frozen diagnostic capture session', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('debug-console-start-capture')));
    await tester.pump();
    expect(FluviDiagnosticLogger.captureActive, isTrue);

    await tester.tap(find.byKey(const ValueKey('debug-console-stop-capture')));
    await tester.pump();
    expect(FluviDiagnosticLogger.captureFrozen, isTrue);

    await tester.tap(find.byKey(const ValueKey('debug-console-clear-capture')));
    await tester.pump();
    expect(FluviDiagnosticLogger.captureEntries, isEmpty);
  });

  testWidgets('exports the bounded physical rail report without stdout', (
    tester,
  ) async {
    String? clipboardText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DebugFloatingButton(
                physicalReportProvider: () =>
                    '{"schema":"fluvi.dashboard.physical-rail.v1"}',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('debug-console-report-tab')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('debug-console-copy-physical-report')),
    );
    await tester.pump();

    expect(clipboardText, '{"schema":"fluvi.dashboard.physical-rail.v1"}');
  });

  testWidgets('keeps the physical report readable when clipboard copy fails', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'clipboard-denied');
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              DebugFloatingButton(
                physicalReportProvider: () => '{"readiness":"ready"}',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('debug-console-report-tab')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('debug-console-physical-report')),
      findsOneWidget,
    );
    expect(find.textContaining('"readiness":"ready"'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('debug-console-copy-physical-report')),
    );
    await tester.pump();
    expect(find.textContaining('clipboard-denied'), findsOneWidget);
  });
}
