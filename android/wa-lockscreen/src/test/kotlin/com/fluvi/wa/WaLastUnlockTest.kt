package com.fluvi.wa

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WaLastUnlockTest {
    private fun stamp(tick: Long) = WaTime(tick / 1000, tick)

    private fun record(window: Long, at: Long, childStatus: String = "APPLIED") = WaUnlockRecord(
        WaUnlockProduct("com.fluvi.app", "a".repeat(40), "0.1.5", 7, "Fixture", 37),
        WaUnlockTrigger(
            WaAttachment(12, window, window, 3, 112), WaHideReason.UNLOCKED, WaSource.ACCESSIBILITY,
            32, 11, 12, stamp(at), null,
        ),
        0, WaPresenter.SURFACE_CHILD, null, 112, WaOrbStyle.ORB, window, stamp(at - 4000),
        WaChildHide(childStatus, stamp(at + 100), stamp(at + 200), "PENDING"),
        localHide = stamp(at + 300),
        firstRemove = WaRemoval(stamp(at + 400), stamp(at + 500), true, null),
        hostStop = stamp(at + 600), hostStopStatus = "STOPPED",
    )

    @Test fun firstRemovalPublishesAndAnOldReceiptDoesNotReplaceASuccessor() {
        val head = WaUnlockHead()
        val a = record(1, 13000)
        val b = record(2, 23000)
        assertFalse(head.accept(a.copy(firstRemove = null)))
        assertTrue(head.accept(a))
        assertFalse(head.accept(a))
        assertTrue(head.accept(a.copy(childCommit = stamp(14100))))
        assertTrue(head.accept(b))
        assertFalse(head.accept(a.copy(childCommit = stamp(24100))))
        assertTrue(head.accept(b.copy(retry = WaRemoval(stamp(25000), stamp(26000), true, null))))
    }

    @Test fun digestCoversBoundedUtf8BodyAndMissingEndpointsStayExplicit() {
        val a = record(1, 13000)
        val text = a.copy(product = a.product.copy(model = "Unexpected\n" + "ő".repeat(9000))).text()
        assertTrue(text.startsWith(WaLastUnlock.MAGIC + "\n"))
        assertTrue(text.toByteArray(Charsets.UTF_8).size < WaLastUnlock.LIMIT)
        assertTrue(text.contains("childCommitMainReceiptElapsedNs=UNOBSERVED"))
        assertTrue(text.contains("gateReadBeginUptimeMs=UNOBSERVED"))
        assertTrue(text.contains("physicalLastOrbPixel=UNOBSERVED"))
        val marker = text.lastIndexOf("bodySha256=")
        assertEquals(
            waCaptureDigest(text.substring(0, marker)),
            text.substring(marker).removePrefix("bodySha256=").trimEnd(),
        )
    }

    @Test fun lookupReportsTheActualPresenterAndDifferentRemovalAttempts() {
        val a = record(1, 13000, "ERROR")
        val text = a.copy(
            presenter = WaPresenter.LEGACY_FALLBACK,
            presenterFailure = "SURFACE_LOST",
            child = WaChildHide("FALLBACK"),
            firstRemove = WaRemoval(stamp(14000), stamp(15000), false, "IllegalStateException"),
            retry = WaRemoval(stamp(16000), stamp(17000), true, null),
        ).text()
        assertTrue(text.contains("presenter=LEGACY_FALLBACK presenterError=SURFACE_LOST"))
        assertTrue(text.contains("childHide=FALLBACK"))
        assertTrue(text.contains("removeDetached=false removeError=IllegalStateException"))
        assertTrue(text.contains("retryDetached=true retryError=NONE"))
    }
}
