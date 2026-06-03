# Notification System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete domain notifications so transaction creation, recurring ghost activation, and limit thresholds create internal cards and Android phone/lockscreen notifications.

**Architecture:** Add a native Kotlin notification layer under `android/app/src/main/kotlin/com/exptv2/app/expense`. The repository will call pure factories/evaluators and a delivery emitter after inserting transactions or activating recurring ghosts, keeping notification behavior available in foreground and background flows. Dart changes are limited to parsing/rendering the new internal card types.

**Tech Stack:** Flutter/Dart, Android Kotlin, Room, AndroidX NotificationCompat, JUnit4, Flutter widget/unit tests.

---

## File Structure

Create:

- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactory.kt` - pure factory for all internal notification card rows.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluator.kt` - pure threshold math and period-key/date-window helpers.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationEmitter.kt` - inserts cards and sends Android notifications.
- `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactoryTest.kt` - native factory tests.
- `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluatorTest.kt` - native limit threshold tests.

Modify:

- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt` - wire notification emission after transaction insert and recurring ghost activation.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt` - add sum query for affected limit windows.
- `android/app/src/main/kotlin/com/exptv2/app/expense/CategoryLimitDao.kt` - add affected active limit query.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactory.kt` - either delegate to the new factory or leave as compatibility wrapper.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationHelper.kt` - remove direct notification construction or convert to wrapper around `ExpenseNotificationEmitter` if still referenced.
- `lib/features/notifications/models/expense_notification_card.dart` - parse new card types.
- `lib/features/notifications/widgets/notification_log_box.dart` - display labels for new types.
- `test/notifications/expense_notification_card_test.dart` - cover new types.
- `test/notifications/notification_widgets_test.dart` - cover display labels.
- `test/transactions/native_bridge_expense_test.dart` - cover bridge parsing for new card payloads.

Do not modify the schema for `notification_cards`; the current columns are enough for these alerts.

---

### Task 1: Dart Notification Type Parsing

**Files:**
- Modify: `lib/features/notifications/models/expense_notification_card.dart`
- Modify: `lib/features/notifications/widgets/notification_log_box.dart`
- Test: `test/notifications/expense_notification_card_test.dart`
- Test: `test/notifications/notification_widgets_test.dart`

- [ ] **Step 1: Write failing model tests for new native card types**

Append this test to `test/notifications/expense_notification_card_test.dart`:

```dart
test('parses transaction and limit notification card types', () {
  final transaction = ExpenseNotificationCard.fromMap({
    'id': 8,
    'type': 'transaction_created',
    'title': 'Új tranzakció',
    'message': 'Tesco - 4200 Ft',
    'timestamp': 1778803200000,
    'isRead': false,
    'isActive': true,
    'priority': 'normal',
  });
  final limit75 = ExpenseNotificationCard.fromMap({
    'id': 9,
    'type': 'limit_75',
    'title': 'Limit 75%',
    'message': '12000 Ft maradt a limitből',
    'timestamp': 1778803200000,
    'isRead': false,
    'isActive': true,
    'priority': 'warning',
  });
  final limit100 = ExpenseNotificationCard.fromMap({
    'id': 10,
    'type': 'limit_100',
    'title': 'Limit elérve',
    'message': '3000 Ft-tal túllépted a limitet',
    'timestamp': 1778803200000,
    'isRead': false,
    'isActive': true,
    'priority': 'critical',
  });

  expect(transaction.type, ExpenseNotificationType.transactionCreated);
  expect(limit75.type, ExpenseNotificationType.limit75);
  expect(limit100.type, ExpenseNotificationType.limit100);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/notifications/expense_notification_card_test.dart'
```

Expected: fail because `ExpenseNotificationType.transactionCreated`, `limit75`, and `limit100` do not exist.

- [ ] **Step 3: Add Dart enum values**

Modify `ExpenseNotificationType` in `lib/features/notifications/models/expense_notification_card.dart`:

```dart
enum ExpenseNotificationType {
  recurringTransactionAlert('recurring_transaction_alert'),
  transactionCreated('transaction_created'),
  limit75('limit_75'),
  limit100('limit_100'),
  budgetAlert('budget_alert'),
  spendingLimit('spending_limit'),
  monthlyBudgetAlert('monthly_budget_alert'),
  system('system');
```

Keep the existing `fromNative` implementation unchanged so unknown types still fall back to `system`.

- [ ] **Step 4: Add widget labels**

Modify `_typeLabel` in `lib/features/notifications/widgets/notification_log_box.dart`:

```dart
String _typeLabel(ExpenseNotificationType type) {
  return switch (type) {
    ExpenseNotificationType.recurringTransactionAlert => 'Ismétlődő tranzakció',
    ExpenseNotificationType.transactionCreated => 'Új tranzakció',
    ExpenseNotificationType.limit75 => 'Limit 75%',
    ExpenseNotificationType.limit100 => 'Limit elérve',
    ExpenseNotificationType.budgetAlert => 'Limit alert',
    ExpenseNotificationType.spendingLimit => 'Költési limit',
    ExpenseNotificationType.monthlyBudgetAlert => 'Havi limit alert',
    ExpenseNotificationType.system => 'Értesítés',
  };
}
```

- [ ] **Step 5: Add widget label test**

Append to `test/notifications/notification_widgets_test.dart`:

```dart
testWidgets('notification logbox renders transaction and limit labels', (
  tester,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Column(
        children: [
          NotificationLogBox(
            card: notificationCard(id: 20, type: 'transaction_created'),
            onMarkRead: (_) {},
            onDelete: (_) {},
          ),
          NotificationLogBox(
            card: notificationCard(id: 21, type: 'limit_75'),
            onMarkRead: (_) {},
            onDelete: (_) {},
          ),
          NotificationLogBox(
            card: notificationCard(id: 22, type: 'limit_100'),
            onMarkRead: (_) {},
            onDelete: (_) {},
          ),
        ],
      ),
    ),
  );

  expect(find.text('Új tranzakció'), findsOneWidget);
  expect(find.text('Limit 75%'), findsOneWidget);
  expect(find.text('Limit elérve'), findsOneWidget);
});

ExpenseNotificationCard notificationCard({required int id, required String type}) {
  return ExpenseNotificationCard.fromMap({
    'id': id,
    'type': type,
    'title': 'Teszt',
    'message': 'Teszt üzenet',
    'timestamp': DateTime(2026, 5, 15, 8).millisecondsSinceEpoch,
    'isRead': false,
    'isActive': true,
    'priority': 'normal',
  });
}
```

If `notification_widgets_test.dart` already has a helper named `card`, use the new helper name `notificationCard` to avoid collision.

- [ ] **Step 6: Verify Dart notification tests pass**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/notifications/expense_notification_card_test.dart test/notifications/notification_widgets_test.dart'
```

Expected: all tests pass.

- [ ] **Step 7: Commit Dart type support**

```bash
git add lib/features/notifications/models/expense_notification_card.dart lib/features/notifications/widgets/notification_log_box.dart test/notifications/expense_notification_card_test.dart test/notifications/notification_widgets_test.dart
git commit -m "Add notification card types"
```

---

### Task 2: Native Card Factory

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactory.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactory.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactoryTest.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactoryTest.kt`

- [ ] **Step 1: Write failing native factory tests**

Create `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactoryTest.kt`:

```kotlin
package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ExpenseNotificationCardFactoryTest {
    private val now = 1778803200000L
    private val category = TransactionCategoryEntity(
        transactionCategoryID = 6,
        name = "Élelmiszer",
        type = "kiadás",
        colorSlot = 4,
        iconSlot = 2,
        backgroundColor = "#dc2626",
        icon = null,
        notification = null,
        hasLimit = false,
        limitAmount = 0.0,
        alertActive = false,
        isCustomIcon = true,
        originalIcon = null,
    )
    private val transaction = ExpenseTransactionEntity(
        id = 26051501,
        date = "2026.05.15",
        time = "09:12",
        latitude = null,
        longitude = null,
        address = "Unknown location",
        merchant = "Tesco",
        amount = -4200.0,
        userAssignedName = null,
        transactionCategoryID = 6,
    )

    @Test
    fun buildsTransactionCreatedCard() {
        val card = ExpenseNotificationCardFactory.transactionCreated(
            transaction = transaction,
            category = category,
            now = now,
        )

        assertEquals("transaction_created", card.type)
        assertEquals("Új tranzakció", card.title)
        assertTrue(card.message.contains("Tesco"))
        assertTrue(card.message.contains("4200"))
        assertEquals("normal", card.priority)
        assertEquals(6, card.categoryId)
        assertEquals("Élelmiszer", card.categoryName)
        assertEquals(26051501, card.transactionId)
        assertEquals(4200.0, card.amount!!, 0.0)
        assertFalse(card.isRead)
        assertTrue(card.isActive)
    }

    @Test
    fun buildsLimitCardsWithRemainingAndOverageText() {
        val remaining = ExpenseLimitAlert(
            type = "limit_75",
            title = "Limit 75%",
            targetLabel = "Élelmiszer",
            category = category,
            transaction = transaction,
            limitAmount = 10000.0,
            spentAmount = 7600.0,
            remainingAmount = 2400.0,
            usageRatio = 0.76,
        )
        val over = remaining.copy(
            type = "limit_100",
            title = "Limit elérve",
            spentAmount = 11000.0,
            remainingAmount = -1000.0,
            usageRatio = 1.1,
        )

        val remainingCard = ExpenseNotificationCardFactory.limitAlert(remaining, now)
        val overCard = ExpenseNotificationCardFactory.limitAlert(over, now)

        assertEquals("limit_75", remainingCard.type)
        assertTrue(remainingCard.message.contains("2400 Ft maradt"))
        assertEquals("warning", remainingCard.priority)
        assertEquals("limit_100", overCard.type)
        assertTrue(overCard.message.contains("1000 Ft-tal túllépted"))
        assertEquals("critical", overCard.priority)
    }
}
```

- [ ] **Step 2: Run native tests to verify failure**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.ExpenseNotificationCardFactoryTest'
```

Expected: fail because `ExpenseNotificationCardFactory` and `ExpenseLimitAlert` do not exist.

- [ ] **Step 3: Create the factory and alert data class**

Create `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactory.kt`:

```kotlin
package com.exptv2.app.expense

import java.util.Calendar
import kotlin.math.abs
import kotlin.math.roundToLong

data class ExpenseLimitAlert(
    val type: String,
    val title: String,
    val targetLabel: String,
    val category: TransactionCategoryEntity?,
    val transaction: ExpenseTransactionEntity,
    val limitAmount: Double,
    val spentAmount: Double,
    val remainingAmount: Double,
    val usageRatio: Double,
)

object ExpenseNotificationCardFactory {
    fun transactionCreated(
        transaction: ExpenseTransactionEntity,
        category: TransactionCategoryEntity,
        now: Long,
    ): NotificationCardEntity {
        val amount = abs(transaction.amount)
        val displayName = transaction.userAssignedName?.takeIf { it.isNotBlank() } ?: transaction.merchant
        val typeLabel = if (transaction.amount >= 0) "bevétel" else "kiadás"
        return NotificationCardEntity(
            type = "transaction_created",
            title = "Új tranzakció",
            message = "$displayName: ${formatHuf(amount)} Ft $typeLabel rögzítve.",
            timestamp = now,
            isRead = false,
            isActive = true,
            priority = "normal",
            categoryId = category.transactionCategoryID,
            categoryName = category.name,
            categoryColor = category.backgroundColor ?: CategoryColorSlotManager.colorForSlot(category.colorSlot),
            categoryIconSlot = category.iconSlot ?: 0,
            recurringTransactionId = null,
            transactionId = transaction.id,
            amount = amount,
            triggerDate = transaction.date,
            nextDueDate = null,
            createdAt = now,
            updatedAt = now,
        )
    }

    fun recurringActivated(
        recurring: RecurringTransactionEntity,
        ghost: RecurringGhostTransactionEntity,
        transaction: ExpenseTransactionEntity,
        now: Long,
    ): NotificationCardEntity {
        return NotificationCardEntity(
            type = "recurring_transaction_alert",
            title = "Ismétlődő tranzakció aktiválva",
            message = "${recurring.name} teljes értékű tranzakcióként rögzítve.",
            timestamp = now,
            isRead = false,
            isActive = true,
            priority = "info",
            categoryId = ghost.categoryId,
            categoryName = ghost.categoryName,
            categoryColor = ghost.categoryColor,
            categoryIconSlot = ghost.categoryIconSlot,
            recurringTransactionId = recurring.id,
            transactionId = transaction.id,
            amount = abs(transaction.amount),
            triggerDate = ghost.date,
            nextDueDate = nextDueDate(ghost.periodKey, recurring.dayOfMonth),
            createdAt = now,
            updatedAt = now,
        )
    }

    fun limitAlert(alert: ExpenseLimitAlert, now: Long): NotificationCardEntity {
        val category = alert.category
        val message = when {
            alert.remainingAmount > 0.0 ->
                "${alert.targetLabel}: ${formatHuf(alert.remainingAmount)} Ft maradt a limitből."
            alert.remainingAmount == 0.0 ->
                "${alert.targetLabel}: Elérted a limitet, 0 Ft maradt."
            else ->
                "${alert.targetLabel}: ${formatHuf(abs(alert.remainingAmount))} Ft-tal túllépted a limitet."
        }
        return NotificationCardEntity(
            type = alert.type,
            title = alert.title,
            message = message,
            timestamp = now,
            isRead = false,
            isActive = true,
            priority = if (alert.type == "limit_100") "critical" else "warning",
            categoryId = category?.transactionCategoryID ?: alert.transaction.transactionCategoryID,
            categoryName = category?.name ?: alert.targetLabel,
            categoryColor = category?.backgroundColor ?: category?.colorSlot?.let { CategoryColorSlotManager.colorForSlot(it) },
            categoryIconSlot = category?.iconSlot ?: 0,
            recurringTransactionId = null,
            transactionId = alert.transaction.id,
            amount = abs(alert.transaction.amount),
            triggerDate = alert.transaction.date,
            nextDueDate = null,
            createdAt = now,
            updatedAt = now,
        )
    }

    private fun nextDueDate(periodKey: String, dayOfMonth: Int): String {
        val parts = periodKey.split("-")
        val year = parts.getOrNull(0)?.toIntOrNull() ?: return ""
        val month = parts.getOrNull(1)?.toIntOrNull() ?: return ""
        val calendar = Calendar.getInstance().apply {
            clear()
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month)
            set(Calendar.DAY_OF_MONTH, 1)
        }
        val maxDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        calendar.set(Calendar.DAY_OF_MONTH, dayOfMonth.coerceIn(1, maxDay))
        return "%04d.%02d.%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }

    private fun formatHuf(value: Double): Long = abs(value).roundToLong()
}
```

- [ ] **Step 4: Convert recurring factory to wrapper**

Replace `RecurringNotificationCardFactory.activationCard(...)` body in `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactory.kt` with:

```kotlin
object RecurringNotificationCardFactory {
    fun activationCard(
        recurring: RecurringTransactionEntity,
        ghost: RecurringGhostTransactionEntity,
        transaction: ExpenseTransactionEntity,
        now: Long,
    ): NotificationCardEntity {
        return ExpenseNotificationCardFactory.recurringActivated(
            recurring = recurring,
            ghost = ghost,
            transaction = transaction,
            now = now,
        )
    }
}
```

Remove the private `nextDueDate` function and unused `java.util.Calendar` import from `RecurringNotificationCardFactory.kt`.

- [ ] **Step 5: Verify native factory tests pass**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.ExpenseNotificationCardFactoryTest' --tests 'com.exptv2.app.expense.RecurringNotificationCardFactoryTest'
```

Expected: both test classes pass.

- [ ] **Step 6: Commit native card factory**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactory.kt android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationCardFactory.kt android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactoryTest.kt
git commit -m "Add expense notification card factory"
```

---

### Task 3: Native Limit Threshold Evaluator

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluator.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluatorTest.kt`

- [ ] **Step 1: Write failing evaluator tests**

Create `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluatorTest.kt`:

```kotlin
package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ExpenseLimitNotificationEvaluatorTest {
    @Test
    fun computesPeriodKeysAndDateRangesFromTransactionDate() {
        val periods = ExpenseLimitNotificationEvaluator.periodsFor("2026.05.15")

        assertEquals("2026-05", periods.monthKey)
        assertEquals("2026", periods.yearKey)
        assertEquals("2026.05.01", periods.monthStart)
        assertEquals("2026.05.31", periods.monthEnd)
        assertEquals("2026.01.01", periods.yearStart)
        assertEquals("2026.12.31", periods.yearEnd)
    }

    @Test
    fun emitsNoAlertBelow75Percent() {
        val limit = limit(limitAmount = 10000.0)
        val result = ExpenseLimitNotificationEvaluator.evaluate(
            limit = limit,
            targetLabel = "Élelmiszer",
            category = null,
            transaction = transaction(),
            spentAmount = 7400.0,
        )

        assertNull(result)
    }

    @Test
    fun emits75AlertWithRemainingAmount() {
        val result = ExpenseLimitNotificationEvaluator.evaluate(
            limit = limit(limitAmount = 10000.0),
            targetLabel = "Élelmiszer",
            category = null,
            transaction = transaction(),
            spentAmount = 7600.0,
        )

        requireNotNull(result)
        assertEquals("limit_75", result.type)
        assertEquals("Limit 75%", result.title)
        assertEquals(2400.0, result.remainingAmount, 0.0)
        assertEquals(0.76, result.usageRatio, 0.001)
    }

    @Test
    fun emits100AlertWithOverageAmount() {
        val result = ExpenseLimitNotificationEvaluator.evaluate(
            limit = limit(limitAmount = 10000.0),
            targetLabel = "Élelmiszer",
            category = null,
            transaction = transaction(),
            spentAmount = 11250.0,
        )

        requireNotNull(result)
        assertEquals("limit_100", result.type)
        assertEquals("Limit elérve", result.title)
        assertEquals(-1250.0, result.remainingAmount, 0.0)
        assertEquals(1.125, result.usageRatio, 0.001)
    }

    private fun limit(limitAmount: Double) = CategoryLimitEntity(
        id = 4,
        targetType = "category",
        targetId = 6,
        transactionType = "expense",
        window = "monthly",
        periodKey = "2026-05",
        hasLimit = true,
        limitAmount = limitAmount,
        alertActive = true,
        createdAt = 1,
        updatedAt = 1,
    )

    private fun transaction() = ExpenseTransactionEntity(
        id = 26051501,
        date = "2026.05.15",
        time = "09:12",
        latitude = null,
        longitude = null,
        address = null,
        merchant = "Tesco",
        amount = -4200.0,
        userAssignedName = null,
        transactionCategoryID = 6,
    )
}
```

- [ ] **Step 2: Run evaluator tests to verify failure**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.ExpenseLimitNotificationEvaluatorTest'
```

Expected: fail because `ExpenseLimitNotificationEvaluator` does not exist.

- [ ] **Step 3: Implement pure evaluator**

Create `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluator.kt`:

```kotlin
package com.exptv2.app.expense

import java.util.Calendar
import kotlin.math.abs

data class ExpenseLimitPeriods(
    val monthKey: String,
    val yearKey: String,
    val monthStart: String,
    val monthEnd: String,
    val yearStart: String,
    val yearEnd: String,
)

object ExpenseLimitNotificationEvaluator {
    fun periodsFor(transactionDate: String): ExpenseLimitPeriods {
        val parts = transactionDate.replace('-', '.').split('.')
        val year = parts.getOrNull(0)?.toIntOrNull() ?: 1970
        val month = parts.getOrNull(1)?.toIntOrNull() ?: 1
        val calendar = Calendar.getInstance().apply {
            clear()
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month - 1)
            set(Calendar.DAY_OF_MONTH, 1)
        }
        val monthEndDay = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        return ExpenseLimitPeriods(
            monthKey = "%04d-%02d".format(year, month),
            yearKey = "%04d".format(year),
            monthStart = "%04d.%02d.01".format(year, month),
            monthEnd = "%04d.%02d.%02d".format(year, month, monthEndDay),
            yearStart = "%04d.01.01".format(year),
            yearEnd = "%04d.12.31".format(year),
        )
    }

    fun evaluate(
        limit: CategoryLimitEntity,
        targetLabel: String,
        category: TransactionCategoryEntity?,
        transaction: ExpenseTransactionEntity,
        spentAmount: Double,
    ): ExpenseLimitAlert? {
        if (!limit.hasLimit || !limit.alertActive || limit.limitAmount <= 0.0) return null
        val usageRatio = spentAmount / limit.limitAmount
        val remainingAmount = limit.limitAmount - spentAmount
        val type = when {
            usageRatio >= 1.0 -> "limit_100"
            usageRatio >= 0.75 -> "limit_75"
            else -> return null
        }
        return ExpenseLimitAlert(
            type = type,
            title = if (type == "limit_100") "Limit elérve" else "Limit 75%",
            targetLabel = targetLabel,
            category = category,
            transaction = transaction,
            limitAmount = limit.limitAmount,
            spentAmount = abs(spentAmount),
            remainingAmount = remainingAmount,
            usageRatio = usageRatio,
        )
    }
}
```

- [ ] **Step 4: Verify evaluator tests pass**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.ExpenseLimitNotificationEvaluatorTest'
```

Expected: all evaluator tests pass.

- [ ] **Step 5: Commit evaluator**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluator.kt android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluatorTest.kt
git commit -m "Add limit notification evaluator"
```

---

### Task 4: Native Emitter and Android Notification Delivery

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationEmitter.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationHelper.kt`

- [ ] **Step 1: Create the emitter**

Create `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationEmitter.kt`:

```kotlin
package com.exptv2.app.expense

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.exptv2.app.R

class ExpenseNotificationEmitter(private val context: Context) {
    private val appContext = context.applicationContext

    suspend fun emit(card: NotificationCardEntity, cards: NotificationCardDao): NotificationCardEntity {
        val startedAt = System.currentTimeMillis()
        val id = cards.insert(card).toInt()
        val saved = card.copy(id = id)
        Log.d(TAG, "[Notification] card inserted id=$id type=${card.type}")
        notifyAndroid(saved)
        Log.d(TAG, "[Perf] notification emit type=${card.type} id=$id elapsed=${System.currentTimeMillis() - startedAt}ms")
        return saved
    }

    fun notifyAndroid(card: NotificationCardEntity) {
        ensureChannel()
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(appContext, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.d(TAG, "[Notification] android skipped type=${card.type} reason=missing_post_notifications")
            return
        }
        val notification = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(card.title)
            .setContentText(card.message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(card.message))
            .setPriority(priorityFor(card.priority))
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .build()
        runCatching {
            NotificationManagerCompat.from(appContext).notify(notificationId(card), notification)
            Log.d(TAG, "[Notification] android notify id=${notificationId(card)} type=${card.type}")
        }.onFailure { error ->
            Log.d(TAG, "[Notification] android failed type=${card.type} error=${error.message}")
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = appContext.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Expense alerts",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = "Tranzakciók, limitek és ismétlődő tranzakciók értesítései"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun priorityFor(priority: String): Int {
        return when (priority) {
            "critical" -> NotificationCompat.PRIORITY_HIGH
            "warning" -> NotificationCompat.PRIORITY_DEFAULT
            else -> NotificationCompat.PRIORITY_DEFAULT
        }
    }

    private fun notificationId(card: NotificationCardEntity): Int = 12000 + card.id

    companion object {
        private const val TAG = "ExpenseNotification"
        private const val CHANNEL_ID = "expense_alerts"
    }
}
```

- [ ] **Step 2: Convert recurring helper to a narrow wrapper or remove later**

Modify `RecurringNotificationHelper.kt` so it no longer owns message formatting. If no caller remains after Task 6, delete the file. If a caller still exists while transitioning, reduce `notifyProcessed` to debug logging only:

```kotlin
class RecurringNotificationHelper(private val context: Context) {
    fun notifyProcessed(rows: List<RecurringTransactionEntity>) {
        if (rows.isEmpty()) return
        Log.d("ExpenseNotification", "[Notification] legacy recurring notifyProcessed rows=${rows.size}")
    }
}
```

Keep imports minimal: `android.content.Context` and `android.util.Log`.

- [ ] **Step 3: Compile Android unit tests**

Run:

```bash
cd android && ./gradlew testDebugUnitTest
```

Expected: tests compile and pass. This does not verify Android notification display, but it catches Kotlin compile errors.

- [ ] **Step 4: Commit emitter**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationEmitter.kt android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationHelper.kt
git commit -m "Add expense notification emitter"
```

---

### Task 5: DAO Queries for Affected Limits

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/CategoryLimitDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`

- [ ] **Step 1: Add affected active limits query**

Add to `CategoryLimitDao`:

```kotlin
@Query(
    """
    SELECT * FROM category_limits
    WHERE transactionType = 'expense'
      AND hasLimit = 1
      AND alertActive = 1
      AND limitAmount > 0
      AND (
        (targetType = 'overview' AND targetId = 0) OR
        (targetType = 'category' AND targetId = :categoryId)
      )
      AND (
        (window = 'monthly' AND periodKey = :monthKey) OR
        (window = 'yearly' AND periodKey = :yearKey) OR
        (window = 'all_time' AND periodKey = 'all')
      )
    ORDER BY targetType ASC, targetId ASC, window ASC
    """,
)
suspend fun activeExpenseLimitsForTransaction(
    categoryId: Int,
    monthKey: String,
    yearKey: String,
): List<CategoryLimitEntity>
```

- [ ] **Step 2: Add spent sum query**

Add to `ExpenseTransactionDao`:

```kotlin
@Query(
    """
    SELECT COALESCE(SUM(ABS(amount)), 0) FROM transactions
    WHERE amount < 0
      AND (:categoryId IS NULL OR transactionCategoryID = :categoryId)
      AND (:startDate = '' OR date >= :startDate)
      AND (:endDate = '' OR date <= :endDate)
    """,
)
suspend fun expenseSpentTotal(
    categoryId: Int?,
    startDate: String,
    endDate: String,
): Double
```

Use empty `startDate` / `endDate` for all-time limits. The app stores dates as `YYYY.MM.DD`, so lexicographic range comparison is valid.

- [ ] **Step 3: Run Android compile tests**

Run:

```bash
cd android && ./gradlew testDebugUnitTest
```

Expected: all Android unit tests pass.

- [ ] **Step 4: Commit DAO queries**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/CategoryLimitDao.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt
git commit -m "Add notification limit queries"
```

---

### Task 6: Wire Manual Transaction Notifications

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`

- [ ] **Step 1: Add emitter field**

Near existing repository fields in `ExpenseRepository` add:

```kotlin
private val notificationEmitter = ExpenseNotificationEmitter(appContext)
```

- [ ] **Step 2: Wire `addTransaction` after insert**

In `addTransaction`, keep the existing validation. Store the category entity instead of discarding it:

```kotlin
val category = categories.byId(categoryId)
    ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
```

After `transactions.insert(row)`, add:

```kotlin
emitTransactionCreated(row, category)
if (row.amount < 0) {
    emitLimitAlertsForTransaction(row, category)
}
```

- [ ] **Step 3: Add private notification helpers to repository**

Add these private methods before `recurringTargetMillis()`:

```kotlin
private suspend fun emitTransactionCreated(
    transaction: ExpenseTransactionEntity,
    category: TransactionCategoryEntity,
) {
    val now = System.currentTimeMillis()
    Log.d("ExpenseNotification", "[Notification] transaction created requested id=${transaction.id} category=${category.transactionCategoryID}")
    notificationEmitter.emit(
        ExpenseNotificationCardFactory.transactionCreated(
            transaction = transaction,
            category = category,
            now = now,
        ),
        notificationCards,
    )
}

private suspend fun emitLimitAlertsForTransaction(
    transaction: ExpenseTransactionEntity,
    transactionCategory: TransactionCategoryEntity,
) {
    val startedAt = System.currentTimeMillis()
    val periods = ExpenseLimitNotificationEvaluator.periodsFor(transaction.date)
    val limits = categoryLimits.activeExpenseLimitsForTransaction(
        categoryId = transaction.transactionCategoryID,
        monthKey = periods.monthKey,
        yearKey = periods.yearKey,
    )
    Log.d(
        "ExpenseNotification",
        "[Notification] limit evaluation start transaction=${transaction.id} category=${transaction.transactionCategoryID} limits=${limits.size}",
    )
    for (limit in limits) {
        val categoryId = if (limit.targetType == "category") limit.targetId else null
        val dateRange = dateRangeForLimit(limit, periods)
        val spent = transactions.expenseSpentTotal(
            categoryId = categoryId,
            startDate = dateRange.first,
            endDate = dateRange.second,
        )
        val label = if (limit.targetType == "overview") "Kiadási budget" else transactionCategory.name
        val category = if (limit.targetType == "category") transactionCategory else null
        val alert = ExpenseLimitNotificationEvaluator.evaluate(
            limit = limit,
            targetLabel = label,
            category = category,
            transaction = transaction,
            spentAmount = spent,
        )
        Log.d(
            "ExpenseNotification",
            "[Notification] limit result id=${limit.id} target=${limit.targetType}:${limit.targetId} spent=$spent limit=${limit.limitAmount} threshold=${alert?.type ?: "none"}",
        )
        if (alert != null) {
            notificationEmitter.emit(ExpenseNotificationCardFactory.limitAlert(alert, System.currentTimeMillis()), notificationCards)
        }
    }
    Log.d("ExpenseNotification", "[Perf] limit evaluation complete transaction=${transaction.id} elapsed=${System.currentTimeMillis() - startedAt}ms")
}

private fun dateRangeForLimit(limit: CategoryLimitEntity, periods: ExpenseLimitPeriods): Pair<String, String> {
    return when (limit.window) {
        "monthly" -> periods.monthStart to periods.monthEnd
        "yearly" -> periods.yearStart to periods.yearEnd
        else -> "" to ""
    }
}
```

Also add `import android.util.Log` to `ExpenseRepository.kt` if not already present. It already has `android.util.Log`, so no new import should be needed.

- [ ] **Step 4: Run Android tests**

Run:

```bash
cd android && ./gradlew testDebugUnitTest
```

Expected: all Android unit tests pass.

- [ ] **Step 5: Run Flutter notification bridge test**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/native_bridge_expense_test.dart test/notifications/expense_notification_card_test.dart'
```

Expected: both test files pass.

- [ ] **Step 6: Commit manual transaction wiring**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt
git commit -m "Emit notifications for new transactions"
```

---

### Task 7: Wire Recurring Ghost Activation Notifications

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationHelper.kt` if unused

- [ ] **Step 1: Replace direct recurring card insert**

In `activateDueRecurringGhosts`, replace:

```kotlin
notificationCards.insert(
    RecurringNotificationCardFactory.activationCard(
        recurring = updated,
        ghost = ghost,
        transaction = transaction,
        now = now,
    ),
)
```

with:

```kotlin
notificationEmitter.emit(
    ExpenseNotificationCardFactory.recurringActivated(
        recurring = updated,
        ghost = ghost,
        transaction = transaction,
        now = now,
    ),
    notificationCards,
)
if (transaction.amount < 0) {
    val category = categories.byId(transaction.transactionCategoryID)
    if (category != null) {
        emitLimitAlertsForTransaction(transaction, category)
    }
}
```

- [ ] **Step 2: Remove legacy phone notification call**

In `processDueRecurringTransactions`, remove:

```kotlin
notificationHelper.notifyProcessed(processed)
```

The per-card notification emitter now handles Android delivery. Then remove the `notificationHelper` field if it is unused:

```kotlin
private val notificationHelper = RecurringNotificationHelper(appContext)
```

If `RecurringNotificationHelper.kt` becomes unused after this step, delete it:

```bash
git rm android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationHelper.kt
```

- [ ] **Step 3: Run existing recurring tests**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.RecurringNotificationCardFactoryTest' --tests 'com.exptv2.app.expense.RecurringGhostPlannerTest' --tests 'com.exptv2.app.expense.RecurringScheduleCalculatorTest'
```

Expected: all selected Android recurring tests pass.

- [ ] **Step 4: Commit recurring wiring**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationHelper.kt
git commit -m "Emit notifications for recurring activation"
```

If `RecurringNotificationHelper.kt` was deleted, use `git add -A android/app/src/main/kotlin/com/exptv2/app/expense/RecurringNotificationHelper.kt` instead.

---

### Task 8: Bridge Payload Coverage for New Card Types

**Files:**
- Modify: `test/transactions/native_bridge_expense_test.dart`

- [ ] **Step 1: Extend bridge notification-card test payload**

In `test/transactions/native_bridge_expense_test.dart`, inside the `expenseListNotificationCards` mock return list, add these rows after the existing recurring row:

```dart
{
  'id': 2,
  'type': 'transaction_created',
  'title': 'Új tranzakció',
  'message': 'Tesco: 4200 Ft kiadás rögzítve.',
  'timestamp': 1778803200000,
  'isRead': false,
  'isActive': true,
  'priority': 'normal',
  'categoryId': 6,
  'categoryName': 'Q',
  'categoryColor': '#dc2626',
  'categoryIconSlot': 2,
  'transactionId': 26051502,
  'amount': 4200,
  'triggerDate': '2026.05.15',
  'createdAt': 1778803200000,
  'updatedAt': 1778803200000,
},
{
  'id': 3,
  'type': 'limit_100',
  'title': 'Limit elérve',
  'message': 'Q: 1000 Ft-tal túllépted a limitet.',
  'timestamp': 1778803200000,
  'isRead': false,
  'isActive': true,
  'priority': 'critical',
  'categoryId': 6,
  'categoryName': 'Q',
  'categoryColor': '#dc2626',
  'categoryIconSlot': 2,
  'transactionId': 26051502,
  'amount': 4200,
  'triggerDate': '2026.05.15',
  'createdAt': 1778803200000,
  'updatedAt': 1778803200000,
},
```

Then update the assertions:

```dart
expect(cards, hasLength(3));
expect(cards[1].type, ExpenseNotificationType.transactionCreated);
expect(cards[2].type, ExpenseNotificationType.limit100);
expect(cards[2].priority, 'critical');
```

- [ ] **Step 2: Run bridge test**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/native_bridge_expense_test.dart'
```

Expected: test passes.

- [ ] **Step 3: Commit bridge coverage**

```bash
git add test/transactions/native_bridge_expense_test.dart
git commit -m "Cover new notification card bridge payloads"
```

---

### Task 9: Full Verification

**Files:**
- No new files. Verification only.

- [ ] **Step 1: Run Android unit tests**

Run:

```bash
cd android && ./gradlew testDebugUnitTest
```

Expected: `BUILD SUCCESSFUL` and all Android unit tests pass.

- [ ] **Step 2: Run Flutter analyzer and tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze && /home/flutteruser/flutter/bin/flutter test'
```

Expected: analyzer reports `No issues found!` and Flutter tests end with `All tests passed!`.

- [ ] **Step 3: Inspect logs during manual smoke test**

Run the app and manually trigger:

- add an expense transaction under 75% limit
- add an expense transaction that leaves category or overview limit above 75%
- add an expense transaction that leaves category or overview limit above 100%
- process a due recurring ghost using the recurring debug tools

Expected debug logs include:

```text
[Notification] transaction created requested id=...
[Notification] card inserted id=... type=transaction_created
[Notification] limit evaluation start transaction=...
[Notification] limit result id=... threshold=limit_75
[Notification] limit result id=... threshold=limit_100
[Notification] android notify id=... type=...
[Perf] notification emit type=... elapsed=...ms
```

If Android 13+ notification permission is missing, expected log:

```text
[Notification] android skipped type=... reason=missing_post_notifications
```

- [ ] **Step 4: Final status check**

Run:

```bash
git status --short --branch
```

Expected: branch is ahead of origin with only intentional committed changes, plus any pre-existing untracked `.superpowers/` if it was already present.

---

## Self-Review Notes

Spec coverage:

- Internal notification cards: Tasks 2, 4, 6, 7.
- Phone and lockscreen notifications: Task 4.
- Limit 75 and 100 triggers: Tasks 3, 5, 6, 7.
- New transaction trigger: Task 6.
- Ghost activation trigger: Task 7.
- Remaining/overage amount in limit message: Tasks 2 and 3.
- Debug logs: Tasks 4, 6, and 9.
- Dart parsing/rendering: Tasks 1 and 8.

No unresolved markers or unspecified implementation steps remain.

Type consistency:

- Native card types are `transaction_created`, `limit_75`, `limit_100`, and `recurring_transaction_alert`.
- Dart enum names are `transactionCreated`, `limit75`, and `limit100`.
- Native evaluator returns `ExpenseLimitAlert`, consumed by `ExpenseNotificationCardFactory.limitAlert(...)`.
