package com.fluvi.app.lockscreen

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.fluvi.app.lockscreen.material.KeyguardMaterialTime
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferLease
import com.fluvi.app.lockscreen.material.KeyguardOrbBufferProducerFrame
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/** Exercises the exact acknowledgement object used by ProducerPixelProbe. */
@RunWith(AndroidJUnit4::class)
class KeyguardProducerSampleRequestBookInstrumentationTest {
    @Test fun correct_request_completes_once_and_wrong_phase_or_lease_is_rejected() {
        val book = KeyguardProducerSampleRequestBook<String>()
        val request = book.arm(lease(1L), PHASE_A)

        assertFalse(book.completeIfCurrent(request, frame(request, phase = PHASE_B), "wrong-phase"))
        assertFalse(book.completeIfCurrent(request, frame(request, lease = lease(2L)), "old-lease"))
        assertTrue(book.completeIfCurrent(request, frame(request), "accepted"))
        assertFalse("duplicate delivery cannot complete twice", book.completeIfCurrent(request, frame(request), "duplicate"))
        assertEquals("accepted", book.await(request, timeoutMs = 100L))
    }

    @Test fun same_numeric_phase_requests_remain_distinct_and_delayed_old_frame_cannot_satisfy_new_request() {
        val book = KeyguardProducerSampleRequestBook<String>()
        val a1 = book.arm(lease(1L), PHASE_A)
        val b = book.supersede(a1, lease(1L), PHASE_B)
        val a2 = book.supersede(b, lease(1L), PHASE_A)

        assertNotEquals(a1.requestId, b.requestId)
        assertNotEquals(b.requestId, a2.requestId)
        assertNotEquals(a1.requestId, a2.requestId)
        assertFalse("late A1 must not clear A2", book.completeIfCurrent(a1, frame(a1), "late-a1"))
        assertFalse("late A1 failure must not poison A2", book.failIfCurrent(a1, IllegalStateException("late-a1")))
        assertTrue(book.completeIfCurrent(a2, frame(a2), "a2"))
        assertEquals("a2", book.await(a2, timeoutMs = 100L))
    }

    @Test fun superseded_request_cannot_clear_or_complete_its_successor() {
        val book = KeyguardProducerSampleRequestBook<String>()
        val original = book.arm(lease(1L), PHASE_A)
        val successor = book.supersede(original, lease(1L), PHASE_B)

        assertFalse(book.completeIfCurrent(original, frame(original), "old"))
        assertTrue(book.current() === successor)
        assertTrue(book.completeIfCurrent(successor, frame(successor), "new"))
        assertEquals("new", book.await(successor, timeoutMs = 100L))
    }

    private fun lease(generation: Long) = KeyguardOrbBufferLease(
        attachment = 77L,
        generation = generation,
        visualKey = "visual-$generation",
        programKey = "program-$generation",
        width = 168,
        height = 168,
    )

    private fun frame(
        request: KeyguardProducerSampleRequestBook.Request<String>,
        lease: KeyguardOrbBufferLease = request.expectedLease,
        phase: Float = request.expectedPhase,
    ) = KeyguardOrbBufferProducerFrame(
        lease = lease,
        slotId = 1L,
        useGeneration = 1L,
        frameTimeNanos = 1L,
        materialTime = KeyguardMaterialTime(phase, phase, phase, phase),
        testRequestId = request.requestId,
    )

    private companion object {
        const val PHASE_A = 1.196795f
        const val PHASE_B = 3.75f
    }
}
