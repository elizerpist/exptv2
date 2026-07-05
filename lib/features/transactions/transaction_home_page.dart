import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/debug/debug_console.dart';
import '../../core/theme/app_colors.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/theme/expense_theme.dart';
import '../settings/models/fast_info_config.dart';
import 'models/transaction_category.dart';
import 'models/transaction_record.dart';
import 'state/transaction_store.dart';
import 'widgets/category_menu/category_editor_panel.dart';
import 'widgets/category_menu/category_editor_sheet.dart';
import 'widgets/category_menu/category_menu_overlay.dart';
import 'widgets/category_menu/category_menu_panel.dart';
import 'models/backheader_budget_item.dart';
import 'widgets/header_card/category_budget_stage.dart';
import 'widgets/header_card/budget_target_editor_sheet.dart';
import 'widgets/header_card/fast_info_panel.dart';
import 'widgets/header_card/header_fast_info_surface.dart';
import 'widgets/header_card/magnet_strip.dart';
import 'widgets/header_card/transaction_header_metrics.dart';
import 'widgets/header_card/transaction_header_card.dart';
import 'widgets/search_pill.dart';
import 'widgets/slide_up_menu_card.dart';
import 'widgets/slide_up_panel_metrics.dart';
import 'widgets/summary_pill.dart';
import 'widgets/transaction_log_list.dart';
import 'widgets/transaction_type_pills.dart';

typedef BudgetTargetEditorRequest =
    void Function(
      BackheaderBudgetItem item, {
      required DateTime requestedAt,
      required bool headerExpanded,
    });

class TransactionHomePage extends StatefulWidget {
  const TransactionHomePage({
    super.key,
    required this.store,
    this.expenseTheme,
    this.fastInfoConfig,
    this.onEditTransaction,
    this.onDeleteTransactionRequested,
    this.onBlockingOverlayChanged,
    this.onBudgetTargetEditorRequested,
    this.onBudgetTargetEditorClosed,
    this.onFocusedSheetDismissRequested,
    this.onAddCategoryEditorRequested,
    this.onEditCategoryEditorRequested,
    this.budgetEditorActiveKey,
  });

  final TransactionStore store;
  final ExpenseTheme? expenseTheme;
  final FastInfoConfig? fastInfoConfig;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final FutureOr<bool> Function(TransactionRecord)?
  onDeleteTransactionRequested;
  final ValueChanged<bool>? onBlockingOverlayChanged;
  final BudgetTargetEditorRequest? onBudgetTargetEditorRequested;
  final VoidCallback? onBudgetTargetEditorClosed;
  final VoidCallback? onFocusedSheetDismissRequested;
  final VoidCallback? onAddCategoryEditorRequested;
  final ValueChanged<TransactionCategory>? onEditCategoryEditorRequested;
  final ValueNotifier<String?>? budgetEditorActiveKey;

  @override
  State<TransactionHomePage> createState() => _TransactionHomePageState();
}

class _TransactionHomePageState extends State<TransactionHomePage>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<TransactionHomePage> {
  var _headerExpanded = false;
  late final ValueNotifier<double> _fastInfoExtent;
  var _balanceHidden = false;
  String? _backheaderActiveKey;
  late final AnimationController _headerPullController;
  late final AnimationController _headerSlideController;
  CategoryOverlayMode? _categoryMode;
  BackheaderBudgetItem? _budgetEditorItem;
  DateTime? _budgetEditorOpenRequestedAt;
  var _categoryEditorOpen = false;
  var _blockingOverlayNotified = false;
  TransactionCategory? _editingCategory;
  int? _lastHomeBuildEntriesLogged;
  bool? _lastHomeBuildOverlayLogged;
  bool? _lastHomeBuildHeaderExpandedLogged;
  String? _lastThemeSurfaceLogSignature;

