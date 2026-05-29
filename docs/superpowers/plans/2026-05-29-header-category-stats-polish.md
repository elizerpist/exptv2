# Header Category Stats Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the approved exptv2 polish pass for header pull behavior, category modal behavior, transaction date/time picking, logbox swipes, always-visible FAB, and Stats calendar layout.

**Architecture:** Keep the changes inside the existing Flutter transaction shell and widget boundaries. Transaction state remains owned by `TransactionStore`; UI components receive explicit callbacks and values so category color/type/menu changes refresh through normal rebuilds.

**Tech Stack:** Flutter/Dart, existing widget tests, GitHub Actions for online analyze/test/build verification because the local Termux Flutter runtime is currently blocked by Dart TLS alignment.

---

### Task 1: Header Card Pull, Shadow, Magnet, And Balance Toggle

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`
- Modify: `lib/features/transactions/widgets/header_card/magnet_strip.dart`
- Test: `test/transactions/header_layout_test.dart`
- Test: `test/transactions/magnet_strip_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests that expect the header shadow to stay non-zero while pulled, the balance visibility button to hide/show the amount, and the magnet strip default height to be `105`.

- [ ] **Step 2: Verify red**

Run the targeted tests through GitHub Actions or the available Flutter runtime. Expected failures: shadow opacity still goes to zero, balance visibility does not toggle, and magnet height remains `70`.

- [ ] **Step 3: Implement**

Use an unbounded pull animation controller in `TransactionHomePage` and spring it back to zero on drag release. Keep header card shadow fixed. Store `_balanceHidden` in `TransactionHomePage`, pass it to `TransactionHeaderCard`, and wire the eye button callback. Increase magnet height by 50% and render slab-like rectangular magnet strips instead of pill ends.

- [ ] **Step 4: Verify green**

Run the targeted header and magnet tests. Expected: pass.

### Task 2: Summary Pill And Logbox Swipe Behavior

**Files:**
- Modify: `lib/features/transactions/widgets/summary_pill.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Test: `test/transactions/transaction_widgets_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing tests**

Add widget tests that verify SummaryPill value/title replacement is immediate with no `AnimatedSwitcher`, and that right-swipe delete keeps the logbox offset while the confirm dialog is open, then resets only on cancel.

- [ ] **Step 2: Verify red**

Run the transaction widget tests. Expected failures: `AnimatedSwitcher` is still present and the row resets before the delete dialog decision.

- [ ] **Step 3: Implement**

Replace the SummaryPill animated content switch with direct text content. Change delete callbacks to return `FutureOr<bool>` where `true` means confirmed/deleted and `false` means canceled. Freeze `_visualDx` while the dialog is pending, reset only for cancel, and keep the swipe border constrained to the exact logbox bounds.

- [ ] **Step 4: Verify green**

Run the transaction widget tests. Expected: pass.

### Task 3: Category Menu Inline Modal And Type Switching

**Files:**
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/header_layout_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests that category menu stays open when switching Bevétel/Kiadás, its content updates immediately, it is not a draggable slide-up sheet, and shell navigation/FAB remain visible above it.

- [ ] **Step 2: Verify red**

Run the category/menu tests. Expected failures: active type switching closes the menu and the shell navigation is hidden.

- [ ] **Step 3: Implement**

Replace `SlideUpMenuCard` in the category overlay with a fixed inline `Material` panel from the existing top to `AppDimensions.bottomNavHeight`. Move header add/back controls to the modal edges. Stop treating the category picker as a blocking overlay, and keep `_categoryMode` open across active type changes.

- [ ] **Step 4: Verify green**

Run the category/menu tests. Expected: pass.

### Task 4: Add Transaction Date And Time Pickers

**Files:**
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/transactions/widgets/date_time_fields.dart`
- Test: `test/transactions/transaction_widgets_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests that date and time fields still accept manual text and that tapping the suffix icons opens `DatePickerDialog` and `TimePickerDialog`.

- [ ] **Step 2: Verify red**

Run transaction widget tests. Expected failures: no picker icon callbacks/dialogs exist.

- [ ] **Step 3: Implement**

Add suffix icon buttons to both fields. Use `showDatePicker` and `showTimePicker`, initialize from the current manual value when parsable, and write selected values back as `yyyy-MM-dd` and `HH:mm`.

- [ ] **Step 4: Verify green**

Run transaction widget tests. Expected: pass.

### Task 5: Always Visible FAB And Global Add Sheet

**Files:**
- Modify: `lib/features/shell/expt_shell.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing tests**

Update shell tests to expect the FAB on every bottom-nav tab and verify tapping it opens the add transaction sheet even outside the Home tab.

- [ ] **Step 2: Verify red**

Run shell widget tests. Expected failure: FAB is missing on non-home tabs.

- [ ] **Step 3: Implement**

Remove the active-tab guard from FAB rendering and press handling. Render the add transaction overlay at shell level so it can open over any tab.

- [ ] **Step 4: Verify green**

Run shell widget tests. Expected: pass.

### Task 6: Stats Calendar Layout

**Files:**
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests that Stats menu order is summary label, year, mode switcher; all calendar modes reserve the same month-name gap as summary mode; and dominant-category mode no longer renders a pie chart.

- [ ] **Step 2: Verify red**

Run calendar widget tests. Expected failures: order is year/switch/title, category mode includes the pie chart, and non-summary mode uses tighter month spacing.

- [ ] **Step 3: Implement**

Reorder the overlay header, remove `CategoryDonutChart`, and reuse summary mode offsets for weekday/grid drawing in every calendar mode.

- [ ] **Step 4: Verify green**

Run calendar widget tests. Expected: pass.

### Task 7: Full Verification And Push

**Files:**
- Review: `git diff`
- Verify: GitHub Actions run on `main`

- [ ] **Step 1: Run local static/test command if available**

Run the existing Flutter test command if the runtime works. Expected in this environment may be blocked by the known Dart TLS alignment error.

- [ ] **Step 2: Commit and push**

Commit the completed work with a concise message and push `main` to `origin`.

- [ ] **Step 3: Monitor online build**

Use `gh run list` / `gh run watch` for the pushed commit. Expected: analyze, tests, debug APK build, and artifact upload pass online.

---

## Self-Review

- Spec coverage: every approved user requirement is mapped to Tasks 1-6, with push/build monitoring in Task 7.
- Placeholder scan: no TBD/TODO/fill-in placeholders remain.
- Type consistency: delete callback uses `FutureOr<bool>` consistently from shell through logbox.
