import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/limit_partition_manager.dart';
import '../../models/category_budget_bar_data.dart';

class CategorySummaryOutlineBar extends StatelessWidget {
  const CategorySummaryOutlineBar({super.key, required this.bars});

  final List<CategoryBudgetBarData> bars;

  @override
  Widget build(BuildContext context) {
    final partitions = LimitPartitionManager.partitions(bars: bars);
    return Container(
      key: const ValueKey('category-summary-outline-bar'),
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (partitions.isEmpty) return const SizedBox.expand();
            return Stack(
              fit: StackFit.expand,
              children: _segments(partitions, constraints.maxWidth),
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
    const horizontalPadding = 15.0;
    const overlap = 9.0;
    const segmentHeight = 42.0;
    final trackWidth = (maxWidth - horizontalPadding * 2).clamp(0.0, maxWidth);
    final drawableWidth = trackWidth + overlap * (partitions.length - 1);
    var left = horizontalPadding;
    final segments = <Widget>[];

    for (var i = 0; i < partitions.length; i += 1) {
      final partition = partitions[i];
      final segmentWidth = (drawableWidth * partition.fraction)
          .clamp(20.0, drawableWidth)
          .toDouble();
      segments.add(
        Positioned(
          key: ValueKey('category-summary-segment-position-$i'),
          left: left,
          top: 14,
          width: segmentWidth,
          height: segmentHeight,
          child: DecoratedBox(
            key: ValueKey('category-summary-segment-$i'),
            decoration: BoxDecoration(
              color: partition.bar.color,
              borderRadius: BorderRadius.circular(segmentHeight / 2),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.72),
                width: 1,
              ),
            ),
          ),
        ),
      );
      left += segmentWidth - overlap;
    }
    return segments;
  }
}
