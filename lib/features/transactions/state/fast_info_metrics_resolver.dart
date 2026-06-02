import 'dart:math' as math;

import '../../settings/models/fast_info_card_catalog.dart';
import '../models/category_limit.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class FastInfoMetricResult {
  const FastInfoMetricResult({
    required this.pillValue,
    required this.boxValue,
    required this.boxSubtitle,
    this.progress,
    this.series = const <double>[],
  });

  final String pillValue;
  final String boxValue;
  final String boxSubtitle;
  final double? progress;
  final List<double> series;
}

class FastInfoMetricsResolver {
  const FastInfoMetricsResolver._();

  static Set<String> get supportedMetricIds =>
      fastInfoCardCatalog.map((card) => card.id).toSet();

  static Map<String, FastInfoMetricResult> preview() => _previewMetrics;

  static Map<String, FastInfoMetricResult> resolve({
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
    required List<CategoryLimit> limits,
    required DateTime now,
  }) {
    final scope = _FastInfoMetricScope(
      transactions: transactions,
      categories: categories,
      limits: limits,
      now: now,
    );
    return Map.unmodifiable({
      for (final card in fastInfoCardCatalog) card.id: scope.metricFor(card.id),
    });
  }
}

class _FastInfoMetricScope {
  _FastInfoMetricScope({
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
    required List<CategoryLimit> limits,
    required DateTime now,
  }) : _transactions = transactions,
       _categories = categories,
       _limits = limits,
       _today = _dateOnly(now) {
    _categoriesById = {
      for (final category in _categories)
        category.transactionCategoryID: category,
    };
    _datedRecords = [
      for (final record in _transactions)
        _DatedTransaction(record: record, date: _parseDate(record.date)),
    ];
    _datedRecords.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.record.time.compareTo(a.record.time);
    });
  }

  final List<TransactionRecord> _transactions;
  final List<TransactionCategory> _categories;
  final List<CategoryLimit> _limits;
  final DateTime _today;
  late final Map<int, TransactionCategory> _categoriesById;
  late final List<_DatedTransaction> _datedRecords;

  String get _monthKey => _periodKey(_today);
  DateTime get _monthStart => DateTime(_today.year, _today.month);
  DateTime get _nextMonthStart => DateTime(_today.year, _today.month + 1);
  DateTime get _previousMonthStart => DateTime(_today.year, _today.month - 1);
  DateTime get _weekStart =>
      _today.subtract(Duration(days: _today.weekday - 1));
  DateTime get _nextWeekStart => _weekStart.add(const Duration(days: 7));
  DateTime get _previousWeekStart =>
      _weekStart.subtract(const Duration(days: 7));

  List<_DatedTransaction> get _expenses => _datedRecords
      .where((row) => row.record.amount < 0)
      .toList(growable: false);

  List<_DatedTransaction> get _incomes => _datedRecords
      .where((row) => row.record.amount > 0)
      .toList(growable: false);

  List<_DatedTransaction> get _todayExpenses =>
      _inRange(_expenses, _today, _today.add(const Duration(days: 1)));

  List<_DatedTransaction> get _monthExpenses =>
      _inRange(_expenses, _monthStart, _nextMonthStart);

  List<_DatedTransaction> get _previousMonthExpenses =>
      _inRange(_expenses, _previousMonthStart, _monthStart);

  List<_DatedTransaction> get _weekExpenses =>
      _inRange(_expenses, _weekStart, _nextWeekStart);

  List<_DatedTransaction> get _previousWeekExpenses =>
      _inRange(_expenses, _previousWeekStart, _weekStart);

  List<_DatedTransaction> get _monthIncomes =>
      _inRange(_incomes, _monthStart, _nextMonthStart);

  double get _todayExpenseTotal => _sumAbs(_todayExpenses);
  double get _monthExpenseTotal => _sumAbs(_monthExpenses);
  double get _previousMonthExpenseTotal => _sumAbs(_previousMonthExpenses);
  double get _weekExpenseTotal => _sumAbs(_weekExpenses);
  double get _previousWeekExpenseTotal => _sumAbs(_previousWeekExpenses);
  double get _monthIncomeTotal => _sumAbs(_monthIncomes);
  double get _allExpenseTotal => _sumAbs(_expenses);
  double get _allIncomeTotal => _sumAbs(_incomes);
  double get _monthlyLimit => _overviewLimit(LimitWindow.monthly, _monthKey);
  double get _monthlyRemaining =>
      math.max(0, _monthlyLimit - _monthExpenseTotal);
  double get _dailySuggestedMax {
    final remainingDays = _daysInMonth(_today) - _today.day + 1;
    if (_monthlyLimit <= 0 || remainingDays <= 0) return 0;
    return _monthlyRemaining / remainingDays;
  }

  FastInfoMetricResult metricFor(String id) {
    return switch (id) {
      'mai_koltes' => _todaySpend(),
      'heti_koltes' => _periodSpend(_weekExpenseTotal, 'heti költés'),
      'havi_koltes' => _monthlySpend(),
      'megtakaritas' => _savings(),
      'egyenleg' => _balance(),
      'havi_limit_allapot' => _monthlyLimitState(),
      'koltesi_trend' => _trend(_monthExpenseTotal, _previousMonthExpenseTotal),
      'legutobbi_tranzakcio' => _latestTransaction(),
      'mai_maradek_keret' => _remainingMetric(
        _dailySuggestedMax - _todayExpenseTotal,
        'Mai ajánlott keretből',
      ),
      'heti_maradek_keret' => _remainingMetric(
        _weeklyRemaining,
        'Heti keret maradéka',
      ),
      'honapbol_hatralevo_napok' => _monthDaysLeft(),
      'napi_ajanlott_maximum' => _plainAmount(
        _dailySuggestedMax,
        'Becsült napi plafon',
      ),
      'mai_koltes_ajanlotthoz' => _ratioMetric(
        _todayExpenseTotal,
        _dailySuggestedMax,
        'Mai ajánlott keret',
      ),
      'havi_keret_egesi_sebesseg' => _burnSpeed(),
      'varhato_ho_vegi_koltes' => _projectedMonthEndSpend(),
      'tulkoltes_kockazat' => _overspendRisk(),
      'leggyorsabban_fogyo_kategorialimit' => _fastestCategoryLimit(),
      'limit_feletti_kategoriak_szama' => _categoryLimitCount(over: true),
      'utolso_auto_tranzakcio' => _latestTransaction(),
      'utolso_kezi_tranzakcio' => _latestTransaction(),
      'ma_rogzitett_tranzakciok_szama' => _todayTransactionCount(),
      'fuggoben_levo_feldolgozas' => _zeroStatus(
        '0 függőben',
        'Nincs várakozó elem',
      ),
      'legutobbi_push_forrasapp' => _sourceApp(),
      'sikertelen_parse_ok' => _zeroStatus(
        '0 sikertelen',
        'Nincs hibás parse jel',
      ),
      'ismeretlen_kereskedok_szama' => _unknownMerchants(),
      'uj_kereskedo_ma' => _newMerchantToday(),
      'leggyakoribb_kereskedo' => _topMerchant(_expenses, 'Legtöbb tranzakció'),
      'legdragabb_kereskedo_honapban' => _topMerchant(
        _monthExpenses,
        'Legnagyobb havi összeg',
      ),
      'atlagos_napi_koltes' => _averageDailySpend(),
      'hetvegi_vs_hetkoznapi_koltes' => _weekendWeekdaySpend(),
      'mai_nap_atlaghoz_kepest' => _todayAgainstAverage(),
      'ez_a_het_elozo_hethez' => _trend(
        _weekExpenseTotal,
        _previousWeekExpenseTotal,
      ),
      'ez_a_honap_elozo_honaphoz' => _trend(
        _monthExpenseTotal,
        _previousMonthExpenseTotal,
      ),
      'kiadasi_tempo' => _burnSpeed(),
      'havi_anomalia' => _monthlyAnomaly(),
      'szokatlan_nagy_tetel' => _largeItems(),
      'sporolasi_sorozat' => _savingStreak(),
      'no_spend_napok_szama' => _noSpendDays(),
      'top_kategoria_ma' => _topCategory(
        _todayExpenses,
        'Mai legnagyobb kategória',
      ),
      'top_kategoria_heten' => _topCategory(
        _weekExpenses,
        'Heti legnagyobb kategória',
      ),
      'top_kategoria_honapban' => _topCategory(
        _monthExpenses,
        'Havi legnagyobb kategória',
      ),
      'legnagyobb_novekedo_kategoria' => _categoryDelta(growing: true),
      'legjobban_csokkeno_kategoria' => _categoryDelta(growing: false),
      'kategoria_limit_kozeleben' => _nearCategoryLimits(),
      'kategoria_limit_tullepve' => _categoryLimitCount(over: true),
      'ures_vagy_kategorizalatlan_tranzakciok' => _uncategorizedTransactions(),
      'kedvenc_kategoria_shortcut' => _topCategory(
        _expenses,
        'Gyakran használt kategória',
      ),
      'kategoria_amire_ma_meg_nem_koltottel' => _categoryWithoutTodaySpend(),
      'kovetkezo_ismetlo_kiadas' => _nextFixedExpense(),
      'kovetkezo_7_nap_fix_kiadasai' => _expectedFixedExpense(days: 7),
      'mai_esedekes_fix_kiadas' => _expectedFixedExpense(days: 1),
      'havi_fix_koltseg_osszesen' => _monthlyFixedCost(),
      'fix_koltseg_aranya_havi_keretbol' => _ratioMetric(
        _monthlyFixedTotal,
        _monthlyLimit,
        'Havi keretből',
      ),
      'mar_levont_fix_kiadasok' => _plainAmount(
        _monthlyFixedTotal,
        'Már teljesült fix tételek',
      ),
      'meg_varhato_fix_kiadasok' => _expectedFixedExpense(days: 31),
      'elmaradt_ismetlo_feldolgozas' => _zeroStatus(
        'Nincs elmaradás',
        'Minden naprakész',
      ),
      'legnagyobb_fix_kiadas' => _largestFixedExpense(),
      'fix_koltsegek_utan_marado_keret' => _plainAmount(
        math.max(0.0, _monthlyLimit - _monthlyFixedTotal),
        'Fix tételek után',
      ),
      'biztonsagi_tartalek' => _plainAmount(
        math.max(0.0, _allIncomeTotal - _allExpenseTotal),
        'Becsült puffer',
      ),
      'minimum_egyenleg_figyelmeztetes' => _minimumBalanceWarning(),
      'keszpenz_vs_kartyas_arany' => _cashCardRatio(),
      'bevetel_ebben_a_honapban' => _plainAmount(
        _monthIncomeTotal,
        'Havi bevétel',
      ),
      'kiadas_bevetel_arany' => _ratioMetric(
        _monthExpenseTotal,
        _monthIncomeTotal,
        'Kiadás a bevételhez képest',
      ),
      'netto_havi_cashflow' => _cashflow(),
      'ho_vegi_becsult_maradek' => _monthEndRemaining(),
      'megtakaritasi_cel_haladas' => _savingsRate(),
      'havi_megtakaritasi_rata' => _savingsRate(),
      'puffer_napok_szama' => _bufferDays(),
      'figyelt_app_allapota' => _status('aktív', 'Aktív', 'App figyelés fut'),
      'notification_listener_allapota' => _status(
        'OK',
        'OK',
        'Értesítésfigyelés elérhető',
      ),
      'utolso_sikeres_szinkron' => _status(
        _timeText(_today),
        _timeText(_today),
        'Adatok betöltve',
      ),
      'utolso_backup' => _status(
        'nincs',
        'Nincs adat',
        'Nincs backup jel a lokális adatokban',
      ),
      'adatbazis_sorok_szama' => _rowCount(),
      'hianyos_tranzakciok' => _incompleteTransactions(),
      'duplikatumgyanus_tetelek' => _duplicateSuspects(),
      'parse_pontossag' => _parseAccuracy(),
      'import_export_statusz' => _status(
        'OK',
        'OK',
        'Nincs folyamatban lévő művelet',
      ),
      'debug_riasztasok' => _zeroStatus(
        '0 riasztás',
        'Nincs aktív debug jelzés',
      ),
      _ => _status('-', 'Nincs adat', 'Ehhez nincs metrika'),
    };
  }

  double get _weeklyRemaining {
    if (_monthlyLimit <= 0) return 0;
    return math.max(0, (_monthlyLimit / 4.345) - _weekExpenseTotal);
  }

  double get _monthlyFixedTotal => _fixedMerchantGroups().fold<double>(
    0,
    (sum, group) => sum + group.currentMonthAmount,
  );

  FastInfoMetricResult _todaySpend() {
    return FastInfoMetricResult(
      pillValue: _compactAmount(_todayExpenseTotal),
      boxValue: formatHuf(_todayExpenseTotal),
      boxSubtitle: '${_todayExpenses.length} tranzakció ma',
      progress: _ratio(_todayExpenseTotal, _dailySuggestedMax),
      series: _dailySeries(7),
    );
  }

  FastInfoMetricResult _periodSpend(double amount, String subtitle) {
    return FastInfoMetricResult(
      pillValue: _compactAmount(amount),
      boxValue: formatHuf(amount),
      boxSubtitle: subtitle,
      progress: _ratio(amount, _monthlyLimit),
      series: _dailySeries(7),
    );
  }

  FastInfoMetricResult _monthlySpend() {
    if (_monthlyLimit <= 0) {
      return _periodSpend(_monthExpenseTotal, 'Havi költés limit nélkül');
    }
    final percent = _percent(_ratio(_monthExpenseTotal, _monthlyLimit));
    return FastInfoMetricResult(
      pillValue: _compactAmount(_monthExpenseTotal),
      boxValue:
          '${_compactAmount(_monthExpenseTotal)} / ${_compactAmount(_monthlyLimit)}',
      boxSubtitle: 'A havi keret $percent%-a',
      progress: _ratio(_monthExpenseTotal, _monthlyLimit),
      series: _dailySeries(14),
    );
  }

  FastInfoMetricResult _monthlyLimitState() {
    if (_monthlyLimit <= 0) {
      return _status('nincs', 'Nincs limit', 'Havi limit nincs beállítva');
    }
    final ratio = _ratio(_monthExpenseTotal, _monthlyLimit);
    return FastInfoMetricResult(
      pillValue: '${_percent(ratio)}%',
      boxValue:
          '${_compactAmount(_monthExpenseTotal)} / ${_compactAmount(_monthlyLimit)}',
      boxSubtitle: '${_compactAmount(_monthlyRemaining)} maradt',
      progress: ratio,
      series: _dailySeries(14),
    );
  }

  FastInfoMetricResult _trend(double current, double previous) {
    if (previous <= 0) {
      return _status('új', 'Új adat', 'Nincs előző összevetés');
    }
    final change = ((current - previous) / previous) * 100;
    final text = '${change >= 0 ? '+' : ''}${change.round()}%';
    return FastInfoMetricResult(
      pillValue: text,
      boxValue: text,
      boxSubtitle: 'Az előző időszakhoz képest',
      progress: _ratio(current, math.max(current, previous)),
      series: <double>[previous, current],
    );
  }

  FastInfoMetricResult _latestTransaction() {
    if (_datedRecords.isEmpty) {
      return _status('nincs', 'Nincs tranzakció', 'Nincs adat');
    }
    final latest = _datedRecords.first.record;
    return FastInfoMetricResult(
      pillValue: _signedCompact(latest.amount),
      boxValue: latest.displayAmount,
      boxSubtitle: '${latest.displayMerchant}, ${latest.displayTime}',
      progress: latest.amount < 0 ? 0.35 : 0.65,
    );
  }

  FastInfoMetricResult _remainingMetric(double amount, String subtitle) {
    final remaining = math.max(0.0, amount);
    return FastInfoMetricResult(
      pillValue: _compactAmount(remaining),
      boxValue: formatHuf(remaining),
      boxSubtitle: subtitle,
      progress: _ratio(remaining, amount + _todayExpenseTotal),
    );
  }

  FastInfoMetricResult _monthDaysLeft() {
    final left = _daysInMonth(_today) - _today.day;
    return FastInfoMetricResult(
      pillValue: '$left nap',
      boxValue: '$left nap',
      boxSubtitle: 'A hónap végéig',
      progress: _ratio(left.toDouble(), _daysInMonth(_today).toDouble()),
    );
  }

  FastInfoMetricResult _plainAmount(double amount, String subtitle) {
    return FastInfoMetricResult(
      pillValue: _compactAmount(amount),
      boxValue: formatHuf(amount),
      boxSubtitle: subtitle,
      progress: _ratio(amount, _monthlyLimit > 0 ? _monthlyLimit : amount),
      series: _dailySeries(7),
    );
  }

  FastInfoMetricResult _ratioMetric(
    double numerator,
    double denominator,
    String subtitle,
  ) {
    final ratio = _ratio(numerator, denominator);
    return FastInfoMetricResult(
      pillValue: '${_percent(ratio)}%',
      boxValue: '${_percent(ratio)}%',
      boxSubtitle: subtitle,
      progress: ratio,
      series: <double>[numerator, denominator],
    );
  }

  FastInfoMetricResult _burnSpeed() {
    if (_monthlyLimit <= 0) {
      return _status('nincs', 'Nincs limit', 'Tempóhoz limit kell');
    }
    final expected = _today.day / _daysInMonth(_today);
    final actual = _ratio(_monthExpenseTotal, _monthlyLimit);
    final label = actual > expected * 1.15
        ? 'gyors'
        : actual < expected * 0.80
        ? 'lassú'
        : 'normál';
    return FastInfoMetricResult(
      pillValue: label,
      boxValue: '${label[0].toUpperCase()}${label.substring(1)} tempó',
      boxSubtitle: 'Aktuális ${_percent(actual)}%, várt ${_percent(expected)}%',
      progress: actual,
      series: <double>[expected, actual],
    );
  }

  FastInfoMetricResult _projectedMonthEndSpend() {
    final elapsedDays = math.max(1, _today.day);
    final projected = _monthExpenseTotal / elapsedDays * _daysInMonth(_today);
    return FastInfoMetricResult(
      pillValue: _compactAmount(projected),
      boxValue: formatHuf(projected),
      boxSubtitle: 'Becsült hó végi összeg',
      progress: _ratio(projected, _monthlyLimit),
      series: _dailySeries(14),
    );
  }

  FastInfoMetricResult _overspendRisk() {
    final projected =
        _monthExpenseTotal / math.max(1, _today.day) * _daysInMonth(_today);
    final ratio = _ratio(projected, _monthlyLimit);
    final label = ratio >= 1
        ? 'magas'
        : ratio >= 0.85
        ? 'közepes'
        : 'alacsony';
    return _status(
      label,
      _capitalize(label),
      'Becsült hó végi kockázat',
      progress: ratio,
    );
  }

  FastInfoMetricResult _fastestCategoryLimit() {
    final states = _categoryLimitStates();
    if (states.isEmpty) {
      return _status('nincs', 'Nincs kategórialimit', 'Nincs aktív limit');
    }
    states.sort((a, b) => b.ratio.compareTo(a.ratio));
    final state = states.first;
    return FastInfoMetricResult(
      pillValue: state.name,
      boxValue: '${state.name} ${_percent(state.ratio)}%',
      boxSubtitle: 'A limit közelében',
      progress: state.ratio,
    );
  }

  FastInfoMetricResult _categoryLimitCount({required bool over}) {
    final count = _categoryLimitStates()
        .where((state) => over ? state.ratio >= 1 : state.ratio >= 0.85)
        .length;
    return FastInfoMetricResult(
      pillValue: '$count db',
      boxValue: '$count kategória',
      boxSubtitle: over ? 'Limit felett' : 'Limit közelében',
      progress: math.min(1, count / 5),
    );
  }

  FastInfoMetricResult _todayTransactionCount() {
    final count = _inRange(
      _datedRecords,
      _today,
      _today.add(const Duration(days: 1)),
    ).length;
    return FastInfoMetricResult(
      pillValue: '$count db',
      boxValue: '$count tranzakció',
      boxSubtitle: 'Mai aktivitás',
      progress: math.min(1, count / 10),
    );
  }

  FastInfoMetricResult _sourceApp() {
    final latest = _datedRecords.isEmpty ? null : _datedRecords.first.record;
    final source = latest == null ? 'Nincs' : latest.displayMerchant;
    return _status(source, source, 'Utolsó ismert forrás');
  }

  FastInfoMetricResult _unknownMerchants() {
    final count = _transactions
        .where((record) => record.displayMerchant.trim().isEmpty)
        .length;
    return FastInfoMetricResult(
      pillValue: '$count',
      boxValue: '$count új név',
      boxSubtitle: 'Kategorizálásra vár',
      progress: math.min(1, count / 10),
    );
  }

  FastInfoMetricResult _newMerchantToday() {
    final previous = _datedRecords
        .where((row) => row.date.isBefore(_today))
        .map((row) => row.record.displayMerchant)
        .toSet();
    final today = _inRange(
      _datedRecords,
      _today,
      _today.add(const Duration(days: 1)),
    ).map((row) => row.record.displayMerchant).toSet();
    final count = today
        .where((merchant) => !previous.contains(merchant))
        .length;
    return FastInfoMetricResult(
      pillValue: '$count',
      boxValue: '$count új kereskedő',
      boxSubtitle: 'Ma először láttuk',
      progress: math.min(1, count / 5),
    );
  }

  FastInfoMetricResult _topMerchant(
    List<_DatedTransaction> records,
    String subtitle,
  ) {
    final counts = <String, double>{};
    for (final row in records) {
      final merchant = row.record.displayMerchant.trim();
      if (merchant.isEmpty) continue;
      counts[merchant] = (counts[merchant] ?? 0) + row.record.amount.abs();
    }
    if (counts.isEmpty) return _status('nincs', 'Nincs adat', subtitle);
    final entry = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return FastInfoMetricResult(
      pillValue: _shortText(entry.key),
      boxValue: entry.key,
      boxSubtitle: subtitle,
      progress: _ratio(
        entry.value,
        records.fold<double>(0, (sum, row) => sum + row.record.amount.abs()),
      ),
    );
  }

  FastInfoMetricResult _averageDailySpend() {
    final activeDays = _monthExpenses.map((row) => _dateKey(row.date)).toSet();
    final divisor = math.max(1, activeDays.length);
    final average = _monthExpenseTotal / divisor;
    return FastInfoMetricResult(
      pillValue: _compactAmount(average),
      boxValue: formatHuf(average),
      boxSubtitle: '$divisor aktív nap alapján',
      progress: _ratio(average, _dailySuggestedMax),
      series: _dailySeries(7),
    );
  }

  FastInfoMetricResult _weekendWeekdaySpend() {
    final weekend = _monthExpenses
        .where((row) => row.date.weekday >= DateTime.saturday)
        .fold<double>(0, (sum, row) => sum + row.record.amount.abs());
    final weekday = math.max(0.0, _monthExpenseTotal - weekend);
    final weekendRatio = _ratio(weekend, _monthExpenseTotal);
    final weekdayRatio = _ratio(weekday, _monthExpenseTotal);
    final text = '${_percent(weekendRatio)}/${_percent(weekdayRatio)}';
    return FastInfoMetricResult(
      pillValue: text,
      boxValue: '${_percent(weekendRatio)}% / ${_percent(weekdayRatio)}%',
      boxSubtitle: 'Hétvége és hétköznap',
      progress: weekendRatio,
      series: <double>[weekend, weekday],
    );
  }

  FastInfoMetricResult _todayAgainstAverage() {
    final average = _averageMonthlyDaySpend();
    return _trend(_todayExpenseTotal, average);
  }

  FastInfoMetricResult _monthlyAnomaly() {
    final average = _averageMonthlyDaySpend();
    final large = _monthExpenses
        .where((row) => row.record.amount.abs() > average * 2)
        .length;
    if (large == 0) {
      return _status('nincs', 'Nincs anomália', 'Szokásos mintázat');
    }
    return FastInfoMetricResult(
      pillValue: '$large',
      boxValue: '$large anomália',
      boxSubtitle: 'Átlag feletti tételek',
      progress: math.min(1, large / 5),
    );
  }

  FastInfoMetricResult _largeItems() {
    final average = _averageMonthlyDaySpend();
    final count = _monthExpenses
        .where((row) => row.record.amount.abs() > average * 2)
        .length;
    return FastInfoMetricResult(
      pillValue: '$count',
      boxValue: '$count nagy tétel',
      boxSubtitle: 'Ellenőrizhető tranzakció',
      progress: math.min(1, count / 5),
    );
  }

  FastInfoMetricResult _savingStreak() {
    final average = _averageMonthlyDaySpend();
    var streak = 0;
    for (
      var day = _today;
      !day.isBefore(_monthStart);
      day = day.subtract(const Duration(days: 1))
    ) {
      final spent = _sumAbs(
        _inRange(_expenses, day, day.add(const Duration(days: 1))),
      );
      if (spent > average) break;
      streak += 1;
    }
    return FastInfoMetricResult(
      pillValue: '$streak nap',
      boxValue: '$streak nap',
      boxSubtitle: 'Átlag alatti költés',
      progress: math.min(1, streak / 7),
    );
  }

  FastInfoMetricResult _noSpendDays() {
    final spentDays = _monthExpenses.map((row) => _dateKey(row.date)).toSet();
    var count = 0;
    for (var day = 1; day <= _today.day; day += 1) {
      if (!spentDays.contains(
        '${_today.year}-${_two(_today.month)}-${_two(day)}',
      )) {
        count += 1;
      }
    }
    return FastInfoMetricResult(
      pillValue: '$count nap',
      boxValue: '$count nap',
      boxSubtitle: 'Költés nélküli napok',
      progress: _ratio(count.toDouble(), _today.day.toDouble()),
    );
  }

  FastInfoMetricResult _topCategory(
    List<_DatedTransaction> records,
    String subtitle,
  ) {
    final sums = _categorySums(records);
    if (sums.isEmpty) return _status('nincs', 'Nincs adat', subtitle);
    final entry = sums.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final name = _categoryName(entry.key);
    return FastInfoMetricResult(
      pillValue: _shortText(name),
      boxValue: name,
      boxSubtitle: subtitle,
      progress: _ratio(
        entry.value,
        sums.values.fold<double>(0, (sum, value) => sum + value),
      ),
    );
  }

  FastInfoMetricResult _categoryDelta({required bool growing}) {
    final current = _categorySums(_monthExpenses);
    final previous = _categorySums(_previousMonthExpenses);
    String? bestName;
    double bestDelta = growing ? double.negativeInfinity : double.infinity;
    for (final id in {...current.keys, ...previous.keys}) {
      final prev = previous[id] ?? 0;
      final curr = current[id] ?? 0;
      if (prev <= 0 && curr <= 0) continue;
      final delta = prev <= 0 ? 1.0 : (curr - prev) / prev;
      if ((growing && delta > bestDelta) || (!growing && delta < bestDelta)) {
        bestDelta = delta;
        bestName = _categoryName(id);
      }
    }
    if (bestName == null) {
      return _status('nincs', 'Nincs adat', 'Nincs összevetés');
    }
    final text = '${bestDelta >= 0 ? '+' : ''}${(bestDelta * 100).round()}%';
    return FastInfoMetricResult(
      pillValue: _shortText(bestName),
      boxValue: '$bestName $text',
      boxSubtitle: growing ? 'Legnagyobb növekedés' : 'Legnagyobb csökkenés',
      progress: math.min(1, bestDelta.abs()),
    );
  }

  FastInfoMetricResult _nearCategoryLimits() {
    final count = _categoryLimitStates()
        .where((state) => state.ratio >= 0.85 && state.ratio < 1)
        .length;
    return FastInfoMetricResult(
      pillValue: '$count db',
      boxValue: '$count kategória',
      boxSubtitle: 'Limit közelében',
      progress: math.min(1, count / 5),
    );
  }

  FastInfoMetricResult _uncategorizedTransactions() {
    final count = _transactions
        .where(
          (record) =>
              !_categoriesById.containsKey(record.transactionCategoryID),
        )
        .length;
    return FastInfoMetricResult(
      pillValue: '$count db',
      boxValue: '$count tranzakció',
      boxSubtitle: 'Kategóriára vár',
      progress: math.min(1, count / 10),
    );
  }

  FastInfoMetricResult _categoryWithoutTodaySpend() {
    final spentToday = _todayExpenses
        .map((row) => row.record.transactionCategoryID)
        .toSet();
    final category = _categories.firstWhere(
      (item) =>
          item.normalizedType == TransactionType.expense &&
          !spentToday.contains(item.transactionCategoryID),
      orElse: () => _categories.isNotEmpty ? _categories.first : _emptyCategory,
    );
    return _status(
      _shortText(category.name),
      category.name,
      'Ma még nincs költés',
    );
  }

  FastInfoMetricResult _nextFixedExpense() {
    final groups = _fixedMerchantGroups();
    if (groups.isEmpty) {
      return _status('nincs', 'Nincs fix tétel', 'Nincs ismétlődő minta');
    }
    final next = groups.first;
    return _status(
      _shortText(next.merchant),
      next.merchant,
      '${next.nextDueInDays} nap múlva',
      progress: _ratio(next.currentMonthAmount, _monthlyLimit),
    );
  }

  FastInfoMetricResult _expectedFixedExpense({required int days}) {
    final amount = _fixedMerchantGroups()
        .where((group) => group.nextDueInDays <= days)
        .fold<double>(0, (sum, group) => sum + group.averageAmount);
    final subtitle = days == 1 ? 'Ma esedékes fix tétel' : '$days napon belül';
    if (amount <= 0 && days == 1) {
      return _status('0', 'Nincs ma', 'Ma nincs esedékes fix tétel');
    }
    return FastInfoMetricResult(
      pillValue: _compactAmount(amount),
      boxValue: formatHuf(amount),
      boxSubtitle: subtitle,
      progress: _ratio(amount, _monthlyLimit),
    );
  }

  FastInfoMetricResult _monthlyFixedCost() {
    return FastInfoMetricResult(
      pillValue: _compactAmount(_monthlyFixedTotal),
      boxValue: formatHuf(_monthlyFixedTotal),
      boxSubtitle: 'Fix havi tételek',
      progress: _ratio(_monthlyFixedTotal, _monthlyLimit),
    );
  }

  FastInfoMetricResult _largestFixedExpense() {
    final groups = _fixedMerchantGroups();
    if (groups.isEmpty) {
      return _status('nincs', 'Nincs fix tétel', 'Legnagyobb fix tétel');
    }
    groups.sort((a, b) => b.averageAmount.compareTo(a.averageAmount));
    final group = groups.first;
    return _status(
      _shortText(group.merchant),
      group.merchant,
      'Legnagyobb fix tétel',
      progress: _ratio(group.averageAmount, _monthlyLimit),
    );
  }

  FastInfoMetricResult _minimumBalanceWarning() {
    final balance = _allIncomeTotal - _allExpenseTotal;
    final ok = balance >= _monthlyLimit * 0.2;
    return _status(
      ok ? 'OK' : 'alacsony',
      ok ? 'OK' : 'Alacsony',
      'Aktuális egyenleg: ${formatHuf(balance)}',
    );
  }

  FastInfoMetricResult _cashCardRatio() {
    final cash = _expenses
        .where(
          (row) =>
              row.record.displayMerchant.toLowerCase().contains('készpénz'),
        )
        .length;
    final total = math.max(1, _expenses.length);
    final cashRatio = cash / total;
    final cardRatio = 1 - cashRatio;
    return FastInfoMetricResult(
      pillValue: '${_percent(cashRatio)}/${_percent(cardRatio)}',
      boxValue: '${_percent(cashRatio)}% / ${_percent(cardRatio)}%',
      boxSubtitle: 'Készpénz és kártya',
      progress: cardRatio,
    );
  }

  FastInfoMetricResult _cashflow() {
    final cashflow = _monthIncomeTotal - _monthExpenseTotal;
    return FastInfoMetricResult(
      pillValue: _signedCompact(cashflow),
      boxValue: '${cashflow >= 0 ? '+' : '-'}${formatHuf(cashflow.abs())}',
      boxSubtitle: 'Bevétel mínusz kiadás',
      progress: cashflow >= 0 ? 0.75 : 0.25,
      series: <double>[_monthIncomeTotal, _monthExpenseTotal],
    );
  }

  FastInfoMetricResult _savings() {
    final savings = math.max(0.0, _monthIncomeTotal - _monthExpenseTotal);
    return FastInfoMetricResult(
      pillValue: _compactAmount(savings),
      boxValue: formatHuf(savings),
      boxSubtitle: 'Havi bevétel mínusz kiadás',
      progress: _ratio(savings, _monthIncomeTotal),
    );
  }

  FastInfoMetricResult _balance() {
    final balance = _allIncomeTotal - _allExpenseTotal;
    return FastInfoMetricResult(
      pillValue: _signedCompact(balance),
      boxValue: '${balance >= 0 ? '+' : '-'}${formatHuf(balance.abs())}',
      boxSubtitle: 'Becsült aktuális egyenleg',
      progress: balance >= 0 ? 0.70 : 0.30,
    );
  }

  FastInfoMetricResult _monthEndRemaining() {
    final projected =
        _monthExpenseTotal / math.max(1, _today.day) * _daysInMonth(_today);
    final remaining = _monthIncomeTotal - projected;
    return FastInfoMetricResult(
      pillValue: _signedCompact(remaining),
      boxValue: '${remaining >= 0 ? '+' : '-'}${formatHuf(remaining.abs())}',
      boxSubtitle: 'Becsült maradék',
      progress: _ratio(math.max(0, remaining), _monthIncomeTotal),
      series: _dailySeries(14),
    );
  }

  FastInfoMetricResult _savingsRate() {
    final savings = _monthIncomeTotal - _monthExpenseTotal;
    return _ratioMetric(
      math.max(0.0, savings),
      _monthIncomeTotal,
      'Bevételhez képest',
    );
  }

  FastInfoMetricResult _bufferDays() {
    final dailyAverage = math.max(1, _averageMonthlyDaySpend());
    final days = ((_allIncomeTotal - _allExpenseTotal) / dailyAverage).floor();
    final safeDays = math.max(0, days);
    return FastInfoMetricResult(
      pillValue: '$safeDays nap',
      boxValue: '$safeDays nap',
      boxSubtitle: 'Tartalék becslés',
      progress: math.min(1, safeDays / 30),
    );
  }

  FastInfoMetricResult _rowCount() {
    final rows = _transactions.length + _categories.length + _limits.length;
    return FastInfoMetricResult(
      pillValue: _compactCount(rows),
      boxValue: '$rows sor',
      boxSubtitle: 'Lokális adatbázis',
      progress: math.min(1, rows / 5000),
    );
  }

  FastInfoMetricResult _incompleteTransactions() {
    final count = _transactions
        .where(
          (record) => record.date.isEmpty || record.merchant.trim().isEmpty,
        )
        .length;
    return FastInfoMetricResult(
      pillValue: '$count',
      boxValue: '$count hiányos',
      boxSubtitle: 'Ellenőrzést igényel',
      progress: math.min(1, count / 10),
    );
  }

  FastInfoMetricResult _duplicateSuspects() {
    final seen = <String>{};
    var duplicates = 0;
    for (final row in _datedRecords) {
      final key =
          '${_dateKey(row.date)}|${row.record.displayMerchant}|${row.record.amount}';
      if (!seen.add(key)) duplicates += 1;
    }
    return FastInfoMetricResult(
      pillValue: '$duplicates',
      boxValue: '$duplicates gyanús',
      boxSubtitle: 'Lehetséges duplikátumok',
      progress: math.min(1, duplicates / 10),
    );
  }

  FastInfoMetricResult _parseAccuracy() {
    final incomplete = _transactions
        .where(
          (record) => record.date.isEmpty || record.merchant.trim().isEmpty,
        )
        .length;
    final total = math.max(1, _transactions.length);
    final ratio = 1 - incomplete / total;
    return FastInfoMetricResult(
      pillValue: '${_percent(ratio)}%',
      boxValue: '${_percent(ratio)}%',
      boxSubtitle: 'Becsült feldolgozási arány',
      progress: ratio,
    );
  }

  FastInfoMetricResult _zeroStatus(String boxValue, String subtitle) {
    return FastInfoMetricResult(
      pillValue: '0',
      boxValue: boxValue,
      boxSubtitle: subtitle,
      progress: 0,
    );
  }

  FastInfoMetricResult _status(
    String pillValue,
    String boxValue,
    String subtitle, {
    double? progress,
  }) {
    return FastInfoMetricResult(
      pillValue: pillValue,
      boxValue: boxValue,
      boxSubtitle: subtitle,
      progress: progress ?? 0.5,
    );
  }

  List<_DatedTransaction> _inRange(
    List<_DatedTransaction> source,
    DateTime start,
    DateTime end,
  ) {
    final from = _dateOnly(start);
    final to = _dateOnly(end);
    return source
        .where((row) => !row.date.isBefore(from) && row.date.isBefore(to))
        .toList(growable: false);
  }

  double _overviewLimit(LimitWindow window, String periodKey) {
    final matching = _limits.where(
      (limit) =>
          limit.targetType == LimitTargetType.overview &&
          limit.window == window &&
          limit.periodKey == periodKey &&
          limit.hasLimit &&
          TransactionTypeX.fromAny(limit.transactionType) ==
              TransactionType.expense,
    );
    if (matching.isNotEmpty) return matching.first.limitAmount;
    final categoryLimitTotal = _limits
        .where(
          (limit) =>
              limit.targetType == LimitTargetType.category &&
              limit.window == window &&
              limit.periodKey == periodKey &&
              limit.hasLimit,
        )
        .fold<double>(0, (sum, limit) => sum + limit.limitAmount);
    if (categoryLimitTotal > 0) return categoryLimitTotal;
    return _categories
        .where(
          (category) =>
              category.normalizedType == TransactionType.expense &&
              category.hasLimit,
        )
        .fold<double>(0, (sum, category) => sum + category.limitAmount);
  }

  List<_CategoryLimitState> _categoryLimitStates() {
    final spentByCategory = _categorySums(_monthExpenses);
    final states = <_CategoryLimitState>[];
    for (final limit in _limits) {
      if (limit.targetType != LimitTargetType.category ||
          limit.window != LimitWindow.monthly ||
          limit.periodKey != _monthKey ||
          !limit.hasLimit ||
          limit.limitAmount <= 0) {
        continue;
      }
      final spent = spentByCategory[limit.targetId] ?? 0;
      states.add(
        _CategoryLimitState(
          name: _categoryName(limit.targetId),
          spent: spent,
          limit: limit.limitAmount,
        ),
      );
    }
    if (states.isNotEmpty) return states;
    for (final category in _categories.where(
      (item) => item.hasLimit && item.limitAmount > 0,
    )) {
      final spent = spentByCategory[category.transactionCategoryID] ?? 0;
      states.add(
        _CategoryLimitState(
          name: category.name,
          spent: spent,
          limit: category.limitAmount,
        ),
      );
    }
    return states;
  }

  Map<int, double> _categorySums(List<_DatedTransaction> records) {
    final sums = <int, double>{};
    for (final row in records) {
      final id = row.record.transactionCategoryID;
      sums[id] = (sums[id] ?? 0) + row.record.amount.abs();
    }
    return sums;
  }

  String _categoryName(int id) => _categoriesById[id]?.name ?? 'Ismeretlen';

  double _averageMonthlyDaySpend() {
    final elapsed = math.max(1, _today.day);
    return _monthExpenseTotal / elapsed;
  }

  List<double> _dailySeries(int days) {
    final start = _today.subtract(Duration(days: days - 1));
    return List<double>.unmodifiable([
      for (var index = 0; index < days; index += 1)
        _sumAbs(
          _inRange(
            _expenses,
            start.add(Duration(days: index)),
            start.add(Duration(days: index + 1)),
          ),
        ),
    ]);
  }

  List<_FixedMerchantGroup> _fixedMerchantGroups() {
    final groups = <String, List<_DatedTransaction>>{};
    for (final row in _expenses) {
      final merchant = row.record.displayMerchant.trim();
      if (merchant.isEmpty) continue;
      groups.putIfAbsent(merchant, () => <_DatedTransaction>[]).add(row);
    }
    final result = <_FixedMerchantGroup>[];
    for (final entry in groups.entries) {
      final months = entry.value.map((row) => _periodKey(row.date)).toSet();
      if (months.length < 3) continue;
      final current = _inRange(entry.value, _monthStart, _nextMonthStart);
      final average =
          entry.value.fold<double>(
            0,
            (sum, row) => sum + row.record.amount.abs(),
          ) /
          entry.value.length;
      final dueDay =
          entry.value
              .map((row) => row.date.day)
              .fold<int>(1, (sum, day) => sum + day) ~/
          entry.value.length;
      final dueDate = DateTime(
        _today.year,
        _today.month,
        math.min(dueDay, _daysInMonth(_today)),
      );
      final nextDue = dueDate.isBefore(_today)
          ? DateTime(
              _today.year,
              _today.month + 1,
              math.min(
                dueDay,
                _daysInMonth(DateTime(_today.year, _today.month + 1)),
              ),
            )
          : dueDate;
      result.add(
        _FixedMerchantGroup(
          merchant: entry.key,
          averageAmount: average,
          currentMonthAmount: _sumAbs(current),
          nextDueInDays: nextDue.difference(_today).inDays,
        ),
      );
    }
    result.sort((a, b) => a.nextDueInDays.compareTo(b.nextDueInDays));
    return result;
  }

  static double _sumAbs(List<_DatedTransaction> records) {
    return records.fold<double>(0, (sum, row) => sum + row.record.amount.abs());
  }
}

