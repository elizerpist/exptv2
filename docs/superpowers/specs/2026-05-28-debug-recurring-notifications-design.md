# Debug, Recurring Ghost, Rename, Notification Design

Date: 2026-05-28

## Scope

This spec covers the next exptv2 implementation pass:

- Add an on-screen debug console using the `schedeev2` `DebugConsole` pattern.
- Add a global floating debug button visible above every menu and tab.
- Add debug logs for recurring transaction ghost generation, trigger activation, transaction rename/reset, and notification card creation.
- Change recurring ghost behavior so active recurring transactions appear as transparent monthly ghost logboxes outside `sum` mode.
- Double the magnet strip height.
- Make transaction log names editable by tapping the name, while preserving the original merchant name.
- Rename or reset every transaction with the same original merchant name in one backend operation.
- Port the expt0926 notification card system into the Flutter/Kotlin app.

## Source Findings

The requested `gpstracker` project was not present under the known local roots. The closest matching on-screen debug implementation is in:

- `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/schedeev2/lib/core/utils/debug_console.dart`

That implementation uses:

- a singleton `DebugConsole` log store
- a bounded in-memory list
- timestamped log rows
- a `ValueNotifier` for UI refresh
- a modal debug dialog with copy, clear, and close actions

The expt0926 notification system uses these source files:

- `notificationmanager.js`: month header, month swipe, grouped notification list, empty state, clear-all behavior
- `notificationlogbox.js`: card layout, type-specific content, swipe-right delete, swipe-left read/action, category color/icon mapping
- `notifications.js`: temporary notification pill styling
- `recurring-transaction-notification-store.js`: recurring transaction trigger notification payloads
- `budget-limit-notification-store.js`: budget/category limit notification payloads

The expt0926 rename behavior uses `merchant` as the original immutable source name and `userAssignedName` as the custom display name. Bulk rename updates all matching rows.

## Recommended Approach

Use a Dart UI layer with Kotlin/Room persistence:

- Flutter owns the debug overlay, debug dialog, notification tab widgets, logbox name editing, and visual styles.
- Kotlin/Room owns recurring rules, ghost rows, real transactions, notification card rows, and bulk rename/reset operations.
- MethodChannel stays the boundary between UI intent and native data operations.

This keeps the high-volume and persistent data rules native while keeping UI behavior easy to iterate in Dart.

## Debug Console

Create a reusable debug module in Dart based on `schedeev2`:

- `DebugConsole`: singleton static log API with timestamped entries and clear/copy support.
- `DebugConsoleDialog`: dark terminal-style dialog with count, copy, clear, close, and read-only log text.
- `DebugFloatingButton`: small floating action above the full app shell.

Placement:

- The floating debug button is added at the top level of `ExptShell` as the last Stack child.
- It remains visible above home, settings, blank tabs, slide-up menus, category menu, calendar menu, and add/edit transaction sheets.
- It must avoid the bottom nav/FAB area and sit near the upper right edge unless this collides with system padding.

Initial log events:

- app shell starts
- transaction store bootstrap starts/finishes
- recurring ghosts are requested for a viewed period
- recurring ghost row is created
- recurring ghost is activated into a real transaction
- recurring processing skips a duplicate period
- transaction name bulk rename/reset starts and finishes
- notification card is created/read/deleted

Native Kotlin cannot call the Dart singleton directly. Native operations will return enough structured results for Dart to log user-visible events after MethodChannel calls. Background WorkManager recurring processing can also persist notification rows so the user sees the event later in the notification tab.

## Recurring Ghost Rules

Recurring transactions have three separate concepts:

- `recurring_transactions`: the saved monthly rule.
- `recurring_ghost_transactions`: a pending or activated period row.
- `expense_transactions`: the real transaction created after a trigger.

Visibility rules:

- `sum` / all-time mode shows no ghost rows.
- `monthly` mode shows pending ghost rows for the selected month.
- `yearly` mode shows no ghost rows in the main log list. It still includes only real transactions in totals.
- Ghost rows never affect summary, balance, category budget bars, calendar totals, charts, or magnet strip.
- Ghost rows are transparent/disabled-looking and use the existing recurring ghost logbox visual language.

Generation rules:

- When monthly mode opens or changes month, Dart asks Kotlin to ensure ghosts for that selected month.
- Kotlin creates at most one pending ghost per active recurring rule and period key.
- The unique key is `(recurringTransactionId, periodKey)`.
- A recurring rule active in March, April, and May can have one ghost per viewed month until that month is processed or the rule is disabled.

Activation rules:

- On app bootstrap, explicit recurring processing, or WorkManager run, Kotlin processes due ghosts up to the target date.
- If the due date for a pending ghost is reached, Kotlin inserts one real transaction, marks the ghost activated, stores the real transaction id, and updates the recurring rule `lastProcessedPeriodKey`.
- After activation, the ghost disappears from visible logs and the real transaction appears as a full transaction.
- If the same month is processed again, no duplicate transaction is created.
- Future-month ghosts remain pending until their own date trigger.

## Transaction Name Editing

The original merchant name must remain stored in `merchant`.

The custom user name is stored in `userAssignedName`:

- If `userAssignedName` is empty, the logbox displays `merchant`.
- If `userAssignedName` is set, the logbox displays the custom name.
- The default/original displayed name uses a lighter gray.
- The user custom displayed name uses a darker gray than the current custom-name styling.

Interaction:

- Tapping the logbox body still opens transaction edit.
- Tapping only the transaction name enters name-edit mode or opens a compact name editor.
- Saving a custom name runs a backend bulk operation by original `merchant`.
- Reset is visible next to the name when any row has a custom `userAssignedName`.
- Reset clears `userAssignedName` for every transaction with the same original `merchant`.

