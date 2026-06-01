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
import 'models/backheader_budget_item.dart';
import 'widgets/header_card/category_budget_stage.dart';
import 'widgets/header_card/budget_target_editor_sheet.dart';
import 'widgets/header_card/fast_info_panel.dart';
import 'widgets/header_card/header_fast_info_surface.dart';
import 'widgets/header_card/transaction_header_metrics.dart';
import 'widgets/header_card/transaction_header_card.dart';
import 'widgets/search_pill.dart';
import 'widgets/summary_pill.dart';
import 'widgets/transaction_log_list.dart';
import 'widgets/transaction_type_pills.dart';

class TransactionHomePage extends StatefulWidget {
  const TransactionHomePage({
    super.key,
    required this.store,
    this.expenseTheme,
    this.budgetEditorOpenRequest = 0,
    this.onEditTransaction,
    this.onDeleteTransactionRequested,
    this.onBlockingOverlayChanged,
  });

  final TransactionStore store;
  final ExpenseTheme? expenseTheme;
  final int budgetEditorOpenRequest;
  final ValueChanged<TransactionRecord>? onEditTransaction;
  final FutureOr<bool> Function(TransactionRecord)? onDeleteTransactionRequested;
  final ValueChanged<bool>? onBlockingOverlayChanged;

  @override
  State<TransactionHomePage> createState() => _TransactionHomePageState();
}

