# FastInfo Final Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved 17 FastInfo cards in both box and pill form, including fixed/scheduled exclusion rules, recurring income ghosts, detailed help sheets, and online GitHub build verification.

**Architecture:** Keep `FastInfoMetricsResolver` as the single calculation source. Add explicit actual-versus-variable aggregates, then pass typed visual descriptors to shared pill/box renderers so widgets do not parse display strings. Keep existing slot storage and migrate presentation settings without moving selected cards.

**Tech Stack:** Flutter/Dart, existing repository models, `flutter_test`, GitHub Actions Android workflow on `main`.

---

## File Structure

- Modify `lib/features/transactions/models/fast_info_metric.dart`: typed pill fields, visual descriptors, fixed-excluded badges, scheduled marker support.
- Modify `lib/features/transactions/data/fast_info_period_aggregates.dart`: actual and variable aggregate APIs, recurring-source detection, last-7/last-14 helpers, same-day month helpers.
- Modify `lib/features/transactions/state/fast_info_metrics_resolver.dart`: all 17 approved metrics.
- Modify `lib/features/transactions/widgets/header_card/fast_info_card_surfaces.dart`: 112 x 136 boxes and three-zone pills.
- Modify `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`: marker bars, split bars, deviation meters, strips, mini avatars, paid/remaining visuals.
- Modify `lib/features/settings/models/fast_info_config.dart`: independent upper/lower presentation modes.
- Modify `lib/features/settings/widgets/options/fast_info_options_panel.dart`: selectors for upper and lower rows.
- Modify `lib/features/settings/widgets/options/fast_info_card_help_sheet.dart`: handle-only drag dismissal and card-shaped preview top.
- Modify `lib/features/settings/widgets/options/fast_info_annotated_preview.dart`: arrows/callouts matching new visuals.
- Modify `lib/features/settings/models/fast_info_card_help.dart`: simple Hungarian help copy for all final cards.
- Modify recurring bridge/model path as needed: `lib/features/settings/models/recurring_transaction.dart`, `lib/features/transactions/models/recurring_ghost_record.dart`, `lib/features/transactions/data/transaction_repository.dart`, `lib/services/native_bridge.dart`.
- Add/modify tests: `test/transactions/fast_info_period_aggregates_test.dart`, `test/transactions/fast_info_metrics_resolver_test.dart`, `test/transactions/fast_info_panel_test.dart`, `test/settings/fast_info_options_panel_test.dart`, `test/settings/fast_info_card_help_sheet_test.dart`, `test/settings/fast_info_card_help_test.dart`, `test/transactions/recurring_ghost_log_test.dart`.

### Task 1: Variable Aggregate Foundation

**Files:**
- Test: `test/transactions/fast_info_period_aggregates_test.dart`
- Modify: `lib/features/transactions/data/fast_info_period_aggregates.dart`
- Modify: `lib/features/transactions/models/transaction_record.dart` if recurring source is missing

- [ ] **Step 1: Write the failing test**

Add a test where a normal grocery expense and activated rent exist on the same day:

```dart
test('variable expense totals exclude activated recurring expenses', () {
  final data = FastInfoPeriodAggregates(
    snapshot: FastInfoMetricSnapshot(
      now: DateTime(2026, 6, 10, 12),
      balance: 0,
      transactions: <TransactionRecord>[
        _tx(1, '2026.06.10', -5000, recurringTransactionId: null),
        _tx(2, '2026.06.10', -200000, recurringTransactionId: 77),
      ],
    ),
  );

  expect(data.todayExpense, 205000);
  expect(data.todayVariableExpense, 5000);
  expect(data.variableExpenseBetween(data.currentMonthStart, data.tomorrow), 5000);
});
```

- [ ] **Step 2: Run red**

Run: `flutter test test/transactions/fast_info_period_aggregates_test.dart --plain-name "variable expense totals exclude activated recurring expenses"`

Expected: FAIL because `todayVariableExpense` and `variableExpenseBetween` do not exist.

- [ ] **Step 3: Implement green**

Add a recurring source marker to `TransactionRecord` if needed. Add `variableExpenseRows`, `todayVariableExpense`, `variableExpenseBetween`, and `variableExpenseRowsBetween` to `FastInfoPeriodAggregates`.

- [ ] **Step 4: Verify green and commit**

Run the same targeted test. Expected: PASS.

Commit:

