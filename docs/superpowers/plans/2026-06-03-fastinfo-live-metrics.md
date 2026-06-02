# FastInfo Live Metrics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace static FastInfo placeholder values with live transaction-derived metrics, render richer box details for the same cards, and seed the next build with five years of deterministic transaction history.

**Architecture:** Keep `FastInfoSlot` as persisted configuration and add a Flutter-side resolver that converts slot ids plus a `TransactionStore` snapshot into renderable metric results. `FastInfoPanel` receives resolved values for display while settings continues to edit slot identities. Android seed generation expands the existing deterministic demo data and uses the existing seed version reset path.

**Tech Stack:** Flutter/Dart widgets and tests, `TransactionStore`, `FastInfoConfig`, Android Kotlin Room seed data, Flutter test runner, `flutter analyze`.

---

## File Structure

- Create: `lib/features/transactions/models/fast_info_metric.dart`
  - Defines `FastInfoMetricResult` and optional chart series values used by FastInfo rendering.
- Create: `lib/features/transactions/data/fast_info_metrics_resolver.dart`
  - Pure Dart resolver that calculates metric results from transactions, categories, limits, recurring ghosts, and a clock.
- Modify: `lib/features/settings/models/fast_info_config.dart`
  - Keeps backwards-compatible slot parsing while allowing runtime values to override saved catalog/static values.
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
  - Renders `FastInfoMetricResult` when provided and falls back honestly when no live result exists.
- Modify: `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`
  - Uses live `progress` and optional chart series instead of fixed painter paths.
- Modify: `lib/features/transactions/transaction_home_page.dart`
  - Builds a resolver snapshot from `TransactionStore` and passes resolved FastInfo values into `FastInfoPanel`.
- Modify: `lib/features/settings/widgets/options/fast_info_options_panel.dart`
  - Keeps assignment UX; uses deterministic preview metric output instead of placeholder values in preview.
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt`
  - Expands seed data to five years and bumps seed version.
- Add/modify tests:
  - `test/transactions/fast_info_metrics_resolver_test.dart`
  - `test/transactions/fast_info_panel_test.dart`
  - `test/settings/fast_info_options_panel_test.dart`
  - `test/settings/settings_bridge_test.dart`
  - `test/android_seed_data_test.dart`

---

### Task 1: Add Metric Result Types and Resolver

**Files:**
- Create: `lib/features/transactions/models/fast_info_metric.dart`
- Create: `lib/features/transactions/data/fast_info_metrics_resolver.dart`
- Test: `test/transactions/fast_info_metrics_resolver_test.dart`

- [ ] **Step 1: Write failing resolver tests**

Create `test/transactions/fast_info_metrics_resolver_test.dart` with these fixtures and assertions:

```dart
import 'package:exptv2/features/transactions/data/fast_info_metrics_resolver.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clock = DateTime(2026, 6, 3, 12);
  final categories = <TransactionCategory>[
    category(1, 'Fizetes', TransactionType.income),
    category(10, 'Elelmiszer', TransactionType.expense),
    category(11, 'Lakas', TransactionType.expense),
  ];
  final transactions = <TransactionRecord>[
    record(1, '2026.06.03', '09:00', -4500, 10, 'Lidl'),
    record(2, '2026.06.03', '11:00', -2500, 10, 'Kavezo'),
    record(3, '2026.06.02', '18:00', -10000, 11, 'Rezsi'),
    record(4, '2026.06.01', '08:00', 600000, 1, 'Munkaber'),
    record(5, '2026.05.03', '09:00', -3000, 10, 'Lidl'),
  ];
  final limits = <CategoryLimit>[
    limit('overview', 0, 'expense', LimitWindow.monthly, '2026-06', 200000),
  ];

  test('calculates daily spending from live transactions', () {
    final resolver = FastInfoMetricsResolver(
      FastInfoMetricSnapshot(
        transactions: transactions,
        categories: categories,
        limits: limits,
        recurringGhosts: const <RecurringGhostRecord>[],
        summaryWindow: SummaryWindow.monthly,
        referenceDate: clock,
        activeType: TransactionType.expense,
      ),
    );

    final result = resolver.resolve('mai_koltes');

    expect(result.label, 'Mai költés');
    expect(result.pillValue, '7k');
    expect(result.boxValue, '7 000 Ft');
    expect(result.boxSubtitle, '2 tranzakció ma');
    expect(result.visualType.name, 'bar');
  });

  test('calculates monthly limit usage and remaining budget', () {
    final resolver = FastInfoMetricsResolver(
      FastInfoMetricSnapshot(
        transactions: transactions,
        categories: categories,
        limits: limits,
        recurringGhosts: const <RecurringGhostRecord>[],
        summaryWindow: SummaryWindow.monthly,
        referenceDate: clock,
        activeType: TransactionType.expense,
      ),
    );

    final usage = resolver.resolve('havi_limit_allapot');
    final remaining = resolver.resolve('mai_maradek_keret');

    expect(usage.boxValue, '17 000 Ft / 200 000 Ft');
    expect(usage.progress, closeTo(0.085, 0.001));
    expect(remaining.boxValue, '193 000 Ft');
    expect(remaining.progress, closeTo(0.965, 0.001));
  });

  test('falls back honestly for unknown cards', () {
    final resolver = FastInfoMetricsResolver(
      FastInfoMetricSnapshot(
        transactions: transactions,
        categories: categories,
        limits: limits,
        recurringGhosts: const <RecurringGhostRecord>[],
        summaryWindow: SummaryWindow.monthly,
        referenceDate: clock,
        activeType: TransactionType.expense,
      ),
    );

    final result = resolver.resolve('does_not_exist');

    expect(result.label, 'Ismeretlen FastInfo');
    expect(result.pillValue, 'Nincs adat');
    expect(result.boxValue, 'Nincs adat');
  });
}

