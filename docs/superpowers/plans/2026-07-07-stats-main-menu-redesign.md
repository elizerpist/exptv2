# Stats Main Menu Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the stats tab annual main menu with the approved header-card, type-pill, SummaryPill, annual month-card, threshold joystick, scope sheet, render-mode selector, and graph-only FastInfo design.

**Architecture:** Keep transaction home behavior unchanged. Build a stats-specific annual view in `lib/features/stats/` and reuse shared visual components where they are already exact: `TransactionHeaderCard`, `TransactionTypePills`, `SummaryPill`, `CalendarCanvasLayout`, and `CalendarValueSliderPanel`. Add stats-specific data and painters for scope-aware calculations, header feedback, month cards, and graph-only FastInfo.

**Tech Stack:** Flutter, Dart widget tests, existing app theme tokens, existing transaction models.

## Global Constraints

- Work on branch `feature/stats-menu-main-redesign`.
- Do not implement month focus/detail in this branch.
- Use approved HTML references from `.superpowers/brainstorm/11665-1783356886/content/`.
- Use UTF-8 Hungarian UI copy.
- Do not run local Flutter APK builds in Termux; use proot Ubuntu for Flutter tests/analyze.
- Write failing tests before production code.

---

### Task 1: Stats Annual Data Model

**Files:**
- Create: `lib/features/stats/data/stats_year_data.dart`
- Create: `test/stats/stats_year_data_test.dart`

**Interfaces:**
- Produces: `StatsRenderMode`, `StatsDayData`, `StatsMonthData`, `StatsYearData`, `StatsYearData.build(...)`, `StatsYearData.headerLabel`, `StatsYearData.headerValue`, `StatsYearData.summaryValue`.
- Consumes: `TransactionRecord`, `TransactionCategory`, `TransactionType`, `formatHuf`.

- [ ] **Step 1: Write the failing test**

```dart
test('stats year data measures threshold by active type and selected scope', () {
  final data = StatsYearData.build(
    year: 2026,
    activeType: TransactionType.expense,
    mode: StatsRenderMode.categoryScope,
    thresholdValue: 5000,
    transactions: [
      record(id: 1, date: '2026-01-01', amount: -6000, categoryId: 1),
      record(id: 2, date: '2026-01-01', amount: -30000, categoryId: 2),
      record(id: 3, date: '2026-01-02', amount: -4000, categoryId: 1),
      record(id: 4, date: '2026-01-03', amount: 9000, categoryId: 3),
    ],
    categories: [
      category(id: 1, name: 'Gyorskaja', type: TransactionType.expense),
      category(id: 2, name: 'Ruha', type: TransactionType.expense),
      category(id: 3, name: 'Fizetés', type: TransactionType.income),
    ],
    selectedCategoryIds: {1},
  );

  final january = data.months.first;
  expect(january.days[0].scopeAmount, 6000);
  expect(january.days[0].meetsThreshold, isTrue);
  expect(january.days[1].scopeAmount, 4000);
  expect(january.days[1].meetsThreshold, isFalse);
  expect(january.days[2].scopeAmount, 0);
  expect(january.thresholdHitDays, 1);
  expect(data.summaryValue, '40 000 Ft');
  expect(data.headerLabel, 'SCOPE TREND');
  expect(data.headerValue, contains('Gyorskaja'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_year_data_test.dart'`

Expected: FAIL because `StatsYearData` does not exist.

- [ ] **Step 3: Implement minimal data builder**

Create immutable stats data classes, group records by date, calculate active amount, scope amount, threshold hits, month totals, year totals, active scope label, header label/value, and graph series.

- [ ] **Step 4: Run test to verify it passes**

Run the same targeted Flutter test. Expected: PASS.

### Task 2: Shared Header And Joystick Hooks

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`
- Modify: `lib/features/transactions/models/calendar_menu_mode.dart`
- Test: `test/transactions/header_card_test.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`

**Interfaces:**
- Produces: optional `labelText`, `showBalanceVisibilityButton`, and `onTap` support.
- Consumes: existing widgets must keep default behavior unchanged.

- [ ] **Step 1: Write failing tests**

Add tests that `TransactionHeaderCard(labelText: 'HEATMAP', showBalanceVisibilityButton: false, ...)` renders `HEATMAP` and no visibility button, and `CalendarValueSliderPanel.threshold(onTap: ...)` fires tap without breaking long-press value control.

- [ ] **Step 2: Run targeted tests to verify failure**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/header_card_test.dart test/transactions/calendar_menu_widgets_test.dart'`

Expected: FAIL before optional parameters exist.

- [ ] **Step 3: Implement minimal widget hooks**

Add optional constructor parameters with defaults preserving the transaction home. Add `onTap` to joystick trigger `GestureDetector`.

