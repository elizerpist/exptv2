import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SummaryPill extends StatefulWidget {
  const SummaryPill({
    super.key,
    required this.title,
    required this.value,
    required this.onSwipe,
  });

  final String title;
  final String value;
  final VoidCallback onSwipe;

  @override
  State<SummaryPill> createState() => _SummaryPillState();
}

class _SummaryPillState extends State<SummaryPill> {
  double _dragDx = 0;
  bool _triggered = false;

  void _resetDrag() {
    _dragDx = 0;
    _triggered = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    _dragDx += details.delta.dx;
    if (_dragDx.abs() < 60) return;

    _triggered = true;
    widget.onSwipe();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('summary-pill'),
      onHorizontalDragStart: (_) => _resetDrag(),
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragCancel: _resetDrag,
      onHorizontalDragEnd: (_) => _resetDrag(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.gray500,
                ),
              ),
            ),
            Text(
              widget.value,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: AppColors.gray800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
