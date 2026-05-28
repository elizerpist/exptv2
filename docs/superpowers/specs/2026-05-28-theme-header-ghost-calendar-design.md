# Theme, Header, Ghost Recurring, Calendar Design

Date: 2026-05-28

## Scope

This spec covers the next exptv2 implementation pass:

- Apply user-selected theme settings to the visible app, not only the settings menu.
- Port the original expt0926 magnet strip behavior more accurately.
- Make Header Card and FastInfo behave as one visual unit.
- Improve BackHeader trigger reliability and budget/category bar feedback.
- Implement recurring transaction ghost logboxes with a native Android database model.
- Fix calendar/category overlay sizing, calendar month-card layout consistency, and add the original chart presence where it belonged.
- Filter the category menu by the currently active transaction type.

## Source Findings

The original expt0926 implementation uses these key files:

- `themeoptions.js`: defines theme choices and magnet preview behavior.
- `magnet.js`: renders the actual strip based on `magnetType`.
- `backheader-stage0.js`: Header Card, FastInfo, pull-down spring-back, fixed arrow behavior.
- `backheader-stage1.js`: category/budget bars, `x/y` progress feedback, horizontal bar swipes.
- `calendarmenu.js` and `monthcard.js`: four calendar modes and month-card sizing.
- `chartboxcategory.js`, `kordiagram.js`, `PieChart.js`: category charts including donut/pie-style views.
- `recurringtransactionlogbox.js`: recurring notification/logbox visual style.

Important source behavior:

- FastInfo is positioned offscreen above the header and moves with the header. It shares the header background, so it should read as one continuous card area.
- Header pull-down uses a spring reset to zero. It does not stay open.
- `magnetcard` is not a filled bar. It is a transparent strip with top and bottom border lines plus a vertical marker using balance text color at alpha 0.4.
- `adaptive` is a pill-shaped strip whose width follows the income ratio.
- Regular summary/balance calculations should only include real transactions.

## Theme Application

`AppThemeSettings` will become an app-level state source instead of a settings-only value.

The shell will load settings once at startup through `NativeBridge.expenseLoadSettings()`, pass the current settings down to home/settings pages, and update the same state after theme changes.

Theme effects:

- `cardColor` controls the Header Card, FastInfo background, slide-up menu cards where relevant, and card-like surfaces copied from the original.
- `backgroundColor` controls the app root background.
- `boxColor` controls transaction logbox and recurring ghost logbox background.
- `theme` controls the primary accent color for FAB, selected controls, action circles, and active outlines.
- Existing hardcoded color constants can remain as defaults, but components receiving settings should prefer the active settings.

## Magnet Strip

Create a reusable Dart magnet painter/widget, used by both Header Card and theme previews.

Modes:

- `fade`: full-width horizontal gradient from rgba(44,44,44,0.3) to rgba(44,44,44,0.05).
- `nofade`: full-width sharp transition at the income-ratio split. Left is max opacity, right is min opacity.
- `budget`: full-width red/green budget gradient matching the original preview intent.
- `magnetcard`: transparent strip with top and bottom border lines and a vertical marker at the income-ratio split. No filled background.
- `adaptive`: pill strip with dynamic width based on income ratio, using the selected primary/accent color.

The painter will derive total income/expense from real transactions only. Ghost transactions never influence the strip.

## Header And FastInfo

Header Card and FastInfo will be composed under one wrapper so their backgrounds align and the header shadow does not visibly fall over FastInfo.

Behavior:

- Pulling the header down reveals FastInfo while dragging.
- Releasing always springs back to closed/offscreen, matching expt0926.
- The expand/backheader button remains visually fixed at the lower backheader edge.
- The button gets a larger invisible hit area so it is easier to trigger.
- After a swipe interaction, tap still works. Gesture state must reset reliably.
- FastInfo content is not a separate modal; it is offscreen content attached to the header visual group.

## BackHeader Category/Budget Feedback

When the backheader/category-budget stage is visible, each visible bar should show progress text using the current period data:

- category/overview name
- spent amount and limit amount as `x/y`
- percent can remain secondary if already present

The same `LimitManager` period rules remain authoritative:

- `sum` uses all-time limits.
- `monthly` uses the selected month key.
- `yearly` uses the selected year key.

The bar display reads from the active type and current summary window. It must stay in sync when summary pill changes month/year/sum mode.

## Recurring Ghost Transactions

Recurring rules and visible ghost logboxes will be separate native concepts.

Tables:

- `recurring_transactions`: the recurring rule, already present.
- `recurring_ghost_transactions`: one visible ghost row per recurring rule per period.

Ghost fields:

- `id`
- `recurringId`
- `periodKey`
- `date`
- `time`
- `name`
- `amount`
- `transactionType`
- `categoryId`
- `categoryName`
- `categoryColor`
- `categoryIconSlot`
- `status`: `pending`, `activated`, or `disabled`
- `createdTransactionId`
- `createdAt`
- `updatedAt`

Rules:

- If a recurring rule is active, there is a pending ghost for the current month.
- If the user views another month, ghosts can be generated lazily for that viewed month.
- Pending ghosts appear in the log list at their due date position.
- Ghosts do not count in summary, balance, category budget bars, calendar totals, charts, or magnet strip.
- When the trigger date is reached, WorkManager converts the pending ghost into a real transaction, marks the ghost `activated`, stores the created transaction id, and the ghost disappears from visible logs.
- In the next month, a new pending ghost appears for the same recurring rule.
- Disabling or deleting a recurring rule hides future pending ghosts and does not delete already-created real transactions.

The UI model should represent real logs and ghost logs with a shared display interface, while preserving separate delete/edit behavior. Tapping a ghost should open the recurring editor, not the transaction editor.

## Calendar And Charts

Calendar overlay and category overlay must extend to the screen bottom and cover the bottom nav/FAB while open.

Month card layout:

- Keep the original two-column grid.
- Summary mode has expanded cards.
- Normal, heatmap, and category modes should use one consistent compact card size.
- The canvas layout must reserve enough height for all rows in every mode so non-summary modes do not look compressed or mis-sized.

Charts:

- Port a minimal category chart section from the original chartbox category behavior.
- Include a donut/pie-style chart option based on visible category spending.
- Chart values use real transactions only and follow the active summary period/type.

## Category Menu

The category picker must show only categories matching the current active transaction type:

- If `income` is active, show income categories.
- If `expense` is active, show expense categories.

Selecting a category can still set the category filter. It should not unexpectedly switch type beyond matching the selected category.

## Testing

Flutter tests:

- Theme settings update changes shell/home colors and magnet painter inputs.
- Magnet painter renders distinct behavior for `magnetcard` and `adaptive`.
- Header drag reveals FastInfo during drag and springs closed after release.
- Expand button remains tappable after drag and has a larger hit area.
- Category menu filters by active type.
- Calendar overlay/category overlay cover bottom nav area.
- Calendar compact modes share the same card dimensions.
- Ghost rows appear in log list but are excluded from `activeSummary` and balance.

Kotlin tests:

- Ghost generation creates one pending ghost per active recurring rule per month.
- Trigger conversion creates exactly one real transaction and marks the ghost activated.
- A processed month is not duplicated.
- Next month gets a new pending ghost.
- Disabled recurring rules do not generate pending ghosts.

## Migration

The Android Room database version will increase from 3 to 4.

Migration 3 to 4 creates `recurring_ghost_transactions` and indexes:

- `recurringId`
- `periodKey`
- `status`
- `date`
- unique `(recurringId, periodKey)`

Existing user transactions and categories must remain untouched.