TransactionRecord record(
  int id,
  String date,
  String time,
  double amount,
  int categoryId,
  String merchant,
) {
  return TransactionRecord(
    id: id,
    date: date,
    time: time,
    latitude: null,
    longitude: null,
    address: null,
    merchant: merchant,
    amount: amount,
    userAssignedName: null,
    transactionCategoryID: categoryId,
  );
}

TransactionCategory category(
  int id,
  String name,
  TransactionType type,
) {
  return TransactionCategory(
    id: id,
    name: name,
    type: type == TransactionType.income ? 'bevétel' : 'kiadás',
    iconSlot: 1,
    colorSlot: 1,
    colorHex: '#22C55E',
    iconPath: './assets/broccoli.png',
    isDefault: false,
    isLimitEnabled: false,
    limitAmount: 0,
    alertEnabled: false,
    limitEnabled: false,
    deletedAt: null,
  );
}

CategoryLimit limit(
  String targetType,
  int targetId,
  String transactionType,
  LimitWindow window,
  String periodKey,
  double amount,
) {
  return CategoryLimit(
    id: 1,
    targetType: targetType == 'overview'
        ? LimitTargetType.overview
        : LimitTargetType.category,
    targetId: targetId,
    transactionType: transactionType,
    window: window,
    periodKey: periodKey,
    hasLimit: true,
    limitAmount: amount,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  );
}
```

- [ ] **Step 2: Run resolver test and verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_metrics_resolver_test.dart'
```

Expected: FAIL because `fast_info_metrics_resolver.dart` and `fast_info_metric.dart` do not exist.

- [ ] **Step 3: Implement metric models**

Create `lib/features/transactions/models/fast_info_metric.dart`:

```dart
import '../../settings/models/fast_info_card_catalog.dart';

class FastInfoMetricResult {
  const FastInfoMetricResult({
    required this.id,
    required this.label,
    required this.pillValue,
    required this.boxValue,
    this.boxSubtitle,
    this.progress,
    this.visualType = FastInfoVisualType.plain,
    this.series = const <double>[],
  });

  final String id;
  final String label;
  final String pillValue;
  final String boxValue;
  final String? boxSubtitle;
  final double? progress;
  final FastInfoVisualType visualType;
  final List<double> series;
}
```

- [ ] **Step 4: Implement resolver snapshot and core calculations**

Create `lib/features/transactions/data/fast_info_metrics_resolver.dart`:

