import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/category_color_manager.dart';
import '../../../settings/theme/expense_theme.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_log_entry.dart';
import '../../models/transaction_record.dart';
import '../../state/transaction_store.dart';
import '../category_menu/category_icon_badge.dart';
import '../transaction_log_box.dart';
import 'spendee_center_carousel_controller.dart';
import 'spendee_header_stage_controller.dart';

const _budgetHeaderGradientColors = <Color>[
  Color(0xFFBDF5FF),
  Color(0xFF06B6D4),
  Color(0xFF0057D9),
];

const _budgetHeaderGradientStops = <double>[0, .5, 1];
const _centerCarouselVisualSlotDistance = 64.0;

class SpendeeTestDashboard extends StatefulWidget {
  const SpendeeTestDashboard({
    super.key,
    required this.store,
    required this.expenseTheme,
    required this.onSettingsPressed,
    required this.onPickSummaryMonth,
    required this.onEditTransaction,
    required this.onDeleteTransactionRequested,
    required this.onVendorSheetRequested,
    required this.logBottomPadding,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;
  final VoidCallback? onSettingsPressed;
  final VoidCallback onPickSummaryMonth;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final TransactionDeleteRequest? onDeleteTransactionRequested;
  final VoidCallback? onVendorSheetRequested;
  final double logBottomPadding;

  @override
  State<SpendeeTestDashboard> createState() => _SpendeeTestDashboardState();
}

class _SpendeeTestDashboardState extends State<SpendeeTestDashboard> {
  SpendeeHeaderStageController? _stageController;
  SpendeeHeaderStage _stage = SpendeeHeaderStage.stage0;
  var _headerHeight = 104.0;
  var _dragging = false;
  var _springBack = false;
  var _carouselLiveTicked = false;
  var _carouselVisualDx = 0.0;
  var _carouselSettling = false;
  SpendeeCenterCarouselController? _carouselController;
  int? _selectedCategoryId;

  SpendeeHeaderStageGeometry _geometryFor(BuildContext context) {
    return SpendeeHeaderStageGeometry.html(
      screenHeight: MediaQuery.sizeOf(context).height,
    );
  }

  SpendeeHeaderStageController _controllerFor(BuildContext context) {
    final geometry = _geometryFor(context);
    final existing = _stageController;
    if (existing != null &&
        existing.geometry.stage2Height == geometry.stage2Height) {
      return existing;
    }
    final controller = SpendeeHeaderStageController(geometry: geometry);
    _stageController = controller;
    _stage = controller.stage;
    _headerHeight = controller.currentHeight;
    return controller;
  }

  List<TransactionCategory> get _activeCategories =>
      widget.store.activeCategories;

  TransactionCategory? get _selectedCategory {
    final categories = _activeCategories;
    if (categories.isEmpty) return null;
    final selectedId =
        _selectedCategoryId ??
        widget.store.activeCategory?.transactionCategoryID;
    if (selectedId != null) {
      for (final category in categories) {
        if (category.transactionCategoryID == selectedId) return category;
      }
    }
    return categories.first;
  }

  CategoryBudgetBarData? get _selectedBar {
    final category = _selectedCategory;
    if (category == null) return null;
    for (final bar in widget.store.categoryBudgetBars) {
      if (bar.targetId == category.transactionCategoryID) return bar;
    }
    return null;
  }

  void _beginHeaderDrag(DragStartDetails details) {
    final controller = _controllerFor(context);
    controller.beginDrag();
    setState(() {
      _dragging = true;
      _springBack = false;
    });
  }

  void _updateHeaderDrag(DragUpdateDetails details) {
    final controller = _controllerFor(context);
    final update = controller.dragBy(details.delta.dy);
    if (update.tick) HapticFeedback.selectionClick();
    setState(() {
      _headerHeight = update.height;
      _stage = controller.stage;
    });
  }

  void _endHeaderDrag(DragEndDetails details) {
    final controller = _controllerFor(context);
    final release = controller.release();
    setState(() {
      _dragging = false;
      _springBack = release.springBack;
      _stage = release.targetStage;
      _headerHeight = release.targetHeight;
    });
  }

  void _selectCategory(TransactionCategory category, {bool haptic = true}) {
    if (haptic) HapticFeedback.selectionClick();
    _selectedCategoryId = category.transactionCategoryID;
    widget.store.setCategoryFilter(category);
  }

  int _selectedCategoryIndex() {
    final categories = _activeCategories;
    if (categories.isEmpty) return 0;
    final selectedId = _selectedCategory?.transactionCategoryID;
    final index = categories.indexWhere(
      (category) => category.transactionCategoryID == selectedId,
    );
    return index < 0 ? 0 : index;
  }

  void _handleCarouselDragStart(DragStartDetails details) {
    setState(() {
      _carouselLiveTicked = false;
      _carouselSettling = false;
      _carouselVisualDx = 0;
      _carouselController = SpendeeCenterCarouselController(
        itemCount: _activeCategories.length,
        initialIndex: _selectedCategoryIndex(),
      );
    });
  }

  void _handleCarouselDragUpdate(DragUpdateDetails details) {
    final categories = _activeCategories;
    if (categories.length < 2) return;
    final controller = _carouselController ??= SpendeeCenterCarouselController(
      itemCount: categories.length,
      initialIndex: _selectedCategoryIndex(),
    );
    final update = controller.applyDragDelta(details.delta.dx);
    TransactionCategory? latestCategory;
    for (final index in update.tickedIndexes) {
      _carouselLiveTicked = true;
      latestCategory = categories[index % categories.length];
      HapticFeedback.selectionClick();
    }
    if (latestCategory != null) {
      widget.store.setCategoryFilter(latestCategory);
    }
    setState(() {
      if (latestCategory != null) {
        _selectedCategoryId = latestCategory.transactionCategoryID;
      }
      _carouselVisualDx = update.residualDx;
    });
  }

  void _handleCarouselDragEnd(DragEndDetails details) {
    final categories = _activeCategories;
    final controller = _carouselController;
    if (categories.length < 2 || controller == null) {
      return;
    }
    final plan = controller.releasePlan(
      velocityDx: details.velocity.pixelsPerSecond.dx,
    );
    final steps = _carouselLiveTicked ? plan.velocitySteps : plan.steps;
    _carouselController = null;
    _carouselLiveTicked = false;
    if (steps <= 0) {
      setState(() {
        _carouselSettling = true;
        _carouselVisualDx = 0;
      });
      return;
    }
    unawaited(_tickCarouselBySteps(steps: steps, swipedLeft: plan.swipedLeft));
  }

  Future<void> _tickCarouselBySteps({
    required int steps,
    required bool swipedLeft,
  }) async {
    final categories = _activeCategories;
    if (categories.length < 2) return;
    final boundedSteps = steps.clamp(1, categories.length - 1).toInt();
    setState(() => _carouselSettling = true);
    for (var step = 0; step < boundedSteps; step += 1) {
      if (!mounted) return;
      setState(() {
        _carouselVisualDx = swipedLeft
            ? -_centerCarouselVisualSlotDistance
            : _centerCarouselVisualSlotDistance;
      });
      await Future<void>.delayed(const Duration(milliseconds: 72));
      if (!mounted) return;
      final current = _selectedCategoryIndex();
      final next = swipedLeft
          ? (current + 1) % categories.length
          : (current - 1 + categories.length) % categories.length;
      final category = categories[next];
      HapticFeedback.selectionClick();
      setState(() {
        _selectedCategoryId = category.transactionCategoryID;
        _carouselVisualDx = 0;
      });
      widget.store.setCategoryFilter(category);
      if (step < boundedSteps - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 72));
      }
    }
    if (!mounted) return;
    setState(() => _carouselSettling = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controllerFor(context);
    final geometry = controller.geometry;
    final contentTop = geometry.headerTop + _headerHeight + geometry.contentGap;
    final animationDuration = _dragging
        ? Duration.zero
        : const Duration(milliseconds: 360);
    final animationCurve = _springBack
        ? Curves.elasticOut
        : Curves.easeOutCubic;

    return ColoredBox(
      key: ValueKey('spendee-test-dashboard-stage-${_stage.name}'),
      color: const Color(0xFFF1F5F9),
      child: Stack(
        key: const ValueKey('spendee-test-dashboard'),
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            key: const ValueKey('spendee-test-header-outer-glow'),
            duration: animationDuration,
            curve: animationCurve,
            left: -36,
            right: -36,
            top: 24,
            height: 264 + _headerHeight - geometry.stage0Height,
            child: const _HeaderOuterGlow(),
          ),
          AnimatedPositioned(
            duration: animationDuration,
            curve: animationCurve,
            top: contentTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: _SpendeeHomeContent(
              store: widget.store,
              expenseTheme: widget.expenseTheme,
              stage: _stage,
              onPickSummaryMonth: widget.onPickSummaryMonth,
              onEditTransaction: widget.onEditTransaction,
              onDeleteTransactionRequested: widget.onDeleteTransactionRequested,
              onVendorSheetRequested: widget.onVendorSheetRequested,
              logBottomPadding: widget.logBottomPadding,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: geometry.headerTop,
            child: AnimatedContainer(
              duration: animationDuration,
              curve: animationCurve,
              height: _headerHeight,
              child: _SpendeeBudgetHeaderCard(
                stage: _stage,
                selectedCategory: _selectedCategory,
                selectedBar: _selectedBar,
                bars: widget.store.categoryBudgetBars,
                categories: _activeCategories,
                onHandleDragStart: _beginHeaderDrag,
                onHandleDragUpdate: _updateHeaderDrag,
                onHandleDragEnd: _endHeaderDrag,
                onCategoryTap: _selectCategory,
                carouselOffset: _carouselVisualDx,
                carouselSettling: _carouselSettling,
                onCarouselDragStart: _handleCarouselDragStart,
                onCarouselDragUpdate: _handleCarouselDragUpdate,
                onCarouselDragEnd: _handleCarouselDragEnd,
              ),
            ),
          ),
          if (widget.onSettingsPressed != null)
            Positioned(
              top: 48,
              right: 20,
              child: _AppCornerSettingsButton(
                onPressed: widget.onSettingsPressed!,
              ),
            ),
        ],
      ),
    );
  }
}

