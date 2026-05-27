import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../state/transaction_store.dart';
import 'amount_field.dart';
import 'category_selector_field.dart';
import 'date_time_fields.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    required this.store,
    this.initialTransaction,
    this.onClose,
  });

  final TransactionStore store;
  final TransactionRecord? initialTransaction;
  final VoidCallback? onClose;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  TransactionCategory? _category;
  String? _error;
  var _saving = false;

  bool get _editing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    _resetFields();
  }

  @override
  void didUpdateWidget(AddTransactionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTransaction?.id != widget.initialTransaction?.id) {
      _resetFields();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final type = widget.initialTransaction?.type ?? widget.store.activeType;
        final categories = widget.store.categories
            .where((category) => category.normalizedType == type)
            .toList();
        _category = _resolvedCategory(categories);

        return Container(
          key: const ValueKey('transaction-editor-card'),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                offset: const Offset(0, -2),
                blurRadius: 12,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Text(
                                _title(type),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _close,
                              icon: const Icon(Icons.close, size: 20),
                              color: AppColors.gray500,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _name,
                          decoration: transactionFieldDecoration(
                            'Tranzakció neve',
                          ),
                        ),
                        const SizedBox(height: 12),
                        AmountField(controller: _amount),
                        const SizedBox(height: 12),
                        CategorySelectorField(
                          categories: categories,
                          selected: _category,
                          onChanged: (value) => setState(() => _category = value),
                        ),
                        const SizedBox(height: 12),
                        DateTimeFields(
                          dateController: _date,
                          timeController: _time,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.expense),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text(_saving ? 'Mentés...' : 'Mentés'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _resetFields() {
    final transaction = widget.initialTransaction;
    if (transaction == null) {
      final now = DateTime.now();
      _name.clear();
      _amount.clear();
      _date.text = _formatDate(now);
      _time.text = _formatTime(now);
      _category = _firstActiveCategory();
    } else {
      _name.text = transaction.displayMerchant;
      _amount.text = transaction.amount.abs().toStringAsFixed(0);
      _date.text = transaction.normalizedDate;
      _time.text = transaction.displayTime;
      _category = _categoryById(transaction.transactionCategoryID);
    }
    _error = null;
    _saving = false;
  }

  String _title(TransactionType type) {
    if (_editing) {
      return type == TransactionType.income
          ? 'Bevételi tranzakció módosítása'
          : 'Kiadási tranzakció módosítása';
    }
    return type == TransactionType.income
        ? 'Új bevételi tranzakció'
        : 'Új kiadási tranzakció';
  }

  TransactionCategory? _firstActiveCategory() {
    final categories = widget.store.activeCategories;
    return categories.isEmpty ? null : categories.first;
  }

  TransactionCategory? _categoryById(int id) {
    for (final category in widget.store.categories) {
      if (category.transactionCategoryID == id) return category;
    }
    return null;
  }

  TransactionCategory? _resolvedCategory(List<TransactionCategory> categories) {
    if (categories.isEmpty) return null;
    final selectedId = _category?.transactionCategoryID;
    if (selectedId != null) {
      for (final category in categories) {
        if (category.transactionCategoryID == selectedId) return category;
      }
    }
    return categories.first;
  }

  Future<void> _save() async {
    final merchant = _name.text.trim();
    final amount = double.tryParse(_amount.text.trim().replaceAll(' ', ''));
    final category = _category;
    final type = widget.initialTransaction?.type ?? widget.store.activeType;
    if (merchant.isEmpty || amount == null || category == null) {
      setState(() => _error = 'Hiányzó vagy hibás adat');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final initial = widget.initialTransaction;
      if (initial == null) {
        await widget.store.addTransaction(
          merchant: merchant,
          amount: amount,
          type: type,
          categoryId: category.transactionCategoryID,
          date: _date.text.trim(),
          time: _time.text.trim(),
        );
      } else {
        await widget.store.updateTransaction(
          initial,
          merchant: merchant,
          amount: amount,
          type: type,
          categoryId: category.transactionCategoryID,
          date: _date.text.trim(),
          time: _time.text.trim(),
        );
      }
      if (mounted) _close();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  void _close() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
