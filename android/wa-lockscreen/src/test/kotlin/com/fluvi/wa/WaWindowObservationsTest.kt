package com.fluvi.wa

import android.view.Display
import java.io.IOException
import org.junit.Assert.*
import org.junit.Test

class WaWindowObservationsTest {
    private val owner = WaAttachment(123, 7, 12, 33, 56)
    private val product = WaUnlockProduct("com.fluvi.app", "a".repeat(40), "0.1.6", 8, "A142", 37)
    private fun at(ns: Long) = WaTime(ns / 1_000_000L, ns)
    private fun read(begin: Long, end: Long, locked: Boolean) =
        WaGateRead(at(begin), at(end), WaSystemState(Display.STATE_ON, true, locked))
    private fun draft(cause: WaWithdrawalCause, tick: Long, owner: WaAttachment = this.owner,
                      store: (WaUnlockRecord) -> Unit = {}): WaUnlockDraft {
        val reason = when (cause) {
            WaWithdrawalCause.APP_WINDOW_PRESENT -> WaHideReason.RESTRICTED
            WaWithdrawalCause.PUBLIC_NEGATIVE -> WaHideReason.UNLOCKED
            WaWithdrawalCause.USER_PRESENT -> WaHideReason.USER_PRESENT
        }
        val gate = if (reason == WaHideReason.UNLOCKED) read(tick - 2, tick - 1, false) else null
        val trigger = WaUnlockTrigger(owner, reason, WaSource.ACCESSIBILITY, 32, 2, 3, at(tick), gate, cause)
        return WaUnlockDraft(store).apply {
            record = WaUnlockRecord(product, trigger, 0, WaPresenter.SURFACE_CHILD, null, 56, WaOrbStyle.FLUVI_MASK,
                77, at(tick - 4), WaChildHide("APPLIED", at(tick + 1), at(tick + 2)),
                firstRemove = WaRemoval(at(tick + 6), at(tick + 7), true, null))
        }
    }

    private fun tracking() = WaUnlockTracking().apply { connect(owner.service); attached(owner, 0) }

    @Test fun restrictedRecordNeedsAnIndependentFreshPublicConfirmationAndRetainsTheOwnedChild() {
        val t = tracking()
        val head = WaUnlockHead()
        val accepted = mutableListOf<WaUnlockRecord>()
        val previous = draft(WaWithdrawalCause.PUBLIC_NEGATIVE, 50).record!!
        assertTrue(head.accept(previous))
        val early = draft(WaWithdrawalCause.APP_WINDOW_PRESENT, 100) { if (head.accept(it)) accepted.add(it) }
        val history = t.history(owner)!!
        history.previousRead = read(61, 69, true)
        val attempt = history.begin(91)
        attempt.fetchBeginNs = 70; attempt.fetchEndNs = 75; attempt.metadata(true, 78)
        history.finish(attempt.finish(WaScanDisposition.APPLIED, 100))
        early.record = early.record!!.copy(scans = history.snapshot())
        t.withdrew(early)
        early.committed(at(110))
        assertTrue(accepted.isEmpty())
        assertFalse(t.confirm(owner.service, owner.episode, null, WaHideReason.UNLOCKED, WaSource.ACCESSIBILITY,
            at(123), read(88, 122, false)))
        assertFalse(t.confirm(owner.service, owner.episode, null, WaHideReason.UNLOCKED, WaSource.ACCESSIBILITY,
            at(123), read(115, 122, true)))
        assertTrue(t.confirm(owner.service, owner.episode, null, WaHideReason.UNLOCKED, WaSource.ACCESSIBILITY,
            at(130), read(118, 128, false)))
        val result = accepted.single()
        assertEquals(100L, result.trigger.decision.elapsedNs)
        assertEquals(128L, result.confirmation!!.at.elapsedNs)
        assertEquals(110L, result.childCommit!!.elapsedNs)
        assertEquals(WaHideReason.RESTRICTED, result.trigger.reason)
        val report = verifyWaUnlockText(result.text())
        assertTrue(report.contains("winner=APP_WINDOW_PRESENT confirmation=UNLOCKED"))
        assertTrue(report.contains("observationGeneration=1"))
        assertTrue(report.contains("previousGateLocked=true"))
        assertTrue(report.contains("previousMetadataGateLocked=true"))
        assertTrue(report.contains("firstApp=91"))
        assertTrue(report.contains("disposition=APPLIED"))
        assertTrue(report.contains("physicalFirstRestrictedFrame=UNOBSERVED"))
    }

