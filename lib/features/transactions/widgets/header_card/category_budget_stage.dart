import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/category_budget_bar_data.dart';
import 'category_budget_bar.dart';
import 'category_summary_outline_bar.dart';
import 'transaction_header_metrics.dart';

class CategoryBudgetStage extends StatefulWidget {
  const CategoryBudgetStage({
    super.key,
    required this.bars,
    required this.onBarTap,
  });

  final List<CategoryBudgetBarData> bars;
  final ValueChanged<CategoryBudgetBarData> onBarTap;

  @override
  State<CategoryBudgetStage> createState() => _CategoryBudgetStageState();
}

class _CategoryBudgetStageState extends State<CategoryBudgetStage> {
  var _index = 0;
  var _dragDx = 0.0;

  @override
  void didUpdateWidget(covariant CategoryBudgetStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.bars.length) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bars.isEmpty) {
      return const SizedBox(
        key: ValueKey('category-budget-stage-empty'),
        height: TransactionHeaderMetrics.cardHeight,
      );
    }
    final current = widget.bars[_index];
    return SizedBox(
      key: const ValueKey('category-budget-stage'),
      height: TransactionHeaderMetrics.cardHeight,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: CategorySummaryOutlineBar(bars: widget.bars),
          ),
          Positioned(
            top: 78,
            left: 40,
            right: 40,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
              onHorizontalDragEnd: (_) => _settleDrag(),
              child: CategoryBudgetBar(
                bar: current,
                height: 54,
                compactIcon: true,
                onTap: () => widget.onBarTap(current),
              ),
            ),
          ),
          if (widget.bars.length > 1)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.bars.length; i += 1)
                    AnimatedContainer(
                      key: ValueKey('category-budget-dot-$i'),
                      duration: const Duration(milliseconds: 150),
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? AppColors.white
                            : AppColors.white.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _settleDrag() {
    if (widget.bars.length < 2) {
      _dragDx = 0;
      return;
    }
    if (_dragDx <= -40) {
      setState(() => _index = (_index + 1) % widget.bars.length);
    } else if (_dragDx >= 40) {
      setState(
        () => _index = _index == 0 ? widget.bars.length - 1 : _index - 1,
      );
    }
    _dragDx = 0;
  }
}
