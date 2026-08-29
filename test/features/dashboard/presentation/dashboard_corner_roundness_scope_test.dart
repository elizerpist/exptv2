import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/features/dashboard/presentation/budget_content_card_style.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_corner_roundness.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shadow_style.dart';
import 'package:fluvi/core/design/dashboard_shadow_profile.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_placeholder_card.dart';

void main() {
  testWidgets('reference Header depth keeps inner material above the clip', (
    tester,
  ) async {
    final boundary = GlobalKey();
    final visual = DashboardHeaderVisualController(vsync: tester);
    final frame = ValueNotifier<DashboardHeaderVisualFrame>(
      DashboardHeaderVisualFrame.staticTone(Colors.blue),
    );
    final shadows = DashboardShadowStyleController()
      ..select(DashboardShadowStyle.reference3d);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardShadowStyleScope(
            controller: shadows,
            child: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 320,
                height: 104,
                child: Stack(
                  children: <Widget>[
                    DashboardCoreModeHeaderScaffold(
                      bounds: const DashboardBounds(
                        left: 0,
                        top: 0,
                        width: 320,
                        height: 104,
                      ),
                      surfaceColor: Colors.blue,
                      headerKey: const ValueKey<String>(
                        'reference-depth-header',
                      ),
                      labelKey: const ValueKey<String>('reference-depth-label'),
                      label: 'mode',
                      visualController: visual,
                      visualFrameListenable: frame,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('dashboard-header-depth-highlight')),
      findsOneWidget,
    );
    final physicalShell = tester.widget<FluviRoundedBox>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('reference-depth-header')),
        matching: find.byType(FluviRoundedBox),
      ),
    );
    expect(
      physicalShell.decoration.boxShadow,
      DashboardShadowProfile(
        DashboardShadowStyle.reference3d,
      ).depthFor(DashboardCornerSurfaceFamily.header).outerShadows,
    );
    final rendered =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = (await tester.runAsync(() => rendered.toImage()))!;
    try {
      final bytes = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      expect(bytes, isNotNull);
      final center = _pixelAt(bytes!, width: 320, x: 160, y: 52);
      expect(
        center.toARGB32(),
        Colors.blue.toARGB32(),
        reason:
            'Reference3D may add edge depth but the animated Header palette '
            'remains the only interior fill owner.',
      );
    } finally {
      image.dispose();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    visual.dispose();
    frame.dispose();
    shadows.dispose();
  });

  testWidgets(
    'one roundness scope keeps Header shell and animated clip exactly aligned',
    (tester) async {
      final roundness = DashboardCornerRoundnessController();
      for (final family in DashboardCornerSurfaceFamily.values) {
        roundness.setPosition(family, 1);
      }
      final visual = DashboardHeaderVisualController(vsync: tester);
      final frame = ValueNotifier<DashboardHeaderVisualFrame>(
        DashboardHeaderVisualFrame.staticTone(Colors.blue),
      );
      final cardStyle = BudgetContentCardStyleController();
      const headerBounds = DashboardBounds(
        left: 0,
        top: 0,
        width: 320,
        height: 104,
      );
      const contentBounds = DashboardBounds(
        left: 0,
        top: 110,
        width: 320,
        height: 120,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCornerRoundnessScope(
              controller: roundness,
              child: Stack(
                children: <Widget>[
                  DashboardCoreModeHeaderScaffold(
                    bounds: headerBounds,
                    surfaceColor: Colors.blue,
                    headerKey: const ValueKey<String>('roundness-header'),
                    labelKey: const ValueKey<String>('roundness-label'),
                    label: 'mode',
                    visualController: visual,
                    visualFrameListenable: frame,
                  ),
                  DashboardPlaceholderCard(
                    bounds: contentBounds,
                    semanticKey: const ValueKey<String>('roundness-content'),
                  ),
                  Positioned(
                    left: 0,
                    top: 236,
                    width: 320,
                    height: 120,
                    child: BudgetDistributionCardShell(
                      contentCardStyle: cardStyle,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      var settings = DashboardCornerSettings.defaults;
      for (final family in DashboardCornerSurfaceFamily.values) {
        settings = settings.withPosition(family, 1);
      }
      final profile = DashboardCornerProfile(settings);
      final expectedHeader = profile.borderRadiusFor(
        DashboardCornerSurfaceFamily.header,
        size: const Size(320, 104),
      );
      final header = find.byKey(const ValueKey<String>('roundness-header'));
      final physicalShell = tester.widget<FluviRoundedBox>(
        find.descendant(of: header, matching: find.byType(FluviRoundedBox)),
      );
      final clip = tester.widget<ClipRRect>(
        find.descendant(of: header, matching: find.byType(ClipRRect)),
      );
      expect(physicalShell.decoration.borderRadius, expectedHeader);
      expect(clip.borderRadius, expectedHeader);

      final content = tester.widget<FluviRoundedBox>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('roundness-content')),
          matching: find.byType(FluviRoundedBox),
        ),
      );
      expect(
        content.decoration.borderRadius,
        profile.borderRadiusFor(
          DashboardCornerSurfaceFamily.contentCard,
          size: const Size(320, 120),
        ),
      );
      final card2 = tester.widget<FluviRoundedBox>(
        find.byKey(const ValueKey<String>('budget-distribution-card-shell')),
      );
      expect(
        card2.decoration.borderRadius,
        profile.borderRadiusFor(
          DashboardCornerSurfaceFamily.budgetDistributionCard,
          size: const Size(320, 120),
        ),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      roundness.dispose();
      visual.dispose();
      frame.dispose();
      cardStyle.dispose();
    },
  );
}

Color _pixelAt(
  ByteData bytes, {
  required int width,
  required int x,
  required int y,
}) {
  final offset = (y * width + x) * 4;
  return Color.fromARGB(
    bytes.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
}
