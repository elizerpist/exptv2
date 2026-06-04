# FastInfo Catalog Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 78-card FastInfo catalog with the approved 18 live-data cards, migrate old configurations, and render the agreed compact trends, avatars, limits, bars, rings, and charts.

**Architecture:** Keep `FastInfoConfig` as the persisted slot-identity model, but canonicalize legacy IDs during load and stop using saved demo values at runtime. Build one immutable snapshot and reusable period aggregate object, resolve all 18 cards into a structured render model, then let shared FastInfo widgets render that model. Use existing Flutter widgets and `CustomPainter`; add no chart dependency.

**Tech Stack:** Flutter/Dart, existing `TransactionStore`, existing category icons/colors and recurring ghosts, Flutter widget/unit tests, Git.

---

## File Structure

- Modify: `lib/features/settings/models/fast_info_card_catalog.dart`
  - Contains only the 18 canonical definitions, default IDs, and legacy-to-canonical ID map.
- Modify: `lib/features/settings/models/fast_info_config.dart`
  - Migrates, removes, and globally deduplicates persisted slots while retaining legacy field parsing.
- Create: `lib/features/transactions/models/fast_info_metric.dart`
  - Defines structured result, trend, semantic state, avatar, chart series, and weekly bar point types.
- Create: `lib/features/transactions/models/fast_info_metric_snapshot.dart`
  - Defines immutable resolver input from store data.
- Create: `lib/features/transactions/data/fast_info_period_aggregates.dart`
  - Parses transaction dates once and exposes reusable day/week/month/rolling aggregates and ranking helpers.
- Create: `lib/features/transactions/data/fast_info_preview_data.dart`
  - Builds deterministic settings-preview metrics through the real resolver contract.
- Rewrite: `lib/features/transactions/state/fast_info_metrics_resolver.dart`
  - Resolves exactly the 18 canonical cards from snapshot/aggregates.
- Modify: `lib/features/transactions/state/transaction_store.dart`
  - Builds the snapshot with real balance, goals, limits, and recurring ghosts; invalidates cache on every relevant change.
- Modify: `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`
  - Renders semantic progress/ring/trend/avatar/sparkline/weekly-bars/multi-line visuals without fallback filler graphics.
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
  - Renders structured rows and 112 px boxes; never falls back to saved demo values.
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`
  - Raises live FastInfo surface height to 328 px.
- Modify: `lib/features/settings/widgets/options/fast_info_options_panel.dart`
  - Uses the 18-card pool, deterministic preview, and taller preview surface.
- Modify tests:
  - `test/settings/fast_info_card_catalog_test.dart`
  - `test/settings/fast_info_options_panel_test.dart`
  - `test/settings/settings_bridge_test.dart`
  - `test/transactions/fast_info_metrics_resolver_test.dart`
  - `test/transactions/fast_info_panel_test.dart`
  - `test/transactions/transaction_store_test.dart`
- Create tests:
  - `test/transactions/fast_info_period_aggregates_test.dart`
  - `test/transactions/fast_info_category_metrics_test.dart`
  - `test/transactions/fast_info_recurring_metrics_test.dart`

## Command Convention

Run Flutter commands from Termux through Ubuntu:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter <command>'
```

---

### Task 1: Reduce the Catalog and Migrate Persisted Configurations

**Files:**
- Modify: `lib/features/settings/models/fast_info_card_catalog.dart`
- Modify: `lib/features/settings/models/fast_info_config.dart`
- Test: `test/settings/fast_info_card_catalog_test.dart`
- Test: `test/settings/settings_bridge_test.dart`

- [ ] **Step 1: Replace catalog expectations with failing canonical/migration tests**

In `test/settings/fast_info_card_catalog_test.dart`, replace the large-catalog assertion and add migration coverage:

```dart
const expectedIds = <String>{
  'mai_koltes', 'heti_koltes', 'havi_koltes', 'megtakaritas',
  'koltesi_trend', 'legutobbi_tranzakcio', 'varhato_ho_vegi_koltes',
  'leggyorsabban_fogyo_kategorialimit', 'leggyakoribb_kereskedo',
  'atlagos_napi_koltes', 'no_spend_napok_szama', 'top_kategoria_ma',
  'top_kategoria_heten', 'legnagyobb_novekedo_kategoria',
  'kovetkezo_ismetlo_kiadas', 'havi_fix_koltseg_osszesen',
  'bevetel_ebben_a_honapban', 'kiadas_bevetel_arany',
};

test('catalog exposes exactly the approved canonical cards', () {
  expect(fastInfoCardCatalog.map((card) => card.id).toSet(), expectedIds);
  expect(fastInfoCardCatalog, hasLength(18));
  expect(fastInfoCardById('debug_riasztasok'), isNull);
});

test('config maps merged ids, removes deleted ids, and globally deduplicates', () {
  final config = FastInfoConfig.fromMap({
    'pills': [
      {'id': 'havi_limit_allapot', 'type': 'pill'},
      {'id': 'mai_koltes', 'type': 'pill'},
      {'id': 'debug_riasztasok', 'type': 'pill'},
    ],
    'boxes': [
      {'id': 'havi_koltes', 'type': 'box'},
      {'id': 'puffer_napok_szama', 'type': 'box'},
      {'id': 'top_kategoria_honapban', 'type': 'box'},
    ],
  });

  expect(config.pills.map((slot) => slot?.id).toList(), ['havi_koltes', 'mai_koltes', null]);
  expect(config.boxes.map((slot) => slot?.id).toList(), [null, 'atlagos_napi_koltes', 'top_kategoria_heten']);
});
```

