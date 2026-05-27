import 'dart:math' as math;

import '../models/category_budget_bar_data.dart';

class CategoryLimitPartition {
  const CategoryLimitPartition({
    required this.bar,
    required this.amount,
    required this.weight,
    required this.fraction,
    required this.isActive,
  });

  final CategoryBudgetBarData bar;
  final double amount;
  final double weight;
  final double fraction;
  final bool isActive;
}

class LimitPartitionManager {
  static const fallbackUnitAmount = 10000.0;

  static double unitAmount(
    List<CategoryBudgetBarData> bars, {
    CategoryBudgetBarData? activeBar,
    double? activeLimitAmount,
  }) {
    final amounts = _amounts(
      bars,
      activeBar: activeBar,
      activeLimitAmount: activeLimitAmount,
    ).where((amount) => amount > 0).toList();
    if (amounts.isEmpty) return fallbackUnitAmount;
    final total = amounts.fold<double>(0, (sum, amount) => sum + amount);
    return math.max(total / amounts.length, 1).toDouble();
  }

  static double sliderMaxAmount(
    List<CategoryBudgetBarData> bars, {
    required CategoryBudgetBarData activeBar,
    required double activeLimitAmount,
  }) {
    final sourceBars = bars.isEmpty ? [activeBar] : bars;
    final unit = unitAmount(
      sourceBars,
      activeBar: activeBar,
      activeLimitAmount: activeLimitAmount,
    );
    final count = math.max(sourceBars.length, 1).toDouble();
    final highestAmount = _amounts(
      sourceBars,
      activeBar: activeBar,
      activeLimitAmount: activeLimitAmount,
    ).fold<double>(0, (highest, amount) => math.max(highest, amount));
    return math.max(math.max(unit * count, highestAmount), fallbackUnitAmount).toDouble();
  }

  static int sliderDivisions(
    List<CategoryBudgetBarData> bars, {
    required CategoryBudgetBarData activeBar,
    required double activeLimitAmount,
  }) {
    final sourceBars = bars.isEmpty ? [activeBar] : bars;
    final unit = unitAmount(
      sourceBars,
      activeBar: activeBar,
      activeLimitAmount: activeLimitAmount,
    );
    final maxAmount = sliderMaxAmount(
      sourceBars,
      activeBar: activeBar,
      activeLimitAmount: activeLimitAmount,
    );
    return math.max(1, (maxAmount / unit).round()).toInt();
  }

  static List<CategoryLimitPartition> partitions({
    required List<CategoryBudgetBarData> bars,
    CategoryBudgetBarData? activeBar,
    double? activeLimitAmount,
  }) {
    final sourceBars = bars.isEmpty && activeBar != null ? [activeBar] : bars;
    if (sourceBars.isEmpty) return const [];
    final unit = unitAmount(
      sourceBars,
      activeBar: activeBar,
      activeLimitAmount: activeLimitAmount,
    );
    final weighted = sourceBars.map((bar) {
      final amount = _amountFor(
        bar,
        activeBar: activeBar,
        activeLimitAmount: activeLimitAmount,
      );
      final weight = amount > 0 ? amount : unit;
      return (bar: bar, amount: amount, weight: weight);
    }).toList();
    final totalWeight = weighted.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
    if (totalWeight <= 0) return const [];
    return weighted.map((item) {
      return CategoryLimitPartition(
        bar: item.bar,
        amount: item.amount,
        weight: item.weight,
        fraction: item.weight / totalWeight,
        isActive: activeBar != null && _sameTarget(item.bar, activeBar),
      );
    }).toList();
  }

  static List<double> _amounts(
    List<CategoryBudgetBarData> bars, {
    CategoryBudgetBarData? activeBar,
    double? activeLimitAmount,
  }) {
    return bars
        .map(
          (bar) => _amountFor(
            bar,
            activeBar: activeBar,
            activeLimitAmount: activeLimitAmount,
          ),
        )
        .toList();
  }

  static double _amountFor(
    CategoryBudgetBarData bar, {
    CategoryBudgetBarData? activeBar,
    double? activeLimitAmount,
  }) {
    if (activeBar != null && _sameTarget(bar, activeBar)) {
      return activeLimitAmount ?? bar.limitAmount;
    }
    return bar.limitAmount;
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
