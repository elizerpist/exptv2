# Statistics Visual Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the stats tab so dominant category becomes the default visual mode with threshold filtering, compact draggable controls, larger focused month bubbles, expanded month analytics, and no settings placeholder.

**Architecture:** Keep the existing canvas-based calendar and stats overlay structure. Remove the separate threshold mode from `CalendarMenuMode`, make the threshold slider a dominant-category filter, and keep heatmap controls as the same reusable slider panel. Add focused-month analytics inside `MonthStatsCharts` using the existing transaction/category inputs.

**Tech Stack:** Flutter, Material widgets, custom canvas painters, `flutter_test`, GitHub Actions for Android APK build.

---

### Task 1: RED Tests

**Files:**
- Modify: `test/settings/settings_page_test.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`
- Modify: `test/transactions/calendar_render_builder_test.dart`

- [x] **Step 1: Define failing expectations**

Assert that settings no longer shows `Statisztikák`, `CalendarMenuMode.values` contains only category/summary/heatmap, sliders expose collapse/mini controls, month details include `month-deep-stats-grid` and `month-merchant-stats`, and the stats page starts on `Domináns kategória`.

- [x] **Step 2: Try local RED run**

Run: `/data/data/com.termux/files/home/flutter/bin/flutter test test/transactions/calendar_render_builder_test.dart test/transactions/calendar_menu_widgets_test.dart test/settings/settings_page_test.dart`

Expected in this Termux environment: local Flutter exits before tests with Android Bionic TLS alignment error. Actual RED/PASS verification must run through GitHub Actions.

### Task 2: Remove Settings Placeholder

**Files:**
- Modify: `lib/features/settings/settings_page.dart`
- Test: `test/settings/settings_page_test.dart`

- [ ] **Step 1: Remove enum and root option**

Delete `_SettingsMenu.statistics` and the `SettingsOptionItem(title: 'Statisztikák')`.

- [ ] **Step 2: Remove submenu body/title cases**

Delete the statistics `SimpleOptionsPanel` switch arm and `_menuTitle` switch arm.

### Task 3: Merge Threshold Into Dominant Category Mode

**Files:**
- Modify: `lib/features/transactions/models/calendar_menu_mode.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart`
- Test: `test/transactions/calendar_render_builder_test.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Remove normal mode**

Change `CalendarMenuMode` to `category, summary, heatmap` and keep titles `Domináns kategória`, `Összefoglaló`, `Hőtérkép`.

- [ ] **Step 2: Default stats overlay to category**

Initialize `_mode` as `CalendarMenuMode.category`, and show the threshold slider when category mode is active.

- [ ] **Step 3: Filter dominant category circles by threshold**

In the painter, draw dominant category circles only when `day.dominantCategoryId != null && day.meetsThreshold`. Remove the separate gray threshold-ring visual.

### Task 4: Compact Draggable Sliders

**Files:**
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Convert slider panel to stateful**

Track collapsed state and vertical offset inside `CalendarValueSliderPanel`.

- [ ] **Step 2: Add drag handle and collapse button**

Add `calendar-threshold-slider-drag-handle`, `calendar-threshold-slider-collapse`, `calendar-heatmap-slider-drag-handle`, and `calendar-heatmap-slider-collapse` keys.

- [ ] **Step 3: Add mini restore button**

When collapsed, render a small button at the bottom-left with keys `calendar-threshold-slider-mini-button` or `calendar-heatmap-slider-mini-button`, positioned above the on-screen debug button area.

### Task 5: Larger Focused Month Rendering

**Files:**
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart`

- [ ] **Step 1: Increase focused-month canvas height**

Use more of the available width and increase focused-month card height enough for larger day cells.

- [ ] **Step 2: Scale focused day circles and text**

Detect focused layout via the single month rect width, increase circle radius cap and day text size while keeping annual month cards unchanged.

### Task 6: Expanded Month Analytics

**Files:**
- Modify: `lib/features/transactions/widgets/calendar_menu/month_stats_charts.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Expand `_MonthStatsData`**

Add counts and derived metrics: income/expense counts, no-spend days, spend days, average transaction, median expense, net per day, income/expense ratio, weekend/weekday spend, top merchant, merchant totals, first/last transaction dates, best income day.

- [ ] **Step 2: Render `Havi részletek`**

Add a dense grid under highlights with key `month-deep-stats-grid`.

- [ ] **Step 3: Render `Kereskedők`**

Add merchant/category rows with key `month-merchant-stats`, including the top merchant name from records.

### Task 7: Verification, Push, Build

**Files:**
- Modify: production/test files above
- Read: `.github/workflows/android-build.yml`

- [ ] **Step 1: Analyze locally only if Flutter can run**

The current environment cannot run the Flutter SDK because Dart exits with TLS alignment error. Do not run local APK builds.

- [ ] **Step 2: Commit and push**

Commit tests and implementation on `feature/statistics-visual-rework`, then push to `origin`.

- [ ] **Step 3: Run GitHub Actions build**

Run `gh workflow run android-build.yml --ref feature/statistics-visual-rework`, wait for completion, and return the release asset link `https://github.com/elizerpist/exptv2/releases/download/debug-latest/exptv2-debug.apk`.
