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

  testWidgets(
    'RED MYHR-09: Mind Heatmap is a separate bounded log filter while All preserves every family',
    (tester) async {
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(stage: 'MIND_HEATMAP|DIRECTION_REQUEST'),
      );
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(stage: 'MIND_HEATMAP|PAINTED'),
      );
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(stage: 'MIND_ENTRY|SUMMARY'),
      );
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(stage: 'MIND|PREVIEW_FRAME'),
      );
      FluviDiagnosticLogger.log(const FluviDiagnosticEvent(stage: 'AVATAR|X'));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('[FLOW][MIND_HEATMAP|DIRECTION_REQUEST]'),
        findsOneWidget,
      );
      expect(find.textContaining('[FLOW][AVATAR|X]'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('debug-console-log-filter')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('debug-console-log-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mind Heatmap').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('[FLOW][MIND_HEATMAP|DIRECTION_REQUEST]'),
        findsOneWidget,
      );
      expect(
        find.textContaining('[FLOW][MIND_HEATMAP|PAINTED]'),
        findsOneWidget,
      );
      expect(
        find.textContaining('[FLOW][MIND_ENTRY|SUMMARY]'),
        findsOneWidget,
        reason:
            'The on-screen Mind Heatmap export is the one retained flow for '
            'both existing heatmap records and correlated Mind entries.',
      );
      expect(find.textContaining('[FLOW][MIND|PREVIEW_FRAME]'), findsNothing);
      expect(find.textContaining('[FLOW][AVATAR|X]'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('debug-console-log-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('[FLOW][MIND|PREVIEW_FRAME]'), findsOneWidget);
      expect(find.textContaining('[FLOW][AVATAR|X]'), findsOneWidget);
    },
  );

  testWidgets(
    'RED SUMD-01: the Mind Heatmap dropdown exposes copyable scoped Sum zoom diagnostics',
    (tester) async {
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
      FluviDiagnosticLogger.log(
        const FluviDiagnosticEvent(
          stage: 'MIND_SUM|SCALE_UPDATE',
          scope:
              'mode=detailed pointers=2 focal=180,72 scale=1.12 '
              'windowBefore=365d windowAfter=182d anchors=13 synced=true',
        ),
      );
      FluviDiagnosticLogger.log(const FluviDiagnosticEvent(stage: 'AVATAR|X'));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('debug-console-log-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mind Heatmap').last);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('[FLOW][MIND_SUM|SCALE_UPDATE]'),
        findsOneWidget,
      );
      expect(find.textContaining('[FLOW][AVATAR|X]'), findsNothing);
      expect(
        find.byKey(const ValueKey('debug-console-copy')),
        findsOneWidget,
        reason:
            'The existing bounded console copy affordance exports the '
            'currently selected Mind diagnostic view.',
      );
      await tester.tap(find.byKey(const ValueKey('debug-console-copy')));
      await tester.pump();
      expect(clipboardText, contains('[FLOW][MIND_SUM|SCALE_UPDATE]'));
      expect(clipboardText, isNot(contains('[FLOW][AVATAR|X]')));
    },
  );

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

  testWidgets(
    'RED DRR-09: MARK BUG NOW has a dedicated Mind Heatmap issue without replacing the log filter',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('debug-console-log-filter')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('debug-console-mark-bug')));
      await tester.pumpAndSettle();
      expect(find.text('Mind Heatmap'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Mind slider'), findsOneWidget);

      await tester.tap(find.text('Mind Heatmap'));
      await tester.pump();

      final marker = FluviDiagnosticLogger.entries.last;
      expect(marker.stage, 'USER_MARK');
      expect(marker.scope, contains('issue=mind_heatmap'));
    },
  );

  testWidgets(
    'bug marker menu uses a light surface with legible marker labels',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [DebugFloatingButton()])),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
      await tester.pumpAndSettle();
      final markerMenu = tester.widget<PopupMenuButton<String>>(
        find.byKey(const ValueKey('debug-console-mark-bug')),
      );
      expect(markerMenu.color, const Color(0xFFF8FAFC));

      await tester.tap(find.byKey(const ValueKey('debug-console-mark-bug')));
      await tester.pumpAndSettle();
      final timeLabel = tester.widget<Text>(find.text('Time target jump'));
      final avatarLabel = tester.widget<Text>(find.text('Avatar filter stuck'));
      final mindLabel = tester.widget<Text>(
        find.text('Mind slider: no live list'),
      );
      expect(timeLabel.style?.color, const Color(0xFF1F2937));
      expect(avatarLabel.style?.color, const Color(0xFF1F2937));
      expect(mindLabel.style?.color, const Color(0xFF1F2937));
    },
  );

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
