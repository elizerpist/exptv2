# Stats Main Menu Render Modes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the annual stats main menu so the shared shell, `Kategória scope`, `Hőtérkép`, and `Hózárás` render modes match the approved HTML/spec/checklist references.

**Architecture:** Keep `StatsPage` responsible for UI state and controls, keep `StatsYearData` responsible for normalized annual/month/day data, and move derived graph math into focused pure Dart series helpers. Custom painters consume immutable series models so calculations can be tested without rendering, and widgets verify layout/control behavior separately.

**Tech Stack:** Flutter/Dart, `flutter_test`, `CustomPainter`, existing transaction/category models, Ubuntu proot for local `flutter test` and `flutter analyze`; APK builds run online only.

## Global Constraints

- Mandatory HTML references:
  - `.superpowers/brainstorm/11665-1783356886/content/stats-current-concept-summary-v26.html`
  - `.superpowers/brainstorm/11665-1783356886/content/stats-heatmap-render-mode-v28.html`
  - `.superpowers/brainstorm/11665-1783356886/content/stats-closing-render-mode-v29.html`
- Mandatory checklist: `docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md`
- Mandatory spec: `docs/superpowers/specs/2026-07-07-stats-main-menu-redesign-design.md`
- TDD rule: no production code change before a failing test has been written and verified for that behavior.
- Annual view keeps 12 monthcards visible. Month focus/detail is deferred and must not be inferred in this implementation.
- SummaryPill owns the selected annual period amount. Header does not duplicate it.
- FastInfo is passive graph canvas only: no cards, no pills, no category chips, no settings controls, no long explanatory copy.
- Graphs use the active data domain and must not draw a flat empty tail to year end when data stops earlier.
- Do not run local Flutter APK builds in Termux. Use Ubuntu proot only for local tests/analyze.

---

## File Structure

- Modify `lib/features/stats/data/stats_year_data.dart`: shared active-type filtering, scope normalization, month/day aggregates, graph domain, public fields consumed by series builders.
- Create `lib/features/stats/data/stats_scope_model.dart`: `StatsScopeSelection` normalization, `ALL`/custom state, active category filtering.
- Create `lib/features/stats/data/stats_category_scope_series.dart`: occurrence/value index, risk segments, Kontroll score, Behavior MACD, monthly stacked HUF and impact line.
- Create `lib/features/stats/data/stats_heatmap_series.dart`: cluster density, Heat Pulse, monthly heat load.
- Create `lib/features/stats/data/stats_closing_series.dart`: closing drift, Close Pulse, monthly closing bars, threshold point counts.
- Modify `lib/features/stats/stats_page.dart`: active render mode, active type, threshold, scope sheet, render selector, annual shell integration.
- Modify `lib/features/stats/widgets/stats_fast_info_graph.dart`: graph-only FastInfo stack selection and chart painters for all accepted modes.
- Modify `lib/features/stats/widgets/stats_year_calendar.dart`: preserve existing monthcard behavior and add tests around closing threshold dots.
- Modify `lib/features/stats/widgets/stats_category_scope_sheet.dart`: real category sheet multi-select states and `ALL` normalization.
- Modify `test/stats/stats_year_data_test.dart`: shared aggregation/domain tests.
- Create `test/stats/stats_scope_model_test.dart`: scope normalization tests.
- Create `test/stats/stats_category_scope_series_test.dart`: category trend, score, MACD, monthly stack tests.
- Create `test/stats/stats_heatmap_series_test.dart`: heatmap density, pulse, monthly load tests.
- Create `test/stats/stats_closing_series_test.dart`: closing drift, Close Pulse, monthly close/threshold point tests.
- Modify `test/stats/stats_page_test.dart`: widget/control/FastInfo graph-only tests.

## Task 0: Requirements Gate

**Files:**
- Read: `docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md`
- Read: `docs/superpowers/specs/2026-07-07-stats-main-menu-redesign-design.md`
- Read: `.superpowers/brainstorm/11665-1783356886/content/stats-current-concept-summary-v26.html`
- Read: `.superpowers/brainstorm/11665-1783356886/content/stats-heatmap-render-mode-v28.html`
- Read: `.superpowers/brainstorm/11665-1783356886/content/stats-closing-render-mode-v29.html`

**Interfaces:**
- Consumes: approved `STAT-SHARED-*`, `STAT-CAT-*`, `STAT-HEAT-*`, `STAT-CLOSE-*` requirements.
- Produces: confirmed implementation scope for the remaining tasks.

