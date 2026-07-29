import 'package:flutter/material.dart';

import '../../../data/limit_manager.dart';
import '../../../models/budget_goal_kind.dart';
import '../../../models/category_budget_bar_data.dart';
import '../../../models/category_limit.dart';
import '../../../models/transaction_category.dart';
import '../../../models/transaction_record.dart';
import '../../../slots/category_color_manager.dart';
import '../../../state/balance_frame.dart';

/// Immutable Budget V2 data resolved from the same active Balance query that
/// drives the summary pill, transaction log and detail cards.
///
/// The legacy store accessor only exposed category bars.  Budget V2 also has
/// a real overview target, so this adapter publishes that target as the first
/// avatar and keeps both income and expense on one type-aware code path.
@immutable
class BudgetV2FrameData {
  const BudgetV2FrameData({required this.bars, required this.records});

  final List<CategoryBudgetBarData> bars;
  final List<TransactionRecord> records;

  factory BudgetV2FrameData.fromInput(BalanceFrameInput input) {
    final records = recordsForInput(input);
    final categoryBars = LimitManager.buildBars(
      categories: input.categories,
      transactions: input.transactions,
      limits: input.limits,
      activeType: input.activeType,
      summaryWindow: input.summaryWindow,
      referenceDate: input.summaryReferenceDate,
      windowedTransactions: records,
    );
    return BudgetV2FrameData(
      bars: List<CategoryBudgetBarData>.unmodifiable(<CategoryBudgetBarData>[
        overviewBar(input, records: records),
        ...categoryBars,
      ]),
      records: records,
    );
  }

  /// Applies the exact active Balance type, summary window and user filters.
  /// Keeping this public lets the vendor chart share the category chart's
  /// input rather than silently reading an unfiltered transaction list.
  static List<TransactionRecord> recordsForInput(BalanceFrameInput input) {
    final query = input.searchQuery.trim().toLowerCase();
    return List<TransactionRecord>.unmodifiable(
      LimitManager.recordsForWindow(
        transactions: input.transactions,
        activeType: input.activeType,
        summaryWindow: input.summaryWindow,
        referenceDate: input.summaryReferenceDate,
      ).where((record) {
        if (input.categoryIds.isNotEmpty &&
            !input.categoryIds.contains(record.transactionCategoryID)) {
          return false;
        }
        if (input.merchantFilters.isNotEmpty &&
            !input.merchantFilters.contains(record.displayMerchant)) {
          return false;
        }
        return query.isEmpty ||
            record.displayMerchant.toLowerCase().contains(query);
      }),
    );
  }

  static CategoryBudgetBarData overviewBar(
    BalanceFrameInput input, {
    required Iterable<TransactionRecord> records,
  }) {
    final window = LimitManager.windowForSummary(input.summaryWindow);
    final periodKey = LimitManager.periodKeyFor(
      input.summaryWindow,
      input.summaryReferenceDate,
    );
    final kind = input.activeType == TransactionType.income
        ? BudgetGoalKind.incomeGoal
        : BudgetGoalKind.expenseBudget;
    final sourceLimit = LimitManager.findLimit(
      limits: input.limits,
      targetType: LimitTargetType.overview,
      targetId: 0,
      transactionType: input.activeType.nativeValue,
      window: window,
      periodKey: periodKey,
    );
    final hasLimit = sourceLimit?.hasLimit ?? false;
    final amount = records.fold<double>(
      0,
      (sum, record) => sum + record.amount.abs(),
    );
    // Overview is not a user category, but it still takes its colour from
    // the central palette. Category pieces continue to resolve through
    // CategoryColorResolver from their actual TransactionCategory.
    final overviewSlot = input.activeType == TransactionType.income ? 16 : 11;
    return CategoryBudgetBarData(
      key: 'overview-${kind.key}-${window.nativeValue}-$periodKey',
      targetType: LimitTargetType.overview,
      targetId: 0,
      transactionType: input.activeType,
      window: window,
      periodKey: periodKey,
      title: kind.title,
      spent: amount,
      hasLimit: hasLimit,
      limitAmount: hasLimit ? sourceLimit!.limitAmount : 0,
      alertActive: sourceLimit?.alertActive ?? false,
      color: CategoryColorManager.color(overviewSlot),
      iconSlot: null,
      category: null,
      sourceLimit: sourceLimit,
    );
  }
}