class _SpendeeBudgetHeaderCard extends StatelessWidget {
  const _SpendeeBudgetHeaderCard({
    required this.stage,
    required this.selectedCategory,
    required this.selectedBar,
    required this.bars,
    required this.categories,
    required this.onHandleDragStart,
    required this.onHandleDragUpdate,
    required this.onHandleDragEnd,
    required this.onCategoryTap,
    required this.carouselOffset,
    required this.carouselSettling,
    required this.onCarouselDragStart,
    required this.onCarouselDragUpdate,
    required this.onCarouselDragEnd,
  });

  final SpendeeHeaderStage stage;
  final TransactionCategory? selectedCategory;
  final CategoryBudgetBarData? selectedBar;
  final List<CategoryBudgetBarData> bars;
  final List<TransactionCategory> categories;
  final GestureDragStartCallback onHandleDragStart;
  final GestureDragUpdateCallback onHandleDragUpdate;
  final GestureDragEndCallback onHandleDragEnd;
  final ValueChanged<TransactionCategory> onCategoryTap;
  final double carouselOffset;
  final bool carouselSettling;
  final GestureDragStartCallback onCarouselDragStart;
  final GestureDragUpdateCallback onCarouselDragUpdate;
  final GestureDragEndCallback onCarouselDragEnd;

