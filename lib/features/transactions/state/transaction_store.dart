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
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../models/transaction_summary.dart';
import 'fast_info_metrics_resolver.dart';

class TransactionStore extends ChangeNotifier {
  TransactionStore(
    this._repository, {
    DateTime Function()? clock,
    Future<void> Function()? onNotificationsMayHaveChanged,
  }) : _clock = clock ?? DateTime.now,
       _onNotificationsMayHaveChanged = onNotificationsMayHaveChanged {
    _periodReferenceDate = _monthStart(_clock());
  }

  final TransactionRepositoryContract _repository;
  final DateTime Function() _clock;
  final Future<void> Function()? _onNotificationsMayHaveChanged;
  var _filter = const TransactionFilter();
  var _summaryWindow = SummaryWindow.allTime;
  var _summaryChangeGeneration = 0;
  late DateTime _periodReferenceDate;
  var _loading = false;
  var _startCompleted = false;
  Future<void>? _startFuture;
  String? _error;
  List<TransactionCategory> _categories = [];
  List<TransactionRecord> _transactions = [];
  List<RecurringGhostRecord> _recurringGhostTransactions = [];
  List<RecurringGhostRecord> _stableRecurringGhostTransactions = const [];
  String? _stableGhostPeriodKey;
  var _ghostProjectionInFlight = false;
  List<RecurringRule> _recurringRules = const [];
  List<CategoryLimit> _limits = [];
  List<TransactionCategory> _categoriesView = const [];
  List<TransactionRecord> _transactionsView = const [];
  List<RecurringGhostRecord> _recurringGhostTransactionsView = const [];
  List<CategoryLimit> _limitsView = const [];
  Map<int, TransactionCategory> _categoriesById = const {};
  Map<int, int> _categoryTransactionCounts = const {};
  final _activeCategoriesCache = <TransactionType, List<TransactionCategory>>{};
  final _windowedTransactionsCache = <String, List<TransactionRecord>>{};
  final _visibleTransactionsCache = <String, List<TransactionRecord>>{};
  final _visibleGhostTransactionsCache = <String, List<RecurringGhostRecord>>{};
  final _visibleLogEntriesCache = <String, List<TransactionLogEntry>>{};
  final _visibleDisplayLogEntriesCache = <String, List<TransactionLogEntry>>{};
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
  bool get loading => _loading;
  String? get error => _error;
  TransactionType get activeType => _filter.type;
  SummaryWindow get summaryWindow => _summaryWindow;
  DateTime get currentDate => _clock();
  String get searchQuery => _filter.searchQuery;
  String? get merchantFilter => _filter.merchant;
  String? get merchantFilterColorHex => _filter.merchantColorHex;
  TransactionCategory? get activeCategory {
    final id = _filter.categoryId;
    if (id == null) return null;
    return _categoriesById[id];
  }

  Map<int, int> get categoryTransactionCounts => _categoryTransactionCounts;
  Map<int, TransactionCategory> get categoriesById => _categoriesById;

  List<TransactionCategory> get categories => _categoriesView;
  List<TransactionRecord> get transactions => _transactionsView;
  List<RecurringGhostRecord> get recurringGhostTransactions =>
      _recurringGhostTransactionsView;
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

