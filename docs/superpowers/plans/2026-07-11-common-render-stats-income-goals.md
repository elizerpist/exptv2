# Common Render Stats + Bevételi Célok Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the income-side goal semantics and the common-render stats menu on top of `origin/integration/latest-main-build`.

**Architecture:** Keep persistence compatible with existing `category_limits`; add a presentation layer that separates expense limits from income goals. For stats, replace the old visible multi-render mode with one common stats render state, then add shared filtering, SearchPill/vendor scope, FAB threshold entry, page swipe, sum/year/month Page 1 layouts, and shared Page 2 metrics.

**Tech Stack:** Flutter/Dart, existing `TransactionStore`, `CategoryBudgetStage`, `StatsPage`, custom painters, Flutter widget/model tests through Ubuntu proot.

## Global Constraints

- Base branch is `origin/integration/latest-main-build`; implementation branch is `feature/common-render-stats-income-goals`.
- Required specs: `docs/superpowers/specs/2026-07-10-stat-common-render-page1-2-final-spec.md` and `docs/superpowers/specs/2026-07-11-income-category-goals-design.md`.
- Required visual references: `docs/prototypes/stats_common_2025_final_0710.html`, `docs/prototypes/stats_common_2025_stat_page_2_final_0710.html`, `docs/prototypes/stats_sum_mode_page1_yearcards.html`.
- Stats Page 1 and Page 2 copy must be Hungarian except `Expense Tracker`.
- Old visible stats render modes (`Kategória scope`, `Hózárás`, `Hőtérkép`) must not remain in the stats UI.
- Budget/limit stats must not be mixed into threshold-filtered Page 1/Page 2 stats.
- Flutter tests/analyze must run inside Ubuntu proot; do not run local Termux-host Flutter.

---

## Task 1: Income Goal Presentation Layer

**Files:**
- Create: `lib/features/transactions/models/income_goal_presentation.dart`
- Modify: `lib/features/transactions/models/budget_goal_kind.dart`
- Modify: `lib/features/transactions/models/backheader_budget_item.dart`
- Test: `test/transactions/income_goal_presentation_test.dart`

**Interfaces:**
- Produces `IncomeGoalPresentation.fromOverview(OverviewBudgetData)` and `IncomeGoalPresentation.fromCategory(CategoryBudgetBarData)`.
- Produces `actualIncome`, `goal`, `hasGoal`, `rawProgress`, `ringProgress`, `missing`, `surplus`, `statusText`, and `isComplete`.

- [ ] Write failing unit tests for `X hiányzik`, `Cél megvan`, `+X plusz`, `Nincs cél`.
- [ ] Write failing unit tests for clamped `ringProgress` and 100%+ success.
- [ ] Implement the presentation class.
- [ ] Change `BudgetGoalKind.incomeGoal.title` to `Összbevételi cél`.
- [ ] Keep `BudgetGoalKind.savingGoal` out of the income-side backheader list in later Task 2.
- [ ] Run:
  ```bash
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/income_goal_presentation_test.dart'
  ```

