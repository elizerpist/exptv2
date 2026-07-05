import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/debug/debug_console.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../data/budget_progress_manager.dart';
import '../../data/limit_allocation_manager.dart';
import '../../data/limit_slider_range.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/budget_progress_segment.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_record.dart';
import '../transaction_menu_metrics.dart';
import 'budget_bar_geometry.dart';
import 'backheader_style_surface.dart';
import 'budget_progress_frame.dart';
import 'category_budget_bar.dart';
import 'category_limit_partition_bar.dart';
import 'category_limit_slider.dart';
import 'category_progress_bar.dart';
import 'transaction_header_metrics.dart';

class CategoryBudgetStage extends StatefulWidget {
  const CategoryBudgetStage({
    super.key,
    this.items,
    this.categoryBars,
    this.periodLabel,
    this.backheaderStyle = BackheaderStyle.classic,
    this.backgroundColor = AppColors.gray100,
    this.activeKey,
    this.onActiveItemChanged,
    this.onItemTap,
    this.bars,
    this.onBarTap,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.overviewItems = const [],
    this.periodIncome = 0,
    this.onJumpToIncome,
    this.onSaveOverview,
    this.onSaveCategory,
  });

  final List<BackheaderBudgetItem>? items;
  final List<CategoryBudgetBarData>? categoryBars;
  final String? periodLabel;
  final BackheaderStyle backheaderStyle;
  final Color backgroundColor;
  final String? activeKey;
  final ValueChanged<BackheaderBudgetItem>? onActiveItemChanged;
  final ValueChanged<BackheaderBudgetItem>? onItemTap;
  final ExpenseSurfaceInteraction surfaceStyle;
  final List<OverviewBudgetData> overviewItems;
  final double periodIncome;
  final VoidCallback? onJumpToIncome;
  final Future<void> Function(
    BudgetGoalKind kind, {
    required double limitAmount,
    required bool alertActive,
  })?
  onSaveOverview;
  final Future<void> Function(
    CategoryBudgetBarData bar, {
    required double limitAmount,
    required bool alertActive,
  })?
  onSaveCategory;

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
  static const _orbitAxisSlop = 8.0;
  static const _orbitVerticalBias = 1.25;
  static const _orbitShrinkArmDistance = 10.0;

  late final AnimationController _slideController;
  Animation<double>? _slideAnimation;
  late final TextEditingController _orbitAmountController;
  late final FocusNode _orbitAmountFocus;
  final _orbitRememberedSliderMaxByKey = <String, double>{};
  final _orbitPendingAmountsByKey = <String, double>{};
  final _orbitQueuedSavesByKey = <String, _OrbitSaveRequest>{};
  final _orbitSavingKeys = <String>{};
  Timer? _orbitSaveDebounce;
  var _index = 0;
  var _dragDx = 0.0;
  var _settling = false;
  var _orbitExpansion = 0.0;
  var _orbitDragStartExpansion = 0.0;
  var _orbitGestureDx = 0.0;
  var _orbitGestureDy = 0.0;
  var _orbitExpanded = false;
  var _orbitShrinkArmed = false;
  var _orbitAcceptedVerticalDrag = false;
  var _orbitRejectedDrag = false;
  var _orbitDragStartedExpanded = false;
  var _orbitExpandTriggered = false;
  var _orbitHandlePointerActive = false;
  var _orbitSuppressHorizontalDrag = false;
  var _orbitUpdatingController = false;

