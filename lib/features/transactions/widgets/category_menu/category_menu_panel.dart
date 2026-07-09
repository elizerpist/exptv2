import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/transaction_category.dart';
import 'category_card.dart';

class CategoryMenuSheetRequest {
  const CategoryMenuSheetRequest({
    required this.cardKey,
    required this.panelKey,
    required this.debugLabel,
    required this.topOffset,
    required this.activeType,
    required this.activeCategory,
    required this.selectedCategoryIds,
    required this.onSelect,
    required this.onApply,
    required this.onModify,
    required this.onDelete,
    required this.onAdd,
    required this.onClosed,
  });

  final Key cardKey;
  final Key panelKey;
  final String debugLabel;
  final double topOffset;
  final TransactionType activeType;
  final TransactionCategory? activeCategory;
  final Set<int> selectedCategoryIds;
  final ValueChanged<TransactionCategory> onSelect;
  final ValueChanged<Set<int>> onApply;
  final ValueChanged<TransactionCategory> onModify;
  final ValueChanged<TransactionCategory> onDelete;
  final VoidCallback onAdd;
  final VoidCallback onClosed;
}

typedef CategoryMenuSheetRequested =
    void Function(CategoryMenuSheetRequest request);

class CategoryMenuPanel extends StatefulWidget {
  const CategoryMenuPanel({
    super.key,
    required this.activeType,
    required this.categories,
    required this.categoryTransactionCounts,
    required this.activeCategory,
    required this.onSelect,
    required this.onModify,
    required this.onDelete,
    required this.onAdd,
    required this.onClose,
    this.selectedCategoryIds,
    this.onApply,
    this.surfaceColor = AppColors.white,
    this.cardSurfaceColor = AppColors.white,
    this.cardSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.avatarSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.accentColor = AppColors.primary,
    this.addButtonPlacement = CategoryMenuAddButtonPlacement.card,
  });

  final TransactionType activeType;
  final List<TransactionCategory> categories;
  final Map<int, int> categoryTransactionCounts;
  final TransactionCategory? activeCategory;
  final Set<int>? selectedCategoryIds;
  final ValueChanged<TransactionCategory> onSelect;
  final ValueChanged<TransactionCategory> onModify;
  final ValueChanged<TransactionCategory> onDelete;
  final VoidCallback onAdd;
  final VoidCallback onClose;
  final ValueChanged<Set<int>>? onApply;
  final Color surfaceColor;
  final Color cardSurfaceColor;
  final ExpenseSurfaceInteraction cardSurfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final Color accentColor;
  final CategoryMenuAddButtonPlacement addButtonPlacement;

  @override
  State<CategoryMenuPanel> createState() => _CategoryMenuPanelState();
}

enum CategoryMenuAddButtonPlacement { card, topFab, bottomPill }