- [ ] **Step 1: Re-read accepted requirements**

Run:

```bash
rg -n "STAT-(SHARED|CAT|HEAT|CLOSE)-" docs/superpowers/checklists docs/superpowers/specs docs/superpowers/plans
```

Expected: every accepted stats requirement is visible, including `STAT-CLOSE-001` through `STAT-CLOSE-010`.

- [ ] **Step 2: Re-open mandatory HTML**

Run:

```bash
rg -n "Előfordulás vs értékindex|M1 · Koncentráció marker|S1 · Klaszter-sűrűség|S2 · Heat Pulse|HÓZÁRÁS|M1 · Zárási drift|S2 · Close Pulse|H1 · Havi zárás" .superpowers/brainstorm/11665-1783356886/content/stats-current-concept-summary-v26.html .superpowers/brainstorm/11665-1783356886/content/stats-heatmap-render-mode-v28.html .superpowers/brainstorm/11665-1783356886/content/stats-closing-render-mode-v29.html
```

Expected: all accepted chart/header labels are present in the HTML files.

- [ ] **Step 3: Stop on conflict**

If a checklist row conflicts with the HTML or spec, stop implementation and update the checklist/spec before writing tests.

## Task 1: Scope Normalization And Shared Year Data

**Files:**
- Create: `lib/features/stats/data/stats_scope_model.dart`
- Modify: `lib/features/stats/data/stats_year_data.dart`
- Modify: `test/stats/stats_year_data_test.dart`
- Create: `test/stats/stats_scope_model_test.dart`

**Interfaces:**
- Consumes: `TransactionRecord`, `TransactionCategory`, `TransactionType`.
- Produces: `StatsScopeSelection`, `StatsYearData.graphMonths`, `StatsDayData.scopeAmount`, `StatsDayData.meetsThreshold`, `StatsMonthData.activeTotal`, `StatsMonthData.scopeTotal`, `StatsMonthData.closingAmount`.

- [ ] **Step 1: Write failing scope normalization tests**

Add to `test/stats/stats_scope_model_test.dart`:

```dart
import 'package:exptv2/features/stats/data/stats_scope_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes empty and all-selected scopes to ALL', () {
    expect(
      StatsScopeSelection.normalize(
        selectedCategoryIds: const {},
        availableCategoryIds: const {1, 2, 3},
      ).isAll,
      isTrue,
    );
    expect(
      StatsScopeSelection.normalize(
        selectedCategoryIds: const {1, 2, 3},
        availableCategoryIds: const {1, 2, 3},
      ).isAll,
      isTrue,
    );
  });

  test('keeps partial selections as custom scope', () {
    final selection = StatsScopeSelection.normalize(
      selectedCategoryIds: const {1, 3},
      availableCategoryIds: const {1, 2, 3},
    );

    expect(selection.isAll, isFalse);
    expect(selection.selectedCategoryIds, {1, 3});
    expect(selection.chipLabel, '2');
  });
}
```

- [ ] **Step 2: Verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_scope_model_test.dart'
```

Expected: FAIL because `StatsScopeSelection` does not exist.

- [ ] **Step 3: Implement minimal scope model**

Create `StatsScopeSelection` with:

```dart
class StatsScopeSelection {
  const StatsScopeSelection._({
    required this.isAll,
    required this.selectedCategoryIds,
  });

  final bool isAll;
  final Set<int> selectedCategoryIds;

  String get chipLabel => isAll ? 'ALL' : selectedCategoryIds.length.toString();

  static StatsScopeSelection normalize({
    required Set<int> selectedCategoryIds,
    required Set<int> availableCategoryIds,
  }) {
    final filtered = selectedCategoryIds.where(availableCategoryIds.contains).toSet();
    if (filtered.isEmpty || filtered.length == availableCategoryIds.length) {
      return const StatsScopeSelection._(
        isAll: true,
        selectedCategoryIds: <int>{},
      );
    }
    return StatsScopeSelection._(
      isAll: false,
      selectedCategoryIds: Set.unmodifiable(filtered),
    );
  }
}
```

- [ ] **Step 4: Verify GREEN**

Run the same test command. Expected: PASS.

- [ ] **Step 5: Write failing shared data tests**

Extend `test/stats/stats_year_data_test.dart` with cases proving:

```dart
expect(data.graphMonths.map((month) => month.month), [3, 4, 5, 6, 7]);
expect(january.days[0].scopeAmount, 6000);
expect(january.days[0].meetsThreshold, isTrue);
expect(data.months[1].closingAmount, 7000);
```

Expected behaviors: active graph domain uses first through last active-type transaction month, scope excludes unrelated categories, and `closingAmount` remains active-side monthly total.

- [ ] **Step 6: Verify RED/GREEN around any missing shared-data behavior**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_year_data_test.dart'
```

