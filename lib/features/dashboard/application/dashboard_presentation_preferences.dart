import 'dart:async';

import 'package:flutter/foundation.dart';

import 'balance_daily_calculation_mode.dart';
import '../mind/domain/mind_year_heatmap_presentation_settings.dart';
import '../presentation/core_modes/balance_presentation_settings.dart';
import '../presentation/core_modes/dashboard_header_balance_color_scale.dart';

/// Visual-only package for the three-state ghost quick filter. It is
/// deliberately separate from the query mode and never changes membership.
enum DashboardGhostQuickFilterIconPack { current, receiptGhost }

/// Presentation-only shape of the dashboard ghost quick filter.  This is
/// intentionally independent from [GhostFilterMode]: changing it must never
/// alter the active query membership.
enum DashboardGhostQuickFilterPresentation {
  current,
  dropdown,
  rail,
  searchPillFling,
  summaryPillLeadingFling,
  summaryPillTrailingFling,
}

/// Chooses only the recurring-transaction surface family. It deliberately
/// carries no rule, scheduler, query or financial state.
enum RecurringUiDesign { legacy, unified }

/// Chooses only the push-profile surface family. Like [RecurringUiDesign],
/// this is visual/navigation state and must never alter collected data,
/// profile state, rules or transactions.
enum PushProfileUiDesign { legacy, unified }

/// Chooses only the Automation tab's overview surface. It is deliberately
/// independent from the recurring and push-profile flow selectors.
enum AutomationHomeUiDesign { legacy, unified }

/// Persisted presentation-only choices. Financial membership, query state,
/// selected time and prepared data are deliberately outside this value.
final class DashboardPresentationPreferences {
  const DashboardPresentationPreferences({
    required this.sumVisualStyle,
    required this.showSumLayoutChooser,
    required this.yearGridLayout,
    required this.yearMonthlyAmountPresentation,
    required this.showDayContentViewChooser,
    required this.balanceUsesChildCards,
    required this.balanceHeaderGraphPresentation,
    this.balanceDayLayoutPresentation = BalanceDayLayoutPresentation.focused,
    this.balanceDayFocusedPresentation =
        BalanceDayFocusedPresentation.financialCompass,
    this.balanceDayPerformanceVisualPresentation =
        BalanceDayPerformanceVisualPresentation.semicircle,
    this.balanceDayRatioViewPresentation =
        BalanceDayRatioViewPresentation.dualGauge,
    this.balanceDayRatioPresentation = BalanceDayRatioPresentation.coverage,
    this.balanceShowFocusedDayImpact = true,
    this.balanceSumLayoutPresentation = BalanceSumLayoutPresentation.focused,
    this.balanceSumFocusedPresentation =
        BalanceSumFocusedPresentation.distribution,
    this.balanceShowSumFocusedSupplementaryStats = true,
    this.balanceMonthLayoutPresentation =
        BalanceMonthLayoutPresentation.focused,
    this.balanceYearLayoutPresentation = BalanceYearLayoutPresentation.focused,
    this.balanceDailyCalculationMode = BalanceDailyCalculationMode.monthToDate,
    this.balanceMonthlySpendingChartPresentation =
        BalanceMonthlySpendingChartPresentation.current,
    required this.balanceHeaderPartitionHeightPercent,
    required this.balanceMonthCombinedCardPresentation,
    this.balanceHeaderGlassConfigurationJson = '',
    this.balanceHeaderPalette = DashboardBalanceHeaderPalette.softRainbow,
    this.balanceHeaderPaletteVariant =
        DashboardBalanceHeaderPaletteVariant.saturated,
    this.balanceHeaderPalettePositionPercent = 50,
    this.balanceHeaderPaletteWindowWidthPercent = 15,
    this.ghostQuickFilterIconPack = DashboardGhostQuickFilterIconPack.current,
    this.ghostQuickFilterPresentation =
        DashboardGhostQuickFilterPresentation.searchPillFling,
    this.recurringUiDesign = RecurringUiDesign.unified,
    this.pushProfileUiDesign = PushProfileUiDesign.unified,
    this.automationHomeUiDesign = AutomationHomeUiDesign.unified,
    this.headerTapWaveTrailStrengthPercent = 225,
    this.headerTapWaveTapStartSizePercent = 55,
    this.headerTapWaveTapStrengthPercent = 75,
  });