Update the defaults test to require six unique retained IDs:

```dart
expect(config.pills.map((slot) => slot?.id).toList(), [
  'havi_koltes', 'koltesi_trend', 'kiadas_bevetel_arany',
]);
expect(config.boxes.map((slot) => slot?.id).toList(), [
  'mai_koltes', 'heti_koltes', 'kovetkezo_ismetlo_kiadas',
]);
expect({for (final slot in [...config.pills, ...config.boxes]) slot?.id}, hasLength(6));
```

In `test/settings/settings_bridge_test.dart`, change the unknown `mai_nap` box expectation to `isNull` and add a loaded `havi_limit_allapot` slot that is expected to become `havi_koltes`.

- [ ] **Step 2: Run the catalog and bridge tests and verify they fail**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/fast_info_card_catalog_test.dart test/settings/settings_bridge_test.dart'
```

Expected: FAIL because the catalog still has 78 cards and `FastInfoConfig.fromMap` does not canonicalize or deduplicate IDs.

- [ ] **Step 3: Replace the catalog with the canonical list and map**

In `fast_info_card_catalog.dart`, keep `FastInfoVisualType` only for legacy slot parsing, reduce `FastInfoCardDefinition` to identity/title fields used by settings, define the six defaults from Step 1, and add:

```dart
const fastInfoLegacyIdMap = <String, String>{
  'mai_maradek_keret': 'mai_koltes', 'napi_ajanlott_maximum': 'mai_koltes',
  'mai_koltes_ajanlotthoz': 'mai_koltes', 'mai_nap_atlaghoz_kepest': 'mai_koltes',
  'ma_rogzitett_tranzakciok_szama': 'mai_koltes',
  'heti_maradek_keret': 'heti_koltes', 'ez_a_het_elozo_hethez': 'heti_koltes',
  'havi_limit_allapot': 'havi_koltes', 'ez_a_honap_elozo_honaphoz': 'havi_koltes',
  'megtakaritasi_cel_haladas': 'megtakaritas', 'havi_megtakaritasi_rata': 'megtakaritas',
  'havi_keret_egesi_sebesseg': 'koltesi_trend',
  'tulkoltes_kockazat': 'varhato_ho_vegi_koltes',
  'ho_vegi_becsult_maradek': 'varhato_ho_vegi_koltes',
  'limit_feletti_kategoriak_szama': 'leggyorsabban_fogyo_kategorialimit',
  'kategoria_limit_kozeleben': 'leggyorsabban_fogyo_kategorialimit',
  'kategoria_limit_tullepve': 'leggyorsabban_fogyo_kategorialimit',
  'puffer_napok_szama': 'atlagos_napi_koltes',
  'top_kategoria_honapban': 'top_kategoria_heten',
  'legjobban_csokkeno_kategoria': 'legnagyobb_novekedo_kategoria',
  'kovetkezo_7_nap_fix_kiadasai': 'kovetkezo_ismetlo_kiadas',
  'fix_koltseg_aranya_havi_keretbol': 'havi_fix_koltseg_osszesen',
  'mar_levont_fix_kiadasok': 'havi_fix_koltseg_osszesen',
  'meg_varhato_fix_kiadasok': 'havi_fix_koltseg_osszesen',
  'legnagyobb_fix_kiadas': 'havi_fix_koltseg_osszesen',
  'fix_koltsegek_utan_marado_keret': 'havi_fix_koltseg_osszesen',
  'netto_havi_cashflow': 'kiadas_bevetel_arany',
};
```

```dart
String? canonicalFastInfoCardId(String id) {
  final canonical = fastInfoLegacyIdMap[id] ?? id;
  return fastInfoCardById(canonical) == null ? null : canonical;
}
```

Define all 18 titles exactly as approved, including `30 napos költési trend`, `Kategórialimit állapot`, `Top kategória héten/hónapban`, and `Havi bevétel`.

Update `FastInfoSlot.fromCard` to persist identity only: `id`, canonical `label`, empty legacy `value`, requested `type`, and `FastInfoVisualType.plain`. Keep optional legacy fields parseable from old maps, but do not create new demo values.

- [ ] **Step 4: Implement stable migration in `FastInfoConfig.fromMap`**

Parse raw slot maps first, then canonicalize in pill-then-box order with one shared `seen` set:

```dart
factory FastInfoConfig.fromMap(Map<dynamic, dynamic> map) {
  final seen = <String>{};
  FastInfoSlot? migrate(Object? raw, FastInfoSlotType type) {
    if (raw is! Map<dynamic, dynamic>) return null;
    final id = canonicalFastInfoCardId(raw['id']?.toString() ?? '');
    if (id == null || !seen.add(id)) return null;
    return FastInfoSlot.fromCard(fastInfoCardById(id)!, type);
  }

  final rawPills = rawFixedSlots(map['pills']);
  final rawBoxes = rawFixedSlots(map['boxes']);
  return FastInfoConfig(
    pills: [for (final raw in rawPills) migrate(raw, FastInfoSlotType.pill)],
    boxes: [for (final raw in rawBoxes) migrate(raw, FastInfoSlotType.box)],
  );
}
```

Keep `FastInfoSlot.fromMap` and legacy fields available for direct backwards-compatible parsing, but ensure normal config loading rebuilds from the canonical definition and never moves empty positions.

- [ ] **Step 5: Run tests and commit**

Run the command from Step 2. Expected: PASS.

```bash
git add lib/features/settings/models/fast_info_card_catalog.dart lib/features/settings/models/fast_info_config.dart test/settings/fast_info_card_catalog_test.dart test/settings/settings_bridge_test.dart
git commit -m "Refine FastInfo catalog migration"
```

---

### Task 2: Add Structured Metric Models and Reusable Period Aggregates

**Files:**
- Create: `lib/features/transactions/models/fast_info_metric.dart`
- Create: `lib/features/transactions/models/fast_info_metric_snapshot.dart`
- Create: `lib/features/transactions/data/fast_info_period_aggregates.dart`
- Create: `test/transactions/fast_info_period_aggregates_test.dart`

- [ ] **Step 1: Write failing aggregate boundary tests**

Create `fast_info_period_aggregates_test.dart` with a March 31 snapshot and transactions on March 31, March 30, March 25, February 28, and February 25. Assert:

```dart
expect(data.todayExpense, 1000);
expect(data.currentMonthExpense, 6000);
expect(data.previousMonthSameDayExpense, 9000);
expect(data.rolling30Expense, 6000);
expect(data.previousRolling30Expense, 9000);
expect(data.currentMonthDailySeries, hasLength(31));
expect(data.previousMonthDailySeries, hasLength(28));
```

Add a Wednesday snapshot test asserting seven Monday-Sunday values and that Thursday-Sunday entries have `isFuture == true`.

- [ ] **Step 2: Run the aggregate test and verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_period_aggregates_test.dart'
```