  @override
  void initState() {
    super.initState();
    _fastInfoExtent = ValueNotifier<double>(0);
    _headerPullController = AnimationController.unbounded(vsync: this)
      ..addListener(_syncHeaderPullFromController);
    _headerSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 260),
    );
    widget.budgetEditorActiveKey?.addListener(_syncBudgetEditorActiveKey);
    widget.store.start();
  }

  @override
  void didUpdateWidget(covariant TransactionHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgetEditorActiveKey != widget.budgetEditorActiveKey) {
      oldWidget.budgetEditorActiveKey?.removeListener(
        _syncBudgetEditorActiveKey,
      );
      widget.budgetEditorActiveKey?.addListener(_syncBudgetEditorActiveKey);
      _syncBudgetEditorActiveKey();
    }
  }

  @override
  void dispose() {
    widget.budgetEditorActiveKey?.removeListener(_syncBudgetEditorActiveKey);
    _fastInfoExtent.dispose();
    _headerPullController.dispose();
    _headerSlideController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final expenseTheme =
        widget.expenseTheme ??
        ExpenseTheme.fromSettings(AppThemeSettings.defaults());
    _logThemeSurfaceOnce(expenseTheme);
    return ColoredBox(
      color: expenseTheme.appBackground,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final homeBuildStartedAt = DateTime.now();
          if (widget.store.loading) {
            return Center(
              child: CircularProgressIndicator(color: expenseTheme.accent),
            );
          }
          if (widget.store.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.store.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.expense),
                ),
              ),
            );
          }

          final fastInfoMetrics = widget.store.fastInfoMetrics;
          final visibleTransactions = widget.store.visibleTransactions;
          final visibleGhostTransactions =
              widget.store.visibleGhostTransactions;
          final visibleLogEntries = widget.store.visibleDisplayLogEntries;
          final categoryMenuIsSlide =
              expenseTheme.settings.categoryMenuPresentation ==
              CategoryMenuPresentation.slideUpSheet;
          _logHomeBuildFrame(
            startedAt: homeBuildStartedAt,
            entryCount: visibleLogEntries.length,
            visibleTransactionCount: visibleTransactions.length,
            visibleGhostCount: visibleGhostTransactions.length,
          );
          _notifyBlockingOverlay(
            _categoryEditorOpen ||
                (_categoryMode != null && categoryMenuIsSlide) ||
                (_budgetEditorItem != null &&
                    widget.onBudgetTargetEditorRequested == null),
          );

          final budgetHostItem = widget.onBudgetTargetEditorRequested == null
              ? _budgetEditorItem ?? _defaultBudgetEditorItem()
              : null;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  const SizedBox(height: TransactionHeaderMetrics.contentTop),
                  TransactionTypePills(
                    activeType: widget.store.activeType,
                    surfaceColor: expenseTheme.logBox,
                    surfaceStyle: expenseTheme.buttonSurfaceStyle,
                    accentColor: expenseTheme.accent,
                    shadowEnabled:
                        expenseTheme.settings.headerPillShadowEnabled,
                    onChanged: _setActiveType,
                  ),
                  SummaryPill(
                    title: widget.store.activeSummaryTitle,
                    value: widget.store.activeSummary.formattedFor(
                      widget.store.activeType,
                    ),
                    surfaceColor: expenseTheme.logBox,
                    surfaceStyle: expenseTheme.contentSurfaceStyle,
                    shadowEnabled:
                        expenseTheme.settings.summaryPillShadowEnabled,
                    onIntervalSwipe: () {
                      widget.store.cycleSummaryWindow();
                    },
                    onPeriodSwipe: (direction) {
                      widget.store.shiftSummaryPeriod(direction);
                    },
                    onResetToCurrentMonth: () {
                      widget.store.resetSummaryToCurrentMonth();
                    },
                  ),
                  SearchPill(
                    query: widget.store.searchQuery,
                    onQueryChanged: widget.store.setSearchQuery,
                    surfaceColor: expenseTheme.logBox,
                    surfaceStyle: expenseTheme.contentSurfaceStyle,
                    merchantFilter: widget.store.merchantFilter,
                    categoryFilter: widget.store.activeCategory?.name,
                    categoryFilterColor: widget.store.activeCategory?.slotColor,
                    accentColor: expenseTheme.accent,
                    shadowEnabled:
                        expenseTheme.settings.searchPillShadowEnabled,
                    filteredCount: visibleTransactions.length,
                    onClearMerchant: widget.store.clearMerchantFilter,
                    onClearCategory: widget.store.clearCategoryFilter,
                  ),
                  Expanded(
                    child: TransactionLogList(
                      entries: visibleLogEntries,
                      records: visibleTransactions,
                      ghostRecords: visibleGhostTransactions,
                      categories: widget.store.categories,
                      categoriesById: widget.store.categoriesById,
                      surfaceColor: expenseTheme.logBox,
                      surfaceStyle: expenseTheme.contentSurfaceStyle,
                      avatarSurfaceStyle: expenseTheme.buttonSurfaceStyle,
                      ghostSurfaceStyle: expenseTheme.ghostLogboxSurfaceStyle,
                      shadowEnabled: expenseTheme.settings.logboxShadowEnabled,
                      ghostLogboxSettings:
                          expenseTheme.settings.ghostLogboxSettings,
                      onFastFilter: _setMerchantFastFilter,
                      onRecordTap: _editTransaction,
                      onDeleteRequested: _requestDeleteTransaction,
                      onCategoryFilter: widget.store.setCategoryFilter,
                      onRenameMerchant: _renameTransactionsByMerchant,
                      onResetMerchantName: _resetTransactionNamesByMerchant,
                      hasMore: widget.store.hasMoreVisibleDisplayLogEntries,
                      onLoadMore: widget.store.loadMoreVisibleDisplayLogEntries,
                    ),
                  ),
                ],
              ),
              if (_categoryMode != null && !categoryMenuIsSlide)
                CategoryMenuOverlay(
                  store: widget.store,
                  onClose: _closeCategoryMenu,
                  onAdd: _openAddCategory,
                  onModify: _openModifyCategory,
                  onSelect: _selectCategory,
                  onDelete: _deleteCategory,
                  surfaceColor: expenseTheme.categoryMenu,
                  menuSurfaceStyle: expenseTheme.categoryMenuSurfaceStyle,
                  cardSurfaceColor: expenseTheme.categoryCard,
                  cardSurfaceStyle: expenseTheme.categoryCardSurfaceStyle,
                  avatarSurfaceStyle: expenseTheme.buttonSurfaceStyle,
                  accentColor: expenseTheme.accent,
                  activeBackgroundColor: expenseTheme.activeBackground,
                  cardShadowEnabled:
                      expenseTheme.settings.categoryCardShadowEnabled,
                ),
              if (_categoryMode != null && categoryMenuIsSlide)
                Positioned.fill(
                  child: SlideUpMenuCard(
                    cardKey: const ValueKey('category-menu-slide-card'),
                    debugLabel: 'CategoryMenu',
                    panelHeight: _menuPanelHeight(context),
                    onDismissed: _closeCategoryMenu,
                    dismissOnVeilTap: false,
                    dragFromHandleOnly: true,
                    dragHandleExtent: 72,
                    verticalDragBias: 1.2,
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: ColoredBox(
                        color: expenseTheme.categoryMenu,
                        child: CategoryMenuPanel(
                          key: const ValueKey('category-picker-panel'),
                          activeType: widget.store.activeType,
                          categories: widget.store.categories,
                          categoryTransactionCounts:
                              widget.store.categoryTransactionCounts,
                          activeCategory: widget.store.activeCategory,
                          onSelect: _selectCategory,
                          onModify: _openModifyCategory,
                          onDelete: _deleteCategory,
                          onAdd: _openAddCategory,
                          onClose: _closeCategoryMenu,
                          surfaceColor: expenseTheme.categoryMenu,
                          cardSurfaceColor: expenseTheme.categoryCard,
                          cardSurfaceStyle:
                              expenseTheme.categoryCardSurfaceStyle,
                          avatarSurfaceStyle: expenseTheme.buttonSurfaceStyle,
                          accentColor: expenseTheme.accent,
                          activeBackgroundColor: expenseTheme.activeBackground,
                          addButtonPlacement:
                              CategoryMenuAddButtonPlacement.bottomPill,
                          cardShadowEnabled:
                              expenseTheme.settings.categoryCardShadowEnabled,
                        ),
                      ),
                    ),
                  ),
                ),
              AnimatedBuilder(
                animation: _headerSlideController,
                child: RepaintBoundary(
                  child: CategoryBudgetStage(
                    backheaderStyle: expenseTheme.settings.backheaderStyle,
                    backgroundColor: expenseTheme.appBackground,
                    items: widget.store.backheaderBudgetItems,
                    categoryBars: widget.store.categoryBudgetBars,
                    overviewItems: widget.store.overviewBudgetItems,
                    periodIncome: widget.store.activePeriodIncomeTotal,
                    periodLabel: widget.store.activePeriodLabel,
                    activeKey: _backheaderActiveKey,
                    surfaceStyle: expenseTheme.buttonSurfaceStyle,
                    onActiveItemChanged: _setBackheaderActiveItem,
                    onItemTap: _openBudgetTargetEditor,
                    onJumpToIncome: () =>
                        _setActiveType(TransactionType.income),
                    onSaveOverview:
                        (
                          kind, {
                          required limitAmount,
                          required alertActive,
                        }) async {
                          await widget.store.saveOverviewLimit(
                            kind,
                            limitAmount: limitAmount,
                            alertActive: alertActive,
                          );
                        },
                    onSaveCategory:
                        (
                          bar, {
                          required limitAmount,
                          required alertActive,
                        }) async {
                          await widget.store.saveCategoryLimitForBar(
                            bar,
                            limitAmount: limitAmount,
                            alertActive: alertActive,
                          );
                        },
                  ),
                ),
                builder: (context, budgetStage) {
                  final rawHeaderSlideProgress = _headerSlideController.value;
                  final headerSlideProgress = _headerSlideVisualProgress();
                  final showBackheader =
                      _headerExpanded || rawHeaderSlideProgress > 0.001;
                  if (showBackheader) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        budgetStage!,
                        _buildHeaderCard(
                          expenseTheme: expenseTheme,
                          visibleFastInfoExtent: 0,
                          slideProgress: headerSlideProgress,
                          contentOpacity: _headerContentOpacity(
                            headerSlideProgress,
                          ),
                        ),
                      ],
                    );
                  }
                  return ValueListenableBuilder<double>(
                    key: const ValueKey('header-fast-info-extent-builder'),
                    valueListenable: _fastInfoExtent,
                    builder: (context, fastInfoExtent, _) {
                      final visibleFastInfoExtent = fastInfoExtent
                          .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
                          .toDouble();
                      return HeaderFastInfoSurface(
                        visibleFastInfoExtent: visibleFastInfoExtent,
                        cardColor: expenseTheme.headerCard,
                        surfaceStyle: expenseTheme.contentSurfaceStyle,
                        fastInfo: FastInfoPanel(
                          config:
                              widget.fastInfoConfig ??
                              FastInfoConfig.defaults(),
                          backgroundColor: Colors.transparent,
                          metrics: fastInfoMetrics,
                        ),
                        header: _buildHeaderCard(
                          expenseTheme: expenseTheme,
                          visibleFastInfoExtent: visibleFastInfoExtent,
                          drawSurface: false,
                        ),
                      );
                    },
                  );
                },
              ),
              if (_categoryEditorOpen)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CategoryEditorSheet(
                    activeType: widget.store.activeType,
                    initialCategory: _editingCategory,
                    panelHeight: _menuPanelHeight(context),
                    onClose: _closeCategoryEditor,
                    onSave: (draft) => _saveCategory(draft, _editingCategory),
                    onDelete: _editingCategory == null
                        ? null
                        : (category) => _deleteCategory(category),
                    surfaceColor: expenseTheme.fieldSurface,
                    bodySurfaceStyle: expenseTheme.contentSurfaceStyle,
                    buttonSurfaceStyle: expenseTheme.buttonSurfaceStyle,
                    selectedSurfaceStyle: expenseTheme.forcedInsetSurfaceStyle,
                    accentColor: expenseTheme.accent,
                  ),
                ),
              if (budgetHostItem != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BudgetTargetEditorSheet(
                    item: budgetHostItem,
                    openRequestedAt: _budgetEditorOpenRequestedAt,
                    visible: _budgetEditorItem != null,
                    periodLabel: widget.store.activePeriodLabel,
                    items: widget.store.backheaderBudgetItems,
                    categoryBars: widget.store.categoryBudgetBars,
                    overviewItems: widget.store.overviewBudgetItems,
                    periodIncome: widget.store.activePeriodIncomeTotal,
                    expenseTheme: expenseTheme,
                    onCancel: _closeBudgetTargetEditor,
                    onActiveItemChanged: _setBackheaderActiveItem,
                    onSaveOverview:
                        (
                          kind, {
                          required limitAmount,
                          required alertActive,
                        }) async {
                          await widget.store.saveOverviewLimit(
                            kind,
                            limitAmount: limitAmount,
                            alertActive: alertActive,
                          );
                        },
                    onSaveCategory:
                        (
                          bar, {
                          required limitAmount,
                          required alertActive,
                        }) async {
                          await widget.store.saveCategoryLimitForBar(
                            bar,
                            limitAmount: limitAmount,
                            alertActive: alertActive,
                          );
                        },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _logThemeSurfaceOnce(ExpenseTheme expenseTheme) {
    final signature =
        'typePills=${expenseTheme.buttonSurfaceStyle.nativeValue} '
        'headerButtons=${expenseTheme.buttonSurfaceStyle.nativeValue} '
        'summary=${expenseTheme.contentSurfaceStyle.nativeValue} '
        'search=${expenseTheme.contentSurfaceStyle.nativeValue} '
        'log=${expenseTheme.contentSurfaceStyle.nativeValue} '
        'headerSurface=${expenseTheme.contentSurfaceStyle.nativeValue} '
        'bg=${_hex(expenseTheme.appBackground)} '
        'header=${_hex(expenseTheme.headerCard)} '
        'logBox=${_hex(expenseTheme.logBox)}';
    if (_lastThemeSurfaceLogSignature == signature) return;
    _lastThemeSurfaceLogSignature = signature;
    DebugConsole.log('[ThemeSurface] home fanout $signature');
  }

  String _hex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
  }

  void _logHomeBuildFrame({
    required DateTime startedAt,
    required int entryCount,
    required int visibleTransactionCount,
    required int visibleGhostCount,
  }) {
    final overlayOpen =
        _categoryMode != null ||
        _categoryEditorOpen ||
        _budgetEditorItem != null;
    final shouldLogState =
        _lastHomeBuildEntriesLogged != entryCount ||
        _lastHomeBuildOverlayLogged != overlayOpen ||
        _lastHomeBuildHeaderExpandedLogged != _headerExpanded;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final elapsed = _elapsedMs(startedAt);
      final shouldLog = shouldLogState || elapsed > 32;
      if (!shouldLog) return;
      _lastHomeBuildEntriesLogged = entryCount;
      _lastHomeBuildOverlayLogged = overlayOpen;
      _lastHomeBuildHeaderExpandedLogged = _headerExpanded;
      DebugConsole.log(
        '[Perf] HomeBuild frame entries=$entryCount '
        'records=$visibleTransactionCount ghosts=$visibleGhostCount '
        'headerExpanded=$_headerExpanded overlay=$overlayOpen '
        'elapsed=${elapsed}ms jank=${elapsed > 32}',
      );
    });
  }

  void _syncBudgetEditorActiveKey() {
    if (!mounted) return;
    final nextKey = widget.budgetEditorActiveKey?.value;
    if (_backheaderActiveKey == nextKey) return;
    setState(() => _backheaderActiveKey = nextKey);
  }

  void _syncHeaderPullFromController() {
    final rawNext = _headerPullController.value
        .clamp(-12.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    final next = rawNext.abs() < 0.5 ? 0.0 : rawNext;
    if ((next - _fastInfoExtent.value).abs() < 0.01) return;
    _fastInfoExtent.value = next;
  }

  void _toggleHeaderExpanded() {
    _headerPullController.stop();
    _headerPullController.value = 0;
    if (_headerExpanded) {
      unawaited(_collapseHeader());
      return;
    }
    unawaited(_expandHeader());
  }

  Future<void> _expandHeader() async {
    final startedAt = DateTime.now();
    final entryCount = widget.store.visibleDisplayLogEntries.length;
    final transactionCount = widget.store.transactions.length;
    DebugConsole.log(
      '[HeaderCard] expand requested progress=${_headerSlideController.value.toStringAsFixed(2)} '
      'entries=$entryCount transactions=$transactionCount',
    );
    _headerSlideController.stop();
    _fastInfoExtent.value = 0;
    setState(() {
      _headerExpanded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '[HeaderCard] expand first frame elapsed=${_elapsedMs(startedAt)}ms '
        'progress=${_headerSlideController.value.toStringAsFixed(2)}',
      );
    });
    DebugConsole.log(
      '[HeaderCard] expand start progress=${_headerSlideController.value.toStringAsFixed(2)}',
    );
    await _headerSlideController.forward();
    if (!mounted) return;
    DebugConsole.log(
      '[HeaderCard] expand complete elapsed=${_elapsedMs(startedAt)}ms',
    );
  }

  Future<void> _collapseHeader() async {
    final startedAt = DateTime.now();
    final entryCount = widget.store.visibleDisplayLogEntries.length;
    final transactionCount = widget.store.transactions.length;
    DebugConsole.log(
      '[HeaderCard] collapse requested progress=${_headerSlideController.value.toStringAsFixed(2)} '
      'entries=$entryCount transactions=$transactionCount',
    );
    _headerSlideController.stop();
    _fastInfoExtent.value = 0;
    setState(() {
      _headerExpanded = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '[HeaderCard] collapse first frame elapsed=${_elapsedMs(startedAt)}ms '
        'progress=${_headerSlideController.value.toStringAsFixed(2)}',
      );
    });
    DebugConsole.log(
      '[HeaderCard] collapse start progress=${_headerSlideController.value.toStringAsFixed(2)}',
    );
    await _headerSlideController.reverse();
    if (!mounted) return;
    DebugConsole.log(
      '[HeaderCard] collapse complete elapsed=${_elapsedMs(startedAt)}ms',
    );
  }

  double _menuPanelHeight(BuildContext context) {
    return SlideUpPanelMetrics.fullHeight(context);
  }

  void _notifyBlockingOverlay(bool active) {
    if (_blockingOverlayNotified == active) return;
    _blockingOverlayNotified = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onBlockingOverlayChanged?.call(active);
    });
  }

  Widget _buildHeaderCard({
    required ExpenseTheme expenseTheme,
    required double visibleFastInfoExtent,
    bool drawSurface = true,
    double? slideProgress,
    double? contentOpacity,
  }) {
    return RepaintBoundary(
      child: TransactionHeaderCard(
        balanceText: widget.store.totalBalanceText,
        expanded: _headerExpanded,
        magnetType: expenseTheme.settings.magnetType,
        accent: expenseTheme.accent,
        cardColor: expenseTheme.headerCard,
        surfaceStyle: expenseTheme.contentSurfaceStyle,
        buttonSurfaceStyle: expenseTheme.buttonSurfaceStyle,
        totalIncome: widget.store.activePeriodIncomeTotal,
        totalExpense: widget.store.activePeriodExpenseTotal,
        budgetProgress: _headerBudgetProgress(),
        fastInfoVisible: visibleFastInfoExtent > 0,
        balanceHidden: _balanceHidden,
        drawSurface: drawSurface,
        dragHandleHitTestEnabled:
            !(_headerExpanded &&
                expenseTheme.settings.backheaderStyle ==
                    BackheaderStyle.orbitBudget),
        slideProgress: slideProgress,
        contentOpacity: contentOpacity,
        onBalanceVisibilityPressed: () {
          setState(() => _balanceHidden = !_balanceHidden);
        },
        onCategoryPressed: _openCategoryMenu,
        onVerticalDragUpdate: _handleHeaderDragUpdate,
        onVerticalDragEnd: _handleHeaderDragEnd,
        onExpandPressed: _toggleHeaderExpanded,
      ),
    );
  }

  double _headerContentOpacity(double slideProgress) {
    const fadeStart = 0.94;
    if (slideProgress <= fadeStart) return 1;
    final fadeProgress = ((slideProgress - fadeStart) / (1 - fadeStart))
        .clamp(0.0, 1.0)
        .toDouble();
    return 1 - fadeProgress;
  }

  BudgetStripProgress? _headerBudgetProgress() {
    final item = _activeBackheaderItem();
    if (item == null) return null;
    final overview = item.overview;
    if (overview != null) {
      return BudgetStripProgress(
        hasLimit: overview.hasLimit,
        spent: overview.amount,
        limitAmount: overview.limitAmount,
      );
    }
    final category = item.category!;
    return BudgetStripProgress(
      hasLimit: category.hasLimit,
      spent: category.spent,
      limitAmount: category.limitAmount,
    );
  }

  BackheaderBudgetItem? _activeBackheaderItem() {
    final items = widget.store.backheaderBudgetItems;
    if (items.isEmpty) return null;
    final activeKey = _backheaderActiveKey;
    if (activeKey != null) {
      for (final item in items) {
        if (item.key == activeKey) return item;
      }
    }
    return items.first;
  }

  double _headerSlideVisualProgress() {
    final raw = _headerSlideController.value.clamp(0.0, 1.0).toDouble();
    if (_headerSlideController.status == AnimationStatus.reverse) {
      return 1 - Curves.easeOutCubic.transform(1 - raw);
    }
    return Curves.easeOutCubic.transform(raw);
  }

  void _handleHeaderDragUpdate(DragUpdateDetails details) {
    if (_headerExpanded || _categoryEditorOpen) {
      return;
    }
    _headerPullController.stop();
    final resistedDelta = details.delta.dy > 0
        ? details.delta.dy * 0.85
        : details.delta.dy;
    final current = _fastInfoExtent.value;
    final next = (current + resistedDelta)
        .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    if (next == current) return;
    _headerPullController.value = next;
  }

  void _handleHeaderDragEnd(DragEndDetails details) {
    if (_headerExpanded) return;
    final start = _fastInfoExtent.value
        .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    if (start == 0) {
      _headerPullController.value = 0;
      return;
    }
    _headerPullController.value = start;
    final releaseVelocity = details.velocity.pixelsPerSecond.dy;
    final closingVelocity = releaseVelocity < 0 ? releaseVelocity : 0.0;
    final spring = _headerPullController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 0.75, stiffness: 620, damping: 16),
        start,
        0,
        closingVelocity,
      ),
    );
    unawaited(
      spring.orCancel
          .then<void>((_) {
            if (!mounted) return;
            _headerPullController.value = 0;
            if (_fastInfoExtent.value == 0) return;
            _fastInfoExtent.value = 0;
          })
          .catchError((_) {}),
    );
  }

  void _setActiveType(TransactionType type) {
    _headerPullController.stop();
    _headerPullController.value = 0;
    widget.store.setActiveType(type);
    widget.onBudgetTargetEditorClosed?.call();
    widget.onFocusedSheetDismissRequested?.call();
    _fastInfoExtent.value = 0;
    setState(() {
      if (_categoryEditorOpen) {
        _categoryEditorOpen = false;
        _editingCategory = null;
      }
      _budgetEditorItem = null;
    });
  }

  void _setMerchantFastFilter(
    TransactionRecord record,
    TransactionCategory? category,
  ) {
    widget.store.setMerchantFilter(record.displayMerchant);
  }

  Future<void> _renameTransactionsByMerchant(
    TransactionRecord transaction,
    String userAssignedName,
  ) async {
    await widget.store.renameTransactionsByMerchant(
      transaction,
      userAssignedName,
    );
  }

  Future<void> _resetTransactionNamesByMerchant(
    TransactionRecord transaction,
  ) async {
    await widget.store.resetTransactionNamesByMerchant(transaction);
  }

  void _editTransaction(TransactionRecord record) {
    widget.onEditTransaction?.call(record);
  }

  FutureOr<bool> _requestDeleteTransaction(TransactionRecord record) {
    return widget.onDeleteTransactionRequested?.call(record) ?? false;
  }

  void _setBackheaderActiveItem(BackheaderBudgetItem item) {
    widget.budgetEditorActiveKey?.value = item.key;
    if (!mounted || _backheaderActiveKey == item.key) return;
    setState(() => _backheaderActiveKey = item.key);
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  BackheaderBudgetItem? _defaultBudgetEditorItem() {
    final items = widget.store.backheaderBudgetItems;
    if (items.isEmpty) return null;
    for (final item in items) {
      if (item.overview != null) return item;
    }
    return items.first;
  }

  void _openBudgetTargetEditor(BackheaderBudgetItem item) {
    final requestedAt = DateTime.now();
    DebugConsole.log(
      '[BudgetTargetEditor] open from backheader key=${item.key} '
      'headerExpanded=$_headerExpanded',
    );
    if (widget.onBudgetTargetEditorRequested != null) {
      widget.onBudgetTargetEditorRequested!(
        item,
        requestedAt: requestedAt,
        headerExpanded: _headerExpanded,
      );
      return;
    }
    setState(() {
      _backheaderActiveKey = item.key;
      _budgetEditorOpenRequestedAt = requestedAt;
      _budgetEditorItem = item;
    });
    DebugConsole.log(
      '[BudgetTargetEditor] backheader state queued '
      'elapsed=${_elapsedMs(requestedAt)}ms',
    );
  }

  void _closeBudgetTargetEditor() {
    setState(() {
      _budgetEditorItem = null;
      _budgetEditorOpenRequestedAt = null;
    });
  }

  void _openCategoryMenu() {
    final requestedAt = DateTime.now();
    final closing =
        _categoryMode != null ||
        _categoryEditorOpen ||
        _budgetEditorItem != null;
    DebugConsole.log(
      '[CategoryMenu] ${closing ? 'close' : 'open'} requested '
      'entries=${widget.store.visibleDisplayLogEntries.length} '
      'categories=${widget.store.categories.length} headerExpanded=$_headerExpanded',
    );
    _headerPullController.stop();
    _headerPullController.value = 0;
    widget.onBudgetTargetEditorClosed?.call();
    setState(() {
      if (closing) {
        _categoryMode = null;
        _categoryEditorOpen = false;
        _budgetEditorItem = null;
        _editingCategory = null;
        return;
      }
      _headerExpanded = false;
      _fastInfoExtent.value = 0;
      _categoryMode = CategoryOverlayMode.picker;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '[CategoryMenu] ${closing ? 'close' : 'open'} first frame '
        'elapsed=${_elapsedMs(requestedAt)}ms mode=${_categoryMode?.name ?? 'none'}',
      );
    });
  }

  void _closeCategoryMenu() {
    setState(() {
      _categoryMode = null;
    });
  }

  void _openAddCategory() {
    final externalEditor = widget.onAddCategoryEditorRequested;
    setState(() {
      _categoryMode = CategoryOverlayMode.picker;
      _categoryEditorOpen = externalEditor == null;
      _editingCategory = null;
      _budgetEditorItem = null;
    });
    externalEditor?.call();
  }

  void _openModifyCategory(TransactionCategory category) {
    final externalEditor = widget.onEditCategoryEditorRequested;
    if (externalEditor != null) {
      externalEditor(category);
      return;
    }
    setState(() {
      _categoryMode = null;
      _categoryEditorOpen = true;
      _editingCategory = category;
    });
  }

  void _closeCategoryEditor() {
    setState(() {
      _categoryEditorOpen = false;
      _editingCategory = null;
      _categoryMode = CategoryOverlayMode.picker;
    });
  }

  void _selectCategory(TransactionCategory category) {
    widget.store.setCategoryFilter(category);
    _closeCategoryMenu();
  }

  Future<void> _saveCategory(
    CategoryDraft draft, [
    TransactionCategory? editingCategory,
  ]) async {
    final editing = editingCategory;
    if (draft.id == null || editing == null) {
      await widget.store.addCategory(
        name: draft.name,
        type: draft.type,
        colorSlot: draft.colorSlot,
        iconSlot: draft.iconSlot,
      );
    } else {
      await widget.store.updateCategory(
        editing,
        name: draft.name,
        colorSlot: draft.colorSlot,
        iconSlot: draft.iconSlot,
      );
    }
    if (!mounted) return;
    setState(() {
      _categoryEditorOpen = false;
      _editingCategory = null;
      _categoryMode = CategoryOverlayMode.picker;
    });
  }

  Future<void> _deleteCategory(TransactionCategory category) async {
    final deleted = await widget.store.deleteCategory(category);
    if (!mounted || !deleted) return;
    setState(() {
      _categoryEditorOpen = false;
      _editingCategory = null;
      _categoryMode = CategoryOverlayMode.picker;
    });
  }
}
