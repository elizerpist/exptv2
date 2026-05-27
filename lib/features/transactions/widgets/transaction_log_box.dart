import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class TransactionLogBox extends StatefulWidget {
  const TransactionLogBox({
    super.key,
    required this.record,
    required this.category,
    required this.onFastFilter,
  });

  final TransactionRecord record;
  final TransactionCategory? category;
  final ValueChanged<String> onFastFilter;

  @override
  State<TransactionLogBox> createState() => _TransactionLogBoxState();
}

class _TransactionLogBoxState extends State<TransactionLogBox> {
  double _dragDx = 0;
  bool _triggered = false;

  void _resetDrag() {
    _dragDx = 0;
    _triggered = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    _dragDx += details.delta.dx;
    if (_dragDx > -80) return;

    _triggered = true;
    widget.onFastFilter(widget.record.displayMerchant);
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = widget.record.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    return GestureDetector(
      key: ValueKey('transaction-logbox-${widget.record.id}'),
      onHorizontalDragStart: (_) => _resetDrag(),
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragCancel: _resetDrag,
      onHorizontalDragEnd: (_) => _resetDrag(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: widget.category?.slotColor ?? AppColors.gray500,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.record.displayMerchant,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.record.displayAmount,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.record.displayTime,
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
      ),
    );
  }
}
