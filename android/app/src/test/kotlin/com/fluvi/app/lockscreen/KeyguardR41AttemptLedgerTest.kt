package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardR41AttemptLedgerTest {
    @Test fun emptyAttemptKeepsIdentityLossAndUnknownEndpointsInACompactCore() {
        val row = KeyguardR41AttemptLedger().core(8, 9, 10, 3)
        assertTrue(row, row.contains("attempt=8 session=9 wake=10 systemEligible=UNOBSERVED eligible=UNOBSERVED"))
        assertTrue(row, row.contains("outcome=UNOBSERVED owner=UNOBSERVED"))
        assertTrue(row, row.contains("wakeNs=UNOBSERVED screenNs=UNOBSERVED grantNs=UNOBSERVED"))
        assertTrue(row, row.contains("h2Claims=0 h2Enabled=false fallbackGrant=UNOBSERVED"))
        assertTrue(row, row.contains("omitted=0 invalid=0 dropped=3 coverage=INCOMPLETE"))
        assertFalse(row, row.contains("outcome=SUCCESS"))
    }
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
        repeat(33) { ledger.record("READ_START", it.toLong(), 200 + it.toLong()) }
        ledger.record("READ_START", 0, 999)
        val frozen = ledger.snapshot()
        ledger.record("WAKE", null, 101)
        assertEquals(1L, frozen.omitted)
        assertEquals(1L, frozen.invalid)
        assertEquals(100L, frozen.wakeNs)
        assertTrue(frozen.core(1, 1, 1, 0).contains("omitted=1 invalid=1 dropped=2"))
        assertEquals(32, frozen.requestRows(1).size)
    }

    @Test fun aTwentyFiveRequestWakeRetainsEachOriginalOfferAndRead() {
        val ledger = KeyguardR41AttemptLedger()
        ledger.record("WAKE", null, 100)
        for (id in 1L..25L) ledger.record("OFFER", id, 200 + id)
        ledger.record("READ_START", 1, 300)
        ledger.record("READ_END", 1, 400)
        ledger.record("READ_START", 25, 500)
        ledger.record("READ_END", 25, 600)
        val frozen = ledger.snapshot()
        val rows = frozen.requestRows(1)
        assertEquals(0L, frozen.omitted)
        assertEquals(25, rows.size)
        for (id in 1L..25L) assertEquals("request $id", 1, rows.count { it.contains("req=$id ") })
        assertTrue(rows.single { it.contains("req=1 ") }.contains("read=300/400"))
        assertTrue(rows.single { it.contains("req=25 ") }.contains("read=500/600"))
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

    @Test fun pendingOfferBurstCannotEvictTheRealWinningRequest() {
        val ledger = KeyguardR41AttemptLedger()
        ledger.record("WAKE", null, 1)
        ledger.record("ELIGIBLE", null, 2)
        ledger.record("OFFER", 1, 10)
        ledger.record("WORKER_START", 1, 11)
        for (id in 2L..75L) ledger.record("OFFER", id, 10 + id)
        ledger.record("WORKER_START", 75, 100)
        ledger.record("READ_START", 75, 110)
        ledger.record("READ_END", 75, 120)
        ledger.record("DISPATCH", 75, 130)
        ledger.record("MAIN", 75, 140)
        ledger.record("GRANT", 75, 150, 4, 5)
        ledger.record("WINNER", 75, 160, 4, 5)
        val row = ledger.core(1, 1, 1, 0)
        assertTrue(row, row.contains("owner=4/5/75"))
        assertTrue(row, row.contains("outcome=SUCCESS"))
        assertTrue(row, row.contains("coverage=INCOMPLETE"))
        assertTrue("evicted offers must remain explicit", ledger.omitted > 0)
        assertTrue(ledger.requestRows(1).any { it.contains("req=1 ") })
        assertTrue(ledger.requestRows(1).any { it.contains("req=75 ") })
    }

    @Test fun systemEligibilityAloneNeverCertifiesAnEligibleOpening() {
        val ledger = KeyguardR41AttemptLedger()
        ledger.record("SYSTEM_ELIGIBLE", null, 100)
        val row = ledger.core(1, 1, 1, 0)
        assertTrue(row, row.contains("systemEligible=true eligible=UNOBSERVED"))
        ledger.record("ELIGIBLE", null, 200)
        assertTrue(ledger.core(1, 1, 1, 0).contains("systemEligible=true eligible=true"))
    }

    @Test fun fallbackReceiptRequiresTheSameShowAndNeverFabricatesAGrant() {
        val same = KeyguardR41AttemptLedger()
        same.record("FALLBACK_CANDIDATE", 20, 100, 30, 40)
        same.record("FALLBACK_POST_RECEIPT", 20, 200, 30, 50)
        val row = same.core(1, 1, 1, 0)
        assertTrue(row, row.contains("fallbackCandidateAndPostReceipt=20/30/40/50/100/200"))
        assertTrue(row, row.contains("fallbackGrant=UNOBSERVED"))
        assertTrue(row, row.contains("outcome=UNOBSERVED"))
        val different = KeyguardR41AttemptLedger()
        different.record("FALLBACK_CANDIDATE", 20, 100, 30, 40)
        different.record("FALLBACK_POST_RECEIPT", 20, 200, 31, 50)
        assertTrue(different.core(1, 1, 1, 0).contains("fallbackCandidateAndPostReceipt=UNOBSERVED"))
        // A DIRECT or otherwise unmatched receipt must not become a fallback
        // candidate or authorization merely because its callback was observed.
        val receiptOnly = KeyguardR41AttemptLedger()
        receiptOnly.record("FALLBACK_POST_RECEIPT", 20, 200, 30, 50)
        assertTrue(receiptOnly.core(1, 1, 1, 0).contains("fallbackCandidateAndPostReceipt=UNOBSERVED"))
        assertTrue(receiptOnly.core(1, 1, 1, 0).contains("fallbackGrant=UNOBSERVED"))
    }
}