## Task 2: Backheader Income Goal Semantics

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/data/budget_progress_manager.dart`
- Test: `test/transactions/category_budget_stage_test.dart`
- Test: `test/transactions/budget_progress_manager_test.dart`
- Test: `test/transactions/transaction_store_budget_goals_test.dart`

**Interfaces:**
- Consumes `IncomeGoalPresentation`.
- Keeps existing `CategoryLimit` persistence.

- [ ] Write failing tests that income active items show `Összbevételi cél` then income category goals, with no `Megtakaritas`.
- [ ] Write failing widget test that `backheader-center-remaining-amount` shows `X hiányzik`, `Cél megvan`, or `+X plusz` for income active items.
- [ ] Write failing regression test that expense still shows `X maradt`.
- [ ] Route income overview/category amount text through goal presentation.
- [ ] Route income center/orbit progress through `actualIncome / goal`.
- [ ] Make income 100%+ progress use success/green rather than expense warning/danger.
- [ ] Run targeted transaction tests from the baseline command.

## Task 3: Stats Common State And Filters

**Files:**
- Modify: `lib/features/stats/data/stats_year_data.dart`
- Create: `lib/features/stats/data/stats_common_filter.dart`
- Create: `lib/features/stats/data/stats_layout_mode.dart`
- Test: `test/stats/stats_common_filter_test.dart`
- Test: `test/stats/stats_year_data_test.dart`

**Interfaces:**
- Produces `StatsLayoutMode.sum/year/month`.
- Produces one AND-composed filter: type, period/layout mode, active year/month, category scope, vendor scope, threshold.

- [ ] Write failing model tests for threshold + category + vendor filtering.
- [ ] Write failing model tests for sum/year/month record scopes.
- [ ] Write failing model tests that threshold 0 includes all scoped records.
- [ ] Implement filter helper and thread it into `StatsYearData`.
- [ ] Remove user-facing dependency on old `StatsRenderMode` values.
- [ ] Run stats model tests.

## Task 4: Stats Shell, SearchPill, FAB Threshold Entry

**Files:**
- Modify: `lib/features/stats/stats_page.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/shell/widgets/expt_fab.dart`
- Test: `test/stats/stats_page_test.dart`
- Test: shell/FAB test if an existing shell test file covers `ExptFab`

**Interfaces:**
- StatsPage exposes/receives threshold sheet opener state through shell-safe callback.
- `ExptFab` accepts an icon parameter while preserving default plus icon.

- [ ] Write failing widget test that StatsPage order includes SearchPill between SummaryPill and content viewport.
- [ ] Write failing widget test that stats threshold sheet has no render-mode selector.
- [ ] Write failing widget/shell test that stats-tab FAB uses threshold icon and does not open add transaction.
- [ ] Add SearchPill and vendor capsules to stats.
- [ ] Reuse shell vendor sheet callback for stats.
- [ ] Change stats-tab FAB icon and tap routing.
- [ ] Run stats/shell widget tests.

## Task 5: Page Swipe And Page 2 Metrics

**Files:**
- Create: `lib/features/stats/data/stats_page2_metrics.dart`
- Create: `lib/features/stats/widgets/stats_page2_summary.dart`
- Modify: `lib/features/stats/stats_page.dart`
- Test: `test/stats/stats_page2_metrics_test.dart`
- Test: `test/stats/stats_page_test.dart`

**Interfaces:**
- Page 2 consumes the same filtered records and active layout mode as Page 1.

- [ ] Write failing model tests for Page 2 metrics: monthly average, largest, top month, daily averages, zero-activity days, average event amount.
- [ ] Write failing widget test for top 3 highlighted boxes and lower two-column boxes.
- [ ] Write failing widget test for single selected category hiding the donut/100%.
- [ ] Write failing widget test for threshold warning in top/category/vendor panels.
- [ ] Implement metrics and Page 2 widget.
- [ ] Add horizontal page swipe with Page 1/Page 2 indicators.
- [ ] Run Page 2 model/widget tests.

## Task 6: Page 1 Common Month/Year/Month-Focus Layouts

**Files:**
- Modify: `lib/features/stats/widgets/stats_year_calendar.dart`
- Create: `lib/features/stats/widgets/stats_sum_year_cards.dart`
- Modify: `lib/features/stats/stats_page.dart`
- Test: `test/stats/stats_page_test.dart`
- Test: `test/stats/stats_sum_year_cards_test.dart`

**Interfaces:**
- Page 1 consumes `StatsLayoutMode`.

- [ ] Write failing widget/painter tests for sum-mode year cards with 6x2 month cells.
- [ ] Write failing test that tapping year/month cells updates layout mode and active period.
- [ ] Write failing test that month mode shows a single enlarged month card and top back button.
- [ ] Implement sum-mode year-card widget from the authoritative HTML geometry.
- [ ] Wire sum/year/month Page 1 modes into the swipe viewport.
- [ ] Run stats widget tests.

## Task 7: FastInfo Common Graph Math

**Files:**
- Modify: `lib/features/stats/data/stats_category_scope_series.dart`
- Modify: `lib/features/stats/widgets/stats_fast_info_graph.dart`
- Test: `test/stats/stats_category_scope_series_test.dart`
- Test: `test/stats/stats_page_test.dart`

**Interfaces:**
- Produces expense pressure score, income pattern-trend score, threshold excess helper, adaptive axes.

- [ ] Write failing tests for income pattern score no-signal, stable, worsening, improving.
- [ ] Write failing tests for threshold excess at threshold 0 and threshold > 0.
- [ ] Write failing tests for adaptive year/day x-axis label thinning.
- [ ] Implement score/excess helpers and Hungarian graph metadata.
- [ ] Ensure expense graph regression remains accepted.
- [ ] Run stats series tests.

## Task 8: Snapshot Model And FAB Sheet

**Files:**
- Create: `lib/features/stats/data/stats_snapshot.dart`
- Create: `lib/features/stats/data/stats_snapshot_repository.dart`
- Create: `lib/features/stats/widgets/stats_snapshot_sheet.dart`
- Modify: `lib/features/stats/stats_page.dart`
- Modify: `lib/features/shell/widgets/expt_fab.dart`
- Test: `test/stats/stats_snapshot_test.dart`
- Test: `test/stats/stats_page_test.dart`

**Interfaces:**
- Snapshot include-mask selectively applies stored state fields.

- [ ] Write failing model tests for include-mask recall.
- [ ] Write failing widget test for camera add card and centered add dialog.
- [ ] Write failing widget test for FAB horizontal drag stepping snapshots without opening the sheet.
- [ ] Implement snapshot model/repository and sheet UI.
- [ ] Wire snapshot recall into stats state recomputation.
- [ ] Run snapshot and stats widget tests.

## Task 9: Verification And Checklist Closure

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-11-common-render-stats-income-goals-checklist.md`

- [ ] Re-run targeted tests:
  ```bash
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart test/transactions/budget_progress_manager_test.dart test/transactions/transaction_store_budget_goals_test.dart test/stats/stats_year_data_test.dart test/stats/stats_page_test.dart test/stats/stats_category_scope_series_test.dart'
  ```
- [ ] Run analyze:
  ```bash
  proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
  ```
- [ ] Re-read the two specs and this checklist.
- [ ] Update every checklist row honestly to `DONE`, `PARTIAL`, `BLOCKED`, or `NOT DONE`.
- [ ] Do not claim the feature package complete unless every row is `DONE` or explicitly deferred by the user.
