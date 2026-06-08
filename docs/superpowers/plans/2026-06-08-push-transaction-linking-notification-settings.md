# Push Transaction Linking and Notification Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix push-event transaction linkage, add two-way jump actions, make merchant name memory use the original merchant key, suppress edit-triggered limit notifications, add notification controls, and make backheader background follow the active theme.

**Architecture:** Native repositories remain the source of truth for notification-event links, merchant memory, and notification emission policy. Flutter widgets receive resolved ids through stores/bridge methods and delegate cross-screen navigation to `ExptShell` callbacks. The work is split into backend link/data changes, parser/name rules, notification policy/settings, UI navigation, and visual theme fixes.

**Tech Stack:** Kotlin, Room, Robolectric/JUnit, Flutter/Dart, MethodChannel, flutter_test.

---

## Scope Check

This spec touches several subsystems, but they are coupled by a single user workflow: captured push message -> transaction -> edit/notification behavior. The plan keeps tasks independently testable and commit-sized. Use subagent-driven development by subsystem after this plan is accepted, with integration review after every task.

## File Structure

Native link resolution:

- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstanceDao.kt`: add recurring notification link row queries.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`: add `byIds` and display-name memory queries.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`: add link resolution, single transaction lookup, transaction->event lookup, recurring source event write, merchant display-name inheritance, and edit notification suppression.
- Modify `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`: compute event status with direct and recurring links; load one event by id.
- Modify `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`: add `loadNotificationEvent` method.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`: add `expenseGetTransaction` and `expenseNotificationEventIdForTransaction`.

Parser and notification settings:

- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringParser.kt`: infer `Merchant: amount` prefix form when merchant regex misses.
- Modify `lib/features/settings/models/notification_parser_rule.dart`: teach Flutter preview/training the same prefix-colon merchant form.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactory.kt`: add period label to limit alert message.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluator.kt`: populate alert window and period key/label.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationEmitter.kt`: gate in-app card insert and Android push send through settings.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`: load/update notification settings.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`: add `expenseUpdateNotificationSettings`.

Flutter settings and navigation:

- Modify `lib/services/native_bridge.dart`: add notification settings model parsing and the new bridge methods.
- Modify `lib/features/settings/data/settings_repository.dart`: include notification settings in bootstrap and update path.
- Modify `lib/features/settings/state/settings_store.dart`: store and update notification settings.
- Create `lib/features/settings/models/notification_settings.dart`: Dart notification settings model.
- Create `lib/features/settings/widgets/options/notification_settings_panel.dart`: Settings submenu content.
- Modify `lib/features/settings/settings_page.dart`: add notification submenu and push->transaction callback.
- Modify `lib/features/settings/state/push_notification_log_store.dart`: expose single-event load for jump sheet refresh.
- Modify `lib/features/settings/widgets/push_log/push_notification_log_page.dart`: pass `onOpenTransaction` into the event sheet.
- Modify `lib/features/settings/widgets/push_log/push_notification_event_sheet.dart`: add `Ugras a tranzakciohoz` action.
- Modify `lib/features/transactions/widgets/add_transaction_sheet.dart`: preserve raw merchant on edit, write `userAssignedName`, and add `Ugras az uzenethez` action.
- Modify `lib/features/shell/expt_shell.dart`: coordinate push->transaction and transaction->push jumps.

Backheader color:

- Modify `lib/features/transactions/widgets/header_card/category_budget_stage.dart`: add `backgroundColor` prop and use it instead of `AppColors.gray100` for the stage background/masks.
- Modify `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`: add `backgroundColor` prop and use it for non-orbit backgrounds.
- Modify `lib/features/transactions/transaction_home_page.dart`: pass `expenseTheme.appBackground` into `CategoryBudgetStage`.

Tests:

- Modify native tests under `android/app/src/test/kotlin/com/exptv2/app` and `android/app/src/test/kotlin/com/exptv2/app/expense`.
- Modify Flutter tests under `test/settings`, `test/transactions`, and `test/shell` only where needed.

---

### Task 1: Native Notification Event Link Resolution

**Files:**
- Modify: `android/app/src/test/kotlin/com/exptv2/app/NotificationEventRepositoryTest.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstanceDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/NotificationEventRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `lib/services/native_bridge.dart`

- [ ] **Step 1: Write failing native tests for recurring-linked push status**

Add these imports and helpers to `NotificationEventRepositoryTest.kt`:

```kotlin
import com.exptv2.app.expense.ExpenseTrackerDatabase
import com.exptv2.app.expense.ExpenseTransactionEntity
import com.exptv2.app.expense.RecurringRuleInstanceEntity
import com.exptv2.app.expense.RecurringRuleInstanceStatus
```

Extend `setUp()` so expense tables are empty and seed is disabled:

```kotlin
context.getSharedPreferences("expense_seed", Context.MODE_PRIVATE)
    .edit()
    .putInt("demo_seed_version", com.exptv2.app.expense.ExpenseSeedData.version)
    .commit()
val expenseDb = ExpenseTrackerDatabase.get(context)
expenseDb.notificationCards().clearAllHard()
expenseDb.recurringRuleInstances().clearAll()
expenseDb.recurringRules().clearAll()
expenseDb.recurringGhostTransactions().clearAll()
expenseDb.recurringTransactions().clearAll()
expenseDb.transactions().clearAll()
expenseDb.categoryLimits().clearAll()
expenseDb.categories().clearAll()
```

Add this test:

```kotlin
@Test
fun listPageMarksRecurringActivatedEventAsLinked() = runBlocking {
    val events = PushParserDatabase.get(context).events()
    val expenseDb = ExpenseTrackerDatabase.get(context)
    val event = NotificationEventEntity(
        id = 0,
        timestamp = 1_780_941_600_000L,
        source = NotificationEventRepository.SOURCE_NOTIFICATION_LISTENER,
        packageName = "test.package",
        appLabel = "Notification Test",
        title = "",
        text = "Hitel: 80000 Ft",
        bigText = "",
        subText = "",
        category = "",
        notificationKey = "key-hitel",
        accessibilityEventType = "",
        hash = "hash-hitel",
        isDuplicate = false,
        manualStatus = "",
    )
    val eventId = events.insert(event)
    expenseDb.transactions().insert(
        ExpenseTransactionEntity(
            id = 26060801,
            date = "2026.06.08",
            time = "19:36",
            latitude = null,
            longitude = null,
            address = "Push recurring transaction",
            merchant = "Hitel",
            amount = -80000.0,
            userAssignedName = "hitel",
            transactionCategoryID = null,
            recurringRuleId = 11,
            recurringInstanceId = 22,
            sourceNotificationEventId = null,
        ),
    )
    expenseDb.recurringRuleInstances().insert(
        recurringInstance(
            id = 22,
            ruleId = 11,
            eventId = eventId,
            transactionId = 26060801,
        ),
    )

    val page = NotificationEventRepository(context).listPage(
        mapOf("limit" to 60, "offset" to 0, "status" to "linked"),
    )

    assertEquals(1, page.rows.size)
    assertEquals(NotificationEventStatus.LINKED, page.rows.single().status)
    assertEquals(26060801, page.rows.single().linkedTransactionId)
}

