package com.fluvi.app.lockscreen

import org.junit.Assert.assertEquals
import org.junit.Test

class KeyguardCardWindowLifecycleTest {
    @Test fun `repeated show updates one attached root and repeated hide removes once`() {
        val state = KeyguardCardWindowLifecycle()
        assertEquals(KeyguardCardWindowLifecycle.Operation.ATTACH, state.showOperation())
        state.onAttachSucceeded()
        repeat(10) { assertEquals(KeyguardCardWindowLifecycle.Operation.UPDATE, state.showOperation()) }
        assertEquals(KeyguardCardWindowLifecycle.Operation.DETACH, state.hideOperation())
        state.onDetached()
        repeat(10) { assertEquals(KeyguardCardWindowLifecycle.Operation.NONE, state.hideOperation()) }
    }

    @Test fun `failed token never leaves a logical attachment behind`() {
        val state = KeyguardCardWindowLifecycle()
        state.onAttachFailed()
        assertEquals(KeyguardCardWindowLifecycle.Operation.ATTACH, state.showOperation())
    }
}
