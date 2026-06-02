import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/debug/debug_console.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/budget_progress_manager.dart';
import '../../data/limit_allocation_manager.dart';
import '../../data/limit_slider_range.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';
import '../../models/transaction_category.dart';
import '../../slots/category_icon_manager.dart';
import '../amount_field.dart';
import '../slide_up_menu_card.dart';
import '../slide_up_panel_metrics.dart';
import 'category_limit_partition_bar.dart';
import 'category_limit_slider.dart';

class BudgetTargetEditorSheet extends StatefulWidget {
  const BudgetTargetEditorSheet({
    super.key,
    required this.item,
    required this.items,
    this.openRequestedAt,
    this.visible = true,
    required this.periodLabel,
    required this.categoryBars,
    required this.periodIncome,
    required this.onCancel,
    required this.onActiveItemChanged,
    required this.onSaveOverview,
    required this.onSaveCategory,
    this.overviewItems = const [],
  });

  final BackheaderBudgetItem item;
  final List<BackheaderBudgetItem> items;
  final DateTime? openRequestedAt;
  final bool visible;
  final String periodLabel;
  final List<CategoryBudgetBarData> categoryBars;
  final List<OverviewBudgetData> overviewItems;
  final double periodIncome;
  final VoidCallback onCancel;
  final ValueChanged<BackheaderBudgetItem> onActiveItemChanged;
  final Future<void> Function(
    BudgetGoalKind kind, {
    required double limitAmount,
    required bool alertActive,
  })
  onSaveOverview;
  final Future<void> Function(
    CategoryBudgetBarData bar, {
    required double limitAmount,
    required bool alertActive,
  })
  onSaveCategory;

  @override
  State<BudgetTargetEditorSheet> createState() =>
      _BudgetTargetEditorSheetState();
}

