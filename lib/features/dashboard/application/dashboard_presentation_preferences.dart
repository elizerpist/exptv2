import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mind/domain/mind_year_heatmap_presentation_settings.dart';
import '../presentation/core_modes/balance_presentation_settings.dart';

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
    this.balanceMonthlySpendingChartPresentation =
        BalanceMonthlySpendingChartPresentation.current,
    required this.balanceHeaderPartitionHeightPercent,
    required this.balanceMonthCombinedCardPresentation,
    this.balanceHeaderGlassConfigurationJson = '',
  });

  final MindSumVisualStyle sumVisualStyle;
  final bool showSumLayoutChooser;
  final MindYearHeatmapGridLayout yearGridLayout;
  final MindYearMonthlyAmountPresentation yearMonthlyAmountPresentation;
  final bool showDayContentViewChooser;
  final bool balanceUsesChildCards;
  final BalanceHeaderGraphPresentation balanceHeaderGraphPresentation;
  final BalanceMonthlySpendingChartPresentation
  balanceMonthlySpendingChartPresentation;
  final double balanceHeaderPartitionHeightPercent;
  final BalanceMonthCombinedCardPresentation
  balanceMonthCombinedCardPresentation;
  final String balanceHeaderGlassConfigurationJson;

  static const defaults = DashboardPresentationPreferences(
    sumVisualStyle: MindSumVisualStyle.sumA,
    showSumLayoutChooser: true,
    yearGridLayout: MindYearHeatmapGridLayout.fourByThree,
    yearMonthlyAmountPresentation: MindYearMonthlyAmountPresentation.inline,
    showDayContentViewChooser: false,
    balanceUsesChildCards: true,
    balanceHeaderGraphPresentation: BalanceHeaderGraphPresentation.lineChart,
    balanceMonthlySpendingChartPresentation:
        BalanceMonthlySpendingChartPresentation.current,
    balanceHeaderPartitionHeightPercent: 50,
    balanceMonthCombinedCardPresentation:
        BalanceMonthCombinedCardPresentation.incomeExpense,
    balanceHeaderGlassConfigurationJson: '',
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardPresentationPreferences &&
      other.sumVisualStyle == sumVisualStyle &&
      other.showSumLayoutChooser == showSumLayoutChooser &&
      other.yearGridLayout == yearGridLayout &&
      other.yearMonthlyAmountPresentation == yearMonthlyAmountPresentation &&
      other.showDayContentViewChooser == showDayContentViewChooser &&
      other.balanceUsesChildCards == balanceUsesChildCards &&
      other.balanceHeaderGraphPresentation == balanceHeaderGraphPresentation &&
      other.balanceMonthlySpendingChartPresentation ==
          balanceMonthlySpendingChartPresentation &&
      other.balanceHeaderPartitionHeightPercent ==
          balanceHeaderPartitionHeightPercent &&
      other.balanceMonthCombinedCardPresentation ==
          balanceMonthCombinedCardPresentation &&
      other.balanceHeaderGlassConfigurationJson ==
          balanceHeaderGlassConfigurationJson;

  @override
  int get hashCode => Object.hash(
    sumVisualStyle,
    showSumLayoutChooser,
    yearGridLayout,
    yearMonthlyAmountPresentation,
    showDayContentViewChooser,
    balanceUsesChildCards,
    balanceHeaderGraphPresentation,
    balanceMonthlySpendingChartPresentation,
    balanceHeaderPartitionHeightPercent,
    balanceMonthCombinedCardPresentation,
    balanceHeaderGlassConfigurationJson,
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

  Future<void> restore() async {
    try {
      value = await _store.read();
    } catch (_) {
      // Presentation settings are never allowed to block dashboard admission.
    }
  }

  void setPreferences(DashboardPresentationPreferences next) {
    if (next == value) return;
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