  bool get hasMoreVisibleDisplayLogEntries =>
      visibleDisplayLogEntries.length < visibleDisplayLogEntryTotalCount;

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
    final merchant = _filter.merchant;
    if (merchant != null) parts.add(merchant);
    final category = activeCategory;
    if (category != null) parts.add(category.name);
    return parts.join(' · ');
  }

  String get _activePeriodKey =>
      LimitManager.periodKeyFor(_summaryWindow, _periodReferenceDate);

  String get _activeMonthlyPeriodKey => _monthPeriodKey(_periodReferenceDate);

  String _windowCacheKey(TransactionType type) =>
      '${type.name}|${_summaryWindow.name}|$_activePeriodKey';

  String _filterCacheKey(TransactionFilter filter) {
    final query = filter.searchQuery.trim().toLowerCase();
    final merchant = filter.merchant?.trim() ?? '';
    return '${_windowCacheKey(filter.type)}|c=${filter.categoryId ?? 0}|m=$merchant|q=$query';
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

  List<TransactionRecord> _visibleTransactionsFor(TransactionFilter filter) {
    final key = _filterCacheKey(filter);
    final cached = _visibleTransactionsCache[key];
    if (cached != null) return cached;
    final query = filter.searchQuery.trim().toLowerCase();
    final merchant = filter.merchant?.trim();
    final rows = List<TransactionRecord>.unmodifiable(
      _windowedTransactionsFor(filter.type).where((record) {
        if (filter.categoryId != null &&
            record.transactionCategoryID != filter.categoryId) {
          return false;
        }
        if (merchant != null && record.displayMerchant != merchant) {
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
    final merchant = filter.merchant?.trim();
    final rows = List<RecurringGhostRecord>.unmodifiable(
      _activeGhostSource.where((ghost) {
        if (ghost.isActivated) return false;
        if (_ghostIsBeforeCurrentMonth(ghost)) return false;
        if (ghost.type != filter.type) return false;
        if (!_ghostInActiveWindow(ghost, periodKey: periodKey)) return false;
        if (filter.categoryId != null &&
            ghost.categoryId != filter.categoryId) {
          return false;
        }
        if (merchant != null && ghost.name != merchant) return false;
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
    final records = <TransactionLogEntry>[
      for (final record in _visibleTransactionsFor(filter))
        TransactionLogEntry.record(record),
    ];
    records.sort(_compareLogEntries);
    final entries = _summaryWindow == SummaryWindow.monthly
        ? <TransactionLogEntry>[
            for (final ghost in _visibleGhostTransactionsFor(filter))
              TransactionLogEntry.ghost(ghost),
            ...records,
          ]
        : records;
    final rows = List<TransactionLogEntry>.unmodifiable(entries);
    _visibleLogEntriesCache[key] = rows;
    return rows;
  }

  List<TransactionLogEntry> _visibleDisplayLogEntriesFor(
    TransactionFilter filter,
  ) {
    final key = _filterCacheKey(filter);
    final cached = _visibleDisplayLogEntriesCache[key];
    if (cached != null) return cached;
    final stopwatch = Stopwatch()..start();
    final entries = <TransactionLogEntry>[];
    String? previousGhostDate;
    String? previousRecordDate;
    for (final row in _visibleLogEntriesFor(filter)) {
      if (row.isGhost) {
        if (row.date != previousGhostDate) {
          entries.add(TransactionLogEntry.header(row.date));
          previousGhostDate = row.date;
        }
        entries.add(row);
        continue;
      }
      if (row.date != previousRecordDate) {
        entries.add(TransactionLogEntry.header(row.date));
        previousRecordDate = row.date;
      }
      entries.add(row);
    }
    final rows = List<TransactionLogEntry>.unmodifiable(entries);
    _visibleDisplayLogEntriesCache[key] = rows;
    _logCacheBuild('display-${filter.type.name}', key, stopwatch, rows.length);
    return rows;
  }

  int _visibleDisplayLogEntryTotalCountFor(TransactionFilter filter) {
    var total = 0;
    String? previousGhostDate;
    String? previousRecordDate;
    for (final row in _visibleLogEntriesFor(filter)) {
      if (row.isGhost) {
        if (row.date != previousGhostDate) {
          total += 1;
          previousGhostDate = row.date;
        }
        total += 1;
        continue;
      }
      if (row.date != previousRecordDate) {
        total += 1;
        previousRecordDate = row.date;
      }
      total += 1;
    }
    return total;
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
        : const [BudgetGoalKind.incomeGoal, BudgetGoalKind.savingGoal];

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

  void _invalidateViewCaches() {
    _activeCategoriesCache.clear();
    _windowedTransactionsCache.clear();
    _visibleTransactionsCache.clear();
    _visibleGhostTransactionsCache.clear();
    _visibleLogEntriesCache.clear();
    _visibleDisplayLogEntriesCache.clear();
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
      _visibleDisplayLogEntriesFor(baseFilter);
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
    final entries = _visibleDisplayLogEntriesFor(_filter);
    _activeSummaryFor(_filter);
    DebugConsole.log(
      '[Perf] Store active view reason=$reason type=${_filter.type.name} '
      'entries=${entries.length} elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
  }

  void loadMoreVisibleDisplayLogEntries() {
    if (!hasMoreVisibleDisplayLogEntries) return;
    _prewarmActiveView('log-window-more');
    notifyListeners();
    DebugConsole.log(
      '[Perf] LogWindow expand visible=${visibleDisplayLogEntries.length} '
      'total=$visibleDisplayLogEntryTotalCount',
    );
  }

  void _resetVisibleDisplayWindow() {}

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

  Future<void> _loadInitialData() async {
    var success = false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = await _repository.loadBootstrap();
      _categories = payload.categories;
      _transactions = _sort(payload.transactions);
      _replaceRecurringGhostTransactions(payload.recurringGhostTransactions);
      DebugConsole.log(
        '[Recurring] loaded ${_recurringGhostTransactions.length} pending ghosts',
      );
      _limits = payload.limits;
      _rebuildPublicViews();
      _rebuildDerivedIndexes();
      _invalidateViewCaches();
      _invalidateFastInfoMetrics();
      _prewarmCriticalCaches('start');
      success = true;
    } catch (error) {
      _error = error.toString();
    } finally {
      _startCompleted = success;
      _startFuture = null;
      _loading = false;
      notifyListeners();
    }
  }

  void setActiveType(TransactionType type) {
    final unchanged =
        _filter.type == type &&
        _filter.categoryId == null &&
        _filter.merchant == null &&
        _filter.searchQuery.isEmpty;
    if (unchanged) return;
    final stopwatch = Stopwatch()..start();
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      type: type,
      clearMerchant: true,
      clearCategory: true,
      searchQuery: '',
    );
    _prewarmActiveView('type-switch');
    notifyListeners();
    DebugConsole.log(
      '[Perf] TypeSwitch type=${type.name} elapsed=${stopwatch.elapsedMilliseconds}ms',
    );
  }

  void setCategoryFilter(TransactionCategory category) {
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      type: category.normalizedType,
      categoryId: category.transactionCategoryID,
      searchQuery: '',
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

  void setSearchQuery(String value) {
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(searchQuery: value);
    _prewarmActiveView('search');
    notifyListeners();
  }

  void setMerchantFilter(String merchant, {String? colorHex}) {
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(
      merchant: merchant,
      merchantColorHex: colorHex,
      searchQuery: '',
    );
    _prewarmActiveView('merchant-filter');
    notifyListeners();
  }

  void clearMerchantFilter() {
    _resetVisibleDisplayWindow();
    _filter = _filter.copyWith(clearMerchant: true);
    _prewarmActiveView('merchant-clear');
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

  Future<void> _finishSummaryChange(String reason, int generation) async {
    await Future<void>.delayed(Duration.zero);
    if (generation != _summaryChangeGeneration) return;
    _prewarmCriticalCaches(reason);
    await _projectRecurringGhostsForActiveWindow(generation: generation);
  }

  Future<void> addTransaction({
    required String merchant,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required String date,
    required String time,
  }) async {
    await _repository.addTransaction({
      'merchant': merchant,
      'amount': amount,
      'type': type.nativeValue,
      'transactionCategoryID': categoryId,
      'date': date,
      'time': time,
    });
    await _reload();
    _scheduleNotificationRefresh();
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
    final assignedName = userAssignedName ??
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
  ) async {
    DebugConsole.log(
      '[Transactions] rename ${transaction.merchant} -> $userAssignedName',
    );
    final count = await _repository.renameTransactionsByMerchant(
      transaction.merchant,
      userAssignedName,
    );
    await _reload();
    DebugConsole.log(
      '[Transactions] renamed $count rows for ${transaction.merchant}',
    );
    return count;
  }

  Future<int> resetTransactionNamesByMerchant(
    TransactionRecord transaction,
  ) async {
    DebugConsole.log('[Transactions] reset name ${transaction.merchant}');
    final count = await _repository.resetTransactionNamesByMerchant(
      transaction.merchant,
    );
    await _reload();
    DebugConsole.log(
      '[Transactions] reset $count rows for ${transaction.merchant}',
    );
    return count;
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
      if (_filter.categoryId == category.transactionCategoryID) {
        _filter = _filter.copyWith(clearCategory: true);
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

  Future<void> _projectRecurringGhostsForActiveWindow({int? generation}) async {
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
      _rebuildPublicViews();
      _invalidateViewCaches();
      _invalidateFastInfoMetrics();
      _prewarmCriticalCaches('recurring-ghosts');
      DebugConsole.log(
        '[Recurring] projected ${visibleGhostTransactions.length} ghosts for $periodKey',
      );
      notifyListeners();
    } finally {
      if ((generation == null || generation == _summaryChangeGeneration) &&
          _ghostProjectionInFlight) {
        _ghostProjectionInFlight = false;
        _invalidateViewCaches();
        notifyListeners();
      }
    }
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

  Future<void> _reload() async {
    final payload = await _repository.loadBootstrap();
    _categories = payload.categories;
    _transactions = _sort(payload.transactions);
    _replaceRecurringGhostTransactions(payload.recurringGhostTransactions);
    _limits = payload.limits;
    _rebuildPublicViews();
    _rebuildDerivedIndexes();
    _invalidateViewCaches();
    _invalidateFastInfoMetrics();
    _prewarmCriticalCaches('reload');
    notifyListeners();
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
    if (_ghostProjectionInFlight && _stableGhostPeriodKey != null) {
      return _stableGhostPeriodKey;
    }
    return _activeMonthlyPeriodKey;
  }

  void _replaceRecurringGhostTransactions(
    List<RecurringGhostRecord> records, {
    String? stablePeriodKey,
  }) {
    final sorted = _sortGhosts(records);
    _recurringGhostTransactions = sorted;
    _stableRecurringGhostTransactions = sorted;
    _stableGhostPeriodKey = stablePeriodKey ?? _stablePeriodKeyFor(sorted);
    _ghostProjectionInFlight = false;
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
    _recurringGhostTransactionsView = List<RecurringGhostRecord>.unmodifiable(
      _recurringGhostTransactions,
    );
    _limitsView = List<CategoryLimit>.unmodifiable(_limits);
  }

  void _rebuildDerivedIndexes() {
    _categoriesById = Map.unmodifiable({
      for (final category in _categories)
        category.transactionCategoryID: category,
    });
    final counts = <int, int>{};
    for (final transaction in _transactions) {
      final categoryId = transaction.transactionCategoryID;
      if (categoryId == null) continue;
      counts.update(categoryId, (value) => value + 1, ifAbsent: () => 1);
    }
    _categoryTransactionCounts = Map.unmodifiable(counts);
  }

  bool _ghostIsBeforeCurrentMonth(RecurringGhostRecord ghost) {
    final ghostDate = DateTime.tryParse(ghost.normalizedDate);
    if (ghostDate == null) return false;
    return DateTime(
      ghostDate.year,
      ghostDate.month,
    ).isBefore(_monthStart(_clock()));
  }

  bool _ghostInActiveWindow(
    RecurringGhostRecord ghost, {
    String? periodKey,
  }) {
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

int _compareLogEntries(TransactionLogEntry left, TransactionLogEntry right) {
  final date = right.date.compareTo(left.date);
  if (date != 0) return date;
  final time = right.time.compareTo(left.time);
  if (time != 0) return time;
  return right.sortId.compareTo(left.sortId);
}

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
