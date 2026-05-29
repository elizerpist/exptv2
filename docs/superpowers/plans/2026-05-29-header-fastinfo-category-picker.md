# Header FastInfo Category Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the pulled header and FastInfo read as one component, add FAB long-press category creation, reuse the category menu as the add/edit transaction category picker, align category menu header controls to the edges, and animate backheader category-bar swipes.

**Architecture:** Keep state ownership in `TransactionStore` and the existing shell/home widgets. Add only small widget parameters and one focused header surface widget so visual ownership is clearer without rewriting the transaction page.

**Tech Stack:** Flutter/Dart, existing widget tests, GitHub Actions for authoritative analyze/test/build verification because local Termux Flutter is blocked by the Dart TLS alignment error.

---

### Task 1: Shared Header FastInfo Surface

**Files:**
- Create: `lib/features/transactions/widgets/header_card/header_fast_info_surface.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Test: `test/transactions/header_layout_test.dart`

- [ ] **Step 1: Write failing widget expectations**

Add header layout assertions that max-pulled FastInfo and the header card are under one `header-fast-info-surface` key, that `fast-info-panel` is still present, and that `transaction-header-card` no longer owns the outer surface when embedded.

- [ ] **Step 2: Run red verification**

Run: `flutter test test/transactions/header_layout_test.dart`
Expected locally in this Termux environment: blocked by the known Dart TLS alignment error. Expected in GitHub Actions before implementation: missing `header-fast-info-surface`.

- [ ] **Step 3: Implement the shared surface**

Create `HeaderFastInfoSurface` as the single visual parent. It should draw the card color, bottom radius, and shadow once, position `FastInfoPanel` in the upper section, and position `TransactionHeaderCard` in the lower section with its background disabled.

Use this interface:

```dart
class HeaderFastInfoSurface extends StatelessWidget {
  const HeaderFastInfoSurface({
    super.key,
    required this.visibleFastInfoExtent,
    required this.fastInfo,
    required this.header,
    required this.cardColor,
  });

