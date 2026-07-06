# Center Badge Backheader Partition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the new selectable center-badge budget backheader layout, centralize partition progress coloring, add a new selectable partitioned magnet strip, and deliver a GitHub-built debug APK into `/storage/emulated/0/Download/exptv2`.

**Architecture:** `LimitAllocationManager` becomes the single source for budget partition segments, including limit-free spending segments. `CategoryBudgetStage` owns gestures and pending budget values; `BackheaderStyleSurface` owns the new center-badge visual layout; `MagnetStrip` consumes the shared allocation for the new partitioned magnet mode.

**Tech Stack:** Flutter/Dart widget and unit tests; existing settings/store models; local verification through Ubuntu proot only; Android APK build through GitHub Actions.

## Global Constraints

- Work on the current branch only; do not create an isolated worktree.
- Do not run local Android APK builds in Termux.
- Run `flutter test` and `flutter analyze` through Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`.
- Preserve existing backheader and magnet options unless the requested partition/circle bugs require shared fixes.
- Keep the user checklist at `docs/superpowers/checklists/2026-07-06-center-badge-backheader-partition-checklist.md` current.

---

### Task 1: Central Partition Allocation

**Files:**
- Modify: `lib/features/transactions/models/limit_allocation_data.dart`
- Modify: `lib/features/transactions/data/limit_allocation_manager.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`
- Test: `test/transactions/limit_allocation_manager_test.dart`

**Interfaces:**
- Produces: `LimitAllocationSegmentKind.unlimitedUsed`.
- Produces: `LimitAllocationManager.build({required double overviewLimit, required List<CategoryBudgetBarData> bars})`.
- Consumes: `CategoryBudgetBarData.spent`, `hasLimit`, `limitAmount`, `color`, `targetId`, `title`.

- [ ] **Step 1: Write failing partition example test**

```dart
test('allocation includes unlimited spending after limited reserved segments', () {
  final green = barFixture(6, 'Green', spent: 250, limit: 500);
  final pink = barFixture(8, 'Pink', spent: 300, limit: 0);

  final data = LimitAllocationManager.build(
    overviewLimit: 1000,
    bars: [green, pink],
  );

  expect(data.segments.map((segment) => segment.kind.name), [
    'used',
    'remaining',
    'unlimitedUsed',
    'free',
  ]);
  expect(data.segments.map((segment) => segment.amount), [250, 250, 300, 200]);
  expect(data.segments.map((segment) => segment.fraction), [
    0.25,
    0.25,
    0.30,
    0.20,
  ]);
});
```

- [ ] **Step 2: Run RED**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/limit_allocation_manager_test.dart'
```

Expected: FAIL because `unlimitedUsed` is missing or the pink segment is omitted.

- [ ] **Step 3: Implement shared allocation**

Add `unlimitedUsed` and make `build()` include:
- limited bars as `used` plus low-opacity `remaining`;
- no-limit bars with `spent > 0` as full-color `unlimitedUsed`;
- `free` as `overviewLimit - limited allocations - unlimited used`, clamped at `0`.

- [ ] **Step 4: Remove active duplicate budget math**

Make `CategoryLimitPartitionBar` render via `allocation` for budget-aware paths; keep legacy no-overview partition fallback only for existing callers without overview context.

- [ ] **Step 5: Run GREEN**

Run the same test command and expect PASS.

### Task 2: New Settings Values

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Modify: `lib/features/settings/widgets/options/backheader_style_options_panel.dart`
- Modify: `lib/features/settings/widgets/options/backheader_style_preview.dart`
- Modify: `lib/features/settings/widgets/options/theme_options_panel.dart`
- Modify: `lib/features/transactions/widgets/header_card/magnet_strip.dart`
- Test: `test/settings/backheader_style_options_panel_test.dart`
- Test: `test/transactions/magnet_strip_test.dart`

**Interfaces:**
- Produces: new `BackheaderStyle` value for the center badge layout.
- Produces: new `MagnetType` value for the partitioned magnet strip.

- [ ] **Step 1: Write failing settings tests**

Add expectations that the backheader panel lists the new center-badge layout and the theme panel lists a separate partitioned magnet option while keeping `MagnetType.budget`.

