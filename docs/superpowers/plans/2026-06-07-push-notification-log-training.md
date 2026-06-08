# Push Notification Log Training Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Settings push-message log that lazily lists captured notifications, shows whether each event has a live linked transaction, and lets an unlinked event train the parser and create an uncategorized transaction.

**Architecture:** Room keeps raw notification events and transactions durable, with `sourceNotificationEventId` linking a transaction back to its source event. Kotlin exposes paged event/status APIs over the existing `pushparser/methods` channel, while Flutter owns filters, lazy list state, and the bottom-sheet training UX by reusing the existing parser profile model. Transactions created from push events deliberately have no category; the main transaction log renders them with a gray question-mark avatar until the user assigns a category through the existing transaction editor.

**Tech Stack:** Flutter/Dart, Kotlin, Room, MethodChannel, Android notification listener/accessibility capture, flutter_test, JUnit/Robolectric.

---

## Scope Check

This plan covers the approved design in `docs/superpowers/specs/2026-06-07-push-notification-log-training-design.md`. It touches native schema, native query APIs, Dart bridge/models, Settings UI, transaction log category-null rendering, and tests. It does not add a parser category selector, does not delete raw push messages from this UI, and does not implement merchant-to-category learning; newly push-created transactions remain uncategorized until the main transaction editor assigns a category.

## File Structure

Create native push-log files:

- `android/app/src/main/kotlin/com/exptv2/app/NotificationEventStatus.kt`: constants and mapping for `all`, `linked`, `missing`, and `system`.
- `android/app/src/main/kotlin/com/exptv2/app/NotificationEventPageModels.kt`: query/page DTOs used by `NotificationEventRepository`.

Modify native push files:

- `android/app/src/main/kotlin/com/exptv2/app/NotificationEventEntity.kt`: add `manualStatus` to persisted events and maps.
- `android/app/src/main/kotlin/com/exptv2/app/NotificationEventDao.kt`: add indexed, paged candidate queries, count helpers, lookup, and manual-status update.
- `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`: build event pages, derive status from live transaction links, and mark events as system.
- `android/app/src/main/kotlin/com/exptv2/app/PushParserDatabase.kt`: add migration from version 1 to 2 with indexes.
- `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`: expose `loadNotificationEventPage` and `markNotificationEventSystem`.
- `android/app/src/main/kotlin/com/exptv2/app/NotificationParserRuleStore.kt`: ensure at least one parser profile is enabled when profiles are loaded or saved.

Modify native transaction files:

- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt`: make `transactionCategoryID` nullable and add `sourceNotificationEventId`.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`: add source-event link queries, exclude null category from category counts, and keep category filters null-safe.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`: migrate version 8 to 9 by rebuilding `transactions`.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`: allow add/update without a category, skip category limit alerts for uncategorized transactions, and expose source-event link lookup.

Create Dart push-log files:

- `lib/features/settings/models/push_notification_log_event.dart`: page event model, status enum, and page query/page payload.
- `lib/features/settings/state/push_notification_log_store.dart`: lazy page state, filters, system marking, and train-and-create action.
- `lib/features/settings/widgets/push_log/push_notification_log_page.dart`: Settings submenu body with filters and lazy list.
- `lib/features/settings/widgets/push_log/push_notification_log_box.dart`: row/logbox matching the approved design.
- `lib/features/settings/widgets/push_log/push_notification_event_sheet.dart`: bottom sheet with token training and final actions.

Modify Dart files:

- `lib/services/native_bridge.dart`: add paged event methods and parse payloads.
- `lib/state/event_store.dart`: prefer enabled parser profile on load and add a save helper for a trained selected profile.
- `lib/features/settings/settings_page.dart`: add the `Elkapott push üzenetek` entry and submenu.
- `lib/features/settings/widgets/options/settings_option_widgets.dart`: add optional subtitles for Settings rows.
- `lib/features/transactions/models/transaction_record.dart`: make `transactionCategoryID` nullable and parse `sourceNotificationEventId`.
- `lib/features/transactions/widgets/transaction_log_list.dart`: accept nullable category ids.
- `lib/features/transactions/widgets/transaction_log_box.dart`: render uncategorized avatar state.
- `lib/features/transactions/widgets/category_menu/category_icon_badge.dart`: support a white question-mark icon when category is null.
- `lib/features/transactions/widgets/add_transaction_sheet.dart`: open uncategorized transactions with no selected category so the user can assign one.
- `lib/features/transactions/state/transaction_store.dart`: avoid counting null category ids in category-count indexes.
- `lib/features/transactions/data/limit_manager.dart`: skip uncategorized rows for category limit bars.
- `lib/features/transactions/data/calendar_render_builder.dart`: include uncategorized amounts in day totals but not dominant-category maps.
- `lib/features/transactions/data/fast_info_period_aggregates.dart`: skip uncategorized rows in category groups.
- `lib/features/transactions/widgets/calendar_menu/month_stats_charts.dart`: skip uncategorized category totals.
- `lib/features/transactions/widgets/calendar_menu/category_donut_chart.dart`: skip uncategorized category slices.

Test files:

- `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseTransactionEntityTest.kt`
- `android/app/src/test/kotlin/com/exptv2/app/NotificationEventEntityTest.kt`
- `android/app/src/test/kotlin/com/exptv2/app/NotificationEventStatusTest.kt`
- `test/transactions/transaction_models_test.dart`
- `test/transactions/transaction_widgets_test.dart`
- `test/notification_event_test.dart`
- `test/settings/settings_bridge_test.dart`
- `test/settings/settings_page_test.dart`
- `test/settings/push_notification_log_store_test.dart`
- `test/settings/push_notification_log_page_test.dart`

---