  final MindSumVisualStyle sumVisualStyle;
  final bool showSumLayoutChooser;
  final MindYearHeatmapGridLayout yearGridLayout;
  final MindYearMonthlyAmountPresentation yearMonthlyAmountPresentation;
  final bool showDayContentViewChooser;
  final BalanceDayLayoutPresentation balanceDayLayoutPresentation;
  final BalanceDayFocusedPresentation balanceDayFocusedPresentation;
  final BalanceDayPerformanceVisualPresentation
  balanceDayPerformanceVisualPresentation;
  final BalanceDayRatioViewPresentation balanceDayRatioViewPresentation;
  final BalanceDayRatioPresentation balanceDayRatioPresentation;
  final bool balanceShowFocusedDayImpact;
  final BalanceSumLayoutPresentation balanceSumLayoutPresentation;
  final BalanceSumFocusedPresentation balanceSumFocusedPresentation;
  final bool balanceShowSumFocusedSupplementaryStats;
  final BalanceMonthLayoutPresentation balanceMonthLayoutPresentation;
  final BalanceYearLayoutPresentation balanceYearLayoutPresentation;
  final BalanceDailyCalculationMode balanceDailyCalculationMode;
  final bool balanceUsesChildCards;
  final BalanceHeaderGraphPresentation balanceHeaderGraphPresentation;
  final BalanceMonthlySpendingChartPresentation
  balanceMonthlySpendingChartPresentation;
  final double balanceHeaderPartitionHeightPercent;
  final BalanceMonthCombinedCardPresentation
  balanceMonthCombinedCardPresentation;
  final String balanceHeaderGlassConfigurationJson;
  final DashboardBalanceHeaderPalette balanceHeaderPalette;
  final DashboardBalanceHeaderPaletteVariant balanceHeaderPaletteVariant;
  final double balanceHeaderPalettePositionPercent;
  final double balanceHeaderPaletteWindowWidthPercent;
  final DashboardGhostQuickFilterIconPack ghostQuickFilterIconPack;
  final DashboardGhostQuickFilterPresentation ghostQuickFilterPresentation;
  final RecurringUiDesign recurringUiDesign;
  final PushProfileUiDesign pushProfileUiDesign;
  final AutomationHomeUiDesign automationHomeUiDesign;

  /// Personal (not the temporary A/B reference) Header touch-wave controls.
  final double headerTapWaveTrailStrengthPercent;
  final double headerTapWaveTapStartSizePercent;
  final double headerTapWaveTapStrengthPercent;

