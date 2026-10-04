import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_partition_lane_geometry.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_budget_header_presentation.dart';

void main() {
  test(
    'Budget Header partition slider is a percentage of the exact baseline',
    () {
      DashboardBudgetHeaderPresentationProfile profile(double percent) =>
          DashboardBudgetHeaderPresentationProfile(
            DashboardBudgetHeaderPresentationSettings(
              partitionHeightPercent: percent,
            ),
          );

      expect(profile(0).partitionThickness, 7);
      expect(profile(50).partitionThickness, 10.5);
      expect(profile(100).partitionThickness, 14);
      expect(profile(0).partitionBottomInset, 4);
      expect(profile(50).partitionBottomInset, 2.25);
      expect(profile(100).partitionBottomInset, .5);
    },
  );

  test(
    'Budget Header foreground setting is paint-only and clamps slider input',
    () {
      final controller = DashboardBudgetHeaderPresentationController();
      addTearDown(controller.dispose);

      controller
        ..setPartitionHeightPercent(140)
        ..selectForeground(DashboardBudgetHeaderForeground.white);
      var profile = DashboardBudgetHeaderPresentationProfile(controller.value);
      expect(profile.partitionThickness, 14);
      expect(profile.foreground, FluviVisualTokens.textOnAction);

      controller
        ..setPartitionHeightPercent(-51)
        ..selectForeground(DashboardBudgetHeaderForeground.black);
      profile = DashboardBudgetHeaderPresentationProfile(controller.value);
      expect(controller.value.partitionHeightPercent, -50);
      expect(profile.partitionThickness, 3.5);
      expect(profile.foreground, FluviVisualTokens.textPrimary);
    },
  );

  test(
    'Budget Header partition-height slider admits a lower authored minimum',
    () {
      final controller = DashboardBudgetHeaderPresentationController();
      addTearDown(controller.dispose);

      controller.setPartitionHeightPercent(-50);
      final profile = DashboardBudgetHeaderPresentationProfile(
        controller.value,
      );

      expect(controller.value.partitionHeightPercent, -50);
      expect(profile.partitionThickness, 3.5);
      expect(
        profile.partitionThickness,
        lessThan(DashboardPartitionLaneGeometry.baselineThickness),
      );
    },
  );

  test(
    'partition contour and text contrast default to the baseline and reset',
    () {
      final controller = DashboardBudgetHeaderPresentationController();
      addTearDown(controller.dispose);

      expect(controller.value.showPartitionContour, isFalse);
      expect(
        controller.value.textContrastStyle,
        DashboardHeaderTextContrastStyle.none,
      );

      controller
        ..setPartitionContour(true)
        ..selectTextContrastStyle(
          DashboardHeaderTextContrastStyle.oppositeOutline,
        );
      expect(controller.value.showPartitionContour, isTrue);
      expect(
        controller.value.textContrastStyle,
        DashboardHeaderTextContrastStyle.oppositeOutline,
      );

      controller.reset();
      expect(
        controller.value,
        DashboardBudgetHeaderPresentationSettings.defaults,
      );
    },
  );
}
