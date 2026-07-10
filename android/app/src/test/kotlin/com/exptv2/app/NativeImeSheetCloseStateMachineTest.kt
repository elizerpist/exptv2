package com.exptv2.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NativeImeSheetCloseStateMachineTest {
    @Test
    fun closeWithVisibleImeWaitsForImeZeroBeforeNotifying() {
        val state = NativeImeSheetCloseStateMachine()
        state.markOpened()

        val requested = state.requestClose(
            visible = true,
            imeBottomPx = 252,
            notifyMain = true,
        )

        assertTrue(requested.hideKeyboard)
        assertTrue(requested.scheduleTimeout)
        assertFalse(requested.finish)
        assertFalse(requested.notifyMain)
        assertEquals(NativeImeSheetCloseStateMachine.Phase.CLOSING, state.phase)

        val progress = state.onImeProgress(0)

        assertTrue(progress.finish)
        assertTrue(progress.notifyMain)
        assertEquals("ime_zero", progress.reason)
        assertEquals(NativeImeSheetCloseStateMachine.Phase.CLOSED, state.phase)
    }

    @Test
    fun closeWithHiddenImeFinishesImmediately() {
        val state = NativeImeSheetCloseStateMachine()
        state.markOpened()

        val requested = state.requestClose(
            visible = true,
            imeBottomPx = 0,
            notifyMain = true,
        )

        assertFalse(requested.hideKeyboard)
        assertFalse(requested.scheduleTimeout)
        assertTrue(requested.finish)
        assertTrue(requested.notifyMain)
        assertEquals("ime_already_zero", requested.reason)
        assertEquals(NativeImeSheetCloseStateMachine.Phase.CLOSED, state.phase)
    }

    @Test
    fun duplicateCloseWhileClosingDoesNotDoubleNotify() {
        val state = NativeImeSheetCloseStateMachine()
        state.markOpened()
        val first = state.requestClose(
            visible = true,
            imeBottomPx = 252,
            notifyMain = true,
        )

        val duplicate = state.requestClose(
            visible = true,
            imeBottomPx = 252,
            notifyMain = true,
        )

        assertTrue(first.scheduleTimeout)
        assertFalse(duplicate.scheduleTimeout)
        assertFalse(duplicate.finish)
        assertFalse(duplicate.notifyMain)

        val finished = state.onImeEnd(0)
        val afterFinish = state.onImeEnd(0)

        assertTrue(finished.finish)
        assertTrue(finished.notifyMain)
        assertFalse(afterFinish.finish)
        assertFalse(afterFinish.notifyMain)
    }

    @Test
    fun duplicateCloseWithSettledImeCompletesPendingClose() {
        val state = NativeImeSheetCloseStateMachine()
        state.markOpened()
        state.requestClose(
            visible = true,
            imeBottomPx = 252,
            notifyMain = true,
        )

        val duplicate = state.requestClose(
            visible = true,
            imeBottomPx = 0,
            notifyMain = true,
        )

        assertTrue(duplicate.finish)
        assertTrue(duplicate.notifyMain)
        assertEquals("ime_zero", duplicate.reason)
        assertEquals(NativeImeSheetCloseStateMachine.Phase.CLOSED, state.phase)
    }

    @Test
    fun staleTimeoutAfterReopenIsIgnored() {
        val state = NativeImeSheetCloseStateMachine()
        state.markOpened()
        val close = state.requestClose(
            visible = true,
            imeBottomPx = 252,
            notifyMain = true,
        )

        state.markOpened()
        val staleTimeout = state.onTimeout(close.token)

        assertFalse(staleTimeout.finish)
        assertFalse(staleTimeout.notifyMain)
        assertEquals(NativeImeSheetCloseStateMachine.Phase.OPEN, state.phase)
    }

    @Test
    fun timeoutCompletesPendingCloseOnce() {
        val state = NativeImeSheetCloseStateMachine()
        state.markOpened()
        val close = state.requestClose(
            visible = true,
            imeBottomPx = 252,
            notifyMain = true,
        )

        val timeout = state.onTimeout(close.token)
        val duplicateTimeout = state.onTimeout(close.token)

        assertTrue(timeout.finish)
        assertTrue(timeout.notifyMain)
        assertEquals("timeout", timeout.reason)
        assertFalse(duplicateTimeout.finish)
        assertFalse(duplicateTimeout.notifyMain)
        assertEquals(NativeImeSheetCloseStateMachine.Phase.CLOSED, state.phase)
    }
}
