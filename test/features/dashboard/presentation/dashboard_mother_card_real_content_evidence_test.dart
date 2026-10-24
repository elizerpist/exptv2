// Opt-in real dashboard evidence: live controllers and interactive subtrees.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';
import '../../../support/test_pump.dart';

void main() {
  const stage = String.fromEnvironment('MOTHER_CARD_REAL_EVIDENCE');
  testWidgets('render live Mother Card dashboard layers', (tester) async {
    await prepareDashboardTestRenderResources();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    for (final mode in [
      DashboardModeSpec.budget,
      DashboardModeSpec.mind,
      DashboardModeSpec.balance,
    ]) {
      final core = DashboardCoreController(
        initialCoreRevision: 1,
        initialDate: DateTime(2026, 7, 16),
        initialPlane: TimePlane.year,
        initialRailOpen: false,
      );
      final modes = DashboardCoreModeController(initialMode: mode);
      await core.bootstrap();
      await pumpDashboardSurface(
        tester,
        RepaintBoundary(
          key: const ValueKey('real-evidence'),
          child: Theme(
            data: ThemeData(fontFamily: 'Inter'),
            child: CoreDashboard(
              controller: core,
              modeController: modes,
              categoryCollection: emptyTestCategoryCollection,
            ),
          ),
        ),
      );
      await tester.pump();
      core.expansion.beginDrag();
      for (final separation in [0.0, .1 / 180, .05, .35, .5, .65, .95, 1.0]) {
        core.expansion.setProgress(180 * separation);
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('real-evidence')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'docs/superpowers/evidence/2026-10-24-shared-motion/$stage-real-${mode.mode.name}-${(separation * 100000).round()}.png',
          );
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      core.dispose();
      modes.dispose();
    }
  }, skip: stage.isEmpty);
}
