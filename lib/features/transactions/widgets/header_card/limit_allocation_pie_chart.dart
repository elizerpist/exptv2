import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/limit_allocation_manager.dart';
import '../../models/limit_allocation_data.dart';

class LimitAllocationPieChart extends StatelessWidget {
  const LimitAllocationPieChart({
    super.key,
    required this.allocation,
    required this.onSliceTap,
    required this.onSliceAmountChanged,
    this.size = 180,
  });

  final LimitAllocationData allocation;
  final ValueChanged<int> onSliceTap;
  final void Function(int targetId, double amount) onSliceAmountChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('limit-allocation-pie-chart'),
      onTapUp: (details) {
        final targetId = _targetAt(details.localPosition, Size.square(size));
        if (targetId != null) onSliceTap(targetId);
      },
      onHorizontalDragUpdate: (details) {
        final targetId = _firstTargetId;
        if (targetId == null || allocation.overviewLimit <= 0) return;
        final delta = details.delta.dx * 1000;
        final current = _amountForTarget(targetId);
        final next = LimitAllocationManager.snapSliderAmount(
          (current + delta).clamp(0.0, allocation.overviewLimit).toDouble(),
        );
        onSliceAmountChanged(targetId, next);
      },
      child: CustomPaint(
        size: Size.square(size),
        painter: _LimitAllocationPiePainter(allocation),
      ),
    );
  }

  int? get _firstTargetId {
    for (final segment in allocation.segments) {
      if (segment.targetId != null) return segment.targetId;
    }
    return null;
  }

  double _amountForTarget(int targetId) {
    return allocation.segments
        .where((segment) => segment.targetId == targetId)
        .fold<double>(0, (sum, segment) => sum + segment.amount);
  }

  int? _targetAt(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = position - center;
    if (vector.distance > size.shortestSide / 2) return null;
    var angle = math.atan2(vector.dy, vector.dx);
    if (angle < -math.pi / 2) angle += math.pi * 2;
    final normalized = (angle + math.pi / 2) / (math.pi * 2);
    var cursor = 0.0;
    for (final segment in allocation.segments) {
      final next = cursor + segment.fraction;
      if (normalized >= cursor && normalized <= next) return segment.targetId;
      cursor = next;
    }
    return null;
  }
}

class _LimitAllocationPiePainter extends CustomPainter {
  const _LimitAllocationPiePainter(this.allocation);

  final LimitAllocationData allocation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    var start = -math.pi / 2;
    if (allocation.segments.isEmpty) {
      paint.color = AppColors.gray200;
      canvas.drawCircle(rect.center, size.shortestSide / 2, paint);
      return;
    }
    for (final segment in allocation.segments) {
      final sweep = math.pi * 2 * segment.fraction;
      paint.color = segment.color;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.white;
    canvas.drawCircle(rect.center, size.shortestSide / 2 - 1, paint);
  }

  @override
  bool shouldRepaint(covariant _LimitAllocationPiePainter oldDelegate) {
    return oldDelegate.allocation != allocation;
  }
}
