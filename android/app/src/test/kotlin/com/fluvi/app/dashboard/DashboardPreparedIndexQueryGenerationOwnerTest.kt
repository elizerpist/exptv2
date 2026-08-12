package com.fluvi.app.dashboard

import com.fluvi.core.model.LedgerDirection
import kotlinx.coroutines.Job
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class DashboardPreparedIndexQueryGenerationOwnerTest {
    @Test
    fun `newer generation cancels the older foreground Query job`() {
        val owner = DashboardPreparedIndexQueryGenerationOwner()
        val first = Job()
        owner.replace(
            DashboardPreparedIndexQueryGenerationOwner.Request(
                generation = 4L,
                direction = LedgerDirection.expense,
                job = first,
            ),
        )
        val second = Job()

        val superseded = owner.replace(
            DashboardPreparedIndexQueryGenerationOwner.Request(
                generation = 5L,
                direction = LedgerDirection.expense,
                job = second,
            ),
        )

        assertEquals(4L, superseded?.generation)
        assertTrue(first.isCancelled)
        assertFalse(second.isCancelled)
    }

    @Test
    fun `explicit cancellation only stops its exact active generation`() {
        val owner = DashboardPreparedIndexQueryGenerationOwner()
        val active = Job()
        owner.replace(
            DashboardPreparedIndexQueryGenerationOwner.Request(
                generation = 8L,
                direction = LedgerDirection.income,
                job = active,
            ),
        )

        assertNull(owner.cancel(7L))
        assertFalse(active.isCancelled)
        assertEquals(8L, owner.cancel(8L)?.generation)
        assertTrue(active.isCancelled)
    }
}
