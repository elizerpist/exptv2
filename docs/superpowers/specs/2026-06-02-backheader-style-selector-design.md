# Backheader Style Selector Design

## Goal

Add a global Backheader settings menu that lets the user switch the transaction home backheader between the current bar system and six experimental layouts: A, B, C, D, E, and F. The goal is fast real-world comparison while keeping every existing backheader function available.

## Scope

This is a global visual setting, not a per-income/per-expense setting. It affects the backheader renderer used by the transaction home wherever the backheader is shown.

The setting options are:

- `classic`: current bar system
- `colorFieldPartition`: A - Color Field Partition
- `partitionDashboard`: B - Partition Dashboard
- `heroToken`: C - Hero Token
- `orbitBudget`: D - Orbit Budget
- `mosaicBudget`: E - Mosaic Budget
- `ledgerStrip`: F - Ledger Strip

The default and fallback is `classic`.

## Settings Model

Extend `AppThemeSettings` with a `backheaderStyle` enum. This is intentionally stored with the existing theme settings because the shell already loads and propagates `AppThemeSettings`, and the native settings store already persists these values through `expenseLoadSettings` and `expenseUpdateThemeSettings`.

Android `ExpenseSettingsStore` will persist the setting in SharedPreferences under `backheaderStyle`. Missing or unknown values map to `classic`.

## Settings UI

Add a new root item under `Megjelenítési beállítások`:

- `Backheader`

The submenu uses the existing `SettingsRadioOption` pattern. Each option has:

- title with `(jelenlegi)` suffix when selected
- short description
- compact preview thumbnail

Selecting an option immediately calls `updateThemeSettings`, persists it natively, updates shell state, and updates the transaction home without requiring restart.

## Backheader Rendering

`TransactionHomePage` already receives theme settings through the shell. It will pass `expenseTheme.settings.backheaderStyle` into `CategoryBudgetStage`.

`CategoryBudgetStage` will keep the same external contract:

- `items`
- `categoryBars`
- `periodLabel`
- `activeKey`
- `onActiveItemChanged`
- `onItemTap`

The stage chooses a renderer based on `backheaderStyle`. The existing implementation becomes the `classic` renderer. The A-F renderers share the same active item state and callbacks so behavior stays consistent.

## Required Behavior

Every style must preserve:

- tap active budget surface -> open limit editor
- horizontal swipe -> switch active backheader item
- long press on category item -> jump to the matching overview item
- active dots when multiple items exist
- active key synchronization with the budget editor
- stable 176 px backheader height
- no regression to the current category/overview amount display behavior

The experimental styles may change the visual interaction surface, but the same callbacks must fire.

## Visual Directions

Classic keeps the current category/overview bar system.

A, Color Field Partition: the whole backheader uses the active category color, and the shared partition strip is the main budget visual.

B, Partition Dashboard: a dark budget-map surface with partition blocks as the primary UI.

C, Hero Token: a large active category token/gauge with a small shared partition strip.

D, Orbit Budget: a category-colored card with a partition ring/orbit.

E, Mosaic Budget: a treemap-like mosaic where the active category is a highlighted tile.

F, Ledger Strip: a financial segment strip with an active label below it.

## Implementation Boundaries

Keep renderer code isolated. Avoid putting all A-F layout code into one large build method. Prefer small widgets such as:

- `BackheaderStyle`
- `BackheaderStylePreview`
- `BackheaderStyleOptionsPanel`
- `ClassicBackheaderRenderer`
- `ExperimentalBackheaderRenderer` helpers, split by visual family if needed

The first implementation can use simplified but functional versions of A-F. The priority is live selection and preserved interactions; pixel-perfect polish can follow after real in-app comparison.

## Testing

Add focused tests for:

- `AppThemeSettings.fromMap` and `toMap` include `backheaderStyle`
- missing/unknown native `backheaderStyle` falls back to `classic`
- settings page shows the Backheader menu item
- Backheader submenu displays `classic` and A-F options
- selecting a style calls `expenseUpdateThemeSettings` with `backheaderStyle`
- `CategoryBudgetStage` renders the selected style
- tap/swipe/long-press behavior remains wired for at least `classic` and one experimental style

Run targeted settings/backheader tests, then `flutter analyze`, then full `flutter test`.

## Risks

The main risk is mixing visual experimentation with existing gesture state. To reduce that risk, keep gesture/state ownership in `CategoryBudgetStage` and make renderers mostly presentational.

The second risk is native settings compatibility. The fallback to `classic` handles older persisted settings and missing native keys.

## Out Of Scope

- Per-income/per-expense style selection
- Per-category style overrides
- Final choice between A-F
- Full pixel-perfect polish for all six experimental styles
- Removing the current classic renderer
