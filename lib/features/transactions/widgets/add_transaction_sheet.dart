import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../state/transaction_store.dart';
import 'amount_field.dart';
import 'category_selector_field.dart';
import 'category_scroll_picker.dart';
import 'date_time_fields.dart';
import 'slide_up_menu_card.dart';

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
  final _categoryPickerBoundaryKey = GlobalKey();
  TransactionCategory? _category;
  String? _error;
  var _saving = false;
  var _categoryPickerOpen = false;

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

        return SlideUpMenuCard(
          cardKey: const ValueKey('transaction-editor-card'),
          debugLabel: _editing ? 'EditTransaction' : 'AddTransaction',
          panelHeight: _panelHeightFor(context),
          dragExclusionKeys: _categoryPickerOpen
              ? [_categoryPickerBoundaryKey]
              : const <GlobalKey>[],
          onDismissed: _close,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Builder(
              builder: (context) {
                final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: keyboardInset + 24,
                  ),
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
                      const SizedBox(height: 12),
                      Text(
                        _title(type),
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
                        decoration: transactionFieldDecoration(
                          'Tranzakció neve',
                        ),
                      ),
                      const SizedBox(height: 16),
                      AmountField(controller: _amount),
                      const SizedBox(height: 16),
                      CategorySelectorField(
                        selected: _category,
                        onTap: _openCategoryPicker,
                      ),
                      if (_categoryPickerOpen) ...[
                        const SizedBox(height: 8),
                        CategoryScrollPicker(
                          key: _categoryPickerBoundaryKey,
                          keyPrefix: 'transaction-category',
                          categories: categories,
                          selected: _category,
                          onSelected: _selectCategory,
                        ),
                      ],
                      const SizedBox(height: 16),
                      DateTimeFields(
                        dateController: _date,
                        timeController: _time,
                        onPickDate: _pickDate,
                        onPickTime: _pickTime,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.expense),
                        ),
                      ],
                      const SizedBox(height: 20),
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
                );
              },
            ),
          ),
        );
      },
    );
  }


  double _panelHeightFor(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final compactHeight = math.min(448.0, screenHeight * 0.50);
    final pickerHeight = math.min(560.0, math.max(500.0, screenHeight * 0.62));
    final baseHeight = _categoryPickerOpen ? pickerHeight : compactHeight;
    final requested = baseHeight + math.min(keyboardInset, 180.0);
    return requested.clamp(0.0, screenHeight).toDouble();
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
    _categoryPickerOpen = false;
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

  void _openCategoryPicker() {
    setState(() => _categoryPickerOpen = !_categoryPickerOpen);
  }

  void _selectCategory(TransactionCategory category) {
    setState(() {
      _category = category;
      _categoryPickerOpen = false;
    });
  }

  Future<void> _pickDate() async {
    final initialDate = _parseDate(_date.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _date.text = _formatDate(picked));
  }

  Future<void> _pickTime() async {
    final initialTime = _parseTime(_time.text) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _time.text = _formatTimeOfDay(picked));
  }

  Future<void> _save() async {
    final merchant = _name.text.trim();
    final amount = double.tryParse(_amount.text.trim().replaceAll(' ', ''));
    final category = _category;
    final type = widget.initialTransaction?.type ?? widget.store.activeType;
    final date = _normalizeDate(_date.text);
    final time = _normalizeTime(_time.text);
    if (merchant.isEmpty ||
        amount == null ||
        category == null ||
        date == null ||
        time == null) {
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
          date: date,
          time: time,
        );
      } else {
        await widget.store.updateTransaction(
          initial,
          merchant: merchant,
          amount: amount,
          type: type,
          categoryId: category.transactionCategoryID,
          date: date,
          time: time,
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

  String? _normalizeDate(String value) {
    final parsed = _parseDate(value);
    return parsed == null ? null : _formatDate(parsed);
  }

  String? _normalizeTime(String value) {
    final parsed = _parseTime(value);
    return parsed == null ? null : _formatTimeOfDay(parsed);
  }

  DateTime? _parseDate(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[./]'), '-');
    final parts = normalized.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
