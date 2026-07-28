import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/summary_window.dart';
import '../../../models/category_budget_bar_data.dart';
import '../../../models/transaction_category.dart';
import '../../../slots/category_icon_manager.dart';
import '../../../state/balance_amount_formatter.dart';
import '../../../state/balance_frame.dart';
import 'spendee_balance_cards.dart';
import 'spendee_balance_collapse_controller.dart';
import 'spendee_balance_debug_trace.dart';
import 'spendee_balance_header.dart';
import 'spendee_balance_post_content.dart';
import 'spendee_balance_rail_publication_coordinator.dart';
import 'spendee_balance_visual_spec.dart';
import 'spendee_budget_v2_components.dart';

typedef SpendeeBalanceTransactionLogBuilder =
    Widget Function(BuildContext context, BalanceRenderFrame frame);

/// BudgetV2 is not a separate screen implementation.  It is the Balance
/// collapse, rail, search and log shell with only the B3M-B island region
/// replaced.  Keeping that ownership here prevents the old nested scroll
/// surface and the resulting clipped glows from returning.
enum SpendeeBalancePresentation { balance, balanceV2, budgetV2 }

/// Production composition of the frozen B3M-A3 Balance screen.
///
/// All visible values are resolved from one immutable [BalanceFrameInput].
/// The caller only owns mutations; no preview/sample values are generated here.
class SpendeeBalanceDashboard extends StatefulWidget {
  const SpendeeBalanceDashboard({
    super.key,
    required this.input,
    required this.brand,
    required this.transactionLogBuilder,
    this.presentation = SpendeeBalancePresentation.balance,
    this.budgetV2Bars = const <CategoryBudgetBarData>[],
    this.onBudgetV2LimitChanged,
    this.transactionLogRevision,
    this.menuButton,
    this.headerSurfaceBuilder,
    this.onTypeChanged,
    this.onSummaryTap,
    this.onSummaryReset,
    this.onShiftPeriod,
    this.onCycleSummary,
    this.onQueryChanged,
    this.onRemoveFilter,
    this.onFilterPressed,
    this.onScopeSelected,
    this.onScopeFallback,
    this.onOpenDebugPanel,
  });

  final BalanceFrameInput input;
  final SpendeeBalancePresentation presentation;
  final List<CategoryBudgetBarData> budgetV2Bars;
  final void Function(CategoryBudgetBarData bar, double amount)?
  onBudgetV2LimitChanged;
  final Widget brand;
  final Widget? menuButton;
  final SpendeeBalanceHeaderSurfaceBuilder? headerSurfaceBuilder;
  final SpendeeBalanceTransactionLogBuilder transactionLogBuilder;

  /// Identity/equality token for dependencies captured by
  /// [transactionLogBuilder] but not represented by [input].
  ///
  /// When omitted, the builder identity is used so a new closure can never
  /// leave stale callbacks or layout properties in the cached log widget.
  final Object? transactionLogRevision;
  final ValueChanged<TransactionType>? onTypeChanged;
  final VoidCallback? onSummaryTap;
  final VoidCallback? onSummaryReset;
  final ValueChanged<int>? onShiftPeriod;
  final VoidCallback? onCycleSummary;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<SpendeeBalanceSearchChip>? onRemoveFilter;
  final VoidCallback? onFilterPressed;
  final ValueChanged<BalanceTimeScopeOption>? onScopeSelected;
  final ValueChanged<BalanceQueryFrame>? onScopeFallback;
  final VoidCallback? onOpenDebugPanel;

  @override
  State<SpendeeBalanceDashboard> createState() =>
      _SpendeeBalanceDashboardState();
}

