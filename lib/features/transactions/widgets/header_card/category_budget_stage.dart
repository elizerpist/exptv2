import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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
import '../../models/limit_allocation_data.dart';
import '../../models/overview_budget_data.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_record.dart';
import 'budget_bar_geometry.dart';
import 'backheader_style_surface.dart';
import 'budget_progress_frame.dart';
import 'category_budget_bar.dart';
import 'category_limit_partition_bar.dart';
import 'category_progress_bar.dart';
import 'magnet_strip.dart';
import 'transaction_header_metrics.dart';

class CategoryBudgetStage extends StatefulWidget {
  const CategoryBudgetStage({
    super.key,
    this.items,
    this.categoryBars,
    this.periodLabel,
    this.backheaderStyle = BackheaderStyle.classic,
    this.centerBackheaderDesign = BackheaderCenterDesign.neutral,
    this.centerPartitionRingEnabled = false,
    this.backgroundColor = AppColors.gray100,
    this.activeKey,
    this.onActiveItemChanged,
    this.onItemTap,
    this.bars,
    this.onBarTap,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.overviewItems = const [],
    this.pendingAmountsByKey = const <String, double>{},
    this.periodIncome = 0,
    this.onOrbitCloseRequested,
    this.onSaveOverview,
    this.onSaveCategory,
  });

  final List<BackheaderBudgetItem>? items;
  final List<CategoryBudgetBarData>? categoryBars;
  final String? periodLabel;
  final BackheaderStyle backheaderStyle;
  final BackheaderCenterDesign centerBackheaderDesign;
  final bool centerPartitionRingEnabled;
  final Color backgroundColor;
  final String? activeKey;
  final ValueChanged<BackheaderBudgetItem>? onActiveItemChanged;
  final ValueChanged<BackheaderBudgetItem>? onItemTap;
  final ExpenseSurfaceInteraction surfaceStyle;
  final List<OverviewBudgetData> overviewItems;
  final Map<String, double> pendingAmountsByKey;
  final double periodIncome;
  final VoidCallback? onOrbitCloseRequested;
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
  static const _orbitSnapArmDistance = 18.0;
  static const _orbitCloseArmDistance = 54.0;
  static const _orbitMaxClosePull = 64.0;
  static const _centerCarouselSlotDistance = 64.0;
  static const _centerJoystickDeadZone = 10.0;
  static const _centerJoystickTickInterval = Duration(milliseconds: 90);

