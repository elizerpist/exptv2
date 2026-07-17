# Category / Month / Vendor Checkbox Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the category menu selected-card visual language to the summary month selector and vendor selector, and keep the vendor selector visually aligned with the category list.

**Architecture:** Reuse the existing category card visual primitives where possible: `CategoryActiveBorder`, `categoryNeutralShadow`, `ExpenseSurfaceContainer`, and the same card metrics. Keep behavior local to `SummaryScopePickerSheet` and `VendorFilterPanel`; do not change transaction filtering semantics.

**Tech Stack:** Flutter widgets, `flutter_test`, existing `ExpenseSurfaceInteraction` theme primitives.

## Global Constraints

- Do not modify unrelated dirty files in this worktree.
- Run Flutter tests through Ubuntu/proot, not the Termux-host Flutter binary.
- Do not run local APK builds in Termux.
- Use TDD: write failing widget tests before production code.

---

### Task 1: Vendor card parity

**Files:**
- Modify: `test/transactions/category_menu_test.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`

**Interfaces:**
- Consumes: `VendorFilterPanel`, `VendorFilterSummary`
- Produces: vendor cards whose visible card surface, selected marker, and metrics match the category card pattern.

- [x] **Step 1: Write failing tests**
  - Add assertions that a selected vendor card exposes a stable selected marker key and uses the same selected border/pressed design path as category cards.
  - Add assertions that vendor card body metrics align with category card metrics: 150px card height, 18px radius, 65px avatar, top avatar position, category-like title typography.

- [x] **Step 2: Run targeted test and verify RED**
  - Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/transactions/category_menu_test.dart --plain-name "vendor selected card exposes category-style selected marker"'`
  - Expected: FAIL because the selected marker key/widget does not exist yet.

- [x] **Step 3: Implement minimal vendor parity**
  - Update `_VendorFilterRow` to expose category-style selected marker keys and ensure selected-state rendering matches `CategoryCard`.
  - Keep search, rename, reset, amount/count display, and apply behavior unchanged.

- [x] **Step 4: Run targeted vendor tests and verify GREEN**
  - Run the new vendor tests plus existing vendor tests in `test/transactions/category_menu_test.dart`.

### Task 2: Summary month selector parity

**Files:**
- Modify: `test/transactions/transaction_widgets_test.dart`
- Modify: `lib/features/transactions/widgets/summary_scope_picker_sheet.dart`

**Interfaces:**
- Consumes: `SummaryScopePickerSheet`, `_ScopeRow`
- Produces: month row selected/unselected visual state using the category menu selected-card language while preserving scope selection semantics.

- [x] **Step 1: Write failing tests**
  - Add a test that the month row exposes a category-style selected marker when enabled.
  - Add a test that the visual marker disappears when the year is disabled.

- [x] **Step 2: Run targeted test and verify RED**
  - Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_widgets_test.dart --plain-name "summary month row uses category-style selected marker"'`
  - Expected: FAIL because the marker is not present yet.

- [x] **Step 3: Implement minimal month parity**
  - Replace switch-only visual emphasis with an `ExpenseSurfaceContainer`-based card row and `CategoryActiveBorder` marker for enabled state.
  - Preserve the actual `Switch`, +/- controls, drag behavior, and apply semantics.

- [x] **Step 4: Run targeted month tests and verify GREEN**
  - Run the new month tests and existing `summary scope picker toggles year and month with drag`.

### Task 3: Checklist update and verification

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-17-category-month-vendor-checkbox-parity.md`

**Interfaces:**
- Consumes: test output and direct code inspection.
- Produces: checklist statuses updated to `DONE`, `PARTIAL`, or `BLOCKED` honestly.

- [x] **Step 1: Run final targeted verification**
  - Run: `proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test test/transactions/category_menu_test.dart test/transactions/transaction_widgets_test.dart'`

- [x] **Step 2: Inspect changed files**
  - Run: `git diff -- lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/summary_scope_picker_sheet.dart test/transactions/category_menu_test.dart test/transactions/transaction_widgets_test.dart docs/superpowers/checklists/2026-07-17-category-month-vendor-checkbox-parity.md`

- [x] **Step 3: Update checklist statuses**
  - Mark only verified requirements `DONE`.

- [ ] **Step 4: Commit**
  - Commit only files touched for this task, excluding unrelated dirty `color_lab*` files and `test/failures/`.