```dart
import '../../settings/models/fast_info_card_catalog.dart';
import '../models/category_limit.dart';
import '../models/fast_info_metric.dart';
import '../models/recurring_ghost_record.dart';
import '../models/summary_window.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class FastInfoMetricSnapshot {
  const FastInfoMetricSnapshot({
    required this.transactions,
    required this.categories,
    required this.limits,
    required this.recurringGhosts,
    required this.summaryWindow,
    required this.referenceDate,
    required this.activeType,
  });

  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final List<CategoryLimit> limits;
  final List<RecurringGhostRecord> recurringGhosts;
  final SummaryWindow summaryWindow;
  final DateTime referenceDate;
  final TransactionType activeType;
}

class FastInfoMetricsResolver {
  FastInfoMetricsResolver(this.snapshot);

  final FastInfoMetricSnapshot snapshot;

  FastInfoMetricResult resolve(String id) {
    return switch (id) {
      'mai_koltes' => _dailyExpense(),
      'havi_koltes' => _monthlyExpense(),
      'havi_limit_allapot' => _monthlyLimitUsage(),
      'mai_maradek_keret' => _monthlyRemainingBudget(),
      'koltesi_trend' => _expenseTrend(),
      'legutobbi_tranzakcio' => _latestTransaction(),
      _ => FastInfoMetricResult(
        id: id,
        label: fastInfoCardById(id)?.title ?? 'Ismeretlen FastInfo',
        pillValue: 'Nincs adat',
        boxValue: 'Nincs adat',
        boxSubtitle: 'Ehhez a kártyához még nincs live metrika',
        visualType: FastInfoVisualType.status,
      ),
    };
  }

  FastInfoMetricResult _dailyExpense() {
    final rows = _expenses.where((record) => _isSameDay(record, snapshot.referenceDate)).toList();
    final total = _sumAbs(rows);
    return FastInfoMetricResult(
      id: 'mai_koltes',
      label: 'Mai költés',
      pillValue: _compactHuf(total),
      boxValue: formatHuf(total),
      boxSubtitle: '${rows.length} tranzakció ma',
      progress: _ratio(total, _monthlyLimitAmount()),
      visualType: FastInfoVisualType.bar,
      series: _dailySeries(),
    );
  }

  FastInfoMetricResult _monthlyExpense() {
    final rows = _expenses.where((record) => record.yearMonthKey == _monthKey(snapshot.referenceDate)).toList();
    final total = _sumAbs(rows);
    final limit = _monthlyLimitAmount();
    return FastInfoMetricResult(
      id: 'havi_koltes',
      label: 'Havi költés',
      pillValue: _compactHuf(total),
      boxValue: limit > 0 ? '${formatHuf(total)} / ${formatHuf(limit)}' : formatHuf(total),
      boxSubtitle: limit > 0 ? 'A havi keret ${(_ratio(total, limit) * 100).round()}%-a' : '${rows.length} havi tranzakció',
      progress: limit > 0 ? _ratio(total, limit) : null,
      visualType: FastInfoVisualType.progress,
      series: _dailySeries(),
    );
  }

  FastInfoMetricResult _monthlyLimitUsage() {
    final total = _monthlyExpenseAmount();
    final limit = _monthlyLimitAmount();
    final progress = limit > 0 ? _ratio(total, limit) : null;
    return FastInfoMetricResult(
      id: 'havi_limit_allapot',
      label: 'Havi limit állapot',
      pillValue: progress == null ? 'Nincs limit' : '${(progress * 100).round()}%',
      boxValue: limit > 0 ? '${formatHuf(total)} / ${formatHuf(limit)}' : 'Nincs limit',
      boxSubtitle: limit > 0 ? '${formatHuf((limit - total).clamp(0, double.infinity))} maradt' : 'Állíts be havi limitet',
      progress: progress,
      visualType: FastInfoVisualType.progress,
    );
  }

  FastInfoMetricResult _monthlyRemainingBudget() {
    final total = _monthlyExpenseAmount();
    final limit = _monthlyLimitAmount();
    final remaining = limit <= 0 ? 0.0 : (limit - total).clamp(0, double.infinity).toDouble();
    return FastInfoMetricResult(
      id: 'mai_maradek_keret',
      label: 'Mai maradék keret',
      pillValue: limit <= 0 ? 'Nincs limit' : _compactHuf(remaining),
      boxValue: limit <= 0 ? 'Nincs limit' : formatHuf(remaining),
      boxSubtitle: 'Havi keret maradéka',
      progress: limit > 0 ? _ratio(remaining, limit) : null,
      visualType: FastInfoVisualType.progress,
    );
  }

  FastInfoMetricResult _expenseTrend() {
    final current = _monthlyExpenseAmount();
    final previousMonth = DateTime(snapshot.referenceDate.year, snapshot.referenceDate.month - 1, 1);
    final previous = _sumAbs(_expenses.where((record) => record.yearMonthKey == _monthKey(previousMonth)));
    final change = previous <= 0 ? 0.0 : ((current - previous) / previous) * 100;
    final prefix = change >= 0 ? '+' : '';
    return FastInfoMetricResult(
      id: 'koltesi_trend',
      label: 'Költési trend',
      pillValue: '$prefix${change.round()}%',
      boxValue: '$prefix${change.round()}%',
      boxSubtitle: 'Az előző hónaphoz képest',
      visualType: FastInfoVisualType.trend,
      series: _monthSeries(),
    );
  }

  FastInfoMetricResult _latestTransaction() {
    final row = snapshot.transactions.isEmpty ? null : snapshot.transactions.first;
    if (row == null) {
      return const FastInfoMetricResult(
        id: 'legutobbi_tranzakcio',
        label: 'Legutóbbi tranzakció',
        pillValue: 'Nincs adat',
        boxValue: 'Nincs adat',
        visualType: FastInfoVisualType.status,
      );
    }
    return FastInfoMetricResult(
      id: 'legutobbi_tranzakcio',
      label: 'Legutóbbi tranzakció',
      pillValue: _compactSignedHuf(row.amount),
      boxValue: row.displayAmount,
      boxSubtitle: '${row.displayMerchant}, ${row.displayTime}',
      visualType: FastInfoVisualType.status,
    );
  }

  Iterable<TransactionRecord> get _expenses => snapshot.transactions.where((record) => record.amount < 0);

  double _monthlyExpenseAmount() => _sumAbs(_expenses.where((record) => record.yearMonthKey == _monthKey(snapshot.referenceDate)));

  double _monthlyLimitAmount() {
    final periodKey = _monthKey(snapshot.referenceDate);
    for (final limit in snapshot.limits) {
      if (limit.targetType == LimitTargetType.overview &&
          limit.transactionType == 'expense' &&
          limit.window == LimitWindow.monthly &&
          limit.periodKey == periodKey &&
          limit.hasLimit) {
        return limit.limitAmount;
      }
    }
    return 0;
  }

  List<double> _dailySeries() => const <double>[];
  List<double> _monthSeries() => const <double>[];

  bool _isSameDay(TransactionRecord record, DateTime date) =>
      record.normalizedDate == '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _monthKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  double _sumAbs(Iterable<TransactionRecord> records) =>
      records.fold<double>(0, (sum, record) => sum + record.amount.abs());

  double _ratio(double value, double max) => max <= 0 ? 0 : (value / max).clamp(0.0, 1.0).toDouble();

  String _compactHuf(num amount) {
    final rounded = amount.round();
    if (rounded.abs() >= 1000000) return '${(rounded / 1000000).toStringAsFixed(1)}M';
    if (rounded.abs() >= 1000) return '${(rounded / 1000).round()}k';
    return '${rounded} Ft';
  }

  String _compactSignedHuf(num amount) {
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix${_compactHuf(amount.abs())}';
  }
}
```