Backend operations:

- `expenseRenameTransactionsByMerchant(originalMerchant, customName)`
- `expenseResetTransactionNamesByMerchant(originalMerchant)`

The bulk update should match `merchant = originalMerchant`, not the current display name. This avoids chaining custom names as if they were source names.

## Magnet Strip

The magnet strip visual height doubles from its current effective usage.

Implementation:

- Keep the existing magnet mode painter and theme-aware color behavior.
- Increase the height passed by Header Card/theme previews consistently.
- Do not change how the strip calculates income/expense ratio.
- Ghost rows remain excluded because only real transactions feed the magnet totals.

## Notification Cards

Add a Flutter notification tab that replaces the current blank notifications page.

Data model:

- `notification_cards` Room table
- fields include `id`, `type`, `title`, `message`, `timestamp`, `isRead`, `isActive`, `priority`, `categoryId`, `categoryName`, `categoryColor`, `categoryIconSlot`, `recurringTransactionId`, `transactionId`, `amount`, `triggerDate`, `nextDueDate`, `createdAt`, `updatedAt`

Supported initial types:

- `recurring_transaction_alert`
- `budget_alert`
- `spending_limit`
- `monthly_budget_alert`
- generic fallback `system`

UI behavior:

- Header shows the selected month using Hungarian month names.
- Horizontal swipe on the header changes notification month.
- Notifications are grouped by date using `Ma`, `Tegnap`, or `MM.DD`.
- Cards follow the expt0926 `NotificationLogBox` proportions: rounded 25, 46 px colored icon circle, white/box-colored body, light gray borders, and swipe border feedback.
- Right swipe opens delete confirmation.
- Left swipe marks read for normal cards.
- For budget cards, left swipe can later increase the limit; the first pass can keep the callback boundary in place if category-limit mutation is not triggered from notifications yet.

Recurring trigger card:

- When a recurring ghost activates into a real transaction, Kotlin creates a `recurring_transaction_alert` notification row.
- The card title is `Ismétlődő tranzakció`.
- The card body includes recurring name, amount, category, trigger date, and next due date.

Budget card:

- Category limit save/check logic can create budget notification rows when a category or period exceeds an alert-enabled limit.
- Budget notification creation should not block the recurring implementation.

## Data Flow

Startup:

1. `ExptShell` creates `TransactionStore`.
2. `TransactionStore.start()` loads bootstrap data.
3. Kotlin seeds data, processes due recurring ghosts, returns categories, real transactions, limits, and pending ghosts.
4. Dart logs the bootstrap and recurring result in `DebugConsole`.

Monthly view change:

1. User swipes summary pill to monthly mode or changes month.
2. `TransactionStore` calls `ensureRecurringGhostTransactions(periodDate)`.
3. Kotlin creates missing pending ghost rows for the selected period.
4. Store reloads ghost rows and log list.
5. Debug console records the period, created count, and visible ghost count.

Recurring activation:

1. WorkManager or explicit processing calls Kotlin recurring processor.
2. Kotlin ensures pending ghosts, activates due ghosts, inserts real transactions, marks ghosts activated, and creates notification cards.
3. Next UI bootstrap/reload reads the real transaction and notification card.
4. Debug console logs activation when the UI receives the processed result or reload delta.

Name rename/reset:

1. User taps transaction name.
2. UI shows compact editor with save/reset.
3. Save/reset calls the bulk MethodChannel operation.
4. Kotlin updates all rows with matching original merchant.
5. Store reloads and logs affected count.

Notifications:

1. Notification tab loads cards through MethodChannel.
2. Month selection filters cards on the Dart side unless the row count requires later native pagination.
3. Read/delete operations mutate Kotlin rows and then reload the tab.

## Testing

Flutter tests:

- DebugConsole stores timestamped rows, trims old rows, clears entries, and notifies listeners.
- ExptShell renders a global debug button above tabs and sheets.
- TransactionStore does not show ghost rows in `sum` mode.
- TransactionStore shows pending ghost rows in selected monthly mode.
- TransactionStore excludes ghosts from `activeSummary`.
- Transaction logbox name tap triggers name editing without triggering full transaction edit.
- Custom names and original names use distinct colors.
- Reset button appears only when a custom name exists.
- Notification card list groups by month/date and renders recurring trigger cards.
- Magnet strip height constant doubles in header usage.

Kotlin tests:

- Ensuring ghosts for a selected period creates one row per active recurring rule.
- Ensuring the same period twice does not duplicate rows.
- Processing due ghosts creates one real transaction and marks the ghost activated.
- Sum/all-time bootstrap does not require ghost projection for every historical month.
- Bulk rename updates `userAssignedName` for every row with matching original `merchant`.
- Bulk reset clears `userAssignedName` for every row with matching original `merchant`.
- Recurring activation creates one notification card.
- Notification read/delete mutations persist.

## Migration

The Room database version will increase by one from the current version.

Migration adds:

- `notification_cards`
- new indexes for notification `timestamp`, `type`, `isRead`, and `isActive`
- any missing DAO query support for transaction bulk rename/reset

The existing `recurring_ghost_transactions` table remains the source for ghost rows. If its current schema already has the required fields and unique `(recurringTransactionId, periodKey)` index, no ghost-table migration is needed. The implementation should verify this before bumping the migration SQL.

Existing user transactions, categories, category limits, recurring rules, and settings must remain untouched.

## Out Of Scope

- Copying gpstracker-specific code, unless the project path is provided later.
- Replacing the push scraper engine.
- Changing category slot colors or icon assets.
- Changing calendar canvas design.
- Making ghost rows count toward any financial total.
