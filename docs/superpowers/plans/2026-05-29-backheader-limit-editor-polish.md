# Backheader Limit Editor Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the header/backheader geometry and replace the current limit editor with an autosaving allocation editor that includes a compact partition bar and interactive pie chart for expense and income sides.

**Architecture:** Add a pure allocation manager that turns overview targets plus category bars into shared partition/pie segments. Keep persistence in `TransactionStore` and `category_limits`; widgets become views over the same allocation data. Make `TransactionHomePage` the synchronization point for the active backheader/editor item so stage swipes, editor arrows, and pie taps all stay in sync.

**Tech Stack:** Flutter/Dart widgets and tests, existing `TransactionStore`, existing native `category_limits` bridge, GitHub Actions Android workflow for final analyze/test/APK verification when local Termux Flutter hits the Dart TLS alignment issue.

---

## File Structure

Create these files:

- `lib/features/transactions/models/limit_allocation_data.dart`: immutable allocation segment model shared by partition bar and pie chart.
- `lib/features/transactions/data/limit_allocation_manager.dart`: pure math for slider maxes, 1000 Ft snapping, allocated/free amounts, used/remaining subsegments, and category availability.
- `lib/features/transactions/widgets/header_card/budget_bar_geometry.dart`: shared constants for backheader frame and active pill sizing so the frame overhang is equal on all sides.
- `lib/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart`: interactive pie chart renderer and gesture handler.
- `test/transactions/limit_allocation_manager_test.dart`: unit tests for allocation math and slider rules.
- `test/transactions/limit_allocation_pie_chart_test.dart`: widget tests for pie rendering, tap, and drag callbacks.

Modify these files:

- `lib/features/transactions/state/transaction_store.dart`: expose active period label and active period income total for all summary windows.
- `lib/features/transactions/transaction_home_page.dart`: store active backheader key, pass controlled active item to `CategoryBudgetStage`, open autosaving editor, keep editor/backheader synchronized.
- `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`: move magnet strip 20 px up and expose the adjusted label position.
- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`: move `Egyenleg` label into magnet zone and keep balance visibility working.
- `lib/features/transactions/widgets/header_card/category_budget_stage.dart`: lower top labels, add period label, use controlled active key, reduce swipe travel and snap bounce, use shared geometry.
- `lib/features/transactions/widgets/header_card/budget_progress_frame.dart`: apply shared geometry and exact inner clipping for border/segments.
- `lib/features/transactions/widgets/header_card/category_budget_bar.dart`: use the same radius/height assumptions as the frame geometry.
- `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`: render compact rounded-square allocation data instead of deriving partitions locally.
- `lib/features/transactions/widgets/header_card/category_limit_slider.dart`: support disabled state, 1000 Ft divisions, and optional trailing end button ownership from editor layout.
- `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`: redesign as autosave card with arrows, avatar, input reset icon, slider, compact partition bar, and pie chart.
- `lib/features/transactions/widgets/header_card/category_limit_editor_sheet.dart`: keep compatibility wrapper but route through the new autosave layout in tests without requiring save/cancel controls.
- `test/transactions/header_layout_test.dart`: header magnet/label layout tests.
- `test/transactions/header_card_test.dart`: update magnet expectations.
- `test/transactions/category_budget_stage_test.dart`: backheader label/period/geometry/swipe tests.
- `test/transactions/transaction_home_limits_test.dart`: autosave, disabled slider, overview max, synchronization, and income-side integration tests.

## Local Verification Note

Local Flutter currently fails on this Termux install before loading app code:

```text
executable's TLS segment is underaligned: alignment is 8, needs to be at least 64 for ARM64 Bionic
```

For every test command below, run it locally first. If it fails with that exact Dart TLS message, continue and use the GitHub Actions workflow after pushing. Do not treat TLS failure as an app test result.

---

### Task 1: Allocation Math Model

**Files:**
- Create: `lib/features/transactions/models/limit_allocation_data.dart`
- Create: `lib/features/transactions/data/limit_allocation_manager.dart`
- Test: `test/transactions/limit_allocation_manager_test.dart`

- [ ] **Step 1: Write failing allocation math tests**

Create `test/transactions/limit_allocation_manager_test.dart`:

```dart
import 'package:exptv2/features/transactions/data/limit_allocation_manager.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allocation splits used remaining and free overview budget', () {
    final food = barFixture(6, 'Food', spent: 25, limit: 50);
    final travel = barFixture(7, 'Travel', spent: 10, limit: 20);

    final data = LimitAllocationManager.build(
      overviewLimit: 100,
      bars: [food, travel],
    );

    expect(data.overviewLimit, 100);
    expect(data.allocatedAmount, 70);
    expect(data.freeAmount, 30);
    expect(data.segments.map((segment) => segment.amount), [25, 25, 10, 10, 30]);
    expect(data.segments.map((segment) => segment.kind.name), [
      'used',
      'remaining',
      'used',
      'remaining',
      'free',
    ]);
    expect(data.segments.first.targetId, 6);
    expect(data.segments.last.targetId, isNull);
  });

  test('available category max includes the active category current allocation', () {
    final food = barFixture(6, 'Food', spent: 25, limit: 50);
    final travel = barFixture(7, 'Travel', spent: 10, limit: 50);

    expect(
      LimitAllocationManager.categorySliderMax(
        overviewLimit: 100,
        bars: [food, travel],
        activeBar: food,
      ),
      50,
    );
  });

  test('new category slider disables when overview allocation is full', () {
    final food = barFixture(6, 'Food', spent: 25, limit: 100);
    final travel = barFixture(7, 'Travel', spent: 0, limit: 0);

    expect(
      LimitAllocationManager.categorySliderEnabled(
        overviewLimit: 100,
        bars: [food, travel],
        activeBar: travel,
      ),
      isFalse,
    );
  });

  test('slider snapping uses 1000 HUF steps without changing manual values', () {
    expect(LimitAllocationManager.snapSliderAmount(1499), 1000);
    expect(LimitAllocationManager.snapSliderAmount(1500), 2000);
    expect(LimitAllocationManager.sliderDivisions(12500), 13);
  });
}

