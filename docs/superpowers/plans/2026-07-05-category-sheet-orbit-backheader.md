# Category Sheet Orbit Backheader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the slide-up category picker layering/drag behavior and redesign only the `orbitBudget` backheader so its limit editor is embedded, draggable, and immediately persisted.

**Architecture:** Keep `TransactionHomePage` as the home state owner. The shell hides/blocks navigation when the home page reports a foreground overlay; category sheet drag gating stays in `SlideUpMenuCard`; orbitBudget-specific layout and inline editing live in `CategoryBudgetStage` and `BackheaderStyleSurface`. Shared limit math continues to use `LimitSliderRange`, `LimitAllocationManager`, and `CategoryLimitPartitionBar`.

**Tech Stack:** Flutter/Dart widget tests, existing transaction store/model layer, GitHub/online APK build later; local tests and analysis run through Ubuntu proot.

## Global Constraints

- Do not run local Flutter APK builds in Termux/Android ARM64.
- Run local Flutter tests/analyze inside Ubuntu proot with `/home/flutteruser/flutter/bin/flutter`.
- Tests must be written before implementation and watched failing before production edits.
- Completion requires all checklist rows in `docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md` to be `DONE` or explicitly deferred.
- Classic and hero-token backheader styles must keep their existing external `BudgetTargetEditorSheet` behavior.
- OrbitBudget inline editor has no save button; slider changes save immediately, while close/shrink gestures do not save.
- Category slide sheet must keep the add-category sheet above it while the picker remains mounted behind it.

---

## File Structure

- Modify `test/transactions/category_menu_test.dart`: add widget tests for handler-only drag, content scroll isolation, diagonal no-op, and bottom pill visibility in slide-up category mode.
- Modify `test/transactions/category_menu_test.dart`: add a slide-up sheet layout regression proving the category scroll body ends above the fixed bottom add pill with a persistent gap matching `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260705-045048.png`.
- Modify `test/widget_test.dart`: add shell-level widget test proving slide-up category sheet foreground state hides/blocks bottom nav and FAB.
- Modify `lib/features/transactions/widgets/slide_up_menu_card.dart`: add an opt-in handler-only drag gate for sheets that should not drag from content.
- Modify `lib/features/transactions/transaction_home_page.dart`: report category slide picker as a blocking overlay, pass handler-only drag options, and route orbitBudget budget editing inline.
- Modify `lib/features/shell/expt_shell.dart`: hide shell navigation/FAB while the home page reports a blocking foreground overlay.
- Modify `test/transactions/category_budget_stage_test.dart`: add orbitBudget layout, partition, ring, gesture, no external tap, and inline save tests.
- Modify `test/transactions/category_budget_stage_test.dart`: add orbitBudget inline editor regressions for smooth serialized/debounced persistence, amount input, reset/delete, previous/next, max, explicit jump-to-overview/income, and top content +10px layout.
- Modify `test/transactions/transaction_home_limits_test.dart`: add home-level orbitBudget regression tests proving no separate sheet opens and slider save is immediate.
- Modify `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`: replace orbitBudget’s old orbit chart/avatar with icon/name/amount/partition/ring layout.
- Modify `lib/features/transactions/widgets/header_card/category_budget_stage.dart`: add orbitBudget inline expansion state, drag thresholds, slider persistence, partition/ring preview data, and axis-safe gestures.
- Modify `docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md`: update row statuses after verification.

## Task 1: Category Sheet Red Tests

