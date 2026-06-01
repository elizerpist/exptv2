# Transaction Picker Backheader Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep add-transaction controls anchored while category pickers expand upward, refine backheader budget frame visuals, restore backheader header-content hiding, and make recurring category selection interactive.

**Architecture:** Keep `SlideUpMenuCard` as the common modal primitive. Split the add transaction sheet into an upper expandable selector area and a bottom anchored save/date area. Keep backheader progress rendering in `BudgetProgressFrame` and `CategoryBudgetStage`, and reuse `CategorySelectorField` plus `CategoryScrollPicker` for recurring options.

**Tech Stack:** Flutter widgets, existing widget tests, GitHub Actions Android workflow.

---

### Task 1: Regression Tests

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `test/settings/settings_page_test.dart`
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `test/transactions/transaction_home_limits_test.dart`

- [ ] Add widget coverage proving AddTransaction save/date controls keep the same screen position when the category picker opens and the card expands upward.
- [ ] Add coverage that AddTransaction uses a faster slide entry duration.
- [ ] Update recurring settings coverage so the category list is hidden initially, opens from a selector tap, and closes after selection.
- [ ] Add backheader coverage for no default white border, warning-only border, and a grey same-size mask over the progress frame.
- [ ] Update limit editor coverage so header content remains hidden when the backheader is active.

### Task 2: AddTransaction Layout and Entry Timing

**Files:**
- Modify: `lib/features/transactions/widgets/slide_up_menu_card.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`

- [ ] Add an optional `entryDuration` to `SlideUpMenuCard` while preserving the default duration for other sheets.
- [ ] Pass a shorter duration from Add/EditTransaction.
- [ ] Split AddTransaction layout into an upper bottom-aligned expandable picker area and a fixed bottom controls area.
- [ ] Add a stable key to the transaction save button for tests.

### Task 3: Backheader Progress Visuals

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/budget_bar_geometry.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_progress_frame.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`

- [ ] Center a progress frame that is 10% larger than the limit bars.
- [ ] Remove the default white border and render a border only for expense warning/danger states.
- [ ] Add a grey mask bar with the same size and position as the visible budget/category bar above the progress frame.

### Task 4: Limit Editor and Recurring Picker

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Modify: `lib/features/settings/widgets/options/recurring_options_panel.dart`
- Modify: `lib/features/transactions/widgets/category_selector_field.dart`

- [ ] Hide header-card content whenever the backheader is active, including while the limit editor is open.
- [ ] Raise the limit editor panel height slightly.
- [ ] Make recurring category selection use a closed selector plus interactive scroll picker.
- [ ] Allow `CategorySelectorField` to use a custom key so recurring tests and transaction tests stay distinct.

### Task 5: Verification and Delivery

- [ ] Run local diff checks.
- [ ] Commit and push to `feature/backheader-budget-goals`.
- [ ] Run `android-build.yml` through GitHub Actions and confirm analyze, tests, APK build, and upload pass without downloading the artifact.
