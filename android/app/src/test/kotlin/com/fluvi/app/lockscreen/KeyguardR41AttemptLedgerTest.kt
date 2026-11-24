package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardR41AttemptLedgerTest {
    @Test fun outOfOrderBoundariesRemainBoundToTheSameWinningOwner() {
        val ledger = KeyguardR41AttemptLedger()
        ledger.record("WINNER", 12, 300, 4, 5)
        ledger.record("READ_END", 12, 180)
        ledger.record("GRANT", 12, 280, 4, 5)
        ledger.record("READ_START", 12, 120)
        ledger.record("OFFER", 12, 110)
        ledger.record("DISPATCH", 12, 200)
        ledger.record("MAIN", 12, 210)
        ledger.record("WAKE", null, 100)
        ledger.record("ELIGIBLE", null, 100)
        val row = ledger.core(1, 2, 3, 0)
        assertTrue(row, row.contains("owner=4/5/12 readOwner=4/5/12 dispatchOwner=4/5/12 grantOwner=4/5/12"))
        assertTrue(row, row.contains("outcome=SUCCESS"))
        assertTrue(row, row.contains("coverage=INCOMPLETE"))
    }

    @Test fun cancelledOrDifferentOwnerNeverBecomesTheWinner() {
        val different = KeyguardR41AttemptLedger()
        different.record("GRANT", 12, 200, 4, 5)
        different.record("WINNER", 12, 300, 4, 6)
        assertTrue(different.core(1, 1, 1, 0).contains("owner=UNOBSERVED"))
        val cancelled = KeyguardR41AttemptLedger()
        cancelled.record("GRANT", 12, 200, 4, 5)
        cancelled.record("CANCEL", 12, 250)
        cancelled.record("WINNER", 12, 300, 4, 5)
        assertTrue(cancelled.core(1, 1, 1, 0).contains("outcome=CANCELLED"))
    }

    @Test fun capacityLossAndConflictsAreExplicitAndSnapshotsAreIndependent() {
        val ledger = KeyguardR41AttemptLedger()
        ledger.record("WAKE", null, 100)
        repeat(17) { ledger.record("READ_START", it.toLong(), 200 + it.toLong()) }
        ledger.record("READ_START", 0, 999)
        val frozen = ledger.snapshot()
        ledger.record("WAKE", null, 101)
        assertEquals(1L, frozen.omitted)
        assertEquals(1L, frozen.invalid)
        assertEquals(100L, frozen.wakeNs)
        assertTrue(frozen.core(1, 1, 1, 0).contains("omitted=1 invalid=1 dropped=2"))
        assertEquals(16, frozen.requestRows(1).size)
    }

    @Test fun shadowMatchesDoNotClaimOrEnableTheH2Intervention() {
        val ledger = KeyguardR41AttemptLedger()
        ledger.record("ORDERED_SHADOW_OFFER", 7, 100, 8, 15)
        ledger.record("ORDERED_SHADOW_OFFER", 7, 101, 9, 3)
        val frozen = ledger.snapshot()
        val row = frozen.core(1, 1, 1, 0)
        assertTrue(row, row.contains("h2ShadowOffers=2 h2PartialMatches=1"))
        assertTrue(row, row.contains("h2LastRequest=9 h2LastFlags=3 h2Claims=0 h2Enabled=false"))
        assertTrue(row, row.contains("h2ShadowCoverage=partialGuardsDispatchUnverified"))
        ledger.record("ORDERED_SHADOW_OFFER", 7, 102, 10, 15)
        assertEquals(2L, frozen.shadowOffers)
    }
}
