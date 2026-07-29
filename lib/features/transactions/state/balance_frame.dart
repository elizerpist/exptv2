import 'dart:math' as math;

import '../models/category_limit.dart';
import '../models/fast_info_metric.dart';
import '../models/fast_info_metric_snapshot.dart';
import '../models/recurring_ghost_record.dart';
import '../models/summary_window.dart';
import '../models/transaction_category.dart';
import '../models/transaction_log_entry.dart';
import '../models/transaction_record.dart';
import 'balance_amount_formatter.dart';
import 'balance_metrics_resolver.dart';
import 'transaction_store.dart';

enum BalanceInsightKind {
  noSpend,
  categoryChange,
  latestTransaction,
  trendComparison,
  upcomingRecurring,
}

enum BalanceBudgetPeriod { day, week, month }

enum BalanceCategoryPeriod { day, week, month, year }

enum BalanceMerchantPeriod { year, month, allTime }

/// Dimensions for the query-derived ranking detail cards.
enum SpendeeBalanceRankDimension { month, year, all }

/// Dimensions for the query-derived average detail card.
enum SpendeeBalanceAverageDimension { day, week, month, year }

/// Four query-derived views for the no-spend FastInfo card.
enum SpendeeBalanceNoSpendDimension { week, month, year, all }

enum BalanceGhostSection {
  noSpend,
  categoryChange,
  latestTransaction,
  trendComparison,
  upcomingRecurring,
  variableBudget,
  topCategories,
  topMerchants,
  averageDaily,
}

class BalanceGhostPolicy {
  const BalanceGhostPolicy._(this.includedSections);

  factory BalanceGhostPolicy.only(Set<BalanceGhostSection> sections) {
    return BalanceGhostPolicy._(
      Set<BalanceGhostSection>.unmodifiable(sections),
    );
  }

  static const none = BalanceGhostPolicy._(<BalanceGhostSection>{});
  static final all = BalanceGhostPolicy.only(
    BalanceGhostSection.values.toSet(),
  );

  final Set<BalanceGhostSection> includedSections;

  bool includes(BalanceGhostSection section) =>
      includedSections.contains(section);
}

class BalanceFrameInput {
  BalanceFrameInput({
    required this.now,
    required this.activeType,
    required this.summaryWindow,
    required this.summaryReferenceDate,
    required List<TransactionRecord> transactions,
    required List<RecurringGhostRecord> recurringGhosts,
    required List<TransactionCategory> categories,
    required List<CategoryLimit> limits,
    this.searchQuery = '',
    Set<String> merchantFilters = const <String>{},
    Set<int> categoryIds = const <int>{},
    Map<String, FastInfoMetricResult> fastInfoMetrics =
        const <String, FastInfoMetricResult>{},
    List<TransactionLogEntry> displayLogEntries = const <TransactionLogEntry>[],
    this.displayLogSummaryWindow,
    this.displayLogSummaryReferenceDate,
    this.visibleLogEntryLimit,
    this.totalLogEntryCount,
    this.hasMoreLogEntries,
    this.ghostProjectionInFlight = false,
  }) : merchantFilters = Set<String>.unmodifiable(
         merchantFilters
             .map((merchant) => merchant.trim())
             .where((merchant) => merchant.isNotEmpty),
       ),
       categoryIds = Set<int>.unmodifiable(categoryIds),
       transactions = List<TransactionRecord>.unmodifiable(transactions),
       recurringGhosts = List<RecurringGhostRecord>.unmodifiable(
         recurringGhosts,
       ),
       categories = List<TransactionCategory>.unmodifiable(categories),
       limits = List<CategoryLimit>.unmodifiable(limits),
       fastInfoMetrics = Map<String, FastInfoMetricResult>.unmodifiable(
         fastInfoMetrics,
       ),
       displayLogEntries = List<TransactionLogEntry>.unmodifiable(
         displayLogEntries,
       );

  BalanceFrameInput._fromStore({
    required this.now,
    required this.activeType,
    required this.summaryWindow,
    required this.summaryReferenceDate,
    required this.searchQuery,
    required this.merchantFilters,
    required this.categoryIds,
    required this.transactions,
    required this.recurringGhosts,
    required this.categories,
    required this.limits,
    required this.fastInfoMetrics,
    required this.displayLogEntries,
    required this.displayLogSummaryWindow,
    required this.displayLogSummaryReferenceDate,
    required this.visibleLogEntryLimit,
    required this.totalLogEntryCount,
    required this.hasMoreLogEntries,
    required this.ghostProjectionInFlight,
  });

  factory BalanceFrameInput.fromStore(TransactionStore store) {
    final displayLogEntries = store.balanceVisibleDisplayLogEntries;
    final visibleRows = displayLogEntries
        .where((entry) => !entry.isHeader)
        .length;
    final currentDate = store.currentDate;
    return BalanceFrameInput._fromStore(
      now: DateTime(currentDate.year, currentDate.month, currentDate.day),
      activeType: store.activeType,
      summaryWindow: store.summaryWindow,
      summaryReferenceDate: store.summaryReferenceDate,
      searchQuery: store.searchQuery,
      merchantFilters: store.activeMerchantFilters,
      categoryIds: store.activeCategoryIds,
      transactions: store.transactions,
      recurringGhosts: store.balanceRecurringGhostTransactions,
      categories: store.categories,
      limits: store.limits,
      // Balance resolves its own query-and-rail-scoped metrics below. Reading
      // the legacy global map here would synchronously scan every transaction
      // on each rail/type change, despite not being consumed by this frame.
      fastInfoMetrics: const <String, FastInfoMetricResult>{},
      displayLogEntries: displayLogEntries,
      displayLogSummaryWindow: store.summaryWindow,
      displayLogSummaryReferenceDate: store.summaryReferenceDate,
      visibleLogEntryLimit: visibleRows,
      totalLogEntryCount: store.balanceVisibleDisplayLogEntryTotalCount,
      hasMoreLogEntries: store.hasMoreBalanceVisibleDisplayLogEntries,
      ghostProjectionInFlight: store.recurringGhostProjectionInFlight,
    );
  }

  bool sameRevisionAs(BalanceFrameInput other) {
    return _sameSourceAndQueryAs(other) &&
        identical(recurringGhosts, other.recurringGhosts) &&
        identical(fastInfoMetrics, other.fastInfoMetrics) &&
        identical(displayLogEntries, other.displayLogEntries) &&
        _sameDisplayWindowAs(other);
  }

  /// Compares the immutable source/query revision used by the bounded Balance
  /// history cache. A rail return deliberately rebuilds the presentation-log
  /// list and the obsolete store FastInfo map; neither changes the frame
  /// resolver's result. Generated ghosts remain part of the comparison so a
  /// changed recurring projection can never reuse stale card or log data.
  bool sameHistoryRevisionAs(
    BalanceFrameInput other, {
    bool ignoreGhostProjectionInFlight = false,
  }) {
    return _sameSourceAndQueryAs(other) &&
        _sameRecurringGhostSnapshot(recurringGhosts, other.recurringGhosts) &&
        _sameDisplayWindowAs(
          other,
          ignoreGhostProjectionInFlight: ignoreGhostProjectionInFlight,
        );
  }

  bool _sameSourceAndQueryAs(BalanceFrameInput other) {
    return now == other.now &&
        activeType == other.activeType &&
        summaryWindow == other.summaryWindow &&
        summaryReferenceDate == other.summaryReferenceDate &&
        searchQuery == other.searchQuery &&
        _sameSet(merchantFilters, other.merchantFilters) &&
        _sameSet(categoryIds, other.categoryIds) &&
        identical(transactions, other.transactions) &&
        identical(categories, other.categories) &&
        identical(limits, other.limits);
  }

  bool _sameDisplayWindowAs(
    BalanceFrameInput other, {
    bool ignoreGhostProjectionInFlight = false,
  }) {
    return displayLogSummaryWindow == other.displayLogSummaryWindow &&
        displayLogSummaryReferenceDate ==
            other.displayLogSummaryReferenceDate &&
        visibleLogEntryLimit == other.visibleLogEntryLimit &&
        totalLogEntryCount == other.totalLogEntryCount &&
        hasMoreLogEntries == other.hasMoreLogEntries &&
        (ignoreGhostProjectionInFlight ||
            ghostProjectionInFlight == other.ghostProjectionInFlight);
  }

  final DateTime now;
  final TransactionType activeType;
  final SummaryWindow summaryWindow;
  final DateTime summaryReferenceDate;
  final String searchQuery;
  final Set<String> merchantFilters;
  final Set<int> categoryIds;
  final List<TransactionRecord> transactions;
  final List<RecurringGhostRecord> recurringGhosts;
  final List<TransactionCategory> categories;
  final List<CategoryLimit> limits;
  final Map<String, FastInfoMetricResult> fastInfoMetrics;
  final List<TransactionLogEntry> displayLogEntries;
  final SummaryWindow? displayLogSummaryWindow;
  final DateTime? displayLogSummaryReferenceDate;
  final int? visibleLogEntryLimit;
  final int? totalLogEntryCount;
  final bool? hasMoreLogEntries;
  final bool ghostProjectionInFlight;
}

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameRecurringGhostSnapshot(
  List<RecurringGhostRecord> left,
  List<RecurringGhostRecord> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    final first = left[index];
    final second = right[index];
    if (first.id != second.id ||
        first.recurringTransactionId != second.recurringTransactionId ||
        first.periodKey != second.periodKey ||
        first.name != second.name ||
        first.amount != second.amount ||
        first.triggerType != second.triggerType ||
        first.transactionType != second.transactionType ||
        first.date != second.date ||
        first.time != second.time ||
        first.categoryId != second.categoryId ||
        first.categoryName != second.categoryName ||
        first.categoryColor != second.categoryColor ||
        first.categoryIconSlot != second.categoryIconSlot ||
        first.triggerMillis != second.triggerMillis ||
        first.isActivated != second.isActivated ||
        first.activatedTransactionId != second.activatedTransactionId ||
        first.createdAt != second.createdAt ||
        first.updatedAt != second.updatedAt) {
      return false;
    }
  }
  return true;
}

