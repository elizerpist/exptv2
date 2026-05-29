# Limit Editor Redesign UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the limit editor, remove the pie chart, make partition bars navigable, stabilize limit sliders, and align the backheader, summary pill, and header-card gestures with the approved spec.

**Architecture:** Keep the existing transaction feature boundaries. Add one focused slider-range helper, reuse `SlideUpMenuCard` for the redesigned editor surface, and update the existing header/backheader widgets in place rather than introducing a parallel UI tree. Each task starts with failing widget/unit tests and ends with a small commit.

**Tech Stack:** Flutter/Dart, existing transaction widgets/state, `flutter_test`, existing GitHub Actions Flutter analyze/test/build workflow.

---

## File Map

- `lib/features/transactions/data/limit_slider_range.dart`: new pure helper for fallback max, adaptive high-water max, snapping, and constrained category ranges.
- `lib/features/transactions/data/limit_allocation_manager.dart`: keep allocation math and slider step; only change if a shared helper needs its existing `sliderStep`/`sliderDivisions` methods.
- `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`: redesigned editor content, no pie chart, adaptive slider state, partition tap navigation.
- `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`: make allocation/legacy category subbars tappable without changing free gray segments into targets.
- `lib/features/transactions/widgets/header_card/category_budget_bar.dart`: reverse category progress opacity so remaining limit is strong and spent portion is low opacity.
- `lib/features/transactions/widgets/header_card/category_budget_stage.dart`: release-triggered swipe, smaller visual offset, overview jump button, budget bar shrink behavior.
- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`: balance label/value position and any header transition hooks that must live in the card.
- `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`: balance top constants only.
- `lib/features/transactions/widgets/summary_pill.dart`: swapped gesture mapping and double tap callback.
- `lib/features/transactions/transaction_home_page.dart`: wire summary callbacks, inline redesigned limit editor overlay, backheader overview jump, header expanded transition.
- `lib/features/transactions/state/transaction_store.dart`: add `resetSummaryToCurrentMonth()` and keep existing `cycleSummaryWindow()`/`shiftSummaryPeriod()` behavior.
- Delete `lib/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart` after references are gone.
- Delete `test/transactions/limit_allocation_pie_chart_test.dart` after equivalent partition tests exist.
- Update tests in `test/transactions/category_budget_stage_test.dart`, `test/transactions/transaction_home_limits_test.dart`, `test/transactions/transaction_widgets_test.dart`, `test/transactions/header_layout_test.dart`, and `test/transactions/header_card_test.dart`.
- Add `test/transactions/limit_slider_range_test.dart`.

### Task 1: Summary Pill Gesture Contract

**Files:**
- Modify: `lib/features/transactions/widgets/summary_pill.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/transaction_widgets_test.dart`
- Test: `test/transactions/transaction_store_test.dart`

- [ ] **Step 1: Write failing summary pill widget tests**

Replace the old horizontal/vertical gesture expectations in `test/transactions/transaction_widgets_test.dart` with explicit tests for the new mapping:

```dart
testWidgets('summary pill vertical swipe cycles interval', (tester) async {
  var cycles = 0;
  final periods = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: SummaryPill(
        title: 'Május 2026',
        value: '-66 Ft',
        onIntervalSwipe: () => cycles += 1,
        onPeriodSwipe: periods.add,
        onResetToCurrentMonth: () {},
      ),
    ),
  );

  await tester.drag(
    find.byKey(const ValueKey('summary-pill')),
    const Offset(0, -90),
  );
  await tester.pumpAndSettle();

  expect(cycles, 1);
  expect(periods, isEmpty);
});

testWidgets('summary pill horizontal swipe shifts period', (tester) async {
  var cycles = 0;
  final periods = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: SummaryPill(
        title: 'Május 2026',
        value: '-66 Ft',
        onIntervalSwipe: () => cycles += 1,
        onPeriodSwipe: periods.add,
        onResetToCurrentMonth: () {},
      ),
    ),
  );

  await tester.drag(
    find.byKey(const ValueKey('summary-pill')),
    const Offset(-90, 0),
  );
  await tester.pumpAndSettle();
  await tester.drag(
    find.byKey(const ValueKey('summary-pill')),
    const Offset(90, 0),
  );
  await tester.pumpAndSettle();

  expect(cycles, 0);
  expect(periods, [1, -1]);
});