class _CategoryMenuPanelState extends State<CategoryMenuPanel> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = _initialSelection();
  }

  @override
  void didUpdateWidget(covariant CategoryMenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeType != widget.activeType ||
        oldWidget.activeCategory?.transactionCategoryID !=
            widget.activeCategory?.transactionCategoryID ||
        oldWidget.selectedCategoryIds != widget.selectedCategoryIds) {
      _selected = _initialSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.categories
        .where((category) => category.normalizedType == widget.activeType)
        .toList();
    return ColoredBox(
      color: widget.surfaceColor,
      child: Column(
        children: [
          const SizedBox(height: 12),
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
          const SizedBox(
            height: 54,
            child: Center(
              child: Text(
                'Válassz kategóriát',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: KeyedSubtree(
                key: const ValueKey('category-menu-scroll-body'),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 150,
                  ),
                  itemCount: filtered.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _CategoryUtilityCard(
                        key: const ValueKey('category-menu-all-card'),
                        title: 'Minden kategória',
                        subtitle: _selected.isEmpty
                            ? 'szűrés aktív'
                            : 'egyedi szűrő',
                        avatarLabel: 'ALL',
                        avatarColor: widget.accentColor,
                        active: _selected.isEmpty,
                        surfaceColor: widget.cardSurfaceColor,
                        surfaceStyle: widget.cardSurfaceStyle,
                        avatarSurfaceStyle: widget.avatarSurfaceStyle,
                        accentColor: widget.accentColor,
                        onTap: _selectAll,
                      );
                    }
                    if (index == 1) {
                      return _CategoryUtilityCard(
                        key: const ValueKey('category-menu-add-card'),
                        title: 'Új kategória',
                        subtitle: 'hozzáadás',
                        icon: Icons.add_rounded,
                        avatarColor: widget.accentColor,
                        active: false,
                        surfaceColor: widget.cardSurfaceColor,
                        surfaceStyle: widget.cardSurfaceStyle,
                        avatarSurfaceStyle: widget.avatarSurfaceStyle,
                        accentColor: widget.accentColor,
                        onTap: widget.onAdd,
                      );
                    }
                    final category = filtered[index - 2];
                    final id = category.transactionCategoryID;
                    final count = widget.categoryTransactionCounts[id] ?? 0;
                    return CategoryCard(
                      category: category,
                      transactionCount: count,
                      active: _selected.contains(id),
                      onSelect: _toggleCategory,
                      onModify: widget.onModify,
                      onDelete: widget.onDelete,
                      surfaceColor: widget.cardSurfaceColor,
                      cardSurfaceStyle: widget.cardSurfaceStyle,
                      avatarSurfaceStyle: widget.avatarSurfaceStyle,
                      accentColor: widget.accentColor,
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.paddingOf(context).bottom + 8,
            ),
            child: ExpenseSurfaceButton(
              buttonKey: const ValueKey('category-menu-apply-button'),
              label: 'Szűrőbeállítás',
              onPressed: _apply,
              surfaceStyle: widget.avatarSurfaceStyle,
              color: widget.accentColor,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Set<int> _initialSelection() {
    final selected = widget.selectedCategoryIds;
    if (selected != null) return {...selected};
    final active = widget.activeCategory;
    if (active == null) return <int>{};
    return <int>{active.transactionCategoryID};
  }

  void _toggleCategory(TransactionCategory category) {
    if (widget.onApply == null) {
      widget.onSelect(category);
      return;
    }
    final id = category.transactionCategoryID;
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _selectAll() {
    setState(_selected.clear);
  }

  void _apply() {
    final onApply = widget.onApply;
    if (onApply == null) {
      widget.onClose();
      return;
    }
    onApply(_normalizedSelection());
  }

  Set<int> _normalizedSelection() {
    if (_selected.isEmpty) return const <int>{};
    final filteredIds = widget.categories
        .where((category) => category.normalizedType == widget.activeType)
        .map((category) => category.transactionCategoryID)
        .toSet();
    final allFilteredSelected =
        filteredIds.length > 1 &&
        filteredIds.length == _selected.length &&
        _selected.containsAll(filteredIds);
    if (allFilteredSelected) return const <int>{};
    return Set<int>.unmodifiable(_selected);
  }
}

class _CategoryUtilityCard extends StatelessWidget {
  const _CategoryUtilityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.avatarColor,
    required this.active,
    required this.surfaceColor,
    required this.surfaceStyle,
    required this.avatarSurfaceStyle,
    required this.accentColor,
    required this.onTap,
    this.avatarLabel,
    this.icon,
  });

  final String title;
  final String subtitle;
  final String? avatarLabel;
  final IconData? icon;
  final Color avatarColor;
  final bool active;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final activeUsesInset = active && surfaceStyle.hasPressEffect;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ExpensePressable(
        enabled: surfaceStyle.hasPressEffect,
        forcePressed: activeUsesInset,
        builder: (context, pressed) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ExpenseSurfaceContainer(
                surfaceKey: ValueKey('category-utility-surface-$title'),
                style: surfaceStyle,
                color: surfaceColor,
                borderRadius: radius,
                pressed: pressed,
                padding: const EdgeInsets.fromLTRB(12, 15, 12, 18),
                neutralBorder: Border.all(color: AppColors.gray200),
                neutralShadow: categoryNeutralShadow(surfaceStyle),
                child: Column(
                  children: [
                    ExpensePressable(
                      enabled: avatarSurfaceStyle.hasPressEffect,
                      forcePressed: active && avatarSurfaceStyle.hasPressEffect,
                      builder: (context, avatarPressed) {
                        return ExpenseSurfaceContainer(
                          surfaceKey: ValueKey(
                            'category-utility-avatar-surface-$title',
                          ),
                          style: avatarSurfaceStyle,
                          color: avatarColor,
                          primary: true,
                          primaryColor: avatarColor,
                          borderRadius: BorderRadius.circular(32.5),
                          pressed: avatarPressed,
                          width: 65,
                          height: 65,
                          child: Center(
                            child: avatarLabel == null
                                ? Icon(icon, color: AppColors.white, size: 34)
                                : Text(
                                    avatarLabel!,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              if (active && !surfaceStyle.hasPressEffect)
                CategoryActiveBorder(
                  key: ValueKey('category-utility-active-border-$title'),
                  radius: radius,
                  color: accentColor,
                ),
            ],
          );
        },
      ),
    );
  }
}
