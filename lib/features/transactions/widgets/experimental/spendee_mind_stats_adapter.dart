import '../../../stats/data/stats_category_scope_series.dart';
import '../../../stats/data/stats_render_frame.dart';
import '../../../stats/data/stats_render_frame_worker_base.dart';
import '../../../stats/data/stats_year_data.dart';
import '../../models/summary_window.dart';
import '../../models/transaction_category.dart';
import '../../state/transaction_store.dart';

class SpendeeMindStatsFrame {
  const SpendeeMindStatsFrame({
    required this.summaryScope,
    required this.periodLabel,
    required this.modeKey,
    required this.activeFrame,
    required this.expenseFrame,
    required this.incomeFrame,
  });

  final StatsSummaryScope summaryScope;
  final String periodLabel;
  final String modeKey;
  final StatsRenderFrame activeFrame;
  final StatsRenderFrame expenseFrame;
  final StatsRenderFrame incomeFrame;

  StatsCategoryScopeSeries get activeSeries => activeFrame.categoryScopeSeries;
  List<StatsSeriesPoint> get activeVolumePoints => activeSeries.valueIndex;
  List<StatsHelperBar> get activePatternBars => activeSeries.helperBars;
  List<StatsSeriesPoint> get activeScoreLine => activeSeries.scoreLine;
  double get activeScore => activeSeries.kontrollScore;

  static SpendeeMindStatsFrame fromStore(TransactionStore store) {
    final reference = store.summaryReferenceDate;
    final scope = switch (store.summaryWindow) {
      SummaryWindow.monthly => StatsSummaryScope.monthly,
      SummaryWindow.yearly => StatsSummaryScope.yearly,
      SummaryWindow.allTime => StatsSummaryScope.allTime,
    };
    final modeKey = switch (scope) {
      StatsSummaryScope.monthly => 'monthly',
      StatsSummaryScope.yearly => 'yearly',
      StatsSummaryScope.allTime => 'sum',
    };
    final expenseFrame = _buildFrame(
      store: store,
      activeType: TransactionType.expense,
      scope: scope,
      year: reference.year,
      month: reference.month,
    );
    final incomeFrame = _buildFrame(
      store: store,
      activeType: TransactionType.income,
      scope: scope,
      year: reference.year,
      month: reference.month,
    );
    return SpendeeMindStatsFrame(
      summaryScope: scope,
      periodLabel: store.activePeriodLabel,
      modeKey: modeKey,
      activeFrame: store.activeType == TransactionType.income
          ? incomeFrame
          : expenseFrame,
      expenseFrame: expenseFrame,
      incomeFrame: incomeFrame,
    );
  }

  static StatsRenderFrame _buildFrame({
    required TransactionStore store,
    required TransactionType activeType,
    required StatsSummaryScope scope,
    required int year,
    required int month,
  }) {
    return StatsRenderFrame.build(
      year: year,
      activeType: activeType,
      thresholdValue: defaultStatsThreshold,
      transactions: store.transactions,
      categories: store.categories,
      selectedCategoryIds: store.activeType == activeType
          ? store.activeCategoryIds
          : const <int>{},
      vendorFilters: store.activeMerchantFilters,
      summaryScope: scope,
      month: month,
      query: store.searchQuery,
      today: store.currentDate,
    );
  }
}