  static const defaults = DashboardPresentationPreferences(
    sumVisualStyle: MindSumVisualStyle.sumA,
    showSumLayoutChooser: true,
    yearGridLayout: MindYearHeatmapGridLayout.fourByThree,
    yearMonthlyAmountPresentation: MindYearMonthlyAmountPresentation.inline,
    showDayContentViewChooser: false,
    balanceUsesChildCards: true,
    balanceHeaderGraphPresentation:
        BalanceHeaderGraphPresentation.incomeExpensePartition,
    balanceDayLayoutPresentation: BalanceDayLayoutPresentation.focused,
    balanceSumLayoutPresentation: BalanceSumLayoutPresentation.focused,
    balanceMonthLayoutPresentation: BalanceMonthLayoutPresentation.focused,
    balanceYearLayoutPresentation: BalanceYearLayoutPresentation.focused,
    balanceMonthlySpendingChartPresentation:
        BalanceMonthlySpendingChartPresentation.current,
    balanceHeaderPartitionHeightPercent: 50,
    balanceMonthCombinedCardPresentation:
        BalanceMonthCombinedCardPresentation.incomeExpense,
    balanceHeaderGlassConfigurationJson: '',
    balanceHeaderPalette: DashboardBalanceHeaderPalette.softRainbow,
    balanceHeaderPaletteVariant: DashboardBalanceHeaderPaletteVariant.saturated,
    balanceHeaderPalettePositionPercent: 50,
    balanceHeaderPaletteWindowWidthPercent: 15,
    ghostQuickFilterIconPack: DashboardGhostQuickFilterIconPack.current,
    ghostQuickFilterPresentation:
        DashboardGhostQuickFilterPresentation.searchPillFling,
    recurringUiDesign: RecurringUiDesign.unified,
    pushProfileUiDesign: PushProfileUiDesign.unified,
    automationHomeUiDesign: AutomationHomeUiDesign.unified,
    headerTapWaveTrailStrengthPercent: 225,
    headerTapWaveTapStartSizePercent: 55,
    headerTapWaveTapStrengthPercent: 75,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardPresentationPreferences &&
      other.sumVisualStyle == sumVisualStyle &&
      other.showSumLayoutChooser == showSumLayoutChooser &&
      other.yearGridLayout == yearGridLayout &&
      other.yearMonthlyAmountPresentation == yearMonthlyAmountPresentation &&
      other.showDayContentViewChooser == showDayContentViewChooser &&
      other.balanceDayLayoutPresentation == balanceDayLayoutPresentation &&
      other.balanceDayFocusedPresentation == balanceDayFocusedPresentation &&
      other.balanceDayPerformanceVisualPresentation ==
          balanceDayPerformanceVisualPresentation &&
      other.balanceDayRatioViewPresentation ==
          balanceDayRatioViewPresentation &&
      other.balanceDayRatioPresentation == balanceDayRatioPresentation &&
      other.balanceShowFocusedDayImpact == balanceShowFocusedDayImpact &&
      other.balanceSumLayoutPresentation == balanceSumLayoutPresentation &&
      other.balanceSumFocusedPresentation == balanceSumFocusedPresentation &&
      other.balanceShowSumFocusedSupplementaryStats ==
          balanceShowSumFocusedSupplementaryStats &&
      other.balanceMonthLayoutPresentation == balanceMonthLayoutPresentation &&
      other.balanceYearLayoutPresentation == balanceYearLayoutPresentation &&
      other.balanceDailyCalculationMode == balanceDailyCalculationMode &&
      other.balanceUsesChildCards == balanceUsesChildCards &&
      other.balanceHeaderGraphPresentation == balanceHeaderGraphPresentation &&
      other.balanceMonthlySpendingChartPresentation ==
          balanceMonthlySpendingChartPresentation &&
      other.balanceHeaderPartitionHeightPercent ==
          balanceHeaderPartitionHeightPercent &&
      other.balanceMonthCombinedCardPresentation ==
          balanceMonthCombinedCardPresentation &&
      other.balanceHeaderGlassConfigurationJson ==
          balanceHeaderGlassConfigurationJson &&
      other.balanceHeaderPalette == balanceHeaderPalette &&
      other.balanceHeaderPaletteVariant == balanceHeaderPaletteVariant &&
      other.balanceHeaderPalettePositionPercent ==
          balanceHeaderPalettePositionPercent &&
      other.balanceHeaderPaletteWindowWidthPercent ==
          balanceHeaderPaletteWindowWidthPercent &&
      other.ghostQuickFilterIconPack == ghostQuickFilterIconPack &&
      other.ghostQuickFilterPresentation == ghostQuickFilterPresentation &&
      other.recurringUiDesign == recurringUiDesign &&
      other.pushProfileUiDesign == pushProfileUiDesign &&
      other.automationHomeUiDesign == automationHomeUiDesign &&
      other.headerTapWaveTrailStrengthPercent ==
          headerTapWaveTrailStrengthPercent &&
      other.headerTapWaveTapStartSizePercent ==
          headerTapWaveTapStartSizePercent &&
      other.headerTapWaveTapStrengthPercent == headerTapWaveTapStrengthPercent;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    sumVisualStyle,
    showSumLayoutChooser,
    yearGridLayout,
    yearMonthlyAmountPresentation,
    showDayContentViewChooser,
    balanceDayLayoutPresentation,
    balanceDayFocusedPresentation,
    balanceDayPerformanceVisualPresentation,
    balanceDayRatioViewPresentation,
    balanceDayRatioPresentation,
    balanceShowFocusedDayImpact,
    balanceSumLayoutPresentation,
    balanceSumFocusedPresentation,
    balanceShowSumFocusedSupplementaryStats,
    balanceMonthLayoutPresentation,
    balanceYearLayoutPresentation,
    balanceDailyCalculationMode,
    balanceUsesChildCards,
    balanceHeaderGraphPresentation,
    balanceMonthlySpendingChartPresentation,
    balanceHeaderPartitionHeightPercent,
    balanceMonthCombinedCardPresentation,
    balanceHeaderGlassConfigurationJson,
    balanceHeaderPalette,
    balanceHeaderPaletteVariant,
    balanceHeaderPalettePositionPercent,
    balanceHeaderPaletteWindowWidthPercent,
    ghostQuickFilterIconPack,
    ghostQuickFilterPresentation,
    recurringUiDesign,
    pushProfileUiDesign,
    automationHomeUiDesign,
    headerTapWaveTrailStrengthPercent,
    headerTapWaveTapStartSizePercent,
    headerTapWaveTapStrengthPercent,
  ]);

  DashboardPresentationPreferences withGhostQuickFilterIconPack(
    DashboardGhostQuickFilterIconPack next,
  ) => DashboardPresentationPreferences(
    sumVisualStyle: sumVisualStyle,
    showSumLayoutChooser: showSumLayoutChooser,
    yearGridLayout: yearGridLayout,
    yearMonthlyAmountPresentation: yearMonthlyAmountPresentation,
    showDayContentViewChooser: showDayContentViewChooser,
    balanceUsesChildCards: balanceUsesChildCards,
    balanceHeaderGraphPresentation: balanceHeaderGraphPresentation,
    balanceDayLayoutPresentation: balanceDayLayoutPresentation,
    balanceDayFocusedPresentation: balanceDayFocusedPresentation,
    balanceDayPerformanceVisualPresentation:
        balanceDayPerformanceVisualPresentation,
    balanceDayRatioViewPresentation: balanceDayRatioViewPresentation,
    balanceDayRatioPresentation: balanceDayRatioPresentation,
    balanceShowFocusedDayImpact: balanceShowFocusedDayImpact,
    balanceSumLayoutPresentation: balanceSumLayoutPresentation,
    balanceSumFocusedPresentation: balanceSumFocusedPresentation,
    balanceShowSumFocusedSupplementaryStats:
        balanceShowSumFocusedSupplementaryStats,
    balanceMonthLayoutPresentation: balanceMonthLayoutPresentation,
    balanceYearLayoutPresentation: balanceYearLayoutPresentation,
    balanceDailyCalculationMode: balanceDailyCalculationMode,
    balanceMonthlySpendingChartPresentation:
        balanceMonthlySpendingChartPresentation,
    balanceHeaderPartitionHeightPercent: balanceHeaderPartitionHeightPercent,
    balanceMonthCombinedCardPresentation: balanceMonthCombinedCardPresentation,
    balanceHeaderGlassConfigurationJson: balanceHeaderGlassConfigurationJson,
    balanceHeaderPalette: balanceHeaderPalette,
    balanceHeaderPaletteVariant: balanceHeaderPaletteVariant,
    balanceHeaderPalettePositionPercent: balanceHeaderPalettePositionPercent,
    balanceHeaderPaletteWindowWidthPercent:
        balanceHeaderPaletteWindowWidthPercent,
    ghostQuickFilterIconPack: next,
    ghostQuickFilterPresentation: ghostQuickFilterPresentation,
    recurringUiDesign: recurringUiDesign,
    pushProfileUiDesign: pushProfileUiDesign,
    automationHomeUiDesign: automationHomeUiDesign,
    headerTapWaveTrailStrengthPercent: headerTapWaveTrailStrengthPercent,
    headerTapWaveTapStartSizePercent: headerTapWaveTapStartSizePercent,
    headerTapWaveTapStrengthPercent: headerTapWaveTapStrengthPercent,
  );

  DashboardPresentationPreferences withGhostQuickFilterPresentation(
    DashboardGhostQuickFilterPresentation next,
  ) => DashboardPresentationPreferences(
    sumVisualStyle: sumVisualStyle,
    showSumLayoutChooser: showSumLayoutChooser,
    yearGridLayout: yearGridLayout,
    yearMonthlyAmountPresentation: yearMonthlyAmountPresentation,
    showDayContentViewChooser: showDayContentViewChooser,
    balanceUsesChildCards: balanceUsesChildCards,
    balanceHeaderGraphPresentation: balanceHeaderGraphPresentation,
    balanceDayLayoutPresentation: balanceDayLayoutPresentation,
    balanceDayFocusedPresentation: balanceDayFocusedPresentation,
    balanceDayPerformanceVisualPresentation:
        balanceDayPerformanceVisualPresentation,
    balanceDayRatioViewPresentation: balanceDayRatioViewPresentation,
    balanceDayRatioPresentation: balanceDayRatioPresentation,
    balanceShowFocusedDayImpact: balanceShowFocusedDayImpact,
    balanceSumLayoutPresentation: balanceSumLayoutPresentation,
    balanceSumFocusedPresentation: balanceSumFocusedPresentation,
    balanceShowSumFocusedSupplementaryStats:
        balanceShowSumFocusedSupplementaryStats,
    balanceMonthLayoutPresentation: balanceMonthLayoutPresentation,
    balanceYearLayoutPresentation: balanceYearLayoutPresentation,
    balanceDailyCalculationMode: balanceDailyCalculationMode,
    balanceMonthlySpendingChartPresentation:
        balanceMonthlySpendingChartPresentation,
    balanceHeaderPartitionHeightPercent: balanceHeaderPartitionHeightPercent,
    balanceMonthCombinedCardPresentation: balanceMonthCombinedCardPresentation,
    balanceHeaderGlassConfigurationJson: balanceHeaderGlassConfigurationJson,
    balanceHeaderPalette: balanceHeaderPalette,
    balanceHeaderPaletteVariant: balanceHeaderPaletteVariant,
    balanceHeaderPalettePositionPercent: balanceHeaderPalettePositionPercent,
    balanceHeaderPaletteWindowWidthPercent:
        balanceHeaderPaletteWindowWidthPercent,
    ghostQuickFilterIconPack: ghostQuickFilterIconPack,
    ghostQuickFilterPresentation: next,
    recurringUiDesign: recurringUiDesign,
    pushProfileUiDesign: pushProfileUiDesign,
    automationHomeUiDesign: automationHomeUiDesign,
    headerTapWaveTrailStrengthPercent: headerTapWaveTrailStrengthPercent,
    headerTapWaveTapStartSizePercent: headerTapWaveTapStartSizePercent,
    headerTapWaveTapStrengthPercent: headerTapWaveTapStrengthPercent,
  );

  DashboardPresentationPreferences withRecurringUiDesign(
    RecurringUiDesign next,
  ) => DashboardPresentationPreferences(
    sumVisualStyle: sumVisualStyle,
    showSumLayoutChooser: showSumLayoutChooser,
    yearGridLayout: yearGridLayout,
    yearMonthlyAmountPresentation: yearMonthlyAmountPresentation,
    showDayContentViewChooser: showDayContentViewChooser,
    balanceUsesChildCards: balanceUsesChildCards,
    balanceHeaderGraphPresentation: balanceHeaderGraphPresentation,
    balanceDayLayoutPresentation: balanceDayLayoutPresentation,
    balanceDayFocusedPresentation: balanceDayFocusedPresentation,
    balanceDayPerformanceVisualPresentation:
        balanceDayPerformanceVisualPresentation,
    balanceDayRatioViewPresentation: balanceDayRatioViewPresentation,
    balanceDayRatioPresentation: balanceDayRatioPresentation,
    balanceShowFocusedDayImpact: balanceShowFocusedDayImpact,
    balanceSumLayoutPresentation: balanceSumLayoutPresentation,
    balanceSumFocusedPresentation: balanceSumFocusedPresentation,
    balanceShowSumFocusedSupplementaryStats:
        balanceShowSumFocusedSupplementaryStats,
    balanceMonthLayoutPresentation: balanceMonthLayoutPresentation,
    balanceYearLayoutPresentation: balanceYearLayoutPresentation,
    balanceDailyCalculationMode: balanceDailyCalculationMode,
    balanceMonthlySpendingChartPresentation:
        balanceMonthlySpendingChartPresentation,
    balanceHeaderPartitionHeightPercent: balanceHeaderPartitionHeightPercent,
    balanceMonthCombinedCardPresentation: balanceMonthCombinedCardPresentation,
    balanceHeaderGlassConfigurationJson: balanceHeaderGlassConfigurationJson,
    balanceHeaderPalette: balanceHeaderPalette,
    balanceHeaderPaletteVariant: balanceHeaderPaletteVariant,
    balanceHeaderPalettePositionPercent: balanceHeaderPalettePositionPercent,
    balanceHeaderPaletteWindowWidthPercent:
        balanceHeaderPaletteWindowWidthPercent,
    ghostQuickFilterIconPack: ghostQuickFilterIconPack,
    ghostQuickFilterPresentation: ghostQuickFilterPresentation,
    recurringUiDesign: next,
    pushProfileUiDesign: pushProfileUiDesign,
    automationHomeUiDesign: automationHomeUiDesign,
    headerTapWaveTrailStrengthPercent: headerTapWaveTrailStrengthPercent,
    headerTapWaveTapStartSizePercent: headerTapWaveTapStartSizePercent,
    headerTapWaveTapStrengthPercent: headerTapWaveTapStrengthPercent,
  );

  DashboardPresentationPreferences withPushProfileUiDesign(
    PushProfileUiDesign next,
  ) => DashboardPresentationPreferences(
    sumVisualStyle: sumVisualStyle,
    showSumLayoutChooser: showSumLayoutChooser,
    yearGridLayout: yearGridLayout,
    yearMonthlyAmountPresentation: yearMonthlyAmountPresentation,
    showDayContentViewChooser: showDayContentViewChooser,
    balanceUsesChildCards: balanceUsesChildCards,
    balanceHeaderGraphPresentation: balanceHeaderGraphPresentation,
    balanceDayLayoutPresentation: balanceDayLayoutPresentation,
    balanceDayFocusedPresentation: balanceDayFocusedPresentation,
    balanceDayPerformanceVisualPresentation:
        balanceDayPerformanceVisualPresentation,
    balanceDayRatioViewPresentation: balanceDayRatioViewPresentation,
    balanceDayRatioPresentation: balanceDayRatioPresentation,
    balanceShowFocusedDayImpact: balanceShowFocusedDayImpact,
    balanceSumLayoutPresentation: balanceSumLayoutPresentation,
    balanceSumFocusedPresentation: balanceSumFocusedPresentation,
    balanceShowSumFocusedSupplementaryStats:
        balanceShowSumFocusedSupplementaryStats,
    balanceMonthLayoutPresentation: balanceMonthLayoutPresentation,
    balanceYearLayoutPresentation: balanceYearLayoutPresentation,
    balanceDailyCalculationMode: balanceDailyCalculationMode,
    balanceMonthlySpendingChartPresentation:
        balanceMonthlySpendingChartPresentation,
    balanceHeaderPartitionHeightPercent: balanceHeaderPartitionHeightPercent,
    balanceMonthCombinedCardPresentation: balanceMonthCombinedCardPresentation,
    balanceHeaderGlassConfigurationJson: balanceHeaderGlassConfigurationJson,
    balanceHeaderPalette: balanceHeaderPalette,
    balanceHeaderPaletteVariant: balanceHeaderPaletteVariant,
    balanceHeaderPalettePositionPercent: balanceHeaderPalettePositionPercent,
    balanceHeaderPaletteWindowWidthPercent:
        balanceHeaderPaletteWindowWidthPercent,
    ghostQuickFilterIconPack: ghostQuickFilterIconPack,
    ghostQuickFilterPresentation: ghostQuickFilterPresentation,
    recurringUiDesign: recurringUiDesign,
    pushProfileUiDesign: next,
    automationHomeUiDesign: automationHomeUiDesign,
    headerTapWaveTrailStrengthPercent: headerTapWaveTrailStrengthPercent,
    headerTapWaveTapStartSizePercent: headerTapWaveTapStartSizePercent,
    headerTapWaveTapStrengthPercent: headerTapWaveTapStrengthPercent,
  );

  DashboardPresentationPreferences withAutomationHomeUiDesign(
    AutomationHomeUiDesign next,
  ) => DashboardPresentationPreferences(
    sumVisualStyle: sumVisualStyle,
    showSumLayoutChooser: showSumLayoutChooser,
    yearGridLayout: yearGridLayout,
    yearMonthlyAmountPresentation: yearMonthlyAmountPresentation,
    showDayContentViewChooser: showDayContentViewChooser,
    balanceUsesChildCards: balanceUsesChildCards,
    balanceHeaderGraphPresentation: balanceHeaderGraphPresentation,
    balanceDayLayoutPresentation: balanceDayLayoutPresentation,
    balanceDayFocusedPresentation: balanceDayFocusedPresentation,
    balanceDayPerformanceVisualPresentation:
        balanceDayPerformanceVisualPresentation,
    balanceDayRatioViewPresentation: balanceDayRatioViewPresentation,
    balanceDayRatioPresentation: balanceDayRatioPresentation,
    balanceShowFocusedDayImpact: balanceShowFocusedDayImpact,
    balanceSumLayoutPresentation: balanceSumLayoutPresentation,
    balanceSumFocusedPresentation: balanceSumFocusedPresentation,
    balanceShowSumFocusedSupplementaryStats:
        balanceShowSumFocusedSupplementaryStats,
    balanceMonthLayoutPresentation: balanceMonthLayoutPresentation,
    balanceYearLayoutPresentation: balanceYearLayoutPresentation,
    balanceDailyCalculationMode: balanceDailyCalculationMode,
    balanceMonthlySpendingChartPresentation:
        balanceMonthlySpendingChartPresentation,
    balanceHeaderPartitionHeightPercent: balanceHeaderPartitionHeightPercent,
    balanceMonthCombinedCardPresentation: balanceMonthCombinedCardPresentation,
    balanceHeaderGlassConfigurationJson: balanceHeaderGlassConfigurationJson,
    balanceHeaderPalette: balanceHeaderPalette,
    balanceHeaderPaletteVariant: balanceHeaderPaletteVariant,
    balanceHeaderPalettePositionPercent: balanceHeaderPalettePositionPercent,
    balanceHeaderPaletteWindowWidthPercent:
        balanceHeaderPaletteWindowWidthPercent,
    ghostQuickFilterIconPack: ghostQuickFilterIconPack,
    ghostQuickFilterPresentation: ghostQuickFilterPresentation,
    recurringUiDesign: recurringUiDesign,
    pushProfileUiDesign: pushProfileUiDesign,
    automationHomeUiDesign: next,
    headerTapWaveTrailStrengthPercent: headerTapWaveTrailStrengthPercent,
    headerTapWaveTapStartSizePercent: headerTapWaveTapStartSizePercent,
    headerTapWaveTapStrengthPercent: headerTapWaveTapStrengthPercent,
  );

  DashboardPresentationPreferences withHeaderTapWaveControls({
    required double trailStrengthPercent,
    required double tapStartSizePercent,
    required double tapStrengthPercent,
  }) => DashboardPresentationPreferences(
    sumVisualStyle: sumVisualStyle,
    showSumLayoutChooser: showSumLayoutChooser,
    yearGridLayout: yearGridLayout,
    yearMonthlyAmountPresentation: yearMonthlyAmountPresentation,
    showDayContentViewChooser: showDayContentViewChooser,
    balanceUsesChildCards: balanceUsesChildCards,
    balanceHeaderGraphPresentation: balanceHeaderGraphPresentation,
    balanceDayLayoutPresentation: balanceDayLayoutPresentation,
    balanceDayFocusedPresentation: balanceDayFocusedPresentation,
    balanceDayPerformanceVisualPresentation:
        balanceDayPerformanceVisualPresentation,
    balanceDayRatioViewPresentation: balanceDayRatioViewPresentation,
    balanceDayRatioPresentation: balanceDayRatioPresentation,
    balanceShowFocusedDayImpact: balanceShowFocusedDayImpact,
    balanceSumLayoutPresentation: balanceSumLayoutPresentation,
    balanceSumFocusedPresentation: balanceSumFocusedPresentation,
    balanceShowSumFocusedSupplementaryStats:
        balanceShowSumFocusedSupplementaryStats,
    balanceMonthLayoutPresentation: balanceMonthLayoutPresentation,
    balanceYearLayoutPresentation: balanceYearLayoutPresentation,
    balanceDailyCalculationMode: balanceDailyCalculationMode,
    balanceMonthlySpendingChartPresentation:
        balanceMonthlySpendingChartPresentation,
    balanceHeaderPartitionHeightPercent: balanceHeaderPartitionHeightPercent,
    balanceMonthCombinedCardPresentation: balanceMonthCombinedCardPresentation,
    balanceHeaderGlassConfigurationJson: balanceHeaderGlassConfigurationJson,
    balanceHeaderPalette: balanceHeaderPalette,
    balanceHeaderPaletteVariant: balanceHeaderPaletteVariant,
    balanceHeaderPalettePositionPercent: balanceHeaderPalettePositionPercent,
    balanceHeaderPaletteWindowWidthPercent:
        balanceHeaderPaletteWindowWidthPercent,
    ghostQuickFilterIconPack: ghostQuickFilterIconPack,
    ghostQuickFilterPresentation: ghostQuickFilterPresentation,
    recurringUiDesign: recurringUiDesign,
    pushProfileUiDesign: pushProfileUiDesign,
    automationHomeUiDesign: automationHomeUiDesign,
    headerTapWaveTrailStrengthPercent: trailStrengthPercent,
    headerTapWaveTapStartSizePercent: tapStartSizePercent,
    headerTapWaveTapStrengthPercent: tapStrengthPercent,
  );
}