CategoryBudgetBarData barFixture(
  int id,
  String title, {
  required double spent,
  required double limit,
}) {
  final category = TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': title,
    'type': 'kiadás',
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#0ea5e9',
    'hasLimit': limit > 0,
    'limitAmount': limit,
    'alertActive': false,
    'isCustomIcon': true,
  });
  return CategoryBudgetBarData(
    key: 'category-$id',
    targetType: LimitTargetType.category,
    targetId: id,
    transactionType: category.normalizedType,
    window: LimitWindow.monthly,
    periodKey: '2026-05',
    title: title,
    spent: spent,
    hasLimit: limit > 0,
    limitAmount: limit,
    alertActive: false,
    color: colorFor(id),
    iconSlot: category.iconSlot,
    category: category,
    sourceLimit: null,
  );
}

Color colorFor(int id) => switch (id) {
  6 => const Color(0xfffacc15),
  7 => const Color(0xff38bdf8),
  _ => const Color(0xff94a3b8),
};
```

- [ ] **Step 2: Run the failing allocation test**

Run:

```bash
flutter test test/transactions/limit_allocation_manager_test.dart
```

Expected in a working Flutter environment: FAIL because `LimitAllocationManager` and `LimitAllocationData` do not exist.

- [ ] **Step 3: Add allocation data models**

Create `lib/features/transactions/models/limit_allocation_data.dart`:

```dart
import 'package:flutter/material.dart';

enum LimitAllocationSegmentKind { used, remaining, free }

class LimitAllocationSegment {
  const LimitAllocationSegment({
    required this.kind,
    required this.amount,
    required this.fraction,
    required this.color,
    this.targetId,
    this.label,
  });

  final LimitAllocationSegmentKind kind;
  final double amount;
  final double fraction;
  final Color color;
  final int? targetId;
  final String? label;
}

class LimitAllocationData {
  const LimitAllocationData({
    required this.overviewLimit,
    required this.allocatedAmount,
    required this.freeAmount,
    required this.segments,
  });

  final double overviewLimit;
  final double allocatedAmount;
  final double freeAmount;
  final List<LimitAllocationSegment> segments;

  bool get hasOverviewLimit => overviewLimit > 0;
  bool get hasFreeSpace => freeAmount > 0;
}
```

- [ ] **Step 4: Add allocation manager**

Create `lib/features/transactions/data/limit_allocation_manager.dart`:

```dart
import 'dart:math' as math;

import '../../../../core/theme/app_colors.dart';
import '../models/category_budget_bar_data.dart';
import '../models/limit_allocation_data.dart';

class LimitAllocationManager {
  static const sliderStep = 1000.0;

  static LimitAllocationData build({
    required double overviewLimit,
    required List<CategoryBudgetBarData> bars,
  }) {
    if (overviewLimit <= 0) {
      return const LimitAllocationData(
        overviewLimit: 0,
        allocatedAmount: 0,
        freeAmount: 0,
        segments: [],
      );
    }

    final visibleBars = bars.where((bar) => bar.limitAmount > 0).toList();
    final segments = <LimitAllocationSegment>[];
    var allocated = 0.0;
    for (final bar in visibleBars) {
      final limit = bar.limitAmount.clamp(0.0, overviewLimit).toDouble();
      final used = math.min(bar.spent, limit).clamp(0.0, limit).toDouble();
      final remaining = (limit - used).clamp(0.0, limit).toDouble();
      allocated += limit;
      if (used > 0) {
        segments.add(
          LimitAllocationSegment(
            kind: LimitAllocationSegmentKind.used,
            amount: used,
            fraction: used / overviewLimit,
            color: bar.color,
            targetId: bar.targetId,
            label: bar.title,
          ),
        );
      }
      if (remaining > 0) {
        segments.add(
          LimitAllocationSegment(
            kind: LimitAllocationSegmentKind.remaining,
            amount: remaining,
            fraction: remaining / overviewLimit,
            color: bar.color.withValues(alpha: 0.70),
            targetId: bar.targetId,
            label: bar.title,
          ),
        );
      }
    }
    final free = (overviewLimit - allocated).clamp(0.0, overviewLimit).toDouble();
    if (free > 0) {
      segments.add(
        LimitAllocationSegment(
          kind: LimitAllocationSegmentKind.free,
          amount: free,
          fraction: free / overviewLimit,
          color: AppColors.gray200,
        ),
      );
    }
    return LimitAllocationData(
      overviewLimit: overviewLimit,
      allocatedAmount: allocated.clamp(0.0, overviewLimit).toDouble(),
      freeAmount: free,
      segments: segments,
    );
  }