### Task 1: Uncategorized Transaction Foundation

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `lib/features/transactions/models/transaction_record.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_icon_badge.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/data/limit_manager.dart`
- Modify: `lib/features/transactions/data/calendar_render_builder.dart`
- Modify: `lib/features/transactions/data/fast_info_period_aggregates.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/month_stats_charts.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/category_donut_chart.dart`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseTransactionEntityTest.kt`
- Test: `test/transactions/transaction_models_test.dart`
- Test: `test/transactions/transaction_widgets_test.dart`

- [ ] **Step 1: Write native failing tests for nullable category and source event link**

Add this test to `ExpenseTransactionEntityTest.kt`:

```kotlin
@Test
fun transactionMapAllowsUncategorizedPushSource() {
    val row = ExpenseTransactionEntity(
        id = 26060701,
        date = "2026.06.07",
        time = "21:10",
        latitude = null,
        longitude = null,
        address = "Push notification",
        merchant = "Tesco",
        amount = -12345.0,
        userAssignedName = null,
        transactionCategoryID = null,
        recurringTransactionId = null,
        recurringRuleId = null,
        recurringInstanceId = null,
        sourceNotificationEventId = 77L,
    )

    val map = row.toMap()

    assertEquals(null, map["transactionCategoryID"])
    assertEquals(77L, map["sourceNotificationEventId"])
}
```

- [ ] **Step 2: Run the native entity test and verify failure**

Run:

```bash
./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.expense.ExpenseTransactionEntityTest"
```

Expected: FAIL because `transactionCategoryID` is non-null and `sourceNotificationEventId` does not exist.

- [ ] **Step 3: Write Dart failing model tests for uncategorized records**

Add this test to `test/transactions/transaction_models_test.dart`:

```dart
test('TransactionRecord parses uncategorized push source payload', () {
  final record = TransactionRecord.fromMap({
    'id': 26060701,
    'date': '2026.06.07',
    'time': '21:10',
    'merchant': 'Tesco',
    'amount': -12345,
    'userAssignedName': null,
    'transactionCategoryID': null,
    'sourceNotificationEventId': 77,
  });

  expect(record.transactionCategoryID, isNull);
  expect(record.sourceNotificationEventId, 77);
  expect(record.displayAmount, '-12 345 Ft');
  expect(record.toMap(), containsPair('transactionCategoryID', null));
  expect(record.toMap(), containsPair('sourceNotificationEventId', 77));
});
```

Run:

```bash
flutter test test/transactions/transaction_models_test.dart
```

Expected: FAIL because `_int(map['transactionCategoryID'])` cannot parse null and `sourceNotificationEventId` is not modeled.

- [ ] **Step 4: Update the native transaction entity**

In `ExpenseTransactionEntity.kt`, change the category field and add the source event field:

```kotlin
val transactionCategoryID: Int?,
val recurringTransactionId: Int? = null,
val recurringRuleId: Int? = null,
val recurringInstanceId: Int? = null,
val sourceNotificationEventId: Long? = null,
```

Update `toMap()` so it includes:

```kotlin
"transactionCategoryID" to transactionCategoryID,
"recurringTransactionId" to recurringTransactionId,
"recurringRuleId" to recurringRuleId,
"recurringInstanceId" to recurringInstanceId,
"sourceNotificationEventId" to sourceNotificationEventId,
```

Add an index to the entity indices:

```kotlin
Index("sourceNotificationEventId"),
```

- [ ] **Step 5: Update the transaction DAO link queries**

In `ExpenseTransactionDao.kt`, keep `CategoryCountRow.transactionCategoryID` as `Int`, change category counts to exclude null, and add source-event lookup:

```kotlin
@Query("SELECT transactionCategoryID, COUNT(*) AS count FROM transactions WHERE transactionCategoryID IS NOT NULL GROUP BY transactionCategoryID")
suspend fun categoryCounts(): List<CategoryCountRow>

@Query("SELECT * FROM transactions WHERE sourceNotificationEventId IN (:eventIds)")
suspend fun bySourceNotificationEventIds(eventIds: List<Long>): List<ExpenseTransactionEntity>

