import 'package:flutter/material.dart';

import '../../../core/categories/catalog/category_color_catalog.dart';
import '../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/category_visual_badge.dart';
import '../../../core/presentation/child_editor_sheet.dart';
import '../domain/manual_transaction_models.dart';
import '../domain/manual_transaction_repository.dart';

/// Opens the partner child editor. Existing partners commit globally; a new
/// partner is returned as a draft and is persisted only with its transaction.
Future<ManualPartnerSelection?> showPartnerEditorPopup(
  BuildContext context, {
  required ManualTransactionRepository repository,
  required List<FluviCategory> categories,
  PartnerDirectoryEntry? existing,
  String initialName = '',
}) => showFluviChildEditorSheet<ManualPartnerSelection>(
  context,
  builder: (_) => _PartnerEditorPopup(
    repository: repository,
    categories: categories,
    existing: existing,
    initialName: initialName,
  ),
);

final class _PartnerEditorPopup extends StatefulWidget {
  const _PartnerEditorPopup({
    required this.repository,
    required this.categories,
    required this.existing,
    required this.initialName,
  });
  final ManualTransactionRepository repository;
  final List<FluviCategory> categories;
  final PartnerDirectoryEntry? existing;
  final String initialName;

  @override
  State<_PartnerEditorPopup> createState() => _PartnerEditorPopupState();
}

final class _PartnerEditorPopupState extends State<_PartnerEditorPopup> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.displayName ?? widget.initialName,
  );
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _categoryScroll = ScrollController();
  String? _categoryId;
  bool _saving = false;
  String? _nameError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categoryId =
        widget.existing?.defaultCategoryId ??
        widget.categories
            .where((category) => category.isSystemUncategorized)
            .firstOrNull
            ?.id ??
        (widget.categories.isEmpty ? null : widget.categories.first.id);
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _name.dispose();
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocus.dispose();
    _categoryScroll.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  FluviCategory? get _selectedCategory {
    for (final category in widget.categories) {
      if (category.id == _categoryId) return category;
    }
    return null;
  }

  List<FluviCategory> get _visibleCategories {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.categories;
    return widget.categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  bool get _showsInheritanceNotice {
    final existing = widget.existing;
    return existing != null && _categoryId != existing.defaultCategoryId;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final categoryId = _categoryId;
    if (name.isEmpty) {
      setState(() => _nameError = 'Adj meg egy partnernevet.');
      return;
    }
    if (categoryId == null) {
      setState(() => _error = 'Válassz alapértelmezett kategóriát.');
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
      _error = null;
    });
    try {
      final existing = widget.existing;
      if (existing == null) {
        if (mounted) {
          Navigator.of(context).pop(
            NewManualPartner(displayName: name, defaultCategoryId: categoryId),
          );
        }
        return;
      }
      final updated = await widget.repository.updatePartner(
        partnerId: existing.partnerId,
        displayNameOverride: name == existing.originalName ? null : name,
        defaultCategoryId: categoryId,
      );
      if (mounted) {
        Navigator.of(context).pop(ExistingManualPartner(updated.partnerId));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'A partner mentése nem sikerült: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = _selectedCategory;
    return ChildEditorSheetFrame(
      title: widget.existing == null ? 'Új partner' : 'Partner szerkesztése',
      avatar: CategoryVisualBadge(
        colorHandle: CategoryColorCatalog.handleOf(
          category?.colorId ?? 'fallback',
        ),
        iconHandle: CategoryIconCatalog.handleOf(
          category?.iconId ?? 'fallback',
        ),
        size: 72,
        iconSize: 31,
      ),
      nameController: _name,
      nameLabel: 'Partner neve',
      nameFieldKey: const ValueKey<String>('partner-editor-name-input'),
      cancelKey: const ValueKey<String>('partner-editor-cancel'),
      saveKey: const ValueKey<String>('partner-editor-save'),
      nameError: _nameError,
      textCapitalization: TextCapitalization.words,
      saving: _saving,
      onCancel: () => Navigator.of(context).pop(),
      onSave: _save,
      onNameChanged: (_) {
        if (_nameError != null || _error != null) {
          setState(() {
            _nameError = null;
            _error = null;
          });
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Alapértelmezett kategória',
            style: TextStyle(
              color: ChildEditorSheetTokens.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey<String>('partner-editor-category-search'),
            controller: _search,
            focusNode: _searchFocus,
            autofocus: false,
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: ChildEditorSheetTokens.neutralSurface,
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: ChildEditorSheetTokens.secondary,
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 44),
              hintText: 'Kategória keresése',
              hintStyle: TextStyle(
                color: ChildEditorSheetTokens.secondary,
                fontSize: 15,
              ),
              constraints: BoxConstraints(minHeight: 44),
              contentPadding: EdgeInsets.symmetric(vertical: 11),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: ChildEditorSheetTokens.save),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _showsInheritanceNotice ? 104 : 184,
            child: _CategoryList(
              controller: _categoryScroll,
              categories: _visibleCategories,
              selectedCategoryId: _categoryId,
              onSelected: (id) => setState(() {
                _categoryId = id;
                _error = null;
              }),
            ),
          ),
          if (_showsInheritanceNotice) ...[
            const SizedBox(height: 10),
            const _PartnerInheritanceNotice(),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 10),
            Text(error, style: const TextStyle(color: Color(0xffc9465c))),
          ],
        ],
      ),
    );
  }
}

final class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.controller,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final ScrollController controller;
  final List<FluviCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'Nincs találat.',
          style: TextStyle(color: ChildEditorSheetTokens.secondary),
        ),
      );
    }
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: ListView.separated(
        controller: controller,
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: ChildEditorSheetTokens.border),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _PartnerCategoryRow(
            key: ValueKey<String>('partner-editor-category-${category.id}'),
            category: category,
            selected: category.id == selectedCategoryId,
            onTap: () => onSelected(category.id),
          );
        },
      ),
    );
  }
}

final class _PartnerCategoryRow extends StatelessWidget {
  const _PartnerCategoryRow({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FluviCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Material(
      color: selected ? const Color(0xffe6faf2) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CategoryVisualBadge(
                colorHandle: CategoryColorCatalog.handleOf(category.colorId),
                iconHandle: CategoryIconCatalog.handleOf(category.iconId),
                size: 36,
                iconSize: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ChildEditorSheetTokens.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xff20b7a3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

final class _PartnerInheritanceNotice extends StatelessWidget {
  const _PartnerInheritanceNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ChildEditorSheetTokens.neutralSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            color: ChildEditorSheetTokens.secondary,
            size: 17,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'A módosítás az öröklő tranzakciókat és ismétlődő szabályokat is érintheti. Az egyedi felülírások megmaradnak.',
            style: TextStyle(
              color: ChildEditorSheetTokens.secondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

extension on Iterable<FluviCategory> {
  FluviCategory? get firstOrNull => isEmpty ? null : first;
}
