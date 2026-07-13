import 'package:exptv2/core/theme/category_color_manager.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_center_carousel_controller.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_header_stage_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme settings persist the experimental dashboard design mode', () {
    final settings = AppThemeSettings.defaults().copyWith(
      dashboardDesignMode: DashboardDesignMode.spendeeTest,
    );

    expect(settings.dashboardDesignMode, DashboardDesignMode.spendeeTest);
    expect(settings.toMap()['dashboardDesignMode'], 'spendeeTest');

    final restored = AppThemeSettings.fromMap(settings.toMap());
    expect(restored.dashboardDesignMode, DashboardDesignMode.spendeeTest);
  });

  test('category color manager exposes HTML Spendee gradient slots', () {
    final slot0 = CategoryColorManager.gradientStops(0);
    final slot20 = CategoryColorManager.gradientStops(20);

    expect(slot0.map(CategoryColorManager.toHex), [
      '#ff3b4f',
      '#ff5268',
      '#ff6b7d',
    ]);
    expect(slot20.map(CategoryColorManager.toHex), [
      '#e43ec4',
      '#f04ab6',
      '#fb56a8',
    ]);
    expect(
      CategoryColorManager.toHex(CategoryColorManager.color(20)),
      '#f04ab6',
    );
  });

  test('HTML C-header geometry matches the Color Lab C1-C3 constants', () {
    final geometry = SpendeeHeaderStageGeometry.html(screenHeight: 892);

    expect(geometry.headerTop, 104);
    expect(geometry.stage0Height, 104);
    expect(geometry.stage1Height, 284);
    expect(geometry.stage2Height, 584);
    expect(geometry.contentTopFor(SpendeeHeaderStage.stage0), 212);
    expect(geometry.contentTopFor(SpendeeHeaderStage.stage1), 392);
    expect(geometry.contentTopFor(SpendeeHeaderStage.stage2), 692);
  });

  test('header stage controller arms ticks and snaps between C1-C3 stages', () {
    final geometry = SpendeeHeaderStageGeometry.html(screenHeight: 892);
    final controller = SpendeeHeaderStageController(geometry: geometry);

    expect(controller.stage, SpendeeHeaderStage.stage0);
    expect(controller.currentHeight, 104);

    controller.beginDrag();
    var update = controller.dragBy(50);
    expect(update.tick, isFalse);
    var release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage0);
    expect(release.springBack, isTrue);

    controller.beginDrag();
    update = controller.dragBy(90);
    expect(update.tick, isTrue);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isFalse);

    controller.beginDrag();
    update = controller.dragBy(4);
    expect(update.tick, isTrue);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage0);
    expect(release.springBack, isFalse);

    controller.beginDrag();
    update = controller.dragBy(90);
    expect(update.tick, isTrue);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);

    controller.beginDrag();
    update = controller.dragBy(12);
    expect(update.tick, isTrue);
    expect(update.height, greaterThan(geometry.stage1Height));
    update = controller.dragBy(-12);
    expect(update.height, geometry.stage1Height);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isTrue);

    controller.beginDrag();
    update = controller.dragBy(230);
    expect(update.tick, isTrue);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);
    expect(release.springBack, isFalse);

    controller.beginDrag();
    update = controller.dragBy(8);
    expect(update.tick, isTrue);
    expect(update.height, greaterThan(geometry.stage2Height));
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isFalse);

    controller.beginDrag();
    update = controller.dragBy(230);
    expect(update.tick, isTrue);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);

    controller.beginDrag();
    update = controller.dragBy(8);
    expect(update.tick, isTrue);
    update = controller.dragBy(-8);
    expect(update.height, geometry.stage2Height);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);
    expect(release.springBack, isTrue);
  });

  test(
    'center carousel controller ports backheader belt inertia and ticks',
    () {
      final controller = SpendeeCenterCarouselController(itemCount: 5);

      final update = controller.applyDragDelta(-130);
      expect(update.index, 2);
      expect(update.residualDx, -2);
      expect(update.tickedIndexes, [1, 2]);

      final plan = controller.releasePlan(velocityDx: -2600);
      expect(plan.swipedLeft, isTrue);
      expect(plan.distanceSteps, 2);
      expect(plan.velocitySteps, 2);
      expect(plan.steps, 4);
    },
  );
}
