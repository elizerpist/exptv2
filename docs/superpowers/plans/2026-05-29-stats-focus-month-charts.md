# Stats Focus Month Charts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a general stats dropdown menu, a focused month view, and visual monthly chart summaries to the statistics screen.

**Architecture:** Extend `CalendarMenuOverlay` to own annual/focused navigation state and the shared calendar view mode. Keep rendering bounded by focused widgets: one canvas widget for an enlarged month card and one chart widget that computes month-level aggregates from existing transaction/category models. The dropdown is the only view-mode surface in the stats menu and export actions are placeholder UI feedback.

**Tech Stack:** Flutter widgets, CustomPainter charts, existing transaction models, existing Flutter widget tests.

---

### Task 1: General Stats Dropdown

**Files:**
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Write failing tests**

Add widget tests that pump `CalendarMenuOverlay`, verify `calendar-mode-selector` is absent, tap `stats-menu-trigger`, select `stats-menu-mode-heatmap`, and verify `Hőtérkép` plus `calendar-heatmap-slider`. Add tests for `stats-menu-export-csv` and `stats-menu-export-pdf` placeholder snackbars.

- [ ] **Step 2: Verify red**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`
Expected: FAIL because `stats-menu-trigger` and export menu items do not exist.

- [ ] **Step 3: Implement dropdown**

Replace the inline `CalendarModeSelector` usage inside `CalendarMenuOverlay` with a `PopupMenuButton` keyed `stats-menu-trigger`. Menu entries use child keys `stats-menu-mode-normal`, `stats-menu-mode-summary`, `stats-menu-mode-heatmap`, `stats-menu-mode-category`, `stats-menu-export-csv`, and `stats-menu-export-pdf`. Mode selections call `_setMode`; export selections show SnackBars.

- [ ] **Step 4: Verify green**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`
Expected: PASS for dropdown tests and updated existing overlay tests.

### Task 2: Focus Month Navigation

**Files:**
- Create: `lib/features/transactions/widgets/calendar_menu/focused_month_canvas.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Write failing tests**

Add a widget test that taps the first annual month card through `calendar-canvas`, expects `calendar-focus-month-view`, `calendar-focus-month-canvas`, `calendar-focus-back`, and a month/year title, then taps back and expects the annual `calendar-canvas` again.

- [ ] **Step 2: Verify red**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`
Expected: FAIL because focused month widgets do not exist.

- [ ] **Step 3: Implement focus view**

Track `_focusedMonth` in `CalendarMenuOverlay`. Annual `CalendarCanvas.onMonthSelected` sets `_focusedMonth`; focused body renders `FocusedMonthCanvas` with the selected `CalendarMonthRenderData`. Back clears `_focusedMonth`.

- [ ] **Step 4: Verify green**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`
Expected: PASS for focus navigation.

### Task 3: Monthly Visual Charts

**Files:**
- Create: `lib/features/transactions/widgets/calendar_menu/month_stats_charts.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Write failing tests**

Add a widget test with sample transactions/categories, open a focused month, and expect keys `month-cashflow-chart`, `month-daily-sparkline`, `month-category-breakdown`, `month-weekly-bars`, and `month-highlight-tiles`. Verify representative labels: `Cashflow`, `Napi ritmus`, `Kategóriák`, `Heti bontás`, and `Kiemelések`.

- [ ] **Step 2: Verify red**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`
Expected: FAIL because month chart widgets do not exist.

- [ ] **Step 3: Implement chart widgets**

Add `MonthStatsCharts` with custom-painted cashflow bars, daily expense sparkline, category donut with top-three bars, weekly income/expense bars, and highlight tiles. Compute aggregates from `TransactionRecord` and `TransactionCategory` using the selected month.

- [ ] **Step 4: Verify green and full suite**

Run: `flutter analyze` and `flutter test`
Expected: analyzer has no issues and the full test suite passes.
