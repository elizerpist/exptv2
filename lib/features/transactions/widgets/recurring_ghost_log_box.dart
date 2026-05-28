import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import 'category_menu/category_icon_badge.dart';

class RecurringGhostLogBox extends StatelessWidget {
  const RecurringGhostLogBox({
    super.key,
    required this.ghost,
    required this.category,
  });

  final RecurringGhostRecord ghost;
  final TransactionCategory? category;

  @override
  Widget build(BuildContext context) {
    final amountColor = ghost.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    return Container(
      key: ValueKey('recurring-ghost-logbox-${ghost.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.gray300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          CategoryIconBadge(
            category: category,
            backgroundColor: category?.slotColor ?? AppColors.gray500,
            size: 46,
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ghost.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Ghost',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ghost.displayAmount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ghost.displayTime,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
