import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_collapse_controller.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B3M-A3 two-state collapse controller', () {
    test('has exactly expanded and collapsed stable endpoints', () {
      final controller = SpendeeBalanceCollapseController();

      expect(controller.state, SpendeeBalanceCollapseState.expanded);
      expect(controller.offset, 0);
      expect(controller.progress, 0);

      controller.jumpTo(SpendeeBalanceCollapseController.maxOffset);

      expect(controller.state, SpendeeBalanceCollapseState.collapsed);
      expect(controller.offset, SpendeeBalanceCollapseController.maxOffset);
      expect(controller.progress, 1);
    });

    test('direct finger follow clamps to the frozen 180px path', () {
      final controller = SpendeeBalanceCollapseController();

      controller.beginDrag();
      controller.dragBy(-72);

      expect(controller.offset, 72);
      expect(controller.progress, closeTo(.4, 1e-9));
      expect(controller.state, SpendeeBalanceCollapseState.collapsing);

      controller.dragBy(-200);
      expect(controller.offset, 180);
      expect(controller.progress, 1);

      controller.dragBy(400);
      expect(controller.offset, 0);
      expect(controller.progress, 0);
    });

    test('release uses the exact 50 percent snap threshold', () {
      final controller = SpendeeBalanceCollapseController();

      controller
        ..beginDrag()
        ..dragBy(-89.99);
      expect(controller.release(), SpendeeBalanceCollapseTarget.expanded);

      controller
        ..jumpTo(0)
        ..beginDrag()
        ..dragBy(-90);
      expect(controller.release(), SpendeeBalanceCollapseTarget.collapsed);
    });

    test('collapsed drag reverses over the same path', () {
      final controller = SpendeeBalanceCollapseController()
        ..jumpTo(SpendeeBalanceCollapseController.maxOffset)
        ..beginDrag()
        ..dragBy(54);

      expect(controller.offset, 126);
      expect(controller.progress, closeTo(.7, 1e-9));
      expect(controller.release(), SpendeeBalanceCollapseTarget.collapsed);

      controller
        ..jumpTo(180)
        ..beginDrag()
        ..dragBy(91);
      expect(controller.release(), SpendeeBalanceCollapseTarget.expanded);
    });

    test('toggle always targets the opposite stable endpoint', () {
      final controller = SpendeeBalanceCollapseController();

      expect(controller.toggleTarget, SpendeeBalanceCollapseTarget.collapsed);
      controller.jumpTo(180);
      expect(controller.toggleTarget, SpendeeBalanceCollapseTarget.expanded);

      controller.jumpTo(72);
      expect(controller.toggleTarget, SpendeeBalanceCollapseTarget.collapsed);
      controller.jumpTo(108);
      expect(controller.toggleTarget, SpendeeBalanceCollapseTarget.expanded);
    });
  });

  group('B3M-A3 collapse visual cascade', () {
    test('expanded, midpoint and collapsed values match frozen JS', () {
      final expanded = SpendeeBalanceCollapseVisuals.forProgress(0);
      final midpoint = SpendeeBalanceCollapseVisuals.forProgress(.5);
      final collapsed = SpendeeBalanceCollapseVisuals.forProgress(1);

      expect(expanded.heroHeight, 126);
      expect(expanded.insightOpacity, 1);
      expect(expanded.insightScale, 1);
      expect(expanded.insightTranslateY, 0);
      expect(expanded.detailOpacity, 1);
      expect(expanded.detailScale, 1);
      expect(expanded.detailTranslateY, 0);
      expect(expanded.heroStatsOpacity, 1);
      expect(expanded.heroStatsTranslateY, 0);
      expect(expanded.scrollContentTranslateY, 0);
      expect(expanded.postTranslateY, 0);

      final midpointInsight = ((.5 - .03) / .62).clamp(0.0, 1.0);
      final midpointDetail = ((.5 - .16) / .62).clamp(0.0, 1.0);
      final midpointStats = 1 - ((.5 - .08) / .52).clamp(0.0, 1.0);
      expect(midpoint.heroHeight, 115);
      expect(midpoint.insightOpacity, closeTo(1 - midpointInsight, 1e-9));
      expect(midpoint.insightScale, closeTo(1 - .1 * midpointInsight, 1e-9));
      expect(midpoint.insightTranslateY, closeTo(-18 * midpointInsight, 1e-9));
      expect(midpoint.detailOpacity, closeTo(1 - midpointDetail, 1e-9));
      expect(midpoint.detailScale, closeTo(1 - .04 * midpointDetail, 1e-9));
      expect(midpoint.detailTranslateY, closeTo(-24 * midpointDetail, 1e-9));
      expect(midpoint.heroStatsOpacity, closeTo(midpointStats, 1e-9));
      expect(
        midpoint.heroStatsTranslateY,
        closeTo(10 * (1 - midpointStats), 1e-9),
      );
      expect(midpoint.scrollContentTranslateY, -101);
      final midpointPostShift =
          -(SpendeeBalanceVisualSpec.insightHeight +
              SpendeeBalanceVisualSpec.stackGap * 2 +
              SpendeeBalanceVisualSpec.detailStageHeight -
              SpendeeBalanceCollapseController.maxOffset * .5 +
              SpendeeBalanceVisualSpec.stackGap -
              SpendeeBalanceVisualSpec.stackGap);
      expect(
        midpoint.postTranslateY,
        closeTo(midpointPostShift * midpointDetail, 1e-9),
      );

      expect(collapsed.heroHeight, 104);
      expect(collapsed.insightOpacity, 0);
      expect(collapsed.insightScale, .9);
      expect(collapsed.insightTranslateY, -18);
      expect(collapsed.detailOpacity, 0);
      expect(collapsed.detailScale, .96);
      expect(collapsed.detailTranslateY, -24);
      expect(collapsed.heroStatsOpacity, 0);
      expect(collapsed.heroStatsTranslateY, 10);
      expect(collapsed.scrollContentTranslateY, -202);
      final collapsedPostShift =
          -(SpendeeBalanceVisualSpec.insightHeight +
              SpendeeBalanceVisualSpec.stackGap * 2 +
              SpendeeBalanceVisualSpec.detailStageHeight -
              SpendeeBalanceCollapseController.maxOffset);
      expect(collapsed.postTranslateY, collapsedPostShift);
    });

    test('progress is clamped and pointer thresholds follow frozen JS', () {
      final before = SpendeeBalanceCollapseVisuals.forProgress(-2);
      final after = SpendeeBalanceCollapseVisuals.forProgress(3);

      expect(before.progress, 0);
      expect(after.progress, 1);
      expect(before.insightsInteractive, isTrue);
      expect(before.detailsInteractive, isTrue);
      expect(after.insightsInteractive, isFalse);
      expect(after.detailsInteractive, isFalse);

      expect(
        SpendeeBalanceCollapseVisuals.forOffset(112).insightsInteractive,
        isTrue,
      );
      expect(
        SpendeeBalanceCollapseVisuals.forOffset(113).insightsInteractive,
        isFalse,
      );
      expect(
        SpendeeBalanceCollapseVisuals.forOffset(135).detailsInteractive,
        isTrue,
      );
      expect(
        SpendeeBalanceCollapseVisuals.forOffset(136).detailsInteractive,
        isFalse,
      );
    });

    test('post flow matches the five frozen DOM collapse samples', () {
      const samples = <double>[0, .25, .5, .75, 1];

      for (final progress in samples) {
        final visuals = SpendeeBalanceCollapseVisuals.forProgress(progress);
        final expectedFlow =
            -(SpendeeBalanceCollapseController.maxOffset + 22) * progress;
        final detailProgress = ((progress - .16) / .62).clamp(0.0, 1.0);
        final sourcePostShift =
            -(SpendeeBalanceVisualSpec.insightHeight +
                SpendeeBalanceVisualSpec.stackGap * 2 +
                SpendeeBalanceVisualSpec.detailStageHeight -
                SpendeeBalanceCollapseController.maxOffset * progress +
                SpendeeBalanceVisualSpec.stackGap -
                SpendeeBalanceVisualSpec.stackGap);
        final expectedActionY =
            SpendeeBalanceVisualSpec.actionTop +
            expectedFlow +
            sourcePostShift * detailProgress;
        expect(
          visuals.scrollContentTranslateY,
          closeTo(expectedFlow, .001),
          reason: 'flow at progress $progress',
        );
        expect(
          SpendeeBalanceVisualSpec.actionTop +
              visuals.scrollContentTranslateY +
              visuals.postTranslateY,
          closeTo(expectedActionY, .05),
          reason: 'action y at progress $progress',
        );
      }
    });
  });
}
