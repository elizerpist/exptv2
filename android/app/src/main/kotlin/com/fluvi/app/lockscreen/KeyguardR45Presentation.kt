package com.fluvi.app.lockscreen

import android.view.Display
import android.view.accessibility.AccessibilityEvent

/** Public, fixed-sample authority. It contains no private material or legacy
 * inspection ticket. Each route separately owns its live presentation. */
internal data class KeyguardR45SampleIntent(
    val generation: Long,
    val capture: String,
    val session: Long,
    val routeGeneration: Long,
    val action: String,
    val circle: Boolean,
)

internal enum class KeyguardR45Phase {
    PREPARED, WAIT_WAKE, OPENING, ATTACHED_HIDDEN, VISIBLE, SUSPENDED, RETIRED,
}

/** The delay belongs to the wake owner, not to each revision of its proof.
 * Elapsing the delay is never itself permission to attach or reveal. */
internal class KeyguardR46OpeningDelay {
    var eligibleSince: Long? = null
        private set
    var dueAt: Long? = null
        private set

    fun allow(now: Long): Long {
        if (eligibleSince == null) {
            eligibleSince = now
            dueAt = now + 50L
        }
        return (requireNotNull(dueAt) - now).coerceAtLeast(0L)
    }

    fun reset() { eligibleSince = null; dueAt = null }
}

/** WA has its own arm and wake identity; no Fluvi target, scene or ticket is
 * accepted by this controller. The caller remains responsible for actual
 * system admission and exact View cleanup. Main thread owns these fields. */
internal class KeyguardR45WaLifetime {
    private var nextGeneration = 0L
    @Volatile var intent: KeyguardR45SampleIntent? = null
        private set
    @Volatile var phase = KeyguardR45Phase.RETIRED
        private set
    @Volatile var wake = 0L
        private set
    @Volatile var material = 0L
        private set

    fun prepare(capture: String, session: Long, route: Long, action: String, circle: Boolean): KeyguardR45SampleIntent {
        val next = KeyguardR45SampleIntent(++nextGeneration, capture, session, route, action, circle)
        intent = next
        phase = KeyguardR45Phase.PREPARED
        wake = 0L
        material = 0L
        return next
    }

    fun screenOff(): Boolean {
        if (phase == KeyguardR45Phase.WAIT_WAKE && intent != null) return true
        if (phase != KeyguardR45Phase.PREPARED || intent == null) return false
        phase = KeyguardR45Phase.WAIT_WAKE
        return true
    }

    fun screenOn(session: Long, capture: String?): KeyguardR45SampleIntent? {
        val current = intent ?: return null
        if (phase != KeyguardR45Phase.WAIT_WAKE || current.session != session || current.capture != capture) return null
        phase = KeyguardR45Phase.OPENING
        return current
    }

    fun bind(value: KeyguardR45SampleIntent, wake: Long, material: Long): Boolean {
        if (intent !== value || phase != KeyguardR45Phase.OPENING || this.wake != 0L || wake <= 0L || material <= 0L) return false
        this.wake = wake
        this.material = material
        return true
    }

    fun current(value: KeyguardR45SampleIntent, wake: Long, material: Long): Boolean =
        intent === value && this.wake == wake && this.material == material && wake > 0L &&
            phase != KeyguardR45Phase.RETIRED

    fun attached(value: KeyguardR45SampleIntent) {
        if (intent === value && phase == KeyguardR45Phase.OPENING) phase = KeyguardR45Phase.ATTACHED_HIDDEN
    }
    fun visible(value: KeyguardR45SampleIntent) {
        if (intent === value && phase in setOf(KeyguardR45Phase.ATTACHED_HIDDEN, KeyguardR45Phase.SUSPENDED,
                KeyguardR45Phase.VISIBLE)) phase = KeyguardR45Phase.VISIBLE
    }
    fun suspend(value: KeyguardR45SampleIntent) {
        if (intent === value && phase in setOf(KeyguardR45Phase.OPENING, KeyguardR45Phase.ATTACHED_HIDDEN,
                KeyguardR45Phase.VISIBLE, KeyguardR45Phase.SUSPENDED)) phase = KeyguardR45Phase.SUSPENDED
    }
    fun retire() { intent = null; phase = KeyguardR45Phase.RETIRED; wake = 0L; material = 0L }
}

/** A direct lease is created only after the legacy opening proof has issued a
 * target. Subsequent frame ownership no longer depends on that old read. */
