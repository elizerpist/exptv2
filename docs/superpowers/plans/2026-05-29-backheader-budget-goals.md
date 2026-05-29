# Backheader Budget Goals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add expense budget, income goal, and saving goal support to the expanded backheader, including overview progress, category limit allocation, editor workflow, and requested header/backheader animations.

**Architecture:** Keep persistence on the existing `category_limits` table and add focused Dart models/managers for overview targets and progress segments. `TransactionStore` will expose a single backheader item list that combines overview items and category items, while widgets render those items through one pill-style visual system. Native validation only changes enough to allow `saving` for overview targets and reject it for category targets.

**Tech Stack:** Flutter/Dart, Kotlin Room repository, existing `NativeBridge`, `TransactionStore`, widget/unit tests, GitHub Actions for full analyze/test/build verification.

---

## File Structure

Create these files:

- `lib/features/transactions/models/budget_goal_kind.dart`: enum for `expenseBudget`, `incomeGoal`, and `savingGoal`, plus label/transaction type helpers.
- `lib/features/transactions/models/overview_budget_data.dart`: immutable overview target data used by store, editor, and widgets.
- `lib/features/transactions/models/backheader_budget_item.dart`: union-like model for overview items and category items in swipe order.
- `lib/features/transactions/models/budget_progress_segment.dart`: immutable segment model for background progress fills.
- `lib/features/transactions/data/budget_progress_manager.dart`: pure calculations for overview progress, category activity segments, saving progress, and category allocation max.
- `lib/features/transactions/widgets/header_card/budget_progress_frame.dart`: large pill-shaped background frame behind the active backheader bar.
- `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`: common editor for overview targets and category limits.
- `test/transactions/budget_progress_manager_test.dart`: pure calculation tests.
- `test/transactions/transaction_store_budget_goals_test.dart`: store payload and item-order tests.

Modify these files:

- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`: allow `saving` only for overview limits.
- `lib/features/transactions/data/limit_manager.dart`: expose one public static `findLimit` wrapper for the existing private lookup.
- `lib/features/transactions/state/transaction_store.dart`: expose overview goals, backheader items, and overview save method.
- `lib/features/transactions/widgets/header_card/category_budget_stage.dart`: consume `BackheaderBudgetItem`, render frame, move labels to gray header, change swipe snap behavior, recolor dots.
- `lib/features/transactions/widgets/header_card/category_budget_bar.dart`: remove internal text/progress and render opacity-based pill progress.
- `lib/features/transactions/widgets/header_card/category_limit_editor_sheet.dart`: keep only a compatibility wrapper around `BudgetTargetEditorSheet` for tests that instantiate the old widget directly.
- `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`: update partition drawing to use overview limit and spent/remain opacity states when called from the new editor.
- `lib/features/transactions/widgets/header_card/magnet_strip.dart`: increase slab height and remove pill-like ends for magnet strip variants.
- `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`: set `magnetHeight` to `157.5` and keep dependent positions explicitly tested for non-overlap.
- `lib/features/transactions/transaction_home_page.dart`: pass backheader items, open the common editor, save overview/category targets.
- `test/transactions/category_budget_stage_test.dart`: update UI expectations for overview rows, labels, progress frame, dots, and snap animation.
- `test/transactions/header_layout_test.dart`: update magnet/spring expectations.
- `test/transactions/transaction_home_limits_test.dart`: update editor integration tests.
- `test/transactions/category_limit_bridge_test.dart`: add bridge payload coverage for `saving` overview.

Do not create a new database table. Do not redesign the stats menu in this pass.

## Local Verification Note

The current Termux Flutter binary may fail locally with the known Dart TLS alignment error. In an environment where Flutter runs, use:

```bash
flutter test test/transactions/budget_progress_manager_test.dart
flutter test test/transactions/transaction_store_budget_goals_test.dart
flutter test test/transactions/category_budget_stage_test.dart
flutter test test/transactions/transaction_home_limits_test.dart
flutter test test/transactions/header_layout_test.dart
```

If local Flutter fails with TLS alignment, push the branch and use GitHub Actions for `flutter analyze`, tests, and Android build verification.

---

### Task 1: Pure Budget Goal Models And Progress Math

**Files:**
- Create: `lib/features/transactions/models/budget_goal_kind.dart`
- Create: `lib/features/transactions/models/overview_budget_data.dart`
- Create: `lib/features/transactions/models/budget_progress_segment.dart`
- Create: `lib/features/transactions/data/budget_progress_manager.dart`
- Test: `test/transactions/budget_progress_manager_test.dart`

- [ ] **Step 1: Write failing pure calculation tests**

Create `test/transactions/budget_progress_manager_test.dart` with these tests:

```dart
import 'package:exptv2/features/transactions/data/budget_progress_manager.dart';
import 'package:exptv2/features/transactions/models/budget_goal_kind.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense overview progress includes only categories with spending', () {
    final bars = [
      barFixture(6, 'Food', 50, const Color(0xffef4444)),
      barFixture(7, 'Travel', 25, const Color(0xff22c55e)),
      barFixture(8, 'Unused', 0, const Color(0xff3b82f6)),
    ];

    final progress = BudgetProgressManager.overviewProgress(
      kind: BudgetGoalKind.expenseBudget,
      limitAmount: 100,
      categoryBars: bars,
      periodIncome: 0,
      periodExpense: 75,
    );

    expect(progress.hasLimit, isTrue);
    expect(progress.ratio, 0.75);
    expect(progress.remainingFraction, 0.25);
    expect(progress.segments, hasLength(2));
    expect(progress.segments[0].amount, 50);
    expect(progress.segments[0].fraction, 0.5);
    expect(progress.segments[1].amount, 25);
    expect(progress.segments[1].fraction, 0.25);
  });

  test('income goal uses income category bars and treats full progress as success', () {
    final bars = [
      barFixture(5, 'Salary', 600, const Color(0xff06b6d4), type: TransactionType.income),
      barFixture(9, 'Bonus', 200, const Color(0xffa855f7), type: TransactionType.income),
      barFixture(10, 'Unused', 0, const Color(0xfff97316), type: TransactionType.income),
    ];

    final progress = BudgetProgressManager.overviewProgress(
      kind: BudgetGoalKind.incomeGoal,
      limitAmount: 800,
      categoryBars: bars,
      periodIncome: 800,
      periodExpense: 0,
    );

    expect(progress.ratio, 1);
    expect(progress.isSuccess, isTrue);
    expect(progress.isWarning, isFalse);
    expect(progress.isDanger, isFalse);
    expect(progress.segments.map((segment) => segment.amount), [600, 200]);
  });

  test('saving goal uses income minus expense and clamps negative balance to zero', () {
    final positive = BudgetProgressManager.overviewProgress(
      kind: BudgetGoalKind.savingGoal,
      limitAmount: 200,
      categoryBars: const [],
      periodIncome: 900,
      periodExpense: 750,
    );
    final negative = BudgetProgressManager.overviewProgress(
      kind: BudgetGoalKind.savingGoal,
      limitAmount: 200,
      categoryBars: const [],
      periodIncome: 100,
      periodExpense: 150,
    );

    expect(positive.amount, 150);
    expect(positive.ratio, 0.75);
    expect(positive.segments, hasLength(1));
    expect(negative.amount, 0);
    expect(negative.ratio, 0);
    expect(negative.segments, isEmpty);
  });

  test('category max excludes the currently edited category', () {
    final current = barFixture(6, 'Food', 25, const Color(0xffef4444), limit: 50);
    final other = barFixture(7, 'Travel', 0, const Color(0xff22c55e), limit: 25);

    expect(
      BudgetProgressManager.availableCategoryLimit(
        overviewLimit: 100,
        categoryBars: [current, other],
        activeBar: current,
      ),
      75,
    );
  });
}

