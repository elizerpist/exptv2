import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/app/platform/dashboard_active_header_frame_preparer.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_orb_material.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';

void main() {
  testWidgets('diagnose real animated renderer and bounded loop preparation', (tester) async {
    final c = DashboardHeaderVisualController(vsync: tester)
      ..selectEffect(DashboardHeaderEffectId.dualTide)
      ..setPortalEnabled(DashboardHeaderPortalChannel.backgroundMorph, true)
      ..setPortalEnabled(DashboardHeaderPortalChannel.innerMotion, true);
    const colors = [Color(0xffffb37b), Color(0xffff79a8), Color(0xff8f5ee8)];
    final snap = DashboardHeaderMaterialSnapshot.capture(controller: c, frame: DashboardHeaderVisualFrame(
      colors: colors, stops: [0,.5,1], opacity: 1, colorA: colors.first, colorB: colors.last));
    final renderer = DashboardHeaderMaterialFrameRenderer();
    try {
      final image = (await tester.runAsync(() => renderer.renderOrbTexture(snapshot: snap,
        headerSize: const Size(377.5,125.8), devicePixelRatio: 2.625, orbSizePx: 96, offset: Duration.zero)))!;
      final exact = renderer.lastPaintWasExact;
      print('singleFrameExact=$exact size=${image.width}x${image.height}');
      image.dispose();
      final prepared = (await tester.runAsync(() => renderActiveHeaderFrames(snapshot: snap,
        headerSize: const Size(377.5,125.8), devicePixelRatio: 2.625,
        motionEnabled: true, isCurrent: () => true)))!;
      print('realAnimatedPreparation=${prepared.status.name} count=${prepared.frames?.length}');
      expect(exact, isTrue, reason: 'the synthetic animated shader must render without a gradient fallback');
      expect(prepared.status, isNot(ActiveHeaderPreparationStatus.rendererUnavailable));
    } finally { renderer.dispose(); c.dispose(); }
  });
}
