# Exptv2 Kotlin Transactions Design

Date: 2026-05-27

## Goal

Build the first functional expense-tracker slice in `exptv2` by cloning the relevant data model and interaction model from the old React Native `expt0926` app, while keeping the current Flutter app architecture clean and file sizes small.

The result of this slice is a Flutter home screen that reads and writes transactions through a Kotlin Room database. The existing push parser engine remains integrated but is not wired into transaction creation yet.

## Source Findings

The old `expt0926` project stores app data in JSON files behind a Node backend, not in SQLite.

Primary source files:

- `/storage/emulated/0/androidapps/expt0926/data/transaction-logs.json`
- `/storage/emulated/0/androidapps/expt0926/data/transaction-categories.json`
- `/storage/emulated/0/androidapps/expt0926/transaction-logs-store.js`
- `/storage/emulated/0/androidapps/expt0926/transaction-category-store.js`
- `/storage/emulated/0/androidapps/expt0926/addnewtransactionmenu.js`
- `/storage/emulated/0/androidapps/expt0926/addnewtransactionmenucontent.js`
- `/storage/emulated/0/androidapps/expt0926/transactionpills.js`
- `/storage/emulated/0/androidapps/expt0926/summarypill.js`
- `/storage/emulated/0/androidapps/expt0926/searchpill.js`
- `/storage/emulated/0/androidapps/expt0926/transactionmanager.js`
- `/storage/emulated/0/androidapps/expt0926/transactionlogbox.js`
- `/storage/emulated/0/androidapps/expt0926/SlotManager.js`

The current `exptv2` project already has:

- Flutter shell, bottom navigation, FAB, settings page.
- Kotlin Room infrastructure for the push parser notification event store.
- MethodChannel `pushparser/methods` and EventChannel `pushparser/events`.
- GitHub Actions debug APK build.

## Database Design

Use Kotlin Room as the single source of truth for expense tracker data.

Create a separate Room database for expense data named `expense_tracker.db`. Keep it separate from the current `pushparser_events.db` so the push parser engine and transaction data can evolve independently.

### `transaction_categories`

Columns:

- `transactionCategoryID INTEGER PRIMARY KEY`
- `name TEXT NOT NULL`
- `type TEXT NOT NULL`
- `colorSlot INTEGER`
- `iconSlot INTEGER`
- `backgroundColor TEXT`
- `icon TEXT`
- `notification TEXT`
- `hasLimit INTEGER NOT NULL`
- `limitAmount REAL NOT NULL`
- `alertActive INTEGER NOT NULL`
- `isCustomIcon INTEGER NOT NULL`
- `originalIcon TEXT`

Type values stay compatible with the old app:

- `bevétel`
- `kiadás`

Flutter normalizes these to:

- `income`
- `expense`

### `transactions`

Columns:

- `id INTEGER PRIMARY KEY`
- `date TEXT NOT NULL`
- `time TEXT NOT NULL`
- `latitude REAL`
- `longitude REAL`
- `address TEXT`
- `merchant TEXT NOT NULL`
- `amount REAL NOT NULL`
- `userAssignedName TEXT`
- `transactionCategoryID INTEGER NOT NULL`

Rules:

- `amount > 0` means income.
- `amount < 0` means expense.
- `transactionCategoryID` references `transaction_categories.transactionCategoryID`.
- `date` remains compatible with the old app format: `YYYY.MM.DD`.
- `time` remains string-based and is displayed as `HH:mm` when possible.

### Seed Data

Seed the database on first launch with the current old-project data:

- 9 categories from `transaction-categories.json`.
- 13 transactions from `transaction-logs.json`.

The seed is idempotent. If the DB already has categories or transactions, do not overwrite user-created data.

## Colors

Preserve the old app design colors in central Flutter theme/constants.

Core colors:

- Primary/FAB: `#06b6d4`
- Primary dark: `#0891b2`
- Primary light: `#67e8f9`
- White: `#ffffff`
- Gray 50: `#f8fafc`
- Gray 100: `#f1f5f9`
- Gray 200: `#e2e8f0`
- Gray 300: `#cbd5e1`
- Gray 400: `#94a3b8`
- Gray 500: `#64748b`
- Gray 600: `#475569`
- Gray 800: `#1e293b`
- Gray 900: `#0f172a`
- Income green: `#22c55e`
- Expense red: `#ef4444`

