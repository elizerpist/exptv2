package com.fluvi.wa

import java.security.MessageDigest
import java.util.concurrent.atomic.AtomicLong

data class WaAttachment(val service: Long, val episode: Long, val window: Long, val widget: Int, val dp: Int)

internal enum class WaSource {
    WINDOW, ACCESSIBILITY, OTHER_DISPLAY, SCREEN_OFF, SCREEN_ON, USER_PRESENT, DISPLAY,
    CONTENT, CONNECT, DISCONNECT, CONFIGURATION, SCAN_APPLY, ADD_RECHECK, ENTRANCE, INTERRUPT, PROBE,
}

internal enum class WaEventClass { UNKNOWN, OWN, SYSTEM_UI, HOME, OTHER }

internal enum class WaStage(val terminal: Boolean = false, val coalescible: Boolean = false) {
    CALLBACK, STATE_READ, DECISION(terminal = true), REVOKE(terminal = true), ROOT_ATTACHED,
    INGRESS(coalescible = true), FILTERED(coalescible = true), DENIED(coalescible = true),
    TERMINAL(terminal = true, coalescible = true), EPISODE_OPEN,
    SCAN_OFFER, SCAN_START, SCAN_RESULT, SCAN_APPLY, SCAN_CANCEL, STALE, ADD_WAIT,
    MATERIAL_READY, ATTACH, ROOT_DRAW, ENTRANCE_BEGIN, FIRST_NONZERO, ENTRANCE_END,
    ENTRANCE_DISABLED, ENTRANCE_REUSED, ENTRANCE_CANCEL(terminal = true), RESIZE,
    LOCAL_HIDE(terminal = true), REMOVE_BEGIN(terminal = true), REMOVE_RETURN(terminal = true),
    REMOVE_ERROR(terminal = true), DETACHED(terminal = true), HOST_STOP_BEGIN(terminal = true),
    HOST_STOP_END(terminal = true), HOST_STOP_ERROR(terminal = true), PROBE,
}

/** One writer per ring. A reader takes the rings only after the capture has stopped. */
internal class WaTraceRing(private val capacity: Int, private val sequence: AtomicLong) {
    private val slots = Array(capacity) { Row() }
    var observed = 0
        private set
    var coalesced = 0
        private set
    var dropped = 0
        private set
    private var size = 0
    private var next = 0

    fun add(
        stage: WaStage, source: WaSource, service: Long, episode: Long, owner: WaAttachment?,
        scan: Long, hide: Long, reason: WaHideReason, state: WaSystemState?, scene: WaLockscreenScene?,
        barrier: WaBarrier?, up: Long, elapsed: Long, received: Long, type: Int, eventTime: Long,
        detail: Long, detailEnd: Long, allowMerge: Boolean,
        displayId: Int = 0, windowAlias: Int = 0, eventClass: WaEventClass = WaEventClass.UNKNOWN,
        windowChanges: Int = -1, contentChanges: Int = -1,
    ): Row {
        observed++
        val observedSequence = sequence.incrementAndGet()
        val latest = slots[(next + capacity - 1) % capacity]
        if (size > 0 && allowMerge && latest.stage == stage && latest.source == source &&
            latest.service == service && latest.episode == episode && latest.owner == owner &&
            latest.hide == hide && latest.reason == reason && latest.state == state &&
            latest.scene == scene && latest.barrier == barrier && latest.type == type &&
            latest.displayId == displayId && latest.windowAlias == windowAlias && latest.eventClass == eventClass &&
            latest.windowChanges == windowChanges && latest.contentChanges == contentChanges
        ) {
            if (stage == WaStage.PROBE) {
                val previousEnd = latest.latestProbeEnd
                latest.maxGap = maxOf(latest.maxGap, elapsed - previousEnd)
                latest.latestProbeEnd = detailEnd
            }
            latest.lastSequence = observedSequence
            latest.lastUp = up
            latest.lastElapsed = elapsed
            latest.count++
            coalesced++
            return latest
        }
        if (size == capacity) dropped++ else size++
        val row = slots[next]
        next = (next + 1) % capacity
        row.sequence = observedSequence
        row.lastSequence = observedSequence
        row.stage = stage
        row.source = source
        row.service = service
        row.episode = episode
        row.owner = owner
        row.scan = scan
        row.hide = hide
        row.reason = reason
        row.state = state
        row.scene = scene
        row.barrier = barrier
        row.up = up
        row.elapsed = elapsed
        row.received = received
        row.type = type
        row.eventTime = eventTime
        row.detail = detail
        row.detailEnd = detailEnd
        row.displayId = displayId
        row.windowAlias = windowAlias
        row.eventClass = eventClass
        row.windowChanges = windowChanges
        row.contentChanges = contentChanges
        row.count = 1
        row.lastUp = up
        row.lastElapsed = elapsed
        row.latestProbeEnd = detailEnd
        row.maxGap = 0
        return row
    }

    fun rows(): List<Row> = if (size < capacity) slots.take(size) else slots.toList()

