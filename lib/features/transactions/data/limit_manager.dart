import 'package:flutter/material.dart';

import '../models/category_budget_bar_data.dart';
import '../models/category_limit.dart';
import '../models/summary_window.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class LimitManager {
  static const warningColor = Color(0xffff8800);
  static const overLimitColor = Color(0xffff4444);

  static LimitWindow windowForSummary(SummaryWindow window) {
    return switch (window) {
      SummaryWindow.monthly => LimitWindow.monthly,
      SummaryWindow.yearly => LimitWindow.yearly,
      SummaryWindow.allTime => LimitWindow.allTime,
    };
  }

  static String periodKeyFor(SummaryWindow window, DateTime referenceDate) {
    return switch (window) {
      SummaryWindow.monthly =>
        "${referenceDate.year}-${referenceDate.month.toString().padLeft(2, '0')}",
      SummaryWindow.yearly => referenceDate.year.toString(),
      SummaryWindow.allTime => 'all',
    };
  }

  static Iterable<TransactionRecord> recordsForWindow({
    required Iterable<TransactionRecord> transactions,
    required TransactionType activeType,
    required SummaryWindow summaryWindow,
    required DateTime referenceDate,
  }) {
    final monthKey = periodKeyFor(SummaryWindow.monthly, referenceDate);
    final yearKey = periodKeyFor(SummaryWindow.yearly, referenceDate);
    return transactions.where((record) {
      if (record.type != activeType) return false;
      return switch (summaryWindow) {
        SummaryWindow.monthly => record.yearMonthKey == monthKey,
        SummaryWindow.yearly => record.yearMonthKey.startsWith(yearKey),
        SummaryWindow.allTime => true,
      };
    });
  }

  static List<CategoryBudgetBarData> buildBars({
    required List<TransactionCategory> categories,
    required List<TransactionRecord> transactions,
    required List<CategoryLimit> limits,
    required TransactionType activeType,
    required SummaryWindow summaryWindow,
    required DateTime referenceDate,
    Iterable<TransactionRecord>? windowedTransactions,
  }) {
    final window = windowForSummary(summaryWindow);
    final periodKey = periodKeyFor(summaryWindow, referenceDate);
    final transactionType = activeType.nativeValue;
    final records = (windowedTransactions ??
            recordsForWindow(
              transactions: transactions,
              activeType: activeType,
              summaryWindow: summaryWindow,
              referenceDate: referenceDate,
            ))
        .toList();

    final spentByCategory = <int, double>{};
    for (final record in records) {
      spentByCategory.update(
        record.transactionCategoryID,
        (value) => value + record.amount.abs(),
        ifAbsent: () => record.amount.abs(),
      );
    }

    return categories
        .where((category) => category.normalizedType == activeType)
        .map((category) {
          final sourceLimit = _findLimit(
            limits: limits,
            targetType: LimitTargetType.category,
            targetId: category.transactionCategoryID,
            transactionType: transactionType,
            window: window,
            periodKey: periodKey,
          );
          final fallbackHasLimit =
              category.hasLimit && category.limitAmount > 0;
          final hasLimit = sourceLimit?.hasLimit ?? fallbackHasLimit;
          final limitAmount =
              sourceLimit?.limitAmount ??
              (fallbackHasLimit ? category.limitAmount : 0.0);
          final alertActive =
              sourceLimit?.alertActive ??
              (fallbackHasLimit && category.alertActive);
          return CategoryBudgetBarData(
            key:
                'category-${category.transactionCategoryID}-$transactionType-${window.nativeValue}-$periodKey',
            targetType: LimitTargetType.category,
            targetId: category.transactionCategoryID,
            transactionType: activeType,
            window: window,
            periodKey: periodKey,
            title: category.name,
            spent: spentByCategory[category.transactionCategoryID] ?? 0.0,
            hasLimit: hasLimit,
            limitAmount: hasLimit ? limitAmount : 0.0,
            alertActive: alertActive,
            color: category.slotColor,
            iconSlot: category.iconSlot,
            category: category,
            sourceLimit: sourceLimit,
          );
        })
        .toList();
  }

  static Color progressColor(double spent, double limitAmount) {
    if (limitAmount <= 0) return Colors.white;
    final ratio = spent / limitAmount;
    if (ratio >= 1) return overLimitColor;
    if (ratio >= 0.8) return warningColor;
    return Colors.white;
  }

  static CategoryLimit? findLimit({
    required List<CategoryLimit> limits,
    required LimitTargetType targetType,
    required int targetId,
    required String transactionType,
    required LimitWindow window,
    required String periodKey,
  }) {
    return _findLimit(
      limits: limits,
      targetType: targetType,
      targetId: targetId,
      transactionType: transactionType,
      window: window,
      periodKey: periodKey,
    );
  }

  static CategoryLimit? _findLimit({
    required List<CategoryLimit> limits,
    required LimitTargetType targetType,
    required int targetId,
    required String transactionType,
    required LimitWindow window,
    required String periodKey,
  }) {
    for (final limit in limits) {
      if (limit.targetType == targetType &&
          limit.targetId == targetId &&
          limit.transactionType == transactionType &&
          limit.window == window &&
          limit.periodKey == periodKey) {
        return limit;
      }
    }
    return null;
  }
}