Expected: FAIL because the snapshot, structured types, and aggregate class do not exist.

- [ ] **Step 3: Define the structured metric model**

Create `fast_info_metric.dart` with immutable types:

```dart
enum FastInfoProgressKind { bar, ring }
enum FastInfoChartKind { sparkline, weeklyBars, multiLine }
enum FastInfoSemantic { neutral, good, warning, bad }
enum FastInfoTrendDirection { up, down }

class FastInfoTrend {
  const FastInfoTrend({required this.direction, required this.text, required this.semantic});
  final FastInfoTrendDirection direction;
  final String text;
  final FastInfoSemantic semantic;
}

class FastInfoAvatar {
  const FastInfoAvatar({required this.colorHex, required this.iconSlot});
  final String colorHex;
  final int? iconSlot;
}

class FastInfoChartSeries {
  const FastInfoChartSeries({required this.label, required this.values});
  final String label;
  final List<double> values;
}

class FastInfoWeeklyBar {
  const FastInfoWeeklyBar({required this.value, required this.isFuture, required this.semantic});
  final double value;
  final bool isFuture;
  final FastInfoSemantic semantic;
}

class FastInfoMetricResult {
  const FastInfoMetricResult({
    required this.pillValue,
    required this.primaryValue,
    this.secondaryValues = const [],
    this.progressKind,
    this.chartKind,
    this.semantic = FastInfoSemantic.neutral,
    this.progress,
    this.trend,
    this.avatar,
    this.chartSeries = const [],
    this.weeklyBars = const [],
  });
  final String pillValue;
  final String primaryValue;
  final List<String> secondaryValues;
  final FastInfoProgressKind? progressKind;
  final FastInfoChartKind? chartKind;
  final FastInfoSemantic semantic;
  final double? progress;
  final FastInfoTrend? trend;
  final FastInfoAvatar? avatar;
  final List<FastInfoChartSeries> chartSeries;
  final List<FastInfoWeeklyBar> weeklyBars;
}
```

