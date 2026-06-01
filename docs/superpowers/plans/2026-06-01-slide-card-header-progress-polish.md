# Slide Card Header Progress Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the latest slide-card sizing/dismiss behavior, preserve header content behind the limit editor, and make backheader progress-frame segments visibly fill the larger frame.

**Architecture:** Keep `SlideUpMenuCard` as the shared modal primitive and add outside-tap dismiss there so all three menus inherit it. Restore category editor sizing through the existing `_menuPanelHeight` paths, tune only the transaction sheet height for four visible category rows, and adjust `BudgetProgressFrame` segment geometry without changing budget math.

**Tech Stack:** Flutter widgets, existing widget tests, GitHub Actions Flutter analyze/test/build.

---

### Task 1: Regression Tests

**Files:**
- Modify: `test/transactions/slide_up_menu_card_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `test/transactions/header_layout_test.dart`
- Modify: `test/transactions/category_budget_stage_test.dart`

- [ ] Add a test that tapping the slide-card veil calls `onDismissed`.
- [ ] Add/update transaction picker test to assert a four-row category picker is visible inside the add transaction card.
- [ ] Add/update category editor height test to assert the add/edit category card returns to the prior summary-aligned height.
- [ ] Add a test that opening the budget limit editor still leaves header balance/category content in the tree.
- [ ] Add a test that budget progress-frame segments fill the frame height and use max opacity colors.

### Task 2: Shared Slide Card Outside Tap

**Files:**
- Modify: `lib/features/transactions/widgets/slide_up_menu_card.dart`

- [ ] Change veil tap from no-op to `_dismiss()`.
- [ ] Preserve existing drag dismissal and veil fade behavior.

### Task 3: Card Heights

**Files:**
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`

- [ ] Increase add transaction sheet height enough for four category rows while keeping bottom-aligned content behavior.
- [ ] Restore category editor menu height to the previous `screenHeight - TransactionMenuMetrics.overlayTop` calculation in shell and transaction home.

### Task 4: Header and Backheader Visuals

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_progress_frame.dart`

- [ ] Ensure the header card is still built with visible content while the budget editor overlay is open.
- [ ] Make progress-frame colored segments fill the larger frame inner height and render at full opacity.

### Task 5: Verification and Delivery

- [ ] Run local static diff checks.
- [ ] Commit and push.
- [ ] Run GitHub Actions Android workflow and confirm analyze, tests, build, and upload pass without downloading the artifact.