  static double categorySliderMax({
    required double overviewLimit,
    required List<CategoryBudgetBarData> bars,
    required CategoryBudgetBarData activeBar,
  }) {
    if (overviewLimit <= 0) return math.max(activeBar.limitAmount, sliderStep);
    final others = bars
        .where((bar) => !_sameTarget(bar, activeBar))
        .where((bar) => bar.limitAmount > 0)
        .fold<double>(0, (sum, bar) => sum + bar.limitAmount);
    return (overviewLimit - others)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  static bool categorySliderEnabled({
    required double overviewLimit,
    required List<CategoryBudgetBarData> bars,
    required CategoryBudgetBarData activeBar,
  }) {
    if (overviewLimit <= 0) return true;
    if (activeBar.limitAmount > 0) return true;
    return categorySliderMax(
          overviewLimit: overviewLimit,
          bars: bars,
          activeBar: activeBar,
        ) >
        0;
  }

  static double snapSliderAmount(double amount) {
    if (amount <= 0) return 0;
    return (amount / sliderStep).round() * sliderStep;
  }

  static int sliderDivisions(double max) {
    if (max <= 0) return 1;
    return math.max(1, (max / sliderStep).ceil()).toInt();
  }

  static bool _sameTarget(CategoryBudgetBarData left, CategoryBudgetBarData right) {
    return left.targetType == right.targetType &&
        left.targetId == right.targetId &&
        left.transactionType == right.transactionType &&
        left.window == right.window &&
        left.periodKey == right.periodKey;
  }
}
```

- [ ] **Step 5: Run allocation tests**

Run:

```bash
flutter test test/transactions/limit_allocation_manager_test.dart
```

Expected: PASS in a working Flutter environment.

- [ ] **Step 6: Commit allocation math**

```bash
git add lib/features/transactions/models/limit_allocation_data.dart \
  lib/features/transactions/data/limit_allocation_manager.dart \
  test/transactions/limit_allocation_manager_test.dart
git commit -m "feat: add limit allocation math"
```

---

### Task 2: Header And Backheader Geometry Polish

**Files:**
- Create: `lib/features/transactions/widgets/header_card/budget_bar_geometry.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_progress_frame.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_bar.dart`
- Test: `test/transactions/header_layout_test.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Add failing header/backheader layout tests**

Append to `test/transactions/header_layout_test.dart`:

```dart
testWidgets('magnet strip moves up and balance label sits in magnet zone', (tester) async {
  final store = TransactionStore(HeaderLayoutRepository());
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 780,
          child: TransactionHomePage(store: store),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final magnet = tester.getRect(find.byKey(const ValueKey('magnet-strip-fade')));
  final balanceLabel = tester.getRect(find.text('Egyenleg'));

  expect(magnet.top, moreOrLessEquals(45, epsilon: 0.1));
  expect(balanceLabel.center.dy, greaterThanOrEqualTo(magnet.top));
  expect(balanceLabel.center.dy, lessThanOrEqualTo(magnet.bottom));
});
```

Append to `test/transactions/category_budget_stage_test.dart`:

```dart
testWidgets('stage lowers labels and shows period label bottom-left', (tester) async {
  final bars = [barFixture(6, 'Food', 100, 150)];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 260,
          child: CategoryBudgetStage(
            items: bars.map(BackheaderBudgetItem.category).toList(),
            categoryBars: bars,
            periodLabel: 'Május 2026',
            onItemTap: (_) {},
          ),
        ),
      ),
    ),
  );

  final titleTop = tester.getRect(find.byKey(const ValueKey('backheader-active-title'))).top;
  final periodRect = tester.getRect(find.byKey(const ValueKey('backheader-period-label')));
  expect(titleTop, greaterThanOrEqualTo(42));
  expect(periodRect.left, lessThan(40));
  expect(periodRect.bottom, lessThanOrEqualTo(172));
});

testWidgets('progress frame overhang is equal around active bar', (tester) async {
  final bars = [barFixture(6, 'Food', 50, 0)];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 260,
          child: CategoryBudgetStage(
            items: [
              BackheaderBudgetItem.overview(
                overviewFixture(BudgetGoalKind.expenseBudget, 50, 100),
              ),
              ...bars.map(BackheaderBudgetItem.category),
            ],
            categoryBars: bars,
            periodLabel: 'Május 2026',
            onItemTap: (_) {},
          ),
        ),
      ),
    ),
  );

  final frame = tester.getRect(find.byKey(const ValueKey('budget-progress-frame')));
  final bar = tester.getRect(find.byKey(const ValueKey('category-budget-bar')));
  expect(bar.center, frame.center);
  expect(bar.left - frame.left, moreOrLessEquals(frame.right - bar.right, epsilon: 0.1));
  expect(bar.top - frame.top, moreOrLessEquals(frame.bottom - bar.bottom, epsilon: 0.1));
});
```

- [ ] **Step 2: Run failing layout tests**

Run:

```bash
flutter test test/transactions/header_layout_test.dart test/transactions/category_budget_stage_test.dart
```

Expected: FAIL because `periodLabel` and equal frame geometry are not implemented and magnet top is still 65.

- [ ] **Step 3: Add shared bar geometry constants**

Create `lib/features/transactions/widgets/header_card/budget_bar_geometry.dart`:

```dart
class BudgetBarGeometry {
  const BudgetBarGeometry._();

  static const frameTop = 70.0;
  static const frameHorizontalInset = 34.0;
  static const frameHeight = 66.0;
  static const barTop = 76.0;
  static const barHorizontalInset = 40.0;
  static const barHeight = 54.0;
  static const overhang = 6.0;
  static const radius = barHeight / 2;
  static const frameRadius = frameHeight / 2;
}
```

- [ ] **Step 4: Update header metrics**

In `transaction_header_metrics.dart`, change these constants:

```dart
static const magnetTop = 45.0;
static const balanceLabelTop = 82.0;
static const balanceTop = 108.0;
```

Keep `magnetHeight = 157.5`.

- [ ] **Step 5: Move `Egyenleg` label in header card**

In `TransactionHeaderCard`, replace the balance `Column` with separate positioned label and value blocks:

```dart
Positioned(
  top: TransactionHeaderMetrics.balanceLabelTop,
  left: 30,
  child: AnimatedOpacity(
    duration: const Duration(milliseconds: 180),
    opacity: expanded ? 0 : 1,
    child: const Text(
      'Egyenleg',
      style: TextStyle(
        fontSize: 14,
        color: AppColors.gray600,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
),
Positioned(
  top: TransactionHeaderMetrics.balanceTop,
  left: 30,
  right: 90,
  child: AnimatedOpacity(
    duration: const Duration(milliseconds: 180),
    opacity: expanded ? 0 : 1,
    child: Row(
      children: [
        Flexible(
          child: Text(
            visibleBalanceText,
            key: const ValueKey('header-balance-text'),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.gray800,
            ),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          key: const ValueKey('header-balance-visibility-button'),
          onPressed: onBalanceVisibilityPressed,
          icon: Icon(
            balanceHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.gray800,
            size: 20,
          ),
          tooltip: balanceHidden ? 'Egyenleg megjelenítése' : 'Egyenleg elrejtése',
          splashRadius: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 6: Expose period label from store**

In `TransactionStore`, add:

```dart
String get activePeriodLabel {
  final reference = _periodReferenceDate;
  return switch (_summaryWindow) {
    SummaryWindow.allTime => 'Sum',
    SummaryWindow.yearly => reference.year.toString(),
    SummaryWindow.monthly => '${_hungarianMonth(reference.month)} ${reference.year}',
  };
}
```

- [ ] **Step 7: Pass period label to stage**

In `TransactionHomePage`, update the stage call:

```dart
CategoryBudgetStage(
  items: widget.store.backheaderBudgetItems,
  categoryBars: widget.store.categoryBudgetBars,
  periodLabel: widget.store.activePeriodLabel,
  activeKey: _backheaderActiveKey,
  onActiveItemChanged: _setBackheaderActiveItem,
  onItemTap: _openBudgetTargetEditor,
),
```

Add state fields and helper:

```dart
String? _backheaderActiveKey;

void _setBackheaderActiveItem(BackheaderBudgetItem item) {
  setState(() => _backheaderActiveKey = item.key);
}
```

- [ ] **Step 8: Update `CategoryBudgetStage` API and layout**

Add constructor fields:

```dart
this.periodLabel,
this.activeKey,
this.onActiveItemChanged,
```

Add fields:

```dart
final String? periodLabel;
final String? activeKey;
final ValueChanged<BackheaderBudgetItem>? onActiveItemChanged;
```

In `didUpdateWidget`, sync controlled key:

```dart
final activeKey = widget.activeKey;
if (activeKey != null) {
  final nextIndex = _items.indexWhere((item) => item.key == activeKey);
  if (nextIndex >= 0) _index = nextIndex;
}
```

Move title row to `top: 44`. Render period label:

```dart
if (widget.periodLabel != null)
  Positioned(
    left: 24,
    bottom: 12,
    child: Text(
      widget.periodLabel!,
      key: const ValueKey('backheader-period-label'),
      style: const TextStyle(
        color: AppColors.gray600,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
```

Use `BudgetBarGeometry` for frame and bar positions:

```dart
Positioned(
  top: BudgetBarGeometry.frameTop,
  left: BudgetBarGeometry.frameHorizontalInset,
  right: BudgetBarGeometry.frameHorizontalInset,
  child: BudgetProgressFrame(..., height: BudgetBarGeometry.frameHeight),
),
Positioned(
  top: BudgetBarGeometry.barTop,
  left: BudgetBarGeometry.barHorizontalInset,
  right: BudgetBarGeometry.barHorizontalInset,
  child: ... height: BudgetBarGeometry.barHeight,
),
```

Reduce swipe values:

```dart
if (nextDx.abs() < 56 || _items.length < 2) return;
_dragDx = swipedLeft ? settleDistance * 0.18 : -settleDistance * 0.18;
await _animateDragTo(
  0,
  curve: Curves.easeOutBack,
  duration: const Duration(milliseconds: 240),
);
```

After index changes, call:

```dart
widget.onActiveItemChanged?.call(_items[_index]);
```

- [ ] **Step 9: Make frame clipping exact**

In `BudgetProgressFrame`, keep outer `Container` border but add inner padding:

```dart
const borderWidth = 2.0;
const segmentInset = 3.0;
...
padding: const EdgeInsets.all(borderWidth + segmentInset),
child: ClipRRect(
  borderRadius: BorderRadius.circular((height / 2) - borderWidth - segmentInset),
  child: LayoutBuilder(...),
),
```

Do not place segment `Positioned` children directly under the bordered container.

- [ ] **Step 10: Run layout tests**

Run:

```bash
flutter test test/transactions/header_layout_test.dart test/transactions/category_budget_stage_test.dart
```

Expected: PASS in a working Flutter environment.

- [ ] **Step 11: Commit layout polish**

```bash
git add lib/features/transactions/widgets/header_card/budget_bar_geometry.dart \
  lib/features/transactions/widgets/header_card/transaction_header_metrics.dart \
  lib/features/transactions/widgets/header_card/transaction_header_card.dart \
  lib/features/transactions/state/transaction_store.dart \
  lib/features/transactions/widgets/header_card/category_budget_stage.dart \
  lib/features/transactions/widgets/header_card/budget_progress_frame.dart \
  lib/features/transactions/widgets/header_card/category_budget_bar.dart \
  test/transactions/header_layout_test.dart \
  test/transactions/category_budget_stage_test.dart
git commit -m "feat: polish backheader geometry"
```

---

### Task 3: Autosave Limit Editor Layout

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_limit_editor_sheet.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_limit_slider.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Replace editor tests with autosave expectations**

In `test/transactions/transaction_home_limits_test.dart`, update the overview test body after opening the sheet:

```dart
expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
expect(find.byKey(const ValueKey('limit-cancel-button')), findsNothing);
expect(find.byKey(const ValueKey('limit-alert-toggle')), findsNothing);
expect(find.byKey(const ValueKey('limit-card-avatar')), findsOneWidget);
expect(find.byKey(const ValueKey('limit-reset-inline-button')), findsOneWidget);

await tester.enterText(find.byKey(const ValueKey('limit-amount-input')), '300000');
await tester.pump(const Duration(milliseconds: 500));
await tester.pumpAndSettle();

expect(repository.savedLimits.single['targetType'], 'overview');
expect(repository.savedLimits.single['limitAmount'], 300000);
```

Add a new test:

```dart
testWidgets('budget end button saves period income as overview limit', (tester) async {
  final repository = FakeHomeLimitRepository();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 17));
  await pumpExpandedMonthlyHome(tester, store);

  await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('limit-slider-end-button')));
  await tester.pumpAndSettle();

  expect(repository.savedLimits.single['targetType'], 'overview');
  expect(repository.savedLimits.single['limitAmount'], 1000);
});
```

Make `FakeHomeLimitRepository.transactions` include an income record:

```dart
TransactionRecord.fromMap({
  'id': 2,
  'date': '2026.05.01',
  'time': '09:00',
  'merchant': 'Salary',
  'amount': 1000,
  'userAssignedName': null,
  'transactionCategoryID': 5,
}),
```

And add category 5 as income if missing.

- [ ] **Step 2: Run failing autosave tests**

Run:

```bash
flutter test test/transactions/transaction_home_limits_test.dart test/transactions/category_budget_stage_test.dart
```

Expected: FAIL because editor still has save/cancel/bell and does not autosave.

- [ ] **Step 3: Update slider widget**

In `CategoryLimitSlider`, add:

```dart
this.enabled = true,
this.onChangeEnd,
```

Fields:

```dart
final bool enabled;
final ValueChanged<double>? onChangeEnd;
```

Update `Slider`:

```dart
onChanged: enabled ? onChanged : null,
onChangeEnd: enabled ? onChangeEnd : null,
```

Use gray thumb/track when disabled:

```dart
final effectiveColor = enabled ? activeColor : AppColors.gray400;
```

- [ ] **Step 4: Rewrite editor layout as autosave card**

In `BudgetTargetEditorSheet`, replace the current `Column` children with:

```dart
_BudgetLimitCard(
  item: _activeItem,
  amountController: _controller,
  activeColor: _activeColor,
  sliderValue: _sliderValue,
  sliderMax: _sliderMax,
  sliderEnabled: _sliderEnabled,
  sliderDivisions: LimitAllocationManager.sliderDivisions(_sliderMax),
  onPrevious: _selectPrevious,
  onNext: _selectNext,
  onReset: _resetLimit,
  onSliderChanged: _setAmountFromSlider,
  onSliderChangeEnd: _saveSliderAmount,
  onInputChanged: _scheduleInputSave,
  onSetToMax: _setOverviewToMax,
  showSetToMax: _activeItem.overview != null,
  partitionBar: _buildPartitionBar(),
  pieChart: _buildPieChart(),
)
```

Add local active key state:

```dart
late String _activeKey;
Timer? _saveDebounce;