- [ ] **Step 5: Run resolver tests and verify GREEN**

Run the same resolver test command.

Expected: all tests in `fast_info_metrics_resolver_test.dart` pass.

- [ ] **Step 6: Commit resolver**

```bash
git add lib/features/transactions/models/fast_info_metric.dart lib/features/transactions/data/fast_info_metrics_resolver.dart test/transactions/fast_info_metrics_resolver_test.dart
git commit -m "Add FastInfo live metric resolver"
```

---

### Task 2: Render Resolved Metrics in FastInfoPanel

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`
- Test: `test/transactions/fast_info_panel_test.dart`

- [ ] **Step 1: Write failing panel test for live values**

Modify the first test in `test/transactions/fast_info_panel_test.dart` to pass resolved values:

```dart
final config = FastInfoConfig(
  pills: [FastInfoSlot.fromCard(card, FastInfoSlotType.pill), null, null],
  boxes: [FastInfoSlot.fromCard(card, FastInfoSlotType.box), null, null],
);
final metrics = {
  'havi_koltes': const FastInfoMetricResult(
    id: 'havi_koltes',
    label: 'Havi költés',
    pillValue: '217k',
    boxValue: '217 000 Ft / 300 000 Ft',
    boxSubtitle: 'Live havi keret 72%-a',
    progress: 0.72,
    visualType: FastInfoVisualType.progress,
  ),
};