testWidgets('summary pill double tap resets to current month', (tester) async {
  var resets = 0;
  await tester.pumpWidget(
    MaterialApp(
      home: SummaryPill(
        title: 'Sum',
        value: '-66 Ft',
        onIntervalSwipe: () {},
        onPeriodSwipe: (_) {},
        onResetToCurrentMonth: () => resets += 1,
      ),
    ),
  );

  await tester.tap(find.byKey(const ValueKey('summary-pill')));
  await tester.pump(const Duration(milliseconds: 80));
  await tester.tap(find.byKey(const ValueKey('summary-pill')));
  await tester.pumpAndSettle();

  expect(resets, 1);
});
```

- [ ] **Step 2: Write failing store reset test**

Add this to `test/transactions/transaction_store_test.dart` near the summary window tests:

```dart
test('reset summary returns to current monthly window', () async {
  final store = TransactionStore(
    FakeTransactionRepository(),
    clock: () => DateTime(2026, 5, 29),
  );
  await store.start();

  await store.cycleSummaryWindow();
  await store.cycleSummaryWindow();
  await store.shiftSummaryPeriod(-2);
  expect(store.summaryWindow, SummaryWindow.yearly);

  await store.resetSummaryToCurrentMonth();

  expect(store.summaryWindow, SummaryWindow.monthly);
  expect(store.activePeriodLabel, 'Május 2026');
});
```

- [ ] **Step 3: Run the focused tests and verify failure**

Run:

```bash
flutter test test/transactions/transaction_widgets_test.dart test/transactions/transaction_store_test.dart
```

Expected locally in Termux: the command may fail before tests with the known ARM64 TLS alignment error. If it runs, the new tests should fail because `SummaryPill` does not expose the new callbacks and the store reset method does not exist.

- [ ] **Step 4: Update `SummaryPill` API and gestures**

Change the constructor and fields in `lib/features/transactions/widgets/summary_pill.dart` to:

```dart
const SummaryPill({
  super.key,
  required this.title,
  required this.value,
  required this.onIntervalSwipe,
  required this.onPeriodSwipe,
  required this.onResetToCurrentMonth,
});

final String title;
final String value;
final VoidCallback onIntervalSwipe;
final ValueChanged<int> onPeriodSwipe;
final VoidCallback onResetToCurrentMonth;
```

Update the handlers:

```dart
void _handleHorizontalDragUpdate(DragUpdateDetails details) {
  if (_triggered) return;
  _dragDx += details.delta.dx;
  setState(() => _visualDx = (_dragDx * 0.1).clamp(-18.0, 18.0).toDouble());
  if (_dragDx.abs() < 60) return;

  _triggered = true;
  widget.onPeriodSwipe(_dragDx < 0 ? 1 : -1);
}

void _handleVerticalDragUpdate(DragUpdateDetails details) {
  if (_triggered) return;
  _dragDy += details.delta.dy;
  setState(() => _visualDy = (_dragDy * 0.1).clamp(-18.0, 18.0).toDouble());
  if (_dragDy.abs() < 60) return;

  _triggered = true;
  widget.onIntervalSwipe();
}
```

Add double tap wiring on the `GestureDetector`:

```dart
onDoubleTap: widget.onResetToCurrentMonth,
```

- [ ] **Step 5: Add store reset method and wire home page**

In `lib/features/transactions/state/transaction_store.dart`, add:

```dart
Future<void> resetSummaryToCurrentMonth() async {
  _summaryWindow = SummaryWindow.monthly;
  _periodReferenceDate = _monthStart(_clock());
  notifyListeners();
  await _projectRecurringGhostsForActiveWindow();
}
```

In `lib/features/transactions/transaction_home_page.dart`, replace the `SummaryPill` call with:

```dart
SummaryPill(
  title: widget.store.activeSummaryTitle,
  value: widget.store.activeSummary.formattedFor(
    widget.store.activeType,
  ),
  onIntervalSwipe: () {
    widget.store.cycleSummaryWindow();
  },
  onPeriodSwipe: (direction) {
    widget.store.shiftSummaryPeriod(direction);
  },
  onResetToCurrentMonth: () {
    widget.store.resetSummaryToCurrentMonth();
  },
),
```

- [ ] **Step 6: Run tests and commit**

Run:

```bash
flutter test test/transactions/transaction_widgets_test.dart test/transactions/transaction_store_test.dart
```

Expected on GitHub Actions: PASS. Expected locally if TLS bug persists: document the TLS error.

Commit:

```bash
git add lib/features/transactions/widgets/summary_pill.dart lib/features/transactions/transaction_home_page.dart lib/features/transactions/state/transaction_store.dart test/transactions/transaction_widgets_test.dart test/transactions/transaction_store_test.dart
git commit -m "feat: remap summary pill gestures"
```

### Task 2: Tappable Partition Bar And Pie Chart Removal

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Delete: `lib/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart`
- Delete: `test/transactions/limit_allocation_pie_chart_test.dart`
- Test: `test/transactions/category_budget_stage_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Write failing partition tap test**

Add to `test/transactions/category_budget_stage_test.dart` after the compact allocation test:

```dart
testWidgets('partition bar segment tap reports category target id', (tester) async {
  int? tappedTargetId;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: CategoryLimitPartitionBar(
            height: 29.4,
            allocation: LimitAllocationManager.build(
              overviewLimit: 100,
              bars: [
                barFixture(6, 'Food', 25, 50),
                barFixture(7, 'Travel', 0, 20),
              ],
            ),
            onSegmentTap: (targetId) => tappedTargetId = targetId,
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const ValueKey('category-limit-partition-segment-0')));
  await tester.pump();

  expect(tappedTargetId, 6);
});
```

- [ ] **Step 2: Replace pie editor sync test with partition sync test**

In `test/transactions/transaction_home_limits_test.dart`, replace the test named `pie tap selects category and syncs backheader` with:

```dart
testWidgets('partition tap selects category and syncs backheader', (tester) async {
  final repository = FakeHomeLimitRepository.withBudgetLimits();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 29));
  await tester.pumpWidget(MaterialApp(home: TransactionHomePage(store: store)));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('limit-allocation-pie-chart')), findsNothing);
  expect(find.byKey(const ValueKey('category-limit-partition-bar')), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('category-limit-partition-segment-0')));
  await tester.pumpAndSettle();

  expect(find.text('Food'), findsWidgets);
  expect(find.byKey(const ValueKey('backheader-active-title')), findsOneWidget);
  expect(
    tester.widget<Text>(find.byKey(const ValueKey('backheader-active-title'))).data,
    'Food',
  );
});
```

