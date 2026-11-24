package com.fluvi.app.lockscreen.host

import org.junit.Assert.*
import org.junit.Test

class R35FrameSequencerTest {
    private class Frame(val label: String)

    @Test fun onlyTheReceivedFrameReleasesTheNextSubmission() {
        val queue = R35FrameSequencer<Frame>()
        val blank = Frame("blank")
        val a = Frame("A")
        val b = Frame("B")
        queue.enqueue(blank)
        queue.enqueue(a)
        queue.enqueue(b)
        assertSame(blank, queue.begin())
        assertNull(queue.begin())
        assertSame(blank, queue.received())
        assertSame(a, queue.begin())
        assertNull(queue.begin())
        assertSame(a, queue.received())
        assertSame(b, queue.begin())
        assertSame(b, queue.received())
        assertNull(queue.begin())
    }

    @Test fun staleQueuedFrameCanBeDiscardedWithoutMislabelingItsSuccessor() {
        val queue = R35FrameSequencer<Frame>()
        val stale = Frame("stale")
        val current = Frame("current")
        queue.enqueue(stale)
        queue.enqueue(current)
        assertSame(stale, queue.begin())
        queue.discard(stale)
        assertSame(current, queue.begin())
        assertSame(current, queue.received())
    }

    @Test fun strayReceiptDoesNotConsumeAQueuedFrame() {
        val queue = R35FrameSequencer<Frame>()
        val a = Frame("A")
        queue.enqueue(a)
        assertNull(queue.received())
        assertSame(a, queue.begin())
        assertSame(a, queue.received())
    }

    @Test fun overflowDoesNotReplaceAcceptedFrames() {
        val queue = R35FrameSequencer<Frame>(1)
        val a = Frame("A")
        queue.enqueue(a)
        try {
            queue.enqueue(Frame("overflow"))
            fail("queue must reject overflow")
        } catch (_: IllegalStateException) {
            assertSame(a, queue.begin())
            assertSame(a, queue.received())
        }
    }

    @Test fun clearInvalidatesOutstandingAndQueuedFrames() {
        val queue = R35FrameSequencer<Frame>()
        queue.enqueue(Frame("A"))
        assertNotNull(queue.begin())
        queue.enqueue(Frame("B"))
        queue.clear()
        assertNull(queue.received())
        assertNull(queue.begin())
    }
}
