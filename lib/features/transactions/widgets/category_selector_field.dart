import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';
import '../models/transaction_category.dart';

class CategorySelectorField extends StatelessWidget {
  const CategorySelectorField({
    super.key,
    required this.selected,
    required this.onTap,
    this.selectorKey = const ValueKey('transaction-category-selector'),
    this.surfaceColor = AppColors.gray50,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  });

  final TransactionCategory? selected;
  final VoidCallback onTap;
  final Key selectorKey;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;

  @override
  Widget build(BuildContext context) {
    final category = selected;
    if (surfaceStyle.hasPressEffect) {
      return GestureDetector(
        key: selectorKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExpenseSurfaceContainer(
          surfaceKey: ValueKey(
            '${_selectorSurfaceKeyValue(selectorKey)}-surface',
          ),
          style: surfaceStyle,
          color: surfaceColor,
          borderRadius: BorderRadius.circular(25),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          neutralBorder: Border.all(color: AppColors.gray200),
          child: _CategorySelectorContent(category: category),
        ),
      );
    }
    return InkWell(
      key: selectorKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Kategória',
          filled: true,
          fillColor: surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: AppColors.gray200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: AppColors.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        isEmpty: category == null,
        child: _CategorySelectorContent(category: category),
      ),
    );
  }
}

Object _selectorSurfaceKeyValue(Key key) {
  if (key is ValueKey) return key.value;
  return key;
}

class _CategorySelectorContent extends StatelessWidget {
  const _CategorySelectorContent({required this.category});

  final TransactionCategory? category;

  @override
  Widget build(BuildContext context) {
    final selected = category;
    return Row(
      children: [
        if (selected != null) ...[
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: selected.slotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selected.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.gray800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else
          const Expanded(
            child: Text(
              'Válassz kategóriát',
              style: TextStyle(color: AppColors.gray500),
            ),
          ),
        const Icon(
          Icons.keyboard_arrow_right,
          color: AppColors.gray500,
          size: 22,
        ),
      ],
    );
  }
}
