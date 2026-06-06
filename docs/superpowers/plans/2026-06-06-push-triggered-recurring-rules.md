# Push-Triggered Recurring Rules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace manual-only recurring transactions with a long-term recurring rule/instance system that supports both date-triggered and push-triggered fixed items, managed from FAB long-press instead of Settings.

**Architecture:** Kotlin/Room owns the durable recurring rule model, instance generation, date activation, push parsing/matching, and recurring transaction creation. Flutter owns the manager UI, parser training UX, settings toggle for conflict behavior, and rendering pending instances as ghost cards. Existing recurring rows migrate into the new `recurring_rules` and `recurring_rule_instances` domain.

**Tech Stack:** Flutter/Dart, Kotlin, Room, MethodChannel, Android notification listener/accessibility capture, AlarmManager, flutter_test, JUnit.

---

## Scope Check

This plan touches native schema, native recurring activation, push parsing, Dart bridge/models, transaction store rendering, shell/FAB behavior, Settings, category menu, and widget tests. These are tightly coupled through the new recurring rule/instance model, so this remains one implementation plan with commit-sized tasks. Do not implement unrelated FastInfo catalog redesigns or unrelated visual polish in this branch.

## File Structure

Create native recurring rule domain files:

- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringTriggerType.kt`: native enum-like constants for `date` and `push`.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleEntity.kt`: Room entity for user-managed recurring rules.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstanceEntity.kt`: Room entity for monthly ghost/activation instances.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleDao.kt`: CRUD and active-rule queries.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstanceDao.kt`: pending/current/activation queries.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstancePlanner.kt`: pure monthly instance planning.
- `android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringParser.kt`: native parser for rule-scoped push samples/events.
- `android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringMatcher.kt`: deterministic scoring for pending push instances.

Modify native files:

- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`: add new entities/DAOs and migration.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt`: add `recurringRuleId` and `recurringInstanceId`.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`: keep current queries; add indexes for new recurring link fields.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`: route recurring CRUD, monthly generation, activation, and notification-trigger matching through the new model.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`: expose recurring rule methods.
- `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`: call native expense processing after a new notification event is stored.
- `android/app/src/main/kotlin/com/exptv2/app/PushNotificationListenerService.kt`: keep capture path, relying on repository hook.
- `android/app/src/main/kotlin/com/exptv2/app/PushAccessibilityService.kt`: keep capture path, relying on repository hook.

Create Dart files:

- `lib/features/transactions/models/recurring_rule.dart`: Dart model and draft for recurring rules.
- `lib/features/transactions/models/recurring_rule_instance.dart`: Dart model for pending/activated instances.
- `lib/features/transactions/widgets/recurring_manager/recurring_manager_sheet.dart`: combined manager sheet.
- `lib/features/transactions/widgets/recurring_manager/recurring_rule_editor.dart`: upper form for date/push rules.
- `lib/features/transactions/widgets/recurring_manager/recurring_rule_list.dart`: lower grouped manager list.
- `lib/features/transactions/widgets/recurring_manager/push_rule_training_panel.dart`: rule-scoped parser trainer.

Modify Dart files:

- `lib/services/native_bridge.dart`: add recurring rule methods and parse new bootstrap fields.
- `lib/features/transactions/data/transaction_repository.dart`: expose recurring rule/instance repository methods.
- `lib/features/transactions/state/transaction_store.dart`: load/render pending instances, exclude pending from totals, refresh after activation.
- `lib/features/transactions/models/transaction_record.dart`: parse new recurring link fields and update `isRecurringGenerated`.
- `lib/features/transactions/models/transaction_log_entry.dart`: point ghost entries at `RecurringRuleInstance`.
- `lib/features/transactions/widgets/recurring_ghost_log_box.dart`: render new instance model.
- `lib/features/transactions/widgets/transaction_log_list.dart`: pass new ghost records.
- `lib/features/shell/expt_shell.dart`: FAB long-press opens recurring manager, no category editor long-press.
- `lib/features/shell/widgets/expt_fab.dart`: preserve long-press callback shape.
- `lib/features/settings/settings_page.dart`: remove recurring manager entry and keep only global push-match setting.
- `lib/features/settings/state/settings_store.dart`: remove recurring CRUD, add push-match setting persistence.
- `lib/features/settings/data/settings_repository.dart`: remove recurring CRUD from Settings repository.
- `lib/features/settings/widgets/options/recurring_options_panel.dart`: remove after manager replacement.
- `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`: add header plus button.
- `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`: route plus button to category editor.

Test files:

- `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringRuleInstancePlannerTest.kt`
- `android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringParserTest.kt`
- `android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringMatcherTest.kt`
- `test/transactions/recurring_rule_models_test.dart`
- `test/transactions/recurring_manager_sheet_test.dart`
- `test/transactions/transaction_store_test.dart`
- `test/transactions/recurring_ghost_log_test.dart`
- `test/settings/settings_page_test.dart`
- `test/settings/settings_store_test.dart`
- `test/transactions/category_menu_test.dart`
- `test/widget_test.dart`

---

### Task 1: Native Schema And Migration

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringTriggerType.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleEntity.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstanceEntity.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleDao.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstanceDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseTransactionEntityTest.kt`

- [ ] **Step 1: Extend the transaction entity test first**

Add assertions proving transaction maps expose both new recurring links while preserving old parsing expectations:

```kotlin
@Test
fun transactionMapIncludesRecurringRuleAndInstanceLinks() {
    val row = ExpenseTransactionEntity(
        id = 26060101,
        date = "2026.06.01",
        time = "09:10",
        latitude = null,
        longitude = null,
        address = "Push",
        merchant = "OTP Bank",
        amount = -120000.0,
        userAssignedName = "Lakáshitel",
        transactionCategoryID = 6,
        recurringTransactionId = 9,
        recurringRuleId = 90,
        recurringInstanceId = 900,
    )

    val map = row.toMap()

    assertEquals(9, map["recurringTransactionId"])
    assertEquals(90, map["recurringRuleId"])
    assertEquals(900, map["recurringInstanceId"])
}
```

- [ ] **Step 2: Run the native entity test and verify failure**

Run:

```bash
./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.expense.ExpenseTransactionEntityTest"
```

Expected: FAIL because `recurringRuleId` and `recurringInstanceId` do not exist.

- [ ] **Step 3: Add native trigger constants**

Create `RecurringTriggerType.kt`:

```kotlin
package com.exptv2.app.expense

object RecurringTriggerType {
    const val DATE = "date"
    const val PUSH = "push"

    fun normalize(value: String?): String = when (value?.trim()?.lowercase()) {
        PUSH -> PUSH
        else -> DATE
    }
}
```

- [ ] **Step 4: Add `RecurringRuleEntity`**

