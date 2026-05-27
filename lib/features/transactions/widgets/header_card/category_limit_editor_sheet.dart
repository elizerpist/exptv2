import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/limit_partition_manager.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/transaction_record.dart';
import '../amount_field.dart';
import 'category_budget_bar.dart';
import 'category_limit_partition_bar.dart';
import 'category_limit_slider.dart';
import 'category_progress_bar.dart';

typedef CategoryLimitSave =
    Future<void> Function({
      required double limitAmount,
      required bool alertActive,
    });

class CategoryLimitEditorSheet extends StatefulWidget {
  const CategoryLimitEditorSheet({
    super.key,
    required this.bar,
    required this.onCancel,
    required this.onSave,
    this.allBars = const [],
  });

  final CategoryBudgetBarData bar;
  final List<CategoryBudgetBarData> allBars;
  final VoidCallback onCancel;
  final CategoryLimitSave onSave;

  @override
  State<CategoryLimitEditorSheet> createState() =>
      _CategoryLimitEditorSheetState();
}

class _CategoryLimitEditorSheetState extends State<CategoryLimitEditorSheet> {
  late final TextEditingController _controller;
  late bool _alertActive;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.bar.limitAmount > 0
          ? widget.bar.limitAmount.round().toString()
          : '',
    );
    _controller.addListener(() => setState(() {}));
    _alertActive = widget.bar.alertActive;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewBar;
    final hasLimit = preview.hasLimit;
    final partitionBars = _partitionBars;
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
                '${widget.bar.title} limit',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 16),
              CategoryBudgetBar(bar: preview, compactIcon: true, onTap: () {}),
              if (hasLimit) ...[
                const SizedBox(height: 10),
                _RemainingBar(bar: preview),
              ],
              const SizedBox(height: 16),
              CategoryLimitPartitionBar(
                bars: partitionBars,
                activeBar: widget.bar,
                activeLimitAmount: _amount,
              ),
              const SizedBox(height: 6),
              CategoryLimitSlider(
                value: _amount,
                max: _sliderMaxAmount(partitionBars),
                divisions: _sliderDivisions(partitionBars),
                activeColor: widget.bar.color,
                onChanged: _setAmountFromSlider,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('limit-amount-input'),
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: transactionFieldDecoration(
                  'Kategória limit',
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

  CategoryBudgetBarData get _previewBar {
    final amount = _amount;
    final hasLimit = amount > 0;
    return CategoryBudgetBarData(
      key: widget.bar.key,
      targetType: widget.bar.targetType,
      targetId: widget.bar.targetId,
      transactionType: widget.bar.transactionType,
      window: widget.bar.window,
      periodKey: widget.bar.periodKey,
      title: widget.bar.title,
      spent: widget.bar.spent,
      hasLimit: hasLimit,
      limitAmount: hasLimit ? amount : 0,
      alertActive: hasLimit && _alertActive,
      color: widget.bar.color,
      iconSlot: widget.bar.iconSlot,
      category: widget.bar.category,
      sourceLimit: widget.bar.sourceLimit,
    );
  }

  List<CategoryBudgetBarData> get _partitionBars {
    final bars = widget.allBars.isEmpty ? <CategoryBudgetBarData>[] : widget.allBars;
    final hasCurrent = bars.any((bar) => _sameTarget(bar, widget.bar));
    if (hasCurrent) return bars;
    return [widget.bar, ...bars];
  }

  double get _amount {
    final value = _controller.text.trim().replaceAll(' ', '');
    return double.tryParse(value) ?? 0;
  }

  double _sliderMaxAmount(List<CategoryBudgetBarData> bars) {
    return LimitPartitionManager.sliderMaxAmount(
      bars,
      activeBar: widget.bar,
      activeLimitAmount: _amount,
    );
  }

  int _sliderDivisions(List<CategoryBudgetBarData> bars) {
    return LimitPartitionManager.sliderDivisions(
      bars,
      activeBar: widget.bar,
      activeLimitAmount: _amount,
    );
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
    await widget.onSave(
      limitAmount: _amount,
      alertActive: _amount > 0 && _alertActive,
    );
    if (mounted) setState(() => _saving = false);
  }
}

class _RemainingBar extends StatelessWidget {
  const _RemainingBar({required this.bar});

  final CategoryBudgetBarData bar;

  @override
  Widget build(BuildContext context) {
    final over = bar.remaining < 0;
    final color = over ? const Color(0xffdc2626) : const Color(0xff10b981);
    final title = over ? 'Túllépés' : 'Még elkölthető';
    final amount = formatHuf(bar.remaining.abs());
    final denominator = bar.limitAmount <= 0 ? 1.0 : bar.limitAmount;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 15, right: 20),
      child: Stack(
        children: [
          Row(
            children: [
              Icon(
                over ? Icons.error_outline : Icons.check_circle_outline,
                color: AppColors.white,
                size: 35,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 60,
            right: 20,
            bottom: 22,
            child: CategoryProgressBar(
              spent: bar.remaining.abs(),
              limitAmount: denominator,
              fillColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