CategoryBudgetBarData barFixture(
  int id,
  String title,
  double spent,
  Color color, {
  double limit = 0,
  TransactionType type = TransactionType.expense,
}) {
  final category = TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': title,
    'type': type.hungarianValue,
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
    transactionType: type,
    window: LimitWindow.monthly,
    periodKey: '2026-05',
    title: title,
    spent: spent,
    hasLimit: limit > 0,
    limitAmount: limit,
    alertActive: false,
    color: color,
    iconSlot: 2,
    category: category,
    sourceLimit: null,
  );
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
flutter test test/transactions/budget_progress_manager_test.dart
```

Expected: fails because `BudgetGoalKind`, `BudgetProgressManager`, and progress models do not exist.

- [ ] **Step 3: Add the models and pure manager**

Create `lib/features/transactions/models/budget_goal_kind.dart`:

```dart
enum BudgetGoalKind { expenseBudget, incomeGoal, savingGoal }

extension BudgetGoalKindX on BudgetGoalKind {
  String get key => switch (this) {
    BudgetGoalKind.expenseBudget => 'expense_budget',
    BudgetGoalKind.incomeGoal => 'income_goal',
    BudgetGoalKind.savingGoal => 'saving_goal',
  };

  String get title => switch (this) {
    BudgetGoalKind.expenseBudget => 'Budget',
    BudgetGoalKind.incomeGoal => 'Beveteli cel',
    BudgetGoalKind.savingGoal => 'Megtakaritas',
  };

  String get transactionType => switch (this) {
    BudgetGoalKind.expenseBudget => 'expense',
    BudgetGoalKind.incomeGoal => 'income',
    BudgetGoalKind.savingGoal => 'saving',
  };

  bool get usesCategorySegments => this != BudgetGoalKind.savingGoal;
  bool get warnsWhenHigh => this == BudgetGoalKind.expenseBudget;
}
```

Create `lib/features/transactions/models/budget_progress_segment.dart`:

```dart
import 'package:flutter/material.dart';

class BudgetProgressSegment {
  const BudgetProgressSegment({
    required this.amount,
    required this.fraction,
    required this.color,
  });

  final double amount;
  final double fraction;
  final Color color;
}

class BudgetProgressData {
  const BudgetProgressData({
    required this.hasLimit,
    required this.amount,
    required this.limitAmount,
    required this.ratio,
    required this.segments,
  });

  final bool hasLimit;
  final double amount;
  final double limitAmount;
  final double ratio;
  final List<BudgetProgressSegment> segments;

  double get clampedRatio => ratio.clamp(0.0, 1.0).toDouble();
  double get remainingFraction => (1 - clampedRatio).clamp(0.0, 1.0).toDouble();
  bool get isWarning => ratio >= 0.75 && ratio < 0.90;
  bool get isDanger => ratio >= 0.90;
  bool get isSuccess => hasLimit && ratio >= 1.0;
}
```

Create `lib/features/transactions/models/overview_budget_data.dart`:

```dart
import 'category_limit.dart';
import 'budget_goal_kind.dart';
import 'transaction_record.dart';

