package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardCardVisibilityPolicyTest {
    private fun signals(
        requested: Boolean = true,
        connected: Boolean = true,
        unlockedSinceBoot: Boolean = true,
        primary: Boolean = true,
        interactive: Boolean = true,
        displayOn: Boolean = true,
        keyguard: Boolean = true,
        surface: KeyguardSurface = KeyguardSurface.MAIN_KEYGUARD,
        full: Boolean = false,
    ) = KeyguardCardSignals(
        requested, connected, unlockedSinceBoot, primary, interactive, displayOn, keyguard, surface, full,
    )

    @Test fun `every fast gate hides before a main keyguard signal`() {
        assertEquals(KeyguardCardVisibility.HIDDEN_OPT_OUT, KeyguardCardVisibilityPolicy.decide(signals(requested = false)))
        assertEquals(KeyguardCardVisibility.HIDDEN_DISCONNECTED, KeyguardCardVisibilityPolicy.decide(signals(connected = false)))
        assertEquals(KeyguardCardVisibility.HIDDEN_BEFORE_FIRST_UNLOCK, KeyguardCardVisibilityPolicy.decide(signals(unlockedSinceBoot = false)))
        assertEquals(KeyguardCardVisibility.HIDDEN_OTHER_DISPLAY, KeyguardCardVisibilityPolicy.decide(signals(primary = false)))
        assertEquals(KeyguardCardVisibility.HIDDEN_SCREEN, KeyguardCardVisibilityPolicy.decide(signals(interactive = false)))
        assertEquals(KeyguardCardVisibility.HIDDEN_SCREEN, KeyguardCardVisibilityPolicy.decide(signals(displayOn = false)))
        assertEquals(KeyguardCardVisibility.HIDDEN_UNLOCKED, KeyguardCardVisibilityPolicy.decide(signals(keyguard = false)))
    }

    @Test fun `sensitive surfaces outrank a visible lockscreen marker`() {
        assertEquals(KeyguardCardVisibility.HIDDEN_CREDENTIAL, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.CREDENTIAL, full = true)))
        assertEquals(KeyguardCardVisibility.HIDDEN_SHADE, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.SHADE, full = true)))
        assertEquals(KeyguardCardVisibility.HIDDEN_OCCLUDED, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.OCCLUDED, full = true)))
        assertEquals(KeyguardCardVisibility.HIDDEN_UNKNOWN, KeyguardCardVisibilityPolicy.decide(signals(surface = KeyguardSurface.UNKNOWN, full = true)))
    }

    @Test fun `only verified main keyguard can show and privacy decides payload`() {
        assertEquals(KeyguardCardVisibility.SHOW_DISCREET, KeyguardCardVisibilityPolicy.decide(signals()))
        assertEquals(KeyguardCardVisibility.SHOW_FULL, KeyguardCardVisibilityPolicy.decide(signals(full = true)))
    }

    @Test fun `classifier gives pin shade and foreign occlusion priority`() {
        val mainAndPin = listOf(
            system("com.android.systemui:id/keyguard_carrier_text", "com.android.systemui:id/keyguard_security_container"),
        )
        assertEquals(KeyguardSurface.CREDENTIAL, KeyguardSurfaceClassifier.classify(mainAndPin))
        assertEquals(KeyguardSurface.SHADE, KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text", "com.android.systemui:id/quick_settings_panel"))))
        assertEquals(KeyguardSurface.OCCLUDED, KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text"), KeyguardWindowSnapshot("com.android.camera", 1, 99, 0))))
    }

    @Test fun `own overlay does not change main surface decision`() {
        assertEquals(
            KeyguardSurface.MAIN_KEYGUARD,
            KeyguardSurfaceClassifier.classify(listOf(system("com.android.systemui:id/keyguard_carrier_text"), KeyguardWindowSnapshot("com.fluvi.app", 2032, 100, 0, ownOverlay = true))),
        )
    }

    @Test fun `late full result cannot survive privacy tightening unlock or focus change`() {
        fun gate(
            epoch: Long = 4,
            focus: Long = 9,
            full: Boolean = true,
            details: Boolean = true,
            display: Boolean = true,
        ) = KeyguardCardContentPublication(
            requestSession = 2,
            currentSession = 2,
            requestEpoch = 4,
            currentEpoch = epoch,
            requestFocusGeneration = 9,
            currentFocusGeneration = focus,
            currentlyFull = full,
            detailsStillAllowed = details,
            displayStillEligible = display,
        )
        assertEquals(true, KeyguardCardContentPublicationPolicy.canApply(gate()))
        assertEquals(false, KeyguardCardContentPublicationPolicy.canApply(gate(details = false)))
        assertEquals(false, KeyguardCardContentPublicationPolicy.canApply(gate(full = false)))
        assertEquals(false, KeyguardCardContentPublicationPolicy.canApply(gate(epoch = 5)))
        assertEquals(false, KeyguardCardContentPublicationPolicy.canApply(gate(focus = 10)))
        assertEquals(false, KeyguardCardContentPublicationPolicy.canApply(gate(display = false)))
    }

    @Test fun `matched own window feedback is ignored but package-less attach race is inspected`() {
        val own = KeyguardAccessibilityEventMeta(
            eventType = AccessibilityEvent.TYPE_WINDOWS_CHANGED,
            windowId = 41,
            displayId = 0,
            windowChanges = AccessibilityEvent.WINDOWS_CHANGE_ADDED,
            packageName = null,
        )
        assertEquals(KeyguardEventAction.IGNORE_OWN, KeyguardCardEventGate.decide(own, ownWindow = true))
        // Before View.accessibilityWindowId is available the event is not
        // assumed safe. It is inspected, but no eager detach is allowed.
        assertEquals(KeyguardEventAction.INSPECT, KeyguardCardEventGate.decide(own, ownWindow = false))
    }

    @Test fun `stale inspection has no detach authority over a newer attach`() {
        assertEquals(
            KeyguardInspectionAction.DROP_STALE,
            KeyguardCardInspectionGate.decide(
                expectedSession = 3,
                currentSession = 3,
                expectedEpoch = 5,
                currentEpoch = 6,
                displayEligibleNow = true,
                keyguardLockedNow = true,
            ),
        )
        assertEquals(
            KeyguardInspectionAction.HIDE_CURRENT_GATE,
            KeyguardCardInspectionGate.decide(3, 3, 6, 6, false, true),
        )
    }

    @Test fun `inspection which predates own pointer or attach cannot name or remove current overlay`() {
        assertEquals(
            KeyguardInspectionAction.DROP_STALE,
            KeyguardCardInspectionGate.decide(
                expectedSession = 3,
                currentSession = 3,
                expectedEpoch = 6,
                currentEpoch = 6,
                displayEligibleNow = true,
                keyguardLockedNow = true,
                expectedInteractionEpoch = 4,
                currentInteractionEpoch = 5,
                expectedAttachGeneration = 8,
                currentAttachGeneration = 9,
            ),
        )
    }

    @Test fun `fluvi activity event is not mistaken for own overlay feedback`() {
        val event = KeyguardAccessibilityEventMeta(
            eventType = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            windowId = 77,
            displayId = 0,
            windowChanges = 0,
            packageName = "com.fluvi.app",
        )

        assertEquals(KeyguardEventAction.INSPECT, KeyguardCardEventGate.decide(event, ownWindow = false))
    }

    @Test fun `missing roots and truncated walks stay distinguishable unknown states`() {
        assertEquals(
            KeyguardSurfaceReason.ROOT_UNAVAILABLE,
            KeyguardSurfaceClassifier.classifyDetailed(emptyList(), unavailableRoot = true).reason,
        )
        assertEquals(
            KeyguardSurfaceReason.WALK_TRUNCATED,
            KeyguardSurfaceClassifier.classifyDetailed(
                listOf(system()),
                walkTruncated = true,
            ).reason,
        )
    }

    @Test fun `partial systemui read cannot turn an early main marker into show authority`() {
        val main = listOf(system("com.android.systemui:id/keyguard_carrier_text"))
        assertEquals(
            KeyguardSurface.UNKNOWN,
            KeyguardSurfaceClassifier.classifyDetailed(main, unavailableRoot = true).surface,
        )
        assertEquals(
            KeyguardSurfaceReason.ROOT_UNAVAILABLE,
            KeyguardSurfaceClassifier.classifyDetailed(main, unavailableRoot = true).reason,
        )
        assertEquals(
            KeyguardSurface.UNKNOWN,
            KeyguardSurfaceClassifier.classifyDetailed(main, walkTruncated = true).surface,
        )
        assertEquals(
            KeyguardSurfaceReason.WALK_TRUNCATED,
            KeyguardSurfaceClassifier.classifyDetailed(main, walkTruncated = true).reason,
        )
        // A directly observed credential is still a safe exclusion even if
        // another branch of the tree could not be completed.
        assertEquals(
            KeyguardSurface.CREDENTIAL,
            KeyguardSurfaceClassifier.classifyDetailed(
                listOf(system(
                    "com.android.systemui:id/keyguard_carrier_text",
                    "com.android.systemui:id/keyguard_security_container",
                )),
                walkTruncated = true,
            ).surface,
        )
    }

    private fun system(vararg ids: String) = KeyguardWindowSnapshot(
        packageName = "com.android.systemui",
        type = 1,
        layer = 20,
        displayId = 0,
        visibleViewIds = ids.toSet(),
    )
}
