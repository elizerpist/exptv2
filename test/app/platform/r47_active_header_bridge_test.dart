import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/platform/dashboard_keyguard_material_bridge.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'active header changes publish independently of configured card target',
    (tester) async {
      const channel = MethodChannel('fluvi/keyguard_material');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final visual = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.dualTide);
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      final balance = ValueNotifier(
        DashboardHeaderVisualFrame.staticTone(const Color(0xffc42b39)),
      );
      final budget = ValueNotifier(
        DashboardHeaderVisualFrame.staticTone(const Color(0xff2649bf)),
      );
      final mind = ValueNotifier(
        DashboardHeaderVisualFrame.staticTone(const Color(0xff229954)),
      );
      final active = <Map<Object?, Object?>>[];
      final card = <Map<Object?, Object?>>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'sceneTarget') {
          return <String, Object?>{
            'mode': 'budget',
            'projectionAvailable': true,
          };
        }
        if (call.method == 'publishActiveHeaderProfile') {
          active.add(Map<Object?, Object?>.from(call.arguments as Map));
        }
        if (call.method == 'publishProfile') {
          card.add(Map<Object?, Object?>.from(call.arguments as Map));
        }
        return <String, Object?>{'accepted': true};
      });
      final bridge = DashboardKeyguardMaterialBridge(
        controller: visual,
        balanceFrame: balance,
        budgetFrame: budget,
        mindFrame: mind,
        activeMode: mode,
        channel: channel,
      );
      try {
        bridge.updateHeaderGeometry(const Size(400, 200));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump();
        expect(
          active,
          isNotEmpty,
          reason: 'the visible header needs its own publication',
        );
        expect(
          active.last['colors'],
          contains(const Color(0xffc42b39).toARGB32()),
        );
        expect(
          card.last['colors'],
          contains(const Color(0xff2649bf).toARGB32()),
        );

        balance.value = DashboardHeaderVisualFrame.staticTone(
          const Color(0xffce8818),
        );
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump();
        expect(
          active.last['colors'],
          contains(const Color(0xffce8818).toARGB32()),
        );
        expect(active.last['effectId'], DashboardHeaderEffectId.dualTide.name);
        expect(
          card.last['colors'],
          contains(const Color(0xff2649bf).toARGB32()),
        );
        mode.setProgrammaticMode(DashboardModeSpec.budget);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump();
        expect(active.last['activeMode'], 'budget');
        expect(
          active.last['colors'],
          contains(const Color(0xff2649bf).toARGB32()),
        );
        mode.setProgrammaticMode(DashboardModeSpec.mind);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump();
        expect(active.last['activeMode'], 'mind');
        expect(
          active.last['colors'],
          contains(const Color(0xff229954).toARGB32()),
        );
        visual.setMotionEnabled(false);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump();
        expect(active.last['motionEnabled'], isFalse);
        expect(active.last['sourceAnimated'], isFalse);
        visual.setMotionEnabled(true);
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump();
        expect(active.last['motionEnabled'], isTrue);
        expect(active.last['sourceAnimated'], isTrue);
      } finally {
        bridge.dispose();
        mode.dispose();
        visual.dispose();
        balance.dispose();
        budget.dispose();
        mind.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      }
    },
  );

  testWidgets('late receipt cannot make an older header current', (
    tester,
  ) async {
    const channel = MethodChannel('fluvi/keyguard_material');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final visual = DashboardHeaderVisualController(vsync: tester);
    final balance = ValueNotifier(
      DashboardHeaderVisualFrame.staticTone(const Color(0xffa12345)),
    );
    final budget = ValueNotifier(
      DashboardHeaderVisualFrame.staticTone(const Color(0xff2244aa)),
    );
    final mind = ValueNotifier(
      DashboardHeaderVisualFrame.staticTone(const Color(0xff338833)),
    );
    final mode = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    final firstReceipt = Completer<Object?>();
    final sent = <Map<Object?, Object?>>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'sceneTarget') {
        return <String, Object?>{'mode': 'budget', 'projectionAvailable': true};
      }
      if (call.method == 'publishActiveHeaderProfile') {
        sent.add(Map<Object?, Object?>.from(call.arguments as Map));
        if (sent.length == 1) return firstReceipt.future;
        return <String, Object?>{'accepted': true};
      }
      return <String, Object?>{'accepted': true};
    });
    final bridge = DashboardKeyguardMaterialBridge(
      controller: visual,
      balanceFrame: balance,
      budgetFrame: budget,
      mindFrame: mind,
      activeMode: mode,
      channel: channel,
    );
    try {
      bridge.updateHeaderGeometry(const Size(400, 200));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(sent.single['activeMode'], 'balance');
      mode.setProgrammaticMode(DashboardModeSpec.mind);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();
      expect(sent.last['activeMode'], 'mind');
      expect(sent.length, 2);
      firstReceipt.complete(<String, Object?>{'accepted': true});
      await tester.pump();
      // Ordinary animation ticks must not republish material or make the old
      // receipt current. Native independently enforces the revision floor.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();
      expect(
        sent.length,
        2,
        reason: 'a stale receipt must not replace the newer cache identity',
      );
    } finally {
      if (!firstReceipt.isCompleted) {
        firstReceipt.complete(<String, Object?>{'accepted': false});
      }
      bridge.dispose();
      mode.dispose();
      visual.dispose();
      balance.dispose();
      budget.dispose();
      mind.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    }
  });
}
