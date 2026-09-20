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
    test('defaults retain only data-independent Mind presentation choices', () {
      final controller = MindYearHeatmapPresentationController();
      addTearDown(controller.dispose);

      expect(controller.value.paletteStyle, MindYearHeatmapPaletteStyle.fluvi);
      expect(
        controller.value.sumYearRowLayout,
        MindSumYearRowLayout.twoRowExpanded,
      );
      expect(
        controller.value.sumMonthLabelPlacement,
        MindSumMonthLabelPlacement.none,
      );
      expect(controller.value.revision, 0);
    });

    test('each independent presentation preference advances one revision', () {
      final controller = MindYearHeatmapPresentationController();
      addTearDown(controller.dispose);

      controller.setPaletteStyle(MindYearHeatmapPaletteStyle.b3mMy3);
      controller.setScaleResolution(MindHeatmapScaleResolution.twenty);
      controller.setSumYearRowLayout(MindSumYearRowLayout.oneRowCompact);
      controller.setSumMonthLabelPlacement(
        MindSumMonthLabelPlacement.insideMonthCells,
      );

      expect(controller.value.revision, 4);
      expect(controller.value.paletteStyle, MindYearHeatmapPaletteStyle.b3mMy3);
      expect(
        controller.value.scaleResolution,
        MindHeatmapScaleResolution.twenty,
      );
    });

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
      'SUM-DENSITY-SETTINGS RED: visible Sum yearly chart count defaults to two and stays presentation-only',
      () {
        final controller = MindYearHeatmapPresentationController();
        addTearDown(controller.dispose);

        expect(
          controller.value.sumVisibleChartCount,
          MindSumVisibleChartCount.two,
        );
        expect(controller.value.revision, 0);

        controller.setSumVisibleChartCount(MindSumVisibleChartCount.one);
        expect(
          controller.value.sumVisibleChartCount,
          MindSumVisibleChartCount.one,
        );
        expect(controller.value.revision, 1);

        controller.setSumVisibleChartCount(MindSumVisibleChartCount.one);
        expect(
          controller.value.revision,
          1,
          reason:
              'A repeated visual preference writes neither Query nor frame.',
        );
      },
    );

    test(
      'YEAR-PROFIT-SETTINGS RED: the 3x4 MonthCard tint preferences are revisioned presentation-only values',
      () {
        final controller = MindYearHeatmapPresentationController();
        addTearDown(controller.dispose);

        expect(
          controller.value.yearThreeColumnProfitabilityTintEnabled,
          isFalse,
        );
        expect(
          controller.value.yearThreeColumnProfitabilityTintOpacity,
          closeTo(.16, .0001),
        );

        controller.setYearThreeColumnProfitabilityTintEnabled(true);
        controller.setYearThreeColumnProfitabilityTintOpacity(.34);

        expect(
          controller.value.yearThreeColumnProfitabilityTintEnabled,
          isTrue,
        );
        expect(
          controller.value.yearThreeColumnProfitabilityTintOpacity,
          closeTo(.34, .0001),
        );
        expect(controller.value.revision, 2);
      },
    );

    test(
      'Y26-04/SUM-02 RED: MonthCard chrome and Sum curve choices are independently revisioned presentation state',
      () {
        final controller = MindYearHeatmapPresentationController();
        addTearDown(controller.dispose);

        expect(controller.value.yearMonthCardBorderEnabled, isTrue);
        expect(controller.value.yearMonthCardProfitabilityTintEnabled, isFalse);
        expect(
          controller.value.yearMonthCardProfitabilityTintOpacity,
          closeTo(.16, .0001),
        );
        expect(
          controller.value.sumLineInterpolationMode,
          MindSumLineInterpolationMode.linear,
        );
        expect(controller.value.sumLineTemporalSmoothingEnabled, isFalse);
        expect(controller.value.sumLineZoomAdaptiveSmoothingEnabled, isFalse);
        expect(
          controller.value.sumLineSmoothingWindow,
          MindSumSmoothingWindow.days3,
        );

        controller.setYearMonthCardBorderEnabled(false);
        controller.setYearMonthCardProfitabilityTintEnabled(true);
        controller.setYearMonthCardProfitabilityTintOpacity(.37);
        controller.setSumLineInterpolationMode(
          MindSumLineInterpolationMode.catmullRom,
        );
        controller.setSumLineCatmullRomTension(.62);
        controller.setSumLineTemporalSmoothingEnabled(true);
        controller.setSumLineSmoothingWindow(MindSumSmoothingWindow.days7);
        controller.setSumLineZoomAdaptiveSmoothingEnabled(true);

        expect(controller.value.yearMonthCardBorderEnabled, isFalse);
        expect(controller.value.yearMonthCardProfitabilityTintEnabled, isTrue);
        expect(
          controller.value.yearMonthCardProfitabilityTintOpacity,
          closeTo(.37, .0001),
        );
        expect(
          controller.value.sumLineInterpolationMode,
          MindSumLineInterpolationMode.catmullRom,
        );
        expect(controller.value.sumLineCatmullRomTension, closeTo(.62, .0001));
        expect(controller.value.sumLineTemporalSmoothingEnabled, isTrue);
        expect(
          controller.value.sumLineSmoothingWindow,
          MindSumSmoothingWindow.days7,
        );
        expect(controller.value.sumLineZoomAdaptiveSmoothingEnabled, isTrue);
        expect(
          controller.value.revision,
          8,
          reason: 'Each visual choice is independently revisioned only.',
        );
      },
    );
  });
}
