import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';

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
          showYearMotherCardActions: false,
          balanceUsesChildCards: false,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final restored = DashboardPresentationPreferencesController(store: store);
      addTearDown(restored.dispose);
      await restored.restore();
      expect(restored.value.sumVisualStyle, MindSumVisualStyle.sumB);
      expect(restored.value.showSumLayoutChooser, isFalse);
      expect(restored.value.showYearMotherCardActions, isFalse);
      expect(restored.value.balanceUsesChildCards, isFalse);
    },
  );
}
