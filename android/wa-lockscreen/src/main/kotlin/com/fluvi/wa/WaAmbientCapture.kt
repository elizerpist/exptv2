package com.fluvi.wa

import android.view.Display

/** Transition receipts only. Android submission is distinct from panel visibility. */
object WaAmbientCapture {
    private const val LIMIT = 14
    private data class Row(
        val step: String, val source: String, val at: WaTime,
        val state: WaSystemState?, val gate: WaAmbientGate?, val owner: WaAmbientAuthority.Ticket?,
        val detail: String?,
    )

    private data class Episode(
        val product: WaUnlockProduct, val service: Long, val requested: Boolean, val start: WaTime,
        val rows: ArrayDeque<Row> = ArrayDeque(), var dropped: Int = 0, var repeated: Int = 0,
    )

    private var episode: Episode? = null
    private var sawDoze = false

    fun observedStatus(): String = if (sawDoze) "AOD_OBSERVED" else "AOD_UNKNOWN"

    internal fun start(product: WaUnlockProduct, service: Long, requested: Boolean) {
        episode = Episode(product, service, requested, WaTime.now())
    }

    internal fun observe(
        service: Long, source: String, state: WaSystemState, gate: WaAmbientGate,
    ) {
        if (state.isDozing) sawDoze = true
        val capture = episode?.takeIf { it.service == service } ?: return
        val previous = capture.rows.lastOrNull { it.step == "STATE" }
        if (previous?.state == state && previous.gate == gate) {
            capture.repeated++
            return
        }
        append(capture, Row("STATE", source, WaTime.now(), state, gate, null, null))
    }

    internal fun edge(
        service: Long, step: String, reason: String, owner: WaAmbientAuthority.Ticket? = null,
        detail: String? = null,
    ) {
        val capture = episode?.takeIf { it.service == service } ?: return
        append(capture, Row(step, reason, WaTime.now(), null, null, owner, detail))
    }

    private fun append(capture: Episode, row: Row) {
        if (capture.rows.size == LIMIT) {
            capture.rows.removeFirst()
            capture.dropped++
        }
        capture.rows.addLast(row)
    }

    fun latest(): Map<String, String> {
        val data = episode ?: return mapOf("status" to "EMPTY")
        val body = buildString {
            appendLine("FLUVI_WA_AMBIENT_V1")
            appendLine("build=${data.product.sourceCommit} package=${data.product.packageName} api=${data.product.sdk} display=${Display.DEFAULT_DISPLAY}")
            appendLine("serviceElapsedNs=${data.service} startedElapsedNs=${data.start.elapsedNs} requested=${data.requested}")
            appendLine("transitionSampling=true repeatedStates=${data.repeated} droppedTransitions=${data.dropped} physicalVisibility=UNOBSERVED outsideOrbPixels=UNOBSERVED")
            for (row in data.rows) {
                append("${row.step} source=${row.source} elapsedNs=${row.at.elapsedNs} uptimeMs=${row.at.uptimeMs}")
                row.state?.let {
                    append(" displayState=${it.displayState} locked=${it.locked ?: "UNOBSERVED"} interactive=${it.interactive ?: "UNOBSERVED"} gate=${row.gate}")
                }
                row.owner?.let {
                    val id = it.identity
                    append(" generation=${it.generation} widget=${id.widget} packet=${id.packet} sizeDp=${id.sizeDp} style=${id.style}")
                }
                row.detail?.let { append(" detail=$it") }
                appendLine()
            }
        }
        return mapOf("status" to "READY", "text" to "${body}bodySha256=${waCaptureDigest(body)}\n")
    }
}
