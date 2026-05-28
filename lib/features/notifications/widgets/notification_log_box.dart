import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../transactions/slots/category_color_resolver.dart';
import '../models/expense_notification_card.dart';

class NotificationLogBox extends StatefulWidget {
  const NotificationLogBox({
    super.key,
    required this.card,
    required this.onMarkRead,
    required this.onDelete,
  });

  final ExpenseNotificationCard card;
  final ValueChanged<int> onMarkRead;
  final ValueChanged<int> onDelete;

  @override
  State<NotificationLogBox> createState() => _NotificationLogBoxState();
}

class _NotificationLogBoxState extends State<NotificationLogBox> {
  double _dragDx = 0;
  double _visualDx = 0;
  bool _triggered = false;

  void _resetDrag() {
    _dragDx = 0;
    _triggered = false;
    if (!mounted) return;
    setState(() => _visualDx = 0);
  }

  void _startDrag() {
    _dragDx = 0;
    _triggered = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    _dragDx += details.delta.dx;
    setState(() => _visualDx = _dragDx.clamp(-20.0, 20.0).toDouble());
    if (_dragDx < -80) {
      _triggered = true;
      widget.onMarkRead(widget.card.id);
      return;
    }
    if (_dragDx > 80) {
      _triggered = true;
      widget.onDelete(widget.card.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColorResolver.color(
      snapshotHex: widget.card.categoryColor,
      fallback: AppColors.primary,
    );
    final deleteOpacity = _borderOpacity(_dragDx > 0 ? _dragDx : 0);
    final readOpacity = _borderOpacity(_dragDx < 0 ? -_dragDx : 0);
    return GestureDetector(
      key: ValueKey('notification-logbox-${widget.card.id}'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _startDrag(),
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragCancel: _resetDrag,
      onHorizontalDragEnd: (_) => _resetDrag(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Transform.translate(
          offset: Offset(_visualDx, 0),
          child: Stack(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _typeLabel(widget.card.type),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.card.message.isNotEmpty
                                    ? widget.card.message
                                    : widget.card.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: AppColors.gray200),
                    const SizedBox(height: 8),
                    Text(
                      widget.card.categoryName ?? widget.card.priority,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        widget.card.isRead ? 'Elolvasva' : 'Új értesítés',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _SwipeBorder(opacity: deleteOpacity, color: AppColors.expense),
              _SwipeBorder(opacity: readOpacity, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  double _borderOpacity(double distance) {
    if (distance <= 0) return 0;
    return (distance / 80).clamp(0.0, 1.0).toDouble();
  }
}

class _SwipeBorder extends StatelessWidget {
  const _SwipeBorder({required this.opacity, required this.color});

  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color, width: 3),
          ),
        ),
      ),
    );
  }
}

String _typeLabel(ExpenseNotificationType type) {
  return switch (type) {
    ExpenseNotificationType.recurringTransactionAlert => 'Ismétlődő tranzakció',
    ExpenseNotificationType.budgetAlert => 'Limit alert',
    ExpenseNotificationType.spendingLimit => 'Költési limit',
    ExpenseNotificationType.monthlyBudgetAlert => 'Havi limit alert',
    ExpenseNotificationType.system => 'Értesítés',
  };
}
