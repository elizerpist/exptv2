# Backheader Budget, Income Goal, and Saving Goal Design

Date: 2026-05-29
Project: exptv2

## Context

The existing expanded header shows swipeable category budget bars through `CategoryBudgetStage`. Category bars are currently built from `CategoryBudgetBarData`, and category limits are stored in the existing `category_limits` table.

The existing backheader background outline currently uses category limit partition data. That is not the desired behavior anymore. The new behavior is that overview targets define 100%, and the background progress shows actual period progress against that overview target.

The existing data model already supports `targetType = overview` in `category_limits`, so the new design should reuse that model instead of introducing a separate table.

## Approved Product Model

The backheader has three overview target concepts:

- Expense budget: maximum spend target for the active period.
- Income goal: minimum income target for the active period.
- Saving goal: target for money retained in the active period.

The expanded backheader swipe order is:

- Expense tab: `Budget`, then expense categories.
- Income tab: `Beveteli cel`, `Megtakaritas`, then income categories.

All overview and category items should use the same pill-like bar family so the UI feels consistent. Overview items behave like "sum category" bars, but they are not tied to a concrete transaction category.

## Storage

Reuse `category_limits`:

```text
Expense budget:
targetType = overview
targetId = 0
transactionType = expense

Income goal:
targetType = overview
targetId = 0
transactionType = income

Saving goal:
targetType = overview
targetId = 0
transactionType = saving
```

For category limits:

```text
targetType = category
targetId = category id
transactionType = expense or income
```

Native validation should allow `transactionType = saving` only for overview targets. Category targets should continue to allow only `expense` or `income`.

All limits remain scoped by:

- `window`: monthly, yearly, or all-time
- `periodKey`: same key format as existing summary windows

## Progress Calculations

Expense budget:

```text
progress = period expense / expense budget limit
```

The background progress bar is visible only when an expense budget limit exists. The bar's 100% is the configured budget. Only categories with spending in the active period appear as colored segments. Remaining capacity is gray. Border state:

- below 75%: normal
- 75% to below 90%: orange
- 90% and above: red

Income goal:

```text
progress = period income / income goal
```

The background progress bar is visible only when an income goal exists. Only income categories with actual income in the active period appear as colored segments. Reaching 100% is a success state, not a warning state.

Saving goal:

```text
progress = max(0, period income - period expense) / saving goal
```

Saving progress is not category-partitioned. It uses one saving-colored fill segment. If the period balance is negative, progress is zero. Reaching 100% is a success state.

## Background Progress Bar

The backheader background progress bar replaces the old category limit outline behavior.

Rules:

- It appears only if the currently relevant overview target has a configured limit/goal.
- Shape matches the category pill shape, but is about 10% larger so it reads as a frame around the active bar.
- It is not a rounded box; it should look like the same pill family as the category bars.
- Its fill segments represent actual period activity, not configured category limit sizes.
- Categories with no period activity are omitted from the colored fill.
- Unused space remains gray.

For example:

```text
Budget = 100 HUF
Food spent = 50 HUF
Travel spent = 25 HUF
Other categories spent = 0 HUF

Progress bar:
50% Food color, 25% Travel color, 25% gray
```

## Category Bar Display

The inner thin `CategoryProgressBar` should be removed from category bars.

The category pill itself becomes the progress visualization:

- Full pill shape remains visible.
- Left portion has max opacity and represents used amount.
- Right portion has lower opacity and represents remaining category limit/capacity.
- The bar should not grow when progress increases. It should visually decrease remaining opacity instead.

Category bar text is moved out of the pill:

- Top-left on gray backheader area: category or overview name.
- Top-right on gray backheader area: period amount, or `x/y` when a limit/goal exists.
- Text should use dark color on the gray backheader background.

For category bars without a category limit, the full pill remains max opacity and the top-right text shows only period amount.

## Limit and Goal Editor Workflow

Use one common editor sheet for all target types:

