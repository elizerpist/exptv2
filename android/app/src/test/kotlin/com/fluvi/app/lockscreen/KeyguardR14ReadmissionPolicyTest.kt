package com.fluvi.app.lockscreen

import org.junit.Assert.*
import org.junit.Test

class KeyguardR14ReadmissionPolicyTest {
    private val authority = KeyguardInspectionAuthority(1, 2, 3, 4, 5)
    private val settings = KeyguardCardSettings(requested = true, showFinancialDetails = true,
        presentationMode = KeyguardCardPresentationMode.ORB, animationMode = KeyguardCardAnimationMode.ORB_ONLY,
        generation = 7, layoutRevision = 8)
    private val recovery = KeyguardR14Recovery(9, authority, 7, 8, settings.focus.generation, true, true, 11, 5)
    private fun request(id: Long, event: KeyguardR14Ingress? = null) = KeyguardCardInspectionRequest(
        id, "window", 1, 2, 4, 5, 3, event?.callbackAt ?: 90, eventTimeUptimeMs = event?.eventAt,
        triggerReceivedUptimeMs = event?.callbackAt, r14Ingress = event)
    private val a = request(1, KeyguardR14Ingress(1, true, 6, 0, 32, 90, 95))
    private val good = request(2, KeyguardR14Ingress(2, true, 6, 0, 32, 110, 120))
    private fun defer(b: KeyguardCardInspectionRequest? = good, r: KeyguardR14Recovery? = recovery,
        config: KeyguardCardSettings = settings, route: Boolean = true, attached: Boolean = false,
        state: KeyguardSurfacePresentationState = KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE,
        complete: Boolean = true, decision: KeyguardCardVisibility = KeyguardCardVisibility.SHOW_FULL,
        current: KeyguardInspectionAuthority = authority) = KeyguardR14ReadmissionPolicy.shouldDefer(
        r, current, config, route, attached, state, complete, decision, a, 100, 200, b)

    @Test fun onlyOneEligiblePendingExternalEventCanDefer() {
        assertTrue(defer())
        assertFalse(defer(r = recovery.copy(used = true)))
        assertFalse(defer(b = null))
        assertFalse(defer(attached = true))
        assertFalse(defer(state = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE))
        assertFalse(defer(complete = false))
        assertFalse(defer(decision = KeyguardCardVisibility.HIDDEN_UNKNOWN))
        assertFalse(defer(current = authority.copy(wakeGeneration = 4)))
        assertFalse(defer(current = authority.copy(serviceSession = 2)))
        assertFalse(defer(current = authority.copy(visibilityEpoch = 3)))
        assertFalse(defer(current = authority.copy(interactionEpoch = 5)))
        assertFalse(defer(current = authority.copy(attachGeneration = 6)))
    }

    @Test fun staleAmbiguousSyntheticWrongDisplayAndBadTimeNeverDefer() {
        val e = good.r14Ingress!!
        assertFalse(defer(b = good.copy(r14Ingress = null)))
        assertFalse(defer(b = good.copy(r14Ingress = e.copy(externalSystemUi = false))))
        assertFalse(defer(b = good.copy(r14Ingress = e.copy(origin = KeyguardR14Origin.OWN))))
        assertFalse(defer(b = good.copy(r14Ingress = e.copy(origin = KeyguardR14Origin.AMBIGUOUS))))
        assertFalse(defer(b = good.copy(r14Ingress = e.copy(displayId = 1))))
        assertFalse(defer(b = good.copy(r14Ingress = e.copy(windowId = -1))))
        assertFalse(defer(b = good.copy(r14Ingress = e.copy(eventType = 2048))))
        assertFalse(defer(b = good.copy(trigger = "surfaceRetry")))
        assertFalse(defer(b = good.copy(id = a.id)))
        assertFalse(defer(b = good.copy(r14Ingress = e.copy(id = a.r14Ingress!!.id))))
        assertFalse(defer(b = request(2, e.copy(eventAt = 99))))
        assertFalse(defer(b = request(2, e.copy(eventAt = 100))))
        assertFalse(defer(b = request(2, e.copy(callbackAt = 100))))
        assertFalse(defer(b = request(2, e.copy(eventAt = 121))))
        assertFalse(defer(b = request(2, e.copy(callbackAt = 201))))
        assertFalse(defer(b = request(2, e.copy(eventAt = null))))
        assertFalse(defer(b = good.copy(triggerReceivedUptimeMs = null)))
        assertFalse(defer(b = good.copy(visibilityEpoch = 3)))
    }

    @Test fun changedRoutePrivacyAndSettingsCannotUseOldRecovery() {
        assertFalse(defer(route = false))
        assertFalse(defer(config = settings.copy(showFinancialDetails = false)))
        assertFalse(defer(config = settings.copy(requested = false)))
        assertFalse(defer(config = settings.copy(generation = 8)))
        assertFalse(defer(config = settings.copy(layoutRevision = 9)))
        assertFalse(defer(config = settings.copy(presentationMode = KeyguardCardPresentationMode.CARD)))
        assertFalse(defer(config = settings.copy(animationMode = KeyguardCardAnimationMode.OFF)))
        assertFalse(defer(config = settings.copy(animationMode = KeyguardCardAnimationMode.ORB_AND_BACKGROUND)))
        assertFalse(defer(config = settings.copy(focus = settings.focus.copy(generation = 7))))
        assertFalse(defer(r = null))
        assertFalse(defer(decision = KeyguardCardVisibility.SHOW_DISCREET))
    }

    @Test fun reacquisitionCannotMakeAnOldOriginNew() {
        val old = KeyguardR14Ingress(4, true, 6, 0, 32, 80, 90)
        val original = request(4, old)
        val reacquired = original.reacquireAfterWithdrawal(authority, 5, 115,
            KeyguardWindowFreshness.FRAMEWORK_EVENT)!!
        assertEquals(old, reacquired.r14Ingress)
        assertEquals(80L, reacquired.eventTimeUptimeMs)
        assertEquals(90L, reacquired.triggerReceivedUptimeMs)
        assertFalse(defer(b = reacquired))
    }

    @Test fun onlyTheUnstartedQueueSlotIsAQualifier() {
        val queue = KeyguardCardInspectionQueue()
        assertTrue(queue.offer(a))
        assertFalse(queue.offer(good))
        assertTrue(defer(b = queue.pendingRequest()))
        assertEquals(good, queue.complete(a))
        assertNull(queue.pendingRequest())
        assertFalse(defer(b = queue.pendingRequest()))
        assertFalse(defer(b = queue.pendingRequest(), r = recovery.copy(used = true)))
    }

    @Test fun ingressClassificationDistinguishesOwnAmbiguousAndOther() {
        val base = KeyguardAccessibilityEventMeta(32, 6, 0, 0, "com.android.systemui", 110)
        assertEquals(KeyguardR14Origin.SYSTEM_UI, KeyguardR14IngressClassifier.classify(base, false))
        assertEquals(KeyguardR14Origin.OWN, KeyguardR14IngressClassifier.classify(base, true))
        assertEquals(KeyguardR14Origin.AMBIGUOUS, KeyguardR14IngressClassifier.classify(base.copy(packageName = null), false))
        assertEquals(KeyguardR14Origin.AMBIGUOUS, KeyguardR14IngressClassifier.classify(base.copy(windowId = -1), false))
        assertEquals(KeyguardR14Origin.OTHER, KeyguardR14IngressClassifier.classify(base.copy(packageName = "another.app"), false))
    }
}