    @Test fun unrelatedRestrictionsOwnerTurnoverAndTimeoutPreserveTheExistingConfirmedHead() {
        for (invalidate in listOf<(WaUnlockTracking) -> Unit>(
            { it.attached(owner.copy(window = owner.window + 1), 0) },
            { it.connect(owner.service + 1) }, { it.invalidate(owner.service) }, { it.discardPending(owner.service) },
            { it.hasPending(owner.service, 100 + WaUnlockTracking.CONFIRM_NS + 1) },
        )) {
            val t = tracking()
            val head = WaUnlockHead()
            val existing = draft(WaWithdrawalCause.PUBLIC_NEGATIVE, 80).record!!
            assertTrue(head.accept(existing))
            val d = draft(WaWithdrawalCause.APP_WINDOW_PRESENT, 100) { assertFalse(head.accept(it)) }
            t.withdrew(d)
            invalidate(t)
            assertFalse(t.confirm(owner.service, owner.episode, null, WaHideReason.USER_PRESENT, WaSource.USER_PRESENT,
                at(200), null))
            d.committed(at(300))
            assertFalse(head.accept(existing))
        }
        val t = tracking()
        val d = draft(WaWithdrawalCause.APP_WINDOW_PRESENT, 100)
        t.withdrew(d)
        assertFalse(t.confirm(owner.service, owner.episode + 1, null, WaHideReason.USER_PRESENT, WaSource.USER_PRESENT, at(120), null))
        assertFalse(t.confirm(owner.service, owner.episode, owner.copy(window = 90), WaHideReason.USER_PRESENT, WaSource.USER_PRESENT, at(120), null))
        assertFalse(t.confirm(owner.service, owner.episode, null, WaHideReason.USER_PRESENT, WaSource.DISPLAY, at(120), null))
        assertFalse(t.confirm(owner.service, owner.episode, null, WaHideReason.UNLOCKED, WaSource.DISPLAY, at(120), null))
        assertTrue(t.confirm(owner.service, owner.episode, null, WaHideReason.USER_PRESENT, WaSource.USER_PRESENT, at(130), null))
        assertEquals(WaHideReason.USER_PRESENT, d.record!!.confirmation!!.reason)
        assertNull(d.record!!.confirmation!!.read)
    }

    @Test fun oldServiceCallbacksCannotExpireOrDiscardAReplacementServiceDraft() {
        val t = tracking()
        val newOwner = owner.copy(service = owner.service + 1)
        t.connect(newOwner.service)
        t.attached(newOwner, 0)
        val replacement = draft(WaWithdrawalCause.APP_WINDOW_PRESENT, 100, newOwner)
        t.withdrew(replacement)
        t.disconnect(owner.service)
        t.invalidate(owner.service)
        t.discardPending(owner.service)
        t.hasPending(owner.service, Long.MAX_VALUE)
        t.connect(owner.service)
        t.attached(owner, 0)
        assertTrue(t.confirm(newOwner.service, newOwner.episode, null, WaHideReason.USER_PRESENT,
            WaSource.USER_PRESENT, at(120), null))
        assertEquals(2L, t.history(newOwner)!!.generation)
    }

