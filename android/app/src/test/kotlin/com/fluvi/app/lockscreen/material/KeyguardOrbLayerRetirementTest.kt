package com.fluvi.app.lockscreen.material

import org.junit.Assert.*
import org.junit.Test

/** State-only controls: platform composition is checked separately on API35. */
class KeyguardOrbLayerRetirementTest {
    @Test fun retiredOwnerRejectsNewBorrowsUntilTheEnteredOperationActuallyDrains() {
        val owner = KeyguardOrbOutputLifetime()
        assertTrue(owner.acquire())
        assertTrue(owner.seal())
        assertFalse(owner.acquire())
        assertFalse(owner.readyToDispose())
        assertTrue(owner.release())
        assertTrue(owner.readyToDispose())
        assertFalse(owner.seal())
    }

    @Test fun independentCopyBorrowKeepsRetiredNativeOwnerAlive() {
        val owner = KeyguardOrbOutputLifetime()
        assertTrue(owner.acquire()) // Canvas
        assertTrue(owner.acquire()) // PixelCopy
        assertTrue(owner.seal())
        assertFalse(owner.release())
        assertFalse(owner.readyToDispose())
        assertTrue(owner.release())
        assertTrue(owner.readyToDispose())
    }

    @Test fun retiringOldGenerationCannotRevokeOrDisposeItsSuccessor() {
        val old = KeyguardOrbOutputLifetime()
        val next = KeyguardOrbOutputLifetime()
        assertTrue(old.acquire())
        assertTrue(old.seal())
        assertTrue(next.acquire())
        assertTrue(old.release())
        assertTrue(old.readyToDispose())
        assertFalse(next.readyToDispose())
        assertFalse(next.release())
        assertTrue(next.acquire())
        assertFalse(next.release())
    }
}