- [ ] **Step 4: Define snapshot and aggregate implementation**

Create `FastInfoMetricSnapshot` with unmodifiable transactions, categories, limits, recurring ghosts, required `now` and `balance`, and nullable `savingGoal`. Implement `FastInfoPeriodAggregates` so its constructor parses/sorts transaction dates once and exposes named totals, daily series, category groups, merchant groups, and recurring-ghost ranges used by later tasks. Preserve raw ratios; only painters clamp.

The weekly bar helper returns exactly seven entries:

```dart
List<FastInfoWeeklyBar> get currentWeekBars => List.generate(7, (index) {
  final date = weekStart.add(Duration(days: index));
  return FastInfoWeeklyBar(
    value: expenseOn(date),
    isFuture: date.isAfter(today),
    semantic: FastInfoSemantic.neutral,
  );
});
```

- [ ] **Step 5: Run tests and commit**

Run the command from Step 2. Expected: PASS.

```bash
git add lib/features/transactions/models/fast_info_metric.dart lib/features/transactions/models/fast_info_metric_snapshot.dart lib/features/transactions/data/fast_info_period_aggregates.dart test/transactions/fast_info_period_aggregates_test.dart
git commit -m "Add structured FastInfo metric data"
```

---

### Task 3: Implement Spend, Savings, Forecast, and Income Metrics

**Files:**
- Rewrite: `lib/features/transactions/state/fast_info_metrics_resolver.dart`
- Modify: `test/transactions/fast_info_metrics_resolver_test.dart`

- [ ] **Step 1: Replace legacy resolver assertions with failing approved-math tests**

Build a snapshot fixture at `DateTime(2026, 6, 3, 12)` with today's expense `7000`, June 1-2 expense `16000`, current-month income `150000`, rolling-30 expense `53000`, previous-rolling-30 expense `60000`, a `300000` monthly expense limit, `50000` saving goal, three calendar months of daily data, and `300000` real balance. Assert:

```dart
final metrics = FastInfoMetricsResolver.resolve(snapshot);
expect(metrics, hasLength(18));
expect(metrics['mai_koltes']?.primaryValue, '7 000 Ft elköltve');
expect(metrics['mai_koltes']?.progress, closeTo(7000 / ((300000 - 16000) / 28), 0.001));
expect(metrics['mai_koltes']?.semantic, FastInfoSemantic.good);
expect(metrics['heti_koltes']?.weeklyBars, hasLength(7));
expect(metrics['heti_koltes']?.weeklyBars.last.isFuture, isTrue);
expect(metrics['havi_koltes']?.chartSeries, hasLength(3));
expect(metrics['havi_koltes']?.chartSeries.first.values, hasLength(3));
expect(metrics['megtakaritas']?.progress, closeTo(127000 / 50000, 0.001));
expect(metrics['koltesi_trend']?.trend, isNotNull);
expect(metrics['koltesi_trend']?.progress, isNull);
expect(metrics['koltesi_trend']?.chartSeries, isEmpty);
expect(metrics['atlagos_napi_koltes']?.secondaryValues, contains('Puffer: 170 nap'));
expect(metrics['kiadas_bevetel_arany']?.progress, closeTo(23000 / 150000, 0.001));
```

Add separate tests for no monthly limit, no saving goal, zero income, zero prior period, exactly 75%, exactly 100%, and above 100%.

- [ ] **Step 2: Run the resolver test and verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_metrics_resolver_test.dart'
```

Expected: FAIL because the legacy resolver signature/result and calculations do not match the approved model.

- [ ] **Step 3: Rewrite resolver entry point and shared semantic helpers**

Use one aggregate instance and return one result for every canonical ID:

```dart
static Map<String, FastInfoMetricResult> resolve(FastInfoMetricSnapshot snapshot) {
  final scope = _FastInfoMetricScope(FastInfoPeriodAggregates(snapshot: snapshot));
  return Map.unmodifiable({
    for (final card in fastInfoCardCatalog) card.id: scope.safeMetricFor(card.id),
  });
}

FastInfoMetricResult safeMetricFor(String id) {
  try {
    return metricFor(id);
  } on Object {
    return const FastInfoMetricResult(
      pillValue: 'Nincs adat',
      primaryValue: 'Nincs adat',
    );
  }
}

