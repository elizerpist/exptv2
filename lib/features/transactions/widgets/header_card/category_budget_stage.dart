import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/budget_progress_manager.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/budget_progress_segment.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';
import '../../models/transaction_category.dart';
import 'budget_bar_geometry.dart';
import 'budget_progress_frame.dart';
import 'category_budget_bar.dart';
import 'transaction_header_metrics.dart';

class CategoryBudgetStage extends StatefulWidget {
  const CategoryBudgetStage({
    super.key,
    this.items,
    this.categoryBars,
    this.periodLabel,
    this.activeKey,
    this.onActiveItemChanged,
    this.onItemTap,
    this.bars,
    this.onBarTap,
  });

  final List<BackheaderBudgetItem>? items;
  final List<CategoryBudgetBarData>? categoryBars;
  final String? periodLabel;
  final String? activeKey;
  final ValueChanged<BackheaderBudgetItem>? onActiveItemChanged;
  final ValueChanged<BackheaderBudgetItem>? onItemTap;

  // Compatibility for call sites migrated in the next implementation task.
  final List<CategoryBudgetBarData>? bars;
  final ValueChanged<CategoryBudgetBarData>? onBarTap;

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
  var _swipeTriggered = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    )..addListener(_syncSlideAnimation);
    _syncControlledIndex();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CategoryBudgetStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final synced = _syncControlledIndex(resetDrag: true);
    if (_index >= _items.length) _index = 0;
    if (!synced && _items.length != _oldItems(oldWidget).length) _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) {
      return const SizedBox(
        key: ValueKey('category-budget-stage-empty'),
        height: TransactionHeaderMetrics.cardHeight,
      );
    }
    final current = items[_index];
    final frameOverview = _frameOverviewFor(current, items);
    final frameProgress = frameOverview == null
        ? null
        : _progressFor(frameOverview, _categoryBars);
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
            top: 44,
            left: 30,
            right: 30,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    current.title,
                    key: const ValueKey('backheader-active-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  current.amountText,
                  key: const ValueKey('backheader-active-amount'),
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (frameProgress != null && frameOverview != null)
            Positioned(
              top: BudgetBarGeometry.frameTop,
              left: BudgetBarGeometry.frameHorizontalInset,
              right: BudgetBarGeometry.frameHorizontalInset,
              child: BudgetProgressFrame(
                progress: frameProgress,
                kind: frameOverview.kind,
                height: BudgetBarGeometry.frameHeight,
              ),
            ),
          Positioned(
            top: BudgetBarGeometry.barTop,
            left: BudgetBarGeometry.barHorizontalInset,
            right: BudgetBarGeometry.barHorizontalInset,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final settleDistance = constraints.maxWidth + 40;
                return GestureDetector(
                  onHorizontalDragStart: (_) {
                    _slideController.stop();
                    _settling = false;
                    _swipeTriggered = false;
                  },
                  onHorizontalDragUpdate: (details) {
                    if (_settling || _swipeTriggered) return;
                    final nextDx = (_dragDx + details.delta.dx)
                        .clamp(-settleDistance, settleDistance)
                        .toDouble();
                    setState(() => _dragDx = nextDx);
                    if (nextDx.abs() < 56 || _items.length < 2) return;
                    _swipeTriggered = true;
                    unawaited(
                      _snapToNext(
                        settleDistance,
                        swipedLeft: nextDx < 0,
                      ),
                    );
                  },
                  onHorizontalDragCancel: () => _animateDragTo(0),
                  onHorizontalDragEnd: (_) => _settleDrag(settleDistance),
                  child: Transform.translate(
                    key: const ValueKey('category-budget-bar-translation'),
                    offset: Offset(_dragDx, 0),
                    child: _barFor(current),
                  ),
                );
              },
            ),
          ),
          if (items.length > 1)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < items.length; i += 1)
                    AnimatedContainer(
                      key: ValueKey('category-budget-dot-$i'),
                      duration: const Duration(milliseconds: 150),
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index ? AppColors.primary : AppColors.white,
                      ),
                    ),
                ],
              ),
            ),
          if (widget.periodLabel != null)
            Positioned(
              left: 24,
              bottom: 12,
              child: Text(
                widget.periodLabel!,
                key: const ValueKey('backheader-period-label'),
                style: const TextStyle(
                  color: AppColors.gray600,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _syncControlledIndex({bool resetDrag = false}) {
    final activeKey = widget.activeKey;
    if (activeKey == null) return false;
    final nextIndex = _items.indexWhere((item) => item.key == activeKey);
    if (nextIndex < 0) return false;
    _index = nextIndex;
    if (resetDrag) _dragDx = 0;
    return true;
  }

  List<BackheaderBudgetItem> get _items {
    final explicit = widget.items;
    if (explicit != null) return explicit;
    return [
      for (final bar in widget.bars ?? const <CategoryBudgetBarData>[])
        BackheaderBudgetItem.category(bar),
    ];
  }

  List<CategoryBudgetBarData> get _categoryBars {
    final explicit = widget.categoryBars;
    if (explicit != null) return explicit;
    final legacy = widget.bars;
    if (legacy != null) return legacy;
    return [
      for (final item in widget.items ?? const <BackheaderBudgetItem>[])
        if (item.category != null) item.category!,
    ];
  }

  List<BackheaderBudgetItem> _oldItems(CategoryBudgetStage oldWidget) {
    final explicit = oldWidget.items;
    if (explicit != null) return explicit;
    return [
      for (final bar in oldWidget.bars ?? const <CategoryBudgetBarData>[])
        BackheaderBudgetItem.category(bar),
    ];
  }

  Widget _barFor(BackheaderBudgetItem item) {
    final category = item.category;
    if (category != null) {
      return CategoryBudgetBar(
        bar: category,
        height: BudgetBarGeometry.barHeight,
        compactIcon: true,
        onTap: () => _tap(item),
      );
    }
    return _OverviewBudgetBar(
      item: item,
      height: BudgetBarGeometry.barHeight,
      onTap: () => _tap(item),
    );
  }

  void _tap(BackheaderBudgetItem item) {
    widget.onItemTap?.call(item);
    final category = item.category;
    if (category != null) widget.onBarTap?.call(category);
  }

  OverviewBudgetData? _frameOverviewFor(
    BackheaderBudgetItem current,
    List<BackheaderBudgetItem> items,
  ) {
    final currentOverview = current.overview;
    if (currentOverview != null && currentOverview.hasLimit) {
      return currentOverview;
    }
    for (final item in items) {
      final overview = item.overview;
      if (overview != null && overview.hasLimit) return overview;
    }
    return null;
  }

  BudgetProgressData _progressFor(
    OverviewBudgetData overview,
    List<CategoryBudgetBarData> bars,
  ) {
    if (overview.kind == BudgetGoalKind.savingGoal) {
      return BudgetProgressManager.overviewProgress(
        kind: overview.kind,
        limitAmount: overview.limitAmount,
        categoryBars: bars,
        periodIncome: overview.amount,
        periodExpense: 0,
      );
    }
    return BudgetProgressManager.overviewProgress(
      kind: overview.kind,
      limitAmount: overview.limitAmount,
      categoryBars: bars,
      periodIncome: _periodIncome(bars),
      periodExpense: _periodExpense(bars),
    );
  }

  double _periodIncome(List<CategoryBudgetBarData> bars) {
    for (final item in _items) {
      final overview = item.overview;
      if (overview?.kind == BudgetGoalKind.incomeGoal) return overview!.amount;
    }
    return bars
        .where((bar) => bar.transactionType == TransactionType.income)
        .fold<double>(0, (sum, bar) => sum + bar.spent);
  }

  double _periodExpense(List<CategoryBudgetBarData> bars) {
    for (final item in _items) {
      final overview = item.overview;
      if (overview?.kind == BudgetGoalKind.expenseBudget) return overview!.amount;
    }
    return bars
        .where((bar) => bar.transactionType == TransactionType.expense)
        .fold<double>(0, (sum, bar) => sum + bar.spent);
  }

  void _syncSlideAnimation() {
    final animation = _slideAnimation;
    if (animation == null || !mounted) return;
    setState(() => _dragDx = animation.value);
  }

  Future<void> _settleDrag(double settleDistance) async {
    if (_settling || _swipeTriggered) return;
    final items = _items;
    if (items.length < 2) {
      await _animateDragTo(0);
      return;
    }

    final start = _dragDx;
    if (start.abs() < 40) {
      await _animateDragTo(0);
      return;
    }

    await _snapToNext(settleDistance, swipedLeft: start < 0);
  }

  Future<void> _snapToNext(
    double settleDistance, {
    required bool swipedLeft,
  }) async {
    if (_settling) return;
    final items = _items;
    if (items.length < 2) return;
    _settling = true;
    setState(() {
      _index = swipedLeft
          ? (_index + 1) % items.length
          : _index == 0
          ? items.length - 1
          : _index - 1;
      _dragDx = swipedLeft ? settleDistance * 0.18 : -settleDistance * 0.18;
    });
    widget.onActiveItemChanged?.call(_items[_index]);
    await _animateDragTo(
      0,
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 240),
    );
    _settling = false;
    _swipeTriggered = false;
  }

  Future<void> _animateDragTo(
    double target, {
    Curve curve = Curves.easeOutCubic,
    Duration duration = const Duration(milliseconds: 160),
  }) {
    _slideController.stop();
    _slideController.duration = duration;
    _slideAnimation = Tween<double>(begin: _dragDx, end: target).animate(
      CurvedAnimation(parent: _slideController, curve: curve),
    );
    return _slideController.forward(from: 0);
  }
}

class _OverviewBudgetBar extends StatelessWidget {
  const _OverviewBudgetBar({
    required this.item,
    required this.onTap,
    required this.height,
  });

  final BackheaderBudgetItem item;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final overview = item.overview!;
    final color = switch (overview.kind) {
      BudgetGoalKind.expenseBudget => AppColors.primary,
      BudgetGoalKind.incomeGoal => AppColors.income,
      BudgetGoalKind.savingGoal => BudgetProgressManager.savingColor,
    };
    final icon = switch (overview.kind) {
      BudgetGoalKind.expenseBudget => Icons.account_balance_wallet_outlined,
      BudgetGoalKind.incomeGoal => Icons.trending_up,
      BudgetGoalKind.savingGoal => Icons.savings_outlined,
    };
    final progress = overview.hasLimit && overview.limitAmount > 0
        ? (overview.amount / overview.limitAmount).clamp(0.0, 1.0).toDouble()
        : 1.0;
    return Material(
      key: const ValueKey('category-budget-bar'),
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(height / 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(height / 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: color.withValues(alpha: 0.30)),
                FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: ColoredBox(color: color),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Icon(icon, color: AppColors.white, size: 35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