```bash
git add lib/features/transactions/data/fast_info_period_aggregates.dart lib/features/transactions/models/transaction_record.dart test/transactions/fast_info_period_aggregates_test.dart
git commit -m "Add variable FastInfo aggregates"
```

### Task 2: Daily, Weekly, Monthly Spend Metrics

**Files:**
- Test: `test/transactions/fast_info_metrics_resolver_test.dart`
- Modify: `lib/features/transactions/state/fast_info_metrics_resolver.dart`
- Modify: `lib/features/transactions/models/fast_info_metric.dart`

- [ ] **Step 1: Write failing tests**

Add one focused group proving:

```dart
expect(metrics['mai_koltes']!.primaryValue, '205 000 Ft elköltve');
expect(metrics['mai_koltes']!.progress, closeTo(5000 / dailyCeiling, 0.001));
expect(metrics['mai_koltes']!.secondaryValues, contains('12 300 Ft költhető'));
expect(metrics['heti_koltes']!.secondaryValues.any((v) => v.startsWith('időarányhoz képest')), isTrue);
expect(metrics['havi_koltes']!.secondaryValues.any((v) => v.startsWith('előző hónap index:')), isTrue);
```

- [ ] **Step 2: Run red**

Run: `flutter test test/transactions/fast_info_metrics_resolver_test.dart --plain-name "daily weekly monthly FastInfo metrics use variable pace"`

Expected: FAIL because current resolver uses actual expense for pace/progress and lacks approved labels.

- [ ] **Step 3: Implement green**

Update `_todaySpend`, `_weeklySpend`, and `_monthlySpend` so actual visible totals and variable progress totals are separate. Emit approved labels: `x költhető`, `napi átlaghoz képest:`, `időarányhoz képest <n>p`, and `előző hónap index: <n>%`.

- [ ] **Step 4: Verify green and commit**

Run the same targeted test. Expected: PASS.

Commit:

```bash
git add lib/features/transactions/state/fast_info_metrics_resolver.dart lib/features/transactions/models/fast_info_metric.dart test/transactions/fast_info_metrics_resolver_test.dart
git commit -m "Update FastInfo spend pace metrics"
```

### Task 3: Typed Visual Descriptors

**Files:**
- Test: `test/transactions/fast_info_metrics_resolver_test.dart`
- Modify: `lib/features/transactions/models/fast_info_metric.dart`
- Modify: `lib/features/transactions/state/fast_info_metrics_resolver.dart`

- [ ] **Step 1: Write failing tests**

Assert typed visuals exist for representative cards:

```dart
expect(metrics['mai_koltes']!.visual.kind, FastInfoVisualKind.thresholdMarkerBar);
expect(metrics['heti_koltes']!.visual.kind, FastInfoVisualKind.deviationMeter);
expect(metrics['top_kategoria_heten']!.visual.kind, FastInfoVisualKind.miniAvatarRow);
expect(metrics['kiadas_bevetel_arany']!.visual.kind, FastInfoVisualKind.remainingSpentSplit);
```

- [ ] **Step 2: Run red**

Run: `flutter test test/transactions/fast_info_metrics_resolver_test.dart --plain-name "approved FastInfo cards expose typed visuals"`

Expected: FAIL because `visual` and `FastInfoVisualKind` do not exist.

- [ ] **Step 3: Implement green**

Add `FastInfoVisualKind` and `FastInfoVisualDescriptor` to `fast_info_metric.dart`. Populate all 17 cards with explicit visual descriptors: threshold marker bar, deviation meter, same-day index marker, goal marker, zone marker, avatar, projection fill, overflow risk, 14-day strip, spike line, 7-day strip, mini avatars, analog meter, seven-day fixed load, paid/remaining split, income comparison bars, remaining/spent split.

- [ ] **Step 4: Verify green and commit**

Run targeted test. Expected: PASS.

Commit:

```bash
git add lib/features/transactions/models/fast_info_metric.dart lib/features/transactions/state/fast_info_metrics_resolver.dart test/transactions/fast_info_metrics_resolver_test.dart
git commit -m "Add typed FastInfo visual descriptors"
```

### Task 4: Remaining Metric Rules

**Files:**
- Test: `test/transactions/fast_info_metrics_resolver_test.dart`
- Modify: `lib/features/transactions/state/fast_info_metrics_resolver.dart`
- Modify: `lib/features/transactions/data/fast_info_period_aggregates.dart`

- [ ] **Step 1: Write failing tests**

Cover these exact rules:

