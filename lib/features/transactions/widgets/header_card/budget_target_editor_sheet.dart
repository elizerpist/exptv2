import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

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
import 'category_limit_partition_bar.dart';
import 'category_limit_slider.dart';

class BudgetTargetEditorSheet extends StatefulWidget {
  const BudgetTargetEditorSheet({
    super.key,
    required this.item,
    required this.items,
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
  late String _activeKey;
  Timer? _saveDebounce;
  final _rememberedSliderMaxByKey = <String, double>{};
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _activeKey = widget.item.key;
    final amount = _limitAmountFor(widget.item);
    _controller = TextEditingController(
      text: amount > 0 ? amount.round().toString() : '',
    );
    _controller.addListener(_refreshFromController);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _controller
      ..removeListener(_refreshFromController)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideUpMenuCard(
      cardKey: const ValueKey('budget-target-editor-card'),
      onDismissed: widget.onCancel,
      child: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            final contentHeight = constraints.maxHeight - keyboardInset - 44;
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: keyboardInset + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: contentHeight < 0 ? 0 : contentHeight,
                ),
                child: IntrinsicHeight(
                  child: _BudgetLimitCard(
                    item: _activeItem,
                    amountController: _controller,
                    inputLabel: _inputLabel,
                    activeColor: _activeColor,
                    sliderValue: _sliderRange.value,
                    sliderMax: _sliderRange.max,
                    sliderEnabled: _sliderRange.enabled,
                    sliderDivisions: _sliderRange.divisions,
                    saving: _saving,
                    onPrevious: _selectPrevious,
                    onNext: _selectNext,
                    onReset: _resetLimit,
                    onSliderChanged: _setAmountFromSlider,
                    onSliderChangeEnd: _saveSliderAmount,
                    onInputChanged: _scheduleInputSave,
                    onSetToMax: _setOverviewToMax,
                    showSetToMax: _activeItem.overview != null,
                    partitionBar: _buildPartitionBar(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
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
    final maxAllowed = LimitAllocationManager.categorySliderMax(
      overviewLimit: overviewLimit,
      bars: widget.categoryBars,
      activeBar: category,
    );
    return LimitSliderRange.constrained(
      amount: _amount,
      rememberedMax: remembered,
      maxAllowed: maxAllowed,
      hasExistingLimit: category.limitAmount > 0 || _amount > 0,
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
    final category = _activeItem.category;
    if (category == null) return widget.categoryBars;
    final preview = _previewCategoryBar(category);
    final replaced = <CategoryBudgetBarData>[];
    var found = false;
    for (final bar in widget.categoryBars) {
      if (_sameTarget(bar, preview)) {
        replaced.add(preview);
        found = true;
      } else {
        replaced.add(bar);
      }
    }
    if (!found) replaced.insert(0, preview);
    return replaced;
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
      height: 29.4,
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
    _saveDebounce?.cancel();
    _activeKey = item.key;
    _setControllerAmount(_limitAmountFor(item));
    setState(() {});
    widget.onActiveItemChanged(item);
  }

  void _refreshFromController() {
    _rememberSliderMax(_amount);
    if (mounted) setState(() {});
  }

  void _scheduleInputSave(String _) {
    final key = _activeKey;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      _saveAmount(_amount, itemKey: key);
    });
  }

  void _resetLimit() {
    _saveDebounce?.cancel();
    _setControllerAmount(0);
    unawaited(_saveAmount(0));
  }

  void _setAmountFromSlider(double amount) {
    final snapped = LimitAllocationManager.snapSliderAmount(amount)
        .clamp(0.0, _sliderRange.max)
        .toDouble();
    _setControllerAmount(snapped);
  }

  void _saveSliderAmount(double amount) {
    _saveDebounce?.cancel();
    final snapped = LimitAllocationManager.snapSliderAmount(amount)
        .clamp(0.0, _sliderRange.max)
        .toDouble();
    _setControllerAmount(snapped);
    unawaited(_saveAmount(snapped));
  }

  void _setOverviewToMax() {
    _saveDebounce?.cancel();
    final max = math.max(0.0, widget.periodIncome).toDouble();
    _setControllerAmount(max);
    unawaited(_saveAmount(max));
  }

  void _selectPrevious() => _selectAdjacent(-1);

  void _selectNext() => _selectAdjacent(1);

  void _selectAdjacent(int direction) {
    final items = _items;
    if (items.length < 2) return;
    final index = items.indexWhere((item) => item.key == _activeKey);
    final currentIndex = index < 0 ? 0 : index;
    final nextIndex = (currentIndex + direction + items.length) % items.length;
    final next = items[nextIndex];
    _selectItem(next);
  }

  void _setControllerAmount(double amount) {
    _rememberSliderMax(amount);
    final roundedAmount = amount.round();
    final text = roundedAmount <= 0 ? '' : roundedAmount.toString();
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _rememberSliderMax(double amount) {
    final current = _rememberedSliderMaxByKey[_activeKey] ?? 0;
    if (amount > current) {
      _rememberedSliderMaxByKey[_activeKey] = amount;
    }
  }

  Future<void> _saveAmount(double rawAmount, {String? itemKey}) async {
    final item = _itemForKey(itemKey ?? _activeKey);
    final amount = math.max(0.0, rawAmount).toDouble();
    if (mounted) setState(() => _saving = true);
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
    if (mounted) setState(() => _saving = false);
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

  CategoryBudgetBarData _previewCategoryBar(CategoryBudgetBarData category) {
    final hasLimit = _amount > 0;
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
      limitAmount: hasLimit ? _amount : 0,
      alertActive: false,
      color: category.color,
      iconSlot: category.iconSlot,
      category: category.category,
      sourceLimit: category.sourceLimit,
    );
  }

  double _matchingOverviewLimitForCategory(CategoryBudgetBarData category) {
    for (final overview in widget.overviewItems) {
      if (overview.kind == BudgetGoalKind.savingGoal) continue;
      if (overview.kind.transactionType != category.transactionType.nativeValue) {
        continue;
      }
      return overview.hasLimit ? overview.limitAmount : 0;
    }
    return 0;
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
    required this.amountController,
    required this.inputLabel,
    required this.activeColor,
    required this.sliderValue,
    required this.sliderMax,
    required this.sliderEnabled,
    required this.sliderDivisions,
    required this.saving,
    required this.onPrevious,
    required this.onNext,
    required this.onReset,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
    required this.onInputChanged,
    required this.onSetToMax,
    required this.showSetToMax,
    required this.partitionBar,
  });

  final BackheaderBudgetItem item;
  final TextEditingController amountController;
  final String inputLabel;
  final Color activeColor;
  final double sliderValue;
  final double sliderMax;
  final bool sliderEnabled;
  final int sliderDivisions;
  final bool saving;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
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
              constraints: const BoxConstraints.tightFor(
                width: 44,
                height: 44,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _LimitAvatar(item: item, color: activeColor),
                  const SizedBox(height: 10),
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
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('limit-card-next-button'),
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.gray700,
              constraints: const BoxConstraints.tightFor(
                width: 44,
                height: 44,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey('limit-amount-input'),
          controller: amountController,
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
                  icon: const Icon(Icons.refresh_outlined),
                  tooltip: 'Reset',
                ),
              ],
            ),
          ),
        ),
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
        partitionBar,
        const Spacer(),
      ],
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
