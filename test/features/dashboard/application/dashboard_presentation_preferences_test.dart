import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';

void main() {
  test(
    'PRESENTATION-PREFERENCES-01 RED: visual choices restore and persist without owning financial state',
    () async {
      final store = InMemoryDashboardPresentationPreferencesStore();
      final controller = DashboardPresentationPreferencesController(
        store: store,
      );
      addTearDown(controller.dispose);

      expect(controller.value.sumVisualStyle, MindSumVisualStyle.current);
      controller.setPreferences(
        const DashboardPresentationPreferences(
          sumVisualStyle: MindSumVisualStyle.sumB,
          showSumLayoutChooser: false,
          yearGridLayout: MindYearHeatmapGridLayout.twoBySix,
          yearMonthlyAmountPresentation:
              MindYearMonthlyAmountPresentation.hidden,
          showDayContentViewChooser: true,
          balanceUsesChildCards: false,
          balanceHeaderGraphPresentation:
              BalanceHeaderGraphPresentation.incomeExpensePartition,
          balanceHeaderPartitionHeightPercent: 80,
          balanceMonthCombinedCardPresentation:
              BalanceMonthCombinedCardPresentation.spendingRhythm,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final restored = DashboardPresentationPreferencesController(store: store);
      addTearDown(restored.dispose);
      await restored.restore();
      expect(restored.value.sumVisualStyle, MindSumVisualStyle.sumB);
      expect(restored.value.showSumLayoutChooser, isFalse);
      expect(restored.value.yearGridLayout, MindYearHeatmapGridLayout.twoBySix);
      expect(
        restored.value.yearMonthlyAmountPresentation,
        MindYearMonthlyAmountPresentation.hidden,
      );
      expect(restored.value.showDayContentViewChooser, isTrue);
      expect(restored.value.balanceUsesChildCards, isFalse);
      expect(
        restored.value.balanceHeaderGraphPresentation,
        BalanceHeaderGraphPresentation.incomeExpensePartition,
      );
      expect(restored.value.balanceHeaderPartitionHeightPercent, 80);
      expect(
        restored.value.balanceMonthCombinedCardPresentation,
        BalanceMonthCombinedCardPresentation.spendingRhythm,
      );
    },
  );
}