FastInfoSemantic expenseSemantic(double ratio) {
  if (ratio > 1) return FastInfoSemantic.bad;
  if (ratio >= .75) return FastInfoSemantic.warning;
  return FastInfoSemantic.good;
}
```

Use `null` progress when a denominator is absent. Trend helpers return `null` when the comparison denominator is zero and apply opposite good/bad semantics for income versus expense.

- [ ] **Step 4: Implement the ten finance metrics**

Implement `mai_koltes`, `heti_koltes`, `havi_koltes`, `megtakaritas`, `koltesi_trend`, `varhato_ho_vegi_koltes`, `atlagos_napi_koltes`, `no_spend_napok_szama`, `bevetel_ebben_a_honapban`, and `kiadas_bevetel_arany`.

Required details:

- Daily ceiling subtracts current-month expense before today, not today's spend.
- Today's trend compares with rolling-30 daily average including zero-spend days.
- Weekly trend compares equal weekday counts.
- Weekly bars always render; with a monthly limit, each elapsed day's semantic
  color compares its spend with `weekly allowance / 7` using the shared
  green/yellow/red thresholds. Without a limit, elapsed bars are neutral and
  future bars remain gray.
- Monthly chart labels are `Aktuális`, `Előző`, `Két hónapja`; current values stop today.
- Monthly expense and income trends compare month-to-date with previous month through the same calendar day.
- Savings progress uses saving goal; savings rate uses income.
- 30-day trend has no chart/progress.
- Its integrated pace status is `gyors` above `expected pace * 1.15`, `lassú`
  below `expected pace * 0.80`, otherwise `normál`, where expected pace is
  `elapsed month days / days in month`.
- Forecast sparkline appends the current daily average for future days through month-end.
- Forecast remaining is current-month income minus projected expense.
- Average daily spend divides rolling expense by exactly 30 and uses real balance for runway.
- Income coverage is current-month income divided by rolling daily average; 30+ days is good, below 30 is warning, and zero average omits coverage.
- No-spend ring uses elapsed current-month days.
- Income trend is green-up/red-down; expense trends are red-up/green-down.
- `Kiadás/bevétel arány` includes a signed cashflow secondary row.

Use named getters for formulas rather than repeating arithmetic in card builders:

```dart
double get dailyCeiling => monthlyLimit == null
    ? 0
    : math.max(0, monthlyLimit! - currentMonthExpenseBeforeToday) / remainingMonthDaysIncludingToday;
double get weeklyAllowance => monthlyLimit == null ? 0 : monthlyLimit! / 4.345;
double get actualSavings => math.max(0, currentMonthIncome - currentMonthExpense);
double get projectedMonthExpense => currentMonthExpense / elapsedMonthDays * daysInCurrentMonth;
double get rollingDailyAverage => rolling30Expense / 30;
```

- [ ] **Step 5: Run tests and commit**

Run the command from Step 2. Expected: PASS for all finance metric cases.

```bash
git add lib/features/transactions/state/fast_info_metrics_resolver.dart test/transactions/fast_info_metrics_resolver_test.dart
git commit -m "Implement FastInfo finance metrics"
```

---

### Task 4: Implement Transaction, Category, Merchant, and Recurring Metrics

**Files:**
- Modify: `lib/features/transactions/state/fast_info_metrics_resolver.dart`
- Create: `test/transactions/fast_info_category_metrics_test.dart`
- Create: `test/transactions/fast_info_recurring_metrics_test.dart`

- [ ] **Step 1: Write failing category and merchant ranking tests**

Create `fast_info_category_metrics_test.dart` with ties that prove ordering by count, amount, then name. Assert:

```dart
expect(metrics['legutobbi_tranzakcio']?.avatar, isNotNull);
expect(metrics['leggyakoribb_kereskedo']?.primaryValue, 'Kávézó');
expect(metrics['leggyakoribb_kereskedo']?.secondaryValues.first, '4 tranzakció');
expect(metrics['top_kategoria_ma']?.primaryValue, 'Étel');
expect(metrics['top_kategoria_heten']?.secondaryValues, contains(startsWith('Hónap:')));
expect(metrics['legnagyobb_novekedo_kategoria']?.trend?.text, '+50%');
expect(metrics['leggyorsabban_fogyo_kategorialimit']?.progress, closeTo(1.1, .001));
expect(metrics['leggyorsabban_fogyo_kategorialimit']?.semantic, FastInfoSemantic.bad);
```

Add a new-category delta case expecting `Új` instead of infinity.

- [ ] **Step 2: Write failing recurring/fixed-cost tests**

Create `fast_info_recurring_metrics_test.dart` with pending and activated current-month ghosts plus one next-month ghost. Assert:

```dart
expect(metrics['kovetkezo_ismetlo_kiadas']?.primaryValue, 'Telefon · 8 000 Ft');
expect(metrics['kovetkezo_ismetlo_kiadas']?.secondaryValues, contains('7 nap: 2 tétel · 28 000 Ft'));
expect(metrics['havi_fix_koltseg_osszesen']?.primaryValue, '128 000 Ft');
expect(metrics['havi_fix_koltseg_osszesen']?.secondaryValues, [
  'Levonva 100k · marad 28k',
  'Legnagyobb Lakbér · keret után 72k',
]);
```

- [ ] **Step 3: Run both new test files and verify they fail**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_category_metrics_test.dart test/transactions/fast_info_recurring_metrics_test.dart'
```

