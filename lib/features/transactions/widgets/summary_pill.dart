import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SummaryPill extends StatefulWidget {
  const SummaryPill({
    super.key,
    required this.title,
    required this.value,
    required this.onSwipe,
    this.onVerticalSwipe,
  });

  final String title;
  final String value;
  final VoidCallback onSwipe;
  final ValueChanged<int>? onVerticalSwipe;

  @override
  State<SummaryPill> createState() => _SummaryPillState();
}

class _SummaryPillState extends State<SummaryPill> {
  double _dragDx = 0;
  double _dragDy = 0;
  double _visualDx = 0;
  double _visualDy = 0;
  bool _triggered = false;
  bool _dragging = false;

  void _resetDrag() {
    _dragDx = 0;
    _dragDy = 0;
    _triggered = false;
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _visualDx = 0;
      _visualDy = 0;
    });
  }

  void _startDrag() {
    _dragDx = 0;
    _dragDy = 0;
    _triggered = false;
    setState(() => _dragging = true);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    _dragDx += details.delta.dx;
    setState(() => _visualDx = (_dragDx * 0.1).clamp(-18.0, 18.0).toDouble());
    if (_dragDx.abs() < 60) return;

    _triggered = true;
    widget.onSwipe();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    _dragDy += details.delta.dy;
    setState(() => _visualDy = (_dragDy * 0.1).clamp(-18.0, 18.0).toDouble());
    if (_dragDy.abs() < 60) return;

    _triggered = true;
    widget.onVerticalSwipe?.call(_dragDy < 0 ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('summary-pill'),
      onHorizontalDragStart: (_) => _startDrag(),
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragCancel: _resetDrag,
      onHorizontalDragEnd: (_) => _resetDrag(),
      onVerticalDragStart: (_) => _startDrag(),
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragCancel: _resetDrag,
      onVerticalDragEnd: (_) => _resetDrag(),
      child: AnimatedContainer(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(_visualDx, _visualDy, 0),
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Row(
            key: ValueKey('${widget.title}-${widget.value}'),
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
      ),
    );
  }
}