BackheaderBudgetItem get _activeItem {
  return widget.items.firstWhere(
    (item) => item.key == _activeKey,
    orElse: () => widget.item,
  );
}
```

Add methods:

```dart
void _scheduleInputSave(String _) {
  _saveDebounce?.cancel();
  _saveDebounce = Timer(const Duration(milliseconds: 400), () {
    _saveAmount(_amount);
  });
}

void _resetLimit() {
  _controller.clear();
  _saveAmount(0);
}

void _saveSliderAmount(double amount) {
  final snapped = LimitAllocationManager.snapSliderAmount(amount);
  _setControllerAmount(snapped);
  _saveAmount(snapped);
}

void _setOverviewToMax() {
  final max = _sliderMax;
  _setControllerAmount(max);
  _saveAmount(max);
}
```

Remove `_alertActive` use from production layout and always save `alertActive: false`.

- [ ] **Step 5: Add `_BudgetLimitCard` private widget**

Add below `BudgetTargetEditorSheet`:

```dart
class _BudgetLimitCard extends StatelessWidget {
  const _BudgetLimitCard({
    required this.item,
    required this.amountController,
    required this.activeColor,
    required this.sliderValue,
    required this.sliderMax,
    required this.sliderEnabled,
    required this.sliderDivisions,
    required this.onPrevious,
    required this.onNext,
    required this.onReset,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
    required this.onInputChanged,
    required this.onSetToMax,
    required this.showSetToMax,
    required this.partitionBar,
    required this.pieChart,
  });

