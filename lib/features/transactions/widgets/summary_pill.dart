import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SummaryPill extends StatefulWidget {
  const SummaryPill({
    super.key,
    required this.title,
    required this.value,
    required this.onIntervalSwipe,
    required this.onPeriodSwipe,
    required this.onResetToCurrentMonth,
  });

  final String title;
  final String value;
  final VoidCallback onIntervalSwipe;
  final ValueChanged<int> onPeriodSwipe;
  final VoidCallback onResetToCurrentMonth;

  @override
  State<SummaryPill> createState() => _SummaryPillState();
}

class _SummaryPillState extends State<SummaryPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settleController;
  late final ValueNotifier<Offset> _visualOffset;
  Animation<Offset>? _settleAnimation;
  double _dragDx = 0;
  double _dragDy = 0;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _visualOffset = ValueNotifier<Offset>(Offset.zero);
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..addListener(_syncSettleOffset);
  }

  @override
  void dispose() {
    _settleController
      ..removeListener(_syncSettleOffset)
      ..dispose();
    _visualOffset.dispose();
    super.dispose();
  }

  void _syncSettleOffset() {
    final animation = _settleAnimation;
    if (animation == null) return;
    _visualOffset.value = animation.value;
  }

  void _resetDrag() {
    _dragDx = 0;
    _dragDy = 0;
    _triggered = false;
    final start = _visualOffset.value;
    _settleController.stop();
    if (start == Offset.zero) {
      _settleAnimation = null;
      return;
    }
    _settleAnimation = Tween<Offset>(begin: start, end: Offset.zero).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.easeOutCubic),
    );
    _settleController.forward(from: 0);
  }

  void _startDrag() {
    _settleController.stop();
    _settleAnimation = null;
    _dragDx = 0;
    _dragDy = 0;
    _triggered = false;
    _visualOffset.value = Offset.zero;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    _dragDx += details.delta.dx;
    _visualOffset.value = Offset(
      (_dragDx * 0.1).clamp(-18.0, 18.0).toDouble(),
      _visualOffset.value.dy,
    );
    if (_dragDx.abs() < 60) return;

    _triggered = true;
    widget.onPeriodSwipe(_dragDx < 0 ? 1 : -1);
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_triggered) return;
    _dragDy += details.delta.dy;
    _visualOffset.value = Offset(
      _visualOffset.value.dx,
      (_dragDy * 0.1).clamp(-18.0, 18.0).toDouble(),
    );
    if (_dragDy.abs() < 60) return;

    _triggered = true;
    widget.onIntervalSwipe();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('summary-pill'),
      onDoubleTap: widget.onResetToCurrentMonth,
      onHorizontalDragStart: (_) => _startDrag(),
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragCancel: _resetDrag,
      onHorizontalDragEnd: (_) => _resetDrag(),
      onVerticalDragStart: (_) => _startDrag(),
      onVerticalDragUpdate: _handleVerticalDragUpdate,
      onVerticalDragCancel: _resetDrag,
      onVerticalDragEnd: (_) => _resetDrag(),
      child: ValueListenableBuilder<Offset>(
        key: const ValueKey('summary-pill-transform'),
        valueListenable: _visualOffset,
        child: RepaintBoundary(child: _SummaryPillBody(widget: widget)),
        builder: (context, offset, child) {
          return Transform.translate(offset: offset, child: child);
        },
      ),
    );
  }
}

class _SummaryPillBody extends StatelessWidget {
  const _SummaryPillBody({required this.widget});

  final SummaryPill widget;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
