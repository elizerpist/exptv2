import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class NotificationMonthHeader extends StatefulWidget {
  const NotificationMonthHeader({
    super.key,
    required this.selectedMonth,
    required this.hasCards,
    required this.onMonthShift,
    required this.onClear,
  });

  final DateTime selectedMonth;
  final bool hasCards;
  final ValueChanged<int> onMonthShift;
  final VoidCallback onClear;

  @override
  State<NotificationMonthHeader> createState() =>
      _NotificationMonthHeaderState();
}

class _NotificationMonthHeaderState extends State<NotificationMonthHeader> {
  double _dragDx = 0;
  var _triggered = false;

  void _startDrag() {
    _dragDx = 0;
    _triggered = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    _dragDx += details.delta.dx;
    if (_dragDx < -50) {
      _triggered = true;
      widget.onMonthShift(1);
    } else if (_dragDx > 50) {
      _triggered = true;
      widget.onMonthShift(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('notification-month-header'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _startDrag(),
      onHorizontalDragUpdate: _handleDragUpdate,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Row(
          children: [
            const SizedBox(width: 36),
            Expanded(
              child: Text(
                '${widget.selectedMonth.year}. ${_monthName(widget.selectedMonth.month)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('notification-clear-month'),
              onPressed: widget.hasCards ? widget.onClear : null,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.gray500,
            ),
          ],
        ),
      ),
    );
  }
}

String _monthName(int month) {
  const names = <int, String>{
    1: 'Január',
    2: 'Február',
    3: 'Március',
    4: 'Április',
    5: 'Május',
    6: 'Június',
    7: 'Július',
    8: 'Augusztus',
    9: 'Szeptember',
    10: 'Október',
    11: 'November',
    12: 'December',
  };
  return names[month] ?? month.toString();
}
