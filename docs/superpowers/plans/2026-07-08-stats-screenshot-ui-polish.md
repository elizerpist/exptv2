# Stats Screenshot UI Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the stats screen regressions visible in the 2026-07-08 screenshot while preserving the latest merged main/backheader/FAB work.

**Architecture:** Keep the changes narrowly scoped. Stats-specific visual behavior is passed through existing header/FastInfo/theme entry points instead of forking the main menu. Monthcard background is a settings-backed theme value. FastInfo layout is centralized in `StatsFastInfoGraph` so category scope, heatmap, and closing use the same vertical rhythm, axis, and legend system.

**Tech Stack:** Flutter widgets, `CustomPainter`, existing `AppThemeSettings`/`ExpenseTheme`, widget tests through Ubuntu proot.

## Global Constraints

- Do not run local APK builds; GitHub Actions builds APKs.
- Run Flutter tests/analyze through Ubuntu proot.
- Preserve existing main-menu/backheader magnet behavior.
- FastInfo remains graph-only: no cards, no filter chips, no long paragraphs.
- Existing unrelated untracked files stay untouched.

---

### Task 1: Stats Header And Debug Button

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/magnet_strip.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/stats/stats_page.dart`
- Modify: `lib/core/debug/debug_floating_button.dart`
- Test: `test/transactions/magnet_strip_test.dart`
- Test: `test/stats/stats_page_test.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Add a stats-safe custom marker style to `MagnetStrip`.
- Add an optional pass-through marker style to `TransactionHeaderCard`.
- Keep stats chip color fixed at `Color(0xFFFBBF24)`.
- Move `DebugFloatingButton` to `left: 16`.

- [ ] Write failing tests for stats marker line, chip color, and debug left position.
- [ ] Run targeted tests and confirm they fail for the current screenshot behavior.
- [ ] Implement the marker style, fixed chip color, and left debug position.
- [ ] Run targeted tests and confirm they pass.

### Task 2: Stats Monthcard Background Setting

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Modify: `lib/features/settings/theme/expense_theme.dart`
- Modify: `lib/features/settings/widgets/options/theme_options_panel.dart`
- Modify: `lib/features/stats/stats_page.dart`
- Modify: `lib/features/stats/widgets/stats_year_calendar.dart`
- Test: `test/settings/expense_theme_test.dart`
- Test: `test/settings/settings_page_test.dart`
- Test: `test/stats/stats_page_test.dart`

**Interfaces:**
- Add `StatsMonthCardColor` with `white`, `gray`, `darkgray`.
- Add `statsMonthCardColor` to `AppThemeSettings` parse/serialize/copy/defaults.
- Add `statsMonthCard` color to `ExpenseTheme`.
- Pass `ExpenseTheme.statsMonthCard` into `StatsYearCalendar`.

- [ ] Write failing tests for settings parse/serialize/copy and stats calendar background.
- [ ] Run targeted tests and confirm failure.
- [ ] Implement the setting, theme resolver, settings UI, and calendar paint input.
- [ ] Run targeted tests and confirm pass.

### Task 3: FastInfo Chart Layout, Legends, And Axes

**Files:**
- Modify: `lib/features/stats/widgets/stats_fast_info_graph.dart`
- Test: `test/stats/stats_page_test.dart`

**Interfaces:**
- Centralize layout in a small immutable layout helper inside `StatsFastInfoGraph`.
- Use top/pulse/bottom chart rects that lower the top chart and preserve bottom chart bottom.
- Draw mode-specific legends and small x/y axis labels inside the graph canvas.
- Keep all chart labels within the canvas and out of the status bar.

- [ ] Write failing tests for graph height/layout keys across category scope, heatmap, and closing.
- [ ] Run targeted stats tests and confirm failure where current layout lacks the new markers.
- [ ] Implement layout helper, legend drawing, axis labels, and chart size adjustments.
- [ ] Run targeted stats tests and confirm pass.

### Task 4: Final Verification And Build

**Files:**
- Modify checklist statuses in `docs/superpowers/checklists/2026-07-08-stats-screenshot-ui-polish-checklist.md`.

**Interfaces:**
- The final main build must include commit `7d82959` plus this stats polish commit.

- [ ] Run `git diff --check`.
- [ ] Run targeted Flutter tests through Ubuntu proot.
- [ ] Run `flutter analyze` through Ubuntu proot.
- [ ] Push to `main`.
- [ ] Wait for GitHub Actions APK build.
- [ ] Download the APK to `/storage/emulated/0/Download/exptv2` without deleting existing APKs.
