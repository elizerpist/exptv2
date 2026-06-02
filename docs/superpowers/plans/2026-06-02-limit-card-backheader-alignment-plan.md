# Limit Card Backheader Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the LimitCard save button with the existing AddTransaction/AddCategory save baseline, reorder the LimitCard content, and update the backheader bar/text presentation from the approved design.

**Architecture:** Keep the existing `BudgetTargetEditorSheet`, `CategoryBudgetStage`, and bar widget boundaries. Add small geometry helpers in `BudgetBarGeometry` so overview and category bars share the same visible-width calculation. Use widget tests to lock exact button baseline, content order, avatar scale, bar vertical offset, text sizes, visible bar shrinkage, and minimum icon width.

**Tech Stack:** Flutter, Dart widget tests, existing Exptv2 transaction widgets.

---

## File Structure

- Modify `lib/features/transactions/widgets/slide_up_panel_metrics.dart`: make the budget save bottom inset reuse the transaction save baseline.
- Modify `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`: reorder `_BudgetLimitCard`, shrink `_LimitAvatar`, and bottom-anchor content inside the scroll viewport so the limit input gap stays close while the save button baseline moves down.
- Modify `lib/features/transactions/widgets/header_card/budget_bar_geometry.dart`: move the bar center 5 px down and add shared visible-width/min-width helpers.
- Modify `lib/features/transactions/widgets/header_card/category_budget_stage.dart`: increase title/amount font sizes, apply the lower geometry, and size the overview bar plus gray mask to the visible width.
- Modify `lib/features/transactions/widgets/header_card/category_budget_bar.dart`: size category bars to visible remaining width and remove full-width spent overlay rendering.
- Modify `test/transactions/transaction_home_limits_test.dart`: add/adjust LimitCard baseline, gap, order, and avatar tests.
- Modify `test/transactions/category_budget_stage_test.dart`: add/adjust backheader geometry, font, category width, overview width, mask width, and min-width tests.

---

### Task 1: LimitCard Baseline and Layout Tests

**Files:**
- Modify: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Replace the current LimitCard gap-only test with baseline + gap assertions**

In `test/transactions/transaction_home_limits_test.dart`, replace the body of the test named `limit editor keeps save button close to the budget limit field` with this assertion structure:

```dart
      final limitCard = tester.getRect(
        find.byKey(const ValueKey('budget-target-editor-card')),
      );
      final saveButton = tester.getRect(
        find.byKey(const ValueKey('limit-save-button')),
      );
      final amountInput = tester.getRect(
        find.byKey(const ValueKey('limit-amount-input')),
      );
      expect(SlideUpPanelMetrics.budgetBaseHeight, 432);
      expect(limitCard.height, moreOrLessEquals(432, epsilon: 0.1));
      expect(
        limitCard.bottom - saveButton.bottom,
        moreOrLessEquals(
          SlideUpPanelMetrics.transactionActionBottomInset,
          epsilon: 0.1,
        ),
      );
      expect(saveButton.top - amountInput.bottom, lessThanOrEqualTo(22));
```

- [ ] **Step 2: Add a test for LimitCard vertical order**

Add this widget test after the baseline test:

```dart
  testWidgets('limit editor lays out period avatar title progress slider input save in order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final overview = OverviewBudgetData(
      kind: BudgetGoalKind.expenseBudget,
      window: LimitWindow.monthly,
      periodKey: '2026-05',
      amount: 100,
      hasLimit: true,
      limitAmount: 1000,
      alertActive: false,
      sourceLimit: null,
    );
    final item = BackheaderBudgetItem.overview(overview);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetTargetEditorSheet(
            item: item,
            items: [item],
            periodLabel: '2026 május',
            categoryBars: const <CategoryBudgetBarData>[],
            periodIncome: 1000,
            onCancel: () {},
            onActiveItemChanged: (_) {},
            onSaveOverview:
                (_, {required limitAmount, required alertActive}) async {},
            onSaveCategory:
                (_, {required limitAmount, required alertActive}) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final period = tester.getRect(find.byKey(const ValueKey('limit-card-period-label')));
    final avatar = tester.getRect(find.byKey(const ValueKey('limit-card-avatar')));
    final title = tester.getRect(find.byKey(const ValueKey('limit-card-title')));
    final progress = tester.getRect(find.byKey(const ValueKey('category-limit-partition-bar')));
    final slider = tester.getRect(find.byKey(const ValueKey('category-limit-slider')));
    final input = tester.getRect(find.byKey(const ValueKey('limit-amount-input')));
    final save = tester.getRect(find.byKey(const ValueKey('limit-save-button')));

    expect(period.top, lessThan(avatar.top));
    expect(avatar.bottom, lessThan(title.top));
    expect(title.bottom, lessThan(progress.top));
    expect(progress.bottom, lessThan(slider.top));
    expect(slider.bottom, lessThan(input.top));
    expect(input.bottom, lessThan(save.top));
  });
```

