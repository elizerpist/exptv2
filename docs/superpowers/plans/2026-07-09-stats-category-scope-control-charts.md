# Stats Category Scope Control Charts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the category-scope FastInfo charts with the approved two-function control model for expense and income, then push and build online.

**Architecture:** Keep `StatsYearData` as the source of active graph months and scoped daily/monthly amounts. Move the new category-scope calculations into `StatsCategoryScopeSeries`, then keep `StatsFastInfoGraph` as a painter-only surface that reads the model and draws the two approved charts.

**Tech Stack:** Flutter/Dart, existing stats widgets, targeted Flutter tests in Ubuntu proot, GitHub Actions APK build.

## Global Constraints

- Approved HTML reference: `.superpowers/brainstorm/26096-1783533355/content/stats-category-scope-current-and-ideas-v1.html`, sections I-M.
- No local Flutter APK build on Termux/Android ARM64; APK builds must run online through GitHub Actions.
- Preserve existing stats menu navigation, summary pill, income/expense switch, render-mode selector, category scope sheet, and month-card focus behavior.
- Do not delete anything from `/storage/emulated/0/Download/exptv2`.

---

### Task 1: Model tests for the approved control charts

**Files:**
- Modify: `test/stats/stats_category_scope_series_test.dart`

**Interfaces:**
- Consumes: existing `StatsCategoryScopeSeries`.
- Produces: failing tests for expense dynamic EMA, income rare-event buckets, threshold-zero denominator, and month labels.

- [ ] Write failing tests for the approved model behavior.
- [ ] Run `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/stats/stats_category_scope_series_test.dart'` and confirm the new tests fail for missing model support.

### Task 2: Implement category-scope model

**Files:**
- Modify: `lib/features/stats/data/stats_category_scope_series.dart`

**Interfaces:**
- Produces: `controlBars`, `secondaryLine`, `monthLabels`, and chart semantics for expense/income.

- [ ] Add focused model types for control bars and secondary line points.
- [ ] Implement expense dynamic EMA control histogram with 50 baseline.
- [ ] Implement income monthly/event income-strength histogram with 50 baseline.
- [ ] Implement threshold-zero active-day denominator behavior.
- [ ] Run the targeted model test and keep it green.

### Task 3: Update FastInfo painter and metadata

**Files:**
- Modify: `lib/features/stats/widgets/stats_fast_info_graph.dart`
- Modify: `test/stats/stats_page_test.dart`

**Interfaces:**
- Consumes: new `StatsCategoryScopeSeries` model fields.
- Produces: two category-scope charts with legends, x/y axis labels, active month labels, red/green control bars, and orange secondary line.

- [ ] Add failing metadata/widget tests for two category-scope charts.
- [ ] Replace old three-chart category-scope drawing with two-chart drawing.
- [ ] Run targeted stats widget tests.

### Task 4: Verify, commit, push, build, download

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-09-stats-category-scope-control-charts-checklist.md`

**Interfaces:**
- Consumes: all implementation and tests.
- Produces: pushed branch and downloaded GitHub Actions APK.

- [ ] Re-read the checklist and approved HTML sections I-M.
- [ ] Run targeted Flutter tests in Ubuntu proot.
- [ ] Update checklist statuses honestly.
- [ ] Commit and push `integration/latest-main-build`.
- [ ] Trigger/watch GitHub Actions build and download the APK to `/storage/emulated/0/Download/exptv2` without deleting existing files.
