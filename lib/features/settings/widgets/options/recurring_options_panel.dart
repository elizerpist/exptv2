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
  var _selectedType = TransactionType.expense;
  var _categoryPickerOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.store.categoriesFor(_selectedType).firstOrNull;
  }

  @override
  void didUpdateWidget(covariant RecurringOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedCategory = _resolveSelectedCategory(
      widget.store.categoriesFor(_selectedType),
    );
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
              title: _editing == null ? _newSectionTitle : _editSectionTitle,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _typeSelector(),
                      const SizedBox(height: 16),
                      _field(
                        label: _selectedType == TransactionType.income
                            ? 'Bevétel neve'
                            : 'Kiadás neve',
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
              title: 'Meglévő ismétlődő tranzakciók',
              children: widget.store.recurringTransactions.isEmpty
                  ? const [
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Még nincsenek ismétlődő tranzakciók',
                            style: TextStyle(color: AppColors.gray500),
                          ),
                        ),
                      ),
                    ]
                  : widget.store.recurringTransactions.map((transaction) {
                      final category = CategoryColorResolver.findById(
                        widget.store.categories,
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
                    'Az ismétlődő bevételek és kiadások automatikusan hozzáadódnak a kiválasztott napon minden hónapban. Az inaktív tételek nem kerülnek automatikusan hozzáadásra.',
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

  String get _newSectionTitle => _selectedType == TransactionType.income
      ? 'Új ismétlődő bevétel hozzáadása'
      : 'Új ismétlődő kiadás hozzáadása';

  String get _editSectionTitle => _selectedType == TransactionType.income
      ? 'Ismétlődő bevétel módosítása'
      : 'Ismétlődő kiadás módosítása';

  Widget _typeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TypeChoice(
            key: const ValueKey('recurring-type-expense'),
            label: 'Kiadás',
            selected: _selectedType == TransactionType.expense,
            color: AppColors.expense,
            onTap: () => _selectType(TransactionType.expense),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TypeChoice(
            key: const ValueKey('recurring-type-income'),
            label: 'Bevétel',
            selected: _selectedType == TransactionType.income,
            color: AppColors.income,
            onTap: () => _selectType(TransactionType.income),
          ),
        ),
      ],
    );
  }

  void _selectType(TransactionType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      _categoryPickerOpen = false;
      _selectedCategory = widget.store.categoriesFor(type).firstOrNull;
    });
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
    final categories = widget.store.categoriesFor(_selectedType);
    final selected = _resolveSelectedCategory(categories);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedType == TransactionType.income
                ? 'Bevételi kategória'
                : 'Kiadási kategória',
            style: const TextStyle(
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

  TransactionCategory? _resolveSelectedCategory(
    List<TransactionCategory> categories,
  ) {
    if (categories.isEmpty) return null;
    final selected = _selectedCategory;
    if (selected != null &&
        selected.normalizedType == _selectedType &&
        categories.any(
          (category) =>
              category.transactionCategoryID == selected.transactionCategoryID,
        )) {
      return selected;
    }
    return categories.first;
  }

  Future<void> _save() async {
    final category =
        _selectedCategory ??
        widget.store.categoriesFor(_selectedType).firstOrNull;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final day = int.tryParse(_dayController.text);
    if (category == null || amount == null || day == null) return;
    await widget.store.saveRecurringTransaction(
      id: _editing?.id,
      name: _nameController.text.trim(),
      amount: amount,
      transactionType: _selectedType,
      dayOfMonth: day,
      categoryId: category.transactionCategoryID,
      isActive: _editing?.isActive ?? true,
    );
    if (!mounted) return;
    setState(() {
      _editing = null;
      _categoryPickerOpen = false;
      _selectedCategory = widget.store.categoriesFor(_selectedType).firstOrNull;
      _nameController.clear();
      _amountController.clear();
      _dayController.text = '1';
    });
  }

  void _edit(RecurringTransaction transaction) {
    setState(() {
      _editing = transaction;
      _selectedType = transaction.transactionType;
      _categoryPickerOpen = false;
      _nameController.text = transaction.name;
      _amountController.text = transaction.amount.toStringAsFixed(0);
      _dayController.text = transaction.dayOfMonth.toString();
      final categories = widget.store.categoriesFor(
        transaction.transactionType,
      );
      _selectedCategory = categories.isEmpty
          ? null
          : categories.firstWhere(
              (category) =>
                  category.transactionCategoryID == transaction.categoryId,
              orElse: () => categories.first,
            );
    });
  }
}

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.gray100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color : AppColors.gray200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.gray600,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
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
                  '${transaction.transactionType.label} • ${transaction.amount.toStringAsFixed(0)} Ft • hónap ${transaction.dayOfMonth}. napja',
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
