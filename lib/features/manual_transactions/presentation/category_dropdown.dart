import 'package:flutter/material.dart';

import '../../../core/categories/catalog/category_color_catalog.dart';
import '../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/category_visual_badge.dart';

/// A route-local anchored category picker. It returns only an ID; each caller
/// owns whether that means a partner default or an entry override.
final class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.onCreate,
    this.label = 'Kategória',
    this.enabled = true,
  });

  final List<FluviCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelected;
  final Future<void> Function()? onCreate;
  final String label;
  final bool enabled;

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

final class _CategoryDropdownState extends State<CategoryDropdown> {
  final MenuController _controller = MenuController();
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<FluviCategory> get _visibleCategories {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.categories;
    return widget.categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                24)
            .clamp(180, 340)
            .toDouble();
    final selected = widget.categories.cast<FluviCategory?>().firstWhere(
      (category) => category?.id == widget.selectedCategoryId,
      orElse: () => null,
    );
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(0, 8),
      menuChildren: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: availableHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: TextField(
                  key: const ValueKey('manual-category-search'),
                  controller: _search,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Kategória keresése',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final category in _visibleCategories)
                        MenuItemButton(
                          leadingIcon: _CategoryAvatar(
                            category: category,
                            size: 28,
                          ),
                          trailingIcon: category.id == widget.selectedCategoryId
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onPressed: () {
                            _controller.close();
                            widget.onSelected(category.id);
                          },
                          child: Text(category.name),
                        ),
                      if (_visibleCategories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Nincs találat.'),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.onCreate != null) ...[
                const Divider(height: 1),
                MenuItemButton(
                  key: const ValueKey('manual-category-create-action'),
                  leadingIcon: const Icon(Icons.add_rounded),
                  onPressed: () async {
                    _controller.close();
                    await widget.onCreate!();
                  },
                  child: const Text('Új kategória'),
                ),
              ],
            ],
          ),
        ),
      ],
      builder: (context, controller, _) => Semantics(
        button: true,
        label: '${widget.label} kiválasztása',
        child: InkWell(
          key: const ValueKey('manual-category-dropdown-anchor'),
          borderRadius: BorderRadius.circular(16),
          onTap: widget.enabled
              ? () => controller.isOpen ? controller.close() : controller.open()
              : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              enabled: widget.enabled,
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: selected == null
                ? const Text('Kategorizálatlan')
                : Row(
                    children: [
                      _CategoryAvatar(category: selected, size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Text(selected.name)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

final class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.category, required this.size});
  final FluviCategory category;
  final double size;

  @override
  Widget build(BuildContext context) => CategoryVisualBadge(
    colorHandle: CategoryColorCatalog.handleOf(category.colorId),
    iconHandle: CategoryIconCatalog.handleOf(category.iconId),
    size: size,
    iconSize: 17,
  );
}