abstract interface class DashboardPresentationPreferencesStore {
  Future<DashboardPresentationPreferences> read();
  Future<void> write(DashboardPresentationPreferences preferences);
}

final class DashboardPresentationPreferencesController
    extends ValueNotifier<DashboardPresentationPreferences> {
  DashboardPresentationPreferencesController({
    required DashboardPresentationPreferencesStore store,
  }) : _store = store,
       super(DashboardPresentationPreferences.defaults);

  final DashboardPresentationPreferencesStore _store;
  int _mutationRevision = 0;

  Future<void> restore() async {
    final restoreRevision = _mutationRevision;
    try {
      final restored = await _store.read();
      // A delayed platform read must never undo a selection made while the
      // dashboard was already interactive.
      if (restoreRevision == _mutationRevision) value = restored;
    } catch (_) {
      // Presentation settings are never allowed to block dashboard admission.
    }
  }

  void setPreferences(DashboardPresentationPreferences next) {
    if (next == value) return;
    _mutationRevision++;
    value = next;
    unawaited(_persist(next));
  }

  Future<void> _persist(DashboardPresentationPreferences next) async {
    try {
      await _store.write(next);
    } catch (_) {
      // Local UI remains responsive if the platform adapter is unavailable.
    }
  }
}

final class InMemoryDashboardPresentationPreferencesStore
    implements DashboardPresentationPreferencesStore {
  InMemoryDashboardPresentationPreferencesStore([
    this._value = DashboardPresentationPreferences.defaults,
  ]);

  DashboardPresentationPreferences _value;

  @override
  Future<DashboardPresentationPreferences> read() async => _value;

  @override
  Future<void> write(DashboardPresentationPreferences preferences) async {
    _value = preferences;
  }
}