class _SpendeeBalanceDashboardState extends State<SpendeeBalanceDashboard>
    with SingleTickerProviderStateMixin {
  static const _collapseSettleDuration = Duration(milliseconds: 260);
  // Annual rail navigation spans more than the prior eight query states once
  // both income/expense and a bounded log window are involved. Retaining the
  // recent query frames prevents a return tap from recomputing all FastInfo
  // aggregates on the UI isolate.
  static const _frameHistoryCapacity = 32;
  // A type toggle has two stable, mutually exclusive log views. Keeping the
  // most recent pair mounted offstage avoids rebuilding a 96-row sliver tree
  // when the user returns to the prior type.
  static const _transactionLogCacheCapacity = 2;

  late final SpendeeBalanceCollapseController _collapseController;
  late final AnimationController _collapseSettleController;
  Animation<double>? _collapseAnimation;
  final Set<BalanceGhostSection> _includedGhostSections = BalanceGhostSection
      .values
      .toSet();
  var _budgetDimension = SpendeeBalanceBudgetDimension.day;
  var _merchantDimension = SpendeeBalanceMerchantDimension.month;
  var _categoryRankDimension = SpendeeBalanceRankDimension.month;
  var _vendorRankDimension = SpendeeBalanceRankDimension.month;
  var _averageDimension = SpendeeBalanceAverageDimension.day;
  var _noSpendDimension = SpendeeBalanceNoSpendDimension.week;
  var _timeRailExpanded = false;
  BalanceFrameInput? _cachedInput;
  BalanceRenderFrame? _cachedFrame;
  final List<_BalanceFrameHistoryEntry> _frameHistory =
      <_BalanceFrameHistoryEntry>[];
  final List<_BalanceTransactionLogCacheEntry> _transactionLogCaches =
      <_BalanceTransactionLogCacheEntry>[];
  Object? _transactionLogCacheRevision;
  String? _scheduledFallbackKey;
  var _lastFrameCacheOutcome = 'cold';
  var _lastTransactionLogCacheOutcome = 'cold';
  BalanceDebugTraceToken? _pendingScopeTrace;
  String? _pendingScopeTraceKey;
  var _scopeTraceFinishScheduled = false;
  final _railPublication = BalanceRailPublicationCoordinator();
  String? _budgetV2SelectedBarKey;

  bool get _isBudgetV2 =>
      widget.presentation == SpendeeBalancePresentation.budgetV2;

  bool get _isBalanceV2 =>
      widget.presentation == SpendeeBalancePresentation.balanceV2;

  /// Every active category is a ticker item. The belt renders five at once
  /// (two neighbours either side of the selected disc), but it must never
  /// truncate its data source: otherwise the sixth and later app categories
  /// can neither be selected nor contribute to the selected-card flow.
  List<CategoryBudgetBarData> get _budgetV2AllBars =>
      List<CategoryBudgetBarData>.unmodifiable(widget.budgetV2Bars);

  List<CategoryBudgetBarData> get _budgetV2Bars => _budgetV2AllBars;

  int get _budgetV2SelectedIndex {
    final bars = _budgetV2Bars;
    if (bars.isEmpty) return 0;
    final selectedKey = _budgetV2SelectedBarKey;
    final index = selectedKey == null
        ? 0
        : bars.indexWhere((bar) => bar.key == selectedKey);
    return index < 0 ? 0 : index;
  }

  void _selectBudgetV2Bar(int index) {
    final bars = _budgetV2Bars;
    if (index < 0 || index >= bars.length) return;
    if (_budgetV2SelectedBarKey == bars[index].key) return;
    setState(() => _budgetV2SelectedBarKey = bars[index].key);
  }

  @override
  void initState() {
    super.initState();
    _collapseController = SpendeeBalanceCollapseController()
      ..addListener(_handleCollapseChanged);
    _collapseSettleController = AnimationController(
      vsync: this,
      duration: _collapseSettleDuration,
    )..addListener(_handleCollapseAnimation);
  }

  @override
  void dispose() {
    final pendingScopeTrace = _pendingScopeTrace;
    if (pendingScopeTrace != null) {
      BalanceDebugTrace.finish(
        pendingScopeTrace,
        fields: const <String, Object?>{'reason': 'dispose'},
      );
    }
    _collapseSettleController
      ..removeListener(_handleCollapseAnimation)
      ..dispose();
    _collapseController
      ..removeListener(_handleCollapseChanged)
      ..dispose();
    super.dispose();
  }

  void _handleCollapseChanged() {
    if (mounted) setState(() {});
  }

  void _handleCollapseAnimation() {
    final animation = _collapseAnimation;
    if (animation != null) _collapseController.jumpTo(animation.value);
  }

  void _beginCollapseDrag() {
    _collapseSettleController.stop();
    _collapseAnimation = null;
    _collapseController.beginDrag();
  }

  void _updateCollapseDrag(double dy) {
    _collapseController.dragBy(dy);
  }

  void _endCollapseDrag() {
    final start = _collapseController.offset;
    final target = _collapseController.release();
    if (_reducedMotion) return;
    _collapseController.jumpTo(start);
    _animateCollapseTo(target);
  }

  void _cancelCollapseDrag() {
    final start = _collapseController.offset;
    final target = start >= SpendeeBalanceCollapseController.snapOffset
        ? SpendeeBalanceCollapseTarget.collapsed
        : SpendeeBalanceCollapseTarget.expanded;
    _collapseController.cancelDrag();
    if (_reducedMotion) return;
    _collapseController.jumpTo(start);
    _animateCollapseTo(target);
  }

  void _toggleCollapse() {
    _animateCollapseTo(_collapseController.toggleTarget);
  }

  void _animateCollapseTo(SpendeeBalanceCollapseTarget target) {
    final destination = target == SpendeeBalanceCollapseTarget.collapsed
        ? SpendeeBalanceCollapseController.maxOffset
        : 0.0;
    if (_reducedMotion) {
      _collapseSettleController.stop();
      _collapseAnimation = null;
      _collapseController.jumpTo(destination);
      return;
    }
    _collapseSettleController.stop();
    _collapseAnimation =
        Tween<double>(
          begin: _collapseController.offset,
          end: destination,
        ).animate(
          CurvedAnimation(
            parent: _collapseSettleController,
            curve: Curves.easeOutCubic,
          ),
        );
    unawaited(
      _collapseSettleController.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _collapseAnimation = null;
        _collapseController.jumpTo(destination);
      }),
    );
  }

  bool get _reducedMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  Widget build(BuildContext context) {
    final frame = _resolveFrame();
    if (frame.query.selectedScope case final selected?) {
      _railPublication.reconcileCommitted(selected.key);
    }
    _scheduleScopeFallback(frame.query);
    final visuals = SpendeeBalanceCollapseVisuals.forProgress(
      _collapseController.progress,
    );
    return FocusTraversalGroup(
      key: const ValueKey('spendee-balance-focus-traversal'),
      policy: ReadingOrderTraversalPolicy(),
      child: ColoredBox(
        color: SpendeeBalanceVisualSpec.pageBackground,
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const ValueKey('spendee-balance-dashboard'),
            width: SpendeeBalanceVisualSpec.canvas.width,
            height: SpendeeBalanceVisualSpec.canvas.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 33.3,
                  right: 0,
                  left: 0,
                  height: 70,
                  child: widget.brand,
                ),
                _buildCollapsibleContent(frame, visuals),
                _buildPostContent(frame, visuals),
                if (widget.menuButton case final menu?)
                  Positioned(
                    top: SpendeeBalanceVisualSpec.menuTop,
                    right: SpendeeBalanceVisualSpec.menuRight,
                    child: menu,
                  ),
                if (widget.onOpenDebugPanel case final onOpenDebugPanel?)
                  Positioned(
                    top: 43,
                    left: 8,
                    child: IconButton(
                      key: const ValueKey('spendee-balance-debug-panel-button'),
                      tooltip: 'Debug log',
                      icon: const Icon(Icons.terminal, size: 18),
                      onPressed: onOpenDebugPanel,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BalanceRenderFrame _resolveFrame() {
    final cached = _cachedFrame;
    final cachedInput = _cachedInput;
    if (cached != null &&
        cachedInput != null &&
        (identical(cachedInput, widget.input) ||
            cachedInput.sameRevisionAs(widget.input))) {
      _cachedInput = widget.input;
      _lastFrameCacheOutcome = 'same';
      _settleScopeTraceIfReady(cached);
      return cached;
    }
    for (final entry in _frameHistory) {
      if (!entry.matches(widget.input, _includedGhostSections)) continue;
      _cachedInput = widget.input;
      _cachedFrame = entry.frame;
      _lastFrameCacheOutcome = 'history';
      _settleScopeTraceIfReady(entry.frame);
      return entry.frame;
    }
    _lastFrameCacheOutcome = 'miss';
    final BalanceDebugTraceToken? trace;
    if (BalanceDebugTrace.enabled) {
      trace = BalanceDebugTrace.begin(
        'balance-frame-resolve',
        fields: <String, Object?>{
          'type': widget.input.activeType.name,
          'window': widget.input.summaryWindow.name,
          'visible_rows': widget.input.visibleLogEntryLimit ?? 0,
        },
      );
    } else {
      trace = null;
    }
    late final BalanceRenderFrame frame;
    try {
      frame = BalanceFrameResolver.resolve(
        widget.input,
        ghostPolicy: BalanceGhostPolicy.only(_includedGhostSections),
      );
    } catch (error) {
      BalanceDebugTrace.finish(trace, error: error);
      rethrow;
    }
    if (trace != null) {
      BalanceDebugTrace.finish(
        trace,
        fields: <String, Object?>{
          'cache': _lastFrameCacheOutcome,
          'scope_options': frame.query.scopeOptions.length,
          'visible_rows': frame.visibleLogRowCount,
        },
      );
    }
    _cachedInput = widget.input;
    _cachedFrame = frame;
    _rememberFrame(widget.input, frame);
    _settleScopeTraceIfReady(frame);
    return frame;
  }

  void _rememberFrame(BalanceFrameInput input, BalanceRenderFrame frame) {
    _frameHistory.removeWhere(
      (entry) => entry.matches(input, _includedGhostSections),
    );
    _frameHistory.insert(
      0,
      _BalanceFrameHistoryEntry(
        input: input,
        includedGhostSections: _includedGhostSections,
        frame: frame,
      ),
    );
    if (_frameHistory.length > _frameHistoryCapacity) {
      _frameHistory.removeLast();
    }
  }

  void _scheduleScopeFallback(BalanceQueryFrame query) {
    if (_railPublication.isDragging ||
        !query.hasPendingScopeFallback ||
        widget.onScopeFallback == null) {
      _scheduledFallbackKey = null;
      return;
    }
    final key =
        '${query.summaryWindow.name}:'
        '${query.requestedReferenceDate.toIso8601String()}:'
        '${query.effectiveReferenceDate.toIso8601String()}';
    if (_scheduledFallbackKey == key) return;
    _scheduledFallbackKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledFallbackKey != key) return;
      widget.onScopeFallback?.call(query);
    });
  }

  Widget _buildCollapsibleContent(
    BalanceRenderFrame frame,
    SpendeeBalanceCollapseVisuals visuals,
  ) {
    final isBudgetV2 = _isBudgetV2;
    final isBalanceV2 = _isBalanceV2;
    final insightTop = isBudgetV2 ? 241.0 : SpendeeBalanceVisualSpec.insightTop;
    final insightHeight = isBudgetV2
        ? 80.0
        : SpendeeBalanceVisualSpec.insightHeight;
    final detailTop = isBudgetV2
        ? 332.0
        : isBalanceV2
        ? SpendeeBalanceVisualSpec.balanceV2DetailTop
        : SpendeeBalanceVisualSpec.detailTop;
    final detailHeight = isBudgetV2
        ? 210.0
        : isBalanceV2
        ? SpendeeBalanceVisualSpec.balanceV2DetailStageHeight
        : SpendeeBalanceVisualSpec.detailStageHeight;
    return Positioned(
      key: const ValueKey('spendee-balance-collapse-content-region'),
      top: SpendeeBalanceVisualSpec.heroTop,
      right: SpendeeBalanceVisualSpec.canvasContentInset,
      left: SpendeeBalanceVisualSpec.canvasContentInset,
      height: detailTop - SpendeeBalanceVisualSpec.heroTop + detailHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) => _beginCollapseDrag(),
        onVerticalDragUpdate: (details) =>
            _updateCollapseDrag(details.delta.dy),
        onVerticalDragEnd: (_) => _endCollapseDrag(),
        onVerticalDragCancel: _cancelCollapseDrag,
        child: Stack(
          key: const ValueKey('spendee-balance-collapse-layer-stack'),
          clipBehavior: Clip.none,
          children: [
            if (!isBalanceV2)
              Positioned(
                key: const ValueKey('spendee-balance-fast-info-layer'),
                top: insightTop - SpendeeBalanceVisualSpec.heroTop,
                right: 0,
                left: 0,
                height: insightHeight,
                child: IgnorePointer(
                  ignoring: !visuals.insightsInteractive,
                  child: ExcludeFocus(
                    excluding: !visuals.insightsInteractive,
                    child: ExcludeSemantics(
                      excluding: !visuals.insightsInteractive,
                      child: Transform.translate(
                        offset: Offset(0, visuals.scrollContentTranslateY),
                        child: Transform.translate(
                          offset: Offset(0, visuals.insightTranslateY),
                          child: Transform.scale(
                            alignment: Alignment.topCenter,
                            scale: visuals.insightScale,
                            child: Opacity(
                              key: const ValueKey(
                                'spendee-balance-insight-opacity',
                              ),
                              opacity: visuals.insightOpacity,
                              child: isBudgetV2
                                  ? SpendeeBudgetV2AvatarBelt(
                                      bars: _budgetV2Bars,
                                      selectedIndex: _budgetV2SelectedIndex,
                                      onSelected: _selectBudgetV2Bar,
                                    )
                                  : SpendeeBalanceFastInfoBelt(
                                      cards: _fastInfoModels(frame),
                                      onGhostChanged: _setGhostSection,
                                      onNoSpendCycle: _cycleNoSpendDimension,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              key: const ValueKey('spendee-balance-detail-layer'),
              top: detailTop - SpendeeBalanceVisualSpec.heroTop,
              right: 0,
              left: 0,
              height: detailHeight,
              child: IgnorePointer(
                ignoring: !visuals.detailsInteractive,
                child: ExcludeFocus(
                  excluding: !visuals.detailsInteractive,
                  child: ExcludeSemantics(
                    excluding: !visuals.detailsInteractive,
                    child: Transform.translate(
                      offset: Offset(0, visuals.scrollContentTranslateY),
                      child: Transform.translate(
                        offset: Offset(0, visuals.detailTranslateY),
                        child: Transform.scale(
                          alignment: Alignment.topCenter,
                          scale: visuals.detailScale,
                          child: Opacity(
                            key: const ValueKey(
                              'spendee-balance-detail-opacity',
                            ),
                            opacity: visuals.detailOpacity,
                            child: isBudgetV2
                                ? _buildBudgetV2MotherCard()
                                : isBalanceV2
                                ? SpendeeBalanceV2DetailCarousel(
                                    fastInfoPages: _fastInfoModels(frame),
                                    detailPages: _detailModels(
                                      frame,
                                      expanded: true,
                                    ),
                                    onGhostChanged: _setGhostSection,
                                    onNoSpendCycle: _cycleNoSpendDimension,
                                    onBudgetDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'variable_budget',
                                        previous: _budgetDimension.name,
                                        next: value.name,
                                        apply: () => _budgetDimension = value,
                                      );
                                    },
                                    onMerchantDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'top_merchants',
                                        previous: _merchantDimension.name,
                                        next: value.name,
                                        apply: () =>
                                            _merchantDimension = value,
                                      );
                                    },
                                    onCategoryRankDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'top_categories',
                                        previous: _categoryRankDimension.name,
                                        next: value.name,
                                        apply: () =>
                                            _categoryRankDimension = value,
                                      );
                                    },
                                    onVendorRankDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'top_vendors',
                                        previous: _vendorRankDimension.name,
                                        next: value.name,
                                        apply: () =>
                                            _vendorRankDimension = value,
                                      );
                                    },
                                    onAverageDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'average_daily',
                                        previous: _averageDimension.name,
                                        next: value.name,
                                        apply: () =>
                                            _averageDimension = value,
                                      );
                                    },
                                  )
                                : SpendeeBalanceDetailCarousel(
                                    pages: _detailModels(frame),
                                    onGhostChanged: _setGhostSection,
                                    onBudgetDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'variable_budget',
                                        previous: _budgetDimension.name,
                                        next: value.name,
                                        apply: () => _budgetDimension = value,
                                      );
                                    },
                                    onMerchantDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'top_merchants',
                                        previous: _merchantDimension.name,
                                        next: value.name,
                                        apply: () => _merchantDimension = value,
                                      );
                                    },
                                    onCategoryRankDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'top_categories',
                                        previous: _categoryRankDimension.name,
                                        next: value.name,
                                        apply: () =>
                                            _categoryRankDimension = value,
                                      );
                                    },
                                    onVendorRankDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'top_vendors',
                                        previous: _vendorRankDimension.name,
                                        next: value.name,
                                        apply: () =>
                                            _vendorRankDimension = value,
                                      );
                                    },
                                    onAverageDimensionChanged: (value) {
                                      _changeFastInfoDimension(
                                        card: 'average_daily',
                                        previous: _averageDimension.name,
                                        next: value.name,
                                        apply: () => _averageDimension = value,
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              key: const ValueKey('spendee-balance-header-layer'),
              top: 0,
              right: 0,
              left: 0,
              child: isBudgetV2
                  ? SpendeeBudgetV2Header(
                      bars: _budgetV2AllBars,
                      collapseProgress: visuals.progress,
                    )
                  : SpendeeBalanceHeader(
                      balanceText: _signedBalance(frame.balance),
                      reservePercent: (frame.reserveRatio * 100).round(),
                      incomeRatio: (frame.incomeRatio * 100).round(),
                      expenseRatio: (frame.expenseRatio * 100).round(),
                      collapseProgress: visuals.progress,
                      surfaceBuilder: widget.headerSurfaceBuilder,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetV2MotherCard() {
    final bars = _budgetV2Bars;
    if (bars.isEmpty) {
      return const SizedBox(
        key: ValueKey('spendee-budget-v2-mother-card-empty'),
        width: 378,
        height: 210,
      );
    }
    final selected = bars[_budgetV2SelectedIndex];
    return SpendeeBudgetV2MotherCard(
      // The selected bar is input, not the identity of the card. Keeping this
      // key stable preserves the readable mother-card page while a ticking
      // avatar selects a different category.
      key: const ValueKey('spendee-budget-v2-mother-card-state'),
      bar: selected,
      allBars: _budgetV2AllBars,
      weeklyRhythmValues: BudgetV2WeeklyRhythmValues.resolve(
        bar: selected,
        records: widget.input.transactions,
        endDate: widget.input.summaryReferenceDate,
      ),
      onLimitChanged: (amount) =>
          widget.onBudgetV2LimitChanged?.call(selected, amount),
    );
  }

  Widget _buildPostContent(
    BalanceRenderFrame frame,
    SpendeeBalanceCollapseVisuals visuals,
  ) {
    return Positioned(
      top: SpendeeBalanceVisualSpec.actionTop,
      right: SpendeeBalanceVisualSpec.canvasContentInset,
      left: SpendeeBalanceVisualSpec.canvasContentInset,
      child: Transform.translate(
        offset: Offset(0, visuals.scrollContentTranslateY),
        child: Transform.translate(
          key: const ValueKey('spendee-balance-post-content-transform'),
          offset: Offset(0, visuals.postTranslateY),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                key: const ValueKey('spendee-balance-action-collapse-region'),
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) => _beginCollapseDrag(),
                onVerticalDragUpdate: (details) =>
                    _updateCollapseDrag(details.delta.dy),
                onVerticalDragEnd: (_) => _endCollapseDrag(),
                onVerticalDragCancel: _cancelCollapseDrag,
                child: SpendeeBalanceActionToggle(
                  activeType: frame.query.activeType,
                  onChanged: _changeType,
                ),
              ),
              const SizedBox(height: SpendeeBalanceVisualSpec.stackGap),
              SpendeeBalanceSummary(
                label: _summaryLabel(frame),
                amount: frame.summary.amountText,
                scopeExpanded: _timeRailExpanded,
                onOpenScopePicker: _toggleTimeRail,
                onSummaryTap: widget.onSummaryTap,
                onResetCurrentMonth: widget.onSummaryReset ?? () {},
                onShiftPeriod: widget.onShiftPeriod ?? (_) {},
                onCycleScope: widget.onCycleSummary ?? () {},
              ),
              const SizedBox(height: SpendeeBalanceVisualSpec.stackGap),
              SpendeeBalanceSearchFilter(
                query: frame.query.searchQuery,
                filters: _searchChips(frame),
                onQueryChanged: widget.onQueryChanged ?? (_) {},
                onRemoveFilter: widget.onRemoveFilter ?? (_) {},
                onFilterPressed: widget.onFilterPressed ?? () {},
                onCycleScope: widget.onCycleSummary ?? () {},
              ),
              const SizedBox(height: SpendeeBalanceVisualSpec.stackGap),
              AnimatedSize(
                duration: _reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                child: _timeRailExpanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SpendeeBalanceTimeScopeRail(
                            label: '',
                            currentLabel: '',
                            selectedKey: frame.query.selectedScope?.key ?? '',
                            options: [
                              for (final option in frame.query.scopeOptions)
                                SpendeeBalanceTimeScopeItem(
                                  key: option.key,
                                  label: option.label,
                                ),
                            ],
                            collapseProgress: visuals.progress,
                            dragging: _collapseController.dragging,
                            showChrome: false,
                            onSelected: (item) {
                              final selected = frame.query.scopeOptions
                                  .firstWhere(
                                    (option) => option.key == item.key,
                                  );
                              _selectScope(selected);
                            },
                            onPreview: (item) =>
                                _railPublication.preview(item.key),
                            onRailDragStart: () => _railPublication.beginDrag(
                              frame.query.selectedScope?.key ?? '',
                            ),
                            onCollapseDragStart: _beginCollapseDrag,
                            onCollapseDragUpdate: _updateCollapseDrag,
                            onCollapseDragEnd: _endCollapseDrag,
                            onCollapseToggle: _toggleCollapse,
                          ),
                          const SizedBox(height: 3),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              SpendeeBalanceCollapseControl(
                transactionCount: frame.transactionCount,
                collapseProgress: visuals.progress,
                dragging: _collapseController.dragging,
                onDragStart: _beginCollapseDrag,
                onDragUpdate: _updateCollapseDrag,
                onDragEnd: _endCollapseDrag,
                onToggle: _toggleCollapse,
              ),
              const SizedBox(height: SpendeeBalanceVisualSpec.stackGap),
              RepaintBoundary(
                key: const ValueKey(
                  'spendee-balance-transaction-repaint-boundary',
                ),
                child: _transactionLog(context, frame),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setGhostSection(String cardId, bool included) {
    final section = _ghostSectionForId(cardId);
    if (section == null) return;
    setState(() {
      if (included) {
        _includedGhostSections.add(section);
      } else {
        _includedGhostSections.remove(section);
      }
      _cachedFrame = null;
      _frameHistory.clear();
      _clearTransactionLogCache();
    });
  }

  void _toggleTimeRail() {
    final trace = BalanceDebugTrace.enabled
        ? BalanceDebugTrace.begin(
            'balance-rail-toggle',
            fields: <String, Object?>{'expanded': !_timeRailExpanded},
          )
        : null;
    try {
      setState(() => _timeRailExpanded = !_timeRailExpanded);
    } catch (error) {
      BalanceDebugTrace.finish(trace, error: error);
      rethrow;
    }
    _finishTraceAfterNextFrame(trace);
  }

  void _finishTraceAfterNextFrame(
    BalanceDebugTraceToken? trace, {
    String? selectedScope,
    int? prebuiltSlots,
    String? metricCache,
  }) {
    if (trace == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        BalanceDebugTrace.finish(
          trace,
          fields: const <String, Object?>{'reason': 'dispose'},
        );
        return;
      }
      BalanceDebugTrace.finish(
        trace,
        fields: <String, Object?>{
          'frame_cache': _lastFrameCacheOutcome,
          'log_cache': _lastTransactionLogCacheOutcome,
          ...switch (selectedScope) {
            final selectedScope? => <String, Object?>{
              'selected_scope': selectedScope,
            },
            null => const <String, Object?>{},
          },
          ...switch (prebuiltSlots) {
            final prebuiltSlots? => <String, Object?>{
              'prebuilt_slots': prebuiltSlots,
            },
            null => const <String, Object?>{},
          },
          ...switch (metricCache) {
            final metricCache? => <String, Object?>{
              'metric_cache': metricCache,
            },
            null => const <String, Object?>{},
          },
        },
      );
    });
  }

  void _cycleNoSpendDimension() {
    final dimensions = SpendeeBalanceNoSpendDimension.values;
    final previous = _noSpendDimension;
    final next = dimensions[(previous.index + 1) % dimensions.length];
    _changeFastInfoDimension(
      card: 'no_spend',
      previous: previous.name,
      next: next.name,
      apply: () => _noSpendDimension = next,
    );
  }

  Widget _transactionLog(BuildContext context, BalanceRenderFrame frame) {
    final revision =
        widget.transactionLogRevision ?? widget.transactionLogBuilder;
    // A parent AnimatedBuilder commonly recreates this callback after a
    // page-load notify. Keep the cache entry's token in that case: the new
    // child below refreshes callbacks and rows, while the token preserves the
    // ScrollableState that emitted the load-more notification.
    final revisionChanged = _transactionLogCacheRevision != revision;
    _transactionLogCacheRevision = revision;
    final cacheKey = _BalanceTransactionLogCacheKey.fromFrame(frame);
    final cached = _transactionLogCaches
        .where((entry) => entry.key == cacheKey)
        .firstOrNull;
    if (cached != null && !revisionChanged && identical(cached.frame, frame)) {
      _lastTransactionLogCacheOutcome = 'reused';
      return _RetainedBalanceTransactionLogs(
        activeToken: cached.token,
        entries: _transactionLogCaches,
      );
    }
    _lastTransactionLogCacheOutcome = 'rebuilt';
    final trace = BalanceDebugTrace.enabled
        ? BalanceDebugTrace.begin(
            'balance-transaction-log-build',
            fields: <String, Object?>{
              'groups': frame.logGroups.length,
              'visible_rows': frame.visibleLogRowCount,
              'has_more': frame.hasMoreLogEntries,
            },
          )
        : null;
    late final Widget result;
    try {
      result = widget.transactionLogBuilder(context, frame);
    } catch (error) {
      BalanceDebugTrace.finish(trace, error: error);
      rethrow;
    }
    if (trace != null) {
      BalanceDebugTrace.finish(
        trace,
        fields: <String, Object?>{
          'cache': _lastTransactionLogCacheOutcome,
          'groups': frame.logGroups.length,
        },
      );
    }
    if (cached != null) {
      // Paging changes the frame's bounded rows but not the user's logical
      // query. Replace the child under its stable token so ScrollableState and
      // its current offset survive the next page without keeping stale rows.
      cached.replace(frame: frame, child: result);
      return _RetainedBalanceTransactionLogs(
        activeToken: cached.token,
        entries: _transactionLogCaches,
      );
    }
    final entry = _BalanceTransactionLogCacheEntry(
      key: cacheKey,
      frame: frame,
      child: result,
    );
    _transactionLogCaches.add(entry);
    if (_transactionLogCaches.length > _transactionLogCacheCapacity) {
      _transactionLogCaches.removeAt(0);
    }
    return _RetainedBalanceTransactionLogs(
      activeToken: entry.token,
      entries: _transactionLogCaches,
    );
  }

  void _clearTransactionLogCache() {
    _transactionLogCaches.clear();
    _transactionLogCacheRevision = null;
  }

  void _changeType(TransactionType type) {
    final trace = BalanceDebugTrace.enabled
        ? BalanceDebugTrace.begin(
            'balance-type-switch',
            fields: <String, Object?>{
              'from_type': widget.input.activeType.name,
              'to_type': type.name,
            },
          )
        : null;
    try {
      widget.onTypeChanged?.call(type);
    } catch (error) {
      BalanceDebugTrace.finish(trace, error: error);
      rethrow;
    }
    _finishTraceAfterNextFrame(trace);
  }

  void _selectScope(BalanceTimeScopeOption option) {
    if (!_railPublication.settle(option.key)) return;
    final trace = BalanceDebugTrace.enabled
        ? BalanceDebugTrace.begin(
            'balance-rail-load',
            fields: <String, Object?>{
              'requested_scope': option.key,
              'window': option.window.name,
              'superseded': _railPublication.superseded,
              'duplicate_final_loads': 0,
              'discarded_frame_resolves': 0,
              'recurring_during_drag': 0,
              'inactive_stats_during_drag': 0,
            },
          )
        : null;
    try {
      widget.onScopeSelected?.call(option);
    } catch (error) {
      BalanceDebugTrace.finish(trace, error: error);
      rethrow;
    }
    if (trace == null) return;
    final previousTrace = _pendingScopeTrace;
    if (previousTrace != null) {
      BalanceDebugTrace.finish(
        previousTrace,
        fields: const <String, Object?>{'reason': 'superseded'},
      );
    }
    _pendingScopeTrace = trace;
    _pendingScopeTraceKey = option.key;
    _scopeTraceFinishScheduled = false;
  }

  /// Complete the rail load at the first frame carrying its settled scope.
  /// Recurring ghosts continue as background work; making them part of the
  /// rail completion would turn a visual drag settle into an unbounded wait.
  void _settleScopeTraceIfReady(BalanceRenderFrame frame) {
    final trace = _pendingScopeTrace;
    final requestedKey = _pendingScopeTraceKey;
    if (trace == null || requestedKey == null || _scopeTraceFinishScheduled) {
      return;
    }
    if (frame.query.selectedScope?.key != requestedKey) {
      return;
    }
    _scopeTraceFinishScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final latestTrace = _pendingScopeTrace;
      if (!identical(latestTrace, trace)) return;
      _pendingScopeTrace = null;
      _pendingScopeTraceKey = null;
      _scopeTraceFinishScheduled = false;
      if (!mounted) {
        BalanceDebugTrace.finish(
          trace,
          fields: const <String, Object?>{'reason': 'dispose'},
        );
        return;
      }
      BalanceDebugTrace.finish(
        trace,
        fields: <String, Object?>{
          'selected_scope': requestedKey,
          'frame_cache': _lastFrameCacheOutcome,
          'log_cache': _lastTransactionLogCacheOutcome,
          'prebuilt_slots':
              SpendeeBalanceVisualSpec.timeRailVisibleLogicalDistance * 2 + 1,
        },
      );
    });
  }

  void _changeFastInfoDimension({
    required String card,
    required String previous,
    required String next,
    required VoidCallback apply,
  }) {
    if (previous == next) return;
    final trace = BalanceDebugTrace.enabled
        ? BalanceDebugTrace.begin(
            'balance-fast-info-dimension',
            fields: <String, Object?>{
              'card': card,
              'from_dimension': previous,
              'to_dimension': next,
            },
          )
        : null;
    try {
      setState(apply);
    } catch (error) {
      BalanceDebugTrace.finish(trace, error: error);
      rethrow;
    }
    _finishTraceAfterNextFrame(trace, metricCache: 'frame_local');
  }

  List<SpendeeBalanceFastInfoCardModel> _fastInfoModels(
    BalanceRenderFrame frame,
  ) {
    final noSpend = frame.insights[BalanceInsightKind.noSpend]!;
    final categoryChange = frame.insights[BalanceInsightKind.categoryChange]!;
    final latest = frame.insights[BalanceInsightKind.latestTransaction]!;
    final trend = frame.insights[BalanceInsightKind.trendComparison]!;
    final recurring = frame.insights[BalanceInsightKind.upcomingRecurring]!;
    final recurringCategory = recurring.category;
    final recurringGhost = recurring.ghost;
    final noSpendFrame = frame.noSpendFor(_noSpendDimension);
    final categoryPercent = _categoryChangePercent(categoryChange);
    final latestMerchant =
        latest.record?.displayMerchant.trim().isNotEmpty == true
        ? latest.record!.displayMerchant
        : latest.ghost?.name ?? latest.secondaryText.split(' · ').first;
    return [
      SpendeeBalanceNoSpendCardModel(
        id: 'no-spend',
        title: noSpend.title,
        value: '${noSpendFrame.noSpendDays} nap',
        secondary: '${noSpendFrame.observedDays} napból',
        dimension: _noSpendDimension,
        dimensionLabel: _noSpendDimension.fastInfoViewLabel,
        includeGhostTransactions: _ghostIncluded(BalanceGhostSection.noSpend),
      ),
      SpendeeBalanceCategoryChangeCardModel(
        id: 'category-change',
        title: categoryChange.category?.name ?? categoryChange.title,
        value: categoryPercent,
        category: categoryChange.category?.name ?? 'Nincs kategória',
        secondary: 'az elmúlt 30 naphoz képest',
        iconAsset: _categoryIcon(categoryChange.category),
        currentAmount: formatBalanceForint(
          (categoryChange.comparisonValue ?? 0) +
              (categoryChange.numericValue ?? 0),
        ),
        previousAmount: formatBalanceForint(
          categoryChange.comparisonValue ?? 0,
        ),
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.categoryChange,
        ),
      ),
      SpendeeBalanceLatestTransactionCardModel(
        id: 'latest-transaction',
        title: latest.title,
        amount: latest.primaryText,
        merchantAndTime: latestMerchant,
        iconAsset: _categoryIcon(latest.category),
        category: latest.category?.name ?? 'Nincs kategória',
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.latestTransaction,
        ),
      ),
      SpendeeBalanceTrendComparisonCardModel(
        id: 'trend-comparison',
        title: trend.title,
        percentage: trend.primaryText,
        secondary: trend.secondaryText,
        direction: switch (trend.direction) {
          'up' => SpendeeBalanceTrendDirection.up,
          'down' => SpendeeBalanceTrendDirection.down,
          _ => SpendeeBalanceTrendDirection.flat,
        },
        iconAsset: 'assets/icons/lucide/chart-candlestick.svg',
        currentAmount: formatBalanceForint(trend.numericValue ?? 0),
        previousAmount: formatBalanceForint(trend.comparisonValue ?? 0),
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.trendComparison,
        ),
      ),
      SpendeeBalanceUpcomingRecurringCardModel(
        id: 'upcoming-recurring',
        title: recurring.title,
        name: recurringGhost?.name ?? 'Nincs közelgő tétel',
        amount: recurring.primaryText,
        dueText: recurringGhost == null ? '' : _shortDate(recurringGhost.date),
        categoryIconAsset: _categoryIcon(recurringCategory),
        categoryColor: recurringCategory?.slotColor ?? const Color(0xFF8B5CF6),
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.upcomingRecurring,
        ),
      ),
    ];
  }

  String _categoryChangePercent(BalanceInsightFrame insight) {
    final delta = insight.numericValue;
    final previous = insight.comparisonValue;
    if (delta == null || previous == null || previous == 0) {
      return insight.primaryText;
    }
    final percent = (delta / previous * 100).round();
    return '${percent >= 0 ? '+' : ''}$percent%';
  }

  List<SpendeeBalanceDetailPageModel> _detailModels(
    BalanceRenderFrame frame, {
    bool expanded = false,
  }) {
    final variableDimensions =
        <SpendeeBalanceBudgetDimension, SpendeeBalanceBudgetDimensionModel>{
          for (final entry in frame.variableBudgets.entries)
            _budgetPresentation(entry.key): _budgetDimensionModel(entry.value),
        };
    final categoryRanks = frame.topCategoriesFor(_categoryRankDimension);
    final categoryLeader = categoryRanks.isEmpty ? null : categoryRanks.first;
    final categoryRows = <SpendeeBalanceTopCategoryRowModel>[
      for (final row in categoryRanks.skip(1))
        SpendeeBalanceTopCategoryRowModel(
          scope: '${row.rank}. hely',
          category: row.name,
          amount: formatBalanceForint(row.amount),
          iconAsset: _categoryIcon(row.category),
          color: row.category?.slotColor ?? const Color(0xFFF24CAE),
        ),
    ];
    final vendorRanks = frame.topVendorsFor(_vendorRankDimension);
    final average = frame.averageFor(_averageDimension);
    return [
      SpendeeBalanceVariableBudgetModel(
        id: 'variable-budget',
        title: 'Változó keret',
        selectedDimension: _budgetDimension,
        dimensions: variableDimensions,
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.variableBudget,
        ),
      ),
      SpendeeBalanceTopCategoriesModel(
        id: 'top-categories',
        title: expanded ? 'Top 5 kategória' : 'Top kategóriák',
        featuredCategory: categoryLeader?.name ?? 'Nincs adat',
        featuredMeta: '${_categoryRankDimension.label} · 1. hely',
        featuredAmount: formatBalanceForint(categoryLeader?.amount ?? 0),
        featuredIconAsset: _categoryIcon(categoryLeader?.category),
        rows: categoryRows,
        rankDimension: _categoryRankDimension,
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.topCategories,
        ),
      ),
      SpendeeBalanceTopMerchantsModel(
        id: 'top-merchants',
        title: expanded ? 'Top 5 kereskedő' : 'Top 4 kereskedő',
        selectedDimension: _merchantDimension,
        rows: [
          for (final row in vendorRanks)
            SpendeeBalanceMerchantRowModel(
              merchant: row.name,
              transactionCount: '${row.transactionCount} tranzakció',
              amount: formatBalanceForint(row.amount),
              iconAsset: _categoryIcon(row.category),
              color: row.category?.slotColor ?? const Color(0xFFF24CAE),
            ),
        ],
        rankDimension: _vendorRankDimension,
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.topMerchants,
        ),
      ),
      SpendeeBalanceAverageDailyModel(
        id: 'average-daily',
        title: 'Átlagos napi költés',
        periodLabel: _averageDimension.label,
        rollingTotalLabel:
            '${formatBalanceForint(average.total)} / ${average.observedDays} nap',
        averageLabel: '${formatBalanceForint(average.dailyAverage)} / nap',
        dailyValues: average.dailyValues,
        facts: [
          SpendeeBalanceDailyFactModel(
            label: 'Egyenleg puffer',
            value: average.bufferDays == null
                ? 'Nincs adat'
                : '${average.bufferDays} nap',
          ),
          SpendeeBalanceDailyFactModel(
            label: 'Legmagasabb nap',
            value: formatBalanceForint(average.maximum),
          ),
          SpendeeBalanceDailyFactModel(
            label:
                'Kiugrások > ${formatBalanceForint(average.outlierThreshold)}',
            value: '${average.outlierCount} db',
          ),
        ],
        selectedDimension: _averageDimension,
        iconAsset: 'assets/icons/lucide/chart-candlestick.svg',
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.averageDaily,
        ),
      ),
    ];
  }

  SpendeeBalanceBudgetDimensionModel _budgetDimensionModel(
    BalanceVariableBudgetDimension value,
  ) {
    final (remaining, spent, transactions, threshold) = switch (value.period) {
      BalanceBudgetPeriod.day => (
        'Mára még elkölthető',
        'Ma elköltve',
        'Mai kiadási tételek',
        'Mai költés a kerethez képest',
      ),
      BalanceBudgetPeriod.week => (
        'A héten még elkölthető',
        'Héten elköltve',
        'Heti kiadási tételek',
        'Heti költés a kerethez képest',
      ),
      BalanceBudgetPeriod.month => (
        'Ebben a hónapban még elkölthető',
        'Hónapban elköltve',
        'Havi kiadási tételek',
        'Havi költés a kerethez képest',
      ),
    };
    return SpendeeBalanceBudgetDimensionModel(
      dimension: _budgetPresentation(value.period),
      remainingLabel: remaining,
      remaining: formatBalanceForint(value.remaining),
      spentLabel: spent,
      spent: formatBalanceForint(value.spent),
      transactionLabel: transactions,
      transactionCount: '${value.transactionCount} db',
      thresholdLabel: threshold,
      budgetLabel: 'Keret: ${formatBalanceForint(value.budget)}',
      referenceLabel: switch (value.period) {
        BalanceBudgetPeriod.day =>
          '30 napos napi átlag: '
              '${formatBalanceForint(value.referenceAmount)}',
        BalanceBudgetPeriod.week || BalanceBudgetPeriod.month =>
          'Felhasználva: '
              '${(value.progress.clamp(0.0, 1.0) * 100).round()}%',
      },
      progress: value.progress.clamp(0.0, 1.0).toDouble(),
    );
  }

  List<SpendeeBalanceSearchChip> _searchChips(BalanceRenderFrame frame) {
    final categoriesById = {
      for (final category in widget.input.categories)
        category.transactionCategoryID: category,
    };
    return [
      for (final categoryId in frame.query.categoryIds)
        if (categoriesById[categoryId] case final category?)
          SpendeeBalanceSearchChip(
            keyValue: 'category:$categoryId',
            label: category.name,
            color: category.slotColor,
          ),
      for (final merchant in frame.query.merchantFilters)
        SpendeeBalanceSearchChip(
          keyValue: 'merchant:$merchant',
          label: merchant,
          color: const Color(0xFF7564F5),
        ),
    ];
  }

  String _summaryLabel(BalanceRenderFrame frame) {
    final reference = frame.summary.referenceDate;
    final now = widget.input.now;
    if (frame.summary.window == SummaryWindow.monthly &&
        reference.year == now.year &&
        reference.month == now.month &&
        frame.query.searchQuery.trim().isEmpty &&
        frame.query.categoryIds.isEmpty &&
        frame.query.merchantFilters.isEmpty) {
      return 'Aktuális hónap';
    }
    return frame.summary.label;
  }

  bool _ghostIncluded(BalanceGhostSection section) =>
      _includedGhostSections.contains(section);
}