class OverviewBudgetData {
  const OverviewBudgetData({
    required this.kind,
    required this.window,
    required this.periodKey,
    required this.amount,
    required this.hasLimit,
    required this.limitAmount,
    required this.alertActive,
    required this.sourceLimit,
  });

  final BudgetGoalKind kind;
  final LimitWindow window;
  final String periodKey;
  final double amount;
  final bool hasLimit;
  final double limitAmount;
  final bool alertActive;
  final CategoryLimit? sourceLimit;

  String get key => 'overview-${kind.key}-${window.nativeValue}-$periodKey';
  String get title => kind.title;
  String get formattedAmount => formatHuf(amount);
  String get formattedLimit => formatHuf(limitAmount);
  String get displayAmount => hasLimit ? '$formattedAmount / $formattedLimit' : formattedAmount;
}
```

Create `lib/features/transactions/data/budget_progress_manager.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/budget_goal_kind.dart';
import '../models/budget_progress_segment.dart';
import '../models/category_budget_bar_data.dart';

class BudgetProgressManager {
  static const savingColor = Color(0xff10b981);

  static BudgetProgressData overviewProgress({
    required BudgetGoalKind kind,
    required double limitAmount,
    required List<CategoryBudgetBarData> categoryBars,
    required double periodIncome,
    required double periodExpense,
  }) {
    final hasLimit = limitAmount > 0;
    if (!hasLimit) {
      return const BudgetProgressData(
        hasLimit: false,
        amount: 0,
        limitAmount: 0,
        ratio: 0,
        segments: [],
      );
    }

    final amount = switch (kind) {
      BudgetGoalKind.expenseBudget => periodExpense,
      BudgetGoalKind.incomeGoal => periodIncome,
      BudgetGoalKind.savingGoal => (periodIncome - periodExpense).clamp(0.0, double.infinity).toDouble(),
    };

    final segments = kind == BudgetGoalKind.savingGoal
        ? _savingSegments(amount: amount, limitAmount: limitAmount)
        : _categorySegments(categoryBars, limitAmount);

    return BudgetProgressData(
      hasLimit: true,
      amount: amount,
      limitAmount: limitAmount,
      ratio: amount / limitAmount,
      segments: segments,
    );
  }

  static double availableCategoryLimit({
    required double overviewLimit,
    required List<CategoryBudgetBarData> categoryBars,
    required CategoryBudgetBarData activeBar,
  }) {
    if (overviewLimit <= 0) return 0;
    final usedByOthers = categoryBars
        .where((bar) => !_sameTarget(bar, activeBar))
        .where((bar) => bar.hasLimit && bar.limitAmount > 0)
        .fold<double>(0, (sum, bar) => sum + bar.limitAmount);
    return (overviewLimit - usedByOthers).clamp(0.0, double.infinity).toDouble();
  }

  static List<BudgetProgressSegment> _categorySegments(
    List<CategoryBudgetBarData> bars,
    double limitAmount,
  ) {
    if (limitAmount <= 0) return const [];
    return bars
        .where((bar) => bar.spent > 0)
        .map(
          (bar) => BudgetProgressSegment(
            amount: bar.spent,
            fraction: (bar.spent / limitAmount).clamp(0.0, 1.0).toDouble(),
            color: bar.color,
          ),
        )
        .toList();
  }