@Query("SELECT * FROM transactions WHERE sourceNotificationEventId = :eventId ORDER BY id DESC LIMIT 1")
suspend fun bySourceNotificationEventId(eventId: Long): ExpenseTransactionEntity?
```

Keep existing category filters as:

```sql
AND (:categoryId IS NULL OR transactionCategoryID = :categoryId)
```

because null category rows should only appear when no category filter is selected.

- [ ] **Step 6: Add the Room migration from expense database version 8 to 9**

In `ExpenseTrackerDatabase.kt`, change `version = 8` to `version = 9`, add `MIGRATION_8_9`, and include it in `.addMigrations(...)`.

Use this migration body:

```kotlin
private val MIGRATION_8_9 = object : Migration(8, 9) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE IF NOT EXISTS transactions_new (
                id INTEGER PRIMARY KEY NOT NULL,
                date TEXT NOT NULL,
                time TEXT NOT NULL,
                latitude REAL,
                longitude REAL,
                address TEXT,
                merchant TEXT NOT NULL,
                amount REAL NOT NULL,
                userAssignedName TEXT,
                transactionCategoryID INTEGER,
                recurringTransactionId INTEGER,
                recurringRuleId INTEGER,
                recurringInstanceId INTEGER,
                sourceNotificationEventId INTEGER,
                FOREIGN KEY(transactionCategoryID) REFERENCES transaction_categories(transactionCategoryID) ON UPDATE NO ACTION ON DELETE RESTRICT
            )
            """.trimIndent(),
        )
        db.execSQL(
            """
            INSERT INTO transactions_new (
                id, date, time, latitude, longitude, address, merchant, amount,
                userAssignedName, transactionCategoryID, recurringTransactionId,
                recurringRuleId, recurringInstanceId, sourceNotificationEventId
            )
            SELECT
                id, date, time, latitude, longitude, address, merchant, amount,
                userAssignedName, transactionCategoryID, recurringTransactionId,
                recurringRuleId, recurringInstanceId, NULL
            FROM transactions
            """.trimIndent(),
        )
        db.execSQL("DROP TABLE transactions")
        db.execSQL("ALTER TABLE transactions_new RENAME TO transactions")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_transactionCategoryID ON transactions(transactionCategoryID)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_date ON transactions(date)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_merchant ON transactions(merchant)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_amount ON transactions(amount)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_recurringTransactionId ON transactions(recurringTransactionId)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_recurringRuleId ON transactions(recurringRuleId)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_recurringInstanceId ON transactions(recurringInstanceId)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_sourceNotificationEventId ON transactions(sourceNotificationEventId)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_date_time_id ON transactions(date, time, id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_amount_date_time_id ON transactions(amount, date, time, id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_transactionCategoryID_date_time_id ON transactions(transactionCategoryID, date, time, id)")
    }
}
```

- [ ] **Step 7: Make add/update transaction category-null aware**

In `ExpenseRepository.addTransaction`, replace the required category parsing block with:

```kotlin
val categoryId = optionalInt(args["transactionCategoryID"])
val category = categoryId?.let { id ->
    categories.byId(id)
        ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
}
val sourceNotificationEventId = optionalLong(args["sourceNotificationEventId"])
```

Set the row fields:

```kotlin
transactionCategoryID = categoryId,
sourceNotificationEventId = sourceNotificationEventId,
```

Replace limit emission with:

```kotlin
if (row.amount < 0 && category != null) {
    emitLimitAlertsForTransaction(row, category)
} else {
    val reason = if (row.amount >= 0) "non_expense" else "missing_category"
    Log.d("ExpenseNotification", "[Notification] transaction limit evaluation skipped id=${row.id} reason=$reason")
}
```

In `ExpenseRepository.updateTransaction`, use:

```kotlin
val categoryId = if (args.containsKey("transactionCategoryID")) {
    optionalInt(args["transactionCategoryID"])
} else {
    existing.transactionCategoryID
}
val category = categoryId?.let { id ->
    categories.byId(id)
        ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
}
val row = existing.copy(
    date = formatDate(args["date"]?.toString() ?: existing.date),
    time = args["time"]?.toString()?.trim().takeUnless { it.isNullOrEmpty() } ?: existing.time,
    merchant = merchant,
    amount = signedAmount,
    userAssignedName = if (args.containsKey("userAssignedName")) {
        args["userAssignedName"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
    } else {
        existing.userAssignedName
    },
    transactionCategoryID = categoryId,
)
```

Add this helper near the existing `optionalInt` helper:

```kotlin
private fun optionalLong(value: Any?): Long? = when (value) {
    is Number -> value.toLong()
    null -> null
    else -> value.toString().toLongOrNull()
}
```

Add repository link lookup for the push event repository:

```kotlin
suspend fun transactionsBySourceNotificationEventIds(eventIds: List<Long>): Map<Long, ExpenseTransactionEntity> {
    seedIfEmpty()
    if (eventIds.isEmpty()) return emptyMap()
    return transactions.bySourceNotificationEventIds(eventIds)
        .mapNotNull { row -> row.sourceNotificationEventId?.let { it to row } }
        .toMap()
}
```

Add this helper near other private repository helpers:

```kotlin
private suspend fun categoryFor(transaction: ExpenseTransactionEntity): TransactionCategoryEntity? {
    return transaction.transactionCategoryID?.let { categoryId -> categories.byId(categoryId) }
}
```

Replace transaction-category limit emission call sites that currently read the category directly with:

```kotlin
categoryFor(transaction)?.let { category -> emitLimitAlertsForTransaction(transaction, category) }
```

For local rows named `row`, use:

```kotlin
categoryFor(row)?.let { category -> emitLimitAlertsForTransaction(row, category) }
```

- [ ] **Step 8: Update Dart transaction model**

In `transaction_record.dart`, change the field type and constructor:

```dart
final int? transactionCategoryID;
final int? sourceNotificationEventId;
```

Parse and serialize with:

```dart
transactionCategoryID: _nullableInt(map['transactionCategoryID']),
sourceNotificationEventId: _nullableInt(map['sourceNotificationEventId']),
```

and:

```dart
'transactionCategoryID': transactionCategoryID,
if (sourceNotificationEventId != null)
  'sourceNotificationEventId': sourceNotificationEventId,
```

- [ ] **Step 9: Render the uncategorized transaction avatar**

In `CategoryIconBadge`, add:

```dart
final bool showQuestionMark;
```

with constructor default:

```dart
this.showQuestionMark = false,
```

Replace the `ImageIcon` child with:

```dart
child: showQuestionMark
    ? Icon(Icons.question_mark, color: AppColors.white, size: iconSize)
    : ImageIcon(
        CategoryIconManager.assetImage(resolvedIconSlot),
        color: AppColors.white,
        size: iconSize,
      ),
```

In `TransactionLogBox`, compute:

```dart
final uncategorized = widget.category == null;
final avatarColor = uncategorized ? AppColors.gray500 : widget.category!.slotColor;
```

and pass:

```dart
showQuestionMark: uncategorized,
```

to `CategoryIconBadge`.

In `TransactionLogList`, change `_categoryForId` to:

```dart
TransactionCategory? _categoryForId(int? id) {
  if (id == null) return null;
  final indexed = widget.categoriesById[id];
  if (indexed != null) return indexed;
  for (final category in widget.categories) {
    if (category.transactionCategoryID == id) return category;
  }
  return null;
}
```

- [ ] **Step 10: Harden category-derived Dart code for null category ids**

Apply these exact null skips:

In `LimitManager.buildBars`:

```dart
for (final record in records) {
  final categoryId = record.transactionCategoryID;
  if (categoryId == null) continue;
  spentByCategory.update(
    categoryId,
    (value) => value + record.amount.abs(),
    ifAbsent: () => record.amount.abs(),
  );
}
```

In `CalendarRenderBuilder.buildYear`, inside expense handling:

```dart
final categoryId = record.transactionCategoryID;
if (categoryId != null) {
  expenseByCategory.update(
    categoryId,
    (value) => value + absolute,
    ifAbsent: () => absolute,
  );
}
```

In `FastInfoPeriodAggregates.categoryExpenseGroups`:

```dart
final categoryId = row.record.transactionCategoryID;
if (categoryId == null) continue;
groups.putIfAbsent(categoryId, () => <FastInfoDatedTransaction>[]).add(row);
```

In `MonthStatsCharts` category totals:

```dart
final categoryId = record.transactionCategoryID;
if (categoryId != null) {
  categoryTotals.update(
    categoryId,
    (value) => value + absolute,
    ifAbsent: () => absolute,
  );
}
```

In `CategoryDonutChart._buildSlices`:

```dart
final categoryId = transaction.transactionCategoryID;
if (categoryId == null) continue;
totals.update(
  categoryId,
  (value) => value + transaction.amount.abs(),
  ifAbsent: () => transaction.amount.abs(),
);
```

In `TransactionStore._rebuildDerivedIndexes`:

```dart
for (final transaction in _transactions) {
  final categoryId = transaction.transactionCategoryID;
  if (categoryId == null) continue;
  counts.update(categoryId, (value) => value + 1, ifAbsent: () => 1);
}
```

In `AddTransactionSheet`, change:

```dart
TransactionCategory? _categoryById(int? id) {
  if (id == null) return null;
  for (final category in widget.store.categories) {
    if (category.transactionCategoryID == id) return category;
  }
  return null;
}
```

- [ ] **Step 11: Run focused tests and commit**

Run:

```bash
./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.expense.ExpenseTransactionEntityTest"
flutter test test/transactions/transaction_models_test.dart test/transactions/transaction_widgets_test.dart
```

Expected: PASS.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense lib/features/transactions test/transactions
git commit -m "feat: support uncategorized push transactions"
```

---

### Task 2: Native Notification Event Paging And Status

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventStatus.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventPageModels.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventEntity.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/PushParserDatabase.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/NotificationEventEntityTest.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/NotificationEventStatusTest.kt`

- [ ] **Step 1: Write failing status/entity tests**

Create `NotificationEventStatusTest.kt`:

```kotlin
package com.exptv2.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationEventStatusTest {
    @Test
    fun mapsFinalStatusTexts() {
        assertEquals("Van tranzakció", NotificationEventStatus.displayText(NotificationEventStatus.LINKED))
        assertEquals("Nincs hozzárendelt log", NotificationEventStatus.displayText(NotificationEventStatus.MISSING))
        assertEquals("Rendszer", NotificationEventStatus.displayText(NotificationEventStatus.SYSTEM))
    }

    @Test
    fun missingFilterExcludesSystemEvents() {
        assertTrue(NotificationEventStatus.matchesFilter(NotificationEventStatus.MISSING, NotificationEventStatus.MISSING))
        assertFalse(NotificationEventStatus.matchesFilter(NotificationEventStatus.MISSING, NotificationEventStatus.SYSTEM))
        assertTrue(NotificationEventStatus.matchesFilter(NotificationEventStatus.ALL, NotificationEventStatus.SYSTEM))
    }
}
```

Create `NotificationEventEntityTest.kt`:

```kotlin
package com.exptv2.app

import org.junit.Assert.assertEquals
import org.junit.Test

class NotificationEventEntityTest {
    @Test
    fun eventMapIncludesManualStatus() {
        val row = NotificationEventEntity(
            id = 10L,
            timestamp = 1780858800000L,
            source = NotificationEventRepository.SOURCE_NOTIFICATION_LISTENER,
            packageName = "hu.bank.app",
            appLabel = "Bank",
            title = "Vásárlás",
            text = "Kártyás vásárlás: Tesco - 12 345 HUF",
            bigText = "",
            subText = "",
            category = "",
            notificationKey = "n-10",
            accessibilityEventType = "",
            hash = "abc",
            isDuplicate = false,
            manualStatus = NotificationEventStatus.SYSTEM,
        )

        val map = row.toMap()

        assertEquals(NotificationEventStatus.SYSTEM, map["manualStatus"])
    }
}
```

Run:

```bash
./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.NotificationEventStatusTest" --tests "com.exptv2.app.NotificationEventEntityTest"
```

Expected: FAIL because the status object and `manualStatus` do not exist.

- [ ] **Step 2: Add status constants**

Create `NotificationEventStatus.kt`:

```kotlin
package com.exptv2.app

object NotificationEventStatus {
    const val ALL = "all"
    const val LINKED = "linked"
    const val MISSING = "missing"
    const val SYSTEM = "system"

    fun normalizeFilter(value: Any?): String = when (value?.toString()?.trim()?.lowercase()) {
        LINKED -> LINKED
        MISSING -> MISSING
        SYSTEM -> SYSTEM
        else -> ALL
    }

    fun forEvent(manualStatus: String, linkedTransactionId: Int?): String {
        return when {
            manualStatus == SYSTEM -> SYSTEM
            linkedTransactionId != null -> LINKED
            else -> MISSING
        }
    }

    fun matchesFilter(filter: String, status: String): Boolean = when (filter) {
        LINKED -> status == LINKED
        MISSING -> status == MISSING
        SYSTEM -> status == SYSTEM
        else -> true
    }

    fun displayText(status: String): String = when (status) {
        LINKED -> "Van tranzakció"
        SYSTEM -> "Rendszer"
        else -> "Nincs hozzárendelt log"
    }
}
```

- [ ] **Step 3: Add page model DTOs**

Create `NotificationEventPageModels.kt`:

```kotlin
package com.exptv2.app

data class NotificationEventPageQuery(
    val limit: Int,
    val offset: Int,
    val startMillis: Long?,
    val endMillis: Long?,
    val query: String,
    val status: String,
    val packageName: String,
)

data class NotificationEventPageRow(
    val event: NotificationEventEntity,
    val status: String,
    val linkedTransactionId: Int?,
) {
    fun toMap(): Map<String, Any?> {
        val displayText = listOf(event.text, event.bigText, event.subText)
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
            .joinToString("\n")
        return event.toMap() + mapOf(
            "displayText" to displayText,
            "status" to status,
            "statusText" to NotificationEventStatus.displayText(status),
            "linkedTransactionId" to linkedTransactionId,
        )
    }
}

data class NotificationEventPage(
    val events: List<NotificationEventPageRow>,
    val totalCount: Int,
    val limit: Int,
    val offset: Int,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "events" to events.map { it.toMap() },
        "totalCount" to totalCount,
        "limit" to limit,
        "offset" to offset,
    )
}
```

- [ ] **Step 4: Add manual status to notification events**

In `NotificationEventEntity.kt`, add:

```kotlin
val manualStatus: String = "",
```

and include:

```kotlin
"manualStatus" to manualStatus,
```

in `toMap()`.

In `NotificationEventRepository.insertDraft`, pass:

```kotlin
manualStatus = "",
```

- [ ] **Step 5: Add DAO queries**

In `NotificationEventDao.kt`, add:

```kotlin
@Query(
    """
    SELECT * FROM notification_events
    WHERE (:startMillis IS NULL OR timestamp >= :startMillis)
      AND (:endMillis IS NULL OR timestamp < :endMillis)
      AND (:packageName = '' OR packageName = :packageName)
      AND (:query = ''
        OR appLabel LIKE '%' || :query || '%'
        OR packageName LIKE '%' || :query || '%'
        OR title LIKE '%' || :query || '%'
        OR text LIKE '%' || :query || '%'
        OR bigText LIKE '%' || :query || '%'
        OR subText LIKE '%' || :query || '%')
      AND (:systemOnly = 0 OR manualStatus = 'system')
      AND (:excludeSystem = 0 OR manualStatus != 'system')
    ORDER BY timestamp DESC, id DESC
    LIMIT :limit OFFSET :offset
    """
)
suspend fun pageCandidates(
    startMillis: Long?,
    endMillis: Long?,
    packageName: String,
    query: String,
    systemOnly: Int,
    excludeSystem: Int,
    limit: Int,
    offset: Int,
): List<NotificationEventEntity>

@Query("SELECT * FROM notification_events WHERE id = :id LIMIT 1")
suspend fun byId(id: Long): NotificationEventEntity?

@Query("UPDATE notification_events SET manualStatus = :manualStatus WHERE id = :id")
suspend fun updateManualStatus(id: Long, manualStatus: String): Int
```

Keep `allEvents()` for existing debug/event-store use, but do not use it for the new Settings push log.

- [ ] **Step 6: Add PushParserDatabase migration**

In `PushParserDatabase.kt`, import Room migration classes, set `version = 2`, and add:

```kotlin
private val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE notification_events ADD COLUMN manualStatus TEXT NOT NULL DEFAULT ''")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_events_timestamp_id ON notification_events(timestamp, id)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_events_packageName ON notification_events(packageName)")
        db.execSQL("CREATE INDEX IF NOT EXISTS index_notification_events_manualStatus ON notification_events(manualStatus)")
    }
}
```

and:

```kotlin
).addMigrations(MIGRATION_1_2).build().also { instance = it }
```

- [ ] **Step 7: Implement repository paging and system marking**

In `NotificationEventRepository.kt`, add an `ExpenseRepository` property:

```kotlin
private val expenseRepository = ExpenseRepository(appContext)
```

Add:

```kotlin
suspend fun listPage(args: Map<*, *>): NotificationEventPage {
    val pageQuery = pageQuery(args)
    val scanLimit = maxOf(pageQuery.limit * 4, 64).coerceAtMost(500)
    val rows = mutableListOf<NotificationEventPageRow>()
    var total = 0
    var skipped = 0
    var candidateOffset = 0
    while (true) {
        val candidates = dao.pageCandidates(
            startMillis = pageQuery.startMillis,
            endMillis = pageQuery.endMillis,
            packageName = pageQuery.packageName,
            query = pageQuery.query,
            systemOnly = if (pageQuery.status == NotificationEventStatus.SYSTEM) 1 else 0,
            excludeSystem = if (pageQuery.status == NotificationEventStatus.MISSING) 1 else 0,
            limit = scanLimit,
            offset = candidateOffset,
        )
        if (candidates.isEmpty()) break
        val linked = expenseRepository.transactionsBySourceNotificationEventIds(candidates.map { it.id })
        for (event in candidates) {
            val transaction = linked[event.id]
            val status = NotificationEventStatus.forEvent(event.manualStatus, transaction?.id)
            if (!NotificationEventStatus.matchesFilter(pageQuery.status, status)) continue
            total += 1
            if (skipped < pageQuery.offset) {
                skipped += 1
                continue
            }
            if (rows.size < pageQuery.limit) {
                rows.add(NotificationEventPageRow(event, status, transaction?.id))
            }
        }
        candidateOffset += candidates.size
    }
    return NotificationEventPage(rows, total, pageQuery.limit, pageQuery.offset)
}

suspend fun markSystem(id: Long): Boolean {
    return dao.updateManualStatus(id, NotificationEventStatus.SYSTEM) > 0
}
```

Add `pageQuery(args)` with exact parsing:

```kotlin
private fun pageQuery(args: Map<*, *>): NotificationEventPageQuery {
    val limit = optionalInt(args["limit"])?.coerceIn(1, 120) ?: 60
    val offset = optionalInt(args["offset"])?.coerceAtLeast(0) ?: 0
    val year = optionalInt(args["year"])
    val month = optionalInt(args["month"])
    val range = millisRange(year, month)
    return NotificationEventPageQuery(
        limit = limit,
        offset = offset,
        startMillis = range.first,
        endMillis = range.second,
        query = args["query"]?.toString()?.trim().orEmpty(),
        status = NotificationEventStatus.normalizeFilter(args["status"]),
        packageName = args["packageName"]?.toString()?.trim().orEmpty(),
    )
}
```

Use a `Calendar`-based `millisRange(year, month)` helper that returns `(null, null)` when year is null, year range when only year exists, and month range when both exist.

- [ ] **Step 8: Wire the MethodChannel**

In `MainActivity.kt`, add cases before the expense fallback:

```kotlin
"loadNotificationEventPage" -> scope.launch {
    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
    val page = withContext(Dispatchers.IO) { repository.listPage(args).toMap() }
    result.success(page)
}
"markNotificationEventSystem" -> scope.launch {
    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
    val id = (args["id"] as? Number)?.toLong()
        ?: args["id"]?.toString()?.toLongOrNull()
        ?: 0L
    val updated = withContext(Dispatchers.IO) { repository.markSystem(id) }
    result.success(updated)
}
```

- [ ] **Step 9: Run native tests and commit**

Run:

```bash
./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.NotificationEventStatusTest" --tests "com.exptv2.app.NotificationEventEntityTest"
```

Expected: PASS.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app android/app/src/test/kotlin/com/exptv2/app
git commit -m "feat: page push notification events"
```

---

### Task 3: Dart Bridge, Models, And Lazy Store

**Files:**
- Create: `lib/features/settings/models/push_notification_log_event.dart`
- Create: `lib/features/settings/state/push_notification_log_store.dart`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/state/event_store.dart`
- Test: `test/notification_event_test.dart`
- Test: `test/settings/settings_bridge_test.dart`
- Test: `test/settings/push_notification_log_store_test.dart`

- [ ] **Step 1: Write failing bridge/model tests**

Add this test to `test/settings/settings_bridge_test.dart`:

```dart
test('loads paged push notification log events', () async {
  final page = await bridge.loadNotificationEventPage(
    const PushNotificationLogQuery(
      limit: 2,
      offset: 4,
      year: 2026,
      month: 6,
      query: 'tesco',
      status: PushNotificationLogStatus.missing,
    ),
  );

  expect(page.limit, 2);
  expect(page.offset, 4);
  expect(page.totalCount, 8);
  expect(page.events.single.statusText, 'Nincs hozzárendelt log');
});
```

In that test file's mock handler, add:

```dart
case 'loadNotificationEventPage':
  return <String, Object?>{
    'events': <Object?>[
      pushLogEventRow(
        id: 77,
        status: 'missing',
        statusText: 'Nincs hozzárendelt log',
      ),
    ],
    'totalCount': 8,
    'limit': 2,
    'offset': 4,
  };
case 'markNotificationEventSystem':
  return true;
```

Add a helper at the bottom of the file:

```dart
Map<String, Object?> pushLogEventRow({
  required int id,
  required String status,
  required String statusText,
  int? linkedTransactionId,
}) {
  return <String, Object?>{
    'id': id,
    'timestamp': DateTime(2026, 6, 7, 21, 10).millisecondsSinceEpoch,
    'source': 'notification_listener',
    'packageName': 'hu.bank.app',
    'appLabel': 'Bank',
    'title': 'Vásárlás',
    'text': 'Kártyás vásárlás: Tesco - 12 345 HUF',
    'bigText': '',
    'subText': '',
    'category': '',
    'notificationKey': 'n-$id',
    'accessibilityEventType': '',
    'hash': 'h-$id',
    'isDuplicate': false,
    'manualStatus': '',
    'displayText': 'Kártyás vásárlás: Tesco - 12 345 HUF',
    'status': status,
    'statusText': statusText,
    'linkedTransactionId': linkedTransactionId,
  };
}
```

Run:

```bash
flutter test test/settings/settings_bridge_test.dart
```

Expected: FAIL because `PushNotificationLogQuery`, `PushNotificationLogStatus`, and bridge methods do not exist.

- [ ] **Step 2: Add push log model**

Create `push_notification_log_event.dart` with:

```dart
import '../../../models/notification_event.dart';

enum PushNotificationLogStatus {
  all('all', 'Összes'),
  linked('linked', 'Van tranzakció'),
  missing('missing', 'Nincs hozzárendelt log'),
  system('system', 'Rendszer');

  const PushNotificationLogStatus(this.nativeValue, this.label);

  final String nativeValue;
  final String label;

  static PushNotificationLogStatus fromNative(Object? value) {
    final text = value?.toString();
    for (final status in PushNotificationLogStatus.values) {
      if (status.nativeValue == text) return status;
    }
    return PushNotificationLogStatus.missing;
  }
}

class PushNotificationLogQuery {
  const PushNotificationLogQuery({
    this.limit = 60,
    this.offset = 0,
    this.year,
    this.month,
    this.query = '',
    this.status = PushNotificationLogStatus.all,
    this.packageName,
  });

  final int limit;
  final int offset;
  final int? year;
  final int? month;
  final String query;
  final PushNotificationLogStatus status;
  final String? packageName;
  static const Object _noChange = Object();

  Map<String, Object?> toMap() => <String, Object?>{
    'limit': limit,
    'offset': offset,
    'year': year,
    'month': month,
    'query': query,
    'status': status.nativeValue,
    'packageName': packageName,
  };

  PushNotificationLogQuery copyWith({
    int? limit,
    int? offset,
    Object? year = _noChange,
    Object? month = _noChange,
    String? query,
    PushNotificationLogStatus? status,
    Object? packageName = _noChange,
  }) {
    return PushNotificationLogQuery(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      year: identical(year, _noChange) ? this.year : year as int?,
      month: identical(month, _noChange) ? this.month : month as int?,
      query: query ?? this.query,
      status: status ?? this.status,
      packageName: identical(packageName, _noChange)
          ? this.packageName
          : packageName as String?,
    );
  }
}

class PushNotificationLogPage {
  const PushNotificationLogPage({
    required this.events,
    required this.totalCount,
    required this.limit,
    required this.offset,
  });

  final List<PushNotificationLogEvent> events;
  final int totalCount;
  final int limit;
  final int offset;
}

class PushNotificationLogEvent {
  const PushNotificationLogEvent({
    required this.base,
    required this.displayText,
    required this.status,
    required this.statusText,
    required this.linkedTransactionId,
    required this.manualStatus,
  });

  final NotificationEvent base;
  final String displayText;
  final PushNotificationLogStatus status;
  final String statusText;
  final int? linkedTransactionId;
  final String manualStatus;

  int get id => base.id;
  DateTime get timestamp => base.timestamp;
  String get sourceBadge => base.sourceBadge;
  String get displayApp => base.displayApp;
  bool get hasLinkedTransaction => linkedTransactionId != null;
  String get fullText => displayText.trim().isNotEmpty ? displayText : base.bodyText;

  factory PushNotificationLogEvent.fromMap(Map<dynamic, dynamic> map) {
    return PushNotificationLogEvent(
      base: NotificationEvent.fromMap(map),
      displayText: map['displayText']?.toString() ?? '',
      status: PushNotificationLogStatus.fromNative(map['status']),
      statusText: map['statusText']?.toString() ?? PushNotificationLogStatus.fromNative(map['status']).label,
      linkedTransactionId: _nullableInt(map['linkedTransactionId']),
      manualStatus: map['manualStatus']?.toString() ?? '',
    );
  }
}

int _readInt(Object? value) => value is int ? value : int.parse(value.toString());
int? _nullableInt(Object? value) => value == null ? null : _readInt(value);
```

- [ ] **Step 3: Add NativeBridge methods**

In `native_bridge.dart`, import the model and add:

```dart
Future<PushNotificationLogPage> loadNotificationEventPage(
  PushNotificationLogQuery query,
) async {
  final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'loadNotificationEventPage',
    query.toMap(),
  );
  final payload = map ?? <dynamic, dynamic>{};
  final rows = (payload['events'] as List<dynamic>? ?? <dynamic>[])
      .cast<Map<dynamic, dynamic>>()
      .map(PushNotificationLogEvent.fromMap)
      .toList();
  int readInt(String key) {
    final value = payload[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  return PushNotificationLogPage(
    events: rows,
    totalCount: readInt('totalCount'),
    limit: readInt('limit'),
    offset: readInt('offset'),
  );
}

Future<bool> markNotificationEventSystem(int id) async {
  final updated = await _methodChannel.invokeMethod<bool>(
    'markNotificationEventSystem',
    {'id': id},
  );
  return updated ?? false;
}
```

- [ ] **Step 4: Ensure parser profiles are active in Dart selection**

In `EventStore._firstProfileId`, prefer the first enabled profile:

```dart
String? _firstProfileId() {
  for (final profile in notificationParserProfiles) {
    if (profile.enabled) return profile.id;
  }
  return notificationParserProfiles.isEmpty
      ? null
      : notificationParserProfiles.first.id;
}
```

Add this helper:

```dart
Future<void> saveTrainedNotificationParserProfile(
  NotificationParserProfile profile,
) async {
  final enabledProfile = profile.copyWith(enabled: true);
  notificationParserConfig = notificationParserConfig.upsert(enabledProfile);
  selectedNotificationParserProfileId = enabledProfile.id;
  notifyListeners();
  await _saveNotificationParserProfiles();
}
```

- [ ] **Step 5: Add lazy push log store**

Create `push_notification_log_store.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../../../services/native_bridge.dart';
import '../../../state/event_store.dart';
import '../models/notification_parser_rule.dart';
import '../models/push_notification_log_event.dart';

class PushNotificationLogStore extends ChangeNotifier {
  PushNotificationLogStore({
    required NativeBridge bridge,
    required EventStore parserStore,
  }) : _bridge = bridge,
       _parserStore = parserStore;

  static const pageSize = 60;

  final NativeBridge _bridge;
  final EventStore _parserStore;
  final List<PushNotificationLogEvent> _events = <PushNotificationLogEvent>[];

  PushNotificationLogQuery _query = const PushNotificationLogQuery(limit: pageSize);
  bool _loading = false;
  bool _loadingMore = false;
  int _totalCount = 0;
  String? _errorText;

  List<PushNotificationLogEvent> get events => List.unmodifiable(_events);
  PushNotificationLogQuery get query => _query;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  int get totalCount => _totalCount;
  String? get errorText => _errorText;
  bool get hasMore => _events.length < _totalCount;

  Future<void> loadFirstPage() async {
    _loading = true;
    _errorText = null;
    notifyListeners();
    try {
      final page = await _bridge.loadNotificationEventPage(
        _query.copyWith(limit: pageSize, offset: 0),
      );
      _events
        ..clear()
        ..addAll(page.events);
      _totalCount = page.totalCount;
    } catch (error) {
      _errorText = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _bridge.loadNotificationEventPage(
        _query.copyWith(limit: pageSize, offset: _events.length),
      );
      _events.addAll(page.events);
      _totalCount = page.totalCount;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setFilters({
    int? year,
    int? month,
    String? query,
    PushNotificationLogStatus? status,
  }) async {
    _query = _query.copyWith(
      offset: 0,
      year: year,
      month: month,
      query: query,
      status: status,
    );
    await loadFirstPage();
  }

  Future<void> markSystem(PushNotificationLogEvent event) async {
    final updated = await _bridge.markNotificationEventSystem(event.id);
    if (!updated) return;
    await loadFirstPage();
  }

  Future<void> trainAndCreateTransaction({
    required PushNotificationLogEvent event,
    required NotificationParserProfile trainedProfile,
  }) async {
    final preview = trainedProfile.preview;
    if (!preview.isReady || preview.amountValue == null || preview.merchant == null) {
      throw StateError(preview.errorText ?? 'Érvénytelen parser előnézet');
    }
    await _parserStore.saveTrainedNotificationParserProfile(trainedProfile);
    await _bridge.expenseAddTransaction(<String, Object?>{
      'merchant': preview.merchant,
      'amount': preview.amountValue,
      'type': preview.transactionType.nativeValue,
      'transactionCategoryID': null,
      'date': _formatDate(event.timestamp),
      'time': _formatTime(event.timestamp),
      'address': 'Push notification',
      'sourceNotificationEventId': event.id,
    });
    await loadFirstPage();
  }
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 6: Run focused Dart tests and commit**

Run:

```bash
flutter test test/settings/settings_bridge_test.dart test/notification_event_test.dart
flutter test test/settings/push_notification_log_store_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/services/native_bridge.dart lib/state/event_store.dart lib/features/settings/models lib/features/settings/state test/settings test/notification_event_test.dart
git commit -m "feat: add push log bridge and store"
```

---

### Task 4: Settings Entry And Lazy Push Log Screen

**Files:**
- Create: `lib/features/settings/widgets/push_log/push_notification_log_page.dart`
- Create: `lib/features/settings/widgets/push_log/push_notification_log_box.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/settings/widgets/options/settings_option_widgets.dart`
- Test: `test/settings/settings_page_test.dart`
- Test: `test/settings/push_notification_log_page_test.dart`

- [ ] **Step 1: Write failing Settings entry test**

Add to `test/settings/settings_page_test.dart`:

```dart
testWidgets('parsed app submenu opens captured push messages log', (tester) async {
  await tester.pumpWidget(buildSubject());
  await tester.pumpAndSettle();

  await tester.tap(find.text('Megfigyelni kívánt alkalmazás'));
  await tester.pumpAndSettle();

  expect(find.text('PushParser napló'), findsOneWidget);
  expect(find.text('Elkapott push üzenetek'), findsOneWidget);

  await tester.tap(find.text('Elkapott push üzenetek'));
  await tester.pumpAndSettle();

  expect(find.text('Elkapott push üzenetek'), findsWidgets);
  expect(find.byKey(const ValueKey('push-notification-log-list')), findsOneWidget);
});
```

Run:

```bash
flutter test test/settings/settings_page_test.dart
```

Expected: FAIL because the menu entry and submenu do not exist.

- [ ] **Step 2: Add push logbox widget**

Create `push_notification_log_box.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/push_notification_log_event.dart';

class PushNotificationLogBox extends StatelessWidget {
  const PushNotificationLogBox({
    super.key,
    required this.event,
    required this.onTap,
  });

  final PushNotificationLogEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('push-logbox-${event.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 92,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SourceBadge(label: event.sourceBadge),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.displayApp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.gray800,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(event.timestamp),
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.fullText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gray700,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusPill(text: event.statusText, status: event.status),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.gray800,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.status});

  final String text;
  final PushNotificationLogStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PushNotificationLogStatus.linked => const Color(0xFF059669),
      PushNotificationLogStatus.system => AppColors.gray500,
      PushNotificationLogStatus.all || PushNotificationLogStatus.missing => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 3: Add push log page with lazy rendering**

Create `push_notification_log_page.dart` with a `StatefulWidget` that owns a `PushNotificationLogStore`, calls `loadFirstPage()` in `initState`, disposes it, and renders:

```dart
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter < 320 && _store.hasMore) {
      _store.loadMore();
    }
    return false;
  },
  child: ListView.builder(
    key: const ValueKey('push-notification-log-list'),
    cacheExtent: 360,
    itemExtent: 102,
    padding: const EdgeInsets.only(bottom: 96),
    itemCount: _store.events.length + (_store.loadingMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index >= _store.events.length) {
        return const Center(child: CircularProgressIndicator());
      }
      final event = _store.events[index];
      return PushNotificationLogBox(
        event: event,
        onTap: () => _openEvent(event),
      );
    },
  ),
)
```

Use a filter header above the list with:

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    ChoiceChip(label: const Text('Összes'), selected: _store.query.status == PushNotificationLogStatus.all, onSelected: (_) => _setStatus(PushNotificationLogStatus.all)),
    ChoiceChip(label: const Text('Van tranzakció'), selected: _store.query.status == PushNotificationLogStatus.linked, onSelected: (_) => _setStatus(PushNotificationLogStatus.linked)),
    ChoiceChip(label: const Text('Nincs hozzárendelt log'), selected: _store.query.status == PushNotificationLogStatus.missing, onSelected: (_) => _setStatus(PushNotificationLogStatus.missing)),
    ChoiceChip(label: const Text('Rendszer'), selected: _store.query.status == PushNotificationLogStatus.system, onSelected: (_) => _setStatus(PushNotificationLogStatus.system)),
  ],
)
```

Add year/month dropdowns using integer values and a search field with `ValueKey('push-log-search')`. Filter changes call `_store.setFilters(...)` and reset pagination through the store.

- [ ] **Step 4: Add optional subtitle support to Settings rows**

In `settings_option_widgets.dart`, update `SettingsOptionItem`:

```dart
const SettingsOptionItem({
  super.key,
  required this.title,
  this.subtitle,
  this.onTap,
  this.trailing,
  this.isLast = false,
});

final String title;
final String? subtitle;
```

Replace the current title-only `Expanded` block with:

```dart
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        title,
        style: const TextStyle(color: Color(0xFF374151), fontSize: 16),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(
          subtitle!,
          style: const TextStyle(color: AppColors.gray500, fontSize: 12),
        ),
      ],
    ],
  ),
),
```

- [ ] **Step 5: Wire Settings menu**

In `settings_page.dart`, add enum value:

```dart
pushLog,
```

In `_submenuBody(_SettingsMenu.parsedApp)`, insert before `NotificationParserProfilesPanel`:

```dart
SettingsSection(
  title: 'PushParser napló',
  children: [
    SettingsOptionItem(
      title: 'Elkapott push üzenetek',
      subtitle: 'Év, hónap, app, szöveg és log kapcsolat szerint szűrhető',
      onTap: () => _open(_SettingsMenu.pushLog),
      isLast: true,
    ),
  ],
),
const SizedBox(height: 16),
```

In `_submenuBody`, add:

```dart
_SettingsMenu.pushLog => PushNotificationLogPage(
  nativeBridge: widget.nativeBridge,
  parserStore: widget.store,
),
```

In `_menuTitle`, add:

```dart
_SettingsMenu.pushLog => 'Elkapott push üzenetek',
```

- [ ] **Step 6: Run Settings UI tests and commit**

Run:

```bash
flutter test test/settings/settings_page_test.dart test/settings/push_notification_log_page_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/features/settings test/settings
git commit -m "feat: add push log settings screen"
```

---

### Task 5: Event Detail Sheet And Parser Training Action

**Files:**
- Create: `lib/features/settings/widgets/push_log/push_notification_event_sheet.dart`
- Modify: `lib/features/settings/widgets/push_log/push_notification_log_page.dart`
- Modify: `lib/features/settings/state/push_notification_log_store.dart`
- Test: `test/settings/push_notification_log_page_test.dart`
- Test: `test/settings/push_notification_log_store_test.dart`

- [ ] **Step 1: Write failing bottom-sheet tests**

Add to `test/settings/push_notification_log_page_test.dart`:

```dart
testWidgets('event sheet shows final training actions without separate create button', (tester) async {
  await tester.pumpWidget(buildPushLogSubject());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('push-logbox-77')));
  await tester.pumpAndSettle();

  expect(find.text('Tanítás és log létrehozása'), findsOneWidget);
  expect(find.text('Rendszerüzenetként jelölés'), findsOneWidget);
  expect(find.text('Bezárás'), findsOneWidget);
  expect(find.text('Log létrehozása'), findsNothing);
});
```

Add to `test/settings/push_notification_log_store_test.dart`:

```dart
test('valid training creates uncategorized transaction linked to event', () async {
  final store = buildStoreWithEvent();
  await store.loadFirstPage();
  final event = store.events.single;
  final profile = NotificationParserProfile.defaults().copyWith(
    sampleText: event.fullText,
  ).learnAmountFromSelection('12 345 HUF').learnMerchantFromSelection('Tesco');

  await store.trainAndCreateTransaction(event: event, trainedProfile: profile);

  expect(savedTransactions.single['transactionCategoryID'], isNull);
  expect(savedTransactions.single['sourceNotificationEventId'], 77);
  expect(savedProfiles.single['profiles'], isNotEmpty);
});
```

Run:

```bash
flutter test test/settings/push_notification_log_page_test.dart test/settings/push_notification_log_store_test.dart
```

Expected: FAIL because the sheet does not exist.

- [ ] **Step 2: Add event sheet widget**

Create `push_notification_event_sheet.dart` with:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../state/event_store.dart';
import '../../models/notification_parser_rule.dart';
import '../../models/push_notification_log_event.dart';
import '../../state/push_notification_log_store.dart';

enum _PushSheetTrainingMode { amount, merchant }

class PushNotificationEventSheet extends StatefulWidget {
  const PushNotificationEventSheet({
    super.key,
    required this.event,
    required this.parserStore,
    required this.logStore,
  });

  final PushNotificationLogEvent event;
  final EventStore parserStore;
  final PushNotificationLogStore logStore;

  @override
  State<PushNotificationEventSheet> createState() => _PushNotificationEventSheetState();
}

class _PushNotificationEventSheetState extends State<PushNotificationEventSheet> {
  late NotificationParserProfile _profile;
  var _mode = _PushSheetTrainingMode.amount;
  var _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _profile = widget.parserStore.selectedNotificationParserProfile.copyWith(
      enabled: true,
      sampleText: widget.event.fullText,
      includeKeyword: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final tokens = NotificationTrainingToken.fromSample(event.fullText);
    final preview = _profile.preview;
    final canCreate = !event.hasLinkedTransaction && preview.isReady && !_saving;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${event.displayApp} · ${event.statusText.toLowerCase()}',
                style: const TextStyle(
                  color: AppColors.gray800,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatTimestamp(event.timestamp)} · ${event.sourceBadge} · #${event.id}',
                style: const TextStyle(color: AppColors.gray500, fontSize: 12),
              ),
              const SizedBox(height: 14),
              SelectableText(
                event.fullText,
                style: const TextStyle(color: AppColors.gray800, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 14),
              if (!event.hasLinkedTransaction) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('push-event-mode-amount'),
                      label: const Text('Összeg'),
                      selected: _mode == _PushSheetTrainingMode.amount,
                      onSelected: (_) => setState(() => _mode = _PushSheetTrainingMode.amount),
                    ),
                    ChoiceChip(
                      key: const ValueKey('push-event-mode-merchant'),
                      label: const Text('Bolt'),
                      selected: _mode == _PushSheetTrainingMode.merchant,
                      onSelected: (_) => setState(() => _mode = _PushSheetTrainingMode.merchant),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final token in tokens)
                      ActionChip(
                        key: ValueKey('push-event-token-${token.text}'),
                        label: Text(token.text),
                        onPressed: () => _selectToken(token),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _PreviewBox(preview: preview),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorText!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const ValueKey('push-event-train-create'),
                  onPressed: canCreate ? _trainAndCreate : null,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.school, size: 18),
                  label: const Text('Tanítás és log létrehozása'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('push-event-mark-system'),
                  onPressed: _saving ? null : _markSystem,
                  child: const Text('Rendszerüzenetként jelölés'),
                ),
              ] else ...[
                Text(
                  'Kapcsolt log: #${event.linkedTransactionId}',
                  key: const ValueKey('push-event-linked-transaction'),
                  style: const TextStyle(color: AppColors.gray700, fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('push-event-close'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bezárás'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectToken(NotificationTrainingToken token) {
    setState(() {
      _profile = switch (_mode) {
        _PushSheetTrainingMode.amount => _profile.learnAmountFromSelection(token.text),
        _PushSheetTrainingMode.merchant => _profile.learnMerchantFromSelection(token.text),
      };
      _errorText = null;
    });
  }

  Future<void> _trainAndCreate() async {
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      await widget.logStore.trainAndCreateTransaction(
        event: widget.event,
        trainedProfile: _profile,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = error.toString();
      });
    }
  }

  Future<void> _markSystem() async {
    await widget.logStore.markSystem(widget.event);
    if (mounted) Navigator.of(context).pop();
  }
}
```

Add `_PreviewBox` with rows for `Összeg`, `Bolt`, and `Típus` using `NotificationParserPreview`, matching the existing parser editor labels. Use exact fallback text `Nincs találat`.

- [ ] **Step 3: Open the sheet from the list**

In `PushNotificationLogPage._openEvent`, use:

```dart
Future<void> _openEvent(PushNotificationLogEvent event) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => PushNotificationEventSheet(
      event: event,
      parserStore: widget.parserStore,
      logStore: _store,
    ),
  );
}
```

- [ ] **Step 4: Run sheet/store tests and commit**

Run:

```bash
flutter test test/settings/push_notification_log_page_test.dart test/settings/push_notification_log_store_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/features/settings test/settings
git commit -m "feat: train parser from push log events"
```

---

### Task 6: Parser Enablement, Integration Checks, And Review

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationParserRuleStore.kt`
- Test: `test/event_store_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Add failing parser activation test**

Add to `test/event_store_test.dart`:

```dart
test('selects enabled parser profile after load', () async {
  final store = EventStore(
    NativeBridge(methodChannel: methodChannel, eventChannel: eventChannel),
    realtimeEnabled: false,
  );

  await store.start();

  expect(store.selectedNotificationParserProfile.enabled, isTrue);
});
```

Update the mock `loadNotificationParserProfiles` response in this test so the first profile is disabled and the second is enabled:

```dart
'enabled': false,
```

for `bank-a`, and:

```dart
'enabled': true,
```

for `bank-b`.

Run:

```bash
flutter test test/event_store_test.dart
```

Expected: FAIL until `_firstProfileId()` prefers enabled profiles.

- [ ] **Step 2: Ensure native parser profiles never load all-disabled**

In `NotificationParserRuleStore.kt`, change `loadProfiles()` to:

```kotlin
fun loadProfiles(): Map<String, Any?> = mapOf(
    "profiles" to ensureEnabledProfile(loadProfileRows()),
)
```

Change `saveProfiles(args)` to save the ensured rows:

```kotlin
val ensuredRows = ensureEnabledProfile(
    rows.filterIsInstance<Map<*, *>>().map { it.toStringMap() },
)
val json = JSONArray()
ensuredRows.forEach { row -> json.put(JSONObject(row)) }
prefs.edit().putString(KEY_PROFILES_JSON, json.toString()).apply()
return loadProfiles()
```

Add:

```kotlin
private fun ensureEnabledProfile(rows: List<Map<String, Any?>>): List<Map<String, Any?>> {
    val safeRows = rows.ifEmpty { listOf(defaultProfile()) }
    if (safeRows.any { it["enabled"] as? Boolean == true }) return safeRows
    return safeRows.mapIndexed { index, row ->
        if (index == 0) {
            row.toMutableMap().apply { put("enabled", true) }
        } else {
            row
        }
    }
}
```

This only enables the app parser profile. Android Notification Listener and Accessibility permissions stay controlled by Android settings and continue to be surfaced through `getStatus`.

- [ ] **Step 3: Run complete focused verification**

Run these local checks:

```bash
flutter analyze
flutter test test/event_store_test.dart test/settings/settings_bridge_test.dart test/settings/settings_page_test.dart test/settings/push_notification_log_store_test.dart test/settings/push_notification_log_page_test.dart test/transactions/transaction_models_test.dart test/transactions/transaction_widgets_test.dart test/notification_event_test.dart
./gradlew :app:testDebugUnitTest
```

Expected: PASS.

Do not run a local Flutter APK build in Termux/Android.

- [ ] **Step 4: Request code review**

Use `superpowers:requesting-code-review`. Ask the reviewer to check:

```text
Review the push notification log training feature for:
1. Spec compliance with docs/superpowers/specs/2026-06-07-push-notification-log-training-design.md.
2. Room migration safety for nullable transactionCategoryID and sourceNotificationEventId.
3. Event paging performance for thousands of notification rows.
4. Exact Hungarian UI labels: Van tranzakció, Nincs hozzárendelt log, Rendszer, Tanítás és log létrehozása.
5. Absence of parser category selection.
6. Raw notification events are never deleted by the new UI.
```

- [ ] **Step 5: Commit final fixes and push**

After review fixes and passing checks:

```bash
git status --short
git add android/app/src/main/kotlin android/app/src/test/kotlin lib test docs/superpowers
git commit -m "feat: add push notification log training"
git push -u origin feature/push-notification-log-training
```

If there are no remaining staged code changes after review, skip the final commit and push the existing branch.

## Self-Review

Spec coverage:

- Entry point and submenu are covered in Task 4.
- Lazy rendering and page append behavior are covered in Tasks 3 and 4.
- Exact status text and status filtering are covered in Tasks 2 and 4.
- Detail sheet actions and absence of separate `Log létrehozása` are covered in Task 5.
- Raw messages remain in `notification_events`; the only new event mutation is `manualStatus = system` in Task 2.
- `sourceNotificationEventId` and live transaction link lookup are covered in Tasks 1 and 2.
- Uncategorized transaction creation and gray question-mark avatar are covered in Tasks 1 and 5.
- Parser profile enablement is covered in Task 6.
- Category selection is deliberately absent from the parser sheet.

Deferred-work marker scan:

- No deferred-work markers are present.
- Every new method name used by later tasks is introduced before use.
- The final labels match the approved Hungarian text.

Type consistency:

- Native event ids use `Long`.
- Native transaction ids remain `Int`.
- Dart event ids and linked transaction ids are `int`.
- Dart `transactionCategoryID` is `int?`.
- Native `transactionCategoryID` is `Int?`.
- Push status native values are `all`, `linked`, `missing`, and `system`.