await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: FastInfoPanel(config: config, metrics: metrics)),
  ),
);

expect(find.text('217k'), findsOneWidget);
expect(find.text('217 000 Ft / 300 000 Ft'), findsOneWidget);
expect(find.text('Live havi keret 72%-a'), findsOneWidget);
expect(find.text('184k'), findsNothing);
```

Add imports:

```dart
import 'package:exptv2/features/transactions/models/fast_info_metric.dart';
```

- [ ] **Step 2: Run panel test and verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_panel_test.dart --plain-name "same card renders"'
```

Expected: FAIL because `FastInfoPanel` has no `metrics` parameter.

- [ ] **Step 3: Add metrics parameter and result lookup**

Modify `FastInfoPanel` constructor and fields:

```dart
import '../../models/fast_info_metric.dart';

class FastInfoPanel extends StatelessWidget {
  const FastInfoPanel({
    super.key,
    required this.config,
    this.metrics = const <String, FastInfoMetricResult>{},
    this.backgroundColor = AppColors.gray100,
    this.pillTop = 54,
    this.boxTop = 202,
    this.onDropPillCard,
    this.onDropBoxCard,
    this.onClearPillSlot,
    this.onClearBoxSlot,
  });

  final FastInfoConfig config;
  final Map<String, FastInfoMetricResult> metrics;
```

Pass each slot's result into pill and box:

```dart
_FastInfoPill(
  slot: config.pills[i],
  metric: _metricFor(config.pills[i]),
  index: i,
  onDropCard: onDropPillCard,
  onClear: onClearPillSlot,
)
```

```dart
_FastInfoBox(
  slot: config.boxes[i],
  metric: _metricFor(config.boxes[i]),
  index: i,
  onDropCard: onDropBoxCard,
  onClear: onClearBoxSlot,
)
```

Add helper:

```dart
FastInfoMetricResult? _metricFor(FastInfoSlot? slot) {
  if (slot == null) return null;
  return metrics[slot.id];
}
```

- [ ] **Step 4: Update pill and box renderers**

Add fields:

```dart
final FastInfoMetricResult? metric;
```

Pill text should use:

```dart
metric?.pillValue ?? slot?.pillValue ?? slot?.value ?? 'Üres pill slot'
```

Box label/value/subtitle should use:

```dart
final label = metric?.label ?? slot.label;
final value = metric?.boxValue ?? slot.boxValue ?? slot.value;
final subtitle = metric?.boxSubtitle ?? slot.boxSubtitle ?? slot.extra;
```

Visual call should use a metric-aware visual:

```dart
FastInfoVisual(slot: slot, metric: metric),
```

- [ ] **Step 5: Update FastInfoVisual to consume metric**

Modify `FastInfoVisual`:

```dart
class FastInfoVisual extends StatelessWidget {
  const FastInfoVisual({super.key, required this.slot, this.metric});

  final FastInfoSlot slot;
  final FastInfoMetricResult? metric;

  FastInfoVisualType get _visualType => metric?.visualType ?? slot.visualType;
  double? get _progress => metric?.progress ?? slot.progress;
  List<double> get _series => metric?.series ?? const <double>[];
```