  static List<BudgetProgressSegment> _savingSegments({
    required double amount,
    required double limitAmount,
  }) {
    if (amount <= 0 || limitAmount <= 0) return const [];
    return [
      BudgetProgressSegment(
        amount: amount,
        fraction: (amount / limitAmount).clamp(0.0, 1.0).toDouble(),
        color: savingColor,
      ),
    ];
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

- [ ] **Step 4: Run the pure calculation test**

Run:

```bash
flutter test test/transactions/budget_progress_manager_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit Task 1**

```bash
git add lib/features/transactions/models/budget_goal_kind.dart   lib/features/transactions/models/overview_budget_data.dart   lib/features/transactions/models/budget_progress_segment.dart   lib/features/transactions/data/budget_progress_manager.dart   test/transactions/budget_progress_manager_test.dart
git commit -m "feat: add budget goal progress math"
```

---

### Task 2: Native Validation And Bridge Coverage

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Test: `test/transactions/category_limit_bridge_test.dart`

- [ ] **Step 1: Add bridge coverage for saving overview payload**

Append this test to `test/transactions/category_limit_bridge_test.dart`:

```dart
test('upserts saving overview limit through native bridge', () async {
  final limit = await bridge.expenseUpsertCategoryLimit({
    'targetType': 'overview',
    'targetId': 0,
    'transactionType': 'saving',
    'window': 'monthly',
    'periodKey': '2026-05',
    'hasLimit': true,
    'limitAmount': 100000,
    'alertActive': false,
  });

  expect(limit.targetType, LimitTargetType.overview);
  expect(limit.targetId, 0);
  expect(limit.transactionType, 'saving');
  expect(limit.limitAmount, 100000);
  expect(calls.single.method, 'expenseUpsertCategoryLimit');
});
```

- [ ] **Step 2: Run the bridge test**

Run:

```bash
flutter test test/transactions/category_limit_bridge_test.dart
```

Expected: PASS on Dart bridge behavior. Native validation still needs Kotlin change for real Android runtime.

- [ ] **Step 3: Update Kotlin validation**

In `ExpenseRepository.upsertCategoryLimit`, replace transaction type validation around the existing `normalizeNativeTransactionType` call with logic that accepts saving only for overview:

```kotlin
val rawTransactionType = args["transactionType"]?.toString()
val transactionType = if (targetType == "overview" && rawTransactionType == "saving") {
    "saving"
} else {
    normalizeNativeTransactionType(rawTransactionType)
        ?: throw ExpenseValidationException("INVALID_LIMIT_TYPE", "Limit transaction type is required")
}
if (targetType == "category" && transactionType == "saving") {
    throw ExpenseValidationException("INVALID_LIMIT_TYPE", "Saving limits are only valid for overview targets")
}
```

Keep the existing category existence check unchanged.

- [ ] **Step 4: Commit Task 2**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt   test/transactions/category_limit_bridge_test.dart
git commit -m "feat: allow saving overview limits"
```

---

### Task 3: TransactionStore Overview Targets And Backheader Items

**Files:**
- Create: `lib/features/transactions/models/backheader_budget_item.dart`
- Modify: `lib/features/transactions/data/limit_manager.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/transaction_store_budget_goals_test.dart`

- [ ] **Step 1: Write failing store tests**

Create `test/transactions/transaction_store_budget_goals_test.dart` with tests for item order and save payloads:

```dart
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/backheader_budget_item.dart';
import 'package:exptv2/features/transactions/models/budget_goal_kind.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense backheader starts with budget then expense categories', () async {
    final store = TransactionStore(FakeBudgetGoalRepository(), clock: () => DateTime(2026, 5, 17));
    await store.start();
    await store.cycleSummaryWindow();

    expect(store.summaryWindow, SummaryWindow.monthly);
    expect(store.backheaderBudgetItems.first.kind, BackheaderBudgetItemKind.overview);
    expect(store.backheaderBudgetItems.first.overview?.kind, BudgetGoalKind.expenseBudget);
    expect(store.backheaderBudgetItems[1].category?.title, 'Food');
  });

  test('income backheader starts with income goal and saving goal', () async {
    final store = TransactionStore(FakeBudgetGoalRepository(), clock: () => DateTime(2026, 5, 17));
    await store.start();
    await store.cycleSummaryWindow();
    store.setActiveType(TransactionType.income);

    expect(store.backheaderBudgetItems[0].overview?.kind, BudgetGoalKind.incomeGoal);
    expect(store.backheaderBudgetItems[1].overview?.kind, BudgetGoalKind.savingGoal);
    expect(store.backheaderBudgetItems[2].category?.title, 'Salary');
  });

  test('saving overview target saves as overview target id zero', () async {
    final repository = FakeBudgetGoalRepository();
    final store = TransactionStore(repository, clock: () => DateTime(2026, 5, 17));
    await store.start();
    await store.cycleSummaryWindow();

    await store.saveOverviewLimit(
      BudgetGoalKind.savingGoal,
      limitAmount: 100000,
      alertActive: false,
    );

    expect(repository.savedLimits.single['targetType'], 'overview');
    expect(repository.savedLimits.single['targetId'], 0);
    expect(repository.savedLimits.single['transactionType'], 'saving');
    expect(repository.savedLimits.single['window'], 'monthly');
    expect(repository.savedLimits.single['periodKey'], '2026-05');
  });
}

class FakeBudgetGoalRepository implements TransactionRepositoryContract {
  final savedLimits = <Map<String, Object?>>[];
  var limits = <CategoryLimit>[];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: [
      categoryFixture(5, 'Salary', TransactionType.income),
      categoryFixture(6, 'Food', TransactionType.expense),
    ],
    transactions: [
      transactionFixture(1, '2026.05.01', 500000, 5),
      transactionFixture(2, '2026.05.02', -120000, 6),
    ],
    limits: limits,
  );

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) async {
    savedLimits.add(payload);
    final limit = CategoryLimit.fromMap({
      'id': savedLimits.length,
      ...payload,
      'createdAt': 0,
      'updatedAt': savedLimits.length,
    });
    limits = [...limits.where((row) => row.targetType != limit.targetType || row.targetId != limit.targetId || row.transactionType != limit.transactionType), limit];
    return limit;
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({String? transactionType, String? window, String? periodKey}) async => limits;
  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) async => throw UnimplementedError();
  @override
  Future<TransactionRecord> updateTransaction(int id, Map<String, Object?> payload) async => throw UnimplementedError();
  @override
  Future<bool> deleteTransaction(int id) async => throw UnimplementedError();
  @override
  Future<int> renameTransactionsByMerchant(String originalMerchant, String userAssignedName) async => throw UnimplementedError();
  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async => throw UnimplementedError();
  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({DateTime? targetDate}) async => const [];
  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) async => throw UnimplementedError();
  @override
  Future<TransactionCategory> updateCategory(int id, Map<String, Object?> payload) async => throw UnimplementedError();
  @override
  Future<bool> deleteCategory(int id) async => throw UnimplementedError();
  @override
  Future<Map<int, int>> categoryCounts() async => const {5: 1, 6: 1};
}

TransactionCategory categoryFixture(int id, String name, TransactionType type) => TransactionCategory.fromMap({
  'transactionCategoryID': id,
  'name': name,
  'type': type.hungarianValue,
  'colorSlot': type == TransactionType.income ? 2 : 7,
  'iconSlot': 2,
  'backgroundColor': type == TransactionType.income ? '#3b82f6' : '#0ea5e9',
  'hasLimit': false,
  'limitAmount': 0,
  'alertActive': false,
  'isCustomIcon': true,
});

TransactionRecord transactionFixture(int id, String date, double amount, int categoryId) => TransactionRecord.fromMap({
  'id': id,
  'date': date,
  'time': '12:00',
  'merchant': 'Merchant',
  'amount': amount,
  'userAssignedName': null,
  'transactionCategoryID': categoryId,
});
```

- [ ] **Step 2: Run the failing store test**

```bash
flutter test test/transactions/transaction_store_budget_goals_test.dart
```

Expected: fails because store models/getters do not exist.

- [ ] **Step 3: Add `BackheaderBudgetItem`**

Create `lib/features/transactions/models/backheader_budget_item.dart`:

```dart
import 'category_budget_bar_data.dart';
import 'overview_budget_data.dart';

enum BackheaderBudgetItemKind { overview, category }

class BackheaderBudgetItem {
  const BackheaderBudgetItem._({required this.kind, this.overview, this.category});

  factory BackheaderBudgetItem.overview(OverviewBudgetData data) => BackheaderBudgetItem._(
    kind: BackheaderBudgetItemKind.overview,
    overview: data,
  );

  factory BackheaderBudgetItem.category(CategoryBudgetBarData data) => BackheaderBudgetItem._(
    kind: BackheaderBudgetItemKind.category,
    category: data,
  );

  final BackheaderBudgetItemKind kind;
  final OverviewBudgetData? overview;
  final CategoryBudgetBarData? category;

  String get key => overview?.key ?? category!.key;
  String get title => overview?.title ?? category!.title;
  String get amountText => overview?.displayAmount ?? _categoryAmount(category!);

  static String _categoryAmount(CategoryBudgetBarData bar) {
    return bar.hasLimit ? '${bar.formattedSpent} / ${bar.formattedLimit}' : bar.formattedSpent;
  }
}
```

- [ ] **Step 4: Expose public limit lookup helpers**

In `LimitManager`, add a public wrapper around the existing private `_findLimit` and keep the private method call sites working:

```dart
static CategoryLimit? findLimit({
  required List<CategoryLimit> limits,
  required LimitTargetType targetType,
  required int targetId,
  required String transactionType,
  required LimitWindow window,
  required String periodKey,
}) {
  return _findLimit(
    limits: limits,
    targetType: targetType,
    targetId: targetId,
    transactionType: transactionType,
    window: window,
    periodKey: periodKey,
  );
}
```

- [ ] **Step 5: Add store overview getters and save method**

In `TransactionStore`, import the new models and add these getters/methods:

```dart
List<OverviewBudgetData> get overviewBudgetItems {
  final window = LimitManager.windowForSummary(_summaryWindow);
  final periodKey = LimitManager.periodKeyFor(_summaryWindow, _periodReferenceDate);
  final income = _periodTotal(TransactionType.income);
  final expense = _periodTotal(TransactionType.expense);
  final kinds = _filter.type == TransactionType.expense
      ? const [BudgetGoalKind.expenseBudget]
      : const [BudgetGoalKind.incomeGoal, BudgetGoalKind.savingGoal];
  return kinds.map((kind) {
    final sourceLimit = LimitManager.findLimit(
      limits: _limits,
      targetType: LimitTargetType.overview,
      targetId: 0,
      transactionType: kind.transactionType,
      window: window,
      periodKey: periodKey,
    );
    final amount = switch (kind) {
      BudgetGoalKind.expenseBudget => expense,
      BudgetGoalKind.incomeGoal => income,
      BudgetGoalKind.savingGoal => (income - expense).clamp(0.0, double.infinity).toDouble(),
    };
    final hasLimit = sourceLimit?.hasLimit ?? false;
    final limitAmount = hasLimit ? sourceLimit!.limitAmount : 0.0;
    return OverviewBudgetData(
      kind: kind,
      window: window,
      periodKey: periodKey,
      amount: amount,
      hasLimit: hasLimit,
      limitAmount: limitAmount,
      alertActive: sourceLimit?.alertActive ?? false,
      sourceLimit: sourceLimit,
    );
  }).toList();
}

List<BackheaderBudgetItem> get backheaderBudgetItems {
  return [
    for (final overview in overviewBudgetItems) BackheaderBudgetItem.overview(overview),
    for (final bar in categoryBudgetBars) BackheaderBudgetItem.category(bar),
  ];
}

double _periodTotal(TransactionType type) {
  return LimitManager.recordsForWindow(
    transactions: _transactions,
    activeType: type,
    summaryWindow: _summaryWindow,
    referenceDate: _periodReferenceDate,
  ).fold<double>(0, (sum, record) => sum + record.amount.abs());
}

Future<void> saveOverviewLimit(
  BudgetGoalKind kind, {
  required double limitAmount,
  required bool alertActive,
}) async {
  final amount = limitAmount < 0 ? 0.0 : limitAmount;
  final hasLimit = amount > 0;
  await _repository.upsertCategoryLimit({
    'targetType': LimitTargetType.overview.nativeValue,
    'targetId': 0,
    'transactionType': kind.transactionType,
    'window': LimitManager.windowForSummary(_summaryWindow).nativeValue,
    'periodKey': LimitManager.periodKeyFor(_summaryWindow, _periodReferenceDate),
    'hasLimit': hasLimit,
    'limitAmount': hasLimit ? amount : 0.0,
    'alertActive': hasLimit && alertActive,
  });
  await _reload();
}
```

- [ ] **Step 6: Run store tests**

```bash
flutter test test/transactions/transaction_store_budget_goals_test.dart
flutter test test/transactions/transaction_store_limits_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit Task 3**

```bash
git add lib/features/transactions/models/backheader_budget_item.dart   lib/features/transactions/data/limit_manager.dart   lib/features/transactions/state/transaction_store.dart   test/transactions/transaction_store_budget_goals_test.dart   test/transactions/transaction_store_limits_test.dart
git commit -m "feat: expose backheader budget goals"
```

---

### Task 4: Progress Frame And Category Pill Rendering

**Files:**
- Create: `lib/features/transactions/widgets/header_card/budget_progress_frame.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Update widget tests for labels, progress frame, and removed inner progress**

In `test/transactions/category_budget_stage_test.dart`, update the first test to build `CategoryBudgetStage(items: [...])` instead of `bars: [...]`, then assert:

```dart
expect(find.text('Food'), findsOneWidget);
expect(find.text('100 Ft / 150 Ft'), findsOneWidget);
expect(find.byKey(const ValueKey('category-progress-fill')), findsNothing);
expect(find.byKey(const ValueKey('budget-progress-frame')), findsOneWidget);
expect(find.byKey(const ValueKey('category-budget-dot-0')), findsOneWidget);
```

Add a test for no overview limit:

```dart
testWidgets('stage hides background progress frame without overview limit', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 260,
        child: CategoryBudgetStage(
          items: [BackheaderBudgetItem.category(barFixture(6, 'Food', 100, 0))],
          categoryBars: [barFixture(6, 'Food', 100, 0)],
          onItemTap: (_) {},
        ),
      ),
    ),
  ));

  expect(find.byKey(const ValueKey('budget-progress-frame')), findsNothing);
});
```

- [ ] **Step 2: Run failing stage tests**

```bash
flutter test test/transactions/category_budget_stage_test.dart
```

Expected: fails because `CategoryBudgetStage` still accepts bars and still renders the old outline/progress.

- [ ] **Step 3: Create `BudgetProgressFrame`**

Create `lib/features/transactions/widgets/header_card/budget_progress_frame.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/budget_goal_kind.dart';
import '../../models/budget_progress_segment.dart';

class BudgetProgressFrame extends StatelessWidget {
  const BudgetProgressFrame({
    super.key,
    required this.progress,
    required this.kind,
    this.height = 62,
  });

  final BudgetProgressData progress;
  final BudgetGoalKind kind;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!progress.hasLimit) return const SizedBox.shrink();
    final borderColor = _borderColor();
    return Container(
      key: const ValueKey('budget-progress-frame'),
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          var left = 0.0;
          final children = <Widget>[];
          for (var i = 0; i < progress.segments.length; i += 1) {
            final segment = progress.segments[i];
            final width = constraints.maxWidth * segment.fraction;
            children.add(Positioned(
              key: ValueKey('budget-progress-frame-segment-$i'),
              left: left,
              top: 0,
              width: width,
              bottom: 0,
              child: ColoredBox(color: segment.color),
            ));
            left += width;
          }
          return Stack(fit: StackFit.expand, children: children);
        },
      ),
    );
  }

  Color _borderColor() {
    if (kind.warnsWhenHigh && progress.isDanger) return const Color(0xffff4444);
    if (kind.warnsWhenHigh && progress.isWarning) return const Color(0xffff9800);
    if (!kind.warnsWhenHigh && progress.isSuccess) return const Color(0xff10b981);
    return AppColors.white;
  }
}
```

- [ ] **Step 4: Refactor `CategoryBudgetBar` to be visual-only**

Change constructor to accept optional `progress` and remove text/progress children. Keep icon support. The core body should be:

```dart
final progress = bar.hasLimit && bar.limitAmount > 0
    ? (bar.spent / bar.limitAmount).clamp(0.0, 1.0).toDouble()
    : 1.0;
return Material(
  key: const ValueKey('category-budget-bar'),
  color: Colors.transparent,
  elevation: 8,
  shadowColor: Colors.black.withValues(alpha: 0.2),
  borderRadius: BorderRadius.circular(25),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(25),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: bar.color.withValues(alpha: 0.30)),
            FractionallySizedBox(
              key: const ValueKey('category-budget-used-fill'),
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: ColoredBox(color: bar.color),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Image(
                  image: CategoryIconManager.assetImage(bar.iconSlot),
                  width: compactIcon ? 35 : 45,
                  height: compactIcon ? 35 : 45,
                  color: AppColors.white,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.category_outlined,
                    color: AppColors.white,
                    size: compactIcon ? 35 : 45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
```

- [ ] **Step 5: Refactor `CategoryBudgetStage` to use backheader items**

Change constructor fields:

```dart
final List<BackheaderBudgetItem> items;
final List<CategoryBudgetBarData> categoryBars;
final ValueChanged<BackheaderBudgetItem> onItemTap;
```

In build:

```dart
final current = widget.items[_index];
final title = current.title;
final amountText = current.amountText;
final progress = current.overview == null
    ? null
    : BudgetProgressManager.overviewProgress(
        kind: current.overview!.kind,
        limitAmount: current.overview!.limitAmount,
        categoryBars: widget.categoryBars,
        periodIncome: _periodIncomeFromOverviewItems(),
        periodExpense: _periodExpenseFromOverviewItems(),
      );
```

Place title and amount on the gray surface above the active pill:

```dart
Positioned(
  top: 34,
  left: 30,
  right: 30,
  child: Row(
    children: [
      Expanded(child: Text(title, key: const ValueKey('backheader-active-title'), style: const TextStyle(color: AppColors.gray800, fontWeight: FontWeight.w700, fontSize: 15))),
      Text(amountText, key: const ValueKey('backheader-active-amount'), style: const TextStyle(color: AppColors.gray800, fontWeight: FontWeight.w700, fontSize: 13)),
    ],
  ),
)
```

Render `BudgetProgressFrame` behind the active bar only when `progress?.hasLimit == true`. For overview items, render an overview-colored pill. For category items, render `CategoryBudgetBar`.

- [ ] **Step 6: Run stage tests**

```bash
flutter test test/transactions/category_budget_stage_test.dart
```

Expected: PASS after updating fixtures/imports for `BackheaderBudgetItem`.

- [ ] **Step 7: Commit Task 4**

```bash
git add lib/features/transactions/widgets/header_card/budget_progress_frame.dart   lib/features/transactions/widgets/header_card/category_budget_bar.dart   lib/features/transactions/widgets/header_card/category_budget_stage.dart   test/transactions/category_budget_stage_test.dart
git commit -m "feat: render backheader budget progress frame"
```

---

### Task 5: Common Budget Target Editor

**Files:**
- Create: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_limit_editor_sheet.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Update home editor integration tests**

Add one test that taps the first backheader item and saves an expense budget:

```dart
await tester.tap(find.byKey(const ValueKey('header-expand-button')));
await tester.pumpAndSettle();
await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
await tester.pumpAndSettle();
await tester.enterText(find.byKey(const ValueKey('limit-amount-input')), '300000');
await tester.tap(find.byKey(const ValueKey('limit-save-button')));
await tester.pumpAndSettle();

expect(repository.savedLimits.single['targetType'], 'overview');
expect(repository.savedLimits.single['targetId'], 0);
expect(repository.savedLimits.single['transactionType'], 'expense');
```

Add a second test for category allocation max after an overview limit exists:

```dart
expect(find.byKey(const ValueKey('category-limit-slider')), findsOneWidget);
expect(find.byKey(const ValueKey('category-limit-partition-bar')), findsOneWidget);
```

- [ ] **Step 2: Run failing integration test**

```bash
flutter test test/transactions/transaction_home_limits_test.dart
```

Expected: fails because home still opens `CategoryLimitEditorSheet` for category bars only.

- [ ] **Step 3: Create `BudgetTargetEditorSheet`**

Create a sheet that accepts either `BackheaderBudgetItem.overview` or `.category`:

```dart
class BudgetTargetEditorSheet extends StatefulWidget {
  const BudgetTargetEditorSheet({
    super.key,
    required this.item,
    required this.categoryBars,
    required this.periodIncome,
    required this.onCancel,
    required this.onSaveOverview,
    required this.onSaveCategory,
  });

  final BackheaderBudgetItem item;
  final List<CategoryBudgetBarData> categoryBars;
  final double periodIncome;
  final VoidCallback onCancel;
  final Future<void> Function(BudgetGoalKind kind, {required double limitAmount, required bool alertActive}) onSaveOverview;
  final Future<void> Function(CategoryBudgetBarData bar, {required double limitAmount, required bool alertActive}) onSaveCategory;
}
```

Inside state:

```dart
bool get _isOverview => widget.item.kind == BackheaderBudgetItemKind.overview;
double get _initialAmount => widget.item.overview?.limitAmount ?? widget.item.category?.limitAmount ?? 0;
double get _amount => double.tryParse(_controller.text.trim().replaceAll(' ', '')) ?? 0;
```

Slider max:

```dart
double get _sliderMax {
  final overview = widget.item.overview;
  final category = widget.item.category;
  if (overview != null) return math.max(widget.periodIncome, _amount <= 0 ? 10000 : _amount);
  if (category != null) {
    final overviewLimit = _matchingOverviewLimitForCategory();
    final available = BudgetProgressManager.availableCategoryLimit(
      overviewLimit: overviewLimit,
      categoryBars: widget.categoryBars,
      activeBar: category,
    );
    return math.max(available, _amount <= 0 ? 10000 : _amount);
  }
  return 10000;
}
```

Save:

```dart
Future<void> _save() async {
  setState(() => _saving = true);
  final overview = widget.item.overview;
  final category = widget.item.category;
  if (overview != null) {
    await widget.onSaveOverview(overview.kind, limitAmount: _amount, alertActive: _amount > 0 && _alertActive);
  } else if (category != null) {
    await widget.onSaveCategory(category, limitAmount: _amount, alertActive: _amount > 0 && _alertActive);
  }
  if (mounted) setState(() => _saving = false);
}
```

- [ ] **Step 4: Wire editor from `TransactionHomePage`**

Replace `CategoryBudgetStage(bars: widget.store.categoryBudgetBars, onBarTap: _openLimitEditor)` with:

```dart
CategoryBudgetStage(
  items: widget.store.backheaderBudgetItems,
  categoryBars: widget.store.categoryBudgetBars,
  onItemTap: _openBudgetTargetEditor,
)
```

Add `_openBudgetTargetEditor(BackheaderBudgetItem item)` that opens `BudgetTargetEditorSheet` and calls `saveOverviewLimit` or `saveCategoryLimitForBar`.

- [ ] **Step 5: Keep compatibility or remove old sheet import**

If `CategoryLimitEditorSheet` has no remaining references, remove its import from `transaction_home_page.dart`. If tests still import it directly, keep it as a wrapper that creates `BudgetTargetEditorSheet` for a category item.

- [ ] **Step 6: Run editor tests**

```bash
flutter test test/transactions/transaction_home_limits_test.dart
flutter test test/transactions/category_budget_stage_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit Task 5**

```bash
git add lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart   lib/features/transactions/widgets/header_card/category_limit_partition_bar.dart   lib/features/transactions/widgets/header_card/category_limit_editor_sheet.dart   lib/features/transactions/transaction_home_page.dart   test/transactions/transaction_home_limits_test.dart
git commit -m "feat: add shared budget target editor"
```

---

### Task 6: Header Magnet And Backheader Swipe Animation

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/magnet_strip.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_metrics.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/header_layout_test.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Add animation behavior tests**

In `header_layout_test.dart`, add a test that checks magnet custom paint height is 50% larger than the prior visual track. Use the metric, not screenshot pixels:

```dart
expect(TransactionHeaderMetrics.magnetHeight, greaterThanOrEqualTo(157.5));
```

In `category_budget_stage_test.dart`, add a snap test:

```dart
final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('category-budget-bar'))));
await gesture.moveBy(const Offset(-90, 0));
await tester.pump();
await gesture.up();
await tester.pump();
expect(find.text('Travel'), findsOneWidget);
final translated = tester.widget<Transform>(find.byKey(const ValueKey('category-budget-bar-translation')));
expect(translated.transform.getTranslation().x.abs(), greaterThan(40));
await tester.pumpAndSettle();
expect(tester.widget<Transform>(find.byKey(const ValueKey('category-budget-bar-translation'))).transform.getTranslation().x, 0);
```

- [ ] **Step 2: Run failing animation tests**

```bash
flutter test test/transactions/header_layout_test.dart
flutter test test/transactions/category_budget_stage_test.dart
```

Expected: fails until metrics and snap behavior change.

- [ ] **Step 3: Update magnet metrics and slab shape**

In `TransactionHeaderMetrics`, set:

```dart
static const magnetHeight = 157.5;
```

Adjust `magnetTop`, `balanceTop`, and `categoryButtonTop` only if tests or layout show overlap. In `MagnetStripPainter`, replace pill-like rounded slab drawing with low-radius rectangles:

```dart
final slabHeight = math.max(18.0, size.height * 0.55);
final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
```

Use the same tiny radius in `budget`, `nofade`, and default branches where the strip currently uses `Radius.circular(3)`.

- [ ] **Step 4: Strengthen header pull spring**

In `_handleHeaderDragEnd`, change the spring description to a faster, visibly underdamped return:

```dart
const SpringDescription(mass: 0.75, stiffness: 620, damping: 16)
```

Keep the final clamp/reset logic so `_fastInfoExtent` ends at zero.

- [ ] **Step 5: Change backheader swipe to snap-after-switch**

In `CategoryBudgetStage._settleDrag`, replace exit animation with immediate index switch and snap-back:

```dart
final swipedLeft = start < 0;
setState(() {
  _index = swipedLeft ? (_index + 1) % widget.items.length : _index == 0 ? widget.items.length - 1 : _index - 1;
  _dragDx = swipedLeft ? settleDistance * 0.33 : -settleDistance * 0.33;
});
await _animateDragTo(0, curve: Curves.elasticOut, duration: const Duration(milliseconds: 420));
```

Update `_animateDragTo` signature:

```dart
Future<void> _animateDragTo(
  double target, {
  Curve curve = Curves.easeOutCubic,
  Duration duration = const Duration(milliseconds: 160),
}) {
  _slideController.stop();
  _slideController.duration = duration;
  _slideAnimation = Tween<double>(begin: _dragDx, end: target).animate(
    CurvedAnimation(parent: _slideController, curve: curve),
  );
  return _slideController.forward(from: 0);
}
```

Set dots:

```dart
color: i == _index ? AppColors.primary : AppColors.white
```

- [ ] **Step 6: Run animation tests**

```bash
flutter test test/transactions/header_layout_test.dart
flutter test test/transactions/category_budget_stage_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit Task 6**

