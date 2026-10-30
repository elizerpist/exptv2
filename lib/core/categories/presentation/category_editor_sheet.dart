import 'package:flutter/material.dart';

import '../catalog/category_catalog_ids.dart';
import '../catalog/category_color_catalog.dart';
import '../catalog/category_icon_catalog.dart';
import '../domain/category_repository.dart';
import '../domain/fluvi_category.dart';
import 'category_visual_badge.dart';

/// The manual-editor category creator. It persists directly through
/// [CategoryRepository], never through a temporary picker-only list.
Future<FluviCategory?> showCategoryEditorSheet(
  BuildContext context, {
  required CategoryRepository repository,
  FluviCategory? category,
}) => showModalBottomSheet<FluviCategory>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
  ),
  builder: (_) =>
      _CategoryEditorSheet(category: category, repository: repository),
);

final class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({
    required this.category,
    required this.repository,
  });

  final FluviCategory? category;
  final CategoryRepository repository;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

final class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late final TextEditingController _name;
  late String _colorId;
  late String _iconId;
  String? _error;
  bool _saving = false;

  bool get _isCreate => widget.category == null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _name = TextEditingController(text: category?.name ?? '');
    _colorId = category?.colorId ?? CategoryCatalogIds.colorIds.first;
    _iconId = category?.iconId ?? CategoryCatalogIds.iconIds.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Adj meg egy kategórianevet.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.category;
      final saved = existing == null
          ? await widget.repository.createCategory(
              name: name,
              colorId: _colorId,
              iconId: _iconId,
            )
          : await widget.repository.updateCategory(
              id: existing.id,
              name: name,
              colorId: _colorId,
              iconId: _iconId,
            );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'A kategória mentése nem sikerült. Ellenőrizd a nevet.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isCreate ? 'Új kategória' : 'Kategória szerkesztése',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Center(
          child: CategoryVisualBadge(
            colorHandle: CategoryColorCatalog.handleOf(_colorId),
            iconHandle: CategoryIconCatalog.handleOf(_iconId),
            size: 76,
            iconSize: 38,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          key: const ValueKey<String>('category-editor-name-input'),
          controller: _name,
          autofocus: _isCreate,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Kategória neve',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 20),
        const Text('Szín', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final colorId in CategoryCatalogIds.colorIds)
              _ColorChoice(
                colorId: colorId,
                selected: colorId == _colorId,
                onTap: () => setState(() => _colorId = colorId),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        SizedBox(
          height: 206,
          child: GridView.builder(
            key: const ValueKey<String>('category-editor-icon-grid'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: CategoryCatalogIds.iconIds.length,
            itemBuilder: (context, index) {
              final iconId = CategoryCatalogIds.iconIds[index];
              return _IconChoice(
                iconId: iconId,
                colorId: _colorId,
                selected: iconId == _iconId,
                onTap: () => setState(() => _iconId = iconId),
              );
            },
          ),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Color(0xffc9465c))),
        ],
        const SizedBox(height: 18),
        FilledButton(
          key: const ValueKey<String>('category-editor-save'),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Mentés…' : 'Mentés'),
        ),
      ],
    ),
  );
}

final class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.colorId,
    required this.selected,
    required this.onTap,
  });

  final String colorId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final token = CategoryColorCatalog.resolve(colorId);
    return Semantics(
      selected: selected,
      label: 'Szín ${token.id}',
      child: InkWell(
        key: ValueKey<String>('category-editor-color-$colorId'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: token.gradient,
            border: Border.all(
              color: selected ? const Color(0xff18233d) : Colors.white,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

final class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconId,
    required this.colorId,
    required this.selected,
    required this.onTap,
  });

  final String iconId;
  final String colorId;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = CategoryColorCatalog.resolve(colorId).middleColor;
    return Semantics(
      selected: selected,
      label: '${CategoryIconCatalog.resolve(iconId).semanticName} ikon',
      child: InkWell(
        key: ValueKey<String>('category-editor-icon-$iconId'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: .18) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : const Color(0xffe1e6ef),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: CategoryVisualBadge(
              colorHandle: CategoryColorCatalog.handleOf(colorId),
              iconHandle: CategoryIconCatalog.handleOf(iconId),
              size: 24,
              iconSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
