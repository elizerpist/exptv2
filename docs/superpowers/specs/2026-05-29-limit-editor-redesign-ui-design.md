# Limit Editor Redesign And Header UI Design

Date: 2026-05-29

## Scope

Redesign the budget/category limit editor as the primary interaction surface for
all period limits, remove the pie chart, and align the related backheader,
summary pill, and header-card gestures with the requested behavior.

This spec covers:

- The redesigned limit editor.
- Partition bar interaction.
- Budget and category slider range behavior.
- Backheader category and budget bar progress visuals.
- Backheader swipe behavior.
- Summary pill swipe and double-tap behavior.
- Header-card transition and balance positioning.

## Limit Editor

The limit editor becomes a full-height bottom panel that visually reaches the
bottom of the screen, matching the add-new-transaction menu behavior. It should
not leave a visible gray safe zone above Android navigation.

The editor keeps the current autosave model. Save and cancel buttons remain
absent. Every slider, text input, reset button, category switch, and partition
bar tap persists immediately through the existing store save methods.

The top card layout is rebuilt around the selected target:

- Left and right arrows select the previous or next budget item.
- The center shows a circular avatar/icon, then the target name.
- The limit amount is editable in a compact input pill.
- The reset action is an icon inside or directly attached to the input area.
- The slider uses 1000 HUF steps for drag interactions.
- The partition bar sits below the slider and is the only allocation chart.

The pie chart is removed from the editor and no replacement radial chart is
introduced in this work.

## Partition Bar

The partition bar remains the allocation overview. When an overview budget limit
exists, 100% means the active period's overview limit. Category limit subbars are
laid out proportionally inside that total.

Subbars with a category target are tappable. Tapping a subbar selects that
category's limit card in the editor and updates the active backheader item to
the same category. Gray/free segments are not category navigation targets.

The bar must still render a stable empty/gray state when no overview budget
limit exists.

## Slider Range

Both overview budget sliders and category limit sliders use the same range
rules:

- If there is no constraining overview budget/income value, the default max is
  100000 HUF.
- Slider drag steps are 1000 HUF.
- Manual input may exceed the current max.
- Once a higher manual value has been entered, the slider remembers a high-water
  max so the thumb can be dragged back up to that value.
- Reducing the current value must not immediately shrink the max to the thumb
  position. This prevents the broken state where the amount changes but the
  thumb cannot move back upward.

When an overview budget exists, category sliders are still constrained by the
free allocation space left by other category limits. If no free space exists and
the active category has no existing limit, the slider is disabled/gray until
space is freed.

## Backheader Progress Visuals

The backheader keeps separate behavior for category bars and budget/overview
bars.

Category bars:

- A category with a limit always shows the full limit width.
- With 0 spending, the whole bar is max opacity.
- As spending increases, the spent part becomes low opacity and the remaining
  part stays max opacity.
- Example: for 1000 HUF spent from a 10000 HUF limit, 10% is low opacity and
  90% is max opacity.
- The bar's shape remains pill-like and clipped consistently.

Budget/overview bars:

- Budget bars shrink in width as the available amount is consumed.
- The right edge stays pill-shaped while shrinking.
- They do not use the category opacity-progress behavior.

The background progress frame remains visible only when the relevant overview
limit exists. It continues to represent spent/used allocation against the
overview limit.

## Backheader Gesture Behavior

Backheader bar swipe behavior changes from threshold-triggered switching to
release-triggered switching:

- Dragging moves the bar visually but does not switch the selected item yet.
- The user can hold the bar indefinitely in the dragged offset state.
- On release, if the drag is far enough, the active item switches and the new
  bar snaps back to center.
- If the drag is too short, the current bar simply returns to center.
- The maximum side offset is reduced to roughly half of the current behavior.

A small button is added to the backheader's lower-right corner. Pressing it
selects the overview budget item regardless of the currently active category.

## Summary Pill Gestures

The summary pill gesture mapping is swapped:

- Vertical swipe cycles the summary interval: monthly, yearly, sum.
- Horizontal swipe shifts the active period within the current interval:
  previous/next month in monthly view and previous/next year in yearly view.
- Horizontal swipe does nothing in sum view.
- Double tap resets the store to monthly view for the current calendar month.

The summary title and amount continue to update immediately with no text fade
animation.

## Header Card

When entering the backheader view, the header card should slide up into its
expanded position instead of visually jumping. When leaving backheader view, it
slides back down.

The balance label and balance amount move 10 px lower than their current
positions.

Existing fast-info pullback spring behavior remains in place unless directly
affected by the expanded/collapsed transition.

## Testing

Automated coverage should include:

- The pie chart is absent from the editor.
- Partition bar category subbar tap selects the matching category and syncs the
  active backheader item.
- Slider fallback max is 100000 HUF and divisions represent 1000 HUF steps.
- Manual high input preserves an adaptive slider max after dragging downward.
- Category bar opacity shows full-strength remaining limit and low-opacity spent
  progress.
- Budget/overview bars shrink while keeping a pill-shaped right edge.
- Backheader switching occurs on drag release, not during drag update.
- Backheader drag offset is reduced.
- Summary pill vertical swipe cycles the interval.
- Summary pill horizontal swipe shifts the period.
- Summary pill double tap returns to the current monthly view.
- Header expanded/collapsed transition uses slide animation without jumping.

Local Flutter commands may fail in the Termux environment because the Flutter
binary has an ARM64 TLS alignment issue. GitHub Actions remains the source of
truth for full analyze/test/build verification.
