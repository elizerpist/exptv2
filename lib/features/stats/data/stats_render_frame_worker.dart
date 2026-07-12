import 'dart:isolate';

import '../../transactions/models/transaction_category.dart';
import '../../transactions/models/transaction_record.dart';
import 'stats_render_frame.dart';
import 'stats_year_data.dart';

class StatsRenderFrameRequest {
  const StatsRenderFrameRequest({
    required this.year,
    required this.month,
    required this.activeType,
    required this.thresholdValue,
    required this.transactions,
    required this.categories,
    required this.selectedCategoryIds,
    required this.vendorFilters,
    required this.summaryScope,
    required this.query,
    required this.today,
    this.clampThreshold = true,
  });

  final int year;
  final int month;
  final TransactionType activeType;
  final double thresholdValue;
  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final Set<int> selectedCategoryIds;
  final Set<String> vendorFilters;
  final StatsSummaryScope summaryScope;
  final String query;
  final DateTime today;
  final bool clampThreshold;

  StatsRenderFrame buildSynchronously() {
    return StatsRenderFrame.build(
      year: year,
      month: month,
      activeType: activeType,
      thresholdValue: thresholdValue,
      transactions: transactions,
      categories: categories,
      selectedCategoryIds: selectedCategoryIds,
      vendorFilters: vendorFilters,
      summaryScope: summaryScope,
      query: query,
      today: today,
      thresholdResolver: clampThreshold ? _resolveThreshold : null,
    );
  }
}

abstract interface class StatsRenderFrameWorker {
  Future<StatsRenderFrame> build(StatsRenderFrameRequest request);
}

class IsolateStatsRenderFrameWorker implements StatsRenderFrameWorker {
  const IsolateStatsRenderFrameWorker();

  @override
  Future<StatsRenderFrame> build(StatsRenderFrameRequest request) {
    return Isolate.run(request.buildSynchronously);
  }
}

double _resolveThreshold(double requested, double observedMaximum) {
  const step = 5000.0;
  const fallbackMax = 50000.0;
  final sourceMax = observedMaximum > fallbackMax
      ? observedMaximum
      : fallbackMax;
  final max = (sourceMax / step).ceil() * step;
  final snapped = (requested / step).round() * step;
  return snapped.clamp(0.0, max).toDouble();
}