private fun recurringInstance(
    id: Int,
    ruleId: Int,
    eventId: Long,
    transactionId: Int,
) = RecurringRuleInstanceEntity(
    id = id,
    ruleId = ruleId,
    periodKey = "2026-06",
    status = RecurringRuleInstanceStatus.ACTIVATED,
    estimatedDate = "2026.06.08",
    estimatedAmount = 80000.0,
    transactionTypeSnapshot = "expense",
    triggerTypeSnapshot = "push",
    nameSnapshot = "hitel",
    categoryIdSnapshot = 0,
    categoryNameSnapshot = "",
    categoryColorSnapshot = "",
    categoryIconSlotSnapshot = 0,
    activatedTransactionId = transactionId,
    activatedAt = 1_780_941_600_000L,
    matchedNotificationEventId = eventId,
    matchConfidence = 1.0,
    createdAt = 1L,
    updatedAt = 1L,
)
```

- [ ] **Step 2: Run the focused native test and verify it fails**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.NotificationEventRepositoryTest.listPageMarksRecurringActivatedEventAsLinked'
```

Expected: FAIL because `NotificationEventRepository.listPage()` only checks `sourceNotificationEventId` and returns no linked rows for recurring activations.

- [ ] **Step 3: Add recurring link DAO rows and transaction lookup queries**

In `RecurringRuleInstanceDao.kt`, add above the DAO interface:

```kotlin
data class RecurringNotificationTransactionLink(
    val matchedNotificationEventId: Long,
    val activatedTransactionId: Int,
)
```

Add these queries to the interface:

```kotlin
@Query(
    """
    SELECT matchedNotificationEventId, activatedTransactionId
    FROM recurring_rule_instances
    WHERE status = 'activated'
      AND matchedNotificationEventId IN (:eventIds)
      AND activatedTransactionId IS NOT NULL
    """
)
suspend fun activatedTransactionLinksForNotificationEvents(
    eventIds: List<Long>,
): List<RecurringNotificationTransactionLink>

@Query(
    """
    SELECT matchedNotificationEventId
    FROM recurring_rule_instances
    WHERE status = 'activated'
      AND activatedTransactionId = :transactionId
      AND matchedNotificationEventId IS NOT NULL
    ORDER BY activatedAt DESC, id DESC
    LIMIT 1
    """
)
suspend fun notificationEventIdForActivatedTransaction(transactionId: Int): Long?
```

In `ExpenseTransactionDao.kt`, add:

```kotlin
@Query("SELECT * FROM transactions WHERE id IN (:ids)")
suspend fun byIds(ids: List<Int>): List<ExpenseTransactionEntity>
```

- [ ] **Step 4: Implement central link resolution in `ExpenseRepository`**

Replace `transactionsBySourceNotificationEventIds` with a direct-only private helper plus public resolved helpers:

```kotlin
private suspend fun directTransactionsBySourceNotificationEventIds(
    eventIds: List<Long>,
): Map<Long, ExpenseTransactionEntity> {
    if (eventIds.isEmpty()) return emptyMap()
    return transactions.bySourceNotificationEventIds(eventIds)
        .mapNotNull { row -> row.sourceNotificationEventId?.let { it to row } }
        .toMap()
}

suspend fun transactionsByNotificationEventIds(
    eventIds: List<Long>,
): Map<Long, ExpenseTransactionEntity> {
    seedIfEmpty()
    if (eventIds.isEmpty()) return emptyMap()
    val direct = directTransactionsBySourceNotificationEventIds(eventIds).toMutableMap()
    val missingEventIds = eventIds.filterNot { direct.containsKey(it) }
    if (missingEventIds.isEmpty()) return direct
    val recurringLinks = recurringRuleInstances
        .activatedTransactionLinksForNotificationEvents(missingEventIds)
    val linkedTransactions = transactions
        .byIds(recurringLinks.map { it.activatedTransactionId }.distinct())
        .associateBy { it.id }
    for (link in recurringLinks) {
        val transaction = linkedTransactions[link.activatedTransactionId] ?: continue
        direct.putIfAbsent(link.matchedNotificationEventId, transaction)
    }
    return direct
}

suspend fun transactionById(id: Int): ExpenseTransactionEntity? {
    seedIfEmpty()
    return transactions.byId(id)
}

suspend fun notificationEventIdForTransaction(id: Int): Long? {
    seedIfEmpty()
    val transaction = transactions.byId(id) ?: return null
    return transaction.sourceNotificationEventId
        ?: recurringRuleInstances.notificationEventIdForActivatedTransaction(id)
}
```

Keep a compatibility wrapper if any existing call still uses the old method name:

```kotlin
suspend fun transactionsBySourceNotificationEventIds(
    eventIds: List<Long>,
): Map<Long, ExpenseTransactionEntity> = transactionsByNotificationEventIds(eventIds)
```

- [ ] **Step 5: Update notification event repository and method channels**

In `NotificationEventRepository.listPage()`, change:

```kotlin
val linked = expenseRepository.transactionsBySourceNotificationEventIds(candidates.map { it.id })
```

to:

```kotlin
val linked = expenseRepository.transactionsByNotificationEventIds(candidates.map { it.id })
```

Add to `NotificationEventRepository`:

```kotlin
suspend fun eventById(id: Long): NotificationEventPageRow? {
    val event = dao.byId(id) ?: return null
    val linked = expenseRepository.transactionsByNotificationEventIds(listOf(id))[id]
    val status = NotificationEventStatus.forEvent(event.manualStatus, linked?.id)
    return NotificationEventPageRow(event, status, linked?.id)
}
```

`NotificationEventDao.byId(id)` already exists, so no DAO change is needed for single-event loading.

In `MainActivity.kt`, add a `loadNotificationEvent` method next to `loadNotificationEventPage`:

```kotlin
"loadNotificationEvent" -> scope.launch {
    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
    val id = (args["id"] as? Number)?.toLong()
        ?: args["id"]?.toString()?.toLongOrNull()
        ?: 0L
    val row = withContext(Dispatchers.IO) { repository.eventById(id)?.toMap() }
    result.success(row)
}
```

In `ExpenseMethodChannel.kt`, add:

```kotlin
"expenseGetTransaction" -> scope.launchResult(result) {
    val id = (call.argumentsMap()["id"] as? Number)?.toInt()
        ?: call.argumentsMap()["id"]?.toString()?.toIntOrNull()
        ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction id is required")
    repository.transactionById(id)?.toMap()
        ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction does not exist")
}
"expenseNotificationEventIdForTransaction" -> scope.launchResult(result) {
    val id = (call.argumentsMap()["id"] as? Number)?.toInt()
        ?: call.argumentsMap()["id"]?.toString()?.toIntOrNull()
        ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction id is required")
    repository.notificationEventIdForTransaction(id)
}
```

