package com.fluvi.app.lockscreen.host

import com.fluvi.r29.contract.R29Descriptor
import com.fluvi.r29.contract.R29Disclosure
import com.fluvi.r29.contract.R29FrameInputs
import com.fluvi.r29.contract.R29FramePolicy
import com.fluvi.r29.contract.R29HostReducer
import com.fluvi.r29.contract.R29Material
import com.fluvi.r29.contract.R29Portal
import com.fluvi.r29.contract.R29Protocol
import com.fluvi.r29.contract.R29PublisherIdentity
import org.junit.Assert.*
import org.junit.Test

class R29HostContractTest {
    private val nonce = "0123456789abcdef0123456789abcdef"
    private val otherNonce = "fedcba9876543210fedcba9876543210"
    private val now = 1_700_000_000_000L
    private val portal = R29Portal(false, 0, 0f, 0f, 50f, 68f, false, 0f, List(12) { 0f })
    private val material = R29Material(
        effectId = "dualTide", effectShaderId = 1, phase = .3f, elapsedSeconds = 1f,
        phaseSpeed = 1f, colors = listOf(0xff123456.toInt(), 0xffabcdef.toInt()),
        stops = listOf(0f, 1f), opacity = 1f, paletteSplitPercent = 50f,
        commonSettings = List(40) { 0f }, background = portal, interior = portal,
        referenceWidth = 1080f, referenceHeight = 2400f,
    )

    private fun descriptor(sequence: Long, visual: Long = sequence) = R29Descriptor(
        session = nonce, sequence = sequence, visualRevision = visual,
        dataRevision = 7, focusGeneration = 3, layoutRevision = 4, privacyRevision = 5,
        validFromEpochMs = now - 1000, validUntilEpochMs = now + 60_000,
        userId = 0, displayId = 0, displayWidth = 1080, displayHeight = 2400,
        densityDpi = 420, orbSizePx = 168, xFraction = .5f, yFraction = .8f,
        disclosure = R29Disclosure.FULL, projectionCurrent = true, material = material,
    )

    @Test fun onlyPinnedSinglePackageSignerAndEnrolledPrimaryUserAreTrusted() {
        val good = R29PublisherIdentity(10042, 10042, 0, listOf("com.fluvi.app"),
            listOf(R29Protocol.PUBLISHER_CERT_SHA256), true, true)
        assertTrue(R29Protocol.trustedPublisher(good))
        assertFalse(R29Protocol.trustedPublisher(good.copy(packages = listOf("com.fluvi.app", "other"))))
        assertFalse(R29Protocol.trustedPublisher(good.copy(certificates = listOf("0".repeat(64)))))
        assertFalse(R29Protocol.trustedPublisher(good.copy(callingUid = 10043)))
        assertFalse(R29Protocol.trustedPublisher(good.copy(userId = 10)))
        assertFalse(R29Protocol.trustedPublisher(good.copy(enrolled = false)))
        assertFalse(R29Protocol.trustedPublisher(good.copy(debuggableHost = false)))
    }

    @Test fun descriptorRejectsStalePrivateMalformedAndUnboundedInputs() {
        val good = descriptor(1)
        assertNull(R29Protocol.invalidReason(good, now, 2048))
        assertNotNull(R29Protocol.invalidReason(good.copy(projectionCurrent = false), now, 2048))
        assertNotNull(R29Protocol.invalidReason(good.copy(validUntilEpochMs = now), now, 2048))
        assertNotNull(R29Protocol.invalidReason(good.copy(orbSizePx = 400), now, 2048))
        assertNotNull(R29Protocol.invalidReason(good.copy(xFraction = Float.NaN), now, 2048))
        assertNotNull(R29Protocol.invalidReason(good.copy(material = material.copy(commonSettings = List(41) { 0f })), now, 2048))
        assertNotNull(R29Protocol.invalidReason(good, now, 32769))
        assertNotNull(R29Protocol.invalidReason(good.copy(userId = 1), now, 2048))
        assertNotNull(R29Protocol.invalidReason(good.copy(displayId = 1), now, 2048))
    }

    @Test fun newerAbaCoalescesAndCannotAdoptAnOldCompletion() {
        val host = R29HostReducer()
        assertTrue(host.beginSession(nonce))
        assertEquals(1L, host.prepare(descriptor(1), now, 2048)?.sequence)
        assertNull(host.prepare(descriptor(2), now, 2048))
        assertNull(host.prepare(descriptor(3, visual = 1), now, 2048))
        val next = host.workerFinished(nonce, 1)
        assertEquals(3L, next?.sequence)
        assertFalse(host.adopt(nonce, 1, now))
        assertNull(host.current(now))
        assertNull(host.workerFinished(nonce, 3))
        assertTrue(host.adopt(nonce, 3, now))
        assertEquals(3L, host.current(now)?.sequence)
    }

    @Test fun revokeAndExpiryNeverResurrectOldOrInflightFull() {
        val host = R29HostReducer()
        host.beginSession(nonce)
        host.prepare(descriptor(1), now, 2048)
        host.workerFinished(nonce, 1)
        assertTrue(host.adopt(nonce, 1, now))
        assertNotNull(host.current(now))
        host.prepare(descriptor(2), now, 2048)
        assertNull("replacement hides the previously ready image immediately", host.current(now))
        assertTrue(host.invalidate(nonce, 3))
        host.workerFinished(nonce, 2)
        assertFalse(host.adopt(nonce, 2, now))
        assertNull(host.current(now))
        assertFalse(host.invalidate(otherNonce, 4))
        assertNull(host.prepare(descriptor(3), now, 2048))
        assertEquals(4L, host.prepare(descriptor(4), now, 2048)?.sequence)
        host.workerFinished(nonce, 4)
        assertFalse(host.adopt(nonce, 4, now + 60_000))
        assertNull(host.current(now + 60_000))
    }

