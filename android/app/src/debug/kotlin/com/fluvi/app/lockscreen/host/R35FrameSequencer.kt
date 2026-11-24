package com.fluvi.app.lockscreen.host

import java.util.ArrayDeque

/** Debug receiver only: at most one posted buffer may await ImageReader. */
internal class R35FrameSequencer<T : Any>(private val capacity: Int = 32) {
    private val waiting = ArrayDeque<T>()
    private var active: T? = null

    init { require(capacity > 0) }

    fun enqueue(frame: T) {
        check(waiting.size < capacity) { "R35 demo frame queue exhausted" }
        waiting.addLast(frame)
    }

    fun begin(): T? {
        if (active != null) return null
        val frame = waiting.pollFirst() ?: return null
        active = frame
        return frame
    }

    fun received(): T? {
        val frame = active
        active = null
        return frame
    }

    fun discard(frame: T) {
        check(active === frame) { "R35 demo frame is not active" }
        active = null
    }

    fun clear() {
        waiting.clear()
        active = null
    }
}
