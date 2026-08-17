package com.fluvi.core.usecase

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.database.entity.FluviCategoryEntity
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviFinancialLimitKey
import com.fluvi.core.model.FluviFinancialLimitPeriod
import com.fluvi.core.model.FluviFinancialLimitTarget
import com.fluvi.core.model.LedgerDirection
import com.fluvi.core.repository.FluviCoreRevisionRepository
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviFinancialLimitUseCaseTest {
    private lateinit var database: FluviDatabase
    private lateinit var limits: FluviFinancialLimitUseCase
    private lateinit var revisions: FluviCoreRevisionRepository

    @Before
    fun setUp() {
        database = FluviDatabaseFactory.createInMemory(
            ApplicationProvider.getApplicationContext<Context>(),
            FluviClock { 1_700_000_000_000L },
        )
        limits = FluviFinancialLimitUseCase(
            database = database,
            clock = FluviClock { 1_700_000_000_000L },
        )
        revisions = FluviCoreRevisionRepository(database)
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun missingLimitAndPersistedZeroAreDistinctAndWritesAdvanceOneRevision() = runBlocking {
        val key = FluviFinancialLimitKey(
            direction = LedgerDirection.expense,
            target = FluviFinancialLimitTarget.Aggregate,
            period = FluviFinancialLimitPeriod.Sum,
        )
        val initialRevision = revisions.current()

        assertNull(limits.get(key))
        limits.upsert(key, 0L)
        assertEquals(0L, limits.get(key)?.amountScaled100)
        assertEquals(initialRevision + 1L, revisions.current())

        // Same value is a no-op and does not churn the exact prepared revision.
        limits.upsert(key, 0L)
        assertEquals(initialRevision + 1L, revisions.current())

        limits.upsert(key, 120_000L * 100L)
        assertEquals(initialRevision + 2L, revisions.current())
        assertTrue(limits.delete(key))
        assertEquals(initialRevision + 3L, revisions.current())
        assertFalse(limits.delete(key))
        assertNull(limits.get(key))
    }

    @Test
    fun categoryLimitCascadesOnCategoryDeleteWhileAggregateSurvives() = runBlocking {
        val category = FluviCategoryEntity(
            id = "financial-limit-category",
            name = "Financial limit category",
            colorId = "color_01",
            iconId = "icon_01",
            isSystemUncategorized = false,
            createdAtUtcMs = 1L,
            updatedAtUtcMs = 1L,
        )
        database.categoryDao().insert(category)
        val aggregate = FluviFinancialLimitKey(
            direction = LedgerDirection.expense,
            target = FluviFinancialLimitTarget.Aggregate,
            period = FluviFinancialLimitPeriod.Month(2026, 7),
        )
        val categoryKey = FluviFinancialLimitKey(
            direction = LedgerDirection.expense,
            target = FluviFinancialLimitTarget.Category(category.id),
            period = FluviFinancialLimitPeriod.Month(2026, 7),
        )
        limits.upsert(aggregate, 100L)
        limits.upsert(categoryKey, 200L)

        database.categoryDao().delete(category.id)

        assertEquals(100L, limits.get(aggregate)?.amountScaled100)
        assertNull(limits.get(categoryKey))
    }
}
