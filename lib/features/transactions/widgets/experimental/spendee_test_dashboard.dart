import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/platform/browser_fullscreen_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/category_color_manager.dart';
import '../../../settings/theme/expense_theme.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_log_entry.dart';
import '../../models/transaction_record.dart';
import '../../state/transaction_store.dart';
import '../glossy_category_avatar.dart';
import '../transaction_log_box.dart';
import 'fluvi_logo.dart';
import 'spendee_center_carousel_controller.dart';
import 'spendee_header_glass.dart';
import 'spendee_header_stage_controller.dart';
import 'spendee_header_visual_spec.dart';

final _budgetHeaderVisualSpec = SpendeeHeaderVisualSpec.budgetDefault();

class SpendeeTestDashboard extends StatefulWidget {
  const SpendeeTestDashboard({
    super.key,
    required this.store,
    required this.expenseTheme,
    this.browserFullscreenController,
    required this.onPickSummaryMonth,
    required this.onEditTransaction,
    required this.onDeleteTransactionRequested,
    required this.onVendorSheetRequested,
    required this.logBottomPadding,
  });

  final TransactionStore store;
  final ExpenseTheme expenseTheme;
  final BrowserFullscreenController? browserFullscreenController;
  final VoidCallback onPickSummaryMonth;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final TransactionDeleteRequest? onDeleteTransactionRequested;
  final VoidCallback? onVendorSheetRequested;
  final double logBottomPadding;

  @override
  State<SpendeeTestDashboard> createState() => _SpendeeTestDashboardState();
}