Expected: FAIL because the remaining eight canonical metrics are not implemented with approved ranking and ghost data.

- [ ] **Step 4: Implement the remaining eight metrics**

Implement `legutobbi_tranzakcio`, `leggyorsabban_fogyo_kategorialimit`, `leggyakoribb_kereskedo`, `top_kategoria_ma`, `top_kategoria_heten`, `legnagyobb_novekedo_kategoria`, `kovetkezo_ismetlo_kiadas`, and `havi_fix_koltseg_osszesen`.

Use `TransactionCategory.slotColorHex` and `iconSlot` for avatars. Merchant avatar uses the winning merchant's most frequent category. For category delta, new categories rank ahead of finite percentages and tie-break by current amount, then category name.

Metric-specific rules: latest transaction sorts by parsed date then time and shows amount plus merchant/category/time; category-limit state uses current-month category limits and reports the highest ratio plus near/over counts; merchant ranking uses all-history expense count then amount then name; today's top category ranks by amount; weekly/monthly top categories rank by count; category change compares the two rolling 30-day windows.

Recurring rules:

- Next recurring considers pending expense ghosts dated today or later.
- Seven-day total/count includes today through today plus six days.
- Current-month fixed total includes activated and pending expense ghosts.
- Activated amount is deducted; pending amount is remaining.
- Largest fixed expense compares ghost amounts.
- Budget-after-fixed appears only when a monthly expense limit exists.

Use explicit ranking records instead of sorting formatted strings:

```dart
int compareRank(_RankedTotal a, _RankedTotal b) {
  final byCount = b.count.compareTo(a.count);
  if (byCount != 0) return byCount;
  final byAmount = b.amount.compareTo(a.amount);
  if (byAmount != 0) return byAmount;
  return a.name.compareTo(b.name);
}
```

- [ ] **Step 5: Run all resolver tests and commit**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_period_aggregates_test.dart test/transactions/fast_info_metrics_resolver_test.dart test/transactions/fast_info_category_metrics_test.dart test/transactions/fast_info_recurring_metrics_test.dart'
```

Expected: PASS with exactly 18 resolved metric IDs.

```bash
git add lib/features/transactions/state/fast_info_metrics_resolver.dart test/transactions/fast_info_category_metrics_test.dart test/transactions/fast_info_recurring_metrics_test.dart
git commit -m "Implement FastInfo category and recurring metrics"
```

---

### Task 5: Wire Snapshot, Saving Goal, Balance, Ghosts, and Cache into Store

**Files:**
- Create: `lib/features/transactions/data/fast_info_preview_data.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `test/transactions/transaction_store_test.dart`

- [ ] **Step 1: Write failing store snapshot/cache tests**

Update the existing FastInfo cache test to assert a retained metric and real balance runway. Add a repository fixture with a monthly saving overview limit and recurring ghosts, then assert:

```dart
final metrics = store.fastInfoMetrics;
expect(metrics.keys, containsAll(fastInfoCardCatalog.map((card) => card.id)));
expect(metrics['megtakaritas']?.progress, closeTo(expectedSavings / 100000, .001));
expect(metrics['atlagos_napi_koltes']?.secondaryValues.single, startsWith('Puffer:'));
expect(metrics['kovetkezo_ismetlo_kiadas']?.primaryValue, contains('Rent'));
```

After projecting a different recurring-ghost list, assert `identical(store.fastInfoMetrics, metrics)` is false.

