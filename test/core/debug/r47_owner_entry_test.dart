import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/debug/debug_floating_button.dart';
import 'package:fluvi/core/diagnostics/keyguard_timing_capture_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Human diagnostic opens the two-route recording panel directly',
    (tester) async {
      const runtime = MethodChannel('com.fluvi/runtime_monitoring');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        runtime,
        (call) async => switch (call.method) {
          'getR448DisplayRoute' => {
            'available': true,
            'connected': true,
            'configured': 'FLUVI_STREAM',
          },
          'getR46Recording' => {'state': 'READY'},
          _ => <String, Object?>{},
        },
      );
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  DebugFloatingButton(
                    keyguardTimingCapture: KeyguardTimingCaptureBridge(
                      channel: runtime,
                      isAndroid: () => true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('debug-floating-button')));
        await tester.pumpAndSettle();
        expect(find.text('Zárképernyő mérése'), findsOneWidget);
        expect(find.text('Fluvi'), findsOneWidget);
        expect(find.text('Widgets Anywhere'), findsOneWidget);
        expect(find.text('Felvétel indítása'), findsOneWidget);
      } finally {
        messenger.setMockMethodCallHandler(runtime, null);
      }
    },
    skip:
        const String.fromEnvironment('FLUVI_BUILD_PURPOSE') !=
        'human_diagnostic',
  );
}