    class Row {
        var sequence = 0L
        var lastSequence = 0L
        var stage = WaStage.INGRESS
        var source = WaSource.WINDOW
        var service = 0L
        var episode = 0L
        var owner: WaAttachment? = null
        var scan = 0L
        var hide = 0L
        var reason = WaHideReason.NONE
        var state: WaSystemState? = null
        var scene: WaLockscreenScene? = null
        var barrier: WaBarrier? = null
        var up = 0L
        var elapsed = 0L
        var received = 0L
        var type = 0
        var eventTime = 0L
        var detail = 0L
        var detailEnd = 0L
        var displayId = 0
        var windowAlias = 0
        var eventClass = WaEventClass.UNKNOWN
        var windowChanges = -1
        var contentChanges = -1
        var count = 1
        var lastUp = 0L
        var lastElapsed = 0L
        var latestProbeEnd = 0L
        var maxGap = 0L

        fun line(): String = buildString {
            append("$sequence $stage src=$source up=$up el=$elapsed s=$service e=$episode")
            owner?.let { append(" w=${it.window} id=${it.widget} dp=${it.dp}") }
            if (scan != 0L) append(" scan=$scan")
            if (hide != 0L) append(" hide=$hide")
            if (reason != WaHideReason.NONE) append(" why=$reason")
            if (received != 0L) append(" recvUp=$received")
            if (type != 0 && stage != WaStage.PROBE) append(" event=$type eventUp=" + seenTime(eventTime))
            if (stage == WaStage.CALLBACK) {
                append(" eventClass=$eventClass displayId=" + if (displayId >= 0) displayId else "UNOBSERVED")
                append(" alias=" + if (windowAlias != 0) windowAlias else "UNOBSERVED")
                append(" windowChanges=" + if (windowChanges >= 0) windowChanges else "UNOBSERVED")
                append(" contentChanges=" + if (contentChanges >= 0) contentChanges else "UNOBSERVED")
            }
            if (state != null || source == WaSource.PROBE || stage == WaStage.TERMINAL) {
                append(" display=${state?.displayState ?: "UNKNOWN"}")
                append(" interactive=${state?.interactive ?: "UNKNOWN"} locked=${state?.locked ?: "UNKNOWN"}")
            }
            if (scene != null) append(" scene=$scene")
            if (barrier != null) append(" gate=$barrier")
            when (stage) {
                WaStage.STATE_READ -> append(" readStartEl=$detail readEndEl=$detailEnd")
                WaStage.PROBE -> append(" readEndEl=$detailEnd lastReadEndEl=$latestProbeEnd maxIdleNs=$maxGap crossedVisibility=${type != 0}")
                WaStage.SCAN_RESULT -> append(" workerBeginUp=$detail workerEndUp=$detailEnd")
                WaStage.TERMINAL, WaStage.DENIED -> if (detail != 0L) append(" decideUp=$detail decideEl=$detailEnd")
                WaStage.REMOVE_RETURN, WaStage.REMOVE_ERROR -> append(" detached=${detail == 1L}")
                WaStage.REMOVE_BEGIN -> append(" retry=${detail == 1L}")
                WaStage.RESIZE -> append(" currentDp=$detail")
                else -> Unit
            }
            if (count > 1) append(" repeat=$count lastUp=$lastUp lastEl=$lastElapsed")
            append('\n')
        }

        private fun seenTime(value: Long) = if (value == 0L) "UNOBSERVED" else value.toString()
    }
}

internal const val WA_CAPTURE_MAGIC = "FLUVI_WA_LOCKSCREEN_CAPTURE_V1"
internal const val WA_CAPTURE_MAGIC_V2 = "FLUVI_WA_LOCKSCREEN_CAPTURE_V2"
internal const val WA_CAPTURE_BYTES = 128 * 1024

/** The digest describes all UTF-8 bytes up to and including the final body newline. */
internal fun waCaptureDigest(body: String): String =
    MessageDigest.getInstance("SHA-256").digest(body.toByteArray(Charsets.UTF_8))
        .joinToString("") { "%02x".format(it) }

internal fun waCaptureText(header: String, rows: List<WaTraceRing.Row>): Pair<String, Int> {
    val chosen = mutableListOf<Pair<Long, String>>()
    // Reserve the metadata and digest, then retain terminal rows before the recent ordinary rows.
    var remaining = WA_CAPTURE_BYTES - header.toByteArray(Charsets.UTF_8).size - 512
    for (row in rows.sortedWith(compareByDescending<WaTraceRing.Row> { it.stage.terminal }.thenByDescending { it.sequence })) {
        val line = row.line() // All variable fields here are enums, booleans, or integers.
        if (line.length <= remaining) {
            chosen += row.sequence to line
            remaining -= line.length
        }
    }
    val dropped = rows.size - chosen.size
    val body = buildString {
        append(header)
        append("retained=${chosen.size} textDropped=$dropped truncated=${dropped > 0 || "ringTruncated=true" in header}\n")
        chosen.sortedBy { it.first }.forEach { append(it.second) }
    }
    return (body + "sha256=${waCaptureDigest(body)}\n") to dropped
}