Expected RED before changes for any missing normalization/domain behavior, then PASS after `StatsYearData` uses `StatsScopeSelection`.

- [ ] **Step 7: Commit**

```bash
git add lib/features/stats/data/stats_scope_model.dart lib/features/stats/data/stats_year_data.dart test/stats/stats_scope_model_test.dart test/stats/stats_year_data_test.dart
git commit -m "test: lock stats scope normalization and annual data"
```

## Task 2: Category Scope Series

**Files:**
- Create: `lib/features/stats/data/stats_category_scope_series.dart`
- Create: `test/stats/stats_category_scope_series_test.dart`

**Interfaces:**
- Consumes: `StatsYearData`, `StatsMonthData`, `StatsDayData`.
- Produces: `StatsCategoryScopeSeries.fromYearData(...)`, `StatsCategoryScopeSeries.fromDailySamples(...)`, `StatsTrendPoint`, `StatsRiskSegment`, `StatsMacdBar`, `StatsMonthlyScopeBar`, `StatsImpactPoint`.

- [ ] **Step 1: Write failing occurrence/value-index test**

Add a test where March has fewer threshold-hit days but higher hit value:

```dart
test('occurrence can fall while value index rises', () {
  final series = StatsCategoryScopeSeries.fromDailySamples(
    threshold: 5000,
    dailyScopeAmounts: const [6000, 6000, 0, 0, 30000],
    window: 2,
  );

  expect(series.occurrence.last.value, lessThan(series.occurrence.first.value));
  expect(series.valueIndex.last.value, greaterThan(series.valueIndex.first.value));
});
```

- [ ] **Step 2: Verify RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_category_scope_series_test.dart'
```

Expected: FAIL because `StatsCategoryScopeSeries` does not exist.

- [ ] **Step 3: Implement category series math**

Implement:

```text
hit(day) = scopeAmount(day) >= threshold
hitValue(day) = hit(day) ? scopeAmount(day) : 0
occurrence(day) = rollingHitRate(hit, window) * 100
valueIndex(day) = rollingSum(hitValue, window) / maxRollingValue * 100
pressure = 0.4 * occurrence + 0.6 * valueIndex
MACD = EMA(pressure, 7) - EMA(pressure, 21)
signal = EMA(MACD, 5)
histogram = MACD - signal
monthlyImpact = monthlyScopeFt / monthlyThresholdHitDays
```

Risk segment colors:

```text
green rgba(16,185,129,.55): both improve
orange rgba(249,115,22,.55): mixed/diverging
red rgba(239,68,68,.55): both worsen
none: both flat/noise
```

- [ ] **Step 4: Add RED/GREEN tests for score, MACD, monthly stack**

Tests must cover:

- occurrence-only improvement does not produce false high Kontroll score;
- `EMA(P, 7) - EMA(P, 21)` produces a known histogram sign;
- more than three categories become top 3 + `Egyéb`;
- latest non-null `Ft/kiugrás` label is preserved.

- [ ] **Step 5: Commit**

```bash
git add lib/features/stats/data/stats_category_scope_series.dart test/stats/stats_category_scope_series_test.dart
git commit -m "feat: add category scope graph series"
```

## Task 3: Heatmap Series

**Files:**
- Create: `lib/features/stats/data/stats_heatmap_series.dart`
- Create: `test/stats/stats_heatmap_series_test.dart`

**Interfaces:**
- Consumes: `StatsYearData`.
- Produces: `StatsHeatmapSeries`, cluster density points, Heat Pulse bars, monthly heat-load bars.

- [ ] **Step 1: Write failing cluster density and pulse tests**

Add tests for:

```text
hot(d) = scopeAmount(d) >= threshold ? 1 : 0
density(t) = sum(hot, W) / activeDays(W)
over(d) = hot(d) ? min(scopeAmount(d) / threshold, 3.0) : 0
pulse(t) = EMA_short(over) - EMA_long(over)
heatLoad(month) = Σ over(d)
```

Expected colors:

```text
density line #06B6D4
pulse positive #06B6D4
pulse negative #CBD5E1
monthly high #06B6D4
monthly middle #67E8F9
monthly low #DDF8FD
```

- [ ] **Step 2: Verify RED**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_heatmap_series_test.dart'
```

