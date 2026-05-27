import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import 'transaction_menu_metrics.dart';

class TransactionTypePills extends StatelessWidget {
  const TransactionTypePills({
    super.key,
    required this.activeType,
    required this.onChanged,
  });

  final TransactionType activeType;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        TransactionMenuMetrics.typePillTopPadding,
        20,
        TransactionMenuMetrics.typePillBottomPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: _TransactionTypePill(
              type: TransactionType.income,
              active: activeType == TransactionType.income,
              onTap: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TransactionTypePill(
              type: TransactionType.expense,
              active: activeType == TransactionType.expense,
              onTap: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTypePill extends StatelessWidget {
  const _TransactionTypePill({
    required this.type,
    required this.active,
    required this.onTap,
  });

  final TransactionType type;
  final bool active;
  final ValueChanged<TransactionType> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.white,
      elevation: active ? 3 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => onTap(type),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: TransactionMenuMetrics.typePillMinHeight,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.gray200,
            ),
          ),
          child: Text(
            type.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.white : AppColors.gray500,
            ),
          ),
        ),
      ),
    );
  }
}
