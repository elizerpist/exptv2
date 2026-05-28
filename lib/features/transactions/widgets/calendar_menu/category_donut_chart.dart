import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_record.dart';

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({
    super.key,
    required this.transactions,
    required this.categories,
    required this.year,
  });

  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final int year;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('calendar-category-donut-chart'),
      height: 82,
      width: double.infinity,
      child: CustomPaint(
        painter: _CategoryDonutPainter(slices: _buildSlices()),
      ),
    );
  }

  List<_CategorySlice> _buildSlices() {
    final totals = <int, double>{};
    for (final transaction in transactions) {
      final date = DateTime.tryParse(transaction.normalizedDate);
      if (date == null || date.year != year || transaction.amount >= 0) {
        continue;
      }
      totals.update(
        transaction.transactionCategoryID,
        (value) => value + transaction.amount.abs(),
        ifAbsent: () => transaction.amount.abs(),
      );
    }
    final byId = {
      for (final category in categories)
        category.transactionCategoryID: category,
    };
    final slices = <_CategorySlice>[];
    for (final entry in totals.entries) {
      final category = byId[entry.key];
      slices.add(
        _CategorySlice(
          amount: entry.value,
          color: category?.slotColor ?? AppColors.gray400,
        ),
      );
    }
    slices.sort((left, right) => right.amount.compareTo(left.amount));
    return slices;
  }
}

class _CategorySlice {
  const _CategorySlice({required this.amount, required this.color});

  final double amount;
  final Color color;
}

class _CategoryDonutPainter extends CustomPainter {
  const _CategoryDonutPainter({required this.slices});

  final List<_CategorySlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(48, size.height / 2);
    final radius = math.min(size.height * 0.36, 30.0);
    final strokeWidth = 12.0;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.gray200;
    canvas.drawCircle(center, radius, basePaint);

    final total = slices.fold<double>(0, (sum, slice) => sum + slice.amount);
    if (total <= 0) return;

    var start = -math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (final slice in slices) {
      final sweep = (slice.amount / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = slice.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    final legendLeft = center.dx + radius + 24;
    var legendTop = 14.0;
    for (final slice in slices.take(4)) {
      final dot = Rect.fromLTWH(legendLeft, legendTop + 4, 10, 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(dot, const Radius.circular(5)),
        Paint()..color = slice.color,
      );
      legendTop += 16;
    }
  }

  @override
  bool shouldRepaint(_CategoryDonutPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}
