import 'package:flutter/foundation.dart';

import '../../transactions/models/transaction_category.dart';
import '../../transactions/models/transaction_record.dart';
import 'stats_category_scope_series.dart';
import 'stats_page2_metrics.dart';
import 'stats_year_data.dart';

class StatsRenderFrame {
  const StatsRenderFrame({
    required this.yearData,
    required this.categoryScopeSeries,
    required this.page2Metrics,
    required this.observedMaximum,
    required this.filteredTransactionCount,
    required this.largestVisibleVendor,
    required this.sumYearSummaries,
  });

  final StatsYearData yearData;
  final StatsCategoryScopeSeries categoryScopeSeries;
  final StatsPage2Metrics page2Metrics;
  final double observedMaximum;
  final int filteredTransactionCount;
  final String largestVisibleVendor;
  final List<StatsSumYearSummary> sumYearSummaries;

  static StatsRenderFrame build({
    required int year,
    required TransactionType activeType,
    required double thresholdValue,
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
    required Set<int> selectedCategoryIds,
    Set<String> vendorFilters = const <String>{},
    StatsSummaryScope summaryScope = StatsSummaryScope.yearly,
    int? month,
    String query = '',
    DateTime? today,
    double Function(double requested, double observedMaximum)?
    thresholdResolver,
  }) {
    final normalizedQuery = StatsRenderFrameKey.normalizeQuery(query);
    final queryFilteredTransactions = normalizedQuery.isEmpty
        ? transactions
        : transactions
              .where(
                (record) => record.displayMerchant.toLowerCase().contains(
                  normalizedQuery,
                ),
              )
              .toList(growable: false);
    final yearData = StatsYearData.build(
      year: year,
      activeType: activeType,
      mode: StatsRenderMode.common,
      thresholdValue: thresholdValue,
      transactions: queryFilteredTransactions,
      categories: categories,
      selectedCategoryIds: selectedCategoryIds,
      vendorFilters: vendorFilters,
      summaryScope: summaryScope,
      month: month,
      today: today,
      thresholdResolver: thresholdResolver,
    );
    final categoryScopeSeries = StatsCategoryScopeSeries.fromYearData(yearData);
    final page2Metrics = StatsPage2Metrics.fromYearData(yearData);
    return StatsRenderFrame(
      yearData: yearData,
      categoryScopeSeries: categoryScopeSeries,
      page2Metrics: page2Metrics,
      observedMaximum: yearData.observedMaximum,
      filteredTransactionCount: yearData.metricRecordCount,
      largestVisibleVendor: yearData.largestVisibleVendor,
      sumYearSummaries: yearData.sumYearSummaries,
    );
  }
}

class StatsRenderFrameKey {
  StatsRenderFrameKey({
    required this.dataRevision,
    required this.activeType,
    required this.summaryScope,
    required this.year,
    required this.month,
    required Iterable<int> categoryIds,
    required Iterable<String> vendorNames,
    required String query,
    required this.threshold,
  }) : categoryIds = List.unmodifiable([...categoryIds]..sort()),
       vendorNames = List.unmodifiable(
         [
           ...vendorNames
               .map((name) => name.trim())
               .where((name) => name.isNotEmpty),
         ]..sort(),
       ),
       query = normalizeQuery(query);

  final Object dataRevision;
  final TransactionType activeType;
  final StatsSummaryScope summaryScope;
  final int year;
  final int month;
  final List<int> categoryIds;
  final List<String> vendorNames;
  final String query;
  final double threshold;

  static String normalizeQuery(String query) => query.trim().toLowerCase();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StatsRenderFrameKey &&
            other.dataRevision == dataRevision &&
            other.activeType == activeType &&
            other.summaryScope == summaryScope &&
            other.year == year &&
            other.month == month &&
            listEquals(other.categoryIds, categoryIds) &&
            listEquals(other.vendorNames, vendorNames) &&
            other.query == query &&
            other.threshold == threshold;
  }

  @override
  int get hashCode => Object.hash(
    dataRevision,
    activeType,
    summaryScope,
    year,
    month,
    Object.hashAll(categoryIds),
    Object.hashAll(vendorNames),
    query,
    threshold,
  );
}

class StatsRenderFrameCache {
  StatsRenderFrameCache({int capacity = 12})
    : capacity = capacity < 1 ? 1 : capacity;

  final int capacity;
  final _frames = <StatsRenderFrameKey, StatsRenderFrame>{};

  StatsRenderFrame resolve(
    StatsRenderFrameKey key,
    StatsRenderFrame Function() builder,
  ) {
    final frame = lookup(key);
    if (frame != null) return frame;
    final next = builder();
    seed(key, next);
    return next;
  }

  StatsRenderFrame? lookup(StatsRenderFrameKey key) {
    final frame = _frames.remove(key);
    if (frame == null) return null;
    _frames[key] = frame;
    return frame;
  }

  void seed(StatsRenderFrameKey key, StatsRenderFrame frame) {
    _frames.remove(key);
    _frames[key] = frame;
    while (_frames.length > capacity) {
      _frames.remove(_frames.keys.first);
    }
  }

  void clear() {
    _frames.clear();
  }
}
