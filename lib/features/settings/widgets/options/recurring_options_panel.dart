import 'package:flutter/material.dart';

import '../../../../core/debug/debug_text_input.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/recurring_transaction.dart';
import '../../../transactions/models/transaction_category.dart';
import '../../../transactions/slots/category_color_resolver.dart';
import '../../../transactions/widgets/category_scroll_picker.dart';
import '../../../transactions/widgets/category_selector_field.dart';
import '../../state/settings_store.dart';
import 'settings_option_widgets.dart';

class RecurringOptionsPanel extends StatefulWidget {
  const RecurringOptionsPanel({super.key, required this.store});

  final SettingsStore store;

  @override
  State<RecurringOptionsPanel> createState() => _RecurringOptionsPanelState();
}

class _RecurringOptionsPanelState extends State<RecurringOptionsPanel> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dayController = TextEditingController(text: '1');
  TransactionCategory? _selectedCategory;
  RecurringTransaction? _editing;
  var _categoryPickerOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.store.expenseCategories.firstOrNull;
  }

  @override
  void didUpdateWidget(covariant RecurringOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedCategory ??= widget.store.expenseCategories.firstOrNull;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(
              title: _editing == null
                  ? 'Új ismétlődő kiadás hozzáadása'
                  : 'Ismétlődő kiadás módosítása',
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _field(
                        label: 'Kiadás neve',
                        controller: _nameController,
                        hint: 'pl. Lakbér, Telefon számla...',
                      ),
                      _field(
                        label: 'Összeg (Ft)',
                        controller: _amountController,
                        hint: 'pl. 50000',
                        keyboardType: TextInputType.number,
                      ),
                      _categoryPicker(),
                      _field(
                        label: 'Hónap napja (1-31)',
                        controller: _dayController,
                        hint: 'pl. 15',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('recurring-save-button'),
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            _editing == null ? 'Hozzáadás' : 'Módosítás',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: 'Meglévő ismétlődő kiadások',
              children: widget.store.recurringTransactions.isEmpty
                  ? const [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Még nincsenek ismétlődő kiadások',
                            style: TextStyle(color: AppColors.gray500),
                          ),
                        ),
                      ),
                    ]
                  : widget.store.recurringTransactions.map((transaction) {
                      final category = CategoryColorResolver.findById(
                        widget.store.expenseCategories,
                        transaction.categoryId,
                      );
                      return _RecurringCard(
                        transaction: transaction,
                        category: category,
                        onEdit: () => _edit(transaction),
                        onToggle: () => widget.store.toggleRecurringTransaction(
                          transaction,
                        ),
                        onDelete: () => widget.store.deleteRecurringTransaction(
                          transaction,
                        ),
                      );
                    }).toList(),
            ),
            const SettingsSection(
              title: 'Információ',
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Az ismétlődő kiadások automatikusan hozzáadódnak a kiválasztott napon minden hónapban. Az inaktív kiadások nem kerülnek automatikusan hozzáadásra.',
                    style: TextStyle(color: AppColors.gray500, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          DebugTextField(
            debugLabel: 'RecurringOptions.$label',
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryPicker() {
    final categories = widget.store.expenseCategories;
    final selected = categories.contains(_selectedCategory)
        ? _selectedCategory
        : categories.firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategória',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          CategorySelectorField(
            selectorKey: const ValueKey('recurring-category-selector'),
            selected: selected,
            onTap: () =>
                setState(() => _categoryPickerOpen = !_categoryPickerOpen),
          ),
          if (_categoryPickerOpen) ...[
            const SizedBox(height: 8),
            CategoryScrollPicker(
              keyPrefix: 'recurring-category',
              categories: categories,
              selected: selected,
              maxHeight: 180,
              onSelected: (value) => setState(() {
                _selectedCategory = value;
                _categoryPickerOpen = false;
              }),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final category =
        _selectedCategory ?? widget.store.expenseCategories.firstOrNull;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final day = int.tryParse(_dayController.text);
    if (category == null || amount == null || day == null) return;
    await widget.store.saveRecurringTransaction(
      id: _editing?.id,
      name: _nameController.text.trim(),
      amount: amount,
      dayOfMonth: day,
      categoryId: category.transactionCategoryID,
      isActive: _editing?.isActive ?? true,
    );
    if (!mounted) return;
    setState(() {
      _editing = null;
      _categoryPickerOpen = false;
      _nameController.clear();
      _amountController.clear();
      _dayController.text = '1';
    });
  }

  void _edit(RecurringTransaction transaction) {
    setState(() {
      _editing = transaction;
      _categoryPickerOpen = false;
      _nameController.text = transaction.name;
      _amountController.text = transaction.amount.toStringAsFixed(0);
      _dayController.text = transaction.dayOfMonth.toString();
      _selectedCategory = widget.store.expenseCategories.firstWhere(
        (category) => category.transactionCategoryID == transaction.categoryId,
        orElse: () => widget.store.expenseCategories.first,
      );
    });
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.transaction,
    required this.category,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final RecurringTransaction transaction;
  final TransactionCategory? category;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          _CategoryColorDot(
            key: ValueKey('recurring-category-color-${transaction.id}'),
            color: CategoryColorResolver.color(
              category: category,
              snapshotHex: transaction.categoryColor,
            ),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.amount.toStringAsFixed(0)} Ft • hónap ${transaction.dayOfMonth}. napja',
                  style: const TextStyle(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onToggle,
            child: Text(transaction.isActive ? 'Aktív' : 'Inaktív'),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.gray600),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}

class _CategoryColorDot extends StatelessWidget {
  const _CategoryColorDot({super.key, required this.color, this.size = 14});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
