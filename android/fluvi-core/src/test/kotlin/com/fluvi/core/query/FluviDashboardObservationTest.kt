package com.fluvi.core.query

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.FluviCore
import com.fluvi.core.FluviCoreFactory
import com.fluvi.core.model.LedgerDirection
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class FluviDashboardObservationTest {
    private lateinit var core: FluviCore

    @Before
    fun setUp() {
        core = FluviCoreFactory.createInMemory(
            ApplicationProvider.getApplicationContext<Context>(),
        )
    }

    @After
    fun tearDown() {
        core.close()
    }

    @Test
    fun sliceUsesOneScopeForTotalAndStableLedgerPage() = runBlocking {
        core.demoSeed.seed()
        val scope = monthScope(LedgerDirection.expense, 7)

        val slice = core.query.readSlice(scope, pageSize = 50)

        assertEquals("expense|month:2026-07|categories:|partners:|refinements:", slice.queryKey)
        assertEquals(100, slice.entryCount)
        assertEquals(689_000L * 100L, slice.totalMinor)
        assertEquals(50, slice.entries.size)
        assertNotNull(slice.nextCursor)
        assertTrue(slice.entries.all { it.categoryColorId.startsWith("color_") })
        assertTrue(slice.entries.all { it.categoryIconId.startsWith("icon_") })
        assertTrue(slice.entries.zipWithNext().all { (left, right) ->
            left.bookedLocalEpochDay >= right.bookedLocalEpochDay
        })
    }

    @Test
    fun revisionObserverEmitsTheUpdatedSliceAfterSeed() = runBlocking {
        val scope = monthScope(LedgerDirection.income, 7)
        val observer = async {
            core.query.observeSlice(scope, pageSize = 50).first {
                it.entryCount == 6L
            }
        }
        core.demoSeed.seed()

        val emission = observer.await()

        assertEquals(100, emission.entryCount)
        assertEquals(707_000L * 100L, emission.totalMinor)
        assertTrue(emission.coreRevision > 0L)
    }

    private fun monthScope(direction: LedgerDirection, month: Int): FluviQueryScope =
        FluviQueryScope(
            direction = direction,
            periodGroups = listOf(
                FluviPeriodGroup(
                    key = "time",
                    selections = setOf(
                        FluviPeriodSelection.month(
                            "2026-${month.toString().padStart(2, '0')}",
                        ),
                    ),
                ),
            ),
        )
}
