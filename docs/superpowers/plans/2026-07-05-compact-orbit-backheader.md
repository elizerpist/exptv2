# Compact Orbit Backheader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the expanded orbitBudget editor with a compact backheader whose white handle closes by overpull, whose partition bar doubles as the slider, and whose amount text edits limits directly.

**Architecture:** Keep the change scoped to the existing header/backheader widgets. `TransactionHeaderCard` owns the trigger chip and header magnet surface; `CategoryBudgetStage` owns orbitBudget state, save scheduling, amount editing, bar-as-slider gestures, and close requests; `BackheaderStyleSurface` renders the compact orbit layout.

**Tech Stack:** Flutter widgets, existing `flutter_test` widget tests, existing `CategoryLimitPartitionBar`, existing save callbacks on `CategoryBudgetStage`.

## Global Constraints

- Local Flutter analysis/tests must run through Ubuntu proot.
- APK builds must run online through GitHub Actions, not Termux local Flutter build.
- Completion requires every checklist row OB28-OB41 to be `DONE` or explicitly deferred.
- Use TDD: add failing widget tests before production edits.
- Preserve classic and heroToken backheader behavior.

---

### Task 1: Header Trigger And Magnet Affordances

**Files:**
- Modify: `test/transactions/header_card_test.dart`
- Modify: `test/transactions/header_layout_test.dart`
- Modify: `test/transactions/magnet_strip_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/widgets/header_card/magnet_strip.dart`

**Interfaces:**
- Consumes: `TransactionHeaderCard.onExpandPressed`
- Produces: `header-budget-trigger-chip` with yellow background, no `header-card-drag-handle`

- [ ] **Step 1: Write failing tests**

Add assertions that `header-card-drag-handle` is absent, the budget trigger chip decoration color is `Color(0xFFFBBF24)`, and non-fade magnet variants expose the same visible track/slab height as fade via testable geometry.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/header_card_test.dart test/transactions/magnet_strip_test.dart'
```

Expected: FAIL because the dark handle still exists and the chip is accent-colored.

- [ ] **Step 3: Implement header and magnet changes**

Remove the `header-card-drag-handle` overlay and `dragHandleHitTestEnabled` API, set trigger chip color to `const Color(0xFFFBBF24)`, and normalize non-fade magnet visual heights to the fade visual track height.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 2: Compact Orbit Layout Without Expanded Editor

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `test/transactions/transaction_home_limits_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`

**Interfaces:**
- Consumes: `BackheaderBudgetItem`, `onSaveOverview`, `onSaveCategory`, `onJumpToIncome`
- Produces: compact orbitBudget layout keys `backheader-orbit-handle`, `backheader-orbit-amount-input`, `backheader-orbit-max-button`, `limit-reset-inline-button`

- [ ] **Step 1: Write failing tests**

Replace expanded-editor expectations with compact expectations: no `backheader-orbit-inline-editor`, no `backheader-orbit-slider`, no `backheader-overview-jump-button`; one white handle remains; stage height stays normal; amount is below partition bar with header-balance font size; reset and max controls are bottom-right.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_budget_stage_test.dart --plain-name orbitBudget'
```

Expected: FAIL because the expanded editor and separate slider still render.

- [ ] **Step 3: Implement compact orbit layout**

Remove `_orbitExpanded` and `_orbitExpansion` as persistent editor state, remove `_buildOrbitInlineEditor`, and render the compact layout directly in `_OrbitBudget`.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 3: Partition Bar As Slider And Inline Amount Editing

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`

**Interfaces:**
- Consumes: existing `_setOrbitAmount`, `_orbitSliderRangeFor`, `_orbitAmountController`
- Produces: draggable `category-limit-partition-bar`, editable `backheader-orbit-amount-input`

- [ ] **Step 1: Write failing tests**

Add tests that dragging `category-limit-partition-bar` changes/saves the active limit, tapping the lower amount enters edit mode, entering category and overview limits saves immediately, and unlimited category shows an empty editable lower-left pill.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_budget_stage_test.dart --plain-name orbitBudget'
```

Expected: FAIL because the bar is not yet a slider and the amount text is not editable.

- [ ] **Step 3: Implement bar slider and amount input**

Wrap the orbit partition bar with a horizontal drag/tap handler that maps local x to `LimitSliderRange.max`, and render the x/y limit area as a compact `TextField`/editable pill bound to `_orbitAmountController`.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 4: Slide-Tick-Close And Home Integration

**Files:**
- Modify: `test/transactions/header_layout_test.dart`
- Modify: `test/transactions/transaction_home_limits_test.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`

**Interfaces:**
- Consumes: existing `TransactionHomePage._toggleHeaderExpanded` and header slide state
- Produces: `CategoryBudgetStage.onOrbitCloseRequested`

- [ ] **Step 1: Write failing tests**

Add tests that a short downward handle pull snaps back, trigger 1 remains open at compact height, trigger 2 calls close and the home header card returns to collapsed slide position; diagonal/horizontal gestures do not close.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/header_layout_test.dart test/transactions/transaction_home_limits_test.dart --plain-name orbit'
```

Expected: FAIL because close is still tied to expanded-editor overpull behavior.

- [ ] **Step 3: Implement close request wiring**

Add `onOrbitCloseRequested` to `CategoryBudgetStage`, wire it from `TransactionHomePage` to collapse the header, and make the white handle support only compact overpull close thresholds.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 5: Checklist, Verification, Commit, Push, APK

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md`

- [ ] **Step 1: Update checklist statuses**

Mark OB28-OB41 `DONE` only after matching tests or direct inspection verify each row.

- [ ] **Step 2: Format and verify**

Run:

```bash
dart format lib/features/transactions/widgets/header_card/transaction_header_card.dart lib/features/transactions/widgets/header_card/magnet_strip.dart lib/features/transactions/widgets/header_card/backheader_style_surface.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart test/transactions/header_card_test.dart test/transactions/header_layout_test.dart test/transactions/magnet_strip_test.dart test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/header_card_test.dart test/transactions/header_layout_test.dart test/transactions/magnet_strip_test.dart test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart test/widget_test.dart'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze --no-pub'
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 3: Commit, push, online build, download APK**

Commit on `integrated-latest`, push, watch GitHub Actions, download `exptv2-debug-<shortsha>.apk` to `/storage/emulated/0/Download/exptv2`, and verify SHA256 matches the GitHub release digest.