  final BackheaderBudgetItem item;
  final TextEditingController amountController;
  final Color activeColor;
  final double sliderValue;
  final double sliderMax;
  final bool sliderEnabled;
  final int sliderDivisions;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReset;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<double> onSliderChangeEnd;
  final ValueChanged<String> onInputChanged;
  final VoidCallback onSetToMax;
  final bool showSetToMax;
  final Widget partitionBar;
  final Widget pieChart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(key: const ValueKey('limit-card-previous'), onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
            Expanded(child: Center(child: _LimitAvatar(item: item, color: activeColor))),
            IconButton(key: const ValueKey('limit-card-next'), onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 8),
        Text(item.title, key: const ValueKey('limit-card-title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray800)),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('limit-amount-input'),
          controller: amountController,
          keyboardType: TextInputType.number,
          onChanged: onInputChanged,
          decoration: transactionFieldDecoration('Limit').copyWith(
            suffixText: 'Ft',
            suffixIcon: IconButton(
              key: const ValueKey('limit-reset-inline-button'),
              onPressed: onReset,
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Reset',
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CategoryLimitSlider(
                value: sliderValue,
                max: sliderMax,
                divisions: sliderDivisions,
                activeColor: activeColor,
                enabled: sliderEnabled,
                onChanged: onSliderChanged,
                onChangeEnd: onSliderChangeEnd,
              ),
            ),
            if (showSetToMax)
              IconButton(
                key: const ValueKey('limit-slider-end-button'),
                onPressed: onSetToMax,
                icon: const Icon(Icons.last_page),
                tooltip: 'Max',
              ),
          ],
        ),
        const SizedBox(height: 8),
        partitionBar,
        const SizedBox(height: 14),
        pieChart,
      ],
    );
  }
}
```

Add `_LimitAvatar` that uses category icon for category targets and Material icons for overview targets.

- [ ] **Step 6: Update compatibility wrapper tests**

In `category_budget_stage_test.dart`, update old editor expectations:

```dart
expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);
await tester.enterText(find.byKey(const ValueKey('limit-amount-input')), '250');
await tester.pump(const Duration(milliseconds: 500));
expect(savedAmount, 250);
await tester.tap(find.byKey(const ValueKey('limit-reset-inline-button')));
await tester.pumpAndSettle();
expect(savedAmount, 0);
```

- [ ] **Step 7: Run autosave tests**

Run:

```bash
flutter test test/transactions/transaction_home_limits_test.dart test/transactions/category_budget_stage_test.dart
```

Expected: PASS in a working Flutter environment.

- [ ] **Step 8: Commit autosave editor**

```bash
git add lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart \
  lib/features/transactions/widgets/header_card/category_limit_editor_sheet.dart \
  lib/features/transactions/widgets/header_card/category_limit_slider.dart \
  test/transactions/transaction_home_limits_test.dart \
  test/transactions/category_budget_stage_test.dart
git commit -m "feat: add autosaving limit editor card"
```

---

### Task 4: Compact Partition Bar Rendering

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Test: `test/transactions/category_budget_stage_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Add compact partition tests**

Append to `category_budget_stage_test.dart`:

```dart
testWidgets('partition bar renders compact rounded-square allocation', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CategoryLimitPartitionBar(
          height: 29.4,
          allocation: LimitAllocationManager.build(
            overviewLimit: 100,
            bars: [barFixture(6, 'Food', 25, 50)],
          ),
        ),
      ),
    ),
  );

  final bar = tester.getRect(find.byKey(const ValueKey('category-limit-partition-bar')));
  expect(bar.height, moreOrLessEquals(29.4, epsilon: 0.1));
  expect(find.byKey(const ValueKey('category-limit-partition-segment-0')), findsOneWidget);
  expect(find.byKey(const ValueKey('category-limit-partition-segment-1')), findsOneWidget);
  expect(find.byKey(const ValueKey('category-limit-partition-segment-2')), findsOneWidget);
});
```

Add imports for `LimitAllocationManager` and `CategoryLimitPartitionBar`.

