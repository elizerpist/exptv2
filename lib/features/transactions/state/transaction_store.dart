import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/debug/debug_console.dart';
import '../data/limit_manager.dart';
import '../data/transaction_filter.dart';
import '../data/transaction_repository.dart';
import '../models/backheader_budget_item.dart';
import '../models/budget_goal_kind.dart';
import '../models/category_budget_bar_data.dart';
import '../models/overview_budget_data.dart';
import '../models/category_limit.dart';
import '../models/fast_info_metric_snapshot.dart';
import '../models/recurring_ghost_record.dart';
import '../models/recurring_rule.dart';
import '../models/summary_window.dart';
import '../models/transaction_log_entry.dart';
import '../models/transaction_log_projection.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../models/transaction_summary.dart';
import 'fast_info_metrics_resolver.dart';

class VendorFilterSummary {
  const VendorFilterSummary({
    required this.name,
    required this.originalName,
    required this.total,
    required this.count,
    this.colorHex,
    this.categoryIconSlot,
    this.hasCustomName = false,
  });

  final String name;
  final String originalName;
  final double total;
  final int count;
  final String? colorHex;
  final int? categoryIconSlot;
  final bool hasCustomName;
}

class StatsViewMutation {
  const StatsViewMutation({
    required this.merchantFilters,
    required this.summaryWindow,
    required this.referenceDate,
  });

  final Set<String>? merchantFilters;
  final SummaryWindow? summaryWindow;
  final DateTime? referenceDate;
}

class _VendorCategoryRollup {
  const _VendorCategoryRollup({
    required this.category,
    required this.total,
    required this.count,
  });

  final TransactionCategory category;
  final double total;
  final int count;

  _VendorCategoryRollup add(double amount) {
    return _VendorCategoryRollup(
      category: category,
      total: total + amount,
      count: count + 1,
    );
  }
}

class TransactionStore extends ChangeNotifier {
  static const int visibleDisplayLogPageSize = 96;

  @visibleForTesting
  static const int maxFilterCacheEntries = 12;

  TransactionStore(
    this._repository, {
    DateTime Function()? clock,
    Future<void> Function()? onNotificationsMayHaveChanged,
  }) : _clock = clock ?? DateTime.now,
       _onNotificationsMayHaveChanged = onNotificationsMayHaveChanged {
    final now = _clock();
    _periodReferenceDate = _monthStart(now);
    _publishedDateBoundaryKey = _calendarDayKey(now);
  }

  final TransactionRepositoryContract _repository;
  final DateTime Function() _clock;
  final Future<void> Function()? _onNotificationsMayHaveChanged;
  var _filter = const TransactionFilter();
  var _summaryWindow = SummaryWindow.allTime;
  var _summaryChangeGeneration = 0;
  var _dateBoundaryProjectionGeneration = 0;
  late DateTime _periodReferenceDate;
  late String _publishedDateBoundaryKey;
  var _loading = false;
  var _startCompleted = false;
  Future<void>? _startFuture;
  var _uiUpdateSuspendDepth = 0;
  var _pendingUiNotify = false;
  final _pendingPrewarmReasons = <String>[];
  String? _error;
  List<TransactionCategory> _categories = [];
  List<TransactionRecord> _transactions = [];
  List<RecurringGhostRecord> _recurringGhostTransactions = [];
  List<RecurringGhostRecord> _stableRecurringGhostTransactions = const [];
  final Map<String, List<RecurringGhostRecord>>
  _balanceRecurringGhostsByPeriod = {};
  String? _stableGhostPeriodKey;
  var _ghostProjectionInFlight = false;
  List<RecurringRule> _recurringRules = const [];
  List<CategoryLimit> _limits = [];
  List<TransactionCategory> _categoriesView = const [];
  List<TransactionRecord> _transactionsView = const [];
  List<RecurringGhostRecord> _recurringGhostTransactionsView = const [];
  List<RecurringGhostRecord> _balanceRecurringGhostTransactionsView = const [];
  List<CategoryLimit> _limitsView = const [];
  Map<int, TransactionCategory> _categoriesById = const {};
  Set<String> _transactionIdsByType = const {};
  Set<String> _recurringInstanceIdsByType = const {};
  Set<String> _recurringMonthKeysByType = const {};
  final _categoryTransactionCountsCache = <String, Map<int, int>>{};
  final _activeCategoriesCache = <TransactionType, List<TransactionCategory>>{};
  final _windowedTransactionsCache = <String, List<TransactionRecord>>{};
  final _visibleTransactionsCache = <String, List<TransactionRecord>>{};
  final _visibleGhostTransactionsCache = <String, List<RecurringGhostRecord>>{};
  final _balanceVisibleGhostTransactionsCache =
      <String, List<RecurringGhostRecord>>{};
  final _visibleLogEntriesCache = <String, List<TransactionLogEntry>>{};
  final _visibleDisplayLogEntriesCache = <String, List<TransactionLogEntry>>{};
  final _balanceVisibleDisplayLogEntriesCache =
      <String, List<TransactionLogEntry>>{};
  final _balanceVisibleDisplayLogEntryKeysByFilter = <String, Set<String>>{};
  final _visibleDisplayLogEntryTotalCountCache = <String, int>{};
  final _balanceVisibleDisplayLogEntryTotalCountCache = <String, int>{};
  final _activeSummaryCache = <String, TransactionSummary>{};
  final _periodTotalsCache = <String, double>{};
  final _categoryBudgetBarsCache = <String, List<CategoryBudgetBarData>>{};
  final _overviewBudgetItemsCache = <String, List<OverviewBudgetData>>{};
  final _backheaderBudgetItemsCache = <String, List<BackheaderBudgetItem>>{};
  TransactionSummary? _totalSummaryCache;
  Map<String, FastInfoMetricResult>? _fastInfoMetricsCache;
  String? _fastInfoMetricsDateKey;
  double? _totalIncomeCache;
  double? _totalExpenseCache;
  var _balanceVisibleDisplayLogLimit = visibleDisplayLogPageSize;
  final _filterCacheLru = <String>[];

  @visibleForTesting
  int get filterCacheEntryCount => <String>{
    ..._filterCacheLru,
    ..._visibleTransactionsCache.keys,
    ..._visibleGhostTransactionsCache.keys,
    ..._balanceVisibleGhostTransactionsCache.keys,
    ..._visibleLogEntriesCache.keys,
    ..._visibleDisplayLogEntriesCache.keys,
    ..._balanceVisibleDisplayLogEntryKeysByFilter.keys,
    ..._visibleDisplayLogEntryTotalCountCache.keys,
    ..._balanceVisibleDisplayLogEntryTotalCountCache.keys,
    ..._activeSummaryCache.keys,
  }.length;

  bool get loading => _loading;
  String? get error => _error;
  TransactionType get activeType => _filter.type;
  SummaryWindow get summaryWindow => _summaryWindow;
  DateTime get summaryReferenceDate => _periodReferenceDate;
  DateTime get currentDate => _clock();

  bool refreshForDateBoundary() {
    final now = _clock();
    final nextKey = _calendarDayKey(now);
    if (nextKey == _publishedDateBoundaryKey) return false;
    final previousKey = _publishedDateBoundaryKey;
    final previousMonthKey = previousKey.substring(0, 7);
    final nextMonthKey = nextKey.substring(0, 7);
    final monthChanged = previousMonthKey != nextMonthKey;
    final previousYear = int.parse(previousKey.substring(0, 4));
    final yearChanged = previousYear != now.year;
    final followsCurrentMonth =
        _summaryWindow == SummaryWindow.monthly &&
        _activeMonthlyPeriodKey == previousMonthKey;
    final followsCurrentYear =
        _summaryWindow == SummaryWindow.yearly &&
        _periodReferenceDate.year == previousYear;
    _publishedDateBoundaryKey = nextKey;
    int? activeProjectionGeneration;
    if (monthChanged && followsCurrentMonth) {
      _periodReferenceDate = _monthStart(now);
      _prepareGhostProjectionForActiveWindow();
      activeProjectionGeneration = ++_summaryChangeGeneration;
    } else if (yearChanged && followsCurrentYear) {
      _periodReferenceDate = DateTime(now.year);
      _summaryChangeGeneration += 1;
    }
    _invalidateViewCaches();
    _invalidateFastInfoMetrics();
    _prewarmCriticalCaches('date-boundary');
    notifyListeners();
    if (monthChanged) {
      final projection = activeProjectionGeneration == null
          ? _projectRecurringGhostsForBalancePeriod(
              targetDate: _monthStart(now),
              generation: ++_dateBoundaryProjectionGeneration,
            )
          : _projectRecurringGhostsForActiveWindow(
              generation: activeProjectionGeneration,
            );
      unawaited(
        projection.catchError((Object error, StackTrace stackTrace) {
          DebugConsole.log(
            '[Recurring] date-boundary projection failed: $error',
          );
        }),
      );
    }
    DebugConsole.log('[Balance] date boundary refreshed day=$nextKey');
    return true;
  }

  String get searchQuery => _filter.searchQuery;
  String? get merchantFilter => _filter.merchant;
  String? get merchantFilterColorHex => _filter.merchantColorHex;
  Set<String> get activeMerchantFilters =>
      Set.unmodifiable(_filter.effectiveMerchants);
  Set<int> get activeCategoryIds =>
      Set.unmodifiable(_filter.effectiveCategoryIds);

  TransactionCategory? get activeCategory {
    final ids = _filter.effectiveCategoryIds;
    if (ids.length != 1) return null;
    final id = ids.first;
    return _categoriesById[id];
  }

  String? get activeCategoryFilterLabel {
    final ids = _filter.effectiveCategoryIds;
    if (ids.isEmpty) return null;
    if (ids.length == 1) return activeCategory?.name;
    return '${ids.length} kategória';
  }

