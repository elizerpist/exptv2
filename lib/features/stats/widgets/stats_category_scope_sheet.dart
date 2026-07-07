import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../transactions/models/transaction_category.dart';
import '../../transactions/widgets/category_menu/category_icon_badge.dart';

class StatsCategoryScopeSheet extends StatefulWidget {
  const StatsCategoryScopeSheet({
    super.key,
    required this.activeType,
    required this.categories,
    required this.selectedCategoryIds,
    required this.accentColor,
    required this.onApply,
  });

  final TransactionType activeType;
  final List<TransactionCategory> categories;
  final Set<int> selectedCategoryIds;
  final Color accentColor;
  final ValueChanged<Set<int>> onApply;

  @override
  State<StatsCategoryScopeSheet> createState() =>
      _StatsCategoryScopeSheetState();
}

class _StatsCategoryScopeSheetState extends State<StatsCategoryScopeSheet> {
  late final Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedCategoryIds};
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories
        .where((category) => category.normalizedType == widget.activeType)
        .toList();
    return Material(
      key: const ValueKey('stats-scope-sheet'),
      color: AppColors.gray100,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      clipBehavior: Clip.antiAlias,
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
                'Kategória scope',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 14,
                mainAxisExtent: 150,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _StatsScopeCategoryCard(
                  category: category,
                  active: _selected.contains(category.transactionCategoryID),
                  accentColor: widget.accentColor,
                  onTap: () => _toggle(category.transactionCategoryID),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: GestureDetector(
              key: const ValueKey('stats-scope-apply'),
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onApply(Set.unmodifiable(_selected)),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Szűrő beállítása',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(int id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }
}

class _StatsScopeCategoryCard extends StatelessWidget {
  const _StatsScopeCategoryCard({
    required this.category,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('stats-scope-category-${category.transactionCategoryID}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? accentColor.withValues(alpha: 0.12) : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? accentColor : AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 15, 12, 18),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: category.slotColor,
                borderRadius: BorderRadius.circular(32.5),
              ),
              alignment: Alignment.center,
              child: _iconContent(),
            ),
            const Spacer(),
            Text(
              category.name,
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
              active ? 'scope aktív' : 'nincs kiválasztva',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconContent() {
    if (category.iconSlot != null || category.icon != null) {
      return CategoryIconBadge(
        category: category,
        backgroundColor: Colors.transparent,
        size: 65,
        iconSize: 44,
        iconStrokeWidth: 1.35,
        showShadow: false,
      );
    }
    return Text(
      _initial(category.name),
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }
}
