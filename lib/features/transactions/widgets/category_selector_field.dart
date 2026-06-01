import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';

class CategorySelectorField extends StatelessWidget {
  const CategorySelectorField({
    super.key,
    required this.selected,
    required this.onTap,
    this.selectorKey = const ValueKey('transaction-category-selector'),
  });

  final TransactionCategory? selected;
  final VoidCallback onTap;
  final Key selectorKey;

  @override
  Widget build(BuildContext context) {
    final category = selected;
    return InkWell(
      key: selectorKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Kategória',
          filled: true,
          fillColor: AppColors.gray50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        isEmpty: category == null,
        child: Row(
          children: [
            if (category != null) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: category.slotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
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
        ),
      ),
    );
  }
}
