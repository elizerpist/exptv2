package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

/** Queue/policy controls only; actual Android route ownership is checked by
 * separate service instrumentation, never inferred from these scalar cases. */
class KeyguardR26OpeningRoutePolicyTest {
    private fun request(id: Long) = KeyguardCardInspectionRequest(
        id = id, trigger = "window", session = 1, visibilityEpoch = 1,
        interactionEpoch = 1, attachGeneration = 1, wakeGeneration = 1, queuedAtUptimeMs = id,
    )
    private fun choose(backend: String, withPending: Boolean): Triple<String, KeyguardCardInspectionQueue, KeyguardOpeningPublication<String>> {
        val q = KeyguardCardInspectionQueue(); val p = KeyguardOpeningPublication<String>()
        val a = request(1); val b = request(2)
        assertTrue(q.offer(a))
        if (withPending) assertFalse(q.offer(b))
        val outcome = if (!KeyguardOpeningRoutePolicy.useCompletedHandoff(backend)) "ORDERED"
            else if (withPending) { assertEquals(b, q.handoffCompleted(a, b)); "PROMOTED" }
            else { assertNotNull(p.park(q, a, "a")); "PARKED" }
        return Triple(outcome, q, p)
    }
    @Test fun directWithAlreadyPendingBRemainsOrderedUntilMainCompletesA() {
        val (choice, q) = choose("R18_DIRECT", true)
        assertEquals("ORDERED", choice)
        assertEquals(request(1), q.activeRequest())
        assertEquals(request(2), q.pendingRequest())
        assertEquals(request(2), q.complete(request(1)))
        assertEquals(request(2), q.activeRequest())
    }
    @Test fun stableDirectAndBLaterRemainOrdered() {
        val (choice, q) = choose("R18_DIRECT", false)
        assertEquals("ORDERED", choice)
        assertFalse(q.offer(request(2)))
        assertEquals(request(1), q.activeRequest())
        assertEquals(request(2), q.complete(request(1)))
    }
    @Test fun stockStillPromotesTheActualPendingOwner() {
        val (choice, q) = choose("STOCK", true)
        assertEquals("PROMOTED", choice)
        assertEquals(request(2), q.activeRequest())
    }
    @Test fun stockStableStillParksAndClaimsOnce() {
        val (choice, q, p) = choose("STOCK", false)
        assertEquals("PARKED", choice)
        assertEquals(request(1), p.waitingRequest())
        assertEquals(request(1), q.activeRequest())
    }
    @Test fun unknownRouteDoesNotEnterThePositiveHandoff() {
        assertFalse(KeyguardOpeningRoutePolicy.useCompletedHandoff("UNKNOWN"))
    }
}
