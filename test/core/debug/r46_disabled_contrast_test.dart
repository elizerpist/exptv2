import 'dart:math' as math;
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
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets(
    'disabled selected and unselected labels stay legible while recording',
    (tester) async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => switch (call.method) {
          'getR46Recording' => {'state': 'RECORDING', 'captureId': 'contrast'},
          'getR448DisplayRoute' => {
            'available': true,
            'connected': true,
            'configured': 'WIDGETS_ANYWHERE',
          },
          _ => <String, Object?>{},
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DebugConsoleDialog(
              initialKeyguard: true,
              keyguardTimingCapture: KeyguardTimingCaptureBridge(
                channel: channel,
                isAndroid: () => true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final route in KeyguardDisplayRoute.values) {
        final button = tester.widget<OutlinedButton>(
          find.byKey(ValueKey('r46-route-${route.wireValue}')),
        );
        expect(button.onPressed, isNull);
        const state = {WidgetState.disabled};
        final fg = button.style?.foregroundColor?.resolve(state);
        final bg =
            button.style?.backgroundColor?.resolve(state) ??
            const Color(0xFF1E1E2E);
        expect(
          fg,
          isNotNull,
          reason:
              'disabled foreground must not fall back to the dark default theme',
        );
        final effective = Color.alphaBlend(fg!, bg);
        final bright = math.max(
          effective.computeLuminance(),
          bg.computeLuminance(),
        );
        final dark = math.min(
          effective.computeLuminance(),
          bg.computeLuminance(),
        );
        expect(
          (bright + .05) / (dark + .05),
          greaterThanOrEqualTo(4.5),
          reason: route.wireValue,
        );
      }
    },
  );
}
