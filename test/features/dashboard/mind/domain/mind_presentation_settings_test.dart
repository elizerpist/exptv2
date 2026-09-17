import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';

void main() {
  group('Mind behavioural score settings', () {
    test('defaults to causal trailing with full filtered history', () {
      final controller = MindBehavioralScoreSettingsController();
      addTearDown(controller.dispose);

      expect(
        controller.value.expenseAlgorithm,
        MindExpenseScoreAlgorithm.causalTrailing,
      );
      expect(
        controller.value.causalHistoryOrigin,
        MindCausalHistoryOrigin.fullFilteredHistory,
      );
      expect(controller.value.revision, 0);
    });

    test(
      'publishes a new semantic revision only for a real setting change',
      () {
        final controller = MindBehavioralScoreSettingsController();
        addTearDown(controller.dispose);
        var notifications = 0;
        controller.addListener(() => notifications += 1);

        controller.setExpenseAlgorithm(MindExpenseScoreAlgorithm.htmlCentered);
        expect(controller.value.revision, 1);
        expect(notifications, 1);

        controller.setExpenseAlgorithm(MindExpenseScoreAlgorithm.htmlCentered);
        expect(controller.value.revision, 1);
        expect(notifications, 1);

        controller.setCausalHistoryOrigin(
          MindCausalHistoryOrigin.selectedScopeStart,
        );
        expect(controller.value.revision, 2);
        expect(notifications, 2);
      },
    );
  });

  group('Mind Year heatmap presentation settings', () {
    test('defaults preserve the accepted Fluvi three-by-four presentation', () {
      final controller = MindYearHeatmapPresentationController();
      addTearDown(controller.dispose);

      expect(controller.value.paletteStyle, MindYearHeatmapPaletteStyle.fluvi);
      expect(
        controller.value.monthCardLayout,
        MindYearMonthCardLayout.threeColumns,
      );
      expect(controller.value.showMonthlyNetClose, isFalse);
      expect(controller.value.showMonthlyDirectionTotal, isFalse);
      expect(controller.value.revision, 0);
    });

    test('each independent presentation preference advances one revision', () {
      final controller = MindYearHeatmapPresentationController();
      addTearDown(controller.dispose);

      controller.setPaletteStyle(MindYearHeatmapPaletteStyle.b3mMy3);
      controller.setMonthCardLayout(MindYearMonthCardLayout.twoColumns);
      controller.setShowMonthlyNetClose(true);
      controller.setShowMonthlyDirectionTotal(true);

      expect(controller.value.revision, 4);
      expect(controller.value.paletteStyle, MindYearHeatmapPaletteStyle.b3mMy3);
      expect(
        controller.value.monthCardLayout,
        MindYearMonthCardLayout.twoColumns,
      );
      expect(controller.value.showMonthlyNetClose, isTrue);
      expect(controller.value.showMonthlyDirectionTotal, isTrue);
    });
  });
}