class _BalanceFrameHistoryEntry {
  _BalanceFrameHistoryEntry({
    required this.input,
    required Set<BalanceGhostSection> includedGhostSections,
    required this.frame,
  }) : includedGhostSections = Set<BalanceGhostSection>.unmodifiable(
         includedGhostSections,
       );

  final BalanceFrameInput input;
  final Set<BalanceGhostSection> includedGhostSections;
  final BalanceRenderFrame frame;

  bool matches(
    BalanceFrameInput candidate,
    Set<BalanceGhostSection> candidateSections,
  ) {
    final sameGhostProjectionContent =
        input.ghostProjectionInFlight != candidate.ghostProjectionInFlight &&
        candidate.summaryWindow == SummaryWindow.monthly &&
        frame.query.selectedScope?.key ==
            '${candidate.summaryReferenceDate.year}-${candidate.summaryReferenceDate.month.toString().padLeft(2, '0')}';
    return input.sameHistoryRevisionAs(
          candidate,
          ignoreGhostProjectionInFlight: sameGhostProjectionContent,
        ) &&
        includedGhostSections.length == candidateSections.length &&
        includedGhostSections.containsAll(candidateSections);
  }
}

class _BalanceTransactionLogCacheEntry {
  _BalanceTransactionLogCacheEntry({
    required this.key,
    required this.frame,
    required this.child,
  });

