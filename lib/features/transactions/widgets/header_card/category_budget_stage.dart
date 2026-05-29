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

class _CategoryBudgetStageState extends State<CategoryBudgetStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  Animation<double>? _slideAnimation;
  var _index = 0;
  var _dragDx = 0.0;
  var _settling = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    )..addListener(_syncSlideAnimation);
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CategoryBudgetStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.bars.length) _index = 0;
    if (oldWidget.bars.length != widget.bars.length) _dragDx = 0;
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final settleDistance = constraints.maxWidth + 40;
                return GestureDetector(
                  onHorizontalDragStart: (_) {
                    _slideController.stop();
                    _settling = false;
                  },
                  onHorizontalDragUpdate: (details) {
                    if (_settling) return;
                    setState(() {
                      _dragDx = (_dragDx + details.delta.dx)
                          .clamp(-settleDistance, settleDistance)
                          .toDouble();
                    });
                  },
                  onHorizontalDragCancel: () => _animateDragTo(0),
                  onHorizontalDragEnd: (_) => _settleDrag(settleDistance),
                  child: Transform.translate(
                    key: const ValueKey('category-budget-bar-translation'),
                    offset: Offset(_dragDx, 0),
                    child: CategoryBudgetBar(
                      bar: current,
                      height: 54,
                      compactIcon: true,
                      onTap: () => widget.onBarTap(current),
                    ),
                  ),
                );
              },
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

  void _syncSlideAnimation() {
    final animation = _slideAnimation;
    if (animation == null || !mounted) return;
    setState(() => _dragDx = animation.value);
  }

  Future<void> _settleDrag(double settleDistance) async {
    if (_settling) return;
    if (widget.bars.length < 2) {
      await _animateDragTo(0);
      return;
    }

    final start = _dragDx;
    if (start.abs() < 40) {
      await _animateDragTo(0);
      return;
    }

    _settling = true;
    final swipedLeft = start < 0;
    final exitOffset = swipedLeft ? -settleDistance : settleDistance;
    await _animateDragTo(exitOffset);
    if (!mounted) return;

    setState(() {
      _index = swipedLeft
          ? (_index + 1) % widget.bars.length
          : _index == 0
          ? widget.bars.length - 1
          : _index - 1;
      _dragDx = -exitOffset;
    });
    await _animateDragTo(0);
    _settling = false;
  }

  Future<void> _animateDragTo(double target) {
    _slideController.stop();
    _slideAnimation = Tween<double>(begin: _dragDx, end: target).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    return _slideController.forward(from: 0);
  }
}