  @override
  void initState() {
    super.initState();
    _orbitAmountController = TextEditingController()
      ..addListener(_handleOrbitAmountInputChanged);
    _orbitAmountFocus = FocusNode();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    )..addListener(_syncSlideAnimation);
    _syncControlledIndex();
    if (_items.isNotEmpty) _syncOrbitAmountController(_items[_index]);
  }

  @override
  void dispose() {
    _orbitSaveDebounce?.cancel();
    _orbitAmountFocus.dispose();
    _orbitAmountController
      ..removeListener(_handleOrbitAmountInputChanged)
      ..dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CategoryBudgetStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final synced = _syncControlledIndex(resetDrag: true);
    if (_index >= _items.length) _index = 0;
    if (!synced && _items.length != _oldItems(oldWidget).length) _dragDx = 0;
    if (_items.isNotEmpty) _syncOrbitAmountController(_items[_index]);
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
              key: const ValueKey('category-budget-stage-background'),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
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
                  fit: FlexFit.tight,
                  child: Align(
                    alignment: Alignment.centerRight,
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
                    color: widget.backgroundColor,
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
          if (items.length > 1 &&
              widget.backheaderStyle != BackheaderStyle.orbitBudget)
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
    final isOrbitBudget = widget.backheaderStyle == BackheaderStyle.orbitBudget;
    return SizedBox(
      key: const ValueKey('category-budget-stage'),
      height:
          TransactionHeaderMetrics.cardHeight +
          (isOrbitBudget ? _orbitExpansion : 0),
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('backheader-experimental-surface'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(current),
              onHorizontalDragStart: (_) {
                if (_orbitHandlePointerActive) {
                  _orbitSuppressHorizontalDrag = true;
                  return;
                }
                _slideController.stop();
                _settling = false;
              },
              onHorizontalDragUpdate: (details) {
                if (_orbitSuppressHorizontalDrag) return;
                if (_settling) return;
                final nextDx = (_dragDx + details.delta.dx)
                    .clamp(-_maxVisualDrag, _maxVisualDrag)
                    .toDouble();
                setState(() => _dragDx = nextDx);
              },
              onHorizontalDragCancel: () {
                if (_orbitSuppressHorizontalDrag) {
                  _orbitSuppressHorizontalDrag = false;
                  return;
                }
                _animateDragTo(0);
              },
              onHorizontalDragEnd: (_) {
                if (_orbitSuppressHorizontalDrag) {
                  _orbitSuppressHorizontalDrag = false;
                  return;
                }
                _settleDrag();
              },
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
                  backgroundColor: widget.backgroundColor,
                  orbitPartitionBar:
                      widget.backheaderStyle == BackheaderStyle.orbitBudget
                      ? _orbitPartitionBarFor(current)
                      : null,
                  orbitProgress: _orbitProgressFor(current),
                  orbitHasLimit: _orbitHasLimit(current),
                  orbitAmountText: isOrbitBudget
                      ? _orbitAmountTextFor(current)
                      : null,
                  orbitTopPadding:
                      isOrbitBudget && (_orbitExpanded || _orbitExpansion > 0)
                      ? 64
                      : 42,
                  orbitInlineEditor: isOrbitBudget && _orbitExpanded
                      ? _buildOrbitInlineEditor(current)
                      : null,
                  onOrbitHandlePointerDown: isOrbitBudget
                      ? _handleOrbitHandlePointerDown
                      : null,
                  onOrbitHandlePointerMove: isOrbitBudget
                      ? _handleOrbitHandlePointerMove
                      : null,
                  onOrbitHandlePointerUp: isOrbitBudget
                      ? _handleOrbitHandlePointerUp
                      : null,
                  onOrbitHandlePointerCancel: isOrbitBudget
                      ? _handleOrbitHandlePointerCancel
                      : null,
                ),
              ),
            ),
          ),
          if (items.length > 1 &&
              widget.backheaderStyle != BackheaderStyle.orbitBudget)
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
        surfaceStyle: widget.surfaceStyle,
        surfaceIndex: _index,
        onTap: () => _tap(item),
      );
    }
    return _OverviewBudgetBar(
      item: item,
      height: BudgetBarGeometry.barHeight,
      backgroundColor: widget.backgroundColor,
      onTap: () => _tap(item),
    );
  }

  void _tap(BackheaderBudgetItem item) {
    if (widget.backheaderStyle == BackheaderStyle.orbitBudget) return;
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

  Widget _orbitPartitionBarFor(BackheaderBudgetItem current) {
    if (current.overview?.kind == BudgetGoalKind.savingGoal) {
      return const SizedBox.shrink();
    }
    final allocation = LimitAllocationManager.build(
      overviewLimit: _orbitOverviewLimitAmount(current),
      bars: _orbitPartitionBars,
    );
    return CategoryLimitPartitionBar(height: 14, allocation: allocation);
  }

  double _orbitOverviewLimitAmount(BackheaderBudgetItem current) {
    final overview = current.overview;
    if (overview != null) {
      return _orbitEffectiveAmountFor(current);
    }
    final category = current.category;
    if (category == null) return 0;
    for (final item in _items) {
      final overview = item.overview;
      if (overview == null || overview.kind == BudgetGoalKind.savingGoal) {
        continue;
      }
      if (overview.kind.transactionType ==
          category.transactionType.nativeValue) {
        return _orbitEffectiveAmountFor(item);
      }
    }
    return _orbitEffectiveAmountFor(current);
  }

  bool _orbitHasLimit(BackheaderBudgetItem item) {
    return _orbitEffectiveAmountFor(item) > 0;
  }

  double _orbitProgressFor(BackheaderBudgetItem item) {
    final overview = item.overview;
    final amount = _orbitEffectiveAmountFor(item);
    if (overview != null) {
      if (amount <= 0) return 0;
      return (overview.amount / amount).clamp(0.0, 1.0).toDouble();
    }
    final category = item.category;
    if (category == null) return 0;
    if (amount <= 0) return 0;
    return (category.spent / amount).clamp(0.0, 1.0).toDouble();
  }

  String _orbitAmountTextFor(BackheaderBudgetItem item) {
    final amount = _orbitEffectiveAmountFor(item);
    final overview = item.overview;
    if (overview != null) {
      final formattedAmount = formatHuf(overview.amount);
      return amount > 0
          ? '$formattedAmount / ${formatHuf(amount)}'
          : formattedAmount;
    }
    final category = item.category;
    if (category == null) return item.amountText;
    return amount > 0
        ? '${category.formattedSpent} / ${formatHuf(amount)}'
        : category.formattedSpent;
  }

  Widget _buildOrbitInlineEditor(BackheaderBudgetItem current) {
    _syncOrbitAmountController(current);
    final range = _orbitSliderRangeFor(current);
    final showSetToMax = current.overview != null;
    final canJump = _orbitCanJump(current);
    return KeyedSubtree(
      key: const ValueKey('backheader-orbit-inline-editor'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: const ValueKey('backheader-orbit-slider'),
            height: 30,
            child: CategoryLimitSlider(
              value: range.value,
              max: range.max,
              divisions: range.divisions,
              enabled: range.enabled,
              activeColor: AppColors.white,
              onChanged: (amount) => _setOrbitAmountFromSlider(current, amount),
              onChangeEnd: (amount) =>
                  _setOrbitAmountFromSlider(current, amount, flush: true),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canJump) ...[
                  _OrbitCompactIconButton(
                    buttonKey: const ValueKey(
                      'backheader-overview-jump-button',
                    ),
                    icon: _orbitJumpIconFor(current),
                    tooltip: _orbitJumpTooltipFor(current),
                    onPressed: () => _handleOrbitJump(current),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: _OrbitAmountPill(
                    controller: _orbitAmountController,
                    focusNode: _orbitAmountFocus,
                    label: _orbitInputLabelFor(current),
                    onChanged: (text) =>
                        _setOrbitAmountFromInput(current, text, flush: false),
                    showSetToMax: showSetToMax,
                    onSetToMax: () => _setOrbitOverviewToMax(current),
                    onReset: () => _setOrbitAmount(current, 0, flush: true),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LimitSliderRange _orbitSliderRangeFor(BackheaderBudgetItem item) {
    final amount = _orbitEffectiveAmountFor(item);
    final remembered = _orbitRememberedSliderMaxByKey[item.key] ?? 0;
    final overview = item.overview;
    if (overview != null) {
      if (widget.periodIncome > 0) {
        return LimitSliderRange.constrained(
          amount: amount,
          rememberedMax: remembered,
          maxAllowed: math.max(widget.periodIncome, amount),
          hasExistingLimit: amount > 0,
        );
      }
      return LimitSliderRange.unconstrained(
        amount: amount,
        rememberedMax: remembered,
      );
    }

    final category = item.category;
    if (category == null) {
      return const LimitSliderRange(
        value: 0,
        max: 1,
        divisions: 1,
        enabled: false,
      );
    }
    final overviewLimit = _orbitMatchingOverviewLimitForCategory(category);
    if (overviewLimit <= 0) {
      return LimitSliderRange.unconstrained(
        amount: amount,
        rememberedMax: remembered,
      );
    }
    final activePreview = _orbitPreviewCategoryBar(category, amount);
    final maxAllowed = LimitAllocationManager.categorySliderMax(
      overviewLimit: overviewLimit,
      bars: _orbitPartitionBars,
      activeBar: activePreview,
    );
    return LimitSliderRange.constrained(
      amount: amount,
      rememberedMax: remembered,
      maxAllowed: maxAllowed,
      hasExistingLimit: _orbitLimitAmountFor(item) > 0 || amount > 0,
    );
  }

  List<CategoryBudgetBarData> get _orbitPartitionBars {
    final result = <CategoryBudgetBarData>[];
    for (final bar in _categoryBars) {
      final item = _orbitItemForCategoryBar(bar);
      final amount = item == null
          ? bar.limitAmount
          : _orbitEffectiveAmountFor(item);
      result.add(_orbitPreviewCategoryBar(bar, amount));
    }
    final activeCategory = _items[_index].category;
    if (activeCategory != null &&
        !result.any((bar) => _orbitSameTarget(bar, activeCategory))) {
      result.insert(
        0,
        _orbitPreviewCategoryBar(
          activeCategory,
          _orbitEffectiveAmountFor(_items[_index]),
        ),
      );
    }
    return result;
  }

  CategoryBudgetBarData _orbitPreviewCategoryBar(
    CategoryBudgetBarData category,
    double amount,
  ) {
    final hasLimit = amount > 0;
    return CategoryBudgetBarData(
      key: category.key,
      targetType: category.targetType,
      targetId: category.targetId,
      transactionType: category.transactionType,
      window: category.window,
      periodKey: category.periodKey,
      title: category.title,
      spent: category.spent,
      hasLimit: hasLimit,
      limitAmount: hasLimit ? amount : 0,
      alertActive: hasLimit,
      color: category.color,
      iconSlot: category.iconSlot,
      category: category.category,
      sourceLimit: category.sourceLimit,
    );
  }

  double _orbitMatchingOverviewLimitForCategory(
    CategoryBudgetBarData category,
  ) {
    for (final item in _items) {
      final overview = item.overview;
      if (overview == null || overview.kind == BudgetGoalKind.savingGoal) {
        continue;
      }
      if (overview.kind.transactionType !=
          category.transactionType.nativeValue) {
        continue;
      }
      return _orbitEffectiveAmountFor(item);
    }
    for (final overview in widget.overviewItems) {
      if (overview.kind == BudgetGoalKind.savingGoal) continue;
      if (overview.kind.transactionType !=
          category.transactionType.nativeValue) {
        continue;
      }
      return _orbitEffectiveAmountFor(BackheaderBudgetItem.overview(overview));
    }
    return 0;
  }

  BackheaderBudgetItem? _orbitItemForCategoryBar(CategoryBudgetBarData bar) {
    for (final item in _items) {
      final category = item.category;
      if (category != null && _orbitSameTarget(category, bar)) return item;
    }
    return null;
  }

  bool _orbitSameTarget(
    CategoryBudgetBarData left,
    CategoryBudgetBarData right,
  ) {
    return left.targetType == right.targetType &&
        left.targetId == right.targetId &&
        left.transactionType == right.transactionType &&
        left.window == right.window &&
        left.periodKey == right.periodKey;
  }

  double _orbitEffectiveAmountFor(BackheaderBudgetItem item) {
    return _orbitPendingAmountsByKey[item.key] ?? _orbitLimitAmountFor(item);
  }

  double _orbitLimitAmountFor(BackheaderBudgetItem item) {
    final overview = item.overview;
    if (overview != null && overview.hasLimit) return overview.limitAmount;
    final category = item.category;
    if (category != null && category.hasLimit) return category.limitAmount;
    return 0;
  }

  String _orbitInputLabelFor(BackheaderBudgetItem item) {
    final overview = item.overview;
    if (overview == null) return 'Kategória limit';
    return switch (overview.kind) {
      BudgetGoalKind.expenseBudget => 'Budget limit',
      BudgetGoalKind.incomeGoal => 'Bevételi cél',
      BudgetGoalKind.savingGoal => 'Megtakarítási cél',
    };
  }

  void _handleOrbitAmountInputChanged() {
    if (_orbitUpdatingController || _items.isEmpty) return;
    _setOrbitAmountFromInput(
      _items[_index],
      _orbitAmountController.text,
      updateController: false,
    );
  }

  void _setOrbitAmountFromInput(
    BackheaderBudgetItem item,
    String text, {
    bool updateController = false,
    bool flush = false,
  }) {
    final value = text.trim().replaceAll(' ', '');
    final amount = math.max(0, double.tryParse(value) ?? 0).toDouble();
    _setOrbitAmount(
      item,
      amount,
      updateController: updateController,
      flush: flush,
    );
  }

  void _syncOrbitAmountController(BackheaderBudgetItem item) {
    if (_orbitAmountFocus.hasFocus && !_orbitUpdatingController) return;
    final amount = _orbitEffectiveAmountFor(item);
    final text = amount > 0 ? amount.round().toString() : '';
    if (_orbitAmountController.text == text) return;
    _orbitUpdatingController = true;
    _orbitAmountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _orbitUpdatingController = false;
  }

  void _setOrbitAmountFromSlider(
    BackheaderBudgetItem item,
    double amount, {
    bool flush = false,
  }) {
    final range = _orbitSliderRangeFor(item);
    final snapped = LimitAllocationManager.snapSliderAmount(
      amount,
    ).clamp(0.0, range.max).toDouble();
    _setOrbitAmount(item, snapped, flush: flush);
  }

  void _setOrbitOverviewToMax(BackheaderBudgetItem item) {
    final max = math.max(0.0, widget.periodIncome).toDouble();
    _setOrbitAmount(item, max, flush: true);
  }

  void _setOrbitAmount(
    BackheaderBudgetItem item,
    double rawAmount, {
    bool updateController = true,
    bool flush = false,
    bool snap = false,
  }) {
    final range = _orbitSliderRangeFor(item);
    final normalized = math.max(0.0, rawAmount).toDouble();
    final amount =
        (snap
                ? LimitAllocationManager.snapSliderAmount(normalized)
                : normalized)
            .clamp(0.0, range.max)
            .toDouble();
    final current = _orbitEffectiveAmountFor(item);
    if ((current - amount).abs() < 0.01) {
      if (updateController) _syncOrbitAmountController(item);
      return;
    }
    _orbitRememberedSliderMaxByKey[item.key] = math.max(
      _orbitRememberedSliderMaxByKey[item.key] ?? 0,
      amount,
    );
    _orbitPendingAmountsByKey[item.key] = amount;
    if (updateController &&
        _items.isNotEmpty &&
        _items[_index].key == item.key) {
      final text = amount > 0 ? amount.round().toString() : '';
      if (_orbitAmountController.text != text) {
        _orbitUpdatingController = true;
        _orbitAmountController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        _orbitUpdatingController = false;
      }
    }
    setState(() {});
    _scheduleOrbitSave(item, amount, flush: flush);
  }

  void _selectOrbitIndex(int nextIndex) {
    final items = _items;
    if (nextIndex < 0 || nextIndex >= items.length || nextIndex == _index) {
      return;
    }
    _slideController.stop();
    setState(() {
      _index = nextIndex;
      _dragDx = 0;
      _settling = false;
    });
    _syncOrbitAmountController(items[nextIndex]);
    widget.onActiveItemChanged?.call(items[nextIndex]);
  }

  int? _orbitMatchingOverviewIndexFor(BackheaderBudgetItem item) {
    final category = item.category;
    if (category == null) return null;
    final targetIndex = _items.indexWhere((candidate) {
      final overview = candidate.overview;
      return overview != null &&
          overview.kind.transactionType == category.transactionType.nativeValue;
    });
    if (targetIndex < 0 || targetIndex == _index) return null;
    return targetIndex;
  }

  bool _orbitCanJump(BackheaderBudgetItem item) {
    return _orbitMatchingOverviewIndexFor(item) != null ||
        _orbitCanJumpToIncome(item);
  }

  bool _orbitCanJumpToIncome(BackheaderBudgetItem item) {
    return widget.onJumpToIncome != null &&
        item.overview?.kind == BudgetGoalKind.expenseBudget;
  }

  IconData _orbitJumpIconFor(BackheaderBudgetItem item) {
    if (_orbitCanJumpToIncome(item)) return Icons.trending_up;
    return Icons.account_balance_wallet_outlined;
  }

  String _orbitJumpTooltipFor(BackheaderBudgetItem item) {
    if (_orbitCanJumpToIncome(item)) return 'Bevétel';
    return 'Összesítő';
  }

  void _handleOrbitJump(BackheaderBudgetItem item) {
    final targetIndex = _orbitMatchingOverviewIndexFor(item);
    if (targetIndex != null) {
      _jumpToOverviewForCurrent();
      return;
    }
    if (_orbitCanJumpToIncome(item)) {
      HapticFeedback.selectionClick();
      widget.onJumpToIncome?.call();
    }
  }

  void _scheduleOrbitSave(
    BackheaderBudgetItem item,
    double amount, {
    bool flush = false,
  }) {
    _orbitQueuedSavesByKey[item.key] = _OrbitSaveRequest(item, amount);
    final canStartNow = !_orbitSavingKeys.contains(item.key);
    if (flush || canStartNow) {
      _flushOrbitSaves();
      return;
    }
    _orbitSaveDebounce?.cancel();
    _orbitSaveDebounce = Timer(
      const Duration(milliseconds: 120),
      _flushOrbitSaves,
    );
  }

  void _flushOrbitSaves() {
    _orbitSaveDebounce?.cancel();
    _orbitSaveDebounce = null;
    final requests = _orbitQueuedSavesByKey.values.toList();
    for (final request in requests) {
      if (_orbitSavingKeys.contains(request.item.key)) continue;
      _orbitQueuedSavesByKey.remove(request.item.key);
      _startOrbitSave(request);
    }
  }

  void _startOrbitSave(_OrbitSaveRequest request) {
    final key = request.item.key;
    _orbitSavingKeys.add(key);
    unawaited(() async {
      try {
        await _saveOrbitItemAmount(request.item, request.amount);
      } catch (error) {
        DebugConsole.log(
          '[BackheaderBudget] orbit inline save failed key=$key error=$error',
        );
      } finally {
        _orbitSavingKeys.remove(key);
        if (_orbitQueuedSavesByKey.containsKey(key)) {
          _flushOrbitSaves();
        }
        if (mounted) setState(() {});
      }
    }());
  }

  Future<void> _saveOrbitItemAmount(
    BackheaderBudgetItem item,
    double rawAmount,
  ) async {
    final amount = math.max(0.0, rawAmount).toDouble();
    final alertActive = amount > 0;
    final overview = item.overview;
    final category = item.category;
    if (overview != null) {
      await widget.onSaveOverview?.call(
        overview.kind,
        limitAmount: amount,
        alertActive: alertActive,
      );
    } else if (category != null) {
      await widget.onSaveCategory?.call(
        category,
        limitAmount: amount,
        alertActive: alertActive,
      );
    }
  }

  double get _orbitMaxExpansion {
    return math
        .max(
          0.0,
          TransactionHeaderMetrics.contentTop +
              TransactionMenuMetrics.typePillTopPadding +
              TransactionMenuMetrics.typePillMinHeight -
              TransactionHeaderMetrics.cardHeight,
        )
        .toDouble();
  }

  void _handleOrbitHandlePointerDown(PointerDownEvent event) {
    _orbitHandlePointerActive = true;
    _orbitSuppressHorizontalDrag = false;
    _orbitDragStartExpansion = _orbitExpansion;
    _orbitGestureDx = 0;
    _orbitGestureDy = 0;
    _orbitAcceptedVerticalDrag = false;
    _orbitRejectedDrag = false;
    _orbitDragStartedExpanded = _orbitExpanded;
    _orbitExpandTriggered = _orbitExpanded;
    _orbitShrinkArmed = false;
  }

  void _handleOrbitHandlePointerMove(PointerMoveEvent event) {
    if (widget.backheaderStyle != BackheaderStyle.orbitBudget) return;
    _orbitGestureDx += event.delta.dx;
    _orbitGestureDy += event.delta.dy;
    if (_orbitRejectedDrag) return;

    if (!_orbitAcceptedVerticalDrag) {
      final absDx = _orbitGestureDx.abs();
      final absDy = _orbitGestureDy.abs();
      if (absDx > _orbitAxisSlop && absDx >= absDy) {
        _orbitRejectedDrag = true;
        return;
      }
      if (absDy <= _orbitAxisSlop) return;
      if (absDy < absDx * _orbitVerticalBias || _orbitGestureDy <= 0) {
        _orbitRejectedDrag = true;
        return;
      }
      _orbitAcceptedVerticalDrag = true;
    }

    final maxExpansion = _orbitMaxExpansion;
    final dragLimit = _orbitDragStartedExpanded
        ? maxExpansion + _orbitShrinkArmDistance
        : maxExpansion;
    final nextExpansion = (_orbitDragStartExpansion + _orbitGestureDy)
        .clamp(0.0, dragLimit)
        .toDouble();
    var nextShrinkArmed = _orbitShrinkArmed;
    var nextExpandTriggered = _orbitExpandTriggered;
    if (!_orbitDragStartedExpanded &&
        !nextExpandTriggered &&
        nextExpansion >= maxExpansion) {
      nextExpandTriggered = true;
      HapticFeedback.selectionClick();
    }
    if (_orbitDragStartedExpanded) {
      final armed =
          nextExpansion >= maxExpansion + _orbitShrinkArmDistance - 0.1;
      if (armed != nextShrinkArmed) {
        nextShrinkArmed = armed;
        HapticFeedback.selectionClick();
      }
    }
    setState(() {
      _orbitExpansion = nextExpansion;
      _orbitShrinkArmed = nextShrinkArmed;
      _orbitExpandTriggered = nextExpandTriggered;
    });
  }

  void _handleOrbitHandlePointerUp(PointerUpEvent event) {
    _orbitHandlePointerActive = false;
    if (!_orbitAcceptedVerticalDrag || _orbitRejectedDrag) {
      _resetOrbitHandleGesture();
      return;
    }
    final maxExpansion = _orbitMaxExpansion;
    setState(() {
      if (_orbitDragStartedExpanded) {
        if (_orbitShrinkArmed) {
          _orbitExpanded = false;
          _orbitExpansion = 0;
        } else {
          _orbitExpanded = true;
          _orbitExpansion = maxExpansion;
        }
      } else if (_orbitExpansion >= maxExpansion) {
        _orbitExpanded = true;
        _orbitExpansion = maxExpansion;
      } else {
        _orbitExpanded = false;
        _orbitExpansion = 0;
      }
      _orbitShrinkArmed = false;
    });
    _resetOrbitHandleGesture();
  }

  void _handleOrbitHandlePointerCancel(PointerCancelEvent event) {
    _orbitHandlePointerActive = false;
    if (_orbitAcceptedVerticalDrag && !_orbitRejectedDrag) {
      setState(() {
        _orbitExpansion = _orbitExpanded ? _orbitMaxExpansion : 0;
        _orbitShrinkArmed = false;
      });
    }
    _resetOrbitHandleGesture();
  }

  void _resetOrbitHandleGesture() {
    _orbitDragStartExpansion = _orbitExpansion;
    _orbitGestureDx = 0;
    _orbitGestureDy = 0;
    _orbitAcceptedVerticalDrag = false;
    _orbitRejectedDrag = false;
    _orbitDragStartedExpanded = false;
    _orbitExpandTriggered = _orbitExpanded;
    _orbitShrinkArmed = false;
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
    final targetIndex = _orbitMatchingOverviewIndexFor(current);
    if (targetIndex == null) return;
    HapticFeedback.selectionClick();
    DebugConsole.log(
      '[BackheaderBudget] long press jump from=${current.key} to=${items[targetIndex].key}',
    );
    _selectOrbitIndex(targetIndex);
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
    required this.backgroundColor,
  });

  final BackheaderBudgetItem item;
  final VoidCallback onTap;
  final double height;
  final Color backgroundColor;

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
                    color: backgroundColor,
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
                        child: ColoredBox(
                          color: color,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Align(
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
                              if (overview.hasLimit)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 12,
                                  child: CategoryProgressBar(
                                    spent: overview.amount,
                                    limitAmount: overview.limitAmount,
                                  ),
                                ),
                            ],
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

class _OrbitSaveRequest {
  const _OrbitSaveRequest(this.item, this.amount);

  final BackheaderBudgetItem item;
  final double amount;
}

class _OrbitCompactIconButton extends StatelessWidget {
  const _OrbitCompactIconButton({
    required this.buttonKey,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        child: IconButton(
          key: buttonKey,
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 20,
          color: AppColors.gray800,
          padding: EdgeInsets.zero,
          tooltip: tooltip,
        ),
      ),
    );
  }
}

class _OrbitAmountPill extends StatelessWidget {
  const _OrbitAmountPill({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.onChanged,
    required this.showSetToMax,
    required this.onSetToMax,
    required this.onReset,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final ValueChanged<String> onChanged;
  final bool showSetToMax;
  final VoidCallback onSetToMax;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('limit-amount-input'),
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: label,
                suffixText: 'Ft',
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(left: 14, right: 6),
              ),
            ),
          ),
          if (showSetToMax)
            IconButton(
              key: const ValueKey('limit-slider-end-button'),
              onPressed: onSetToMax,
              icon: const Icon(Icons.last_page),
              iconSize: 19,
              color: AppColors.gray700,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 38),
              tooltip: 'Max',
            ),
          IconButton(
            key: const ValueKey('limit-reset-inline-button'),
            onPressed: onReset,
            icon: const Icon(Icons.delete_outline),
            iconSize: 19,
            color: AppColors.gray700,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 38),
            tooltip: 'Reset',
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
