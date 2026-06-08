# Merchant Category Propagation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce "same original merchant, same category" for manual edits and future push/parser-created transactions.

**Architecture:** Keep the existing `transactions` table as the source of truth. Add focused DAO queries that read and update category by original `merchant`, then call them from `ExpenseRepository.addTransaction`, `ExpenseRepository.updateTransaction`, and push parser transaction creation. Flutter keeps its current reload-after-save behavior.

**Tech Stack:** Flutter/Dart state and bridge tests, Android Kotlin Room DAO/repository, GitHub Actions for full Flutter/Android verification.

---

### Task 1: Add Native Regression Tests

**Files:**
- Create: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseRepositoryMerchantCategoryTest.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`

- [ ] **Step 1: Write the failing native repository tests**

Create `ExpenseRepositoryMerchantCategoryTest.kt` with tests that use the real Room database singleton and repository. The test sets the demo seed version to avoid seed reset, clears tables, inserts fixture categories and transactions, then calls repository methods.

```kotlin
package com.exptv2.app.expense

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

class ExpenseRepositoryMerchantCategoryTest {
    private lateinit var context: Context
    private lateinit var db: ExpenseTrackerDatabase
    private lateinit var repository: ExpenseRepository

    @Before
    fun setUp() = runBlocking {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences("expense_seed", Context.MODE_PRIVATE)
            .edit()
            .putInt("demo_seed_version", ExpenseSeedData.version)
            .commit()
        db = ExpenseTrackerDatabase.get(context)
        db.notificationCards().clearAllHard()
        db.recurringRuleInstances().clearAll()
        db.recurringRules().clearAll()
        db.recurringGhostTransactions().clearAll()
        db.recurringTransactions().clearAll()
        db.transactions().clearAll()
        db.categoryLimits().clearAll()
        db.categories().clearAll()
        db.categories().insertAll(testCategories())
        repository = ExpenseRepository(context)
    }

    @Test
    fun updateTransactionPropagatesCategoryToSameOriginalMerchant() = runBlocking {
        db.transactions().insertAll(
            listOf(
                transaction(id = 260101, merchant = "nyírő", categoryId = 6),
                transaction(id = 260102, merchant = "nyírő", categoryId = null),
                transaction(id = 260103, merchant = "másik", categoryId = null),
            ),
        )

        repository.updateTransaction(
            mapOf(
                "id" to 260101,
                "merchant" to "nyírő",
                "amount" to 3085.0,
                "type" to "expense",
                "transactionCategoryID" to 7,
                "date" to "2026-01-01",
                "time" to "10:00",
            ),
        )

        assertEquals(7, db.transactions().byId(260101)?.transactionCategoryID)
        assertEquals(7, db.transactions().byId(260102)?.transactionCategoryID)
        assertNull(db.transactions().byId(260103)?.transactionCategoryID)
    }

    @Test
    fun addTransactionInheritsCategoryFromSameOriginalMerchant() = runBlocking {
        db.transactions().insert(transaction(id = 260101, merchant = "nyírő", categoryId = 7))

        val saved = repository.addTransaction(
            mapOf(
                "merchant" to "nyírő",
                "amount" to 4500.0,
                "type" to "expense",
                "date" to "2026-01-02",
                "time" to "11:00",
            ),
        )

        assertEquals(7, saved["transactionCategoryID"])
    }

    @Test
    fun addTransactionWithoutMerchantMemoryStaysUncategorized() = runBlocking {
        db.transactions().insert(transaction(id = 260101, merchant = "másik", categoryId = 7))

        val saved = repository.addTransaction(
            mapOf(
                "merchant" to "új bolt",
                "amount" to 1200.0,
                "type" to "expense",
                "date" to "2026-01-02",
                "time" to "11:00",
            ),
        )

        assertNull(saved["transactionCategoryID"])
    }

    private fun testCategories(): List<TransactionCategoryEntity> = listOf(
        TransactionCategoryEntity(6, "Egyéb", "kiadás", 0, 0, "#64748b", null, null, false, 0.0, false, true, null),
        TransactionCategoryEntity(7, "Étterem", "kiadás", 1, 1, "#ef4444", null, null, false, 0.0, false, true, null),
    )

    private fun transaction(id: Int, merchant: String, categoryId: Int?): ExpenseTransactionEntity =
        ExpenseTransactionEntity(
            id = id,
            date = "2026.01.01",
            time = "10:00",
            latitude = null,
            longitude = null,
            address = "Test",
            merchant = merchant,
            amount = -1000.0,
            userAssignedName = null,
            transactionCategoryID = categoryId,
        )
}
```

- [ ] **Step 2: Run the targeted Kotlin test**

Run:

```bash
./gradlew testDebugUnitTest --tests com.exptv2.app.expense.ExpenseRepositoryMerchantCategoryTest
```

Expected before implementation: FAIL because `latestCategoryIdForMerchant` and `updateCategoryByMerchant` do not exist or repository does not propagate/inherit categories yet. In this Termux checkout, `./gradlew` is not present; record that and use GitHub Actions for the executable red/green signal.

- [ ] **Step 3: Commit failing tests if they compile locally**

When local test execution is unavailable, keep the test changes staged with implementation and verify in CI before the final commit. If local test execution is available and the failing test compiles, commit the red test:

```bash
git add android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseRepositoryMerchantCategoryTest.kt
git commit -m "test: cover merchant category propagation"
```

### Task 2: Add DAO Queries

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`

- [ ] **Step 1: Add merchant category lookup and propagation DAO methods**

