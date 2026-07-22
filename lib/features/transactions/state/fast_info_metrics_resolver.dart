import 'dart:math' as math;

import '../../settings/models/fast_info_card_catalog.dart';
import '../data/fast_info_period_aggregates.dart';
import '../models/category_limit.dart';
import '../models/fast_info_metric.dart';
import '../models/fast_info_metric_snapshot.dart';
import '../models/recurring_ghost_record.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

export '../models/fast_info_metric.dart';

class FastInfoMetricsResolver {
  const FastInfoMetricsResolver._();

  static Set<String> get supportedMetricIds =>
      fastInfoCardCatalog.map((card) => card.id).toSet();

  static Map<String, FastInfoMetricResult> preview() =>
      resolve(_previewSnapshot);

  static Map<String, FastInfoMetricResult> resolve(
    FastInfoMetricSnapshot snapshot,
  ) {
    final scope = _FastInfoMetricScope(
      FastInfoPeriodAggregates(snapshot: snapshot),
    );
    return Map.unmodifiable({
      for (final card in fastInfoCardCatalog)
        card.id: scope.safeMetricFor(card.id),
    });
  }
}

class _FastInfoMetricScope {
  const _FastInfoMetricScope(this.data);

  final FastInfoPeriodAggregates data;

  FastInfoMetricSnapshot get snapshot => data.snapshot;
  String get monthKey => _periodKey(data.today);

  double? get monthlyLimit {
    for (final limit in snapshot.limits) {
      if (limit.targetType == LimitTargetType.overview &&
          limit.window == LimitWindow.monthly &&
          limit.periodKey == monthKey &&
          limit.hasLimit &&
          limit.limitAmount > 0 &&
          TransactionTypeX.fromAny(limit.transactionType) ==
              TransactionType.expense) {
        return limit.limitAmount;
      }
    }
    return null;
  }

  double get dailyCeiling {
    final limit = monthlyLimit;
    if (limit == null) return 0.0;
    return math.max(0, limit - data.currentMonthVariableExpenseBeforeToday) /
        data.remainingMonthDaysIncludingToday;
  }

  double get weeklyAllowance =>
      monthlyLimit == null ? 0.0 : monthlyLimit! / 4.345;
  double get actualSavings =>
      math.max(0, data.currentMonthIncome - data.currentMonthExpense);
  double get projectedMonthExpense => data.elapsedMonthDays == 0
      ? 0.0
      : data.currentMonthExpense /
            data.elapsedMonthDays *
            data.daysInCurrentMonth;
  double get rollingDailyAverage => data.rolling30VariableExpense / 30;

  FastInfoMetricResult safeMetricFor(String id) {
    try {
      return metricFor(id);
    } on Object {
      return _noData('Nincs adat');
    }
  }

  FastInfoMetricResult metricFor(String id) {
    return switch (id) {
      'mai_koltes' => _todaySpend(),
      'heti_koltes' => _weeklySpend(),
      'havi_koltes' => _monthlySpend(),
      'megtakaritas' => _savings(),
      'koltesi_trend' => _rollingSpendTrend(),
      'legutobbi_tranzakcio' => _latestTransaction(),
      'varhato_ho_vegi_koltes' => _forecast(),
      'leggyorsabban_fogyo_kategorialimit' => _categoryLimitState(),
      'leggyakoribb_kereskedo' => _topMerchant(),
      'atlagos_napi_koltes' => _averageDailySpend(),
      'no_spend_napok_szama' => _noSpendDays(),
      'top_kategoria_heten' => _topCategoryWeekMonth(),
      'legnagyobb_novekedo_kategoria' => _largestCategoryChange(),
      'kovetkezo_ismetlo_kiadas' => _nextRecurringExpense(),
      'havi_fix_koltseg_osszesen' => _monthlyFixedCosts(),
      'kiadas_bevetel_arany' => _expenseIncomeRatio(),
      _ => const FastInfoMetricResult(
        pillValue: 'Nincs adat',
        primaryValue: 'Nincs adat',
      ),
    };
  }

  FastInfoMetricResult _todaySpend() {
    final ceiling = dailyCeiling;
    final variableToday = data.todayVariableExpense;
    final progress = ceiling > 0 ? variableToday / ceiling : null;
    final count = data.expenseRowsBetween(data.today, data.tomorrow).length;
    final secondary = <String>[
      '$count tranzakció ma',
      if (progress != null)
        '${formatHuf(math.max(0, ceiling - variableToday))} költhető',
      if (rollingDailyAverage > 0)
        'napi átlaghoz képest:'
      else
        'Nincs összehasonlítás',
    ];
    return FastInfoMetricResult(
      pillValue: _compactAmount(data.todayExpense),
      primaryValue: '${formatHuf(data.todayExpense)} elköltve',
      secondaryValues: secondary,
      progressKind: progress == null ? null : FastInfoProgressKind.bar,
      progress: progress,
      semantic: progress == null
          ? FastInfoSemantic.neutral
          : expenseSemantic(progress),
      trend: expenseTrend(variableToday, rollingDailyAverage),
      visual: progress == null
          ? FastInfoVisualDescriptor.none
          : FastInfoVisualDescriptor(
              kind: FastInfoVisualKind.thresholdMarkerBar,
              value: progress,
              marker: ceiling > 0 ? rollingDailyAverage / ceiling : null,
              semantic: expenseSemantic(progress),
            ),
    );
  }

