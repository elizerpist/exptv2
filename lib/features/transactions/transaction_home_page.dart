import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'models/transaction_category.dart';
import 'state/transaction_store.dart';
import 'widgets/category_menu/category_editor_panel.dart';
import 'widgets/category_menu/category_editor_sheet.dart';
import 'widgets/calendar_menu/calendar_menu_overlay.dart';
import 'widgets/category_menu/category_menu_overlay.dart';
import 'models/category_budget_bar_data.dart';
import 'widgets/header_card/category_budget_stage.dart';
import 'widgets/header_card/category_limit_editor_sheet.dart';
import 'widgets/header_card/transaction_header_metrics.dart';
import 'widgets/header_card/transaction_header_card.dart';
import 'widgets/search_pill.dart';
import 'widgets/summary_pill.dart';
import 'widgets/transaction_log_list.dart';
import 'widgets/transaction_type_pills.dart';

class TransactionHomePage extends StatefulWidget {
  const TransactionHomePage({super.key, required this.store});

  final TransactionStore store;

  @override
  State<TransactionHomePage> createState() => _TransactionHomePageState();
}

class _TransactionHomePageState extends State<TransactionHomePage> {
  var _headerExpanded = false;
  var _calendarOpen = false;
  CategoryOverlayMode? _categoryMode;

  @override
  void initState() {
    super.initState();
    widget.store.start();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray50,
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

          return Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: TransactionHeaderMetrics.contentTop),
                  TransactionTypePills(
                    activeType: widget.store.activeType,
                    onChanged: _setActiveType,
                  ),
                  SummaryPill(
                    title: widget.store.activeType == TransactionType.income
                        ? 'Bevételek'
                        : 'Kiadások',
                    value: widget.store.activeSummary.formattedFor(
                      widget.store.activeType,
                    ),
                    onSwipe: widget.store.cycleSummaryWindow,
                  ),
                  SearchPill(
                    query: widget.store.searchQuery,
                    onQueryChanged: widget.store.setSearchQuery,
                    merchantFilter: widget.store.merchantFilter,
                    filteredCount: widget.store.visibleTransactions.length,
                    onClearMerchant: widget.store.clearMerchantFilter,
                  ),
                  Expanded(
                    child: TransactionLogList(
                      records: widget.store.visibleTransactions,
                      categories: widget.store.categories,
                      onFastFilter: widget.store.setMerchantFilter,
                    ),
                  ),
                ],
              ),
              if (_headerExpanded)
                CategoryBudgetStage(
                  bars: widget.store.categoryBudgetBars,
                  onBarTap: _openLimitEditor,
                ),
              TransactionHeaderCard(
                balanceText: widget.store.totalBalanceText,
                expanded: _headerExpanded,
                onCategoryPressed: _openCategoryMenu,
                onCalendarPressed: _openCalendarMenu,
                onExpandPressed: () =>
                    setState(() => _headerExpanded = !_headerExpanded),
              ),
              if (_calendarOpen)
                CalendarMenuOverlay(
                  transactions: widget.store.transactions,
                  categories: widget.store.categories,
                  onClose: _closeCalendarMenu,
                  onMonthSelect: (_, _) {},
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
            ],
          );
        },
      ),
    );
  }

  void _setActiveType(TransactionType type) {
    widget.store.setActiveType(type);
    setState(() {
      _calendarOpen = false;
      _categoryMode = null;
    });
  }

  void _openLimitEditor(CategoryBudgetBarData bar) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: CategoryLimitEditorSheet(
            bar: bar,
            allBars: widget.store.categoryBudgetBars,
            onCancel: () => Navigator.of(sheetContext).pop(),
            onSave: ({required limitAmount, required alertActive}) async {
              await widget.store.saveCategoryLimitForBar(
                bar,
                limitAmount: limitAmount,
                alertActive: alertActive,
              );
              if (!sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
            },
          ),
        );
      },
    );
  }

  void _openCalendarMenu() {
    setState(() {
      _headerExpanded = false;
      _calendarOpen = true;
      _categoryMode = null;
    });
  }

  void _closeCalendarMenu() {
    setState(() => _calendarOpen = false);
  }

  void _openCategoryMenu() {
    setState(() {
      _headerExpanded = false;
      _calendarOpen = false;
      _categoryMode = CategoryOverlayMode.picker;
    });
  }

  void _closeCategoryMenu() {
    setState(() {
      _categoryMode = null;
    });
  }

  void _openAddCategory() {
    _openCategoryEditorSheet();
  }

  void _openModifyCategory(TransactionCategory category) {
    _openCategoryEditorSheet(initialCategory: category);
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
      _categoryMode = CategoryOverlayMode.picker;
    });
  }

  void _openCategoryEditorSheet({TransactionCategory? initialCategory}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return CategoryEditorSheet(
          activeType: widget.store.activeType,
          initialCategory: initialCategory,
          onClose: () => Navigator.of(sheetContext).pop(),
          onSave: (draft) async {
            await _saveCategory(draft, initialCategory);
            if (!sheetContext.mounted) return;
            Navigator.of(sheetContext).pop();
          },
          onDelete: initialCategory == null
              ? null
              : (category) async {
                  await _deleteCategory(category);
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                },
        );
      },
    );
  }

  Future<void> _deleteCategory(TransactionCategory category) async {
    final deleted = await widget.store.deleteCategory(category);
    if (!mounted || !deleted) return;
    setState(() {
      _categoryMode = CategoryOverlayMode.picker;
    });
  }
}
