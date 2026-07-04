# Category Sheet And Orbit Backheader Design

## Scope

This design covers two related home-screen changes:

- Fix the slide-up category menu so it behaves like a foreground sheet, covers the bottom navigation/FAB area, keeps the bottom add-category pill visible, and only drags from its handler.
- Redesign only the `orbitBudget` backheader style and move budget/limit editing for that style into the backheader itself, with immediate slider persistence and no separate save button.

Classic and hero-token backheader styles keep their current layout and existing external limit editor behavior.

## Category Sheet

When `categoryMenuPresentation == slideUpSheet`, the category menu must be a foreground overlay above the shell navigation. The bottom nav and FAB must not remain visible or tappable through the sheet. The existing inline category menu mode remains unchanged.

The slide sheet keeps the bottom `Új kategória` pill. The pill sits above the device bottom safe area and remains visible at the bottom of the sheet. Tapping it opens the existing add-category sheet above the picker, while the category sheet remains mounted behind it.

The category sheet can only be dragged from the top handler. Dragging or scrolling the grid content never moves the sheet. Horizontal and diagonal gestures must not close or move the sheet. A downward drag from the handler follows the existing slide-up semantics: free movement while dragging, snap back before the dismiss threshold, close after the threshold, and close on a fast downward handler swipe.

## Orbit Budget Backheader Layout

Only `BackheaderStyle.orbitBudget` changes. The current color background remains. The current orbit chart and center letter avatar are removed.

The collapsed card layout becomes:

- left: the real category icon for category items, or the existing overview icon for overview items;
- around that icon: a white circular progress ring only when the active item has a limit;
- middle: the item name;
- right: amount text, using the same amount formatting as the current backheader item;
- bottom: the same partition progress bar component and allocation logic currently used by the limit editor sheet.

For category items, the white circular progress ring uses `spent / limitAmount`, clamped to 0-1 for the visual arc. No ring is drawn when `hasLimit` is false or `limitAmount <= 0`. Overview items use the overview amount and limit with the same clamped visual rule.

## Inline Orbit Editor

In `orbitBudget` mode, tapping or dragging the backheader no longer opens `BudgetTargetEditorSheet`. The budget/limit editor content is embedded into the colored backheader surface.

The colored surface has a handle near its bottom edge. Dragging down from that handle expands the colored backheader. Dragging elsewhere must preserve the horizontal backheader item swipe behavior and must not start vertical expansion. Diagonal gestures are ignored unless they clearly resolve to the intended axis.

The expanded height is capped at the bottom edge of the income/expense button row. That is the expansion trigger point. When the drag reaches this trigger for the first time, the app sends one selection haptic tick. If the user releases after reaching the trigger, the backheader stays expanded. If the user releases before reaching the trigger, it snaps back to the collapsed height.

Expanded content reveals the current limit editor controls inside the backheader: partition bar, slider, amount display/input as space allows, reset/max affordances where applicable, and previous/next item navigation if already present in the editor model. There is no dedicated save button in this inline editor.

Slider changes persist immediately. On every slider change, the store save method is called for the active overview/category item, and the ring, amount text, and partition bar update from the pending value immediately. Closing/shrinking the editor does not trigger a save; saving is independent from the close gesture.

When already expanded, the user can drag the handle about 10 px further downward to arm a shrink-back trigger. The app sends a haptic tick when the shrink trigger arms. The user can cancel the shrink by dragging back into the expanded resting range; another haptic tick marks the cancel. Releasing while the shrink trigger is armed collapses the inline editor back to the normal orbitBudget height.

## State And Data Flow

`TransactionHomePage` remains the owner of active backheader item state. For orbitBudget, it passes save callbacks and budget data into `CategoryBudgetStage` instead of opening the shell-hosted `BudgetTargetEditorSheet`.

The inline editor reuses existing limit calculation helpers:

- `LimitSliderRange` for slider bounds and snapping;
- `LimitAllocationManager` for overview/category allocation and partition data;
- `CategoryLimitPartitionBar` for the partition visual;
- store methods `saveOverviewLimit` and `saveCategoryLimitForBar` for immediate persistence.

The separate `BudgetTargetEditorSheet` remains for classic and hero-token styles, and for any shell-level entry point that still explicitly requests it.

## Testing

Tests must be written before implementation. Required coverage:

- slide-up category sheet covers bottom nav/FAB and shows the bottom add pill;
- category sheet content scroll does not drag the sheet;
- category sheet handler drag snaps back before threshold and dismisses after threshold or fast swipe;
- orbitBudget renders icon/name/amount/partition bar and no old orbit chart/letter avatar;
- orbitBudget limit ring appears only for active limited items and reflects changed slider values;
- orbitBudget inline editor expands only from its handle, does not interfere with horizontal item swipe, and ignores diagonal drags;
- orbitBudget slider saves immediately through the store callbacks and does not require a save button;
- classic and hero-token backheader modes keep the current separate budget editor behavior.

## Self-Review

- No open design decisions remain after the user's immediate-save clarification.
- Scope is limited to slide-up category menu behavior and `orbitBudget`; unrelated backheader styles stay unchanged.
- The design avoids silent close-time saving: only slider edits save, and close/shrink is visual state only.
