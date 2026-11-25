package com.fluvi.app.lockscreen

/** Timing is an annotation of a user-held surface, never visibility authority. */
internal object KeyguardR43HoldTiming {
    const val OPEN = 0
    const val PASSIVE_RETAINED = 1
    const val OBSERVER_RESERVED = 2
    const val OBSERVER_INCOMPLETE = 3

    fun passiveIndex(elapsedMs: Long): Int {
        if (elapsedMs < 2_500L) return -1
        val index = (elapsedMs / 6_000L).toInt()
        return if (index in 0..3 && elapsedMs - index * 6_000L >= 2_500L) index else -1
    }

    fun canAcceptPassive(state: Int): Boolean = state == OPEN || state == OBSERVER_INCOMPLETE
}

/** Capture-only technical evidence. It never conveys visibility authority or
 * retains a node, text, content description, notification, or foreign name. */
internal class KeyguardR43SurfaceEvidence {
    companion object {
        const val MAX_WINDOWS = 4
        const val MAX_IDS = 12
        private const val SYSTEM_UI = "com.android.systemui"
        private const val PREFIX = "com.android.systemui:id/"
        private val ENTRY = Regex("[a-zA-Z_][a-zA-Z0-9_]{0,63}")
    }

    data class Candidate(val entry: String, val ordinal: Int, val parent: Int, val depth: Int)
    data class Window(
        val id: Int, val type: Int, val layer: Int, val display: Int,
        val active: Boolean, val own: Boolean, val root: String, val verified: Boolean,
        var visited: Int = 0, var visible: Int = 0, var nullId: Int = 0,
        var systemId: Int = 0, var otherId: Int = 0, var foreignNode: Int = 0,
        var markers: KeyguardSurfaceMarkers = KeyguardSurfaceMarkers(),
        var candidatesOmitted: Int = 0, val candidates: MutableList<Candidate> = mutableListOf(),
    ) {
        fun node(visibleNode: Boolean, systemOwner: Boolean, rawId: String?, ordinal: Int, parent: Int, depth: Int) {
            visited++
            if (!visibleNode) return
            visible++
            if (!systemOwner) foreignNode++
            if (rawId == null) { nullId++; return }
            if (rawId.startsWith(PREFIX)) systemId++ else otherId++
            if (!verified || !systemOwner || !rawId.startsWith(PREFIX)) return
            val entry = rawId.removePrefix(PREFIX)
            if (!ENTRY.matches(entry)) return
            if (candidates.size < MAX_IDS) candidates += Candidate(entry, ordinal, parent, depth)
            else candidatesOmitted++
        }
    }

    private val retained = mutableListOf<Window>()
    var omittedWindows = 0
        private set
    fun window(id: Int, type: Int, layer: Int, display: Int, active: Boolean,
               own: Boolean, rootPackage: String?, verified: Boolean): Window? {
        if (retained.size >= MAX_WINDOWS) { omittedWindows++; return null }
        val category = when {
            own -> "OWN"
            rootPackage == null -> "UNAVAILABLE"
            rootPackage == SYSTEM_UI -> "SYSTEMUI"
            rootPackage == "com.android.keyguard" -> "KEYGUARD"
            rootPackage == "android" -> "ANDROID"
            else -> "FOREIGN"
        }
        return Window(id, type, layer, display, active, own, category,
            verified && !own && rootPackage == SYSTEM_UI).also(retained::add)
    }

    fun windows(): List<Window> = retained.toList()

    /** Classify only already-acquired scalar snapshots; never revisit a node. */
    fun attachMarkers(snapshots: List<KeyguardWindowSnapshot>) {
        retained.forEach { window ->
            val snapshot = snapshots.firstOrNull { it.windowId == window.id && !it.ownOverlay }
            if (snapshot != null) window.markers = KeyguardSurfaceClassifier.classifyDetailed(listOf(snapshot)).markers
        }
    }

    /** Called off the acquisition lane: only resource entries actually
     * resolved in installed SystemUI may survive into a report. */
    fun verifiedEntries(window: Window, exists: (String) -> Boolean): List<Candidate> =
        window.candidates.filter { runCatching { exists(it.entry) }.getOrDefault(false) }
}

/** One immutable read owner plus bounded scalar-only window evidence. A hold
 * label is a time-based user annotation, never an admission decision. */
internal data class KeyguardR43Observation(
    val captureId: String,
    val session: Long,
    val wake: Long,
    val request: Long?,
    val scene: Long?,
    val observedAt: Long,
    val source: String,
    val hold: String?,
    val serviceFlags: Int?,
    val ownAmbiguous: Boolean,
    val classification: KeyguardSurfaceClassification,
    val rootUnavailable: Boolean,
    val truncated: Boolean,
    val stale: Boolean,
    val windowsMs: Long,
    val scanMs: Long,
    val visited: Int,
    val evidence: KeyguardR43SurfaceEvidence,
)
