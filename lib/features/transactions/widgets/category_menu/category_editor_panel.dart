import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_category.dart';
import 'category_preview_pill.dart';
import 'category_slot_grid.dart';

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.type,
    required this.colorSlot,
    required this.iconSlot,
    this.id,
  });

  final int? id;
  final String name;
  final TransactionType type;
  final int colorSlot;
  final int iconSlot;
}

class CategoryEditorPanel extends StatefulWidget {
  const CategoryEditorPanel({
    super.key,
    required this.activeType,
    required this.onSave,
    required this.onClose,
    this.initialCategory,
    this.onDelete,
  });

  final TransactionType activeType;
  final TransactionCategory? initialCategory;
  final ValueChanged<CategoryDraft> onSave;
  final ValueChanged<TransactionCategory>? onDelete;
  final VoidCallback onClose;

  @override
  State<CategoryEditorPanel> createState() => _CategoryEditorPanelState();
}

class _CategoryEditorPanelState extends State<CategoryEditorPanel> {
  late final TextEditingController _name;
  late int _colorSlot;
  late int _iconSlot;
  var _page = 0;
  String? _error;
  double _dragDx = 0;

  bool get _editing => widget.initialCategory != null;

  @override
  void initState() {
    super.initState();
    final category = widget.initialCategory;
    _name = TextEditingController(text: category?.name ?? '');
    _colorSlot = category?.colorSlot ?? 0;
    _iconSlot = category?.iconSlot ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _editing
        ? 'Kategória módosítása'
        : widget.activeType == TransactionType.income
        ? 'Új bevételi kategória'
        : 'Új kiadási kategória';
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.gray200,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
              if (_editing && widget.onDelete != null)
                Positioned(
                  right: 12,
                  child: IconButton(
                    key: const ValueKey('category-editor-delete-button'),
                    onPressed: () => widget.onDelete!(widget.initialCategory!),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.expense,
                    ),
                    splashRadius: 22,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Kategória neve',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('category-name-input'),
                  controller: _name,
                  decoration: InputDecoration(
                    hintText: 'pl. Utazás, Hobbi...',
                    hintStyle: const TextStyle(color: AppColors.gray500),
                    filled: true,
                    fillColor: AppColors.gray100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
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
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      _page == 0 ? 'Válassz színt' : 'Válassz ikont',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    SizedBox.square(
                      dimension: 32,
                      child: IconButton(
                        key: const ValueKey('category-slot-toggle-button'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.gray100,
                          foregroundColor: AppColors.gray700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.gray200),
                          ),
                        ),
                        onPressed: _toggleSlotPage,
                        icon: Icon(
                          _page == 0
                              ? Icons.grid_view_rounded
                              : Icons.palette_outlined,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  key: const ValueKey('category-slot-page-view'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => _dragDx = 0,
                  onHorizontalDragUpdate: (details) {
                    _dragDx += details.delta.dx;
                  },
                  onHorizontalDragEnd: (_) {
                    if (_dragDx.abs() > 80) {
                      setState(() => _page = _page == 0 ? 1 : 0);
                    }
                    _dragDx = 0;
                  },
                  child: SizedBox(
                    height: 170,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 120),
                      child: _page == 0
                          ? CategorySlotGrid.colors(
                              key: const ValueKey('color-slot-grid'),
                              selectedSlot: _colorSlot,
                              onSelected: (slot) =>
                                  setState(() => _colorSlot = slot),
                            )
                          : CategorySlotGrid.icons(
                              key: const ValueKey('icon-slot-grid'),
                              selectedSlot: _iconSlot,
                              onSelected: (slot) =>
                                  setState(() => _iconSlot = slot),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Előnézet',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                CategoryPreviewPill(
                  name: _name.text,
                  colorSlot: _colorSlot,
                  iconSlot: _iconSlot,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.expense),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  key: const ValueKey('category-save-button'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Mentés'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _toggleSlotPage() {
    setState(() => _page = _page == 0 ? 1 : 0);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'A kategória neve kötelező');
      return;
    }
    widget.onSave(
      CategoryDraft(
        id: widget.initialCategory?.transactionCategoryID,
        name: name,
        type: widget.initialCategory?.normalizedType ?? widget.activeType,
        colorSlot: _colorSlot,
        iconSlot: _iconSlot,
      ),
    );
  }
}
