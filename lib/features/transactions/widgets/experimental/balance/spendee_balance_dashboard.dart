import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/summary_window.dart';
import '../../../models/transaction_category.dart';
import '../../../slots/category_icon_manager.dart';
import '../../../state/balance_amount_formatter.dart';
import '../../../state/balance_frame.dart';
import 'spendee_balance_cards.dart';
import 'spendee_balance_collapse_controller.dart';
import 'spendee_balance_header.dart';
import 'spendee_balance_post_content.dart';
import 'spendee_balance_visual_spec.dart';

typedef SpendeeBalanceTransactionLogBuilder =
    Widget Function(BuildContext context, BalanceRenderFrame frame);

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
  });

  final BalanceFrameInput input;
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

  @override
  State<SpendeeBalanceDashboard> createState() =>
      _SpendeeBalanceDashboardState();
}

class _SpendeeBalanceDashboardState extends State<SpendeeBalanceDashboard>
    with SingleTickerProviderStateMixin {
  static const _collapseSettleDuration = Duration(milliseconds: 260);

  late final SpendeeBalanceCollapseController _collapseController;
  late final AnimationController _collapseSettleController;
  Animation<double>? _collapseAnimation;
  final Set<BalanceGhostSection> _includedGhostSections = BalanceGhostSection
      .values
      .toSet();
  var _budgetDimension = SpendeeBalanceBudgetDimension.day;
  var _merchantDimension = SpendeeBalanceMerchantDimension.month;
  BalanceFrameInput? _cachedInput;
  BalanceRenderFrame? _cachedFrame;
  Widget? _cachedTransactionLog;
  BalanceRenderFrame? _cachedTransactionLogFrame;
  Object? _cachedTransactionLogRevision;
  String? _scheduledFallbackKey;

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
    _scheduleScopeFallback(frame.query);
    final visuals = SpendeeBalanceCollapseVisuals.forProgress(
      _collapseController.progress,
    );
    final inheritedTheme = Theme.of(context);
    return Theme(
      data: inheritedTheme.copyWith(
        textTheme: inheritedTheme.textTheme.apply(fontFamily: 'Inter'),
        primaryTextTheme: inheritedTheme.primaryTextTheme.apply(
          fontFamily: 'Inter',
        ),
      ),
      child: FocusTraversalGroup(
        key: const ValueKey('spendee-balance-focus-traversal'),
        policy: ReadingOrderTraversalPolicy(),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'Inter'),
          child: ColoredBox(
            color: SpendeeBalanceVisualSpec.pageBackground,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  key: const ValueKey('spendee-balance-dashboard'),
                  width: SpendeeBalanceVisualSpec.canvas.width,
                  height: SpendeeBalanceVisualSpec.canvas.height,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
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
                    ],
                  ),
                ),
              ),
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
      return cached;
    }
    final frame = BalanceFrameResolver.resolve(
      widget.input,
      ghostPolicy: BalanceGhostPolicy.only(_includedGhostSections),
    );
    _cachedInput = widget.input;
    _cachedFrame = frame;
    _cachedTransactionLog = null;
    _cachedTransactionLogFrame = null;
    _cachedTransactionLogRevision = null;
    return frame;
  }

  void _scheduleScopeFallback(BalanceQueryFrame query) {
    if (!query.hasPendingScopeFallback || widget.onScopeFallback == null) {
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
    return Positioned(
      key: const ValueKey('spendee-balance-collapse-content-region'),
      top: SpendeeBalanceVisualSpec.heroTop,
      right: SpendeeBalanceVisualSpec.horizontalInset,
      left: SpendeeBalanceVisualSpec.horizontalInset,
      height:
          SpendeeBalanceVisualSpec.detailTop -
          SpendeeBalanceVisualSpec.heroTop +
          SpendeeBalanceVisualSpec.detailStageHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (_) => _beginCollapseDrag(),
        onVerticalDragUpdate: (details) =>
            _updateCollapseDrag(details.delta.dy),
        onVerticalDragEnd: (_) => _endCollapseDrag(),
        onVerticalDragCancel: _cancelCollapseDrag,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: SpendeeBalanceHeader(
                balanceText: _signedBalance(frame.balance),
                reservePercent: (frame.reserveRatio * 100).round(),
                incomeRatio: (frame.incomeRatio * 100).round(),
                expenseRatio: (frame.expenseRatio * 100).round(),
                collapseProgress: visuals.progress,
                surfaceBuilder: widget.headerSurfaceBuilder,
              ),
            ),
            Positioned(
              top:
                  SpendeeBalanceVisualSpec.insightTop -
                  SpendeeBalanceVisualSpec.heroTop,
              right: 0,
              left: 0,
              height: SpendeeBalanceVisualSpec.insightHeight,
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
                            child: SpendeeBalanceFastInfoBelt(
                              cards: _fastInfoModels(frame),
                              onGhostChanged: _setGhostSection,
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
              top:
                  SpendeeBalanceVisualSpec.detailTop -
                  SpendeeBalanceVisualSpec.heroTop,
              right: 0,
              left: 0,
              height: SpendeeBalanceVisualSpec.detailStageHeight,
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
                            child: SpendeeBalanceDetailCarousel(
                              pages: _detailModels(frame),
                              onGhostChanged: _setGhostSection,
                              onBudgetDimensionChanged: (value) {
                                setState(() => _budgetDimension = value);
                              },
                              onMerchantDimensionChanged: (value) {
                                setState(() => _merchantDimension = value);
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
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent(
    BalanceRenderFrame frame,
    SpendeeBalanceCollapseVisuals visuals,
  ) {
    return Positioned(
      top: SpendeeBalanceVisualSpec.actionTop,
      right: SpendeeBalanceVisualSpec.horizontalInset,
      left: SpendeeBalanceVisualSpec.horizontalInset,
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
                  onChanged: widget.onTypeChanged ?? (_) {},
                ),
              ),
              const SizedBox(height: SpendeeBalanceVisualSpec.stackGap),
              SpendeeBalanceSummary(
                label: _summaryLabel(frame),
                amount: frame.summary.amountText,
                onOpenScopePicker: widget.onSummaryTap ?? () {},
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
              SpendeeBalanceTimeScopeRail(
                label: frame.query.summaryWindow == SummaryWindow.monthly
                    ? 'HÓNAP FINOMÍTÁS'
                    : 'ÉV FINOMÍTÁS',
                currentLabel:
                    frame.query.selectedScope?.label ?? frame.summary.label,
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
                onSelected: (item) {
                  final selected = frame.query.scopeOptions.firstWhere(
                    (option) => option.key == item.key,
                  );
                  widget.onScopeSelected?.call(selected);
                },
                onCollapseDragStart: _beginCollapseDrag,
                onCollapseDragUpdate: _updateCollapseDrag,
                onCollapseDragEnd: _endCollapseDrag,
                onCollapseToggle: _toggleCollapse,
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
      _cachedTransactionLog = null;
      _cachedTransactionLogFrame = null;
      _cachedTransactionLogRevision = null;
    });
  }

  Widget _transactionLog(BuildContext context, BalanceRenderFrame frame) {
    final revision =
        widget.transactionLogRevision ?? widget.transactionLogBuilder;
    final cached = _cachedTransactionLog;
    if (cached != null &&
        identical(_cachedTransactionLogFrame, frame) &&
        _cachedTransactionLogRevision == revision) {
      return cached;
    }
    final result = widget.transactionLogBuilder(context, frame);
    _cachedTransactionLogFrame = frame;
    _cachedTransactionLogRevision = revision;
    _cachedTransactionLog = result;
    return result;
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
    return [
      SpendeeBalanceNoSpendCardModel(
        id: 'no-spend',
        title: noSpend.title,
        value: noSpend.primaryText,
        secondary: noSpend.secondaryText,
        includeGhostTransactions: _ghostIncluded(BalanceGhostSection.noSpend),
      ),
      SpendeeBalanceCategoryChangeCardModel(
        id: 'category-change',
        title: categoryChange.title,
        value: categoryChange.primaryText,
        category: categoryChange.category?.name ?? 'Nincs kategória',
        secondary: categoryChange.secondaryText,
        iconAsset: _categoryIcon(categoryChange.category),
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.categoryChange,
        ),
      ),
      SpendeeBalanceLatestTransactionCardModel(
        id: 'latest-transaction',
        title: latest.title,
        amount: latest.primaryText,
        merchantAndTime: latest.secondaryText,
        iconAsset: _categoryIcon(latest.category),
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

  List<SpendeeBalanceDetailPageModel> _detailModels(BalanceRenderFrame frame) {
    final variableDimensions =
        <SpendeeBalanceBudgetDimension, SpendeeBalanceBudgetDimensionModel>{
          for (final entry in frame.variableBudgets.entries)
            _budgetPresentation(entry.key): _budgetDimensionModel(entry.value),
        };
    final categoryRows = <SpendeeBalanceTopCategoryRowModel>[
      _categoryRow(
        frame.topCategories[BalanceCategoryPeriod.week],
        'Ezen a héten',
      ),
      _categoryRow(
        frame.topCategories[BalanceCategoryPeriod.month],
        'Ebben a hónapban',
      ),
      _categoryRow(
        frame.topCategories[BalanceCategoryPeriod.year],
        'Idén eddig',
      ),
    ];
    final featured =
        frame.topCategories[BalanceCategoryPeriod.day] ??
        frame.topCategories.values.whereType<BalanceCategoryRank>().firstOrNull;
    final merchantPeriod = _merchantDomain(_merchantDimension);
    final merchantRows = [...?frame.topMerchants[merchantPeriod]];
    while (merchantRows.length < 5) {
      merchantRows.add(
        BalanceMerchantRank(
          period: merchantPeriod,
          rank: merchantRows.length + 1,
          name: 'Nincs adat',
          amount: 0,
          transactionCount: 0,
        ),
      );
    }
    final average = frame.averageDaily;
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
        title: 'Top kategóriák',
        featuredCategory: featured?.category?.name ?? 'Nincs adat',
        featuredMeta: 'Ma vezető kategóriája',
        featuredAmount: formatBalanceForint(featured?.amount ?? 0),
        featuredIconAsset: _categoryIcon(featured?.category),
        rows: categoryRows,
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.topCategories,
        ),
      ),
      SpendeeBalanceTopMerchantsModel(
        id: 'top-merchants',
        title: 'Top 5 kereskedő',
        selectedDimension: _merchantDimension,
        rows: [
          for (final row in merchantRows.take(5))
            SpendeeBalanceMerchantRowModel(
              merchant: row.name,
              transactionCount: '${row.transactionCount} tranzakció',
              amount: formatBalanceForint(row.amount),
              iconAsset: _categoryIcon(row.category),
              color: row.category?.slotColor ?? const Color(0xFF8B7DFA),
            ),
        ],
        includeGhostTransactions: _ghostIncluded(
          BalanceGhostSection.topMerchants,
        ),
      ),
      SpendeeBalanceAverageDailyModel(
        id: 'average-daily',
        title: 'Átlagos napi költés',
        periodLabel: 'Elmúlt 30 nap',
        rollingTotalLabel:
            '${formatBalanceForint(average.rollingTotal)} / 30 nap',
        averageLabel: '${formatBalanceForint(average.average)} / nap',
        dailyValues: average.dailySeries,
        facts: [
          SpendeeBalanceDailyFactModel(
            label: 'Egyenleg puffer',
            value: average.bufferDays == null
                ? 'Nincs adat'
                : '${average.bufferDays} nap',
          ),
          SpendeeBalanceDailyFactModel(
            label: 'Legmagasabb nap',
            value: formatBalanceForint(average.highestDay),
          ),
          SpendeeBalanceDailyFactModel(
            label: 'Kiugrások > ${formatBalanceForint(average.spikeThreshold)}',
            value: '${average.spikeDays} db',
          ),
        ],
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

  SpendeeBalanceTopCategoryRowModel _categoryRow(
    BalanceCategoryRank? row,
    String scope,
  ) {
    return SpendeeBalanceTopCategoryRowModel(
      scope: scope,
      category: row?.category?.name ?? 'Nincs adat',
      amount: formatBalanceForint(row?.amount ?? 0),
      iconAsset: _categoryIcon(row?.category),
      color: row?.category?.slotColor ?? const Color(0xFF8B7DFA),
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

BalanceMerchantPeriod _merchantDomain(SpendeeBalanceMerchantDimension value) =>
    switch (value) {
      SpendeeBalanceMerchantDimension.year => BalanceMerchantPeriod.year,
      SpendeeBalanceMerchantDimension.month => BalanceMerchantPeriod.month,
      SpendeeBalanceMerchantDimension.all => BalanceMerchantPeriod.allTime,
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