- [ ] **Step 3: Add a test for 20 percent avatar shrink**

Add this widget test after the order test:

```dart
  testWidgets('limit editor avatar is 20 percent smaller', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final overview = OverviewBudgetData(
      kind: BudgetGoalKind.expenseBudget,
      window: LimitWindow.monthly,
      periodKey: '2026-05',
      amount: 100,
      hasLimit: true,
      limitAmount: 1000,
      alertActive: false,
      sourceLimit: null,
    );
    final item = BackheaderBudgetItem.overview(overview);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetTargetEditorSheet(
            item: item,
            items: [item],
            periodLabel: '2026 május',
            categoryBars: const <CategoryBudgetBarData>[],
            periodIncome: 1000,
            onCancel: () {},
            onActiveItemChanged: (_) {},
            onSaveOverview:
                (_, {required limitAmount, required alertActive}) async {},
            onSaveCategory:
                (_, {required limitAmount, required alertActive}) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('limit-card-avatar'))),
      const Size(50, 50),
    );
  });
```

- [ ] **Step 4: Run tests and verify failures**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_home_limits_test.dart'
```

Expected: FAIL. The baseline assertion reports the current `budgetActionBottomInset` gap around `68.0`, and the order/avatar tests fail because the period label is currently in a `Wrap` with the title and the avatar is `62x62`.

---

### Task 2: Implement LimitCard Baseline, Order, and Avatar

**Files:**
- Modify: `lib/features/transactions/widgets/slide_up_panel_metrics.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Point the budget save inset at the shared transaction save baseline**

In `lib/features/transactions/widgets/slide_up_panel_metrics.dart`, replace the budget inset constant with:

```dart
  static const actionBottomInset = 24.0;
  static const transactionActionBottomInset = 44.0;
  static const budgetActionBottomInset = transactionActionBottomInset;
```

Keep the rest of the constants unchanged.

- [ ] **Step 2: Bottom-anchor the LimitCard content inside the scroll viewport**

In `BudgetTargetEditorSheet.build`, replace the current `Expanded(child: SingleChildScrollView(...))` branch with:

```dart
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: horizontalInset,
                          right: horizontalInset,
                          top: 20,
                          bottom: 8,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: math.max(
                              0,
                              constraints.maxHeight - 28,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: _BudgetLimitCard(
                              item: _activeItem,
                              periodLabel: widget.periodLabel,
                              amountController: _controller,
                              amountFocusNode: _amountFocus,
                              inputLabel: _inputLabel,
                              activeColor: _activeColor,
                              sliderValue: _sliderRange.value,
                              sliderMax: _sliderRange.max,
                              sliderEnabled: _sliderRange.enabled,
                              sliderDivisions: _sliderRange.divisions,
                              saving: _saving,
                              onPrevious: _selectPrevious,
                              onNext: _selectNext,
                              onAvatarDoubleTap: _selectOverviewItem,
                              onReset: _resetLimit,
                              onSliderChanged: _setAmountFromSlider,
                              onSliderChangeEnd: _setAmountFromSlider,
                              onInputChanged: _captureInputAmount,
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
```

This keeps the limit input close to the fixed save area when the save button moves down.

- [ ] **Step 3: Reorder `_BudgetLimitCard`**

In `_BudgetLimitCard.build`, replace the current children after the drag handle with this order:

```dart
        const SizedBox(height: 10),
        Center(
          child: Container(
            key: const ValueKey('limit-card-period-label'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Text(
              periodLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gray600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              key: const ValueKey('limit-card-previous-button'),
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              color: AppColors.gray700,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: onAvatarDoubleTap,
                  child: _LimitAvatar(item: item, color: activeColor),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('limit-card-next-button'),
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.gray700,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          item.title,
          key: const ValueKey('limit-card-title'),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.gray800,
          ),
        ),
        const SizedBox(height: 8),
        partitionBar,
        const SizedBox(height: 10),
        CategoryLimitSlider(
          value: sliderValue,
          max: sliderMax,
          divisions: sliderDivisions,
          activeColor: activeColor,
          enabled: sliderEnabled,
          onChanged: onSliderChanged,
          onChangeEnd: onSliderChangeEnd,
        ),
```

Keep the saving indicator and `TextField` after the slider.

- [ ] **Step 4: Shrink `_LimitAvatar` by 20 percent**

In `_LimitAvatar.build`, replace the size values with:

```dart
      width: 50,
      height: 50,
```

Use these child sizes:

```dart
      child: category == null
          ? Icon(icon, color: AppColors.white, size: 27)
          : Image(
              image: CategoryIconManager.assetImage(category.iconSlot),
              width: 29,
              height: 29,
              color: AppColors.white,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.category_outlined,
                color: AppColors.white,
                size: 27,
              ),
            ),
```

- [ ] **Step 5: Run targeted LimitCard tests and verify pass**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_home_limits_test.dart'
```

Expected: PASS for the LimitCard tests and no regressions in the existing home limit tests.

- [ ] **Step 6: Commit LimitCard changes**

Run:

```bash
git add lib/features/transactions/widgets/slide_up_panel_metrics.dart lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart test/transactions/transaction_home_limits_test.dart
git commit -m "Align limit editor save baseline"
```

---

### Task 3: Backheader Geometry and Text Tests

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Update the existing geometry test for the 5 px lower bar center**

In the test named `budget bar geometry is 20 percent smaller with centered frame`, update the center expectation to:

```dart
    expect(BudgetBarGeometry.barCenterY, 112);
```

Keep the existing 20 percent height assertions.

- [ ] **Step 2: Add a font-size test for active title and amount**

Add this test near the other `CategoryBudgetStage` label tests:

```dart
  testWidgets('stage title and amount use matching enlarged font size', (
    tester,
  ) async {
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
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('backheader-active-title')),
    );
    final amount = tester.widget<Text>(
      find.byKey(const ValueKey('backheader-active-amount')),
    );

    expect(title.style!.fontSize, moreOrLessEquals(16.5, epsilon: 0.01));
    expect(amount.style!.fontSize, moreOrLessEquals(16.5, epsilon: 0.01));
  });
```

- [ ] **Step 3: Run tests and verify failures**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart --plain-name "budget bar geometry is 20 percent smaller with centered frame" --plain-name "stage title and amount use matching enlarged font size"'
```

Expected: FAIL. Current `barCenterY` is `107`, title font is `15`, and amount font is `13`.

---

### Task 4: Implement Backheader Geometry and Text

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/budget_bar_geometry.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Move the bar stack down 5 px**

In `BudgetBarGeometry`, replace:

```dart
  static const barCenterY = 107.0;
```

with:

```dart
  static const barCenterY = 112.0;
```

- [ ] **Step 2: Match and enlarge title and amount font sizes**

In `CategoryBudgetStage`, replace the title and amount text styles with:

```dart
                    style: const TextStyle(
                      color: AppColors.gray800,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.5,
                    ),
```

Apply the same style block to `current.amountText`.

- [ ] **Step 3: Run targeted tests and verify pass**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart --plain-name "budget bar geometry is 20 percent smaller with centered frame" --plain-name "stage title and amount use matching enlarged font size"'
```

Expected: PASS.

- [ ] **Step 4: Commit backheader geometry/text changes**

Run:

```bash
git add lib/features/transactions/widgets/header_card/budget_bar_geometry.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart test/transactions/category_budget_stage_test.dart
git commit -m "Adjust backheader bar position and labels"
```

---

### Task 5: Visible Bar Width Tests

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Replace category overlay test with visible-width shrink test**

Replace the test named `category bar fades spent part and keeps remaining part strong` with:

```dart
  testWidgets('category bar width shrinks as spending consumes limit', (
    tester,
  ) async {
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

    final bar = tester.getRect(find.byKey(const ValueKey('category-budget-bar')));
    expect(bar.width, moreOrLessEquals(270, epsilon: 0.5));
    expect(find.byKey(const ValueKey('category-budget-spent-overlay')), findsNothing);
  });