```dart
expect(metrics['no_spend_napok_szama']!.primaryValue, '3 / 7 nap');
expect(metrics['top_kategoria_heten']!.secondaryValues.join(' '), contains('Hét'));
expect(metrics['legnagyobb_novekedo_kategoria']!.secondaryValues.join(' '), contains('%'));
expect(metrics['havi_fix_koltseg_osszesen']!.secondaryValues.join(' '), contains('fixből'));
expect(metrics['kiadas_bevetel_arany']!.primaryValue, contains('maradt'));
```

Also add data where rent would win if fixed items were not excluded.

- [ ] **Step 2: Run red**

Run: `flutter test test/transactions/fast_info_metrics_resolver_test.dart`

Expected: FAIL on the newly added assertions.

- [ ] **Step 3: Implement green**

Update merchant ranking, top categories, no-spend days, category change, next fixed, monthly fixed, monthly income, and income spent ratio to match the spec. Use variable rows where the spec says `fixek nélkül`; use actual rows for real-money cards.

- [ ] **Step 4: Verify green and commit**

Run the full resolver test file. Expected: PASS.

Commit:

```bash
git add lib/features/transactions/state/fast_info_metrics_resolver.dart lib/features/transactions/data/fast_info_period_aggregates.dart test/transactions/fast_info_metrics_resolver_test.dart
git commit -m "Complete approved FastInfo metrics"
```

### Task 5: Render Approved Pill and Box Anatomy

**Files:**
- Test: `test/transactions/fast_info_panel_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_card_surfaces.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_visuals.dart`

- [ ] **Step 1: Write failing widget tests**

Assert a pill has title, primary, secondary, and visual keys:

```dart
expect(find.byKey(const ValueKey('fastinfo-pill-title-kiadas_bevetel_arany')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-pill-primary-kiadas_bevetel_arany')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-pill-secondary-kiadas_bevetel_arany')), findsOneWidget);
expect(find.byKey(const ValueKey('fastinfo-visual-remaining-spent-kiadas_bevetel_arany')), findsOneWidget);
```

Add a box-size test that pumps constrained `112 x 136` cards and expects no overflow exception.

- [ ] **Step 2: Run red**

Run: `flutter test test/transactions/fast_info_panel_test.dart --plain-name "approved pill anatomy renders title values and visual"`

Expected: FAIL because current pills render one centered value.

- [ ] **Step 3: Implement green**

Update `FastInfoPillCard` to the three-zone layout. Update `FastInfoBoxCard` to 136px height, smaller approved avatars, tighter label/value spacing, and visuals that do not clip text.

- [ ] **Step 4: Verify green and commit**

Run targeted widget test. Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/header_card/fast_info_card_surfaces.dart lib/features/transactions/widgets/header_card/fast_info_visuals.dart test/transactions/fast_info_panel_test.dart
git commit -m "Render approved FastInfo card anatomy"
```

### Task 6: Independent Upper and Lower Row Presentation

**Files:**
- Test: `test/settings/fast_info_options_panel_test.dart`
- Modify: `lib/features/settings/models/fast_info_config.dart`
- Modify: `lib/features/settings/widgets/options/fast_info_options_panel.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`

- [ ] **Step 1: Write failing tests**

Assert four layouts are possible: upper pill/lower box, upper box/lower box, upper pill/lower pill, upper box/lower pill. Assert card IDs do not move when presentation changes.

- [ ] **Step 2: Run red**

Run: `flutter test test/settings/fast_info_options_panel_test.dart --plain-name "FastInfo row presentation can be changed independently"`

Expected: FAIL because config only supports `mixed` and `sixBoxes`.

- [ ] **Step 3: Implement green**

Add row presentation fields. Migrate old `mixed` to upper pill/lower box and old `sixBoxes` to upper box/lower box. Add two settings selectors and render rows from the new fields.

- [ ] **Step 4: Verify green and commit**

Run targeted test. Expected: PASS.

Commit:

```bash
git add lib/features/settings/models/fast_info_config.dart lib/features/settings/widgets/options/fast_info_options_panel.dart lib/features/transactions/widgets/header_card/fast_info_panel.dart test/settings/fast_info_options_panel_test.dart
git commit -m "Add independent FastInfo row presentation"
```

### Task 7: Recurring Income Ghosts

**Files:**
- Test: `test/transactions/recurring_ghost_log_test.dart`
- Modify: `lib/features/settings/models/recurring_transaction.dart`
- Modify: `lib/features/transactions/models/recurring_ghost_record.dart`
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/services/native_bridge.dart`