  FastInfoMetricResult _weeklySpend() {
    final dailyAllowance = weeklyAllowance > 0 ? weeklyAllowance / 7 : null;
    final count = data.expenseRowsBetween(data.weekStart, data.tomorrow).length;
    final bars = <FastInfoWeeklyBar>[
      for (final bar in data.currentWeekBars)
        FastInfoWeeklyBar(
          value: bar.value,
          isFuture: bar.isFuture,
          semantic: bar.isFuture || dailyAllowance == null
              ? FastInfoSemantic.neutral
              : expenseSemantic(bar.value / dailyAllowance),
        ),
    ];
    return FastInfoMetricResult(
      pillValue: _compactAmount(data.currentWeekExpense),
      primaryValue: formatHuf(data.currentWeekExpense),
      secondaryValues: <String>[
        '$count tranzakció',
        if (monthlyLimit != null)
          '${formatHuf(math.max(0, weeklyAllowance - data.currentWeekVariableExpense))} költhető',
        if (monthlyLimit != null) _weeklyPaceLabel(),
        if (data.previousWeekSameDayVariableExpense <= 0)
          'Nincs összehasonlítás',
      ],
      chartKind: FastInfoChartKind.weeklyBars,
      weeklyBars: bars,
      trend: expenseTrend(
        data.currentWeekVariableExpense,
        data.previousWeekSameDayVariableExpense,
      ),
      visual: monthlyLimit == null
          ? FastInfoVisualDescriptor.none
          : FastInfoVisualDescriptor(
              kind: FastInfoVisualKind.deviationMeter,
              value: _weeklyPacePoints() / 100,
              semantic: _weeklyPacePoints() > 0
                  ? FastInfoSemantic.bad
                  : FastInfoSemantic.good,
              values: [for (final bar in bars) bar.value],
            ),
    );
  }