  final _BalanceTransactionLogCacheKey key;
  BalanceRenderFrame frame;
  Widget child;
  final Object token = Object();

  void replace({required BalanceRenderFrame frame, required Widget child}) {
    this.frame = frame;
    this.child = child;
  }
}

class _BalanceTransactionLogCacheKey {
  const _BalanceTransactionLogCacheKey({
    required this.type,
    required this.window,
    required this.requestedReferenceDate,
    required this.effectiveReferenceDate,
    required this.searchQuery,
    required this.merchantFilters,
    required this.categoryIds,
  });

  factory _BalanceTransactionLogCacheKey.fromFrame(BalanceRenderFrame frame) {
    final query = frame.query;
    final merchants = query.merchantFilters.toList()..sort();
    final categories = query.categoryIds.toList()..sort();
    return _BalanceTransactionLogCacheKey(
      type: query.activeType,
      window: query.summaryWindow,
      requestedReferenceDate: query.requestedReferenceDate,
      effectiveReferenceDate: query.effectiveReferenceDate,
      searchQuery: query.searchQuery,
      merchantFilters: merchants.join('\u001f'),
      categoryIds: categories.join(','),
    );
  }

  final TransactionType type;
  final SummaryWindow window;
  final DateTime requestedReferenceDate;
  final DateTime effectiveReferenceDate;
  final String searchQuery;
  final String merchantFilters;
  final String categoryIds;