**Files:**
- Test: `test/transactions/category_menu_test.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes existing keys: `category-menu-slide-card`, `category-menu-add-pill`, `slide-up-menu-transform`, `header-category-button`, `expt-bottom-nav`, `expt-fab`.
- Produces regression expectations later satisfied by `SlideUpMenuCard.dragFromHandleOnly` and shell nav hiding.

- [ ] **Step 1: Add handler/content drag tests**

Add tests that open `TransactionHomePage` with `categoryMenuPresentation: CategoryMenuPresentation.slideUpSheet`, then:

```dart
final transformBefore = tester.widget<Transform>(
  find.byKey(const ValueKey('slide-up-menu-transform')),
);
await tester.drag(find.byKey(const ValueKey('category-card-6')), const Offset(0, 90));
await tester.pump();
final transformAfter = tester.widget<Transform>(
  find.byKey(const ValueKey('slide-up-menu-transform')),
);
expect(transformAfter.transform, transformBefore.transform);
```

Also drag from `sheetRect.topCenter + const Offset(0, 24)` and assert the sheet transform changes during the gesture, then snaps or dismisses according to existing thresholds.

- [ ] **Step 2: Add shell foreground test**

In `test/widget_test.dart`, pump `ExptShell`, apply slide-up category presentation using the existing settings/theme helper path, open the category picker from `header-category-button`, then assert:

```dart
expect(find.byKey(const ValueKey('category-menu-slide-card')), findsOneWidget);
expect(find.byKey(const ValueKey('category-menu-add-pill')), findsOneWidget);
expect(find.byKey(const ValueKey('expt-bottom-nav')), findsNothing);
expect(find.byKey(const ValueKey('expt-fab')), findsNothing);
```

- [ ] **Step 3: Verify RED**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_menu_test.dart test/widget_test.dart --plain-name "slide-up category"'
```

Expected: at least one new test fails because content drag still moves the sheet and/or shell nav/FAB remain mounted.

## Task 2: Category Sheet Implementation

**Files:**
- Modify: `lib/features/transactions/widgets/slide_up_menu_card.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/shell/expt_shell.dart`

**Interfaces:**
- Produces `SlideUpMenuCard.dragFromHandleOnly`.
- Produces category slide picker blocking overlay notification.

- [ ] **Step 1: Add handler-only option**

Add a constructor parameter and field:

```dart
this.dragFromHandleOnly = false,
final bool dragFromHandleOnly;
```

In `_handlePointerDown`, after drag exclusions and before `_dragActive = true`, reject non-handler starts:

```dart
if (widget.dragFromHandleOnly &&
    event.localPosition.dy > widget.dragHandleExtent) {
  _dragActive = false;
  DebugConsole.log(
    '[SlideUpMenu] $_debugLabel drag ignored outside handle y=${event.localPosition.dy.toStringAsFixed(1)} handle=${widget.dragHandleExtent.toStringAsFixed(1)}',
  );
  return;
}
```

- [ ] **Step 2: Wire category sheet**

In `TransactionHomePage.build`, compute `categoryMenuIsSlide` before `_notifyBlockingOverlay` and include:

```dart
(_categoryMode != null && categoryMenuIsSlide)
```

Pass to the category `SlideUpMenuCard`:

```dart
dragFromHandleOnly: true,
dragHandleExtent: 72,
```

- [ ] **Step 3: Hide shell navigation during blocking home overlay**

In `ExptShell.build`, render shell navigation only when:

```dart
if (!_homeBlockingOverlayOpen) ...shellNavigation,
```

Leave `_ShellSheetHost` above the body so add-category and other shell-hosted sheets still render.

- [ ] **Step 4: Verify GREEN**

Run the same category/shell tests from Task 1. Expected: selected tests pass without Flutter framework errors.

- [ ] **Step 5: Commit**

Commit only category sheet changes:

```bash
git add test/transactions/category_menu_test.dart test/widget_test.dart lib/features/transactions/widgets/slide_up_menu_card.dart lib/features/transactions/transaction_home_page.dart lib/features/shell/expt_shell.dart
git commit -m "fix: keep category slide sheet foreground"
```

## Task 3: OrbitBudget Layout Red Tests

**Files:**
- Test: `test/transactions/category_budget_stage_test.dart`

**Interfaces:**
- Consumes `CategoryBudgetStage`.
- Produces required keys: `backheader-orbit-icon`, `backheader-orbit-title`, `backheader-orbit-amount`, `backheader-orbit-progress-ring`, `category-limit-partition-bar`, `backheader-orbit-handle`.

- [ ] **Step 1: Add collapsed layout test**

Create an orbitBudget stage with one limited category and assert:

```dart
expect(find.byKey(const ValueKey('backheader-style-orbitBudget-content')), findsOneWidget);
expect(find.byKey(const ValueKey('backheader-orbit-icon')), findsOneWidget);
expect(find.byKey(const ValueKey('backheader-orbit-title')), findsOneWidget);
expect(find.byKey(const ValueKey('backheader-orbit-amount')), findsOneWidget);
expect(find.byKey(const ValueKey('backheader-orbit-progress-ring')), findsOneWidget);
expect(find.byKey(const ValueKey('category-limit-partition-bar')), findsOneWidget);
expect(find.byKey(const ValueKey('backheader-partition-strip')), findsNothing);
```

Compare rect ordering: icon left, title middle, amount right, partition bar near card bottom.

- [ ] **Step 2: Add no-ring test**

Render an unlimited category in orbitBudget and assert `backheader-orbit-progress-ring` is absent while icon/title/amount remain.

- [ ] **Step 3: Add style isolation test**

Render `BackheaderStyle.heroToken` and assert `backheader-partition-strip` remains present and orbit-specific keys are absent.

- [ ] **Step 4: Verify RED**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart --plain-name "orbitBudget"'
```

Expected: new tests fail because the old orbit chart/avatar/fake partition strip is still rendered.

## Task 4: OrbitBudget Collapsed Layout Implementation

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`

**Interfaces:**
- `BackheaderStyleSurface` gains optional `Widget? orbitPartitionBar`, `double orbitProgress`, and `bool orbitHasLimit`.
- `CategoryBudgetStage` supplies a `CategoryLimitPartitionBar` allocation for orbitBudget.

- [ ] **Step 1: Build orbit partition helper in stage**

Import `limit_allocation_manager.dart` and `category_limit_partition_bar.dart`, then add:

```dart
Widget _orbitPartitionBarFor(BackheaderBudgetItem current) {
  if (current.overview?.kind == BudgetGoalKind.savingGoal) return const SizedBox.shrink();
  final allocation = LimitAllocationManager.build(
    overviewLimit: _orbitOverviewLimitAmount(current),
    bars: _categoryBars,
  );
  return CategoryLimitPartitionBar(height: 14, allocation: allocation);
}
```

Use the same category/overview matching logic as `BudgetTargetEditorSheet`.

- [ ] **Step 2: Replace orbit content**

In `BackheaderStyleSurface`, import `category_slot_icon.dart` and render orbitBudget as:

```dart
Row(
  children: [
    _OrbitIcon(...),
    const SizedBox(width: 14),
    Expanded(child: Text(current.title, key: const ValueKey('backheader-orbit-title'), ...)),
    const SizedBox(width: 12),
    Flexible(child: Text(amountText, key: const ValueKey('backheader-orbit-amount'), ...)),
  ],
)
```

Place `orbitPartitionBar` at the bottom of the colored card and add a bottom handle key `backheader-orbit-handle`.

- [ ] **Step 3: Add white ring painter**

Add `_OrbitIconProgressRing` with `CustomPainter` using white stroke, `strokeWidth: 2.2`, and `progress.clamp(0, 1)`. Only mount it when `orbitHasLimit == true`.

- [ ] **Step 4: Verify GREEN**

Run the orbitBudget layout tests from Task 3. Expected: selected tests pass.

## Task 5: OrbitBudget Inline Editor Red Tests

