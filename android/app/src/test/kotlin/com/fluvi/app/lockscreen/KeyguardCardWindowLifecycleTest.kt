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

    @Test fun `failed layout update does not cause a duplicate attach while root remains attached`() {
        val state = KeyguardCardWindowLifecycle()
        state.onAttachSucceeded()
        state.onUpdateFailed(stillAttached = true)
        assertEquals(KeyguardCardWindowLifecycle.Operation.UPDATE, state.showOperation())
    }

    @Test fun `same full surface preserves the amount without a new loading publication`() {
        assertEquals(
            KeyguardCardContentRefreshPlan(publishLoading = false, startResolve = false),
            KeyguardCardContentRefreshPolicy.firstOrSurfacePlan(
                focusChanged = false,
                hasCurrentContent = true,
                resolveInFlightForFocus = false,
            ),
        )
        assertEquals(
            KeyguardCardContentRefreshPlan(publishLoading = false, startResolve = false),
            KeyguardCardContentRefreshPolicy.firstOrSurfacePlan(
                focusChanged = false,
                hasCurrentContent = false,
                resolveInFlightForFocus = true,
            ),
        )
    }

    @Test fun `fifty stable system events produce no window operation`() {
        val state = KeyguardCardWindowLifecycle()
        state.onAttachSucceeded()
        repeat(50) {
            assertEquals(
                KeyguardCardWindowLifecycle.Operation.NONE,
                state.renderOperation(contentChanged = false, geometryChanged = false),
            )
        }
    }

    @Test fun `financial content change updates the attached root without a second attach`() {
        val state = KeyguardCardWindowLifecycle()
        state.onAttachSucceeded()
        assertEquals(
            KeyguardCardWindowLifecycle.Operation.CONTENT_UPDATE,
            state.renderOperation(contentChanged = true, geometryChanged = false),
        )
        assertEquals(
            KeyguardCardWindowLifecycle.Operation.LAYOUT_UPDATE,
            state.renderOperation(contentChanged = false, geometryChanged = true),
        )
        assertEquals(KeyguardCardWindowLifecycle.Operation.DETACH, state.hideOperation())
    }
}