internal class KeyguardR45DirectLifetime {
    data class Lease(
        val token: Any, val capture: String, val session: Long, val wake: Long,
        val route: Long, val target: KeyguardR446Target, val screenAt: Long, val expiresAt: Long,
    )
    @Volatile var lease: Lease? = null
        private set
    @Volatile var phase = KeyguardR45Phase.RETIRED
        private set
    fun open(value: Lease) { lease = value; phase = KeyguardR45Phase.OPENING }
    fun current(value: Lease, now: Long): Boolean = lease === value && phase != KeyguardR45Phase.RETIRED && now < value.expiresAt
    fun visible(value: Lease) { if (lease === value && phase != KeyguardR45Phase.RETIRED) phase = KeyguardR45Phase.VISIBLE }
    fun suspend(value: Lease) { if (lease === value && phase != KeyguardR45Phase.RETIRED) phase = KeyguardR45Phase.SUSPENDED }
    fun retire() { lease = null; phase = KeyguardR45Phase.RETIRED }
}

internal enum class KeyguardR45IngressAction { IGNORE, REASSESS, OWN_REMOVED, TARGET_REMOVED }

/** In-memory only: a bounded identity from a complete, qualified inventory. */
internal data class KeyguardR45LowerWindow(val window: Int, val display: Int, val packageName: String)

/** Bounded scalar receipt; never contains accessibility text or user data. */
internal data class KeyguardR45Observation(
    val context: KeyguardDiagnosticContext,
    val route: String,
    val stage: String,
    val at: Long,
    val sequence: Long? = null,
    val sourceAt: Long? = null,
    val eventType: Int? = null,
    val changes: Int? = null,
    val window: Int? = null,
    val display: Int? = null,
    val attribution: String = "UNOBSERVED",
    val decision: String = "UNOBSERVED",
    val phase: String = "UNOBSERVED",
    val revision: Long = 0,
    val readStart: Long? = null,
    val readEnd: Long? = null,
    val detail: String = "UNOBSERVED",
)

internal data class KeyguardR45Trace(
    var firstEvent: KeyguardR45Observation? = null,
    var firstRecovery: KeyguardR45Observation? = null,
    var terminal: KeyguardR45Observation? = null,
    var attachedHidden: Long? = null,
    var postCheckBegin: Long? = null,
    var postCheckEnd: Long? = null,
    var postCheckResult: String? = null,
    var reveal: Long? = null,
    var revealState: String? = null,
    var firstDraw: Long? = null,
    var firstShader: Long? = null,
    var conceal: Long? = null,
    var remove: Long? = null,
    var shape: String? = null,
    var ignored: Int = 0,
    var unknown: Int = 0,
    var terminalEvents: Int = 0,
    var suspended: Int = 0,
    var resumed: Int = 0,
)

/** Event metadata alone never proves another window harmless. Exact own
 * content/add notifications and a verified different display are the only
 * surface-event exemptions; all other primary/unknown events need a read. */
internal object KeyguardR45IngressPolicy {
    fun decide(meta: KeyguardAccessibilityEventMeta, exactOwn: Boolean, targetWindow: Int?,
               lower: List<KeyguardR45LowerWindow> = emptyList()): KeyguardR45IngressAction {
        if (meta.displayId != Display.DEFAULT_DISPLAY && meta.displayId >= 0) return KeyguardR45IngressAction.IGNORE
        if (meta.displayId < 0) return KeyguardR45IngressAction.REASSESS
        if (meta.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED &&
            meta.windowChanges and AccessibilityEvent.WINDOWS_CHANGE_REMOVED != 0) {
            if (exactOwn) return KeyguardR45IngressAction.OWN_REMOVED
            if (targetWindow != null && meta.windowId == targetWindow) return KeyguardR45IngressAction.TARGET_REMOVED
        }
        if (exactOwn && meta.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED)
            return KeyguardR45IngressAction.IGNORE
        if (meta.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED && meta.packageName != null &&
            lower.any { it.window == meta.windowId && it.display == meta.displayId && it.packageName == meta.packageName })
            return KeyguardR45IngressAction.IGNORE
        if (exactOwn && meta.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED &&
            meta.windowChanges == AccessibilityEvent.WINDOWS_CHANGE_ADDED)
            return KeyguardR45IngressAction.IGNORE
        return KeyguardR45IngressAction.REASSESS
    }
}