class BalanceTimeScopeOption {
  const BalanceTimeScopeOption({
    required this.window,
    required this.referenceDate,
    required this.key,
    required this.label,
    required this.recordCount,
  });

  final SummaryWindow window;
  final DateTime referenceDate;
  final String key;
  final String label;
  final int recordCount;
}

class BalanceQueryFrame {
  BalanceQueryFrame({
    required this.activeType,
    required this.summaryWindow,
    required this.requestedReferenceDate,
    required this.effectiveReferenceDate,
    required this.searchQuery,
    required Set<String> merchantFilters,
    required Set<int> categoryIds,
    required List<BalanceTimeScopeOption> scopeOptions,
    required this.selectedScope,
    required List<TransactionCategory> availableCategories,
    required List<String> availableMerchants,
  }) : merchantFilters = Set<String>.unmodifiable(merchantFilters),
       categoryIds = Set<int>.unmodifiable(categoryIds),
       scopeOptions = List<BalanceTimeScopeOption>.unmodifiable(scopeOptions),
       availableCategories = List<TransactionCategory>.unmodifiable(
         availableCategories,
       ),
       availableMerchants = List<String>.unmodifiable(availableMerchants);

  final TransactionType activeType;
  final SummaryWindow summaryWindow;
  final DateTime requestedReferenceDate;
  final DateTime effectiveReferenceDate;
  final String searchQuery;
  final Set<String> merchantFilters;
  final Set<int> categoryIds;
  final List<BalanceTimeScopeOption> scopeOptions;
  final BalanceTimeScopeOption? selectedScope;
  final List<TransactionCategory> availableCategories;
  final List<String> availableMerchants;

  bool get hasPendingScopeFallback =>
      summaryWindow != SummaryWindow.allTime &&
      !_sameSummaryPeriod(
        summaryWindow,
        requestedReferenceDate,
        effectiveReferenceDate,
      );
}

class BalanceScopeCommitAdapter {
  const BalanceScopeCommitAdapter._();

  static Future<bool> commitIfNeeded(
    TransactionStore store,
    BalanceQueryFrame query,
  ) async {
    if (!query.hasPendingScopeFallback) return false;
    if (store.summaryWindow != query.summaryWindow ||
        !_sameSummaryPeriod(
          query.summaryWindow,
          store.summaryReferenceDate,
          query.requestedReferenceDate,
        )) {
      return false;
    }
    switch (query.summaryWindow) {
      case SummaryWindow.monthly:
        await store.setSummaryMonth(
          query.effectiveReferenceDate.year,
          query.effectiveReferenceDate.month,
        );
        return true;
      case SummaryWindow.yearly:
        await store.setSummaryYear(query.effectiveReferenceDate.year);
        return true;
      case SummaryWindow.allTime:
        return false;
    }
  }
}

class BalanceInsightFrame {
  const BalanceInsightFrame({
    required this.kind,
    required this.title,
    required this.primaryText,
    required this.secondaryText,
    this.numericValue,
    this.comparisonValue,
    this.direction,
    this.category,
    this.record,
    this.ghost,
    this.sourceMetric,
  });

  final BalanceInsightKind kind;
  final String title;
  final String primaryText;
  final String secondaryText;
  final double? numericValue;
  final double? comparisonValue;
  final String? direction;
  final TransactionCategory? category;
  final TransactionRecord? record;
  final RecurringGhostRecord? ghost;
  final FastInfoMetricResult? sourceMetric;
}

class BalanceVariableBudgetDimension {
  const BalanceVariableBudgetDimension({
    required this.period,
    required this.label,
    required this.spent,
    required this.budget,
    required this.remaining,
    required this.transactionCount,
    required this.progress,
    required this.referenceAmount,
  });

  final BalanceBudgetPeriod period;
  final String label;
  final double spent;
  final double budget;
  final double remaining;
  final int transactionCount;
  final double progress;
  final double referenceAmount;
}

class BalanceCategoryRank {
  const BalanceCategoryRank({
    required this.period,
    required this.category,
    required this.amount,
    required this.transactionCount,
  });

  final BalanceCategoryPeriod period;
  final TransactionCategory? category;
  final double amount;
  final int transactionCount;
}

class BalanceMerchantRank {
  const BalanceMerchantRank({
    required this.period,
    required this.rank,
    required this.name,
    required this.amount,
    required this.transactionCount,
    this.category,
  });

  final BalanceMerchantPeriod period;
  final int rank;
  final String name;
  final double amount;
  final int transactionCount;
  final TransactionCategory? category;
}

class BalanceAverageDailyFrame {
  BalanceAverageDailyFrame({
    required List<double> dailySeries,
    required this.rollingTotal,
    required this.average,
    required this.bufferDays,
    required this.highestDay,
    required this.spikeThreshold,
    required this.spikeDays,
  }) : dailySeries = List<double>.unmodifiable(dailySeries);

  final List<double> dailySeries;
  final double rollingTotal;
  final double average;
  final int? bufferDays;
  final double highestDay;
  final double spikeThreshold;
  final int spikeDays;
}

/// One immutable, pre-ranked category or vendor result.
class BalanceRankRow {
  const BalanceRankRow({
    required this.rank,
    required this.id,
    required this.name,
    required this.amount,
    required this.transactionCount,
    this.category,
  });

  final int rank;
  final String id;
  final String name;
  final double amount;
  final int transactionCount;
  final TransactionCategory? category;
}

/// Traceable input-derived average statistics for one calendar dimension.
class BalanceAverageFrame {
  BalanceAverageFrame({
    required this.total,
    required this.observedDays,
    required this.dailyAverage,
    required this.trend,
    required this.bufferDays,
    required this.maximum,
    required this.outlierThreshold,
    required this.outlierCount,
    required List<double> dailyValues,
  }) : dailyValues = List<double>.unmodifiable(dailyValues);

  final double total;
  final int observedDays;
  final double dailyAverage;
  final double trend;
  final int? bufferDays;
  final double maximum;
  final double outlierThreshold;
  final int outlierCount;
  final List<double> dailyValues;
}

/// Calendar-day coverage for one no-spend view.
class BalanceNoSpendFrame {
  const BalanceNoSpendFrame({
    required this.observedDays,
    required this.noSpendDays,
  });

  final int observedDays;
  final int noSpendDays;
}

class BalanceSummaryFrame {
  const BalanceSummaryFrame({
    required this.window,
    required this.referenceDate,
    required this.label,
    required this.income,
    required this.expense,
    required this.activeAmount,
    required this.amountText,
  });

  final SummaryWindow window;
  final DateTime referenceDate;
  final String label;
  final double income;
  final double expense;
  final double activeAmount;
  final String amountText;
}

class BalanceLogRow {
  const BalanceLogRow._({this.record, this.ghost});

  factory BalanceLogRow.record(TransactionRecord record) =>
      BalanceLogRow._(record: record);

  factory BalanceLogRow.ghost(RecurringGhostRecord ghost) =>
      BalanceLogRow._(ghost: ghost);

  final TransactionRecord? record;
  final RecurringGhostRecord? ghost;

  bool get isGhost => ghost != null;
  String get date => record?.date ?? ghost!.date;
  String get time => record?.time ?? ghost?.time ?? '';
  int get sortId => record?.id ?? ghost?.id ?? 0;
  String get merchant => record?.displayMerchant ?? ghost?.name ?? '';
  double get amount => record?.amount ?? ghost?.amount ?? 0;
  String get amountText => formatBalanceSignedForint(
    record?.amount ??
        (ghost!.type == TransactionType.income
            ? ghost!.amount.abs()
            : -ghost!.amount.abs()),
  );
}

class BalanceLogGroup {
  BalanceLogGroup({required this.date, required List<BalanceLogRow> rows})
    : rows = List<BalanceLogRow>.unmodifiable(rows);

  final String date;
  final List<BalanceLogRow> rows;
}