- expense overview budget
- income overview goal
- saving overview goal
- category limit

Workflow:

1. User taps an overview or category bar.
2. The common editor opens.
3. It shows a preview bar.
4. It shows the relevant partition/progress bar.
5. It shows slider plus manual amount input.
6. Save persists the limit/goal for the active summary window and period key.

Expense budget editor:

- Slider max defaults to the current period total income.
- Manual input can exceed the slider max, similar to stats threshold editing.
- If there is no configured budget yet, the partition bar is gray.

Income goal editor:

- Slider max can default to current period income or a sensible unit fallback.
- Manual input can exceed slider max.

Saving goal editor:

- Slider max can default to current period income.
- Manual input can exceed slider max.
- No category partition is shown because saving is calculated from income minus expense.

Category limit editor:

- It depends on the matching overview target.
- Category max is the remaining unallocated overview space:

```text
category max = overview limit - sum(other category limits)
```

- The currently edited category's existing value is excluded from `other category limits`.
- If no overview target exists, category limit editing may still allow a manual amount, but the partition bar cannot show a meaningful 100% overview background.

Category partition display:

```text
Budget = 100 HUF
Yellow category limit = 50 HUF
Yellow spent = 25 HUF

Partition:
25% full opacity yellow
25% 0.7 opacity yellow
50% gray
```

## Header and Swipe Animation

Header card:

- Magnet strip becomes 50% taller.
- Magnet strip should not be pill-shaped. It should be slab-like with straight edges or only tiny corner rounding.
- Header pull release should keep the current smooth slide but use a stronger spring:
  - faster return
  - visible overshoot
  - short bounce settle
- Header card shadow must remain visible during slide.

Backheader bar swipe:

- Do not use slide-out/slide-in carousel behavior.
- Gesture crosses threshold, then data switches immediately like `SummaryPill`.
- New bar starts from a 2-3 cm horizontal offset and snaps back to center.
- The background progress bar remains visible during this interaction.

Indicator dots:

- Inactive dots are white.
- Active dot uses the FAB blue color.

## Components and Data Flow

Recommended new or refactored units:

- `OverviewBudgetData`: represents expense budget, income goal, or saving goal.
- `BudgetGoalKind`: `expenseBudget`, `incomeGoal`, `savingGoal`.
- `BudgetProgressSegment`: color, amount, and fraction for background progress fill.
- `BudgetProgressManager`: pure calculation helper for overview progress and segments.
- `BudgetTargetEditorSheet`: common editor for overview targets and category limits.

`TransactionStore` should expose:

- current overview targets for active window and period
- current category bars
- current backheader item list: overview items plus category items
- save method for overview target
- save method for category target

`LimitManager` can continue building category bars, but overview progress should use a separate calculation helper because it has different semantics from category limit partitions.

## Error Handling

- Negative limit/goal input is treated as zero or rejected before save.
- Native validation rejects `saving` for category targets.
- If an overview target is missing, hide the background progress bar.
- If transaction totals are zero, progress fractions should be zero and no colored segments should render.
- If progress exceeds 100%, visual fill should clamp to 100%, while text still shows actual `x/y`.

## Testing

Add or update tests for:

- Overview targets save with correct `targetType`, `targetId`, `transactionType`, `window`, and `periodKey`.
- Native validation accepts overview `saving` and rejects category `saving`.
- Expense budget progress includes only categories with period spending.
- Expense budget remaining space is gray.
- Income goal progress includes only categories with period income.
- Saving goal uses `income - expense`.
- No overview target means no background progress bar.
- Category editor max equals remaining unallocated overview space.
- Category bar no longer renders inner thin progress bar.
- Category name and amount render on the gray backheader surface.
- Swipe switches data immediately and snaps back from horizontal offset.
- Header magnet strip height and slab shape are stable.

## Out of Scope for This Pass

- New stats redesign for goal analytics.
- Long-term envelope allocation system.
- Notification rules for income and saving goals beyond storing alert state.
- Any new database table.
