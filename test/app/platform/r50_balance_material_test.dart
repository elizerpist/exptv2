import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/platform/dashboard_active_header_frame_preparer.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  testWidgets('default Balance prepares a verified animated widget packet', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final policy = DashboardBalanceHeaderColorPolicy(tuning: controller.tuning);
    try {
      final snapshot = DashboardHeaderMaterialSnapshot.capture(
        controller: controller,
        frame: policy.value,
      );
      final prepared = (await tester.runAsync(
        () => renderActiveHeaderFrames(
          snapshot: snapshot,
          headerSize: const Size(377.5, 126),
          devicePixelRatio: 2.625,
          motionEnabled: true,
          isCurrent: () => true,
        ),
      ))!;
      expect(prepared.status, ActiveHeaderPreparationStatus.ready);
      expect(prepared.frames!.length, greaterThan(2));
      expect(
        prepared.playback!.decodedBitmapBytes,
        lessThanOrEqualTo(700 * 1024),
      );
      expect(prepared.phaseOffsetMs, greaterThan(0));
      debugPrint(
        'R50_DEFAULT_LOOP frames=${prepared.frames!.length} '
        'intervalMs=${prepared.playback!.intervalMs} '
        'offsetMs=${prepared.phaseOffsetMs}',
      );
    } finally {
      policy.dispose();
      controller.dispose();
    }
  });
}