class BalanceRenderFrame {
  BalanceRenderFrame({
    required this.query,
    required this.balance,
    required this.reserveRatio,
    required this.incomeRatio,
    required this.expenseRatio,
    required Map<BalanceInsightKind, BalanceInsightFrame> insights,
    required Map<BalanceBudgetPeriod, BalanceVariableBudgetDimension>
    variableBudgets,
    required Map<BalanceCategoryPeriod, BalanceCategoryRank?> topCategories,
    required Map<BalanceMerchantPeriod, List<BalanceMerchantRank>> topMerchants,
    required Map<String, FastInfoMetricResult> fastInfoMetrics,
    required this.averageDaily,
    required this.summary,
    required List<BalanceLogGroup> logGroups,
    required this.visibleLogRowCount,
    required this.totalLogEntryCount,
    required this.hasMoreLogEntries,
    required this.transactionCount,
    required List<String> availableMonthScopes,
    required List<int> availableYearScopes,
    required Map<SpendeeBalanceRankDimension, List<BalanceRankRow>>
    categoryRanks,
    required Map<SpendeeBalanceRankDimension, List<BalanceRankRow>> vendorRanks,
    required Map<SpendeeBalanceAverageDimension, BalanceAverageFrame> averages,
    required Map<SpendeeBalanceNoSpendDimension, BalanceNoSpendFrame> noSpend,
  }) : insights = Map<BalanceInsightKind, BalanceInsightFrame>.unmodifiable(
         insights,
       ),
       variableBudgets =
           Map<
             BalanceBudgetPeriod,
             BalanceVariableBudgetDimension
           >.unmodifiable(variableBudgets),
       topCategories =
           Map<BalanceCategoryPeriod, BalanceCategoryRank?>.unmodifiable(
             topCategories,
           ),
       topMerchants =
           Map<BalanceMerchantPeriod, List<BalanceMerchantRank>>.unmodifiable({
             for (final entry in topMerchants.entries)
               entry.key: List<BalanceMerchantRank>.unmodifiable(entry.value),
           }),
       fastInfoMetrics = Map<String, FastInfoMetricResult>.unmodifiable(
         fastInfoMetrics,
       ),
       logGroups = List<BalanceLogGroup>.unmodifiable(logGroups),
       availableMonthScopes = List<String>.unmodifiable(availableMonthScopes),
       availableYearScopes = List<int>.unmodifiable(availableYearScopes),
       _categoryRanks = _immutableRanks(categoryRanks),
       _vendorRanks = _immutableRanks(vendorRanks),
       _averages =
           Map<
             SpendeeBalanceAverageDimension,
             BalanceAverageFrame
           >.unmodifiable(averages),
       _noSpend =
           Map<
             SpendeeBalanceNoSpendDimension,
             BalanceNoSpendFrame
           >.unmodifiable(noSpend);

  final BalanceQueryFrame query;
  final double balance;
  final double reserveRatio;
  final double incomeRatio;
  final double expenseRatio;
  final Map<BalanceInsightKind, BalanceInsightFrame> insights;
  final Map<BalanceBudgetPeriod, BalanceVariableBudgetDimension>
  variableBudgets;
  final Map<BalanceCategoryPeriod, BalanceCategoryRank?> topCategories;
  final Map<BalanceMerchantPeriod, List<BalanceMerchantRank>> topMerchants;
  final Map<String, FastInfoMetricResult> fastInfoMetrics;
  final BalanceAverageDailyFrame averageDaily;
  final BalanceSummaryFrame summary;
  final List<BalanceLogGroup> logGroups;
  final int visibleLogRowCount;
  final int totalLogEntryCount;
  final bool hasMoreLogEntries;
  final int transactionCount;
  final List<String> availableMonthScopes;
  final List<int> availableYearScopes;
  final Map<SpendeeBalanceRankDimension, List<BalanceRankRow>> _categoryRanks;
  final Map<SpendeeBalanceRankDimension, List<BalanceRankRow>> _vendorRanks;
  final Map<SpendeeBalanceAverageDimension, BalanceAverageFrame> _averages;
  final Map<SpendeeBalanceNoSpendDimension, BalanceNoSpendFrame> _noSpend;

  List<BalanceRankRow> topCategoriesFor(
    SpendeeBalanceRankDimension dimension,
  ) => _categoryRanks[dimension] ?? const <BalanceRankRow>[];

  List<BalanceRankRow> topVendorsFor(SpendeeBalanceRankDimension dimension) =>
      _vendorRanks[dimension] ?? const <BalanceRankRow>[];

  BalanceAverageFrame averageFor(SpendeeBalanceAverageDimension dimension) =>
      _averages[dimension]!;

  BalanceNoSpendFrame noSpendFor(SpendeeBalanceNoSpendDimension dimension) =>
      _noSpend[dimension]!;
}

Map<SpendeeBalanceRankDimension, List<BalanceRankRow>> _immutableRanks(
  Map<SpendeeBalanceRankDimension, List<BalanceRankRow>> ranks,
) => Map<SpendeeBalanceRankDimension, List<BalanceRankRow>>.unmodifiable({
  for (final entry in ranks.entries)
    entry.key: List<BalanceRankRow>.unmodifiable(entry.value),
});

class BalanceFrameResolver {
  const BalanceFrameResolver._();

  static BalanceRenderFrame resolve(
    BalanceFrameInput input, {
    BalanceGhostPolicy? ghostPolicy,
    bool includeDetailMetrics = true,
  }) {
    return _BalanceFrameScope(
      input,
      ghostPolicy ?? BalanceGhostPolicy.all,
      includeDetailMetrics: includeDetailMetrics,
    ).resolve();
  }
}

/// Bounded LRU for the expensive aggregate bundles behind Balance detail
/// cards. Store-backed [BalanceFrameInput] instances retain their immutable
/// source-list identities while a recent action, filter or rail query returns,
/// so that query's expensive aggregate does not run again.
class _BalanceMetricBundleCache {
  // Five-plus rail periods × two transaction types must survive a fast return
  // gesture; the old 12-entry cache evicted a just-visited year too early.
  static const _capacity = 32;
  static final Map<_BalanceMetricBundleCacheKey, _BalanceMetricBundlePair>
  _entries = <_BalanceMetricBundleCacheKey, _BalanceMetricBundlePair>{};

  static _BalanceMetricBundlePair resolve({
    required BalanceFrameInput input,
    required DateTime referenceDate,
    required List<TransactionRecord> transactions,
    required List<RecurringGhostRecord> ghosts,
  }) {
    final key = _BalanceMetricBundleCacheKey.fromInput(
      input,
      referenceDate: referenceDate,
    );
    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }
    final snapshot = FastInfoMetricSnapshot(
      now: referenceDate,
      balance: transactions.fold<double>(
        0,
        (sum, record) => sum + record.amount,
      ),
      transactions: transactions,
      categories: input.categories,
      limits: input.limits,
    );
    final canonical = BalanceMetricsResolver.resolve(snapshot);
    final resolved = _BalanceMetricBundlePair(
      canonical: canonical,
      withGhosts: ghosts.isEmpty
          ? canonical
          : BalanceMetricsResolver.resolve(snapshot, includedGhosts: ghosts),
    );
    _entries[key] = resolved;
    if (_entries.length > _capacity) {
      _entries.remove(_entries.keys.first);
    }
    return resolved;
  }
}

class _BalanceMetricBundlePair {
  const _BalanceMetricBundlePair({
    required this.canonical,
    required this.withGhosts,
  });

  final BalanceMetricBundle canonical;
  final BalanceMetricBundle withGhosts;
}

class _BalanceMetricBundleCacheKey {
  _BalanceMetricBundleCacheKey._({
    required this.transactions,
    required this.recurringGhosts,
    required this.categories,
    required this.limits,
    required this.referenceDate,
    required this.summaryWindow,
    required this.summaryReferenceDate,
    required this.activeType,
    required this.searchQuery,
    required this.merchantFilterKey,
    required this.categoryFilterKey,
  });

  factory _BalanceMetricBundleCacheKey.fromInput(
    BalanceFrameInput input, {
    required DateTime referenceDate,
  }) {
    final merchants = input.merchantFilters.toList()..sort();
    final categoryIds = input.categoryIds.toList()..sort();
    return _BalanceMetricBundleCacheKey._(
      transactions: input.transactions,
      recurringGhosts: input.recurringGhosts,
      categories: input.categories,
      limits: input.limits,
      referenceDate: referenceDate,
      summaryWindow: input.summaryWindow,
      summaryReferenceDate: input.summaryReferenceDate,
      activeType: input.activeType,
      searchQuery: input.searchQuery,
      merchantFilterKey: merchants.join('\u001f'),
      categoryFilterKey: categoryIds.join(','),
    );
  }

  final List<TransactionRecord> transactions;
  final List<RecurringGhostRecord> recurringGhosts;
  final List<TransactionCategory> categories;
  final List<CategoryLimit> limits;
  final DateTime referenceDate;
  final SummaryWindow summaryWindow;
  final DateTime summaryReferenceDate;
  final TransactionType activeType;
  final String searchQuery;
  final String merchantFilterKey;
  final String categoryFilterKey;

  @override
  bool operator ==(Object other) =>
      other is _BalanceMetricBundleCacheKey &&
      identical(transactions, other.transactions) &&
      identical(recurringGhosts, other.recurringGhosts) &&
      identical(categories, other.categories) &&
      identical(limits, other.limits) &&
      referenceDate == other.referenceDate &&
      summaryWindow == other.summaryWindow &&
      summaryReferenceDate == other.summaryReferenceDate &&
      activeType == other.activeType &&
      searchQuery == other.searchQuery &&
      merchantFilterKey == other.merchantFilterKey &&
      categoryFilterKey == other.categoryFilterKey;