Expected: FAIL because heatmap series helper does not exist.

- [ ] **Step 3: Implement heatmap series**

Use dynamic windows:

```text
cluster density W: 7 short, 14 medium, 21 full-year
Heat Pulse EMA: 3/7 short, 5/14 medium, 7/21 full-year
```

Keep heatmap mode free of orange/red/yellow risk colors.

- [ ] **Step 4: Verify GREEN and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_heatmap_series_test.dart'
git add lib/features/stats/data/stats_heatmap_series.dart test/stats/stats_heatmap_series_test.dart
git commit -m "feat: add heatmap graph series"
```

## Task 4: Hózárás Series

**Files:**
- Create: `lib/features/stats/data/stats_closing_series.dart`
- Create: `test/stats/stats_closing_series_test.dart`

**Interfaces:**
- Consumes: `StatsYearData`, `StatsMonthData.thresholdHitDays`, `StatsMonthData.closingAmount`, active type.
- Produces: `StatsClosingSeries.fromYearData(...)`, `StatsClosingSeries.fromMonthCloses(...)`, `closingDriftMarker`, `closePulseBars`, `monthlyCloseBars`, `StatsClosePulseBar.value`, `StatsClosePulseBar.colorHex`, `StatsMonthlyCloseBar.amount`, `StatsMonthlyCloseBar.thresholdHitDays`, `StatsMonthlyCloseBar.barColorHex`, `StatsMonthlyCloseBar.thresholdPointColorHex`.

- [ ] **Step 1: Write failing closing drift tests**

Add tests for expense and income sign handling:

```dart
test('closing drift moves right when expense monthly closes improve', () {
  final series = StatsClosingSeries.fromMonthCloses(
    activeType: TransactionType.expense,
    closes: const [30000, 22000, 18000],
    thresholdHitDays: const [3, 2, 1],
  );

  expect(series.driftMarker, greaterThan(0.5));
});

test('closing drift moves left when income monthly closes fall', () {
  final series = StatsClosingSeries.fromMonthCloses(
    activeType: TransactionType.income,
    closes: const [300000, 240000, 210000],
    thresholdHitDays: const [2, 1, 1],
  );

  expect(series.driftMarker, lessThan(0.5));
});
```

- [ ] **Step 2: Verify RED**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_closing_series_test.dart --plain-name "closing drift"'
```

Expected: FAIL because `StatsClosingSeries` does not exist.

- [ ] **Step 3: Implement closing drift**

Implement:

```text
closing(month) = activeTypeTotal(month)
delta(month) = closing(month) - previousActiveClosing
improvementDelta(month) = activeType == expense ? -delta(month) : delta(month)
maxAbsDelta = max(abs(delta(month)))
normalizedDelta(month) = maxAbsDelta == 0 ? 0 : improvementDelta(month) / maxAbsDelta
drift = average(normalizedDelta(month))
markerPosition = clamp(0.5 + 0.5 * drift, 0, 1)
```

Use active months only.

- [ ] **Step 4: Write failing Close Pulse tests**

Add:

```dart
test('close pulse maps expense worsening to positive red pressure', () {
  final series = StatsClosingSeries.fromMonthCloses(
    activeType: TransactionType.expense,
    closes: const [10000, 15000, 24000, 32000, 41000],
    thresholdHitDays: const [1, 2, 3, 4, 5],
  );

  expect(series.closePulseBars.last.value, greaterThan(0));
  expect(series.closePulseBars.last.colorHex, '#EF4444');
});

test('close pulse maps income recovery to negative green pressure', () {
  final series = StatsClosingSeries.fromMonthCloses(
    activeType: TransactionType.income,
    closes: const [100000, 80000, 90000, 120000, 150000],
    thresholdHitDays: const [1, 1, 2, 2, 3],
  );

  expect(series.closePulseBars.last.value, lessThan(0));
  expect(series.closePulseBars.last.colorHex, '#22C55E');
});
```

- [ ] **Step 5: Implement Close Pulse**

Implement:

```text
pressureDelta(month) = activeType == expense ? delta(month) : -delta(month)
closePulse(month) = EMA_short(pressureDelta) - EMA_long(pressureDelta)
```

Dynamic windows:

```text
active months < 5: 1/3
active months 5-8: 2/4
active months 9-12: 3/6
```

Colors:

```text
positive #EF4444
negative #22C55E
zero line rgba(100,116,139,.50)
grid #E2E8F0 / #CBD5E1
```