Use `_visualType`, `_progress`, and `_series`. For sparkline painter, pass series and retain the old fixed shape only when `series.isEmpty`:

```dart
child: CustomPaint(painter: _SparklinePainter(_series)),
```

- [ ] **Step 6: Run panel tests and verify GREEN**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_panel_test.dart'
```

Expected: all FastInfo panel tests pass.

- [ ] **Step 7: Commit panel rendering**

```bash
git add lib/features/transactions/widgets/header_card/fast_info_panel.dart lib/features/transactions/widgets/header_card/fast_info_visuals.dart test/transactions/fast_info_panel_test.dart
git commit -m "Render live FastInfo metrics"
```

---

### Task 3: Wire Live Metrics Into TransactionHomePage

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/widget_test.dart` or `test/transactions/transaction_home_fast_info_test.dart`

- [ ] **Step 1: Write failing integration test**

Add a test to `test/widget_test.dart` or create `test/transactions/transaction_home_fast_info_test.dart` using the existing app fixture pattern:

```dart
testWidgets('FastInfo values update after adding a transaction', (tester) async {
  await tester.pumpWidget(buildApp());
  await tester.pumpAndSettle();

  expect(find.text('7k'), findsNothing);

  await tester.tap(find.byKey(const ValueKey('fab-add-transaction')));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Tranzakció neve'), 'Live Shop');
  await tester.enterText(find.widgetWithText(TextField, 'Összeg'), '7000');
  await tester.ensureVisible(find.text('Mentés'));
  await tester.tap(find.text('Mentés'));
  await tester.pumpAndSettle();

  expect(find.textContaining('7'), findsWidgets);
});
```

If the existing fixture uses different keys or text labels, copy the exact add-transaction flow from the existing `add transaction sheet saves through native bridge` test and replace the final expectation with a FastInfo live value assertion.

- [ ] **Step 2: Run integration test and verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/widget_test.dart --plain-name "FastInfo values update"'
```

Expected: FAIL because `TransactionHomePage` still renders static FastInfo config values.

- [ ] **Step 3: Build resolver snapshot in TransactionHomePage**

In `transaction_home_page.dart`, import:

```dart
import 'data/fast_info_metrics_resolver.dart';
import 'models/fast_info_metric.dart';
```

Near the `FastInfoPanel` construction, build metrics:

```dart
final fastInfoConfig = widget.fastInfoConfig ?? FastInfoConfig.defaults();
final fastInfoResolver = FastInfoMetricsResolver(
  FastInfoMetricSnapshot(
    transactions: store.transactions,
    categories: store.categories,
    limits: store.limits,
    recurringGhosts: store.recurringGhostTransactions,
    summaryWindow: store.summaryWindow,
    referenceDate: DateTime.now(),
    activeType: store.activeType,
  ),
);
final fastInfoMetrics = <String, FastInfoMetricResult>{
  for (final slot in [...fastInfoConfig.pills, ...fastInfoConfig.boxes])
    if (slot != null) slot.id: fastInfoResolver.resolve(slot.id),
};
```

Pass into panel:

```dart
FastInfoPanel(
  config: fastInfoConfig,
  metrics: fastInfoMetrics,
  ...existing callbacks...
)
```

- [ ] **Step 4: Add and use a stable store clock getter**

Add this getter to `TransactionStore`:

```dart
DateTime get currentDate => _clock();
```

Use it in `TransactionHomePage` instead of `DateTime.now()`:

```dart
referenceDate: store.currentDate,
```

This keeps widget tests deterministic because `TransactionStore` already accepts a test clock.

- [ ] **Step 5: Run integration test and verify GREEN**

Run the same `flutter test ... --plain-name "FastInfo values update"` command.

Expected: PASS.

- [ ] **Step 6: Commit live wiring**

```bash
git add lib/features/transactions/transaction_home_page.dart lib/features/transactions/state/transaction_store.dart test/widget_test.dart test/transactions/transaction_home_fast_info_test.dart
git commit -m "Wire FastInfo metrics to transaction state"
```

Only add files that actually changed.

---

### Task 4: Keep Settings Assignment UX and Use Honest Preview Data

**Files:**
- Modify: `lib/features/settings/models/fast_info_config.dart`
- Modify: `lib/features/settings/widgets/options/fast_info_options_panel.dart`
- Test: `test/settings/fast_info_options_panel_test.dart`
- Test: `test/settings/settings_bridge_test.dart`

- [ ] **Step 1: Write backwards compatibility test**

Add to `test/settings/settings_bridge_test.dart` or `test/settings/fast_info_config_test.dart`:

```dart
test('FastInfo slot parses old saved values but keeps card identity', () {
  final slot = FastInfoSlot.fromMap(const <String, Object?>{
    'id': 'havi_koltes',
    'label': 'Old label',
    'value': '999k',
    'extra': 'Old subtitle',
    'type': 'box',
  });

  expect(slot.id, 'havi_koltes');
  expect(slot.type, FastInfoSlotType.box);
  expect(slot.value, '999k');
  expect(slot.boxValue, isNotEmpty);
});
```

- [ ] **Step 2: Write settings preview test**

Add to `test/settings/fast_info_options_panel_test.dart`:

```dart
testWidgets('settings preview uses deterministic non-placeholder metric values', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 780,
          child: FastInfoOptionsPanel(
            config: FastInfoConfig.defaults(),
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );

  expect(find.text('184k'), findsNothing);
  expect(find.text('217k'), findsWidgets);
});
```

Use the actual deterministic preview value chosen in implementation.

- [ ] **Step 3: Run settings tests and verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/fast_info_options_panel_test.dart test/settings/settings_bridge_test.dart'
```