- [ ] **Step 3: Run focused tests and verify failure**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart
```

Expected if tests run: FAIL because `onSegmentTap` is not defined and the editor still renders the pie chart.

- [ ] **Step 4: Add tap callback to partition bar**

Update `CategoryLimitPartitionBar` constructor and fields:

```dart
const CategoryLimitPartitionBar({
  super.key,
  this.bars = const [],
  this.allocation,
  this.activeBar,
  this.activeLimitAmount,
  this.overviewLimitAmount,
  this.height = 42,
  this.onSegmentTap,
});

final ValueChanged<int>? onSegmentTap;
```

Pass it into `_AllocationPartitionBar`:

```dart
return _AllocationPartitionBar(
  allocation: allocation,
  height: height,
  onSegmentTap: onSegmentTap,
);
```

Update `_AllocationPartitionBar`:

```dart
const _AllocationPartitionBar({
  required this.allocation,
  required this.height,
  this.onSegmentTap,
});

final LimitAllocationData allocation;
final double height;
final ValueChanged<int>? onSegmentTap;
```

Wrap category segments:

```dart
final targetId = segment.targetId;
final tappable = targetId != null && onSegmentTap != null;
final child = Positioned(
  key: ValueKey('category-limit-partition-segment-$i'),
  left: left,
  top: 0,
  width: width,
  bottom: 0,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: tappable ? () => onSegmentTap!(targetId) : null,
    child: ColoredBox(color: segment.color),
  ),
);
```

- [ ] **Step 5: Remove pie chart from editor**

In `budget_target_editor_sheet.dart`:

Remove:

```dart
import 'limit_allocation_pie_chart.dart';
```

Remove `_buildPieChart()` and `_saveCategoryAmountByTargetId()`.

Pass the tap callback to the partition bar:

```dart
return CategoryLimitPartitionBar(
  height: 29.4,
  allocation: allocation,
  onSegmentTap: _selectCategoryByTargetId,
);
```

Remove `pieChart: _buildPieChart(),` from `_BudgetLimitCard` construction and remove the `pieChart` field/rendering from `_BudgetLimitCard`.

- [ ] **Step 6: Delete pie chart file and test**

Run:

```bash
rm lib/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart test/transactions/limit_allocation_pie_chart_test.dart
```

- [ ] **Step 7: Run tests and commit**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart
```

Commit:

```bash
git add lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart
git add -u lib/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart test/transactions/limit_allocation_pie_chart_test.dart
git commit -m "feat: navigate limit editor from partition bar"
```

### Task 3: Adaptive Limit Slider Range

**Files:**
- Create: `lib/features/transactions/data/limit_slider_range.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Test: `test/transactions/limit_slider_range_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Write pure helper tests**

Create `test/transactions/limit_slider_range_test.dart`:

```dart
import 'package:exptv2/features/transactions/data/limit_slider_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unconstrained slider defaults to 100000 with 1000 steps', () {
    final range = LimitSliderRange.unconstrained(
      amount: 0,
      rememberedMax: 0,
    );

    expect(range.max, 100000);
    expect(range.divisions, 100);
    expect(range.value, 0);
  });

  test('manual high value keeps a high water max after amount is reduced', () {
    final high = LimitSliderRange.unconstrained(
      amount: 250000,
      rememberedMax: 100000,
    );
    expect(high.max, 250000);

    final reduced = LimitSliderRange.unconstrained(
      amount: 50000,
      rememberedMax: high.max,
    );

    expect(reduced.max, 250000);
    expect(reduced.value, 50000);
  });

  test('constrained range disables empty category when no free budget remains', () {
    final range = LimitSliderRange.constrained(
      amount: 0,
      rememberedMax: 0,
      maxAllowed: 0,
      hasExistingLimit: false,
    );

    expect(range.enabled, isFalse);
    expect(range.max, 1);
    expect(range.value, 0);
  });
}
```

- [ ] **Step 2: Write widget regression for manual high input**

Add to `test/transactions/transaction_home_limits_test.dart`:

```dart
testWidgets('limit editor slider keeps adaptive max after manual high input', (tester) async {
  final repository = FakeHomeLimitRepository.withoutBudgetLimits();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 29));
  await tester.pumpWidget(MaterialApp(home: TransactionHomePage(store: store)));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
  await tester.pumpAndSettle();

  final initialSlider = tester.widget<Slider>(find.byKey(const ValueKey('category-limit-slider')));
  expect(initialSlider.max, 100000);
  expect(initialSlider.divisions, 100);

  await tester.enterText(find.byKey(const ValueKey('limit-amount-input')), '250000');
  await tester.pump(const Duration(milliseconds: 500));

  final highSlider = tester.widget<Slider>(find.byKey(const ValueKey('category-limit-slider')));
  expect(highSlider.max, 250000);

  await tester.drag(find.byKey(const ValueKey('category-limit-slider')), const Offset(-120, 0));
  await tester.pumpAndSettle();

  final reducedSlider = tester.widget<Slider>(find.byKey(const ValueKey('category-limit-slider')));
  expect(reducedSlider.max, 250000);
});
```

