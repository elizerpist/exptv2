import 'dart:math' as math;

import '../../../core/theme/app_colors.dart';
import '../models/category_budget_bar_data.dart';
import '../models/limit_allocation_data.dart';

class LimitAllocationManager {
  static const sliderStep = 1000.0;

  static LimitAllocationData build({
    required double overviewLimit,
    required List<CategoryBudgetBarData> bars,
  }) {
    if (overviewLimit <= 0) {
      return const LimitAllocationData(
        overviewLimit: 0,
        allocatedAmount: 0,
        freeAmount: 0,
        segments: [],
      );
    }

    final visibleBars = bars.where((bar) => bar.limitAmount > 0).toList();
    final segments = <LimitAllocationSegment>[];
    var allocated = 0.0;
    for (final bar in visibleBars) {
      final limit = bar.limitAmount.clamp(0.0, overviewLimit).toDouble();
      final used = math.min(bar.spent, limit).clamp(0.0, limit).toDouble();
      final remaining = (limit - used).clamp(0.0, limit).toDouble();
      allocated += limit;
      if (used > 0) {
        segments.add(
          LimitAllocationSegment(
            kind: LimitAllocationSegmentKind.used,
            amount: used,
            fraction: used / overviewLimit,
            color: bar.color,
            targetId: bar.targetId,
            label: bar.title,
          ),
        );
      }
      if (remaining > 0) {
        segments.add(
          LimitAllocationSegment(
            kind: LimitAllocationSegmentKind.remaining,
            amount: remaining,
            fraction: remaining / overviewLimit,
            color: bar.color.withValues(alpha: 0.70),
            targetId: bar.targetId,
            label: bar.title,
          ),
        );
      }
    }
    final free = (overviewLimit - allocated)
        .clamp(0.0, overviewLimit)
        .toDouble();
    if (free > 0) {
      segments.add(
        LimitAllocationSegment(
          kind: LimitAllocationSegmentKind.free,
          amount: free,
          fraction: free / overviewLimit,
          color: AppColors.gray200,
        ),
      );
    }
    return LimitAllocationData(
      overviewLimit: overviewLimit,
      allocatedAmount: allocated.clamp(0.0, overviewLimit).toDouble(),
      freeAmount: free,
      segments: segments,
    );
  }

  static double categorySliderMax({
    required double overviewLimit,
    required List<CategoryBudgetBarData> bars,
    required CategoryBudgetBarData activeBar,
  }) {
    if (overviewLimit <= 0) return math.max(activeBar.limitAmount, sliderStep);
    final others = bars
        .where((bar) => !_sameTarget(bar, activeBar))
        .where((bar) => bar.limitAmount > 0)
        .fold<double>(0, (sum, bar) => sum + bar.limitAmount);
    return (overviewLimit - others).clamp(0.0, double.infinity).toDouble();
  }

  static bool categorySliderEnabled({
    required double overviewLimit,
    required List<CategoryBudgetBarData> bars,
    required CategoryBudgetBarData activeBar,
  }) {
    if (overviewLimit <= 0) return true;
    if (activeBar.limitAmount > 0) return true;
    return categorySliderMax(
          overviewLimit: overviewLimit,
          bars: bars,
          activeBar: activeBar,
        ) >
        0;
  }

  static double snapSliderAmount(double amount) {
    if (amount <= 0) return 0;
    return (amount / sliderStep).round() * sliderStep;
  }

  static int sliderDivisions(double max) {
    if (max <= 0) return 1;
    return math.max(1, (max / sliderStep).ceil()).toInt();
  }

  static bool _sameTarget(
    CategoryBudgetBarData left,
    CategoryBudgetBarData right,
  ) {
    return left.targetType == right.targetType &&
        left.targetId == right.targetId &&
        left.transactionType == right.transactionType &&
        left.window == right.window &&
        left.periodKey == right.periodKey;
  }
}