class _BudgetTargetEditorSheetState extends State<BudgetTargetEditorSheet> {
  late final TextEditingController _controller;
  late final FocusNode _amountFocus;
  DateTime? _focusStartedAt;
  late String _activeKey;
  final _rememberedSliderMaxByKey = <String, double>{};
  final _pendingAmountsByKey = <String, double>{};
  var _updatingController = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _logSheetActivation();
    _activeKey = widget.item.key;
    _controller = TextEditingController();
    _amountFocus = FocusNode()..addListener(_handleAmountFocusChanged);
    _syncControllerToItem(widget.item);
    _controller.addListener(_refreshFromController);
  }

  @override
  void didUpdateWidget(covariant BudgetTargetEditorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.visible && widget.visible) {
      _pendingAmountsByKey.clear();
      _saving = false;
      _syncControllerToItem(widget.item);
      _logSheetActivation();
      return;
    }
    if (oldWidget.item.key != widget.item.key && widget.visible) {
      _syncControllerToItem(widget.item);
    }
  }

  void _logSheetActivation() {
    DebugConsole.log(
      '[BudgetTargetEditor] sheet init '
      'requestElapsed=${_elapsedMs(widget.openRequestedAt)}ms',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.visible) return;
      DebugConsole.log(
        '[BudgetTargetEditor] first frame '
        'requestElapsed=${_elapsedMs(widget.openRequestedAt)}ms',
      );
    });
  }

  @override
  void dispose() {
    _amountFocus
      ..removeListener(_handleAmountFocusChanged)
      ..dispose();
    _controller
      ..removeListener(_refreshFromController)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideUpMenuCard(
      cardKey: const ValueKey('budget-target-editor-card'),
      debugLabel: 'BudgetTargetEditor',
      panelHeight: _panelHeightFor(context),
      visible: widget.visible,
      openRequestedAt: widget.openRequestedAt,
      onDismissed: widget.onCancel,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Builder(
          builder: (context) {
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            const horizontalInset = SlideUpPanelMetrics.horizontalInset;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: horizontalInset,
                      right: horizontalInset,
                      top: 20,
                      bottom: 16,
                    ),
                    child: _BudgetLimitCard(
                      item: _activeItem,
                      periodLabel: widget.periodLabel,
                      amountController: _controller,
                      amountFocusNode: _amountFocus,
                      inputLabel: _inputLabel,
                      activeColor: _activeColor,
                      sliderValue: _sliderRange.value,
                      sliderMax: _sliderRange.max,
                      sliderEnabled: _sliderRange.enabled,
                      sliderDivisions: _sliderRange.divisions,
                      saving: _saving,
                      onPrevious: _selectPrevious,
                      onNext: _selectNext,
                      onAvatarDoubleTap: _selectOverviewItem,
                      onReset: _resetLimit,
                      onSliderChanged: _setAmountFromSlider,
                      onSliderChangeEnd: _setAmountFromSlider,
                      onInputChanged: _captureInputAmount,
                      onSetToMax: _setOverviewToMax,
                      showSetToMax: _activeItem.overview != null,
                      partitionBar: _buildPartitionBar(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalInset,
                    right: horizontalInset,
                    bottom:
                        keyboardInset +
                        SlideUpPanelMetrics.budgetActionBottomInset,
                  ),
                  child: _BudgetLimitSaveButton(
                    saving: _saving,
                    onSave: _savePendingChanges,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _panelHeightFor(BuildContext context) {
    return SlideUpPanelMetrics.budgetHeight(context);
  }

  void _handleAmountFocusChanged() {
    if (_amountFocus.hasFocus) {
      _focusStartedAt = DateTime.now();
      DebugConsole.log(
        '[Perf] BudgetTargetEditor focus field=amount active=true',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_amountFocus.hasFocus) return;
        DebugConsole.log(
          '[Perf] BudgetTargetEditor focus frame field=amount elapsed=${_elapsedMs(_focusStartedAt)}ms',
        );
      });
      return;
    }
    DebugConsole.log(
      '[Perf] BudgetTargetEditor focus field=amount active=false elapsed=${_elapsedMs(_focusStartedAt)}ms',
    );
    _focusStartedAt = null;
  }

  int _elapsedMs(DateTime? startedAt) {
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inMilliseconds;
  }

  void _syncControllerToItem(BackheaderBudgetItem item) {
    _activeKey = item.key;
    final amount = _limitAmountFor(item);
    final text = amount > 0 ? amount.round().toString() : '';
    _updatingController = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _updatingController = false;
  }

  List<BackheaderBudgetItem> get _items {
    final items = [...widget.items];
    if (!items.any((item) => item.key == widget.item.key)) {
      items.insert(0, widget.item);
    }
    return items;
  }

  BackheaderBudgetItem get _activeItem {
    for (final item in _items) {
      if (item.key == _activeKey) return item;
    }
    return widget.item;
  }

  double get _amount {
    final value = _controller.text.trim().replaceAll(' ', '');
    return math.max(0, double.tryParse(value) ?? 0).toDouble();
  }

  LimitSliderRange get _sliderRange {
    final remembered = _rememberedSliderMaxByKey[_activeKey] ?? 0;
    final overview = _activeItem.overview;
    if (overview != null) {
      if (widget.periodIncome > 0) {
        return LimitSliderRange.constrained(
          amount: _amount,
          rememberedMax: remembered,
          maxAllowed: math.max(widget.periodIncome, _amount),
          hasExistingLimit: _amount > 0,
        );
      }
      return LimitSliderRange.unconstrained(
        amount: _amount,
        rememberedMax: remembered,
      );
    }

    final category = _activeItem.category;
    if (category == null) {
      return const LimitSliderRange(
        value: 0,
        max: 1,
        divisions: 1,
        enabled: false,
      );
    }
    final overviewLimit = _matchingOverviewLimitForCategory(category);
    if (overviewLimit <= 0) {
      return LimitSliderRange.unconstrained(
        amount: _amount,
        rememberedMax: remembered,
      );
    }
    final activePreview = _previewCategoryBar(category, _amount);
    final maxAllowed = LimitAllocationManager.categorySliderMax(
      overviewLimit: overviewLimit,
      bars: _partitionBars,
      activeBar: activePreview,
    );
    return LimitSliderRange.constrained(
      amount: _amount,
      rememberedMax: remembered,
      maxAllowed: maxAllowed,
      hasExistingLimit: _effectiveAmountFor(_activeItem) > 0 || _amount > 0,
    );
  }

  String get _inputLabel {
    final overview = _activeItem.overview;
    if (overview == null) return 'Kategória limit';
    return switch (overview.kind) {
      BudgetGoalKind.expenseBudget => 'Budget limit',
      BudgetGoalKind.incomeGoal => 'Bevételi cél',
      BudgetGoalKind.savingGoal => 'Megtakarítási cél',
    };
  }

  Color get _activeColor {
    final category = _activeItem.category;
    if (category != null) return category.color;
    final overview = _activeItem.overview;
    return switch (overview?.kind) {
      BudgetGoalKind.expenseBudget => AppColors.primary,
      BudgetGoalKind.incomeGoal => AppColors.income,
      BudgetGoalKind.savingGoal => BudgetProgressManager.savingColor,
      null => AppColors.primary,
    };
  }

  List<CategoryBudgetBarData> get _partitionBars {
    final result = <CategoryBudgetBarData>[];
    for (final bar in widget.categoryBars) {
      final item = _itemForCategoryBar(bar);
      final amount = item == null ? bar.limitAmount : _effectiveAmountFor(item);
      result.add(_previewCategoryBar(bar, amount));
    }
    final activeCategory = _activeItem.category;
    if (activeCategory != null &&
        !result.any((bar) => _sameTarget(bar, activeCategory))) {
      result.insert(0, _previewCategoryBar(activeCategory, _amount));
    }
    return result;
  }

  double? get _overviewLimitAmount {
    final overview = _activeItem.overview;
    if (overview != null) return _amount > 0 ? _amount : null;
    final category = _activeItem.category;
    if (category == null) return null;
    final amount = _matchingOverviewLimitForCategory(category);
    return amount > 0 ? amount : null;
  }

  Widget _buildPartitionBar() {
    final overview = _activeItem.overview;
    if (overview?.kind == BudgetGoalKind.savingGoal) {
      return const SizedBox.shrink();
    }
    final allocation = LimitAllocationManager.build(
      overviewLimit: _overviewLimitAmount ?? 0,
      bars: _partitionBars,
    );
    return CategoryLimitPartitionBar(
      height: 18.8,
      allocation: allocation,
      onSegmentTap: _selectCategoryByTargetId,
    );
  }

  void _selectCategoryByTargetId(int targetId) {
    for (final item in _items) {
      if (item.category?.targetId == targetId) {
        _selectItem(item);
        return;
      }
    }
  }

  void _selectItem(BackheaderBudgetItem item) {
    _activeKey = item.key;
    _setControllerAmount(_effectiveAmountFor(item), recordPending: false);
    setState(() {});
    widget.onActiveItemChanged(item);
  }

  void _refreshFromController() {
    if (_updatingController) return;
    _captureInputAmount(_controller.text);
  }

  void _captureInputAmount(String _) {
    _storePendingAmount(_activeKey, _amount);
    if (mounted) setState(() {});
  }

  void _resetLimit() {
    _setControllerAmount(0);
  }

  void _setAmountFromSlider(double amount) {
    final snapped = LimitAllocationManager.snapSliderAmount(
      amount,
    ).clamp(0.0, _sliderRange.max).toDouble();
    _setControllerAmount(snapped);
  }

  void _setOverviewToMax() {
    final max = math.max(0.0, widget.periodIncome).toDouble();
    _setControllerAmount(max);
  }

  void _selectPrevious() => _selectAdjacent(-1);

  void _selectNext() => _selectAdjacent(1);

  void _selectOverviewItem() {
    BackheaderBudgetItem? target;
    for (final item in _items) {
      if (item.overview != null) {
        target = item;
        break;
      }
    }
    if (target == null || target.key == _activeKey) return;
    DebugConsole.log(
      '[BudgetTargetEditor] avatar double tap jump key=${target.key}',
    );
    _selectItem(target);
  }

  void _selectAdjacent(int direction) {
    final items = _items;
    if (items.length < 2) return;
    final index = items.indexWhere((item) => item.key == _activeKey);
    final currentIndex = index < 0 ? 0 : index;
    final nextIndex = (currentIndex + direction + items.length) % items.length;
    final next = items[nextIndex];
    _selectItem(next);
  }

  void _setControllerAmount(double amount, {bool recordPending = true}) {
    final normalized = math.max(0.0, amount).toDouble();
    _rememberSliderMax(normalized);
    if (recordPending) _storePendingAmount(_activeKey, normalized);
    final roundedAmount = normalized.round();
    final text = roundedAmount <= 0 ? '' : roundedAmount.toString();
    if (_controller.text != text) {
      _updatingController = true;
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _updatingController = false;
    }
    if (mounted) setState(() {});
  }

  void _storePendingAmount(String key, double amount) {
    final normalized = math.max(0.0, amount).toDouble();
    _pendingAmountsByKey[key] = normalized;
    _rememberSliderMax(normalized);
  }

  void _rememberSliderMax(double amount) {
    final current = _rememberedSliderMaxByKey[_activeKey] ?? 0;
    if (amount > current) {
      _rememberedSliderMaxByKey[_activeKey] = amount;
    }
  }

  Future<void> _savePendingChanges() async {
    if (_saving) return;
    final changes = _pendingAmountsByKey.entries.where((entry) {
      final item = _itemForKey(entry.key);
      return (_limitAmountFor(item) - entry.value).abs() > 0.01;
    }).toList();
    if (changes.isEmpty) {
      widget.onCancel();
      return;
    }

    if (mounted) setState(() => _saving = true);
    for (final change in changes) {
      await _saveItemAmount(_itemForKey(change.key), change.value);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onCancel();
  }

  Future<void> _saveItemAmount(
    BackheaderBudgetItem item,
    double rawAmount,
  ) async {
    final amount = math.max(0.0, rawAmount).toDouble();
    final overview = item.overview;
    final category = item.category;
    if (overview != null) {
      await widget.onSaveOverview(
        overview.kind,
        limitAmount: amount,
        alertActive: false,
      );
    } else if (category != null) {
      await widget.onSaveCategory(
        category,
        limitAmount: amount,
        alertActive: false,
      );
    }
  }

  BackheaderBudgetItem _itemForKey(String key) {
    for (final item in _items) {
      if (item.key == key) return item;
    }
    return _activeItem;
  }

  double _limitAmountFor(BackheaderBudgetItem item) {
    final overview = item.overview;
    if (overview != null && overview.hasLimit) return overview.limitAmount;
    final category = item.category;
    if (category != null && category.hasLimit) return category.limitAmount;
    return 0;
  }

  CategoryBudgetBarData _previewCategoryBar(
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
      alertActive: false,
      color: category.color,
      iconSlot: category.iconSlot,
      category: category.category,
      sourceLimit: category.sourceLimit,
    );
  }

  double _matchingOverviewLimitForCategory(CategoryBudgetBarData category) {
    for (final item in _items) {
      final overview = item.overview;
      if (overview == null || overview.kind == BudgetGoalKind.savingGoal) {
        continue;
      }
      if (overview.kind.transactionType !=
          category.transactionType.nativeValue) {
        continue;
      }
      return _effectiveAmountFor(item);
    }
    for (final overview in widget.overviewItems) {
      if (overview.kind == BudgetGoalKind.savingGoal) continue;
      if (overview.kind.transactionType !=
          category.transactionType.nativeValue) {
        continue;
      }
      final item = BackheaderBudgetItem.overview(overview);
      return _effectiveAmountFor(item);
    }
    return 0;
  }

  double _effectiveAmountFor(BackheaderBudgetItem item) {
    return _pendingAmountsByKey[item.key] ?? _limitAmountFor(item);
  }

  BackheaderBudgetItem? _itemForCategoryBar(CategoryBudgetBarData bar) {
    for (final item in _items) {
      final category = item.category;
      if (category != null && _sameTarget(category, bar)) return item;
    }
    return null;
  }

  bool _sameTarget(CategoryBudgetBarData left, CategoryBudgetBarData right) {
    return left.targetType == right.targetType &&
        left.targetId == right.targetId &&
        left.transactionType == right.transactionType &&
        left.window == right.window &&
        left.periodKey == right.periodKey;
  }
}

class _BudgetLimitCard extends StatelessWidget {
  const _BudgetLimitCard({
    required this.item,
    required this.periodLabel,
    required this.amountController,
    required this.amountFocusNode,
    required this.inputLabel,
    required this.activeColor,
    required this.sliderValue,
    required this.sliderMax,
    required this.sliderEnabled,
    required this.sliderDivisions,
    required this.saving,
    required this.onPrevious,
    required this.onNext,
    required this.onAvatarDoubleTap,
    required this.onReset,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
    required this.onInputChanged,
    required this.onSetToMax,
    required this.showSetToMax,
    required this.partitionBar,
  });

  final BackheaderBudgetItem item;
  final String periodLabel;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final String inputLabel;
  final Color activeColor;
  final double sliderValue;
  final double sliderMax;
  final bool sliderEnabled;
  final int sliderDivisions;
  final bool saving;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onAvatarDoubleTap;
  final VoidCallback onReset;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double> onSliderChangeEnd;
  final ValueChanged<String> onInputChanged;
  final VoidCallback onSetToMax;
  final bool showSetToMax;
  final Widget partitionBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            IconButton(
              key: const ValueKey('limit-card-previous-button'),
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              color: AppColors.gray700,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: onAvatarDoubleTap,
                  child: _LimitAvatar(item: item, color: activeColor),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('limit-card-next-button'),
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.gray700,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              item.title,
              key: const ValueKey('limit-card-title'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gray800,
              ),
            ),
            Container(
              key: const ValueKey('limit-card-period-label'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Text(
                periodLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        partitionBar,
        const SizedBox(height: 14),
        CategoryLimitSlider(
          value: sliderValue,
          max: sliderMax,
          divisions: sliderDivisions,
          activeColor: activeColor,
          enabled: sliderEnabled,
          onChanged: onSliderChanged,
          onChangeEnd: onSliderChangeEnd,
        ),
        if (saving)
          const SizedBox(
            height: 2,
            child: LinearProgressIndicator(color: AppColors.primary),
          )
        else
          const SizedBox(height: 2),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('limit-amount-input'),
          controller: amountController,
          focusNode: amountFocusNode,
          keyboardType: TextInputType.number,
          onChanged: onInputChanged,
          decoration: transactionFieldDecoration(inputLabel).copyWith(
            suffixText: 'Ft',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSetToMax)
                  IconButton(
                    key: const ValueKey('limit-slider-end-button'),
                    onPressed: onSetToMax,
                    icon: const Icon(Icons.last_page),
                    tooltip: 'Max',
                  ),
                IconButton(
                  key: const ValueKey('limit-reset-inline-button'),
                  onPressed: onReset,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Reset',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetLimitSaveButton extends StatelessWidget {
  const _BudgetLimitSaveButton({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const ValueKey('limit-save-button'),
      onPressed: saving ? null : onSave,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(saving ? 'Mentés...' : 'Mentés'),
    );
  }
}

class _LimitAvatar extends StatelessWidget {
  const _LimitAvatar({required this.item, required this.color});

  final BackheaderBudgetItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final icon = _overviewIcon(item.overview?.kind);
    return Container(
      key: const ValueKey('limit-card-avatar'),
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: category == null
          ? Icon(icon, color: AppColors.white, size: 34)
          : Image(
              image: CategoryIconManager.assetImage(category.iconSlot),
              width: 36,
              height: 36,
              color: AppColors.white,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.category_outlined,
                color: AppColors.white,
                size: 34,
              ),
            ),
    );
  }

  IconData _overviewIcon(BudgetGoalKind? kind) {
    return switch (kind) {
      BudgetGoalKind.expenseBudget => Icons.account_balance_wallet_outlined,
      BudgetGoalKind.incomeGoal => Icons.trending_up,
      BudgetGoalKind.savingGoal => Icons.savings_outlined,
      null => Icons.account_balance_wallet_outlined,
    };
  }
}