**Files:**
- Test: `test/transactions/category_budget_stage_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

**Interfaces:**
- Consumes new keys: `backheader-orbit-handle`, `backheader-orbit-inline-editor`, `backheader-orbit-slider`, `backheader-orbit-expanded-shell`.
- Produces callbacks on `CategoryBudgetStage`: `periodIncome`, `overviewItems`, `onSaveOverview`, `onSaveCategory`.

- [ ] **Step 1: Add stage expand/snap tests**

Render `CategoryBudgetStage(backheaderStyle: BackheaderStyle.orbitBudget, ...)`. Drag `backheader-orbit-handle` down by 40 px and assert no inline editor remains. Drag it down by 90 px and assert:

```dart
expect(find.byKey(const ValueKey('backheader-orbit-inline-editor')), findsOneWidget);
expect(find.byKey(const ValueKey('backheader-orbit-slider')), findsOneWidget);
expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
```

- [ ] **Step 2: Add shrink trigger tests**

After expansion, drag the handle down by 12 px and release; assert the inline editor collapses. Repeat but drag down 12 px, back up 12 px, release; assert it remains expanded.

- [ ] **Step 3: Add axis-safety tests**

Drag the full experimental surface horizontally and assert active item changes. Drag the handle diagonally with similar dx/dy and assert expanded state does not change.

- [ ] **Step 4: Add immediate-save test**

Render stage with `onSaveCategory` recording calls. Expand handle, drag `backheader-orbit-slider`, pump one frame, then assert:

```dart
expect(savedCategoryAmounts, isNotEmpty);
expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
expect(find.textContaining('/'), findsOneWidget);
```

Then collapse without touching the slider and assert no additional save call.

- [ ] **Step 5: Add home-level no-sheet test**

In `transaction_home_limits_test.dart`, pump expanded home with `ExpenseTheme.fromSettings(AppThemeSettings.defaults().copyWith(backheaderStyle: BackheaderStyle.orbitBudget))`, tap/drag the backheader, and assert `budget-target-editor-card` is absent while `backheader-orbit-inline-editor` appears after handle expansion.

- [ ] **Step 6: Verify RED**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart --plain-name "orbit"'
```

Expected: new tests fail because inline editor keys/callbacks do not exist and orbitBudget taps still open the external sheet.

## Task 6: OrbitBudget Inline Editor Implementation

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`

**Interfaces:**
- `CategoryBudgetStage` receives:

```dart
final List<OverviewBudgetData> overviewItems;
final double periodIncome;
final Future<void> Function(BudgetGoalKind kind, {required double limitAmount, required bool alertActive})? onSaveOverview;
final Future<void> Function(CategoryBudgetBarData bar, {required double limitAmount, required bool alertActive})? onSaveCategory;
```

- [ ] **Step 1: Add inline state**

In `_CategoryBudgetStageState`, add expansion constants/state:

```dart
static const _orbitShrinkArmDistance = 10.0;
double _orbitExpansion = 0;
double _orbitDragStartExpansion = 0;
bool _orbitExpanded = false;
bool _orbitShrinkArmed = false;
bool _orbitAcceptedVerticalDrag = false;
double _orbitGestureDx = 0;
double _orbitGestureDy = 0;
final _orbitPendingAmountsByKey = <String, double>{};
final _orbitRememberedSliderMaxByKey = <String, double>{};
```

Expansion max is:

```dart
TransactionHeaderMetrics.contentTop +
TransactionMenuMetrics.typePillTopPadding +
TransactionMenuMetrics.typePillMinHeight -
TransactionHeaderMetrics.cardHeight
```

- [ ] **Step 2: Prevent external sheet in orbitBudget**

Change `_tap` so orbitBudget does not call `widget.onItemTap`:

```dart
if (widget.backheaderStyle == BackheaderStyle.orbitBudget) return;
```

Classic/heroToken keep existing tap behavior.

- [ ] **Step 3: Add handle vertical drag**

Wrap only `backheader-orbit-handle` in a vertical drag handler. Accept vertical drag only when `absDy > 8`, `absDy > absDx * 1.25`, and `dy > 0` for expansion/shrink arming. Diagonal gestures leave `_orbitExpansion` unchanged.

- [ ] **Step 4: Add inline editor UI**

When `_orbitExpanded == true`, render a compact internal editor with key `backheader-orbit-inline-editor` containing:

```dart
_orbitPartitionBarFor(current),
CategoryLimitSlider(
  key: const ValueKey('backheader-orbit-slider'),
  value: _orbitSliderRangeFor(current).value,
  max: _orbitSliderRangeFor(current).max,
  divisions: _orbitSliderRangeFor(current).divisions,
  enabled: _orbitSliderRangeFor(current).enabled,
  activeColor: current.category?.color ?? AppColors.white,
  onChanged: (value) => _setOrbitAmountFromSlider(current, value),
  onChangeEnd: (value) => _setOrbitAmountFromSlider(current, value),
),
```

Do not render `limit-save-button`.

- [ ] **Step 5: Save immediately on slider change**

Implement `_setOrbitAmountFromSlider` to snap via `LimitAllocationManager.snapSliderAmount`, update `_orbitPendingAmountsByKey`, call `setState`, and immediately call the matching save callback with `alertActive: amount > 0`.

- [ ] **Step 6: Pass store callbacks from home**

When constructing `CategoryBudgetStage` in `TransactionHomePage`, pass `overviewItems`, `periodIncome`, `onSaveOverview`, and `onSaveCategory`. Keep `onItemTap: _openBudgetTargetEditor`; the stage itself suppresses it for orbitBudget.

- [ ] **Step 7: Verify GREEN**

Run the orbit tests from Task 5. Expected: selected tests pass.

## Task 7: Full Verification And Checklist

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md`

