# Backheader And Limit Editor Polish Design

Date: 2026-05-29
Project: exptv2
Branch: feature/backheader-budget-goals

## Goal

Polish the header and expanded backheader layout, then redesign the limit editor as an autosaving allocation tool with a synchronized partition bar and interactive pie chart for both expense and income flows.

This change is implemented as one large feature pass on the existing `feature/backheader-budget-goals` branch.

## Header Changes

The header card keeps the existing component structure, but its magnet/balance layout changes:

- Move the magnet strip 20 px higher.
- Place the `Egyenleg` label into the visual magnet strip zone.
- Keep the balance value and hide-balance icon functional.
- Preserve the header card shadow during slide and drag states.

The intent is to make the magnet strip and balance label read as one grouped header area instead of two disconnected vertical zones.

## Backheader Layout

The expanded backheader keeps the same swipeable `CategoryBudgetStage`, but its spacing and visual alignment change:

- Move the active title and amount row lower so the text top is never clipped.
- Add the active summary period label to the gray backheader surface, bottom-left:
  - monthly view: current month and year
  - yearly view: current year
  - all-time view: `Sum`
- Keep period-specific limits separate. Monthly, yearly, and all-time each continue to read/write their own overview and category limits through the existing `window` and `periodKey` fields.
- Reduce swipe travel. The user should need less horizontal drag to trigger a switch, and the visible drag offset should be smaller.
- Reduce snap-back bounce. The active bar should jump from a short side offset and settle quickly without the large elastic movement.

The backheader item and the limit editor must stay synchronized: if a user changes active category/goal in the editor, the backheader active bar changes to the same item.

## Progress Frame And Bar Geometry

The budget progress frame behind the active bar should be a true centered frame:

- The active category or overview bar sits exactly in the center of the progress frame.
- The progress frame is larger by the same visual amount on all four sides.
- Top, bottom, left, and right overhangs should feel proportional, not wider on the sides than vertically.
- If this requires changing the active bar width/height or radius, prefer a shared geometry helper over local magic numbers.

Border and clipping behavior must be exact:

- The normal white border must follow the pill path.
- Warning and danger borders must use the same path as the normal border. Orange/red borders must not clip or square off the pill corners.
- The partial colored progress frame segments must be clipped to the same outer pill path.
- Edge segments must not touch or bleed into the border.
- Inner segments may meet each other with straight edges, but the first and last visible segments must respect the outer curve.

## Limit Editor Mode

The limit editor becomes autosave-only:

- Remove `Mentés`.
- Remove `Mégse`.
- Remove the bell/alert control because limit alerts are not relevant here.
- Every interaction saves immediately:
  - slider changes
  - manual input after commit/debounce
  - reset icon in the input
  - pie chart tap/drag
  - category/goal navigation arrows

Because autosave can issue many updates, drag-based changes should save at controlled points:

- Sliders save on the settled changed value.
- Manual typing saves after a short debounce or on field submit/focus loss.
- Pie drag saves in 1000 Ft increments only when the snapped value changes.

The sheet still reloads from `TransactionStore` after saves so the backheader, partition bar, and pie chart reflect persisted state.

## Limit Card Layout

Replace the current editor sheet layout with a single focused limit card:

1. Header row:
   - left arrow button for previous limit target
   - centered round avatar with category/goal icon
   - right arrow button for next limit target
2. Target name below the avatar.
3. Limit input pill below the name.
   - Contains the editable amount.
   - Contains a reset icon inside the input pill.
   - The reset icon clears the limit and immediately saves.
4. Slider below the input.
   - Uses 1000 Ft steps.
   - Manual input remains free-form and can save non-rounded values.
5. Partition bar below the slider.
   - 30% lower height than the current partition bar.
   - Rounded-square shape, not pill-shaped.
6. Interactive pie chart below the partition bar.

The old `CategoryLimitEditorSheet` can remain as a compatibility wrapper, but production UI should use the redesigned `BudgetTargetEditorSheet`.

## Slider Rules

All sliders use 1000 Ft steps.

Manual input can save exact values such as `756243`; the slider should not be analog and should not create arbitrary non-step values.

Overview budget/goal sliders:

- Expense budget max:
  - monthly view: current period monthly income
  - yearly view: current period yearly income
  - all-time view: total income
- Income goal max:
  - same period income basis as above, with a fallback when income is zero
- Saving goal max:
  - same period income basis as above
- The right side of the overview slider has an end/reset button.
  - It sets the overview limit to the slider max.
  - It immediately saves that max value.

Category sliders:

- Matching overview limit is the 100% allocation base.
- Category max is:

```text
available = overview limit - sum(other category limits)
max = available + current category limit
```

- If matching overview has no limit, category editing remains possible manually, but partition/pie cannot show meaningful free budget.
- If other categories already consume 100% of the overview budget and the current category has no allocated limit, the slider is disabled and gray.
- A category with an existing limit can still reduce its own limit even when free budget is zero.

The income side follows the same allocation rules using income goal and income categories.

## Partition Bar

The partition bar is a compact rounded-square allocation view:

- It is 30% less tall than the current partition bar.
- It uses the same allocation data as the pie chart.
- It shows:
  - full-opacity category color for spent/earned part inside that category allocation
  - lower-opacity category color for remaining allocation
  - gray for unallocated overview space
- It respects the active summary window and period key.

For expense:

```text
Budget = 100
Food limit = 50, Food spent = 25

Partition:
25 full Food color
25 faded Food color
50 gray
```

For income:

```text
Income goal = 100
Salary limit = 70, Salary earned = 40

Partition:
40 full Salary color
30 faded Salary color
30 gray
```

Saving goal does not use category partitioning.

## Interactive Pie Chart

Add an interactive pie chart under the partition bar.

The pie chart and partition bar are two renderings of the same allocation model:

- category limit slices
- used/earned portion
- remaining allocated portion
- unallocated gray portion

Interactions:

- Tap a slice:
  - makes that category the active limit card
  - updates the backheader active bar to the same category
- Swipe or drag a slice edge:
  - grows or shrinks that slice's category limit
  - snaps to 1000 Ft increments
  - respects the matching overview free allocation
  - immediately saves when the snapped limit changes

The user can adjust any category from any active card through the pie chart. The active card changes only on explicit tap or arrow navigation, not merely because another slice was dragged.

## Navigation And Synchronization

The editor target list mirrors the backheader list for the active transaction side:

- expense side: budget overview, then expense categories
- income side: income goal, saving goal, then income categories

The card header arrows move to neighboring targets in that list.

When the active editor target changes:

- the editor card updates
- the backheader active bar updates
- the title/amount row updates
- dots update
- the progress frame uses the relevant overview target for the active side

## Persistence

Continue using the existing `category_limits` persistence model:

- overview budget/goal:
  - `targetType = overview`
  - `targetId = 0`
  - `transactionType = expense`, `income`, or `saving`
- category limits:
  - `targetType = category`
  - `targetId = category id`
  - `transactionType = expense` or `income`
- window and period:
  - `window = monthly`, `yearly`, or `all_time`
  - `periodKey` comes from the active summary window

Autosave calls should go through `TransactionStore` so the existing native bridge and reload flow remain the source of truth.

## Testing

Add or update tests for:

- Header magnet top is 20 px higher and balance label sits in the magnet zone.
- Backheader title row is lower and period label appears bottom-left.
- Backheader progress frame centers the active bar with equal overhang.
- Warning/danger frame border uses the same rounded path as the normal border.
- Progress frame segments are clipped inside the border.
- Swipe switches with shorter travel and smaller snap-back offset.
- Overview slider uses period income as max and end button saves that value.
- Category slider disables when free budget is zero and current category has no limit.
- Category slider remains able to reduce an existing limit when free budget is zero.
- Slider values snap to 1000 Ft, while manual input can save exact values.
- Autosave removes save/cancel/bell controls and persists on interactions.
- Partition bar uses compact rounded-square geometry.
- Pie chart renders the same allocation as the partition bar.
- Pie tap changes active target and syncs backheader.
- Pie drag adjusts the target category in 1000 Ft increments and persists.
- Income side supports the same editor flow.

Local Termux Flutter may fail with the Dart TLS alignment issue. If that happens, use the GitHub Actions Android workflow as the verification source.