  @override
  int get hashCode => Object.hash(
    identityHashCode(transactions),
    identityHashCode(recurringGhosts),
    identityHashCode(categories),
    identityHashCode(limits),
    referenceDate,
    summaryWindow,
    summaryReferenceDate,
    activeType,
    searchQuery,
    merchantFilterKey,
    categoryFilterKey,
  );
}

class _BalanceFrameScope {
  _BalanceFrameScope(
    this.input,
    this.ghostPolicy, {
    required this.includeDetailMetrics,
  }) : now = _dateOnly(input.now) {
    _recordIds = <String>{
      for (final record in input.transactions)
        _typedKey(record.type, record.id),
    };
    _recurringInstanceIds = <String>{
      for (final record in input.transactions)
        if (record.recurringInstanceId case final recurringInstanceId?)
          _typedKey(record.type, recurringInstanceId),
    };
    _recurringMonthKeys = <String>{
      for (final record in input.transactions)
        if (record.recurringTransactionId case final recurringTransactionId?)
          '${record.type.name}|$recurringTransactionId|${record.yearMonthKey}',
    };
    filteredRecords = List<TransactionRecord>.unmodifiable(
      input.transactions.where(_matchesRecord),
    );
    pendingGhosts = List<RecurringGhostRecord>.unmodifiable(
      _dedupePendingGhosts(),
    );
    filteredPendingGhosts = List<RecurringGhostRecord>.unmodifiable(
      pendingGhosts.where(_matchesGhost),
    );
    scopeOptions = _buildScopeOptions();
    selectedScope = _selectNearestScope(scopeOptions);
    effectiveReferenceDate =
        input.summaryWindow == SummaryWindow.allTime || selectedScope == null
        ? input.summaryReferenceDate
        : selectedScope!.referenceDate;
    scopedRecords = List<TransactionRecord>.unmodifiable(
      filteredRecords.where(
        (record) => _inSummaryWindow(
          _parseDate(record.normalizedDate),
          input.summaryWindow,
          effectiveReferenceDate,
        ),
      ),
    );
    scopedGhosts = input.summaryWindow == SummaryWindow.monthly
        ? List<RecurringGhostRecord>.unmodifiable(
            filteredPendingGhosts.where(
              (ghost) => _inSummaryWindow(
                _parseDate(ghost.normalizedDate),
                input.summaryWindow,
                effectiveReferenceDate,
              ),
            ),
          )
        : const <RecurringGhostRecord>[];
    detailAnchorDay = _detailAnchorFor(
      window: input.summaryWindow,
      referenceDate: effectiveReferenceDate,
      now: now,
    );
    if (!includeDetailMetrics) {
      // Budget V2 renders its own category/vendor visualisation. It still
      // needs the query, header summary and transaction log, but it never
      // consumes normal Balance detail cards or their FastInfo metric bundle.
      // Avoiding those scans keeps a final avatar-filter commit from blocking
      // the next physical belt interaction.
      canonicalDetailRows = const <_BalanceDetailRow>[];
      scopedGhostDetailRows = const <_BalanceDetailRow>[];
      canonicalBalanceMetrics = null;
      ghostBalanceMetrics = null;
      return;
    }
    // Detail cards share the exact selected rail scope with the header, log,
    // summary and FastInfo values. Their Havi/Éves/Össz. pills only choose a
    // presentation aggregation inside this active result set; they may never
    // pull a record back in from another rail period.
    canonicalDetailRows = _detailRowsFromRecords(scopedRecords);
    scopedGhostDetailRows = _detailRowsFromGhosts(scopedGhosts);
    final bundlePair = _BalanceMetricBundleCache.resolve(
      input: input,
      // Every visible Balance metric uses the same active type/search/filter
      // query and selected rail period as the log and summary. Detail cards
      // retain their own calendar dimensions below, anchored to this scope.
      referenceDate: detailAnchorDay ?? now,
      transactions: scopedRecords,
      ghosts: scopedGhosts,
    );
    canonicalBalanceMetrics = bundlePair.canonical;
    ghostBalanceMetrics = bundlePair.withGhosts;
  }

  final BalanceFrameInput input;
  final BalanceGhostPolicy ghostPolicy;
  final bool includeDetailMetrics;
  final DateTime now;
  late final Set<String> _recordIds;
  late final Set<String> _recurringInstanceIds;
  late final Set<String> _recurringMonthKeys;
  late final List<TransactionRecord> filteredRecords;
  late final List<RecurringGhostRecord> pendingGhosts;
  late final List<RecurringGhostRecord> filteredPendingGhosts;
  late final List<BalanceTimeScopeOption> scopeOptions;
  late final BalanceTimeScopeOption? selectedScope;
  late final DateTime effectiveReferenceDate;
  late final List<TransactionRecord> scopedRecords;
  late final List<RecurringGhostRecord> scopedGhosts;
  late final List<_BalanceDetailRow> canonicalDetailRows;
  late final List<_BalanceDetailRow> scopedGhostDetailRows;
  late final DateTime? detailAnchorDay;
  final Map<BalanceGhostSection, List<_BalanceDetailRow>> _detailRowsBySection =
      <BalanceGhostSection, List<_BalanceDetailRow>>{};
  late final BalanceMetricBundle? canonicalBalanceMetrics;
  late final BalanceMetricBundle? ghostBalanceMetrics;