Expected: FAIL because preview still uses catalog placeholder values.

- [ ] **Step 4: Add deterministic preview metrics in FastInfoOptionsPanel**

In `fast_info_options_panel.dart`, import metric type:

```dart
import '../../../../features/transactions/models/fast_info_metric.dart';
```

Create preview metrics for selected cards:

```dart
Map<String, FastInfoMetricResult> _previewMetrics(FastInfoConfig config) {
  return <String, FastInfoMetricResult>{
    for (final slot in [...config.pills, ...config.boxes])
      if (slot != null)
        slot.id: FastInfoMetricResult(
          id: slot.id,
          label: slot.label,
          pillValue: '217k',
          boxValue: '217 000 Ft',
          boxSubtitle: 'Live előnézet',
          progress: 0.72,
          visualType: slot.visualType,
        ),
  };
}
```

Pass to preview panel:

```dart
FastInfoPanel(
  config: _draft,
  metrics: _previewMetrics(_draft),
  ...existing callbacks...
)
```

- [ ] **Step 5: Run settings tests and verify GREEN**

Run the same settings test command.

Expected: PASS.

- [ ] **Step 6: Commit settings preview compatibility**

```bash
git add lib/features/settings/models/fast_info_config.dart lib/features/settings/widgets/options/fast_info_options_panel.dart test/settings/fast_info_options_panel_test.dart test/settings/settings_bridge_test.dart
git commit -m "Keep FastInfo settings as live metric identities"
```

Only add files that actually changed.

---

