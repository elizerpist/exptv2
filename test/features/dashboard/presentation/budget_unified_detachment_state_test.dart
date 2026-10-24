import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_avatar_rail.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_pager.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';
import '../../../support/test_pump.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);
  for (final config in [
    (TimePlane.sum, false),
    (TimePlane.year, false),
    (TimePlane.month, false),
    (TimePlane.month, true),
  ]) {
    final plane = config.$1, daily = config.$2;
    testWidgets(
      '$plane daily=$daily reverse vertical input retains pager, scroll position and avatar state',
      (tester) async {
        final core = DashboardCoreController(
          initialCoreRevision: 1,
          initialDate: DateTime(2026, 7, 16),
          initialPlane: plane,
          initialRailOpen: daily,
        );
        final modes = DashboardCoreModeController(
          initialMode: DashboardModeSpec.budget,
        );
        addTearDown(core.dispose);
        addTearDown(modes.dispose);
        await core.bootstrap();
        await pumpDashboardSurface(
          tester,
          CoreDashboard(
            controller: core,
            modeController: modes,
            categoryCollection: emptyTestCategoryCollection,
          ),
        );
        await tester.pump();
        final pager = find.byType(BudgetDistributionPager);
        expect(pager, findsOneWidget);
        final pages = tester.widget<BudgetDistributionPager>(pager).controller;
        final pageView = find.descendant(
          of: pager,
          matching: find.byType(PageView),
        );
        final pagerState = tester.state(pager),
            pageState = tester.state(pageView);
        final position = pages.pageController.position;
        final avatar = find.byType(BudgetTargetAvatarRail);
        final avatarState = tester.state(avatar);
        pages.pageController.jumpToPage(pages.virtualIndex + 1);
        await tester.pump();
        await tester.pump();
        final index = pages.virtualIndex;
        void stable() {
          expect(tester.state(pager), same(pagerState));
          expect(tester.state(pageView), same(pageState));
          expect(
            tester.widget<BudgetDistributionPager>(pager).controller,
            same(pages),
          );
          expect(pages.pageController.position, same(position));
          expect(pages.pageController.page, closeTo(index.toDouble(), .01));
          expect(tester.state(avatar), same(avatarState));
          final body = tester.getRect(
            find.byKey(const ValueKey('budget-unified-moving-body')),
          );
          final chart = tester.getRect(
            find.byKey(const ValueKey('dashboard-core-mode-budget-card-2')),
          );
          expect(body.left, closeTo(chart.left, .001));
          expect(body.right, closeTo(chart.right, .001));
          expect(tester.takeException(), isNull);
        }

        core.expansion.beginDrag();
        for (final p in [
          0.0,
          .1,
          9.0,
          36.0,
          90.0,
          144.0,
          90.0,
          36.0,
          90.0,
          9.0,
          0.0,
        ]) {
          core.expansion.setProgress(p);
          await tester.pump();
          stable();
        }
        core.expansion.endDrag();
        await tester.pump();
        final gesture = await tester.startGesture(
          tester.getCenter(
            find.byKey(const ValueKey('dashboard-core-mode-budget-header')),
          ),
        );
        await gesture.moveBy(const Offset(0, -25));
        await tester.pump();
        await gesture.moveBy(const Offset(0, -36));
        await tester.pump();
        final partial = core.expansion.progress;
        expect(partial, greaterThan(0));
        stable();
        await gesture.moveBy(const Offset(0, 18));
        await tester.pump();
        expect(core.expansion.progress, lessThan(partial));
        stable();
        await gesture.up();
        await tester.pump();
        core.expansion.setProgress(0);
        await tester.pump();
        // A fresh horizontal gesture works immediately after repeated reversals.
        await tester.drag(pageView, const Offset(-260, 0));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        expect(pages.virtualIndex, greaterThan(index));
        expect(pages.pageController.position, same(position));
        expect(tester.state(pager), same(pagerState));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}