Add these methods near the existing merchant rename queries:

```kotlin
@Query(
    """
    SELECT transactionCategoryID FROM transactions
    WHERE TRIM(merchant) = TRIM(:merchant)
      AND transactionCategoryID IS NOT NULL
    ORDER BY date DESC, time DESC, id DESC
    LIMIT 1
    """
)
suspend fun latestCategoryIdForMerchant(merchant: String): Int?

@Query(
    """
    UPDATE transactions
    SET transactionCategoryID = :categoryId
    WHERE TRIM(merchant) = TRIM(:merchant)
    """
)
suspend fun updateCategoryByMerchant(merchant: String, categoryId: Int): Int
```

- [ ] **Step 2: Run Kotlin/Android tests if available**

Run:

```bash
./gradlew testDebugUnitTest
```

Expected in CI-capable environments: compile passes. In this repo on Termux, `./gradlew` is not present; record that and rely on GitHub Actions.

- [ ] **Step 3: Commit DAO changes**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt
git commit -m "feat: add merchant category dao queries"
```

### Task 3: Implement Repository Propagation

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`

- [ ] **Step 1: Add helper functions near transaction methods**

Add focused helpers:

```kotlin
private suspend fun inheritedCategoryIdForMerchant(merchant: String, explicitCategoryId: Int?): Int? {
    if (explicitCategoryId != null) return explicitCategoryId
    val key = merchant.trim()
    if (key.isEmpty()) return null
    val inherited = transactions.latestCategoryIdForMerchant(key)
    Log.d("ExpenseRepository", "[MerchantCategory] inherit merchant=$key category=$inherited")
    return inherited
}

private suspend fun propagateCategoryForMerchant(merchant: String, categoryId: Int): Int {
    val key = merchant.trim()
    if (key.isEmpty()) return 0
    val count = transactions.updateCategoryByMerchant(key, categoryId)
    Log.d("ExpenseRepository", "[MerchantCategory] propagate merchant=$key category=$categoryId rows=$count")
    return count
}
```

- [ ] **Step 2: Update manual `addTransaction`**

Replace category resolution with inherited category support:

```kotlin
val requestedCategoryId = optionalInt(args["transactionCategoryID"])
val categoryId = inheritedCategoryIdForMerchant(merchant, requestedCategoryId)
val category = categoryId?.let { id ->
    categories.byId(id)
        ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")
}
```

Keep the row assignment:

```kotlin
transactionCategoryID = categoryId,
```

- [ ] **Step 3: Update manual `updateTransaction`**

After the updated row is inserted and limit alert evaluation remains intact, propagate category only for non-null category changes:

```kotlin
val originalMerchantKey = existing.merchant.trim()
val categoryChanged = row.transactionCategoryID != null &&
    row.transactionCategoryID != existing.transactionCategoryID
if (categoryChanged) {
    propagateCategoryForMerchant(originalMerchantKey, row.transactionCategoryID!!)
}
```

This uses the original merchant group even if the same edit changes the row merchant text.

- [ ] **Step 4: Run targeted checks**

Run:

```bash
git diff --check
```

Expected: no output, exit 0.

- [ ] **Step 5: Commit repository propagation**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt
git commit -m "feat: propagate categories by merchant"
```

### Task 4: Apply Inheritance to Push Parser Transactions

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`

- [ ] **Step 1: Update parser-created transaction category**

In `processNotificationEventForParserProfiles`, before constructing `ExpenseTransactionEntity`, resolve:

```kotlin
val categoryId = inheritedCategoryIdForMerchant(parsed.merchant, null)
```

Use it in the row:

```kotlin
transactionCategoryID = categoryId,
```

- [ ] **Step 2: Keep parser-created transactions uncategorized when no merchant memory exists**

No fallback category should be invented. If `categoryId` is null, the existing uncategorized avatar behavior remains valid.

- [ ] **Step 3: Add debug log detail**

Add category to the parser success log:

```kotlin
"category=$categoryId"
```

- [ ] **Step 4: Run syntax check**

Run:

```bash
git diff --check
```

Expected: no output, exit 0.

- [ ] **Step 5: Commit parser inheritance**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt
git commit -m "feat: inherit category for push parser transactions"
```

### Task 5: Verify and Publish

**Files:**
- No code file changes expected beyond previous tasks.

- [ ] **Step 1: Run local checks available in Termux**

Run:

```bash
git diff --check
command -v flutter
test -x ./gradlew
```

Expected: `git diff --check` passes. `flutter` and `./gradlew` may be unavailable in this environment; record the limitation.

- [ ] **Step 2: Push branch**

```bash
git push origin feature/push-log-parser-training-fixes
```

- [ ] **Step 3: Run GitHub Actions build**

```bash
gh workflow run 284214499 --ref feature/push-log-parser-training-fixes
RUN_ID=$(gh run list --workflow 284214499 --branch feature/push-log-parser-training-fixes --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch "$RUN_ID" --exit-status
```

Expected: analyzer, Flutter tests, debug APK build, and release publish all pass.

- [ ] **Step 4: Verify release asset**

```bash
gh release view debug-latest --json tagName,name,isDraft,isPrerelease,assets,url,publishedAt,targetCommitish
```

Expected: `exptv2-debug.apk` asset exists and has a fresh `updatedAt`.

- [ ] **Step 5: Final status**

Report:

- Branch name.
- Final commit.
- GitHub Actions run URL.
- APK direct link: `https://github.com/elizerpist/exptv2/releases/download/debug-latest/exptv2-debug.apk`
