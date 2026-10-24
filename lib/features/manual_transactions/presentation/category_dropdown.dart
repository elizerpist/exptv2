import 'package:flutter/material.dart';

import '../../../core/categories/domain/fluvi_category.dart';

/// A route-local anchored category picker. It returns only an ID; each caller
/// owns whether that means a partner default or an entry override.
final class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.label = 'Kategória',
    this.enabled = true,
  });

  final List<FluviCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelected;
  final String label;
  final bool enabled;

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

final class _CategoryDropdownState extends State<CategoryDropdown> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final selected = widget.categories.cast<FluviCategory?>().firstWhere(
      (category) => category?.id == widget.selectedCategoryId,
      orElse: () => null,
    );
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(0, 8),
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 304),
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final category in widget.categories)
                  MenuItemButton(
                    leadingIcon: _CategoryAvatar(category: category, size: 28),
                    trailingIcon: category.id == widget.selectedCategoryId
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onPressed: () {
                      _controller.close();
                      widget.onSelected(category.id);
                    },
                    child: Text(category.name),
                  ),
              ],
            ),
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
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: category.visual.gradient.gradient,
      borderRadius: BorderRadius.circular(size * .3),
    ),
    child: const Icon(Icons.category_rounded, color: Colors.white, size: 17),
  );
}
