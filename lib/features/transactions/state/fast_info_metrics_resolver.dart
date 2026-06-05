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
      'top_kategoria_ma' => _topCategoryToday(),
      'top_kategoria_heten' => _topCategoryWeekMonth(),
      'legnagyobb_novekedo_kategoria' => _largestCategoryChange(),
      'kovetkezo_ismetlo_kiadas' => _nextRecurringExpense(),
      'havi_fix_koltseg_osszesen' => _monthlyFixedCosts(),
      'bevetel_ebben_a_honapban' => _monthlyIncome(),
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
    final rate = data.currentMonthIncome > 0
        ? actualSavings / data.currentMonthIncome
        : null;
    return FastInfoMetricResult(
      pillValue: _compactAmount(actualSavings),
      primaryValue: formatHuf(actualSavings),
      secondaryValues: <String>[
        if (goal == null || goal <= 0)
          'Nincs cél'
        else
          'Cél: ${formatHuf(goal)}',
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
              semantic: progress >= 1
                  ? FastInfoSemantic.good
                  : progress >= .75
                  ? FastInfoSemantic.warning
                  : FastInfoSemantic.neutral,
            ),
    );
  }

  FastInfoMetricResult _rollingSpendTrend() {
    final pace = _paceStatus();
    return FastInfoMetricResult(
      pillValue: _compactAmount(data.rolling30Expense),
      primaryValue: formatHuf(data.rolling30Expense),
      secondaryValues: <String>[
        'Előző 30 nap: ${formatHuf(data.previousRolling30Expense)}',
        if (pace != null) 'Kerettempó: $pace',
        if (data.previousRolling30Expense <= 0) 'Nincs összehasonlítás',
      ],
      trend: expenseTrend(data.rolling30Expense, data.previousRolling30Expense),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.zoneMarker,
        value: data.previousRolling30Expense > 0
            ? data.rolling30Expense / data.previousRolling30Expense
            : null,
        semantic: data.previousRolling30Expense > 0
            ? expenseSemantic(
                data.rolling30Expense / data.previousRolling30Expense,
              )
            : FastInfoSemantic.neutral,
      ),
    );
  }

  FastInfoMetricResult _latestTransaction() {
    if (data.datedTransactions.isEmpty) return _noData('Nincs tranzakció');
    final row = data.datedTransactions.first;
    final category = data.categoriesById[row.record.transactionCategoryID];
    return FastInfoMetricResult(
      pillValue: _signedCompact(row.record.amount),
      primaryValue: row.record.displayAmount,
      secondaryValues: <String>[
        row.record.displayMerchant.isEmpty
            ? 'Névtelen tranzakció'
            : row.record.displayMerchant,
        '${category?.name ?? 'Nincs kategória'} · ${row.record.displayTime}',
      ],
      avatar: avatarForCategory(category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.avatar,
        avatar: avatarForCategory(category),
      ),
    );
  }

  FastInfoMetricResult _forecast() {
    final average = data.elapsedMonthDays == 0
        ? 0.0
        : data.currentMonthExpense / data.elapsedMonthDays;
    final forecast = <double>[
      for (var day = 1; day <= data.daysInCurrentMonth; day += 1)
        if (day <= data.today.day)
          data.currentMonthDailySeries[day - 1]
        else
          average,
    ];
    final limit = monthlyLimit;
    final ratio = limit == null ? null : projectedMonthExpense / limit;
    final remaining = data.currentMonthIncome - projectedMonthExpense;
    return FastInfoMetricResult(
      pillValue: _compactAmount(projectedMonthExpense),
      primaryValue: formatHuf(projectedMonthExpense),
      secondaryValues: <String>[
        'Becsült maradék: ${_signedHuf(remaining)}',
        if (ratio != null) 'Kockázat: ${_riskLabel(ratio)}',
      ],
      semantic: ratio == null
          ? FastInfoSemantic.neutral
          : expenseSemantic(ratio),
      chartKind: FastInfoChartKind.sparkline,
      chartSeries: <FastInfoChartSeries>[
        FastInfoChartSeries(label: 'Előrejelzés', values: forecast),
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
    return FastInfoMetricResult(
      pillValue: '${top.name} ${_percent(top.ratio)}%',
      primaryValue: top.name,
      secondaryValues: <String>[
        '${formatHuf(top.spent)} / ${formatHuf(top.limit)}',
        'Közel: $near · felett: $over',
      ],
      progressKind: FastInfoProgressKind.bar,
      progress: top.ratio,
      semantic: expenseSemantic(top.ratio),
      avatar: avatarForCategory(top.category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.overflowRisk,
        value: top.ratio,
        semantic: expenseSemantic(top.ratio),
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
      return a.key.compareTo(b.key);
    });
    final top = entries.first;
    return FastInfoMetricResult(
      pillValue: _shortText(top.key),
      primaryValue: top.key,
      secondaryValues: <String>[
        '${top.value.length} tranzakció',
        formatHuf(_sum(top.value)),
      ],
      avatar: _mostFrequentCategoryAvatar(top.value),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.activityStrip,
        value: top.value.length.toDouble(),
        avatar: _mostFrequentCategoryAvatar(top.value),
      ),
    );
  }

  FastInfoMetricResult _averageDailySpend() {
    final average = rollingDailyAverage;
    return FastInfoMetricResult(
      pillValue: _compactAmount(average),
      primaryValue: formatHuf(average),
      secondaryValues: <String>[
        if (average > 0)
          'Puffer: ${(math.max(0, snapshot.balance) / average).round()} nap',
      ],
      chartKind: FastInfoChartKind.sparkline,
      chartSeries: <FastInfoChartSeries>[
        FastInfoChartSeries(
          label: '30 nap',
          values: data.rolling30VariableDailySeries,
        ),
      ],
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.spikeLine,
        values: data.rolling30VariableDailySeries,
      ),
    );
  }

  FastInfoMetricResult _noSpendDays() {
    const windowDays = 7;
    final start = data.today.subtract(const Duration(days: windowDays - 1));
    var count = 0;
    final points = <FastInfoVisualPoint>[];
    for (var index = 0; index < windowDays; index += 1) {
      final date = start.add(Duration(days: index));
      final noSpend = data.variableExpenseOn(date) == 0;
      if (noSpend) count += 1;
      points.add(
        FastInfoVisualPoint(
          label: '${date.month}.${date.day}',
          value: noSpend ? 1 : 0,
          semantic: noSpend ? FastInfoSemantic.good : FastInfoSemantic.bad,
          isToday: _isSameDay(date, data.today),
        ),
      );
    }
    final progress = count / windowDays;
    return FastInfoMetricResult(
      pillValue: '$count / 7',
      primaryValue: '$count / 7 nap',
      secondaryValues: const <String>['elmúlt 7 nap', 'fixek nélkül'],
      progressKind: FastInfoProgressKind.ring,
      progress: progress,
      semantic: FastInfoSemantic.good,
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.sevenDayStrip,
        value: progress,
        points: points,
        semantic: FastInfoSemantic.good,
      ),
    );
  }

  FastInfoMetricResult _topCategoryToday() {
    final top = _topCategory(
      data.variableExpenseRowsBetween(data.today, data.tomorrow),
      byAmount: true,
    );
    if (top == null) return _noData('Ma nincs költés');
    final share = data.todayExpense > 0 ? top.amount / data.todayExpense : 0.0;
    return FastInfoMetricResult(
      pillValue: _shortText(top.name),
      primaryValue: top.name,
      secondaryValues: <String>[
        formatHuf(top.amount),
        'Mai költés ${_percent(share)}%-a',
      ],
      avatar: avatarForCategory(top.category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.avatar,
        value: share,
        avatar: avatarForCategory(top.category),
      ),
    );
  }

  FastInfoMetricResult _topCategoryWeekMonth() {
    final weekly = _topCategory(
      data.variableExpenseRowsBetween(data.weekStart, data.tomorrow),
      byAmount: true,
    );
    final monthly = _topCategory(
      data.variableExpenseRowsBetween(data.currentMonthStart, data.tomorrow),
      byAmount: true,
    );
    if (weekly == null && monthly == null) return _noData('Nincs kategória');
    final primary = weekly ?? monthly!;
    return FastInfoMetricResult(
      pillValue: _shortText(primary.name),
      primaryValue: primary.name,
      secondaryValues: <String>[
        if (weekly != null)
          'Hét: ${weekly.count} db · ${formatHuf(weekly.amount)}',
        if (monthly != null)
          'Hónap: ${monthly.name} · ${monthly.count} db · ${formatHuf(monthly.amount)}',
      ],
      avatar: avatarForCategory(primary.category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.miniAvatarRow,
        avatar: avatarForCategory(primary.category),
        points: <FastInfoVisualPoint>[
          if (weekly != null)
            FastInfoVisualPoint(
              label: 'Hét',
              value: weekly.amount,
              avatar: avatarForCategory(weekly.category),
            ),
          if (monthly != null)
            FastInfoVisualPoint(
              label: 'Hó',
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
      final byNew = (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0);
      if (byNew != 0) return byNew;
      final byChange = b.absoluteChange.compareTo(a.absoluteChange);
      if (byChange != 0) return byChange;
      final byAmount = b.current.compareTo(a.current);
      if (byAmount != 0) return byAmount;
      return a.name.compareTo(b.name);
    });
    final top = changes.first;
    final up = top.current >= top.previous;
    return FastInfoMetricResult(
      pillValue: _shortText(top.name),
      primaryValue: top.name,
      secondaryValues: <String>[
        '30 nap: ${formatHuf(top.current)} · előtte ${formatHuf(top.previous)}',
        'változás: ${top.isNew ? '+100%' : _signedPercent(top.change)}',
        'fixek nélkül',
      ],
      trend: FastInfoTrend(
        direction: up ? FastInfoTrendDirection.up : FastInfoTrendDirection.down,
        text: top.isNew ? 'Új' : _signedPercent(top.change),
        semantic: up ? FastInfoSemantic.bad : FastInfoSemantic.good,
      ),
      avatar: avatarForCategory(top.category),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.analogMeter,
        value: top.change,
        semantic: up ? FastInfoSemantic.bad : FastInfoSemantic.good,
        avatar: avatarForCategory(top.category),
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
    final next = pending.first.record;
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
    return FastInfoMetricResult(
      pillValue: _compactAmount(next.amount),
      primaryValue: '${next.name} · ${formatHuf(next.amount.abs())}',
      secondaryValues: <String>[
        'Esedékes: ${next.date.replaceAll('.', '-')}',
        '7 nap: ${sevenDays.length} tétel · ${formatHuf(sevenTotal)}',
      ],
      avatar: avatarForGhost(next),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.fixedLoad,
        value: sevenTotal,
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
      pillValue: _compactAmount(total),
      primaryValue: formatHuf(total),
      secondaryValues: <String>[
        '${_compactAmount(remaining)} hátra ${_compactAmount(total)} fixből',
        'Levonva ${_compactAmount(deducted)} · legnagyobb ${largest.record.name}',
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

  FastInfoMetricResult _monthlyIncome() {
    final coverage = rollingDailyAverage > 0
        ? data.currentMonthIncome / rollingDailyAverage
        : null;
    return FastInfoMetricResult(
      pillValue: _compactAmount(data.currentMonthIncome),
      primaryValue: formatHuf(data.currentMonthIncome),
      secondaryValues: <String>[
        if (coverage != null) 'Fedezet: ${coverage.floor()} nap',
        if (data.previousMonthSameDayIncome <= 0) 'Nincs összehasonlítás',
      ],
      semantic: coverage == null
          ? FastInfoSemantic.neutral
          : coverage >= 30
          ? FastInfoSemantic.good
          : FastInfoSemantic.warning,
      trend: incomeTrend(
        data.currentMonthIncome,
        data.previousMonthSameDayIncome,
      ),
      visual: FastInfoVisualDescriptor(
        kind: FastInfoVisualKind.incomeComparisonBars,
        value: data.currentMonthIncome,
        compareValue: data.previousMonthSameDayIncome,
        semantic: data.currentMonthIncome >= data.previousMonthSameDayIncome
            ? FastInfoSemantic.good
            : FastInfoSemantic.bad,
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
      primaryValue: '${_percent(remainingRatio)}% maradt',
      secondaryValues: <String>[
        '${formatHuf(remainingAmount)} bevételből',
        'elköltve ${_percent(ratio)}%',
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

  String? _paceStatus() {
    final limit = monthlyLimit;
    if (limit == null || limit <= 0) return null;
    final actual = data.currentMonthExpense / limit;
    final expected = data.elapsedMonthDays / data.daysInCurrentMonth;
    if (actual > expected * 1.15) return 'gyors';
    if (actual < expected * .80) return 'lassú';
    return 'normál';
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

  Map<int, double> _categoryAmounts(Iterable<FastInfoDatedTransaction> rows) {
    return {
      for (final entry in data.categoryExpenseGroups(rows).entries)
        entry.key: _sum(entry.value),
    };
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

FastInfoTrend? incomeTrend(double current, double previous) =>
    _trend(current, previous, income: true);

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
  double get absoluteChange => isNew ? double.infinity : change.abs();
}

double _sum(Iterable<FastInfoDatedTransaction> rows) =>
    rows.fold<double>(0, (sum, row) => sum + row.record.amount.abs());

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

String _riskLabel(double ratio) {
  if (ratio > 1) return 'magas';
  if (ratio >= .75) return 'közepes';
  return 'alacsony';
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