```

- [ ] **Step 2: Add a category min-width test**

Add this test after the category shrink test:

```dart
  testWidgets('category bar keeps minimum icon width at full spending', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: CategoryBudgetBar(
              bar: barFixture(6, 'Food', 12000, 10000),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(find.byKey(const ValueKey('category-budget-bar')));
    expect(bar.width, moreOrLessEquals(84, epsilon: 0.5));
  });
```

- [ ] **Step 3: Replace overview fill-factor test with visible-width test**

Replace the body of `expense budget overview bar shrinks as budget is consumed` with:

```dart
    final bar = tester.getRect(find.byKey(const ValueKey('category-budget-bar')));
    final fillFinder = find.byKey(const ValueKey('overview-budget-remaining-fill'));
    expect(fillFinder, findsNothing);
    // Stage width 390 minus 40 px insets on each side gives a 310 px slot.
    // Remaining ratio is 0.75, so the visible bar is 232.5 px wide.
    expect(bar.width, moreOrLessEquals(232.5, epsilon: 0.5));
```

- [ ] **Step 4: Add a stage mask width test**

Add this assertion inside `stage renders budget progress frame when overview limit exists` after `maskRect` and `barRect` are read:

```dart
      expect(maskRect.width, moreOrLessEquals(barRect.width, epsilon: 0.1));
```

- [ ] **Step 5: Run tests and verify failures**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart'
```

Expected: FAIL. Current category bars stay full width and render `category-budget-spent-overlay`; overview bars still expose `overview-budget-remaining-fill`; mask width equals the full slot.

---

### Task 6: Implement Visible Bar Widths

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/budget_bar_geometry.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Add shared width helpers**

In `BudgetBarGeometry`, add:

```dart
  static double minVisibleWidth(double height) => height * 1.20;

  static double visibleWidth({
    required double availableWidth,
    required double height,
    required double ratio,
  }) {
    final clampedRatio = ratio.clamp(0.0, 1.0).toDouble();
    final minWidth = minVisibleWidth(height).clamp(0.0, availableWidth).toDouble();
    return (availableWidth * clampedRatio)
        .clamp(minWidth, availableWidth)
        .toDouble();
  }
```

- [ ] **Step 2: Update `CategoryBudgetBar` to render only visible width**

Import the geometry helper:

```dart
import 'budget_bar_geometry.dart';
```

In `CategoryBudgetBar.build`, compute remaining ratio and wrap the `Material` in a `LayoutBuilder`:

```dart
    final remainingRatio = bar.hasLimit && bar.limitAmount > 0
        ? (1.0 - spentRatio).clamp(0.0, 1.0).toDouble()
        : 1.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = BudgetBarGeometry.visibleWidth(
          availableWidth: constraints.maxWidth,
          height: height,
          ratio: remainingRatio,
        );
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: width,
            child: Material(
              key: const ValueKey('category-budget-bar'),
              color: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(height / 2),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(height / 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(height / 2),
                  child: SizedBox(
                    height: height,
                    child: ColoredBox(
                      key: const ValueKey('category-budget-remaining-fill'),
                      color: bar.color,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: iconLeftPadding),
                          child: Image(
                            image: CategoryIconManager.assetImage(bar.iconSlot),
                            width: compactIcon ? iconSize : height * 0.64,
                            height: compactIcon ? iconSize : height * 0.64,
                            color: AppColors.white,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.category_outlined,
                              color: AppColors.white,
                              size: compactIcon ? iconSize : height * 0.64,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
```

Remove the `category-budget-spent-overlay` branch entirely.

- [ ] **Step 3: Add a visible ratio helper for backheader items**

In `_CategoryBudgetStageState`, add:

```dart
  double _visibleRatioFor(BackheaderBudgetItem item) {
    final category = item.category;
    if (category != null) {
      if (!category.hasLimit || category.limitAmount <= 0) return 1.0;
      final spentRatio = (category.spent / category.limitAmount)
          .clamp(0.0, 1.0)
          .toDouble();
      return (1.0 - spentRatio).clamp(0.0, 1.0).toDouble();
    }
    final overview = item.overview;
    if (overview == null || !overview.hasLimit || overview.limitAmount <= 0) {
      return 1.0;
    }
    final progressRatio = (overview.amount / overview.limitAmount)
        .clamp(0.0, 1.0)
        .toDouble();
    if (overview.kind.warnsWhenHigh) {
      return (1.0 - progressRatio).clamp(0.0, 1.0).toDouble();
    }
    return progressRatio;
  }
```

- [ ] **Step 4: Size the gray mask to the active visible width**

Replace the current `budget-progress-frame-mask` `Positioned` child with a `LayoutBuilder` that computes visible width:

```dart
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = BudgetBarGeometry.visibleWidth(
                    availableWidth: constraints.maxWidth,
                    height: BudgetBarGeometry.barHeight,
                    ratio: _visibleRatioFor(current),
                  );
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      key: const ValueKey('budget-progress-frame-mask'),
                      width: width,
                      height: BudgetBarGeometry.barHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(
                            BudgetBarGeometry.radius,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
```

- [ ] **Step 5: Update `_OverviewBudgetBar` to render only visible width**

Replace the full-width `Material` return with the same `LayoutBuilder` and `Align` pattern. The inner colored content becomes a single solid `DecoratedBox` keyed as `category-budget-bar`; do not use `overview-budget-remaining-fill`.

Use this ratio:

```dart
    final visibleRatio = overview.kind.warnsWhenHigh
        ? (1.0 - spentRatio).clamp(0.0, 1.0).toDouble()
        : spentRatio;
```

Use this width calculation inside the builder:

```dart
        final width = BudgetBarGeometry.visibleWidth(
          availableWidth: constraints.maxWidth,
          height: height,
          ratio: visibleRatio,
        );
```

- [ ] **Step 6: Run category budget stage tests and verify pass**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart'
```

Expected: PASS.

- [ ] **Step 7: Commit visible bar changes**

Run:

```bash
git add lib/features/transactions/widgets/header_card/budget_bar_geometry.dart lib/features/transactions/widgets/header_card/category_budget_bar.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart test/transactions/category_budget_stage_test.dart
git commit -m "Shrink backheader budget bars by remaining limit"
```

---

### Task 7: Final Verification

**Files:**
- Verify all modified files from Tasks 1-6.

- [ ] **Step 1: Format modified Dart files**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/dart format lib/features/transactions/widgets/slide_up_panel_metrics.dart lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart lib/features/transactions/widgets/header_card/budget_bar_geometry.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart lib/features/transactions/widgets/header_card/category_budget_bar.dart test/transactions/transaction_home_limits_test.dart test/transactions/category_budget_stage_test.dart'
```

Expected: formatter exits with code 0.

- [ ] **Step 2: Run analyzer**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: `No issues found!`

- [ ] **Step 3: Run targeted tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_home_limits_test.dart test/transactions/category_budget_stage_test.dart test/widget_test.dart'
```

Expected: all tests in the three files pass.

- [ ] **Step 4: Run full test suite**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test'
```

Expected: all tests pass.

- [ ] **Step 5: Check git diff and status**

Run:

```bash
git diff --check
git status --short --branch
```

Expected: `git diff --check` exits 0. `git status` shows only intentional committed changes or a clean tree after the final commit.

- [ ] **Step 6: Commit final verification cleanup if formatter changed files after Task 6**

Run only if Step 1 changed files after the previous commits:

```bash
git add lib/features/transactions/widgets/slide_up_panel_metrics.dart lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart lib/features/transactions/widgets/header_card/budget_bar_geometry.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart lib/features/transactions/widgets/header_card/category_budget_bar.dart test/transactions/transaction_home_limits_test.dart test/transactions/category_budget_stage_test.dart
git commit -m "Polish limit card and backheader formatting"
```

Expected: a formatting-only commit, or no commit when there are no formatter changes.
