package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

/** Only explicitly proved internal offers may leave the sample candidate
 * current; ordinary FULL/DISCREET ordering must still reject it. */
class KeyguardR447ReadOrderTest {
    @Test fun duplicateOfferDoesNotInvalidateCompletedSample() {
        val owner = KeyguardFirstAuthorizedOrb()
        val scene = owner.sceneSerial()
        owner.requireRead(40)
        owner.readCompleted(40)
        owner.requireRead(43, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
        assertFalse(owner.isUnclaimedReadCurrent(40, scene))
        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.REDUNDANT_OFFER_ACCEPTED,
            owner.sampleOrder(40, scene).result)
    }

    @Test fun laterBarrierSurvivesReplacementByDuplicate() {
        val owner = KeyguardFirstAuthorizedOrb()
        val scene = owner.sceneSerial()
        owner.requireRead(40)
        owner.readCompleted(40)
        owner.requireRead(43)
        owner.requireRead(44, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.NEWER_BARRIER_REQUIRED,
            owner.sampleOrder(40, scene).result)
        owner.readCompleted(43)
        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.NEWER_COMPLETED,
            owner.sampleOrder(40, scene).result)
    }

    @Test fun changedSceneCannotBeExcusedBySameWindowOrDuplicate() {
        val owner = KeyguardFirstAuthorizedOrb()
        val scene = owner.sceneSerial()
        owner.requireRead(40)
        owner.readCompleted(40)
        owner.externalIngress()
        owner.requireRead(43, KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE)
        assertEquals(KeyguardFirstAuthorizedOrb.SampleResult.SCENE_CHANGED,
            owner.sampleOrder(40, scene).result)
    }
}
