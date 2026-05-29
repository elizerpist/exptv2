import 'package:flutter/material.dart';

class BudgetProgressSegment {
  const BudgetProgressSegment({
    required this.amount,
    required this.fraction,
    required this.color,
  });

  final double amount;
  final double fraction;
  final Color color;
}

class BudgetProgressData {
  const BudgetProgressData({
    required this.hasLimit,
    required this.amount,
    required this.limitAmount,
    required this.ratio,
    required this.segments,
  });

  final bool hasLimit;
  final double amount;
  final double limitAmount;
  final double ratio;
  final List<BudgetProgressSegment> segments;

  double get clampedRatio => ratio.clamp(0.0, 1.0).toDouble();
  double get remainingFraction => (1 - clampedRatio).clamp(0.0, 1.0).toDouble();
  bool get isWarning => ratio >= 0.75 && ratio < 0.90;
  bool get isDanger => ratio >= 0.90;
  bool get isSuccess => hasLimit && ratio >= 1.0;
}