  final double visibleFastInfoExtent;
  final Widget fastInfo;
  final Widget header;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    final extent = visibleFastInfoExtent
        .clamp(0.0, TransactionHeaderMetrics.fastInfoHeight)
        .toDouble();
    return Positioned(
      top: -TransactionHeaderMetrics.fastInfoHeight + extent,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: extent == 0,
        child: Opacity(
          opacity: (extent / TransactionHeaderMetrics.fastInfoHeight)
              .clamp(0.0, 1.0),
          child: DecoratedBox(
            key: const ValueKey('header-fast-info-surface'),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SizedBox(
              height: TransactionHeaderMetrics.fastInfoHeight +
                  TransactionHeaderMetrics.cardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: fastInfo,
                  ),
                  Positioned(
                    top: TransactionHeaderMetrics.fastInfoHeight,
                    left: 0,
                    right: 0,
                    child: header,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Update `TransactionHeaderCard` with a `drawSurface` bool defaulting to `true`. When `false`, skip the `DecoratedBox` that paints the card background/shadow. Replace the separate FastInfo `Positioned` and translated header in `TransactionHomePage` with normal header rendering at rest and the shared surface while pulled.

Move FastInfo content lower by changing the pill top from `33` to around `54` and the box top from `179` to around `202`, keeping the existing element sizes.

- [ ] **Step 4: Verify green**

Run the header layout test in CI. Expected: `header-fast-info-surface` exists during pull, FastInfo is lower, and no duplicate card surface creates a visible seam.

### Task 2: FAB Long Press Opens New Category

**Files:**
- Modify: `lib/features/shell/widgets/expt_fab.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing test**

Add a shell widget test that long-presses `find.byKey(const ValueKey('expt-fab'))` and expects a category editor sheet/new-category UI, while a normal tap still opens `transaction-editor-card`.

- [ ] **Step 2: Run red verification**

Run: `flutter test test/widget_test.dart`
Expected before implementation: long press has no effect.

- [ ] **Step 3: Implement FAB long press callback**

Change `ExptFab` to accept `onLongPress`:

```dart
const ExptFab({
  super.key,
  required this.onPressed,
  this.onLongPress,
});

final VoidCallback onPressed;
final VoidCallback? onLongPress;
```

Pass it to `InkResponse(onLongPress: onLongPress)`. In `ExptShell`, add shell state for category editor visibility and render `CategoryEditorSheet` above the app using `_transactionStore.activeType`. Normal FAB tap keeps opening `AddTransactionSheet`; long press closes transaction editing and opens the category editor.

- [ ] **Step 4: Verify green**

Expected: FAB is visible on every tab, normal tap opens add transaction, long press opens new category editor.

### Task 3: Category Menu Picker Inside Add/Edit Transaction

**Files:**
- Modify: `lib/features/transactions/widgets/category_selector_field.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
- Test: `test/transactions/transaction_widgets_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests that tapping the transaction category field opens `category-menu-overlay`, selecting a category updates the form, and the add/edit transaction sheet remains open. Add a test that the category menu header back and plus buttons are aligned to the modal edges by their explicit `40x54` constraints and zero padding.

- [ ] **Step 2: Run red verification**

Run: `flutter test test/transactions/transaction_widgets_test.dart`
Expected before implementation: the field is a `DropdownButtonFormField` and no category overlay opens from the sheet.

- [ ] **Step 3: Implement tappable selector and picker overlay**

Replace `CategorySelectorField` dropdown internals with an `InkWell`/`InputDecorator` field that receives `onTap` and displays the selected category swatch/name plus a right chevron.

Inside `AddTransactionSheet`, add `_categoryPickerOpen`, `_categoryEditorOpen`, and `_editingCategory` state. When the field is tapped, show `CategoryMenuOverlay` in the sheet stack. For picker mode, `onSelect` sets `_category = category` and closes only the picker overlay. Do not call `store.setCategoryFilter` from the transaction sheet.

Support category add/edit/delete from the picker by opening `CategoryEditorSheet` inside the transaction sheet and saving through `widget.store.addCategory`, `widget.store.updateCategory`, and `widget.store.deleteCategory`.

- [ ] **Step 4: Verify green**

Expected: add/edit transaction forms use the same category menu UI, category selection is immediate, and the transaction sheet is still visible after selection.

### Task 4: Category Menu Header Edge Controls

**Files:**
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
- Test: `test/transactions/transaction_widgets_test.dart`

- [ ] **Step 1: Write failing test**

Assert that `category-menu-back-button` and `category-add-button` are inside explicit tight edge-aligned boxes with no default inward `IconButton` padding.

- [ ] **Step 2: Run red verification**

Expected before implementation: default `IconButton` constraints/padding keep the controls visually inward.

- [ ] **Step 3: Implement explicit edge layout**

Wrap each button in `SizedBox(width: 44, height: 54)`, set `padding: EdgeInsets.zero`, `constraints: const BoxConstraints.tightFor(width: 44, height: 54)`, and use `Positioned(left: 0)` / `Positioned(right: 0)`.

- [ ] **Step 4: Verify green**

Expected: buttons sit on the modal header edges in both home category mode and transaction picker mode.

### Task 5: Backheader Category Budget Swipe Animation

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/header_layout_test.dart`

- [ ] **Step 1: Write failing test**

Add a drag test over `category-budget-stage` that expects a horizontal transform/offset while dragging before release, then expects the active dot/index to change only after the settle animation completes.

- [ ] **Step 2: Run red verification**

Expected before implementation: `_dragDx` is accumulated but never applied to the UI.

- [ ] **Step 3: Implement visible drag and settle animation**

Convert `_CategoryBudgetStageState` to use `SingleTickerProviderStateMixin` and an `AnimationController`. Apply `_dragDx` through a `Transform.translate` around `CategoryBudgetBar`. During drag, call `setState` as `_dragDx` changes. On release, animate to `-availableWidth` or `availableWidth` for threshold-passing swipes, update `_index`, then reset `_dragDx` to `0`; otherwise animate back to `0`.

- [ ] **Step 4: Verify green**

Expected: the category bar moves sideways with the finger and settles with animation.

### Task 6: Full Verification, Commit, Push, Online Build

**Files:**
- Review: `git diff`
- Verify: GitHub Actions run on `main`

- [ ] **Step 1: Local static checks**

Run: `git diff --check`
Expected: no whitespace errors.

- [ ] **Step 2: Local Flutter attempt**

Run: `/data/data/com.termux/files/home/flutter_user/flutter/bin/flutter test`
Expected in this environment: likely Dart TLS alignment failure. Record the failure instead of treating it as proof of app failure.

- [ ] **Step 3: Commit and push**

Commit the implementation with a concise message and push to `origin/main`.

- [ ] **Step 4: Monitor GitHub Actions**

Run: `gh run list --limit 5` and watch the run for the pushed commit. Expected: analyze, tests, debug APK build, and artifact upload pass online.

---

## Self-Review

- Spec coverage: Task 1 covers the shared FastInfo/header component and lower FastInfo elements; Task 2 covers FAB long press; Tasks 3-4 cover category picker/menu edge controls; Task 5 covers backheader swipe animation; Task 6 covers push and online build.
- Placeholder scan: no placeholder or fill-in language remains.
- Type consistency: category selection stays typed as `TransactionCategory`; transaction type uses existing `TransactionType`; FAB callbacks use `VoidCallback` consistently.