**Interfaces:**
- Produces honest status rows for CS1-CS4 and OB1-OB11.

- [ ] **Step 1: Run focused verification**

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_menu_test.dart test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart test/widget_test.dart'
```

- [ ] **Step 2: Run analyzer**

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

- [ ] **Step 3: Update checklist**

For each row in `docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md`, set `DONE`, `PARTIAL`, or `BLOCKED` based on tests/code inspection. Do not mark a row `DONE` unless its acceptance condition has evidence.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md lib test
git commit -m "feat: redesign orbit budget backheader"
```

- [ ] **Step 5: Stop before APK build**

Do not run local APK build. If all checklist rows are `DONE`, push branch and use GitHub Actions for the debug APK in the later build/push phase.

## Self-Review

- Spec coverage: CS1-CS4 covered in Tasks 1-2; OB1-OB5 in Tasks 3-4; OB6-OB11 in Tasks 5-6; final verification/checklist in Task 7.
- No partial build claim: plan ends with verification and checklist before any APK/build status.
- Type consistency: new `CategoryBudgetStage` callbacks match `BudgetTargetEditorSheet` save callback shapes and existing `TransactionStore` methods.

---

## Addendum Task 8: Category Sheet Scroll Body Gap

**Files:**
- Modify: `test/transactions/category_menu_test.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`

**Interfaces:**
- Consumes existing keys: `category-menu-add-pill` and the slide-up category body/grid key currently used by `CategoryMenuPanel`.
- Produces a stable scroll body bottom gap above `category-menu-add-pill` in slide-up sheet mode.

- [ ] **Step 1: Write failing layout test**

Add a slide-up category menu test that opens the sheet and asserts:

```dart
final body = tester.getRect(find.byKey(const ValueKey('category-menu-scroll-body')));
final addPill = tester.getRect(find.byKey(const ValueKey('category-menu-add-pill')));
expect(body.bottom, lessThan(addPill.top));
expect(addPill.top - body.bottom, greaterThanOrEqualTo(20));
```

The body key may be added in the implementation if it does not exist yet; the RED failure should be either missing key or insufficient gap.

- [ ] **Step 2: Run RED**

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_menu_test.dart --plain-name "slide-up category"'
```

Expected: FAIL because the body key/gap is not implemented.

- [ ] **Step 3: Implement fixed body/add-pill layout**

In `CategoryMenuPanel`, when `addButtonPlacement == CategoryMenuAddButtonPlacement.bottomPill`, keep the add pill outside the scroll body and give the scroll body a bounded `Expanded` area ending above the pill. Add `ValueKey('category-menu-scroll-body')` to that bounded body. Preserve inline mode behavior.

- [ ] **Step 4: Run GREEN**

Run the same command. Expected: PASS for the new gap test and existing slide-up category tests.

## Addendum Task 9: Orbit Inline Editor Controls And Smooth Persistence

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`

**Interfaces:**
- Consumes `CategoryLimitSlider`, `CategoryLimitPartitionBar`, `LimitSliderRange`, `LimitAllocationManager`, and sheet control keys (`limit-amount-input`, `limit-reset-inline-button`, `limit-slider-end-button`, `limit-card-previous-button`, `limit-card-next-button`).
- Produces an orbit inline editor with sheet-equivalent controls except `limit-save-button`, immediate UI preview, and serialized/debounced persistence.

