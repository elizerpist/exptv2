import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/platform/dashboard_active_header_frame_preparer.dart';
import 'package:fluvi/app/platform/dashboard_header_widget_publisher.dart';
import 'package:fluvi/app/platform/dashboard_orb_material_playback_profile.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  testWidgets(
    'Balance only follows semantic changes without a dashboard visit',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('fluvi/header_orb_widget');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final visual = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.staticEffect);
      final mode = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      final balance = ValueNotifier(
        DashboardHeaderVisualFrame.staticTone(const Color(0xffc84444)),
      );
      final budget = ValueNotifier(
        DashboardHeaderVisualFrame.staticTone(const Color(0xff5577ee)),
      );
      final mind = ValueNotifier(
        DashboardHeaderVisualFrame.staticTone(const Color(0xff33cc55)),
      );
      var serial = 0;
      final claims = <String>[];
      final published = <String>[];
      final colors = <Color>[];
      final first = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        final values = call.arguments as Map;
        if (call.method == 'prepare') {
          claims.add(values['signature'] as String);
          return {'token': 'balance-${++serial}'};
        }
        if (call.method == 'publish') {
          published.add(values['token'] as String);
          expect(values['motion'], isFalse);
          expect(values['frames'], hasLength(1));
        }
        return true;
      });
      final publisher = DashboardHeaderWidgetPublisher(
        controller: visual,
        balanceFrame: balance,
        channel: channel,
        render:
            ({
              required snapshot,
              required headerSize,
              required devicePixelRatio,
              required motionEnabled,
              required isCurrent,
            }) async {
              colors.add(snapshot.frame.colors.first);
              if (colors.length == 1) await first.future;
              final playback = DashboardOrbMaterialPlaybackProfile.resolve(
                isAnimated: false,
                requiresDenseShaderSampling: false,
                characteristicCycleMs: 1000,
                preferredTextureSizePx: 48,
                maximumFrameCount: 24,
                maximumDecodedBytes: 700 * 1024,
                applyCircularAlphaMask: false,
              );
              return prepareActiveHeaderFrames(
                playback: playback,
                animated: false,
                isCurrent: isCurrent,
                render: (_) async => ActiveHeaderRenderedFrame(
                  png: Uint8List.fromList([1]),
                  rgba: Uint8List(
                    playback.frameSizePx * playback.frameSizePx * 4,
                  ),
                ),
              );
            },
      );
      try {
        publisher.updateBinding({'epoch': 'active', 'connection': 1});
        publisher.updateHeaderGeometry(
          const Size(400, 200),
          devicePixelRatio: 2,
        );
        await tester.pump();
        await tester.pump();
        mode.setProgrammaticMode(DashboardModeSpec.budget);
        budget.value = DashboardHeaderVisualFrame.staticTone(Colors.cyan);
        await tester.pump();
        mode.setProgrammaticMode(DashboardModeSpec.mind);
        mind.value = DashboardHeaderVisualFrame.staticTone(Colors.orange);
        await tester.pump();
        expect(claims, hasLength(1));

        balance.value = DashboardHeaderVisualFrame.staticTone(Colors.purple);
        await tester.pump();
        balance.value = DashboardHeaderVisualFrame.staticTone(Colors.amber);
        await tester.pump();
        first.complete();
        await tester.pump();
        expect(claims, hasLength(3));
        expect(claims.every((claim) => claim.startsWith('balance|')), isTrue);
        expect(published, ['balance-3']);
        expect(colors, [const Color(0xffc84444), Colors.amber]);

        publisher.updateBinding({'epoch': '', 'connection': 1});
        balance.value = DashboardHeaderVisualFrame.staticTone(Colors.pink);
        await tester.pump();
        expect(claims, hasLength(3));
        publisher.updateBinding({'epoch': 'new', 'connection': 2});
        await tester.pump();
        await tester.pump();
        expect(published, ['balance-3', 'balance-4']);
        expect(colors.last, Colors.pink);
      } finally {
        publisher.dispose();
        mode.dispose();
        visual.dispose();
        balance.dispose();
        budget.dispose();
        mind.dispose();
        messenger.setMockMethodCallHandler(channel, null);
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
