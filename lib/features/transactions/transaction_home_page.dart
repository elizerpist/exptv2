import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/debug/debug_console.dart';
import '../../core/keyboard/keyboard_inset_follower.dart';
import '../../core/theme/app_colors.dart';
import '../settings/models/app_theme_settings.dart';
import '../settings/theme/expense_theme.dart';
import '../settings/models/fast_info_config.dart';
import '../settings/widgets/options/backheader_style_options_panel.dart';
import '../../services/native_bridge.dart';
import 'data/limit_allocation_manager.dart';
import 'models/transaction_category.dart';
import 'models/transaction_record.dart';
import 'models/budget_goal_kind.dart';
import 'models/summary_window.dart';
import 'state/transaction_store.dart';
import 'widgets/category_menu/category_editor_panel.dart';
import 'widgets/category_menu/category_editor_sheet.dart';
import 'widgets/category_menu/category_card.dart';
import 'widgets/category_menu/category_icon_badge.dart';
import 'widgets/category_menu/category_menu_panel.dart';
import 'models/backheader_budget_item.dart';
import 'widgets/header_card/category_budget_stage.dart';
import 'widgets/header_card/budget_target_editor_sheet.dart';
import 'widgets/header_card/fast_info_panel.dart';
import 'widgets/header_card/header_fast_info_surface.dart';
import 'widgets/header_card/transaction_header_metrics.dart';
import 'widgets/header_card/transaction_header_card.dart';
import 'models/limit_allocation_data.dart';
import 'widgets/search_pill.dart';
import 'widgets/slide_up_menu_card.dart';
import 'widgets/summary_pill.dart';
import 'widgets/summary_scope_picker_sheet.dart';
import 'widgets/transaction_menu_metrics.dart';
import 'widgets/transaction_log_list.dart';
import 'widgets/transaction_type_pills.dart';

typedef BudgetTargetEditorRequest =
    void Function(
      BackheaderBudgetItem item, {
      required DateTime requestedAt,
      required bool headerExpanded,
    });