  BalanceRenderFrame resolve() {
    final globalIncome = scopedRecords
        .where((record) => record.amount > 0)
        .fold<double>(0, (sum, record) => sum + record.amount);
    final globalExpense = scopedRecords
        .where((record) => record.amount < 0)
        .fold<double>(0, (sum, record) => sum + record.amount.abs());
    final balance = globalIncome - globalExpense;
    final globalFlow = globalIncome + globalExpense;
    final metricReference = detailAnchorDay ?? now;
    final currentMonthStart = DateTime(
      metricReference.year,
      metricReference.month,
    );
    final nextMonthStart = DateTime(
      metricReference.year,
      metricReference.month + 1,
    );
    final currentMonthRows = scopedRecords.where((record) {
      final date = _parseDate(record.normalizedDate);
      return date != null &&
          !date.isBefore(currentMonthStart) &&
          date.isBefore(nextMonthStart);
    });
    final currentIncome = currentMonthRows
        .where((record) => record.amount > 0)
        .fold<double>(0, (sum, record) => sum + record.amount);
    final currentExpense = currentMonthRows
        .where((record) => record.amount < 0)
        .fold<double>(0, (sum, record) => sum + record.amount.abs());
    final currentFlow = currentIncome + currentExpense;

    final query = BalanceQueryFrame(
      activeType: input.activeType,
      summaryWindow: input.summaryWindow,
      requestedReferenceDate: input.summaryReferenceDate,
      effectiveReferenceDate: effectiveReferenceDate,
      searchQuery: input.searchQuery,
      merchantFilters: input.merchantFilters,
      categoryIds: input.categoryIds,
      scopeOptions: scopeOptions,
      selectedScope: selectedScope,
      availableCategories:
          input.categories
              .where((category) => category.normalizedType == input.activeType)
              .toList()
            ..sort((left, right) => left.name.compareTo(right.name)),
      availableMerchants:
          filteredRecords
              .map((record) => record.displayMerchant)
              .where((merchant) => merchant.isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
    );
    final matchingLogSnapshot = _hasMatchingLogSnapshot;
    final logGroups = matchingLogSnapshot
        ? _buildLogGroupsFromSnapshot()
        : _buildLogGroupsFromCanonicalRows();
    final visibleLogRowCount = logGroups.fold<int>(
      0,
      (sum, group) => sum + group.rows.length,
    );
    final calculatedTotal =
        scopedRecords.length +
        scopedGhosts.length +
        _allLogGroupCount(scopedRecords, scopedGhosts);
    final totalLogEntryCount = matchingLogSnapshot
        ? input.totalLogEntryCount ?? calculatedTotal
        : calculatedTotal;
    final hasMore = matchingLogSnapshot
        ? input.hasMoreLogEntries ??
              (visibleLogRowCount + logGroups.length < totalLogEntryCount)
        : visibleLogRowCount < scopedRecords.length + scopedGhosts.length;
    final reserveRatio = globalIncome <= 0
        ? 0.0
        : (math.max(0.0, balance) / globalIncome).clamp(0.0, 1.0);
    final incomeRatio = currentFlow <= 0
        ? (globalFlow <= 0 ? 0.0 : globalIncome / globalFlow)
        : currentIncome / currentFlow;
    final expenseRatio = currentFlow <= 0
        ? (globalFlow <= 0 ? 0.0 : globalExpense / globalFlow)
        : currentExpense / currentFlow;
    final summary = _buildSummary();
    if (!includeDetailMetrics) {
      return _buildLightweightFrame(
        query: query,
        balance: balance,
        reserveRatio: reserveRatio,
        incomeRatio: incomeRatio,
        expenseRatio: expenseRatio,
        summary: summary,
        logGroups: logGroups,
        visibleLogRowCount: visibleLogRowCount,
        totalLogEntryCount: totalLogEntryCount,
        hasMoreLogEntries: hasMore,
      );
    }
    final insights = _buildInsights();
    final averageDaily = _buildAverageDaily();
    final detailAggregates = _buildDetailAggregates();
    final detailScopes = _buildDetailScopes();
    final noSpend = _buildNoSpendFrames();
    final fastInfoMetrics = <String, FastInfoMetricResult>{
      ...canonicalBalanceMetrics!.fastInfoMetrics,
      'no_spend_napok_szama':
          insights[BalanceInsightKind.noSpend]!.sourceMetric!,
      'legnagyobb_novekedo_kategoria':
          insights[BalanceInsightKind.categoryChange]!.sourceMetric!,
      'legutobbi_tranzakcio':
          insights[BalanceInsightKind.latestTransaction]!.sourceMetric!,
      'koltesi_trend':
          insights[BalanceInsightKind.trendComparison]!.sourceMetric!,
      'kovetkezo_ismetlo_kiadas':
          insights[BalanceInsightKind.upcomingRecurring]!.sourceMetric!,
      'atlagos_napi_koltes': _metricFor(
        BalanceGhostSection.averageDaily,
        'atlagos_napi_koltes',
      ),
    };

    return BalanceRenderFrame(
      query: query,
      balance: balance,
      reserveRatio: reserveRatio,
      incomeRatio: incomeRatio,
      expenseRatio: expenseRatio,
      insights: insights,
      variableBudgets: _buildVariableBudgets(),
      topCategories: _buildTopCategories(),
      topMerchants: _buildTopMerchants(),
      fastInfoMetrics: fastInfoMetrics,
      averageDaily: averageDaily,
      summary: summary,
      logGroups: logGroups,
      visibleLogRowCount: visibleLogRowCount,
      totalLogEntryCount: totalLogEntryCount,
      hasMoreLogEntries: hasMore,
      transactionCount: visibleLogRowCount,
      availableMonthScopes: detailScopes.months,
      availableYearScopes: detailScopes.years,
      categoryRanks: detailAggregates.categoryRanks,
      vendorRanks: detailAggregates.vendorRanks,
      averages: detailAggregates.averages,
      noSpend: noSpend,
    );
  }

  bool _matchesRecord(TransactionRecord record) {
    if (record.type != input.activeType) return false;
    if (input.categoryIds.isNotEmpty &&
        !input.categoryIds.contains(record.transactionCategoryID)) {
      return false;
    }
    if (input.merchantFilters.isNotEmpty &&
        !input.merchantFilters.contains(record.displayMerchant)) {
      return false;
    }
    final query = input.searchQuery.trim().toLowerCase();
    return query.isEmpty ||
        record.displayMerchant.toLowerCase().contains(query);
  }

  bool _matchesGhost(RecurringGhostRecord ghost) {
    if (ghost.type != input.activeType) return false;
    if (input.categoryIds.isNotEmpty &&
        !input.categoryIds.contains(ghost.categoryId)) {
      return false;
    }
    if (input.merchantFilters.isNotEmpty &&
        !input.merchantFilters.contains(ghost.name.trim())) {
      return false;
    }
    final query = input.searchQuery.trim().toLowerCase();
    return query.isEmpty || ghost.name.toLowerCase().contains(query);
  }

  FastInfoMetricResult _metricFor(
    BalanceGhostSection section,
    String metricId,
  ) {
    return _bundleFor(section).fastInfoMetrics[metricId] ??
        const FastInfoMetricResult(
          pillValue: 'Nincs adat',
          primaryValue: 'Nincs adat',
        );
  }

  BalanceMetricBundle _bundleFor(BalanceGhostSection section) =>
      ghostPolicy.includes(section)
      ? ghostBalanceMetrics!
      : canonicalBalanceMetrics!;

  BalanceRenderFrame _buildLightweightFrame({
    required BalanceQueryFrame query,
    required double balance,
    required double reserveRatio,
    required double incomeRatio,
    required double expenseRatio,
    required BalanceSummaryFrame summary,
    required List<BalanceLogGroup> logGroups,
    required int visibleLogRowCount,
    required int totalLogEntryCount,
    required bool hasMoreLogEntries,
  }) {
    final averages = <SpendeeBalanceAverageDimension, BalanceAverageFrame>{
      for (final dimension in SpendeeBalanceAverageDimension.values)
        dimension: BalanceAverageFrame(
          total: 0,
          observedDays: 0,
          dailyAverage: 0,
          trend: 0,
          bufferDays: null,
          maximum: 0,
          outlierThreshold: 0,
          outlierCount: 0,
          dailyValues: const <double>[],
        ),
    };
    final noSpend = <SpendeeBalanceNoSpendDimension, BalanceNoSpendFrame>{
      for (final dimension in SpendeeBalanceNoSpendDimension.values)
        dimension: const BalanceNoSpendFrame(observedDays: 0, noSpendDays: 0),
    };
    return BalanceRenderFrame(
      query: query,
      balance: balance,
      reserveRatio: reserveRatio,
      incomeRatio: incomeRatio,
      expenseRatio: expenseRatio,
      insights: const <BalanceInsightKind, BalanceInsightFrame>{},
      variableBudgets:
          const <BalanceBudgetPeriod, BalanceVariableBudgetDimension>{},
      topCategories: const <BalanceCategoryPeriod, BalanceCategoryRank?>{},
      topMerchants: const <BalanceMerchantPeriod, List<BalanceMerchantRank>>{},
      fastInfoMetrics: const <String, FastInfoMetricResult>{},
      averageDaily: BalanceAverageDailyFrame(
        dailySeries: const <double>[],
        rollingTotal: 0,
        average: 0,
        bufferDays: null,
        highestDay: 0,
        spikeThreshold: 0,
        spikeDays: 0,
      ),
      summary: summary,
      logGroups: logGroups,
      visibleLogRowCount: visibleLogRowCount,
      totalLogEntryCount: totalLogEntryCount,
      hasMoreLogEntries: hasMoreLogEntries,
      transactionCount: visibleLogRowCount,
      availableMonthScopes: const <String>[],
      availableYearScopes: const <int>[],
      categoryRanks:
          const <SpendeeBalanceRankDimension, List<BalanceRankRow>>{},
      vendorRanks: const <SpendeeBalanceRankDimension, List<BalanceRankRow>>{},
      averages: averages,
      noSpend: noSpend,
    );
  }

  _BalanceDetailScopes _buildDetailScopes() {
    final months = <String>{};
    final years = <int>{};
    for (final row in canonicalDetailRows) {
      months.add(_monthKey(row.date));
      years.add(row.date.year);
    }
    return _BalanceDetailScopes(
      months: (months.toList()..sort()),
      years: (years.toList()..sort()),
    );
  }

  _BalanceDetailAggregates _buildDetailAggregates() {
    final categoryRows = _detailRowsFor(BalanceGhostSection.topCategories);
    final vendorRows = _detailRowsFor(BalanceGhostSection.topMerchants);
    final averageRows = _detailRowsFor(BalanceGhostSection.averageDaily);
    final rankMonthStart = DateTime(
      effectiveReferenceDate.year,
      effectiveReferenceDate.month,
    );
    final rankYearStart = DateTime(effectiveReferenceDate.year);
    final rankRows = <SpendeeBalanceRankDimension, List<_BalanceDetailRow>>{
      SpendeeBalanceRankDimension.all: categoryRows,
      SpendeeBalanceRankDimension.month: _rowsInRange(
        categoryRows,
        rankMonthStart,
        DateTime(rankMonthStart.year, rankMonthStart.month + 1),
      ),
      SpendeeBalanceRankDimension.year: _rowsInRange(
        categoryRows,
        rankYearStart,
        DateTime(rankYearStart.year + 1),
      ),
    };
    final vendorRankRows =
        <SpendeeBalanceRankDimension, List<_BalanceDetailRow>>{
          SpendeeBalanceRankDimension.all: vendorRows,
          SpendeeBalanceRankDimension.month: _rowsInRange(
            vendorRows,
            rankMonthStart,
            DateTime(rankMonthStart.year, rankMonthStart.month + 1),
          ),
          SpendeeBalanceRankDimension.year: _rowsInRange(
            vendorRows,
            rankYearStart,
            DateTime(rankYearStart.year + 1),
          ),
        };
    final anchor = detailAnchorDay;
    return _BalanceDetailAggregates(
      categoryRanks: <SpendeeBalanceRankDimension, List<BalanceRankRow>>{
        for (final entry in rankRows.entries)
          entry.key: _rankCategories(entry.value),
      },
      vendorRanks: <SpendeeBalanceRankDimension, List<BalanceRankRow>>{
        for (final entry in vendorRankRows.entries)
          entry.key: _rankVendors(entry.value),
      },
      averages: <SpendeeBalanceAverageDimension, BalanceAverageFrame>{
        for (final dimension in SpendeeBalanceAverageDimension.values)
          dimension: anchor == null
              ? _emptyAverageFrame()
              : _averageForRows(
                  averageRows,
                  start: _averageStartFor(dimension, anchor),
                  endExclusive: anchor.add(const Duration(days: 1)),
                ),
      },
    );
  }

  List<_BalanceDetailRow> _detailRowsFor(BalanceGhostSection section) {
    return _detailRowsBySection.putIfAbsent(section, () {
      if (!ghostPolicy.includes(section) || scopedGhostDetailRows.isEmpty) {
        return canonicalDetailRows;
      }
      return List<_BalanceDetailRow>.unmodifiable([
        ...canonicalDetailRows,
        ...scopedGhostDetailRows,
      ]);
    });
  }

  List<_BalanceDetailRow> _detailRowsFromRecords(
    Iterable<TransactionRecord> records,
  ) => List<_BalanceDetailRow>.unmodifiable([
    for (final record in records)
      if (_parseDate(record.normalizedDate) case final date?)
        _BalanceDetailRow.record(record, date),
  ]);

  List<_BalanceDetailRow> _detailRowsFromGhosts(
    Iterable<RecurringGhostRecord> ghosts,
  ) => List<_BalanceDetailRow>.unmodifiable([
    for (final ghost in ghosts)
      if (_parseDate(ghost.normalizedDate) case final date?)
        _BalanceDetailRow.ghost(ghost, date),
  ]);

  List<_BalanceDetailRow> _rowsInRange(
    Iterable<_BalanceDetailRow> rows,
    DateTime start,
    DateTime endExclusive,
  ) => List<_BalanceDetailRow>.unmodifiable(
    rows.where((row) => _isInRange(row.date, start, endExclusive)),
  );

  DateTime _averageStartFor(
    SpendeeBalanceAverageDimension dimension,
    DateTime anchor,
  ) => switch (dimension) {
    SpendeeBalanceAverageDimension.day => anchor,
    SpendeeBalanceAverageDimension.week => anchor.subtract(
      Duration(days: anchor.weekday - DateTime.monday),
    ),
    SpendeeBalanceAverageDimension.month => DateTime(anchor.year, anchor.month),
    SpendeeBalanceAverageDimension.year => DateTime(anchor.year),
  };

  List<BalanceRankRow> _rankCategories(Iterable<_BalanceDetailRow> records) {
    final categoriesById = <int, TransactionCategory>{
      for (final category in input.categories)
        category.transactionCategoryID: category,
    };
    final groups = <String, List<_BalanceDetailRow>>{};
    for (final record in records) {
      final id = record.categoryId?.toString() ?? 'uncategorized';
      (groups[id] ??= <_BalanceDetailRow>[]).add(record);
    }
    return _rankRows(
      groups,
      nameFor: (id, _) => id == 'uncategorized'
          ? 'Nincs kategória'
          : categoriesById[int.parse(id)]?.name ?? 'Nincs kategória',
      categoryFor: (id, _) =>
          id == 'uncategorized' ? null : categoriesById[int.parse(id)],
    );
  }

  List<BalanceRankRow> _rankVendors(Iterable<_BalanceDetailRow> records) {
    final groups = <String, List<_BalanceDetailRow>>{};
    for (final record in records) {
      final name = record.merchant.trim();
      final id = name.isEmpty ? 'unknown-vendor' : name;
      (groups[id] ??= <_BalanceDetailRow>[]).add(record);
    }
    return _rankRows(
      groups,
      nameFor: (id, _) => id == 'unknown-vendor' ? 'Ismeretlen' : id,
      categoryFor: (_, rows) => _dominantCategory(rows),
    );
  }

  List<BalanceRankRow> _rankRows(
    Map<String, List<_BalanceDetailRow>> groups, {
    required String Function(String id, List<_BalanceDetailRow> rows) nameFor,
    required TransactionCategory? Function(
      String id,
      List<_BalanceDetailRow> rows,
    )
    categoryFor,
  }) {
    final rows =
        <_BalanceRankAggregate>[
          for (final entry in groups.entries)
            _BalanceRankAggregate(
              id: entry.key,
              name: nameFor(entry.key, entry.value),
              amount: entry.value.fold<double>(
                0,
                (sum, record) => sum + record.amount.abs(),
              ),
              transactionCount: entry.value.length,
              category: categoryFor(entry.key, entry.value),
            ),
        ]..sort((left, right) {
          final amount = right.amount.compareTo(left.amount);
          if (amount != 0) return amount;
          final name = left.name.compareTo(right.name);
          if (name != 0) return name;
          return left.id.compareTo(right.id);
        });
    return List<BalanceRankRow>.unmodifiable([
      for (var index = 0; index < rows.length && index < 4; index += 1)
        BalanceRankRow(
          rank: index + 1,
          id: rows[index].id,
          name: rows[index].name,
          amount: rows[index].amount,
          transactionCount: rows[index].transactionCount,
          category: rows[index].category,
        ),
    ]);
  }

  TransactionCategory? _dominantCategory(List<_BalanceDetailRow> records) {
    final categoriesById = <int, TransactionCategory>{
      for (final category in input.categories)
        category.transactionCategoryID: category,
    };
    final amounts = <int?, double>{};
    for (final record in records) {
      amounts.update(
        record.categoryId,
        (amount) => amount + record.amount.abs(),
        ifAbsent: () => record.amount.abs(),
      );
    }
    final entries = amounts.entries.toList()
      ..sort((left, right) {
        final amount = right.value.compareTo(left.value);
        if (amount != 0) return amount;
        final leftName = categoriesById[left.key]?.name ?? 'Nincs kategória';
        final rightName = categoriesById[right.key]?.name ?? 'Nincs kategória';
        final name = leftName.compareTo(rightName);
        if (name != 0) return name;
        return (left.key ?? -1).compareTo(right.key ?? -1);
      });
    return entries.isEmpty ? null : categoriesById[entries.first.key];
  }

  BalanceAverageFrame _emptyAverageFrame() => _averageForRows(
    const <_BalanceDetailRow>[],
    start: now,
    endExclusive: now,
  );

  BalanceAverageFrame _averageForRows(
    Iterable<_BalanceDetailRow> rows, {
    required DateTime start,
    required DateTime endExclusive,
  }) {
    final byDate = <DateTime, double>{};
    for (final row in rows) {
      final day = _dateOnly(row.date);
      if (!_isInRange(day, start, endExclusive)) continue;
      byDate.update(
        day,
        (amount) => amount + row.amount.abs(),
        ifAbsent: () => row.amount.abs(),
      );
    }
    final observedDays = math.max(0, endExclusive.difference(start).inDays);
    final values = <double>[
      for (var offset = 0; offset < observedDays; offset += 1)
        byDate[start.add(Duration(days: offset))] ?? 0,
    ];
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final average = observedDays == 0 ? 0.0 : total / observedDays;
    final split = (observedDays / 2).ceil();
    final first = values.take(split).toList();
    final second = values.skip(split).toList();
    final firstAverage = first.isEmpty
        ? 0.0
        : first.fold<double>(0, (sum, value) => sum + value) / first.length;
    final secondAverage = second.isEmpty
        ? firstAverage
        : second.fold<double>(0, (sum, value) => sum + value) / second.length;
    final threshold = average * 1.5;
    final activeNet = rows
        .where((row) => _isInRange(row.date, start, endExclusive))
        .fold<double>(0, (sum, row) => sum + row.amount);
    return BalanceAverageFrame(
      total: total,
      observedDays: observedDays,
      dailyAverage: average,
      trend: secondAverage - firstAverage,
      bufferDays: average <= 0 || activeNet <= 0
          ? null
          : (activeNet / average).floor(),
      maximum: values.fold<double>(0, math.max),
      outlierThreshold: threshold,
      outlierCount: values.where((value) => value > threshold).length,
      dailyValues: values,
    );
  }

  Map<SpendeeBalanceNoSpendDimension, BalanceNoSpendFrame>
  _buildNoSpendFrames() {
    final anchor = detailAnchorDay;
    if (anchor == null) {
      return Map<
        SpendeeBalanceNoSpendDimension,
        BalanceNoSpendFrame
      >.unmodifiable(<SpendeeBalanceNoSpendDimension, BalanceNoSpendFrame>{
        for (final dimension in SpendeeBalanceNoSpendDimension.values)
          dimension: const BalanceNoSpendFrame(observedDays: 0, noSpendDays: 0),
      });
    }
    final nowDay = _dateOnly(anchor);
    final spendDays = <DateTime>{};
    DateTime? firstSpendDay;
    for (final row in _detailRowsFor(BalanceGhostSection.noSpend)) {
      final day = _dateOnly(row.date);
      if (day.isAfter(nowDay)) continue;
      spendDays.add(day);
      if (firstSpendDay == null || day.isBefore(firstSpendDay)) {
        firstSpendDay = day;
      }
    }

    BalanceNoSpendFrame frameFor(DateTime? start) {
      if (start == null || start.isAfter(nowDay)) {
        return const BalanceNoSpendFrame(observedDays: 0, noSpendDays: 0);
      }
      final observedDays = nowDay.difference(start).inDays + 1;
      final daysWithSpend = spendDays
          .where((day) => !day.isBefore(start) && !day.isAfter(nowDay))
          .length;
      return BalanceNoSpendFrame(
        observedDays: observedDays,
        noSpendDays: math.max(0, observedDays - daysWithSpend),
      );
    }

    return Map<
      SpendeeBalanceNoSpendDimension,
      BalanceNoSpendFrame
    >.unmodifiable(<SpendeeBalanceNoSpendDimension, BalanceNoSpendFrame>{
      SpendeeBalanceNoSpendDimension.week: frameFor(
        nowDay.subtract(Duration(days: nowDay.weekday - DateTime.monday)),
      ),
      SpendeeBalanceNoSpendDimension.month: frameFor(
        DateTime(nowDay.year, nowDay.month),
      ),
      SpendeeBalanceNoSpendDimension.year: frameFor(DateTime(nowDay.year)),
      SpendeeBalanceNoSpendDimension.all: frameFor(firstSpendDay),
    });
  }

  Iterable<RecurringGhostRecord> _dedupePendingGhosts() sync* {
    final seen = <String>{};
    final currentMonthStart = DateTime(now.year, now.month);
    for (final ghost in input.recurringGhosts) {
      if (ghost.isActivated) continue;
      final date = _parseDate(ghost.normalizedDate);
      if (date != null && date.isBefore(currentMonthStart)) continue;
      if (_isGeneratedGhost(ghost)) continue;
      final key = '${ghost.recurringTransactionId}|${ghost.periodKey}';
      if (!seen.add(key)) continue;
      yield ghost;
    }
  }

  bool _isGeneratedGhost(RecurringGhostRecord ghost) {
    final type = ghost.type;
    final activatedId = ghost.activatedTransactionId;
    return (activatedId != null &&
            _recordIds.contains(_typedKey(type, activatedId))) ||
        _recurringInstanceIds.contains(_typedKey(type, ghost.id)) ||
        _recurringMonthKeys.contains(
          '${type.name}|${ghost.recurringTransactionId}|${ghost.yearMonthKey}',
        );
  }

  List<BalanceTimeScopeOption> _buildScopeOptions() {
    final counts = <String, int>{};
    final references = <String, DateTime>{};
    final optionWindow = input.summaryWindow == SummaryWindow.monthly
        ? SummaryWindow.monthly
        : SummaryWindow.yearly;

    void add(DateTime? date) {
      if (date == null) return;
      final reference = optionWindow == SummaryWindow.monthly
          ? DateTime(date.year, date.month)
          : DateTime(date.year);
      final key = optionWindow == SummaryWindow.monthly
          ? _monthKey(reference)
          : reference.year.toString();
      references[key] = reference;
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }

    for (final record in filteredRecords) {
      add(_parseDate(record.normalizedDate));
    }
    if (input.summaryWindow == SummaryWindow.monthly) {
      for (final ghost in filteredPendingGhosts) {
        add(_parseDate(ghost.normalizedDate));
      }
    }
    final keys = counts.keys.toList()..sort();
    return List<BalanceTimeScopeOption>.unmodifiable([
      for (final key in keys)
        BalanceTimeScopeOption(
          window: optionWindow,
          referenceDate: references[key]!,
          key: key,
          label: optionWindow == SummaryWindow.monthly
              ? '${_hungarianMonth(references[key]!.month)} ${references[key]!.year}'
              : key,
          recordCount: counts[key]!,
        ),
    ]);
  }

  BalanceTimeScopeOption? _selectNearestScope(
    List<BalanceTimeScopeOption> options,
  ) {
    if (options.isEmpty) return null;
    final requested = input.summaryReferenceDate;
    if (input.summaryWindow == SummaryWindow.monthly &&
        input.ghostProjectionInFlight) {
      final requestedKey = _monthKey(requested);
      for (final option in options) {
        if (option.key == requestedKey) return option;
      }
      return null;
    }
    final requestedOrdinal = input.summaryWindow == SummaryWindow.monthly
        ? requested.year * 12 + requested.month
        : requested.year;
    final ranked = [...options]
      ..sort((left, right) {
        int ordinal(BalanceTimeScopeOption option) =>
            input.summaryWindow == SummaryWindow.monthly
            ? option.referenceDate.year * 12 + option.referenceDate.month
            : option.referenceDate.year;
        final leftDistance = (ordinal(left) - requestedOrdinal).abs();
        final rightDistance = (ordinal(right) - requestedOrdinal).abs();
        final distanceOrder = leftDistance.compareTo(rightDistance);
        if (distanceOrder != 0) return distanceOrder;
        return ordinal(left).compareTo(ordinal(right));
      });
    return ranked.first;
  }

  Map<BalanceInsightKind, BalanceInsightFrame> _buildInsights() {
    BalanceInsightFrame adapt(
      BalanceInsightKind kind,
      BalanceMetricInsight source,
    ) {
      return BalanceInsightFrame(
        kind: kind,
        title: source.title,
        primaryText: source.primaryText,
        secondaryText: source.secondaryText,
        numericValue: source.numericValue,
        comparisonValue: source.comparisonValue,
        direction: source.direction,
        category: source.category,
        record: source.record,
        ghost: source.ghost,
        sourceMetric: source.sourceMetric,
      );
    }

    BalanceMetricInsight source(
      BalanceGhostSection section,
      BalanceMetricInsightKind kind,
    ) => _bundleFor(section).insights[kind]!;

    return <BalanceInsightKind, BalanceInsightFrame>{
      BalanceInsightKind.noSpend: adapt(
        BalanceInsightKind.noSpend,
        source(BalanceGhostSection.noSpend, BalanceMetricInsightKind.noSpend),
      ),
      BalanceInsightKind.categoryChange: adapt(
        BalanceInsightKind.categoryChange,
        source(
          BalanceGhostSection.categoryChange,
          BalanceMetricInsightKind.categoryChange,
        ),
      ),
      BalanceInsightKind.latestTransaction: adapt(
        BalanceInsightKind.latestTransaction,
        source(
          BalanceGhostSection.latestTransaction,
          BalanceMetricInsightKind.latestTransaction,
        ),
      ),
      BalanceInsightKind.trendComparison: adapt(
        BalanceInsightKind.trendComparison,
        source(
          BalanceGhostSection.trendComparison,
          BalanceMetricInsightKind.trendComparison,
        ),
      ),
      BalanceInsightKind.upcomingRecurring: adapt(
        BalanceInsightKind.upcomingRecurring,
        source(
          BalanceGhostSection.upcomingRecurring,
          BalanceMetricInsightKind.upcomingRecurring,
        ),
      ),
    };
  }

  Map<BalanceBudgetPeriod, BalanceVariableBudgetDimension>
  _buildVariableBudgets() {
    final source = _bundleFor(
      BalanceGhostSection.variableBudget,
    ).variableBudgets;
    return <BalanceBudgetPeriod, BalanceVariableBudgetDimension>{
      for (final entry in source.entries)
        _budgetPeriod(entry.key): BalanceVariableBudgetDimension(
          period: _budgetPeriod(entry.key),
          label: entry.value.label,
          spent: entry.value.spent,
          budget: entry.value.budget,
          remaining: entry.value.remaining,
          transactionCount: entry.value.transactionCount,
          progress: entry.value.progress,
          referenceAmount: entry.value.referenceAmount,
        ),
    };
  }

  Map<BalanceCategoryPeriod, BalanceCategoryRank?> _buildTopCategories() {
    final source = _bundleFor(BalanceGhostSection.topCategories).topCategories;
    return <BalanceCategoryPeriod, BalanceCategoryRank?>{
      for (final entry in source.entries)
        _categoryPeriod(entry.key): entry.value == null
            ? null
            : BalanceCategoryRank(
                period: _categoryPeriod(entry.key),
                category: entry.value!.category,
                amount: entry.value!.amount,
                transactionCount: entry.value!.transactionCount,
              ),
    };
  }

  Map<BalanceMerchantPeriod, List<BalanceMerchantRank>> _buildTopMerchants() {
    final source = _bundleFor(BalanceGhostSection.topMerchants).topMerchants;
    return <BalanceMerchantPeriod, List<BalanceMerchantRank>>{
      for (final entry in source.entries)
        _merchantPeriod(entry.key): <BalanceMerchantRank>[
          for (final row in entry.value)
            BalanceMerchantRank(
              period: _merchantPeriod(entry.key),
              rank: row.rank,
              name: row.name,
              amount: row.amount,
              transactionCount: row.transactionCount,
              category: row.category,
            ),
        ],
    };
  }

  BalanceAverageDailyFrame _buildAverageDaily() {
    final source = _bundleFor(BalanceGhostSection.averageDaily).averageDaily;
    return BalanceAverageDailyFrame(
      dailySeries: source.dailySeries,
      rollingTotal: source.rollingTotal,
      average: source.average,
      bufferDays: source.bufferDays,
      highestDay: source.highestDay,
      spikeThreshold: source.spikeThreshold,
      spikeDays: source.spikeDays,
    );
  }

  BalanceSummaryFrame _buildSummary() {
    final income =
        scopedRecords
            .where((record) => record.amount > 0)
            .fold<double>(0, (sum, record) => sum + record.amount) +
        scopedGhosts
            .where((ghost) => ghost.type == TransactionType.income)
            .fold<double>(0, (sum, ghost) => sum + ghost.amount.abs());
    final expense =
        scopedRecords
            .where((record) => record.amount < 0)
            .fold<double>(0, (sum, record) => sum + record.amount.abs()) +
        scopedGhosts
            .where((ghost) => ghost.type == TransactionType.expense)
            .fold<double>(0, (sum, ghost) => sum + ghost.amount.abs());
    final activeAmount = input.activeType == TransactionType.income
        ? income
        : expense;
    return BalanceSummaryFrame(
      window: input.summaryWindow,
      referenceDate: effectiveReferenceDate,
      label: switch (input.summaryWindow) {
        SummaryWindow.monthly =>
          '${_hungarianMonth(effectiveReferenceDate.month)} ${effectiveReferenceDate.year}',
        SummaryWindow.yearly => effectiveReferenceDate.year.toString(),
        SummaryWindow.allTime => 'Összesen',
      },
      income: income,
      expense: expense,
      activeAmount: activeAmount,
      amountText: formatBalanceSignedForint(
        input.activeType == TransactionType.income
            ? activeAmount
            : -activeAmount,
      ),
    );
  }

  bool get _hasMatchingLogSnapshot {
    final snapshotWindow = input.displayLogSummaryWindow;
    final snapshotReference = input.displayLogSummaryReferenceDate;
    if (snapshotWindow == null || snapshotReference == null) return false;
    if (snapshotWindow != input.summaryWindow) return false;
    return _sameSummaryPeriod(
      input.summaryWindow,
      snapshotReference,
      effectiveReferenceDate,
    );
  }

  List<BalanceLogGroup> _buildLogGroupsFromSnapshot() {
    final groups = <BalanceLogGroup>[];
    String? activeDate;
    var activeRows = <BalanceLogRow>[];

    void flush() {
      final date = activeDate;
      if (date == null || activeRows.isEmpty) return;
      groups.add(BalanceLogGroup(date: date, rows: activeRows));
      activeRows = <BalanceLogRow>[];
    }

    for (final entry in input.displayLogEntries) {
      if (entry.isHeader) {
        flush();
        activeDate = entry.date;
        continue;
      }
      final row = entry.record != null
          ? BalanceLogRow.record(entry.record!)
          : BalanceLogRow.ghost(entry.ghost!);
      if (activeDate == null ||
          _normalizedDate(activeDate) != _normalizedDate(row.date)) {
        flush();
        activeDate = row.date;
      }
      activeRows.add(row);
    }
    flush();
    return List<BalanceLogGroup>.unmodifiable(groups);
  }

  List<BalanceLogGroup> _buildLogGroupsFromCanonicalRows() {
    final rows = <BalanceLogRow>[
      for (final record in scopedRecords) BalanceLogRow.record(record),
      for (final ghost in scopedGhosts) BalanceLogRow.ghost(ghost),
    ]..sort(_compareLogRowsDescending);
    final groups = <BalanceLogGroup>[];
    var index = 0;
    var emitted = 0;
    final fallbackIsActive =
        input.summaryWindow != SummaryWindow.allTime &&
        !_sameSummaryPeriod(
          input.summaryWindow,
          input.summaryReferenceDate,
          effectiveReferenceDate,
        );
    final limit = fallbackIsActive
        ? TransactionStore.visibleDisplayLogPageSize
        : input.visibleLogEntryLimit;
    while (index < rows.length && (limit == null || emitted < limit)) {
      final normalizedDate = _normalizedDate(rows[index].date);
      final groupRows = <BalanceLogRow>[];
      final displayDate = rows[index].date;
      do {
        groupRows.add(rows[index]);
        index += 1;
        emitted += 1;
      } while ((limit == null || emitted < limit) &&
          index < rows.length &&
          _normalizedDate(rows[index].date) == normalizedDate);
      groups.add(BalanceLogGroup(date: displayDate, rows: groupRows));
    }
    return List<BalanceLogGroup>.unmodifiable(groups);
  }

  int _allLogGroupCount(
    List<TransactionRecord> records,
    List<RecurringGhostRecord> ghosts,
  ) {
    return <String>{
      for (final record in records) _normalizedDate(record.date),
      for (final ghost in ghosts) _normalizedDate(ghost.date),
    }.length;
  }
}

class _BalanceDetailScopes {
  _BalanceDetailScopes({required this.months, required this.years});