    @Test fun canceledPositiveSurvivesForItsOwnPublicWinnerAndIncompleteNegativeStaysUnknown() {
        val h = WaWindowHistory(owner, 1)
        h.previousRead = read(60, 65, true)
        fun start(id: Long, app: Boolean?, ns: Long): WaWindowAttempt = h.begin(id).apply {
            fetchBeginNs = ns - 3; fetchEndNs = ns - 1
            if (app != null) metadata(app, ns)
        }
        h.finish(start(1, false, 70).finish(WaScanDisposition.APPLIED, 76))
        val older = start(2, true, 90)
        val stale = start(3, false, 105)
        val unfinished = start(4, null, 115)
        val head = WaUnlockHead()
        val ordinary = draft(WaWithdrawalCause.PUBLIC_NEGATIVE, 99) { head.accept(it) }
        val replacement = draft(WaWithdrawalCause.PUBLIC_NEGATIVE, 120, owner.copy(window = 80)).record!!
        h.draft = ordinary
        assertTrue(head.accept(ordinary.record!!))
        assertTrue(head.accept(replacement))
        h.finish(stale.finish(WaScanDisposition.STALE, 125))
        val inflight = h.snapshot()
        assertEquals(WaScanDisposition.IN_FLIGHT, inflight.firstPositive!!.disposition)
        assertEquals(1L, inflight.lastPriorNegative!!.scan)
        h.finish(older.finish(WaScanDisposition.CANCELED, 130))
        h.finish(unfinished.finish(WaScanDisposition.CANCELED, 138))
        val summary = ordinary.record!!.scans!!
        assertEquals(4, summary.attempted)
        assertEquals(3, summary.completed)
        assertEquals(2, summary.canceled)
        assertEquals(1, summary.stale)
        assertEquals(1L, summary.lastPriorNegative!!.scan)
        assertEquals(2L, summary.firstPositive!!.scan)
        assertEquals(WaScanDisposition.CANCELED, summary.firstPositive.disposition)
        assertNull(summary.last!!.appWindow)
        assertEquals(WaWithdrawalCause.PUBLIC_NEGATIVE, ordinary.record!!.trigger.cause)
        assertFalse(head.accept(ordinary.record!!))
        assertFalse(head.accept(replacement))
    }

    @Test fun maximumSizedReportFitsAndExistingV1BytesStillRoundTripAfterRestart() {
        val legacy = "FLUVI_WA_LAST_UNLOCK_V1\nsource=ACCESSIBILITY reason=UNLOCKED\n"
        val oldBytes = legacy + "bodySha256=" + waCaptureDigest(legacy) + "\n"
        assertEquals(oldBytes, verifyWaUnlockText(oldBytes))
        try { verifyWaUnlockText(oldBytes.replace("UNLOCKED", "OTHER")); fail("digest must fail") }
        catch (_: IOException) { }

        val huge = Long.MAX_VALUE
        val tick = WaTime(huge, huge)
        val gate = WaGateRead(tick, tick, WaSystemState(Display.STATE_ON, true, true))
        fun row(id: Long, app: Boolean?) = WaWindowObservation(id, huge, huge, huge, app, gate,
            WaScanDisposition.GATE_DENIED, huge)
        val scans = WaWindowSummary(huge, Int.MAX_VALUE, Int.MAX_VALUE, Int.MAX_VALUE, Int.MAX_VALUE,
            row(huge - 1, true), row(huge - 2, false), row(huge, null), gate)
        val record = draft(WaWithdrawalCause.APP_WINDOW_PRESENT, 100).record!!
        val removal = WaRemoval(tick, tick, false, "x".repeat(64))
        val t = record.trigger
        val text = record.copy(product = product.copy(model = "x".repeat(64), version = "v".repeat(64)),
            trigger = WaUnlockTrigger(WaAttachment(huge, huge, huge, Int.MAX_VALUE, 112), t.reason, t.source,
                Int.MAX_VALUE, huge, huge, tick, gate, t.cause), hideId = huge, attached = tick,
            presenterFailure = "x".repeat(64), child = WaChildHide("APPLIED", tick, tick, "OBSERVED", "x".repeat(64)),
            childCommit = tick, localHide = tick, detached = tick, firstRemove = removal, retry = removal, hostStop = tick,
            scans = scans, confirmation = WaUnlockConfirmation(WaHideReason.UNLOCKED, WaSource.ACCESSIBILITY, tick, gate)).text()
        val bytes = text.toByteArray(Charsets.UTF_8)
        assertTrue("report bytes=${bytes.size}", bytes.size <= WaLastUnlock.LIMIT)
        assertEquals(text, verifyWaUnlockText(String(bytes, Charsets.UTF_8)))
    }
}