- [ ] **Step 1: Write failing controls test**

Add a widget test that expands an orbitBudget category item and asserts:

```dart
expect(find.byKey(const ValueKey('limit-amount-input')), findsOneWidget);
expect(find.byKey(const ValueKey('limit-reset-inline-button')), findsOneWidget);
expect(find.byKey(const ValueKey('limit-card-previous-button')), findsOneWidget);
expect(find.byKey(const ValueKey('limit-card-next-button')), findsOneWidget);
expect(find.byKey(const ValueKey('backheader-overview-jump-button')), findsOneWidget);
expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
```

Tap reset and verify the latest save callback receives `limitAmount == 0` and `alertActive == false`.

- [ ] **Step 2: Write failing input/max/jump test**

Add a widget test that expands an overview/income item, taps `limit-slider-end-button`, enters text into `limit-amount-input`, and verifies immediate preview/save. From a category item, tap `backheader-overview-jump-button` and verify `onActiveItemChanged` receives the matching overview/income item.

- [ ] **Step 3: Write failing smooth-save test**

Add a widget test with a delayed save callback. Call the slider `onChanged` several times rapidly through the `CategoryLimitSlider` widget and assert no more than one in-flight save at a time, the UI amount updates immediately, and after debounce/flush the latest amount is saved. Add a save callback that throws once and assert `tester.takeException()` stays null.

- [ ] **Step 4: Write failing +10px layout test**

Record the `top` of `backheader-orbit-icon`/`backheader-orbit-title` and assert it is at least 10 px lower than the previous orbit top offset, while a heroToken/classic test keeps its existing positions/keys.

- [ ] **Step 5: Run RED**

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart --plain-name "orbitBudget"'
```

Expected: FAIL because the inline editor only has text+slider and saves on every slider movement.

- [ ] **Step 6: Implement inline editor state**

Add a `TextEditingController`, `FocusNode`, `_orbitSavingByKey`, `_orbitQueuedSaveByKey`, and `Timer? _orbitSaveDebounce`. Keep UI preview state in `_orbitPendingAmountsByKey`. Input/slider/reset/max write preview immediately and schedule persistence. Dispose the controller, focus node, and timer.

- [ ] **Step 7: Implement serialized/debounced persistence**

Replace per-pixel `unawaited(_saveOrbitItemAmount(...))` with a scheduler that:

```dart
_orbitQueuedSaveByKey[item.key] = amount;
_orbitSaveDebounce?.cancel();
_orbitSaveDebounce = Timer(const Duration(milliseconds: 120), _flushOrbitSaves);
```

`_flushOrbitSaves` saves one latest amount per key sequentially. If a save is already running, mark the latest amount queued and run it after the current save completes. Wrap saves in `try/catch` and log through `DebugConsole.log`.

- [ ] **Step 8: Implement missing controls**

Render compact controls inside `backheader-orbit-inline-editor`: previous/next icon buttons, explicit `backheader-overview-jump-button` for category-to-overview/income, `limit-slider-end-button` for overview max, `limit-reset-inline-button`, and `ThemedPillField` with `limit-amount-input`. Do not render `limit-save-button`.

- [ ] **Step 9: Move orbit top content 10px down**

In `BackheaderStyleSurface._OrbitBudget`, change top padding from `32` to `42`. Do not change heroToken/classic layout.

- [ ] **Step 10: Run GREEN**

Run the RED command again. Expected: PASS.

## Addendum Task 10: Final Regression Verification

**Files:**
- Modify: `docs/superpowers/checklists/2026-07-05-category-sheet-orbit-backheader-checklist.md`

- [ ] **Step 1: Run focused suite**

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test --no-pub test/transactions/category_menu_test.dart test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart test/widget_test.dart'
```

- [ ] **Step 2: Run analyzer**

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze --no-pub'
```

- [ ] **Step 3: Update checklist**

Set CS5 and OB12-OB17 to `DONE` only after the focused tests/analyzer and direct code inspection confirm the acceptance conditions.
