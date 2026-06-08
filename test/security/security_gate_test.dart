import 'package:exptv2/features/security/security_gate.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/security_gate_methods');
  final calls = <String>[];
  var pinEnabled = true;
  var biometricEnabled = false;
  var biometricResult = false;

  setUp(() {
    calls.clear();
    pinEnabled = true;
    biometricEnabled = false;
    biometricResult = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'expenseLoadSettings':
              return <String, Object?>{
                'themeSettings': <String, Object?>{},
                'fastInfoConfig': <String, Object?>{},
                'pushRecurringSettings': <String, Object?>{},
                'notificationSettings': <String, Object?>{},
                'securitySettings': <String, Object?>{
                  'pinEnabled': pinEnabled,
                  'biometricEnabled': biometricEnabled,
                  'biometricAvailable': true,
                  'biometricLabel': 'Ujjlenyomat elerheto',
                },
              };
            case 'expenseVerifySecurityPin':
              return (call.arguments as Map<dynamic, dynamic>)['pin'] ==
                  '1234';
            case 'expenseAuthenticateBiometric':
              return biometricResult;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget subject() {
    return MaterialApp(
      home: SecurityGate(
        nativeBridge: NativeBridge(
          methodChannel: channel,
          eventChannel: const EventChannel('test/security_gate_events'),
        ),
        child: const Text('Unlocked app'),
      ),
    );
  }

  testWidgets('locks on startup when pin is enabled', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('Feloldás'), findsOneWidget);
    expect(find.text('Unlocked app'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('lock-pin-input')), '1234');
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();

    expect(find.text('Unlocked app'), findsOneWidget);
  });

  testWidgets('locks again after background resume', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('lock-pin-input')), '1234');
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();
    expect(find.text('Unlocked app'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Feloldás'), findsOneWidget);
    expect(find.text('Unlocked app'), findsNothing);
  });

  testWidgets('does not lock after biometric prompt inactive resume', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('lock-pin-input')), '1234');
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();
    expect(find.text('Unlocked app'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Unlocked app'), findsOneWidget);
    expect(find.text('Feloldás'), findsNothing);
  });

  testWidgets('does not lock during ordinary foreground pumping', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('lock-pin-input')), '1234');
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 30));

    expect(find.text('Unlocked app'), findsOneWidget);
    expect(find.text('Feloldás'), findsNothing);
  });

  testWidgets('biometric failure keeps pin fallback visible', (tester) async {
    biometricEnabled = true;
    biometricResult = false;

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(calls, contains('expenseAuthenticateBiometric'));
    expect(find.byKey(const ValueKey('lock-pin-input')), findsOneWidget);
  });
}
