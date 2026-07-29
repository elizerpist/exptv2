import 'package:flutter/material.dart';

import '../../../data/limit_manager.dart';
import '../../../models/budget_goal_kind.dart';
import '../../../models/category_budget_bar_data.dart';
import '../../../models/category_limit.dart';
import '../../../models/overview_budget_data.dart';
import '../../../models/transaction_category.dart';
import '../../../models/transaction_record.dart';
import '../../../slots/category_color_manager.dart';
import '../../../state/balance_frame.dart';
import '../../../state/transaction_store.dart';

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

  /// Production adapter for Budget V2.  The ordinary Budget carousel already
  /// owns the authoritative overview calculations in [TransactionStore], so
  /// Budget V2 adapts those records instead of recomputing a lookalike row.
  factory BudgetV2FrameData.fromStore(
    TransactionStore store, {
    BalanceFrameInput? input,
  }) => BudgetV2FrameData.fromInput(
    input ?? BalanceFrameInput.fromStore(store),
    overviewItems: store.overviewBudgetItems,
  );

  factory BudgetV2FrameData.fromInput(
    BalanceFrameInput input, {
    Iterable<OverviewBudgetData> overviewItems = const <OverviewBudgetData>[],
  }) {
    final records = recordsForInput(input);
    // Avatar discs, the category pie and the vendor pie are an authored
    // overview of the summary-pill scope. They must stay complete while the
    // selected avatar narrows only the transaction log below the card.
    // Otherwise selecting Food would erase every other disc and make it
    // impossible to step the ticker back to a neighbouring category.
    final avatarScopeRecords = recordsForAvatarScope(input);
    final categoryBars = LimitManager.buildBars(
      categories: input.categories,
      transactions: input.transactions,
      limits: input.limits,
      activeType: input.activeType,
      summaryWindow: input.summaryWindow,
      referenceDate: input.summaryReferenceDate,
      windowedTransactions: avatarScopeRecords,
    );
    final overview = overviewItems
        .where(
          (item) => item.kind.transactionType == input.activeType.nativeValue,
        )
        .firstOrNull;
    return BudgetV2FrameData(
      bars: List<CategoryBudgetBarData>.unmodifiable(<CategoryBudgetBarData>[
        overview == null
            ? overviewBar(input, records: avatarScopeRecords)
            : overviewBarFromData(input, overview),
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

  /// Summary-pill scope before the Budget V2 avatar or vendor refinement.
  ///
  /// The production log still uses [recordsForInput], so its category and
  /// merchant filters remain exact. Budget V2 visual aggregates deliberately
  /// use this list so the belt and charts retain the complete selected period.
  static List<TransactionRecord> recordsForAvatarScope(
    BalanceFrameInput input,
  ) => List<TransactionRecord>.unmodifiable(
    LimitManager.recordsForWindow(
      transactions: input.transactions,
      activeType: input.activeType,
      summaryWindow: input.summaryWindow,
      referenceDate: input.summaryReferenceDate,
    ),
  );

  /// Mirrors [TransactionStore.overviewBudgetItems]: a Budget or income goal
  /// represents the whole active period, not the currently selected category
  /// or merchant avatar.
  static List<TransactionRecord> overviewRecordsForInput(
    BalanceFrameInput input,
  ) => recordsForAvatarScope(input);

  static CategoryBudgetBarData overviewBarFromData(
    BalanceFrameInput input,
    OverviewBudgetData overview,
  ) {
    final kind = overview.kind;
    return CategoryBudgetBarData(
      key: overview.key,
      targetType: LimitTargetType.overview,
      targetId: 0,
      transactionType: input.activeType,
      window: overview.window,
      periodKey: overview.periodKey,
      title: overview.title,
      spent: overview.amount,
      hasLimit: overview.hasLimit,
      limitAmount: overview.limitAmount,
      alertActive: overview.alertActive,
      color: CategoryColorManager.color(_overviewSlot(kind)),
      iconSlot: null,
      category: null,
      sourceLimit: overview.sourceLimit,
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
    final overviewSlot = _overviewSlot(kind);
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

  static int _overviewSlot(BudgetGoalKind kind) => switch (kind) {
    BudgetGoalKind.expenseBudget => 11,
    BudgetGoalKind.incomeGoal => 16,
    BudgetGoalKind.savingGoal => 14,
  };
}
