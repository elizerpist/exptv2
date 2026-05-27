import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../state/transaction_store.dart';
import 'amount_field.dart';
import 'category_selector_field.dart';
import 'date_time_fields.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, required this.store});

  final TransactionStore store;

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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date.text = _formatDate(now);
    _time.text = _formatTime(now);
    _category = _firstActiveCategory();
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
    final type = widget.store.activeType;
    final categories = widget.store.activeCategories;
    _category = _resolvedCategory(categories);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              type == TransactionType.income
                  ? 'Új bevételi tranzakció'
                  : 'Új kiadási tranzakció',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              decoration: transactionFieldDecoration('Tranzakció neve'),
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
            DateTimeFields(dateController: _date, timeController: _time),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.expense)),
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
  }

  TransactionCategory? _firstActiveCategory() {
    final categories = widget.store.activeCategories;
    return categories.isEmpty ? null : categories.first;
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
    if (merchant.isEmpty || amount == null || category == null) {
      setState(() => _error = 'Hiányzó vagy hibás adat');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.store.addTransaction(
        merchant: merchant,
        amount: amount,
        type: widget.store.activeType,
        categoryId: category.transactionCategoryID,
        date: _date.text.trim(),
        time: _time.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