  final List<String> months;
  final List<int> years;
}

class _BalanceDetailAggregates {
  _BalanceDetailAggregates({
    required this.categoryRanks,
    required this.vendorRanks,
    required this.averages,
  });

  final Map<SpendeeBalanceRankDimension, List<BalanceRankRow>> categoryRanks;
  final Map<SpendeeBalanceRankDimension, List<BalanceRankRow>> vendorRanks;
  final Map<SpendeeBalanceAverageDimension, BalanceAverageFrame> averages;
}

/// One immutable, query-filtered row shared by detail cards.
///
/// Recurring ghosts are materialized only when the card's own ghost policy
/// permits them, so each toggle changes data as well as its presentation.
class _BalanceDetailRow {
  const _BalanceDetailRow({
    required this.date,
    required this.amount,
    required this.merchant,
    required this.categoryId,
  });

  factory _BalanceDetailRow.record(TransactionRecord record, DateTime date) =>
      _BalanceDetailRow(
        date: _dateOnly(date),
        amount: record.amount,
        merchant: record.displayMerchant,
        categoryId: record.transactionCategoryID,
      );

  factory _BalanceDetailRow.ghost(RecurringGhostRecord ghost, DateTime date) =>
      _BalanceDetailRow(
        date: _dateOnly(date),
        amount: ghost.type == TransactionType.income
            ? ghost.amount.abs()
            : -ghost.amount.abs(),
        merchant: ghost.name,
        categoryId: ghost.categoryId,
      );