```bash
git add lib/features/transactions/widgets/header_card/magnet_strip.dart   lib/features/transactions/widgets/header_card/transaction_header_metrics.dart   lib/features/transactions/transaction_home_page.dart   lib/features/transactions/widgets/header_card/category_budget_stage.dart   test/transactions/header_layout_test.dart   test/transactions/category_budget_stage_test.dart
git commit -m "feat: polish header and backheader motion"
```

---

### Task 7: Full Regression And Android Build

**Files:**
- No source files unless prior tests reveal required fixes.

- [ ] **Step 1: Run focused Flutter tests**

```bash
flutter test test/transactions/budget_progress_manager_test.dart
flutter test test/transactions/transaction_store_budget_goals_test.dart
flutter test test/transactions/category_limit_bridge_test.dart
flutter test test/transactions/category_budget_stage_test.dart
flutter test test/transactions/transaction_home_limits_test.dart
flutter test test/transactions/header_layout_test.dart
```

Expected: all focused tests pass in a working Flutter environment.

- [ ] **Step 2: Run broader test suite**

```bash
flutter test test/transactions
```

Expected: all transaction tests pass.

- [ ] **Step 3: Analyze**

```bash
flutter analyze
```

Expected: no new errors.

- [ ] **Step 4: Android build**

```bash
flutter build apk --debug
```

Expected: debug APK builds successfully.

- [ ] **Step 5: If local Flutter fails with TLS alignment**

Push the branch and verify the same commands through GitHub Actions. Record the failing local command and CI run result in the final handoff.

- [ ] **Step 6: Final commit if verification-only fixes were needed**

```bash
git status --short
git add lib/features/transactions android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt test/transactions
git commit -m "fix: stabilize budget goal regressions"
```

Expected: skip this commit if `git status --short` is clean.