- [ ] **Step 6: Write failing monthly close + threshold point tests**

Add:

```dart
test('monthly close bars use active totals and threshold-hit counts', () {
  final series = StatsClosingSeries.fromMonthCloses(
    activeType: TransactionType.expense,
    closes: const [4000, 30000, 12000],
    thresholdHitDays: const [0, 5, 1],
  );

  expect(series.monthlyCloseBars[1].amount, 30000);
  expect(series.monthlyCloseBars[1].thresholdHitDays, 5);
  expect(series.monthlyCloseBars[1].barColorHex, '#EF4444');
  expect(series.monthlyCloseBars[1].thresholdPointColorHex, '#EF4444');
});
```

- [ ] **Step 7: Implement monthly close bars**

Implement:

```text
barHeight(month) = closing(month)
thresholdHitDays(month) = count(scopeAmount(day) >= threshold && scopeAmount(day) > 0)
expense bars #EF4444 / #FCA5A5
income bars #22C55E / #86EFAC
labels #64748B
```

Do not include inactive future months in `StatsClosingSeries`.

- [ ] **Step 8: Verify GREEN and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_closing_series_test.dart'
git add lib/features/stats/data/stats_closing_series.dart test/stats/stats_closing_series_test.dart
git commit -m "feat: add closing graph series"
```

## Task 5: Header, Controls, And Magnets

**Files:**
- Modify: `lib/features/stats/stats_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/widgets/header_card/magnet_strip.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`
- Modify: `test/stats/stats_page_test.dart`

**Interfaces:**
- Consumes: `StatsRenderMode`, `StatsCategoryScopeSeries`, `StatsHeatmapSeries`, `StatsClosingSeries`.
- Produces: header label/value, scope chip, category button, render selector, joystick threshold updates, render-specific magnet state.

- [ ] **Step 1: Write failing widget tests**

Tests must verify:

- SummaryPill remains present and owns annual amount;
- `Bevétel`/`Kiadás` pills change active type;
- category button opens multi-select scope sheet;
- joystick tap opens render selector;
- joystick drag/long-press changes threshold;
- category mode magnet has no score/text overlap;
- heatmap magnet uses M1 concentration strip;
- closing magnet uses M1 closing drift strip.

- [ ] **Step 2: Verify RED**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart --plain-name "stats"'
```

Expected: FAIL on missing render-specific magnet/control assertions.

- [ ] **Step 3: Implement controls and magnet inputs**

Render selector options:

```text
Kategória scope
Hőtérkép
Hózárás
```

Magnet ownership:

```text
category scope: Kontroll trend marker, red/orange/green
heatmap: concentration marker, white/blue
closing: closing drift marker, red/white/green
```

No magnet strip contains text or numbers.

- [ ] **Step 4: Verify GREEN and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart --plain-name "stats"'
git add lib/features/stats/stats_page.dart lib/features/transactions/widgets/header_card/transaction_header_card.dart lib/features/transactions/widgets/header_card/magnet_strip.dart lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart test/stats/stats_page_test.dart
git commit -m "feat: wire stats header controls and magnets"
```

## Task 6: FastInfo Graph Painters

**Files:**
- Modify: `lib/features/stats/widgets/stats_fast_info_graph.dart`
- Modify: `test/stats/stats_page_test.dart`

**Interfaces:**
- Consumes: `StatsCategoryScopeSeries`, `StatsHeatmapSeries`, `StatsClosingSeries`.
- Produces: render-mode-specific graph-only FastInfo canvas.

- [ ] **Step 1: Write failing graph-only widget tests**

Verify accepted stacks:

```text
category scope: occurrence/value index, Behavior MACD, monthly scope Ft + impact line
heatmap: S1 cluster density, S2 Heat Pulse, H1 monthly heat load
closing: S2 Close Pulse, H1 monthly close + threshold points
```

Verify absent UI:

```text
no cards
no pills
no category chips
no settings controls
no long explanatory paragraphs
```

- [ ] **Step 2: Verify RED**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart --plain-name "FastInfo"'
```

Expected: FAIL until graph stack keys/labels/painters are implemented.

- [ ] **Step 3: Implement painters from approved HTML**

Category colors:

```text
occurrence #EF4444
value index #0EA5A4
risk green rgba(16,185,129,.55)
risk orange rgba(249,115,22,.55)
risk red rgba(239,68,68,.55)
MACD positive expense #EF4444
MACD negative expense #22C55E
Ft/kiugrás line orange
Egyéb #CBD5E1
```