enum CategoryOverlayMode { picker }

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
    this.onCategoryMenuRequested,
    this.onVendorSheetRequested,
    this.onAddCategoryEditorRequested,
    this.onEditCategoryEditorRequested,
    this.onThemeSettingsChanged,
    this.onBackheaderLiveTunerRequested,
    this.onPickSummaryMonth,
    this.onNotificationPressed,
    this.notificationUnreadCount = 0,
    this.logBottomPadding = 96,
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
  final CategoryMenuSheetRequested? onCategoryMenuRequested;
  final VoidCallback? onVendorSheetRequested;
  final VoidCallback? onAddCategoryEditorRequested;
  final ValueChanged<TransactionCategory>? onEditCategoryEditorRequested;
  final ValueChanged<AppThemeSettings>? onThemeSettingsChanged;
  final VoidCallback? onBackheaderLiveTunerRequested;
  final Future<NativeYearMonthSelection?> Function(DateTime initial)?
  onPickSummaryMonth;
  final VoidCallback? onNotificationPressed;
  final int notificationUnreadCount;
  final double logBottomPadding;
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
  final _vendorListScrollController = ScrollController();
  CategoryOverlayMode? _categoryMode;
  BackheaderBudgetItem? _budgetEditorItem;
  DateTime? _budgetEditorOpenRequestedAt;
  final _budgetEditorPendingAmountsByKey = <String, double>{};
  var _categoryEditorOpen = false;
  var _vendorSheetOpen = false;
  Set<String> _pendingVendorFilters = const <String>{};
  var _backheaderLiveTunerOpen = false;
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
    _vendorListScrollController.dispose();
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
          _logHomeBuildFrame(
            startedAt: homeBuildStartedAt,
            entryCount: visibleLogEntries.length,
            visibleTransactionCount: visibleTransactions.length,
            visibleGhostCount: visibleGhostTransactions.length,
          );
          _notifyBlockingOverlay(
            _vendorSheetOpen ||
                _categoryEditorOpen ||
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
                    shadowEnabled: true,
                    onChanged: _setActiveType,
                  ),
                  SummaryPill(
                    title: widget.store.activeSummaryTitle,
                    value: widget.store.activeSummary.formattedFor(
                      widget.store.activeType,
                    ),
                    surfaceColor: expenseTheme.logBox,
                    surfaceStyle: expenseTheme.summaryPillSurfaceStyle,
                    shadowEnabled: true,
                    onTap: _pickSummaryMonth,
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
                    merchantFilters: _merchantSearchFilters(expenseTheme),
                    categoryFilters: _categorySearchFilters(),
                    accentColor: expenseTheme.accent,
                    shadowEnabled: true,
                    onVendorListPressed: _openVendorSheet,
                  ),
                  _TransactionListHeader(
                    transactionCount: visibleTransactions.length,
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
                      shadowEnabled: true,
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
                      bottomPadding: widget.logBottomPadding,
                    ),
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: _headerSlideController,
                child: RepaintBoundary(
                  child: CategoryBudgetStage(
                    backheaderStyle: expenseTheme.settings.backheaderStyle,
                    centerBackheaderDesign:
                        expenseTheme.settings.centerBackheaderDesign,
                    centerPartitionRingEnabled:
                        expenseTheme.settings.centerPartitionRingEnabled,
                    centerBadgeDiscEnabled:
                        expenseTheme.settings.centerBadgeDiscEnabled,
                    centerBadgeBorderMode:
                        expenseTheme.settings.centerBadgeBorderMode,
                    centerBadgeOverlapMaskEnabled:
                        expenseTheme.settings.centerBadgeOverlapMaskEnabled,
                    centerBadgeWhiteDiscOpacities:
                        expenseTheme.settings.centerBadgeWhiteDiscOpacities,
                    centerBadgeWhiteIconOpacities:
                        expenseTheme.settings.centerBadgeWhiteIconOpacities,
                    centerBadgeWhiteProgressOpacities:
                        expenseTheme.settings.centerBadgeWhiteProgressOpacities,
                    centerBadgeColoredFillOpacities:
                        expenseTheme.settings.centerBadgeColoredFillOpacities,
                    centerBadgeColoredIconOpacities:
                        expenseTheme.settings.centerBadgeColoredIconOpacities,
                    centerBadgeColoredProgressOpacities: expenseTheme
                        .settings
                        .centerBadgeColoredProgressOpacities,
                    centerBadgeSlotSizePercents:
                        expenseTheme.settings.centerBadgeSlotSizePercents,
                    centerBadgeSlotXOffsets:
                        expenseTheme.settings.centerBadgeSlotXOffsets,
                    centerBadgeColoredBackgroundOpacity: expenseTheme
                        .settings
                        .centerBadgeColoredBackgroundOpacity,
                    backgroundColor: expenseTheme.appBackground,
                    items: widget.store.backheaderBudgetItems,
                    categoryBars: widget.store.categoryBudgetBars,
                    overviewItems: widget.store.overviewBudgetItems,
                    pendingAmountsByKey: _budgetEditorPendingAmountsByKey,
                    periodIncome: widget.store.activePeriodIncomeTotal,
                    periodLabel: widget.store.activePeriodLabel,
                    activeKey: _backheaderActiveKey,
                    surfaceStyle: expenseTheme.buttonSurfaceStyle,
                    onActiveItemChanged: _setBackheaderActiveItem,
                    onItemTap: _openBudgetTargetEditor,
                    onCenterBackgroundTap: _openBackheaderLiveTuner,
                    onOrbitCloseRequested: () {
                      if (_headerExpanded) unawaited(_collapseHeader());
                    },
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
                        ambulanceSkin:
                            expenseTheme.settings.magnetType ==
                            MagnetType.ambulanceSkin,
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
              if (_categoryMode != null)
                Positioned.fill(
                  child: SlideUpMenuCard(
                    cardKey: const ValueKey('category-menu-slide-card'),
                    debugLabel: 'CategoryMenu',
                    panelHeight: _menuPanelHeight(context),
                    onDismissed: _closeCategoryMenu,
                    dismissOnVeilTap: true,
                    focusVeilPassthroughTop: 0,
                    dragFromHandleOnly: true,
                    dragHandleExtent: 72,
                    verticalDragBias: 1.2,
                    keyboardAvoidance: false,
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: CategoryMenuPanel(
                        key: const ValueKey('category-picker-panel'),
                        activeType: widget.store.activeType,
                        categories: widget.store.categories,
                        categoryTransactionCounts:
                            widget.store.categoryTransactionCounts,
                        activeCategory: widget.store.activeCategory,
                        selectedCategoryIds: widget.store.activeCategoryIds,
                        onSelect: _selectCategory,
                        onApply: _applyCategoryFilters,
                        onModify: _openModifyCategory,
                        onDelete: _deleteCategory,
                        onAdd: _openAddCategory,
                        onClose: _closeCategoryMenu,
                        surfaceColor: expenseTheme.categoryMenu,
                        cardSurfaceColor: expenseTheme.categoryCard,
                        cardSurfaceStyle: expenseTheme.categoryCardSurfaceStyle,
                        avatarSurfaceStyle: expenseTheme.buttonSurfaceStyle,
                        accentColor: expenseTheme.accent,
                        addButtonPlacement: CategoryMenuAddButtonPlacement.card,
                      ),
                    ),
                  ),
                ),
              if (_vendorSheetOpen)
                Positioned.fill(
                  child: SlideUpMenuCard(
                    cardKey: const ValueKey('vendor-filter-slide-card'),
                    debugLabel: 'VendorFilter',
                    panelHeight: _menuPanelHeight(context),
                    onDismissed: _closeVendorSheet,
                    dismissOnVeilTap: true,
                    focusVeilPassthroughTop: 0,
                    canDragFrom: _canDragVendorSheet,
                    dragFromHandleOnly: true,
                    dragHandleExtent: 72,
                    verticalDragBias: 1.2,
                    keyboardAvoidance: false,
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: VendorFilterPanel(
                        summaries: widget.store.vendorFilterSummaries,
                        selectedVendors: _pendingVendorFilters,
                        activeType: widget.store.activeType,
                        scrollController: _vendorListScrollController,
                        accentColor: expenseTheme.accent,
                        cardSurfaceColor: expenseTheme.categoryCard,
                        cardSurfaceStyle: expenseTheme.categoryCardSurfaceStyle,
                        avatarSurfaceStyle: expenseTheme.buttonSurfaceStyle,
                        buttonSurfaceStyle: expenseTheme.buttonSurfaceStyle,
                        onToggle: _togglePendingVendorFilter,
                        onRename: _renameVendorFilterSummary,
                        onResetName: _resetVendorFilterSummary,
                        onApply: _applyVendorFilters,
                      ),
                    ),
                  ),
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
              if (_backheaderLiveTunerOpen)
                Positioned.fill(
                  child: SlideUpMenuCard(
                    cardKey: const ValueKey('backheader-live-tuner-slide-card'),
                    debugLabel: 'BackheaderLiveTuner',
                    panelHeight: _backheaderTunerPanelHeight(context),
                    showFocusVeil: false,
                    dismissOnVeilTap: false,
                    dragFromHandleOnly: true,
                    dragHandleExtent: 72,
                    verticalDragBias: 1.2,
                    onDismissed: _closeBackheaderLiveTuner,
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: ColoredBox(
                        key: const ValueKey('backheader-live-tuner-panel'),
                        color: expenseTheme.fieldSurface,
                        child: BackheaderStyleOptionsPanel(
                          settings: expenseTheme.settings,
                          onChanged: _updateBackheaderLiveThemeSettings,
                        ),
                      ),
                    ),
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
                    onPendingAmountChanged: _setBudgetEditorPendingAmount,
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight - TransactionMenuMetrics.overlayTop)
        .clamp(0.0, screenHeight)
        .toDouble();
  }

  double _backheaderTunerPanelHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight - TransactionMenuMetrics.overlayTop)
        .clamp(0.0, screenHeight)
        .toDouble();
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
        backheaderStyle: expenseTheme.settings.backheaderStyle,
        accent: expenseTheme.accent,
        cardColor: expenseTheme.headerCard,
        surfaceStyle: expenseTheme.contentSurfaceStyle,
        buttonSurfaceStyle: expenseTheme.buttonSurfaceStyle,
        totalIncome: widget.store.totalIncomeAmount,
        totalExpense: widget.store.totalExpenseAmount,
        budgetAllocation: _headerBudgetAllocation(),
        fastInfoVisible: visibleFastInfoExtent > 0,
        balanceHidden: _balanceHidden,
        drawSurface: drawSurface,
        slideProgress: slideProgress,
        contentOpacity: contentOpacity,
        onBalanceVisibilityPressed: () {
          setState(() => _balanceHidden = !_balanceHidden);
        },
        onCategoryPressed: _openCategoryMenu,
        onNotificationPressed: widget.onNotificationPressed,
        notificationUnreadCount: widget.notificationUnreadCount,
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

  LimitAllocationData? _headerBudgetAllocation() {
    for (final overview in widget.store.overviewBudgetItems) {
      if (overview.kind != BudgetGoalKind.expenseBudget ||
          !overview.hasLimit ||
          overview.limitAmount <= 0) {
        continue;
      }
      return LimitAllocationManager.build(
        overviewLimit: overview.limitAmount,
        bars: widget.store.categoryBudgetBars,
      );
    }
    return null;
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
    final stopwatch = Stopwatch()..start();
    DebugConsole.log(
      '[Perf] Home type switch start target=${type.name} '
      'current=${widget.store.activeType.name}',
    );
    _headerPullController.stop();
    _headerPullController.value = 0;
    widget.store.setActiveType(type);
    DebugConsole.log(
      '[Perf] Home type switch state target=${type.name} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
    widget.onBudgetTargetEditorClosed?.call();
    widget.onFocusedSheetDismissRequested?.call();
    _fastInfoExtent.value = 0;
    setState(() {
      if (_categoryEditorOpen) {
        _categoryEditorOpen = false;
        _editingCategory = null;
      }
      _backheaderLiveTunerOpen = false;
      _budgetEditorItem = null;
    });
    _logFirstFrameAfterInteraction(reason: 'type-switch', stopwatch: stopwatch);
  }

  void _setMerchantFastFilter(
    TransactionRecord record,
    TransactionCategory? category,
  ) {
    final stopwatch = Stopwatch()..start();
    DebugConsole.log(
      '[Perf] FastFilter start merchant=${record.displayMerchant} '
      'category=${category?.name ?? 'none'}',
    );
    widget.store.setMerchantFilter(record.displayMerchant);
    DebugConsole.log(
      '[Perf] FastFilter state merchant=${record.displayMerchant} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
    _logFirstFrameAfterInteraction(reason: 'fastfilter', stopwatch: stopwatch);
  }

  void _logFirstFrameAfterInteraction({
    required String reason,
    required Stopwatch stopwatch,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final visibleTransactions = widget.store.visibleTransactions.length;
      final visibleGhosts = widget.store.visibleGhostTransactions.length;
      final visibleEntries = widget.store.visibleDisplayLogEntries.length;
      final elapsed = stopwatch.elapsedMilliseconds;
      DebugConsole.log(
        '[Perf] Home first frame reason=$reason '
        'type=${widget.store.activeType.name} '
        'visibleTransactions=$visibleTransactions '
        'visibleGhosts=$visibleGhosts entries=$visibleEntries '
        'elapsed=${elapsed}ms frameBudget=16ms jank=${elapsed > 48}',
      );
    });
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

  void _clearKeyboardDebug(String label) {
    DebugConsole.clear();
    DebugConsole.log('[KeyboardFlow] $label debug cleared');
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
    if (_backheaderLiveTunerOpen) {
      setState(() => _backheaderLiveTunerOpen = false);
    }
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
      _budgetEditorPendingAmountsByKey.clear();
    });
  }

  void _openBackheaderLiveTuner() {
    final settings =
        widget.expenseTheme?.settings ?? AppThemeSettings.defaults();
    if (!_headerExpanded ||
        settings.backheaderStyle != BackheaderStyle.centerBadgeBudget) {
      return;
    }
    if (widget.onBackheaderLiveTunerRequested != null) {
      DebugConsole.log('[BackheaderTuner] request shell host from background');
      widget.onBackheaderLiveTunerRequested!();
      return;
    }
    if (_backheaderLiveTunerOpen) return;
    setState(() => _backheaderLiveTunerOpen = true);
    DebugConsole.log('[BackheaderTuner] open from backheader background');
  }

  void _closeBackheaderLiveTuner() {
    if (!_backheaderLiveTunerOpen) return;
    setState(() => _backheaderLiveTunerOpen = false);
    DebugConsole.log('[BackheaderTuner] closed');
  }

  void _updateBackheaderLiveThemeSettings(AppThemeSettings settings) {
    widget.onThemeSettingsChanged?.call(settings);
  }

  void _setBudgetEditorPendingAmount(BackheaderBudgetItem item, double amount) {
    if (!mounted) return;
    final normalized = amount < 0 ? 0.0 : amount;
    final current = _budgetEditorPendingAmountsByKey[item.key];
    if (current != null && (current - normalized).abs() < 0.01) return;
    setState(() {
      _budgetEditorPendingAmountsByKey[item.key] = normalized;
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
    final externalPicker = widget.onCategoryMenuRequested;
    if (externalPicker != null) {
      setState(() {
        _headerExpanded = false;
        _fastInfoExtent.value = 0;
        _categoryMode = null;
        _categoryEditorOpen = false;
        _budgetEditorItem = null;
        _editingCategory = null;
      });
      externalPicker(
        CategoryMenuSheetRequest(
          cardKey: const ValueKey('category-menu-slide-card'),
          panelKey: const ValueKey('category-picker-panel'),
          debugLabel: 'CategoryMenu',
          topOffset: TransactionMenuMetrics.overlayTop,
          activeType: widget.store.activeType,
          activeCategory: widget.store.activeCategory,
          selectedCategoryIds: widget.store.activeCategoryIds,
          onSelect: _selectCategory,
          onApply: _applyCategoryFilters,
          onModify: _openModifyCategory,
          onDelete: _deleteCategory,
          onAdd: _openAddCategory,
          onClosed: _closeCategoryMenu,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        DebugConsole.log(
          '[CategoryMenu] shell request first frame '
          'elapsed=${_elapsedMs(requestedAt)}ms',
        );
      });
      return;
    }
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
    if (externalEditor != null) {
      setState(() {
        _categoryMode = null;
        _categoryEditorOpen = false;
        _editingCategory = null;
        _budgetEditorItem = null;
      });
      externalEditor();
      return;
    }
    _clearKeyboardDebug('AddCategory');
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
    _clearKeyboardDebug('EditCategory');
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

  void _applyCategoryFilters(Set<int> categoryIds) {
    widget.store.setCategoryFilters(
      type: widget.store.activeType,
      categoryIds: categoryIds,
    );
    _closeCategoryMenu();
  }

  List<SearchPillFilter> _categorySearchFilters() {
    final filters = <SearchPillFilter>[];
    final ids = widget.store.activeCategoryIds.toList()..sort();
    for (final id in ids) {
      final category = widget.store.categoriesById[id];
      if (category == null) continue;
      filters.add(
        SearchPillFilter(
          id: id.toString(),
          label: category.name,
          color: category.slotColor,
          onClear: () => widget.store.clearCategoryFilterId(id),
        ),
      );
    }
    if (filters.isEmpty) return const <SearchPillFilter>[];
    return filters;
  }

  List<SearchPillFilter> _merchantSearchFilters(ExpenseTheme expenseTheme) {
    final merchants = widget.store.activeMerchantFilters.toList()..sort();
    return [
      for (final merchant in merchants)
        SearchPillFilter(
          id: merchant,
          label: merchant,
          color: expenseTheme.accent,
          onClear: () => widget.store.clearMerchantFilter(merchant),
        ),
    ];
  }

  void _openVendorSheet() {
    final externalVendorSheet = widget.onVendorSheetRequested;
    if (externalVendorSheet != null) {
      externalVendorSheet();
      return;
    }
    _clearKeyboardDebug('VendorFilter');
    setState(() {
      _pendingVendorFilters = {...widget.store.activeMerchantFilters};
      _vendorSheetOpen = true;
    });
  }

  void _closeVendorSheet() {
    if (!_vendorSheetOpen) return;
    setState(() => _vendorSheetOpen = false);
  }

  bool _canDragVendorSheet(
    Offset globalPosition,
    Offset startGlobalPosition,
    double gestureDx,
    double gestureDy,
  ) {
    if (!_vendorListScrollController.hasClients) return true;
    return _vendorListScrollController.offset <= 0.5;
  }

  void _togglePendingVendorFilter(String vendor) {
    setState(() {
      final next = {..._pendingVendorFilters};
      if (!next.add(vendor)) next.remove(vendor);
      _pendingVendorFilters = next;
    });
  }

  Future<void> _renameVendorFilterSummary(
    VendorFilterSummary summary,
    String userAssignedName,
  ) async {
    final previousName = summary.name.trim();
    final nextName = userAssignedName.trim();
    if (nextName.isEmpty) return;
    await widget.store.renameTransactionsByOriginalMerchant(
      summary.originalName,
      nextName,
    );
    if (!mounted) return;
    setState(() {
      final nextFilters = {..._pendingVendorFilters};
      if (nextFilters.remove(previousName)) nextFilters.add(nextName);
      _pendingVendorFilters = nextFilters;
    });
  }

  Future<void> _resetVendorFilterSummary(VendorFilterSummary summary) async {
    final previousName = summary.name.trim();
    final nextName = summary.originalName.trim();
    await widget.store.resetTransactionNamesByOriginalMerchant(
      summary.originalName,
    );
    if (!mounted) return;
    setState(() {
      final nextFilters = {..._pendingVendorFilters};
      if (nextFilters.remove(previousName) && nextName.isNotEmpty) {
        nextFilters.add(nextName);
      }
      _pendingVendorFilters = nextFilters;
    });
  }

  void _applyVendorFilters() {
    widget.store.setMerchantFilters(_pendingVendorFilters);
    _closeVendorSheet();
  }

  ExpenseTheme get _expenseTheme =>
      widget.expenseTheme ??
      ExpenseTheme.fromSettings(AppThemeSettings.defaults());

  Future<void> _pickSummaryMonth() async {
    final reference = widget.store.summaryReferenceDate;
    final selection = await showModalBottomSheet<SummaryScopeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SummaryScopePickerSheet(
          initialSelection: SummaryScopeSelection(
            yearEnabled: widget.store.summaryWindow != SummaryWindow.allTime,
            monthEnabled: widget.store.summaryWindow == SummaryWindow.monthly,
            year: reference.year,
            month: reference.month,
          ),
          accentColor: _expenseTheme.accent,
          buttonSurfaceStyle: _expenseTheme.buttonSurfaceStyle,
          onApply: (selection) => Navigator.of(context).pop(selection),
        );
      },
    );
    if (!mounted || selection == null) return;
    if (!selection.yearEnabled) {
      await widget.store.setSummaryAllTime();
      return;
    }
    if (!selection.monthEnabled) {
      await widget.store.setSummaryYear(selection.year);
      return;
    }
    await widget.store.setSummaryMonth(selection.year, selection.month);
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

class _TransactionListHeader extends StatelessWidget {
  const _TransactionListHeader({required this.transactionCount});

  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.gray500,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    return SizedBox(
      key: const ValueKey('transaction-list-header'),
      height: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              heightFactor: 1,
              child: Text(
                '$transactionCount tranzakció',
                key: const ValueKey('transaction-list-header-count'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorFilterPanel extends StatefulWidget {
  const VendorFilterPanel({
    super.key,
    required this.summaries,
    required this.selectedVendors,
    required this.activeType,
    required this.scrollController,
    required this.accentColor,
    required this.cardSurfaceColor,
    required this.cardSurfaceStyle,
    required this.avatarSurfaceStyle,
    required this.buttonSurfaceStyle,
    required this.onToggle,
    required this.onRename,
    required this.onResetName,
    required this.onApply,
  });

  final List<VendorFilterSummary> summaries;
  final Set<String> selectedVendors;
  final TransactionType activeType;
  final ScrollController scrollController;
  final Color accentColor;
  final Color cardSurfaceColor;
  final ExpenseSurfaceInteraction cardSurfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ValueChanged<String> onToggle;
  final Future<void> Function(VendorFilterSummary summary, String name)
  onRename;
  final Future<void> Function(VendorFilterSummary summary) onResetName;
  final VoidCallback onApply;

  @override
  State<VendorFilterPanel> createState() => _VendorFilterPanelState();
}

class _VendorFilterPanelState extends State<VendorFilterPanel> {
  late final TextEditingController _searchController;
  var _query = '';
  double? _lastLoggedKeyboardInset;
  List<VendorFilterSummary>? _cachedModelSource;
  String? _cachedModelQuery;
  _VendorVisibleModel? _cachedModel;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VendorFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.summaries, widget.summaries)) {
      _cachedModelSource = null;
      _cachedModelQuery = null;
      _cachedModel = null;
    }
  }

  void _logKeyboardLayout(
    KeyboardInsetMetrics keyboard,
    double safeBottomInset,
    double listBottomPadding,
  ) {
    final keyboardInset = keyboard.effectiveInset;
    if (_lastLoggedKeyboardInset == keyboardInset) return;
    _lastLoggedKeyboardInset = keyboardInset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DebugConsole.log(
        '[KeyboardFlow] VendorFilter keyboard '
        'raw=${keyboard.rawInset.toStringAsFixed(1)} '
        'animated=${keyboard.animatedInset.toStringAsFixed(1)} '
        'inset=${keyboardInset.toStringAsFixed(1)} '
        'lag=${keyboard.lag.toStringAsFixed(1)} '
        'footerBottom=${keyboardInset.toStringAsFixed(1)} '
        'listPadding=${listBottomPadding.toStringAsFixed(1)} '
        'safe=${safeBottomInset.toStringAsFixed(1)} '
        'source=${keyboard.source} '
        'phase=${keyboard.phase ?? 'none'} '
        'seq=${keyboard.sequence?.toString() ?? 'n/a'} '
        'ageMs=${keyboard.ageMs?.toString() ?? 'n/a'} '
        'fallback=${keyboard.fallbackInset.toStringAsFixed(1)} '
        'nativeSource=${keyboard.nativeSource ?? 'n/a'}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeBottomInset = MediaQuery.paddingOf(context).bottom + 8;
    return KeyboardInsetFollower(
      debugLabel: 'VendorFilter',
      builder: (context, keyboard, child) {
        final keyboardInset = keyboard.effectiveInset;
        final visibleModel = _visibleModel();
        final listBottomPadding = 84 + safeBottomInset + keyboardInset;
        _logKeyboardLayout(keyboard, safeBottomInset, listBottomPadding);
        return ColoredBox(
          color: AppColors.white,
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 46,
                    child: Center(
                      child: Text(
                        'Vendor lista',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                  ),
                  _VendorSearchPill(
                    controller: _searchController,
                    count: visibleModel.count,
                    surfaceStyle: widget.buttonSurfaceStyle,
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                        _cachedModelSource = null;
                        _cachedModelQuery = null;
                        _cachedModel = null;
                      });
                    },
                  ),
                  Expanded(
                    child: widget.summaries.isEmpty
                        ? const Center(
                            child: Text(
                              'Nincs vendor az időszakban',
                              style: TextStyle(color: AppColors.gray500),
                            ),
                          )
                        : ListView.builder(
                            key: const ValueKey('vendor-filter-list'),
                            controller: widget.scrollController,
                            padding: EdgeInsets.fromLTRB(
                              20,
                              8,
                              20,
                              listBottomPadding,
                            ),
                            itemCount: visibleModel.items.length,
                            itemBuilder: (context, index) {
                              final item = visibleModel.items[index];
                              if (item.headerLabel != null) {
                                return _VendorSectionHeader(
                                  label: item.headerLabel!,
                                );
                              }
                              final summaries = item.summaries;
                              final left = summaries[0];
                              final right = summaries.length > 1
                                  ? summaries[1]
                                  : null;
                              return Padding(
                                key: ValueKey('vendor-filter-rowpair-$index'),
                                padding: const EdgeInsets.only(bottom: 15),
                                child: SizedBox(
                                  height: 150,
                                  child: Row(
                                    children: [
                                      Expanded(child: _vendorCard(left)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: right == null
                                            ? const SizedBox.shrink()
                                            : _vendorCard(right),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: keyboardInset,
                child: ColoredBox(
                  key: const ValueKey('vendor-filter-footer'),
                  color: AppColors.white,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, safeBottomInset),
                    child: ExpenseSurfaceButton(
                      buttonKey: const ValueKey('vendor-filter-apply-button'),
                      label: 'Szűrőbeállítás',
                      onPressed: widget.onApply,
                      surfaceStyle: widget.buttonSurfaceStyle,
                      color: widget.accentColor,
                      foregroundColor: AppColors.white,
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

  Widget _vendorCard(VendorFilterSummary summary) {
    return _VendorFilterRow(
      summary: summary,
      selected: widget.selectedVendors.contains(summary.name),
      activeType: widget.activeType,
      accentColor: widget.accentColor,
      cardSurfaceColor: widget.cardSurfaceColor,
      cardSurfaceStyle: widget.cardSurfaceStyle,
      avatarSurfaceStyle: widget.avatarSurfaceStyle,
      onTap: () => widget.onToggle(summary.name),
      onRename: widget.onRename,
      onResetName: widget.onResetName,
    );
  }

  _VendorVisibleModel _visibleModel() {
    final needle = _query.trim().toLowerCase();
    final cached = _cachedModel;
    if (cached != null &&
        identical(_cachedModelSource, widget.summaries) &&
        _cachedModelQuery == needle) {
      return cached;
    }
    final visibleSummaries = needle.isEmpty
        ? widget.summaries
        : [
            for (final summary in widget.summaries)
              if (summary.name.toLowerCase().contains(needle) ||
                  summary.originalName.toLowerCase().contains(needle))
                summary,
          ];
    final sorted = [...visibleSummaries]..sort(_compareVendorSummaries);
    final items = <_VendorListItem>[];
    String? previousGroup;
    var rowSummaries = <VendorFilterSummary>[];
    void flushRow() {
      if (rowSummaries.isEmpty) return;
      items.add(_VendorListItem.row(List.unmodifiable(rowSummaries)));
      rowSummaries = <VendorFilterSummary>[];
    }

    for (final summary in sorted) {
      final group = _vendorGroup(summary.name);
      if (previousGroup != null && group != previousGroup) {
        flushRow();
      }
      if (previousGroup != group) {
        items.add(_VendorListItem.header(group));
      }
      previousGroup = group;
      rowSummaries.add(summary);
      if (rowSummaries.length == 2) flushRow();
    }
    flushRow();
    final model = _VendorVisibleModel(
      count: visibleSummaries.length,
      items: List.unmodifiable(items),
    );
    _cachedModelSource = widget.summaries;
    _cachedModelQuery = needle;
    _cachedModel = model;
    return model;
  }

  int _compareVendorSummaries(
    VendorFilterSummary left,
    VendorFilterSummary right,
  ) {
    final leftGroup = _vendorGroup(left.name);
    final rightGroup = _vendorGroup(right.name);
    final groupCompare = _groupRank(
      leftGroup,
    ).compareTo(_groupRank(rightGroup));
    if (groupCompare != 0) return groupCompare;
    final leftName = _normalizeVendorName(left.name);
    final rightName = _normalizeVendorName(right.name);
    final nameCompare = leftName.compareTo(rightName);
    if (nameCompare != 0) return nameCompare;
    return left.name.compareTo(right.name);
  }

  int _groupRank(String group) {
    if (group == '#') return 0;
    return group.codeUnitAt(0);
  }

  String _vendorGroup(String name) {
    final normalized = _normalizeVendorName(name).trim();
    if (normalized.isEmpty) return '#';
    final first = normalized.codeUnitAt(0);
    if (first < 97 || first > 122) return '#';
    return String.fromCharCode(first).toUpperCase();
  }

  String _normalizeVendorName(String name) {
    final lower = name.toLowerCase();
    const accents = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ő': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'ű': 'u',
      'û': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(accents[char] ?? char);
    }
    return buffer.toString();
  }
}

class _VendorVisibleModel {
  const _VendorVisibleModel({required this.count, required this.items});

  final int count;
  final List<_VendorListItem> items;
}

class _VendorListItem {
  const _VendorListItem.header(String label)
    : headerLabel = label,
      summaries = const <VendorFilterSummary>[];

  const _VendorListItem.row(this.summaries) : headerLabel = null;

  final String? headerLabel;
  final List<VendorFilterSummary> summaries;
}

class _VendorSectionHeader extends StatelessWidget {
  const _VendorSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('vendor-filter-section-$label'),
      height: 34,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _VendorSearchPill extends StatelessWidget {
  const _VendorSearchPill({
    required this.controller,
    required this.count,
    required this.surfaceStyle,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int count;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpenseSurfaceContainer(
      surfaceKey: const ValueKey('vendor-filter-search-pill'),
      style: surfaceStyle,
      color: AppColors.white,
      borderRadius: BorderRadius.circular(25),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      neutralBorder: Border.all(color: AppColors.gray200),
      neutralShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 2),
          blurRadius: 3,
        ),
      ],
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.gray400),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('vendor-filter-search-field'),
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                hintText: 'Vendor keresés',
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count vendor',
            key: const ValueKey('vendor-filter-count'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.gray500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorFilterRow extends StatefulWidget {
  const _VendorFilterRow({
    required this.summary,
    required this.selected,
    required this.activeType,
    required this.accentColor,
    required this.cardSurfaceColor,
    required this.cardSurfaceStyle,
    required this.avatarSurfaceStyle,
    required this.onTap,
    required this.onRename,
    required this.onResetName,
  });

  final VendorFilterSummary summary;
  final bool selected;
  final TransactionType activeType;
  final Color accentColor;
  final Color cardSurfaceColor;
  final ExpenseSurfaceInteraction cardSurfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final VoidCallback onTap;
  final Future<void> Function(VendorFilterSummary summary, String name)
  onRename;
  final Future<void> Function(VendorFilterSummary summary) onResetName;

  @override
  State<_VendorFilterRow> createState() => _VendorFilterRowState();
}

class _VendorFilterRowState extends State<_VendorFilterRow> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  Timer? _cardReleaseTimer;
  var _editingName = false;
  var _savingName = false;
  var _cardPressed = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.summary.name);
    _nameFocusNode = FocusNode()..addListener(_handleNameFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _VendorFilterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingName && widget.summary.name != oldWidget.summary.name) {
      _setControllerText(widget.summary.name);
    }
  }

  @override
  void dispose() {
    _cardReleaseTimer?.cancel();
    _nameFocusNode
      ..removeListener(_handleNameFocusChanged)
      ..dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _pressCard() {
    if (!widget.cardSurfaceStyle.hasPressEffect) return;
    _cardReleaseTimer?.cancel();
    _setCardPressed(true);
  }

  void _releaseCardSoon() {
    if (!widget.cardSurfaceStyle.hasPressEffect) return;
    _cardReleaseTimer?.cancel();
    _cardReleaseTimer = Timer(const Duration(milliseconds: 120), () {
      _setCardPressed(false);
    });
  }

  void _setCardPressed(bool value) {
    if (_cardPressed == value || !mounted) return;
    setState(() => _cardPressed = value);
  }

  void _handleNameFocusChanged() {
    if (!_nameFocusNode.hasFocus && _editingName && !_savingName) {
      unawaited(_commitNameEdit());
    }
  }

  void _beginNameEdit() {
    if (_savingName) return;
    DebugConsole.log(
      '[KeyboardFlow] VendorFilter focus request '
      'vendor=${widget.summary.originalName} '
      '${_keyboardTraceText()}',
    );
    setState(() {
      _editingName = true;
      _setControllerText(widget.summary.name);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nameFocusNode.requestFocus();
      DebugConsole.log(
        '[KeyboardFlow] VendorFilter focus frame '
        'vendor=${widget.summary.originalName} '
        '${_keyboardTraceText()}',
      );
    });
  }

  Future<void> _commitNameEdit() async {
    if (!_editingName || _savingName) return;
    final nextName = _nameController.text.trim();
    final currentName = widget.summary.name.trim();
    if (nextName.isEmpty || nextName == currentName) {
      if (!mounted) return;
      setState(() {
        _editingName = false;
        _setControllerText(widget.summary.name);
      });
      return;
    }
    setState(() => _savingName = true);
    await widget.onRename(widget.summary, nextName);
    if (!mounted) return;
    setState(() {
      _editingName = false;
      _savingName = false;
    });
  }

  Future<void> _resetName() async {
    if (_savingName) return;
    await widget.onResetName(widget.summary);
  }

  void _setControllerText(String value) {
    _nameController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _keyboardTraceText() {
    final snapshot = KeyboardInsetReader.snapshotOf(context);
    return 'keyboard=${snapshot.inset.toStringAsFixed(1)} '
        'source=${snapshot.source} '
        'phase=${snapshot.phase ?? 'none'} '
        'seq=${snapshot.sequence?.toString() ?? 'n/a'} '
        'ageMs=${snapshot.ageMs?.toString() ?? 'n/a'} '
        'fallback=${snapshot.fallbackInset.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasCategoryIcon = widget.summary.categoryIconSlot != null;
    final avatarColor = !hasCategoryIcon
        ? AppColors.gray500
        : widget.summary.colorHex == null
        ? widget.accentColor
        : AppColors.fromHex(widget.summary.colorHex!);
    final amountColor = widget.activeType == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    final amountPrefix = widget.activeType == TransactionType.income
        ? '+'
        : '-';
    final activeUsesInset =
        widget.selected && widget.cardSurfaceStyle.hasPressEffect;
    final cardPressed = activeUsesInset || _cardPressed;
    final avatarCardOffset = ExpenseSurface.pressOffset(
      style: widget.cardSurfaceStyle,
      pressed: cardPressed,
    );
    return SizedBox(
      key: ValueKey('vendor-filter-row-${widget.summary.name}'),
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _pressCard(),
              onPointerUp: (_) => _releaseCardSoon(),
              onPointerCancel: (_) => _releaseCardSoon(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _editingName ? null : widget.onTap,
                child: ExpensePressable(
                  enabled: widget.cardSurfaceStyle.hasPressEffect,
                  forcePressed: cardPressed,
                  builder: (context, pressed) {
                    final radius = BorderRadius.circular(18);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ExpenseSurfaceContainer(
                          surfaceKey: ValueKey(
                            'vendor-filter-row-surface-${widget.summary.name}',
                          ),
                          style: widget.cardSurfaceStyle,
                          color: widget.cardSurfaceColor,
                          borderRadius: radius,
                          pressed: pressed,
                          padding: const EdgeInsets.fromLTRB(10, 76, 10, 12),
                          neutralBorder: Border.all(color: AppColors.gray200),
                          neutralShadow: categoryNeutralShadow(
                            widget.cardSurfaceStyle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _nameArea(),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.summary.count} tranzakció',
                                key: ValueKey(
                                  'vendor-filter-transaction-count-${widget.summary.name}',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1,
                                  color: AppColors.gray500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$amountPrefix${formatHuf(widget.summary.total)}',
                                key: ValueKey(
                                  'vendor-filter-amount-${widget.summary.name}',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.selected &&
                            !widget.cardSurfaceStyle.hasPressEffect)
                          CategoryActiveBorder(
                            radius: radius,
                            color: widget.accentColor,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(begin: Offset.zero, end: avatarCardOffset),
                duration: ExpenseSurface.pressDuration,
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(offset: value, child: child);
                },
                child: IgnorePointer(
                  child: ExpensePressable(
                    key: ValueKey(
                      'vendor-filter-avatar-${widget.summary.name}',
                    ),
                    enabled: widget.avatarSurfaceStyle.hasPressEffect,
                    forcePressed:
                        cardPressed && widget.avatarSurfaceStyle.hasPressEffect,
                    builder: (context, avatarPressed) {
                      return ExpenseSurfaceContainer(
                        surfaceKey: ValueKey(
                          'vendor-filter-avatar-surface-${widget.summary.name}',
                        ),
                        style: widget.avatarSurfaceStyle,
                        color: avatarColor,
                        primary: true,
                        primaryColor: avatarColor,
                        borderRadius: BorderRadius.circular(32.5),
                        pressed: avatarPressed,
                        width: 65,
                        height: 65,
                        child: CategoryIconBadge(
                          iconSlot: widget.summary.categoryIconSlot,
                          backgroundColor: Colors.transparent,
                          size: 65,
                          iconSize: 44,
                          iconStrokeWidth: 1.35,
                          showShadow: false,
                          showQuestionMark: !hasCategoryIcon,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (widget.summary.hasCustomName)
            Positioned(
              top: 7,
              right: 7,
              child: IconButton(
                key: ValueKey(
                  'vendor-filter-reset-${widget.summary.originalName}',
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                onPressed: _resetName,
                icon: const Icon(Icons.restart_alt, size: 17),
                color: AppColors.gray500,
                tooltip: 'Eredeti vendor név',
              ),
            ),
        ],
      ),
    );
  }

  Widget _nameArea() {
    if (_editingName) {
      return Container(
        key: ValueKey(
          'vendor-filter-name-editor-${widget.summary.originalName}',
        ),
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.accentColor, width: 1.4),
        ),
        child: TextField(
          key: ValueKey(
            'vendor-filter-name-input-${widget.summary.originalName}',
          ),
          controller: _nameController,
          focusNode: _nameFocusNode,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          textInputAction: TextInputAction.done,
          cursorColor: widget.accentColor,
          maxLines: 1,
          onSubmitted: (_) => unawaited(_commitNameEdit()),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.gray800,
          ),
        ),
      );
    }
    return GestureDetector(
      key: ValueKey('vendor-filter-name-${widget.summary.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: _beginNameEdit,
      child: SizedBox(
        height: 24,
        child: Center(
          child: Text(
            widget.summary.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.gray800,
            ),
          ),
        ),
      ),
    );
  }
}
