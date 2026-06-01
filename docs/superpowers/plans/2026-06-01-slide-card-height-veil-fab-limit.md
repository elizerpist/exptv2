# Slide Card Height, Veil Fade, FAB Limit Trigger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the three slide-up cards sit lower/shorter, fade the focus veil with the slide state, open the limit editor from FAB double tap, and prevent the transaction category picker scroll from dragging the parent card.

**Architecture:** Keep the existing `SlideUpMenuCard` as the shared interaction primitive. Add keyed drag-exclusion zones for nested scrollables, compute veil opacity from entry and drag progress, and route FAB double-tap requests through `ExptShell` into `TransactionHomePage` with a small signal prop.

**Tech Stack:** Flutter widgets, widget tests, existing transaction state/store.

---

### Task 1: Regression Tests

**Files:**
- Modify: `test/transactions/slide_up_menu_card_test.dart`
- Modify: `test/widget_test.dart`

- [ ] Add a widget test proving veil opacity decreases while the card is dragged down.
- [ ] Add a widget test proving a keyed drag-exclusion child does not move the parent slide card.
- [ ] Add an app widget test proving FAB double tap opens `budget-target-editor-card` instead of the transaction editor.
- [ ] Add an app widget test proving dragging inside `transaction-category-scroll-list` does not translate `transaction-editor-card`.

### Task 2: Shared Slide Card Behavior

**Files:**
- Modify: `lib/features/transactions/widgets/slide_up_menu_card.dart`

- [ ] Add `dragExclusionKeys` to `SlideUpMenuCard`.
- [ ] On pointer down, ignore card dragging when the global pointer is inside one of those keyed render boxes.
- [ ] Animate veil opacity from entry progress and current drag offset.

### Task 3: Transaction Picker and Panel Heights

**Files:**
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/transactions/widgets/category_scroll_picker.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_editor_sheet.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`

- [ ] Give the transaction category picker a `GlobalKey` and pass it as a slide-card drag exclusion while open.
- [ ] Reduce add transaction, category editor, and budget editor panel heights so their save buttons sit lower, near the bottom-nav zone.

### Task 4: FAB Double Tap Limit Editor

**Files:**
- Modify: `lib/features/shell/widgets/expt_fab.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`

- [ ] Add an `onDoubleTap` callback to the FAB widget.
- [ ] Shell double tap switches to Home and sends an incrementing open-budget-editor signal.
- [ ] Home page opens the overview budget editor when the signal changes.

### Task 5: Verification and Delivery

- [ ] Run focused widget tests.
- [ ] Run full Flutter tests in CI/local if available.
- [ ] Commit, push, and run GitHub Actions build without downloading the artifact.
