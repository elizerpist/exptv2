import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluvi/core/design/dashboard_border_profile.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_shadow_profile.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_border_style.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shadow_style.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/features/dashboard/presentation/budget_content_card_style.dart';
import 'package:fluvi/features/dashboard/presentation/budget_section_order.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_upper_avatar_cascade_motion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';

const capture = ValueKey('budget-detachment-scene');
DashboardLayoutFrame frame(double collapse) =>
    DashboardGeometryResolver.resolve(
      metrics: DashboardLayoutMetrics.reference,
      mode: DashboardModeSpec.budget,
      collapseProgress: collapse,
      isRailExpanded: false,
      hasPhysicalRail: false,
    );
Future<void> pump(
  WidgetTester tester,
  double collapse, {
  BudgetAvatarContentStyle style = BudgetAvatarContentStyle.separate,
  ValueNotifier<BudgetContentLayout>? layout,
  ValueNotifier<BudgetSectionOrder>? order,
  DashboardHeaderVisualController? visual,
  ValueNotifier<DashboardHeaderVisualFrame>? colors,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xffe9edf6),
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: capture,
          child: SizedBox(
            width: 412,
            height: 700,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: colors == null
                        ? Colors.transparent
                        : const Color(0xffe9edf6),
                  ),
                ),
                BudgetDashboardCoreSurface(
                  avatarContentStyle: style,
                  contentCardStyle: layout,
                  sectionOrder: order,
                  headerVisualController: visual,
                  headerVisualFrame: colors,
                  presentation: DashboardCoreModePresentation(
                    geometry: frame(collapse),
                    palette: DashboardModePaletteResolver.resolve(
                      DashboardModeSpec.budget,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
  });
  testWidgets('accepted expanded and collapsed physical endpoints', (
    tester,
  ) async {
    for (final state in [(0.0, 'expanded'), (180.0, 'collapsed')]) {
      await pump(tester, state.$1);
      await tester.pump();
      await expectLater(
        find.byKey(capture),
        matchesGoldenFile(
          '../../../goldens/budget_unified_detachment_${state.$2}.png',
        ),
      );
    }
  });
  testWidgets(
    'first travel frames retain one physical material and render identity',
    (tester) async {
      RenderObject? bodyRender, perimeterRender;
      Rect? previous;
      var previousCollapse = -1.0;
      for (final collapse in [
        0.0,
        .1,
        .5,
        1.0,
        3.0,
        9.0,
        36.0,
        90.0,
        144.0,
        180.0,
        90.0,
        9.0,
        0.0,
      ]) {
        await pump(tester, collapse);
        await tester.pump();
        final body = find.byKey(const ValueKey('budget-unified-moving-body'));
        final perimeter = find.byKey(
          const ValueKey('budget-unified-perimeter'),
        );
        bodyRender ??= tester.renderObject(body);
        perimeterRender ??= tester.renderObject(perimeter);
        expect(tester.renderObject(body), same(bodyRender));
        expect(tester.renderObject(perimeter), same(perimeterRender));
        final f = frame(collapse);
        final header = tester.widget<DashboardCoreModeHeaderScaffold>(
          find.byType(DashboardCoreModeHeaderScaffold),
        );
        expect(header.visualInset, EdgeInsets.zero);
        expect(header.borderSurface, DashboardBorderSurface.header);
        expect(header.depthProgress, closeTo(collapse / 180, 1e-10));
        expect(header.borderProgress, header.depthProgress);
        final rect = tester.getRect(body);
        if (collapse <= 9 && previous != null && collapse > previousCollapse) {
          expect(rect.bottom, lessThanOrEqualTo(previous.bottom + 1e-8));
        }
        expect(rect.top, greaterThanOrEqualTo(f.headerBounds.bottom));
        final material = tester.widget<FluviRoundedBox>(
          find
              .descendant(of: body, matching: find.byType(FluviRoundedBox))
              .first,
        );
        final radius = material.borderRadius! as BorderRadius;
        expect(
          radius.topLeft.x,
          closeTo(header.borderRadiusOverride!.bottomLeft.x, 1e-8),
        );
        expect(
          find.byKey(const ValueKey('budget-distribution-card-shell')),
          findsNothing,
        );
        previous = rect;
        previousCollapse = collapse;
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'Budget split and section/style variants keep their original content cascades',
    (tester) async {
      final layout = ValueNotifier(BudgetContentLayout.unifiedCard);
      final order = ValueNotifier(BudgetSectionOrder.avatarsThenChart);
      addTearDown(layout.dispose);
      addTearDown(order.dispose);
      for (final section in BudgetSectionOrder.values) {
        order.value = section;
        for (final style in BudgetAvatarContentStyle.values) {
          for (final p in [0.0, .1, 9.0, 36.0, 90.0, 144.0, 180.0, 90.0, 0.0]) {
            layout.value = BudgetContentLayout.split;
            await pump(tester, p, layout: layout, order: order, style: style);
            await tester.pump();
            final oldChart = tester.getRect(
              find.byKey(const ValueKey('dashboard-core-mode-budget-card-2')),
            );
            final oldAvatar = tester.getRect(
              find.byKey(const ValueKey('dashboard-core-mode-budget-card-1')),
            );
            final splitHeader = tester.widget<DashboardCoreModeHeaderScaffold>(
              find.byType(DashboardCoreModeHeaderScaffold),
            );
            expect(splitHeader.depthProgress, 1);
            expect(splitHeader.borderProgress, 1);
            expect(
              find.byKey(const ValueKey('budget-distribution-card-shell')),
              findsOneWidget,
            );
            layout.value = BudgetContentLayout.unifiedCard;
            await tester.pump();
            expect(
              tester.getRect(
                find.byKey(const ValueKey('dashboard-core-mode-budget-card-2')),
              ),
              oldChart,
            );
            // Unified has always retained the existing selected-avatar overhang.
            final avatar = tester.getRect(
              find.byKey(const ValueKey('dashboard-core-mode-budget-card-1')),
            );
            expect(avatar.left, oldAvatar.left);
            expect(avatar.width, oldAvatar.width);
            expect(
              find.byKey(const ValueKey('budget-distribution-card-shell')),
              findsNothing,
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
  testWidgets(
    'Budget applies the shared retiming only to its upper avatar layers',
    (tester) async {
      for (final collapse in [
        0.0,
        9.0,
        36.0,
        63.0,
        90.0,
        117.0,
        144.0,
        171.0,
        180.0,
      ]) {
        await pump(
          tester,
          collapse,
          style: BudgetAvatarContentStyle.avatarRail,
        );
        final avatar = tester.widget<DashboardCoreModeCascadeCard>(
          find
              .ancestor(
                of: find.byKey(
                  const ValueKey('dashboard-core-mode-budget-card-1'),
                ),
                matching: find.byType(DashboardCoreModeCascadeCard),
              )
              .first,
        );
        final backplate = tester.widget<DashboardCoreModeCascadeCard>(
          find
              .ancestor(
                of: find.byKey(
                  const ValueKey('budget-avatar-content-rail-backplate'),
                ),
                matching: find.byType(DashboardCoreModeCascadeCard),
              )
              .first,
        );
        final lower = tester.widget<DashboardCoreModeCascadeCard>(
          find
              .ancestor(
                of: find.byKey(
                  const ValueKey('dashboard-core-mode-budget-card-2'),
                ),
                matching: find.byType(DashboardCoreModeCascadeCard),
              )
              .first,
        );
        final geometry = frame(collapse);
        final expectedUpper = DashboardUpperAvatarCascadeMotion.resolve(
          geometry,
        );
        expect(avatar.motion.top, closeTo(expectedUpper.top, 1e-8));
        expect(avatar.motion.opacity, closeTo(expectedUpper.opacity, 1e-8));
        expect(backplate.motion.top, closeTo(avatar.motion.top, 1e-8));
        expect(backplate.motion.opacity, closeTo(avatar.motion.opacity, 1e-8));
        expect(lower.motion.top, closeTo(geometry.lowerCardMotion!.top, 1e-8));
        expect(
          lower.motion.opacity,
          closeTo(geometry.lowerCardMotion!.opacity, 1e-8),
        );
        if (collapse > 0 && collapse < 180) {
          expect(avatar.motion.top, greaterThan(geometry.upperCardMotion!.top));
          expect(
            avatar.motion.opacity,
            greaterThan(geometry.upperCardMotion!.opacity),
          );
        }
      }
    },
  );
  testWidgets(
    'intermediate physical frames expose the gap without gradient bleed',
    (tester) async {
      final visual = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.staticEffect);
      final colors = ValueNotifier(
        const DashboardHeaderVisualFrame(
          colors: [Color(0xff7045d8), Color(0xff7045d8)],
          stops: [0, 1],
          opacity: 1,
          colorA: Color(0xff7045d8),
          colorB: Color(0xff7045d8),
        ),
      );
      for (final state in [
        (0.0, 'joined_color'),
        (.1, 'first'),
        (9.0, 'five'),
        (36.0, 'early'),
        (63.0, 'thirty_five'),
        (90.0, 'half'),
        (117.0, 'sixty_five'),
        (144.0, 'near'),
        (180.0, 'detached_color'),
      ]) {
        await pump(tester, state.$1, visual: visual, colors: colors);
        await tester.pump();
        await expectLater(
          find.byKey(capture),
          matchesGoldenFile(
            '../../../goldens/budget_unified_detachment_${state.$2}.png',
          ),
        );
        expect(
          find.byKey(const ValueKey('budget-unified-header-color-bleed')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      visual.dispose();
      colors.dispose();
    },
  );
  testWidgets(
    'enabled contours and every shadow style emerge from master progress',
    (tester) async {
      final borders = DashboardBorderController()
        ..setEnabled(DashboardBorderSurface.header, true)
        ..setEnabled(DashboardBorderSurface.budgetContent, true);
      final shadows = DashboardShadowStyleController();
      addTearDown(borders.dispose);
      addTearDown(shadows.dispose);
      for (final style in DashboardShadowStyle.values) {
        shadows.select(style);
        for (final travel in [0.0, .1, 9.0, 36.0, 90.0, 180.0]) {
          await tester.pumpWidget(
            MaterialApp(
              home: DashboardBorderScope(
                controller: borders,
                child: DashboardShadowStyleScope(
                  controller: shadows,
                  child: Scaffold(
                    body: RepaintBoundary(
                      key: capture,
                      child: SizedBox(
                        width: 412,
                        height: 700,
                        child: Stack(
                          children: [
                            BudgetDashboardCoreSurface(
                              presentation: DashboardCoreModePresentation(
                                geometry: frame(travel),
                                palette: DashboardModePaletteResolver.resolve(
                                  DashboardModeSpec.budget,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          final header = find.byKey(
            const ValueKey('dashboard-core-mode-budget-header'),
          );
          final material = tester.widget<FluviRoundedBox>(
            find
                .descendant(of: header, matching: find.byType(FluviRoundedBox))
                .first,
          );
          final expected = DashboardShadowProfile(
            style,
          ).shadowsFor(DashboardCornerSurfaceFamily.header);
          expect(material.boxShadow!.length, expected.length);
          for (var i = 0; i < expected.length; i++) {
            expect(
              material.boxShadow![i].color.a,
              closeTo(expected[i].color.a * travel / 180, 1e-8),
            );
            expect(material.boxShadow![i].blurRadius, expected[i].blurRadius);
          }
          final border = material.border!;
          final normal = DashboardBorderProfile(
            borders.value,
          ).borderFor(DashboardBorderSurface.header)!;
          expect(
            border.top.width,
            closeTo(normal.top.width * travel / 180, 1e-8),
          );
          if (style == DashboardShadowStyle.current && travel == .1) {
            await expectLater(
              find.byKey(capture),
              matchesGoldenFile(
                '../../../goldens/budget_unified_detachment_contours_first.png',
              ),
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