Create `RecurringRuleEntity.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "recurring_rules",
    foreignKeys = [
        ForeignKey(
            entity = TransactionCategoryEntity::class,
            parentColumns = ["transactionCategoryID"],
            childColumns = ["categoryId"],
            onDelete = ForeignKey.RESTRICT,
        ),
    ],
    indices = [
        Index("triggerType"),
        Index("transactionType"),
        Index("categoryId"),
        Index("expectedDayOfMonth"),
        Index("isActive"),
    ],
)
data class RecurringRuleEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val triggerType: String,
    val transactionType: String,
    val name: String,
    val estimatedAmount: Double,
    val expectedDayOfMonth: Int,
    val categoryId: Int,
    val categoryName: String,
    val categoryColor: String,
    val categoryIconSlot: Int,
    val isActive: Boolean,
    val appFilterText: String,
    val packageName: String,
    val appLabel: String,
    val sampleText: String,
    val includeKeyword: String,
    val amountPattern: String,
    val amountSelection: String,
    val merchantPattern: String,
    val merchantSelection: String,
    val dateToleranceDays: Int,
    val amountTolerancePercent: Double,
    val amountToleranceMin: Double,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "triggerType" to triggerType,
        "transactionType" to transactionType,
        "name" to name,
        "estimatedAmount" to estimatedAmount,
        "expectedDayOfMonth" to expectedDayOfMonth,
        "categoryId" to categoryId,
        "categoryName" to categoryName,
        "categoryColor" to categoryColor,
        "categoryIconSlot" to categoryIconSlot,
        "isActive" to isActive,
        "appFilterText" to appFilterText,
        "packageName" to packageName,
        "appLabel" to appLabel,
        "sampleText" to sampleText,
        "includeKeyword" to includeKeyword,
        "amountPattern" to amountPattern,
        "amountSelection" to amountSelection,
        "merchantPattern" to merchantPattern,
        "merchantSelection" to merchantSelection,
        "dateToleranceDays" to dateToleranceDays,
        "amountTolerancePercent" to amountTolerancePercent,
        "amountToleranceMin" to amountToleranceMin,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
```

- [ ] **Step 5: Add `RecurringRuleInstanceEntity`**

Create `RecurringRuleInstanceEntity.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

object RecurringRuleInstanceStatus {
    const val PENDING = "pending"
    const val ACTIVATED = "activated"
    const val EXPIRED = "expired"
}

@Entity(
    tableName = "recurring_rule_instances",
    foreignKeys = [
        ForeignKey(
            entity = RecurringRuleEntity::class,
            parentColumns = ["id"],
            childColumns = ["ruleId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(value = ["ruleId", "periodKey"], unique = true),
        Index("status"),
        Index("periodKey"),
        Index("estimatedDate"),
        Index("matchedNotificationEventId"),
    ],
)
data class RecurringRuleInstanceEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val ruleId: Int,
    val periodKey: String,
    val status: String,
    val estimatedDate: String,
    val estimatedAmount: Double,
    val triggerTypeSnapshot: String,
    val transactionTypeSnapshot: String,
    val nameSnapshot: String,
    val categoryIdSnapshot: Int,
    val categoryNameSnapshot: String,
    val categoryColorSnapshot: String,
    val categoryIconSlotSnapshot: Int,
    val activatedTransactionId: Int?,
    val activatedAt: Long?,
    val matchedNotificationEventId: Long?,
    val matchConfidence: Double?,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "ruleId" to ruleId,
        "periodKey" to periodKey,
        "status" to status,
        "estimatedDate" to estimatedDate,
        "estimatedAmount" to estimatedAmount,
        "triggerTypeSnapshot" to triggerTypeSnapshot,
        "transactionTypeSnapshot" to transactionTypeSnapshot,
        "nameSnapshot" to nameSnapshot,
        "categoryIdSnapshot" to categoryIdSnapshot,
        "categoryNameSnapshot" to categoryNameSnapshot,
        "categoryColorSnapshot" to categoryColorSnapshot,
        "categoryIconSlotSnapshot" to categoryIconSlotSnapshot,
        "activatedTransactionId" to activatedTransactionId,
        "activatedAt" to activatedAt,
        "matchedNotificationEventId" to matchedNotificationEventId,
        "matchConfidence" to matchConfidence,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
```

- [ ] **Step 6: Add DAOs**

Create `RecurringRuleDao.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface RecurringRuleDao {
    @Query("SELECT * FROM recurring_rules ORDER BY expectedDayOfMonth ASC, name ASC")
    suspend fun all(): List<RecurringRuleEntity>

    @Query("SELECT * FROM recurring_rules WHERE isActive = 1 ORDER BY expectedDayOfMonth ASC, name ASC")
    suspend fun active(): List<RecurringRuleEntity>

    @Query("SELECT * FROM recurring_rules WHERE id = :id LIMIT 1")
    suspend fun byId(id: Int): RecurringRuleEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(row: RecurringRuleEntity): Long

    @Update
    suspend fun update(row: RecurringRuleEntity)

    @Delete
    suspend fun delete(row: RecurringRuleEntity)

    @Query("DELETE FROM recurring_rules")
    suspend fun clearAll()
}
```

Create `RecurringRuleInstanceDao.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface RecurringRuleInstanceDao {
    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' ORDER BY estimatedDate DESC, id DESC")
    suspend fun pending(): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' AND periodKey = :periodKey ORDER BY estimatedDate ASC, id ASC")
    suspend fun pendingForPeriod(periodKey: String): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE status = 'pending' AND triggerTypeSnapshot = 'date' AND estimatedDate <= :date ORDER BY estimatedDate ASC, id ASC")
    suspend fun dueDateTriggered(date: String): List<RecurringRuleInstanceEntity>

    @Query("SELECT * FROM recurring_rule_instances WHERE ruleId = :ruleId AND periodKey = :periodKey LIMIT 1")
    suspend fun byRuleAndPeriod(ruleId: Int, periodKey: String): RecurringRuleInstanceEntity?

    @Query("SELECT COUNT(*) FROM recurring_rule_instances WHERE matchedNotificationEventId = :eventId AND status = 'activated'")
    suspend fun activatedCountForNotificationEvent(eventId: Long): Int

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(row: RecurringRuleInstanceEntity): Long

    @Query("UPDATE recurring_rule_instances SET status = :status, updatedAt = :updatedAt WHERE id = :id")
    suspend fun updateStatus(id: Int, status: String, updatedAt: Long)

    @Query("UPDATE recurring_rule_instances SET status = 'activated', activatedTransactionId = :transactionId, activatedAt = :activatedAt, matchedNotificationEventId = :eventId, matchConfidence = :confidence, updatedAt = :activatedAt WHERE id = :id")
    suspend fun markActivated(id: Int, transactionId: Int, activatedAt: Long, eventId: Long?, confidence: Double?)

    @Query("UPDATE recurring_rule_instances SET status = 'expired', updatedAt = :updatedAt WHERE status = 'pending' AND periodKey < :currentPeriodKey")
    suspend fun expirePastPending(currentPeriodKey: String, updatedAt: Long)

    @Query("DELETE FROM recurring_rule_instances WHERE ruleId = :ruleId AND status = 'pending'")
    suspend fun deletePendingForRule(ruleId: Int)

    @Query("DELETE FROM recurring_rule_instances")
    suspend fun clearAll()
}
```