class _DatedTransaction {
  const _DatedTransaction({required this.record, required this.date});

  final TransactionRecord record;
  final DateTime date;
}

class _CategoryLimitState {
  const _CategoryLimitState({
    required this.name,
    required this.spent,
    required this.limit,
  });

  final String name;
  final double spent;
  final double limit;

  double get ratio => _ratio(spent, limit);
}

class _FixedMerchantGroup {
  const _FixedMerchantGroup({
    required this.merchant,
    required this.averageAmount,
    required this.currentMonthAmount,
    required this.nextDueInDays,
  });

  final String merchant;
  final double averageAmount;
  final double currentMonthAmount;
  final int nextDueInDays;
}

final _emptyCategory = TransactionCategory(
  transactionCategoryID: -1,
  name: 'Nincs kategória',
  type: TransactionType.expense.nativeValue,
  colorSlot: null,
  iconSlot: null,
  backgroundColor: null,
  icon: null,
  notification: null,
  hasLimit: false,
  limitAmount: 0,
  alertActive: false,
  isCustomIcon: false,
  originalIcon: null,
);

DateTime _parseDate(String value) {
  final normalized = value.replaceAll('.', '-');
  return _dateOnly(DateTime.tryParse(normalized) ?? DateTime(1970));
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _dateKey(DateTime value) =>
    '${value.year}-${_two(value.month)}-${_two(value.day)}';

String _periodKey(DateTime value) => '${value.year}-${_two(value.month)}';

String _two(int value) => value.toString().padLeft(2, '0');

int _daysInMonth(DateTime value) =>
    DateTime(value.year, value.month + 1, 0).day;

double _ratio(double numerator, double denominator) {
  if (denominator <= 0) return 0;
  return (numerator / denominator).clamp(0, 1).toDouble();
}

int _percent(double ratio) => (ratio.clamp(0, 1) * 100).round();

String _compactAmount(num amount) {
  final absolute = amount.abs();
  if (absolute >= 1000000) return '${_trim(absolute / 1000000)}m';
  if (absolute >= 1000) return '${_trim(absolute / 1000)}k';
  return absolute.round().toString();
}

String _signedCompact(num amount) {
  final sign = amount >= 0 ? '+' : '-';
  return '$sign${_compactAmount(amount.abs())}';
}

String _compactCount(int count) {
  if (count >= 1000) return '${_trim(count / 1000)}k';
  return count.toString();
}

String _trim(num value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1);
}