class _TransactionHomePageState extends State<TransactionHomePage>
    with TickerProviderStateMixin {
  var _headerExpanded = false;
  var _fastInfoExtent = 0.0;
  var _balanceHidden = false;
  String? _backheaderActiveKey;
  late final AnimationController _headerPullController;
  late final AnimationController _headerSlideController;
  CategoryOverlayMode? _categoryMode;
  BackheaderBudgetItem? _budgetEditorItem;
  var _categoryEditorOpen = false;
  var _blockingOverlayNotified = false;
  TransactionCategory? _editingCategory;

  @override
  void initState() {
    super.initState();
    _headerPullController = AnimationController.unbounded(vsync: this)
      ..addListener(_syncHeaderPullFromController);
    _headerSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 260),
    )..addListener(_syncHeaderSlideFromController);
    widget.store.start();
  }

  @override
  void didUpdateWidget(covariant TransactionHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgetEditorOpenRequest != widget.budgetEditorOpenRequest &&
        widget.budgetEditorOpenRequest > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openBudgetEditorFromShellSignal();
      });
    }
  }

  @override
  void dispose() {
    _headerPullController.dispose();
    _headerSlideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseTheme =
        widget.expenseTheme ??
        ExpenseTheme.fromSettings(
          const AppThemeSettings(
            magnetType: MagnetType.fade,
            cardColor: AppCardColor.lightgray,
            theme: AppTheme.turquoise,
            backgroundColor: AppBackgroundColor.gray,
            boxColor: AppBoxColor.gray,
          ),
        );
    return ColoredBox(
      color: expenseTheme.appBackground,
      child: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          if (widget.store.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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

          final visibleFastInfoExtent = _fastInfoExtent
              .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
              .toDouble();
          _notifyBlockingOverlay(
            _categoryEditorOpen || _budgetEditorItem != null,
          );

          final headerSlideProgress = _headerSlideController.value;
          final showBackheader =
              _headerExpanded || headerSlideProgress > 0.001;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  const SizedBox(height: TransactionHeaderMetrics.contentTop),
                  TransactionTypePills(
                    activeType: widget.store.activeType,
                    onChanged: _setActiveType,
                  ),
                  SummaryPill(
                    title: widget.store.activeSummaryTitle,
                    value: widget.store.activeSummary.formattedFor(
                      widget.store.activeType,
                    ),
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
                    merchantFilter: widget.store.merchantFilter,
                    merchantFilterColor: _merchantFilterColor(),
                    categoryFilter: widget.store.activeCategory?.name,
                    categoryFilterColor: widget.store.activeCategory?.slotColor,
                    filteredCount: widget.store.visibleTransactions.length,
                    onClearMerchant: widget.store.clearMerchantFilter,
                    onClearCategory: widget.store.clearCategoryFilter,
                  ),
                  Expanded(
                    child: TransactionLogList(
                      records: widget.store.visibleTransactions,
                      ghostRecords: widget.store.visibleGhostTransactions,
                      categories: widget.store.categories,
                      onFastFilter: _setMerchantFastFilter,
                      onRecordTap: _editTransaction,
                      onDeleteRequested: _requestDeleteTransaction,
                      onCategoryFilter: widget.store.setCategoryFilter,
                      onRenameMerchant: _renameTransactionsByMerchant,
                      onResetMerchantName: _resetTransactionNamesByMerchant,
                    ),
                  ),
                ],
              ),
              if (showBackheader)
                CategoryBudgetStage(
                  items: widget.store.backheaderBudgetItems,
                  categoryBars: widget.store.categoryBudgetBars,
                  periodLabel: widget.store.activePeriodLabel,
                  activeKey: _backheaderActiveKey,
                  onActiveItemChanged: _setBackheaderActiveItem,
                  onItemTap: _openBudgetTargetEditor,
                  onOverviewJump: _jumpBackheaderToOverview,
                ),
              if (showBackheader)
                _buildHeaderCard(
                  expenseTheme: expenseTheme,
                  visibleFastInfoExtent: 0,
                  slideProgress: headerSlideProgress,
                )
              else
                HeaderFastInfoSurface(
                  visibleFastInfoExtent: visibleFastInfoExtent,
                  cardColor: expenseTheme.headerCard,
                  fastInfo: FastInfoPanel(
                    config: FastInfoConfig.defaults(),
                    backgroundColor: Colors.transparent,
                  ),
                  header: _buildHeaderCard(
                    expenseTheme: expenseTheme,
                    visibleFastInfoExtent: visibleFastInfoExtent,
                    drawSurface: false,
                  ),
                ),
              if (_categoryMode != null)
                CategoryMenuOverlay(
                  store: widget.store,
                  onClose: _closeCategoryMenu,
                  onAdd: _openAddCategory,
                  onModify: _openModifyCategory,
                  onSelect: _selectCategory,
                  onDelete: _deleteCategory,
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
                  ),
                ),
              if (_budgetEditorItem != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BudgetTargetEditorSheet(
                    item: _budgetEditorItem!,
                    items: widget.store.backheaderBudgetItems,
                    categoryBars: widget.store.categoryBudgetBars,
                    overviewItems: widget.store.overviewBudgetItems,
                    periodIncome: widget.store.activePeriodIncomeTotal,
                    onCancel: _closeBudgetTargetEditor,
                    onActiveItemChanged: _setBackheaderActiveItem,
                    onSaveOverview: (
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
                    onSaveCategory: (
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

  void _syncHeaderPullFromController() {
    if (!mounted) return;
    final rawNext = _headerPullController.value
        .clamp(-12.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    final next = rawNext.abs() < 0.5 ? 0.0 : rawNext;
    if ((next - _fastInfoExtent).abs() < 0.01) return;
    setState(() => _fastInfoExtent = next);
  }

  void _syncHeaderSlideFromController() {
    if (!mounted) return;
    setState(() {});
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
    _headerSlideController.stop();
    setState(() {
      _fastInfoExtent = 0;
      _headerExpanded = true;
    });
    DebugConsole.log(
      '[HeaderCard] expand start progress=${_headerSlideController.value.toStringAsFixed(2)}',
    );
    await _headerSlideController.forward();
    if (!mounted) return;
    DebugConsole.log('[HeaderCard] expand complete');
  }

  Future<void> _collapseHeader() async {
    _headerSlideController.stop();
    setState(() {
      _fastInfoExtent = 0;
      _headerExpanded = false;
    });
    DebugConsole.log(
      '[HeaderCard] collapse start progress=${_headerSlideController.value.toStringAsFixed(2)}',
    );
    await _headerSlideController.reverse();
    if (!mounted) return;
    setState(() {});
    DebugConsole.log('[HeaderCard] collapse complete');
  }


  double _menuPanelHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final requested = screenHeight * 0.55;
    final compactHeight = requested < 520.0 ? requested : 520.0;
    return compactHeight.clamp(0.0, screenHeight).toDouble();
  }

  void _notifyBlockingOverlay(bool active) {
    if (_blockingOverlayNotified == active) return;
    _blockingOverlayNotified = active;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onBlockingOverlayChanged?.call(active);
    });
  }

  TransactionHeaderCard _buildHeaderCard({
    required ExpenseTheme expenseTheme,
    required double visibleFastInfoExtent,
    bool drawSurface = true,
    double? slideProgress,
  }) {
    return TransactionHeaderCard(
      balanceText: widget.store.totalBalanceText,
      expanded: _headerExpanded,
      magnetType: expenseTheme.settings.magnetType,
      accent: expenseTheme.accent,
      cardColor: expenseTheme.headerCard,
      totalIncome: _totalIncome(),
      totalExpense: _totalExpense(),
      fastInfoVisible: visibleFastInfoExtent > 0,
      balanceHidden: _balanceHidden,
      drawSurface: drawSurface,
      slideProgress: slideProgress,
      onBalanceVisibilityPressed: () {
        setState(() => _balanceHidden = !_balanceHidden);
      },
      onCategoryPressed: _openCategoryMenu,
      onVerticalDragUpdate: _handleHeaderDragUpdate,
      onVerticalDragEnd: _handleHeaderDragEnd,
      onExpandPressed: _toggleHeaderExpanded,
    );
  }

  double _totalIncome() {
    return widget.store.transactions
        .where((record) => record.amount > 0)
        .fold<double>(0, (sum, record) => sum + record.amount.abs());
  }

  double _totalExpense() {
    return widget.store.transactions
        .where((record) => record.amount < 0)
        .fold<double>(0, (sum, record) => sum + record.amount.abs());
  }

  void _handleHeaderDragUpdate(DragUpdateDetails details) {
    if (_headerExpanded || _categoryMode != null || _categoryEditorOpen) {
      return;
    }
    _headerPullController.stop();
    final resistedDelta = details.delta.dy > 0
        ? details.delta.dy * 0.85
        : details.delta.dy;
    final next = (_fastInfoExtent + resistedDelta)
        .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    if (next == _fastInfoExtent) return;
    _headerPullController.value = next;
  }

  void _handleHeaderDragEnd(DragEndDetails details) {
    if (_headerExpanded) return;
    final start = _fastInfoExtent
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
            if (_fastInfoExtent == 0) return;
            setState(() => _fastInfoExtent = 0);
          })
          .catchError((_) {}),
    );
  }

  void _setActiveType(TransactionType type) {
    _headerPullController.stop();
    _headerPullController.value = 0;
    widget.store.setActiveType(type);
    setState(() {
      _fastInfoExtent = 0;
      if (_categoryEditorOpen) {
        _categoryEditorOpen = false;
        _editingCategory = null;
      }
      _budgetEditorItem = null;
    });
  }

  Color? _merchantFilterColor() {
    final hex = widget.store.merchantFilterColorHex;
    return hex == null ? null : AppColors.fromHex(hex);
  }

  void _setMerchantFastFilter(
    TransactionRecord record,
    TransactionCategory? category,
  ) {
    widget.store.setMerchantFilter(
      record.displayMerchant,
      colorHex: category?.slotColorHex,
    );
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
    if (!mounted || _backheaderActiveKey == item.key) return;
    setState(() => _backheaderActiveKey = item.key);
  }

  void _jumpBackheaderToOverview() {
    for (final item in widget.store.backheaderBudgetItems) {
      if (item.overview != null) {
        _setBackheaderActiveItem(item);
        return;
      }
    }
  }

  void _openBudgetTargetEditor(BackheaderBudgetItem item) {
    setState(() {
      _backheaderActiveKey = item.key;
      _budgetEditorItem = item;
    });
  }

  void _openBudgetEditorFromShellSignal() {
    final items = widget.store.backheaderBudgetItems;
    if (items.isEmpty) return;
    final item = items.firstWhere(
      (candidate) => candidate.overview != null,
      orElse: () => items.first,
    );
    setState(() {
      _headerExpanded = true;
      _fastInfoExtent = 0;
      _categoryMode = null;
      _categoryEditorOpen = false;
      _editingCategory = null;
      _backheaderActiveKey = item.key;
      _budgetEditorItem = item;
    });
  }

  void _closeBudgetTargetEditor() {
    setState(() => _budgetEditorItem = null);
  }

  void _openCategoryMenu() {
    _headerPullController.stop();
    _headerPullController.value = 0;
    setState(() {
      if (_categoryMode != null ||
          _categoryEditorOpen ||
          _budgetEditorItem != null) {
        _categoryMode = null;
        _categoryEditorOpen = false;
        _budgetEditorItem = null;
        _editingCategory = null;
        return;
      }
      _headerExpanded = false;
      _fastInfoExtent = 0;
      _categoryMode = CategoryOverlayMode.picker;
    });
  }

  void _closeCategoryMenu() {
    setState(() {
      _categoryMode = null;
    });
  }

  void _openAddCategory() {
    setState(() {
      _categoryMode = null;
      _categoryEditorOpen = true;
      _editingCategory = null;
    });
  }

  void _openModifyCategory(TransactionCategory category) {
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