- [ ] **Step 2: Run RED targeted tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/settings/backheader_style_options_panel_test.dart test/transactions/magnet_strip_test.dart'
```

- [ ] **Step 3: Add enum values and previews**

Add display title/description, previews, and non-breaking `fromAny` behavior.

- [ ] **Step 4: Run GREEN targeted tests**

Run the same targeted test command and expect PASS.

### Task 3: Partitioned Magnet Strip

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/magnet_strip.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/magnet_strip_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

**Interfaces:**
- Consumes: shared `LimitAllocationData`.
- Produces: `MagnetStrip(type: MagnetType.partitionedBudget, budgetAllocation: allocation)`.

- [ ] **Step 1: Write failing magnet strip test**

Assert the new magnet type renders a full-width original-height track with multiple allocation segment keys, no border, and no small variant.

- [ ] **Step 2: Run RED**

Run `flutter test --no-pub test/transactions/magnet_strip_test.dart` through proot.

- [ ] **Step 3: Implement painter/widget**

Render allocation segments inside the same `visualTrackHeight` and rounded track shape used by the original magnet strip.

- [ ] **Step 4: Wire transaction home data**

Build allocation from the active expense overview limit and `categoryBudgetBars`, pass it to `TransactionHeaderCard`, then to `MagnetStrip`.

- [ ] **Step 5: Run GREEN**

Run magnet and transaction home targeted tests through proot.

### Task 4: Center Badge Backheader Layout

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

**Interfaces:**
- Consumes: effective pending limit amount, ring progress, ring color, reset/max action widgets, handle callbacks, and carousel callbacks from `CategoryBudgetStage`.
- Produces: centered limit-budget badge, top-left amount row, bottom-right actions, down-expand remaining amount, and neighbor preview rail.

- [ ] **Step 1: Write failing layout tests**

Assert the new style renders:
- top-left spent/limit amount with bar-system number sizing/color;
- app background color;
- centered limit-budget badge button;
- visible circle progress ring;
- no partition bar in backheader;
- bottom-right reset and max buttons;
- previous/next preview badges.

- [ ] **Step 2: Run RED**

Run `flutter test --no-pub test/transactions/category_budget_stage_test.dart` through proot.

- [ ] **Step 3: Implement visual surface**

Add a new surface branch in `BackheaderStyleSurface` for the center badge layout.

- [ ] **Step 4: Implement stage wiring**

Pass action widgets, progress values, and callbacks from `CategoryBudgetStage`; keep tap opening `BudgetTargetEditorSheet`.

- [ ] **Step 5: Run GREEN layout tests**

Run the same category stage test through proot.

### Task 5: Joystick, Expand-Close, And Carousel Gestures

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Consider create: `lib/features/transactions/widgets/header_card/budget_joystick_range.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

**Interfaces:**
- Consumes: stats joystick behavior from `calendar_value_slider_panel.dart` and `calendar_joystick_range.dart`.
- Produces: badge long-press/swipe up/down tick adjustment with live ring updates and debounced saves.

- [ ] **Step 1: Write failing gesture tests**

Assert:
- swipe/long-press upward on badge increases effective limit;
- downward decreases it;
- ring progress updates before save completes;
- handle down overpull reveals remaining amount and requests close;
- tapping neighbor preview selects it;
- fast horizontal swipe can skip more than one item.

- [ ] **Step 2: Run RED**

Run category stage targeted tests through proot.

- [ ] **Step 3: Implement joystick state**

Use the same dead zone, tick interval, and distance speed bands as the calendar joystick.

- [ ] **Step 4: Implement expand-close and carousel settling**

Reuse existing orbit handle close thresholds where appropriate; add velocity/distance based multi-step settling for the new layout.

- [ ] **Step 5: Run GREEN**

Run category stage targeted tests through proot.

### Task 6: Sheet Lag And Regression Verification

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Test: `test/transactions/category_budget_stage_test.dart`
- Test: any existing sheet test if present

**Interfaces:**
- Consumes: shared allocation and pending amount state.
- Produces: partition bar and handle movement in the same frame as slider/input changes.

- [ ] **Step 1: Write failing sheet update test**

Assert slider movement changes the partition handle/segment position after one `pump()`.

- [ ] **Step 2: Run RED**

Run targeted tests through proot.

- [ ] **Step 3: Fix state update path**

Ensure `_setControllerAmount` and slider changes rebuild the allocation and handle without delayed controller sync.

- [ ] **Step 4: Run GREEN**

Run targeted tests through proot.

### Task 7: Final Verification, Commit, Push, APK Download

**Files:**
- Modify: checklist statuses.

**Interfaces:**
- Produces: pushed branch and debug APK in `/storage/emulated/0/Download/exptv2`.

- [ ] **Step 1: Run analyzer**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze --no-pub'
```

- [ ] **Step 2: Run targeted tests**

Run all changed targeted tests through proot.

- [ ] **Step 3: Update checklist statuses**

Mark each implemented acceptance item `DONE`; leave any unimplemented item explicit.

- [ ] **Step 4: Commit and push branch**

```bash
git add lib test docs/superpowers/checklists/2026-07-06-center-badge-backheader-partition-checklist.md docs/superpowers/plans/2026-07-06-center-badge-backheader-partition-plan.md
git commit -m "feat: add center badge budget backheader"
git push -u origin feature/center-badge-backheader-partition
```

- [ ] **Step 5: Download debug APK artifact**

Use the repository's GitHub Actions workflow/artifact tooling after the online build completes, then place the APK under:

```bash
mkdir -p /storage/emulated/0/Download/exptv2
```

Final verification lists the downloaded APK path.