Slot colors from old `SlotManager.colorConfig`:

- `0 #ef4444`
- `1 #f97316`
- `2 #eab308`
- `3 #84cc16`
- `4 #22c55e`
- `5 #10b981`
- `6 #06b6d4`
- `7 #0ea5e9`
- `8 #3b82f6`
- `9 #6366f1`
- `10 #8b5cf6`
- `11 #a855f7`
- `12 #d946ef`
- `13 #ec4899`
- `14 #f43f5e`
- `15 #6b7280`
- `16 #374151`
- `17 #1f2937`
- `18 #064e3b`
- `19 #7c2d12`
- `20 #4c1d95`

Icon assets are not cloned in this slice. Keep `iconSlot`, `icon`, `isCustomIcon`, and `originalIcon` in the database for compatibility, but render category circles with a simple existing Flutter Material placeholder for now.

## Native API Contract

Extend the existing MethodChannel `pushparser/methods` with expense methods.

Methods:

- `expenseLoadBootstrap`
  - Returns categories, transactions, and computed summaries.
- `expenseListTransactions`
  - Args: `type`, `searchQuery`, `categoryId`, `merchant`, `yearMonth`.
  - Returns filtered transactions sorted newest first.
- `expenseAddTransaction`
  - Args: `merchant`, `amount`, `type`, `transactionCategoryID`, `date`, `time`, optional geolocation fields.
  - Applies the sign rule in Kotlin.
  - Returns the inserted transaction.
- `expenseDeleteTransaction`
  - Args: `id`.
  - Deletes one transaction. The method is implemented with the DB layer, but the right-swipe UI confirmation is reserved for a follow-up.
- `expenseListCategories`
  - Args: optional `type`.
  - Returns categories for the add transaction menu.

Kotlin handles validation and returns Flutter errors for missing merchant, invalid amount, missing category, or invalid type.

## Flutter Architecture

Create `lib/features/transactions/` with small files.

Models:

- `models/transaction_record.dart`
- `models/transaction_category.dart`
- `models/transaction_summary.dart`

Data layer:

- `data/transaction_repository.dart`
- `data/transaction_filter.dart`

State:

- `state/transaction_store.dart`

Pages and widgets:

- `transaction_home_page.dart`
- `widgets/transaction_type_pills.dart`
- `widgets/summary_pill.dart`
- `widgets/search_pill.dart`
- `widgets/transaction_log_list.dart`
- `widgets/transaction_log_box.dart`
- `widgets/add_transaction_sheet.dart`
- `widgets/category_selector_field.dart`
- `widgets/date_time_fields.dart`
- `widgets/amount_field.dart`

Update `ExptShell` so `AppTab.home` renders `TransactionHomePage` instead of a blank page. Other tabs stay as they are.

## UI Behavior

### Header Body Area

The home body clones the old app structure:

1. Transaction type pills at the top: `Bevétel`, `Kiadás`.
2. Summary pill under the type pills.
3. Search/fast filter pill under the summary.
4. Transaction list under the search pill.

The old app uses fixed vertical positions (`205`, `286`, `366`, then list around `414`). Flutter should reproduce the visual spacing responsively rather than hard-coding every pixel, while preserving the same proportions, margins, pill radii, borders, shadows, and colors.

### Income/Expense Switch

The old app switches income/expense by tapping `TransactionPills`, not by swiping.

Implement:

- `Bevétel` pill sets active type to `income`.
- `Kiadás` pill sets active type to `expense`.
- Active pill uses `#06b6d4` with white text.
- Inactive pill uses white background, gray border, and gray text.

### Summary Pill

The summary pill displays the active type total:

- Monthly current period.
- Current year.
- All time.

Horizontal swipe cycles the summary window in the same order as the old app:

- monthly
- yearly
- all time

### Search/Fast Filter

Search filters by merchant display name:

- `userAssignedName` if present.
- Otherwise `merchant`.

Fast filter behavior:

- Left swipe on a logbox sets the merchant filter.
- Search pill shows the merchant filter capsule and filtered transaction count.
- Close action clears the filter.

Category filter data structures stay available, but full category-filter menus are not part of this slice unless needed by the add menu.

### Add Transaction Menu