  late final AnimationController _slideController;
  Animation<double>? _slideAnimation;
  late final TextEditingController _orbitAmountController;
  late final FocusNode _orbitAmountFocus;
  final _orbitRememberedSliderMaxByKey = <String, double>{};
  final _orbitPendingAmountsByKey = <String, double>{};
  final _orbitQueuedSavesByKey = <String, _OrbitSaveRequest>{};
  final _orbitSavingKeys = <String>{};
  Timer? _orbitSaveDebounce;
  Timer? _centerJoystickTimer;
  BackheaderBudgetItem? _centerJoystickItem;
  double? _centerJoystickActivationGlobalY;
  var _centerJoystickDragOffsetY = 0.0;
  var _centerJoystickTickCount = 0;
  var _index = 0;
  var _dragDx = 0.0;
  var _dragTotalDx = 0.0;
  var _settling = false;
  var _orbitClosePull = 0.0;
  var _orbitGestureDx = 0.0;
  var _orbitGestureDy = 0.0;
  var _orbitSnapArmed = false;
  var _orbitAcceptedVerticalDrag = false;
  var _orbitRejectedDrag = false;
  var _orbitCloseArmed = false;
  var _orbitHandlePointerActive = false;
  var _orbitPartitionDragActive = false;
  int? _orbitSurfaceSwipePointer;
  var _orbitSurfaceSwipeDx = 0.0;
  var _orbitSurfaceSwipeDy = 0.0;
  var _orbitSurfaceSwipeAccepted = false;
  var _orbitSurfaceSwipeRejected = false;
  int? _centerSurfaceDragPointer;
  var _centerSurfaceDragDx = 0.0;
  var _centerSurfaceDragDy = 0.0;
  var _centerSurfaceLastLoggedDx = 0.0;
  var _centerSurfaceDragAccepted = false;
  var _centerSurfaceDragRejected = false;
  var _centerSurfaceVelocityDx = 0.0;
  VelocityTracker? _centerSurfaceVelocityTracker;
  Duration? _centerSurfaceLastMoveAt;
  var _centerBeltAnimationActive = false;
  var _centerBeltAnimationLastValue = 0.0;
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
    _centerJoystickTimer?.cancel();
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
    final keepCenterDrag =
        widget.backheaderStyle == BackheaderStyle.centerBadgeBudget &&
        _centerSurfaceDragAccepted;
    final synced = _syncControlledIndex(resetDrag: !keepCenterDrag);
    if (_index >= _items.length) _index = 0;
    if (!synced && _items.length != _oldItems(oldWidget).length) _dragDx = 0;
    _discardStaleOrbitPendingAmounts();
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
                    _dragTotalDx = 0;
                  },
                  onHorizontalDragUpdate: (details) {
                    if (_settling) return;
                    _dragTotalDx += details.delta.dx;
                    final nextDx = (_dragDx + details.delta.dx)
                        .clamp(-_maxVisualDrag, _maxVisualDrag)
                        .toDouble();
                    setState(() => _dragDx = nextDx);
                  },
                  onHorizontalDragCancel: () => _animateDragTo(0),
                  onHorizontalDragEnd: _settleDrag,
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
    final isCenterBadgeBudget =
        widget.backheaderStyle == BackheaderStyle.centerBadgeBudget;
    Widget surfaceFor(BackheaderBudgetItem item, {bool preview = false}) {
      final showCenterPreviews = isCenterBadgeBudget && !preview;
      final centerPartitionAllocation =
          isCenterBadgeBudget && widget.centerPartitionRingEnabled
          ? _centerPartitionAllocationFor(item)
          : null;
      return BackheaderStyleSurface(
        style: widget.backheaderStyle,
        current: item,
        items: items,
        categoryBars: _categoryBars,
        frameProgress: frameProgress,
        frameOverview: frameOverview,
        activeIndex: _index,
        backgroundColor: widget.backgroundColor,
        centerDesign: widget.centerBackheaderDesign,
        centerPartitionRingEnabled: widget.centerPartitionRingEnabled,
        centerPartitionAllocation: centerPartitionAllocation,
        centerDragOffset: isCenterBadgeBudget ? _dragDx : 0,
        orbitPartitionBar: isOrbitBudget
            ? preview
                  ? _orbitStaticPartitionBarFor(item)
                  : _orbitPartitionBarFor(item)
            : null,
        orbitProgress: _orbitProgressFor(item),
        orbitHasLimit: _orbitHasLimit(item),
        orbitAmountText: isOrbitBudget || isCenterBadgeBudget
            ? _orbitAmountTextFor(item)
            : null,
        orbitAmountEditor: isOrbitBudget && !preview
            ? _buildOrbitAmountEditor(item)
            : null,
        orbitActions: isOrbitBudget && !preview
            ? _buildOrbitActions(item)
            : null,
        centerProgress: _orbitProgressFor(item),
        centerHasLimit: _orbitHasLimit(item),
        centerProgressColor: _centerProgressColorFor(item),
        centerPeriodLabel: isCenterBadgeBudget ? widget.periodLabel : null,
        centerActions: null,
        centerPreviousEdge: showCenterPreviews
            ? _centerNeighborAtOffset(items, -4)
            : null,
        centerPreviousFarthest: showCenterPreviews
            ? _centerNeighborAtOffset(items, -3)
            : null,
        centerPreviousOuter: showCenterPreviews
            ? _centerNeighborAtOffset(items, -2)
            : null,
        centerPreviousInner: showCenterPreviews
            ? _centerNeighborAtOffset(items, -1)
            : null,
        centerNextInner: showCenterPreviews
            ? _centerNeighborAtOffset(items, 1)
            : null,
        centerNextOuter: showCenterPreviews
            ? _centerNeighborAtOffset(items, 2)
            : null,
        centerNextFarthest: showCenterPreviews
            ? _centerNeighborAtOffset(items, 3)
            : null,
        centerNextEdge: showCenterPreviews
            ? _centerNeighborAtOffset(items, 4)
            : null,
        centerExpandedExtent: isCenterBadgeBudget ? _orbitClosePull : 0,
        onCenterPreviousEdgeTap: showCenterPreviews
            ? () => _selectCenterPreviewOffset(-4)
            : null,
        onCenterPreviousOuterTap: showCenterPreviews
            ? () => _selectCenterPreviewOffset(-2)
            : null,
        onCenterPreviousFarthestTap: showCenterPreviews
            ? () => _selectCenterPreviewOffset(-3)
            : null,
        onCenterPreviousInnerTap: showCenterPreviews
            ? () => _selectCenterPreviewOffset(-1)
            : null,
        onCenterNextInnerTap: showCenterPreviews
            ? () => _selectCenterPreviewOffset(1)
            : null,
        onCenterNextOuterTap: showCenterPreviews
            ? () => _selectCenterPreviewOffset(2)
            : null,
        onCenterNextFarthestTap: showCenterPreviews
            ? () => _selectCenterPreviewOffset(3)
            : null,
        onCenterNextEdgeTap: showCenterPreviews
            ? () => _selectCenterPreviewOffset(4)
            : null,
        onCenterBadgeLongPressStart: isCenterBadgeBudget && !preview
            ? (details) => _handleCenterBadgeLongPressStart(item, details)
            : null,
        onCenterBadgeLongPressMoveUpdate: isCenterBadgeBudget && !preview
            ? _handleCenterBadgeLongPressMoveUpdate
            : null,
        onCenterBadgeLongPressEnd: isCenterBadgeBudget && !preview
            ? (_) => _finishCenterJoystick()
            : null,
        onCenterBadgeLongPressCancel: isCenterBadgeBudget && !preview
            ? _finishCenterJoystick
            : null,
        centerRemainingText:
            isCenterBadgeBudget && !preview && _orbitClosePull > 0
            ? _remainingAmountTextFor(item)
            : null,
        onCenterHandlePointerDown: isCenterBadgeBudget && !preview
            ? _handleOrbitHandlePointerDown
            : null,
        onCenterHandlePointerMove: isCenterBadgeBudget && !preview
            ? _handleOrbitHandlePointerMove
            : null,
        onCenterHandlePointerUp: isCenterBadgeBudget && !preview
            ? _handleOrbitHandlePointerUp
            : null,
        onCenterHandlePointerCancel: isCenterBadgeBudget && !preview
            ? _handleOrbitHandlePointerCancel
            : null,
        onOrbitHandlePointerDown: isOrbitBudget && !preview
            ? _handleOrbitHandlePointerDown
            : null,
        onOrbitHandlePointerMove: isOrbitBudget && !preview
            ? _handleOrbitHandlePointerMove
            : null,
        onOrbitHandlePointerUp: isOrbitBudget && !preview
            ? _handleOrbitHandlePointerUp
            : null,
        onOrbitHandlePointerCancel: isOrbitBudget && !preview
            ? _handleOrbitHandlePointerCancel
            : null,
      );
    }

    return SizedBox(
      key: const ValueKey('category-budget-stage'),
      height:
          TransactionHeaderMetrics.cardHeight +
          (isOrbitBudget || isCenterBadgeBudget ? _orbitClosePull : 0),
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerDown: isOrbitBudget
                  ? _handleOrbitSurfacePointerDown
                  : isCenterBadgeBudget
                  ? _handleCenterSurfacePointerDown
                  : null,
              onPointerMove: isOrbitBudget
                  ? _handleOrbitSurfacePointerMove
                  : isCenterBadgeBudget
                  ? _handleCenterSurfacePointerMove
                  : null,
              onPointerUp: isOrbitBudget
                  ? _handleOrbitSurfacePointerUp
                  : isCenterBadgeBudget
                  ? _handleCenterSurfacePointerUp
                  : null,
              onPointerCancel: isOrbitBudget
                  ? _handleOrbitSurfacePointerCancel
                  : isCenterBadgeBudget
                  ? _handleCenterSurfacePointerCancel
                  : null,
              child: GestureDetector(
                key: const ValueKey('backheader-experimental-surface'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _tap(current),
                onHorizontalDragStart: isOrbitBudget || isCenterBadgeBudget
                    ? null
                    : (_) {
                        _slideController.stop();
                        _settling = false;
                        _dragTotalDx = 0;
                      },
                onHorizontalDragUpdate: isOrbitBudget || isCenterBadgeBudget
                    ? null
                    : (details) {
                        if (_settling) return;
                        _dragTotalDx += details.delta.dx;
                        final nextDx = (_dragDx + details.delta.dx)
                            .clamp(-_maxVisualDrag, _maxVisualDrag)
                            .toDouble();
                        setState(() => _dragDx = nextDx);
                      },
                onHorizontalDragCancel: isOrbitBudget || isCenterBadgeBudget
                    ? null
                    : () => _animateDragTo(0),
                onHorizontalDragEnd: isOrbitBudget || isCenterBadgeBudget
                    ? null
                    : _settleDrag,
                onLongPress: _jumpToOverviewForCurrent,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final showPreview =
                        isOrbitBudget && items.length > 1 && _dragDx != 0;
                    final nextIndex = (_index + 1) % items.length;
                    final previousIndex = _index == 0
                        ? items.length - 1
                        : _index - 1;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (showPreview && _dragDx < 0)
                          Positioned.fill(
                            child: Transform.translate(
                              offset: Offset(width + _dragDx, 0),
                              child: IgnorePointer(
                                child: KeyedSubtree(
                                  key: const ValueKey(
                                    'backheader-orbit-preview-next',
                                  ),
                                  child: Opacity(
                                    opacity: 0.82,
                                    child: surfaceFor(
                                      items[nextIndex],
                                      preview: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (showPreview && _dragDx > 0)
                          Positioned.fill(
                            child: Transform.translate(
                              offset: Offset(-width + _dragDx, 0),
                              child: IgnorePointer(
                                child: KeyedSubtree(
                                  key: const ValueKey(
                                    'backheader-orbit-preview-previous',
                                  ),
                                  child: Opacity(
                                    opacity: 0.82,
                                    child: surfaceFor(
                                      items[previousIndex],
                                      preview: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: isCenterBadgeBudget
                              ? surfaceFor(current)
                              : Transform.translate(
                                  offset: Offset(_dragDx, 0),
                                  child: surfaceFor(current),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (items.length > 1 &&
              widget.backheaderStyle != BackheaderStyle.orbitBudget &&
              widget.backheaderStyle != BackheaderStyle.centerBadgeBudget)
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

  BackheaderBudgetItem? _centerNeighborAtOffset(
    List<BackheaderBudgetItem> items,
    int offset,
  ) {
    if (offset == 0 || items.length < 2) return null;
    if (items.length < offset.abs() * 2 + 1) return null;
    final rawIndex = (_index + offset) % items.length;
    final normalizedIndex = rawIndex < 0 ? rawIndex + items.length : rawIndex;
    final item = items[normalizedIndex];
    return item.key == items[_index].key ? null : item;
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
    final range = _orbitSliderRangeFor(current);
    final handleRatio = range.max <= 0
        ? 0.0
        : (range.value / range.max).clamp(0.0, 1.0).toDouble();
    return Builder(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) => _setOrbitAmountFromPartitionPosition(
            current,
            context,
            details.globalPosition.dx,
            flush: true,
          ),
          onHorizontalDragStart: (_) {
            _orbitPartitionDragActive = true;
          },
          onHorizontalDragUpdate: (details) =>
              _setOrbitAmountFromPartitionPosition(
                current,
                context,
                details.globalPosition.dx,
                deferSave: true,
              ),
          onHorizontalDragCancel: () {
            _orbitPartitionDragActive = false;
            _flushOrbitSaves();
          },
          onHorizontalDragEnd: (_) {
            _orbitPartitionDragActive = false;
            _flushOrbitSaves();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              const handleWidth = 12.0;
              const handleHeight = 20.0;
              final maxLeft = math.max(0.0, constraints.maxWidth - handleWidth);
              final handleLeft =
                  (constraints.maxWidth * handleRatio - handleWidth / 2)
                      .clamp(0.0, maxLeft)
                      .toDouble();
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CategoryLimitPartitionBar(
                    height: _orbitPartitionHeight,
                    allocation: allocation,
                    fullBleedSquare: true,
                  ),
                  Positioned(
                    key: const ValueKey('backheader-orbit-partition-handle'),
                    left: handleLeft,
                    top: (_orbitPartitionHeight - handleHeight) / 2,
                    child: Container(
                      width: handleWidth,
                      height: handleHeight,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(handleWidth / 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  LimitAllocationData? _centerPartitionAllocationFor(
    BackheaderBudgetItem current,
  ) {
    if (current.overview?.kind == BudgetGoalKind.savingGoal) return null;
    final overviewLimit = _orbitOverviewLimitAmount(current);
    if (overviewLimit <= 0) return null;
    return LimitAllocationManager.build(
      overviewLimit: overviewLimit,
      bars: _orbitPartitionBars,
    );
  }

  Widget _orbitStaticPartitionBarFor(BackheaderBudgetItem current) {
    if (current.overview?.kind == BudgetGoalKind.savingGoal) {
      return const SizedBox.shrink();
    }
    return CategoryLimitPartitionBar(
      height: _orbitPartitionHeight,
      allocation: LimitAllocationManager.build(
        overviewLimit: _orbitOverviewLimitAmount(current),
        bars: _orbitPartitionBars,
      ),
      fullBleedSquare: true,
    );
  }

  double get _orbitPartitionHeight {
    final previousTrackHeight = MagnetStripPainter.visualTrackHeight(
      MagnetType.fade,
      TransactionHeaderMetrics.magnetHeight,
    );
    return math.max(2.0, previousTrackHeight * 0.5103);
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

  String _orbitSpentTextFor(BackheaderBudgetItem item) {
    final overview = item.overview;
    if (overview != null) return formatHuf(overview.amount);
    final category = item.category;
    if (category != null) return category.formattedSpent;
    return item.amountText;
  }

  String _remainingAmountTextFor(BackheaderBudgetItem item) {
    final remaining = (_orbitEffectiveAmountFor(item) - _spentAmountFor(item))
        .clamp(0.0, double.infinity)
        .toDouble();
    return '${formatHuf(remaining)} maradt';
  }

  double _orbitLimitPillWidth({required bool hasLimit}) {
    final display = _orbitAmountController.text.isEmpty && !hasLimit
        ? 'n/a'
        : _orbitAmountController.text;
    final length = math.max(3, display.length);
    return (length * 10.5 + 24).clamp(54.0, 164.0).toDouble();
  }

  Widget _buildOrbitAmountEditor(BackheaderBudgetItem current) {
    _syncOrbitAmountController(current);
    final amount = _orbitEffectiveAmountFor(current);
    final hasLimit = amount > 0;
    final spentText = _orbitSpentTextFor(current);
    const amountStyle = TextStyle(
      color: AppColors.white,
      fontSize: 16.8,
      fontWeight: FontWeight.w800,
      height: 1.05,
    );
    final pillWidth = _orbitLimitPillWidth(hasLimit: hasLimit);
    return KeyedSubtree(
      key: const ValueKey('backheader-orbit-amount'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            spentText,
            key: const ValueKey('backheader-orbit-spent-text'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: amountStyle,
          ),
          const SizedBox(width: 6),
          const Text(
            '/',
            key: ValueKey('backheader-orbit-amount-slash'),
            style: amountStyle,
          ),
          const SizedBox(width: 6),
          Container(
            key: const ValueKey('backheader-orbit-limit-pill'),
            width: pillWidth,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.42),
              ),
            ),
            alignment: Alignment.center,
            child: TextField(
              key: const ValueKey('backheader-orbit-amount-input'),
              controller: _orbitAmountController,
              focusNode: _orbitAmountFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enableInteractiveSelection: false,
              maxLines: 1,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: amountStyle,
              cursorColor: AppColors.white,
              decoration: InputDecoration(
                hintText: hasLimit ? null : 'n/a',
                hintStyle: amountStyle.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                ),
                isDense: true,
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitActions(BackheaderBudgetItem current) {
    final showSetToMax = current.overview != null && widget.periodIncome > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OrbitCompactIconButton(
          buttonKey: const ValueKey('limit-reset-inline-button'),
          icon: Icons.delete_outline,
          tooltip: 'Reset',
          onPressed: () => _setOrbitAmount(current, 0, flush: true),
        ),
        if (showSetToMax) ...[
          const SizedBox(width: 6),
          _OrbitCompactIconButton(
            buttonKey: const ValueKey('backheader-orbit-max-button'),
            icon: Icons.last_page,
            tooltip: 'Max',
            onPressed: () => _setOrbitOverviewToMax(current),
          ),
        ],
      ],
    );
  }

  Color _centerProgressColorFor(BackheaderBudgetItem item) {
    final limit = _orbitEffectiveAmountFor(item);
    if (limit <= 0) return item.category?.color ?? AppColors.primary;
    final ratio = (_spentAmountFor(item) / limit).clamp(0.0, double.infinity);
    if (ratio >= 0.90) return AppColors.expense;
    if (ratio >= 0.75) return const Color(0xFFEAB308);
    return item.category?.color ?? AppColors.primary;
  }

  double _spentAmountFor(BackheaderBudgetItem item) {
    final overview = item.overview;
    if (overview != null) return overview.amount;
    final category = item.category;
    if (category != null) return category.spent;
    return 0;
  }

  void _handleCenterBadgeLongPressStart(
    BackheaderBudgetItem item,
    LongPressStartDetails details,
  ) {
    _centerJoystickTimer?.cancel();
    _centerJoystickItem = item;
    _centerJoystickActivationGlobalY = details.globalPosition.dy;
    _centerJoystickDragOffsetY = 0;
    _centerJoystickTickCount = 0;
    HapticFeedback.mediumImpact();
    _centerJoystickTimer = Timer.periodic(
      _centerJoystickTickInterval,
      (_) => _applyCenterJoystickTick(),
    );
  }

  void _handleCenterBadgeLongPressMoveUpdate(
    LongPressMoveUpdateDetails details,
  ) {
    final activationGlobalY = _centerJoystickActivationGlobalY;
    if (activationGlobalY == null) return;
    _centerJoystickDragOffsetY = details.globalPosition.dy - activationGlobalY;
  }

  void _finishCenterJoystick() {
    _centerJoystickTimer?.cancel();
    _centerJoystickTimer = null;
    _centerJoystickItem = null;
    _centerJoystickActivationGlobalY = null;
    _centerJoystickDragOffsetY = 0;
    _centerJoystickTickCount = 0;
    _flushOrbitSaves();
  }

  void _applyCenterJoystickTick() {
    final item = _centerJoystickItem;
    if (item == null ||
        _centerJoystickDragOffsetY.abs() <= _centerJoystickDeadZone) {
      return;
    }
    final speed = _centerJoystickSpeedForOffset(
      _centerJoystickDragOffsetY.abs(),
    );
    _centerJoystickTickCount += 1;
    if (_centerJoystickTickCount % speed.tickStride != 0) return;

    final direction = _centerJoystickDragOffsetY < 0 ? 1 : -1;
    final range = _orbitSliderRangeFor(item);
    final step = _centerJoystickStepFor(range.max);
    final next = math
        .max(
          0.0,
          _orbitEffectiveAmountFor(item) +
              direction * step * speed.stepMultiplier,
        )
        .toDouble();
    _setOrbitAmount(
      item,
      next,
      deferSave: true,
      snap: true,
      maxOverride: direction > 0 ? next : null,
    );
    HapticFeedback.selectionClick();
  }

  double _centerJoystickStepFor(double max) {
    if (max <= 10000) return 1000;
    if (max <= 50000) return 2000;
    return 5000;
  }

  _CenterJoystickSpeed _centerJoystickSpeedForOffset(double distance) {
    final activeDistance = math.max(0.0, distance - _centerJoystickDeadZone);
    final normalized = (activeDistance / 52).clamp(0.0, 1.0).toDouble();
    final parabolicBoost = normalized * normalized;
    final multiplier = (1 + parabolicBoost * 9).round().clamp(1, 10);
    final tickStride = activeDistance < 18
        ? 3
        : activeDistance < 28
        ? 2
        : 1;
    return _CenterJoystickSpeed(
      stepMultiplier: multiplier,
      tickStride: tickStride,
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
    return widget.pendingAmountsByKey[item.key] ??
        _orbitPendingAmountsByKey[item.key] ??
        _orbitLimitAmountFor(item);
  }

  void _discardStaleOrbitPendingAmounts() {
    final keysToRemove = <String>[];
    for (final entry in _orbitPendingAmountsByKey.entries) {
      if (widget.pendingAmountsByKey.containsKey(entry.key)) {
        keysToRemove.add(entry.key);
        continue;
      }
      final item = _itemForKeyOrNull(entry.key);
      if (item == null) {
        keysToRemove.add(entry.key);
        continue;
      }
      if ((_orbitLimitAmountFor(item) - entry.value).abs() < 0.01) {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _orbitPendingAmountsByKey.remove(key);
    }
  }

  BackheaderBudgetItem? _itemForKeyOrNull(String key) {
    for (final item in _items) {
      if (item.key == key) return item;
    }
    return null;
  }

  double _orbitLimitAmountFor(BackheaderBudgetItem item) {
    final overview = item.overview;
    if (overview != null && overview.hasLimit) return overview.limitAmount;
    final category = item.category;
    if (category != null && category.hasLimit) return category.limitAmount;
    return 0;
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
    bool deferSave = false,
  }) {
    final range = _orbitSliderRangeFor(item);
    final snapped = LimitAllocationManager.snapSliderAmount(
      amount,
    ).clamp(0.0, range.max).toDouble();
    _setOrbitAmount(item, snapped, flush: flush, deferSave: deferSave);
  }

  void _setOrbitAmountFromPartitionPosition(
    BackheaderBudgetItem item,
    BuildContext context,
    double globalDx, {
    bool flush = false,
    bool deferSave = false,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final range = _orbitSliderRangeFor(item);
    if (!range.enabled || range.max <= 0) return;
    final localDx = box.globalToLocal(Offset(globalDx, 0)).dx;
    final ratio = (localDx / box.size.width).clamp(0.0, 1.0).toDouble();
    _setOrbitAmountFromSlider(
      item,
      range.max * ratio,
      flush: flush,
      deferSave: deferSave,
    );
  }

  void _setOrbitOverviewToMax(BackheaderBudgetItem item) {
    final max = math.max(0.0, widget.periodIncome).toDouble();
    _setOrbitAmount(item, max, flush: true);
  }

  void _handleCenterSurfacePointerDown(PointerDownEvent event) {
    if (_orbitHandlePointerActive ||
        _centerSurfaceDragBlocked(event.localPosition)) {
      return;
    }
    _centerSurfaceDragPointer = event.pointer;
    _centerSurfaceDragDx = 0;
    _centerSurfaceDragDy = 0;
    _centerSurfaceLastLoggedDx = 0;
    _centerSurfaceDragAccepted = false;
    _centerSurfaceDragRejected = false;
    _centerSurfaceVelocityDx = 0;
    _centerSurfaceVelocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.localPosition);
    _centerSurfaceLastMoveAt = event.timeStamp;
    _slideController.stop();
    _centerBeltAnimationActive = false;
    _centerBeltAnimationLastValue = 0;
    _settling = false;
    _dragTotalDx = 0;
    _logCenterCarousel(
      'down pointer=${event.pointer} local=(${_fmt(event.localPosition.dx)},${_fmt(event.localPosition.dy)}) items=${_items.length}',
    );
  }

  void _handleCenterSurfacePointerMove(PointerMoveEvent event) {
    if (_centerSurfaceDragPointer != event.pointer ||
        _centerSurfaceDragRejected ||
        _settling) {
      return;
    }
    _recordCenterSurfaceVelocity(event);
    _centerSurfaceDragDx += event.delta.dx;
    _centerSurfaceDragDy += event.delta.dy;
    if (!_centerSurfaceDragAccepted) {
      final absDx = _centerSurfaceDragDx.abs();
      final absDy = _centerSurfaceDragDy.abs();
      if (absDx <= _orbitAxisSlop && absDy <= _orbitAxisSlop) return;
      if (absDy > absDx) {
        _centerSurfaceDragRejected = true;
        _logCenterCarousel(
          'reject dx=${_fmt(_centerSurfaceDragDx)} dy=${_fmt(_centerSurfaceDragDy)}',
        );
        return;
      }
      _centerSurfaceDragAccepted = true;
      _logCenterCarousel(
        'accept dx=${_fmt(_centerSurfaceDragDx)} dy=${_fmt(_centerSurfaceDragDy)}',
      );
    }
    _applyCenterSurfaceDragDelta(event.delta.dx);
  }

  void _handleCenterSurfacePointerUp(PointerUpEvent event) {
    if (_centerSurfaceDragPointer != event.pointer) return;
    final shouldSettle = _centerSurfaceDragAccepted;
    _centerSurfaceVelocityTracker?.addPosition(
      event.timeStamp,
      event.localPosition,
    );
    final releaseVelocityDx =
        _centerSurfaceVelocityTracker?.getVelocity().pixelsPerSecond.dx ??
        _centerSurfaceVelocityDx;
    _logCenterCarousel(
      'up accepted=$shouldSettle totalDx=${_fmt(_centerSurfaceDragDx)} residualDx=${_fmt(_dragDx)} sampleVelocity=${_fmt(_centerSurfaceVelocityDx)} releaseVelocity=${_fmt(releaseVelocityDx)}',
    );
    _resetCenterSurfaceDrag();
    if (!shouldSettle) {
      _logCenterCarousel('settle back reason=not-accepted');
      _animateDragTo(0);
      return;
    }
    unawaited(_releaseCenterBelt(velocityDx: releaseVelocityDx));
  }

  void _handleCenterSurfacePointerCancel(PointerCancelEvent event) {
    if (_centerSurfaceDragPointer != event.pointer) return;
    _logCenterCarousel(
      'cancel pointer=${event.pointer} totalDx=${_fmt(_centerSurfaceDragDx)} visualDx=${_fmt(_dragDx)}',
    );
    _resetCenterSurfaceDrag();
    _animateDragTo(0);
  }

  void _recordCenterSurfaceVelocity(PointerMoveEvent event) {
    _centerSurfaceVelocityTracker?.addPosition(
      event.timeStamp,
      event.localPosition,
    );
    final previous = _centerSurfaceLastMoveAt;
    if (previous != null) {
      final elapsed = event.timeStamp - previous;
      if (elapsed.inMicroseconds > 0) {
        final trackerVelocity = _centerSurfaceVelocityTracker
            ?.getVelocity()
            .pixelsPerSecond
            .dx;
        _centerSurfaceVelocityDx =
            trackerVelocity ??
            event.delta.dx /
                elapsed.inMicroseconds *
                Duration.microsecondsPerSecond;
      }
    }
    _centerSurfaceLastMoveAt = event.timeStamp;
  }

  bool _centerSurfaceDragBlocked(Offset localPosition) {
    final handleTop =
        TransactionHeaderMetrics.fastInfoHeight + _orbitClosePull - 34;
    return localPosition.dy >= handleTop;
  }

  void _resetCenterSurfaceDrag() {
    _centerSurfaceDragPointer = null;
    _centerSurfaceDragDx = 0;
    _centerSurfaceDragDy = 0;
    _centerSurfaceLastLoggedDx = 0;
    _centerSurfaceDragAccepted = false;
    _centerSurfaceDragRejected = false;
    _centerSurfaceVelocityDx = 0;
    _centerSurfaceVelocityTracker = null;
    _centerSurfaceLastMoveAt = null;
  }

  void _applyCenterSurfaceDragDelta(double deltaDx) {
    final items = _items;
    if (items.length < 2) return;
    _dragTotalDx += deltaDx;
    _applyCenterBeltDelta(deltaDx, source: 'drag');
    final shouldLogMove =
        (_centerSurfaceDragDx - _centerSurfaceLastLoggedDx).abs() >= 24 ||
        deltaDx.abs() >= 12;
    if (shouldLogMove) {
      _centerSurfaceLastLoggedDx = _centerSurfaceDragDx;
      _logCenterCarousel(
        'move delta=${_fmt(deltaDx)} total=${_fmt(_centerSurfaceDragDx)} residual=${_fmt(_dragDx)} velocity=${_fmt(_centerSurfaceVelocityDx)}',
      );
    }
  }

  void _applyCenterBeltDelta(double deltaDx, {required String source}) {
    final items = _items;
    if (items.length < 2 || deltaDx == 0) return;
    var nextDx = _dragDx + deltaDx;
    var nextIndex = _index;
    final tickedItems = <BackheaderBudgetItem>[];
    while (nextDx <= -_centerCarouselSlotDistance) {
      nextDx += _centerCarouselSlotDistance;
      nextIndex = (nextIndex + 1) % items.length;
      tickedItems.add(items[nextIndex]);
    }
    while (nextDx >= _centerCarouselSlotDistance) {
      nextDx -= _centerCarouselSlotDistance;
      nextIndex = nextIndex == 0 ? items.length - 1 : nextIndex - 1;
      tickedItems.add(items[nextIndex]);
    }
    setState(() {
      _index = nextIndex;
      _dragDx = nextDx;
    });
    for (final item in tickedItems) {
      HapticFeedback.selectionClick();
      _syncOrbitAmountController(item);
      widget.onActiveItemChanged?.call(item);
      _logCenterCarousel(
        'tick source=$source current=${item.key}:${item.title}',
      );
    }
  }

  Future<void> _releaseCenterBelt({required double velocityDx}) async {
    if (_settling) return;
    final speed = velocityDx.abs();
    final residual = _dragDx;
    final inertialTravel = speed < 700
        ? 0.0
        : (velocityDx * 0.055)
              .clamp(
                -_centerCarouselSlotDistance * 3,
                _centerCarouselSlotDistance * 3,
              )
              .toDouble();
    final travel = inertialTravel == 0
        ? _centerBeltSnapTravel(residual)
        : inertialTravel;
    _logCenterCarousel(
      'release travel=${_fmt(travel)} residual=${_fmt(residual)} velocity=${_fmt(velocityDx)}',
    );
    _settling = true;
    try {
      if (travel.abs() >= 0.5) {
        final duration = inertialTravel == 0
            ? const Duration(milliseconds: 120)
            : Duration(
                milliseconds: (180 + speed * 0.045).clamp(200, 340).round(),
              );
        await _animateCenterBeltTravel(
          travel,
          curve: inertialTravel == 0 ? Curves.easeOutCubic : Curves.easeOutQuad,
          duration: duration,
        );
      }
      if (!mounted || !_settling) return;
      await _settleCenterBeltResidual();
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && _settling) {
        setState(() {
          _settling = false;
        });
        _logCenterCarousel('settled source=release');
      }
    }
  }

  Future<void> _settleCenterBeltResidual() async {
    final travel = _centerBeltSnapTravel(_dragDx);
    if (travel.abs() < 0.5) {
      if (_dragDx != 0) {
        setState(() => _dragDx = 0);
      }
      return;
    }
    _logCenterCarousel(
      'settle residual=${_fmt(_dragDx)} travel=${_fmt(travel)}',
    );
    await _animateCenterBeltTravel(
      travel,
      curve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 120),
    );
  }

  double _centerBeltSnapTravel(double residual) {
    if (residual.abs() >= _switchThreshold) {
      return residual < 0
          ? -_centerCarouselSlotDistance - residual
          : _centerCarouselSlotDistance - residual;
    }
    return -residual;
  }

  void _handleOrbitSurfacePointerDown(PointerDownEvent event) {
    if (_orbitHandlePointerActive ||
        _orbitSurfaceSwipeBlocked(event.localPosition)) {
      return;
    }
    _orbitSurfaceSwipePointer = event.pointer;
    _orbitSurfaceSwipeDx = 0;
    _orbitSurfaceSwipeDy = 0;
    _orbitSurfaceSwipeAccepted = false;
    _orbitSurfaceSwipeRejected = false;
  }

  void _handleOrbitSurfacePointerMove(PointerMoveEvent event) {
    if (_orbitSurfaceSwipePointer != event.pointer ||
        _orbitSurfaceSwipeRejected ||
        _settling) {
      return;
    }
    _orbitSurfaceSwipeDx += event.delta.dx;
    _orbitSurfaceSwipeDy += event.delta.dy;
    if (!_orbitSurfaceSwipeAccepted) {
      final absDx = _orbitSurfaceSwipeDx.abs();
      final absDy = _orbitSurfaceSwipeDy.abs();
      if (absDx <= _orbitAxisSlop && absDy <= _orbitAxisSlop) return;
      if (absDy > absDx) {
        _orbitSurfaceSwipeRejected = true;
        return;
      }
      _orbitSurfaceSwipeAccepted = true;
      _slideController.stop();
      _settling = false;
    }
    final nextDx = (_dragDx + event.delta.dx)
        .clamp(-_maxVisualDrag, _maxVisualDrag)
        .toDouble();
    setState(() => _dragDx = nextDx);
  }

  void _handleOrbitSurfacePointerUp(PointerUpEvent event) {
    if (_orbitSurfaceSwipePointer != event.pointer) return;
    final shouldSettle = _orbitSurfaceSwipeAccepted;
    _resetOrbitSurfaceSwipe();
    if (shouldSettle) {
      _settleDrag();
    } else {
      _animateDragTo(0);
    }
  }

  void _handleOrbitSurfacePointerCancel(PointerCancelEvent event) {
    if (_orbitSurfaceSwipePointer != event.pointer) return;
    _resetOrbitSurfaceSwipe();
    _animateDragTo(0);
  }

  bool _orbitSurfaceSwipeBlocked(Offset localPosition) {
    final trackHeight = MagnetStripPainter.visualTrackHeight(
      MagnetType.fade,
      TransactionHeaderMetrics.magnetHeight,
    );
    final partitionTop =
        TransactionHeaderMetrics.magnetTop +
        TransactionHeaderMetrics.magnetHeight / 2 -
        trackHeight / 2;
    final partitionBottom = partitionTop + trackHeight * 0.7;
    final handleTop =
        TransactionHeaderMetrics.cardHeight + _orbitClosePull - 30;
    return localPosition.dy >= partitionTop - 8 &&
            localPosition.dy <= partitionBottom + 8 ||
        localPosition.dy >= handleTop;
  }

  void _resetOrbitSurfaceSwipe() {
    _orbitSurfaceSwipePointer = null;
    _orbitSurfaceSwipeDx = 0;
    _orbitSurfaceSwipeDy = 0;
    _orbitSurfaceSwipeAccepted = false;
    _orbitSurfaceSwipeRejected = false;
  }

  void _setOrbitAmount(
    BackheaderBudgetItem item,
    double rawAmount, {
    bool updateController = true,
    bool flush = false,
    bool deferSave = false,
    bool snap = false,
    double? maxOverride,
  }) {
    final range = _orbitSliderRangeFor(item);
    final clampMax = math.max(range.max, maxOverride ?? range.max);
    final normalized = math.max(0.0, rawAmount).toDouble();
    final amount =
        (snap
                ? LimitAllocationManager.snapSliderAmount(normalized)
                : normalized)
            .clamp(0.0, clampMax)
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
    _scheduleOrbitSave(item, amount, flush: flush, deferSave: deferSave);
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

  void _selectCenterPreviewOffset(int offset) {
    if (_settling) return;
    if (offset == 0) return;
    _logCenterCarousel('tap offset=$offset');
    unawaited(
      _tickCenterCarouselBySteps(
        steps: offset.abs(),
        swipedLeft: offset > 0,
        source: 'tap',
      ),
    );
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

  void _scheduleOrbitSave(
    BackheaderBudgetItem item,
    double amount, {
    bool flush = false,
    bool deferSave = false,
  }) {
    _orbitQueuedSavesByKey[item.key] = _OrbitSaveRequest(item, amount);
    if (deferSave || _orbitPartitionDragActive) {
      _orbitSaveDebounce?.cancel();
      return;
    }
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

  void _handleOrbitHandlePointerDown(PointerDownEvent event) {
    _orbitHandlePointerActive = true;
    _orbitGestureDx = 0;
    _orbitGestureDy = 0;
    _orbitAcceptedVerticalDrag = false;
    _orbitRejectedDrag = false;
    _orbitSnapArmed = false;
    _orbitCloseArmed = false;
  }

  void _handleOrbitHandlePointerMove(PointerMoveEvent event) {
    if (widget.backheaderStyle != BackheaderStyle.orbitBudget &&
        widget.backheaderStyle != BackheaderStyle.centerBadgeBudget) {
      return;
    }
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

    final nextPull = _orbitGestureDy.clamp(0.0, _orbitMaxClosePull).toDouble();
    var nextSnapArmed = _orbitSnapArmed;
    var nextCloseArmed = _orbitCloseArmed;
    final snapArmed = nextPull >= _orbitSnapArmDistance;
    if (snapArmed != nextSnapArmed) {
      nextSnapArmed = snapArmed;
      HapticFeedback.selectionClick();
    }
    final closeArmed = nextPull >= _orbitCloseArmDistance;
    if (closeArmed != nextCloseArmed) {
      nextCloseArmed = closeArmed;
      HapticFeedback.selectionClick();
    }
    setState(() {
      _orbitClosePull = nextPull;
      _orbitSnapArmed = nextSnapArmed;
      _orbitCloseArmed = nextCloseArmed;
    });
  }

  void _handleOrbitHandlePointerUp(PointerUpEvent event) {
    _orbitHandlePointerActive = false;
    if (!_orbitAcceptedVerticalDrag || _orbitRejectedDrag) {
      _resetOrbitHandleGesture();
      return;
    }
    final shouldClose = _orbitCloseArmed;
    setState(() {
      _orbitClosePull = 0;
      _orbitSnapArmed = false;
      _orbitCloseArmed = false;
    });
    _resetOrbitHandleGesture();
    if (shouldClose) widget.onOrbitCloseRequested?.call();
  }

  void _handleOrbitHandlePointerCancel(PointerCancelEvent event) {
    _orbitHandlePointerActive = false;
    if (_orbitAcceptedVerticalDrag && !_orbitRejectedDrag) {
      setState(() {
        _orbitClosePull = 0;
        _orbitSnapArmed = false;
        _orbitCloseArmed = false;
      });
    }
    _resetOrbitHandleGesture();
  }

  void _resetOrbitHandleGesture() {
    _orbitGestureDx = 0;
    _orbitGestureDy = 0;
    _orbitAcceptedVerticalDrag = false;
    _orbitRejectedDrag = false;
    _orbitSnapArmed = false;
    _orbitCloseArmed = false;
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
    if (_centerBeltAnimationActive &&
        widget.backheaderStyle == BackheaderStyle.centerBadgeBudget) {
      final value = animation.value;
      final delta = value - _centerBeltAnimationLastValue;
      _centerBeltAnimationLastValue = value;
      _applyCenterBeltDelta(delta, source: 'inertia');
      return;
    }
    setState(() => _dragDx = animation.value);
  }

  void _logCenterCarousel(String message) {
    DebugConsole.log(
      '[CenterCarousel] $message index=$_index current=${_centerCarouselItemLabel(_index)} dragDx=${_fmt(_dragDx)} totalDx=${_fmt(_dragTotalDx)} pointer=${_centerSurfaceDragPointer ?? '-'} accepted=$_centerSurfaceDragAccepted settling=$_settling',
    );
  }

  String _centerCarouselItemLabel(int index) {
    final items = _items;
    if (items.isEmpty) return 'none';
    final normalized = index % items.length;
    final safeIndex = normalized < 0 ? normalized + items.length : normalized;
    final item = items[safeIndex];
    return '$safeIndex:${item.key}:${item.title}';
  }

  String _fmt(double value) => value.toStringAsFixed(1);

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

  Future<void> _settleDrag([DragEndDetails? details]) async {
    if (_settling) return;
    final items = _items;
    if (items.length < 2 || _dragDx.abs() < _switchThreshold) {
      await _animateDragTo(0);
      return;
    }
    if (widget.backheaderStyle == BackheaderStyle.centerBadgeBudget) {
      final swipedLeft = (_dragTotalDx == 0 ? _dragDx : _dragTotalDx) < 0;
      final steps = _centerCarouselSteps(details);
      await _tickCenterCarouselBySteps(
        steps: steps,
        swipedLeft: swipedLeft,
        source: 'settle',
      );
      return;
    }
    await _snapToNext(swipedLeft: _dragDx < 0);
  }

  int _centerCarouselSteps(DragEndDetails? details) {
    final distance = math.max(_dragTotalDx.abs(), _dragDx.abs());
    final velocity = details?.primaryVelocity?.abs() ?? 0;
    return _centerCarouselPlanFor(distance: distance, velocity: velocity).steps;
  }

  _CenterCarouselPlan _centerCarouselPlanFor({
    required double distance,
    required double velocity,
  }) {
    if (_items.length < 2) {
      return _CenterCarouselPlan(
        steps: 0,
        distanceSteps: 0,
        velocitySteps: 0,
        distance: distance,
        velocity: velocity,
      );
    }
    final maxSteps = math.max(1, _items.length - 1);
    final distanceSteps = distance < _switchThreshold
        ? 0
        : math.max(1, (distance / _centerCarouselSlotDistance).round());
    final velocitySteps = velocity < 1200 ? 0 : (velocity / 1200).floor();
    return _CenterCarouselPlan(
      steps: (distanceSteps + velocitySteps).clamp(0, maxSteps).toInt(),
      distanceSteps: distanceSteps.clamp(0, maxSteps).toInt(),
      velocitySteps: velocitySteps.clamp(0, maxSteps).toInt(),
      distance: distance,
      velocity: velocity,
    );
  }

  Future<void> _snapToNext({required bool swipedLeft}) async {
    await _snapBySteps(steps: 1, swipedLeft: swipedLeft);
  }

  Future<void> _tickCenterCarouselBySteps({
    required int steps,
    required bool swipedLeft,
    String source = 'direct',
  }) async {
    if (_settling) return;
    final items = _items;
    if (items.length < 2) return;
    final normalizedSteps = steps.clamp(1, items.length - 1).toInt();
    _slideController.stop();
    _settling = true;
    _dragTotalDx = 0;
    for (var step = 0; step < normalizedSteps; step += 1) {
      if (!mounted) return;
      final nextIndex = swipedLeft
          ? (_index + 1) % items.length
          : (_index - 1) % items.length;
      final normalizedNextIndex = nextIndex < 0
          ? nextIndex + items.length
          : nextIndex;
      _logCenterCarousel(
        'step start source=$source step=${step + 1}/$normalizedSteps from=${_centerCarouselItemLabel(_index)} to=${_centerCarouselItemLabel(normalizedNextIndex)} targetDx=${_fmt(swipedLeft ? -_centerCarouselSlotDistance : _centerCarouselSlotDistance)}',
      );
      await _animateDragTo(
        swipedLeft ? -_centerCarouselSlotDistance : _centerCarouselSlotDistance,
        curve: Curves.linear,
        duration: const Duration(milliseconds: 96),
      );
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _index = normalizedNextIndex;
        _dragDx = 0;
      });
      _syncOrbitAmountController(_items[_index]);
      widget.onActiveItemChanged?.call(_items[_index]);
      _logCenterCarousel(
        'step end source=$source step=${step + 1}/$normalizedSteps current=${_centerCarouselItemLabel(_index)}',
      );
    }
    if (!mounted) return;
    setState(() {
      _settling = false;
    });
    _logCenterCarousel(
      'settled source=$source current=${_centerCarouselItemLabel(_index)}',
    );
  }

  Future<void> _snapBySteps({
    required int steps,
    required bool swipedLeft,
  }) async {
    if (_settling) return;
    final items = _items;
    if (items.length < 2) return;
    final normalizedSteps = steps.clamp(1, items.length - 1).toInt();
    _settling = true;
    setState(() {
      _index = swipedLeft
          ? (_index + normalizedSteps) % items.length
          : (_index - normalizedSteps) % items.length;
      if (_index < 0) _index += items.length;
      _dragDx = swipedLeft ? _maxVisualDrag : -_maxVisualDrag;
      _dragTotalDx = 0;
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
    _centerBeltAnimationActive = false;
    _centerBeltAnimationLastValue = 0;
    _slideController.stop();
    _slideController.duration = duration;
    _slideAnimation = Tween<double>(
      begin: _dragDx,
      end: target,
    ).animate(CurvedAnimation(parent: _slideController, curve: curve));
    return _slideController.forward(from: 0);
  }

  Future<void> _animateCenterBeltTravel(
    double travel, {
    required Curve curve,
    required Duration duration,
  }) async {
    _slideController.stop();
    _slideController.duration = duration;
    _centerBeltAnimationActive = true;
    _centerBeltAnimationLastValue = 0;
    _slideAnimation = Tween<double>(
      begin: 0,
      end: travel,
    ).animate(CurvedAnimation(parent: _slideController, curve: curve));
    try {
      await _slideController.forward(from: 0).orCancel;
    } finally {
      _centerBeltAnimationActive = false;
      _centerBeltAnimationLastValue = 0;
    }
  }
}

class _CenterCarouselPlan {
  const _CenterCarouselPlan({
    required this.steps,
    required this.distanceSteps,
    required this.velocitySteps,
    required this.distance,
    required this.velocity,
  });

  final int steps;
  final int distanceSteps;
  final int velocitySteps;
  final double distance;
  final double velocity;
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

class _CenterJoystickSpeed {
  const _CenterJoystickSpeed({
    required this.stepMultiplier,
    required this.tickStride,
  });

  final int stepMultiplier;
  final int tickStride;
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
      width: 34,
      height: 34,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        child: IconButton(
          key: buttonKey,
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 18,
          color: AppColors.gray800,
          padding: EdgeInsets.zero,
          tooltip: tooltip,
        ),
      ),
    );
  }
}
