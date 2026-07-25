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
      fastInfoMetrics: store.fastInfoMetrics,
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
    return now == other.now &&
        activeType == other.activeType &&
        summaryWindow == other.summaryWindow &&
        summaryReferenceDate == other.summaryReferenceDate &&
        searchQuery == other.searchQuery &&
        _sameSet(merchantFilters, other.merchantFilters) &&
        _sameSet(categoryIds, other.categoryIds) &&
        identical(transactions, other.transactions) &&
        identical(recurringGhosts, other.recurringGhosts) &&
        identical(categories, other.categories) &&
        identical(limits, other.limits) &&
        identical(fastInfoMetrics, other.fastInfoMetrics) &&
        identical(displayLogEntries, other.displayLogEntries) &&
        displayLogSummaryWindow == other.displayLogSummaryWindow &&
        displayLogSummaryReferenceDate ==
            other.displayLogSummaryReferenceDate &&
        visibleLogEntryLimit == other.visibleLogEntryLimit &&
        totalLogEntryCount == other.totalLogEntryCount &&
        hasMoreLogEntries == other.hasMoreLogEntries &&
        ghostProjectionInFlight == other.ghostProjectionInFlight;
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
       logGroups = List<BalanceLogGroup>.unmodifiable(logGroups);

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
}

class BalanceFrameResolver {
  const BalanceFrameResolver._();

  static BalanceRenderFrame resolve(
    BalanceFrameInput input, {
    BalanceGhostPolicy? ghostPolicy,
  }) {
    return _BalanceFrameScope(
      input,
      ghostPolicy ?? BalanceGhostPolicy.all,
    ).resolve();
  }
}

class _BalanceFrameScope {
  _BalanceFrameScope(this.input, this.ghostPolicy)
    : now = _dateOnly(input.now) {
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
    final snapshot = FastInfoMetricSnapshot(
      now: input.now,
      balance: input.transactions.fold<double>(
        0,
        (sum, record) => sum + record.amount,
      ),
      transactions: input.transactions,
      categories: input.categories,
      limits: input.limits,
    );
    canonicalBalanceMetrics = BalanceMetricsResolver.resolve(snapshot);
    ghostBalanceMetrics = BalanceMetricsResolver.resolve(
      snapshot,
      includedGhosts: pendingGhosts,
    );
  }

  final BalanceFrameInput input;
  final BalanceGhostPolicy ghostPolicy;
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
  late final BalanceMetricBundle canonicalBalanceMetrics;
  late final BalanceMetricBundle ghostBalanceMetrics;

  BalanceRenderFrame resolve() {
    final globalIncome = input.transactions
        .where((record) => record.amount > 0)
        .fold<double>(0, (sum, record) => sum + record.amount);
    final globalExpense = input.transactions
        .where((record) => record.amount < 0)
        .fold<double>(0, (sum, record) => sum + record.amount.abs());
    final balance = globalIncome - globalExpense;
    final globalFlow = globalIncome + globalExpense;
    final currentMonthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    final currentMonthRows = input.transactions.where((record) {
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
    final insights = _buildInsights();
    final averageDaily = _buildAverageDaily();
    final fastInfoMetrics = <String, FastInfoMetricResult>{
      ...canonicalBalanceMetrics.fastInfoMetrics,
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
      reserveRatio: globalIncome <= 0
          ? 0
          : (math.max(0.0, balance) / globalIncome).clamp(0.0, 1.0),
      incomeRatio: currentFlow <= 0
          ? (globalFlow <= 0 ? 0 : globalIncome / globalFlow)
          : currentIncome / currentFlow,
      expenseRatio: currentFlow <= 0
          ? (globalFlow <= 0 ? 0 : globalExpense / globalFlow)
          : currentExpense / currentFlow,
      insights: insights,
      variableBudgets: _buildVariableBudgets(),
      topCategories: _buildTopCategories(),
      topMerchants: _buildTopMerchants(),
      fastInfoMetrics: fastInfoMetrics,
      averageDaily: averageDaily,
      summary: _buildSummary(),
      logGroups: logGroups,
      visibleLogRowCount: visibleLogRowCount,
      totalLogEntryCount: totalLogEntryCount,
      hasMoreLogEntries: hasMore,
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
      ? ghostBalanceMetrics
      : canonicalBalanceMetrics;

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
