package com.fluvi.app.lockscreen

import android.view.accessibility.AccessibilityEvent
import org.junit.Assert.*
import org.junit.Test

class KeyguardR45PresentationTest {
    private fun event(type: Int, window: Int = 42, display: Int = 0, changes: Int = 0) =
        KeyguardAccessibilityEventMeta(type, window, display, changes, null, 100L)

    @Test fun exactOwnContentAndVerifiedSecondaryDisplayCanBeIgnored() {
        assertEquals(KeyguardR45IngressAction.IGNORE, KeyguardR45IngressPolicy.decide(
            event(AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED), exactOwn = true, targetWindow = null))
        assertEquals(KeyguardR45IngressAction.IGNORE, KeyguardR45IngressPolicy.decide(
            event(AccessibilityEvent.TYPE_WINDOWS_CHANGED, display = 2,
                changes = AccessibilityEvent.WINDOWS_CHANGE_REMOVED), exactOwn = false, targetWindow = 42))
    }

    @Test fun unknownSamePackageAndMixedOwnFlagsRequireReassessment() {
        assertEquals(KeyguardR45IngressAction.REASSESS, KeyguardR45IngressPolicy.decide(
            event(AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED), exactOwn = false, targetWindow = null))
        assertEquals(KeyguardR45IngressAction.REASSESS, KeyguardR45IngressPolicy.decide(
            event(AccessibilityEvent.TYPE_WINDOWS_CHANGED, changes = AccessibilityEvent.WINDOWS_CHANGE_ADDED or
                AccessibilityEvent.WINDOWS_CHANGE_FOCUSED), exactOwn = true, targetWindow = null))
        assertEquals(KeyguardR45IngressAction.REASSESS, KeyguardR45IngressPolicy.decide(
            event(AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, display = -1), exactOwn = true, targetWindow = null))
    }

    @Test fun exactOwnAndDirectParentRemovalsAreTerminal() {
        val removed = event(AccessibilityEvent.TYPE_WINDOWS_CHANGED, changes = AccessibilityEvent.WINDOWS_CHANGE_REMOVED)
        assertEquals(KeyguardR45IngressAction.OWN_REMOVED,
            KeyguardR45IngressPolicy.decide(removed, exactOwn = true, targetWindow = null))
        assertEquals(KeyguardR45IngressAction.TARGET_REMOVED,
            KeyguardR45IngressPolicy.decide(removed, exactOwn = false, targetWindow = 42))
        assertEquals(KeyguardR45IngressAction.REASSESS,
            KeyguardR45IngressPolicy.decide(removed, exactOwn = false, targetWindow = 43))
    }

    @Test fun onlyTheQualifiedLowerWindowsOwnContentEventIsIgnored() {
        val lower = listOf(KeyguardR45LowerWindow(42, 0, "example.background"))
        val content = event(AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED).copy(packageName = "example.background")
        assertEquals(KeyguardR45IngressAction.IGNORE, KeyguardR45IngressPolicy.decide(content, false, null, lower))
        assertEquals(KeyguardR45IngressAction.REASSESS,
            KeyguardR45IngressPolicy.decide(content.copy(windowId = 43), false, null, lower))
        assertEquals(KeyguardR45IngressAction.REASSESS,
            KeyguardR45IngressPolicy.decide(content.copy(eventType = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED), false, null, lower))
    }

    @Test fun waWakeOwnsItsOwnIdentityAndCannotReuseAnOldIntent() {
        val owner = KeyguardR45WaLifetime()
        val first = owner.prepare("capture", 1, 2, "ONE_WAKE", false)
        assertNull(owner.screenOn(1, "capture"))
        assertTrue(owner.screenOff())
        assertNull(owner.screenOn(1, "other"))
        assertSame(first, owner.screenOn(1, "capture"))
        assertTrue(owner.bind(first, 3, 4))
        owner.attached(first)
        owner.visible(first)
        owner.suspend(first)
        assertEquals(KeyguardR45Phase.SUSPENDED, owner.phase)
        owner.retire()
        val next = owner.prepare("capture", 1, 2, "SESSION", true)
        assertFalse(owner.current(first, 3, 4))
        assertNotEquals(first.generation, next.generation)
        owner.visible(first)
        assertEquals("a late reveal cannot change a newer owner", KeyguardR45Phase.PREPARED, owner.phase)
    }

    @Test fun directLeaseCannotOutliveItsOwnerOrOriginalDeadline() {
        val owner = KeyguardR45DirectLifetime()
        val target = KeyguardR446Target(7, 0, KeyguardR446Bounds(0, 0, 100, 100))
        val first = KeyguardR45DirectLifetime.Lease(Any(), "capture", 1, 2, 3, target, 100, 500)
        owner.open(first)
        assertTrue(owner.current(first, 499))
        owner.suspend(first)
        assertFalse(owner.current(first, 500))
        owner.retire()
        assertFalse(owner.current(first, 100))
    }
}
