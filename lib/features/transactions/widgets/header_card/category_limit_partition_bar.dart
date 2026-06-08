import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/limit_partition_manager.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/limit_allocation_data.dart';

class CategoryLimitPartitionBar extends StatelessWidget {
  const CategoryLimitPartitionBar({
    super.key,
    this.bars = const [],
    this.allocation,
    this.activeBar,
    this.activeLimitAmount,
    this.overviewLimitAmount,
    this.height = 42,
    this.onSegmentTap,
  });

  final List<CategoryBudgetBarData> bars;
  final LimitAllocationData? allocation;
  final CategoryBudgetBarData? activeBar;
  final double? activeLimitAmount;
  final double? overviewLimitAmount;
  final double height;
  final ValueChanged<int>? onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final allocation = this.allocation;
    if (allocation != null) {
      return _AllocationPartitionBar(
        allocation: allocation,
        height: height,
        onSegmentTap: onSegmentTap,
      );
    }
    final overviewLimit = overviewLimitAmount ?? 0;
    return Container(
      key: const ValueKey('category-limit-partition-bar'),
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: AppColors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2 - 1),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (overviewLimit > 0) {
              return Stack(
                fit: StackFit.expand,
                children: _budgetSegments(
                  overviewLimit: overviewLimit,
                  maxWidth: constraints.maxWidth,
                ),
              );
            }
            final partitions = LimitPartitionManager.partitions(
              bars: bars,
              activeBar: activeBar,
              activeLimitAmount: activeLimitAmount,
            );
            if (partitions.isEmpty) return const SizedBox.expand();
            return Stack(
              fit: StackFit.expand,
              children: [
                ..._legacySegments(partitions, constraints.maxWidth),
                ..._unitMarks(partitions.length),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _budgetSegments({
    required double overviewLimit,
    required double maxWidth,
  }) {
    final visible = _budgetBars()
        .where((bar) => _limitAmountFor(bar) > 0)
        .toList();
    if (visible.isEmpty) return const [];
    var left = 0.0;
    final children = <Widget>[];
    for (var i = 0; i < visible.length; i += 1) {
      final bar = visible[i];
      final limitAmount = _limitAmountFor(bar);
      final usedAmount = math
          .min(bar.spent, limitAmount)
          .clamp(0.0, limitAmount);
      final remainingAmount = (limitAmount - usedAmount).clamp(
        0.0,
        limitAmount,
      );
      final usedWidth = (maxWidth * usedAmount / overviewLimit)
          .clamp(0.0, maxWidth - left)
          .toDouble();
      final remainingWidth = (maxWidth * remainingAmount / overviewLimit)
          .clamp(0.0, maxWidth - left - usedWidth)
          .toDouble();
      if (usedWidth > 0) {
        children.add(
          Positioned(
            key: ValueKey('category-limit-partition-segment-$i'),
            left: left,
            top: 0,
            width: usedWidth,
            height: height,
            child: ColoredBox(color: bar.color),
          ),
        );
        left += usedWidth;
      }
      if (remainingWidth > 0) {
        children.add(
          Positioned(
            key: ValueKey('category-limit-partition-remaining-$i'),
            left: left,
            top: 0,
            width: remainingWidth,
            height: height,
            child: ColoredBox(color: bar.color.withValues(alpha: 0.70)),
          ),
        );
        left += remainingWidth;
      }
      if (left >= maxWidth) break;
    }
    return children;
  }

  List<CategoryBudgetBarData> _budgetBars() {
    final active = activeBar;
    if (active == null) return bars;
    final result = <CategoryBudgetBarData>[];
    var found = false;
    for (final bar in bars) {
      if (_sameTarget(bar, active)) {
        result.add(active);
        found = true;
      } else {
        result.add(bar);
      }
    }
    if (!found) result.insert(0, active);
    return result;
  }

  double _limitAmountFor(CategoryBudgetBarData bar) {
    final active = activeBar;
    if (active != null && _sameTarget(bar, active)) {
      return activeLimitAmount ?? bar.limitAmount;
    }
    return bar.limitAmount;
  }

  bool _sameTarget(CategoryBudgetBarData left, CategoryBudgetBarData right) {
    return left.targetType == right.targetType &&
        left.targetId == right.targetId &&
        left.transactionType == right.transactionType &&
        left.window == right.window &&
        left.periodKey == right.periodKey;
  }

  List<Widget> _legacySegments(
    List<CategoryLimitPartition> partitions,
    double maxWidth,
  ) {
    var left = 0.0;
    return [
      for (var i = 0; i < partitions.length; i += 1)
        () {
          final partition = partitions[i];
          final width =
              (i == partitions.length - 1
                      ? (maxWidth - left).clamp(0.0, maxWidth)
                      : (maxWidth * partition.fraction).clamp(0.0, maxWidth))
                  .toDouble();
          final segment = Positioned(
            left: left,
            top: 0,
            width: width,
            height: height,
            child: DecoratedBox(
              key: ValueKey('category-limit-partition-segment-$i'),
              decoration: BoxDecoration(
                color: partition.bar.color,
                border: Border.all(
                  color: partition.isActive
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.46),
                  width: partition.isActive ? 2 : 0.5,
                ),
              ),
            ),
          );
          left += width;
          return segment;
        }(),
    ];
  }

  List<Widget> _unitMarks(int count) {
    if (count < 2) return const [];
    return [
      for (var i = 1; i < count; i += 1)
        FractionallySizedBox(
          key: ValueKey('category-limit-partition-unit-$i'),
          widthFactor: i / count,
          alignment: Alignment.centerLeft,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 1,
              color: AppColors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
    ];
  }
}

class _AllocationPartitionBar extends StatelessWidget {
  const _AllocationPartitionBar({
    required this.allocation,
    required this.height,
    this.onSegmentTap,
  });

  final LimitAllocationData allocation;
  final double height;
  final ValueChanged<int>? onSegmentTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('category-limit-partition-bar'),
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var left = 0.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < allocation.segments.length; i += 1)
                () {
                  final segment = allocation.segments[i];
                  final width = constraints.maxWidth * segment.fraction;
                  final targetId = segment.targetId;
                  final onTap = onSegmentTap;
                  final child = Positioned(
                    key: ValueKey('category-limit-partition-segment-$i'),
                    left: left,
                    top: 0,
                    width: width,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: targetId == null || onTap == null
                          ? null
                          : () => onTap(targetId),
                      child: ColoredBox(color: segment.color),
                    ),
                  );
                  left += width;
                  return child;
                }(),
            ],
          );
        },
      ),
    );
  }
}