- [ ] **Step 3: Run focused tests and verify failure**

Run:

```bash
flutter test test/transactions/limit_slider_range_test.dart test/transactions/transaction_home_limits_test.dart
```

Expected if tests run: FAIL because the helper does not exist and the editor max shrinks to the current amount.

- [ ] **Step 4: Implement `LimitSliderRange`**

Create `lib/features/transactions/data/limit_slider_range.dart`:

```dart
import 'dart:math' as math;

import 'limit_allocation_manager.dart';

class LimitSliderRange {
  const LimitSliderRange({
    required this.value,
    required this.max,
    required this.divisions,
    required this.enabled,
  });

  static const fallbackMax = 100000.0;

  final double value;
  final double max;
  final int divisions;
  final bool enabled;

  static LimitSliderRange unconstrained({
    required double amount,
    required double rememberedMax,
  }) {
    final max = math.max(fallbackMax, math.max(amount, rememberedMax));
    return _build(amount: amount, max: max, enabled: true);
  }

  static LimitSliderRange constrained({
    required double amount,
    required double rememberedMax,
    required double maxAllowed,
    required bool hasExistingLimit,
  }) {
    if (maxAllowed <= 0 && !hasExistingLimit) {
      return _build(amount: 0, max: 1, enabled: false);
    }
    final max = math.max(maxAllowed, math.max(amount, rememberedMax));
    return _build(amount: amount, max: math.max(max, 1), enabled: true);
  }

  static LimitSliderRange _build({
    required double amount,
    required double max,
    required bool enabled,
  }) {
    final safeMax = max <= 0 ? 1.0 : max;
    return LimitSliderRange(
      value: amount.clamp(0.0, safeMax).toDouble(),
      max: safeMax,
      divisions: LimitAllocationManager.sliderDivisions(safeMax),
      enabled: enabled,
    );
  }
}
```

- [ ] **Step 5: Use adaptive range in editor**

In `budget_target_editor_sheet.dart`, import the helper:

```dart
import '../../data/limit_slider_range.dart';
```

Add state:

```dart
final _rememberedSliderMaxByKey = <String, double>{};
```

Add getter:

```dart
LimitSliderRange get _sliderRange {
  final remembered = _rememberedSliderMaxByKey[_activeKey] ?? 0;
  final overview = _activeItem.overview;
  if (overview != null) {
    if (widget.periodIncome > 0) {
      return LimitSliderRange.constrained(
        amount: _amount,
        rememberedMax: remembered,
        maxAllowed: math.max(widget.periodIncome, _amount),
        hasExistingLimit: _amount > 0,
      );
    }
    return LimitSliderRange.unconstrained(
      amount: _amount,
      rememberedMax: remembered,
    );
  }

  final category = _activeItem.category;
  if (category == null) {
    return const LimitSliderRange(value: 0, max: 1, divisions: 1, enabled: false);
  }
  final overviewLimit = _matchingOverviewLimitForCategory(category);
  if (overviewLimit <= 0) {
    return LimitSliderRange.unconstrained(
      amount: _amount,
      rememberedMax: remembered,
    );
  }
  final maxAllowed = LimitAllocationManager.categorySliderMax(
    overviewLimit: overviewLimit,
    bars: widget.categoryBars,
    activeBar: category,
  );
  return LimitSliderRange.constrained(
    amount: _amount,
    rememberedMax: remembered,
    maxAllowed: maxAllowed,
    hasExistingLimit: category.limitAmount > 0 || _amount > 0,
  );
}
```

Then replace `_sliderMax`, `_sliderValue`, `_sliderEnabled`, and `LimitAllocationManager.sliderDivisions(_sliderMax)` usage with `_sliderRange.max`, `_sliderRange.value`, `_sliderRange.enabled`, and `_sliderRange.divisions`.

Add high-water tracking inside `_setControllerAmount`:

```dart
void _rememberSliderMax(double amount) {
  final current = _rememberedSliderMaxByKey[_activeKey] ?? 0;
  if (amount > current) {
    _rememberedSliderMaxByKey[_activeKey] = amount;
  }
}
```

Call `_rememberSliderMax(amount);` before formatting text in `_setControllerAmount`.

- [ ] **Step 6: Run tests and commit**

Run:

```bash
flutter test test/transactions/limit_slider_range_test.dart test/transactions/transaction_home_limits_test.dart
```

Commit:

```bash
git add lib/features/transactions/data/limit_slider_range.dart lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart test/transactions/limit_slider_range_test.dart test/transactions/transaction_home_limits_test.dart
git commit -m "feat: stabilize adaptive limit sliders"
```

### Task 4: Redesigned Limit Editor Surface

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Write failing editor layout tests**

Add to `test/transactions/transaction_home_limits_test.dart`:

