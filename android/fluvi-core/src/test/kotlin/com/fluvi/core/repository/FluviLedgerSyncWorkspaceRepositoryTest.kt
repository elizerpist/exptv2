package com.fluvi.core.repository

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviLedgerSyncWorkspaceRepositoryTest {
    private lateinit var database: FluviDatabase
    private lateinit var workspaces: FluviLedgerSyncWorkspaceRepository

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(
            context = context,
            clock = FluviClock { 1_700_000_000_000L },
        )
        workspaces = FluviLedgerSyncWorkspaceRepository(
            database = database,
            idGenerator = IncrementingIds(),
            clock = FluviClock { 1_700_000_000_000L },
        )
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun oneWorkspaceIsMappedPerBookingYearWithoutCreatingASecondIdentity() = runBlocking {
        val first = workspaces.assign(2025, "sheet-2025")
        val updated = workspaces.assign(2025, "replacement-sheet-2025")
        val nextYear = workspaces.assign(2026, "sheet-2026")

        assertEquals(first.id, updated.id)
        assertEquals("replacement-sheet-2025", workspaces.find(2025)?.workspaceIdentifier)
        assertNotEquals(first.id, nextYear.id)
    }

    private class IncrementingIds : FluviIdGenerator {
        private var nextValue = 1L

        override fun next(): String = nextValue++.toString().padStart(26, '0')
    }
}