In `NativeBridge`, add:

```dart
Future<PushNotificationLogEvent?> loadNotificationEvent(int id) async {
  final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'loadNotificationEvent',
    <String, Object?>{'id': id},
  );
  if (map == null) return null;
  return PushNotificationLogEvent.fromMap(map);
}

Future<TransactionRecord> expenseGetTransaction(int id) async {
  final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'expenseGetTransaction',
    <String, Object?>{'id': id},
  );
  return TransactionRecord.fromMap(row ?? <dynamic, dynamic>{});
}

Future<int?> expenseNotificationEventIdForTransaction(int id) async {
  final value = await _methodChannel.invokeMethod<dynamic>(
    'expenseNotificationEventIdForTransaction',
    <String, Object?>{'id': id},
  );
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
```

- [ ] **Step 6: Store `sourceNotificationEventId` on new recurring push transactions**

In `ExpenseRepository.activatePushRecurringCandidate`, add this field to the `ExpenseTransactionEntity` constructor:

```kotlin
sourceNotificationEventId = event.id,
```

- [ ] **Step 7: Run tests and commit**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.NotificationEventRepositoryTest' --tests 'com.exptv2.app.expense.PushRecurringMatcherTest'
flutter test test/settings/push_notification_log_store_test.dart
```

Expected: PASS.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app android/app/src/test/kotlin/com/exptv2/app lib/services/native_bridge.dart
git commit -m "Fix push event transaction link resolution"
```

---

### Task 2: Prefix-Colon Push Parser Support

**Files:**
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringParserTest.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringMatcherTest.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringParser.kt`
- Modify: `test/settings/notification_parser_rule_test.dart`
- Modify: `lib/features/settings/models/notification_parser_rule.dart`

- [ ] **Step 1: Write failing native parser tests**

Add to `PushRecurringParserTest.kt`:

```kotlin
@Test
fun infersPrefixMerchantWhenMerchantRegexMisses() {
    val result = PushRecurringParser.parse(
        text = "Hitel: 80000 Ft",
        amountPattern = "(?<amount>\\d[\\d\\s.,]*)(?:\\s*(?:Ft|HUF))",
        merchantPattern = "itt:\\s*(?<merchant>.+?)(?:\\.|$)",
        includeKeyword = "",
    )

    assertNotNull(result.amount)
    assertEquals(80000.0, result.amount!!, 0.0)
    assertEquals("Hitel", result.merchant)
    assertNull(result.error)
}
```

Add to `PushRecurringMatcherTest.kt`:

```kotlin
@Test
fun merchantMatchIgnoresCaseAndTrailingColonForm() {
    val rule = PushRecurringMatchRule(
        ruleId = 1,
        instanceId = 10,
        estimatedDate = "2026.06.08",
        estimatedAmount = 80000.0,
        transactionType = "expense",
        appFilterText = "^Notification Test$",
        packageName = "com.test.notification",
        appLabel = "Notification Test",
        dateToleranceDays = 5,
        amountTolerancePercent = 20.0,
        amountToleranceMin = 5000.0,
        merchantSelection = "hitel",
    )
    val event = PushRecurringMatchEvent(
        notificationEventId = 77,
        appLabel = "Notification Test",
        packageName = "com.test.notification",
        date = "2026.06.08",
        amount = 80000.0,
        merchant = "Hitel",
        transactionType = "expense",
    )

    val score = PushRecurringMatcher.score(rule, event)

    assertTrue(score.matches)
}
```

- [ ] **Step 2: Run focused parser tests and verify failure**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.PushRecurringParserTest.infersPrefixMerchantWhenMerchantRegexMisses' --tests 'com.exptv2.app.expense.PushRecurringMatcherTest.merchantMatchIgnoresCaseAndTrailingColonForm'
```

Expected: the parser test fails with `merchant_missing`.

- [ ] **Step 3: Implement native prefix merchant inference**

In `PushRecurringParser.parse`, keep the amount match in a local variable and use fallback merchant inference:

```kotlin
val amountMatch = amountRegex.find(normalized)
val merchantMatch = merchantRegex.find(normalized)
val amountText = capture(amountMatch, "amount")
val merchant = capture(merchantMatch, "merchant")?.trim()
    ?: inferPrefixMerchant(normalized, amountMatch)
val amount = parseAmount(amountText)
```

Add this private helper:

```kotlin
private fun inferPrefixMerchant(text: String, amountMatch: MatchResult?): String? {
    if (amountMatch == null) return null
    val beforeAmount = text.substring(0, amountMatch.range.first).trim()
    val colon = beforeAmount.lastIndexOf(':')
    if (colon <= 0) return null
    val candidate = beforeAmount.substring(0, colon).trim()
    if (candidate.isBlank()) return null
    if (candidate.length > 80) return null
    if (!candidate.any { it.isLetterOrDigit() }) return null
    return candidate.trim(' ', ':', '.', ',', ';')
}
```

- [ ] **Step 4: Write failing Flutter parser-training test**

In `test/settings/notification_parser_rule_test.dart`, add:

```dart
test('learns merchant before colon in prefix amount messages', () {
  final profile = NotificationParserProfile.defaults().copyWith(
    sampleText: 'Hitel: 80000 Ft',
    includeKeyword: '',
  );

  final learned = profile
      .learnAmountFromSelection('80000 Ft')
      .learnMerchantFromSelection('Hitel');

  expect(learned.preview.amountValue, 80000);
  expect(learned.preview.merchant, 'Hitel');
  expect(learned.merchantPattern, r'^(?<merchant>[^:]{1,80}):\s*');
})
```

- [ ] **Step 5: Run Flutter parser test and verify failure**

Run:

```bash
flutter test test/settings/notification_parser_rule_test.dart --plain-name 'learns merchant before colon in prefix amount messages'
```

Expected: FAIL because `learnMerchantFromSelection` currently falls back to literal `(?<merchant>Hitel)`.

- [ ] **Step 6: Implement Flutter prefix-colon learning and preview fallback**

In `NotificationParserProfile.learnMerchantFromSelection`, insert this branch before the existing `itt:` branch:

```dart
if (RegExp(
  '^\\s*$escaped\\s*:',
  caseSensitive: false,
).hasMatch(sample)) {
  pattern = r'^(?<merchant>[^:]{1,80}):\s*';
} else if (RegExp('itt:\\s*$escaped', caseSensitive: false).hasMatch(sample)) {
```

In `NotificationParserPreview.fromRule`, after computing `merchant`, add fallback inference before the merchant missing check:

```dart
final inferredMerchant = merchant?.trim().isNotEmpty == true
    ? merchant!.trim()
    : _inferPrefixMerchant(normalized, amountMatch);
```

Use `inferredMerchant` in the ready/missing branches, and add:

```dart
static String? _inferPrefixMerchant(String text, RegExpMatch? amountMatch) {
  if (amountMatch == null) return null;
  final beforeAmount = text.substring(0, amountMatch.start).trim();
  final colon = beforeAmount.lastIndexOf(':');
  if (colon <= 0) return null;
  final candidate = beforeAmount.substring(0, colon).trim();
  if (candidate.isEmpty || candidate.length > 80) return null;
  if (!RegExp(r'[A-Za-z0-9À-ž]').hasMatch(candidate)) return null;
  return candidate.replaceAll(RegExp(r'^[\s:;,.]+|[\s:;,.]+$'), '');
}
```

- [ ] **Step 7: Run parser tests and commit**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.PushRecurringParserTest' --tests 'com.exptv2.app.expense.PushRecurringMatcherTest'
flutter test test/settings/notification_parser_rule_test.dart
```

Expected: PASS.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/PushRecurringParser.kt android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringParserTest.kt android/app/src/test/kotlin/com/exptv2/app/expense/PushRecurringMatcherTest.kt lib/features/settings/models/notification_parser_rule.dart test/settings/notification_parser_rule_test.dart
git commit -m "Support prefix merchant push messages"
```

---

### Task 3: Merchant Display Name Memory Through Current Edit Card

**Files:**
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseRepositoryMerchantCategoryTest.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `test/transactions/transaction_widgets_test.dart`

- [ ] **Step 1: Write failing native display-name propagation tests**

Add to `ExpenseRepositoryMerchantCategoryTest.kt`:

```kotlin
@Test
fun updateTransactionPropagatesDisplayNameToSameOriginalMerchant() = runBlocking {
    db.transactions().insertAll(
        listOf(
            transaction(id = 260101, merchant = "nyiro", categoryId = 6),
            transaction(id = 260102, merchant = "nyiro", categoryId = null),
            transaction(id = 260103, merchant = "masik", categoryId = null),
        ),
    )

    repository.updateTransaction(
        mapOf(
            "id" to 260101,
            "merchant" to "nyiro",
            "amount" to 3085.0,
            "type" to "expense",
            "transactionCategoryID" to 7,
            "date" to "2026-01-01",
            "time" to "10:00",
            "userAssignedName" to "Nyiro etterem",
        ),
    )

    assertEquals("Nyiro etterem", db.transactions().byId(260101)?.userAssignedName)
    assertEquals("Nyiro etterem", db.transactions().byId(260102)?.userAssignedName)
    assertNull(db.transactions().byId(260103)?.userAssignedName)
}

@Test
fun addTransactionInheritsDisplayNameFromSameOriginalMerchant() = runBlocking {
    db.transactions().insert(
        transaction(id = 260101, merchant = "nyiro", categoryId = 7)
            .copy(userAssignedName = "Nyiro etterem"),
    )

    val saved = repository.addTransaction(
        mapOf(
            "merchant" to "nyiro",
            "amount" to 4500.0,
            "type" to "expense",
            "date" to "2026-01-02",
            "time" to "11:00",
        ),
    )

    assertEquals("Nyiro etterem", saved["userAssignedName"])
}
```

- [ ] **Step 2: Run focused native tests and verify failure**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.ExpenseRepositoryMerchantCategoryTest.updateTransactionPropagatesDisplayNameToSameOriginalMerchant' --tests 'com.exptv2.app.expense.ExpenseRepositoryMerchantCategoryTest.addTransactionInheritsDisplayNameFromSameOriginalMerchant'
```

Expected: FAIL because `updateTransaction` only updates one row and `addTransaction` copies only explicit `userAssignedName`.

- [ ] **Step 3: Add DAO queries for display-name memory**

In `ExpenseTransactionDao.kt`, add:

```kotlin
@Query(
    """
    SELECT userAssignedName FROM transactions
    WHERE TRIM(merchant) = TRIM(:merchant)
      AND userAssignedName IS NOT NULL
      AND TRIM(userAssignedName) != ''
    ORDER BY date DESC, time DESC, id DESC
    LIMIT 1
    """
)
suspend fun latestUserAssignedNameForMerchant(merchant: String): String?

@Query(
    """
    UPDATE transactions
    SET userAssignedName = :userAssignedName
    WHERE TRIM(merchant) = TRIM(:merchant)
    """
)
suspend fun updateUserAssignedNameByMerchant(merchant: String, userAssignedName: String): Int

@Query(
    """
    UPDATE transactions
    SET userAssignedName = NULL
    WHERE TRIM(merchant) = TRIM(:merchant)
    """
)
suspend fun clearUserAssignedNameByMerchant(merchant: String): Int
```

- [ ] **Step 4: Implement display-name inheritance and propagation in `ExpenseRepository`**

Add helpers:

```kotlin
private suspend fun inheritedUserAssignedNameForMerchant(
    merchant: String,
    requested: String?,
): String? {
    val explicit = requested?.trim()?.takeIf { it.isNotEmpty() }
    if (explicit != null) return explicit
    return transactions.latestUserAssignedNameForMerchant(merchant)
        ?.trim()
        ?.takeIf { it.isNotEmpty() }
}

private suspend fun propagateDisplayNameForMerchant(
    originalMerchant: String,
    userAssignedName: String?,
): Int {
    val cleaned = userAssignedName?.trim()?.takeIf { it.isNotEmpty() }
    val count = if (cleaned == null || cleaned == originalMerchant.trim()) {
        transactions.clearUserAssignedNameByMerchant(originalMerchant)
    } else {
        transactions.updateUserAssignedNameByMerchant(originalMerchant, cleaned)
    }
    Log.d(
        "ExpenseRepository",
        "[Transactions] display name propagation merchant=$originalMerchant name=${cleaned.orEmpty()} rows=$count",
    )
    return count
}
```

In `addTransaction`, set:

```kotlin
val userAssignedName = inheritedUserAssignedNameForMerchant(
    merchant,
    args["userAssignedName"]?.toString(),
)
```

and use `userAssignedName = userAssignedName` in the entity.

In `updateTransaction`, after `transactions.insert(row)`, add:

```kotlin
if (args.containsKey("userAssignedName")) {
    propagateDisplayNameForMerchant(existing.merchant, row.userAssignedName)
}
```

- [ ] **Step 5: Write failing Flutter edit-card test**

In `test/transactions/transaction_widgets_test.dart`, add a widget test that builds `AddTransactionSheet` with an initial `TransactionRecord(merchant: 'nyiro', userAssignedName: null)` and a fake store/repository. Assert the save payload keeps `merchant: 'nyiro'` and sends `userAssignedName: 'Nyiro etterem'` after the user edits the name field.

Use this expected payload assertion in the test:

```dart
expect(updatePayload['merchant'], 'nyiro');
expect(updatePayload['userAssignedName'], 'Nyiro etterem');
```

- [ ] **Step 6: Implement edit-card raw merchant preservation**

In `AddTransactionSheet._save`, replace the edit branch with:

```dart
final originalMerchant = initial.merchant.trim();
final displayName = merchant.trim();
final assignedName = displayName == originalMerchant ? null : displayName;
await widget.store.updateTransaction(
  initial,
  merchant: originalMerchant,
  amount: amount,
  type: type,
  categoryId: category.transactionCategoryID,
  date: date,
  time: time,
  userAssignedName: assignedName,
);
```

Keep the add branch unchanged.

- [ ] **Step 7: Run tests and commit**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.ExpenseRepositoryMerchantCategoryTest'
flutter test test/transactions/transaction_widgets_test.dart --plain-name 'edit card preserves original merchant and writes display override'
```