  FastInfoMetricResult _monthlySpend() {
    final limit = monthlyLimit;
    final progress = limit == null
        ? null
        : data.currentMonthVariableExpense / limit;
    final monthIndex = data.previousMonthSameDayVariableExpense > 0
        ? data.currentMonthVariableExpense /
              data.previousMonthSameDayVariableExpense
        : null;
    return FastInfoMetricResult(
      pillValue: _compactAmount(data.currentMonthExpense),
      primaryValue: formatHuf(data.currentMonthExpense),
      secondaryValues: <String>[
        if (progress != null) '${_percent(progress)}% a havi keretből',
        if (monthIndex != null)
          'előző hónap index: ${_percent(monthIndex)}%'
        else
          'Nincs összehasonlítás',
        if (limit != null)
          '${formatHuf(math.max(0, limit - data.currentMonthVariableExpense))} költhető',
      ],
      progressKind: progress == null ? null : FastInfoProgressKind.bar,
      progress: progress,
      semantic: progress == null
          ? FastInfoSemantic.neutral
          : expenseSemantic(progress),
      trend: expenseTrend(
        data.currentMonthVariableExpense,
        data.previousMonthSameDayVariableExpense,
      ),
      chartKind: FastInfoChartKind.multiLine,
      chartSeries: <FastInfoChartSeries>[
        FastInfoChartSeries(
          label: 'Aktuális',
          values: data.currentMonthVariableDailySeries
              .take(data.today.day)
              .toList(),
        ),
        FastInfoChartSeries(
          label: 'Előző',
          values: data.previousMonthDailySeries,
        ),
        FastInfoChartSeries(
          label: 'Két hónapja',
          values: data.twoMonthsAgoDailySeries,
        ),
      ],
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.sameDayIndexMarker,
        value: monthIndex,
        compareValue: progress,
        semantic: monthIndex == null
            ? FastInfoSemantic.neutral
            : expenseSemantic(monthIndex),
      ),
    );
  }

  FastInfoMetricResult _savings() {
    final goal = snapshot.savingGoal;
    final progress = goal != null && goal > 0 ? actualSavings / goal : null;
    final projectedSavings = math.max(
      0.0,
      data.currentMonthExpectedIncome - projectedMonthExpense,
    );
    final projectedProgress = goal != null && goal > 0
        ? projectedSavings / goal
        : null;
    final rate = data.currentMonthIncome > 0
        ? actualSavings / data.currentMonthIncome
        : null;
    return FastInfoMetricResult(
      pillValue: _compactAmount(actualSavings),
      primaryValue: formatHuf(actualSavings),
      secondaryValues: <String>[
        'bevétel - kiadás hóban',
        if (goal == null || goal <= 0)
          'Nincs cél'
        else
          'cél: ${formatHuf(goal)}',
        if (projectedProgress != null)
          'várható cél: ${_percent(projectedProgress)}%',
        if (rate != null) 'Megtakarítási ráta: ${_percent(rate)}%',
      ],
      progressKind: progress == null ? null : FastInfoProgressKind.ring,
      progress: progress,
      semantic: progress == null
          ? FastInfoSemantic.neutral
          : progress >= 1
          ? FastInfoSemantic.good
          : progress >= .75
          ? FastInfoSemantic.warning
          : FastInfoSemantic.neutral,
      visual: progress == null
          ? FastInfoVisualDescriptor.none
          : FastInfoVisualDescriptor(
              kind: FastInfoVisualKind.goalMarker,
              value: progress,
              marker: projectedProgress,
              semantic: progress >= 1
                  ? FastInfoSemantic.good
                  : progress >= .75
                  ? FastInfoSemantic.warning
                  : FastInfoSemantic.neutral,
            ),
    );
  }

  FastInfoMetricResult _rollingSpendTrend() {
    final current = data.rolling30VariableExpense;
    final previous = data.previousRolling30VariableExpense;
    final index = previous > 0 ? current / previous : null;
    final trend = expenseTrend(current, previous);
    return FastInfoMetricResult(
      pillValue: _compactAmount(current),
      primaryValue: formatHuf(current),
      secondaryValues: <String>[
        'előző 30 nap: ${formatHuf(previous)}',
        if (trend != null) 'előző 30 naphoz ${trend.text}',
        'fix tételek nélkül',
        if (previous <= 0) 'Nincs összehasonlítás',
      ],
      trend: trend,
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.zoneMarker,
        value: index,
        semantic: index == null
            ? FastInfoSemantic.neutral
            : expenseSemantic(index),
      ),
    );
  }

  FastInfoMetricResult _latestTransaction() {
    if (data.datedTransactions.isEmpty) return _noData('Nincs tranzakció');
    final row = data.datedTransactions.first;
    final category = data.categoriesById[row.record.transactionCategoryID];
    final merchant = row.record.displayMerchant.isEmpty
        ? 'Névtelen tranzakció'
        : row.record.displayMerchant;
    final categoryName = category?.name ?? 'Nincs kategória';
    return FastInfoMetricResult(
      pillValue: _signedCompact(row.record.amount),
      primaryValue: row.record.displayAmount,
      secondaryValues: <String>[
        '$merchant · $categoryName',
        _latestTimeLabel(row),
      ],
      avatar: avatarForCategory(category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.avatar,
        avatar: avatarForCategory(category),
      ),
    );
  }

  FastInfoMetricResult _forecast() {
    final activatedFixed = _sum(
      data
          .expenseRowsBetween(data.currentMonthStart, data.tomorrow)
          .where((row) => row.record.isRecurringGenerated),
    );
    final pendingFixed = data
        .recurringGhostsBetween(
          data.currentMonthStart,
          data.nextMonthStart,
          expensesOnly: true,
          pendingOnly: true,
        )
        .fold<double>(0, (sum, row) => sum + row.record.amount.abs());
    final monthlyFixed = activatedFixed + pendingFixed;
    final projectedVariable = data.elapsedMonthDays == 0
        ? 0.0
        : data.currentMonthVariableExpense /
              data.elapsedMonthDays *
              data.daysInCurrentMonth;
    final projectedExpense = projectedVariable + monthlyFixed;
    final forecast = <double>[
      for (var index = 6; index >= 0; index -= 1)
        _forecastEstimateForDay(
          data.today.subtract(Duration(days: index)),
          monthlyFixed,
        ),
    ];
    final limit = monthlyLimit;
    final ratio = limit == null ? null : projectedExpense / limit;
    final optimistic = projectedExpense * .9;
    final pessimistic = projectedExpense * 1.08;
    return FastInfoMetricResult(
      pillValue: _compactAmount(projectedExpense),
      primaryValue: formatHuf(projectedExpense),
      secondaryValues: <String>[
        if (ratio != null) 'havi keret ${_percent(ratio)}%',
        'sáv ${_compactAmount(optimistic)}-${_compactAmount(pessimistic)}',
      ],
      semantic: ratio == null
          ? FastInfoSemantic.neutral
          : expenseSemantic(ratio),
      chartKind: FastInfoChartKind.sparkline,
      chartSeries: <FastInfoChartSeries>[
        FastInfoChartSeries(label: 'Elmúlt 7 nap', values: forecast),
      ],
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.projectionFill,
        value: ratio,
        values: forecast,
        semantic: ratio == null
            ? FastInfoSemantic.neutral
            : expenseSemantic(ratio),
      ),
    );
  }

  double _forecastEstimateForDay(DateTime day, double monthlyFixed) {
    if (day.isBefore(data.currentMonthStart)) return monthlyFixed;
    final cappedDay = day.isAfter(data.today) ? data.today : day;
    final elapsedDays = math.max(1, cappedDay.day);
    final variableUntilDay = data.variableExpenseBetween(
      data.currentMonthStart,
      cappedDay.add(const Duration(days: 1)),
    );
    return variableUntilDay / elapsedDays * data.daysInCurrentMonth +
        monthlyFixed;
  }

  FastInfoMetricResult _categoryLimitState() {
    final states = _categoryLimitStates();
    if (states.isEmpty) return _noData('Nincs kategórialimit');
    states.sort((a, b) {
      final byRatio = b.ratio.compareTo(a.ratio);
      if (byRatio != 0) return byRatio;
      return a.name.compareTo(b.name);
    });
    final top = states.first;
    final near = states
        .where((state) => state.ratio >= .75 && state.ratio <= 1)
        .length;
    final over = states.where((state) => state.ratio > 1).length;
    final elapsedShare = data.daysInCurrentMonth <= 0
        ? 1.0
        : data.elapsedMonthDays / data.daysInCurrentMonth;
    final projectedRatio = elapsedShare <= 0
        ? top.ratio
        : top.ratio / elapsedShare;
    return FastInfoMetricResult(
      pillValue: 'várható ${_percent(projectedRatio)}%',
      primaryValue: top.name,
      secondaryValues: <String>[
        '${formatHuf(top.spent)} / ${formatHuf(top.limit)}',
        '${formatHuf(math.max(0, top.limit - top.spent))} maradt',
        'várható ${_percent(projectedRatio)}%',
        '${top.name} hó végére',
        'Közel: $near · felett: $over',
      ],
      progressKind: FastInfoProgressKind.bar,
      progress: top.ratio,
      semantic: expenseSemantic(top.ratio),
      avatar: avatarForCategory(top.category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.overflowRisk,
        value: projectedRatio,
        compareValue: top.ratio,
        semantic: expenseSemantic(projectedRatio),
        avatar: avatarForCategory(top.category),
      ),
    );
  }

  FastInfoMetricResult _topMerchant() {
    final entries = data
        .merchantExpenseGroups(data.variableExpenseRows)
        .entries
        .toList();
    if (entries.isEmpty) return _noData('Nincs kereskedő');
    entries.sort((a, b) {
      final byCount = b.value.length.compareTo(a.value.length);
      if (byCount != 0) return byCount;
      final byAmount = _sum(b.value).compareTo(_sum(a.value));
      if (byAmount != 0) return byAmount;
      final byFreshness = _latestDate(b.value).compareTo(_latestDate(a.value));
      if (byFreshness != 0) return byFreshness;
      return a.key.compareTo(b.key);
    });
    final top = entries.first;
    final activity = _merchantActivityPoints(top.value);
    final activeDays = activity.where((point) => point.value > 0).length;
    return FastInfoMetricResult(
      pillValue: '${_shortText(top.key)} ${top.value.length}x',
      primaryValue: top.key,
      secondaryValues: <String>[
        'legtöbb tranzakció',
        '${top.value.length} alkalom',
        formatHuf(_sum(top.value)),
        '$activeDays aktív nap',
        _mostFrequentCategoryName(top.value),
      ],
      avatar: _mostFrequentCategoryAvatar(top.value),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.activityStrip,
        value: top.value.length.toDouble(),
        avatar: _mostFrequentCategoryAvatar(top.value),
        points: activity,
      ),
    );
  }

  FastInfoMetricResult _averageDailySpend() {
    final average = rollingDailyAverage;
    final series = data.rolling30VariableDailySeries;
    final bufferDays = average > 0
        ? (math.max(0, snapshot.balance) / average).round()
        : null;
    final spikeCount = _spikeCount(series, average);
    return FastInfoMetricResult(
      pillValue: formatHuf(average),
      primaryValue: formatHuf(average),
      secondaryValues: <String>[
        'elmúlt 30 nap átlaga',
        if (bufferDays != null) 'Puffer: $bufferDays nap',
        '$spikeCount kiugró nap húzza',
        'fixek nélkül',
      ],
      chartKind: FastInfoChartKind.sparkline,
      chartSeries: <FastInfoChartSeries>[
        FastInfoChartSeries(label: '30 nap', values: series),
      ],
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.spikeLine,
        values: series,
      ),
    );
  }

  FastInfoMetricResult _noSpendDays() {
    const weekDays = 7;
    final weekStart = data.today.subtract(const Duration(days: weekDays - 1));
    var weekCount = 0;
    final weekValues = <double>[];
    for (var index = 0; index < weekDays; index += 1) {
      final date = weekStart.add(Duration(days: index));
      final noSpend = data.variableExpenseOn(date) == 0;
      if (noSpend) weekCount += 1;
      weekValues.add(noSpend ? 1 : 0);
    }

    final monthPoints = <FastInfoVisualPoint>[];
    var monthCount = 0;
    for (var day = 1; day <= data.daysInCurrentMonth; day += 1) {
      final date = DateTime(data.today.year, data.today.month, day);
      final isFuture = date.isAfter(data.today);
      final noSpend = !isFuture && data.variableExpenseOn(date) == 0;
      if (noSpend) monthCount += 1;
      monthPoints.add(
        FastInfoVisualPoint(
          label: '$day',
          value: isFuture ? 0 : (noSpend ? 1 : 0),
          semantic: isFuture
              ? FastInfoSemantic.neutral
              : noSpend
              ? FastInfoSemantic.good
              : FastInfoSemantic.bad,
          isToday: _isSameDay(date, data.today),
          isFuture: isFuture,
        ),
      );
    }
    final progress = data.elapsedMonthDays <= 0
        ? 0.0
        : monthCount / data.elapsedMonthDays;
    return FastInfoMetricResult(
      pillValue: '$weekCount / 7 nap',
      primaryValue: '$monthCount nap',
      secondaryValues: <String>[
        'aktuális hónapban',
        'elmúlt 7 nap',
        'arány: ${_percent(progress)}%',
        'fixek nélkül',
      ],
      progressKind: FastInfoProgressKind.ring,
      progress: progress,
      semantic: FastInfoSemantic.good,
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.sevenDayStrip,
        value: progress,
        values: weekValues,
        points: monthPoints,
        semantic: FastInfoSemantic.good,
      ),
    );
  }

  FastInfoMetricResult _topCategoryWeekMonth() {
    final today = _topCategory(
      data.variableExpenseRowsBetween(data.today, data.tomorrow),
      byAmount: true,
    );
    final weekly = _topCategory(
      data.variableExpenseRowsBetween(data.weekStart, data.tomorrow),
      byAmount: true,
    );
    final monthly = _topCategory(
      data.variableExpenseRowsBetween(data.currentMonthStart, data.tomorrow),
      byAmount: true,
    );
    if (today == null && weekly == null && monthly == null) {
      return _noData('Nincs kategória');
    }
    final primary = today ?? weekly ?? monthly!;
    final pillLabel = today != null
        ? _periodCategoryLabel('Ma', today)
        : weekly != null
        ? _periodCategoryLabel('Hét', weekly)
        : _periodCategoryLabel('Hó', monthly!);
    return FastInfoMetricResult(
      pillValue: pillLabel,
      primaryValue: primary.name,
      secondaryValues: <String>[
        if (today != null) 'ma ${_compactAmount(today.amount)}',
        if (weekly != null)
          'Hét: ${weekly.name} · ${_compactAmount(weekly.amount)}',
        if (monthly != null)
          'Hó: ${monthly.name} · ${_compactAmount(monthly.amount)}',
        'fixek nélkül',
      ],
      avatar: avatarForCategory(primary.category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.miniAvatarRow,
        avatar: avatarForCategory(primary.category),
        points: <FastInfoVisualPoint>[
          if (today != null)
            FastInfoVisualPoint(
              label: 'Ma|${today.name}',
              value: today.amount,
              avatar: avatarForCategory(today.category),
            ),
          if (weekly != null)
            FastInfoVisualPoint(
              label: 'Hét|${weekly.name}',
              value: weekly.amount,
              avatar: avatarForCategory(weekly.category),
            ),
          if (monthly != null)
            FastInfoVisualPoint(
              label: 'Hó|${monthly.name}',
              value: monthly.amount,
              avatar: avatarForCategory(monthly.category),
            ),
        ],
      ),
    );
  }

  FastInfoMetricResult _largestCategoryChange() {
    final current = _categoryAmounts(
      data.variableExpenseRowsBetween(data.rolling30Start, data.tomorrow),
    );
    final previous = _categoryAmounts(
      data.variableExpenseRowsBetween(
        data.previousRolling30Start,
        data.rolling30Start,
      ),
    );
    final changes = <_CategoryChange>[];
    for (final id in <int>{...current.keys, ...previous.keys}) {
      final currentAmount = current[id] ?? 0.0;
      final previousAmount = previous[id] ?? 0.0;
      if (currentAmount == 0 && previousAmount == 0) continue;
      changes.add(
        _CategoryChange(
          category: data.categoriesById[id],
          current: currentAmount,
          previous: previousAmount,
        ),
      );
    }
    if (changes.isEmpty) return _noData('Nincs összehasonlítható kategória');
    changes.sort((a, b) {
      final byChange = b.absoluteAmountChange.compareTo(a.absoluteAmountChange);
      if (byChange != 0) return byChange;
      final byAmount = b.current.compareTo(a.current);
      if (byAmount != 0) return byAmount;
      return a.name.compareTo(b.name);
    });
    final top = changes.first;
    final up = top.current >= top.previous;
    final arrow = up ? '↑' : '↓';
    final percentText = top.isNew ? 'Új' : _signedPercent(top.change);
    final deltaText = _signedCompact(top.amountChange);
    return FastInfoMetricResult(
      pillValue: '${_shortText(top.name)} $deltaText',
      primaryValue: '${top.name} $arrow $deltaText',
      secondaryValues: <String>[
        '$percentText · fix nélkül',
        '30 nap: ${formatHuf(top.current)} · előtte ${formatHuf(top.previous)}',
      ],
      trend: FastInfoTrend(
        direction: up ? FastInfoTrendDirection.up : FastInfoTrendDirection.down,
        text: percentText,
        semantic: up ? FastInfoSemantic.bad : FastInfoSemantic.good,
      ),
      avatar: avatarForCategory(top.category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.analogMeter,
        value: top.change,
        semantic: up ? FastInfoSemantic.bad : FastInfoSemantic.good,
        avatar: avatarForCategory(top.category),
        values: <double>[top.previous, top.current],
      ),
    );
  }

  FastInfoMetricResult _nextRecurringExpense() {
    final pending = data
        .recurringGhostsBetween(
          data.today,
          DateTime(9999),
          expensesOnly: true,
          pendingOnly: true,
        )
        .toList();
    if (pending.isEmpty) return _noData('Nincs közelgő ismétlődő kiadás');
    final nextRow = pending.first;
    final next = nextRow.record;
    final sevenDays = data.recurringGhostsBetween(
      data.today,
      data.today.add(const Duration(days: 7)),
      expensesOnly: true,
      pendingOnly: true,
    );
    final sevenTotal = sevenDays.fold<double>(
      0,
      (sum, row) => sum + row.record.amount.abs(),
    );
    final weekValues = <double>[
      for (var index = 0; index < 7; index += 1)
        sevenDays
            .where(
              (row) =>
                  _isSameDay(row.date, data.today.add(Duration(days: index))),
            )
            .fold<double>(0, (sum, row) => sum + row.record.amount.abs()),
    ];
    final dueText = _relativeDayLabel(nextRow.date, data.today);
    return FastInfoMetricResult(
      pillValue: '${_shortText(next.name)} ${_compactAmount(next.amount)}',
      primaryValue: next.name,
      secondaryValues: <String>[
        '${formatHuf(next.amount.abs())} · $dueText',
        '7 nap: ${sevenDays.length} tétel · ${formatHuf(sevenTotal)}',
        next.categoryName,
      ],
      avatar: avatarForGhost(next),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.fixedLoad,
        value: sevenTotal,
        values: weekValues,
        avatar: avatarForGhost(next),
      ),
    );
  }

  FastInfoMetricResult _monthlyFixedCosts() {
    final rows = data.recurringGhostsBetween(
      data.currentMonthStart,
      data.nextMonthStart,
      expensesOnly: true,
    );
    if (rows.isEmpty) return _noData('Nincs havi fix költség');
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + row.record.amount.abs(),
    );
    final deducted = rows
        .where((row) => row.record.isActivated)
        .fold<double>(0, (sum, row) => sum + row.record.amount.abs());
    final remaining = math.max(0, total - deducted);
    final largest = rows.reduce(
      (left, right) =>
          left.record.amount.abs() >= right.record.amount.abs() ? left : right,
    );
    final limit = monthlyLimit;
    final progress = limit == null ? null : total / limit;
    return FastInfoMetricResult(
      pillValue: 'hátra ${_compactAmount(remaining)}',
      primaryValue: formatHuf(total),
      secondaryValues: <String>[
        'levonva ${_compactAmount(deducted)} · hátra ${_compactAmount(remaining)}',
        '${_compactAmount(total)} fixből',
        '${largest.record.name} ${_compactAmount(largest.record.amount)}',
      ],
      progressKind: progress == null ? null : FastInfoProgressKind.ring,
      progress: progress,
      semantic: progress == null
          ? FastInfoSemantic.neutral
          : expenseSemantic(progress),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.paidRemainingSplit,
        value: total <= 0 ? null : deducted / total,
        compareValue: total <= 0 ? null : remaining / total,
        semantic: progress == null
            ? FastInfoSemantic.neutral
            : expenseSemantic(progress),
      ),
    );
  }

  FastInfoMetricResult _expenseIncomeRatio() {
    final cashflow = data.currentMonthIncome - data.currentMonthExpense;
    if (data.currentMonthIncome <= 0) {
      return FastInfoMetricResult(
        pillValue: 'Nincs adat',
        primaryValue: 'Nincs adat',
        secondaryValues: <String>['Cashflow: ${_signedHuf(cashflow)}'],
      );
    }
    final ratio = data.currentMonthExpense / data.currentMonthIncome;
    final remainingRatio = math.max(0.0, 1 - ratio);
    final remainingAmount = math.max(0.0, cashflow);
    return FastInfoMetricResult(
      pillValue: '${_percent(remainingRatio)}% maradt',
      primaryValue: '${_percent(ratio)}%',
      secondaryValues: <String>[
        '${_compactAmount(data.currentMonthExpense)} / ${_compactAmount(data.currentMonthIncome)}',
        '${_compactAmount(remainingAmount)} bevételből',
        'Összes tartalék: ${_compactAmount(snapshot.balance)}',
      ],
      progressKind: FastInfoProgressKind.bar,
      progress: ratio,
      semantic: expenseSemantic(ratio),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.remainingSpentSplit,
        value: remainingRatio,
        compareValue: ratio,
        semantic: expenseSemantic(ratio),
      ),
    );
  }

  String _weeklyPaceLabel() {
    final points = _weeklyPacePoints();
    final prefix = points > 0 ? '+' : '';
    return 'időarányhoz képest $prefix${points}p';
  }

  int _weeklyPacePoints() {
    if (weeklyAllowance <= 0) return 0;
    final actualShare = data.currentWeekVariableExpense / weeklyAllowance;
    final expectedShare = data.today.weekday / 7;
    return ((actualShare - expectedShare) * 100).round();
  }

  List<_CategoryLimitState> _categoryLimitStates() {
    final spent = _categoryAmounts(
      data.variableExpenseRowsBetween(data.currentMonthStart, data.tomorrow),
    );
    final states = <_CategoryLimitState>[];
    for (final limit in snapshot.limits) {
      if (limit.targetType != LimitTargetType.category ||
          limit.window != LimitWindow.monthly ||
          limit.periodKey != monthKey ||
          !limit.hasLimit ||
          limit.limitAmount <= 0 ||
          TransactionTypeX.fromAny(limit.transactionType) !=
              TransactionType.expense) {
        continue;
      }
      states.add(
        _CategoryLimitState(
          category: data.categoriesById[limit.targetId],
          spent: spent[limit.targetId] ?? 0.0,
          limit: limit.limitAmount,
        ),
      );
    }
    if (states.isNotEmpty) return states;
    for (final category in snapshot.categories) {
      if (category.normalizedType != TransactionType.expense ||
          !category.hasLimit ||
          category.limitAmount <= 0) {
        continue;
      }
      states.add(
        _CategoryLimitState(
          category: category,
          spent: spent[category.transactionCategoryID] ?? 0.0,
          limit: category.limitAmount,
        ),
      );
    }
    return states;
  }

  _CategoryStat? _topCategory(
    Iterable<FastInfoDatedTransaction> rows, {
    bool byAmount = false,
  }) {
    final stats = <_CategoryStat>[];
    for (final entry in data.categoryExpenseGroups(rows).entries) {
      stats.add(
        _CategoryStat(
          category: data.categoriesById[entry.key],
          amount: _sum(entry.value),
          count: entry.value.length,
        ),
      );
    }
    if (stats.isEmpty) return null;
    stats.sort((a, b) {
      if (byAmount) {
        final amount = b.amount.compareTo(a.amount);
        if (amount != 0) return amount;
        final count = b.count.compareTo(a.count);
        if (count != 0) return count;
      } else {
        final count = b.count.compareTo(a.count);
        if (count != 0) return count;
        final amount = b.amount.compareTo(a.amount);
        if (amount != 0) return amount;
      }
      return a.name.compareTo(b.name);
    });
    return stats.first;
  }

  FastInfoAvatar? _mostFrequentCategoryAvatar(
    List<FastInfoDatedTransaction> rows,
  ) {
    return avatarForCategory(_topCategory(rows)?.category);
  }

  String _mostFrequentCategoryName(List<FastInfoDatedTransaction> rows) {
    return _topCategory(rows)?.name ?? 'Kategória';
  }

  List<FastInfoVisualPoint> _merchantActivityPoints(
    List<FastInfoDatedTransaction> rows,
  ) {
    final start = DateTime(
      data.today.year,
      data.today.month,
      data.today.day,
    ).subtract(const Duration(days: 13));
    return <FastInfoVisualPoint>[
      for (var index = 0; index < 14; index += 1)
        () {
          final day = start.add(Duration(days: index));
          final count = rows.where((row) => _isSameDay(row.date, day)).length;
          return FastInfoVisualPoint(
            label: '${index + 1}',
            value: count.toDouble(),
            isToday: _isSameDay(day, data.today),
          );
        }(),
    ];
  }

  DateTime _latestDate(List<FastInfoDatedTransaction> rows) {
    if (rows.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return rows.map((row) => row.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Map<int, double> _categoryAmounts(Iterable<FastInfoDatedTransaction> rows) {
    return {
      for (final entry in data.categoryExpenseGroups(rows).entries)
        entry.key: _sum(entry.value),
    };
  }

  String _latestTimeLabel(FastInfoDatedTransaction row) {
    if (_isSameDay(row.date, data.today)) return 'ma ${row.record.displayTime}';
    return '${row.record.normalizedDate} ${row.record.displayTime}';
  }

  FastInfoMetricResult _noData(String message) =>
      FastInfoMetricResult(pillValue: 'Nincs adat', primaryValue: message);
}

bool _isSameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

FastInfoSemantic expenseSemantic(double ratio) {
  if (ratio > 1) return FastInfoSemantic.bad;
  if (ratio >= .75) return FastInfoSemantic.warning;
  return FastInfoSemantic.good;
}

FastInfoTrend? expenseTrend(double current, double previous) =>
    _trend(current, previous, income: false);

FastInfoTrend? _trend(double current, double previous, {required bool income}) {
  if (previous <= 0) return null;
  final change = (current - previous) / previous;
  final up = change >= 0;
  return FastInfoTrend(
    direction: up ? FastInfoTrendDirection.up : FastInfoTrendDirection.down,
    text: _signedPercent(change),
    semantic: income
        ? (up ? FastInfoSemantic.good : FastInfoSemantic.bad)
        : (up ? FastInfoSemantic.bad : FastInfoSemantic.good),
  );
}

FastInfoAvatar? avatarForCategory(TransactionCategory? category) {
  if (category == null) return null;
  return FastInfoAvatar(
    colorHex: category.slotColorHex,
    iconSlot: category.iconSlot,
  );
}

FastInfoAvatar avatarForGhost(RecurringGhostRecord ghost) => FastInfoAvatar(
  colorHex: ghost.categoryColor,
  iconSlot: ghost.categoryIconSlot,
);

class _CategoryLimitState {
  const _CategoryLimitState({
    required this.category,
    required this.spent,
    required this.limit,
  });

  final TransactionCategory? category;
  final double spent;
  final double limit;

  String get name => category?.name ?? 'Kategória';
  double get ratio => limit <= 0 ? 0.0 : spent / limit;
}

class _CategoryStat {
  const _CategoryStat({
    required this.category,
    required this.amount,
    required this.count,
  });

  final TransactionCategory? category;
  final double amount;
  final int count;

  String get name => category?.name ?? 'Kategória';
}

String _periodCategoryLabel(String period, _CategoryStat stat) =>
    '$period ${stat.name} ${_compactAmount(stat.amount)}';

class _CategoryChange {
  const _CategoryChange({
    required this.category,
    required this.current,
    required this.previous,
  });

  final TransactionCategory? category;
  final double current;
  final double previous;

  String get name => category?.name ?? 'Kategória';
  bool get isNew => previous <= 0 && current > 0;
  double get change => previous <= 0 ? 0.0 : (current - previous) / previous;
  double get amountChange => current - previous;
  double get absoluteAmountChange => amountChange.abs();
}

double _sum(Iterable<FastInfoDatedTransaction> rows) =>
    rows.fold<double>(0, (sum, row) => sum + row.record.amount.abs());

int _spikeCount(List<double> values, double average) {
  if (average <= 0) return 0;
  return values.where((value) => value > average * 1.5).length;
}

String _relativeDayLabel(DateTime date, DateTime today) {
  final todayOnly = DateTime(today.year, today.month, today.day);
  final days = date.difference(todayOnly).inDays;
  if (days <= 0) return 'ma';
  if (days == 1) return 'holnap';
  return '$days nap múlva';
}

String _compactAmount(num amount) {
  final value = amount.abs();
  if (value >= 1000000) return '${_trim(value / 1000000)}M';
  if (value >= 1000) return '${_trim(value / 1000)}k';
  return value.round().toString();
}

String _signedCompact(num value) =>
    '${value >= 0 ? '+' : '-'}${_compactAmount(value)}';

String _signedHuf(num value) =>
    '${value >= 0 ? '+' : '-'}${formatHuf(value.abs())}';

String _signedPercent(double value) =>
    '${value >= 0 ? '+' : ''}${(value * 100).round()}%';

int _percent(double value) => (value * 100).round();

String _trim(num value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1);
}

String _shortText(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 10) return trimmed;
  return '${trimmed.substring(0, 9)}…';
}

