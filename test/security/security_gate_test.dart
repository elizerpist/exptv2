import 'dart:async';

import 'package:exptv2/features/security/security_gate.dart';
import 'package:exptv2/features/settings/models/security_settings.dart';
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
  var settingsLoadCount = 0;
  Completer<Map<String, Object?>>? resumeSettingsCompleter;

  setUp(() {
    calls.clear();
    pinEnabled = true;
    biometricEnabled = false;
    biometricResult = false;
    settingsLoadCount = 0;
    resumeSettingsCompleter = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'expenseLoadSettings':
              settingsLoadCount += 1;
              final delayed = resumeSettingsCompleter;
              if (settingsLoadCount > 1 && delayed != null) {
                return await delayed.future;
              }
              return settingsPayload(
                pinEnabled: pinEnabled,
                biometricEnabled: biometricEnabled,
              );
            case 'expenseVerifySecurityPin':
              return (call.arguments as Map<dynamic, dynamic>)['pin'] == '1234';
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

  Widget subject({
    Widget child = const Text('Unlocked app'),
    SecurityGateController? controller,
  }) {
    return MaterialApp(
      home: SecurityGate(
        controller: controller,
        nativeBridge: NativeBridge(
          methodChannel: channel,
          eventChannel: const EventChannel('test/security_gate_events'),
        ),
        child: child,
      ),
    );
  }

  testWidgets('locks on startup when pin is enabled', (tester) async {
    var childInitCount = 0;
    await tester.pumpWidget(
      subject(child: _MountProbe(onInit: () => childInitCount += 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feloldás'), findsOneWidget);
    expect(find.text('Unlocked app'), findsNothing);
    expect(childInitCount, 0);

    await tester.enterText(
      find.byKey(const ValueKey('lock-pin-input')),
      '1234',
    );
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();

    expect(find.text('Unlocked app'), findsOneWidget);
    expect(childInitCount, 1);
  });

  testWidgets('locks again after background resume', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('lock-pin-input')),
      '1234',
    );
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

  testWidgets(
    'resume refresh keeps unlocked child mounted without loading spinner',
    (tester) async {
      pinEnabled = false;
      var disposeCount = 0;
      resumeSettingsCompleter = Completer<Map<String, Object?>>();

      await tester.pumpWidget(
        subject(child: _RetainedStateProbe(onDispose: () => disposeCount += 1)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('retained-state-increment')));
      await tester.pump();
      expect(find.text('Retained state 1'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Retained state 1'), findsOneWidget);
      expect(disposeCount, 0);

      resumeSettingsCompleter!.complete(
        settingsPayload(pinEnabled: false, biometricEnabled: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retained state 1'), findsOneWidget);
      expect(disposeCount, 0);
    },
  );

  testWidgets(
    'security settings update locks synchronously before delayed resume load',
    (tester) async {
      pinEnabled = false;
      resumeSettingsCompleter = Completer<Map<String, Object?>>();
      final controller = SecurityGateController();

      await tester.pumpWidget(subject(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('Unlocked app'), findsOneWidget);

      controller.updateSettings(
        const SecuritySettings(
          pinEnabled: true,
          biometricEnabled: false,
          biometricAvailable: true,
          biometricLabel: 'Ujjlenyomat elerheto',
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Feloldás'), findsOneWidget);
      expect(find.text('Unlocked app'), findsNothing);

      resumeSettingsCompleter!.complete(
        settingsPayload(pinEnabled: true, biometricEnabled: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Feloldás'), findsOneWidget);
    },
  );

  testWidgets('successful unlock wins over delayed resume settings refresh', (
    tester,
  ) async {
    resumeSettingsCompleter = Completer<Map<String, Object?>>();
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('lock-pin-input')),
      '1234',
    );
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('lock-pin-input')),
      '1234',
    );
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Unlocked app'), findsOneWidget);

    resumeSettingsCompleter!.complete(
      settingsPayload(pinEnabled: true, biometricEnabled: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unlocked app'), findsOneWidget);
    expect(find.text('Feloldás'), findsNothing);
  });

  testWidgets('pending resume refresh is ignored after gate disposal', (
    tester,
  ) async {
    pinEnabled = false;
    resumeSettingsCompleter = Completer<Map<String, Object?>>();
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    resumeSettingsCompleter!.complete(
      settingsPayload(pinEnabled: false, biometricEnabled: false),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not lock after biometric prompt inactive resume', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('lock-pin-input')),
      '1234',
    );
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
    await tester.enterText(
      find.byKey(const ValueKey('lock-pin-input')),
      '1234',
    );
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

  testWidgets('biometric success publishes the unlocked state', (tester) async {
    biometricEnabled = true;
    biometricResult = true;

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(calls, contains('expenseAuthenticateBiometric'));
    expect(find.text('Unlocked app'), findsOneWidget);
    expect(find.text('Feloldás'), findsNothing);
  });
}

Map<String, Object?> settingsPayload({
  required bool pinEnabled,
  required bool biometricEnabled,
}) {
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
}

class _RetainedStateProbe extends StatefulWidget {
  const _RetainedStateProbe({required this.onDispose});

  final VoidCallback onDispose;

  @override
  State<_RetainedStateProbe> createState() => _RetainedStateProbeState();
}

class _RetainedStateProbeState extends State<_RetainedStateProbe> {
  var _value = 0;

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: TextButton(
          key: const ValueKey('retained-state-increment'),
          onPressed: () => setState(() => _value += 1),
          child: Text('Retained state $_value'),
        ),
      ),
    );
  }
}

class _MountProbe extends StatefulWidget {
  const _MountProbe({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('Unlocked app');
}
