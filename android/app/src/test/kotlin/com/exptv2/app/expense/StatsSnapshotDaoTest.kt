package com.exptv2.app.expense

import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class StatsSnapshotDaoTest {
    private lateinit var database: ExpenseTrackerDatabase
    private lateinit var dao: StatsSnapshotDao

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(
            context,
            ExpenseTrackerDatabase::class.java,
        ).allowMainThreadQueries().build()
        dao = database.statsSnapshots()
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun upsertReplacesNormalizedScopesAndListsDeterministically() = runBlocking {
        dao.upsert(
            snapshot = snapshot(id = "later", createdAt = 2000),
            categoryScopeIds = listOf(9, 2),
            vendorScopeNames = listOf("Tesco", "Aldi"),
        )
        dao.upsert(
            snapshot = snapshot(id = "earlier", createdAt = 1000),
            categoryScopeIds = listOf(3, 1),
            vendorScopeNames = listOf("Spar", "Auchan"),
        )
        dao.upsert(
            snapshot = snapshot(id = "later", createdAt = 2000, updatedAt = 3000),
            categoryScopeIds = listOf(7),
            vendorScopeNames = listOf("Lidl"),
        )

        val rows = dao.list()

        assertEquals(listOf("earlier", "later"), rows.map { it.snapshot.id })
        assertEquals(listOf(1, 3), rows[0].categoryScopeIds)
        assertEquals(listOf("Auchan", "Spar"), rows[0].vendorScopeNames)
        assertEquals(listOf(7), rows[1].categoryScopeIds)
        assertEquals(listOf("Lidl"), rows[1].vendorScopeNames)
        assertEquals(3000L, rows[1].snapshot.updatedAt)
    }

    private fun snapshot(
        id: String,
        createdAt: Long,
        updatedAt: Long = createdAt,
    ) = StatsSnapshotEntity(
        id = id,
        name = "Mentett nezet",
        createdAt = createdAt,
        updatedAt = updatedAt,
        includeCategoryScope = true,
        includeVendorScope = true,
        includeActiveType = true,
        includeThreshold = true,
        includeLayoutMode = true,
        includePageIndex = true,
        activeType = "expense",
        threshold = 15000.0,
        layoutMode = "month",
        activeYear = 2026,
        activeMonth = 7,
        pageIndex = 1,
    )
}