```dart
testWidgets('limit editor is inline slide-up panel reaching screen bottom', (tester) async {
  final repository = FakeHomeLimitRepository.withBudgetLimits();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 29));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(bottom: 24)),
        child: TransactionHomePage(store: store),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
  await tester.pumpAndSettle();

  final card = tester.getRect(find.byKey(const ValueKey('budget-target-editor-card')));
  expect(card.bottom, moreOrLessEquals(844, epsilon: 0.1));
  expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
  expect(find.byKey(const ValueKey('limit-cancel-button')), findsNothing);
});

testWidgets('redesigned limit card exposes arrows avatar input slider and partition bar', (tester) async {
  final repository = FakeHomeLimitRepository.withBudgetLimits();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 29));
  await tester.pumpWidget(MaterialApp(home: TransactionHomePage(store: store)));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('limit-card-previous-button')), findsOneWidget);
  expect(find.byKey(const ValueKey('limit-card-next-button')), findsOneWidget);
  expect(find.byKey(const ValueKey('limit-card-avatar')), findsOneWidget);
  expect(find.byKey(const ValueKey('limit-amount-input')), findsOneWidget);
  expect(find.byKey(const ValueKey('limit-reset-inline-button')), findsOneWidget);
  expect(find.byKey(const ValueKey('category-limit-slider')), findsOneWidget);
  expect(find.byKey(const ValueKey('category-limit-partition-bar')), findsOneWidget);
});
```

- [ ] **Step 2: Run layout tests and verify failure**

Run:

```bash
flutter test test/transactions/transaction_home_limits_test.dart
```

Expected if tests run: FAIL because the editor is still a modal bottom sheet and does not expose the final card key/layout.

- [ ] **Step 3: Convert budget editor to inline overlay**

In `TransactionHomePage` state add:

```dart
BackheaderBudgetItem? _budgetEditorItem;
```

In the `Stack`, after category overlays, add:

```dart
if (_budgetEditorItem != null)
  Positioned(
    top: TransactionMenuMetrics.overlayTop,
    left: 0,
    right: 0,
    bottom: 0,
    child: BudgetTargetEditorSheet(
      item: _budgetEditorItem!,
      items: widget.store.backheaderBudgetItems,
      categoryBars: widget.store.categoryBudgetBars,
      overviewItems: widget.store.overviewBudgetItems,
      periodIncome: widget.store.activePeriodIncomeTotal,
      onCancel: _closeBudgetTargetEditor,
      onActiveItemChanged: _setBackheaderActiveItem,
      onSaveOverview: (kind, {required limitAmount, required alertActive}) async {
        await widget.store.saveOverviewLimit(
          kind,
          limitAmount: limitAmount,
          alertActive: alertActive,
        );
      },
      onSaveCategory: (bar, {required limitAmount, required alertActive}) async {
        await widget.store.saveCategoryLimitForBar(
          bar,
          limitAmount: limitAmount,
          alertActive: alertActive,
        );
      },
    ),
  ),
```

Replace `_openBudgetTargetEditor` modal body with:

```dart
void _openBudgetTargetEditor(BackheaderBudgetItem item) {
  if (_backheaderActiveKey != item.key) {
    _backheaderActiveKey = item.key;
  }
  setState(() => _budgetEditorItem = item);
}

void _closeBudgetTargetEditor() {
  setState(() => _budgetEditorItem = null);
}
```

Include `_budgetEditorItem != null` in `_notifyBlockingOverlay(...)` if blocking overlays should keep FAB/bottom-nav behavior consistent.

- [ ] **Step 4: Rebuild `BudgetTargetEditorSheet` on `SlideUpMenuCard`**

Import:

```dart
import '../slide_up_menu_card.dart';
```

Replace the outer `SafeArea`/`Material`/`SingleChildScrollView` with:

```dart
return SlideUpMenuCard(
  cardKey: const ValueKey('budget-target-editor-card'),
  onDismissed: widget.onCancel,
  child: SafeArea(
    top: false,
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
        final contentHeight = constraints.maxHeight - keyboardInset - 44;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: keyboardInset + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: contentHeight < 0 ? 0 : contentHeight,
            ),
            child: IntrinsicHeight(
              child: _BudgetLimitCard(
                item: _activeItem,
                amountController: _controller,
                inputLabel: _inputLabel,
                activeColor: _activeColor,
                sliderValue: _sliderRange.value,
                sliderMax: _sliderRange.max,
                sliderEnabled: _sliderRange.enabled,
                sliderDivisions: _sliderRange.divisions,
                saving: _saving,
                onPrevious: _selectPrevious,
                onNext: _selectNext,
                onReset: _resetLimit,
                onSliderChanged: _setAmountFromSlider,
                onSliderChangeEnd: _saveSliderAmount,
                onInputChanged: _scheduleInputSave,
                onSetToMax: _setOverviewToMax,
                showSetToMax: _activeItem.overview != null,
                partitionBar: _buildPartitionBar(),
              ),
            ),
          ),
        );
      },
    ),
  ),
);
```

Rework `_BudgetLimitCard` so it lays out in this order with the listed keys: drag handle, arrow/avatar/name row, input pill, slider, partition bar. The avatar container must use `const ValueKey('limit-card-avatar')`, the previous button `limit-card-previous-button`, and the next button `limit-card-next-button`.

- [ ] **Step 5: Run tests and commit**

Run:

```bash
flutter test test/transactions/transaction_home_limits_test.dart
```

Commit:

```bash
git add lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart lib/features/transactions/transaction_home_page.dart test/transactions/transaction_home_limits_test.dart
git commit -m "feat: redesign limit editor surface"
```

### Task 5: Backheader Bar Visuals

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_budget_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Write failing category opacity tests**

