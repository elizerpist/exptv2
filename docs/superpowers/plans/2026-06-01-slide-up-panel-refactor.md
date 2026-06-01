# Slide-Up Panel Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the transaction, category, and limit slide-up cards share one sizing/interaction policy while preserving FAB double tap and correct header visibility.

**Architecture:** Introduce a small shared metrics module for slide-up panel heights, bottom spacing, and gesture timing. Keep each feature panel responsible for its own content, but route panel dimensions through the shared policy so transaction/category/limit sheets align consistently. Keep FAB double-tap recognition outside Flutter's delayed tap recognizer so single-tap open latency can be controlled and logged.

**Tech Stack:** Flutter widgets, existing `DebugConsole`, existing widget tests, GitHub Actions Android build.

---

### Task 1: Shared Panel Metrics

**Files:**
- Create: `lib/features/transactions/widgets/slide_up_panel_metrics.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`

- [ ] Create `SlideUpPanelMetrics` with `actionBottomInset = 24`, `horizontalInset = 20`, `fullHeight(context)`, `transactionHeight(context, pickerOpen)`, and `budgetHeight(context)`.
- [ ] Replace per-file hard-coded panel heights with this shared policy.
- [ ] Make `transactionHeight(... pickerOpen: true)` use the same full-height top anchor as category editor, so the category picker expands upward while the save button remains at the same bottom distance.

### Task 2: AddTransaction Anchored Layout And Logs

**Files:**
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Test: `test/widget_test.dart`

- [ ] Extend the transaction category picker test to assert the expanded transaction card reaches category-editor height and the save button bottom remains fixed.
- [ ] Add debug logs for transaction sheet build/open context: editing mode, picker state, category count, requested panel height.
- [ ] Keep `dragExclusionKeys` around the category scroll list so list swipes scroll only the list.

### Task 3: FAB Tap Timing Refactor

**Files:**
- Modify: `lib/features/shell/widgets/expt_fab.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Test: `test/widget_test.dart`

- [ ] Replace framework `onDoubleTap` with a stateful short-window tap dispatcher.
- [ ] Log first tap, single dispatch, double dispatch, and shell open request timing.
- [ ] Preserve behavior: single tap opens AddTransaction, long press opens AddCategory, double tap opens BudgetTargetEditor.

### Task 4: Category Editor Slot Toggle

**Files:**
- Modify: `lib/features/transactions/widgets/category_menu/category_editor_panel.dart`
- Test: `test/transactions/category_editor_test.dart`

- [ ] Add a small icon button in the `Válassz színt` / `Válassz ikont` row.
- [ ] Tap toggles color/icon pages in an infinite loop.
- [ ] Keep horizontal swipe behavior unchanged.

### Task 5: Header Content Visibility

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/widget_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] Stop forcing `_headerExpanded = true` when FAB double tap opens the budget editor from a visible header.
- [ ] Keep content hidden when the backheader is already active and the limit editor opens from a backheader bar.
- [ ] Add coverage for visible header + budget editor: balance/category content opacity remains visible.

### Task 6: Verification And Push

**Files:**
- Run checks only.

- [ ] Run `git diff --check`.
- [ ] Attempt targeted Flutter tests locally; if Flutter is unavailable, record that explicitly.
- [ ] Commit and push to `feature/backheader-budget-goals`.
- [ ] Manually trigger `android-build.yml` on the feature branch and watch it to success.
- [ ] Do not download the artifact.
