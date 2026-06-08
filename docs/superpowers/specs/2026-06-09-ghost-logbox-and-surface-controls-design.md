# Ghost Logbox And Surface Controls Design

## Scope

This feature changes the monthly transaction log presentation and theme controls for recurring ghost transactions. It does not add ghost rows to yearly or all-time views.

The work has three parts:

- Monthly ghost rows are stable and pinned to the top of the active month.
- Ghost logboxes get configurable visual treatment.
- The old global neumorphism toggle is replaced with component-level surface controls.

## Current Context

Normal transaction rows are rendered by `TransactionLogBox`. Recurring projected rows are rendered by `RecurringGhostLogBox`. The store builds display rows by merging records and ghosts, sorting the combined list, and then adding date headers.

Theme settings currently include a global `designProfile` plus `buttonSurfaceStyle` and `contentSurfaceStyle`. `ExpenseTheme` derives button surfaces as `raisedInset` under neumorphism and content/logbox surfaces as `insetInset`.

## Ghost Row Ordering

Ghost rows appear only in monthly view. For the active monthly period, pending ghosts must render as a separate block at the top of that month, before real transactions, regardless of the ghost due date.

The monthly display order is:

1. All visible ghost rows for the active month.
2. The existing date headers and real transaction rows sorted by the existing transaction order.

This does not require adding a new month header. The ghost block appears at the top of the monthly log list, before the first normal date header.

When a ghost becomes a real transaction, it leaves the ghost block and appears as a normal transaction in its normal chronological position.

Yearly and all-time views do not render ghost rows.

## Ghost Render Stability

Ghost rows must not disappear for a frame during month changes, store reloads, or manual transaction saves.

The store should keep the last stable ghost projection visible while a new monthly projection is in flight. It should replace the ghost view only after the projection for the requested month completes. If the result is empty, the empty state is applied after completion, not during the loading gap.

Manual transaction saves must not clear the visible ghost cache until the replacement ghost data is ready. Activated ghosts should still disappear when they are genuinely activated or when the new stable projection excludes them.

## Component Surface Controls

The global neumorphism profile is removed from the user-facing theme UI. Surface style becomes component-level.

The settings model should persist explicit component choices:

- Buttons: normal or neumorph.
- Logboxes/content: normal or neumorph.
- Ghost logboxes: normal or neumorph.

The meaning is fixed:

- Button neumorph uses `ExpenseSurfaceInteraction.raisedInset`.
- Logbox neumorph uses `ExpenseSurfaceInteraction.insetInset`.
- Ghost logbox neumorph uses `ExpenseSurfaceInteraction.insetInset`.
- Normal uses `ExpenseSurfaceInteraction.neutralNeutral`.

The legacy `designProfile` remains only as a migration input. When old settings load with `designProfile = neumorphism`, defaults migrate to:

- Buttons: neumorph.
- Logboxes/content: neumorph.
- Ghost logboxes: neumorph.

After migration, the UI should not expose one global neumorphism switch.

## Ghost Logbox Settings

The theme area gets a `Ghost logbox` submenu. It controls only `RecurringGhostLogBox`.

Settings:

- Surface: normal or neumorph.
- Border: normal or dashed.
- Background opacity: on or off.
- Avatar opacity: on or off.
- Text opacity: on or off.
- Avatar ghost badge: on or off.
- Text and amount color: normal or gray.
- Expected label: on or off.

Default values:

- Surface: normal unless migrated from legacy neumorphism.
- Border: dashed.
- Background opacity: on.
- Avatar opacity: off.
- Text opacity: off.
- Avatar ghost badge: on.
- Text and amount color: normal.
- Expected label: on.

The label text is user-facing Hungarian: `Várható`. If the secondary line is enabled and the row is recurring, use `Várható · ismétlődő`.

## Ghost Badge

The avatar badge should sit at the avatar's bottom-right corner. Use a local vector/SVG asset for the ghost icon rather than depending on a Material ghost icon, because the Material icon set may not contain a stable ghost glyph across Flutter versions.

The badge should be small enough not to hide the category identity. The category avatar remains the primary visual; the ghost badge is an overlay state marker.

## Visual Rules

Ghost rows must look pending, not disabled.

Opacity should be moderate:

- Background opacity should still leave the row shape readable.
- Avatar opacity should never make the category unrecognizable.
- Text opacity should preserve scan readability in long lists.

If the ghost surface color matches the page background, dashed border and badge become the primary visual markers. Do not rely on opacity alone in that case.

## Settings UI

Use compact controls:

- Segmented controls for normal/neumorph and normal/dashed choices.
- Switches for boolean ghost treatments.

Even if the visual control resembles a slider, the stored value should be an enum or boolean, not an arbitrary numeric slider. These settings are discrete state choices.

## Testing

Add tests for:

- Monthly display rows place ghosts before real transactions.
- Yearly and all-time views do not render ghosts.
- Month projection reload keeps previous ghost rows visible until replacement data arrives.
- Manual transaction save does not clear ghost rows during reload.
- Legacy `designProfile = neumorphism` migrates to component-level neumorph settings.
- Button neumorph maps to `raisedInset`.
- Logbox and ghost logbox neumorph map to `insetInset`.
- Ghost logbox settings render dashed border, opacity choices, badge, gray text, and expected label independently.

## Non-Goals

- No yearly ghost rendering.
- No numeric opacity slider in the first version.
- No global neumorphism switch in the new UI.
- No unrelated transaction sorting changes outside the monthly ghost block behavior.