- [ ] **Step 1: Write failing tests**

Add a test where an active recurring income appears as an income ghost with category metadata and is available to `FastInfoMetricSnapshot`.

- [ ] **Step 2: Run red**

Run: `flutter test test/transactions/recurring_ghost_log_test.dart --plain-name "recurring income ghosts are loaded for FastInfo"`

Expected: FAIL because current app path does not expose income ghosts.

- [ ] **Step 3: Implement green**

Preserve `transactionType == income` through the bridge, repository payload, `RecurringGhostRecord`, and snapshot. Keep `expensesOnly: true` filters expense-only, but never globally drop income ghosts.

- [ ] **Step 4: Verify green and commit**

Run targeted test. Expected: PASS.

Commit:

```bash
git add lib/features/settings/models/recurring_transaction.dart lib/features/transactions/models/recurring_ghost_record.dart lib/features/transactions/data/transaction_repository.dart lib/services/native_bridge.dart test/transactions/recurring_ghost_log_test.dart
git commit -m "Support recurring income ghosts"
```

### Task 8: Help Sheet Interaction and Copy

**Files:**
- Test: `test/settings/fast_info_card_help_sheet_test.dart`
- Test: `test/settings/fast_info_card_help_test.dart`
- Modify: `lib/features/settings/widgets/options/fast_info_card_help_sheet.dart`
- Modify: `lib/features/settings/widgets/options/fast_info_annotated_preview.dart`
- Modify: `lib/features/settings/models/fast_info_card_help.dart`

- [ ] **Step 1: Write failing tests**

Assert all 17 final cards have complete help metadata. Assert dragging the handle down closes the sheet, dragging body text scrolls without closing, and help copy contains simple Hungarian labels such as `Ez azt mutatja`, `Így számol`, and `fixek nélkül` where applicable.

- [ ] **Step 2: Run red**

Run: `flutter test test/settings/fast_info_card_help_sheet_test.dart test/settings/fast_info_card_help_test.dart`

Expected: FAIL on handle-only dismissal and updated copy.

- [ ] **Step 3: Implement green**

Move dismiss drag handling onto the handle widget only. Keep the body as scroll-only. Add card-shaped preview top and update annotated arrows/copy for every card.

- [ ] **Step 4: Verify green and commit**

Run both help test files. Expected: PASS.

Commit:

```bash
git add lib/features/settings/widgets/options/fast_info_card_help_sheet.dart lib/features/settings/widgets/options/fast_info_annotated_preview.dart lib/features/settings/models/fast_info_card_help.dart test/settings/fast_info_card_help_sheet_test.dart test/settings/fast_info_card_help_test.dart
git commit -m "Update FastInfo help sheets"
```

### Task 9: Regression and Online Build

**Files:**
- No source changes expected.

- [ ] **Step 1: Run targeted tests**

Run:

```bash
flutter test test/transactions/fast_info_period_aggregates_test.dart test/transactions/fast_info_metrics_resolver_test.dart test/transactions/fast_info_panel_test.dart test/settings/fast_info_options_panel_test.dart test/settings/fast_info_card_help_sheet_test.dart test/settings/fast_info_card_help_test.dart test/transactions/recurring_ghost_log_test.dart
```

Expected: PASS if local Flutter is runnable. If local Flutter still fails with ARM64 Bionic TLS alignment, record the exact failure.

- [ ] **Step 2: Run full local checks**

Run:

```bash
flutter analyze
flutter test
```

Expected: PASS if local Flutter is runnable.

- [ ] **Step 3: Push main**

Run:

```bash
git status --short --branch
git push origin main
```

Expected: push succeeds.

- [ ] **Step 4: Watch GitHub Actions**

Run:

```bash
gh run list --branch main --workflow android-build.yml --limit 1
gh run watch --exit-status
```

Expected: `Exptv2 Android APK Build` succeeds.

- [ ] **Step 5: Verify APK release**

Run:

```bash
gh release view debug-latest --json tagName,name,assets
```

Expected: release `debug-latest` contains `exptv2-debug.apk`.

## Self-Review

- Spec coverage: Tasks 1-8 cover fixed exclusions, all 17 cards, row presentation, recurring income ghosts, and help sheets. Task 9 covers online build.
- Placeholder scan: no unresolved marker language is present.
- Type consistency: `FastInfoVisualKind`, `FastInfoVisualDescriptor`, `FastInfoMetricResult.visual`, and row presentation fields are introduced before later tasks depend on them.