### Task 5: Expand Android Seed Data to Five Years

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt`
- Test: `test/android_seed_data_test.dart`

- [ ] **Step 1: Inspect seed generation boundaries**

Confirm current loop:

```kotlin
var monthOffset = 0
while (monthOffset <= 12) {
    val absoluteMonth = 5 + monthOffset
    val year = 2025 + (absoluteMonth - 1) / 12
    val month = ((absoluteMonth - 1) % 12) + 1
```

This produces 13 months from 2025-05 to 2026-05. Replace with a 61-month deterministic range ending at 2026-06.

- [ ] **Step 2: Update transaction seed loop**

Change version and loop constants:

```kotlin
const val version = 2026060301

private const val seedStartYear = 2021
private const val seedStartMonth = 6
private const val seedMonthCount = 61
```

Replace the transaction loop with:

```kotlin
for (monthOffset in 0 until seedMonthCount) {
    val absoluteMonth = (seedStartYear * 12 + (seedStartMonth - 1)) + monthOffset
    val year = absoluteMonth / 12
    val month = (absoluteMonth % 12) + 1
    val days = daysInMonth(year, month)
    val idBase = ((year % 100) * 100000) + (month * 1000)
    val expenseCount = 225 + random.nextInt(36)
    // keep existing expense/income generation body
}
```

Expected row count: at least `61 * 225 = 13725` expenses plus income rows.

- [ ] **Step 3: Update limits loop to same range**

Replace the limits monthly loop with:

```kotlin
for (monthOffset in 0 until seedMonthCount) {
    val absoluteMonth = (seedStartYear * 12 + (seedStartMonth - 1)) + monthOffset
    val year = absoluteMonth / 12
    val month = (absoluteMonth % 12) + 1
    val periodKey = "%04d-%02d".format(year, month)
    add("overview", 0, "expense", "monthly", periodKey, 840000.0)
    add("overview", 0, "income", "monthly", periodKey, 620000.0)
    for (category in categories.filter { it.type == "kiadás" }) {
        add("category", category.transactionCategoryID, "expense", "monthly", periodKey, category.limitAmount)
    }
}
```

- [ ] **Step 4: Add seed source sanity test**

Create `test/android_seed_data_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ExpenseSeedData targets five years of demo transactions', () {
    final source = File(
      'android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt',
    ).readAsStringSync();

    expect(source, contains('const val version = 2026060301'));
    expect(source, contains('private const val seedStartYear = 2021'));
    expect(source, contains('private const val seedStartMonth = 6'));
    expect(source, contains('private const val seedMonthCount = 61'));
    expect(source, contains('for (monthOffset in 0 until seedMonthCount)'));
    expect(source, contains('225 + random.nextInt(36)'));
  });
}
```

Do not add per-row logs. The existing reset log remains enough:

```kotlin
"Reset demo data version=${ExpenseSeedData.version} categories=${ExpenseSeedData.categories.size} transactions=${ExpenseSeedData.transactions.size} limits=${ExpenseSeedData.limits.size}"
```

- [ ] **Step 5: Run seed sanity test and targeted repository tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/android_seed_data_test.dart test/transactions/transaction_store_test.dart test/transactions/transaction_store_limits_test.dart test/transactions/transaction_store_budget_goals_test.dart'
```

Expected: PASS. The seed sanity test verifies the five-year generation constants, and the store tests verify Flutter-side assumptions are unchanged.

- [ ] **Step 6: Run Android build check**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/android && ./gradlew :app:assembleDebug'
```

Expected: SUCCESS. If the command fails because the local environment lacks Android build prerequisites, capture the exact failure output in the implementation notes and still run `flutter analyze` and `flutter test` before continuing.

- [ ] **Step 7: Commit seed expansion**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt test/android_seed_data_test.dart
git commit -m "Expand expense seed data to five years"
```

---

### Task 6: Final Verification and Push

**Files:**
- All files changed by Tasks 1-5

- [ ] **Step 1: Search for placeholder values still driving live output**

Run:

```bash
rg -n "pillValue|boxValue|boxSubtitle|184k|156,780|4 500 Ft|180k / 200k" lib test android/app/src/main/kotlin/com/exptv2/app/expense
```

Expected: catalog definitions may still contain example display strings for picker labels/backwards compatibility, but `TransactionHomePage` and normal `FastInfoPanel` rendering must use `FastInfoMetricResult` when live metrics are supplied.

- [ ] **Step 2: Run targeted FastInfo tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/fast_info_metrics_resolver_test.dart test/transactions/fast_info_panel_test.dart test/settings/fast_info_options_panel_test.dart test/settings/settings_bridge_test.dart'
```

Expected: PASS.

- [ ] **Step 3: Run analyzer**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: `No issues found!`

- [ ] **Step 4: Run full Flutter test suite**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test'
```

Expected: all tests pass.

- [ ] **Step 5: Check git status and diff**

Run:

```bash
git status --short --branch
git diff --check
```

Expected: branch ahead with committed task changes only; `.superpowers/` may remain untracked and must not be added.

- [ ] **Step 6: Push main**

Run:

```bash
git push
```

Expected: push succeeds to `origin/main`.