Expected: PASS.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseRepositoryMerchantCategoryTest.kt lib/features/transactions/widgets/add_transaction_sheet.dart test/transactions/transaction_widgets_test.dart
git commit -m "Propagate merchant display names by original merchant"
```

---

### Task 4: Notification Settings, Limit Period Text, and Edit Suppression

**Files:**
- Create: `lib/features/settings/models/notification_settings.dart`
- Create: `lib/features/settings/widgets/options/notification_settings_panel.dart`
- Create: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreNotificationTest.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseRepositoryMerchantCategoryTest.kt`
- Modify: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactoryTest.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationEmitter.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseLimitNotificationEvaluator.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseNotificationCardFactory.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/features/settings/data/settings_repository.dart`
- Modify: `lib/features/settings/state/settings_store.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `test/settings/settings_store_test.dart`
- Modify: `test/settings/settings_page_test.dart`

- [ ] **Step 1: Write failing tests for edit suppression and period text**

In `ExpenseRepositoryMerchantCategoryTest.kt`, add a category limit and assert edit does not add notification cards:

```kotlin
@Test
fun updateTransactionDoesNotCreateLimitNotificationCard() = runBlocking {
    db.categoryLimits().insert(
        CategoryLimitEntity(
            id = 1,
            targetType = "category",
            targetId = 7,
            transactionType = "expense",
            window = "monthly",
            periodKey = "2026-01",
            hasLimit = true,
            limitAmount = 1000.0,
            alertActive = true,
            createdAt = 1,
            updatedAt = 1,
        ),
    )
    db.transactions().insert(transaction(id = 260101, merchant = "nyiro", categoryId = 7))

    repository.updateTransaction(
        mapOf(
            "id" to 260101,
            "merchant" to "nyiro",
            "amount" to 3085.0,
            "type" to "expense",
            "transactionCategoryID" to 7,
            "date" to "2026-01-01",
            "time" to "10:00",
            "userAssignedName" to "Nyiro",
        ),
    )

    assertEquals(0, db.notificationCards().active().size)
}
```

In `ExpenseNotificationCardFactoryTest.kt`, add:

```kotlin
@Test
fun limitCardIncludesMonthlyYearlyAndTotalPeriodLabels() {
    val monthly = ExpenseLimitAlert(
        type = "limit_100",
        title = "Limit elérve",
        targetLabel = "Élelmiszer",
        category = category,
        transaction = transaction,
        limitAmount = 10000.0,
        spentAmount = 12000.0,
        remainingAmount = -2000.0,
        usageRatio = 1.2,
        window = "monthly",
        periodKey = "2026-06",
        periodLabel = "2026 juniusi",
    )

    val card = ExpenseNotificationCardFactory.limitAlert(monthly, now)

    assertTrue(card.message.contains("2026 juniusi"))
    assertTrue(card.message.contains("Élelmiszer"))
}
```

- [ ] **Step 2: Run focused tests and verify failure**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.ExpenseRepositoryMerchantCategoryTest.updateTransactionDoesNotCreateLimitNotificationCard' --tests 'com.exptv2.app.expense.ExpenseNotificationCardFactoryTest.limitCardIncludesMonthlyYearlyAndTotalPeriodLabels'
```

Expected: FAIL because `updateTransaction` emits limit alerts and `ExpenseLimitAlert` has no period label fields.

- [ ] **Step 3: Suppress limit emission in manual updates**

In `ExpenseRepository.updateTransaction`, remove the call to `emitLimitAlertsForTransaction(row, category)` and replace the whole limit-evaluation branch with:

```kotlin
Log.d(
    "ExpenseNotification",
    "[Notification] transaction update limit evaluation skipped id=${row.id} reason=manual_edit",
)
```

Do not remove category propagation or display-name propagation.

- [ ] **Step 4: Add limit period fields and message formatting**

In `ExpenseLimitAlert`, add:

```kotlin
val window: String = "monthly",
val periodKey: String = "",
val periodLabel: String = "",
```

In `ExpenseLimitNotificationEvaluator.evaluate`, pass:

```kotlin
window = limit.window,
periodKey = limit.periodKey,
periodLabel = periodLabel(limit.window, limit.periodKey),
```

Add helper:

```kotlin
private fun periodLabel(window: String, periodKey: String): String {
    return when (window) {
        "monthly" -> {
            val parts = periodKey.split("-")
            val year = parts.getOrNull(0) ?: return "havi"
            val month = parts.getOrNull(1)?.toIntOrNull() ?: return "$year havi"
            val monthName = listOf(
                "januari", "februari", "marciusi", "aprilisi", "majusi", "juniusi",
                "juliusi", "augusztusi", "szeptemberi", "oktoberi", "novemberi", "decemberi",
            ).getOrNull(month - 1) ?: "havi"
            "$year $monthName"
        }
        "yearly" -> "$periodKey evi"
        else -> "osszlimit"
    }
}
```

In `ExpenseNotificationCardFactory.limitAlert`, prefix target with period:

```kotlin
val targetWithPeriod = listOf(alert.periodLabel, alert.targetLabel)
    .filter { it.isNotBlank() }
    .joinToString(" ")
```

Use `targetWithPeriod` in the three message branches instead of `alert.targetLabel`.

- [ ] **Step 5: Add native notification settings tests**

Create `ExpenseSettingsStoreNotificationTest.kt`:

```kotlin
package com.exptv2.app.expense

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class ExpenseSettingsStoreNotificationTest {
    private lateinit var context: Context
    private lateinit var store: ExpenseSettingsStore

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
        store = ExpenseSettingsStore(context)
    }

    @Test
    fun notificationSettingsDefaultToEnabled() {
        val settings = store.loadNotificationSettings()

        assertTrue(settings["inAppEnabled"] as Boolean)
        assertTrue(settings["androidPushEnabled"] as Boolean)
        assertTrue(settings["transactionCreatedEnabled"] as Boolean)
        assertTrue(settings["recurringActivationEnabled"] as Boolean)
        assertTrue(settings["limitWarningEnabled"] as Boolean)
        assertTrue(settings["limitExceededEnabled"] as Boolean)
    }

    @Test
    fun notificationSettingsCanDisableAndroidPushOnly() {
        val settings = store.updateNotificationSettings(
            mapOf("androidPushEnabled" to false, "inAppEnabled" to true),
        )

        assertFalse(settings["androidPushEnabled"] as Boolean)
        assertTrue(settings["inAppEnabled"] as Boolean)
    }
}
```

- [ ] **Step 6: Implement native notification settings and emitter gating**

In `ExpenseSettingsStore.loadSettings`, add:

```kotlin
"notificationSettings" to loadNotificationSettings(),
```

Add methods:

```kotlin
fun loadNotificationSettings(): Map<String, Any?> = mapOf(
    "inAppEnabled" to prefs.getBoolean(KEY_NOTIF_IN_APP, true),
    "androidPushEnabled" to prefs.getBoolean(KEY_NOTIF_ANDROID_PUSH, true),
    "transactionCreatedEnabled" to prefs.getBoolean(KEY_NOTIF_TRANSACTION_CREATED, true),
    "recurringActivationEnabled" to prefs.getBoolean(KEY_NOTIF_RECURRING_ACTIVATION, true),
    "limitWarningEnabled" to prefs.getBoolean(KEY_NOTIF_LIMIT_WARNING, true),
    "limitExceededEnabled" to prefs.getBoolean(KEY_NOTIF_LIMIT_EXCEEDED, true),
)

