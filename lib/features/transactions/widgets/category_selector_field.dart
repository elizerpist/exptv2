import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';

class CategorySelectorField extends StatelessWidget {
  const CategorySelectorField({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<TransactionCategory> categories;
  final TransactionCategory? selected;
  final ValueChanged<TransactionCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TransactionCategory>(
      initialValue: selected,
      items: categories.map((category) {
        return DropdownMenuItem<TransactionCategory>(
          value: category,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: category.slotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
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
    );
  }
}