- [ ] **Step 2: Run failing partition test**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart
```

Expected: FAIL because `CategoryLimitPartitionBar` does not accept `allocation`.

- [ ] **Step 3: Update `CategoryLimitPartitionBar` API**

Add parameter:

```dart
this.allocation,
```

Field:

```dart
final LimitAllocationData? allocation;
```

At build start:

```dart
final allocation = this.allocation;
if (allocation != null) {
  return _AllocationPartitionBar(allocation: allocation, height: height);
}
```

Add private widget:

```dart
class _AllocationPartitionBar extends StatelessWidget {
  const _AllocationPartitionBar({required this.allocation, required this.height});

  final LimitAllocationData allocation;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('category-limit-partition-bar'),
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var left = 0.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < allocation.segments.length; i += 1)
                () {
                  final segment = allocation.segments[i];
                  final width = constraints.maxWidth * segment.fraction;
                  final child = Positioned(
                    key: ValueKey('category-limit-partition-segment-$i'),
                    left: left,
                    top: 0,
                    width: width,
                    bottom: 0,
                    child: ColoredBox(color: segment.color),
                  );
                  left += width;
                  return child;
                }(),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Use allocation from editor**

In `BudgetTargetEditorSheet`, replace direct old partition call with:

```dart
final allocation = LimitAllocationManager.build(
  overviewLimit: _overviewLimitAmount ?? 0,
  bars: _partitionBars,
);
CategoryLimitPartitionBar(
  height: 29.4,
  allocation: allocation,
)
```

- [ ] **Step 5: Run partition/editor tests**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart test/transactions/transaction_home_limits_test.dart
```

Expected: PASS in a working Flutter environment.

- [ ] **Step 6: Commit partition bar**

```bash
git add lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart \
  lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart \
  test/transactions/category_budget_stage_test.dart \
  test/transactions/transaction_home_limits_test.dart
git commit -m "feat: render compact allocation partition bar"
```

---

### Task 5: Interactive Pie Chart

**Files:**
- Create: `lib/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Test: `test/transactions/limit_allocation_pie_chart_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Write failing pie chart tests**

Create `test/transactions/limit_allocation_pie_chart_test.dart`:

```dart
import 'package:exptv2/features/transactions/data/limit_allocation_manager.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pie chart renders allocation and taps category slice', (tester) async {
    int? tappedTarget;
    final bars = [barFixture(6, 'Food', spent: 25, limit: 50)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LimitAllocationPieChart(
            allocation: LimitAllocationManager.build(overviewLimit: 100, bars: bars),
            onSliceTap: (targetId) => tappedTarget = targetId,
            onSliceAmountChanged: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('limit-allocation-pie-chart')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('limit-allocation-pie-chart')));
    expect(tappedTarget, 6);
  });

  testWidgets('pie chart horizontal drag reports snapped category amount', (tester) async {
    final changes = <double>[];
    final bars = [barFixture(6, 'Food', spent: 25, limit: 50)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LimitAllocationPieChart(
            allocation: LimitAllocationManager.build(overviewLimit: 100000, bars: bars),
            onSliceTap: (_) {},
            onSliceAmountChanged: (_, amount) => changes.add(amount),
          ),
        ),
      ),
    );

    await tester.drag(find.byKey(const ValueKey('limit-allocation-pie-chart')), const Offset(45, 0));
    await tester.pump();
    expect(changes, isNotEmpty);
    expect(changes.last % 1000, 0);
  });
}

CategoryBudgetBarData barFixture(
  int id,
  String title, {
  required double spent,
  required double limit,
}) {
  final category = TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': title,
    'type': 'kiadás',
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#0ea5e9',
    'hasLimit': limit > 0,
    'limitAmount': limit,
    'alertActive': false,
    'isCustomIcon': true,
  });
  return CategoryBudgetBarData(
    key: 'category-$id',
    targetType: LimitTargetType.category,
    targetId: id,
    transactionType: category.normalizedType,
    window: LimitWindow.monthly,
    periodKey: '2026-05',
    title: title,
    spent: spent,
    hasLimit: limit > 0,
    limitAmount: limit,
    alertActive: false,
    color: const Color(0xfffacc15),
    iconSlot: category.iconSlot,
    category: category,
    sourceLimit: null,
  );
}
```

- [ ] **Step 2: Run failing pie chart tests**

Run:

```bash
flutter test test/transactions/limit_allocation_pie_chart_test.dart
```

Expected: FAIL because widget does not exist.

- [ ] **Step 3: Implement pie chart widget**

Create `lib/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/limit_allocation_manager.dart';
import '../../models/limit_allocation_data.dart';

class LimitAllocationPieChart extends StatelessWidget {
  const LimitAllocationPieChart({
    super.key,
    required this.allocation,
    required this.onSliceTap,
    required this.onSliceAmountChanged,
    this.size = 180,
  });

  final LimitAllocationData allocation;
  final ValueChanged<int> onSliceTap;
  final void Function(int targetId, double amount) onSliceAmountChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('limit-allocation-pie-chart'),
      onTapUp: (details) {
        final targetId = _targetAt(details.localPosition, Size.square(size));
        if (targetId != null) onSliceTap(targetId);
      },
      onHorizontalDragUpdate: (details) {
        final targetId = _firstTargetId;
        if (targetId == null || allocation.overviewLimit <= 0) return;
        final delta = details.delta.dx * 1000;
        final current = _amountForTarget(targetId);
        final next = LimitAllocationManager.snapSliderAmount(
          (current + delta).clamp(0.0, allocation.overviewLimit).toDouble(),
        );
        onSliceAmountChanged(targetId, next);
      },
      child: CustomPaint(
        size: Size.square(size),
        painter: _LimitAllocationPiePainter(allocation),
      ),
    );
  }

  int? get _firstTargetId {
    for (final segment in allocation.segments) {
      if (segment.targetId != null) return segment.targetId;
    }
    return null;
  }

  double _amountForTarget(int targetId) {
    return allocation.segments
        .where((segment) => segment.targetId == targetId)
        .fold<double>(0, (sum, segment) => sum + segment.amount);
  }

  int? _targetAt(Offset position, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = position - center;
    if (vector.distance > size.shortestSide / 2) return null;
    var angle = math.atan2(vector.dy, vector.dx);
    if (angle < -math.pi / 2) angle += math.pi * 2;
    final normalized = (angle + math.pi / 2) / (math.pi * 2);
    var cursor = 0.0;
    for (final segment in allocation.segments) {
      final next = cursor + segment.fraction;
      if (normalized >= cursor && normalized <= next) return segment.targetId;
      cursor = next;
    }
    return null;
  }
}