Add to `test/transactions/category_budget_stage_test.dart`:

```dart
testWidgets('category bar shows full strength when limit has no spending', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CategoryBudgetBar(
          bar: barFixture(6, 'Food', 0, 10000),
          onTap: () {},
        ),
      ),
    ),
  );

  expect(find.byKey(const ValueKey('category-budget-remaining-fill')), findsOneWidget);
  expect(find.byKey(const ValueKey('category-budget-spent-overlay')), findsNothing);
});

testWidgets('category bar fades spent part and keeps remaining part strong', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: CategoryBudgetBar(
            bar: barFixture(6, 'Food', 1000, 10000),
            onTap: () {},
          ),
        ),
      ),
    ),
  );

  final spent = tester.widget<FractionallySizedBox>(
    find.byKey(const ValueKey('category-budget-spent-overlay')),
  );
  expect(spent.widthFactor, moreOrLessEquals(0.1, epsilon: 0.001));
});
```

- [ ] **Step 2: Write failing budget shrink test**

Add to `test/transactions/category_budget_stage_test.dart`:

```dart
testWidgets('expense budget overview bar shrinks as budget is consumed', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 260,
          child: CategoryBudgetStage(
            items: [
              BackheaderBudgetItem.overview(
                overviewFixture(BudgetGoalKind.expenseBudget, 25, 100),
              ),
            ],
            categoryBars: const [],
            onItemTap: (_) {},
          ),
        ),
      ),
    ),
  );

  final fill = tester.widget<FractionallySizedBox>(
    find.byKey(const ValueKey('overview-budget-remaining-fill')),
  );
  expect(fill.widthFactor, moreOrLessEquals(0.75, epsilon: 0.001));
});
```

- [ ] **Step 3: Run tests and verify failure**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart
```

Expected if tests run: FAIL because keys and reversed progress behavior do not exist.

- [ ] **Step 4: Reverse category opacity progress**

In `CategoryBudgetBar.build`, compute:

```dart
final spentRatio = bar.hasLimit && bar.limitAmount > 0
    ? (bar.spent / bar.limitAmount).clamp(0.0, 1.0).toDouble()
    : 0.0;
```

Replace the fill stack with:

```dart
ColoredBox(
  key: const ValueKey('category-budget-remaining-fill'),
  color: bar.color,
),
if (spentRatio > 0)
  FractionallySizedBox(
    key: const ValueKey('category-budget-spent-overlay'),
    widthFactor: spentRatio,
    alignment: Alignment.centerLeft,
    child: ColoredBox(color: bar.color.withValues(alpha: 0.30)),
  ),
```

- [ ] **Step 5: Shrink expense budget overview bar**

In `_OverviewBudgetBar.build`, replace `progress` with:

```dart
final spentRatio = overview.hasLimit && overview.limitAmount > 0
    ? (overview.amount / overview.limitAmount).clamp(0.0, 1.0).toDouble()
    : 0.0;
final widthFactor = overview.kind.warnsWhenHigh
    ? (1.0 - spentRatio).clamp(0.0, 1.0).toDouble()
    : spentRatio;
```

Use the key on the fill:

```dart
FractionallySizedBox(
  key: const ValueKey('overview-budget-remaining-fill'),
  widthFactor: widthFactor,
  alignment: Alignment.centerLeft,
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(height / 2),
    ),
  ),
),
```

Keep the surrounding `ClipRRect(borderRadius: BorderRadius.circular(height / 2))` so the right edge stays pill-shaped.

- [ ] **Step 6: Run tests and commit**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart
```

Commit:

```bash
git add lib/features/transactions/widgets/header_card/category_budget_bar.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart test/transactions/category_budget_stage_test.dart
git commit -m "feat: update backheader budget bar progress"
```

### Task 6: Backheader Release Swipe And Overview Jump

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/category_budget_stage_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Rewrite swipe tests for release-triggered switching**

In `test/transactions/category_budget_stage_test.dart`, update the test currently named `category budget stage switches immediately then snaps back` to:

```dart
testWidgets('category budget stage switches only when drag is released', (tester) async {
  final bars = [
    barFixture(6, 'Food', 100, 150),
    barFixture(7, 'Travel', 40, 0),
  ];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 260,
          child: CategoryBudgetStage(
            items: bars.map(BackheaderBudgetItem.category).toList(),
            categoryBars: bars,
            onItemTap: (_) {},
          ),
        ),
      ),
    ),
  );

  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const ValueKey('category-budget-bar'))),
  );
  await gesture.moveBy(const Offset(-90, 0));
  await tester.pump();

  expect(find.text('Food'), findsOneWidget);
  expect(find.text('Travel'), findsNothing);

  final held = tester.widget<Transform>(
    find.byKey(const ValueKey('category-budget-bar-translation')),
  );
  expect(held.transform.getTranslation().x.abs(), lessThanOrEqualTo(72));

  await tester.pump(const Duration(seconds: 1));
  expect(find.text('Food'), findsOneWidget);

  await gesture.up();
  await tester.pumpAndSettle();

  expect(find.text('Travel'), findsOneWidget);
  final settled = tester.widget<Transform>(
    find.byKey(const ValueKey('category-budget-bar-translation')),
  );
  expect(settled.transform.getTranslation().x, 0);
});
```

