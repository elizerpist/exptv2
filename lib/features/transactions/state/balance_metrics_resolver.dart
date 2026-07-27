import 'dart:math' as math;

import '../data/fast_info_period_aggregates.dart';
import '../data/limit_manager.dart';
import '../models/category_limit.dart';
import '../models/fast_info_metric_snapshot.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import 'balance_amount_formatter.dart';
import 'fast_info_metrics_resolver.dart';

enum BalanceMetricInsightKind {
  noSpend,
  categoryChange,
  latestTransaction,
  trendComparison,
  upcomingRecurring,
}

enum BalanceMetricBudgetPeriod { day, week, month }

enum BalanceMetricCategoryPeriod { day, week, month, year }

enum BalanceMetricMerchantPeriod { year, month, allTime }

class BalanceMetricInsight {
  const BalanceMetricInsight({
    required this.kind,
    required this.title,
    required this.primaryText,
    required this.secondaryText,
    required this.sourceMetric,
    this.numericValue,
    this.comparisonValue,
    this.direction,
    this.category,
    this.record,
    this.ghost,
  });

  final BalanceMetricInsightKind kind;
  final String title;
  final String primaryText;
  final String secondaryText;
  final FastInfoMetricResult sourceMetric;
  final double? numericValue;
  final double? comparisonValue;
  final String? direction;
  final TransactionCategory? category;
  final TransactionRecord? record;
  final RecurringGhostRecord? ghost;
}

class BalanceMetricVariableBudget {
  const BalanceMetricVariableBudget({
    required this.period,
    required this.label,
    required this.spent,
    required this.budget,
    required this.remaining,
    required this.transactionCount,
    required this.progress,
    required this.referenceAmount,
  });

  final BalanceMetricBudgetPeriod period;
  final String label;
  final double spent;
  final double budget;
  final double remaining;
  final int transactionCount;
  final double progress;
  final double referenceAmount;
}

class BalanceMetricCategoryRank {
  const BalanceMetricCategoryRank({
    required this.period,
    required this.category,
    required this.amount,
    required this.transactionCount,
  });

  final BalanceMetricCategoryPeriod period;
  final TransactionCategory? category;
  final double amount;
  final int transactionCount;
}

class BalanceMetricMerchantRank {
  const BalanceMetricMerchantRank({
    required this.period,
    required this.rank,
    required this.name,
    required this.amount,
    required this.transactionCount,
    this.category,
  });

  final BalanceMetricMerchantPeriod period;
  final int rank;
  final String name;
  final double amount;
  final int transactionCount;
  final TransactionCategory? category;
}