FAB opens the add transaction menu.

Fields:

- `Tranzakció neve`
- `Összeg`
- `Kategória`
- `Dátum`
- `Idő`

Behavior:

- Menu title depends on active type:
  - `Új bevételi tranzakció`
  - `Új kiadási tranzakció`
- Required fields: merchant/name, amount, category.
- Kotlin applies sign:
  - expense is saved as negative.
  - income is saved as positive.
- After save:
  - menu closes.
  - list reloads.
  - summary reloads.
  - the new logbox appears in the active filtered list if it matches.

### Transaction Logbox

Clone the old visual structure:

- White pill card.
- `25` radius.
- `1px` gray border.
- subtle shadow.
- `70` minimum height.
- `20` horizontal screen margin through parent list.
- Left category color circle, `46x46`.
- Center merchant display name.
- Right amount and time.
- Income amount green, prefixed with `+`.
- Expense amount red, prefixed with `-`.

Logbox interactions for this slice:

- Left swipe fast filter is implemented.
- Tap amount editing is deferred.
- Tap merchant editing is deferred.
- Right swipe delete confirmation is deferred, while the native delete method remains available for later UI wiring.

## Data Flow

Initial load:

1. `TransactionStore.start()`
2. Dart calls `expenseLoadBootstrap`
3. Kotlin seeds Room if empty.
4. Kotlin returns categories and transactions.
5. Dart computes UI state or uses native summary values.

Save transaction:

1. User taps FAB.
2. Add transaction menu opens.
3. User enters fields and category.
4. Dart calls `expenseAddTransaction`.
5. Kotlin validates, signs amount, inserts Room row.
6. Dart reloads transactions and summaries.
7. UI returns to the transaction list.

Filtering:

1. `TransactionTypePills` controls income/expense.
2. `SearchPill` controls text query and merchant capsule.
3. `TransactionStore` asks Kotlin for filtered data or filters cached rows locally.

Use local Dart filtering for UI responsiveness after initial bootstrap, and Kotlin filtering for authoritative reloads after writes.

## Error Handling

Kotlin validation errors:

- Missing merchant: `INVALID_TRANSACTION_NAME`
- Invalid amount: `INVALID_AMOUNT`
- Missing category: `INVALID_CATEGORY`
- Invalid transaction type: `INVALID_TRANSACTION_TYPE`

Flutter display:

- Keep form open on validation failure.
- Show concise inline or SnackBar error.
- Do not insert partial rows.

DB errors:

- Return MethodChannel error.
- Flutter keeps current list state and shows a save/load failure message.

## Testing

Dart tests:

- `TransactionRecord.fromMap` parses old/Kotlin payload.
- Amount sign and display formatting.
- Income/expense pill changes visible list.
- FAB opens add transaction menu.
- Saving through mocked MethodChannel inserts/reloads UI.
- Search and merchant fast filter reduce visible logboxes.

Kotlin/Android validation through build:

- Room compiles with KSP.
- `flutter analyze`
- `flutter test`
- GitHub Actions debug APK build.

Local caveat:

- Local APK build under ARM64 proot may fail on `aapt2` architecture, as before. GitHub Actions is the authoritative APK build environment.

## Implementation Boundaries

Included:

- Kotlin Room transaction/category DB.
- Seed data from old app.
- MethodChannel read/write.
- Home page transaction UI.
- FAB add transaction menu.
- Summary/search/type pills.
- Logbox rendering and merchant fast filter.

Excluded for this slice:

- Wiring push parser notifications into automatic transaction creation.
- Copying icon assets.
- Full category-management menus.
- Budget-limit alert engine.
- Merchant/category collective editing from logbox.
- Notification parsing rules.
- Right-swipe delete confirmation UI.

## Acceptance Criteria

- App builds in GitHub Actions and uploads debug APK artifact.
- Home tab is no longer blank.
- Seeded income and expense transactions are visible as logboxes.
- `Bevétel` and `Kiadás` pills switch the list.
- Summary pill values match the active filtered type.
- FAB opens the add transaction menu.
- User can save a new transaction.
- Saved transaction persists through Kotlin Room and appears after reload.
- Merchant search and logbox left-swipe fast filter work.
- Existing bottom navigation, FAB dimensions, and settings app filter remain functional.
