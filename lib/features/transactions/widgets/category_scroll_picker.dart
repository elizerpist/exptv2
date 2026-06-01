import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';

class CategoryScrollPicker extends StatelessWidget {
  const CategoryScrollPicker({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.keyPrefix,
    this.maxHeight = fourRowHeight,
  });

  static const visibleRowCount = 4;
  static const itemExtent = 48.0;
  static const verticalPadding = 8.0;
  static const separatorExtent = 1.0;
  static const fourRowHeight =
      verticalPadding * 2 +
      itemExtent * visibleRowCount +
      separatorExtent * (visibleRowCount - 1);

  final List<TransactionCategory> categories;
  final TransactionCategory? selected;
  final ValueChanged<TransactionCategory> onSelected;
  final String keyPrefix;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final pickerHeight = categories.isEmpty ? null : _pickerHeight();
    return Container(
      key: ValueKey('$keyPrefix-scroll-list'),
      height: pickerHeight,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: categories.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Nincs választható kategória',
                style: TextStyle(color: AppColors.gray500),
              ),
            )
          : ListView.separated(
              primary: false,
              padding: const EdgeInsets.symmetric(vertical: verticalPadding),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selectedId = selected?.transactionCategoryID;
                final isSelected = selectedId == category.transactionCategoryID;
                return SizedBox(
                  height: itemExtent,
                  child: _CategoryScrollPickerItem(
                    key: ValueKey(
                      '$keyPrefix-option-${category.transactionCategoryID}',
                    ),
                    category: category,
                    selected: isSelected,
                    onTap: () => onSelected(category),
                  ),
                );
              },
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Divider(
                  height: separatorExtent,
                  color: AppColors.gray200.withValues(alpha: 0.65),
                ),
              ),
              itemCount: categories.length,
            ),
    );
  }

  double _pickerHeight() {
    final visibleRows = math.min(categories.length, visibleRowCount);
    final separatorCount = math.max(visibleRows - 1, 0);
    final contentHeight =
        verticalPadding * 2 +
        itemExtent * visibleRows +
        separatorExtent * separatorCount;
    return math.min(maxHeight, contentHeight);
  }
}

class _CategoryScrollPickerItem extends StatelessWidget {
  const _CategoryScrollPickerItem({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TransactionCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: selected
            ? category.slotColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: category.slotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: category.slotColor.withValues(alpha: 0.22),
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