  Map<int, int> get categoryTransactionCounts =>
      _categoryTransactionCountsFor(_filter.type);
  Map<int, TransactionCategory> get categoriesById => _categoriesById;
  List<VendorFilterSummary> get vendorFilterSummaries =>
      _vendorFilterSummariesFor(_filter.type);

  List<VendorFilterSummary> vendorFilterSummariesFor(TransactionType type) =>
      _vendorFilterSummariesFor(type);

  List<TransactionCategory> get categories => _categoriesView;
  List<TransactionRecord> get transactions => _transactionsView;
  List<RecurringGhostRecord> get recurringGhostTransactions =>
      _recurringGhostTransactionsView;

  List<RecurringGhostRecord> get budgetV2PeriodGhosts {
    final periodKey = _activeGhostPeriodKey;
    if (periodKey == null) return const <RecurringGhostRecord>[];
    final seenGhostKeys = <String>{};
    return List<RecurringGhostRecord>.unmodifiable(
      _activeGhostSource.where((ghost) {
        if (ghost.isActivated) return false;
        if (_hasGeneratedTransactionForGhost(ghost)) return false;
        final ghostKey = '${ghost.recurringTransactionId}|${ghost.periodKey}';
        if (!seenGhostKeys.add(ghostKey)) return false;
        if (_ghostIsBeforeCurrentMonth(ghost)) return false;
        if (ghost.type != _filter.type) return false;
        return _ghostInActiveWindow(ghost, periodKey: periodKey);
      }),
    );
  }

  List<RecurringGhostRecord> get balanceRecurringGhostTransactions {
    // Balance cards own independent day/week/month/year/all-time dimensions.
    // The frame resolver applies the lower summary/log scope separately.
    return _balanceRecurringGhostTransactionsView;
  }

  bool get recurringGhostProjectionInFlight => _ghostProjectionInFlight;

  List<CategoryLimit> get limits => _limitsView;
  List<RecurringRule> get recurringRules => List.unmodifiable(_recurringRules);

  Map<String, FastInfoMetricResult> get fastInfoMetrics {
    final now = _clock();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final cached = _fastInfoMetricsCache;
    if (cached != null && _fastInfoMetricsDateKey == dateKey) return cached;
    final stopwatch = Stopwatch()..start();
    final periodKey = LimitManager.periodKeyFor(SummaryWindow.monthly, now);
    final savingLimit = LimitManager.findLimit(
      limits: _limits,
      targetType: LimitTargetType.overview,
      targetId: 0,
      transactionType: BudgetGoalKind.savingGoal.transactionType,
      window: LimitWindow.monthly,
      periodKey: periodKey,
    );
    final metrics = FastInfoMetricsResolver.resolve(
      FastInfoMetricSnapshot(
        transactions: _transactions,
        categories: _categories,
        limits: _limits,
        recurringGhosts: _recurringGhostTransactions,
        now: now,
        balance: _totalSummary.balance,
        savingGoal: savingLimit?.hasLimit == true
            ? savingLimit!.limitAmount
            : null,
      ),
    );
    _fastInfoMetricsCache = metrics;
    _fastInfoMetricsDateKey = dateKey;
    final elapsed = stopwatch.elapsedMilliseconds;
    DebugConsole.log(
      '[Perf] FastInfo metrics build transactions=${_transactions.length} '
      'categories=${_categories.length} limits=${_limits.length} '
      'cards=${metrics.length} elapsed=${elapsed}ms',
    );
    return metrics;
  }

  List<TransactionCategory> get activeCategories =>
      _activeCategoriesFor(_filter.type);

  List<CategoryBudgetBarData> get categoryBudgetBars =>
      _categoryBudgetBarsFor(_filter.type);

  List<OverviewBudgetData> get overviewBudgetItems =>
      _overviewBudgetItemsFor(_filter.type);

  List<BackheaderBudgetItem> get backheaderBudgetItems =>
      _backheaderBudgetItemsFor(_filter.type);

  double get activePeriodIncomeTotal => _periodTotal(TransactionType.income);

  double get activePeriodExpenseTotal => _periodTotal(TransactionType.expense);

  double get totalIncomeAmount {
    final cached = _totalIncomeCache;
    if (cached != null) return cached;
    final value = _transactions
        .where((record) => record.amount > 0)
        .fold<double>(0, (sum, record) => sum + record.amount.abs());
    _totalIncomeCache = value;
    return value;
  }

  double get totalExpenseAmount {
    final cached = _totalExpenseCache;
    if (cached != null) return cached;
    final value = _transactions
        .where((record) => record.amount < 0)
        .fold<double>(0, (sum, record) => sum + record.amount.abs());
    _totalExpenseCache = value;
    return value;
  }

  List<TransactionRecord> get windowedTransactions =>
      _windowedTransactionsFor(_filter.type);

  List<TransactionRecord> get visibleTransactions =>
      _visibleTransactionsFor(_filter);

  List<RecurringGhostRecord> get visibleGhostTransactions =>
      _visibleGhostTransactionsFor(_filter);

  List<TransactionLogEntry> get visibleLogEntries =>
      _visibleLogEntriesFor(_filter);

  List<TransactionLogEntry> get visibleDisplayLogEntries =>
      _visibleDisplayLogEntriesFor(_filter);

  int get visibleDisplayLogEntryTotalCount =>
      _visibleDisplayLogEntryTotalCountFor(_filter);

  bool get hasMoreVisibleDisplayLogEntries => false;

  List<TransactionLogEntry> get balanceVisibleDisplayLogEntries =>
      _balanceVisibleDisplayLogEntriesFor(_filter);

  int get balanceVisibleDisplayLogEntryTotalCount =>
      _balanceVisibleDisplayLogEntryTotalCountFor(_filter);

  bool get hasMoreBalanceVisibleDisplayLogEntries {
    final visibleRows = balanceVisibleDisplayLogEntries
        .where((entry) => !entry.isHeader)
        .length;
    return visibleRows < _balanceVisibleLogSourceCountFor(_filter);
  }

  String get totalBalanceText => _totalSummary.formattedBalance;

  TransactionSummary get activeSummary => _activeSummaryFor(_filter);

  String get activePeriodLabel {
    final reference = _periodReferenceDate;
    return switch (_summaryWindow) {
      SummaryWindow.allTime => 'Sum',
      SummaryWindow.yearly => reference.year.toString(),
      SummaryWindow.monthly =>
        '${_hungarianMonth(reference.month)} ${reference.year}',
    };
  }

  String get activeSummaryTitle {
    final reference = _periodReferenceDate;
    final base = switch (_summaryWindow) {
      SummaryWindow.allTime => 'Sum',
      SummaryWindow.yearly => reference.year.toString(),
      SummaryWindow.monthly =>
        '${_hungarianMonth(reference.month)} ${reference.year}',
    };
    final parts = <String>[base];
    final merchants = _filter.effectiveMerchants;
    if (merchants.length == 1) {
      parts.add(merchants.first);
    } else if (merchants.length > 1) {
      parts.add('${merchants.length} vendor');
    }
    final categoryLabel = activeCategoryFilterLabel;
    if (categoryLabel != null) parts.add(categoryLabel);
    return parts.join(' · ');
  }

  String get _activePeriodKey =>
      LimitManager.periodKeyFor(_summaryWindow, _periodReferenceDate);

  String get _activeMonthlyPeriodKey => _monthPeriodKey(_periodReferenceDate);

  String _windowCacheKey(TransactionType type) =>
      '${type.name}|${_summaryWindow.name}|$_activePeriodKey';

  String _filterCacheKey(TransactionFilter filter) {
    final query = filter.searchQuery.trim().toLowerCase();
    final merchantKey = filter.effectiveMerchants.toList()..sort();
    final categoryKey = filter.effectiveCategoryIds.toList()..sort();
    final key =
        '${_windowCacheKey(filter.type)}|c=${categoryKey.join(',')}|m=${merchantKey.join(',')}|q=$query';
    _touchFilterCacheKey(key);
    return key;
  }

  List<TransactionCategory> _activeCategoriesFor(TransactionType type) {
    final cached = _activeCategoriesCache[type];
    if (cached != null) return cached;
    final rows = List<TransactionCategory>.unmodifiable(
      _categories.where((category) => category.normalizedType == type),
    );
    _activeCategoriesCache[type] = rows;
    return rows;
  }

  List<TransactionRecord> _windowedTransactionsFor(TransactionType type) {
    final key = _windowCacheKey(type);
    final cached = _windowedTransactionsCache[key];
    if (cached != null) return cached;
    final stopwatch = Stopwatch()..start();
    final rows = List<TransactionRecord>.unmodifiable(
      LimitManager.recordsForWindow(
        transactions: _transactions,
        activeType: type,
        summaryWindow: _summaryWindow,
        referenceDate: _periodReferenceDate,
      ),
    );
    _windowedTransactionsCache[key] = rows;
    _logCacheBuild('windowed-${type.name}', key, stopwatch, rows.length);
    return rows;
  }

  Map<int, int> _categoryTransactionCountsFor(TransactionType type) {
    final key = _windowCacheKey(type);
    final cached = _categoryTransactionCountsCache[key];
    if (cached != null) return cached;
    final counts = <int, int>{};
    for (final transaction in _windowedTransactionsFor(type)) {
      final categoryId = transaction.transactionCategoryID;
      if (categoryId == null) continue;
      counts.update(categoryId, (value) => value + 1, ifAbsent: () => 1);
    }
    final rows = Map<int, int>.unmodifiable(counts);
    _categoryTransactionCountsCache[key] = rows;
    return rows;
  }