fun updateNotificationSettings(args: Map<*, *>): Map<String, Any?> {
    prefs.edit()
        .putBoolean(KEY_NOTIF_IN_APP, boolSetting(args, "inAppEnabled", true))
        .putBoolean(KEY_NOTIF_ANDROID_PUSH, boolSetting(args, "androidPushEnabled", true))
        .putBoolean(KEY_NOTIF_TRANSACTION_CREATED, boolSetting(args, "transactionCreatedEnabled", true))
        .putBoolean(KEY_NOTIF_RECURRING_ACTIVATION, boolSetting(args, "recurringActivationEnabled", true))
        .putBoolean(KEY_NOTIF_LIMIT_WARNING, boolSetting(args, "limitWarningEnabled", true))
        .putBoolean(KEY_NOTIF_LIMIT_EXCEEDED, boolSetting(args, "limitExceededEnabled", true))
        .apply()
    return loadNotificationSettings()
}

private fun boolSetting(args: Map<*, *>, key: String, fallback: Boolean): Boolean =
    args[key] as? Boolean ?: fallback
```

Add keys in the companion object:

```kotlin
private const val KEY_NOTIF_IN_APP = "notificationInAppEnabled"
private const val KEY_NOTIF_ANDROID_PUSH = "notificationAndroidPushEnabled"
private const val KEY_NOTIF_TRANSACTION_CREATED = "notificationTransactionCreatedEnabled"
private const val KEY_NOTIF_RECURRING_ACTIVATION = "notificationRecurringActivationEnabled"
private const val KEY_NOTIF_LIMIT_WARNING = "notificationLimitWarningEnabled"
private const val KEY_NOTIF_LIMIT_EXCEEDED = "notificationLimitExceededEnabled"
```

In `ExpenseRepository`, construct emitter with the existing settings store:

```kotlin
private val settingsStore = ExpenseSettingsStore(appContext)
private val notificationEmitter = ExpenseNotificationEmitter(appContext, settingsStore)
```

In `ExpenseNotificationEmitter`, change constructor and emit:

```kotlin
class ExpenseNotificationEmitter(
    context: Context,
    private val settingsStore: ExpenseSettingsStore = ExpenseSettingsStore(context),
) {
    suspend fun emit(card: NotificationCardEntity, cards: NotificationCardDao): NotificationCardEntity? {
        val settings = settingsStore.loadNotificationSettings()
        val typeEnabled = notificationTypeEnabled(card.type, settings)
        val inAppEnabled = settings["inAppEnabled"] == true && typeEnabled
        val androidEnabled = settings["androidPushEnabled"] == true && typeEnabled
        if (!inAppEnabled && !androidEnabled) {
            Log.d(TAG, "[Notification] skipped type=${card.type} reason=settings_disabled")
            return null
        }
        val saved = if (inAppEnabled) {
            val id = cards.insert(card).toInt()
            card.copy(id = id)
        } else {
            card.copy(id = transientNotificationId(card))
        }
        if (androidEnabled) notifyAndroid(saved) else Log.d(TAG, "[Notification] android skipped type=${card.type} reason=settings_disabled")
        return saved
    }

    private fun notificationTypeEnabled(type: String, settings: Map<String, Any?>): Boolean = when (type) {
        "transaction_created" -> settings["transactionCreatedEnabled"] == true
        "recurring_transaction_alert" -> settings["recurringActivationEnabled"] == true
        "limit_75" -> settings["limitWarningEnabled"] == true
        "limit_100" -> settings["limitExceededEnabled"] == true
        else -> true
    }

    private fun transientNotificationId(card: NotificationCardEntity): Int =
        (System.currentTimeMillis() % 100000).toInt().coerceAtLeast(1)
}
```

- [ ] **Step 7: Add method channel and Dart model/store/panel**

In `ExpenseMethodChannel.kt`, add:

```kotlin
"expenseUpdateNotificationSettings" -> scope.launchResult(result) {
    repository.updateNotificationSettings(call.argumentsMap())
}
```

Expose in `ExpenseRepository`:

```kotlin
fun updateNotificationSettings(args: Map<*, *>): Map<String, Any?> =
    settingsStore.updateNotificationSettings(args)
```

Create `notification_settings.dart`:

```dart
class NotificationSettings {
  const NotificationSettings({
    required this.inAppEnabled,
    required this.androidPushEnabled,
    required this.transactionCreatedEnabled,
    required this.recurringActivationEnabled,
    required this.limitWarningEnabled,
    required this.limitExceededEnabled,
  });

  factory NotificationSettings.defaults() => const NotificationSettings(
    inAppEnabled: true,
    androidPushEnabled: true,
    transactionCreatedEnabled: true,
    recurringActivationEnabled: true,
    limitWarningEnabled: true,
    limitExceededEnabled: true,
  );