- [ ] **Step 7: Extend transaction entity**

Modify `ExpenseTransactionEntity` constructor and `toMap()`:

```kotlin
val recurringTransactionId: Int? = null,
val recurringRuleId: Int? = null,
val recurringInstanceId: Int? = null,
```

Add to the map:

```kotlin
"recurringTransactionId" to recurringTransactionId,
"recurringRuleId" to recurringRuleId,
"recurringInstanceId" to recurringInstanceId,
```

- [ ] **Step 8: Update `ExpenseTrackerDatabase`**

Increase the database version from `7` to `8`. Add the two new entities and abstract DAO methods:

```kotlin
RecurringRuleEntity::class,
RecurringRuleInstanceEntity::class,

abstract fun recurringRules(): RecurringRuleDao
abstract fun recurringRuleInstances(): RecurringRuleInstanceDao
```

Add `MIGRATION_7_8` that:

```kotlin
db.execSQL("ALTER TABLE transactions ADD COLUMN recurringRuleId INTEGER")
db.execSQL("ALTER TABLE transactions ADD COLUMN recurringInstanceId INTEGER")
db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_recurringRuleId ON transactions(recurringRuleId)")
db.execSQL("CREATE INDEX IF NOT EXISTS index_transactions_recurringInstanceId ON transactions(recurringInstanceId)")
```

Then create `recurring_rules` and `recurring_rule_instances` tables with the columns from Steps 4 and 5, copy old rows into date-triggered rules, and copy old ghost rows into instances. Use `triggerType = 'date'`, `estimatedAmount = amount`, `expectedDayOfMonth = dayOfMonth`, `estimatedDate = date`, and status based on `isActivated`.

- [ ] **Step 9: Run native entity test**

Run:

```bash
./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.expense.ExpenseTransactionEntityTest"
```

Expected: PASS.

- [ ] **Step 10: Commit schema work**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/RecurringTriggerType.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleEntity.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstanceEntity.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleDao.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstanceDao.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt \
  android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseTransactionEntityTest.kt
git commit -m "feat: add recurring rule schema"
```

---

### Task 2: Rule Instance Planning And Date Activation

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstancePlanner.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringRuleInstancePlannerTest.kt`

- [ ] **Step 1: Write planner tests**

Create `RecurringRuleInstancePlannerTest.kt`:

```kotlin
package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class RecurringRuleInstancePlannerTest {
    private val utc = TimeZone.getTimeZone("UTC")

    @Test
    fun createsCurrentMonthInstanceFromExpectedDayAndAmount() {
        val plan = RecurringRuleInstancePlanner.plan(
            targetMillis = millis(2026, Calendar.JUNE, 6),
            expectedDayOfMonth = 15,
            estimatedAmount = 120000.0,
            timeZone = utc,
        )

        assertEquals("2026-06", plan.periodKey)
        assertEquals("2026.06.15", plan.estimatedDate)
        assertEquals(120000.0, plan.estimatedAmount, 0.0)
    }

    @Test
    fun clampsExpectedDayToLastDayOfShortMonth() {
        val plan = RecurringRuleInstancePlanner.plan(
            targetMillis = millis(2026, Calendar.FEBRUARY, 1),
            expectedDayOfMonth = 31,
            estimatedAmount = 9900.0,
            timeZone = utc,
        )

        assertEquals("2026-02", plan.periodKey)
        assertEquals("2026.02.28", plan.estimatedDate)
    }

    private fun millis(year: Int, month: Int, day: Int): Long {
        return Calendar.getInstance(utc).apply {
            clear()
            set(year, month, day, 12, 0, 0)
        }.timeInMillis
    }
}
```

- [ ] **Step 2: Run planner tests and verify failure**

Run:

```bash
./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.expense.RecurringRuleInstancePlannerTest"
```

Expected: FAIL because `RecurringRuleInstancePlanner` does not exist.

- [ ] **Step 3: Implement planner**

Create `RecurringRuleInstancePlanner.kt`:

```kotlin
package com.exptv2.app.expense

import java.util.Calendar
import java.util.TimeZone

data class RecurringRuleInstancePlan(
    val periodKey: String,
    val estimatedDate: String,
    val estimatedAmount: Double,
)

object RecurringRuleInstancePlanner {
    fun plan(
        targetMillis: Long,
        expectedDayOfMonth: Int,
        estimatedAmount: Double,
        timeZone: TimeZone = TimeZone.getDefault(),
    ): RecurringRuleInstancePlan {
        val calendar = Calendar.getInstance(timeZone).apply { timeInMillis = targetMillis }
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        val maxDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        val effectiveDay = expectedDayOfMonth.coerceIn(1, maxDay)
        return RecurringRuleInstancePlan(
            periodKey = "%04d-%02d".format(year, month + 1),
            estimatedDate = "%04d.%02d.%02d".format(year, month + 1, effectiveDay),
            estimatedAmount = estimatedAmount,
        )
    }
}
```

- [ ] **Step 4: Run planner tests and verify pass**

Run the command from Step 2.

Expected: PASS.

- [ ] **Step 5: Wire repository generation methods**

In `ExpenseRepository`, add new DAO properties:

```kotlin
private val recurringRules = db.recurringRules()
private val recurringRuleInstances = db.recurringRuleInstances()
```

Add a private method:

```kotlin
private suspend fun ensureRecurringRuleInstancesForPeriod(targetMillis: Long) {
    val now = System.currentTimeMillis()
    val currentPeriod = RecurringRuleInstancePlanner.plan(targetMillis, 1, 0.0).periodKey
    recurringRuleInstances.expirePastPending(currentPeriod, now)
    for (rule in recurringRules.active()) {
        val plan = RecurringRuleInstancePlanner.plan(
            targetMillis = targetMillis,
            expectedDayOfMonth = rule.expectedDayOfMonth,
            estimatedAmount = rule.estimatedAmount,
        )
        if (recurringRuleInstances.byRuleAndPeriod(rule.id, plan.periodKey) != null) continue
        recurringRuleInstances.insert(
            RecurringRuleInstanceEntity(
                ruleId = rule.id,
                periodKey = plan.periodKey,
                status = RecurringRuleInstanceStatus.PENDING,
                estimatedDate = plan.estimatedDate,
                estimatedAmount = plan.estimatedAmount,
                triggerTypeSnapshot = rule.triggerType,
                transactionTypeSnapshot = rule.transactionType,
                nameSnapshot = rule.name,
                categoryIdSnapshot = rule.categoryId,
                categoryNameSnapshot = rule.categoryName,
                categoryColorSnapshot = rule.categoryColor,
                categoryIconSlotSnapshot = rule.categoryIconSlot,
                activatedTransactionId = null,
                activatedAt = null,
                matchedNotificationEventId = null,
                matchConfidence = null,
                createdAt = now,
                updatedAt = now,
            ),
        )
    }
}
```

- [ ] **Step 6: Replace ghost bootstrap source**

In `ExpenseRepository.bootstrap()`, call `ensureRecurringRuleInstancesForPeriod(recurringTargetMillis())`, and return pending instances under the existing payload key initially:

```kotlin
"recurringGhostTransactions" to recurringRuleInstances.pending().map { it.toMap() }
```

Keep the old key until Dart is migrated in Task 4.

- [ ] **Step 7: Commit planner work**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstancePlanner.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt \
  android/app/src/test/kotlin/com/exptv2/app/expense/RecurringRuleInstancePlannerTest.kt
git commit -m "feat: generate recurring rule instances"
```

---

### Task 3: Native Push Parser And Matcher

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringParser.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringMatcher.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringParserTest.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringMatcherTest.kt`

- [ ] **Step 1: Write parser tests**

Create `PushRecurringParserTest.kt`:

```kotlin
package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PushRecurringParserTest {
    @Test
    fun parsesAmountAndMerchantFromRulePatterns() {
        val result = PushRecurringParser.parse(
            text = "Terheles: 121 550 Ft. Partner: OTP Lakashitel.",
            amountPattern = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*Ft)",
            merchantPattern = "Partner:\\s*(?<merchant>.+?)(?:\\.|$)",
            includeKeyword = "Terheles",
        )

        assertEquals(121550.0, result.amount, 0.0)
        assertEquals("OTP Lakashitel", result.merchant)
        assertNull(result.error)
    }

    @Test
    fun returnsErrorWhenKeywordMissing() {
        val result = PushRecurringParser.parse(
            text = "Kartya vasarlas 1200 Ft Bolt",
            amountPattern = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*Ft)",
            merchantPattern = "(?<merchant>Bolt)",
            includeKeyword = "Terheles",
        )

        assertEquals("keyword_missing", result.error)
    }
}
```

- [ ] **Step 2: Implement parser**

Create `PushRecurringParser.kt`:

```kotlin
package com.exptv2.app.expense

data class PushRecurringParseResult(
    val amount: Double?,
    val merchant: String?,
    val error: String?,
)

object PushRecurringParser {
    fun parse(
        text: String,
        amountPattern: String,
        merchantPattern: String,
        includeKeyword: String,
    ): PushRecurringParseResult {
        val normalized = normalize(text)
        val keyword = normalize(includeKeyword)
        if (keyword.isNotEmpty() && !normalized.contains(keyword, ignoreCase = true)) {
            return PushRecurringParseResult(null, null, "keyword_missing")
        }
        val amountRegex = runCatching { Regex(amountPattern, RegexOption.IGNORE_CASE) }
            .getOrElse { return PushRecurringParseResult(null, null, "amount_regex_invalid") }
        val merchantRegex = runCatching { Regex(merchantPattern, RegexOption.IGNORE_CASE) }
            .getOrElse { return PushRecurringParseResult(null, null, "merchant_regex_invalid") }
        val amountText = capture(amountRegex.find(normalized), "amount")
        val merchant = capture(merchantRegex.find(normalized), "merchant")?.trim()
        val amount = parseAmount(amountText)
        return when {
            amount == null -> PushRecurringParseResult(null, merchant, "amount_missing")
            merchant.isNullOrBlank() -> PushRecurringParseResult(amount, null, "merchant_missing")
            else -> PushRecurringParseResult(amount, merchant, null)
        }
    }

    private fun normalize(value: String): String = value
        .replace('\u00A0', ' ')
        .replace('\u202F', ' ')
        .replace(Regex("\\s+"), " ")
        .trim()

    private fun capture(match: MatchResult?, name: String): String? {
        if (match == null) return null
        return runCatching { match.groups[name]?.value }.getOrNull()
            ?: match.groups.getOrNull(1)?.value
            ?: match.value
    }

    private fun parseAmount(raw: String?): Double? {
        if (raw == null) return null
        var cleaned = normalize(raw).replace(Regex("[^0-9,.]"), "")
        if (cleaned.isBlank()) return null
        val hasComma = cleaned.contains(',')
        val hasDot = cleaned.contains('.')
        cleaned = when {
            hasComma && hasDot -> cleaned.replace(".", "").replace(',', '.')
            hasDot && Regex("^\\d{1,3}(\\.\\d{3})+$").matches(cleaned) -> cleaned.replace(".", "")
            hasComma -> cleaned.replace(',', '.')
            else -> cleaned
        }
        return cleaned.toDoubleOrNull()
    }
}
```

- [ ] **Step 3: Write matcher tests**

Create `PushRecurringMatcherTest.kt` with a direct object fixture:

```kotlin
package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PushRecurringMatcherTest {
    @Test
    fun scoresMatchingRuleHigherThanOutOfToleranceRule() {
        val rule = PushRecurringMatchRule(
            ruleId = 1,
            instanceId = 10,
            estimatedDate = "2026.06.10",
            estimatedAmount = 120000.0,
            transactionType = "expense",
            appFilterText = "^OTP$",
            packageName = "hu.otpbank.mobile",
            appLabel = "OTP",
            dateToleranceDays = 5,
            amountTolerancePercent = 20.0,
            amountToleranceMin = 5000.0,
        )
        val event = PushRecurringMatchEvent(
            notificationEventId = 77,
            appLabel = "OTP",
            packageName = "hu.otpbank.mobile",
            date = "2026.06.12",
            amount = 121550.0,
            merchant = "OTP Lakashitel",
            transactionType = "expense",
        )

        val score = PushRecurringMatcher.score(rule, event)

        assertTrue(score.matches)
        assertTrue(score.confidence >= 0.85)
        assertEquals(10, score.instanceId)
    }
}
```

- [ ] **Step 4: Implement matcher**

Create `PushRecurringMatcher.kt`:

```kotlin
package com.exptv2.app.expense

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import kotlin.math.abs

data class PushRecurringMatchRule(
    val ruleId: Int,
    val instanceId: Int,
    val estimatedDate: String,
    val estimatedAmount: Double,
    val transactionType: String,
    val appFilterText: String,
    val packageName: String,
    val appLabel: String,
    val dateToleranceDays: Int,
    val amountTolerancePercent: Double,
    val amountToleranceMin: Double,
)

data class PushRecurringMatchEvent(
    val notificationEventId: Long,
    val appLabel: String,
    val packageName: String,
    val date: String,
    val amount: Double,
    val merchant: String,
    val transactionType: String,
)

data class PushRecurringMatchScore(
    val instanceId: Int,
    val matches: Boolean,
    val confidence: Double,
)

object PushRecurringMatcher {
    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy.MM.dd")

    fun score(rule: PushRecurringMatchRule, event: PushRecurringMatchEvent): PushRecurringMatchScore {
        if (rule.transactionType != event.transactionType) return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        if (rule.packageName.isNotBlank() && rule.packageName != event.packageName) return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        if (rule.appFilterText.isNotBlank() && !Regex(rule.appFilterText, RegexOption.IGNORE_CASE).containsMatchIn(event.appLabel)) {
            return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        }
        val estimated = LocalDate.parse(rule.estimatedDate, dateFormatter)
        val actual = LocalDate.parse(event.date, dateFormatter)
        val days = abs(java.time.temporal.ChronoUnit.DAYS.between(estimated, actual))
        if (days > rule.dateToleranceDays) return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        val allowedAmountDelta = maxOf(rule.estimatedAmount * rule.amountTolerancePercent / 100.0, rule.amountToleranceMin)
        val amountDelta = abs(rule.estimatedAmount - event.amount)
        if (amountDelta > allowedAmountDelta) return PushRecurringMatchScore(rule.instanceId, false, 0.0)
        val dateScore = 1.0 - (days.toDouble() / rule.dateToleranceDays.coerceAtLeast(1).toDouble() * 0.2)
        val amountScore = 1.0 - (amountDelta / allowedAmountDelta * 0.2)
        return PushRecurringMatchScore(rule.instanceId, true, ((dateScore + amountScore) / 2.0).coerceIn(0.0, 1.0))
    }
}
```

- [ ] **Step 5: Run parser and matcher tests**

Run:

```bash
./gradlew :app:testDebugUnitTest --tests "com.exptv2.app.expense.PushRecurringParserTest" --tests "com.exptv2.app.expense.PushRecurringMatcherTest"
```

Expected: PASS.

- [ ] **Step 6: Commit parser/matcher work**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringParser.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringMatcher.kt \
  android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringParserTest.kt \
  android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringMatcherTest.kt
git commit -m "feat: match push events to recurring instances"
```

---

### Task 4: Native Repository And Method Channel Integration

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`
- Test: `test/settings/settings_bridge_test.dart`
- Test: `test/transactions/native_bridge_expense_test.dart`

- [ ] **Step 1: Add Dart bridge tests for native method names**

In `test/transactions/native_bridge_expense_test.dart`, add a test that mocks:

```dart
test('manages recurring rules through native bridge', () async {
  final bridge = NativeBridge(
    methodChannel: channel,
    eventChannel: const EventChannel('test/native_bridge_events'),
  );

  final rules = await bridge.expenseListRecurringRules();
  expect(rules.single.name, 'Lakáshitel');

  final created = await bridge.expenseAddRecurringRule(
    RecurringRuleDraft(
      triggerType: RecurringTriggerType.push,
      transactionType: TransactionType.expense,
      name: 'Lakáshitel',
      estimatedAmount: 120000,
      expectedDayOfMonth: 10,
      categoryId: 6,
      isActive: true,
      appFilterText: '^OTP$',
      packageName: 'hu.otpbank.mobile',
      appLabel: 'OTP',
      sampleText: 'Terheles: 121 550 Ft. Partner: OTP Lakashitel.',
      includeKeyword: 'Terheles',
      amountPattern: r'(?<amount>\d[\d\s.,]*)(?:\s*Ft)',
      amountSelection: '121 550 Ft',
      merchantPattern: r'Partner:\s*(?<merchant>.+?)(?:\.|$)',
      merchantSelection: 'OTP Lakashitel',
      dateToleranceDays: 5,
      amountTolerancePercent: 20,
      amountToleranceMin: 5000,
    ),
  );

  expect(created.triggerType, RecurringTriggerType.push);
  expect(calls.map((call) => call.method), contains('expenseAddRecurringRule'));
});
```

- [ ] **Step 2: Implement method channel cases**

Add cases to `ExpenseMethodChannel.handle`:

```kotlin
"expenseListRecurringRules" -> scope.launchResult(result) { repository.listRecurringRules() }
"expenseAddRecurringRule" -> scope.launchResult(result) { repository.addRecurringRule(call.argumentsMap()) }
"expenseUpdateRecurringRule" -> scope.launchResult(result) { repository.updateRecurringRule(call.argumentsMap()) }
"expenseToggleRecurringRule" -> scope.launchResult(result) { repository.toggleRecurringRule(call.argumentsMap()) }
"expenseDeleteRecurringRule" -> scope.launchResult(result) {
    val id = (call.argumentsMap()["id"] as? Number)?.toInt()
        ?: call.argumentsMap()["id"]?.toString()?.toIntOrNull()
        ?: throw ExpenseValidationException("INVALID_RECURRING_RULE", "Recurring rule id is required")
    repository.deleteRecurringRule(id)
}
```

- [ ] **Step 3: Implement repository CRUD**

In `ExpenseRepository`, add `listRecurringRules`, `addRecurringRule`, `updateRecurringRule`, `toggleRecurringRule`, and `deleteRecurringRule`. Build rows through one helper:

```kotlin
private suspend fun buildRecurringRule(args: Map<*, *>, existing: RecurringRuleEntity?): RecurringRuleEntity {
    val name = args["name"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        ?: existing?.name
        ?: throw ExpenseValidationException("INVALID_RECURRING_RULE_NAME", "Recurring rule name is required")
    val estimatedAmount = doubleArg(args["estimatedAmount"], existing?.estimatedAmount ?: 0.0)
    if (estimatedAmount <= 0.0) throw ExpenseValidationException("INVALID_RECURRING_RULE_AMOUNT", "Estimated amount must be greater than zero")
    val expectedDay = optionalInt(args["expectedDayOfMonth"]) ?: existing?.expectedDayOfMonth
        ?: throw ExpenseValidationException("INVALID_RECURRING_RULE_DAY", "Expected day is required")
    if (expectedDay !in 1..31) throw ExpenseValidationException("INVALID_RECURRING_RULE_DAY", "Expected day must be between 1 and 31")
    val categoryId = optionalInt(args["categoryId"]) ?: existing?.categoryId
        ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category is required")
    val category = categories.byId(categoryId)
        ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
    val triggerType = RecurringTriggerType.normalize(args["triggerType"]?.toString() ?: existing?.triggerType)
    val now = System.currentTimeMillis()
    return RecurringRuleEntity(
        id = existing?.id ?: 0,
        triggerType = triggerType,
        transactionType = normalizeNativeTransactionType(args["transactionType"]?.toString()) ?: existing?.transactionType ?: "expense",
        name = name,
        estimatedAmount = kotlin.math.abs(estimatedAmount),
        expectedDayOfMonth = expectedDay,
        categoryId = category.transactionCategoryID,
        categoryName = category.name,
        categoryColor = category.backgroundColor ?: colorForSlot(category.colorSlot ?: 4),
        categoryIconSlot = category.iconSlot ?: 0,
        isActive = boolArg(args["isActive"], existing?.isActive ?: true),
        appFilterText = args["appFilterText"]?.toString() ?: existing?.appFilterText ?: "",
        packageName = args["packageName"]?.toString() ?: existing?.packageName ?: "",
        appLabel = args["appLabel"]?.toString() ?: existing?.appLabel ?: "",
        sampleText = args["sampleText"]?.toString() ?: existing?.sampleText ?: "",
        includeKeyword = args["includeKeyword"]?.toString() ?: existing?.includeKeyword ?: "",
        amountPattern = args["amountPattern"]?.toString() ?: existing?.amountPattern ?: "",
        amountSelection = args["amountSelection"]?.toString() ?: existing?.amountSelection ?: "",
        merchantPattern = args["merchantPattern"]?.toString() ?: existing?.merchantPattern ?: "",
        merchantSelection = args["merchantSelection"]?.toString() ?: existing?.merchantSelection ?: "",
        dateToleranceDays = optionalInt(args["dateToleranceDays"]) ?: existing?.dateToleranceDays ?: 5,
        amountTolerancePercent = doubleArg(args["amountTolerancePercent"], existing?.amountTolerancePercent ?: 20.0),
        amountToleranceMin = doubleArg(args["amountToleranceMin"], existing?.amountToleranceMin ?: 5000.0),
        createdAt = existing?.createdAt ?: now,
        updatedAt = now,
    )
}
```

- [ ] **Step 4: Hook notification events to push matching**

In `NotificationEventRepository.insertDraft`, after saving the entity, call:

```kotlin
com.exptv2.app.expense.ExpenseRepository(appContext).processNotificationEventForRecurring(saved)
```

Add `processNotificationEventForRecurring(event: NotificationEventEntity)` to `ExpenseRepository`. It should build a combined text from title/text/bigText/subText, parse each active push rule, score pending current-period instances, and activate based on Settings policy.

- [ ] **Step 5: Preserve transaction activation values**

When activating a push instance, insert `ExpenseTransactionEntity` with:

```kotlin
merchant = parsed.merchant,
amount = if (rule.transactionType == "income") abs(parsed.amount) else -abs(parsed.amount),
userAssignedName = rule.name,
transactionCategoryID = rule.categoryId,
recurringRuleId = rule.id,
recurringInstanceId = instance.id,
```

Use notification timestamp for date/time formatting.

- [ ] **Step 6: Run bridge tests**

Run:

```bash
flutter test test/transactions/native_bridge_expense_test.dart test/settings/settings_bridge_test.dart
```

Expected: PASS in a Flutter-capable environment. If local Termux Dart fails with TLS alignment, record the failure text and rely on CI.

- [ ] **Step 7: Commit native integration**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt \
  android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt \
  android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt \
  test/transactions/native_bridge_expense_test.dart \
  test/settings/settings_bridge_test.dart
git commit -m "feat: activate recurring rules from push events"
```

---

### Task 5: Dart Models, Bridge, Repository, And Store

**Files:**
- Create: `lib/features/transactions/models/recurring_rule.dart`
- Create: `lib/features/transactions/models/recurring_rule_instance.dart`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/models/transaction_record.dart`
- Modify: `lib/features/transactions/models/transaction_log_entry.dart`
- Test: `test/transactions/recurring_rule_models_test.dart`
- Test: `test/transactions/transaction_store_test.dart`

- [ ] **Step 1: Write Dart model tests**

Create `test/transactions/recurring_rule_models_test.dart`:

```dart
import 'package:exptv2/features/transactions/models/recurring_rule.dart';
import 'package:exptv2/features/transactions/models/recurring_rule_instance.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses push recurring rule from native map', () {
    final rule = RecurringRule.fromMap(<String, Object?>{
      'id': 9,
      'triggerType': 'push',
      'transactionType': 'expense',
      'name': 'Lakáshitel',
      'estimatedAmount': 120000,
      'expectedDayOfMonth': 10,
      'categoryId': 6,
      'categoryName': 'Hitel',
      'categoryColor': '#64748b',
      'categoryIconSlot': 2,
      'isActive': true,
      'appFilterText': r'^OTP$',
      'packageName': 'hu.otpbank.mobile',
      'appLabel': 'OTP',
      'sampleText': 'Terhelés 121 550 Ft Partner OTP Lakáshitel',
      'includeKeyword': 'Terhelés',
      'amountPattern': r'(?<amount>\d[\d\s.,]*)(?:\s*Ft)',
      'amountSelection': '121 550 Ft',
      'merchantPattern': r'Partner\s+(?<merchant>.+)',
      'merchantSelection': 'OTP Lakáshitel',
      'dateToleranceDays': 5,
      'amountTolerancePercent': 20,
      'amountToleranceMin': 5000,
      'createdAt': 0,
      'updatedAt': 0,
    });

    expect(rule.triggerType, RecurringTriggerType.push);
    expect(rule.transactionType, TransactionType.expense);
    expect(rule.estimatedAmount, 120000);
  });

  test('parses pending recurring rule instance', () {
    final instance = RecurringRuleInstance.fromMap(<String, Object?>{
      'id': 91,
      'ruleId': 9,
      'periodKey': '2026-06',
      'status': 'pending',
      'estimatedDate': '2026.06.10',
      'estimatedAmount': 120000,
      'triggerTypeSnapshot': 'push',
      'transactionTypeSnapshot': 'expense',
      'nameSnapshot': 'Lakáshitel',
      'categoryIdSnapshot': 6,
      'categoryNameSnapshot': 'Hitel',
      'categoryColorSnapshot': '#64748b',
      'categoryIconSlotSnapshot': 2,
      'activatedTransactionId': null,
      'activatedAt': null,
      'matchedNotificationEventId': null,
      'matchConfidence': null,
      'createdAt': 0,
      'updatedAt': 0,
    });

    expect(instance.isPending, isTrue);
    expect(instance.displayAmount, '-120 000 Ft');
  });
}
```

