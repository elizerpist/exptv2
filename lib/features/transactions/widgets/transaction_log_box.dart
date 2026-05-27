import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import 'category_menu/category_icon_badge.dart';

typedef TransactionLogContextCallback = void Function(
  TransactionRecord record,
  TransactionCategory? category,
);

class TransactionLogBox extends StatefulWidget {
  const TransactionLogBox({
    super.key,
    required this.record,
    required this.category,
    this.onFastFilter,
    this.onTap,
    this.onDeleteRequested,
    this.onCategoryFilter,
  });

  final TransactionRecord record;
  final TransactionCategory? category;
  final TransactionLogContextCallback? onFastFilter;
  final ValueChanged<TransactionRecord>? onTap;
  final ValueChanged<TransactionRecord>? onDeleteRequested;
  final ValueChanged<TransactionCategory>? onCategoryFilter;

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
    if (_dragDx < -80) {
      _triggered = true;
      widget.onFastFilter?.call(widget.record, widget.category);
      return;
    }
    if (_dragDx > 80) {
      _triggered = true;
      widget.onDeleteRequested?.call(widget.record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = widget.record.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    return GestureDetector(
      key: ValueKey('transaction-logbox-${widget.record.id}'),
      onTap: () => widget.onTap?.call(widget.record),
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
            GestureDetector(
              key: ValueKey('transaction-logbox-avatar-${widget.record.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.category == null || widget.onCategoryFilter == null
                  ? null
                  : () => widget.onCategoryFilter!(widget.category!),
              child: CategoryIconBadge(
                category: widget.category,
                backgroundColor:
                    widget.category?.slotColor ?? AppColors.gray500,
                size: 46,
                iconSize: 28,
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