  @override
  bool operator ==(Object other) =>
      other is _BalanceTransactionLogCacheKey &&
      type == other.type &&
      window == other.window &&
      requestedReferenceDate == other.requestedReferenceDate &&
      effectiveReferenceDate == other.effectiveReferenceDate &&
      searchQuery == other.searchQuery &&
      merchantFilters == other.merchantFilters &&
      categoryIds == other.categoryIds;

  @override
  int get hashCode => Object.hash(
    type,
    window,
    requestedReferenceDate,
    effectiveReferenceDate,
    searchQuery,
    merchantFilters,
    categoryIds,
  );
}

/// Keeps the two most recent type-specific logs in the element tree. The
/// inactive viewport is transparent and offstage; it owns no visual surface
/// behind FastInfo/detail cards and it avoids remounting every row on a
/// return toggle.
class _RetainedBalanceTransactionLogs extends StatelessWidget {
  const _RetainedBalanceTransactionLogs({
    required this.activeToken,
    required this.entries,
  });

  final Object activeToken;
  final List<_BalanceTransactionLogCacheEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        for (final entry in entries)
          Offstage(
            key: ValueKey(entry.token),
            offstage: !identical(entry.token, activeToken),
            child: entry.child,
          ),
      ],
    );
  }
}

BalanceGhostSection? _ghostSectionForId(String id) => switch (id) {
  'no-spend' => BalanceGhostSection.noSpend,
  'category-change' => BalanceGhostSection.categoryChange,
  'latest-transaction' => BalanceGhostSection.latestTransaction,
  'trend-comparison' => BalanceGhostSection.trendComparison,
  'upcoming-recurring' => BalanceGhostSection.upcomingRecurring,
  'variable-budget' => BalanceGhostSection.variableBudget,
  'top-categories' => BalanceGhostSection.topCategories,
  'top-merchants' => BalanceGhostSection.topMerchants,
  'average-daily' => BalanceGhostSection.averageDaily,
  _ => null,
};

SpendeeBalanceBudgetDimension _budgetPresentation(BalanceBudgetPeriod value) =>
    switch (value) {
      BalanceBudgetPeriod.day => SpendeeBalanceBudgetDimension.day,
      BalanceBudgetPeriod.week => SpendeeBalanceBudgetDimension.week,
      BalanceBudgetPeriod.month => SpendeeBalanceBudgetDimension.month,
    };

String _categoryIcon(TransactionCategory? category) =>
    CategoryIconManager.assetPath(category?.iconSlot);

String _signedBalance(double amount) {
  return formatBalanceSignedForint(amount);
}

String _shortDate(String raw) {
  final normalized = raw.replaceAll('.', '-');
  final date = DateTime.tryParse(normalized);
  if (date == null) return raw;
  const months = <String>[
    'jan.',
    'febr.',
    'márc.',
    'ápr.',
    'máj.',
    'jún.',
    'júl.',
    'aug.',
    'szept.',
    'okt.',
    'nov.',
    'dec.',
  ];
  return '${months[date.month - 1]} ${date.day}.';
}