String _shortText(String value) {
  final trimmed = value.trim();
  if (trimmed.length <= 8) return trimmed;
  return trimmed.substring(0, 8);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _timeText(DateTime value) => '${_two(value.hour)}:${_two(value.minute)}';

final Map<String, FastInfoMetricResult> _previewMetrics =
    FastInfoMetricsResolver.resolve(
      transactions: _previewTransactions,
      categories: _previewCategories,
      limits: _previewLimits,
      now: DateTime(2026, 6, 3, 12),
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
    hasLimit: true,
    limitAmount: 60000,
    alertActive: true,
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

const _previewLimits = <CategoryLimit>[
  CategoryLimit(
    id: 1,
    targetType: LimitTargetType.overview,
    targetId: 0,
    transactionType: 'expense',
    window: LimitWindow.monthly,
    periodKey: '2026-06',
    hasLimit: true,
    limitAmount: 100000,
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

const _previewTransactions = <TransactionRecord>[
  TransactionRecord(
    id: 1,
    date: '2026.06.03',
    time: '09:10',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Pékség',
    amount: -3000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 2,
    date: '2026.06.03',
    time: '11:30',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Ebéd',
    amount: -4000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 3,
    date: '2026.06.02',
    time: '17:30',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Bolt',
    amount: -12000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 4,
    date: '2026.06.01',
    time: '18:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Piac',
    amount: -8000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 5,
    date: '2026.05.15',
    time: '10:00',
    latitude: null,
    longitude: null,
    address: null,
    merchant: 'Előző hónap',
    amount: -30000,
    userAssignedName: null,
    transactionCategoryID: 1,
  ),
  TransactionRecord(
    id: 6,
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