class _LimitAllocationPiePainter extends CustomPainter {
  const _LimitAllocationPiePainter(this.allocation);

  final LimitAllocationData allocation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    var start = -math.pi / 2;
    if (allocation.segments.isEmpty) {
      paint.color = AppColors.gray200;
      canvas.drawCircle(rect.center, size.shortestSide / 2, paint);
      return;
    }
    for (final segment in allocation.segments) {
      final sweep = math.pi * 2 * segment.fraction;
      paint.color = segment.color;
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.white;
    canvas.drawCircle(rect.center, size.shortestSide / 2 - 1, paint);
  }

  @override
  bool shouldRepaint(covariant _LimitAllocationPiePainter oldDelegate) {
    return oldDelegate.allocation != allocation;
  }
}
```

- [ ] **Step 4: Wire pie chart into editor**

In `BudgetTargetEditorSheet`, implement `_buildPieChart()`:

```dart
Widget _buildPieChart() {
  final allocation = LimitAllocationManager.build(
    overviewLimit: _overviewLimitAmount ?? 0,
    bars: _partitionBars,
  );
  if (_activeItem.overview?.kind == BudgetGoalKind.savingGoal) {
    return const SizedBox.shrink();
  }
  return LimitAllocationPieChart(
    allocation: allocation,
    onSliceTap: _selectCategoryByTargetId,
    onSliceAmountChanged: _saveCategoryAmountByTargetId,
  );
}
```

Add helpers:

```dart
void _selectCategoryByTargetId(int targetId) {
  final match = widget.items.firstWhere(
    (item) => item.category?.targetId == targetId,
    orElse: () => _activeItem,
  );
  _selectItem(match);
}

void _saveCategoryAmountByTargetId(int targetId, double amount) {
  CategoryBudgetBarData? match;
  for (final bar in widget.categoryBars) {
    if (bar.targetId == targetId) {
      match = bar;
      break;
    }
  }
  if (match == null) return;
  widget.onSaveCategory(match, limitAmount: amount, alertActive: false);
}
```

- [ ] **Step 5: Add home integration pie test**

In `transaction_home_limits_test.dart`, add:

```dart
testWidgets('pie tap selects category and syncs backheader', (tester) async {
  final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 17));
  await pumpExpandedMonthlyHome(tester, store);

  await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('limit-allocation-pie-chart')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('limit-card-title')), findsOneWidget);
  expect(find.text('Food'), findsWidgets);
});
```

Add this named constructor to `FakeHomeLimitRepository`:

```dart
FakeHomeLimitRepository.withBudgetAndCategoryLimits() {
  categories.add(
    TransactionCategory.fromMap({
      'transactionCategoryID': 7,
      'name': 'Travel',
      'type': 'kiadás',
      'colorSlot': 8,
      'iconSlot': 3,
      'backgroundColor': '#38bdf8',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
  );
  limits = [
    CategoryLimit.fromMap({
      'id': 10,
      'targetType': 'overview',
      'targetId': 0,
      'transactionType': 'expense',
      'window': 'monthly',
      'periodKey': '2026-05',
      'hasLimit': true,
      'limitAmount': 1000,
      'alertActive': false,
      'createdAt': 0,
      'updatedAt': 1,
    }),
    CategoryLimit.fromMap({
      'id': 11,
      'targetType': 'category',
      'targetId': 6,
      'transactionType': 'expense',
      'window': 'monthly',
      'periodKey': '2026-05',
      'hasLimit': true,
      'limitAmount': 250,
      'alertActive': false,
      'createdAt': 0,
      'updatedAt': 1,
    }),
  ];
}
```

Because the current fake uses `final categories`, keep the default constructor implicit and mutate the existing list in the named constructor body.

- [ ] **Step 6: Run pie tests**

Run:

```bash
flutter test test/transactions/limit_allocation_pie_chart_test.dart test/transactions/transaction_home_limits_test.dart
```

Expected: PASS in a working Flutter environment.

- [ ] **Step 7: Commit pie chart**

```bash
git add lib/features/transactions/widgets/header_card/limit_allocation_pie_chart.dart \
  lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart \
  test/transactions/limit_allocation_pie_chart_test.dart \
  test/transactions/transaction_home_limits_test.dart
git commit -m "feat: add interactive allocation pie chart"
```

---

### Task 6: Backheader And Editor Synchronization

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Add synchronization tests**

In `transaction_home_limits_test.dart`, add:

```dart
testWidgets('editor arrows sync active backheader bar', (tester) async {
  final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 17));
  await pumpExpandedMonthlyHome(tester, store);

  await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('limit-card-next')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('backheader-active-title')), findsOneWidget);
  expect(find.text('Food'), findsWidgets);
});
```

- [ ] **Step 2: Run failing synchronization tests**

Run:

```bash
flutter test test/transactions/transaction_home_limits_test.dart
```

Expected: FAIL until the sheet calls back to the home page and the stage accepts controlled active key.

- [ ] **Step 3: Extend editor constructor**

In `BudgetTargetEditorSheet`, add:

```dart
required this.items,
required this.onActiveItemChanged,
```

Fields:

```dart
final List<BackheaderBudgetItem> items;
final ValueChanged<BackheaderBudgetItem> onActiveItemChanged;
```

Use `items` for previous/next and pie tap.

- [ ] **Step 4: Implement `_selectItem`**

In editor state:

```dart
void _selectItem(BackheaderBudgetItem item) {
  setState(() {
    _activeKey = item.key;
    _setControllerAmount(_limitAmountFor(item));
  });
  widget.onActiveItemChanged(item);
}
```

- [ ] **Step 5: Pass callback from home**

In `_openBudgetTargetEditor`, pass:

```dart
items: widget.store.backheaderBudgetItems,
onActiveItemChanged: _setBackheaderActiveItem,
```

Wrap modal content in `ListenableBuilder` so the editor receives fresh store data after autosave:

```dart
child: ListenableBuilder(
  listenable: widget.store,
  builder: (context, _) => BudgetTargetEditorSheet(...),
),
```

- [ ] **Step 6: Ensure stage honors controlled key**

In `CategoryBudgetStage.didUpdateWidget`, ensure controlled key wins before length fallback:

```dart
final activeKey = widget.activeKey;
if (activeKey != null) {
  final nextIndex = _items.indexWhere((item) => item.key == activeKey);
  if (nextIndex >= 0) {
    _index = nextIndex;
    _dragDx = 0;
  }
}
if (_index >= _items.length) _index = 0;
```

- [ ] **Step 7: Run sync tests**

Run:

```bash
flutter test test/transactions/transaction_home_limits_test.dart test/transactions/category_budget_stage_test.dart
```

Expected: PASS in a working Flutter environment.

- [ ] **Step 8: Commit sync work**

```bash
git add lib/features/transactions/transaction_home_page.dart \
  lib/features/transactions/widgets/header_card/category_budget_stage.dart \
  lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart \
  test/transactions/transaction_home_limits_test.dart \
  test/transactions/category_budget_stage_test.dart