Heatmap colors:

```text
primary #06B6D4
pale #DDF8FD
cyan #67E8F9
gray #CBD5E1 / #E2E8F0
```

Closing colors:

```text
expense #EF4444 / #FCA5A5
income #22C55E / #86EFAC
zero line rgba(100,116,139,.50)
labels #64748B
```

- [ ] **Step 4: Verify GREEN and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart --plain-name "FastInfo"'
git add lib/features/stats/widgets/stats_fast_info_graph.dart test/stats/stats_page_test.dart
git commit -m "feat: render stats fastinfo graph stacks"
```

## Task 7: Monthcards And Scope Sheet Visuals

**Files:**
- Modify: `lib/features/stats/widgets/stats_year_calendar.dart`
- Modify: `lib/features/stats/widgets/stats_category_scope_sheet.dart`
- Modify: `test/stats/stats_page_test.dart`

**Interfaces:**
- Consumes: `StatsYearData`, `StatsScopeSelection`.
- Produces: annual 12 monthcard surface, heatmap day-cell preservation, closing threshold dots, multi-select category scope sheet.

- [ ] **Step 1: Write failing widget/painter tests**

Verify:

- annual stats view renders 12 month hit targets;
- heatmap monthcard day-cell logic remains current white/blue implementation;
- closing monthcard shows active-side close and threshold point;
- default scope sheet shows active `ALL / Minden kategória`;
- selecting all categories one by one normalizes back to `ALL`;
- tapping a category does not close the sheet;
- bottom action is `Szűrőbeállítás`.

- [ ] **Step 2: Verify RED**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart --plain-name "scope sheet"'
```

Expected: FAIL on missing ALL/custom visual states or missing closing dot assertions.

- [ ] **Step 3: Implement only missing behavior**

Preserve existing accepted behavior:

```text
heatmapIntensity = clamp(scopeAmount(day) / threshold, 0..1)
closing threshold point = scopeAmount(day) >= threshold && scopeAmount(day) > 0
closing amount = activeTypeTotal(month)
```

- [ ] **Step 4: Verify GREEN and commit**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart --plain-name "scope sheet"'
git add lib/features/stats/widgets/stats_year_calendar.dart lib/features/stats/widgets/stats_category_scope_sheet.dart test/stats/stats_page_test.dart
git commit -m "feat: finish stats monthcards and scope sheet"
```

## Task 8: Final Verification

**Files:**
- Read/update: `docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md`
- Read: all approved HTML references.

**Interfaces:**
- Consumes: all previous task outputs.
- Produces: verified feature branch status and honest checklist states.

- [ ] **Step 1: Re-read references**

```bash
rg -n "STAT-(SHARED|CAT|HEAT|CLOSE)-" docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md
rg -n "Előfordulás vs értékindex|M1 · Koncentráció marker|S1 · Klaszter-sűrűség|S2 · Heat Pulse|M1 · Zárási drift|S2 · Close Pulse|H1 · Havi zárás" .superpowers/brainstorm/11665-1783356886/content/*.html
```

- [ ] **Step 2: Run targeted tests**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats'
```

Expected: all stats tests pass.

- [ ] **Step 3: Run analyze**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: no analyzer errors.

- [ ] **Step 4: Capture visual evidence**

Use screenshots/golden-style captures for:

- shared header with SummaryPill and 12 monthcards;
- category scope FastInfo stack;
- heatmap FastInfo stack;
- closing FastInfo stack;
- category sheet `ALL`, custom, and all-selected-normalized states.

- [ ] **Step 5: Update checklist honestly**

Set a row to `DONE` only when its acceptance condition has matching test/screenshot/code-inspection evidence. Keep rows `PARTIAL` or `NOT DONE` if implementation or verification is incomplete.

- [ ] **Step 6: Final commit**

```bash
git add docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md docs/superpowers/specs/2026-07-07-stats-main-menu-redesign-design.md docs/superpowers/plans/2026-07-07-stats-main-menu-redesign.md lib test
git commit -m "feat: implement annual stats render modes"
```

## Plan Self-Review

- Spec coverage: shared shell, category scope, heatmap, and hózárás annual main-menu requirements all map to tasks above.
- Deferred scope: month focus/detail is excluded from every task.
- TDD coverage: each behavior task starts with failing data/widget tests and verifies RED before production code.
- Visual coverage: each approved HTML file is mandatory at the gate and final verification.
- Build rule: no local APK build command appears in this plan.