  final DateTime date;
  final double amount;
  final String merchant;
  final int? categoryId;
}

class _BalanceRankAggregate {
  const _BalanceRankAggregate({
    required this.id,
    required this.name,
    required this.amount,
    required this.transactionCount,
    required this.category,
  });

  final String id;
  final String name;
  final double amount;
  final int transactionCount;
  final TransactionCategory? category;
}

BalanceBudgetPeriod _budgetPeriod(BalanceMetricBudgetPeriod value) =>
    switch (value) {
      BalanceMetricBudgetPeriod.day => BalanceBudgetPeriod.day,
      BalanceMetricBudgetPeriod.week => BalanceBudgetPeriod.week,
      BalanceMetricBudgetPeriod.month => BalanceBudgetPeriod.month,
    };

BalanceCategoryPeriod _categoryPeriod(BalanceMetricCategoryPeriod value) =>
    switch (value) {
      BalanceMetricCategoryPeriod.day => BalanceCategoryPeriod.day,
      BalanceMetricCategoryPeriod.week => BalanceCategoryPeriod.week,
      BalanceMetricCategoryPeriod.month => BalanceCategoryPeriod.month,
      BalanceMetricCategoryPeriod.year => BalanceCategoryPeriod.year,
    };

BalanceMerchantPeriod _merchantPeriod(BalanceMetricMerchantPeriod value) =>
    switch (value) {
      BalanceMetricMerchantPeriod.year => BalanceMerchantPeriod.year,
      BalanceMetricMerchantPeriod.month => BalanceMerchantPeriod.month,
      BalanceMetricMerchantPeriod.allTime => BalanceMerchantPeriod.allTime,
    };

bool _inSummaryWindow(
  DateTime? date,
  SummaryWindow window,
  DateTime reference,
) {
  if (date == null) return false;
  return switch (window) {
    SummaryWindow.monthly =>
      date.year == reference.year && date.month == reference.month,
    SummaryWindow.yearly => date.year == reference.year,
    SummaryWindow.allTime => true,
  };
}

/// Last observable day of the active rail scope.
///
/// The HTML source computes detail cards against the selected time scope: a
/// past month/year is complete, while the current scope stops at today's day.
/// A future-only rail position intentionally has no observable calendar.
DateTime? _detailAnchorFor({
  required SummaryWindow window,
  required DateTime referenceDate,
  required DateTime now,
}) {
  final today = _dateOnly(now);
  if (window == SummaryWindow.allTime) return today;
  final start = switch (window) {
    SummaryWindow.monthly => DateTime(referenceDate.year, referenceDate.month),
    SummaryWindow.yearly => DateTime(referenceDate.year),
    SummaryWindow.allTime => today,
  };
  if (start.isAfter(today)) return null;
  final endExclusive = switch (window) {
    SummaryWindow.monthly => DateTime(
      referenceDate.year,
      referenceDate.month + 1,
    ),
    SummaryWindow.yearly => DateTime(referenceDate.year + 1),
    SummaryWindow.allTime => today.add(const Duration(days: 1)),
  };
  final scopeLastDay = endExclusive.subtract(const Duration(days: 1));
  return scopeLastDay.isAfter(today) ? today : scopeLastDay;
}

bool _isInRange(DateTime date, DateTime start, DateTime end) =>
    !date.isBefore(start) && date.isBefore(end);

bool _sameSummaryPeriod(SummaryWindow window, DateTime left, DateTime right) {
  return switch (window) {
    SummaryWindow.monthly =>
      left.year == right.year && left.month == right.month,
    SummaryWindow.yearly => left.year == right.year,
    SummaryWindow.allTime => true,
  };
}

String _typedKey(TransactionType type, int id) => '${type.name}|$id';

int _compareLogRowsDescending(BalanceLogRow left, BalanceLogRow right) {
  final date = _normalizedDate(
    right.date,
  ).compareTo(_normalizedDate(left.date));
  if (date != 0) return date;
  final time = right.time.compareTo(left.time);
  if (time != 0) return time;
  return right.sortId.compareTo(left.sortId);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime? _parseDate(String raw) {
  final parts = _normalizedDate(raw).split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

String _normalizedDate(String raw) => raw.trim().replaceAll('.', '-');

String _monthKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';

String _hungarianMonth(int month) {
  const months = <int, String>{
    1: 'Január',
    2: 'Február',
    3: 'Március',
    4: 'Április',
    5: 'Május',
    6: 'Június',
    7: 'Július',
    8: 'Augusztus',
    9: 'Szeptember',
    10: 'Október',
    11: 'November',
    12: 'December',
  };
  return months[month] ?? month.toString();
}
