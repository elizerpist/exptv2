# Limit Card and Backheader Alignment Design

Date: 2026-06-02

## Scope

This change is limited to the BudgetTargetEditor LimitCard layout and the expanded backheader budget/category bar presentation. It does not change transaction storage, parser behavior, scrolling, or persistence.

## Goals

- Align the LimitCard save button vertically with the existing AddTransaction and AddCategory save buttons.
- Preserve the visual distance between the limit input pill and the save button.
- Reorder the LimitCard content as: period label, avatar row, name, progress bar, slider, limit pill, save button.
- Keep the previous/next controls in the avatar row.
- Make the LimitCard avatar 20 percent smaller.
- Move the backheader active budget/limit/progress bar stack 5 px lower.
- Increase the backheader top-left category title by 10 percent.
- Make the top-right amount text the same font size as the title.
- Make category and budget bars shrink as spending increases, without rendering a transparent full-width remainder on the right.
- Keep a minimum bar width so the left icon remains visible.

## Current Findings

`BudgetTargetEditorSheet` currently places the save button in a fixed bottom area using `SlideUpPanelMetrics.budgetActionBottomInset = 68.0`. This keeps the limit input close to the save button, but it moves the LimitCard save button higher than the already aligned AddTransaction and AddCategory buttons.

`AddTransactionSheet` and `CategoryEditorPanel` already have a shared visual baseline in tests. The LimitCard should join that baseline instead of using a separate high bottom inset.

The current LimitCard title and period label are in one `Wrap`, while the requested layout needs the period label to move above the avatar and the title to sit below the avatar row.

`CategoryBudgetStage` currently uses `BudgetBarGeometry` for the bar and progress frame positions. The active title is 15 px and the amount is 13 px. The budget and category bars draw into a full-width container, using overlays/fills to imply spending state.

## Recommended Approach

Use a shared save-button baseline for all three sheets, then independently tune LimitCard content placement so the content gap remains correct.

The save button should no longer be raised to create the desired limit input gap. Instead, the LimitCard content should be laid out so that the limit input naturally ends close to the fixed save button. This separates two concerns:

- save baseline: common across AddTransaction, AddCategory, and LimitCard
- content rhythm: local to the LimitCard

For the backheader, compute the visible bar width from remaining budget and draw only that bar width. Do not draw a full-width transparent trailing area. Use a minimum width large enough for icon padding plus icon size.

## LimitCard Layout

The sheet keeps `SlideUpPanelMetrics.budgetBaseHeight = 432.0`.

The content order becomes:

1. drag handle
2. period label pill
3. avatar row with previous and next buttons still in the row
4. active item name
5. partition/progress bar
6. slider
7. limit amount input pill
8. fixed save button area

The avatar size changes from 62 px to approximately 50 px. The overview icon and category image scale down by the same 20 percent ratio.

The save button uses the same effective bottom baseline as the already aligned transaction/category buttons. The previous `budgetActionBottomInset = 68.0` should be removed or reduced to the shared action inset path, and tests should compare `limit-save-button.bottom` against `category-save-button.bottom` or the existing common baseline.

The limit input to save button gap remains protected by a separate test. Internal spacers may be tuned to preserve that gap, but the save button baseline remains the alignment anchor and must not move upward again to satisfy the gap.

## Backheader Layout

`BudgetBarGeometry.barCenterY` moves 5 px lower. Because frame top and bar top are derived from the center, this moves the active bar, progress frame, and gray mask together.

The active title font size changes from 15 px to 16.5 px. The active amount font size also becomes 16.5 px so letters and numbers match in visual size.

Dots stay at their current top position. The requested 5 px movement applies to the bar stack only.

## Bar Width Model

Both overview budget bars and category budget bars should expose a visible width:

```text
spentRatio = spent / limit
remainingRatio = 1 - spentRatio
visibleWidth = max(minWidth, fullWidth * remainingRatio)
```

For income/saving targets that grow toward a goal, the existing goal-progress direction can remain forward:

```text
visibleWidth = max(minWidth, fullWidth * progressRatio)
```

The visible bar is aligned left. No transparent trailing fill should be rendered to the right. The icon stays inside the visible bar.

Minimum width is `height * 1.20`, which covers the current icon left padding plus icon size and leaves a small right-side buffer. Overview and category bars use the same helper rule.

## Tests

Update or add widget tests for:

- LimitCard save bottom aligns with AddCategory save bottom within a small epsilon.
- Limit input to save button gap remains close enough.
- LimitCard renders period label above avatar and title below avatar.
- LimitCard avatar size is 20 percent smaller.
- Backheader title and amount use the same larger font size.
- Backheader bar stack is 5 px lower via `BudgetBarGeometry`.
- Category budget bar width shrinks as spending increases.
- Overview budget bar draws the visible bar width directly instead of a full-width transparent remainder.
- Minimum bar width keeps an icon-sized area visible when spending reaches or exceeds the limit.

## Non-Goals

- No transaction list scroll changes.
- No parser changes.
- No storage or repository changes.
- No redesign of AddTransaction or AddCategory layouts beyond using them as save-button alignment references.
