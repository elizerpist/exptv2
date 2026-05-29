import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/budget_progress_manager.dart';
import '../../data/limit_partition_manager.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';
import '../../models/transaction_record.dart';
import '../amount_field.dart';
import 'category_budget_bar.dart';
import 'category_limit_partition_bar.dart';
import 'category_limit_slider.dart';

class BudgetTargetEditorSheet extends StatefulWidget {
  const BudgetTargetEditorSheet({
    super.key,
    required this.item,
    required this.categoryBars,
    required this.periodIncome,
    required this.onCancel,
    required this.onSaveOverview,
    required this.onSaveCategory,
    this.overviewItems = const [],
  });

  final BackheaderBudgetItem item;
  final List<CategoryBudgetBarData> categoryBars;
  final List<OverviewBudgetData> overviewItems;
  final double periodIncome;
  final VoidCallback onCancel;
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
  late bool _alertActive;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final amount = _initialLimitAmount;
    _controller = TextEditingController(
      text: amount > 0 ? amount.round().toString() : '',
    );
    _controller.addListener(() => setState(() {}));
    _alertActive = _initialAlertActive;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewCategory = _previewCategoryBar;
    final overview = widget.item.overview;
    final category = widget.item.category;
    final hasLimit = _amount > 0;
    final partitionBars = _partitionBars;
    final sliderMax = _sliderMaxAmount(partitionBars);
    return SafeArea(
      child: Material(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.item.title} limit',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 16),
              if (previewCategory != null)
                CategoryBudgetBar(
                  bar: previewCategory,
                  compactIcon: true,
                  onTap: () {},
                )
              else if (overview != null)
                _OverviewTargetPreviewBar(
                  overview: overview,
                  amount: _amount,
                ),
              if (overview?.kind != BudgetGoalKind.savingGoal) ...[
                const SizedBox(height: 16),
                CategoryLimitPartitionBar(
                  bars: partitionBars,
                  activeBar: category,
                  activeLimitAmount: category == null ? null : _amount,
                  overviewLimitAmount: _overviewLimitAmount,
                ),
              ],
              const SizedBox(height: 6),
              CategoryLimitSlider(
                value: _amount,
                max: sliderMax,
                divisions: _sliderDivisions(sliderMax),
                activeColor: _activeColor,
                onChanged: _setAmountFromSlider,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('limit-amount-input'),
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: transactionFieldDecoration(
                  _inputLabel,
                ).copyWith(suffixText: 'Ft'),
              ),
              if (hasLimit)
                TextButton.icon(
                  key: const ValueKey('limit-reset-button'),
                  onPressed: () => _controller.clear(),
                  icon: const Icon(
                    Icons.refresh_outlined,
                    size: 20,
                    color: AppColors.gray500,
                  ),
                  label: const Text(
                    'Limit törlése',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    key: const ValueKey('limit-alert-toggle'),
                    onPressed: hasLimit
                        ? () => setState(() => _alertActive = !_alertActive)
                        : null,
                    icon: Icon(
                      _alertActive && hasLimit
                          ? Icons.notifications
                          : Icons.notifications_none_outlined,
                      color: hasLimit ? AppColors.primary : AppColors.gray400,
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : widget.onCancel,
                      child: const Text('Mégse'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const ValueKey('limit-save-button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: _saving ? null : _save,
                      child: const Text('Mentés'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _initialLimitAmount {
    final overview = widget.item.overview;
    if (overview != null && overview.hasLimit) return overview.limitAmount;
    final category = widget.item.category;
    if (category != null && category.hasLimit) return category.limitAmount;
    return 0;
  }

  bool get _initialAlertActive {
    final overview = widget.item.overview;
    if (overview != null) return overview.alertActive;
    return widget.item.category?.alertActive ?? false;
  }

  double get _amount {
    final value = _controller.text.trim().replaceAll(' ', '');
    return double.tryParse(value) ?? 0;
  }

  String get _inputLabel {
    final overview = widget.item.overview;
    if (overview == null) return 'Kategória limit';
    return switch (overview.kind) {
      BudgetGoalKind.expenseBudget => 'Budget limit',
      BudgetGoalKind.incomeGoal => 'Bevételi cél',
      BudgetGoalKind.savingGoal => 'Megtakarítási cél',
    };
  }

  Color get _activeColor {
    final category = widget.item.category;
    if (category != null) return category.color;
    final overview = widget.item.overview;
    return switch (overview?.kind) {
      BudgetGoalKind.expenseBudget => AppColors.primary,
      BudgetGoalKind.incomeGoal => AppColors.income,
      BudgetGoalKind.savingGoal => BudgetProgressManager.savingColor,
      null => AppColors.primary,
    };
  }

  double? get _overviewLimitAmount {
    final overview = widget.item.overview;
    if (overview != null) return _amount > 0 ? _amount : null;
    return _matchingOverviewLimitForCategory();
  }

  CategoryBudgetBarData? get _previewCategoryBar {
    final category = widget.item.category;
    if (category == null) return null;
    final amount = _amount;
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
      alertActive: hasLimit && _alertActive,
      color: category.color,
      iconSlot: category.iconSlot,
      category: category.category,
      sourceLimit: category.sourceLimit,
    );
  }

  List<CategoryBudgetBarData> get _partitionBars {
    final preview = _previewCategoryBar;
    final bars = widget.categoryBars.isEmpty
        ? <CategoryBudgetBarData>[]
        : widget.categoryBars;
    if (preview == null) return bars;
    final replaced = <CategoryBudgetBarData>[];
    var found = false;
    for (final bar in bars) {
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

  double _sliderMaxAmount(List<CategoryBudgetBarData> partitionBars) {
    final overview = widget.item.overview;
    if (overview != null) {
      final fallback = _amount <= 0 ? 10000.0 : _amount;
      return math.max(math.max(widget.periodIncome, overview.amount), fallback)
          .toDouble();
    }
    final category = widget.item.category;
    if (category != null) {
      final overviewLimit = _matchingOverviewLimitForCategory();
      if (overviewLimit > 0) {
        final available = BudgetProgressManager.availableCategoryLimit(
          overviewLimit: overviewLimit,
          categoryBars: widget.categoryBars,
          activeBar: category,
        );
        return math.max(available, _amount <= 0 ? 1.0 : _amount).toDouble();
      }
      return LimitPartitionManager.sliderMaxAmount(
        partitionBars,
        activeBar: category,
        activeLimitAmount: _amount,
      );
    }
    return 10000;
  }

  int _sliderDivisions(double sliderMax) {
    if (sliderMax <= 1) return 1;
    final step = sliderMax >= 100000 ? 10000 : 1000;
    return math.max(1, (sliderMax / step).round()).toInt();
  }

  double _matchingOverviewLimitForCategory() {
    final category = widget.item.category;
    if (category == null) return 0;
    for (final overview in widget.overviewItems) {
      if (overview.kind == BudgetGoalKind.savingGoal) continue;
      if (overview.kind.transactionType != category.transactionType.nativeValue) {
        continue;
      }
      return overview.hasLimit ? overview.limitAmount : 0;
    }
    return 0;
  }

  void _setAmountFromSlider(double amount) {
    final roundedAmount = amount.round();
    final text = roundedAmount <= 0 ? '' : roundedAmount.toString();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  bool _sameTarget(CategoryBudgetBarData left, CategoryBudgetBarData right) {
    return left.targetType == right.targetType &&
        left.targetId == right.targetId &&
        left.transactionType == right.transactionType &&
        left.window == right.window &&
        left.periodKey == right.periodKey;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final amount = _amount < 0 ? 0.0 : _amount;
    final overview = widget.item.overview;
    final category = widget.item.category;
    if (overview != null) {
      await widget.onSaveOverview(
        overview.kind,
        limitAmount: amount,
        alertActive: amount > 0 && _alertActive,
      );
    } else if (category != null) {
      await widget.onSaveCategory(
        category,
        limitAmount: amount,
        alertActive: amount > 0 && _alertActive,
      );
    }
    if (mounted) setState(() => _saving = false);
  }
}

class _OverviewTargetPreviewBar extends StatelessWidget {
  const _OverviewTargetPreviewBar({
    required this.overview,
    required this.amount,
  });

  final OverviewBudgetData overview;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final color = switch (overview.kind) {
      BudgetGoalKind.expenseBudget => AppColors.primary,
      BudgetGoalKind.incomeGoal => AppColors.income,
      BudgetGoalKind.savingGoal => BudgetProgressManager.savingColor,
    };
    final icon = switch (overview.kind) {
      BudgetGoalKind.expenseBudget => Icons.account_balance_wallet_outlined,
      BudgetGoalKind.incomeGoal => Icons.trending_up,
      BudgetGoalKind.savingGoal => Icons.savings_outlined,
    };
    final limit = amount > 0 ? amount : overview.limitAmount;
    final ratio = limit > 0 ? (overview.amount / limit).clamp(0.0, 1.0) : 1.0;
    final amountText = limit > 0
        ? '${formatHuf(overview.amount)} / ${formatHuf(limit)}'
        : formatHuf(overview.amount);
    return Material(
      key: const ValueKey('category-budget-bar'),
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: color.withValues(alpha: 0.30)),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.toDouble(),
                child: ColoredBox(color: color),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.white, size: 35),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        overview.kind.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amountText,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
