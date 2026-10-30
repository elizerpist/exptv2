import 'package:flutter/material.dart';

import '../../assets/prepared_vector_asset_atlas.dart';
import '../../presentation/child_editor_sheet.dart';
import '../catalog/category_catalog_ids.dart';
import '../catalog/category_color_catalog.dart';
import '../catalog/category_icon_catalog.dart';
import '../domain/category_repository.dart';
import '../domain/fluvi_category.dart';
import 'category_icon_view.dart';
import 'category_visual_badge.dart';

/// The manual-editor category creator. It persists directly through
/// [CategoryRepository], never through a temporary picker-only list.
Future<FluviCategory?> showCategoryEditorSheet(
  BuildContext context, {
  required CategoryRepository repository,
  FluviCategory? category,
}) => showFluviChildEditorSheet<FluviCategory>(
  context,
  builder: (_) =>
      _CategoryEditorSheet(category: category, repository: repository),
);

enum _CategoryEditorTab { color, icon }

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
  static const _colorsPerPage = 5;
  static const _iconsPerPage = 8;

  late final TextEditingController _name;
  late final PageController _colorPages;
  late final PageController _iconPages;
  late String _colorId;
  late String _iconId;
  _CategoryEditorTab _tab = _CategoryEditorTab.color;
  String? _nameError;
  String? _error;
  bool _saving = false;
  int _colorPage = 0;
  int _iconPage = 0;

  bool get _isCreate => widget.category == null;

  int _pageFor(String id, List<String> ids, int perPage) {
    final index = ids.indexOf(id);
    return index < 0 ? 0 : index ~/ perPage;
  }

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _name = TextEditingController(text: category?.name ?? '');
    _colorId = category?.colorId ?? CategoryCatalogIds.colorIds.first;
    _iconId = category?.iconId ?? CategoryCatalogIds.iconIds.first;
    _colorPage = _pageFor(
      _colorId,
      CategoryCatalogIds.colorIds,
      _colorsPerPage,
    );
    _iconPage = _pageFor(_iconId, CategoryCatalogIds.iconIds, _iconsPerPage);
    _colorPages = PageController(
      initialPage: _colorPage,
      viewportFraction: .91,
    );
    _iconPages = PageController(initialPage: _iconPage);
  }

  @override
  void dispose() {
    _name.dispose();
    _colorPages.dispose();
    _iconPages.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Adj meg egy kategórianevet.');
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
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
  Widget build(BuildContext context) => ChildEditorSheetFrame(
    title: _isCreate ? 'Új kategória' : 'Kategória szerkesztése',
    avatar: CategoryVisualBadge(
      colorHandle: CategoryColorCatalog.handleOf(_colorId),
      iconHandle: CategoryIconCatalog.handleOf(_iconId),
      size: 72,
      iconSize: 31,
    ),
    nameController: _name,
    nameLabel: 'Kategória neve',
    nameFieldKey: const ValueKey<String>('category-editor-name-input'),
    cancelKey: const ValueKey<String>('category-editor-cancel'),
    saveKey: const ValueKey<String>('category-editor-save'),
    nameError: _nameError,
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
        _CategorySegmentedControl(
          active: _tab,
          colorId: _colorId,
          iconId: _iconId,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: 16),
        SizedBox(
          key: const ValueKey<String>('category-editor-picker-region'),
          height: 180,
          child: _tab == _CategoryEditorTab.color
              ? _ColorPicker(
                  controller: _colorPages,
                  page: _colorPage,
                  selectedColorId: _colorId,
                  onPageChanged: (page) => setState(() => _colorPage = page),
                  onSelected: (colorId) => setState(() => _colorId = colorId),
                )
              : _IconPicker(
                  controller: _iconPages,
                  page: _iconPage,
                  colorId: _colorId,
                  selectedIconId: _iconId,
                  onPageChanged: (page) => setState(() => _iconPage = page),
                  onSelected: (iconId) => setState(() => _iconId = iconId),
                ),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Color(0xffc9465c))),
        ],
      ],
    ),
  );
}

final class _CategorySegmentedControl extends StatelessWidget {
  const _CategorySegmentedControl({
    required this.active,
    required this.colorId,
    required this.iconId,
    required this.onChanged,
  });

