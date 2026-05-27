# Exptv2 Transaction Workflows Design

## Context

The current transaction home screen can list, add, filter, and categorize transactions, but several interactions still behave like temporary scaffolding. The add transaction form opens through Flutter's modal bottom sheet, which adds a blocking veil and steals focus from the app body. Transaction filters are partly single-purpose: merchant fast filter and category filter replace each other in some paths, the search pill only renders one capsule, and the summary pill uses a broader dataset than the list currently shown on screen.

This change makes the transaction screen behave like one coordinated database view. The visible log list, search capsules, summary pill, add/edit transaction card, and backend mutation APIs must all work from the same state model.

## Goals

- Show the add transaction card without modal veil or focus blocking.
- Keep the add transaction card top aligned to the summary pill top and make it taller than the current content-height bottom sheet.
- Let users tap the income/expense pills while the add transaction card is open, with the card title and category selector updating immediately.
- Group transaction logs by date in the app body.
- Open an edit transaction flow when a logbox is tapped.
- Delete a transaction through a confirmation dialog when a logbox is swiped right.
- Filter by merchant fast filter and by category avatar simultaneously.
- Render both active filter capsules inside the search pill, with capsule colors derived from their relevant category color.
- Use add-transaction-style focused input borders for the search input instead of an inner highlighted field frame.
- Make the summary pill label always show the active interval and calculate totals only from the records visible on screen after interval, type, search, merchant, and category filters are applied.

## Non-Goals

- No new visual icon asset system for this change.
- No push parser integration changes.
- No bulk transaction selection.
- No new date picker UX beyond the existing date/time fields.
- No redesign of bottom navigation or FAB styling.

## Architecture

### Overlay Model

`AddTransactionSheet` will become a reusable transaction editor card that can be embedded into the shell stack instead of being shown through `showModalBottomSheet` for the add path. The shell owns an `_transactionEditorOpen` flag and optional editing record. When open, it places the card above the app body, with `top: TransactionMenuMetrics.overlayTop`, no barrier color, and a high enough stack order to sit above the content while leaving the type pills tappable.

The card should not consume the whole screen behind it. Taps outside the card do not need to close it; the card's existing save/cancel/close controls remain explicit. This avoids accidental dismissal while users switch income/expense.

### Transaction Editor

The editor widget supports two modes:

- Add mode: empty merchant and amount, default date/time now, category resolved from `store.activeCategories`.
- Edit mode: prefilled merchant, amount, date, time, and category from the tapped `TransactionRecord`.

The title is derived from state:

- `Új kiadási tranzakció`
- `Új bevételi tranzakció`
- `Tranzakció módosítása`

When the user switches type while the editor is open, add mode updates its title and active category list. Edit mode keeps the edited record's signed type unless the implementation explicitly supports type switching; for this phase, edit keeps the record's current type to avoid accidental sign changes.

### Backend Mutation APIs

Delete transaction already exists in Kotlin and Dart native bridge, but the repository/store layer does not expose it. This change exposes it in `TransactionRepositoryContract`, `TransactionRepository`, and `TransactionStore`.

Update transaction does not exist yet. Add:

- Kotlin `ExpenseRepository.updateTransaction(args)`
- Kotlin method channel route `expenseUpdateTransaction`
- Dart `NativeBridge.expenseUpdateTransaction`
- Dart `TransactionRepository.updateTransaction`
- Dart `TransactionStore.updateTransaction`

The update payload matches add transaction: merchant, amount, type, transactionCategoryID, date, time. Kotlin validates the record exists, validates category exists, signs amount from type, keeps existing latitude, longitude, address, and id, then replaces the row.

### Filter State

`TransactionFilter` keeps independent filter dimensions:

- `type`
- `searchQuery`
- `merchant`
- `merchantCategoryId` or enough metadata to color the merchant capsule
- `categoryId`

The merchant fast filter and category avatar filter are independent. Setting one must not clear the other. Switching income/expense clears both filters and the search query because categories and visible records are type-specific.

For the merchant capsule color, the store resolves a representative category from the currently filtered merchant records. If all visible merchant records are in one category, use that category color; otherwise use primary blue as the fallback.

### Visible Records And Summary

The store exposes two record lists:

- `windowedTransactions`: type + summary interval only.
- `visibleTransactions`: type + summary interval + merchant + category + search query.

The log list uses `visibleTransactions`. The summary pill also uses `visibleTransactions`, so it always sums exactly what the user sees. This intentionally changes the old behavior where summary used all records in the interval regardless of active filters.

The summary label includes interval text:

- all time: `Sum`
- yearly: current year, e.g. `2026`
- monthly: month and year, e.g. `Március 2026`

If a merchant or category filter is active, the title appends concise filter context while keeping the value readable.

### Log List Interaction

`TransactionLogList` groups records by `normalizedDate`. Each group renders a small date header followed by that day's logboxes.

`TransactionLogBox` interactions:

- Tap card body: open edit transaction.
- Swipe left: existing merchant fast filter behavior.
- Swipe right: request delete confirmation dialog.
- Tap category avatar: apply category filter.

The avatar tap must not also trigger the logbox tap. The avatar widget receives its own gesture handler.

### Search Pill

The search pill remains one component but becomes stateful enough to show focused outer border styling. The TextField uses `transactionFieldDecoration` or an equivalent shared input decoration so focus shows a blue rounded outline, matching add transaction inputs.

The capsule row supports up to two capsules at once. Capsules are horizontally compact, truncate labels, and expose close icons. The text input remains usable when capsules are active.

## Testing Strategy

Use TDD with CI as the authoritative Flutter runner because local Termux Flutter fails with the known Dart TLS alignment issue.

Add or update tests for:

- Add transaction editor overlay has no modal barrier, starts at summary pill top, and leaves income/expense pills tappable.
- Add transaction editor title changes when active type changes.
- Transaction store applies merchant and category filters together.
- Transaction store summary uses visible filtered records.
- Search pill renders two capsules with expected colors and keeps the search input usable.
- Log list renders date headers.
- Logbox tap requests edit; swipe right requests delete; avatar tap requests category filter.
- Native bridge and repository expose update/delete transaction.
- Kotlin update transaction validates, signs, preserves id/location/address, and updates the Room row.

## Risks

The main risk is gesture conflict in `TransactionLogBox`: avatar tap, card tap, left swipe, and right swipe all live in one compact card. Tests should verify each callback is isolated.

The second risk is overlay ordering. The transaction editor must sit above the body but not block type pills. This is easiest if the shell positions the editor only from `TransactionMenuMetrics.overlayTop` downward and keeps the header/type pill layer outside the editor's hit-test region.

## Review Notes

This design intentionally keeps the transaction editor in Dart UI while using Kotlin/Room only for durable database operations. That preserves the existing architecture: Dart renders UI and state, Kotlin owns persistence and native database mutation.
