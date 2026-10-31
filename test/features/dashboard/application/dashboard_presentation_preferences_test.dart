import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_presentation_preferences.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';

void main() {
  test(
    'recurring UI choice persists independently from other dashboard presentation writes',
    () async {
      final store = InMemoryDashboardPresentationPreferencesStore();
      final controller = DashboardPresentationPreferencesController(
        store: store,
      );
      addTearDown(controller.dispose);

      controller.setPreferences(
        controller.value.withRecurringUiDesign(RecurringUiDesign.legacy),
      );
      controller.setPreferences(
        controller.value.withGhostQuickFilterPresentation(
          DashboardGhostQuickFilterPresentation.dropdown,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final restored = DashboardPresentationPreferencesController(store: store);
      addTearDown(restored.dispose);
      await restored.restore();
      expect(restored.value.recurringUiDesign, RecurringUiDesign.legacy);
      expect(
        restored.value.ghostQuickFilterPresentation,
        DashboardGhostQuickFilterPresentation.dropdown,
      );
    },
  );

  test('Header wave controls survive unrelated presentation writes', () async {
    final store = InMemoryDashboardPresentationPreferencesStore();
    final controller = DashboardPresentationPreferencesController(store: store);
    addTearDown(controller.dispose);

    controller.setPreferences(
      controller.value.withHeaderTapWaveControls(
        trailStrengthPercent: 300,
        tapStartSizePercent: 25,
        tapStrengthPercent: 0,
      ),
    );
    controller.setPreferences(
      controller.value.withGhostQuickFilterPresentation(
        DashboardGhostQuickFilterPresentation.summaryPillTrailingFling,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final restored = DashboardPresentationPreferencesController(store: store);
    addTearDown(restored.dispose);
    await restored.restore();
    expect(restored.value.headerTapWaveTrailStrengthPercent, 300);
    expect(restored.value.headerTapWaveTapStartSizePercent, 25);
    expect(restored.value.headerTapWaveTapStrengthPercent, 0);
    expect(
      restored.value.ghostQuickFilterPresentation,
      DashboardGhostQuickFilterPresentation.summaryPillTrailingFling,
    );
  });

  test(
    'push and recurring UI choices persist independently from each other',
    () async {
      final store = InMemoryDashboardPresentationPreferencesStore();
      final controller = DashboardPresentationPreferencesController(
        store: store,
      );
      addTearDown(controller.dispose);

      controller.setPreferences(
        controller.value.withPushProfileUiDesign(PushProfileUiDesign.legacy),
      );
      controller.setPreferences(
        controller.value.withRecurringUiDesign(RecurringUiDesign.legacy),
      );
      await Future<void>.delayed(Duration.zero);

      final restored = DashboardPresentationPreferencesController(store: store);
      addTearDown(restored.dispose);
      await restored.restore();
      expect(restored.value.pushProfileUiDesign, PushProfileUiDesign.legacy);
      expect(restored.value.recurringUiDesign, RecurringUiDesign.legacy);
    },
  );

  test(
    'Automation home UI choice persists independently from recurring and push choices',
    () async {
      final store = InMemoryDashboardPresentationPreferencesStore();
      final controller = DashboardPresentationPreferencesController(
        store: store,
      );
      addTearDown(controller.dispose);

      controller.setPreferences(
        controller.value.withAutomationHomeUiDesign(
          AutomationHomeUiDesign.legacy,
        ),
      );
      controller.setPreferences(
        controller.value.withRecurringUiDesign(RecurringUiDesign.legacy),
      );
      controller.setPreferences(
        controller.value.withPushProfileUiDesign(PushProfileUiDesign.unified),
      );
      await Future<void>.delayed(Duration.zero);

      final restored = DashboardPresentationPreferencesController(store: store);
      addTearDown(restored.dispose);
      await restored.restore();
      expect(
        restored.value.automationHomeUiDesign,
        AutomationHomeUiDesign.legacy,
      );
      expect(restored.value.recurringUiDesign, RecurringUiDesign.legacy);
      expect(restored.value.pushProfileUiDesign, PushProfileUiDesign.unified);
    },
  );

  test('a delayed restore cannot undo a current dashboard selection', () async {
    final store = _DelayedPreferencesStore();
    final controller = DashboardPresentationPreferencesController(store: store);
    addTearDown(controller.dispose);
    final restoring = controller.restore();
    controller.setPreferences(
      controller.value.withPushProfileUiDesign(PushProfileUiDesign.legacy),
    );
    store.complete(DashboardPresentationPreferences.defaults);
    await restoring;
    expect(controller.value.pushProfileUiDesign, PushProfileUiDesign.legacy);
  });

  test(
    'PRESENTATION-PREFERENCES-01 RED: visual choices restore and persist without owning financial state',
    () async {
      final store = InMemoryDashboardPresentationPreferencesStore();
      final controller = DashboardPresentationPreferencesController(
        store: store,
      );
      addTearDown(controller.dispose);

      expect(controller.value.sumVisualStyle, MindSumVisualStyle.sumA);
      controller.setPreferences(
        const DashboardPresentationPreferences(
          sumVisualStyle: MindSumVisualStyle.sumB,
          showSumLayoutChooser: false,
          yearGridLayout: MindYearHeatmapGridLayout.twoBySix,
          yearMonthlyAmountPresentation:
              MindYearMonthlyAmountPresentation.hidden,
          showDayContentViewChooser: true,
          balanceDayFocusedPresentation:
              BalanceDayFocusedPresentation.monthlyNetMarginImpact,
          balanceDayPerformanceVisualPresentation:
              BalanceDayPerformanceVisualPresentation.horizontalMeter,
          balanceDayRatioViewPresentation:
              BalanceDayRatioViewPresentation.performanceIndex,
          balanceDayRatioPresentation: BalanceDayRatioPresentation.netMargin,
          balanceUsesChildCards: false,
          balanceHeaderGraphPresentation:
              BalanceHeaderGraphPresentation.simpleIncomeExpensePartition,
          balanceMonthlySpendingChartPresentation:
              BalanceMonthlySpendingChartPresentation.reactiveSvg,
          balanceHeaderPartitionHeightPercent: 80,
          balanceMonthCombinedCardPresentation:
              BalanceMonthCombinedCardPresentation.spendingRhythm,
          balanceHeaderGlassConfigurationJson: '{"renderer":"glassKit"}',
          balanceHeaderPalette: DashboardBalanceHeaderPalette.b3mMy3,
          balanceHeaderPaletteVariant:
              DashboardBalanceHeaderPaletteVariant.original,
          balanceHeaderPalettePositionPercent: 73,
          balanceHeaderPaletteWindowWidthPercent: 41,
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
      expect(
        restored.value.balanceDayRatioPresentation,
        BalanceDayRatioPresentation.netMargin,
      );
      expect(
        restored.value.balanceDayRatioViewPresentation,
        BalanceDayRatioViewPresentation.performanceIndex,
      );
      expect(
        restored.value.balanceDayPerformanceVisualPresentation,
        BalanceDayPerformanceVisualPresentation.horizontalMeter,
      );
      expect(
        restored.value.balanceDayFocusedPresentation,
        BalanceDayFocusedPresentation.monthlyNetMarginImpact,
      );
      expect(restored.value.balanceUsesChildCards, isFalse);
      expect(
        restored.value.balanceHeaderGraphPresentation,
        BalanceHeaderGraphPresentation.simpleIncomeExpensePartition,
      );
      expect(
        restored.value.balanceMonthlySpendingChartPresentation,
        BalanceMonthlySpendingChartPresentation.reactiveSvg,
      );
      expect(restored.value.balanceHeaderPartitionHeightPercent, 80);
      expect(
        restored.value.balanceMonthCombinedCardPresentation,
        BalanceMonthCombinedCardPresentation.spendingRhythm,
      );
      expect(
        restored.value.balanceHeaderGlassConfigurationJson,
        '{"renderer":"glassKit"}',
      );
      expect(
        restored.value.balanceHeaderPalette,
        DashboardBalanceHeaderPalette.b3mMy3,
      );
      expect(
        restored.value.balanceHeaderPaletteVariant,
        DashboardBalanceHeaderPaletteVariant.original,
      );
      expect(restored.value.balanceHeaderPalettePositionPercent, 73);
      expect(restored.value.balanceHeaderPaletteWindowWidthPercent, 41);
    },
  );
}

final class _DelayedPreferencesStore
    implements DashboardPresentationPreferencesStore {
  final Completer<DashboardPresentationPreferences> _read = Completer();

  void complete(DashboardPresentationPreferences value) =>
      _read.complete(value);

  @override
  Future<DashboardPresentationPreferences> read() => _read.future;

  @override
  Future<void> write(DashboardPresentationPreferences preferences) async {}
}
