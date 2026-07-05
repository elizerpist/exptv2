# Orbit Backheader Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the compact orbit backheader and header card spacing to match the latest screenshot and user feedback.

**Architecture:** Keep the change inside the existing header/backheader system. Shared geometry remains in `TransactionHeaderMetrics`; `BackheaderStyleSurface` positions the orbit content; `CategoryBudgetStage` owns editable amount state, partition-slider gestures, save scheduling, and action widgets; `CategoryLimitPartitionBar` owns partition visual styling.

**Tech Stack:** Flutter widgets, existing `flutter_test` widget tests, existing GitHub Actions debug APK workflow.

## Global Constraints

- Local Flutter tests and analysis must run through Ubuntu proot.
- APK builds must run online through GitHub Actions, not Termux local Flutter build.
- Completion requires checklist rows OB42-OB52 to be `DONE` or explicitly deferred.
- Use TDD: add or update failing widget tests before production edits.
- Preserve classic and heroToken backheader behavior.

---

### Task 1: Header And Backheader Height Metrics

**Files:**
- Modify: `test/transactions/header_card_test.dart`
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`

**Interfaces:**
- Consumes: `TransactionHeaderMetrics.cardHeight`, `TransactionHeaderMetrics.contentTop`, `TransactionMenuMetrics.typePillTopPadding`, `TransactionMenuMetrics.typePillBottomPadding`
- Produces: new shared header/backheader height of 188 px while existing content top metrics remain unchanged

- [ ] **Step 1: Write failing tests**

Add metric assertions that `cardHeight` is 188 and:

```dart
expect(
  TransactionHeaderMetrics.contentTop +
      TransactionMenuMetrics.typePillTopPadding -
      TransactionHeaderMetrics.cardHeight,
  TransactionMenuMetrics.typePillBottomPadding,
);
```

Add an orbitBudget stage assertion that its height equals `TransactionHeaderMetrics.cardHeight`.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/header_card_test.dart test/transactions/category_budget_stage_test.dart --plain-name orbitBudget'
```

Expected: FAIL because `cardHeight` is still 176.

- [ ] **Step 3: Implement metric change**

Set `TransactionHeaderMetrics.cardHeight` to `188.0`. Do not change title/chip/magnet/balance/category top metrics.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS for the updated metric tests after all related layout edits are complete.

### Task 2: Thinner Partition Slider And Matched Border Stroke

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`

**Interfaces:**
- Consumes: `MagnetStripPainter.visualTrackHeight(MagnetType.fade, TransactionHeaderMetrics.magnetHeight)`
- Produces: orbit partition height at 70% of the previous fade visual track height, top unchanged, border width 1.6 px

- [ ] **Step 1: Write failing tests**

Add assertions that `CategoryLimitPartitionBar.borderWidth == 1.6`, `OrbitProgressRingPainter.strokeWidth == 1.6`, partition top still matches the old top formula, and partition height is `oldTrackHeight * 0.7`.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_budget_stage_test.dart --plain-name orbitBudget'
```

Expected: FAIL because the border is 2.5 and the partition height is still full fade track height.

- [ ] **Step 3: Implement visual constants**

Expose `CategoryLimitPartitionBar.borderWidth`, reuse the same `1.6` value as the orbit ring stroke, and set `_orbitPartitionHeight` to `fadeTrackHeight * 0.7`. Keep the `Positioned.top` for the partition unchanged.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 3: X-Pill/Y-Text Inline Amount Editor

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`

**Interfaces:**
- Consumes: `_orbitAmountController`, `_handleOrbitAmountInputChanged`, `_orbitEffectiveAmountFor`, `_orbitSpentTextFor`
- Produces: `backheader-orbit-limit-pill`, `backheader-orbit-amount-input`, `backheader-orbit-amount-slash`, `backheader-orbit-spent-text`

- [ ] **Step 1: Write failing tests**

For category, overview, and no-limit category, assert the amount row renders `x pill / y text`, only the x pill contains the `TextField`, no full-row white textbox exists, no-limit x displays `n/a`, and the text style/cursor are white with 16.8 px font.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_budget_stage_test.dart --plain-name orbitBudget'
```

Expected: FAIL because the current amount row is prefix text plus fixed-width input or an oversized empty pill.

- [ ] **Step 3: Implement editor row**

Render the editable x value as an adaptive translucent pill with a transparent `TextField`; render slash and y spent/current amount as plain text outside the pill. Use `n/a` as the controller display for no-limit when not focused, but save numeric edits normally.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 4: Top-Right Actions And Partition Slider Handle

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`

**Interfaces:**
- Consumes: `_orbitSliderRangeFor`, `_setOrbitAmountFromPartitionPosition`, `_buildOrbitActions`
- Produces: top-right `limit-reset-inline-button`, optional top-right `backheader-orbit-max-button`, visible `backheader-orbit-partition-handle`

- [ ] **Step 1: Write failing tests**

Assert action buttons sit above the partition near the right edge. Assert `backheader-orbit-partition-handle` exists, starts at the active x-limit ratio, and moves after dragging the partition bar.

- [ ] **Step 2: Run red tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_budget_stage_test.dart --plain-name orbitBudget'
```

Expected: FAIL because actions are bottom-right and there is no partition slider handle.

- [ ] **Step 3: Implement positions and handle overlay**

Move `actions` to `Positioned(top: topRowTop, right: 24)`. Wrap the partition bar in a `Stack` and overlay a white handle at `(currentAmount / range.max).clamp(0, 1)`.

- [ ] **Step 4: Run green tests**

Run the same command. Expected: PASS.

### Task 5: Checklist, Verification, Commit, Push, APK

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md`

- [ ] **Step 1: Update checklist statuses**

Mark OB42-OB52 `DONE` only after tests or direct inspection verify each row.

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
