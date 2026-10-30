import 'package:flutter/material.dart';

import '../../../core/categories/catalog/category_color_catalog.dart';
import '../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../core/categories/domain/fluvi_category.dart';
import '../../../core/categories/presentation/category_visual_badge.dart';
import '../../../core/design/dashboard_mode_palette.dart';
import 'manual_transaction_editor_field_rows.dart';
import 'manual_transaction_inline_picker_panel.dart';

/// A category picker which can be used as the legacy route-local menu or as
/// the editor's in-flow panel. The latter is opt-in so existing automation
/// forms retain their established menu presentation.
final class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.onCreate,
    this.label = 'Kategória',
    this.enabled = true,
    this.inline = false,
    this.expanded = false,
    this.onExpandedChanged,
  });

  final List<FluviCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelected;
  final Future<void> Function()? onCreate;
  final String label;
  final bool enabled;
  final bool inline;
  final bool expanded;
  final ValueChanged<bool>? onExpandedChanged;

  @override
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

final class _CategoryDropdownState extends State<CategoryDropdown> {
  final MenuController _controller = MenuController();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  List<FluviCategory> get _visibleCategories {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.categories;
    return widget.categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  FluviCategory? get _selected {
    final selectedById = widget.categories.cast<FluviCategory?>().firstWhere(
      (category) => category?.id == widget.selectedCategoryId,
      orElse: () => null,
    );
    return selectedById ??
        widget.categories.cast<FluviCategory?>().firstWhere(
          (category) => category?.isSystemUncategorized ?? false,
          orElse: () => null,
        );
  }

  void _toggleInline() {
    if (!widget.enabled) return;
    // Opening a list ends any existing amount/note text session. It never
    // transfers focus to the list search; only a user tap does that.
    if (!widget.expanded) FocusManager.instance.primaryFocus?.unfocus();
    widget.onExpandedChanged?.call(!widget.expanded);
  }

  Widget _anchor({required bool expanded, VoidCallback? onTap}) =>
      ManualEditorSelectionRow(
        key: const ValueKey('manual-category-dropdown-anchor'),
        label: widget.label,
        value: _selected?.name ?? 'Kategorizálatlan',
        leading: _selected == null
            ? const ManualEditorIconSurface(
                icon: Icons.category_outlined,
                color: Color(0xff64748b),
                background: Color(0xfff1f5f9),
              )
            : _CategoryAvatar(category: _selected!, size: 40),
        enabled: widget.enabled,
        expanded: expanded,
        onTap: onTap,
      );

  Widget _inlinePanel() => ManualTransactionInlinePickerPanel(
    searchController: _search,
    searchFocusNode: _searchFocus,
    searchFieldKey: const ValueKey('manual-category-search'),
    searchHint: 'Kategória keresése',
    emptyMessage: 'Nincs találat.',
    itemCount: _visibleCategories.length,
    itemExtent: 58,
    createLabel: 'Új kategória',
    createActionKey: const ValueKey('manual-category-create-action'),
    onCreate: widget.onCreate == null
        ? null
        : () async {
            widget.onExpandedChanged?.call(false);
            await widget.onCreate!();
          },
    itemBuilder: (context, index) {
      final category = _visibleCategories[index];
      final selected =
          category.id == widget.selectedCategoryId ||
          (widget.selectedCategoryId == null && category.isSystemUncategorized);
      return _PickerCategoryRow(
        key: ValueKey('manual-category-${category.id}'),
        category: category,
        selected: selected,
        onTap: () {
          widget.onExpandedChanged?.call(false);
          widget.onSelected(category.id);
        },
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    if (widget.inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _anchor(expanded: widget.expanded, onTap: _toggleInline),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: widget.expanded ? _inlinePanel() : const SizedBox.shrink(),
          ),
        ],
      );
    }

    final availableHeight =
        (MediaQuery.sizeOf(context).height -
                MediaQuery.viewInsetsOf(context).bottom -
                24)
            .clamp(180, 340)
            .toDouble();
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
                  focusNode: _searchFocus,
                  autofocus: false,
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
      builder: (context, controller, _) => _anchor(
        expanded: controller.isOpen,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

final class _PickerCategoryRow extends StatelessWidget {
  const _PickerCategoryRow({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FluviCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xffe6faf2) : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            _CategoryAvatar(category: category, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FluviVisualTokens.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selected) const ManualTransactionPickerCheck(),
          ],
        ),
      ),
    ),
  );
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
    iconSize: size * .43,
  );
}