  factory NotificationSettings.fromMap(Map<dynamic, dynamic>? map) {
    final defaults = NotificationSettings.defaults();
    if (map == null) return defaults;
    bool read(String key, bool fallback) => map[key] is bool ? map[key] as bool : fallback;
    return NotificationSettings(
      inAppEnabled: read('inAppEnabled', defaults.inAppEnabled),
      androidPushEnabled: read('androidPushEnabled', defaults.androidPushEnabled),
      transactionCreatedEnabled: read('transactionCreatedEnabled', defaults.transactionCreatedEnabled),
      recurringActivationEnabled: read('recurringActivationEnabled', defaults.recurringActivationEnabled),
      limitWarningEnabled: read('limitWarningEnabled', defaults.limitWarningEnabled),
      limitExceededEnabled: read('limitExceededEnabled', defaults.limitExceededEnabled),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'inAppEnabled': inAppEnabled,
    'androidPushEnabled': androidPushEnabled,
    'transactionCreatedEnabled': transactionCreatedEnabled,
    'recurringActivationEnabled': recurringActivationEnabled,
    'limitWarningEnabled': limitWarningEnabled,
    'limitExceededEnabled': limitExceededEnabled,
  };

  final bool inAppEnabled;
  final bool androidPushEnabled;
  final bool transactionCreatedEnabled;
  final bool recurringActivationEnabled;
  final bool limitWarningEnabled;
  final bool limitExceededEnabled;

  NotificationSettings copyWith({
    bool? inAppEnabled,
    bool? androidPushEnabled,
    bool? transactionCreatedEnabled,
    bool? recurringActivationEnabled,
    bool? limitWarningEnabled,
    bool? limitExceededEnabled,
  }) => NotificationSettings(
    inAppEnabled: inAppEnabled ?? this.inAppEnabled,
    androidPushEnabled: androidPushEnabled ?? this.androidPushEnabled,
    transactionCreatedEnabled: transactionCreatedEnabled ?? this.transactionCreatedEnabled,
    recurringActivationEnabled: recurringActivationEnabled ?? this.recurringActivationEnabled,
    limitWarningEnabled: limitWarningEnabled ?? this.limitWarningEnabled,
    limitExceededEnabled: limitExceededEnabled ?? this.limitExceededEnabled,
  );
}
```

Update `NativeBridge.ExpenseSettingsPayload`, `expenseLoadSettings`, and add:

```dart
Future<NotificationSettings> expenseUpdateNotificationSettings(
  NotificationSettings settings,
) async {
  final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'expenseUpdateNotificationSettings',
    settings.toMap(),
  );
  return NotificationSettings.fromMap(map);
}
```

Create `notification_settings_panel.dart` with `SettingsSection` rows and Switch controls for the six settings. Each switch calls `onChanged(settings.copyWith(field: value))`.

- [ ] **Step 8: Wire settings page and run tests**

In `SettingsPage`, add `_SettingsMenu.notifications`, replace the const notification section with a tappable row, and route submenu:

```dart
SettingsSection(
  title: 'Értesítési beállítások',
  children: [
    SettingsOptionItem(
      title: 'Részletes értesítési beállítások',
      subtitle: 'Push, in-app, tranzakció, ismétlődő és limit riasztások',
      onTap: () => _open(_SettingsMenu.notifications),
      isLast: true,
    ),
  ],
),
```

Submenu body:

```dart
_SettingsMenu.notifications => NotificationSettingsPanel(
  settings: _settingsStore.notificationSettings,
  onChanged: _settingsStore.updateNotificationSettings,
),
```

Title:

```dart
_SettingsMenu.notifications => 'Értesítési beállítások',
```

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.expense.ExpenseSettingsStoreNotificationTest' --tests 'com.exptv2.app.expense.ExpenseRepositoryMerchantCategoryTest.updateTransactionDoesNotCreateLimitNotificationCard' --tests 'com.exptv2.app.expense.ExpenseNotificationCardFactoryTest'
flutter test test/settings/settings_store_test.dart test/settings/settings_page_test.dart
```

Expected: PASS.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense android/app/src/test/kotlin/com/exptv2/app/expense lib/services/native_bridge.dart lib/features/settings test/settings
git commit -m "Add notification settings and suppress edit alerts"
```

---

### Task 5: Two-Way Push Message and Transaction UI Navigation

**Files:**
- Modify: `test/settings/push_notification_log_page_test.dart`
- Modify: `test/settings/push_notification_log_store_test.dart`
- Modify: `test/transactions/transaction_widgets_test.dart`
- Modify: `lib/features/settings/state/push_notification_log_store.dart`
- Modify: `lib/features/settings/widgets/push_log/push_notification_event_sheet.dart`
- Modify: `lib/features/settings/widgets/push_log/push_notification_log_page.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/shell/expt_shell.dart`

- [ ] **Step 1: Write failing push sheet button test**

In `test/settings/push_notification_log_page_test.dart`, make one loaded row linked, tap it, and assert the new button calls a captured id:

```dart
testWidgets('linked event sheet can request opening transaction', (tester) async {
  int? openedTransactionId;
  await tester.pumpWidget(buildSubject(onOpenTransaction: (id) {
    openedTransactionId = id;
  }));
  await tester.pumpAndSettle();

  await tester.drag(
    find.byKey(const ValueKey('push-notification-log-list')),
    const Offset(0, -500),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('push-logbox-90')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('push-event-open-transaction')), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('push-event-open-transaction')));
  await tester.pumpAndSettle();

  expect(openedTransactionId, 26060702);
})
```

Update `buildSubject` to accept `ValueChanged<int>? onOpenTransaction` and pass it into `PushNotificationLogPage`.

- [ ] **Step 2: Write failing edit sheet button test**

In `test/transactions/transaction_widgets_test.dart`, add a test that builds `AddTransactionSheet` with an initial transaction whose `sourceNotificationEventId` is 77 and asserts `transaction-open-notification-event` button calls the callback with that transaction.

Expected assertion:

```dart
expect(find.byKey(const ValueKey('transaction-open-notification-event')), findsOneWidget);
await tester.tap(find.byKey(const ValueKey('transaction-open-notification-event')));
expect(openedEventForTransaction?.id, initial.id);
```

- [ ] **Step 3: Add callback props and UI actions**

In `PushNotificationEventSheet`, add:

```dart
final ValueChanged<int>? onOpenTransaction;
```

In the linked branch, after `Kapcsolt log`, add:

```dart
const SizedBox(height: 12),
FilledButton.icon(
  key: const ValueKey('push-event-open-transaction'),
  onPressed: event.linkedTransactionId == null
      ? null
      : () {
          final id = event.linkedTransactionId;
          if (id == null) return;
          Navigator.of(context).pop();
          widget.onOpenTransaction?.call(id);
        },
  icon: const Icon(Icons.open_in_new, size: 18),
  label: const Text('Ugrás a tranzakcióhoz'),
),
```

In `PushNotificationLogPage`, add constructor prop:

```dart
final ValueChanged<int>? onOpenTransaction;
```

Pass it into the sheet.

In `AddTransactionSheet`, add:

```dart
final ValueChanged<TransactionRecord>? onOpenNotificationEvent;
```

Before the save button, show this only for edit transactions where a linked event can be resolved:

```dart
if (_editing) ...[
  const SizedBox(height: 8),
  OutlinedButton.icon(
    key: const ValueKey('transaction-open-notification-event'),
    onPressed: widget.initialTransaction == null
        ? null
        : () => widget.onOpenNotificationEvent?.call(widget.initialTransaction!),
    icon: const Icon(Icons.notifications_active, size: 18),
    label: const Text('Ugrás az üzenethez'),
  ),
],
```

- [ ] **Step 4: Add single-event load to push log store**

In `PushNotificationLogStore`, add:

```dart
Future<PushNotificationLogEvent?> loadEvent(int id) {
  return _bridge.loadNotificationEvent(id);
}
```

- [ ] **Step 5: Wire shell callbacks**

In `SettingsPage`, add:

```dart
final ValueChanged<int>? onOpenTransactionFromPush;
```

Pass it to `PushNotificationLogPage`:

```dart
onOpenTransaction: widget.onOpenTransactionFromPush,
```

In `_ShellSheetHost`, pass `nativeBridge`, `parserStore`, and callbacks into `_TransactionSheetSlot`.

In `ExptShell`, add:

```dart
Future<void> _openTransactionFromPush(int transactionId) async {
  final requestedAt = DateTime.now();
  final transaction = await widget.nativeBridge.expenseGetTransaction(transactionId);
  if (!mounted) return;
  if (_activeTab != AppTab.home) {
    setState(() => _activeTab = AppTab.home);
    widget.store.setShellActiveTabKey(AppTab.home.id);
    _jumpToTabPage(AppTab.home, requestedAt);
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _sheetHostKey.currentState?.openTransaction(
      requestedAt: requestedAt,
      source: 'push-log-jump',
      transaction: transaction,
    );
  });
}