- [ ] **Step 2: Run the store test and verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_store_test.dart'
```

Expected: FAIL because store calls the old resolver signature, omits ghosts/balance/saving goal, and does not invalidate FastInfo after ghost projection.

- [ ] **Step 3: Build the snapshot in `TransactionStore.fastInfoMetrics`**

Find the current monthly saving goal with `LimitManager.findLimit`, then resolve:

```dart
final periodKey = LimitManager.periodKeyFor(SummaryWindow.monthly, now);
final savingLimit = LimitManager.findLimit(
  limits: _limits,
  targetType: LimitTargetType.overview,
  targetId: 0,
  transactionType: BudgetGoalKind.savingGoal.transactionType,
  window: LimitWindow.monthly,
  periodKey: periodKey,
);
final metrics = FastInfoMetricsResolver.resolve(FastInfoMetricSnapshot(
  transactions: _transactions,
  categories: _categories,
  limits: _limits,
  recurringGhosts: _recurringGhostTransactions,
  now: now,
  balance: _totalSummary.balance,
  savingGoal: savingLimit?.hasLimit == true ? savingLimit!.limitAmount : null,
));
```

Call `_invalidateFastInfoMetrics()` after recurring ghost projection and keep existing reload invalidation.

- [ ] **Step 4: Add deterministic preview data through the real resolver**

Create `buildFastInfoPreviewMetrics()` using fixed June 2026 transactions, categories, limits, saving goal, balance, and recurring ghosts. Return `FastInfoMetricsResolver.resolve(snapshot)`; do not store demo values in the catalog.

- [ ] **Step 5: Run tests and commit**

Run the command from Step 2 plus all resolver tests. Expected: PASS.

```bash
git add lib/features/transactions/data/fast_info_preview_data.dart lib/features/transactions/state/transaction_store.dart test/transactions/transaction_store_test.dart
git commit -m "Wire live FastInfo snapshot into store"
```

---

### Task 6: Render Structured Visuals and Taller FastInfo Boxes

**Files:**
- Rewrite: `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`
- Modify: `test/transactions/fast_info_panel_test.dart`

- [ ] **Step 1: Write failing structured-render and no-overflow widget tests**

Replace legacy metric fixtures with `primaryValue`, `secondaryValues`, and visual-specific data. Add assertions:

```dart
expect(find.byKey(const ValueKey('fastinfo-progress-mai_koltes')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-weekly-bars-heti_koltes')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-multiline-havi_koltes')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-avatar-legutobbi_tranzakcio')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-trend-koltesi_trend')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-pill-trend-mai_koltes')), findsOneWidget);
```

Add a result with no progress, trend, avatar, chart series, or weekly bars and expect no filler visual. Pump widths `320` and `600`, assert `tester.takeException()` is null, and assert every box height is `112`.

Also assert that one monthly result renders both progress and multi-line chart, and one category-limit result renders both avatar and progress. This guards the required compositional visual model.

- [ ] **Step 2: Run the panel test and verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_panel_test.dart'
```

Expected: FAIL because current visuals switch on stored slot type, show fallback graphics, and boxes are 84 px.

- [ ] **Step 3: Rewrite shared visual components**

Make `FastInfoVisual` compose every available optional field: avatar, trend, progress using `progressKind`, and chart using `chartKind`. Return `SizedBox.shrink()` when none are present, and never switch on `slot.visualType`. Resolve colors centrally:

```dart
Color fastInfoSemanticColor(FastInfoSemantic semantic) => switch (semantic) {
  FastInfoSemantic.good => const Color(0xFF22C55E),
  FastInfoSemantic.warning => const Color(0xFFF59E0B),
  FastInfoSemantic.bad => const Color(0xFFEF4444),
  FastInfoSemantic.neutral => AppColors.primary,
};
```

Use `CategoryIconBadge(size: 24, iconSize: 14, showShadow: false)` for avatars. Implement painters for one sparkline and three common-scale lines. Implement seven bars that paint future entries in `AppColors.gray200` and elapsed entries with their semantic color. Do not generate sample series.

- [ ] **Step 4: Render structured rows and exact heights**

In `FastInfoPanel`, set container height to `328` and box height to `112`. Pills show `metric?.pillValue ?? 'Nincs adat'` plus a compact trend when `trend.text != pillValue`, so trend-primary cards do not duplicate it. Boxes render title, emphasized primary value, up to two compact combined secondary rows, and every available trend/avatar/progress/chart component. Never display `slot.value`, `slot.boxValue`, or catalog demo values.

Set `TransactionHeaderMetrics.fastInfoHeight = 328.0`. Keep `pillTop = 54` and `boxTop = 202`; `202 + 112` fits inside the surface.

- [ ] **Step 5: Run tests and commit**

Run the command from Step 2. Expected: PASS with no overflow exceptions.

```bash
git add lib/features/transactions/widgets/header_card/fast_info_visuals.dart lib/features/transactions/widgets/header_card/fast_info_panel.dart lib/features/transactions/widgets/header_card/transaction_header_metrics.dart test/transactions/fast_info_panel_test.dart
git commit -m "Render structured FastInfo cards"
```

---

### Task 7: Update Settings Pool and Preview Integration

**Files:**
- Modify: `lib/features/settings/widgets/options/fast_info_options_panel.dart`
- Modify: `test/settings/fast_info_options_panel_test.dart`