String _periodKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

final FastInfoMetricSnapshot _previewSnapshot = FastInfoMetricSnapshot(
  now: DateTime(2026, 6, 3, 12),
  balance: 300000,
  savingGoal: 50000,
  transactions: _previewTransactions,
  categories: _previewCategories,
  limits: _previewLimits,
  recurringGhosts: _previewGhosts,
);

const _previewCategories = <TransactionCategory>[
  TransactionCategory(
    transactionCategoryID: 1,
    name: 'Étel',
    type: 'expense',
    colorSlot: 0,
    iconSlot: 0,
    backgroundColor: null,
    icon: 'restaurant',
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  ),
  TransactionCategory(
    transactionCategoryID: 2,
    name: 'Fizetés',
    type: 'income',
    colorSlot: 1,
    iconSlot: 1,
    backgroundColor: null,
    icon: 'payments',
    notification: null,
    hasLimit: false,
    limitAmount: 0,
    alertActive: false,
    isCustomIcon: false,
    originalIcon: null,
  ),
];

const _previewTransactions = <TransactionRecord>[
  TransactionRecord(
    id: 1,
    date: '2026.06.03',
    time: '11:30',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Kávézó',
    amount: -7000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 2,
    date: '2026.06.02',
    time: '12:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Piac',
    amount: -12000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 3,
    date: '2026.06.01',
    time: '12:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Bolt',
    amount: -8000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 4,
    date: '2026.05.15',
    time: '12:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Bolt',
    amount: -30000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 5,
    date: '2026.06.01',
    time: '08:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Fizetés',
    amount: 150000,
    userAssignedName: null,
    transactionCategoryID: 2,
  ),
];

const _previewLimits = <CategoryLimit>[
  CategoryLimit(
    id: 1,
    targetType: LimitTargetType.overview,
    targetId: 0,
    transactionType: 'expense',
    window: LimitWindow.monthly,
    periodKey: '2026-06',
    hasLimit: true,
    limitAmount: 300000,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  ),
  CategoryLimit(
    id: 2,
    targetType: LimitTargetType.category,
    targetId: 1,
    transactionType: 'expense',
    window: LimitWindow.monthly,
    periodKey: '2026-06',
    hasLimit: true,
    limitAmount: 60000,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  ),
];

const _previewGhosts = <RecurringGhostRecord>[
  RecurringGhostRecord(
    id: 1,
    recurringTransactionId: 1,
    periodKey: '2026-06',
    name: 'Telefon',
    amount: 8000,
    transactionType: 'expense',
    date: '2026.06.05',
    time: '08:00',
    categoryId: 1,
    categoryName: 'Étel',
    categoryColor: '#22c55e',
    categoryIconSlot: 0,
    triggerMillis: 0,
    isActivated: false,
    activatedTransactionId: null,
    createdAt: 0,
    updatedAt: 0,
  ),
];