class BalanceMetricAverageDaily {
  BalanceMetricAverageDaily({
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

class BalanceMetricBundle {
  BalanceMetricBundle({
    required Map<String, FastInfoMetricResult> fastInfoMetrics,
    required Map<BalanceMetricInsightKind, BalanceMetricInsight> insights,
    required Map<BalanceMetricBudgetPeriod, BalanceMetricVariableBudget>
    variableBudgets,
    required Map<BalanceMetricCategoryPeriod, BalanceMetricCategoryRank?>
    topCategories,
    required Map<BalanceMetricMerchantPeriod, List<BalanceMetricMerchantRank>>
    topMerchants,
    required this.averageDaily,
  }) : fastInfoMetrics = Map.unmodifiable(fastInfoMetrics),
       insights = Map.unmodifiable(insights),
       variableBudgets = Map.unmodifiable(variableBudgets),
       topCategories = Map.unmodifiable(topCategories),
       topMerchants = Map.unmodifiable({
         for (final entry in topMerchants.entries)
           entry.key: List<BalanceMetricMerchantRank>.unmodifiable(entry.value),
       });

  final Map<String, FastInfoMetricResult> fastInfoMetrics;
  final Map<BalanceMetricInsightKind, BalanceMetricInsight> insights;
  final Map<BalanceMetricBudgetPeriod, BalanceMetricVariableBudget>
  variableBudgets;
  final Map<BalanceMetricCategoryPeriod, BalanceMetricCategoryRank?>
  topCategories;
  final Map<BalanceMetricMerchantPeriod, List<BalanceMetricMerchantRank>>
  topMerchants;
  final BalanceMetricAverageDaily averageDaily;
}

/// Typed B3M extensions over the canonical FastInfo aggregate/resolver layer.
///
/// The widgets consume the resulting immutable bundle; period arithmetic,
/// ranking, ghost materialization, budgets and chart series remain here.
class BalanceMetricsResolver {
  const BalanceMetricsResolver._();

  static BalanceMetricBundle resolve(
    FastInfoMetricSnapshot snapshot, {
    List<RecurringGhostRecord> includedGhosts = const <RecurringGhostRecord>[],
  }) {
    final effectiveTransactions = <TransactionRecord>[
      ...snapshot.transactions,
      for (final ghost in includedGhosts) _materializeGhost(ghost),
    ];
    final effectiveSnapshot = FastInfoMetricSnapshot(
      now: snapshot.now,
      balance: effectiveTransactions.fold<double>(
        0,
        (sum, record) => sum + record.amount,
      ),
      savingGoal: snapshot.savingGoal,
      transactions: effectiveTransactions,
      categories: snapshot.categories,
      limits: snapshot.limits,
      recurringGhosts: includedGhosts,
    );
    final aggregates = FastInfoPeriodAggregates(snapshot: effectiveSnapshot);
    final fastInfoMetrics = FastInfoMetricsResolver.resolve(effectiveSnapshot);
    final scope = _BalanceMetricScope(
      snapshot: snapshot,
      includedGhosts: includedGhosts,
      data: aggregates,
      fastInfoMetrics: fastInfoMetrics,
    );
    final insights = scope.buildInsights();
    final balanceFastInfoMetrics = <String, FastInfoMetricResult>{
      ...fastInfoMetrics,
      'no_spend_napok_szama':
          insights[BalanceMetricInsightKind.noSpend]!.sourceMetric,
      'legnagyobb_novekedo_kategoria':
          insights[BalanceMetricInsightKind.categoryChange]!.sourceMetric,
      'legutobbi_tranzakcio':
          insights[BalanceMetricInsightKind.latestTransaction]!.sourceMetric,
      'koltesi_trend':
          insights[BalanceMetricInsightKind.trendComparison]!.sourceMetric,
      'kovetkezo_ismetlo_kiadas':
          insights[BalanceMetricInsightKind.upcomingRecurring]!.sourceMetric,
    };
    return BalanceMetricBundle(
      fastInfoMetrics: balanceFastInfoMetrics,
      insights: insights,
      variableBudgets: scope.buildVariableBudgets(),
      topCategories: scope.buildTopCategories(),
      topMerchants: scope.buildTopMerchants(),
      averageDaily: scope.buildAverageDaily(),
    );
  }
}

class _BalanceMetricScope {
  const _BalanceMetricScope({
    required this.snapshot,
    required this.includedGhosts,
    required this.data,
    required this.fastInfoMetrics,
  });

  final FastInfoMetricSnapshot snapshot;
  final List<RecurringGhostRecord> includedGhosts;
  final FastInfoPeriodAggregates data;
  final Map<String, FastInfoMetricResult> fastInfoMetrics;

  FastInfoMetricResult metric(String id) =>
      fastInfoMetrics[id] ??
      const FastInfoMetricResult(
        pillValue: 'Nincs adat',
        primaryValue: 'Nincs adat',
      );

  Map<BalanceMetricInsightKind, BalanceMetricInsight> buildInsights() {
    final noSpendMetric = metric('no_spend_napok_szama');
    final noSpendValues = noSpendMetric.visual.values;
    final noSpendDays = noSpendValues.where((value) => value > 0).length;

    final currentRows = data.variableExpenseRowsBetween(
      data.rolling30Start,
      data.tomorrow,
    );
    final previousRows = data.variableExpenseRowsBetween(
      data.previousRolling30Start,
      data.rolling30Start,
    );
    final currentByCategory = _categoryAmounts(currentRows);
    final previousByCategory = _categoryAmounts(previousRows);
    final rankedCategoryIds =
        <int>{
          ...currentByCategory.keys,
          ...previousByCategory.keys,
        }.toList()..sort((left, right) {
          final leftDelta =
              (currentByCategory[left] ?? 0) - (previousByCategory[left] ?? 0);
          final rightDelta =
              (currentByCategory[right] ?? 0) -
              (previousByCategory[right] ?? 0);
          final byChange = rightDelta.abs().compareTo(leftDelta.abs());
          if (byChange != 0) return byChange;
          final byCurrent = (currentByCategory[right] ?? 0).compareTo(
            currentByCategory[left] ?? 0,
          );
          if (byCurrent != 0) return byCurrent;
          return _categoryName(left).compareTo(_categoryName(right));
        });
    final changedCategoryId = rankedCategoryIds.firstOrNull;
    final changedDelta = changedCategoryId == null
        ? 0.0
        : (currentByCategory[changedCategoryId] ?? 0) -
              (previousByCategory[changedCategoryId] ?? 0);

    final latestRows = <_LatestRow>[
      for (final record in snapshot.transactions) _LatestRow.record(record),
      for (final ghost in includedGhosts)
        if (_isDueOnOrBefore(ghost, data.today)) _LatestRow.ghost(ghost),
    ]..sort(_compareLatestRows);
    final latest = latestRows.firstOrNull;

    final currentTotal = data.rolling30VariableExpense;
    final previousTotal = data.previousRolling30VariableExpense;
    final relative = previousTotal <= 0
        ? 0.0
        : (currentTotal - previousTotal) / previousTotal;

    final upcoming =
        includedGhosts.where((ghost) {
          final date = _parseDate(ghost.normalizedDate);
          return ghost.type == TransactionType.expense &&
              date != null &&
              !date.isBefore(data.today);
        }).toList()..sort((left, right) {
          final byDate = (_parseDate(left.normalizedDate) ?? data.today)
              .compareTo(_parseDate(right.normalizedDate) ?? data.today);
          if (byDate != 0) return byDate;
          final byTime = left.time.compareTo(right.time);
          if (byTime != 0) return byTime;
          return left.id.compareTo(right.id);
        });
    final nextGhost = upcoming.firstOrNull;
    final noSpendPrimary = '$noSpendDays / 7 nap';
    final categoryChangePrimary = _signedHuf(changedDelta);
    final latestPrimary = latest?.balanceDisplayAmount ?? 'Nincs adat';
    final trendPrimary = '${(relative.abs() * 100).round()}%';
    final upcomingPrimary = nextGhost == null
        ? 'Nincs adat'
        : formatBalanceCatalogForint(-nextGhost.amount.abs());

    return <BalanceMetricInsightKind, BalanceMetricInsight>{
      BalanceMetricInsightKind.noSpend: BalanceMetricInsight(
        kind: BalanceMetricInsightKind.noSpend,
        title: 'No-spend napok',
        primaryText: noSpendPrimary,
        secondaryText: 'Elmúlt 7 nap',
        numericValue: noSpendDays.toDouble(),
        sourceMetric: _withExactPrimary(noSpendMetric, noSpendPrimary),
      ),
      BalanceMetricInsightKind.categoryChange: BalanceMetricInsight(
        kind: BalanceMetricInsightKind.categoryChange,
        title: 'Legnagyobb kategóriaváltozás',
        primaryText: categoryChangePrimary,
        secondaryText: 'előző 30 naphoz képest',
        numericValue: changedDelta,
        comparisonValue: previousByCategory[changedCategoryId] ?? 0,
        category: data.categoriesById[changedCategoryId],
        sourceMetric: _withExactPrimary(
          metric('legnagyobb_novekedo_kategoria'),
          categoryChangePrimary,
        ),
      ),
      BalanceMetricInsightKind.latestTransaction: BalanceMetricInsight(
        kind: BalanceMetricInsightKind.latestTransaction,
        title: 'Utolsó tranzakció',
        primaryText: latestPrimary,
        secondaryText: latest == null
            ? 'Nincs tranzakció'
            : '${latest.merchant} · ${latest.relativeTime(data.today)}',
        numericValue: latest?.amount,
        category: data.categoriesById[latest?.categoryId],
        record: latest?.record,
        ghost: latest?.ghost,
        sourceMetric: _withExactPrimary(
          metric('legutobbi_tranzakcio'),
          latestPrimary,
        ),
      ),
      BalanceMetricInsightKind.trendComparison: BalanceMetricInsight(
        kind: BalanceMetricInsightKind.trendComparison,
        title: '30 napos ritmus',
        primaryText: trendPrimary,
        secondaryText: 'Ezt megelőző 30 naphoz képest',
        numericValue: currentTotal,
        comparisonValue: previousTotal,
        direction: relative > 0
            ? 'up'
            : relative < 0
            ? 'down'
            : 'flat',
        sourceMetric: _withExactPrimary(metric('koltesi_trend'), trendPrimary),
      ),
      BalanceMetricInsightKind.upcomingRecurring: BalanceMetricInsight(
        kind: BalanceMetricInsightKind.upcomingRecurring,
        title: 'Közelgő ismétlődés',
        primaryText: upcomingPrimary,
        secondaryText: nextGhost?.date ?? 'Nincs közelgő tétel',
        numericValue: nextGhost?.amount,
        category: data.categoriesById[nextGhost?.categoryId],
        ghost: nextGhost,
        sourceMetric: _withExactPrimary(
          metric('kovetkezo_ismetlo_kiadas'),
          upcomingPrimary,
        ),
      ),
    };
  }

  FastInfoMetricResult _withExactPrimary(
    FastInfoMetricResult source,
    String primary,
  ) {
    return FastInfoMetricResult(
      pillValue: primary,
      primaryValue: primary,
      secondaryValues: source.secondaryValues,
      progressKind: source.progressKind,
      chartKind: source.chartKind,
      semantic: source.semantic,
      progress: source.progress,
      trend: source.trend,
      avatar: source.avatar,
      visual: source.visual,
      chartSeries: source.chartSeries,
      weeklyBars: source.weeklyBars,
    );
  }

  Map<BalanceMetricBudgetPeriod, BalanceMetricVariableBudget>
  buildVariableBudgets() {
    final monthlyLimit = _monthlyLimit();
    final spentBeforeToday = data.currentMonthVariableExpenseBeforeToday;
    final dailyBudget = monthlyLimit <= 0
        ? 0.0
        : math.max(0, monthlyLimit - spentBeforeToday) /
              data.remainingMonthDaysIncludingToday;
    final weeklyBudget = monthlyLimit <= 0 ? 0.0 : monthlyLimit / 4.345;
    final referenceAmount = data.rolling30VariableExpense / 30;

    BalanceMetricVariableBudget build(
      BalanceMetricBudgetPeriod period,
      String label,
      DateTime start,
      double budget,
    ) {
      final spent = data.variableExpenseBetween(start, data.tomorrow);
      final count = data.expenseRowsBetween(start, data.tomorrow).length;
      return BalanceMetricVariableBudget(
        period: period,
        label: label,
        spent: spent,
        budget: budget,
        remaining: math.max(0, budget - spent),
        transactionCount: count,
        progress: budget <= 0 ? 0 : spent / budget,
        referenceAmount: referenceAmount,
      );
    }

    return <BalanceMetricBudgetPeriod, BalanceMetricVariableBudget>{
      BalanceMetricBudgetPeriod.day: build(
        BalanceMetricBudgetPeriod.day,
        'Napi',
        data.today,
        dailyBudget,
      ),
      BalanceMetricBudgetPeriod.week: build(
        BalanceMetricBudgetPeriod.week,
        'Heti',
        data.weekStart,
        weeklyBudget,
      ),
      BalanceMetricBudgetPeriod.month: build(
        BalanceMetricBudgetPeriod.month,
        'Havi',
        data.currentMonthStart,
        monthlyLimit,
      ),
    };
  }

  Map<BalanceMetricCategoryPeriod, BalanceMetricCategoryRank?>
  buildTopCategories() {
    final ranges = <BalanceMetricCategoryPeriod, DateTime>{
      BalanceMetricCategoryPeriod.day: data.today,
      BalanceMetricCategoryPeriod.week: data.weekStart,
      BalanceMetricCategoryPeriod.month: data.currentMonthStart,
      BalanceMetricCategoryPeriod.year: DateTime(data.today.year),
    };
    return <BalanceMetricCategoryPeriod, BalanceMetricCategoryRank?>{
      for (final entry in ranges.entries)
        entry.key: _topCategory(
          entry.key,
          data.variableExpenseRowsBetween(entry.value, data.tomorrow),
        ),
    };
  }

  Map<BalanceMetricMerchantPeriod, List<BalanceMetricMerchantRank>>
  buildTopMerchants() {
    final ranges = <BalanceMetricMerchantPeriod, DateTime?>{
      BalanceMetricMerchantPeriod.year: DateTime(data.today.year),
      BalanceMetricMerchantPeriod.month: data.currentMonthStart,
      BalanceMetricMerchantPeriod.allTime: null,
    };
    return <BalanceMetricMerchantPeriod, List<BalanceMetricMerchantRank>>{
      for (final entry in ranges.entries)
        entry.key: _rankMerchants(
          entry.key,
          entry.value == null
              ? data.variableExpenseRows
              : data.variableExpenseRowsBetween(entry.value!, data.tomorrow),
        ),
    };
  }

  BalanceMetricAverageDaily buildAverageDaily() {
    final source = metric('atlagos_napi_koltes');
    final series = source.series.length == 30
        ? List<double>.of(source.series)
        : List<double>.filled(30, 0);
    final total = series.fold<double>(0, (sum, value) => sum + value);
    final average = total / 30;
    final threshold = average * 1.5;
    return BalanceMetricAverageDaily(
      dailySeries: series,
      rollingTotal: total,
      average: average,
      bufferDays: average <= 0
          ? null
          : (math.max(0, data.snapshot.balance) / average).round(),
      highestDay: series.fold<double>(0, math.max),
      spikeThreshold: threshold,
      spikeDays: series.where((value) => value > threshold).length,
    );
  }

  BalanceMetricCategoryRank? _topCategory(
    BalanceMetricCategoryPeriod period,
    List<FastInfoDatedTransaction> rows,
  ) {
    final entries = data.categoryExpenseGroups(rows).entries.toList()
      ..sort((left, right) {
        final leftAmount = _sumRows(left.value);
        final rightAmount = _sumRows(right.value);
        final amount = rightAmount.compareTo(leftAmount);
        if (amount != 0) return amount;
        final count = right.value.length.compareTo(left.value.length);
        if (count != 0) return count;
        return _categoryName(left.key).compareTo(_categoryName(right.key));
      });
    if (entries.isEmpty) return null;
    final top = entries.first;
    return BalanceMetricCategoryRank(
      period: period,
      category: data.categoriesById[top.key],
      amount: _sumRows(top.value),
      transactionCount: top.value.length,
    );
  }

  List<BalanceMetricMerchantRank> _rankMerchants(
    BalanceMetricMerchantPeriod period,
    List<FastInfoDatedTransaction> rows,
  ) {
    final entries = data.merchantExpenseGroups(rows).entries.toList()
      ..sort((left, right) {
        final count = right.value.length.compareTo(left.value.length);
        if (count != 0) return count;
        final amount = _sumRows(right.value).compareTo(_sumRows(left.value));
        if (amount != 0) return amount;
        final freshness = _latestDate(
          right.value,
        ).compareTo(_latestDate(left.value));
        if (freshness != 0) return freshness;
        return left.key.compareTo(right.key);
      });
    final top = entries.take(5).toList();
    return <BalanceMetricMerchantRank>[
      for (var index = 0; index < top.length; index += 1)
        BalanceMetricMerchantRank(
          period: period,
          rank: index + 1,
          name: top[index].key,
          amount: _sumRows(top[index].value),
          transactionCount: top[index].value.length,
          category: _dominantMerchantCategory(top[index].value),
        ),
    ];
  }

  TransactionCategory? _dominantMerchantCategory(
    List<FastInfoDatedTransaction> rows,
  ) {
    final entries = data.categoryExpenseGroups(rows).entries.toList()
      ..sort((left, right) {
        final count = right.value.length.compareTo(left.value.length);
        if (count != 0) return count;
        final amount = _sumRows(right.value).compareTo(_sumRows(left.value));
        if (amount != 0) return amount;
        return _categoryName(left.key).compareTo(_categoryName(right.key));
      });
    return entries.isEmpty ? null : data.categoriesById[entries.first.key];
  }

  Map<int, double> _categoryAmounts(Iterable<FastInfoDatedTransaction> rows) {
    return <int, double>{
      for (final entry in data.categoryExpenseGroups(rows).entries)
        entry.key: _sumRows(entry.value),
    };
  }

  String _categoryName(int? id) =>
      data.categoriesById[id]?.name ?? 'Nincs kategória';

  double _monthlyLimit() {
    final limit = LimitManager.findLimit(
      limits: snapshot.limits,
      targetType: LimitTargetType.overview,
      targetId: 0,
      transactionType: TransactionType.expense.nativeValue,
      window: LimitWindow.monthly,
      periodKey:
          '${data.today.year}-${data.today.month.toString().padLeft(2, '0')}',
    );
    return limit?.hasLimit == true && limit!.limitAmount > 0
        ? limit.limitAmount
        : 0;
  }
}

class _LatestRow {
  const _LatestRow._({this.record, this.ghost});

  factory _LatestRow.record(TransactionRecord record) =>
      _LatestRow._(record: record);

  factory _LatestRow.ghost(RecurringGhostRecord ghost) =>
      _LatestRow._(ghost: ghost);

  final TransactionRecord? record;
  final RecurringGhostRecord? ghost;

  String get date => record?.normalizedDate ?? ghost!.normalizedDate;
  String get time => record?.displayTime ?? ghost?.displayTime ?? '';
  int get id => record?.id ?? ghost?.id ?? 0;
  String get merchant => record?.displayMerchant ?? ghost?.name ?? '';
  double get amount => record?.amount ?? ghost?.amount ?? 0;
  String get balanceDisplayAmount => formatBalanceCatalogForint(
    record?.amount ??
        (ghost!.type == TransactionType.income
            ? ghost!.amount.abs()
            : -ghost!.amount.abs()),
  );
  int? get categoryId => record?.transactionCategoryID ?? ghost?.categoryId;

  String relativeTime(DateTime today) {
    final parsed = _parseDate(date);
    if (parsed == null) return time;
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final difference = parsed.difference(normalizedToday).inDays;
    final day = switch (difference) {
      0 => 'ma',
      -1 => 'tegnap',
      1 => 'holnap',
      _ =>
        '${parsed.year}.'
            '${parsed.month.toString().padLeft(2, '0')}.'
            '${parsed.day.toString().padLeft(2, '0')}.',
    };
    return '$day, $time';
  }
}

TransactionRecord _materializeGhost(RecurringGhostRecord ghost) {
  return TransactionRecord(
    id: -1000000000 - ghost.id.abs(),
    date: ghost.date,
    time: ghost.time,
    latitude: null,
    longitude: null,
    address: null,
    merchant: ghost.name,
    amount: ghost.type == TransactionType.income
        ? ghost.amount.abs()
        : -ghost.amount.abs(),
    userAssignedName: null,
    transactionCategoryID: ghost.categoryId,
  );
}

int _compareLatestRows(_LatestRow left, _LatestRow right) {
  final byDate = right.date.compareTo(left.date);
  if (byDate != 0) return byDate;
  final byTime = right.time.compareTo(left.time);
  if (byTime != 0) return byTime;
  return right.id.compareTo(left.id);
}

DateTime _latestDate(List<FastInfoDatedTransaction> rows) {
  return rows
      .map((row) => row.date)
      .reduce((left, right) => left.isAfter(right) ? left : right);
}

double _sumRows(Iterable<FastInfoDatedTransaction> rows) =>
    rows.fold<double>(0, (sum, row) => sum + row.record.amount.abs());

String _signedHuf(double value) {
  return formatBalanceSignedForint(value);
}

DateTime? _parseDate(String raw) {
  final normalized = raw.trim().replaceAll('.', '-');
  final parts = normalized.split('-');
  if (parts.length < 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

bool _isDueOnOrBefore(RecurringGhostRecord ghost, DateTime date) {
  final ghostDate = _parseDate(ghost.normalizedDate);
  return ghostDate != null && !ghostDate.isAfter(date);
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