class _SpendeeTestDashboardState extends State<SpendeeTestDashboard>
    with SingleTickerProviderStateMixin {
  SpendeeHeaderStageController? _stageController;
  SpendeeHeaderStage _stage = SpendeeHeaderStage.stage0;
  var _headerHeight = 104.0;
  var _dragging = false;
  var _springBack = false;
  var _carouselLiveTicked = false;
  var _carouselVisualDx = 0.0;
  SpendeeCenterCarouselController? _carouselController;
  late final AnimationController _carouselReleaseController;
  var _carouselMotionSerial = 0;
  int? _selectedCategoryId;
  int? _pulsingCategoryId;
  Timer? _avatarPulseTimer;
  final Map<FluviLogoArc, FluviLogoFill> _logoFills =
      Map<FluviLogoArc, FluviLogoFill>.of(FluviLogoSvg.defaultFills);

  @override
  void initState() {
    super.initState();
    _carouselReleaseController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _avatarPulseTimer?.cancel();
    _carouselReleaseController.dispose();
    super.dispose();
  }

  SpendeeHeaderStageGeometry _geometryFor(BuildContext context) {
    return SpendeeHeaderStageGeometry.html(
      screenHeight: MediaQuery.sizeOf(context).height,
    );
  }

  SpendeeHeaderStageController _controllerFor(BuildContext context) {
    final geometry = _geometryFor(context);
    final existing = _stageController;
    if (existing != null) {
      existing.replaceGeometry(geometry);
      _headerHeight = existing.currentHeight;
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
    for (var index = 0; index < update.tickCount; index++) {
      HapticFeedback.selectionClick();
    }
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

  void _selectCategory(
    TransactionCategory category, {
    bool haptic = true,
    bool animateCarousel = false,
  }) {
    if (animateCarousel) {
      unawaited(_animateCarouselToCategory(category, haptic: haptic));
      return;
    }
    _applySelectedCategory(category, haptic: haptic);
  }

  void _applySelectedCategory(
    TransactionCategory category, {
    bool haptic = true,
  }) {
    if (haptic) HapticFeedback.selectionClick();
    _markAvatarPulse(category.transactionCategoryID);
    widget.store.setCategoryFilter(category);
    if (!mounted) return;
    setState(() {
      _selectedCategoryId = category.transactionCategoryID;
    });
  }

  void _markAvatarPulse(int categoryId) {
    _avatarPulseTimer?.cancel();
    if (!mounted) return;
    setState(() => _pulsingCategoryId = categoryId);
    _avatarPulseTimer = Timer(const Duration(milliseconds: 190), () {
      if (!mounted) return;
      setState(() => _pulsingCategoryId = null);
    });
  }

  Future<void> _animateCarouselToCategory(
    TransactionCategory category, {
    bool haptic = true,
  }) async {
    final categories = _activeCategories;
    final targetIndex = categories.indexWhere(
      (item) => item.transactionCategoryID == category.transactionCategoryID,
    );
    if (targetIndex < 0) return;
    final initialIndex = _selectedCategoryIndex();
    if (targetIndex == initialIndex) {
      _applySelectedCategory(category, haptic: haptic);
      return;
    }
    _carouselMotionSerial += 1;
    final serial = _carouselMotionSerial;
    _carouselReleaseController.stop();
    final controller = SpendeeCenterCarouselController(
      itemCount: categories.length,
      initialIndex: initialIndex,
    );
    final travel = controller.travelToIndex(targetIndex);
    setState(() {
      _carouselLiveTicked = false;
      _carouselVisualDx = 0;
      _carouselController = controller;
    });
    try {
      await _animateCarouselTravel(
        controller: controller,
        travel: travel,
        duration: Duration(
          milliseconds: (170 + travel.abs() * 1.15).clamp(210, 520).round(),
        ),
        curve: Curves.easeOutCubic,
      );
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && serial == _carouselMotionSerial) {
        _carouselController = null;
        _applySelectedCategory(category, haptic: false);
        setState(() {
          _carouselVisualDx = 0;
        });
      }
    }
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
    _carouselMotionSerial += 1;
    _carouselReleaseController.stop();
    setState(() {
      _carouselLiveTicked = false;
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
      _markAvatarPulse(latestCategory.transactionCategoryID);
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
    unawaited(
      _releaseCarouselBelt(
        controller: controller,
        velocityDx: details.velocity.pixelsPerSecond.dx,
        liveTicked: _carouselLiveTicked,
        serial: _carouselMotionSerial,
      ),
    );
  }

  void _handleCarouselDragCancel() {
    final controller = _carouselController;
    if (controller == null) return;
    unawaited(
      _cancelCarouselBelt(
        controller: controller,
        serial: _carouselMotionSerial,
      ),
    );
  }

  Future<void> _cancelCarouselBelt({
    required SpendeeCenterCarouselController controller,
    required int serial,
  }) async {
    _carouselLiveTicked = false;
    final travel = controller.cancelTravel();
    try {
      if (travel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: travel,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && serial == _carouselMotionSerial) {
        _carouselController = null;
        setState(() => _carouselVisualDx = 0);
      }
    }
  }

  Future<void> _releaseCarouselBelt({
    required SpendeeCenterCarouselController controller,
    required double velocityDx,
    required bool liveTicked,
    required int serial,
  }) async {
    final motion = controller.releaseMotion(
      velocityDx: velocityDx,
      liveTicked: liveTicked,
    );
    _carouselLiveTicked = false;
    try {
      if (motion.initialTravel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: motion.initialTravel,
          duration: motion.initialDuration,
          curve: motion.inertial ? Curves.easeOutQuad : Curves.easeOutCubic,
        );
      }
      if (!mounted || serial != _carouselMotionSerial) return;
      final settleTravel = controller.settleTravel(
        preferredDxDirection: motion.preferredDxDirection,
        allowDirectionalSnap: motion.directionalSnapAllowed,
      );
      if (settleTravel.abs() >= .5) {
        await _animateCarouselTravel(
          controller: controller,
          travel: settleTravel,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        );
      }
    } on TickerCanceled {
      return;
    } finally {
      if (mounted && serial == _carouselMotionSerial) {
        _carouselController = null;
        setState(() {
          _carouselVisualDx = 0;
        });
      }
    }
  }

  Future<void> _animateCarouselTravel({
    required SpendeeCenterCarouselController controller,
    required double travel,
    required Duration duration,
    required Curve curve,
  }) async {
    _carouselReleaseController.stop();
    _carouselReleaseController.duration = duration;
    var lastValue = 0.0;
    final animation = Tween<double>(begin: 0, end: travel).animate(
      CurvedAnimation(parent: _carouselReleaseController, curve: curve),
    );
    void applyFrame() {
      final delta = animation.value - lastValue;
      lastValue = animation.value;
      if (delta == 0 || !mounted) return;
      _applyCarouselMotionDelta(controller, delta);
    }

    animation.addListener(applyFrame);
    try {
      await _carouselReleaseController.forward(from: 0).orCancel;
    } finally {
      animation.removeListener(applyFrame);
    }
  }

  void _applyCarouselMotionDelta(
    SpendeeCenterCarouselController controller,
    double deltaDx,
  ) {
    final categories = _activeCategories;
    if (categories.length < 2) return;
    final update = controller.applyDragDelta(deltaDx);
    TransactionCategory? latestCategory;
    for (final index in update.tickedIndexes) {
      latestCategory = categories[index % categories.length];
      HapticFeedback.selectionClick();
    }
    if (latestCategory != null) {
      widget.store.setCategoryFilter(latestCategory);
      _markAvatarPulse(latestCategory.transactionCategoryID);
    }
    setState(() {
      if (latestCategory != null) {
        _selectedCategoryId = latestCategory.transactionCategoryID;
      }
      _carouselVisualDx = update.residualDx;
    });
  }

  void _openLogoEditor() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LogoEditorSheet(
          fills: _logoFills,
          onFillChanged: (arc, fill) {
            setState(() {
              _logoFills[arc] = fill;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controllerFor(context);
    final geometry = controller.geometry;
    var overviewBudgetLimit = 0.0;
    for (final item in widget.store.overviewBudgetItems) {
      if (item.hasLimit && item.limitAmount > 0) {
        overviewBudgetLimit = item.limitAmount;
        break;
      }
    }
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
            left: -_budgetHeaderVisualSpec.glow.horizontalOverflow,
            right: -_budgetHeaderVisualSpec.glow.horizontalOverflow,
            top: _budgetHeaderVisualSpec.glow.top,
            height: _budgetHeaderVisualSpec.glow.heightForHeader(_headerHeight),
            child: SpendeeHeaderOuterGlowSurface(spec: _budgetHeaderVisualSpec),
          ),
          AnimatedPositioned(
            duration: animationDuration,
            curve: animationCurve,
            top: contentTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: _SpendeeHomeContent(
              key: const ValueKey('spendee-test-home-content'),
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
              key: const ValueKey('spendee-test-header-card'),
              duration: animationDuration,
              curve: animationCurve,
              height: _headerHeight,
              child: RepaintBoundary(
                key: const ValueKey('spendee-test-header-golden-boundary'),
                child: _SpendeeBudgetHeaderCard(
                  stage: _stage,
                  selectedCategory: _selectedCategory,
                  selectedBar: _selectedBar,
                  bars: widget.store.categoryBudgetBars,
                  budgetLimitAmount: overviewBudgetLimit,
                  categories: _activeCategories,
                  onHandleDragStart: _beginHeaderDrag,
                  onHandleDragUpdate: _updateHeaderDrag,
                  onHandleDragEnd: _endHeaderDrag,
                  onCategoryTap: _selectCategory,
                  onPieCategoryTap: (category) =>
                      _selectCategory(category, animateCarousel: true),
                  pulsingCategoryId: _pulsingCategoryId,
                  carouselOffset: _carouselVisualDx,
                  onCarouselDragStart: _handleCarouselDragStart,
                  onCarouselDragUpdate: _handleCarouselDragUpdate,
                  onCarouselDragEnd: _handleCarouselDragEnd,
                  onCarouselDragCancel: _handleCarouselDragCancel,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 33.3,
            height: 118,
            child: _SpendeeBrandLockup(
              key: const ValueKey('spendee-test-brand-lockup'),
              logoFills: _logoFills,
              onLogoTap: _openLogoEditor,
            ),
          ),
          if (widget.browserFullscreenController case final controller?)
            Positioned(
              top: 48,
              right: 20,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  if (!controller.isAvailable) {
                    return const SizedBox.shrink();
                  }
                  return _AppCornerFullscreenButton(
                    fullscreen: controller.isFullscreen,
                    requestPending: controller.requestPending,
                    onPressed: () => unawaited(controller.toggle()),
                  );
                },
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
    required this.budgetLimitAmount,
    required this.categories,
    required this.onHandleDragStart,
    required this.onHandleDragUpdate,
    required this.onHandleDragEnd,
    required this.onCategoryTap,
    required this.onPieCategoryTap,
    required this.pulsingCategoryId,
    required this.carouselOffset,
    required this.onCarouselDragStart,
    required this.onCarouselDragUpdate,
    required this.onCarouselDragEnd,
    required this.onCarouselDragCancel,
  });

  final SpendeeHeaderStage stage;
  final TransactionCategory? selectedCategory;
  final CategoryBudgetBarData? selectedBar;
  final List<CategoryBudgetBarData> bars;
  final double budgetLimitAmount;
  final List<TransactionCategory> categories;
  final GestureDragStartCallback onHandleDragStart;
  final GestureDragUpdateCallback onHandleDragUpdate;
  final GestureDragEndCallback onHandleDragEnd;
  final ValueChanged<TransactionCategory> onCategoryTap;
  final ValueChanged<TransactionCategory> onPieCategoryTap;
  final int? pulsingCategoryId;
  final double carouselOffset;
  final GestureDragStartCallback onCarouselDragStart;
  final GestureDragUpdateCallback onCarouselDragUpdate;
  final GestureDragEndCallback onCarouselDragEnd;
  final GestureDragCancelCallback onCarouselDragCancel;

  @override
  Widget build(BuildContext context) {
    final budgetSpec = _budgetHeaderVisualSpec.budget;
    final bar = selectedBar;
    final headerValue = bar == null
        ? 'Nincs limit'
        : '${_formatFt(bar.spent)} / ${bar.hasLimit ? _formatFt(bar.limitAmount) : '0 Ft'}';

    return SpendeeHeaderGlassSurface(
      spec: _budgetHeaderVisualSpec,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 20,
            top: 28,
            child: Text('BUDGET', style: _headerLabelStyle),
          ),
          Positioned(
            left: 20,
            right: 78,
            top: 48,
            child: _HeaderValueText(headerValue),
          ),
          Positioned(
            key: const ValueKey('spendee-test-header-core-partition'),
            left: 20,
            right: 78,
            top: 78,
            child: _PartitionBar(
              key: const ValueKey('spendee-test-partition-bar'),
              bars: bars,
              totalLimit: budgetLimitAmount,
              height: 5,
            ),
          ),
          Positioned(
            top: _budgetHeaderVisualSpec.menu.top,
            right: _budgetHeaderVisualSpec.menu.right,
            child: SpendeeHeaderMenuButton(
              spec: _budgetHeaderVisualSpec,
              onPressed: () => HapticFeedback.selectionClick(),
            ),
          ),
          if (stage != SpendeeHeaderStage.stage0)
            Positioned(
              left: budgetSpec.stage1HorizontalInset,
              right: budgetSpec.stage1HorizontalInset,
              top: budgetSpec.stage1Top,
              height: budgetSpec.stage1Height,
              child: _BudgetExtendedInfo(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategoryTap: onCategoryTap,
                pulsingCategoryId: pulsingCategoryId,
                carouselOffset: carouselOffset,
                onCarouselDragStart: onCarouselDragStart,
                onCarouselDragUpdate: onCarouselDragUpdate,
                onCarouselDragEnd: onCarouselDragEnd,
                onCarouselDragCancel: onCarouselDragCancel,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _budgetHeaderVisualSpec.handle.hitHeight,
            child: SpendeeHeaderHandle(
              spec: _budgetHeaderVisualSpec,
              onVerticalDragStart: onHandleDragStart,
              onVerticalDragUpdate: onHandleDragUpdate,
              onVerticalDragEnd: onHandleDragEnd,
            ),
          ),
          if (stage == SpendeeHeaderStage.stage2)
            Positioned(
              left: budgetSpec.stage1HorizontalInset,
              right: budgetSpec.stage1HorizontalInset,
              top: budgetSpec.stage2Top,
              bottom: budgetSpec.stage2Bottom,
              child: _BudgetPieStage2Layer(
                bars: bars,
                selectedCategory: selectedCategory,
                onCategoryTap: onPieCategoryTap,
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetExtendedInfo extends StatelessWidget {
  const _BudgetExtendedInfo({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.pulsingCategoryId,
    required this.carouselOffset,
    required this.onCarouselDragStart,
    required this.onCarouselDragUpdate,
    required this.onCarouselDragEnd,
    required this.onCarouselDragCancel,
  });

  final List<TransactionCategory> categories;
  final TransactionCategory? selectedCategory;
  final ValueChanged<TransactionCategory> onCategoryTap;
  final int? pulsingCategoryId;
  final double carouselOffset;
  final GestureDragStartCallback onCarouselDragStart;
  final GestureDragUpdateCallback onCarouselDragUpdate;
  final GestureDragEndCallback onCarouselDragEnd;
  final GestureDragCancelCallback onCarouselDragCancel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('spendee-test-budget-stage1-glossy'),
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
            top: 0,
            bottom: 0,
            child: GestureDetector(
              key: const ValueKey('spendee-test-context-carousel-gesture'),
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onHorizontalDragStart: onCarouselDragStart,
              onHorizontalDragUpdate: onCarouselDragUpdate,
              onHorizontalDragEnd: onCarouselDragEnd,
              onHorizontalDragCancel: onCarouselDragCancel,
              child: AnimatedContainer(
                key: const ValueKey('spendee-test-context-carousel'),
                duration: Duration.zero,
                curve: Curves.easeOutQuad,
                transform: Matrix4.translationValues(carouselOffset, 0, 0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Builder(
                    builder: (context) {
                      final visible = _visibleAvatarCategories();
                      final centerIndex = visible.indexWhere(
                        (category) =>
                            category.transactionCategoryID ==
                            selectedCategory?.transactionCategoryID,
                      );
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (
                            var index = 0;
                            index < visible.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 12),
                            _ContextAvatar(
                              category: visible[index],
                              distanceFromCenter: centerIndex < 0
                                  ? index
                                  : (index - centerIndex).abs(),
                              selected:
                                  visible[index].transactionCategoryID ==
                                  selectedCategory?.transactionCategoryID,
                              pulsing:
                                  visible[index].transactionCategoryID ==
                                  pulsingCategoryId,
                              onTap: () => onCategoryTap(visible[index]),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
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
    required this.distanceFromCenter,
    required this.selected,
    required this.pulsing,
    required this.onTap,
  });

  final TransactionCategory category;
  final int distanceFromCenter;
  final bool selected;
  final bool pulsing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visualIndex = selected ? 2 : (distanceFromCenter <= 1 ? 1 : 0);
    final size = _budgetHeaderVisualSpec.budget.avatarSizes[visualIndex];
    final iconSize =
        _budgetHeaderVisualSpec.budget.avatarIconSizes[visualIndex];
    final opacity = selected ? 1.0 : (distanceFromCenter <= 1 ? .9 : .72);
    return GestureDetector(
      key: ValueKey(
        selected
            ? 'spendee-test-category-avatar-${category.transactionCategoryID}-selected'
            : 'spendee-test-category-avatar-${category.transactionCategoryID}',
      ),
      onTap: onTap,
      child: GlossyCategoryAvatar(
        category: category,
        size: size,
        iconSize: iconSize,
        selected: selected,
        pulsing: pulsing,
        opacity: opacity,
        debugSource: 'spendee-test-context-avatar',
      ),
    );
  }
}

class _PartitionBar extends StatelessWidget {
  const _PartitionBar({
    super.key,
    required this.bars,
    required this.totalLimit,
    this.height = 10,
  });

  final List<CategoryBudgetBarData> bars;
  final double totalLimit;
  final double height;

  @override
  Widget build(BuildContext context) {
    final visibleBars = bars
        .where((bar) => bar.spent > 0 || bar.limitAmount > 0)
        .toList();
    final allocated = visibleBars.fold<double>(
      0,
      (sum, bar) => sum + (bar.limitAmount > 0 ? bar.limitAmount : bar.spent),
    );
    final free = math.max(0.0, totalLimit - allocated);
    final scaleTotal = math.max(totalLimit, allocated);
    if (visibleBars.isEmpty || scaleTotal <= 0) {
      return Container(
        key: const ValueKey('spendee-test-partition-segment-free'),
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final bar in visibleBars) ...[
              _partitionSegment(
                key: ValueKey(
                  'spendee-test-partition-segment-used-${bar.targetId}',
                ),
                amount: bar.limitAmount > 0
                    ? math.min(bar.spent, bar.limitAmount)
                    : bar.spent,
                scaleTotal: scaleTotal,
                bar: bar,
                opacity: 1,
              ),
              _partitionSegment(
                key: ValueKey(
                  'spendee-test-partition-segment-remaining-${bar.targetId}',
                ),
                amount: math.max(0.0, bar.limitAmount - bar.spent),
                scaleTotal: scaleTotal,
                bar: bar,
                opacity: .28,
              ),
            ],
            _partitionFreeSegment(amount: free, scaleTotal: scaleTotal),
          ],
        ),
      ),
    );
  }

  Widget _partitionSegment({
    required Key key,
    required double amount,
    required double scaleTotal,
    required CategoryBudgetBarData bar,
    required double opacity,
  }) {
    if (amount <= 0) return SizedBox.shrink(key: key);
    return Flexible(
      key: key,
      flex: math.max(1, (amount / scaleTotal * 10000).round()),
      child: Opacity(
        opacity: opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: CategoryColorManager.gradient(bar.category?.colorSlot),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _partitionFreeSegment({
    required double amount,
    required double scaleTotal,
  }) {
    const key = ValueKey('spendee-test-partition-segment-free');
    if (amount <= 0) return const SizedBox.shrink(key: key);
    return Flexible(
      key: key,
      flex: math.max(1, (amount / scaleTotal * 10000).round()),
      child: ColoredBox(
        color: Colors.white.withValues(alpha: .42),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BudgetPieStage2Layer extends StatelessWidget {
  const _BudgetPieStage2Layer({
    required this.bars,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final List<CategoryBudgetBarData> bars;
  final TransactionCategory? selectedCategory;
  final ValueChanged<TransactionCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: const ValueKey('spendee-test-budget-pie-stage2-layer'),
          padding: const EdgeInsets.fromLTRB(1, 0, 1, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: _BudgetPiePanel(
              bars: bars,
              selectedCategory: selectedCategory,
              onCategoryTap: onCategoryTap,
            ),
          ),
        );
      },
    );
  }
}

class _BudgetPiePanel extends StatelessWidget {
  const _BudgetPiePanel({
    required this.bars,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final List<CategoryBudgetBarData> bars;
  final TransactionCategory? selectedCategory;
  final ValueChanged<TransactionCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final budgetSpec = _budgetHeaderVisualSpec.budget;
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
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(17)),
          gradient: RadialGradient(
            center: Alignment(-.72, -.92),
            radius: .82,
            colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
            stops: [0, .62],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                height: budgetSpec.donutVisualSize,
                child: Row(
                  children: [
                    SizedBox(
                      width: budgetSpec.donutVisualSize,
                      height: budgetSpec.donutVisualSize,
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
              Column(
                children: [
                  for (var index = 0; index < visibleBars.length; index++) ...[
                    if (index > 0) const SizedBox(height: 7),
                    _BudgetPieRow(
                      bar: visibleBars[index],
                      total: total,
                      selected: visibleBars[index].targetId == selectedId,
                      onCategoryTap: onCategoryTap,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetPieRow extends StatelessWidget {
  const _BudgetPieRow({
    required this.bar,
    required this.total,
    required this.selected,
    required this.onCategoryTap,
  });

  final CategoryBudgetBarData bar;
  final double total;
  final bool selected;
  final ValueChanged<TransactionCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0 : (bar.spent / total * 100).round();
    return GestureDetector(
      key: ValueKey('spendee-test-budget-pie-row-${bar.targetId}'),
      behavior: HitTestBehavior.opaque,
      onTap: bar.category == null ? null : () => onCategoryTap(bar.category!),
      child: Container(
        constraints: const BoxConstraints(minHeight: 25),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          color: selected ? null : Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: bar.color.withValues(alpha: .24),
                offset: const Offset(0, 8),
                blurRadius: 18,
              ),
            BoxShadow(
              color: Colors.white.withValues(alpha: selected ? .42 : .24),
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
            Text('$percent% · ${_formatFt(bar.spent)}', style: _pieValueStyle),
          ],
        ),
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
          key: const ValueKey('spendee-test-budget-pie-focus-title'),
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
    final budgetSpec = _budgetHeaderVisualSpec.budget;
    final center = Offset(size.width / 2, size.height / 2);
    final scale =
        math.min(size.width, size.height) / budgetSpec.donutCoordinateSize;
    final radius = budgetSpec.donutRadius * scale;
    final baseStrokeWidth = budgetSpec.donutBaseStrokeWidth * scale;
    final selectedStrokeWidth = budgetSpec.donutSelectedStrokeWidth * scale;
    final centerRadius = budgetSpec.donutCenterRadius * scale;
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
      ..strokeWidth = baseStrokeWidth
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
          ..strokeWidth = selectedStrokeWidth
          ..strokeCap = StrokeCap.butt
          ..color = bar.color.withValues(
            alpha: budgetSpec.donutSelectedGlowOpacity,
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            budgetSpec.donutSelectedGlowBlur * scale,
          );
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
        ..strokeWidth = selected ? selectedStrokeWidth : baseStrokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = selected ? bar.color : bar.color.withValues(alpha: .74);
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
      centerRadius,
      Paint()..color = Colors.white.withValues(alpha: .40),
    );
    canvas.drawCircle(
      center,
      centerRadius,
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
    super.key,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const fixedDashboardControlsHeight = 66.0 + 59.0 + 12.0 + 45.0;
        const transactionHeaderHeight = 24.0;
        final canShowTransactionLog =
            stage != SpendeeHeaderStage.stage2 &&
            constraints.maxHeight >=
                fixedDashboardControlsHeight + transactionHeaderHeight;
        return Column(
          children: [
            SizedBox(
              key: const ValueKey('spendee-test-type-row'),
              height: 66,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _SpendeeTypePill(
                        key: const ValueKey('spendee-test-income-type-pill'),
                        label: 'Bevétel',
                        active: store.activeType == TransactionType.income,
                        activeGradient: const LinearGradient(
                          colors: [Colors.white, Colors.white],
                        ),
                        boxShadows: const <BoxShadow>[
                          BoxShadow(
                            color: Color.fromRGBO(15, 23, 42, .08),
                            offset: Offset(0, 10),
                            blurRadius: 23,
                          ),
                        ],
                        textColor: store.activeType == TransactionType.income
                            ? const Color(0xFF14213A)
                            : AppColors.gray500,
                        onTap: () =>
                            store.setActiveType(TransactionType.income),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SpendeeTypePill(
                        key: const ValueKey('spendee-test-expense-type-pill'),
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
                        boxShadows: const <BoxShadow>[
                          BoxShadow(
                            color: Color.fromRGBO(245, 54, 141, .22),
                            offset: Offset(0, 12),
                            blurRadius: 24,
                          ),
                        ],
                        textColor: store.activeType == TransactionType.expense
                            ? Colors.white
                            : AppColors.gray500,
                        onTap: () =>
                            store.setActiveType(TransactionType.expense),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onPickSummaryMonth,
              onDoubleTap: store.resetSummaryToCurrentMonth,
              onVerticalDragEnd: (_) => store.cycleSummaryWindow(),
              onHorizontalDragEnd: (details) {
                final dx = details.velocity.pixelsPerSecond.dx;
                if (dx == 0) return;
                store.shiftSummaryPeriod(dx < 0 ? 1 : -1);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  key: const ValueKey('spendee-test-summary-pill'),
                  height: 59,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: _softWhiteDecoration(20),
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
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                key: const ValueKey('spendee-test-search-pill'),
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: _softWhiteDecoration(20),
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
            ),
            if (canShowTransactionLog) ...[
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
      },
    );
  }
}

class _SpendeeTypePill extends StatelessWidget {
  const _SpendeeTypePill({
    super.key,
    required this.label,
    required this.active,
    required this.activeGradient,
    required this.boxShadows,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Gradient activeGradient;
  final List<BoxShadow> boxShadows;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: active ? activeGradient : null,
          color: active ? null : Colors.white,
          boxShadow: boxShadows,
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
        decoration: _softWhiteDecoration(18),
        child: Row(
          children: [
            GestureDetector(
              onTap: category == null
                  ? null
                  : () => onCategoryFilter(category!),
              child: GlossyCategoryAvatar(
                category: category,
                size: 46,
                iconSize: 28,
                showQuestionMark: category == null,
                debugSource: 'spendee-test-logbox',
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

class _AppCornerFullscreenButton extends StatelessWidget {
  const _AppCornerFullscreenButton({
    required this.fullscreen,
    required this.requestPending,
    required this.onPressed,
  });

  final bool fullscreen;
  final bool requestPending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: IconButton(
        key: const ValueKey('spendee-test-app-fullscreen-button'),
        tooltip: fullscreen
            ? 'Kilépés a teljes képernyőből'
            : 'Teljes képernyő',
        padding: EdgeInsets.zero,
        onPressed: requestPending ? null : onPressed,
        icon: Icon(
          fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          color: const Color(0xFF14213A),
          size: 20,
        ),
      ),
    );
  }
}

class _SpendeeBrandLockup extends StatelessWidget {
  const _SpendeeBrandLockup({
    super.key,
    required this.logoFills,
    required this.onLogoTap,
  });

  static const _logoSize = 47.88;

  final Map<FluviLogoArc, FluviLogoFill> logoFills;
  final VoidCallback onLogoTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 30,
          top: 6,
          width: _logoSize,
          height: _logoSize,
          child: GestureDetector(
            key: const ValueKey('spendee-test-brand-logo-tap'),
            behavior: HitTestBehavior.opaque,
            onTap: onLogoTap,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: const Offset(0, 3),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0x1A0F172A),
                        BlendMode.srcIn,
                      ),
                      child: FluviLogo(fills: logoFills),
                    ),
                  ),
                ),
                FluviLogo(
                  key: const ValueKey('spendee-test-brand-logo'),
                  fills: logoFills,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 82.25,
          top: 10.602,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'fluvi',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFF14213A),
                  fontSize: 30.096,
                  height: .96,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 1.368),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'your personal '),
                    TextSpan(
                      text: 'financial trainer',
                      style: TextStyle(color: Color(0xFF06AECA)),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: const TextStyle(
                  color: Color(0xFF536078),
                  fontSize: 13.84416,
                  height: 1.02,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoEditorSheet extends StatefulWidget {
  const _LogoEditorSheet({required this.fills, required this.onFillChanged});

  final Map<FluviLogoArc, FluviLogoFill> fills;
  final void Function(FluviLogoArc arc, FluviLogoFill fill) onFillChanged;

  @override
  State<_LogoEditorSheet> createState() => _LogoEditorSheetState();
}

class _LogoEditorSheetState extends State<_LogoEditorSheet> {
  late _LogoPaletteChoice _selectedFill = _categoryLogoChoice(7);
  late final List<_CustomLogoGradientSlot> _customSlots =
      _CustomLogoGradientSlot.defaults();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('spendee-test-logo-editor-sheet'),
        margin: const EdgeInsets.only(top: 72),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              offset: const Offset(0, -10),
              blurRadius: 30,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF536078).withValues(alpha: .32),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                key: const ValueKey('spendee-test-logo-editor-preview'),
                height: 178,
                child: Center(
                  child: _LogoComponentPreview(
                    fills: widget.fills,
                    onComponentTap: _applySelectedFill,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in _htmlSelectedLogoPalette)
                    _LogoSwatchButton(
                      key: ValueKey(
                        'spendee-test-logo-palette-selected-${choice.id}',
                      ),
                      fill: choice.fill,
                      selected: _selectedFill.id == choice.id,
                      onTap: () => setState(() => _selectedFill = choice),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in _htmlAppLogoPalette)
                    _LogoSwatchButton(
                      key: ValueKey(
                        'spendee-test-logo-palette-app-${choice.id}',
                      ),
                      fill: choice.fill,
                      selected: _selectedFill.id == choice.id,
                      onTap: () => setState(() => _selectedFill = choice),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in CategoryColorManager.slots)
                    _LogoSwatchButton(
                      key: ValueKey('spendee-test-logo-palette-slot-$slot'),
                      fill: _categoryLogoChoice(slot).fill,
                      selected: _selectedFill.id == 'slot-$slot',
                      onTap: () {
                        setState(() {
                          _selectedFill = _categoryLogoChoice(slot);
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (final slot in _customSlots) ...[
                _CustomLogoGradientSlotEditor(
                  key: ValueKey('spendee-test-logo-custom-slot-${slot.id}'),
                  slot: slot,
                  selectedFill: () => _selectedFill,
                  selected: _selectedFill.id == 'custom-${slot.id}',
                  onSelect: () {
                    setState(() => _selectedFill = slot.toChoice());
                  },
                  onChanged: () {
                    setState(() {
                      if (_selectedFill.id == 'custom-${slot.id}') {
                        _selectedFill = slot.toChoice();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _applySelectedFill(FluviLogoArc arc) {
    widget.onFillChanged(arc, _selectedFill.fill);
    setState(() {});
  }
}

class _LogoComponentPreview extends StatelessWidget {
  const _LogoComponentPreview({
    required this.fills,
    required this.onComponentTap,
  });

  final Map<FluviLogoArc, FluviLogoFill> fills;
  final ValueChanged<FluviLogoArc> onComponentTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              FluviLogo(
                key: const ValueKey('spendee-test-fluvi-logo-preview'),
                fills: fills,
              ),
              Positioned(
                left: width * .22,
                right: width * .12,
                top: height * .12,
                height: height * .34,
                child: _LogoComponentButton(
                  arc: FluviLogoArc.top,
                  onTap: onComponentTap,
                ),
              ),
              Positioned(
                left: width * .22,
                right: width * .28,
                top: height * .46,
                height: height * .40,
                child: _LogoComponentButton(
                  arc: FluviLogoArc.bottom,
                  onTap: onComponentTap,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogoComponentButton extends StatelessWidget {
  const _LogoComponentButton({required this.arc, required this.onTap});

  final FluviLogoArc arc;
  final ValueChanged<FluviLogoArc> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('spendee-test-logo-component-${arc.name}'),
      behavior: HitTestBehavior.translucent,
      onTap: () => onTap(arc),
      child: const ColoredBox(color: Colors.transparent),
    );
  }
}

class _LogoSwatchButton extends StatelessWidget {
  const _LogoSwatchButton({
    super.key,
    required this.fill,
    required this.selected,
    required this.onTap,
  });

  final FluviLogoFill fill;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: fill.gradient,
          border: Border.all(
            color: selected ? const Color(0xFF14213A) : Colors.white,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              offset: const Offset(0, 5),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomLogoGradientSlotEditor extends StatelessWidget {
  const _CustomLogoGradientSlotEditor({
    super.key,
    required this.slot,
    required this.selectedFill,
    required this.selected,
    required this.onSelect,
    required this.onChanged,
  });

  final _CustomLogoGradientSlot slot;
  final ValueGetter<_LogoPaletteChoice> selectedFill;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogoSwatchButton(
          key: ValueKey('spendee-test-logo-custom-swatch-${slot.id}'),
          fill: slot.toFill(),
          selected: selected,
          onTap: onSelect,
        ),
        const SizedBox(width: 10),
        _EndpointButton(
          key: ValueKey('spendee-test-logo-custom-left-${slot.id}'),
          label: 'L',
          fill: FluviLogoFill.solid(slot.left),
          onTap: () {
            slot.left = selectedFill().fill.left;
            onChanged();
          },
        ),
        const SizedBox(width: 8),
        _EndpointButton(
          key: ValueKey('spendee-test-logo-custom-right-${slot.id}'),
          label: 'R',
          fill: FluviLogoFill.solid(slot.right),
          onTap: () {
            slot.right = selectedFill().fill.right;
            onChanged();
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Slider(
            key: ValueKey('spendee-test-logo-custom-boundary-${slot.id}'),
            value: slot.boundary,
            min: 0,
            max: 100,
            onChanged: (value) {
              slot.boundary = value;
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}

class _EndpointButton extends StatelessWidget {
  const _EndpointButton({
    super.key,
    required this.label,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final FluviLogoFill fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: fill.gradient,
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF14213A),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LogoPaletteChoice {
  const _LogoPaletteChoice({required this.id, required this.fill});

  _LogoPaletteChoice.solid(String id, Color color)
    : this(id: id, fill: FluviLogoFill.solid(color));

  final String id;
  final FluviLogoFill fill;
}

class _CustomLogoGradientSlot {
  _CustomLogoGradientSlot({
    required this.id,
    required this.left,
    required this.right,
    required this.boundary,
  });

  final int id;
  Color left;
  Color right;
  double boundary;

  FluviLogoFill toFill() {
    return FluviLogoFill(left: left, right: right, boundary: boundary);
  }

  _LogoPaletteChoice toChoice() {
    return _LogoPaletteChoice(id: 'custom-$id', fill: toFill());
  }

  static List<_CustomLogoGradientSlot> defaults() {
    return <_CustomLogoGradientSlot>[
      _CustomLogoGradientSlot(
        id: 1,
        left: Colors.white,
        right: const Color(0xFF0F172A),
        boundary: 50,
      ),
      _CustomLogoGradientSlot(
        id: 2,
        left: const Color(0xFFF8FAFC),
        right: const Color(0xFF06B6D4),
        boundary: 50,
      ),
      _CustomLogoGradientSlot(
        id: 3,
        left: const Color(0xFF22C55E),
        right: const Color(0xFF8B5CF6),
        boundary: 50,
      ),
      _CustomLogoGradientSlot(
        id: 4,
        left: const Color(0xFFFBF8CC),
        right: const Color(0xFFB9FBC0),
        boundary: 50,
      ),
      _CustomLogoGradientSlot(
        id: 5,
        left: const Color(0xFFD9ED92),
        right: const Color(0xFF184E77),
        boundary: 50,
      ),
    ];
  }
}

_LogoPaletteChoice _categoryLogoChoice(int slot) {
  final colors = CategoryColorManager.gradientStops(slot);
  return _LogoPaletteChoice(
    id: 'slot-$slot',
    fill: FluviLogoFill(
      left: colors.first,
      middle: colors.length > 2 ? colors[1] : null,
      right: colors.last,
      boundary: 52,
    ),
  );
}

final _htmlSelectedLogoPalette = <_LogoPaletteChoice>[
  _LogoPaletteChoice.solid('D1', Color(0xFFFFFFFF)),
  _LogoPaletteChoice.solid('N5', Color(0xFFFCFCFD)),
  _LogoPaletteChoice.solid('O5', Color(0xFFFAFAFA)),
  _LogoPaletteChoice.solid('E1', Color(0xFFF8FAFC)),
  _LogoPaletteChoice.solid('P5', Color(0xFFF7F8FB)),
  _LogoPaletteChoice.solid('A6', Color(0xFFF4F6F8)),
  _LogoPaletteChoice.solid('F1', Color(0xFFF1F5F9)),
  _LogoPaletteChoice.solid('B6', Color(0xFFEEF2F6)),
  _LogoPaletteChoice.solid('N3', Color(0xFFF4F0E8)),
];

final _htmlAppLogoPalette = <_LogoPaletteChoice>[
  _LogoPaletteChoice.solid('white', Color(0xFFFFFFFF)),
  _LogoPaletteChoice.solid('gray50', Color(0xFFF8FAFC)),
  _LogoPaletteChoice.solid('gray100', Color(0xFFF1F5F9)),
  _LogoPaletteChoice.solid('gray200', Color(0xFFE2E8F0)),
  _LogoPaletteChoice.solid('gray300', Color(0xFFCBD5E1)),
  _LogoPaletteChoice.solid('gray400', Color(0xFF94A3B8)),
  _LogoPaletteChoice.solid('gray500', Color(0xFF64748B)),
  _LogoPaletteChoice.solid('gray600', Color(0xFF475569)),
  _LogoPaletteChoice.solid('gray700', Color(0xFF334155)),
  _LogoPaletteChoice.solid('gray800', Color(0xFF1E293B)),
  _LogoPaletteChoice.solid('gray900', Color(0xFF0F172A)),
  _LogoPaletteChoice.solid('primary', Color(0xFF06B6D4)),
  _LogoPaletteChoice.solid('primaryDark', Color(0xFF0891B2)),
  _LogoPaletteChoice.solid('primaryLight', Color(0xFF67E8F9)),
  _LogoPaletteChoice.solid('income', Color(0xFF22C55E)),
  _LogoPaletteChoice.solid('expense', Color(0xFFEF4444)),
];

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

class _HeaderValueText extends StatelessWidget {
  const _HeaderValueText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _headerValueStyle.copyWith(
            shadows: const <Shadow>[],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .45
              ..color = const Color(0x33FFFFFF),
          ),
        ),
        Text(
          value,
          key: const ValueKey('spendee-test-header-value'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _headerValueStyle,
        ),
      ],
    );
  }
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
