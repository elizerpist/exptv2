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
  static const _dismissThreshold = 96.0;
  static const _maxDragOffset = 260.0;
  static const _collapseDuration = Duration(milliseconds: 180);

  double _dragDx = 0;
  double _visualDx = 0;
  bool _triggered = false;
  bool _collapsed = false;
  bool _deleteSent = false;

  @override
  void didUpdateWidget(covariant NotificationLogBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id == widget.card.id) return;
    _dragDx = 0;
    _visualDx = 0;
    _triggered = false;
    _collapsed = false;
    _deleteSent = false;
  }

  double get _contentOpacity {
    if (_triggered) return 0;
    return (1 - (_dragDx.abs() / _dismissThreshold)).clamp(0.0, 1.0).toDouble();
  }

  void _resetDrag() {
    if (_triggered || _collapsed) return;
    _dragDx = 0;
    if (!mounted) return;
    setState(() => _visualDx = 0);
  }

  void _startDrag() {
    if (_triggered || _collapsed) return;
    _dragDx = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_triggered || _collapsed) return;
    _dragDx += details.delta.dx;
    final clamped = _dragDx.clamp(-_maxDragOffset, _maxDragOffset).toDouble();
    setState(() => _visualDx = clamped);
    if (_dragDx.abs() >= _dismissThreshold) {
      _triggerDelete(_dragDx < 0 ? -1 : 1);
    }
  }

  void _handleDragEnd() {
    if (_triggered || _collapsed) return;
    _resetDrag();
  }

  void _triggerDelete(int direction) {
    if (_triggered || _deleteSent) return;
    _deleteSent = true;
    setState(() {
      _triggered = true;
      _visualDx = direction * _maxDragOffset;
      _collapsed = true;
    });
    widget.onDelete(widget.card.id);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryColorResolver.color(
      snapshotHex: widget.card.categoryColor,
      fallback: AppColors.primary,
    );
    final swipeOpacity = _borderOpacity(_dragDx.abs());
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: AnimatedSize(
        key: ValueKey('notification-logbox-slot-${widget.card.id}'),
        duration: _collapseDuration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _collapsed
            ? const SizedBox.shrink()
            : GestureDetector(
                key: ValueKey('notification-logbox-${widget.card.id}'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => _startDrag(),
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragCancel: _handleDragEnd,
                onHorizontalDragEnd: (_) => _handleDragEnd(),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Transform.translate(
                    offset: Offset(_visualDx, 0),
                    child: Opacity(
                      key: ValueKey(
                        'notification-logbox-opacity-${widget.card.id}',
                      ),
                      opacity: _contentOpacity,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.card.categoryName ??
                                            widget.card.priority,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _timestampLabel(widget.card.timestamp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    widget.card.isRead
                                        ? 'Elolvasva'
                                        : 'Új értesítés',
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
                          _SwipeBorder(
                            opacity: swipeOpacity,
                            color: AppColors.expense,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  double _borderOpacity(double distance) {
    if (distance <= 0) return 0;
    return (distance / _dismissThreshold).clamp(0.0, 1.0).toDouble();
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

String _timestampLabel(DateTime timestamp) {
  final year = timestamp.year.toString().padLeft(4, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final day = timestamp.day.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$year.$month.$day $hour:$minute';
}

String _typeLabel(ExpenseNotificationType type) {
  return switch (type) {
    ExpenseNotificationType.recurringTransactionAlert => 'Ismétlődő tranzakció',
    ExpenseNotificationType.transactionCreated => 'Új tranzakció',
    ExpenseNotificationType.limit75 => 'Limit 75%',
    ExpenseNotificationType.limit100 => 'Limit elérve',
    ExpenseNotificationType.budgetAlert => 'Limit alert',
    ExpenseNotificationType.spendingLimit => 'Költési limit',
    ExpenseNotificationType.monthlyBudgetAlert => 'Havi limit alert',
    ExpenseNotificationType.system => 'Értesítés',
  };
}
