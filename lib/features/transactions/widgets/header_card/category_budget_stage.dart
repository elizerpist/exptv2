import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/debug/debug_console.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../data/budget_progress_manager.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/budget_progress_segment.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';
import '../../models/transaction_category.dart';
import 'budget_bar_geometry.dart';
import 'backheader_style_surface.dart';
import 'budget_progress_frame.dart';
import 'category_budget_bar.dart';
import 'transaction_header_metrics.dart';

class CategoryBudgetStage extends StatefulWidget {
  const CategoryBudgetStage({
    super.key,
    this.items,
    this.categoryBars,
    this.periodLabel,
    this.backheaderStyle = BackheaderStyle.classic,
    this.activeKey,
    this.onActiveItemChanged,
    this.onItemTap,
    this.bars,
    this.onBarTap,
  });

  final List<BackheaderBudgetItem>? items;
  final List<CategoryBudgetBarData>? categoryBars;
  final String? periodLabel;
  final BackheaderStyle backheaderStyle;
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
  static const _maxVisualDrag = 72.0;
  static const _switchThreshold = 44.0;

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
    if (widget.backheaderStyle != BackheaderStyle.classic) {
      return _buildExperimentalStage(
        current: current,
        items: items,
        frameProgress: frameProgress,
        frameOverview: frameOverview,
      );
    }
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
            top: 48,
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
                      fontSize: 16.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    current.amountText,
                    key: const ValueKey('backheader-active-amount'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (frameProgress != null && frameOverview != null) ...[
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
              child: SizedBox(
                key: const ValueKey('budget-progress-frame-mask'),
                height: BudgetBarGeometry.barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(
                      BudgetBarGeometry.radius,
                    ),
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            top: BudgetBarGeometry.barTop,
            left: BudgetBarGeometry.barHorizontalInset,
            right: BudgetBarGeometry.barHorizontalInset,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onHorizontalDragStart: (_) {
                    _slideController.stop();
                    _settling = false;
                  },
                  onHorizontalDragUpdate: (details) {
                    if (_settling) return;
                    final nextDx = (_dragDx + details.delta.dx)
                        .clamp(-_maxVisualDrag, _maxVisualDrag)
                        .toDouble();
                    setState(() => _dragDx = nextDx);
                  },
                  onHorizontalDragCancel: () => _animateDragTo(0),
                  onHorizontalDragEnd: (_) => _settleDrag(),
                  onLongPress: _jumpToOverviewForCurrent,
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
                        color: i == _index
                            ? AppColors.primary
                            : AppColors.white,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExperimentalStage({
    required BackheaderBudgetItem current,
    required List<BackheaderBudgetItem> items,
    required BudgetProgressData? frameProgress,
    required OverviewBudgetData? frameOverview,
  }) {
    return SizedBox(
      key: const ValueKey('category-budget-stage'),
      height: TransactionHeaderMetrics.cardHeight,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('backheader-experimental-surface'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(current),
              onHorizontalDragStart: (_) {
                _slideController.stop();
                _settling = false;
              },
              onHorizontalDragUpdate: (details) {
                if (_settling) return;
                final nextDx = (_dragDx + details.delta.dx)
                    .clamp(-_maxVisualDrag, _maxVisualDrag)
                    .toDouble();
                setState(() => _dragDx = nextDx);
              },
              onHorizontalDragCancel: () => _animateDragTo(0),
              onHorizontalDragEnd: (_) => _settleDrag(),
              onLongPress: _jumpToOverviewForCurrent,
              child: Transform.translate(
                offset: Offset(_dragDx, 0),
                child: BackheaderStyleSurface(
                  style: widget.backheaderStyle,
                  current: current,
                  items: items,
                  categoryBars: _categoryBars,
                  frameProgress: frameProgress,
                  frameOverview: frameOverview,
                  activeIndex: _index,
                ),
              ),
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
                        color: i == _index
                            ? AppColors.primary
                            : AppColors.white,
                      ),
                    ),
                ],
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
      if (overview?.kind == BudgetGoalKind.incomeGoal) {
        return overview!.amount;
      }
    }
    return bars
        .where((bar) => bar.transactionType == TransactionType.income)
        .fold<double>(0, (sum, bar) => sum + bar.spent);
  }

  double _periodExpense(List<CategoryBudgetBarData> bars) {
    for (final item in _items) {
      final overview = item.overview;
      if (overview?.kind == BudgetGoalKind.expenseBudget) {
        return overview!.amount;
      }
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

  void _jumpToOverviewForCurrent() {
    if (_settling) return;
    final items = _items;
    if (items.length < 2 || _index >= items.length) return;
    final current = items[_index];
    final category = current.category;
    if (category == null) return;
    final targetIndex = items.indexWhere((item) {
      final overview = item.overview;
      return overview != null &&
          overview.kind.transactionType == category.transactionType.nativeValue;
    });
    if (targetIndex < 0 || targetIndex == _index) return;
    HapticFeedback.selectionClick();
    DebugConsole.log(
      '[BackheaderBudget] long press jump from=${current.key} to=${items[targetIndex].key}',
    );
    _slideController.stop();
    setState(() {
      _index = targetIndex;
      _dragDx = 0;
      _settling = false;
    });
    widget.onActiveItemChanged?.call(items[targetIndex]);
  }

  Future<void> _settleDrag() async {
    if (_settling) return;
    final items = _items;
    if (items.length < 2 || _dragDx.abs() < _switchThreshold) {
      await _animateDragTo(0);
      return;
    }
    await _snapToNext(swipedLeft: _dragDx < 0);
  }

  Future<void> _snapToNext({required bool swipedLeft}) async {
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
      _dragDx = swipedLeft ? _maxVisualDrag : -_maxVisualDrag;
    });
    widget.onActiveItemChanged?.call(_items[_index]);
    await _animateDragTo(
      0,
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 220),
    );
    _settling = false;
  }

  Future<void> _animateDragTo(
    double target, {
    Curve curve = Curves.easeOutCubic,
    Duration duration = const Duration(milliseconds: 160),
  }) {
    _slideController.stop();
    _slideController.duration = duration;
    _slideAnimation = Tween<double>(
      begin: _dragDx,
      end: target,
    ).animate(CurvedAnimation(parent: _slideController, curve: curve));
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
    final spentRatio = overview.hasLimit && overview.limitAmount > 0
        ? (overview.amount / overview.limitAmount).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final visibleRatio = overview.kind.warnsWhenHigh
        ? (1.0 - spentRatio).clamp(0.0, 1.0).toDouble()
        : spentRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = BudgetBarGeometry.visibleWidth(
          availableWidth: constraints.maxWidth,
          height: height,
          ratio: visibleRatio,
        );
        return SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              SizedBox(
                key: const ValueKey('category-budget-background'),
                width: constraints.maxWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: Material(
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
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(height / 2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: height * 0.28),
                              child: Icon(
                                icon,
                                color: AppColors.white,
                                size: height * 0.65,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