- [ ] **Step 2: Add overview jump test**

Add to `test/transactions/transaction_home_limits_test.dart`:

```dart
testWidgets('backheader overview jump button selects budget bar', (tester) async {
  final repository = FakeHomeLimitRepository.withBudgetLimits();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 29));
  await tester.pumpWidget(MaterialApp(home: TransactionHomePage(store: store)));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pumpAndSettle();
  await tester.drag(find.byKey(const ValueKey('category-budget-bar')), const Offset(-100, 0));
  await tester.pumpAndSettle();
  expect(find.text('Food'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('backheader-overview-jump-button')));
  await tester.pumpAndSettle();

  expect(find.text('Budget'), findsOneWidget);
});
```

- [ ] **Step 3: Run tests and verify failure**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart
```

Expected if tests run: FAIL because switching still happens during drag update and no overview jump button exists.

- [ ] **Step 4: Change drag switching to release-only**

In `CategoryBudgetStage`, remove `_swipeTriggered` and any update-time call to `_snapToNext`. Add constants:

```dart
static const _maxVisualDrag = 72.0;
static const _switchThreshold = 44.0;
```

Update drag handlers:

```dart
onHorizontalDragStart: (_) {
  _slideController.stop();
  _settling = false;
},
onHorizontalDragUpdate: (details) {
  if (_settling) return;
  final nextDx = (_dragDx + details.delta.dx)
      .clamp(-_maxVisualDrag, _maxVisualDrag)
      .toDouble();
  setState(() => _dragDx = nextDx);
},
onHorizontalDragCancel: () => _animateDragTo(0),
onHorizontalDragEnd: (_) => _settleDrag(),
```

Update settle methods:

```dart
Future<void> _settleDrag() async {
  if (_settling) return;
  final items = _items;
  if (items.length < 2 || _dragDx.abs() < _switchThreshold) {
    await _animateDragTo(0);
    return;
  }
  await _snapToNext(swipedLeft: _dragDx < 0);
}

Future<void> _snapToNext({required bool swipedLeft}) async {
  if (_settling) return;
  final items = _items;
  if (items.length < 2) return;
  _settling = true;
  setState(() {
    _index = swipedLeft
        ? (_index + 1) % items.length
        : _index == 0
            ? items.length - 1
            : _index - 1;
    _dragDx = swipedLeft ? _maxVisualDrag : -_maxVisualDrag;
  });
  widget.onActiveItemChanged?.call(_items[_index]);
  await _animateDragTo(
    0,
    curve: Curves.easeOutBack,
    duration: const Duration(milliseconds: 220),
  );
  _settling = false;
}
```

- [ ] **Step 5: Add overview jump button**

Add to `CategoryBudgetStage` constructor:

```dart
this.onOverviewJump,
```

Add field:

```dart
final VoidCallback? onOverviewJump;
```

Render lower-right button:

```dart
Positioned(
  right: 18,
  bottom: 10,
  child: Material(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(12),
    elevation: 4,
    child: InkWell(
      key: const ValueKey('backheader-overview-jump-button'),
      onTap: widget.onOverviewJump,
      borderRadius: BorderRadius.circular(12),
      child: const SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          Icons.account_balance_wallet_outlined,
          color: AppColors.white,
          size: 18,
        ),
      ),
    ),
  ),
),
```

In `TransactionHomePage`, pass:

```dart
onOverviewJump: _jumpBackheaderToOverview,
```

Add:

```dart
void _jumpBackheaderToOverview() {
  for (final item in widget.store.backheaderBudgetItems) {
    if (item.overview != null) {
      _setBackheaderActiveItem(item);
      return;
    }
  }
}
```

- [ ] **Step 6: Run tests and commit**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart
```

Commit:

```bash
git add lib/features/transactions/widgets/header_card/category_budget_stage.dart lib/features/transactions/transaction_home_page.dart test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart
git commit -m "feat: update backheader swipe behavior"
```

