import '../../../stats/data/stats_category_scope_series.dart';
import '../../../stats/data/stats_render_frame.dart';
import '../../../stats/data/stats_render_frame_worker_base.dart';
import '../../../stats/data/stats_year_data.dart';
import '../../models/summary_window.dart';
import '../../models/transaction_category.dart';
import '../../state/transaction_store.dart';

typedef SpendeeMindStatsFrameBuildObserver =
    void Function(SpendeeMindStatsFrameBuildEvent event);

class SpendeeMindStatsFrameBuildEvent {
  const SpendeeMindStatsFrameBuildEvent({
    required this.reason,
    required this.modeKey,
    required this.activeType,
    required this.transactionCount,
    required this.categoryCount,
    required this.elapsedMilliseconds,
  });

  final String reason;
  final String modeKey;
  final TransactionType activeType;
  final int transactionCount;
  final int categoryCount;
  final int elapsedMilliseconds;
}

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

  static SpendeeMindStatsFrameBuildObserver? debugBuildObserver;

  static SpendeeMindStatsFrame fromStore(
    TransactionStore store, {
    String reason = 'direct',
  }) {
    final stopwatch = Stopwatch()..start();
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
    final frame = SpendeeMindStatsFrame(
      summaryScope: scope,
      periodLabel: store.activePeriodLabel,
      modeKey: modeKey,
      activeFrame: store.activeType == TransactionType.income
          ? incomeFrame
          : expenseFrame,
      expenseFrame: expenseFrame,
      incomeFrame: incomeFrame,
    );
    stopwatch.stop();
    debugBuildObserver?.call(
      SpendeeMindStatsFrameBuildEvent(
        reason: reason,
        modeKey: modeKey,
        activeType: store.activeType,
        transactionCount: store.transactions.length,
        categoryCount: store.categories.length,
        elapsedMilliseconds: stopwatch.elapsedMilliseconds,
      ),
    );
    return frame;
  }

  /// Builds the child frame selected by the all-time Mind year rail.
  ///
  /// The Summary Pill remains all-time; only the Mind explorer narrows to the
  /// requested child year. Reusing [_buildFrame] keeps the live type, query,
  /// category, and vendor scope semantics identical to the stats screen.
  static StatsRenderFrame sumYearFrameFromStore(
    TransactionStore store, {
    required int year,
    required TransactionType activeType,
  }) {
    final reference = store.summaryReferenceDate;
    return _buildFrame(
      store: store,
      activeType: activeType,
      scope: StatsSummaryScope.yearly,
      year: year,
      month: reference.month,
    );
  }

  /// Builds unthresholded monthly volumes for every SUM child year.
  ///
  /// The heatmap keeps the stats threshold, but the year rail must represent
  /// every matching transaction month, including low-value or net-zero months.
  static StatsRenderFrame sumYearVolumeFrameFromStore(
    TransactionStore store, {
    required TransactionType activeType,
  }) {
    final reference = store.summaryReferenceDate;
    return _buildFrame(
      store: store,
      activeType: activeType,
      scope: StatsSummaryScope.allTime,
      year: reference.year,
      month: reference.month,
      thresholdValue: 0,
    );
  }

  static StatsRenderFrame _buildFrame({
    required TransactionStore store,
    required TransactionType activeType,
    required StatsSummaryScope scope,
    required int year,
    required int month,
    double thresholdValue = defaultStatsThreshold,
  }) {
    return StatsRenderFrame.build(
      year: year,
      activeType: activeType,
      thresholdValue: thresholdValue,
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
