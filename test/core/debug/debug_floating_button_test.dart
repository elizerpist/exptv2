import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.byType(TextField), findsOneWidget);
    expect(FluviDiagnosticLogger.allText, contains('[FLOW][D10]'));
  });
}