- [ ] **Step 1: Write failing settings-pool and preview tests**

Add assertions:

```dart
expect(find.byKey(const ValueKey('fastinfo-pool-card-debug_riasztasok')), findsNothing);
expect(find.byType(LongPressDraggable<String>), findsNWidgets(12));
expect(tester.getSize(find.byKey(const ValueKey('fast-info-panel'))).height, 328);
expect(find.text('Nincs adat'), findsNothing);
```

The count is 12 because six retained cards are assigned by defaults. Keep assignment, clear, and replacement interaction tests.

- [ ] **Step 2: Run settings preview tests and verify they fail**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/fast_info_options_panel_test.dart'
```

Expected: FAIL because settings calls the removed resolver preview method and uses old preview dimensions/content.

- [ ] **Step 3: Wire deterministic preview and taller settings area**


```dart
late final Map<String, FastInfoMetricResult> _previewMetrics;

@override
void initState() {
  super.initState();
  _draft = widget.config;
  _previewMetrics = buildFastInfoPreviewMetrics();
}
```
Import `fast_info_preview_data.dart`, build preview metrics once in state, pass them to `FastInfoPanel`, and use the retained catalog for pool cards. Set the preview host height to `348` so the `328` panel plus separation fits. Pool cards display `metric.pillValue`; missing preview metrics display `Nincs adat`.

- [ ] **Step 4: Run settings and bridge tests and commit**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/fast_info_card_catalog_test.dart test/settings/settings_bridge_test.dart test/settings/fast_info_options_panel_test.dart'
```

Expected: PASS.

```bash
git add lib/features/settings/widgets/options/fast_info_options_panel.dart test/settings/fast_info_options_panel_test.dart
git commit -m "Update FastInfo settings preview"
```

---

### Task 8: Format, Verify the Full App, Commit Residual Fixes, and Push

**Files:**
- Modify only files already listed if formatter/analyzer/full-suite exposes a concrete issue.

- [ ] **Step 1: Format all touched Dart files**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/dart format lib/features/settings/models/fast_info_card_catalog.dart lib/features/settings/models/fast_info_config.dart lib/features/settings/widgets/options/fast_info_options_panel.dart lib/features/transactions/models/fast_info_metric.dart lib/features/transactions/models/fast_info_metric_snapshot.dart lib/features/transactions/data/fast_info_period_aggregates.dart lib/features/transactions/data/fast_info_preview_data.dart lib/features/transactions/state/fast_info_metrics_resolver.dart lib/features/transactions/state/transaction_store.dart lib/features/transactions/widgets/header_card/fast_info_visuals.dart lib/features/transactions/widgets/header_card/fast_info_panel.dart lib/features/transactions/widgets/header_card/transaction_header_metrics.dart test/settings/fast_info_card_catalog_test.dart test/settings/fast_info_options_panel_test.dart test/settings/settings_bridge_test.dart test/transactions/fast_info_period_aggregates_test.dart test/transactions/fast_info_metrics_resolver_test.dart test/transactions/fast_info_category_metrics_test.dart test/transactions/fast_info_recurring_metrics_test.dart test/transactions/fast_info_panel_test.dart test/transactions/transaction_store_test.dart'
```

Expected: formatter exits `0`.

- [ ] **Step 2: Run all targeted FastInfo tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/fast_info_card_catalog_test.dart test/settings/settings_bridge_test.dart test/settings/fast_info_options_panel_test.dart test/transactions/fast_info_period_aggregates_test.dart test/transactions/fast_info_metrics_resolver_test.dart test/transactions/fast_info_category_metrics_test.dart test/transactions/fast_info_recurring_metrics_test.dart test/transactions/fast_info_panel_test.dart test/transactions/transaction_store_test.dart'
```

Expected: all targeted tests PASS.

- [ ] **Step 3: Run analyzer and full test suite**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze && /home/flutteruser/flutter/bin/flutter test'
```

Expected: analyzer reports no issues and the full suite PASSes.

- [ ] **Step 4: Build the Android debug APK**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter build apk --debug'
```

Expected: exit `0` and `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 5: Inspect final diff and commit formatter/residual fixes if present**

Run:

```bash
git status --short
git diff --check
git log --oneline origin/main..HEAD
```

If tracked changes remain from formatting or verified fixes:

```bash
git add lib test docs/superpowers/plans/2026-06-04-fastinfo-catalog-redesign.md
git commit -m "Finalize FastInfo catalog redesign"
```

Do not add the pre-existing untracked `.superpowers/` directory.

- [ ] **Step 6: Push the verified commits to GitHub**

Run:

```bash
git push origin main
```

Expected: `main` on `origin` advances to the final verified commit.
