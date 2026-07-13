import 'package:exptv2/core/theme/category_color_manager.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
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
    final controller = SpendeeHeaderStageController(
      geometry: SpendeeHeaderStageGeometry.html(screenHeight: 892),
    );

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
    release = controller.release();
    expect(release.targetStage, SpendeeHeaderStage.stage2);
    expect(release.springBack, isTrue);
  });
}