git commit -m "feat: sync limit editor and backheader target"
```

---

### Task 7: Income Side Coverage

**Files:**
- Modify: `test/transactions/transaction_home_limits_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Modify: `lib/features/transactions/data/limit_allocation_manager.dart`

- [ ] **Step 1: Add income-side integration test**

In `transaction_home_limits_test.dart`, add:

```dart
testWidgets('income side uses income goal and income category allocation', (tester) async {
  final repository = FakeHomeLimitRepository.withIncomeData();
  final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 17));
  await pumpExpandedMonthlyHome(tester, store);

  await tester.tap(find.text('Bevétel'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
  await tester.pumpAndSettle();

  expect(find.text('Beveteli cel'), findsWidgets);
  expect(find.byKey(const ValueKey('category-limit-partition-bar')), findsOneWidget);
  expect(find.byKey(const ValueKey('limit-allocation-pie-chart')), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('limit-slider-end-button')));
  await tester.pumpAndSettle();

  expect(repository.savedLimits.last['targetType'], 'overview');
  expect(repository.savedLimits.last['transactionType'], 'income');
});
```

Add this named constructor to `FakeHomeLimitRepository`:

```dart
FakeHomeLimitRepository.withIncomeData() {
  categories.add(
    TransactionCategory.fromMap({
      'transactionCategoryID': 5,
      'name': 'Salary',
      'type': 'bevétel',
      'colorSlot': 2,
      'iconSlot': 0,
      'backgroundColor': '#3b82f6',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
  );
  transactions.add(
    TransactionRecord.fromMap({
      'id': 2,
      'date': '2026.05.01',
      'time': '09:00',
      'merchant': 'Salary',
      'amount': 1000,
      'userAssignedName': null,
      'transactionCategoryID': 5,
    }),
  );
  limits = [
    CategoryLimit.fromMap({
      'id': 20,
      'targetType': 'overview',
      'targetId': 0,
      'transactionType': 'income',
      'window': 'monthly',
      'periodKey': '2026-05',
      'hasLimit': true,
      'limitAmount': 1000,
      'alertActive': false,
      'createdAt': 0,
      'updatedAt': 1,
    }),
  ];
}
```

- [ ] **Step 2: Run failing income test**

Run:

```bash
flutter test test/transactions/transaction_home_limits_test.dart
```

Expected: FAIL if any editor branch assumes expense-only budget.

- [ ] **Step 3: Fix income allocation paths**

In editor code, ensure matching overview lookup uses:

```dart
if (overview.kind.transactionType == category.transactionType.nativeValue) {
  return overview.hasLimit ? overview.limitAmount : 0;
}
```

Ensure saving goal hides partition and pie:

```dart
if (_activeItem.overview?.kind == BudgetGoalKind.savingGoal) {
  return const SizedBox.shrink();
}
```

- [ ] **Step 4: Run income tests**

Run:

```bash
flutter test test/transactions/transaction_home_limits_test.dart
```

Expected: PASS in a working Flutter environment.

- [ ] **Step 5: Commit income coverage**

```bash
git add test/transactions/transaction_home_limits_test.dart \
  lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart \
  lib/features/transactions/data/limit_allocation_manager.dart
git commit -m "test: cover income allocation editor"
```

---

### Task 8: Final Verification And Online Build

**Files:**
- No source files unless verification reveals failures.

- [ ] **Step 1: Run focused tests locally**

Run:

```bash
flutter test test/transactions/limit_allocation_manager_test.dart
flutter test test/transactions/limit_allocation_pie_chart_test.dart
flutter test test/transactions/header_layout_test.dart
flutter test test/transactions/category_budget_stage_test.dart
flutter test test/transactions/transaction_home_limits_test.dart
```

Expected in a working Flutter environment: PASS.

If each command fails with the Dart TLS alignment error before loading tests, record that exact local blocker and continue to GitHub Actions verification.

- [ ] **Step 2: Run broader transaction tests locally**

Run:

```bash
flutter test test/transactions
```

Expected in a working Flutter environment: PASS.

- [ ] **Step 3: Run analyze locally**

Run:

```bash
flutter analyze
```

Expected in a working Flutter environment: no issues.

- [ ] **Step 4: Run debug APK build locally**

Run:

```bash
flutter build apk --debug
```

Expected in a working Flutter environment: debug APK builds.

- [ ] **Step 5: Push branch**

Run:

```bash
git status --short --branch
git push
```

Expected: branch `feature/backheader-budget-goals` is pushed.

- [ ] **Step 6: Run GitHub Actions Android workflow**

Run:

```bash
gh workflow run "Exptv2 Android APK Build" --ref feature/backheader-budget-goals
```

Then watch the returned run:

```bash
gh run watch <run-id> --interval 10
```

Expected: workflow succeeds with these green steps:

- `Analyze Dart code`
- `Run Flutter tests`
- `Build debug APK`
- `Upload debug APK`

- [ ] **Step 7: Download APK artifact**

Run:

```bash
mkdir -p /data/data/com.termux/files/usr/tmp/exptv2-limit-editor-artifacts
gh run download <run-id> --dir /data/data/com.termux/files/usr/tmp/exptv2-limit-editor-artifacts --name exptv2-debug-apk
find /data/data/com.termux/files/usr/tmp/exptv2-limit-editor-artifacts -maxdepth 3 -type f -print
```

Expected: `app-debug.apk` is present.

- [ ] **Step 8: Final status check**

Run:

```bash
git status --short --branch
git log --oneline --decorate -8
```

Expected: clean worktree, branch tracking `origin/feature/backheader-budget-goals`.
