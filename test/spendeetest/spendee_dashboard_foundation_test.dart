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
    expect(geometry.stage1Height, 238);
    expect(geometry.stage2Height, 510);
    expect(geometry.contentTopFor(SpendeeHeaderStage.stage0), 212);
    expect(geometry.contentTopFor(SpendeeHeaderStage.stage1), 346);
    expect(geometry.contentTopFor(SpendeeHeaderStage.stage2), 618);
  });

  test('header stage controller arms ticks at exact C2 and C3 bottoms', () {
    final geometry = SpendeeHeaderStageGeometry.html(screenHeight: 892);
    final controller = SpendeeHeaderStageController(geometry: geometry);
    final stage1Trigger = geometry.stage1Height - geometry.stage0Height;
    final stage2Trigger = geometry.stage2Height - geometry.stage1Height;

    expect(controller.stage, SpendeeHeaderStage.stage0);
    expect(controller.currentHeight, 104);

    controller.beginDrag();
    var update = controller.dragBy(stage1Trigger - 1);
    expect(update.tick, isFalse);
    var release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage0);
    expect(release.springBack, isTrue);

    controller.beginDrag();
    update = controller.dragBy(stage1Trigger);
    expect(update.tick, isTrue);
    expect(update.height, geometry.stage1Height);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isFalse);

    controller.beginDrag();
    update = controller.dragBy(4);
    expect(update.tick, isTrue);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage0);
    expect(release.springBack, isTrue);

    controller.beginDrag();
    update = controller.dragBy(stage1Trigger + 12);
    expect(update.tick, isTrue);
    expect(update.height, greaterThan(geometry.stage1Height));
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isTrue);

    controller.beginDrag();
    update = controller.dragBy(stage2Trigger);
    expect(update.tick, isTrue);
    expect(update.height, geometry.stage2Height);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);
    expect(release.springBack, isFalse);

    controller.beginDrag();
    update = controller.dragBy(30);
    expect(update.tick, isTrue);
    expect(update.height, geometry.stage2Height + 18);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isTrue);

    controller.beginDrag();
    update = controller.dragBy(stage2Trigger + 8);
    expect(update.tick, isTrue);
    expect(update.height, greaterThan(geometry.stage2Height));
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);
    expect(release.springBack, isTrue);
  });

  test('one deep Stage 0 drag reports both lower haptic thresholds', () {
    final geometry = SpendeeHeaderStageGeometry.html(screenHeight: 892);
    final controller = SpendeeHeaderStageController(geometry: geometry);
    final directStage2Distance =
        (geometry.stage1Height - geometry.stage0Height) +
        (geometry.stage2Height - geometry.stage1Height);

    controller.beginDrag();
    final update = controller.dragBy(directStage2Distance);

    expect(update.tickCount, 2);
    expect(update.height, geometry.stage2Height);
    final release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);
    expect(release.springBack, isFalse);
  });

  test('Stage 0 drag just below direct Stage 2 threshold releases Stage 1', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );

    controller.beginDrag();
    final update = controller.dragBy(
      controller.stage0Stage2TriggerDistance - 1,
    );

    expect(update.tickCount, 1);
    expect(update.height, greaterThan(controller.geometry.stage1Height));
    final release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isTrue);
  });

  test('header controller keeps Stage 1 armed across positive drag frames', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );

    controller.beginDrag();
    expect(controller.dragBy(100).tick, isFalse);
    expect(controller.dragBy(34).tick, isTrue);
    expect(controller.dragBy(4).tick, isFalse);

    final release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isTrue);
  });

  test('header controller keeps Stage 2 armed across positive drag frames', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );
    controller.beginDrag();
    controller.dragBy(134);
    controller.release();

    controller.beginDrag();
    expect(controller.dragBy(100).tick, isTrue);
    expect(controller.dragBy(172).tick, isTrue);
    final overshoot = controller.dragBy(4);
    expect(overshoot.tick, isFalse);
    expect(overshoot.height, greaterThan(controller.geometry.stage2Height));

    final release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);
    expect(release.springBack, isTrue);
  });

  test('one large Stage 1 frame reports both crossed haptic thresholds', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );
    controller.beginDrag();
    controller.dragBy(134);
    controller.release();

    controller.beginDrag();
    final update = controller.dragBy(272);

    expect(update.tickCount, 2);
    expect(update.tick, isTrue);
    expect(controller.release().targetStage, SpendeeHeaderStage.stage2);
  });

  test('Stage 2 downward drag has a second tick that arms Stage 0', () {
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );
    controller.beginDrag();
    controller.dragBy(134);
    controller.release();
    controller.beginDrag();
    controller.dragBy(272);
    controller.release();
    expect(controller.stage, SpendeeHeaderStage.stage2);

    controller.beginDrag();
    final firstTick = controller.dragBy(18);
    expect(firstTick.tickCount, 1);
    var release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage1);
    expect(release.springBack, isTrue);

    controller.beginDrag();
    controller.dragBy(272);
    controller.release();

    controller.beginDrag();
    final secondTick = controller.dragBy(42);
    expect(secondTick.tickCount, 2);
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage0);
    expect(release.springBack, isTrue);
  });

  test(
    'header controller disarms Stage 1 after reversing below its trigger',
    () {
      final controller = SpendeeHeaderStageController(
        geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
      );

      controller.beginDrag();
      controller.dragBy(100);
      expect(controller.dragBy(34).tick, isTrue);
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
      controller.dragBy(134);
      controller.release();

      controller.beginDrag();
      controller.dragBy(100);
      expect(controller.dragBy(172).tick, isTrue);
      controller.dragBy(-2);

      final release = controller.release();
      expect(release.targetStage, SpendeeHeaderStage.stage0);
      expect(release.springBack, isTrue);
    },
  );

  test(
    'header controller preserves settled Stage 1 across geometry changes',
    () {
      final controller = SpendeeHeaderStageController(
        geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
      );
      controller.beginDrag();
      controller.dragBy(134);
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
      controller.dragBy(134);
      controller.release();
      controller.beginDrag();
      controller.dragBy(272);
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

  test('geometry changes re-evaluate an armed positive drag offset', () {
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
    controller.dragBy(100);
    expect(controller.dragBy(34).tick, isTrue);

    controller.replaceGeometry(replacement);

    expect(controller.stage, SpendeeHeaderStage.stage0);
    expect(controller.currentHeight, replacement.stage0Height + 134);
    expect(controller.dragBy(4).tick, isFalse);
    expect(controller.release().targetStage, SpendeeHeaderStage.stage0);
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
    controller.dragBy(100);
    expect(controller.dragBy(34).tick, isTrue);
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

  test(
    'center carousel release settle nudges near-boundary snaps into a tick',
    () {
      final controller = SpendeeCenterCarouselController(itemCount: 5);
      controller.applyDragDelta(-46);

      final motion = controller.releaseMotion(
        velocityDx: -545,
        liveTicked: false,
      );
      expect(motion.initialTravel, closeTo(-18, .001));

      final underAppliedTravel = motion.initialTravel + .05;
      final underAppliedUpdate = controller.applyDragDelta(underAppliedTravel);
      expect(underAppliedUpdate.tickedIndexes, isEmpty);
      expect(controller.residualDx, closeTo(-63.95, .001));

      final settleTravel = controller.settleTravel(
        preferredDxDirection: motion.preferredDxDirection,
        allowDirectionalSnap: motion.directionalSnapAllowed,
      );
      expect(settleTravel.abs(), greaterThanOrEqualTo(.5));

      final settledUpdate = controller.applyDragDelta(settleTravel);
      expect(settledUpdate.tickedIndexes, [1]);
      expect(settledUpdate.residualDx.abs(), lessThan(1));
    },
  );
}
