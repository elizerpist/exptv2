import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/platform/dashboard_keyguard_material_bridge.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_category_scale.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final stale in [false, true]) {
    testWidgets(
      'R29 real producer marks ${stale ? 'stale' : 'current'} projection',
      (tester) async {
        const channel = MethodChannel('fluvi/keyguard_material');
        final visual = DashboardHeaderVisualController(vsync: tester)
          ..selectBudgetHeaderColorSource(
            DashboardBudgetHeaderColorSource.category,
          );
        final frame = ValueNotifier(
          DashboardHeaderVisualFrame.staticTone(const Color(0xff718096)),
        );
        final published = <Map<Object?, Object?>>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'sceneTarget') {
            return <String, Object?>{
              'mode': 'budget',
              'timeAxis': 'month',
              'direction': 'expense',
              'categoryId': 'seeded',
              'categoryColorId': 'color_01',
              'remainingPercent': 60.0,
              'projectionAvailable': true,
              'focusGeneration': 3,
              'coreRevision': 7,
              'r29CurrentCoreRevision': stale ? 8 : 7,
              'r29SettingsCurrent': true,
              'r29LayoutRevision': 4,
              'r29PrivacyRevision': 5,
              'r29ShowFinancialDetails': true,
            };
          }
          if (call.method == 'publishProfile')
            published.add(Map<Object?, Object?>.from(call.arguments as Map));
          return null;
        });
        final bridge = DashboardKeyguardMaterialBridge(
          controller: visual,
          balanceFrame: frame,
          budgetFrame: frame,
          mindFrame: frame,
          channel: channel,
        );
        try {
          bridge.updateHeaderGeometry(const Size(400, 200));
          await tester.pump(const Duration(milliseconds: 60));
          await tester.pump();
          expect(published, hasLength(1));
          final evidence =
              published.single['r29Evidence'] as Map<Object?, Object?>?;
          expect(evidence, isNotNull);
          expect(evidence!['targetCoreRevision'], 7);
          expect(evidence['visualCoreRevision'], stale ? null : 7);
          expect(evidence['visualProjectionFull'], !stale);
          expect(evidence['focusGeneration'], 3);
          expect(evidence['layoutRevision'], 4);
          expect(evidence['privacyRevision'], 5);
        } finally {
          bridge.dispose();
          visual.dispose();
          frame.dispose();
          messenger.setMockMethodCallHandler(channel, null);
        }
      },
    );
  }

  testWidgets('R29 producer rejects an older in-flight scene target', (
    tester,
  ) async {
    const channel = MethodChannel('fluvi/keyguard_material');
    final visual = DashboardHeaderVisualController(
      vsync: tester,
    )..selectBudgetHeaderColorSource(DashboardBudgetHeaderColorSource.category);
    final frame = ValueNotifier(
      DashboardHeaderVisualFrame.staticTone(const Color(0xff718096)),
    );
    final published = <Map<Object?, Object?>>[];
    final first = Completer<Map<String, Object?>>();
    var requests = 0;
    Map<String, Object?> target(int revision) => <String, Object?>{
      'mode': 'budget',
      'timeAxis': 'month',
      'direction': 'expense',
      'categoryId': 'seeded',
      'categoryColorId': 'color_01',
      'remainingPercent': 60.0,
      'projectionAvailable': true,
      'focusGeneration': revision,
      'coreRevision': revision,
      'r29CurrentCoreRevision': revision,
      'r29SettingsCurrent': true,
      'r29LayoutRevision': 4,
      'r29PrivacyRevision': 5,
      'r29ShowFinancialDetails': true,
    };
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'sceneTarget') {
        requests++;
        if (requests == 1) return first.future;
        return target(8);
      }
      if (call.method == 'publishProfile')
        published.add(Map<Object?, Object?>.from(call.arguments as Map));
      return null;
    });
    final bridge = DashboardKeyguardMaterialBridge(
      controller: visual,
      balanceFrame: frame,
      budgetFrame: frame,
      mindFrame: frame,
      channel: channel,
    );
    try {
      bridge.updateHeaderGeometry(const Size(400, 200));
      await tester.pump(const Duration(milliseconds: 60));
      expect(requests, 1);
      bridge.schedule();
      await tester.pump(const Duration(milliseconds: 60));
      expect(published, isEmpty);
      first.complete(target(7));
      await tester.pump();
      await tester.pump();
      expect(requests, 2);
      expect(published, hasLength(1));
      final evidence = published.single['r29Evidence'] as Map<Object?, Object?>;
      expect(evidence['targetCoreRevision'], 8);
      expect(evidence['visualCoreRevision'], 8);
      expect(published.single['sceneIdentity'], endsWith('|8'));
    } finally {
      bridge.dispose();
      visual.dispose();
      frame.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    }
  });
}