- [ ] **Step 2: Implement Dart models**

Create `recurring_rule.dart` with `RecurringTriggerType`, `RecurringRule`, and `RecurringRuleDraft`. Create `recurring_rule_instance.dart` with `RecurringRuleInstanceStatus` and `RecurringRuleInstance`. Keep parsing helpers local to each file.

- [ ] **Step 3: Update NativeBridge**

Add methods:

```dart
Future<List<RecurringRule>> expenseListRecurringRules()
Future<RecurringRule> expenseAddRecurringRule(RecurringRuleDraft draft)
Future<RecurringRule> expenseUpdateRecurringRule(int id, RecurringRuleDraft draft)
Future<RecurringRule> expenseToggleRecurringRule(int id, bool isActive)
Future<bool> expenseDeleteRecurringRule(int id)
```

Parse `recurringRuleInstances` from bootstrap when native starts returning it. During transition, also accept old `recurringGhostTransactions` key if present.

- [ ] **Step 4: Update repository contract**

In `TransactionRepositoryContract`, add recurring rule CRUD and change bootstrap from `recurringGhostTransactions` to `recurringRuleInstances`. Keep a compatibility getter if tests still use the old field name during the same task.

- [ ] **Step 5: Update TransactionRecord**

Add fields:

```dart
final int? recurringRuleId;
final int? recurringInstanceId;
```

Update `isRecurringGenerated`:

```dart
bool get isRecurringGenerated =>
    (recurringInstanceId != null && recurringInstanceId! > 0) ||
    (recurringRuleId != null && recurringRuleId! > 0) ||
    (recurringTransactionId != null && recurringTransactionId! > 0);
```

- [ ] **Step 6: Update TransactionStore ghost state**

Replace internal `List<RecurringGhostRecord>` storage with `List<RecurringRuleInstance>`. Keep public names only where changing all callers in one step would create noise. Pending instances must not contribute to `_totalSummary`, `_periodTotal`, or any balance calculation because those already fold only real `_transactions`.

- [ ] **Step 7: Run Dart model/store tests**

Run:

```bash
flutter test test/transactions/recurring_rule_models_test.dart test/transactions/transaction_store_test.dart
```

Expected: PASS in Flutter-capable environment. If local Dart fails in Termux, record the failure and continue only after CI is configured to run it.

- [ ] **Step 8: Commit Dart data layer**

```bash
git add lib/features/transactions/models/recurring_rule.dart \
  lib/features/transactions/models/recurring_rule_instance.dart \
  lib/services/native_bridge.dart \
  lib/features/transactions/data/transaction_repository.dart \
  lib/features/transactions/state/transaction_store.dart \
  lib/features/transactions/models/transaction_record.dart \
  lib/features/transactions/models/transaction_log_entry.dart \
  test/transactions/recurring_rule_models_test.dart \
  test/transactions/transaction_store_test.dart
git commit -m "feat: expose recurring rules to Flutter"
```

---

### Task 6: Recurring Manager Sheet And FAB Long Press

**Files:**
- Create: `lib/features/transactions/widgets/recurring_manager/recurring_manager_sheet.dart`
- Create: `lib/features/transactions/widgets/recurring_manager/recurring_rule_editor.dart`
- Create: `lib/features/transactions/widgets/recurring_manager/recurring_rule_list.dart`
- Create: `lib/features/transactions/widgets/recurring_manager/push_rule_training_panel.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/settings/state/settings_store.dart`
- Modify: `lib/features/settings/data/settings_repository.dart`
- Delete: `lib/features/settings/widgets/options/recurring_options_panel.dart` after imports are removed.
- Test: `test/transactions/recurring_manager_sheet_test.dart`
- Test: `test/settings/settings_page_test.dart`

- [ ] **Step 1: Write manager widget tests**

Create `recurring_manager_sheet_test.dart` with tests that pump `RecurringManagerSheet` using a fake store/repository and assert:

```dart
expect(find.byKey(const ValueKey('recurring-manager-sheet')), findsOneWidget);
expect(find.byKey(const ValueKey('recurring-trigger-date')), findsOneWidget);
expect(find.byKey(const ValueKey('recurring-trigger-push')), findsOneWidget);
expect(find.byKey(const ValueKey('recurring-type-expense')), findsOneWidget);
expect(find.byKey(const ValueKey('recurring-type-income')), findsOneWidget);
```

Add a second test that taps `recurring-trigger-push` and expects:

```dart
expect(find.byKey(const ValueKey('push-rule-training-panel')), findsOneWidget);
expect(find.byKey(const ValueKey('push-rule-sample-text')), findsOneWidget);
expect(find.byKey(const ValueKey('push-rule-amount-pattern')), findsOneWidget);
expect(find.byKey(const ValueKey('push-rule-merchant-pattern')), findsOneWidget);
```

- [ ] **Step 2: Implement sheet shell**

Create `RecurringManagerSheet` as a slide-up card with one scroll view. Use keys from Step 1. Keep visual style aligned with `AddTransactionSheet`: white surface, rounded top corners, form sections, and full-width save button.

- [ ] **Step 3: Implement editor component**

`RecurringRuleEditor` receives selected trigger/type, draft values, categories, and callbacks. It renders shared fields and embeds `PushRuleTrainingPanel` only when trigger is push.

- [ ] **Step 4: Implement rule list**

`RecurringRuleList` renders grouped sections in this order:

1. Időzített fix kiadások
2. Push fix kiadások
3. Időzített fix bevételek
4. Push fix bevételek

Each item has keys:

```dart
ValueKey('recurring-rule-item-${rule.id}')
ValueKey('recurring-rule-toggle-${rule.id}')
ValueKey('recurring-rule-delete-${rule.id}')
```

- [ ] **Step 5: Wire FAB long press**

In `ExptShell`, replace category-editor long-press behavior with opening the recurring manager. Add a recurring slot to `_ShellSheetHost`, matching the existing transaction/category/budget sheet slot pattern.

Expected behavior:

- `ExptFab.onPressed`: open add transaction.
- `ExptFab.onLongPress`: open recurring manager.

- [ ] **Step 6: Remove recurring Settings panel**

In `settings_page.dart`, remove `_SettingsMenu.recurring`, its tile, title mapping, and panel mapping. In `SettingsStore` and `SettingsRepository`, remove recurring CRUD methods after the manager uses `TransactionStore`/`TransactionRepository` for recurring rules.

- [ ] **Step 7: Add global match setting in Settings**

Add a compact option under existing automation/parser settings:

```dart
enum PushRecurringMatchMode { askOnMultipleMatches, automaticBestMatch }
```

Persist through settings native map using key `pushRecurringMatchMode`. Default is `askOnMultipleMatches`.