  List<TransactionRecord> _visibleTransactionsFor(TransactionFilter filter) {
    final key = _filterCacheKey(filter);
    final cached = _visibleTransactionsCache[key];
    if (cached != null) return cached;
    final query = filter.searchQuery.trim().toLowerCase();
    final merchants = filter.effectiveMerchants;
    final rows = List<TransactionRecord>.unmodifiable(
      _windowedTransactionsFor(filter.type).where((record) {
        final categoryIds = filter.effectiveCategoryIds;
        if (categoryIds.isNotEmpty &&
            !categoryIds.contains(record.transactionCategoryID)) {
          return false;
        }
        if (merchants.isNotEmpty &&
            !merchants.contains(record.displayMerchant)) {
          return false;
        }
        if (query.isNotEmpty &&
            !record.displayMerchant.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }),
    );
    _visibleTransactionsCache[key] = rows;
    return rows;
  }

  List<RecurringGhostRecord> _visibleGhostTransactionsFor(
    TransactionFilter filter,
  ) {
    final key = _filterCacheKey(filter);
    final cached = _visibleGhostTransactionsCache[key];
    if (cached != null) return cached;
    final periodKey = _activeGhostPeriodKey;
    if (periodKey == null) {
      final rows = List<RecurringGhostRecord>.unmodifiable(
        const <RecurringGhostRecord>[],
      );
      _visibleGhostTransactionsCache[key] = rows;
      return rows;
    }
    final query = filter.searchQuery.trim().toLowerCase();
    final merchants = filter.effectiveMerchants;
    final seenGhostKeys = <String>{};
    final rows = List<RecurringGhostRecord>.unmodifiable(
      _activeGhostSource.where((ghost) {
        if (ghost.isActivated) return false;
        if (_hasGeneratedTransactionForGhost(ghost)) return false;
        final ghostKey = '${ghost.recurringTransactionId}|${ghost.periodKey}';
        if (!seenGhostKeys.add(ghostKey)) return false;
        if (_ghostIsBeforeCurrentMonth(ghost)) return false;
        if (ghost.type != filter.type) return false;
        if (!_ghostInActiveWindow(ghost, periodKey: periodKey)) return false;
        final categoryIds = filter.effectiveCategoryIds;
        if (categoryIds.isNotEmpty && !categoryIds.contains(ghost.categoryId)) {
          return false;
        }
        if (merchants.isNotEmpty && !merchants.contains(ghost.name)) {
          return false;
        }
        if (query.isNotEmpty && !ghost.name.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }),
    );
    _visibleGhostTransactionsCache[key] = rows;
    return rows;
  }

  List<TransactionLogEntry> _visibleLogEntriesFor(TransactionFilter filter) {
    final key = _filterCacheKey(filter);
    final cached = _visibleLogEntriesCache[key];
    if (cached != null) return cached;
    final entries = <TransactionLogEntry>[
      for (final record in _visibleTransactionsFor(filter))
        TransactionLogEntry.record(record),
      if (_summaryWindow == SummaryWindow.monthly)
        for (final ghost in _visibleGhostTransactionsFor(filter))
          TransactionLogEntry.ghost(ghost),
    ];
    final rows = projectTransactionLogEntries(
      entries,
      rowLimit: entries.length,
    ).rows;
    _visibleLogEntriesCache[key] = rows;
    return rows;
  }

  List<RecurringGhostRecord> _balanceVisibleGhostTransactionsFor(
    TransactionFilter filter,
  ) {
    final key = _filterCacheKey(filter);
    final cached = _balanceVisibleGhostTransactionsCache[key];
    if (cached != null) return cached;
    if (_summaryWindow != SummaryWindow.monthly) {
      const rows = <RecurringGhostRecord>[];
      _balanceVisibleGhostTransactionsCache[key] = rows;
      return rows;
    }
    final periodKey = _activeGhostPeriodKey!;
    final query = filter.searchQuery.trim().toLowerCase();
    final merchants = filter.effectiveMerchants;
    final seenGhostKeys = <String>{};
    final rows = List<RecurringGhostRecord>.unmodifiable(
      balanceRecurringGhostTransactions.where((ghost) {
        if (ghost.isActivated) return false;
        if (_hasGeneratedTransactionForGhost(ghost)) return false;
        final ghostKey = '${ghost.recurringTransactionId}|${ghost.periodKey}';
        if (!seenGhostKeys.add(ghostKey)) return false;
        if (_ghostIsBeforeCurrentMonth(ghost)) return false;
        if (ghost.type != filter.type) return false;
        if (!_ghostInActiveWindow(ghost, periodKey: periodKey)) return false;
        final categoryIds = filter.effectiveCategoryIds;
        if (categoryIds.isNotEmpty && !categoryIds.contains(ghost.categoryId)) {
          return false;
        }
        if (merchants.isNotEmpty && !merchants.contains(ghost.name)) {
          return false;
        }
        if (query.isNotEmpty && !ghost.name.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }),
    );
    _balanceVisibleGhostTransactionsCache[key] = rows;
    return rows;
  }

  List<TransactionLogEntry> _visibleDisplayLogEntriesFor(
    TransactionFilter filter,
  ) {
    final key = _filterCacheKey(filter);
    final cached = _visibleDisplayLogEntriesCache[key];
    if (cached != null) return cached;
    final stopwatch = Stopwatch()..start();
    final source = _visibleLogEntriesFor(filter);
    final rows = projectTransactionLogEntries(
      source,
      rowLimit: source.length,
    ).entries;
    _visibleDisplayLogEntriesCache[key] = rows;
    _logCacheBuild(
      'legacy-display-${filter.type.name}',
      key,
      stopwatch,
      rows.length,
    );
    return rows;
  }

  int _balanceVisibleLogSourceCountFor(TransactionFilter filter) {
    return _visibleTransactionsFor(filter).length +
        (_summaryWindow == SummaryWindow.monthly
            ? _balanceVisibleGhostTransactionsFor(filter).length
            : 0);
  }

  List<TransactionLogEntry> _balanceVisibleDisplayLogEntriesFor(
    TransactionFilter filter,
  ) {
    final filterKey = _filterCacheKey(filter);
    final key = '$filterKey|limit=$_balanceVisibleDisplayLogLimit';
    final cached = _balanceVisibleDisplayLogEntriesCache[key];
    if (cached != null) return cached;
    final stopwatch = Stopwatch()..start();
    final rows = projectTransactionLogEntries(
      _balanceVisibleLogSourceFor(filter),
      rowLimit: _balanceVisibleDisplayLogLimit,
    ).entries;
    _balanceVisibleDisplayLogEntriesCache[key] = rows;
    _balanceVisibleDisplayLogEntryKeysByFilter
        .putIfAbsent(filterKey, () => <String>{})
        .add(key);
    _logCacheBuild(
      'balance-display-${filter.type.name}',
      key,
      stopwatch,
      rows.length,
    );
    return rows;
  }

  int _visibleDisplayLogEntryTotalCountFor(TransactionFilter filter) {
    final key = _filterCacheKey(filter);
    final cached = _visibleDisplayLogEntryTotalCountCache[key];
    if (cached != null) return cached;
    final source = _visibleLogEntriesFor(filter);
    final total = projectTransactionLogEntries(
      source,
      rowLimit: 0,
    ).totalDisplayEntryCount;
    _visibleDisplayLogEntryTotalCountCache[key] = total;
    return total;
  }

  int _balanceVisibleDisplayLogEntryTotalCountFor(TransactionFilter filter) {
    final key = _filterCacheKey(filter);
    final cached = _balanceVisibleDisplayLogEntryTotalCountCache[key];
    if (cached != null) return cached;
    final total = projectTransactionLogEntries(
      _balanceVisibleLogSourceFor(filter),
      rowLimit: 0,
    ).totalDisplayEntryCount;
    _balanceVisibleDisplayLogEntryTotalCountCache[key] = total;
    return total;
  }

  Iterable<TransactionLogEntry> _balanceVisibleLogSourceFor(
    TransactionFilter filter,
  ) sync* {
    for (final record in _visibleTransactionsFor(filter)) {
      yield TransactionLogEntry.record(record);
    }
    if (_summaryWindow == SummaryWindow.monthly) {
      for (final ghost in _balanceVisibleGhostTransactionsFor(filter)) {
        yield TransactionLogEntry.ghost(ghost);
      }
    }
  }

  bool _hasGeneratedTransactionForGhost(RecurringGhostRecord ghost) {
    final type = ghost.type;
    final activatedId = ghost.activatedTransactionId;
    return (activatedId != null &&
            _transactionIdsByType.contains(_typedId(type, activatedId))) ||
        _recurringInstanceIdsByType.contains(_typedId(type, ghost.id)) ||
        _recurringMonthKeysByType.contains(
          '${type.name}|${ghost.recurringTransactionId}|${ghost.yearMonthKey}',
        );
  }

  List<CategoryBudgetBarData> _categoryBudgetBarsFor(TransactionType type) {
    final key = _windowCacheKey(type);
    final cached = _categoryBudgetBarsCache[key];
    if (cached != null) return cached;
    final stopwatch = Stopwatch()..start();
    final rows = List<CategoryBudgetBarData>.unmodifiable(
      LimitManager.buildBars(
        categories: _categories,
        transactions: _transactions,
        limits: _limits,
        activeType: type,
        summaryWindow: _summaryWindow,
        referenceDate: _periodReferenceDate,
        windowedTransactions: _windowedTransactionsFor(type),
      ),
    );
    _categoryBudgetBarsCache[key] = rows;
    _logCacheBuild('budget-bars-${type.name}', key, stopwatch, rows.length);
    return rows;
  }

  List<OverviewBudgetData> _overviewBudgetItemsFor(TransactionType type) {
    final key = _windowCacheKey(type);
    final cached = _overviewBudgetItemsCache[key];
    if (cached != null) return cached;
    final window = LimitManager.windowForSummary(_summaryWindow);
    final periodKey = _activePeriodKey;
    final income = _periodTotal(TransactionType.income);
    final expense = _periodTotal(TransactionType.expense);
    final kinds = type == TransactionType.expense
        ? const [BudgetGoalKind.expenseBudget]
        : const [BudgetGoalKind.incomeGoal];

    final rows = List<OverviewBudgetData>.unmodifiable(
      kinds.map((kind) {
        final sourceLimit = LimitManager.findLimit(
          limits: _limits,
          targetType: LimitTargetType.overview,
          targetId: 0,
          transactionType: kind.transactionType,
          window: window,
          periodKey: periodKey,
        );
        final amount = switch (kind) {
          BudgetGoalKind.expenseBudget => expense,
          BudgetGoalKind.incomeGoal => income,
          BudgetGoalKind.savingGoal =>
            (income - expense).clamp(0.0, double.infinity).toDouble(),
        };
        final hasLimit = sourceLimit?.hasLimit ?? false;
        final limitAmount = hasLimit ? sourceLimit!.limitAmount : 0.0;
        return OverviewBudgetData(
          kind: kind,
          window: window,
          periodKey: periodKey,
          amount: amount,
          hasLimit: hasLimit,
          limitAmount: limitAmount,
          alertActive: sourceLimit?.alertActive ?? false,
          sourceLimit: sourceLimit,
        );
      }),
    );
    _overviewBudgetItemsCache[key] = rows;
    return rows;
  }

  List<BackheaderBudgetItem> _backheaderBudgetItemsFor(TransactionType type) {
    final key = _windowCacheKey(type);
    final cached = _backheaderBudgetItemsCache[key];
    if (cached != null) return cached;
    final rows = List<BackheaderBudgetItem>.unmodifiable([
      for (final overview in _overviewBudgetItemsFor(type))
        BackheaderBudgetItem.overview(overview),
      for (final bar in _categoryBudgetBarsFor(type))
        BackheaderBudgetItem.category(bar),
    ]);
    _backheaderBudgetItemsCache[key] = rows;
    return rows;
  }

  TransactionSummary get _totalSummary {
    final cached = _totalSummaryCache;
    if (cached != null) return cached;
    final value = TransactionSummary.fromRecords(_transactions);
    _totalSummaryCache = value;
    return value;
  }

  TransactionSummary _activeSummaryFor(TransactionFilter filter) {
    final key = _filterCacheKey(filter);
    final cached = _activeSummaryCache[key];
    if (cached != null) return cached;
    final value = TransactionSummary.fromRecords(
      _visibleTransactionsFor(filter),
    );
    _activeSummaryCache[key] = value;
    return value;
  }

  double _periodTotal(TransactionType type) {
    final key = _windowCacheKey(type);
    final cached = _periodTotalsCache[key];
    if (cached != null) return cached;
    final value = _windowedTransactionsFor(
      type,
    ).fold<double>(0, (sum, record) => sum + record.amount.abs());
    _periodTotalsCache[key] = value;
    return value;
  }

  List<VendorFilterSummary> _vendorFilterSummariesFor(TransactionType type) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    final displayNames = <String, String>{};
    final customNames = <String, bool>{};
    final categoryRollups = <String, Map<int, _VendorCategoryRollup>>{};
    for (final record in _windowedTransactionsFor(type)) {
      final originalName = record.merchant.trim();
      final displayName = record.displayMerchant.trim();
      final key = originalName.isEmpty ? displayName : originalName;
      final name = displayName.isEmpty ? key : displayName;
      if (key.isEmpty || name.isEmpty) continue;
      final amount = record.amount.abs();
      totals[key] = (totals[key] ?? 0) + amount;
      counts[key] = (counts[key] ?? 0) + 1;
      final assignedName = record.userAssignedName?.trim();
      if (assignedName != null &&
          assignedName.isNotEmpty &&
          assignedName != originalName) {
        displayNames[key] = assignedName;
        customNames[key] = true;
      } else {
        displayNames.putIfAbsent(key, () => name);
        customNames.putIfAbsent(key, () => false);
      }
      final categoryId = record.transactionCategoryID;
      final category = categoryId == null ? null : _categoriesById[categoryId];
      if (category != null) {
        final vendorCategories = categoryRollups.putIfAbsent(
          key,
          () => <int, _VendorCategoryRollup>{},
        );
        vendorCategories.update(
          category.transactionCategoryID,
          (rollup) => rollup.add(amount),
          ifAbsent: () => _VendorCategoryRollup(
            category: category,
            total: amount,
            count: 1,
          ),
        );
      }
    }
    final rows =
        [
          for (final entry in totals.entries) ...[
            _vendorSummaryFor(
              key: entry.key,
              total: entry.value,
              count: counts[entry.key] ?? 0,
              displayName: displayNames[entry.key] ?? entry.key,
              hasCustomName: customNames[entry.key] ?? false,
              categoryRollups: categoryRollups[entry.key],
            ),
          ],
        ]..sort((left, right) {
          final totalOrder = right.total.compareTo(left.total);
          if (totalOrder != 0) return totalOrder;
          return left.name.compareTo(right.name);
        });
    return List<VendorFilterSummary>.unmodifiable(rows);
  }

  VendorFilterSummary _vendorSummaryFor({
    required String key,
    required double total,
    required int count,
    required String displayName,
    required bool hasCustomName,
    required Map<int, _VendorCategoryRollup>? categoryRollups,
  }) {
    final category = _dominantVendorCategory(categoryRollups);
    return VendorFilterSummary(
      name: displayName,
      originalName: key,
      total: total,
      count: count,
      colorHex: category?.slotColorHex,
      categoryIconSlot: category?.iconSlot,
      hasCustomName: hasCustomName,
    );
  }

  TransactionCategory? _dominantVendorCategory(
    Map<int, _VendorCategoryRollup>? rollups,
  ) {
    if (rollups == null || rollups.isEmpty) return null;
    final ranked = rollups.values.toList()
      ..sort((left, right) {
        final totalOrder = right.total.compareTo(left.total);
        if (totalOrder != 0) return totalOrder;
        final countOrder = right.count.compareTo(left.count);
        if (countOrder != 0) return countOrder;
        final nameOrder = left.category.name.compareTo(right.category.name);
        if (nameOrder != 0) return nameOrder;
        return left.category.transactionCategoryID.compareTo(
          right.category.transactionCategoryID,
        );
      });
    return ranked.first.category;
  }

  void _invalidateViewCaches() {
    _balanceVisibleDisplayLogLimit = visibleDisplayLogPageSize;
    _filterCacheLru.clear();
    _activeCategoriesCache.clear();
    _windowedTransactionsCache.clear();
    _categoryTransactionCountsCache.clear();
    _visibleTransactionsCache.clear();
    _visibleGhostTransactionsCache.clear();
    _balanceVisibleGhostTransactionsCache.clear();
    _visibleLogEntriesCache.clear();
    _visibleDisplayLogEntriesCache.clear();
    _clearBalanceVisibleDisplayLogEntriesCache();
    _visibleDisplayLogEntryTotalCountCache.clear();
    _balanceVisibleDisplayLogEntryTotalCountCache.clear();
    _activeSummaryCache.clear();
    _periodTotalsCache.clear();
    _categoryBudgetBarsCache.clear();
    _overviewBudgetItemsCache.clear();
    _backheaderBudgetItemsCache.clear();
    _totalSummaryCache = null;
    _totalIncomeCache = null;
    _totalExpenseCache = null;
  }

  void _invalidateFastInfoMetrics() {
    _fastInfoMetricsCache = null;
    _fastInfoMetricsDateKey = null;
  }

  void _prewarmCriticalCaches(String reason) {
    final stopwatch = Stopwatch()..start();
    for (final type in TransactionType.values) {
      final baseFilter = TransactionFilter(type: type);
      _activeCategoriesFor(type);
      _balanceVisibleDisplayLogEntriesFor(baseFilter);
      _categoryBudgetBarsFor(type);
      _overviewBudgetItemsFor(type);
      _backheaderBudgetItemsFor(type);
    }
    totalBalanceText;
    totalIncomeAmount;
    totalExpenseAmount;
    DebugConsole.log(
      '[Perf] Store prewarm reason=$reason transactions=${_transactions.length} '
      'categories=${_categories.length} elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
  }

  void _prewarmActiveView(String reason) {
    final stopwatch = Stopwatch()..start();
    final entries = _balanceVisibleDisplayLogEntriesFor(_filter);
    _activeSummaryFor(_filter);
    DebugConsole.log(
      '[Perf] Store active view reason=$reason type=${_filter.type.name} '
      'entries=${entries.length} elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
  }

  void loadMoreVisibleDisplayLogEntries() {
    // The legacy Budget/Mind view is intentionally complete.
  }

  void loadMoreBalanceVisibleDisplayLogEntries() {
    if (!hasMoreBalanceVisibleDisplayLogEntries) return;
    final previousLimit = _balanceVisibleDisplayLogLimit;
    _balanceVisibleDisplayLogLimit += visibleDisplayLogPageSize;
    _clearBalanceVisibleDisplayLogEntriesCache();
    _prewarmActiveView('log-window-more');
    notifyListeners();
    DebugConsole.log(
      '[Perf] LogWindow expand from=$previousLimit '
      'to=$_balanceVisibleDisplayLogLimit '
      'visible=${balanceVisibleDisplayLogEntries.length} '
      'total=$balanceVisibleDisplayLogEntryTotalCount',
    );
  }

  void _resetVisibleDisplayWindow() {
    if (_balanceVisibleDisplayLogLimit == visibleDisplayLogPageSize) return;
    _balanceVisibleDisplayLogLimit = visibleDisplayLogPageSize;
    _clearBalanceVisibleDisplayLogEntriesCache();
  }

  void _touchFilterCacheKey(String key) {
    _filterCacheLru.remove(key);
    _filterCacheLru.add(key);
    if (_filterCacheLru.length <= maxFilterCacheEntries) return;
    _evictFilterCacheKey(_filterCacheLru.removeAt(0));
  }

  void _evictFilterCacheKey(String key) {
    _visibleTransactionsCache.remove(key);
    _visibleGhostTransactionsCache.remove(key);
    _balanceVisibleGhostTransactionsCache.remove(key);
    _visibleLogEntriesCache.remove(key);
    _visibleDisplayLogEntriesCache.remove(key);
    _visibleDisplayLogEntryTotalCountCache.remove(key);
    _balanceVisibleDisplayLogEntryTotalCountCache.remove(key);
    _activeSummaryCache.remove(key);
    final balanceDisplayKeys = _balanceVisibleDisplayLogEntryKeysByFilter
        .remove(key);
    if (balanceDisplayKeys == null) return;
    for (final balanceDisplayKey in balanceDisplayKeys) {
      _balanceVisibleDisplayLogEntriesCache.remove(balanceDisplayKey);
    }
  }

  void _clearBalanceVisibleDisplayLogEntriesCache() {
    _balanceVisibleDisplayLogEntriesCache.clear();
    _balanceVisibleDisplayLogEntryKeysByFilter.clear();
  }

  void _logCacheBuild(
    String label,
    String key,
    Stopwatch stopwatch,
    int rowCount,
  ) {
    final elapsed = stopwatch.elapsedMilliseconds;
    if (rowCount < 1000 && elapsed < 4) return;
    DebugConsole.log(
      '[Perf] Store $label cache key=$key rows=$rowCount elapsed=${elapsed}ms',
    );
  }

  Future<void> start() {
    if (_startCompleted) {
      DebugConsole.log('[Perf] Store start skipped reason=completed');
      return Future.value();
    }
    final existingStart = _startFuture;
    if (existingStart != null) {
      DebugConsole.log('[Perf] Store start skipped reason=in_flight');
      return existingStart;
    }
    _startFuture = _loadInitialData();
    return _startFuture!;
  }

  void suspendUiUpdates() {
    _uiUpdateSuspendDepth += 1;
  }

  void resumeUiUpdates() {
    if (_uiUpdateSuspendDepth == 0) return;
    _uiUpdateSuspendDepth -= 1;
    if (_uiUpdateSuspendDepth > 0) return;
    final reasons = List<String>.from(_pendingPrewarmReasons);
    _pendingPrewarmReasons.clear();
    for (final reason in reasons) {
      _prewarmCriticalCaches(reason);
    }
    if (!_pendingUiNotify) return;
    _pendingUiNotify = false;
    notifyListeners();
  }

  void startAddTransactionForm({
    required List<TransactionCategory> categories,
    required TransactionType type,
  }) {
    _loading = false;
    _error = null;
    _startCompleted = true;
    _startFuture = null;
    _filter = TransactionFilter(type: type);
    _categories = List<TransactionCategory>.unmodifiable(categories);
    _transactions = const <TransactionRecord>[];
    _replaceRecurringGhostTransactions(
      const <RecurringGhostRecord>[],
      resetBalancePool: true,
    );
    _recurringRules = const <RecurringRule>[];
    _limits = const <CategoryLimit>[];
    _rebuildPublicViews();
    _rebuildDerivedIndexes();
    _invalidateViewCaches();
    _invalidateFastInfoMetrics();
    DebugConsole.log(
      '[NativeImeSheet] AddTransaction lightweight store ready '
      'type=${type.name} categories=${_categories.length}',
    );
    notifyListeners();
  }

  Future<void> _loadInitialData() async {
    final railPerf = Stopwatch()..start();
    DebugConsole.log('[RailPerfDiag] store.start');
    var success = false;
    _loading = true;
    _error = null;
    _notifyListenersOrDefer();
    try {
      final payload = await _repository.loadBootstrap();
      DebugConsole.log(
        '[RailPerfDiag] store.bootstrap rows=${payload.transactions.length} ms=${railPerf.elapsedMilliseconds}',
      );
      _categories = payload.categories;
      _transactions = _sort(payload.transactions);
      DebugConsole.log(
        '[RailPerfDiag] store.sort rows=${_transactions.length} ms=${railPerf.elapsedMilliseconds}',
      );
      _replaceRecurringGhostTransactions(
        payload.recurringGhostTransactions,
        resetBalancePool: true,
      );
      DebugConsole.log(
        '[Recurring] loaded ${_recurringGhostTransactions.length} pending ghosts',
      );
      _limits = payload.limits;
      _rebuildPublicViews();
      _rebuildDerivedIndexes();
      _invalidateViewCaches();
      _invalidateFastInfoMetrics();
      _prewarmCriticalCachesOrDefer('start');
      DebugConsole.log(
        '[RailPerfDiag] store.prewarm ms=${railPerf.elapsedMilliseconds}',
      );
      success = true;
    } catch (error) {
      _error = error.toString();
    } finally {
      _startCompleted = success;
      _startFuture = null;
      _loading = false;
      _notifyListenersOrDefer();
      DebugConsole.log(
        '[RailPerfDiag] store.complete success=$success ms=${railPerf.elapsedMilliseconds}',
      );
    }
  }

  bool get _uiUpdatesSuspended => _uiUpdateSuspendDepth > 0;

  void _notifyListenersOrDefer() {
    if (_uiUpdatesSuspended) {
      _pendingUiNotify = true;
      return;
    }
    notifyListeners();
  }

  void _prewarmCriticalCachesOrDefer(String reason) {
    if (!_uiUpdatesSuspended) {
      _prewarmCriticalCaches(reason);
      return;
    }
    if (!_pendingPrewarmReasons.contains(reason)) {
      _pendingPrewarmReasons.add(reason);
    }
  }

  void setActiveType(TransactionType type) {
    final stopwatch = Stopwatch()..start();
    DebugConsole.log(
      '[Perf] TypeSwitch request type=${type.name} '
      'from=${_filter.type.name}',
    );
    final unchanged =
        _filter.type == type &&
        _filter.effectiveCategoryIds.isEmpty &&
        _filter.effectiveMerchants.isEmpty &&
        _filter.searchQuery.isEmpty;
    if (unchanged) {
      DebugConsole.log(
        '[Perf] TypeSwitch skipped type=${type.name} reason=unchanged '
        'elapsed=${stopwatch.elapsedMilliseconds}ms',
      );
      return;
    }
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      type: type,
      clearMerchant: true,
      clearCategory: true,
      searchQuery: '',
    );
    DebugConsole.log(
      '[Perf] TypeSwitch state type=${type.name} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
    DebugConsole.log(
      '[Perf] TypeSwitch notify type=${type.name} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
    notifyListeners();
    DebugConsole.log(
      '[Perf] TypeSwitch complete type=${type.name} '
      'elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
  }

  void setCategoryFilter(TransactionCategory category) {
    setCategoryFilters(
      type: category.normalizedType,
      categoryIds: <int>{category.transactionCategoryID},
    );
  }

  /// Budget V2 has a strict query order: summary pill, avatar category, then
  /// an optional vendor. A new avatar discards the preceding category's
  /// vendor, while a newer vendor intent made after that avatar settled is
  /// preserved by the avatar's single atomic acknowledgement.
  void applyBudgetV2AvatarFilter({
    TransactionCategory? category,
    String? selectedVendor,
  }) {
    final vendor = selectedVendor?.trim();
    final hasVendor = vendor != null && vendor.isNotEmpty;
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      type: category?.normalizedType,
      categoryIds: category == null
          ? null
          : <int>{category.transactionCategoryID},
      clearCategory: category == null,
      merchant: hasVendor ? vendor : null,
      merchantFilters: hasVendor ? <String>{vendor} : null,
      clearMerchant: !hasVendor,
    );
    notifyListeners();
  }

  void setCategoryFilters({
    required TransactionType type,
    required Set<int> categoryIds,
  }) {
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      type: type,
      categoryIds: Set<int>.unmodifiable(categoryIds),
    );
    _prewarmActiveView('category-filter');
    notifyListeners();
  }

  void clearCategoryFilter() {
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(clearCategory: true);
    _prewarmActiveView('category-clear');
    notifyListeners();
  }

  void clearCategoryFilterId(int categoryId) {
    final nextIds = {..._filter.effectiveCategoryIds}..remove(categoryId);
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      clearCategory: nextIds.isEmpty,
      categoryIds: nextIds.isEmpty ? null : Set<int>.unmodifiable(nextIds),
    );
    _prewarmActiveView('category-chip-clear');
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(searchQuery: value);
    _prewarmActiveView('search');
    notifyListeners();
  }

  void setMerchantFilter(String merchant, {String? colorHex}) {
    final value = merchant.trim();
    if (value.isEmpty) return;
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      merchant: value,
      merchantFilters: <String>{value},
      merchantColorHex: colorHex,
    );
    _prewarmActiveView('merchant-filter');
    notifyListeners();
  }

  void setMerchantFilters(Set<String> merchants) {
    final values = merchants
        .map((merchant) => merchant.trim())
        .where((merchant) => merchant.isNotEmpty)
        .toSet();
    _resetVisibleDisplayWindow();
    if (values.isEmpty) {
      _filter = _filter.copyWith(clearMerchant: true);
    } else {
      _filter = _filter.copyWith(
        merchant: values.length == 1 ? values.first : null,
        merchantFilters: Set<String>.unmodifiable(values),
        merchantColorHex: null,
      );
    }
    _prewarmActiveView('merchant-multi-filter');
    notifyListeners();
  }

  Future<StatsViewMutation> prepareStatsViewMutation({
    Set<String>? merchantFilters,
    SummaryWindow? summaryWindow,
    int? year,
    int? month,
  }) async {
    final normalizedMerchants = merchantFilters == null
        ? null
        : Set<String>.unmodifiable(
            merchantFilters
                .map((merchant) => merchant.trim())
                .where((merchant) => merchant.isNotEmpty)
                .toSet(),
          );
    final referenceDate = switch (summaryWindow) {
      SummaryWindow.allTime => _periodReferenceDate,
      SummaryWindow.yearly => DateTime(year ?? _periodReferenceDate.year),
      SummaryWindow.monthly => DateTime(
        year ?? _periodReferenceDate.year,
        (month ?? _periodReferenceDate.month).clamp(1, 12).toInt(),
      ),
      null => null,
    };
    return StatsViewMutation(
      merchantFilters: normalizedMerchants,
      summaryWindow: summaryWindow,
      referenceDate: referenceDate,
    );
  }

  void commitStatsViewMutation(StatsViewMutation mutation) {
    final merchants = mutation.merchantFilters;
    if (merchants != null) {
      _resetVisibleDisplayWindow();
      if (merchants.isEmpty) {
        _filter = _filter.copyWith(clearMerchant: true);
      } else {
        _filter = _filter.copyWith(
          merchant: merchants.length == 1 ? merchants.first : null,
          merchantFilters: merchants,
          merchantColorHex: null,
        );
      }
    }
    final summaryWindow = mutation.summaryWindow;
    int? summaryGeneration;
    if (summaryWindow != null) {
      _summaryWindow = summaryWindow;
      _periodReferenceDate = mutation.referenceDate!;
      _prepareGhostProjectionForActiveWindow();
      summaryGeneration = ++_summaryChangeGeneration;
    }
    _invalidateViewCaches();
    _invalidateFastInfoMetrics();
    notifyListeners();
    if (summaryWindow == SummaryWindow.monthly) {
      // Stats frames consume the stable real-transaction view. Refresh only
      // ghost state after the atomic publish without changing that revision.
      unawaited(
        _projectRecurringGhostsForActiveWindow(
          generation: summaryGeneration,
          notify: false,
        ),
      );
    }
  }

  void clearMerchantFilter([String? merchant]) {
    if (merchant == null) {
      _resetVisibleDisplayWindow();
      _filter = _filter.copyWith(clearMerchant: true);
      _prewarmActiveView('merchant-clear');
      notifyListeners();
      return;
    }
    final nextValues = {..._filter.effectiveMerchants}..remove(merchant.trim());
    _resetVisibleDisplayWindow();
    if (nextValues.isEmpty) {
      _filter = _filter.copyWith(clearMerchant: true);
    } else {
      _filter = _filter.copyWith(
        merchant: nextValues.length == 1 ? nextValues.first : null,
        merchantFilters: Set<String>.unmodifiable(nextValues),
      );
    }
    _prewarmActiveView('merchant-chip-clear');
    notifyListeners();
  }

  Future<void> cycleSummaryWindow() async {
    _summaryWindow = switch (_summaryWindow) {
      SummaryWindow.monthly => SummaryWindow.yearly,
      SummaryWindow.yearly => SummaryWindow.allTime,
      SummaryWindow.allTime => SummaryWindow.monthly,
    };
    _prepareGhostProjectionForActiveWindow();
    _invalidateViewCaches();
    final generation = ++_summaryChangeGeneration;
    notifyListeners();
    await _finishSummaryChange('summary-window', generation);
  }

  Future<void> shiftSummaryPeriod(int direction) async {
    if (direction == 0 || _summaryWindow == SummaryWindow.allTime) return;
    _periodReferenceDate = switch (_summaryWindow) {
      SummaryWindow.monthly => DateTime(
        _periodReferenceDate.year,
        _periodReferenceDate.month + direction,
      ),
      SummaryWindow.yearly => DateTime(_periodReferenceDate.year + direction),
      SummaryWindow.allTime => _periodReferenceDate,
    };
    _prepareGhostProjectionForActiveWindow();
    _invalidateViewCaches();
    final generation = ++_summaryChangeGeneration;
    notifyListeners();
    await _finishSummaryChange('summary-period', generation);
  }

  Future<void> resetSummaryToCurrentMonth() async {
    _summaryWindow = SummaryWindow.monthly;
    _periodReferenceDate = _monthStart(_clock());
    _prepareGhostProjectionForActiveWindow();
    _invalidateViewCaches();
    final generation = ++_summaryChangeGeneration;
    notifyListeners();
    await _finishSummaryChange('summary-reset', generation);
  }

  Future<void> setSummaryMonth(int year, int month) async {
    final boundedMonth = month.clamp(1, 12).toInt();
    _summaryWindow = SummaryWindow.monthly;
    _periodReferenceDate = DateTime(year, boundedMonth);
    _prepareGhostProjectionForActiveWindow();
    _invalidateViewCaches();
    final generation = ++_summaryChangeGeneration;
    notifyListeners();
    await _finishSummaryChange('summary-native-picker', generation);
  }

  Future<void> setSummaryYear(int year) async {
    _summaryWindow = SummaryWindow.yearly;
    _periodReferenceDate = DateTime(year);
    _prepareGhostProjectionForActiveWindow();
    _invalidateViewCaches();
    final generation = ++_summaryChangeGeneration;
    notifyListeners();
    await _finishSummaryChange('summary-year-picker', generation);
  }

  Future<void> setSummaryAllTime() async {
    _summaryWindow = SummaryWindow.allTime;
    _prepareGhostProjectionForActiveWindow();
    _invalidateViewCaches();
    final generation = ++_summaryChangeGeneration;
    notifyListeners();
    await _finishSummaryChange('summary-all-picker', generation);
  }

  Future<void> _finishSummaryChange(String reason, int generation) async {
    await Future<void>.delayed(Duration.zero);
    if (generation != _summaryChangeGeneration) return;
    // A rail settle must publish the selected scope before any broad cache
    // warming. The old all-type prewarm repeatedly rebuilt unrelated Budget
    // and overview views on the UI path, making a one-pill move feel frozen.
    _prewarmActiveView(reason);
    await _projectRecurringGhostsForActiveWindow(generation: generation);
  }

  Future<void> addTransaction({
    required String merchant,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required String date,
    required String time,
    bool reloadAfterSave = true,
  }) async {
    await _repository.addTransaction({
      'merchant': merchant,
      'amount': amount,
      'type': type.nativeValue,
      'transactionCategoryID': categoryId,
      'date': date,
      'time': time,
    });
    if (!reloadAfterSave) {
      _scheduleNotificationRefresh();
      return;
    }
    await _reload(notify: false);
    await _projectRecurringGhostsForActiveWindow(notify: false);
    notifyListeners();
    _scheduleNotificationRefresh();
  }

  Future<void> mergeTransactionsForNotificationEvents(
    Iterable<int> eventIds,
  ) async {
    final ids = eventIds.where((id) => id > 0).toSet();
    if (ids.isEmpty) return;
    final rows = await _repository.transactionsForNotificationEvents(ids);
    if (rows.isEmpty) return;
    mergeExternalTransactions(rows);
  }

  void mergeExternalTransactions(Iterable<TransactionRecord> records) {
    var changed = false;
    for (final record in records) {
      final index = _transactions.indexWhere((row) => row.id == record.id);
      if (index == -1) {
        _transactions.add(record);
        changed = true;
        continue;
      }
      if (!_sameTransactionRecord(_transactions[index], record)) {
        _transactions[index] = record;
        changed = true;
      }
    }
    if (!changed) return;
    _transactions = _sort(_transactions);
    _rebuildPublicViews();
    _rebuildDerivedIndexes();
    _invalidateViewCaches();
    _invalidateFastInfoMetrics();
    _prewarmCriticalCaches('external-transactions');
    notifyListeners();
    _scheduleNotificationRefresh();
  }

  bool _sameTransactionRecord(TransactionRecord left, TransactionRecord right) {
    final leftMap = left.toMap();
    final rightMap = right.toMap();
    if (leftMap.length != rightMap.length) return false;
    for (final entry in leftMap.entries) {
      if (rightMap[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<void> updateTransaction(
    TransactionRecord transaction, {
    required String merchant,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required String date,
    required String time,
    String? userAssignedName,
  }) async {
    DebugConsole.log(
      '[Notification] transaction update requested id=${transaction.id} '
      'oldAmount=${transaction.amount} newAmount=$amount '
      'oldCategory=${transaction.transactionCategoryID} newCategory=$categoryId',
    );
    final originalMerchant = transaction.merchant.trim();
    final displayMerchant = merchant.trim();
    final assignedName =
        userAssignedName ??
        (displayMerchant == originalMerchant ? null : displayMerchant);
    await _repository.updateTransaction(transaction.id, {
      'merchant': originalMerchant,
      'amount': amount,
      'type': type.nativeValue,
      'transactionCategoryID': categoryId,
      'date': date,
      'time': time,
      'userAssignedName': assignedName,
    });
    DebugConsole.log(
      '[Notification] transaction update completed id=${transaction.id}',
    );
    await _reload();
    _scheduleNotificationRefresh();
  }

  Future<bool> deleteTransaction(TransactionRecord transaction) async {
    final deleted = await _repository.deleteTransaction(transaction.id);
    if (deleted) {
      await _reload();
    }
    return deleted;
  }

  Future<void> refreshAfterRecurringProcessing() async {
    await _reload();
    _scheduleNotificationRefresh();
    DebugConsole.log('[RecurringAlarm] store refreshed after processing');
  }

  Future<int> renameTransactionsByMerchant(
    TransactionRecord transaction,
    String userAssignedName,
  ) {
    return renameTransactionsByOriginalMerchant(
      transaction.merchant,
      userAssignedName,
    );
  }

  Future<int> renameTransactionsByOriginalMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async {
    final merchant = originalMerchant.trim();
    final assignedName = userAssignedName.trim();
    if (merchant.isEmpty || assignedName.isEmpty) return 0;
    final previousDisplayNames = _displayNamesForOriginalMerchant(merchant);
    DebugConsole.log('[Transactions] rename $merchant -> $assignedName');
    final count = await _repository.renameTransactionsByMerchant(
      merchant,
      assignedName,
    );
    _replaceActiveMerchantFilters(previousDisplayNames, assignedName);
    await _reload();
    DebugConsole.log('[Transactions] renamed $count rows for $merchant');
    return count;
  }

  Future<int> resetTransactionNamesByMerchant(TransactionRecord transaction) {
    return resetTransactionNamesByOriginalMerchant(transaction.merchant);
  }

  Future<int> resetTransactionNamesByOriginalMerchant(
    String originalMerchant,
  ) async {
    final merchant = originalMerchant.trim();
    if (merchant.isEmpty) return 0;
    final previousDisplayNames = _displayNamesForOriginalMerchant(merchant);
    DebugConsole.log('[Transactions] reset name $merchant');
    final count = await _repository.resetTransactionNamesByMerchant(merchant);
    _replaceActiveMerchantFilters(previousDisplayNames, merchant);
    await _reload();
    DebugConsole.log('[Transactions] reset $count rows for $merchant');
    return count;
  }

  Set<String> _displayNamesForOriginalMerchant(String originalMerchant) {
    final merchant = originalMerchant.trim();
    if (merchant.isEmpty) return const <String>{};
    final names = <String>{};
    for (final transaction in _transactions) {
      if (transaction.merchant.trim() != merchant) continue;
      final displayName = transaction.displayMerchant.trim();
      if (displayName.isNotEmpty) names.add(displayName);
    }
    return names.isEmpty ? <String>{merchant} : names;
  }

  void _replaceActiveMerchantFilters(
    Set<String> previousDisplayNames,
    String nextDisplayName,
  ) {
    final nextName = nextDisplayName.trim();
    if (nextName.isEmpty || previousDisplayNames.isEmpty) return;
    final currentFilters = _filter.effectiveMerchants;
    if (currentFilters.isEmpty) return;
    final nextFilters = <String>{};
    var changed = false;
    for (final filterName in currentFilters) {
      if (previousDisplayNames.contains(filterName)) {
        nextFilters.add(nextName);
        changed = true;
      } else {
        nextFilters.add(filterName);
      }
    }
    if (!changed || setEquals(currentFilters, nextFilters)) return;
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      merchant: nextFilters.length == 1 ? nextFilters.first : null,
      merchantFilters: Set<String>.unmodifiable(nextFilters),
      merchantColorHex: nextFilters.length == 1
          ? _filter.merchantColorHex
          : null,
    );
  }

  Future<void> loadRecurringRules() async {
    _recurringRules = await _repository.listRecurringRules();
    notifyListeners();
  }

  Future<void> saveRecurringRule({
    int? id,
    required RecurringTriggerType triggerType,
    TransactionType? transactionType,
    required String name,
    required double estimatedAmount,
    required int expectedDayOfMonth,
    String expectedTime = '00:00',
    required int categoryId,
    bool isActive = true,
    String appFilterText = '',
    String packageName = '',
    String appLabel = '',
    String sampleText = '',
    String includeKeyword = '',
    String amountPattern = '',
    String amountSelection = '',
    String merchantPattern = '',
    String merchantSelection = '',
    int dateToleranceDays = 5,
    double amountTolerancePercent = 20,
    double amountToleranceMin = 5000,
  }) async {
    final draft = RecurringRuleDraft(
      triggerType: triggerType,
      transactionType: transactionType ?? activeType,
      name: name,
      estimatedAmount: estimatedAmount,
      expectedDayOfMonth: expectedDayOfMonth,
      expectedTime: expectedTime,
      categoryId: categoryId,
      isActive: isActive,
      appFilterText: appFilterText,
      packageName: packageName,
      appLabel: appLabel,
      sampleText: sampleText,
      includeKeyword: includeKeyword,
      amountPattern: amountPattern,
      amountSelection: amountSelection,
      merchantPattern: merchantPattern,
      merchantSelection: merchantSelection,
      dateToleranceDays: dateToleranceDays,
      amountTolerancePercent: amountTolerancePercent,
      amountToleranceMin: amountToleranceMin,
    );
    if (id == null) {
      await _repository.addRecurringRule(draft);
    } else {
      await _repository.updateRecurringRule(id, draft);
    }
    await _reloadRecurringRuleState();
  }

  Future<void> toggleRecurringRule(RecurringRule rule) async {
    await _repository.toggleRecurringRule(rule.id, !rule.isActive);
    await _reloadRecurringRuleState();
  }

  Future<void> deleteRecurringRule(RecurringRule rule) async {
    await _repository.deleteRecurringRule(rule.id);
    await _reloadRecurringRuleState();
  }

  Future<void> addCategory({
    required String name,
    required TransactionType type,
    required int colorSlot,
    required int iconSlot,
  }) async {
    await _repository.addCategory({
      'name': name,
      'type': type.nativeValue,
      'colorSlot': colorSlot,
      'iconSlot': iconSlot,
    });
    await _reload();
  }

  Future<void> updateCategory(
    TransactionCategory category, {
    required String name,
    required int colorSlot,
    required int iconSlot,
  }) async {
    await _repository.updateCategory(category.transactionCategoryID, {
      'name': name,
      'type': category.normalizedType.nativeValue,
      'colorSlot': colorSlot,
      'iconSlot': iconSlot,
    });
    await _reload();
  }

  Future<bool> deleteCategory(TransactionCategory category) async {
    final deleted = await _repository.deleteCategory(
      category.transactionCategoryID,
    );
    if (deleted) {
      final categoryIds = _filter.effectiveCategoryIds;
      if (categoryIds.contains(category.transactionCategoryID)) {
        final nextIds = {...categoryIds}
          ..remove(category.transactionCategoryID);
        _filter = _filter.copyWith(clearCategory: true);
        if (nextIds.isNotEmpty) {
          _filter = _filter.copyWith(categoryIds: nextIds);
        }
      }
      await _reload();
    }
    return deleted;
  }

  Future<void> saveCategoryLimitForBar(
    CategoryBudgetBarData bar, {
    required double limitAmount,
    required bool alertActive,
  }) async {
    final amount = limitAmount < 0 ? 0.0 : limitAmount;
    final hasLimit = amount > 0;
    await _repository.upsertCategoryLimit({
      'targetType': bar.targetType.nativeValue,
      'targetId': bar.targetId,
      'transactionType': bar.transactionType.nativeValue,
      'window': bar.window.nativeValue,
      'periodKey': bar.periodKey,
      'hasLimit': hasLimit,
      'limitAmount': hasLimit ? amount : 0.0,
      'alertActive': hasLimit && alertActive,
    });
    await _reload();
    _scheduleNotificationRefresh();
  }

  Future<void> saveCategoryLimitForBarInline(
    CategoryBudgetBarData bar, {
    required double limitAmount,
    required bool alertActive,
    bool notify = true,
    bool Function()? shouldApplyResult,
  }) async {
    final amount = limitAmount < 0 ? 0.0 : limitAmount;
    final hasLimit = amount > 0;
    final saved = await _repository.upsertCategoryLimit({
      'targetType': bar.targetType.nativeValue,
      'targetId': bar.targetId,
      'transactionType': bar.transactionType.nativeValue,
      'window': bar.window.nativeValue,
      'periodKey': bar.periodKey,
      'hasLimit': hasLimit,
      'limitAmount': hasLimit ? amount : 0.0,
      'alertActive': hasLimit && alertActive,
    });
    if (shouldApplyResult?.call() == false) return;
    _replaceSavedLimit(saved);
    if (notify) notifyListeners();
    _scheduleNotificationRefresh();
  }

  Future<void> saveOverviewLimit(
    BudgetGoalKind kind, {
    required double limitAmount,
    required bool alertActive,
  }) async {
    final amount = limitAmount < 0 ? 0.0 : limitAmount;
    final hasLimit = amount > 0;
    await _repository.upsertCategoryLimit({
      'targetType': LimitTargetType.overview.nativeValue,
      'targetId': 0,
      'transactionType': kind.transactionType,
      'window': LimitManager.windowForSummary(_summaryWindow).nativeValue,
      'periodKey': LimitManager.periodKeyFor(
        _summaryWindow,
        _periodReferenceDate,
      ),
      'hasLimit': hasLimit,
      'limitAmount': hasLimit ? amount : 0.0,
      'alertActive': hasLimit && alertActive,
    });
    await _reload();
    _scheduleNotificationRefresh();
  }

  Future<void> saveOverviewLimitInline(
    BudgetGoalKind kind, {
    required double limitAmount,
    required bool alertActive,
    bool notify = true,
  }) async {
    final amount = limitAmount < 0 ? 0.0 : limitAmount;
    final hasLimit = amount > 0;
    final saved = await _repository.upsertCategoryLimit({
      'targetType': LimitTargetType.overview.nativeValue,
      'targetId': 0,
      'transactionType': kind.transactionType,
      'window': LimitManager.windowForSummary(_summaryWindow).nativeValue,
      'periodKey': LimitManager.periodKeyFor(
        _summaryWindow,
        _periodReferenceDate,
      ),
      'hasLimit': hasLimit,
      'limitAmount': hasLimit ? amount : 0.0,
      'alertActive': hasLimit && alertActive,
    });
    _replaceSavedLimit(saved);
    if (notify) notifyListeners();
    _scheduleNotificationRefresh();
  }

  void _replaceSavedLimit(CategoryLimit saved) {
    final index = _limits.indexWhere((limit) => _sameLimitScope(limit, saved));
    if (index >= 0) {
      _limits = [
        for (var i = 0; i < _limits.length; i += 1)
          if (i == index) saved else _limits[i],
      ];
    } else {
      _limits = [..._limits, saved];
    }
    _rebuildPublicViews();
    _invalidateViewCaches();
    _invalidateFastInfoMetrics();
  }

  bool _sameLimitScope(CategoryLimit left, CategoryLimit right) {
    return left.targetType == right.targetType &&
        left.targetId == right.targetId &&
        left.transactionType == right.transactionType &&
        left.window == right.window &&
        left.periodKey == right.periodKey;
  }

  Future<void> _projectRecurringGhostsForActiveWindow({
    int? generation,
    bool notify = true,
  }) async {
    if (_summaryWindow != SummaryWindow.monthly) {
      if (generation == null || generation == _summaryChangeGeneration) {
        _ghostProjectionInFlight = false;
        _invalidateViewCaches();
      }
      return;
    }
    final targetDate = _monthStart(_periodReferenceDate);
    final periodKey = _monthPeriodKey(targetDate);
    _ghostProjectionInFlight = true;
    _invalidateViewCaches();
    DebugConsole.log('[Recurring] ensuring ghosts for $periodKey');
    try {
      final ghosts = await _repository.ensureRecurringGhostTransactions(
        targetDate: targetDate,
      );
      if (generation != null && generation != _summaryChangeGeneration) {
        return;
      }
      _replaceRecurringGhostTransactions(ghosts, stablePeriodKey: periodKey);
      _rebuildRecurringGhostsView();
      _invalidateViewCaches();
      _invalidateFastInfoMetrics();
      _prewarmActiveView('recurring-ghosts');
      DebugConsole.log(
        '[Recurring] projected ${visibleGhostTransactions.length} ghosts for $periodKey',
      );
      if (notify) notifyListeners();
    } finally {
      if ((generation == null || generation == _summaryChangeGeneration) &&
          _ghostProjectionInFlight) {
        _ghostProjectionInFlight = false;
        _invalidateViewCaches();
        if (notify) notifyListeners();
      }
    }
  }

  Future<void> _projectRecurringGhostsForBalancePeriod({
    required DateTime targetDate,
    required int generation,
  }) async {
    final periodKey = _monthPeriodKey(targetDate);
    DebugConsole.log('[Recurring] ensuring Balance card ghosts for $periodKey');
    final ghosts = await _repository.ensureRecurringGhostTransactions(
      targetDate: targetDate,
    );
    if (generation != _dateBoundaryProjectionGeneration ||
        _monthPeriodKey(_clock()) != periodKey) {
      return;
    }
    final periodGhosts = _sortGhosts(
      ghosts.where((ghost) => ghost.yearMonthKey == periodKey).toList(),
    );
    _updateBalanceRecurringGhostPool(
      periodGhosts,
      projectedPeriodKey: periodKey,
      reset: false,
    );
    _invalidateViewCaches();
    _invalidateFastInfoMetrics();
    _prewarmCriticalCaches('date-boundary-recurring-ghosts');
    notifyListeners();
    DebugConsole.log(
      '[Recurring] projected ${periodGhosts.length} Balance card ghosts '
      'for $periodKey',
    );
  }

  Future<void> _reloadRecurringRuleState() async {
    _recurringRules = await _repository.listRecurringRules();
    await _reload();
    _scheduleNotificationRefresh();
  }

  void _scheduleNotificationRefresh() {
    final callback = _onNotificationsMayHaveChanged;
    if (callback == null) return;
    unawaited(
      callback().catchError((Object error) {
        DebugConsole.log(
          '[Notification] cards refresh after transaction change failed: $error',
        );
      }),
    );
  }

  Future<void> _reload({bool notify = true}) async {
    final payload = await _repository.loadBootstrap();
    _categories = payload.categories;
    _transactions = _sort(payload.transactions);
    _replaceRecurringGhostTransactions(
      payload.recurringGhostTransactions,
      resetBalancePool: true,
    );
    _limits = payload.limits;
    _rebuildPublicViews();
    _rebuildDerivedIndexes();
    _invalidateViewCaches();
    _invalidateFastInfoMetrics();
    _prewarmCriticalCaches('reload');
    if (notify) notifyListeners();
  }

  void _prepareGhostProjectionForActiveWindow() {
    _ghostProjectionInFlight = _summaryWindow == SummaryWindow.monthly;
  }

  List<RecurringGhostRecord> get _activeGhostSource {
    if (_ghostProjectionInFlight && _stableGhostPeriodKey != null) {
      return _stableRecurringGhostTransactions;
    }
    return _recurringGhostTransactions;
  }

  String? get _activeGhostPeriodKey {
    if (_summaryWindow != SummaryWindow.monthly) return null;
    return _activeMonthlyPeriodKey;
  }

  void _replaceRecurringGhostTransactions(
    List<RecurringGhostRecord> records, {
    String? stablePeriodKey,
    bool resetBalancePool = false,
  }) {
    final sorted = _sortGhosts(records);
    _recurringGhostTransactions = sorted;
    _stableRecurringGhostTransactions = sorted;
    _stableGhostPeriodKey = stablePeriodKey ?? _stablePeriodKeyFor(sorted);
    _updateBalanceRecurringGhostPool(
      sorted,
      projectedPeriodKey: stablePeriodKey,
      reset: resetBalancePool,
    );
    _ghostProjectionInFlight = false;
  }

  void _updateBalanceRecurringGhostPool(
    List<RecurringGhostRecord> records, {
    required String? projectedPeriodKey,
    required bool reset,
  }) {
    if (reset) _balanceRecurringGhostsByPeriod.clear();
    if (projectedPeriodKey case final periodKey?) {
      _balanceRecurringGhostsByPeriod[periodKey] =
          List<RecurringGhostRecord>.unmodifiable(records);
    } else {
      final grouped = <String, List<RecurringGhostRecord>>{};
      for (final ghost in records) {
        grouped.putIfAbsent(ghost.yearMonthKey, () => []).add(ghost);
      }
      for (final entry in grouped.entries) {
        _balanceRecurringGhostsByPeriod[entry.key] =
            List<RecurringGhostRecord>.unmodifiable(entry.value);
      }
    }
    final periodKeys = _balanceRecurringGhostsByPeriod.keys.toList()..sort();
    _balanceRecurringGhostTransactionsView =
        List<RecurringGhostRecord>.unmodifiable([
          for (final periodKey in periodKeys)
            ..._balanceRecurringGhostsByPeriod[periodKey]!,
        ]);
  }

  String _stablePeriodKeyFor(List<RecurringGhostRecord> records) {
    final activePeriodKey = _activeMonthlyPeriodKey;
    for (final ghost in records) {
      if (ghost.yearMonthKey == activePeriodKey) return activePeriodKey;
    }
    if (records.isNotEmpty) return records.first.yearMonthKey;
    return activePeriodKey;
  }

  void _rebuildPublicViews() {
    _categoriesView = List<TransactionCategory>.unmodifiable(_categories);
    _transactionsView = List<TransactionRecord>.unmodifiable(_transactions);
    _rebuildRecurringGhostsView();
    _limitsView = List<CategoryLimit>.unmodifiable(_limits);
  }

  void _rebuildRecurringGhostsView() {
    _recurringGhostTransactionsView = List<RecurringGhostRecord>.unmodifiable(
      _recurringGhostTransactions,
    );
  }

  void _rebuildDerivedIndexes() {
    _categoriesById = Map.unmodifiable({
      for (final category in _categories)
        category.transactionCategoryID: category,
    });
    _transactionIdsByType = Set.unmodifiable({
      for (final record in _transactions) _typedId(record.type, record.id),
    });
    _recurringInstanceIdsByType = Set.unmodifiable({
      for (final record in _transactions)
        if (record.recurringInstanceId case final recurringInstanceId?)
          _typedId(record.type, recurringInstanceId),
    });
    _recurringMonthKeysByType = Set.unmodifiable({
      for (final record in _transactions)
        if (record.recurringTransactionId case final recurringTransactionId?)
          '${record.type.name}|$recurringTransactionId|${record.yearMonthKey}',
    });
  }

  bool _ghostIsBeforeCurrentMonth(RecurringGhostRecord ghost) {
    final ghostDate = DateTime.tryParse(ghost.normalizedDate);
    if (ghostDate == null) return false;
    return DateTime(
      ghostDate.year,
      ghostDate.month,
    ).isBefore(_monthStart(_clock()));
  }

  bool _ghostInActiveWindow(RecurringGhostRecord ghost, {String? periodKey}) {
    return switch (_summaryWindow) {
      SummaryWindow.monthly =>
        ghost.yearMonthKey == (periodKey ?? _activeMonthlyPeriodKey),
      SummaryWindow.yearly => false,
      SummaryWindow.allTime => false,
    };
  }

  List<RecurringGhostRecord> _sortGhosts(List<RecurringGhostRecord> records) {
    final rows = [...records];
    rows.sort((left, right) {
      final date = right.date.compareTo(left.date);
      if (date != 0) return date;
      final time = right.time.compareTo(left.time);
      if (time != 0) return time;
      return right.id.compareTo(left.id);
    });
    return rows;
  }

  List<TransactionRecord> _sort(List<TransactionRecord> records) {
    final rows = [...records];
    rows.sort((left, right) => right.id.compareTo(left.id));
    return rows;
  }
}

String _calendarDayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

String _typedId(TransactionType type, int id) => '${type.name}|$id';

DateTime _monthStart(DateTime value) => DateTime(value.year, value.month);

String _monthPeriodKey(DateTime value) =>
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
