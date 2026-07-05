# Orbit Backheader Smoothness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix orbit backheader slider smoothness, ring visibility, header overlap, partition geometry, and swipe preview without changing the existing selection semantics.

**Architecture:** Keep changes in the existing header/backheader widgets. `TransactionHeaderMetrics` owns slide geometry; `BackheaderStyleSurface` owns orbit layout and ring/partition placement; `CategoryBudgetStage` owns drag state, save scheduling, and neighbor preview; `CategoryLimitPartitionBar` gains an orbit-specific square full-width visual mode.

**Tech Stack:** Flutter widgets, existing `flutter_test` widget tests, Ubuntu proot Flutter verification, GitHub Actions debug APK workflow.

## Global Constraints

- Local Flutter tests/analyze must run through Ubuntu proot.
- APK builds must run online through GitHub Actions, not Termux local Flutter build.
- Completion requires checklist rows OB53-OB58 to be `DONE` or explicitly deferred.
- Use TDD: failing widget tests before production edits.
- Keep existing orbit swipe release/selection logic intact.

---

### Task 1: Smooth Partition Slider Saves

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`

**Interfaces:**
- Consumes: `_setOrbitAmountFromPartitionPosition`, `_scheduleOrbitSave`, `_flushOrbitSaves`
- Produces: `_orbitPartitionDragActive` and drag-end save flush behavior

- [ ] **Step 1: Write failing test**

Add a widget test that starts a partition drag, moves several times, verifies the handle moves during drag, verifies `onSaveCategory` is not called before pointer up, then releases and verifies exactly the latest value is saved.

- [ ] **Step 2: Run red test**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_budget_stage_test.dart --plain-name "orbitBudget partition slider defers saves during drag"'
```

Expected: FAIL because current drag updates flush saves immediately.

- [ ] **Step 3: Implement scheduler split**

Set drag-active state on partition drag start/update, queue save requests during drag without flushing, and call `_flushOrbitSaves()` on drag end/cancel. Tap still calls with `flush: true`.

- [ ] **Step 4: Run green test**

Run the same command. Expected: PASS.

### Task 2: Header Slide And Above-Partition Geometry

**Files:**
- Modify: `test/transactions/header_card_test.dart`
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`

**Interfaces:**
- Consumes: `TransactionHeaderMetrics.cardHeight`, `expandedSlideDistance`
- Produces: expanded header bottom fixed at 44 px; orbit top row/actions raised

- [ ] **Step 1: Write failing tests**

Assert `TransactionHeaderMetrics.cardHeight - TransactionHeaderMetrics.expandedSlideDistance == 44`. Assert orbit icon/title/action top positions match the new raised metric and remain above partition.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/header_card_test.dart test/transactions/category_budget_stage_test.dart --plain-name orbitBudget'
```

Expected: FAIL because expanded slide distance is still 132 and top row is still at the old metric.

- [ ] **Step 3: Implement metrics**

Set `expandedSlideDistance` to `144.0` so `188 - 144 == 44`, and keep orbit top row/actions based on `cardHeight - expandedSlideDistance + 10`, which raises them from the current layout.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 3: Ring Visibility And Square Full-Width Partition

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`

**Interfaces:**
- Consumes: `CategoryLimitPartitionBar`
- Produces: orbit ring `Positioned.fill` paint layer and orbit-specific `fullBleedSquare` partition mode

- [ ] **Step 1: Write failing tests**

Assert limited category and overview ring `CustomPaint` has nonzero size and a painter. Assert orbit partition height is `fadeTrackHeight * 0.63`, spans full width, has zero radius, and foreground border top/bottom only.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_budget_stage_test.dart --plain-name orbitBudget'
```

Expected: FAIL because current partition is rounded with full border and ring is not forced to fill.

- [ ] **Step 3: Implement visuals**

Render the ring with `Positioned.fill` and `CustomPaint`. Add `fullBleedSquare` to `CategoryLimitPartitionBar`; in that mode use no radius and `Border(top: ..., bottom: ...)` only. Pass this mode from orbit partition rendering.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 4: Neighbor Preview During Swipe

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`

**Interfaces:**
- Consumes: `_dragDx`, `_settleDrag`, `_snapToNext`
- Produces: `backheader-orbit-preview-next` and `backheader-orbit-preview-previous`

- [ ] **Step 1: Write failing test**

Start a horizontal drag on orbitBudget. While dragging left, assert `backheader-orbit-preview-next` is visible and current selection has not changed yet. Release beyond threshold and assert existing switch behavior still selects the next item.

- [ ] **Step 2: Run red test**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_budget_stage_test.dart --plain-name "orbitBudget shows neighboring card preview while swiping"'
```

Expected: FAIL because only the current card is translated.

- [ ] **Step 3: Implement preview stack**

In orbitBudget experimental stage, render current, previous, and next `BackheaderStyleSurface` instances in a `LayoutBuilder` stack. Translate previews by one screen width plus `_dragDx`, wrap previews in `IgnorePointer`, and keep `_settleDrag` unchanged.

- [ ] **Step 4: Run green test**

Run the same command. Expected: PASS.

### Task 5: Verification, Commit, Push, APK

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md`

- [ ] **Step 1: Mark checklist rows**

Mark OB53-OB58 `DONE` only after tests or direct inspection verify each row.

- [ ] **Step 2: Verify**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/header_card_test.dart test/transactions/header_layout_test.dart test/transactions/magnet_strip_test.dart test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart test/widget_test.dart'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze --no-pub'
git diff --check
```

Expected: all commands exit 0.

- [ ] **Step 3: Commit, push, online build, download APK**

Commit on `integrated-latest`, push, watch GitHub Actions, download `exptv2-debug-<shortsha>.apk` to `/storage/emulated/0/Download/exptv2`, and verify SHA256 matches the GitHub release digest.