    @Test fun cleanDetachRetainsOnlyAcknowledgedCurrentSession() {
        val host = R29HostReducer()
        host.beginSession(nonce)
        host.prepare(descriptor(1), now, 2048)
        host.workerFinished(nonce, 1)
        assertTrue(host.adopt(nonce, 1, now))
        host.detach(nonce)
        assertEquals(1L, host.current(now)?.sequence)
        assertTrue(host.beginSession(otherNonce))
        assertNull(host.current(now))
        assertFalse(host.adopt(nonce, 1, now))
    }

    @Test fun systemResetClearsAcknowledgedImageAndRejectsOldWorker() {
        val host = R29HostReducer()
        host.beginSession(nonce)
        host.prepare(descriptor(1), now, 2048)
        host.workerFinished(nonce, 1)
        assertTrue(host.adopt(nonce, 1, now))
        host.prepare(descriptor(2), now, 2048)
        host.reset()
        assertNull(host.current(now))
        host.workerFinished(nonce, 2)
        assertFalse(host.adopt(nonce, 2, now))
        assertNull(host.current(now))
    }

    @Test fun replayAndLostAdoptionCannotRestorePreviousFull() {
        val host = R29HostReducer()
        assertTrue(host.beginSession(nonce))
        host.prepare(descriptor(1), now, 2048)
        host.workerFinished(nonce, 1)
        // The worker completed, but no consumer adopted it yet.
        assertNull(host.current(now))
        host.detach(nonce)
        assertFalse(host.adopt(nonce, 1, now))
        assertNull(host.current(now))
        assertFalse(host.beginSession(nonce))
        assertTrue(host.beginSession(otherNonce))
        assertNull(host.prepare(descriptor(2), now, 2048))
        assertFalse(host.adopt(nonce, 1, now))
        val next = descriptor(1).copy(session = otherNonce)
        assertEquals(next.sequence, host.prepare(next, now, 2048)?.sequence)
    }

    @Test fun immutablePublishedMaterialCannotBeMutatedByItsProducer() {
        val colors = mutableListOf(0xff123456.toInt(), 0xffabcdef.toInt())
        val stops = mutableListOf(0f, 1f)
        val common = MutableList(40) { 0f }
        val portalSettings = MutableList(12) { 0f }
        val mutable = material.copy(colors = colors, stops = stops, commonSettings = common,
            background = portal.copy(settings = portalSettings))
        val host = R29HostReducer()
        host.beginSession(nonce)
        host.prepare(descriptor(1).copy(material = mutable), now, 2048)
        colors[0] = 0
        stops[0] = .9f
        common[0] = 42f
        portalSettings[0] = 42f
        host.workerFinished(nonce, 1)
        assertTrue(host.adopt(nonce, 1, now))
        val stored = checkNotNull(host.current(now)).material
        assertEquals(0xff123456.toInt(), stored.colors[0])
        assertEquals(0f, stored.stops[0])
        assertEquals(0f, stored.commonSettings[0])
        assertEquals(0f, stored.background.settings[0])
    }

    @Test fun malformedNewerInputInvalidatesOldFullButOtherSessionDoesNot() {
        val host = R29HostReducer()
        host.beginSession(nonce)
        host.prepare(descriptor(1), now, 2048)
        host.workerFinished(nonce, 1)
        assertTrue(host.adopt(nonce, 1, now))
        assertNull(host.prepare(descriptor(2).copy(session = otherNonce), now, 2048))
        assertNotNull(host.current(now))
        assertNull(host.prepare(descriptor(2).copy(material = material.copy(opacity = Float.NaN)), now, 2048))
        assertNull(host.current(now))
        assertNull(host.prepare(descriptor(2), now, 2048))
        assertNotNull(host.prepare(descriptor(3), now, 2048))
    }

    @Test fun firstRestrictiveFrameDeniesEvenIfOutgoingLockscreenRemains() {
        val allow = R29FrameInputs(
            inputsKnown = true, ordinaryLockscreen = true, primaryUser = true,
            defaultDisplay = true, defaultBlueprint = true, geometryValid = true,
            policyAllowsFull = true, currentReadyRevision = true,
            dozing = false, dreaming = false, occluded = false, goingAway = false,
            credential = false, shadeOrQs = false, restrictiveTransition = false,
        )
        assertTrue(R29FramePolicy.allow(allow))
        assertFalse(R29FramePolicy.allow(allow.copy(inputsKnown = false)))
        assertFalse(R29FramePolicy.allow(allow.copy(restrictiveTransition = true)))
        assertFalse(R29FramePolicy.allow(allow.copy(shadeOrQs = true)))
        assertFalse(R29FramePolicy.allow(allow.copy(credential = true)))
        assertFalse(R29FramePolicy.allow(allow.copy(occluded = true)))
        assertFalse(R29FramePolicy.allow(allow.copy(goingAway = true)))
        assertFalse(R29FramePolicy.allow(allow.copy(currentReadyRevision = false)))
    }
}
