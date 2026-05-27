import 'package:flutter/material.dart';

import 'category_limit.dart';
import 'transaction_category.dart';
import 'transaction_record.dart';

class CategoryBudgetBarData {
  const CategoryBudgetBarData({
    required this.key,
    required this.targetType,
    required this.targetId,
    required this.transactionType,
    required this.window,
    required this.periodKey,
    required this.title,
    required this.spent,
    required this.hasLimit,
    required this.limitAmount,
    required this.alertActive,
    required this.color,
    required this.iconSlot,
    required this.category,
    required this.sourceLimit,
  });

  final String key;
  final LimitTargetType targetType;
  final int targetId;
  final TransactionType transactionType;
  final LimitWindow window;
  final String periodKey;
  final String title;
  final double spent;
  final bool hasLimit;
  final double limitAmount;
  final bool alertActive;
  final Color color;
  final int? iconSlot;
  final TransactionCategory? category;
  final CategoryLimit? sourceLimit;

  double get progress {
    if (!hasLimit || limitAmount <= 0) return 0;
    return (spent / limitAmount).clamp(0.0, 1.0).toDouble();
  }

  double get rawProgress {
    if (!hasLimit || limitAmount <= 0) return 0;
    return spent / limitAmount;
  }

  double get remaining => limitAmount - spent;
  bool get isOverLimit => hasLimit && limitAmount > 0 && spent >= limitAmount;
  String get formattedSpent => formatHuf(spent);
  String get formattedLimit => formatHuf(limitAmount);
  String get formattedRemaining => formatHuf(remaining.abs());
}
