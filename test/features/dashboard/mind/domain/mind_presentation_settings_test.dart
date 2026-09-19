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
      expect(
        controller.value.annualSurfaceStyle,
        MindYearHeatmapAnnualSurfaceStyle.monthCards,
        reason:
            'The accepted MonthCard shell remains the conservative default.',
      );
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

    test(
      'HMP-SET-01: annual surface remains an independent presentation preference',
      () {
        final controller = MindYearHeatmapPresentationController();
        addTearDown(controller.dispose);
        controller.setAnnualSurfaceStyle(
          MindYearHeatmapAnnualSurfaceStyle.directCells,
        );
        expect(
          controller.value.annualSurfaceStyle,
          MindYearHeatmapAnnualSurfaceStyle.directCells,
        );
        expect(controller.value.revision, 1);

        controller.setAnnualSurfaceStyle(
          MindYearHeatmapAnnualSurfaceStyle.directCells,
        );
        expect(controller.value.revision, 1);
      },
    );

    test(
      'PAL-REDUCE-01: exactly five approved product palettes are selectable',
      () {
        expect(
          MindYearHeatmapPaletteStyle.values.map((style) => style.name),
          <String>[
            'fluvi',
            'b3mMy3',
            'meadowGreen',
            'fluviStretched',
            'b3mMy3Stretched',
          ],
        );
      },
    );

    test(
      'SCALE-01 RED: scale resolution defaults to ten and changes one presentation revision only when real',
      () {
        final controller = MindYearHeatmapPresentationController();
        addTearDown(controller.dispose);

        expect(
          controller.value.scaleResolution,
          MindHeatmapScaleResolution.ten,
        );
        expect(controller.value.revision, 0);

        controller.setScaleResolution(MindHeatmapScaleResolution.twenty);
        expect(
          controller.value.scaleResolution,
          MindHeatmapScaleResolution.twenty,
        );
        expect(controller.value.revision, 1);

        controller.setScaleResolution(MindHeatmapScaleResolution.twenty);
        expect(controller.value.revision, 1);
      },
    );

    test(
      'SUM-PRESENT-01 RED: Sum year layout and month-label placement are presentation-only revisioned choices',
      () {
        final controller = MindYearHeatmapPresentationController();
        addTearDown(controller.dispose);

        expect(
          controller.value.sumYearRowLayout,
          MindSumYearRowLayout.twoRowExpanded,
        );
        expect(
          controller.value.sumMonthLabelPlacement,
          MindSumMonthLabelPlacement.none,
        );
        expect(controller.value.revision, 0);

        controller.setSumYearRowLayout(MindSumYearRowLayout.oneRowCompact);
        controller.setSumMonthLabelPlacement(
          MindSumMonthLabelPlacement.insideMonthCells,
        );
        expect(controller.value.revision, 2);

        controller.setSumYearRowLayout(MindSumYearRowLayout.oneRowCompact);
        controller.setSumMonthLabelPlacement(
          MindSumMonthLabelPlacement.insideMonthCells,
        );
        expect(controller.value.revision, 2);
      },
    );

    test(
      'YEAR-HEIGHT-01 RED: the two-footer annual fit guard is shared by every column layout',
      () {
        const base = MindYearHeatmapPresentationSettings.defaults();
        expect(base.requiredMindModeContentExtraHeight, 0);

        for (final layout in MindYearMonthCardLayout.values) {
          final twoFooter = base.copyWith(
            monthCardLayout: layout,
            showMonthlyNetClose: true,
            showMonthlyDirectionTotal: true,
          );
          expect(
            twoFooter.requiredMindModeContentExtraHeight,
            15,
            reason:
                'The measured compact Mind viewport lacks exactly 15px for '
                'the fixed two-footer MonthCard chrome; this must never be a '
                'four-column-only envelope.',
          );
        }
      },
    );
  });
}