- [ ] **Step 8: Run widget/settings tests**

Run:

```bash
flutter test test/transactions/recurring_manager_sheet_test.dart test/settings/settings_page_test.dart test/settings/settings_store_test.dart
```

Expected: PASS in Flutter-capable environment.

- [ ] **Step 9: Commit manager UI**

```bash
git add lib/features/transactions/widgets/recurring_manager \
  lib/features/shell/expt_shell.dart \
  lib/features/settings/settings_page.dart \
  lib/features/settings/state/settings_store.dart \
  lib/features/settings/data/settings_repository.dart \
  lib/features/settings/widgets/options/recurring_options_panel.dart \
  test/transactions/recurring_manager_sheet_test.dart \
  test/settings/settings_page_test.dart \
  test/settings/settings_store_test.dart
git commit -m "feat: move recurring manager to fab long press"
```

---

### Task 7: Category Creation Moves To Category Menu Header

**Files:**
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_editor_sheet.dart` if callback shape needs alignment.
- Test: `test/transactions/category_menu_test.dart`
- Test: existing shell/FAB tests.

- [ ] **Step 1: Write category menu test**

In `category_menu_test.dart`, add a test that opens the category menu and expects a plus button:

```dart
expect(find.byKey(const ValueKey('category-menu-add-category')), findsOneWidget);
await tester.tap(find.byKey(const ValueKey('category-menu-add-category')));
await tester.pumpAndSettle();
expect(find.byKey(const ValueKey('category-editor-sheet')), findsOneWidget);
```

- [ ] **Step 2: Add header plus callback**

Add `VoidCallback? onAddCategory` to `CategoryMenuPanel` and render an `IconButton` in the header:

```dart
IconButton(
  key: const ValueKey('category-menu-add-category'),
  tooltip: 'Új kategória',
  onPressed: onAddCategory,
  icon: const Icon(Icons.add),
)
```

- [ ] **Step 3: Route overlay callback**

In `CategoryMenuOverlay`, pass `onAddCategory` through to the panel and wire it to the existing category editor creation flow used by the old FAB long-press.

- [ ] **Step 4: Remove FAB category creation expectations**

Update shell/FAB tests so long-press expects `recurring-manager-sheet`, not `category-editor-sheet`.

- [ ] **Step 5: Run focused tests**

Run:

```bash
flutter test test/transactions/category_menu_test.dart test/transactions/transaction_widgets_test.dart
```

Expected: PASS in Flutter-capable environment.

- [ ] **Step 6: Commit category relocation**

```bash
git add lib/features/transactions/widgets/category_menu/category_menu_panel.dart \
  lib/features/transactions/widgets/category_menu/category_menu_overlay.dart \
  lib/features/transactions/widgets/category_menu/category_editor_sheet.dart \
  test/transactions/category_menu_test.dart \
  test/transactions/transaction_widgets_test.dart
git commit -m "feat: move category creation into category menu"
```

---

### Task 8: Ghost Rendering, FastInfo Compatibility, And Final Verification

**Files:**
- Modify: `lib/features/transactions/widgets/recurring_ghost_log_box.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/state/fast_info_metrics_resolver.dart`
- Modify: `lib/features/transactions/data/fast_info_period_aggregates.dart`
- Test: `test/transactions/recurring_ghost_log_test.dart`
- Test: `test/transactions/fast_info_metrics_resolver_test.dart`
- Test: `test/transactions/fast_info_period_aggregates_test.dart`

- [ ] **Step 1: Update recurring ghost log tests**

In `recurring_ghost_log_test.dart`, change fixtures to `RecurringRuleInstance.fromMap` and assert badges for trigger type:

```dart
expect(find.text('Push fix'), findsOneWidget);
expect(find.text('Várható'), findsOneWidget);
```

- [ ] **Step 2: Update ghost log box**

Change `RecurringGhostLogBox` input from old `RecurringGhostRecord` to `RecurringRuleInstance`. Render:

- name snapshot
- estimated amount
- estimated date
- trigger badge: `Időzített fix` or `Push fix`
- status badge: `Várható`, `Aktiválva`, or `Lejárt`

- [ ] **Step 3: Update FastInfo recurring exclusions**

Where code checks `record.isRecurringGenerated`, keep the property but ensure it reads new fields. Where code reads pending recurring ghosts, switch to `RecurringRuleInstance` fields:

```dart
row.record.status == RecurringRuleInstanceStatus.pending
row.record.estimatedDate
row.record.estimatedAmount
```

- [ ] **Step 4: Run focused FastInfo/ghost tests**

Run:

```bash
flutter test test/transactions/recurring_ghost_log_test.dart test/transactions/fast_info_metrics_resolver_test.dart test/transactions/fast_info_period_aggregates_test.dart
```

Expected: PASS in Flutter-capable environment.

- [ ] **Step 5: Run analyzer and full test suite**

Run:

```bash
flutter analyze
flutter test
```

Expected: PASS in Flutter-capable environment. If local Termux Flutter fails with Bionic TLS alignment, capture the exact error and rely on GitHub Actions for authoritative verification.

- [ ] **Step 6: Run native tests**

Run:

```bash
./gradlew :app:testDebugUnitTest
```

Expected: PASS.

- [ ] **Step 7: Commit final rendering/verification updates**

```bash
git add lib/features/transactions/widgets/recurring_ghost_log_box.dart \
  lib/features/transactions/widgets/transaction_log_list.dart \
  lib/features/transactions/state/fast_info_metrics_resolver.dart \
  lib/features/transactions/data/fast_info_period_aggregates.dart \
  test/transactions/recurring_ghost_log_test.dart \
  test/transactions/fast_info_metrics_resolver_test.dart \
  test/transactions/fast_info_period_aggregates_test.dart
git commit -m "feat: render recurring rule instances"
```

---

## Final Manual Acceptance Checklist

Run these checks on a device or emulator after automated tests pass:

- [ ] FAB tap opens add transaction.
- [ ] FAB long press opens recurring manager.
- [ ] Settings no longer contains the old recurring manager.
- [ ] Category menu header plus opens new category creation.
- [ ] Date-triggered fixed expense creates a current-month ghost.
- [ ] Date-triggered fixed expense activates through the alarm/resume path.
- [ ] Push-triggered fixed expense creates a current-month ghost.
- [ ] Matching push activates the push ghost into a real transaction.
- [ ] Activated push transaction uses push amount/date/raw merchant.
- [ ] Activated push transaction shows user-controlled recurring name until reset.
- [ ] Pending ghosts do not change balance or income/expense totals.
- [ ] Previous-month pending ghosts are not visible.
- [ ] FastInfo trend/average cards exclude activated recurring-generated transactions.
