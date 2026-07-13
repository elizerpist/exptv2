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
    update = controller.dragBy(30);
    expect(update.tick, isTrue);
    expect(update.height, geometry.stage2Height + 18);
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

  test('header controller keeps Stage 1 armed across positive drag frames', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );

    controller.beginDrag();
    expect(controller.dragBy(40).tick, isFalse);
    expect(controller.dragBy(40).tick, isTrue);
    expect(controller.dragBy(4).tick, isFalse);

    final release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isFalse);
  });

  test('header controller keeps Stage 2 armed across positive drag frames', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );
    controller.beginDrag();
    controller.dragBy(90);
    controller.release();

    controller.beginDrag();
    expect(controller.dragBy(100).tick, isTrue);
    expect(controller.dragBy(121).tick, isTrue);
    expect(controller.dragBy(4).tick, isFalse);

    final release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);
    expect(release.springBack, isFalse);
  });

  test(
    'header controller disarms Stage 1 after reversing below its trigger',
    () {
      final controller = SpendeeHeaderStageController(
        geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
      );

      controller.beginDrag();
      controller.dragBy(40);
      expect(controller.dragBy(40).tick, isTrue);
      controller.dragBy(-20);

      final release = controller.release();
      expect(release.targetStage, SpendeeHeaderStage.stage0);
      expect(release.springBack, isTrue);
    },
  );

  test(
    'header controller disarms Stage 2 after reversing below its trigger',
    () {
      final controller = SpendeeHeaderStageController(
        geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
      );
      controller.beginDrag();
      controller.dragBy(90);
      controller.release();

      controller.beginDrag();
      controller.dragBy(100);
      expect(controller.dragBy(121).tick, isTrue);
      controller.dragBy(-2);

      final release = controller.release();
      expect(release.targetStage, SpendeeHeaderStage.stage0);
      expect(release.springBack, isFalse);
    },
  );

  test(
    'header controller preserves settled Stage 1 across geometry changes',
    () {
      final controller = SpendeeHeaderStageController(
        geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
      );
      controller.beginDrag();
      controller.dragBy(90);
      controller.release();
      const replacement = SpendeeHeaderStageGeometry(
        headerTop: 110,
        stage0Height: 120,
        stage1Height: 320,
        stage2Height: 640,
        contentGap: 6,
      );

      controller.replaceGeometry(replacement);

      expect(controller.geometry, same(replacement));
      expect(controller.stage, SpendeeHeaderStage.stage1);
      expect(controller.currentHeight, replacement.stage1Height);
    },
  );

  test(
    'header controller preserves settled Stage 2 across geometry changes',
    () {
      final controller = SpendeeHeaderStageController(
        geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
      );
      controller.beginDrag();
      controller.dragBy(90);
      controller.release();
      controller.beginDrag();
      controller.dragBy(230);
      controller.release();
      const replacement = SpendeeHeaderStageGeometry(
        headerTop: 110,
        stage0Height: 120,
        stage1Height: 320,
        stage2Height: 640,
        contentGap: 6,
      );

      controller.replaceGeometry(replacement);

      expect(controller.geometry, same(replacement));
      expect(controller.stage, SpendeeHeaderStage.stage2);
      expect(controller.currentHeight, replacement.stage2Height);
    },
  );

  test('geometry changes preserve an armed positive drag offset', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );
    const replacement = SpendeeHeaderStageGeometry(
      headerTop: 110,
      stage0Height: 120,
      stage1Height: 320,
      stage2Height: 640,
      contentGap: 6,
    );
    controller.beginDrag();
    controller.dragBy(40);
    expect(controller.dragBy(40).tick, isTrue);

    controller.replaceGeometry(replacement);

    expect(controller.stage, SpendeeHeaderStage.stage0);
    expect(controller.currentHeight, replacement.stage0Height + 80);
    expect(controller.dragBy(4).tick, isFalse);
    expect(controller.release().targetStage, SpendeeHeaderStage.stage1);
  });

  test('geometry changes preserve a negative drag offset', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );
    const replacement = SpendeeHeaderStageGeometry(
      headerTop: 110,
      stage0Height: 120,
      stage1Height: 320,
      stage2Height: 640,
      contentGap: 6,
    );
    controller.beginDrag();
    expect(controller.dragBy(-20).height, controller.geometry.stage0Height);

    controller.replaceGeometry(replacement);
    final update = controller.dragBy(80);

    expect(update.height, replacement.stage0Height + 60);
    expect(update.tick, isFalse);
    expect(controller.release().targetStage, SpendeeHeaderStage.stage0);
  });

  test('threshold ticks are scoped to one pointer sequence', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );
    controller.beginDrag();
    controller.dragBy(40);
    expect(controller.dragBy(40).tick, isTrue);
    expect(controller.dragBy(-20).tick, isFalse);
    expect(controller.dragBy(20).tick, isFalse);
    expect(controller.release().targetStage, SpendeeHeaderStage.stage1);

    controller.beginDrag();
    expect(controller.dragBy(1).tick, isTrue);
    controller.dragBy(-1);
    controller.release();

    controller.beginDrag();
    expect(controller.dragBy(1).tick, isTrue);
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
