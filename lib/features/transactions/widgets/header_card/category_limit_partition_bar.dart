import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/limit_partition_manager.dart';
import '../../models/category_budget_bar_data.dart';

class CategoryLimitPartitionBar extends StatelessWidget {
  const CategoryLimitPartitionBar({
    super.key,
    required this.bars,
    this.activeBar,
    this.activeLimitAmount,
    this.height = 42,
  });

  final List<CategoryBudgetBarData> bars;
  final CategoryBudgetBarData? activeBar;
  final double? activeLimitAmount;
  final double height;

  @override
  Widget build(BuildContext context) {
    final partitions = LimitPartitionManager.partitions(
      bars: bars,
      activeBar: activeBar,
      activeLimitAmount: activeLimitAmount,
    );
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
            if (partitions.isEmpty) return const SizedBox.expand();
            return Stack(
              fit: StackFit.expand,
              children: [
                ..._segments(partitions, constraints.maxWidth),
                ..._unitMarks(partitions.length),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _segments(
    List<CategoryLimitPartition> partitions,
    double maxWidth,
  ) {
    var left = 0.0;
    return [
      for (var i = 0; i < partitions.length; i += 1)
        () {
          final partition = partitions[i];
          final width = (i == partitions.length - 1
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