  final _CategoryEditorTab active;
  final String colorId;
  final String iconId;
  final ValueChanged<_CategoryEditorTab> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xffeceef7),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: _SegmentTab(
            key: const ValueKey<String>('category-editor-color-tab'),
            selected: active == _CategoryEditorTab.color,
            label: 'Szín',
            preview: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: CategoryColorCatalog.resolve(colorId).gradient,
              ),
              child: const SizedBox(width: 14, height: 14),
            ),
            onTap: () => onChanged(_CategoryEditorTab.color),
          ),
        ),
        Expanded(
          child: _SegmentTab(
            key: const ValueKey<String>('category-editor-icon-tab'),
            selected: active == _CategoryEditorTab.icon,
            label: 'Ikon',
            preview: _CatalogIcon(iconId: iconId, size: 17),
            onTap: () => onChanged(_CategoryEditorTab.icon),
          ),
        ),
      ],
    ),
  );
}

final class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    super.key,
    required this.selected,
    required this.label,
    required this.preview,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label választó',
    child: Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            preview,
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? ChildEditorSheetTokens.primary
                    : ChildEditorSheetTokens.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.controller,
    required this.page,
    required this.selectedColorId,
    required this.onPageChanged,
    required this.onSelected,
  });

  final PageController controller;
  final int page;
  final String selectedColorId;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onSelected;

  static const _perPage = 5;

  @override
  Widget build(BuildContext context) {
    final colors = CategoryCatalogIds.colorIds;
    final pageCount = (colors.length / _perPage).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Válassz színt',
          style: TextStyle(
            color: ChildEditorSheetTokens.primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            key: const ValueKey<String>('category-editor-color-pages'),
            controller: controller,
            padEnds: false,
            itemCount: pageCount,
            onPageChanged: onPageChanged,
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * _perPage;
              final pageColors = colors.skip(start).take(_perPage).toList();
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final colorId in pageColors)
                        _ColorChoice(
                          colorId: colorId,
                          selected: colorId == selectedColorId,
                          onTap: () => onSelected(colorId),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _PageIndicator(page: page, count: pageCount),
      ],
    );
  }
}

final class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.controller,
    required this.page,
    required this.colorId,
    required this.selectedIconId,
    required this.onPageChanged,
    required this.onSelected,
  });

  final PageController controller;
  final int page;
  final String colorId;
  final String selectedIconId;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<String> onSelected;

  static const _perPage = 8;

  @override
  Widget build(BuildContext context) {
    final icons = CategoryCatalogIds.iconIds;
    final pageCount = (icons.length / _perPage).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Válassz ikont',
          style: TextStyle(
            color: ChildEditorSheetTokens.primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            key: const ValueKey<String>('category-editor-icon-pages'),
            controller: controller,
            itemCount: pageCount,
            onPageChanged: onPageChanged,
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * _perPage;
              final pageIcons = icons.skip(start).take(_perPage).toList();
              return GridView.count(
                primary: false,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.28,
                children: [
                  for (final iconId in pageIcons)
                    _IconChoice(
                      iconId: iconId,
                      colorId: colorId,
                      selected: iconId == selectedIconId,
                      onTap: () => onSelected(iconId),
                    ),
                ],
              );
            },
          ),
        ),
        _PageIndicator(page: page, count: pageCount),
      ],
    );
  }
}

final class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.page, required this.count});

  final int page;
  final int count;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 16,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: index == page ? 14 : 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: index == page
                  ? ChildEditorSheetTokens.secondary
                  : const Color(0xffcdd2dd),
              borderRadius: BorderRadius.circular(99),
            ),
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
    final foreground = token.middleColor.computeLuminance() > .55
        ? ChildEditorSheetTokens.primary
        : Colors.white;
    return Semantics(
      selected: selected,
      label: 'Szín ${token.id}',
      child: InkResponse(
        key: ValueKey<String>('category-editor-color-$colorId'),
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? ChildEditorSheetTokens.primary : Colors.white,
              width: selected ? 2 : 0,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: token.gradient,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: selected
                ? Icon(Icons.check_rounded, color: foreground, size: 23)
                : null,
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
      child: Material(
        color: selected
            ? color.withValues(alpha: .18)
            : const Color(0xfff3f4fa),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey<String>('category-editor-icon-$iconId'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? color : const Color(0xffdddff0),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: _CatalogIcon(
                      iconId: iconId,
                      size: 26,
                      color: selected ? color : const Color(0xff475569),
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _CatalogIcon extends StatelessWidget {
  const _CatalogIcon({
    required this.iconId,
    required this.size,
    this.color = ChildEditorSheetTokens.secondary,
  });

  final String iconId;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CategoryIconView(
      picture: PreparedVectorAssetAtlas.instance.categoryIcon(
        CategoryIconCatalog.handleOf(iconId),
      ),
      size: size,
      color: color,
    ),
  );
}