- [ ] **Step 4: Run targeted tests to verify pass**

Run the same test command. Expected: PASS.

### Task 3: Stats Annual Calendar And FastInfo Graph

**Files:**
- Create: `lib/features/stats/widgets/stats_year_calendar.dart`
- Create: `lib/features/stats/widgets/stats_fast_info_graph.dart`
- Test: `test/stats/stats_page_test.dart`

**Interfaces:**
- Consumes: `StatsYearData`.
- Produces: `StatsYearCalendar`, `StatsFastInfoGraph`, keys `stats-year-calendar`, `stats-month-hit-1`, `stats-fastinfo-graph`.

- [ ] **Step 1: Write failing widget tests**

Test that the annual calendar renders one custom paint and 12 month hit targets, and the FastInfo graph is a graph-only surface keyed by `stats-fastinfo-graph`.

- [ ] **Step 2: Run targeted tests to verify failure**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart'`

Expected: FAIL because widgets do not exist.

- [ ] **Step 3: Implement painters**

Implement month card painter using the existing month-card constants and FastInfo graph painter with mode-specific line/bar/heat visuals.

- [ ] **Step 4: Run targeted tests to verify pass**

Run the same targeted test. Expected: PASS.

### Task 4: Stats Scope Sheet

**Files:**
- Create: `lib/features/stats/widgets/stats_category_scope_sheet.dart`
- Test: `test/stats/stats_page_test.dart`

**Interfaces:**
- Produces: `StatsCategoryScopeSheet`, keys `stats-scope-sheet`, `stats-scope-category-<id>`, `stats-scope-apply`.
- Consumes: active type, categories, selected ids.

- [ ] **Step 1: Write failing widget tests**

Test that the sheet filters by active type, category taps toggle multiple selections without closing, and apply returns the selected ids.

- [ ] **Step 2: Run targeted tests to verify failure**

Run the stats page test file. Expected: FAIL because sheet does not exist.

- [ ] **Step 3: Implement sheet**

Use the main category sheet's visual language: top handle, title, two-column category cards, active border/background, and bottom primary pill labeled `Szűrő beállítása`.

- [ ] **Step 4: Run targeted tests to verify pass**

Run the same targeted test. Expected: PASS.

### Task 5: StatsPage Integration

**Files:**
- Modify: `lib/features/stats/stats_page.dart`
- Test: `test/stats/stats_page_test.dart`
- Update: `test/transactions/calendar_menu_widgets_test.dart` only where old StatsPage wrapper expectations no longer apply.

**Interfaces:**
- Consumes: `TransactionStore`, `ExpenseTheme`, `StatsYearData`, stats widgets, shared header/type/summary/joystick widgets.
- Produces: annual stats main menu.

- [ ] **Step 1: Write failing integration tests**

Test that `StatsPage` renders `TransactionHeaderCard`, `TransactionTypePills`, `SummaryPill`, `StatsYearCalendar`, and the threshold joystick; does not render `CalendarMenuOverlay`; joystick tap opens render selector; category header button opens scope sheet; header drag reveals graph FastInfo.

- [ ] **Step 2: Run tests to verify failure**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_page_test.dart test/transactions/calendar_menu_widgets_test.dart'`

Expected: FAIL before integration.

- [ ] **Step 3: Implement StatsPage**

Build the annual stats stack, local year/type/mode/scope/threshold state, header pull spring, modal scope sheet, and modal render selector. Keep month tap no-op in this branch.

- [ ] **Step 4: Run targeted tests to verify pass**

Run the same command. Expected: PASS.

### Task 6: Final Verification And Commit

**Files:**
- Update: `docs/superpowers/checklists/2026-07-06-stats-header-monthcard-redesign-checklist.md`

**Interfaces:**
- Produces: honest checklist statuses and committed branch.

- [ ] **Step 1: Run analyze**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'`

Expected: no new analyzer errors.

- [ ] **Step 2: Run targeted tests**

Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats test/transactions/calendar_menu_widgets_test.dart test/transactions/header_card_test.dart test/transactions/calendar_render_builder_test.dart'`

Expected: all targeted tests pass.

- [ ] **Step 3: Update checklist**

Mark implemented annual-main-menu requirements `DONE`, keep month-focus requirements deferred.

- [ ] **Step 4: Commit**

Run: `git add ... && git commit -m "feat: redesign stats main menu"`

- [ ] **Step 5: Push branch**

Run: `git push -u origin feature/stats-menu-main-redesign`

Expected: branch pushed for GitHub Actions.

## Self-Review

- Spec coverage: annual header, type pills, SummaryPill, render modes, joystick tap/drag, scope sheet, FastInfo graph, and no month focus all map to tasks.
- Placeholder scan: no TBD/TODO/fill-later instructions.
- Type consistency: stats model and widget names are consistent across tasks.