Future<void> _openPushEventFromTransaction(TransactionRecord transaction) async {
  final requestedAt = DateTime.now();
  final eventId = transaction.sourceNotificationEventId ??
      await widget.nativeBridge.expenseNotificationEventIdForTransaction(transaction.id);
  if (eventId == null || !mounted) return;
  final event = await widget.nativeBridge.loadNotificationEvent(eventId);
  if (event == null || !mounted) return;
  _sheetHostKey.currentState?.closeAll();
  final logStore = PushNotificationLogStore(
    bridge: widget.nativeBridge,
    parserStore: widget.store,
  );
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (context) => PushNotificationEventSheet(
      event: event,
      parserStore: widget.store,
      logStore: logStore,
      onOpenTransaction: (id) => unawaited(_openTransactionFromPush(id)),
    ),
  );
  logStore.dispose();
  DebugConsole.log('[PushLog] transaction jump event=$eventId elapsed=${_elapsedMs(requestedAt)}ms');
}
```

Add the needed imports in `expt_shell.dart`:

```dart
import '../settings/state/push_notification_log_store.dart';
import '../settings/widgets/push_log/push_notification_event_sheet.dart';
```

- [ ] **Step 6: Hide edit jump button when no event exists**

Before opening the edit sheet, the button can be visible for `sourceNotificationEventId != null`. For recurring-linked older rows, `_openPushEventFromTransaction` resolves via native API after tap. If the direct id is null, still show the button when the row is recurring-generated:

```dart
bool get _canOpenNotificationEvent {
  final transaction = widget.initialTransaction;
  if (transaction == null) return false;
  return transaction.sourceNotificationEventId != null || transaction.isRecurringGenerated;
}
```

Use `_canOpenNotificationEvent` for button visibility.

- [ ] **Step 7: Run Flutter tests and commit**

Run:

```bash
flutter test test/settings/push_notification_log_page_test.dart test/settings/push_notification_log_store_test.dart test/transactions/transaction_widgets_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/features/settings lib/features/transactions/widgets/add_transaction_sheet.dart lib/features/shell/expt_shell.dart test/settings test/transactions
git commit -m "Add push and transaction jump actions"
```

---

### Task 6: Backheader Background Color

**Files:**
- Modify: `test/transactions/category_budget_stage_test.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`

- [ ] **Step 1: Write failing background color test**

In `test/transactions/category_budget_stage_test.dart`, add:

```dart
testWidgets('classic backheader uses provided background color', (tester) async {
  const background = Color(0xFFFFFFFF);
  await tester.pumpWidget(
    MaterialApp(
      home: CategoryBudgetStage(
        backgroundColor: background,
        items: <BackheaderBudgetItem>[
          BackheaderBudgetItem.overview(overviewFixture(BudgetGoalKind.expenseBudget, 5000, 10000)),
        ],
        categoryBars: const <CategoryBudgetBarData>[],
      ),
    ),
  );

  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(const ValueKey('category-budget-stage')),
      matching: find.byType(DecoratedBox),
    ).first,
  );
  final decoration = box.decoration as BoxDecoration;
  expect(decoration.color, background);
});
```

Use the existing `overviewFixture()` helper already defined near the bottom of `category_budget_stage_test.dart`.

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart --plain-name 'classic backheader uses provided background color'
```

Expected: FAIL because the constructor has no `backgroundColor` parameter and the component uses `AppColors.gray100`.

- [ ] **Step 3: Add background color props**

In `CategoryBudgetStage`, add constructor/default field:

```dart
this.backgroundColor = AppColors.gray100,
```

and:

```dart
final Color backgroundColor;
```

Replace classic background `color: AppColors.gray100` with:

```dart
color: widget.backgroundColor,
```

Pass to `BackheaderStyleSurface`:

```dart
backgroundColor: widget.backgroundColor,
```

In `BackheaderStyleSurface`, add:

```dart
required this.backgroundColor,
final Color backgroundColor;
```

Change `_background`:

```dart
Color _background(Color color) => switch (style) {
  BackheaderStyle.orbitBudget => color,
  _ => backgroundColor,
};
```

- [ ] **Step 4: Pass theme background from Home**

In `TransactionHomePage`, add to `CategoryBudgetStage` call:

```dart
backgroundColor: expenseTheme.appBackground,
```

- [ ] **Step 5: Run tests and commit**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart test/transactions/header_card_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/header_card/category_budget_stage.dart lib/features/transactions/widgets/header_card/backheader_style_surface.dart lib/features/transactions/transaction_home_page.dart test/transactions/category_budget_stage_test.dart
git commit -m "Use theme background for backheader"
```

---

### Task 7: Integration Verification and Push

**Files:**
- No new source files unless previous tasks require test expectation updates.

- [ ] **Step 1: Run native regression tests**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --tests 'com.exptv2.app.NotificationEventRepositoryTest' --tests 'com.exptv2.app.expense.ExpenseRepositoryMerchantCategoryTest' --tests 'com.exptv2.app.expense.PushRecurringParserTest' --tests 'com.exptv2.app.expense.PushRecurringMatcherTest' --tests 'com.exptv2.app.expense.ExpenseNotificationCardFactoryTest' --tests 'com.exptv2.app.expense.ExpenseSettingsStoreNotificationTest'
```

Expected: PASS.

- [ ] **Step 2: Run Flutter focused regression tests**

Run:

```bash
flutter test test/settings/push_notification_log_page_test.dart test/settings/push_notification_log_store_test.dart test/settings/settings_page_test.dart test/settings/settings_store_test.dart test/settings/notification_parser_rule_test.dart test/transactions/transaction_widgets_test.dart test/transactions/category_budget_stage_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run analyzer**

Run:

```bash
flutter analyze
```

Expected: no new errors. Existing warnings must be listed in the final response if they are unrelated and pre-existing.

- [ ] **Step 4: Check git history and working tree**

Run:

```bash
git status --short --branch
git log --oneline -8
```

Expected: clean working tree, branch `main` ahead of `origin/main` by the new commits.

- [ ] **Step 5: Push main**

Run:

```bash
git push origin main
```

Expected: push succeeds. Flutter APK builds must run through GitHub Actions or other online CI; do not run a local Flutter APK build in Termux.