  @override
  Widget build(BuildContext context) {
    final categoryName = selectedCategory?.name ?? 'Budget';
    final bar = selectedBar;
    final headerValue = bar == null
        ? 'Nincs limit'
        : '${_formatFt(bar.spent)} / ${bar.hasLimit ? _formatFt(bar.limitAmount) : '0 Ft'}';
    final spentPercent = bar == null || !bar.hasLimit || bar.limitAmount <= 0
        ? 0
        : ((bar.spent / bar.limitAmount) * 100).clamp(0, 999).round();
    final remaining = bar == null || !bar.hasLimit
        ? 0.0
        : (bar.limitAmount - bar.spent).clamp(0.0, double.infinity).toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: .20),
            offset: const Offset(0, 18),
            blurRadius: 42,
          ),
          BoxShadow(
            color: const Color(0xFF0057D9).withValues(alpha: .16),
            offset: const Offset(0, 14),
            blurRadius: 34,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _HeaderGlassBackground(
                key: ValueKey('spendee-test-header-glass-layer'),
              ),
              Positioned(
                left: 20,
                top: 28,
                child: Text('Budget', style: _headerLabelStyle),
              ),
              Positioned(
                left: 20,
                right: 78,
                top: 48,
                child: Text(
                  headerValue,
                  key: const ValueKey('spendee-test-header-value'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _headerValueStyle,
                ),
              ),
              if (stage == SpendeeHeaderStage.stage0)
                Positioned(
                  left: 20,
                  right: 78,
                  top: 76,
                  child: Text(
                    bar?.hasLimit == true
                        ? 'Elköltve $spentPercent% · maradt ${_formatFt(remaining)}'
                        : '$categoryName · nincs limit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _headerSubStyle,
                  ),
                ),
              Positioned(
                top: 14,
                right: 20,
                child: _HeaderGlassMenuButton(
                  onPressed: () => HapticFeedback.selectionClick(),
                ),
              ),
              if (stage != SpendeeHeaderStage.stage0)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 96,
                  height: stage == SpendeeHeaderStage.stage1 ? 130 : 130,
                  child: _BudgetExtendedInfo(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    bars: bars,
                    spentPercent: spentPercent,
                    remaining: remaining,
                    onCategoryTap: onCategoryTap,
                    carouselOffset: carouselOffset,
                    carouselSettling: carouselSettling,
                    onCarouselDragStart: onCarouselDragStart,
                    onCarouselDragUpdate: onCarouselDragUpdate,
                    onCarouselDragEnd: onCarouselDragEnd,
                  ),
                ),
              if (stage == SpendeeHeaderStage.stage2)
                Positioned(
                  left: 16,
                  right: 16,
                  top: 236,
                  bottom: 18,
                  child: _BudgetPiePanel(
                    bars: bars,
                    selectedCategory: selectedCategory,
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 28,
                child: GestureDetector(
                  key: const ValueKey('spendee-test-header-handle'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: onHandleDragStart,
                  onVerticalDragUpdate: onHandleDragUpdate,
                  onVerticalDragEnd: onHandleDragEnd,
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .86),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .13),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderOuterGlow extends StatelessWidget {
  const _HeaderOuterGlow();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .24,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 34, sigmaY: 34),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(44),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: _budgetHeaderGradientColors,
              stops: _budgetHeaderGradientStops,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderGlassBackground extends StatelessWidget {
  const _HeaderGlassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-.9, -.55),
              end: Alignment(.9, .55),
              colors: _budgetHeaderGradientColors,
              stops: _budgetHeaderGradientStops,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-.72, -.62),
              radius: .82,
              colors: [Color(0x85FFFFFF), Color(0x00FFFFFF)],
              stops: [0, .62],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(.74, -.64),
              radius: .78,
              colors: [Color(0x426B9DE8), Color(0x21FFFFFF), Color(0x00FFFFFF)],
              stops: [0, .34, .68],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-.72, -1),
              end: Alignment(.42, 1),
              colors: [Color(0x47FFFFFF), Color(0x00FFFFFF)],
              stops: [0, .54],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetExtendedInfo extends StatelessWidget {
  const _BudgetExtendedInfo({
    required this.categories,
    required this.selectedCategory,
    required this.bars,
    required this.spentPercent,
    required this.remaining,
    required this.onCategoryTap,
    required this.carouselOffset,
    required this.carouselSettling,
    required this.onCarouselDragStart,
    required this.onCarouselDragUpdate,
    required this.onCarouselDragEnd,
  });

  final List<TransactionCategory> categories;
  final TransactionCategory? selectedCategory;
  final List<CategoryBudgetBarData> bars;
  final int spentPercent;
  final double remaining;
  final ValueChanged<TransactionCategory> onCategoryTap;
  final double carouselOffset;
  final bool carouselSettling;
  final GestureDragStartCallback onCarouselDragStart;
  final GestureDragUpdateCallback onCarouselDragUpdate;
  final GestureDragEndCallback onCarouselDragEnd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .36),
            Colors.white.withValues(alpha: .16),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: .46),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            top: 4,
            bottom: 38,
            child: GestureDetector(
              onHorizontalDragStart: onCarouselDragStart,
              onHorizontalDragUpdate: onCarouselDragUpdate,
              onHorizontalDragEnd: onCarouselDragEnd,
              child: AnimatedContainer(
                key: const ValueKey('spendee-test-context-carousel'),
                duration: carouselSettling
                    ? const Duration(milliseconds: 72)
                    : Duration.zero,
                curve: Curves.easeOutQuad,
                transform: Matrix4.translationValues(carouselOffset, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final category in _visibleAvatarCategories()) ...[
                      _ContextAvatar(
                        category: category,
                        selected:
                            category.transactionCategoryID ==
                            selectedCategory?.transactionCategoryID,
                        onTap: () => onCategoryTap(category),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Elköltve $spentPercent%', style: _budgetMetaStyle),
                    Text(
                      'Maradt ${_formatFt(remaining)}',
                      style: _budgetMetaStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _PartitionBar(bars: bars),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionCategory> _visibleAvatarCategories() {
    if (categories.length <= 5) return categories;
    final selectedIndex = categories.indexWhere(
      (category) =>
          category.transactionCategoryID ==
          selectedCategory?.transactionCategoryID,
    );
    final center = selectedIndex < 0 ? 0 : selectedIndex;
    return List<TransactionCategory>.generate(5, (offset) {
      final index = (center - 2 + offset) % categories.length;
      return categories[index < 0 ? index + categories.length : index];
    });
  }
}

class _ContextAvatar extends StatelessWidget {
  const _ContextAvatar({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 66.0 : 46.0;
    final iconSize = selected ? 30.0 : 22.0;
    return GestureDetector(
      key: ValueKey(
        'spendee-test-category-avatar-${category.transactionCategoryID}',
      ),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: CategoryColorManager.gradient(category.colorSlot),
          border: Border.all(color: Colors.white.withValues(alpha: .58)),
          boxShadow: [
            BoxShadow(
              color: category.slotColor.withValues(alpha: selected ? .24 : .12),
              offset: Offset(0, selected ? 14 : 9),
              blurRadius: selected ? 28 : 18,
            ),
            if (selected)
              BoxShadow(
                color: Colors.white.withValues(alpha: .46),
                spreadRadius: 5,
              ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _AvatarTopHighlightPainter(
                opacity: selected ? .78 : .72,
              ),
            ),
            Center(
              child: CategoryIconBadge(
                category: category,
                backgroundColor: Colors.transparent,
                size: size,
                iconSize: iconSize,
                iconStrokeWidth: 1.4,
                showShadow: false,
                debugSource: 'spendee-test-context-avatar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarTopHighlightPainter extends CustomPainter {
  const _AvatarTopHighlightPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: opacity);
    final inset = stroke.strokeWidth / 2 + 1;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawArc(rect, math.pi * 1.08, math.pi * .84, false, stroke);
  }

  @override
  bool shouldRepaint(covariant _AvatarTopHighlightPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

class _PartitionBar extends StatelessWidget {
  const _PartitionBar({required this.bars});

  final List<CategoryBudgetBarData> bars;

  @override
  Widget build(BuildContext context) {
    final visibleBars = bars.where((bar) => bar.spent > 0).toList();
    final total = visibleBars.fold<double>(0, (sum, bar) => sum + bar.spent);
    if (visibleBars.isEmpty || total <= 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final bar in visibleBars)
              Expanded(
                flex: math.max(1, (bar.spent / total * 1000).round()),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: CategoryColorManager.gradient(
                      bar.category?.colorSlot,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetPiePanel extends StatelessWidget {
  const _BudgetPiePanel({required this.bars, required this.selectedCategory});

  final List<CategoryBudgetBarData> bars;
  final TransactionCategory? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final visibleBars = bars.where((bar) => bar.spent > 0).toList();
    final total = visibleBars.fold<double>(0, (sum, bar) => sum + bar.spent);
    final selectedId = selectedCategory?.transactionCategoryID;
    final selectedBar = visibleBars.cast<CategoryBudgetBarData?>().firstWhere(
      (bar) => bar?.targetId == selectedId,
      orElse: () => visibleBars.isEmpty ? null : visibleBars.first,
    );
    final selectedPercent = selectedBar == null || total <= 0
        ? 0
        : (selectedBar.spent / total * 100).round();
    return Container(
      key: const ValueKey('spendee-test-budget-pie-panel'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x5CFFFFFF), Color(0x26FFFFFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: .52),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            offset: const Offset(0, 7),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-.72, -.92),
                radius: .82,
                colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
                stops: [0, .62],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kategória arány', style: _smallCapsStyle),
                        SizedBox(height: 4),
                        Text('limit mix', style: _pieHeadlineStyle),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 112,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 112,
                        height: 112,
                        child: CustomPaint(
                          painter: _BudgetPiePainter(
                            bars: visibleBars,
                            total: total,
                            selectedCategoryId: selectedId,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BudgetPieFocus(
                          key: const ValueKey('spendee-test-budget-pie-focus'),
                          bar: selectedBar,
                          percent: selectedPercent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: visibleBars.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final bar = visibleBars[index];
                      final selected = bar.targetId == selectedId;
                      final percent = total <= 0
                          ? 0
                          : (bar.spent / total * 100).round();
                      return Container(
                        constraints: const BoxConstraints(minHeight: 25),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? RadialGradient(
                                  center: const Alignment(-1, -1),
                                  radius: 1.1,
                                  colors: [
                                    Colors.white.withValues(alpha: .50),
                                    bar.color.withValues(alpha: .18),
                                  ],
                                )
                              : null,
                          color: selected
                              ? null
                              : Colors.white.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (selected)
                              BoxShadow(
                                color: bar.color.withValues(alpha: .24),
                                offset: const Offset(0, 8),
                                blurRadius: 18,
                              ),
                            BoxShadow(
                              color: Colors.white.withValues(
                                alpha: selected ? .42 : .24,
                              ),
                              offset: const Offset(0, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: CategoryColorManager.gradient(
                                  bar.category?.colorSlot,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: bar.color.withValues(alpha: .48),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bar.title,
                                overflow: TextOverflow.ellipsis,
                                style: _pieRowStyle,
                              ),
                            ),
                            Text(
                              '$percent% · ${_formatFt(bar.spent)}',
                              style: _pieValueStyle,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetPieFocus extends StatelessWidget {
  const _BudgetPieFocus({super.key, required this.bar, required this.percent});

  final CategoryBudgetBarData? bar;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('kiemelt kategória', style: _pieFocusLabelStyle),
        const SizedBox(height: 5),
        Text(
          bar?.title ?? 'Nincs adat',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _pieFocusTitleStyle,
        ),
        const SizedBox(height: 5),
        Text(
          bar == null
              ? '0 Ft · 0% a kategória-kosárból'
              : '${_formatFt(bar!.spent)} · $percent% a kategória-kosárból',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _pieFocusMetaStyle,
        ),
      ],
    );
  }
}

class _BudgetPiePainter extends CustomPainter {
  const _BudgetPiePainter({
    required this.bars,
    required this.total,
    required this.selectedCategoryId,
  });

  final List<CategoryBudgetBarData> bars;
  final double total;
  final int? selectedCategoryId;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final shadowPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius + 3));
    canvas.drawShadow(
      shadowPath,
      const Color(0xFF0F172A).withValues(alpha: .16),
      10,
      false,
    );
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..color = Colors.white.withValues(alpha: .40);
    canvas.drawCircle(center, radius, basePaint);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final bar in bars) {
      final sweep = (bar.spent / total) * math.pi * 2;
      final selected = bar.targetId == selectedCategoryId;
      if (selected) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 19
          ..strokeCap = StrokeCap.butt
          ..color = bar.color.withValues(alpha: .42)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
          glowPaint,
        );
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 17 : 13
        ..strokeCap = StrokeCap.butt
        ..color = bar.color.withValues(alpha: selected ? 1 : .74);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
    canvas.drawCircle(
      center,
      radius - 15,
      Paint()..color = Colors.white.withValues(alpha: .40),
    );
    canvas.drawCircle(
      center,
      radius - 15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .48),
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetPiePainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.total != total ||
        oldDelegate.selectedCategoryId != selectedCategoryId;
  }
}

class _SpendeeHomeContent extends StatelessWidget {
  const _SpendeeHomeContent({
    required this.store,
    required this.expenseTheme,
    required this.stage,
    required this.onPickSummaryMonth,
    required this.onEditTransaction,
    required this.onDeleteTransactionRequested,
    required this.onVendorSheetRequested,
    required this.logBottomPadding,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;
  final SpendeeHeaderStage stage;
  final VoidCallback onPickSummaryMonth;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final TransactionDeleteRequest? onDeleteTransactionRequested;
  final VoidCallback? onVendorSheetRequested;
  final double logBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 66,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: _SpendeeTypePill(
                    label: 'Bevétel',
                    active: store.activeType == TransactionType.income,
                    activeGradient: const LinearGradient(
                      colors: [Colors.white, Colors.white],
                    ),
                    textColor: store.activeType == TransactionType.income
                        ? const Color(0xFF14213A)
                        : AppColors.gray500,
                    onTap: () => store.setActiveType(TransactionType.income),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SpendeeTypePill(
                    label: 'Kiadás',
                    active: store.activeType == TransactionType.expense,
                    activeGradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFB15C),
                        Color(0xFFFF6B6B),
                        Color(0xFFF5368D),
                      ],
                    ),
                    textColor: store.activeType == TransactionType.expense
                        ? Colors.white
                        : AppColors.gray500,
                    onTap: () => store.setActiveType(TransactionType.expense),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          key: const ValueKey('spendee-test-summary-pill'),
          onTap: onPickSummaryMonth,
          onDoubleTap: store.resetSummaryToCurrentMonth,
          onVerticalDragEnd: (_) => store.cycleSummaryWindow(),
          onHorizontalDragEnd: (details) {
            final dx = details.velocity.pixelsPerSecond.dx;
            if (dx == 0) return;
            store.shiftSummaryPeriod(dx < 0 ? 1 : -1);
          },
          child: Container(
            height: 59,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _softWhiteDecoration(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    store.activeSummaryTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  store.activeSummary.formattedFor(store.activeType),
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: _softWhiteDecoration(18),
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('spendee-test-search-vendor-button'),
                onPressed: onVendorSheetRequested,
                icon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.gray400,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
              ),
              Expanded(
                child: TextFormField(
                  key: ValueKey(
                    'spendee-test-search-input-${store.searchQuery}',
                  ),
                  initialValue: store.searchQuery,
                  onChanged: store.setSearchQuery,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Keresés tranzakciók között...',
                    hintStyle: TextStyle(
                      color: AppColors.gray500,
                      fontSize: 14,
                    ),
                  ),
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (stage != SpendeeHeaderStage.stage2) ...[
          SizedBox(
            height: 24,
            child: Center(
              child: Text(
                '${store.visibleTransactions.length} tranzakció',
                key: const ValueKey('spendee-test-transaction-count'),
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: _SpendeeLogList(
              entries: store.visibleDisplayLogEntries,
              categoriesById: store.categoriesById,
              bottomPadding: logBottomPadding,
              onFastFilter: (record, _) =>
                  store.setMerchantFilter(record.displayMerchant),
              onRecordTap: onEditTransaction,
              onDeleteRequested: onDeleteTransactionRequested,
              onCategoryFilter: store.setCategoryFilter,
            ),
          ),
        ],
      ],
    );
  }
}

class _SpendeeTypePill extends StatelessWidget {
  const _SpendeeTypePill({
    required this.label,
    required this.active,
    required this.activeGradient,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Gradient activeGradient;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: active ? activeGradient : null,
          color: active ? null : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SpendeeLogList extends StatelessWidget {
  const _SpendeeLogList({
    required this.entries,
    required this.categoriesById,
    required this.bottomPadding,
    required this.onFastFilter,
    required this.onRecordTap,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
  });

  final List<TransactionLogEntry> entries;
  final Map<int, TransactionCategory> categoriesById;
  final double bottomPadding;
  final TransactionLogContextCallback onFastFilter;
  final ValueChanged<TransactionRecord>? onRecordTap;
  final TransactionDeleteRequest? onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'Nincs megjeleníthető tranzakció',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(bottom: bottomPadding),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final header = entry.header;
        if (header != null) {
          return SizedBox(
            height: 24,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 5, 24, 0),
              child: Text(
                header,
                style: const TextStyle(
                  color: AppColors.gray500,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }
        final record = entry.record;
        if (record == null) return const SizedBox.shrink();
        final category = categoriesById[record.transactionCategoryID];
        return _SpendeeLogBox(
          record: record,
          category: category,
          onTap: onRecordTap,
          onFastFilter: onFastFilter,
          onDeleteRequested: onDeleteRequested,
          onCategoryFilter: onCategoryFilter,
        );
      },
    );
  }
}

class _SpendeeLogBox extends StatelessWidget {
  const _SpendeeLogBox({
    required this.record,
    required this.category,
    required this.onTap,
    required this.onFastFilter,
    required this.onDeleteRequested,
    required this.onCategoryFilter,
  });

  final TransactionRecord record;
  final TransactionCategory? category;
  final ValueChanged<TransactionRecord>? onTap;
  final TransactionLogContextCallback onFastFilter;
  final TransactionDeleteRequest? onDeleteRequested;
  final ValueChanged<TransactionCategory> onCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final amountColor = record.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    return GestureDetector(
      key: ValueKey('spendee-test-logbox-${record.id}'),
      onTap: () => onTap?.call(record),
      onHorizontalDragEnd: (details) {
        final dx = details.velocity.pixelsPerSecond.dx;
        if (dx < -200) onFastFilter(record, category);
        if (dx > 200 && onDeleteRequested != null) {
          onDeleteRequested!(record);
        }
      },
      child: Container(
        height: 64.8,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: _softWhiteDecoration(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: category == null
                  ? null
                  : () => onCategoryFilter(category!),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CategoryColorManager.gradient(category?.colorSlot),
                  boxShadow: [
                    BoxShadow(
                      color: (category?.slotColor ?? AppColors.gray500)
                          .withValues(alpha: .18),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: CategoryIconBadge(
                    category: category,
                    backgroundColor: Colors.transparent,
                    size: 46,
                    iconSize: 28,
                    iconStrokeWidth: 1.35,
                    showShadow: false,
                    showQuestionMark: category == null,
                    debugSource: 'spendee-test-logbox',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.displayMerchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category?.name ?? 'Kategória nélkül',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record.displayAmount,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.displayTime,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCornerSettingsButton extends StatelessWidget {
  const _AppCornerSettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('spendee-test-app-settings-button'),
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .70),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: .62)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: .54),
              offset: const Offset(0, 1),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF1F2D46).withValues(alpha: .10),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: const Icon(
          Icons.settings_outlined,
          color: Color(0xFF14213A),
          size: 18,
        ),
      ),
    );
  }
}

class _HeaderGlassMenuButton extends StatelessWidget {
  const _HeaderGlassMenuButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('spendee-test-header-menu-button'),
      onTap: onPressed,
      child: Container(
        width: 33.6,
        height: 33.6,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .32),
          borderRadius: BorderRadius.circular(13.6),
          border: Border.all(color: Colors.white.withValues(alpha: .48)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: .54),
              offset: const Offset(0, 1),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF06B6D4).withValues(alpha: .12),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _GlassMenuBar(),
            SizedBox(height: 3),
            _GlassMenuBar(),
            SizedBox(height: 3),
            _GlassMenuBar(),
          ],
        ),
      ),
    );
  }
}

class _GlassMenuBar extends StatelessWidget {
  const _GlassMenuBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 2.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF5FFFFFF), Color(0xB8DEFFFF), Color(0x7595E5EC)],
          stops: [0, .52, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: .42),
            offset: const Offset(0, -.6),
            blurRadius: .2,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _softWhiteDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1F2D46).withValues(alpha: .08),
        offset: const Offset(0, 8),
        blurRadius: 20,
      ),
      BoxShadow(
        color: const Color(0xFF1F2D46).withValues(alpha: .04),
        offset: const Offset(0, 1),
        blurRadius: 3,
      ),
    ],
  );
}

String _formatFt(double value) {
  final rounded = value.round();
  final sign = rounded < 0 ? '-' : '';
  final digits = rounded.abs().toString();
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(' ');
  }
  buffer.write(' Ft');
  return buffer.toString();
}

const _headerLabelStyle = TextStyle(
  color: Color(0xB814213A),
  fontSize: 11,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: .44,
);

const _headerValueStyle = TextStyle(
  color: Color(0xFF14213A),
  fontSize: 23,
  height: 1.08,
  fontWeight: FontWeight.w900,
  letterSpacing: -0.9,
  shadows: [
    Shadow(color: Color(0x6BFFFFFF), offset: Offset(0, 1)),
    Shadow(color: Color(0x38FFFFFF), offset: Offset(0, 2), blurRadius: 8),
  ],
);

const _headerSubStyle = TextStyle(
  color: Color(0xB314213A),
  fontSize: 12,
  height: 1,
  fontWeight: FontWeight.w800,
);

const _budgetMetaStyle = TextStyle(
  color: Color(0xB314213A),
  fontSize: 10,
  height: 1,
  fontWeight: FontWeight.w900,
);

const _smallCapsStyle = TextStyle(
  color: Color(0xA814213A),
  fontSize: 10,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: .5,
);

const _pieHeadlineStyle = TextStyle(
  color: Color(0xFF14213A),
  fontSize: 17,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: -.68,
);

const _pieFocusLabelStyle = TextStyle(
  color: Color(0x8514213A),
  fontSize: 8,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: .48,
);

const _pieFocusTitleStyle = TextStyle(
  color: Color(0xFF14213A),
  fontSize: 18,
  height: 1,
  fontWeight: FontWeight.w900,
  letterSpacing: -.72,
);

const _pieFocusMetaStyle = TextStyle(
  color: Color(0x9414213A),
  fontSize: 8,
  height: 1.2,
  fontWeight: FontWeight.w800,
);

const _pieRowStyle = TextStyle(
  color: Color(0xC214213A),
  fontSize: 9,
  height: 1,
  fontWeight: FontWeight.w900,
);

const _pieValueStyle = TextStyle(
  color: Color(0x9E14213A),
  fontSize: 8,
  height: 1,
  fontWeight: FontWeight.w900,
);