### Task 7: Header Card Transition And Balance Position

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/header_layout_test.dart`
- Test: `test/transactions/header_card_test.dart`

- [ ] **Step 1: Write failing balance position test**

Update or add in `test/transactions/header_card_test.dart`:

```dart
testWidgets('header balance label and value are shifted down', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TransactionHeaderCard(
          balanceText: '123 Ft',
          onCategoryPressed: () {},
          onExpandPressed: () {},
        ),
      ),
    ),
  );

  expect(TransactionHeaderMetrics.balanceLabelTop, 92);
  expect(TransactionHeaderMetrics.balanceTop, 118);
});
```

- [ ] **Step 2: Write failing expanded transition test**

Add to `test/transactions/header_layout_test.dart`:

```dart
testWidgets('header card animates upward when backheader opens', (tester) async {
  final repository = FakeHomeLimitRepository.withBudgetLimits();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 29));
  await tester.pumpWidget(MaterialApp(home: TransactionHomePage(store: store)));
  await tester.pumpAndSettle();

  final before = tester.getTopLeft(find.byKey(const ValueKey('transaction-header-card'))).dy;
  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pump(const Duration(milliseconds: 80));
  final during = tester.getTopLeft(find.byKey(const ValueKey('transaction-header-card'))).dy;
  await tester.pumpAndSettle();
  final after = tester.getTopLeft(find.byKey(const ValueKey('transaction-header-card'))).dy;

  expect(during, lessThan(before));
  expect(during, greaterThan(after));
});
```

- [ ] **Step 3: Run tests and verify failure**

Run:

```bash
flutter test test/transactions/header_card_test.dart test/transactions/header_layout_test.dart
```

Expected if tests run: FAIL because constants are still 82/108 and the card is remounted in expanded mode.

- [ ] **Step 4: Move balance text down**

In `TransactionHeaderMetrics` change:

```dart
static const balanceLabelTop = 92.0;
static const balanceTop = 118.0;
```

- [ ] **Step 5: Keep header card mounted across expanded/collapsed transition**

In `TransactionHomePage`, replace the expanded/collapsed header branch with a stable keyed wrapper. The target shape is:

```dart
AnimatedPositioned(
  key: const ValueKey('transaction-header-layer'),
  duration: const Duration(milliseconds: 240),
  curve: Curves.easeOutCubic,
  top: _headerExpanded ? -TransactionHeaderMetrics.expandedSlideDistance : 0,
  left: 0,
  right: 0,
  child: _headerExpanded
      ? _buildHeaderCard(
          expenseTheme: expenseTheme,
          visibleFastInfoExtent: 0,
        )
      : HeaderFastInfoSurface(
          visibleFastInfoExtent: visibleFastInfoExtent,
          cardColor: expenseTheme.headerCard,
          fastInfo: FastInfoPanel(
            config: FastInfoConfig.defaults(),
            backgroundColor: Colors.transparent,
          ),
          header: _buildHeaderCard(
            expenseTheme: expenseTheme,
            visibleFastInfoExtent: visibleFastInfoExtent,
            drawSurface: false,
          ),
        ),
),
```

If this creates double translation because `TransactionHeaderCard` also uses `AnimatedSlide(expanded: true)`, then pass `expanded: false` into the card and let `AnimatedPositioned` own the transition. Keep the expand button icon state by adding a separate `expandedForIcon` property only if needed; otherwise preserve the existing `expanded` property and remove the card-internal `AnimatedSlide` offset.

- [ ] **Step 6: Run tests and commit**

Run:

```bash
flutter test test/transactions/header_card_test.dart test/transactions/header_layout_test.dart
```

Commit:

```bash
git add lib/features/transactions/widgets/header_card/transaction_header_metrics.dart lib/features/transactions/widgets/header_card/transaction_header_card.dart lib/features/transactions/transaction_home_page.dart test/transactions/header_card_test.dart test/transactions/header_layout_test.dart
git commit -m "feat: animate header backheader transition"
```

### Task 8: Full Regression And Build Verification

**Files:**
- Modify only files needed for fixes found during verification.

- [ ] **Step 1: Run static checks**

Run:

```bash
git diff --check
flutter analyze
```

Expected locally: `git diff --check` should pass. `flutter analyze` may fail in Termux with the known TLS alignment error; if so, continue to GitHub Actions after pushing.

- [ ] **Step 2: Run full Flutter tests**

Run:

```bash
flutter test
```

Expected locally: may fail before tests with the known TLS alignment error. If it runs, all tests must pass before pushing.

- [ ] **Step 3: Inspect final diff**

Run:

```bash
git status --short
git diff --stat
git diff -- lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart lib/features/transactions/widgets/summary_pill.dart
```

Confirm the diff contains only the approved limit editor/header/backheader/summary work.

- [ ] **Step 4: Commit any verification fixes**

If fixes were needed, commit them:

```bash
git add <fixed-files>
git commit -m "fix: stabilize limit editor redesign"
```

- [ ] **Step 5: Push branch and run GitHub Actions**

Run:

```bash
git push origin feature/backheader-budget-goals
gh workflow run "Exptv2 Android APK Build" --ref feature/backheader-budget-goals
gh run list --workflow "Exptv2 Android APK Build" --branch feature/backheader-budget-goals --limit 1
```

Watch the returned run id:

```bash
gh run watch <run-id> --interval 10
```

Expected: Analyze Dart code, Run Flutter tests, Build debug APK, and Upload debug APK all pass.

- [ ] **Step 6: Download APK artifact**

After a green run:

```bash
mkdir -p /data/data/com.termux/files/usr/tmp/exptv2-limit-editor-redesign-artifacts-<run-id>
gh run download <run-id> --dir /data/data/com.termux/files/usr/tmp/exptv2-limit-editor-redesign-artifacts-<run-id>
```

Report the workflow URL and APK path in the final response.

## Plan Self-Review

- Spec coverage: Tasks 2-4 cover pie removal, partition tap navigation, slider behavior, and editor redesign. Tasks 5-6 cover backheader visuals, release-triggered swipe, reduced offset, and overview jump. Task 1 covers summary gesture swap and double tap. Task 7 covers header transition and balance offset. Task 8 covers verification and APK build.
- Open-marker scan: No task contains unresolved markers or unspecified test instructions.
- Type consistency: New APIs are `SummaryPill.onIntervalSwipe`, `SummaryPill.onPeriodSwipe`, `SummaryPill.onResetToCurrentMonth`, `TransactionStore.resetSummaryToCurrentMonth`, `CategoryLimitPartitionBar.onSegmentTap`, `CategoryBudgetStage.onOverviewJump`, and `LimitSliderRange`. Later tasks use those same names.
